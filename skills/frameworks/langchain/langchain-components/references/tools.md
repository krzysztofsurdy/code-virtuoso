# Tools

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Creating tools](#creating-tools)
- [Accessing runtime context](#accessing-runtime-context)
- [ToolNode](#toolnode)
- [Model Context Protocol (MCP)](#model-context-protocol-mcp)
- [Key APIs](#key-apis)
- [Best practices](#best-practices)

## Overview

Tools let agents fetch real-time data, run code, query databases, and take external actions. A tool is a callable function with defined inputs and outputs; the chat model decides when and how to call it based on the conversation. LangChain also supports the Model Context Protocol (MCP) for sharing tools across applications.

## Installation

```bash
pip install langchain
# For MCP support:
pip install langchain-mcp-adapters
```

## Creating tools

### Basic definition

The `@tool` decorator creates a tool and uses the docstring as its description. Type hints define the input schema:

```python
from langchain.tools import tool

@tool
def search_database(query: str, limit: int = 10) -> str:
    """Search customer database for matching records.

    Args:
        query: Search terms
        limit: Maximum results to return
    """
    return f"Found {limit} results for '{query}'"
```

Prefer `snake_case` for tool names to avoid compatibility issues across model providers.

### Custom names and descriptions

```python
import ast
import operator

@tool("web_search")
def search(query: str) -> str:
    """Search the web for information."""
    return f"Results for: {query}"

@tool("calculator", description="Performs arithmetic calculations...")
def calc(expression: str) -> str:
    """Evaluate mathematical expressions."""
    ops = {ast.Add: operator.add, ast.Sub: operator.sub,
           ast.Mult: operator.mul, ast.Div: operator.truediv}

    def evaluate(node: ast.expr) -> float:
        if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
            return node.value
        if isinstance(node, ast.BinOp) and type(node.op) in ops:
            return ops[type(node.op)](evaluate(node.left), evaluate(node.right))
        raise ValueError("Only + - * / on numbers is allowed")

    return str(evaluate(ast.parse(expression, mode="eval").body))
```

### Advanced schema with Pydantic

```python
from pydantic import BaseModel, Field
from typing import Literal

class WeatherInput(BaseModel):
    location: str = Field(description="City name or coordinates")
    units: Literal["celsius", "fahrenheit"] = Field(default="celsius")
    include_forecast: bool = Field(default=False)

@tool(args_schema=WeatherInput)
def get_weather(location: str, units: str = "celsius",
                include_forecast: bool = False) -> str:
    """Get current weather and optional forecast."""
    temp = 22 if units == "celsius" else 72
    result = f"Current weather in {location}: {temp} degrees {units[0].upper()}"
    if include_forecast:
        result += "\nNext 5 days: Sunny"
    return result
```

### Reserved parameter names

Two parameter names cannot be used as tool arguments:
- `config` - reserved for `RunnableConfig`
- `runtime` - reserved for `ToolRuntime`

## Accessing runtime context

Tools use `ToolRuntime` to access conversation state, configuration, persistent storage, and streaming capabilities.

| Component | Purpose |
|-----------|---------|
| `runtime.state` | Short-term conversation memory (messages, counters, custom fields) |
| `runtime.context` | Immutable invocation-time config (user IDs, session info) |
| `runtime.store` | Long-term persistent data across conversations |
| `runtime.stream_writer` | Real-time updates during execution |
| `runtime.tool_call_id` | Unique identifier for current invocation |

### State access (short-term memory)

```python
@tool
def get_last_user_message(runtime: ToolRuntime) -> str:
    """Get the most recent message from the user."""
    messages = runtime.state["messages"]
    for message in reversed(messages):
        if isinstance(message, HumanMessage):
            return message.content
    return "No user messages found"
```

Update state with Command:

```python
from langgraph.types import Command

@tool
def set_user_name(new_name: str) -> Command:
    """Set the user's name in conversation state."""
    return Command(update={"user_name": new_name})
```

### Context (immutable configuration)

```python
from dataclasses import dataclass

@dataclass
class UserContext:
    user_id: str

@tool
def get_account_info(runtime: ToolRuntime[UserContext]) -> str:
    """Get current user's account information."""
    user_id = runtime.context.user_id
    return f"Account info for {user_id}"
```

Pass context at invocation:

```python
agent = create_agent(
    model,
    tools=[get_account_info],
    context_schema=UserContext,
    system_prompt="You are a financial assistant."
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "What's my balance?"}]},
    context=UserContext(user_id="user123")
)
```

### Store (long-term memory)

```python
@tool
def get_user_info(user_id: str, runtime: ToolRuntime) -> str:
    """Look up user info."""
    store = runtime.store
    user_info = store.get(("users",), user_id)
    return str(user_info.value) if user_info else "Unknown user"

@tool
def save_user_info(user_id: str, user_info: dict[str, Any],
                   runtime: ToolRuntime) -> str:
    """Save user info."""
    store = runtime.store
    store.put(("users",), user_id, user_info)
    return "Successfully saved user info."
```

For production, use `PostgresStore` instead of `InMemoryStore`.

### Stream writer

```python
@tool
def get_weather(city: str, runtime: ToolRuntime) -> str:
    """Get weather for a given city."""
    writer = runtime.stream_writer
    writer(f"Looking up data for city: {city}")
    writer(f"Acquired data for city: {city}")
    return f"It's always sunny in {city}!"
```

## ToolNode

`ToolNode` is a prebuilt LangGraph component that handles parallel execution, error management, and state injection:

```python
from langgraph.prebuilt import ToolNode

tool_node = ToolNode([search, calculator])

builder = StateGraph(MessagesState)
builder.add_node("tools", tool_node)
```

### Tool return value patterns

**String returns** (human-readable):

```python
@tool
def get_weather(city: str) -> str:
    """Get weather for a city."""
    return f"It is currently sunny in {city}."
```

**Object returns** (structured data):

```python
@tool
def get_weather_data(city: str) -> dict:
    """Get structured weather data for a city."""
    return {"city": city, "temperature_c": 22, "conditions": "sunny"}
```

**Command returns** (state updates):

```python
@tool
def set_language(language: str, runtime: ToolRuntime) -> Command:
    """Set the preferred response language."""
    return Command(
        update={
            "preferred_language": language,
            "messages": [
                ToolMessage(
                    content=f"Language set to {language}.",
                    tool_call_id=runtime.tool_call_id,
                )
            ],
        }
    )
```

### Error handling

```python
# Default: catch all errors
tool_node = ToolNode(tools, handle_tool_errors=True)

# Custom message
tool_node = ToolNode(tools, handle_tool_errors="Try again please.")

# Custom handler function
def handle_error(e: ValueError) -> str:
    return f"Invalid input: {e}"
tool_node = ToolNode(tools, handle_tool_errors=handle_error)

# Specific exceptions only
tool_node = ToolNode(tools, handle_tool_errors=(ValueError, TypeError))
```

### Conditional routing

```python
from langgraph.prebuilt import tools_condition

builder.add_edge(START, "llm")
builder.add_conditional_edges("llm", tools_condition)
builder.add_edge("tools", "llm")
```

## Model Context Protocol (MCP)

MCP is an open protocol that standardizes how applications provide tools and context to LLMs.

### Core components

`MultiServerMCPClient` is the primary interface for connecting to MCP servers. Stateless by default; each tool invocation creates a fresh session. Supports multiple simultaneous server connections.

### Supported transports

| Transport | Use Case |
|-----------|----------|
| `stdio` | Local subprocess communication |
| `HTTP/streamable-http` | Remote server communication with optional headers and auth |

### Basic usage

```python
from langchain_mcp_adapters import MultiServerMCPClient

async with MultiServerMCPClient() as client:
    tools = await client.get_tools()
    resources = await client.get_resources()
    prompt = await client.get_prompt("prompt_name")
```

### Stateful sessions

For persistent connections maintaining context across tool calls:

```python
async with client.session("server_name") as session:
    tools = await load_mcp_tools(session)
```

### MCP features

| Feature | Description |
|---------|-------------|
| **Tools** | Executable functions retrieved via `client.get_tools()` |
| **Resources** | Data files/records via `client.get_resources()`, converted to LangChain Blob objects |
| **Prompts** | Reusable templates via `client.get_prompt()`, converted to LangChain message formats |
| **Interceptors** | Middleware for request/response modification, retry logic, dynamic headers |
| **Callbacks** | Progress notifications, logging, elicitation requests |
| **Elicitation** | Servers request additional user input with schema validation |

### Interceptors

Middleware functions for modifying requests/responses at runtime:
- Access runtime context (user IDs, API keys, store data, agent state)
- Retry logic and error handling
- Dynamic header modification
- State updates via `Command` objects

### Building MCP servers

Use FastMCP to build custom servers:

```python
from fastmcp import FastMCP

mcp = FastMCP("my-server")

@mcp.tool()
def my_tool(query: str) -> str:
    """Tool description."""
    return f"Result for {query}"
```

Supports both stdio and HTTP transports.

## Key APIs

| Class/Function | Description |
|----------------|-------------|
| `@tool` | Decorator to create tool functions |
| `ToolRuntime` | Access state, context, store, streaming from within tools |
| `ToolNode` | LangGraph node for parallel tool execution |
| `tools_condition` | Conditional routing based on tool calls |
| `Command` | Return type for tools that update agent state |
| `MultiServerMCPClient` | Connect to MCP servers |
| `load_mcp_tools()` | Load tools from an MCP session |

## Best practices

- Use `snake_case` for tool names across all providers
- Write clear docstrings - they serve as the tool description for the model
- Use Pydantic `Field(description=...)` for complex input schemas
- Avoid reserved parameter names (`config`, `runtime`)
- Use `ToolRuntime` for accessing conversation state rather than global variables
- Use `PostgresStore` instead of `InMemoryStore` in production
- Set `handle_tool_errors=True` on `ToolNode` to catch tool errors
- Use MCP for standardized tool integration across multiple applications
- Prefer stateless MCP connections unless persistent context is required
