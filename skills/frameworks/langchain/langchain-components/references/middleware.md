# Middleware

## Overview

Middleware enables fine-grained control over agent execution by providing hooks at various stages of the agent loop. Middleware intercepts execution at specific points - before/after model calls, before/after tool calls, and at agent start/end - allowing you to add observability, transformation, resilience, and governance to your agents without modifying core logic.

Middleware is integrated via the `create_agent` function and can be combined freely to build comprehensive agent systems.

## Installation

```bash
pip install langchain
```

## Core Concepts

### Agent Loop Architecture

The basic agent loop flow: model invocation -> tool selection -> tool execution -> completion (when no additional tools are called). Middleware exposes hooks before and after each of these steps.

### Hook Types

**Node-style hooks** execute sequentially at defined points:

| Hook | When It Fires |
|------|---------------|
| `before_agent` | Once at initial execution |
| `before_model` | Prior to each model invocation |
| `after_model` | Following model responses |
| `after_agent` | Once at final execution |

**Wrap-style hooks** control execution flow around calls:

| Hook | What It Wraps |
|------|---------------|
| `wrap_model_call` | Surrounds each model interaction |
| `wrap_tool_call` | Surrounds each tool interaction |

### Basic Usage

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

## Built-in Middleware

### Summarization Middleware

Automatically condenses conversation history when approaching token limits while preserving recent messages.

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
| `model` | str / BaseChatModel | The summarization model |
| `trigger` | dict | Activation condition: `fraction` (0-1), `tokens` (absolute), or `messages` (count) |
| `keep` | dict | Context to preserve after summarization |
| `token_counter` | callable | Custom token counting function |
| `summary_prompt` | str | Custom prompt template for summarization |
| `trim_tokens_to_summarize` | int | Max tokens to include when generating summaries (default: 4000) |

### Human-in-the-Loop Middleware

Pauses execution for human approval, editing, or rejection of tool calls before implementation.

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

**Requirements:** Needs a checkpointer to maintain state across interruptions.

**Allowed decisions:** approve, edit, reject.

### Model Call Limit Middleware

Restricts the number of model calls to prevent runaway agents and manage costs.

```python
from langchain.agents.middleware import ModelCallLimitMiddleware

ModelCallLimitMiddleware(
    thread_limit=100,     # Max calls across all runs in a thread
    run_limit=10,         # Max calls per single invocation
    exit_behavior="end",  # "end" for graceful termination, "error" for exception
)
```

### Tool Call Limit Middleware

Controls tool execution by limiting call counts globally or per-tool.

```python
from langchain.agents.middleware import ToolCallLimitMiddleware

ToolCallLimitMiddleware(
    tool_name="search_web",  # Optional: specific tool to limit
    thread_limit=50,
    run_limit=5,
    exit_behavior="continue",  # "continue" (blocks with error), "error", or "end"
)
```

### Model Fallback Middleware

Automatically switches to alternative models when the primary model fails.

```python
from langchain.agents.middleware import ModelFallbackMiddleware

ModelFallbackMiddleware(
    fallbacks=["anthropic:claude-sonnet-4-20250514", "openai:gpt-4.1-mini"]
)
```

### PII Detection Middleware

Detects and handles Personally Identifiable Information using configurable strategies.

```python
from langchain.agents.middleware import PIIDetectionMiddleware

PIIDetectionMiddleware(
    types=["email", "credit_card", "ip", "mac_address", "url"],
    strategy="redact",           # "block", "redact", "mask", or "hash"
    apply_to_input=True,         # Check user messages (default: True)
    apply_to_output=False,       # Check AI responses (default: False)
    apply_to_tool_results=False, # Check tool outputs (default: False)
)
```

**Strategies:**

| Strategy | Behavior |
|----------|----------|
| `block` | Raise exception when PII detected |
| `redact` | Replace with `[REDACTED_{TYPE}]` |
| `mask` | Partially obscure (e.g., `****-****-****-1234`) |
| `hash` | Replace with deterministic hash |

**Custom detectors** support regex patterns, compiled patterns, or custom detection functions returning matches with text/start/end properties.

### To-Do List Middleware

Equips agents with task planning and tracking for complex multi-step operations.

```python
from langchain.agents.middleware import ToDoListMiddleware

ToDoListMiddleware(
    system_prompt="Plan tasks carefully...",
    tool_description="Write and track todos",
)
```

Auto-provides a `write_todos` tool and system prompts guiding effective planning.

### LLM Tool Selector Middleware

Uses an LLM to intelligently select relevant tools before main model invocation. Best for agents with 10+ tools.

```python
from langchain.agents.middleware import LLMToolSelectorMiddleware

LLMToolSelectorMiddleware(
    model="gpt-4.1-mini",    # Selection model (defaults to agent's model)
    max_tools=5,              # Maximum tools to select
    always_include=["search"],# Tools always included
)
```

### Tool Retry Middleware

Automatically retries failed tool calls with exponential backoff.

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

### Model Retry Middleware

Automatically retries failed model calls with exponential backoff. Configuration is similar to Tool Retry.

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

### LLM Tool Emulator Middleware

Emulates tool execution using an LLM for testing without actual tool calls.

```python
from langchain.agents.middleware import LLMToolEmulatorMiddleware

LLMToolEmulatorMiddleware(
    tools=["search_web"],  # None = all, [] = none
    model="gpt-4.1-mini",
)
```

### Context Editing Middleware

Manages conversation context by clearing older tool outputs when token limits are reached.

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

### Shell Tool Middleware

Exposes persistent shell sessions for command execution.

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

**Execution Policies:**

| Policy | Security Level |
|--------|----------------|
| `HostExecutionPolicy` | Full host access (default) |
| `DockerExecutionPolicy` | Isolated Docker container |
| `CodexSandboxExecutionPolicy` | Codex CLI sandbox with syscall restrictions |

### File Search Middleware

Provides Glob and Grep search tools over the filesystem.

```python
from langchain.agents.middleware import FileSearchMiddleware

FileSearchMiddleware(
    root_path="/path/to/project",
    use_ripgrep=True,
    max_file_size_mb=10,
)
```

### Filesystem Middleware (Deep Agents)

Provides context engineering through filesystem interaction for memory management.

```python
from langchain.agents.middleware import FilesystemMiddleware
from langchain.agents.middleware import StateBackend, StoreBackend, CompositeBackend

FilesystemMiddleware(
    backend=CompositeBackend(
        routes={"/memories/": StoreBackend(store=my_store)},
        default=StateBackend(),
    )
)
```

Tools provided: `ls`, `read_file`, `write_file`, `edit_file`.

### Subagent Middleware (Deep Agents)

Allows spawning subagents to isolate context and handle specialized tasks.

```python
from langchain.agents.middleware import SubagentMiddleware, SubagentDefinition

SubagentMiddleware(
    subagents=[
        SubagentDefinition(
            name="researcher",
            description="Researches topics using web search",
            system_prompt="You are a research assistant...",
            tools=[search_web],
            model="gpt-4.1-mini",
        ),
    ]
)
```

## Custom Middleware

### Decorator-Based (Single Hook)

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

### Class-Based (Multiple Hooks)

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

### Wrap-Style Hooks

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

### Custom State

```python
from dataclasses import dataclass
from langchain.agents import AgentState

@dataclass
class CustomState(AgentState):
    call_count: int = 0
    user_tier: str = "free"
```

### Agent Jumps (Control Flow)

```python
from langchain.agents.middleware import before_model

@before_model(can_jump_to=["end"])
def check_limit(state, config):
    if state["call_count"] > 10:
        return {"jump_to": "end"}
    return {"call_count": state["call_count"] + 1}
```

Jump targets: `"end"`, `"tools"`, `"model"`.

### Execution Order

When multiple middleware are registered:
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

## Best Practices

- Keep middleware focused on a single concern
- Handle errors gracefully within middleware
- Choose the right hook type: node-style for observation/transformation, wrap-style for execution control
- Document custom state properties
- Test middleware independently before combining
- Consider execution order when stacking multiple middleware
- Leverage built-in middleware before writing custom solutions
- Use `can_jump_to` declarations for control flow to make intent explicit
