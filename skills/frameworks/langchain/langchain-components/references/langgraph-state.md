# LangGraph state management and persistence

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Short-term memory (thread-level persistence)](#short-term-memory-thread-level-persistence)
- [Long-term memory (cross-thread store)](#long-term-memory-cross-thread-store)
- [Checkpoint management](#checkpoint-management)
- [Message management strategies](#message-management-strategies)
- [Serialization and Security](#serialization-and-security)
- [Durable execution](#durable-execution)
- [Interrupts (human-in-the-loop)](#interrupts-human-in-the-loop)
- [Database migration](#database-migration)
- [Key APIs](#key-apis)
- [Best practices](#best-practices)

## Overview

LangGraph manages state through checkpointers (short-term memory), stores (long-term memory), durable execution, and human-in-the-loop interrupts. Together they let agents keep context across interactions, survive failures, and pause for human input.

## Installation

```bash
pip install -U langgraph
# For production persistence:
pip install langgraph-checkpoint-postgres
# or
pip install langgraph-checkpoint-sqlite
```

## Short-term memory (thread-level persistence)

Short-term memory lets an agent track a multi-turn conversation within a thread.

### Basic setup with InMemorySaver

```python
from langgraph.checkpoint.memory import InMemorySaver

checkpointer = InMemorySaver()
graph = builder.compile(checkpointer=checkpointer)
graph.invoke(
    {"messages": [{"role": "user", "content": "hello"}]},
    {"configurable": {"thread_id": "1"}}
)
```

### Production database checkpointers

#### PostgreSQL

```python
from langgraph.checkpoint.postgres import PostgresSaver

DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresSaver.from_conn_string(DB_URI) as checkpointer:
    graph = builder.compile(checkpointer=checkpointer)
```

#### MongoDB

```python
from langgraph.checkpoint.mongodb import MongoDBSaver

with MongoDBSaver.from_conn_string("mongodb://localhost:27017") as checkpointer:
    graph = builder.compile(checkpointer=checkpointer)
```

#### Redis

```python
from langgraph.checkpoint.redis import RedisSaver

with RedisSaver.from_conn_string("redis://localhost:6379") as checkpointer:
    graph = builder.compile(checkpointer=checkpointer)
```

### Checkpointer libraries

| Library | Class | Use case |
|---------|-------|----------|
| `langgraph-checkpoint` | `InMemorySaver` | Development and testing |
| `langgraph-checkpoint-sqlite` | `SqliteSaver` / `AsyncSqliteSaver` | Local development |
| `langgraph-checkpoint-postgres` | `PostgresSaver` / `AsyncPostgresSaver` | Production |
| `langgraph-checkpoint-cosmosdb` | `CosmosDBSaver` / `AsyncCosmosDBSaver` | Azure |

All implement the `BaseCheckpointSaver` interface: `.put()`, `.put_writes()`, `.get_tuple()`, `.list()`.

### Subgraph integration

A checkpointer set on a parent graph propagates to its child subgraphs.

## Long-term memory (cross-thread store)

Long-term memory shares information across threads through the `Store` interface.

### Basic setup

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()
graph = builder.compile(checkpointer=checkpointer, store=store)
```

### Store operations

```python
# Put memory
namespace = ("user_123", "memories")
memory_id = str(uuid.uuid4())
store.put(namespace, memory_id, {"food_preference": "I like pizza"})

# Search memories
memories = store.search(namespace)
memories[-1].dict()  # Returns Item with value, key, namespace, timestamps
```

### Semantic search

```python
from langchain.embeddings import init_embeddings

store = InMemoryStore(
    index={
        "embed": init_embeddings("openai:text-embedding-3-small"),
        "dims": 1536,
        "fields": ["food_preference", "$"]
    }
)

memories = store.search(
    ("user_123", "memories"),
    query="What does the user like to eat?",
    limit=3
)
```

### Accessing the store in nodes

Use the `Runtime` object:

```python
from langgraph.runtime import Runtime

async def call_model(state: MessagesState, runtime: Runtime[Context]):
    user_id = runtime.context.user_id
    namespace = (user_id, "memories")

    # Search memories
    memories = await runtime.store.asearch(
        namespace,
        query=state["messages"][-1].content,
        limit=3
    )

    # Save memory
    await runtime.store.aput(
        namespace,
        str(uuid.uuid4()),
        {"data": "some memory"}
    )
```

## Checkpoint management

### View current state

```python
config = {"configurable": {"thread_id": "1"}}
graph.get_state(config)
```

### View a specific checkpoint

```python
config = {
    "configurable": {
        "thread_id": "1",
        "checkpoint_id": "1ef663ba-28fe-6528-8002-5a559208592c"
    }
}
graph.get_state(config)
```

### View state history

```python
config = {"configurable": {"thread_id": "1"}}
list(graph.get_state_history(config))  # Most recent first
```

### Update state

Updates respect reducer functions defined on channels:

```python
graph.update_state(config, {"foo": 2, "bar": ["b"]})
```

The optional `as_node` parameter controls which node runs next.

### Replay execution from a checkpoint

```python
config = {
    "configurable": {
        "thread_id": "1",
        "checkpoint_id": "0c62ca34-ac19-445d-bbb0-5b4984975b2a"
    }
}
graph.invoke(None, config=config)
```

### Delete checkpoints

```python
checkpointer.delete_thread(thread_id)
```

### Checkpoint contents

A checkpoint (`StateSnapshot`) contains:
- `config`: Associated configuration
- `metadata`: Checkpoint metadata
- `values`: Current state channel values
- `next`: Node names to execute next
- `tasks`: `PregelTask` objects with execution details and error information

## Message management strategies

### Trim messages

```python
from langchain_core.messages.utils import trim_messages, count_tokens_approximately

messages = trim_messages(
    state["messages"],
    strategy="last",
    token_counter=count_tokens_approximately,
    max_tokens=128
)
```

### Delete messages

```python
from langchain.messages import RemoveMessage
from langgraph.graph.message import REMOVE_ALL_MESSAGES

def delete_messages(state):
    return {"messages": [RemoveMessage(id=m.id) for m in state["messages"][:2]]}
```

### Summarization

Keep a running summary, written by a model, to preserve conversation context while using fewer tokens.

## Serialization and Security

### Default serialization

`JsonPlusSerializer` handles most types. For unsupported types:

```python
from langgraph.checkpoint.serde.jsonplus import JsonPlusSerializer

graph.compile(
    checkpointer=InMemorySaver(serde=JsonPlusSerializer(pickle_fallback=True))
)
```

### Encryption

```python
from langgraph.checkpoint.serde.encrypted import EncryptedSerializer
from langgraph.checkpoint.sqlite import SqliteSaver

serde = EncryptedSerializer.from_pycryptodome_aes()  # reads LANGGRAPH_AES_KEY
checkpointer = SqliteSaver(sqlite3.connect("checkpoint.db"), serde=serde)
```

## Durable execution

Durable execution saves workflow progress at key points, so a run can pause and later resume exactly where it left off.

### Core requirements

1. **Persistence layer**: a checkpointer that preserves workflow progress
2. **Thread identifier**: tracks execution history for a specific workflow instance
3. **Task wrapping**: non-deterministic and side-effect operations go inside tasks

### Durability modes

| Mode | Behavior | Trade-off |
|------|----------|-----------|
| `"exit"` | Saves only at completion or interruption | Best performance |
| `"async"` | Async persistence during next step | Balanced |
| `"sync"` | Synchronous saving before next step | Highest durability |

### Determinism on resume

On resume, LangGraph finds the right restart point and replays the steps. Guidelines:
- Wrap side-effect operations (API calls, file writes) in separate tasks
- Put non-deterministic code (random generation) inside tasks or nodes
- Make side effects idempotent

### Resumption scenarios

```python
# Pause via interrupt
result = graph.invoke(inputs, config)

# Resume after interrupt
graph.invoke(Command(resume=value), config)

# Recovery from failure (re-execute with same thread_id)
graph.invoke(None, config)
```

## Interrupts (human-in-the-loop)

Interrupts pause graph execution at specific points so a person can step in.

### How interrupts work

1. Call `interrupt()` with a JSON-serializable value
2. The graph state is checkpointed automatically
3. The interrupt value surfaces under the `__interrupt__` field of the result
4. Resume with `Command(resume=value)` and the same `thread_id`
5. The resume value becomes the return value of the `interrupt()` call

### Requirements

- A checkpointer for state persistence
- A `thread_id` in config
- JSON-serializable payload

### Basic usage

```python
from langgraph.types import interrupt, Command

def approval_node(state: State):
    approved = interrupt("Do you approve this action?")
    return {"approved": approved}

# Initial invocation
config = {"configurable": {"thread_id": "thread-1"}}
result = graph.invoke({"input": "data"}, config=config)

# Check interrupt payload
print(result["__interrupt__"])

# Resume with response
graph.invoke(Command(resume=True), config=config)
```

### Approval workflows

```python
def approval_node(state: ApprovalState) -> Command[Literal["proceed", "cancel"]]:
    decision = interrupt({
        "question": "Approve this action?",
        "details": state["action_details"],
    })
    return Command(goto="proceed" if decision else "cancel")
```

### Review and edit state

```python
def review_node(state: State):
    edited_content = interrupt({
        "instruction": "Review and edit this content",
        "content": state["generated_text"]
    })
    return {"generated_text": edited_content}
```

### Tool call interrupts

```python
@tool
def send_email(to: str, subject: str, body: str):
    response = interrupt({
        "action": "send_email",
        "to": to,
        "subject": subject,
        "body": body,
        "message": "Approve sending this email?"
    })
    if response.get("action") == "approve":
        return f"Email sent to {response.get('to', to)}"
    return "Email cancelled by user"
```

### Input validation loop

```python
def get_age_node(state: State):
    prompt = "What is your age?"
    while True:
        answer = interrupt(prompt)
        if isinstance(answer, int) and answer > 0:
            break
        prompt = f"'{answer}' is not valid. Enter a positive number."
    return {"age": answer}
```

### Multiple simultaneous interrupts

```python
resume_map = {
    i.id: f"answer for {i.value}"
    for i in interrupted_result["__interrupt__"]
}
result = graph.invoke(Command(resume=resume_map), config=config)
```

### Streaming with interrupts

```python
async for metadata, mode, chunk in graph.astream(
    initial_input,
    stream_mode=["messages", "updates"],
    subgraphs=True,
    config=config
):
    if mode == "updates" and "__interrupt__" in chunk:
        interrupt_info = chunk["__interrupt__"][0].value
        user_response = get_user_input(interrupt_info)
        initial_input = Command(resume=user_response)
        break
```

### Static breakpoints (debugging)

```python
# At compile time
graph = builder.compile(
    interrupt_before=["node_a"],
    interrupt_after=["node_b", "node_c"],
    checkpointer=checkpointer,
)

# At runtime
graph.invoke(
    inputs,
    interrupt_before=["node_a"],
    interrupt_after=["node_b"],
    config=config,
)

# Resume
graph.invoke(None, config=config)
```

### Interrupt rules

**Do not wrap `interrupt()` in a bare try/except:**
```python
# BAD - bare except catches interrupt exception
try:
    interrupt("What's your name?")
except Exception as e:
    print(e)

# GOOD - use specific exceptions
interrupt("What's your name?")
try:
    fetch_data()
except NetworkException as e:
    print(e)
```

**Keep the interrupt order consistent** (matching is index-based):
```python
# GOOD - same order every execution
name = interrupt("What's your name?")
age = interrupt("What's your age?")

# BAD - conditional interrupts change ordering
name = interrupt("What's your name?")
if state.get("needs_age"):
    age = interrupt("What's your age?")
```

**Make pre-interrupt operations idempotent** (code before the interrupt re-executes on resume):
```python
# GOOD - idempotent upsert
db.upsert_user(user_id=state["user_id"], status="pending")
approved = interrupt("Approve?")

# GOOD - side effects after interrupt
approved = interrupt("Approve?")
if approved:
    db.create_audit_log(user_id=state["user_id"], action="approved")

# BAD - non-idempotent create before interrupt
audit_id = db.create_audit_log({"user_id": state["user_id"]})  # Duplicates!
approved = interrupt("Approve?")
```

**Pass only JSON-serializable values:**
```python
# GOOD
interrupt("What's your name?")
interrupt({"question": "Details?", "fields": ["name", "email"]})

# BAD
interrupt({"validator": validate_input})      # Cannot serialize
interrupt({"processor": DataProcessor()})     # Cannot serialize
```

**Node re-execution on resume:**
The whole node re-executes from the beginning, not from the interrupt line.

## Database migration

Most database-specific libraries define a `setup()` method on the checkpointer or store instance. Run it before production deployment or during server startup.

## Key APIs

| API | Purpose |
|-----|---------|
| `InMemorySaver` | Development checkpointer |
| `PostgresSaver` | Production checkpointer |
| `InMemoryStore` | Development long-term store |
| `interrupt()` | Pause for human input |
| `Command(resume=...)` | Resume after interrupt |
| `get_state()` | View current thread state |
| `get_state_history()` | View checkpoint history |
| `update_state()` | Modify graph state |
| `Runtime` | Access store and context in nodes |
| `EncryptedSerializer` | Checkpoint encryption |

## Best practices

- Use database-backed checkpointers in production (not InMemorySaver)
- Run migrations before deployment
- Implement semantic search for relevant memory retrieval
- Manage the context window through trimming, deletion, or summarization
- Pass context at invocation time through `context_schema`
- Design task operations as idempotent
- Wrap side effects in tasks for durable execution
- Use `thread_id` consistently for resume operations
- Only pass JSON-serializable values to interrupts
- Place `interrupt()` calls first in nodes when possible
- Never wrap `interrupt()` in try/except blocks
