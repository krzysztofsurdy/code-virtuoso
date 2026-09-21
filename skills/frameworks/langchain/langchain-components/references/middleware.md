# Middleware

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core concepts](#core-concepts)
- [Built-in middleware](#built-in-middleware)
- [Custom middleware](#custom-middleware)
- [Key APIs](#key-apis)
- [Best practices](#best-practices)

## Overview

Middleware gives you fine-grained control over agent execution through hooks at several stages of the agent loop. It intercepts execution before and after model calls, before and after tool calls, and at agent start and end, so you can add observability, transformation, resilience, and governance without touching the core logic.

Pass middleware to `create_agent`. Middleware can be combined freely.

## Installation

```bash
pip install langchain
```

## Core concepts

### Agent loop

The basic loop is: model invocation -> tool selection -> tool execution -> completion (when no more tools are called). Middleware exposes hooks before and after each of these steps.

### Hook types

**Node-style hooks** run sequentially at defined points:

| Hook | When it fires |
|------|---------------|
| `before_agent` | Once at initial execution |
| `before_model` | Before each model invocation |
| `after_model` | After each model response |
| `after_agent` | Once at final execution |

**Wrap-style hooks** control execution flow around a call:

| Hook | What it wraps |
|------|---------------|
| `wrap_model_call` | Each model call |
| `wrap_tool_call` | Each tool call |

### Basic usage

```python
from langchain.agents import create_agent
from langchain.agents.middleware import SummarizationMiddleware, HumanInTheLoopMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[...],
    middleware=[
        SummarizationMiddleware(...),
        HumanInTheLoopMiddleware(...)
    ],
)
```

## Built-in middleware

### Summarization middleware

Condenses conversation history as it approaches the token limit and keeps recent messages.

```python
from langchain.agents.middleware import SummarizationMiddleware

SummarizationMiddleware(
    model="gpt-4.1",           # Summarization model
    trigger={"fraction": 0.8}, # Activate at 80% of context
    keep={"messages": 5},      # Preserve last 5 messages
    trim_tokens_to_summarize=4000,  # Max tokens for summary input
)
```

**Configuration:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `model` | str / BaseChatModel | Summarization model |
| `trigger` | dict | Activation condition: `fraction` (0-1), `tokens` (absolute), or `messages` (count) |
| `keep` | dict | Context to preserve after summarization |
| `token_counter` | callable | Custom token counting function |
| `summary_prompt` | str | Custom prompt template for summarization |
| `trim_tokens_to_summarize` | int | Max tokens to include when generating summaries (default: 4000) |

### Human-in-the-loop middleware

Pauses execution so a person can approve, edit, or reject a tool call before it runs.

```python
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver

checkpointer = InMemorySaver()

agent = create_agent(
    "openai:gpt-4.1",
    tools=[send_email, search_web],
    middleware=[
        HumanInTheLoopMiddleware(
            interrupt_on={"send_email": True}
        ),
    ],
    checkpointer=checkpointer,  # Required for state persistence
)
```

**Requirements:** A checkpointer, to keep state across interruptions.

**Allowed decisions:** approve, edit, reject.

### Model call limit middleware

Limits the number of model calls to stop runaway agents and control cost.

```python
from langchain.agents.middleware import ModelCallLimitMiddleware

ModelCallLimitMiddleware(
    thread_limit=100,     # Max calls across all runs in a thread
    run_limit=10,         # Max calls per single invocation
    exit_behavior="end",  # "end" for graceful termination, "error" for exception
)
```

### Tool call limit middleware

Limits tool call counts, globally or per tool.

```python
from langchain.agents.middleware import ToolCallLimitMiddleware

ToolCallLimitMiddleware(
    tool_name="search_web",  # Optional: specific tool to limit
    thread_limit=50,
    run_limit=5,
    exit_behavior="continue",  # "continue" (blocks with error), "error", or "end"
)
```

### Model fallback middleware

Switches to alternative models when the primary model fails.

```python
from langchain.agents.middleware import ModelFallbackMiddleware

ModelFallbackMiddleware(
    fallbacks=["anthropic:claude-sonnet-4-6", "openai:gpt-4.1-mini"]
)
```

### PII detection middleware

Detects personally identifiable information (PII) and handles it with a configurable strategy. Each instance handles one PII type, so add one middleware per type.

```python
from langchain.agents.middleware import PIIMiddleware

PIIMiddleware(
    "email",                     # Built-in: "email", "credit_card", "ip", "mac_address", "url", or a custom name
    strategy="redact",           # "block", "redact", "mask", or "hash"
    apply_to_input=True,         # Check user messages (default: True)
    apply_to_output=False,       # Check AI responses (default: False)
    apply_to_tool_results=False, # Check tool outputs (default: False)
)
```

**Strategies:**

| Strategy | Behavior |
|----------|----------|
| `block` | Raise an exception when PII is detected |
| `redact` | Replace with `[REDACTED_{PII_TYPE}]` |
| `mask` | Partially obscure (e.g., `****-****-****-1234`) |
| `hash` | Replace with deterministic hash |

**Custom detectors** can be regex patterns, compiled patterns, or detection functions that return matches with `text`, `start`, and `end` properties.

### To-do list middleware

Gives agents task planning and tracking for complex multi-step operations.

```python
from langchain.agents.middleware import TodoListMiddleware

TodoListMiddleware(
    system_prompt="Plan tasks carefully...",
    tool_description="Write and track todos",
)
```

Adds a `write_todos` tool and system prompts that guide planning.

### LLM tool selector middleware

Uses an LLM to pick the relevant tools before the main model call. Best for agents with 10+ tools.

```python
from langchain.agents.middleware import LLMToolSelectorMiddleware

LLMToolSelectorMiddleware(
    model="gpt-4.1-mini",    # Selection model (defaults to agent's model)
    max_tools=5,              # Maximum tools to select
    always_include=["search"],# Tools always included
)
```

### Tool retry middleware

Retries failed tool calls with exponential backoff.

```python
from langchain.agents.middleware import ToolRetryMiddleware

ToolRetryMiddleware(
    max_retries=2,
    tools=["search_web"],     # Optional: specific tools to retry
    backoff_factor=2.0,
    initial_delay=1.0,
    max_delay=60.0,
    jitter=True,              # Random variation to prevent thundering herd
    on_failure="return_message",  # "return_message", "raise", or custom function
)
```

### Model retry middleware

Retries failed model calls with exponential backoff. Configuration is similar to tool retry.

```python
from langchain.agents.middleware import ModelRetryMiddleware

ModelRetryMiddleware(
    max_retries=3,
    backoff_factor=2.0,
    initial_delay=1.0,
    max_delay=60.0,
    on_failure="continue",  # "continue" (returns AIMessage), "error", or custom
)
```

### LLM tool emulator middleware

Emulates tool execution with an LLM, for testing without real tool calls.

```python
from langchain.agents.middleware import LLMToolEmulatorMiddleware

LLMToolEmulatorMiddleware(
    tools=["search_web"],  # None = all, [] = none
    model="gpt-4.1-mini",
)
```

### Context editing middleware

Manages conversation context by clearing older tool outputs when the token limit is reached.

```python
from langchain.agents.middleware import ContextEditingMiddleware, ClearToolUsesEdit

ContextEditingMiddleware(
    edits=[ClearToolUsesEdit(
        trigger=100000,          # Token count triggering edit
        clear_at_least=0,        # Minimum tokens to reclaim
        keep=3,                  # Recent tool results to preserve
        clear_tool_inputs=False, # Remove tool call parameters
        exclude_tools=[],        # Tools never cleared
        placeholder="[cleared]",
    )]
)
```

### Shell tool middleware

Exposes persistent shell sessions for running commands.

```python
from langchain.agents.middleware import ShellToolMiddleware
from langchain.agents.middleware import HostExecutionPolicy, DockerExecutionPolicy

ShellToolMiddleware(
    execution_policy=HostExecutionPolicy(),  # Or DockerExecutionPolicy()
    workspace_root="/app",
    startup_commands=["source venv/bin/activate"],
    env={"PATH": "/usr/local/bin"},
)
```

**Execution policies:**

| Policy | Security level |
|--------|----------------|
| `HostExecutionPolicy` | Full host access (default) |
| `DockerExecutionPolicy` | Isolated Docker container |
| `CodexSandboxExecutionPolicy` | Codex CLI sandbox with syscall restrictions |

### File search middleware

Provides Glob and Grep search tools over the filesystem.

```python
from langchain.agents.middleware import FileSearchMiddleware

FileSearchMiddleware(
    root_path="/path/to/project",
    use_ripgrep=True,
    max_file_size_mb=10,
)
```

### Filesystem middleware (Deep Agents)

Provides context engineering through filesystem access, for memory management. The filesystem and subagent middleware ship in the `deepagents` package (`pip install deepagents`), not in `langchain`.

```python
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend
from deepagents.middleware import FilesystemMiddleware

FilesystemMiddleware(
    backend=CompositeBackend(
        default=StateBackend(),
        routes={"/memories/": StoreBackend(namespace=lambda rt: ("filesystem",))},
    )
)
```

Tools provided: `ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`.

### Subagent middleware (Deep Agents)

Spawns subagents to isolate context and handle specialized tasks.

```python
from deepagents.middleware.subagents import SubAgentMiddleware

SubAgentMiddleware(
    default_model="claude-sonnet-4-6",
    default_tools=[],
    subagents=[
        {
            "name": "researcher",
            "description": "Researches topics using web search",
            "system_prompt": "You are a research assistant...",
            "tools": [search_web],
            "model": "gpt-4.1-mini",
            "middleware": [],
        },
    ],
)
```

## Custom middleware

### Decorator-based (single hook)

```python
from langchain.agents.middleware import before_model, after_model

@before_model
def log_prompt(state, config):
    print(f"Sending {len(state['messages'])} messages to model")
    return {}  # Return dict merged into state

@after_model
def log_response(state, config):
    last = state["messages"][-1]
    print(f"Model responded with {len(last.content)} chars")
    return {}
```

### Class-based (multiple hooks)

```python
from langchain.agents.middleware import AgentMiddleware

class MonitoringMiddleware(AgentMiddleware):
    def before_model(self, state, config):
        print("Before model call")
        return {}

    def after_model(self, state, config):
        print("After model call")
        return {}

    def wrap_tool_call(self, func, state, config):
        start = time.time()
        result = func(state, config)
        print(f"Tool took {time.time() - start:.2f}s")
        return result
```

### Wrap-style hooks

```python
from langchain.agents.middleware import AgentMiddleware

class RetryMiddleware(AgentMiddleware):
    def wrap_model_call(self, func, state, config):
        try:
            return func(state, config)
        except Exception:
            return func(state, config)  # Simple retry

    def wrap_tool_call(self, func, state, config):
        result = func(state, config)
        # Can modify result before returning
        return result
```

### Custom state

```python
from dataclasses import dataclass
from langchain.agents import AgentState

@dataclass
class CustomState(AgentState):
    call_count: int = 0
    user_tier: str = "free"
```

### Agent jumps (control flow)

```python
from langchain.agents.middleware import before_model

@before_model(can_jump_to=["end"])
def check_limit(state, config):
    if state["call_count"] > 10:
        return {"jump_to": "end"}
    return {"call_count": state["call_count"] + 1}
```

Jump targets: `"end"`, `"tools"`, `"model"`.

### Execution order

When several middleware are registered:
- `before_*` hooks: first-to-last order
- Wrap hooks: nested (outermost wraps innermost)
- `after_*` hooks: reverse order (last-to-first)

## Key APIs

| Class/Function | Purpose |
|----------------|---------|
| `create_agent` | Creates agent with middleware support |
| `AgentMiddleware` | Base class for custom middleware |
| `@before_model` | Decorator for pre-model hooks |
| `@after_model` | Decorator for post-model hooks |
| `@before_agent` | Decorator for agent start hooks |
| `@after_agent` | Decorator for agent end hooks |
| `ExtendedModelResponse` | Return type for wrap-style hooks |
| `Command` | Control flow commands with state updates |

## Best practices

- Keep middleware focused on a single concern
- Handle errors inside the middleware
- Choose the hook type by purpose: node-style for observation and transformation, wrap-style for execution control
- Document custom state properties
- Test middleware independently before combining
- Check the execution order when stacking middleware
- Use built-in middleware before writing your own
- Declare `can_jump_to` for control flow so the intent is explicit
