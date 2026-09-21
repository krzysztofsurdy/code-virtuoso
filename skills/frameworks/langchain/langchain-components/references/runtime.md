# Runtime and component architecture

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Runtime dependency injection](#runtime-dependency-injection)
- [Component architecture](#component-architecture)
- [Key APIs](#key-apis)
- [Best practices](#best-practices)

## Overview

LangChain's `create_agent` uses LangGraph's runtime, which provides dependency injection for tools and middleware. The runtime manages context, persistent storage, and streaming, so tools can avoid hardcoded values and global state and are easier to test and reuse.

A LangChain application is built from components arranged in five layers: input processing, embedding and storage, retrieval, generation, and orchestration.

## Installation

```bash
pip install langchain langgraph
```

## Runtime dependency injection

### Defining Context

Define a context schema using a dataclass and pass it when creating the agent.

```python
from dataclasses import dataclass
from langchain.agents import create_agent

@dataclass
class AgentContext:
    user_id: str
    db_connection: any
    api_key: str

agent = create_agent(
    model="gpt-4.1",
    tools=[search_docs, update_profile],
    context_schema=AgentContext,
)

# Supply context at invocation time
response = agent.invoke(
    {"messages": [{"role": "user", "content": "Update my profile"}]},
    context=AgentContext(
        user_id="user_123",
        db_connection=db,
        api_key="sk-..."
    )
)
```

### Accessing runtime in tools

Add a `runtime: ToolRuntime` parameter to a tool. The agent injects it at call time and hides it from the schema the model sees.

```python
from langchain.tools import tool, ToolRuntime

@tool
def search_docs(query: str, runtime: ToolRuntime[AgentContext]) -> str:
    """Search the user's documents."""
    user_id = runtime.context.user_id
    # Use user_id to filter results
    results = runtime.store.search(
        ("docs", user_id),
        query=query
    )
    return str(results)
```

### Accessing runtime in middleware

Node-style hooks receive a `Runtime` parameter. Wrap-style hooks access it through `ModelRequest`.

```python
from langchain.agents.middleware import AgentMiddleware

class UserAwareMiddleware(AgentMiddleware):
    def before_model(self, state, runtime):
        user_id = runtime.context.user_id
        print(f"Processing request for user: {user_id}")
        return {}
```

### Store for long-term memory

The runtime store provides persistent key-value storage accessible across invocations.

```python
from langchain.tools import tool, ToolRuntime

@tool
def save_preference(key: str, value: str, runtime: ToolRuntime[AgentContext]) -> str:
    """Save a user preference."""
    user_id = runtime.context.user_id
    runtime.store.put(
        ("preferences", user_id),
        key,
        {"preference": value}
    )
    return f"Saved {key}={value}"

@tool
def get_preferences(runtime: ToolRuntime[AgentContext]) -> str:
    """List the user's preferences."""
    user_id = runtime.context.user_id
    items = runtime.store.search(("preferences", user_id))
    return str(items)
```

### Stream writer

The runtime provides a stream writer for custom streaming updates.

```python
from langgraph.config import get_stream_writer

def process_data(data: list) -> str:
    writer = get_stream_writer()
    for i, item in enumerate(data):
        writer(f"Processing item {i+1}/{len(data)}")
        # ... process item
    return "Done"
```

## Component architecture

### Five layers

| Layer | Purpose | Key Components |
|-------|---------|----------------|
| Input Processing | Transform raw data into structured documents | Document loaders, text splitters |
| Embedding and Storage | Convert text to searchable vectors | Embedding models, vector stores |
| Retrieval | Find relevant information | Retrievers, search algorithms |
| Generation | Create AI responses | Chat models, LLMs |
| Orchestration | Coordinate components | Agents, memory systems |

### Component categories

| Category | Purpose | Examples |
|----------|---------|----------|
| Models | AI reasoning and generation | Chat models, LLMs, embedding models |
| Tools | External capabilities | APIs, databases, file systems |
| Agents | Workflow orchestration | ReAct agents, tool-calling agents |
| Memory | Context preservation | Message history, custom state |
| Retrievers | Information access | Vector retrievers, web retrievers |
| Document Processing | Data ingestion | Loaders, splitters, transformers |
| Vector Stores | Semantic search | Chroma, Pinecone, FAISS |

### Common architectural patterns

**RAG (Retrieval-Augmented Generation):**
Retrieves relevant documents to augment LLM responses with current information.

```python
from langchain.agents import create_agent

# RAG pattern: retriever tool + chat model
agent = create_agent(
    model="gpt-4.1",
    tools=[retriever_tool],
    system_prompt="Answer questions using the retriever tool to find relevant docs.",
)
```

**Agent with Tools:**
Models decide when to invoke external tools versus providing direct answers.

```python
agent = create_agent(
    model="gpt-4.1",
    tools=[search_web, calculator, send_email],
    system_prompt="Use tools when needed to answer questions accurately.",
)
```

**Multi-Agent Systems:**
Supervisor agents coordinate specialist agents on complex tasks.

```python
from langchain.tools import tool

researcher = create_agent(
    model="gpt-4.1",
    tools=[search_web],
    name="researcher",
)

writer = create_agent(
    model="gpt-4.1",
    tools=[write_doc],
    name="writer",
)

@tool("research", description="Research a topic and return findings")
def call_researcher(query: str) -> str:
    result = researcher.invoke({"messages": [{"role": "user", "content": query}]})
    return result["messages"][-1].content

@tool("write", description="Write a document from the given notes")
def call_writer(brief: str) -> str:
    result = writer.invoke({"messages": [{"role": "user", "content": brief}]})
    return result["messages"][-1].content

supervisor = create_agent(
    model="gpt-4.1",
    tools=[call_researcher, call_writer],
    name="supervisor",
)
```

## Key APIs

| API | Purpose |
|-----|---------|
| `create_agent()` | Create agent with runtime support |
| `ToolRuntime` | Parameter type that gives tools access to state, context, and store |
| `runtime.context` | Access injected context values |
| `runtime.store` | Access persistent key-value store |
| `get_stream_writer()` | Get stream writer for custom updates |
| `BaseStore` | Base class for store implementations |

## Best practices

- Define context schemas as dataclasses for type safety
- Use runtime dependency injection instead of global state or hardcoded values
- Access the store for user-specific data that persists across conversations
- Keep context schemas focused - include only what tools and middleware need
- Use the stream writer for long-running operations to provide progress feedback
- Test tools by mocking the runtime context rather than real dependencies
- Separate concerns across architectural layers - avoid mixing retrieval logic with generation
- Use the agent pattern (tools + model) rather than building custom chains for most use cases
