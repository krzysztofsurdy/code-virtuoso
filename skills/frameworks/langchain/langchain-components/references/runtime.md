# Runtime and Component Architecture

## Overview

LangChain's `create_agent` uses LangGraph's runtime, which provides dependency injection for tools and middleware. The runtime manages context, persistent storage, and streaming capabilities, making tools more testable, reusable, and flexible by eliminating hardcoded values and global state dependencies.

LangChain organizes AI application development around interconnected components that work together through five main layers: input processing, embedding and storage, retrieval, generation, and orchestration.

## Installation

```bash
pip install langchain langgraph
```

## Runtime Dependency Injection

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
    config={"context": AgentContext(
        user_id="user_123",
        db_connection=db,
        api_key="sk-..."
    )}
)
```

### Accessing Runtime in Tools

Import `ToolRuntime` to access runtime values within tool functions.

```python
from langchain.agents import ToolRuntime

def search_docs(query: str) -> str:
    runtime = ToolRuntime.get()
    user_id = runtime.context.user_id
    # Use user_id to filter results
    results = runtime.store.search(
        namespace=("docs", user_id),
        query=query
    )
    return str(results)
```

### Accessing Runtime in Middleware

Node-style hooks receive a `Runtime` parameter. Wrap-style hooks access it through `ModelRequest`.

```python
from langchain.agents.middleware import AgentMiddleware

class UserAwareMiddleware(AgentMiddleware):
    def before_model(self, state, config):
        runtime = config["runtime"]
        user_id = runtime.context.user_id
        print(f"Processing request for user: {user_id}")
        return {}
```

### Store for Long-Term Memory

The runtime store provides persistent key-value storage accessible across invocations.

```python
from langchain.agents import ToolRuntime

def save_preference(key: str, value: str) -> str:
    runtime = ToolRuntime.get()
    user_id = runtime.context.user_id
    runtime.store.put(
        namespace=("preferences", user_id),
        key=key,
        value={"preference": value}
    )
    return f"Saved {key}={value}"

def get_preferences() -> str:
    runtime = ToolRuntime.get()
    user_id = runtime.context.user_id
    items = runtime.store.list(namespace=("preferences", user_id))
    return str(items)
```

### Stream Writer

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

## Component Architecture

### Five Layers

| Layer | Purpose | Key Components |
|-------|---------|----------------|
| Input Processing | Transform raw data into structured documents | Document loaders, text splitters |
| Embedding and Storage | Convert text to searchable vectors | Embedding models, vector stores |
| Retrieval | Find relevant information | Retrievers, search algorithms |
| Generation | Create AI responses | Chat models, LLMs |
| Orchestration | Coordinate components | Agents, memory systems |

### Component Categories

| Category | Purpose | Examples |
|----------|---------|----------|
| Models | AI reasoning and generation | Chat models, LLMs, embedding models |
| Tools | External capabilities | APIs, databases, file systems |
| Agents | Workflow orchestration | ReAct agents, tool-calling agents |
| Memory | Context preservation | Message history, custom state |
| Retrievers | Information access | Vector retrievers, web retrievers |
| Document Processing | Data ingestion | Loaders, splitters, transformers |
| Vector Stores | Semantic search | Chroma, Pinecone, FAISS |

### Common Architectural Patterns

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

supervisor = create_agent(
    model="gpt-4.1",
    tools=[researcher.as_tool(), writer.as_tool()],
    name="supervisor",
)
```

## Key APIs

| API | Purpose |
|-----|---------|
| `create_agent()` | Create agent with runtime support |
| `ToolRuntime.get()` | Access runtime in tools |
| `runtime.context` | Access injected context values |
| `runtime.store` | Access persistent key-value store |
| `get_stream_writer()` | Get stream writer for custom updates |
| `BaseStore` | Base class for store implementations |

## Best Practices

- Define context schemas as dataclasses for type safety
- Use runtime dependency injection instead of global state or hardcoded values
- Access the store for user-specific data that persists across conversations
- Keep context schemas focused - include only what tools and middleware need
- Use the stream writer for long-running operations to provide progress feedback
- Test tools by mocking the runtime context rather than real dependencies
- Separate concerns across architectural layers - avoid mixing retrieval logic with generation
- Use the agent pattern (tools + model) rather than building custom chains for most use cases
