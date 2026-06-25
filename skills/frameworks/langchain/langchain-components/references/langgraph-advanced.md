# LangGraph advanced features

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Subgraphs](#subgraphs)
- [Time travel](#time-travel)
- [Streaming](#streaming)
- [Graph API advanced usage](#graph-api-advanced-usage)
- [Functional API advanced usage](#functional-api-advanced-usage)
- [Application structure for deployment](#application-structure-for-deployment)
- [Key APIs](#key-apis)
- [Best practices](#best-practices)

## Overview

This reference covers subgraphs for modular composition, time travel for debugging, streaming for real-time updates, and application structure for deployment.

## Installation

```bash
pip install -U langgraph
```

## Subgraphs

Subgraphs are graphs used as nodes inside other graphs. Use them to build multi-agent systems, reuse a set of nodes across graphs, or split development across teams.

### Pattern 1: call inside a node function

Use when the parent and subgraph have different state schemas or the state needs transforming:

```python
def call_subgraph(state: ParentState):
    subgraph_output = subgraph.invoke({"bar": state["foo"]})
    return {"foo": subgraph_output["bar"]}

builder.add_node("node_1", call_subgraph)
```

### Pattern 2: add as a node directly

Use when the parent and subgraph share state keys:

```python
builder.add_node("node_1", subgraph)
```

### Subgraph persistence options

| Setting | `checkpointer=False` | `checkpointer=None` (default) | `checkpointer=True` |
|---------|----------------------|-------------------------------|---------------------|
| Interrupts (HITL) | No | Yes | Yes |
| Multi-turn memory | No | No | Yes |
| Different subgraphs | Yes | Yes | Caution |
| Same subgraph multiple times | Yes | Yes | No |
| State inspection | No | Limited | Yes |
| Durable execution | No | Yes | Yes |

#### Stateless without interrupts (`checkpointer=False`)

- No durable execution
- Runs like a normal function call
- No checkpointing overhead
- Cannot recover from a crash mid-run

#### Stateless with interrupts (`checkpointer=None`, the default)

- Recommended for most applications, including multi-agent systems
- Supports `interrupt()` for human-in-the-loop
- Durable execution available
- Each invocation starts fresh (no multi-turn memory)
- Supports parallel tool calls safely

#### Stateful (`checkpointer=True`)

- The subagent remembers earlier interactions across calls on the same thread
- Each call picks up where the last one left off
- Does not support parallel tool calls to the same subgraph (checkpoint namespace conflicts)

### Namespace isolation

When you have several different stateful subgraphs, wrap each in its own `StateGraph` with unique node names:

```python
# Each subgraph gets a unique namespace
builder_a = StateGraph(StateA)
# ... define nodes ...
subgraph_a = builder_a.compile()

builder_b = StateGraph(StateB)
# ... define nodes ...
subgraph_b = builder_b.compile()

# Add to parent
parent_builder.add_node("agent_a", subgraph_a)
parent_builder.add_node("agent_b", subgraph_b)
```

### State inspection

```python
subgraph_state = graph.get_state(config, subgraphs=True).tasks[0].state
```

The subgraph must be statically discoverable (added directly as a node or called within a node function). This does not work when the subgraph is called inside a tool.

### Streaming subgraph outputs

```python
for chunk in graph.stream({"foo": "foo"}, subgraphs=True, stream_mode="updates"):
    print(chunk)
```

The output includes namespace tuples that show the graph hierarchy.

### Multi-level subgraphs

For nested hierarchies (parent -> child -> grandchild) with different state schemas, use node wrapper functions. Each level transforms state before invoking the next.

### Key constraints

- The parent graph needs a checkpointer for subgraph persistence features
- Stateful subgraphs do not support parallel tool calls to the same instance
- State inspection needs the subgraph structure to be statically discoverable

## Time travel

Time travel lets you inspect how a run reached its result by resuming execution from an earlier checkpoint, optionally with modified state.

### Use cases

- **Understanding reasoning**: analyze the steps that led to a good outcome
- **Debugging mistakes**: find where an error came from
- **Exploring alternatives**: try different execution paths

### Workflow

#### 1. Execute the graph

```python
from langgraph.checkpoint.memory import InMemorySaver

checkpointer = InMemorySaver()
graph = builder.compile(checkpointer=checkpointer)

config = {"configurable": {"thread_id": "1"}}
result = graph.invoke({"topic": "dogs"}, config=config)
```

#### 2. Identify a checkpoint

```python
# Retrieve execution history (most recent first)
all_states = list(graph.get_state_history(config))

# Find checkpoint of interest
target_state = all_states[2]  # Example: third checkpoint
target_config = target_state.config
```

#### 3. Modify state (optional)

```python
# Create new checkpoint with modified state
graph.update_state(target_config, {"topic": "chickens"})
```

#### 4. Resume execution

```python
# Resume from specific checkpoint
config_with_checkpoint = {
    "configurable": {
        "thread_id": "1",
        "checkpoint_id": "0c62ca34-ac19-445d-bbb0-5b4984975b2a"
    }
}
result = graph.invoke(None, config=config_with_checkpoint)
```

### Key methods

| Method | Purpose |
|--------|---------|
| `get_state_history(config)` | Retrieve all checkpoints for a thread |
| `update_state(config, values)` | Create new checkpoint with modified state |
| `invoke(None, config)` | Resume from checkpoint |
| `get_state(config)` | Get current state snapshot |

## Streaming

Streaming keeps LLM applications responsive by showing output progressively, before the full response is ready.

### Stream modes

| Mode | Purpose | Output |
|------|---------|--------|
| `values` | Full state after each step | Complete state dict |
| `updates` | State changes per step | Node name with changes |
| `custom` | User-defined data from nodes | Custom data |
| `messages` | LLM tokens with metadata | 2-tuples (chunk, metadata) |
| `debug` | Full execution info | Detailed debug data |

### Basic usage

```python
# Sync
for chunk in graph.stream(inputs, stream_mode="updates"):
    print(chunk)

# Async
async for chunk in graph.astream(inputs, stream_mode="updates"):
    print(chunk)
```

### Graph state streaming

**Updates mode** returns node names with state modifications:

```python
for chunk in graph.stream({"topic": "ice cream"}, stream_mode="updates"):
    print(chunk)
# Output: {'refineTopic': {'topic': 'ice cream and cats'}}
```

**Values mode** returns complete state snapshots after each step.

### Subgraph streaming

```python
for chunk in graph.stream({"foo": "foo"}, subgraphs=True, stream_mode="updates"):
    print(chunk)
# Output includes namespace tuples: (namespace_tuple, data)
```

### LLM token streaming

The `messages` mode returns tuples of `(message_chunk, metadata)`:

```python
for msg, metadata in graph.stream(inputs, stream_mode="messages"):
    print(msg.content, end="", flush=True)
```

#### Filtering by tags

```python
joke_model = init_chat_model(model="gpt-4.1-mini", tags=['joke'])

async for msg, metadata in graph.astream(inputs, stream_mode="messages"):
    if metadata["tags"] == ["joke"]:
        print(msg.content, end="|", flush=True)
```

#### Filtering by node

```python
for msg, metadata in graph.stream(inputs, stream_mode="messages"):
    if metadata["langgraph_node"] == "some_node_name":
        print(msg.content)
```

### Custom data streaming

#### From nodes

```python
from langgraph.config import get_stream_writer

def node(state):
    writer = get_stream_writer()
    writer({"custom_key": "Progress update"})
    return {"answer": "data"}
```

#### From tools

```python
@tool
def query_database(query: str) -> str:
    """Query the database."""
    writer = get_stream_writer()
    writer({"data": "Retrieved 0/100 records", "type": "progress"})
    return "answer"
```

Access with `stream_mode="custom"`.

#### Arbitrary LLM integration

```python
from langgraph.config import get_stream_writer

def call_arbitrary_model(state):
    writer = get_stream_writer()
    for chunk in your_custom_streaming_client(state["topic"]):
        writer({"custom_llm_chunk": chunk})
    return {"result": "completed"}
```

### Multiple stream modes

```python
for mode, chunk in graph.stream(inputs, stream_mode=["updates", "custom"]):
    print(f"{mode}: {chunk}")
```

### Disabling streaming

```python
model = init_chat_model("claude-sonnet-4-6", streaming=False)
```

### Async on Python < 3.11

For LLM calls, pass `RunnableConfig` explicitly:

```python
async def call_model(state, config):
    response = await model.ainvoke(
        [{"role": "user", "content": f"Write about {state.topic}"}],
        config,  # Required for streaming context
    )
    return {"joke": response.content}
```

For custom streaming, use `writer` parameter instead of `get_stream_writer()`:

```python
async def generate_joke(state: State, writer: StreamWriter):
    writer({"custom_key": "Streaming custom data"})
    return {"joke": f"About {state['topic']}"}
```

### Debug mode

```python
for chunk in graph.stream({"topic": "ice cream"}, stream_mode="debug"):
    print(chunk)
```

## Graph API advanced usage

### Sequences

```python
builder.add_sequence(["node_a", "node_b", "node_c"])
# equivalent to:
builder.add_edge(START, "node_a")
builder.add_edge("node_a", "node_b")
builder.add_edge("node_b", "node_c")
```

### Parallel execution

Fan-out/fan-in patterns run nodes concurrently:

```python
builder.add_edge(START, "node_a")
builder.add_edge(START, "node_b")  # node_a and node_b run in parallel
builder.add_edge("node_a", "node_c")
builder.add_edge("node_b", "node_c")  # node_c waits for both
```

### Deferred execution

```python
builder.add_node("reduce_node", reduce_func, defer=True)
```

Delays the node until all pending tasks complete. Useful for map-reduce with branches of uneven length.

### Overwrite type

Bypass reducers and replace a state value directly:

```python
from langgraph.types import Overwrite

def my_node(state: State):
    return {"my_list": Overwrite(["fresh", "list"])}
```

### Input/output schema filtering

```python
class InputState(TypedDict):
    user_input: str

class OutputState(TypedDict):
    result: str

class InternalState(TypedDict):
    user_input: str
    result: str
    intermediate: str

builder = StateGraph(InternalState, input_schema=InputState, output_schema=OutputState)
```

## Functional API advanced usage

### Entrypoint composition

```python
@entrypoint(checkpointer=checkpointer)
def parent_workflow(inputs: dict):
    result = child_workflow(inputs).result()
    return result

@entrypoint()  # Inherits parent checkpointer
def child_workflow(inputs: dict):
    return process(inputs)
```

### Graph integration

```python
@entrypoint(checkpointer=checkpointer)
def my_workflow(inputs: dict):
    # Call a compiled graph from functional API
    result = compiled_graph.invoke({"messages": inputs["messages"]})
    return result
```

### Error handling with retry

```python
from langgraph.types import RetryPolicy

@task(retry=RetryPolicy(retry_on=ConnectionError, max_attempts=3))
def call_api(data: dict) -> dict:
    return requests.post(API_URL, json=data).json()
```

### Resumption after failure

Checkpointers keep task results, so a run can continue without recomputing them:

```python
@entrypoint(checkpointer=checkpointer)
def workflow(inputs: dict):
    step1 = task_a(inputs).result()   # Cached if already completed
    step2 = task_b(step1).result()    # Resumes from here on failure
    return step2
```

## Application structure for deployment

### Required components

1. `langgraph.json`: configuration file
2. Graph implementations: application logic
3. Dependency file: `requirements.txt` or `pyproject.toml`
4. `.env` file (optional): environment variables

### Directory structure

```
my-app/
├── my_agent/
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── tools.py
│   │   ├── nodes.py
│   │   └── state.py
│   ├── __init__.py
│   └── agent.py
├── .env
├── requirements.txt
└── langgraph.json
```

### Configuration file (langgraph.json)

```json
{
  "dependencies": ["langchain_openai", "./your_package"],
  "graphs": {
    "my_agent": "./your_package/your_file.py:agent"
  },
  "env": "./.env"
}
```

**Key sections:**
- `dependencies`: required packages and local modules
- `graphs`: maps graph names to file paths and variables (compiled graphs or graph-generating functions)
- `env`: points to the environment variable file
- `dockerfile_lines`: system libraries and binaries (optional)

## Key APIs

| API | Purpose |
|-----|---------|
| `add_node("name", subgraph)` | Add subgraph as node |
| `get_state(config, subgraphs=True)` | Inspect subgraph state |
| `get_state_history(config)` | Retrieve all checkpoints |
| `update_state(config, values)` | Modify state at checkpoint |
| `stream(inputs, stream_mode=...)` | Stream with specified mode |
| `astream(inputs, stream_mode=...)` | Async streaming |
| `get_stream_writer()` | Custom stream writer |
| `add_sequence([...])` | Add sequential node chain |
| `RetryPolicy` | Configure retry behavior |
| `CachePolicy` | Configure result caching |
| `Overwrite` | Bypass state reducers |

## Best practices

- Use `checkpointer=None` (default) for most subgraph scenarios
- Use `checkpointer=True` only when the subagent needs multi-turn memory
- Never use stateful subgraphs with parallel tool calls to the same instance
- Wrap each stateful subgraph in its own `StateGraph` for namespace isolation
- Use time travel for debugging non-deterministic LLM behavior
- Stream with `updates` mode for efficiency and `values` for the complete state
- Use `get_stream_writer()` for custom progress updates
- Pass `RunnableConfig` explicitly in async LLM calls (Python < 3.11)
- Use `stream_mode=["updates", "custom"]` to combine multiple modes
- Structure applications with `langgraph.json` for LangSmith deployment
- Use `defer=True` for map-reduce patterns with uneven branches
- Filter streams by tag or node name to get only the output you need
