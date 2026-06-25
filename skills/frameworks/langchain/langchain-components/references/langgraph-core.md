# LangGraph Core

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core capabilities](#core-capabilities)
- [Two APIs](#two-apis)
- [Graph API](#graph-api)
- [Functional API](#functional-api)
- [Quickstart: calculator agent](#quickstart-calculator-agent)
- [Workflows and Agents](#workflows-and-agents)
- [Thinking in LangGraph](#thinking-in-langgraph)
- [Graph migrations](#graph-migrations)
- [Key APIs](#key-apis)
- [Best practices](#best-practices)

## Overview

LangGraph is a low-level orchestration framework for building stateful agents and workflows. It models a workflow as a graph made of three parts: State, Nodes, and Edges. Execution uses message passing inspired by Google's Pregel and proceeds in discrete "super-steps", in which active nodes run and pass messages to their recipients.

Companies such as Klarna, Replit, and Elastic use it in production. Its design draws on Pregel, Apache Beam, and NetworkX. LangGraph does not require LangChain.

## Installation

```bash
pip install -U langgraph
# or
uv add langgraph
```

## Core capabilities

1. **Durable execution**: agents survive failures and resume from where they were interrupted
2. **Human-in-the-loop**: inspect and modify state at any point
3. **Memory**: short-term and long-term storage
4. **Debugging support**: LangSmith integration for visualization and tracing
5. **Production deployment**: scalable infrastructure for stateful workflows

## Two APIs

LangGraph has two APIs that share the same runtime:

| Aspect | Graph API | Functional API |
|--------|-----------|----------------|
| Control flow | Explicit graph paradigm | Standard Python constructs |
| State management | Requires State declaration and reducers | Function-scoped, no explicit declaration |
| Checkpointing | New checkpoint after each superstep | Results saved to existing checkpoint |
| Visualization | Easy graph visualization | Not supported (dynamic runtime graph) |
| Best for | Complex workflows, team environments | Minimal changes to existing code |

## Graph API

### State definition

State is a shared data structure holding the application's current snapshot. Define it with one of:

- **TypedDict** (primary approach)
- **Dataclass** (for default values)
- **Pydantic BaseModel** (for recursive data validation, lower performance)

```python
from typing import TypedDict, Annotated
from operator import add

class State(TypedDict):
    foo: int
    bar: Annotated[list[str], add]  # Uses reducer to append
```

#### Multiple schemas pattern

```python
class InputState(TypedDict):
    user_input: str

class OutputState(TypedDict):
    graph_output: str

class OverallState(TypedDict):
    foo: str
    user_input: str
    graph_output: str

builder = StateGraph(
    OverallState,
    input_schema=InputState,
    output_schema=OutputState
)
```

#### Messages in state

```python
from langgraph.graph.message import add_messages

class GraphState(TypedDict):
    messages: Annotated[list[AnyMessage], add_messages]
```

The `add_messages` reducer tracks message IDs, so it can update existing messages as well as append new ones. `MessagesState` is a prebuilt state with this setup.

### Reducers

Each state key has its own reducer function that decides how updates are applied. By default a key is overwritten. Using `operator.add` appends to lists:

```python
from operator import add

class State(TypedDict):
    foo: int                            # Overwrites on update
    bar: Annotated[list[str], add]      # Appends on update
```

### Nodes

Nodes are Python functions (sync or async) that hold the agent logic. They take state as input and return a state update.

```python
def plain_node(state: State):
    return state

def node_with_runtime(state: State, runtime: Runtime[Context]):
    print("In node: ", runtime.context.user_id)
    return {"results": f"Hello, {state['input']}!"}

def node_with_config(state: State, config: RunnableConfig):
    print("In node with thread_id: ", config["configurable"]["thread_id"])
    return {"results": f"Hello, {state['input']}!"}

builder.add_node("plain_node", plain_node)
builder.add_node("node_with_runtime", node_with_runtime)
builder.add_node("node_with_config", node_with_config)
```

#### Special nodes

```python
from langgraph.graph import START, END

graph.add_edge(START, "node_a")   # Entry point
graph.add_edge("node_a", END)     # Terminal node
```

#### Node caching

```python
from langgraph.cache.memory import InMemoryCache
from langgraph.types import CachePolicy

builder.add_node(
    "expensive_node",
    expensive_node,
    cache_policy=CachePolicy(ttl=3)
)

graph = builder.compile(cache=InMemoryCache())
```

### Edges

#### Normal edges

```python
graph.add_edge("node_a", "node_b")
```

#### Conditional edges

```python
graph.add_conditional_edges("node_a", routing_function)

# With mapping
graph.add_conditional_edges(
    "node_a",
    routing_function,
    {True: "node_b", False: "node_c"}
)
```

#### Entry points

```python
from langgraph.graph import START

graph.add_edge(START, "node_a")                       # Fixed entry
graph.add_conditional_edges(START, routing_function)   # Conditional entry
```

Multiple outgoing edges execute destination nodes in parallel during the next super-step.

### Send API (map-reduce)

```python
from langgraph.types import Send

def continue_to_jokes(state: OverallState):
    return [Send("generate_joke", {"subject": s}) for s in state['subjects']]

graph.add_conditional_edges("node_a", continue_to_jokes)
```

### Command

Combines a state update with control flow:

```python
from langgraph.types import Command

def my_node(state: State) -> Command[Literal["my_other_node"]]:
    return Command(
        update={"foo": "bar"},
        goto="my_other_node"
    )
```

**Command parameters:**
- `update`: state changes
- `goto`: navigate to specific nodes
- `graph`: target the parent graph from a subgraph
- `resume`: provide a value after an interrupt

### Graph compilation

```python
graph = graph_builder.compile(...)
```

Compilation checks the graph structure and sets runtime arguments such as checkpointers and breakpoints. It is required before execution.

### Runtime context

```python
from dataclasses import dataclass

@dataclass
class ContextSchema:
    llm_provider: str = "openai"

graph = StateGraph(State, context_schema=ContextSchema)

# Pass context during invocation
graph.invoke(inputs, context={"llm_provider": "anthropic"})

# Access in nodes
def node_a(state: State, runtime: Runtime[ContextSchema]):
    llm = get_llm(runtime.context.llm_provider)
```

### Recursion limit

Default is 1000 steps (since v1.0.6). Exceeding raises `GraphRecursionError`.

```python
graph.invoke(inputs, config={"recursion_limit": 5})
```

#### RemainingSteps managed value

```python
from langgraph.managed import RemainingSteps

class State(TypedDict):
    remaining_steps: RemainingSteps

def reasoning_node(state: State) -> dict:
    remaining = state["remaining_steps"]
    if remaining <= 2:
        return {"messages": ["Approaching limit, wrapping up..."]}
    return {"messages": ["thinking..."]}
```

#### Available metadata

```python
metadata = config["metadata"]
print(metadata['langgraph_step'])             # Current step
print(metadata['langgraph_node'])             # Current node
print(metadata['langgraph_triggers'])         # What triggered execution
print(metadata['langgraph_path'])             # Execution path
print(metadata['langgraph_checkpoint_ns'])    # Checkpoint namespace
```

### Graph composition patterns

**Sequences:** Chain nodes linearly using `add_sequence()` or manual `add_edge()` calls.

**Parallel execution:** Fan-out/fan-in patterns execute nodes concurrently within supersteps.

**Conditional branching:** Use `add_conditional_edges()` to route based on state values.

**Deferred execution:** Set `defer=True` to delay execution until all pending tasks complete (useful for map-reduce with uneven branches).

### Overwrite type

Bypass reducers and replace a state value directly:

```python
from langgraph.types import Overwrite
# or use "__overwrite__" JSON key
```

### Retry policies

```python
from langgraph.types import RetryPolicy

builder.add_node("my_node", my_node, retry=RetryPolicy(max_attempts=3))
```

### Async support

```python
async def my_node(state: State):
    result = await some_async_call()
    return {"result": result}

await graph.ainvoke(inputs)
# or
async for chunk in graph.astream(inputs):
    print(chunk)
```

### Visualization

Render a graph as a Mermaid diagram or as a PNG using Graphviz:

```python
graph.get_graph().draw_mermaid_png()
```

## Functional API

### Entrypoint

The `@entrypoint` decorator marks a function as the workflow starting point:

```python
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver

@entrypoint(checkpointer=InMemorySaver())
def my_workflow(inputs: dict) -> int:
    value = inputs["value"]
    result = my_task(value).result()
    return result
```

#### Injectable parameters

| Parameter | Purpose |
|-----------|---------|
| `previous` | Prior checkpoint state for the given thread |
| `store` | BaseStore instance for long-term memory |
| `writer` | StreamWriter for async Python < 3.11 |
| `config` | Runtime configuration |

#### Short-term memory with `previous`

```python
@entrypoint(checkpointer=checkpointer)
def my_workflow(inputs: dict, *, previous=None) -> int:
    # previous holds the return value from the prior invocation on the same thread
    pass
```

Use `entrypoint.final(value=return_val, save=saved_val)` to separate the returned value from the value saved to the checkpoint.

### Tasks

The `@task` decorator marks a function as a unit of work that returns a future-like object:

```python
@task
def add_one(x: int) -> int:
    return x + 1

# Inside an entrypoint
result = add_one(5).result()  # Synchronous
# or
result = await add_one(5)      # Async
```

#### When to use tasks

- Checkpointing long-running operations
- Human-in-the-loop workflows (encapsulating randomness)
- Parallel I/O-bound operations
- Observability and monitoring
- Retryable work

#### Parallel execution

```python
futures = [add_one(i) for i in numbers]
return [f.result() for f in futures]
```

### Design requirements

**Serialization:** Entrypoint inputs and outputs and task outputs must be JSON-serializable.

**Determinism:** Put randomness inside tasks so a resumed workflow follows the same execution sequence.

**Idempotency:** Make task operations idempotent so re-execution does not duplicate API calls.

**Side effects:** Put side effects (file writes, emails) in tasks so they are not repeated on resumption.

### Entrypoint composition

Entrypoints can call other entrypoints. A child entrypoint inherits its parent's checkpointer.

### Task caching

```python
@task(cache_policy=CachePolicy(ttl=120))
def my_task(x: int) -> int:
    return x + 1
```

## Quickstart: calculator agent

### Graph API approach

```python
from langchain_anthropic import ChatAnthropic
from langgraph.graph import StateGraph, MessagesState, START, END

# 1. Define tools
@tool
def multiply(a: int, b: int) -> int:
    """Multiply a and b."""
    return a * b

@tool
def add(a: int, b: int) -> int:
    """Add a and b."""
    return a + b

@tool
def divide(a: int, b: int) -> float:
    """Divide a by b."""
    return a / b

tools = [multiply, add, divide]
tools_by_name = {tool.name: tool for tool in tools}

# 2. Model with tools
model = ChatAnthropic(model="claude-sonnet-4-6")
model_with_tools = model.bind_tools(tools)

# 3. State
class State(MessagesState):
    llm_calls: int

# 4. LLM node
def llm_call(state: State):
    return {
        "messages": [model_with_tools.invoke(
            [{"role": "system", "content": "You are a helpful assistant."}]
            + state["messages"]
        )],
        "llm_calls": state.get("llm_calls", 0) + 1,
    }

# 5. Tool node
def tool_node(state: State):
    result_messages = []
    for tool_call in state["messages"][-1].tool_calls:
        tool = tools_by_name[tool_call["name"]]
        result = tool.invoke(tool_call["args"])
        result_messages.append(
            ToolMessage(content=str(result), tool_call_id=tool_call["id"])
        )
    return {"messages": result_messages}

# 6. Routing
def should_continue(state: State):
    if state["messages"][-1].tool_calls:
        return "tool_node"
    return END

# 7. Build graph
builder = StateGraph(State)
builder.add_node("llm_call", llm_call)
builder.add_node("tool_node", tool_node)
builder.add_edge(START, "llm_call")
builder.add_conditional_edges("llm_call", should_continue)
builder.add_edge("tool_node", "llm_call")
graph = builder.compile()
```

### Functional API approach

```python
from langgraph.func import entrypoint, task

@task
def call_llm(messages):
    return model_with_tools.invoke(
        [{"role": "system", "content": "You are a helpful assistant."}]
        + messages
    )

@task
def call_tool(tool_call):
    tool = tools_by_name[tool_call["name"]]
    result = tool.invoke(tool_call["args"])
    return ToolMessage(content=str(result), tool_call_id=tool_call["id"])

@entrypoint()
def agent(messages):
    llm_calls = 0
    while True:
        response = call_llm(messages).result()
        messages = messages + [response]
        llm_calls += 1
        if not response.tool_calls:
            break
        tool_results = [call_tool(tc).result() for tc in response.tool_calls]
        messages = messages + tool_results
    return {"messages": messages, "llm_calls": llm_calls}
```

## Workflows and Agents

### Workflow patterns

| Pattern | Description | Use case |
|---------|-------------|----------|
| Prompt chaining | Sequential LLM calls, each processing the previous output | Document translation, content verification |
| Parallelization | LLMs work on tasks at the same time | Speed, confidence validation |
| Routing | Send inputs to context-specific tasks | Different content types |
| Orchestrator-worker | Orchestrator breaks up the task, workers execute | Complex multi-part tasks |
| Evaluator-optimizer | One LLM generates, another evaluates | Translation refinement |

### Agents

Agents run in a continuous feedback loop and suit problems whose steps cannot be predicted:

```python
@tool
def multiply(a: int, b: int) -> int:
    """Multiply a and b."""
    return a * b
```

An agent receives tool definitions and decides on its own which to call to reach its goal.

## Thinking in LangGraph

### Five-step development process

1. **Map the workflow as discrete steps**: break the process into individual nodes and sketch the connections
2. **Identify operation types**: LLM steps, data steps, action steps, user input steps
3. **Design the state structure**: store raw data, not formatted text, and format prompts inside nodes
4. **Build node functions**: take the current state and return updates
5. **Wire the nodes together**: keep the graph minimal, with only the edges you need

### Error handling strategies

| Error type | Handler | Strategy |
|-----------|---------|----------|
| Transient (network/rate limits) | System | Retry policies |
| LLM-recoverable | LLM | Store error, loop back |
| User-fixable | Human | Use `interrupt()` |
| Unexpected | Developer | Bubble up |

### Node granularity trade-offs

Smaller nodes give you:
- Better isolation of external service failures
- Visible intermediate state for debugging
- Independent retry configuration per operation type
- Easier testing and reuse

## Graph migrations

LangGraph supports topology changes while keeping checkpointed state:
- Threads at the end of the graph: all changes supported
- Interrupted threads: all changes except renaming or removing the interrupted nodes
- State keys: adding and removing are fully backwards and forwards compatible
- Renamed keys: lose their saved state in existing threads

## Key APIs

| API | Purpose |
|-----|---------|
| `StateGraph` | Build graph with typed state |
| `MessagesState` | Prebuilt state for LLM conversations |
| `START`, `END` | Entry and terminal nodes |
| `Command` | State update and control flow in one return value |
| `Send` | Dynamic routing for map-reduce |
| `@entrypoint` | Functional API workflow entry |
| `@task` | Functional API work unit |
| `RetryPolicy` | Configurable retry behavior |
| `CachePolicy` | Node/task result caching |
| `Runtime` | Access context and store in nodes |
| `RunnableConfig` | Thread ID, metadata access |

## Best practices

- Store raw data in state, not formatted text
- Format prompts inside nodes
- Use `Command` objects for routing decisions within nodes
- Call `interrupt()` first in nodes that need human input
- Design side effects as idempotent operations
- Put non-deterministic code inside tasks or nodes
- Use `RetryPolicy` for transient failures
- Compile with `MemorySaver` checkpointer for persistence
- Use `thread_id` for resumable execution
