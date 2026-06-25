# Memory

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Short-term memory](#short-term-memory)
- [Message management strategies](#message-management-strategies)
- [Accessing state in tools](#accessing-state-in-tools)
- [Dynamic prompts via middleware](#dynamic-prompts-via-middleware)
- [After-model middleware](#after-model-middleware)
- [Long-term memory](#long-term-memory)
- [Checkpointer options](#checkpointer-options)
- [Key APIs](#key-apis)
- [Best practices](#best-practices)

## Overview

LangChain has two types of memory for agents: **short-term memory** (conversation context within a single thread) and **long-term memory** (knowledge that persists across conversations). Short-term memory keeps conversation history in a checkpointer. Long-term memory stores structured data across threads through a store abstraction.

Memory lets an agent retain context, learn from feedback, and adapt to user preferences. Long conversations are the main problem: the full history may not fit in the LLM's context window, so you need trimming, summarization, or external persistence.

## Installation

```bash
pip install langchain langgraph
# For production persistence:
pip install langgraph-checkpoint-postgres  # PostgreSQL
pip install langgraph-checkpoint-sqlite    # SQLite
```

## Short-term memory

### Basic setup with InMemorySaver

```python
from langchain.agents import create_agent
from langgraph.checkpoint.memory import InMemorySaver

agent = create_agent(
    "gpt-5",
    tools=[get_user_info],
    checkpointer=InMemorySaver(),
)

# Thread ID groups interactions in a session
agent.invoke(
    {"messages": [{"role": "user", "content": "Hi! My name is Bob."}]},
    {"configurable": {"thread_id": "1"}},
)
```

### Production setup with PostgreSQL

```python
from langchain.agents import create_agent
from langgraph.checkpoint.postgres import PostgresSaver

DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresSaver.from_conn_string(DB_URI) as checkpointer:
    checkpointer.setup()
    agent = create_agent(
        "gpt-5",
        tools=[get_user_info],
        checkpointer=checkpointer,
    )
```

### Custom state extension

```python
from langchain.agents import create_agent, AgentState
from langgraph.checkpoint.memory import InMemorySaver

class CustomAgentState(AgentState):
    user_id: str
    preferences: dict

agent = create_agent(
    "gpt-5",
    tools=[get_user_info],
    state_schema=CustomAgentState,
    checkpointer=InMemorySaver(),
)

result = agent.invoke(
    {
        "messages": [{"role": "user", "content": "Hello"}],
        "user_id": "user_123",
        "preferences": {"theme": "dark"}
    },
    {"configurable": {"thread_id": "1"}}
)
```

## Message management strategies

### Trim messages

Keep only the last N messages before each LLM call:

```python
from langchain.messages import RemoveMessage
from langgraph.graph.message import REMOVE_ALL_MESSAGES
from langchain.agents.middleware import before_model

@before_model
def trim_messages(state: AgentState, runtime: Runtime) -> dict[str, Any] | None:
    """Keep only the last few messages to fit context window."""
    messages = state["messages"]

    if len(messages) <= 3:
        return None

    first_msg = messages[0]
    recent_messages = messages[-3:] if len(messages) % 2 == 0 else messages[-4:]
    new_messages = [first_msg] + recent_messages

    return {
        "messages": [
            RemoveMessage(id=REMOVE_ALL_MESSAGES),
            *new_messages
        ]
    }
```

### Delete specific messages

```python
from langchain.messages import RemoveMessage
from langgraph.graph.message import REMOVE_ALL_MESSAGES

def delete_messages(state):
    messages = state["messages"]
    if len(messages) > 2:
        return {"messages": [RemoveMessage(id=m.id) for m in messages[:2]]}

def delete_all_messages(state):
    return {"messages": [RemoveMessage(id=REMOVE_ALL_MESSAGES)]}
```

### Summarization middleware

Condenses older messages automatically when the conversation grows too long:

```python
from langchain.agents import create_agent
from langchain.agents.middleware import SummarizationMiddleware
from langgraph.checkpoint.memory import InMemorySaver

checkpointer = InMemorySaver()

agent = create_agent(
    model="gpt-4.1",
    tools=[],
    middleware=[
        SummarizationMiddleware(
            model="gpt-4.1-mini",
            trigger=("tokens", 4000),
            keep=("messages", 20)
        )
    ],
    checkpointer=checkpointer,
)
```

| Parameter | Purpose |
|---|---|
| `model` | Model used for summarization (can be cheaper or smaller) |
| `trigger` | When to summarize (e.g., after 4000 tokens) |
| `keep` | How many recent messages to keep |

## Accessing state in tools

### Read state

```python
from langchain.agents import create_agent, AgentState
from langchain.tools import tool, ToolRuntime

class CustomState(AgentState):
    user_id: str

@tool
def get_user_info(runtime: ToolRuntime) -> str:
    """Look up user info."""
    user_id = runtime.state["user_id"]
    return "User is John Smith" if user_id == "user_123" else "Unknown user"
```

### Write state from tools

```python
from langgraph.types import Command

@tool
def update_user_info(runtime: ToolRuntime[Context, CustomState]) -> Command:
    """Look up and update user info."""
    user_id = runtime.context.user_id
    name = "John Smith" if user_id == "user_123" else "Unknown user"
    return Command(update={"user_name": name})
```

## Dynamic prompts via middleware

```python
from langchain.agents.middleware import dynamic_prompt, ModelRequest

@dynamic_prompt
def dynamic_system_prompt(request: ModelRequest) -> str:
    user_name = request.runtime.context["user_name"]
    return f"You are a helpful assistant. Address the user as {user_name}."
```

## After-model middleware

```python
from langchain.agents.middleware import after_model

@after_model
def validate_response(state: AgentState, runtime: Runtime) -> dict | None:
    """Remove messages containing sensitive words."""
    STOP_WORDS = ["password", "secret"]
    last_message = state["messages"][-1]
    if any(word in last_message.content for word in STOP_WORDS):
        return {"messages": [RemoveMessage(id=last_message.id)]}
    return None
```

## Long-term memory

Long-term memory persists across conversation threads through the LangGraph store abstraction. Memories are JSON documents organized in namespaces.

### Store architecture

| Concept | Analogy | Purpose |
|---|---|---|
| Namespace | Folder | Container for organizing memories (typically includes the user ID) |
| Key | Filename | Unique identifier within a namespace |
| Value | File content | JSON document with memory data |

### Basic setup

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore(index={"embed": embed, "dims": 2})
namespace = (user_id, application_context)
store.put(namespace, "a-memory", {"rules": [...], "my-key": "my-value"})
```

### Store operations

| Operation | Description |
|---|---|
| `store.put(namespace, key, value)` | Save or update a memory |
| `store.get(namespace, key)` | Retrieve a specific memory |
| `store.search(namespace, filter={...}, query="...")` | Find memories with vector similarity |

### Reading long-term memory in tools

```python
@tool
def get_user_info(runtime: ToolRuntime[Context]) -> str:
    store = runtime.store
    user_info = store.get(("users",), user_id)
    return str(user_info.value) if user_info else "Unknown user"
```

### Writing long-term memory from tools

```python
@tool
def save_user_info(user_info: UserInfo, runtime: ToolRuntime[Context]) -> str:
    store = runtime.store
    store.put(("users",), user_id, user_info)
    return "Successfully saved user info."
```

### Passing the store to the agent

```python
agent = create_agent(model="gpt-5", tools=[get_user_info, save_user_info], store=store)
```

## Checkpointer options

| Backend | Package | Use case |
|---|---|---|
| `InMemorySaver` | `langgraph` | Development and testing |
| `PostgresSaver` | `langgraph-checkpoint-postgres` | Production deployments |
| `SqliteSaver` | `langgraph-checkpoint-sqlite` | Lightweight persistence |
| Azure Cosmos DB | `langgraph-checkpoint-azure` | Azure deployments |

## Key APIs

| Class/Function | Module | Purpose |
|---|---|---|
| `InMemorySaver` | `langgraph.checkpoint.memory` | In-memory checkpointer |
| `PostgresSaver` | `langgraph.checkpoint.postgres` | PostgreSQL checkpointer |
| `InMemoryStore` | `langgraph.store.memory` | In-memory long-term store |
| `AgentState` | `langchain.agents` | Base state class for agents |
| `ToolRuntime` | `langchain.tools` | Runtime access in tools |
| `RemoveMessage` | `langchain.messages` | Delete messages from history |
| `REMOVE_ALL_MESSAGES` | `langgraph.graph.message` | Sentinel for clearing all messages |
| `SummarizationMiddleware` | `langchain.agents.middleware` | Summarizes long conversations automatically |
| `@before_model` | `langchain.agents.middleware` | Pre-process before LLM call |
| `@after_model` | `langchain.agents.middleware` | Post-process after LLM call |
| `@dynamic_prompt` | `langchain.agents.middleware` | Context-aware system prompts |
| `Command` | `langgraph.types` | Return state updates from tools |

## Best practices

- Use `InMemorySaver` for development; switch to PostgreSQL or SQLite for production
- Always specify `thread_id` in config to isolate conversation threads
- Use summarization middleware for long conversations instead of truncating
- When deleting messages, keep the history valid (some providers require a user message first and tool results after tool calls)
- Use namespaces with user IDs to isolate long-term memories per user
- Keep long-term memory values as structured JSON for easier querying
- Use vector-indexed stores (`index={"embed": embed, "dims": N}`) for semantic search across memories
- Prefer `@before_model` middleware for message trimming over manual state manipulation
