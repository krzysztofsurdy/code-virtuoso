# Deep Agents

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Core components](#core-components)
- [Models](#models)
- [Subagents](#subagents)
- [Skills](#skills)
- [Human-in-the-loop](#human-in-the-loop)
- [Long-term memory](#long-term-memory)
- [Sandboxes](#sandboxes)
- [Context management](#context-management)
- [Research agent example](#research-agent-example)
- [Best practices](#best-practices)

## Overview

Deep Agents is a framework for building LLM-powered agents with built-in planning, file management, subagents, and long-term memory. It is built on LangChain's core components and runs on LangGraph. Its "agent harness" bundles planning, a virtual filesystem, task delegation, context management, code execution, and human-in-the-loop support.

## Installation

```bash
pip install deepagents
```

## Quick start

```python
from deepagents import create_deep_agent

def get_weather(city: str) -> str:
    """Get weather for a given city."""
    return f"It's always sunny in {city}!"

agent = create_deep_agent(
    tools=[get_weather],
    system_prompt="You are a helpful assistant",
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "what is the weather in sf"}]}
)
```

## Core components

### Planning (write_todos)

The built-in `write_todos` tool lets an agent break a complex task into discrete steps, each with one of three statuses: `pending`, `in_progress`, or `completed`. It suits long-running, multi-step tasks.

### Virtual filesystem

A configurable virtual filesystem provides these file operations:

| Tool | Purpose |
|---|---|
| `ls` | Lists directory contents with metadata |
| `read_file` | Reads file contents with line numbers; supports images |
| `write_file` | Creates new files |
| `edit_file` | Performs string replacements in files |
| `glob` | Finds files matching patterns |
| `grep` | Searches file contents with multiple output modes |
| `execute` | Runs shell commands (sandbox backends only) |

### Pluggable filesystem backends

| Backend | Description |
|---|---|
| StateBackend | In-memory storage (default) |
| FilesystemBackend | Local disk storage |
| StoreBackend | LangGraph Store for persistence |
| Sandbox backends | Modal, Daytona, Runloop |
| CompositeBackend | Routes paths to different backends |

## Models

Deep agents work with any LangChain chat model that supports tool calling.

### String-based model selection

```python
agent = create_deep_agent(model="openai:gpt-5.3-codex")
```

### Advanced configuration

```python
from langchain.chat_models import init_chat_model
from deepagents import create_deep_agent

model = init_chat_model(
    model="anthropic:claude-sonnet-4-6",
    thinking={"type": "enabled", "budget_tokens": 10000},
)
agent = create_deep_agent(model=model)
```

### Direct provider instantiation

```python
from langchain_anthropic import ChatAnthropic
from deepagents import create_deep_agent

model = ChatAnthropic(
    model="claude-sonnet-4-6",
    thinking={"type": "enabled", "budget_tokens": 10000},
)
agent = create_deep_agent(model=model)
```

## Subagents

Subagents let a deep agent delegate work without cluttering its own context. Detailed tool work stays inside the subagent, and the main agent receives only the final result, not the intermediate outputs.

### When to use subagents

- Multi-step tasks that would clutter the main agent's context
- Specialized domains that need custom instructions
- Tasks that need a different model
- High-level coordination

### When not to use

- Simple, single-step tasks
- Cases where the intermediate context is essential
- Cases where the overhead outweighs the benefit

### SubAgent configuration

```python
research_subagent = {
    "name": "research-agent",
    "description": "Used to research more in depth questions",
    "system_prompt": "You are a great researcher",
    "tools": [internet_search],
    "model": "openai:gpt-5.2",
}

agent = create_deep_agent(
    model="claude-sonnet-4-6",
    subagents=[research_subagent]
)
```

Required fields:
- `name` - unique identifier used by main agent when calling `task()` tool
- `description` - specific, action-oriented explanation
- `system_prompt` - custom instructions (does not inherit from main agent)
- `tools` - required tool list (does not inherit from main agent)

Optional fields:
- `model` - override main agent's model (uses parent model by default)
- `middleware` - custom logging or rate limiting (no inheritance)
- `interrupt_on` - human-in-the-loop configuration (inherits from main agent)
- `skills` - skill source paths loaded independently; full isolation from parent

### CompiledSubAgent

For complex workflows built with LangGraph:

```python
from deepagents import CompiledSubAgent

custom_subagent = CompiledSubAgent(
    name="data-analyzer",
    description="Specialized agent for complex data analysis tasks",
    runnable=custom_graph  # must call .compile()
)
```

### General-purpose subagent

Available automatically unless overridden. It inherits the main agent's system prompt, tools, model, and skills.

```python
agent = create_deep_agent(
    model="claude-sonnet-4-6",
    subagents=[{
        "name": "general-purpose",
        "description": "General-purpose agent for research",
        "system_prompt": "You are a general-purpose assistant.",
        "tools": [internet_search],
        "model": "openai:gpt-4o",
    }]
)
```

### Multi-subagent pattern

1. Data-collector subagent: gathers information
2. Data-analyzer subagent: extracts insights
3. Report-writer subagent: formats the output

The main agent coordinates and delegates to the right specialist.

### Subagent context

Parent context propagates to all subagents. Use namespaced keys for per-subagent configuration:

```python
{
    "context": {
        "user_id": "user-123",           # shared
        "researcher:max_depth": 3,       # researcher-specific
        "fact-checker:strict_mode": True  # fact-checker-specific
    }
}
```

### Subagent best practices

- Use specific, action-oriented descriptions
- Include tool usage and output formatting guidance in system prompts
- Restrict tools to what the task needs, for focus and security
- Assign models according to task strengths
- Instruct subagents to return summaries only, not raw data

## Skills

Skills are reusable, specialized workflows that follow the Agent Skills specification. They use progressive disclosure: an agent reads a skill's details only when the task calls for it.

### SKILL.md format

```yaml
---
name: skill-name
description: Task-relevant summary (max 1,024 characters)
license: MIT
allowed-tools: [read_file, write_file]
---

# Skill Instructions
...
```

### Configuration methods

**StateBackend (default):** Pass skill files via `invoke(files={...})` using `create_file_data()`.

**StoreBackend:** Store skills in `InMemoryStore` under namespace `("filesystem",)`.

**FilesystemBackend:** Load skills from disk relative to `root_dir`.

### Skills vs memory

| Aspect | Skills | Memory |
|---|---|---|
| Loading | On-demand when relevant | Always loaded |
| File | `SKILL.md` | `AGENTS.md` |
| Use case | Large, task-specific contexts | Always-relevant project conventions |

## Human-in-the-loop

The `interrupt_on` parameter pauses execution for manual review, using LangGraph's interrupt mechanism.

### Configuration

```python
from langgraph.checkpoint.memory import MemorySaver

agent = create_deep_agent(
    model="claude-sonnet-4-6",
    interrupt_on={
        "delete_file": True,                                    # all decisions
        "read_file": False,                                     # no interrupts
        "send_email": {"allowed_decisions": ["approve", "reject"]}  # limited
    },
    checkpointer=MemorySaver()  # required for HITL
)
```

### Decision types

| Type | Action |
|---|---|
| `approve` | Execute with original arguments |
| `edit` | Modify arguments before execution |
| `reject` | Skip tool execution entirely |

### Handling interrupts

```python
from langgraph.types import Command

# Resume after interrupt
result = agent.invoke(
    Command(resume={"decisions": [{"type": "approve"}]}),
    config={"configurable": {"thread_id": "thread-1"}}
)
```

Decisions must match `action_requests` order when multiple tools require approval.

## Long-term memory

Deep agents keep memory across conversation threads by using a `CompositeBackend` that routes specific filesystem paths to durable storage.

### Setup

```python
from deepagents import create_deep_agent
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend
from langgraph.store.memory import InMemoryStore
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()

def make_backend(runtime):
    return CompositeBackend(
        default=StateBackend(runtime),
        routes={"/memories/": StoreBackend(runtime)}
    )

agent = create_deep_agent(
    store=InMemoryStore(),
    backend=make_backend,
    checkpointer=checkpointer
)
```

### Storage types

| Type | Lifetime | Backend | Example path |
|---|---|---|---|
| Short-term (transient) | Single thread | Agent state | `/notes.txt` |
| Long-term (persistent) | Cross-thread | LangGraph Store | `/memories/preferences.txt` |

### Cross-thread access

```python
import uuid

config1 = {"configurable": {"thread_id": str(uuid.uuid4())}}
agent.invoke({
    "messages": [{"role": "user", "content": "Save preferences to /memories/preferences.txt"}]
}, config=config1)

config2 = {"configurable": {"thread_id": str(uuid.uuid4())}}
agent.invoke({
    "messages": [{"role": "user", "content": "What are my preferences?"}]
}, config=config2)
```

### External access (LangSmith)

```python
from langgraph_sdk import get_client

client = get_client(url="<DEPLOYMENT_URL>")

item = await client.store.get_item(
    (assistant_id, "filesystem"),
    "/preferences.txt"
)

await client.store.put_item(
    (assistant_id, "filesystem"),
    "/preferences.txt",
    {"content": ["line 1"], "created_at": "...", "modified_at": "..."}
)
```

### Store implementations

| Store | Use case |
|---|---|
| `InMemoryStore` | Development (data lost on restart) |
| `PostgresStore` | Production (persistent) |

### FileData schema

```python
from deepagents.backends.utils import create_file_data

file_data = create_file_data("Hello\nWorld")
# {"content": ["Hello", "World"], "created_at": "...", "modified_at": "..."}
```

## Sandboxes

Sandboxes are isolated execution environments where an agent can run code, use a filesystem, and execute shell commands without putting the host system at risk.

### Integration patterns

| Pattern | Description | Recommended |
|---|---|---|
| Agent in Sandbox | Agent runs inside sandbox | No (secrets risk) |
| Sandbox as Tool | Agent calls sandbox tools via API | Yes |

### Supported providers

| Provider | Package | Use case |
|---|---|---|
| Modal | `langchain-modal` | ML/AI workloads with GPU access |
| Daytona | `langchain-daytona` | TypeScript/Python, fast cold starts |
| Runloop | `langchain-runloop` | Disposable devboxes |

### Modal example

```python
import modal
from langchain_anthropic import ChatAnthropic
from deepagents import create_deep_agent
from langchain_modal import ModalSandbox

app = modal.App.lookup("your-app")
modal_sandbox = modal.Sandbox.create(app=app)
backend = ModalSandbox(sandbox=modal_sandbox)

agent = create_deep_agent(
    model=ChatAnthropic(model="claude-sonnet-4-20250514"),
    system_prompt="You are a Python coding assistant with sandbox access.",
    backend=backend,
)

try:
    result = agent.invoke({
        "messages": [{
            "role": "user",
            "content": "Create a small Python package and run pytest",
        }]
    })
finally:
    modal_sandbox.terminate()
```

### File transfer APIs

```python
# Upload files to sandbox
backend.upload_files([
    ("/src/index.py", b"print('Hello')\n"),
    ("/pyproject.toml", b"[project]\nname = 'my-app'\n"),
])

# Download files from sandbox
results = backend.download_files(["/src/index.py", "/output.txt"])
for result in results:
    if result.content is not None:
        print(f"{result.path}: {result.content.decode()}")
```

### Security considerations

**Never put secrets inside a sandbox.** API keys, tokens, and database credentials can be read and exfiltrated by a context-injected agent.

Safe alternatives:
1. Keep secrets in external tools outside sandbox (recommended)
2. Use network proxy that injects credentials before forwarding

### Lifecycle management

Always clean up sandbox resources:
- Modal: `modal_sandbox.terminate()`
- Runloop: `devbox.shutdown()`
- Daytona: `sandbox.stop()`

## Context management

### Runtime context compression

**Offloading:** When tool inputs exceed 20,000 tokens (configurable), older tool calls are truncated and replaced with a file pointer and a preview.

**Summarization:** At 85% of `max_input_tokens`, an LLM writes a structured summary covering intent, artifacts, and next steps. The original conversation is kept on the filesystem.

### Input context order

1. Custom system prompt
2. Base agent prompt
3. To-do list instructions
4. Memory guidelines
5. Skills information
6. Filesystem documentation
7. Subagent instructions
8. Middleware prompts
9. Human-in-the-loop settings
10. Local context

## Research agent example

```python
from deepagents import create_deep_agent
from tavily import TavilyClient

tavily_client = TavilyClient()

def internet_search(query: str, max_results: int = 5, topic: str = "general") -> str:
    """Search the internet for information."""
    results = tavily_client.search(
        query=query,
        max_results=max_results,
        topic=topic,
        include_raw_content=True
    )
    return str(results)

agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    tools=[internet_search],
    system_prompt="You are an expert researcher. Use tools to gather information.",
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Research quantum computing advances in 2025"}]
})
print(result["messages"][-1].content)
```

## Best practices

- Use subagents for multi-step tasks to prevent context bloat
- Assign different models to subagents based on task requirements
- Configure human-in-the-loop for destructive operations (file deletion, external API calls)
- Use CompositeBackend to route `/memories/` paths to persistent storage
- Prefer "Sandbox as Tool" pattern over "Agent in Sandbox"
- Never put secrets inside sandboxes
- Organize long-term memory with descriptive paths
- Document memory structure in system prompts
- Configure TTL on sandboxes for automatic cleanup
- Use skills for large task-specific contexts; use memory for always-relevant conventions
