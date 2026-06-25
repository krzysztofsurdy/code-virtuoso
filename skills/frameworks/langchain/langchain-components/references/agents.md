# Agents, context engineering, guardrails, and human-in-the-loop

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Creating agents](#creating-agents)
- [Invocation](#invocation)
- [Tools](#tools)
- [Structured output](#structured-output)
- [Custom state](#custom-state)
- [Dynamic model selection](#dynamic-model-selection)
- [Middleware and error handling](#middleware-and-error-handling)
- [Context engineering](#context-engineering)
- [Guardrails](#guardrails)
- [Human-in-the-loop (HITL)](#human-in-the-loop-hitl)
- [Best practices](#best-practices)

## Overview

Agents combine a language model with tools and loop until the task is done. They follow a ReAct (Reasoning + Acting) loop: input, model decision, tool execution, observation, repeat. The `create_agent` function implements this loop on LangGraph's graph-based runtime.

Context engineering (giving the model the right information and tools in the right format) is the main factor in agent reliability. Guardrails add safety checks at key points in execution, and human-in-the-loop patterns put a person in front of sensitive operations.

## Installation

```bash
pip install langchain langgraph
```

## Creating agents

### Basic agent

```python
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def search(query: str) -> str:
    """Search for information."""
    return f"Results for: {query}"

agent = create_agent("openai:gpt-5", tools=[search])
```

### With a model instance

```python
from langchain.chat_models import ChatOpenAI

model = ChatOpenAI(model="gpt-5", temperature=0.1, max_tokens=1000)
agent = create_agent(model, tools=[search])
```

### System prompts

```python
agent = create_agent(model, tools,
    system_prompt="You are a helpful assistant. Be concise and accurate.",
    name="research_assistant"  # use snake_case
)
```

### Dynamic system prompts

```python
@dynamic_prompt
def state_aware_prompt(request: ModelRequest) -> str:
    message_count = len(request.messages)
    base = "You are a helpful assistant."
    if message_count > 10:
        base += "\nThis is a long conversation - be extra concise."
    return base
```

## Invocation

### Basic

```python
result = agent.invoke({
    "messages": [{"role": "user", "content": "What's the weather in San Francisco?"}]
})
```

### Streaming

```python
for chunk in agent.stream({"messages": [...]}, stream_mode="values"):
    latest_message = chunk["messages"][-1]
```

## Tools

### Static tools

Defined upfront and always available:

```python
@tool(parse_docstring=True)
def search_orders(user_id: str, status: str, limit: int = 10) -> str:
    """Search orders by status.

    Use when checking order history or status.

    Args:
        user_id: User identifier
        status: 'pending', 'shipped', or 'delivered'
        limit: Maximum results (default 10)
    """
```

### Dynamic tools

Filtered based on state, permissions, or feature flags at runtime:

```python
@wrap_model_call
def state_based_tools(request: ModelRequest, handler):
    if not request.state.get("authenticated"):
        tools = [t for t in request.tools if t.name.startswith("public_")]
        request = request.override(tools=tools)
    return handler(request)
```

## Structured output

### ToolStrategy (any tool-calling model)

```python
response_format = ToolStrategy(ContactInfo)
```

### ProviderStrategy (native model support)

```python
response_format = ProviderStrategy(ContactInfo)
```

### Schema Definition

```python
from pydantic import BaseModel, Field

class CustomerSupportTicket(BaseModel):
    category: str = Field(description="'billing', 'technical', 'account', or 'product'")
    priority: str = Field(description="'low', 'medium', 'high', or 'critical'")
    summary: str = Field(description="One-sentence issue summary")
    customer_sentiment: str = Field(description="'frustrated', 'neutral', or 'satisfied'")
```

## Custom state

```python
from langchain.agents import AgentState

class CustomState(AgentState):
    user_preferences: dict

agent = create_agent(model, tools, state_schema=CustomState)
```

## Dynamic model selection

```python
@wrap_model_call
def dynamic_model_selection(request, handler):
    if len(request.state["messages"]) > 10:
        model = advanced_model
    else:
        model = basic_model
    return handler(request.override(model=model))
```

## Middleware and error handling

### Error handling

```python
@wrap_tool_call
def handle_tool_errors(request, handler):
    try:
        return handler(request)
    except Exception as e:
        return ToolMessage(content=f"Tool error: {str(e)}",
                          tool_call_id=request.tool_call["id"])
```

### Message injection (transient)

```python
@wrap_model_call
def inject_context(request: ModelRequest, handler):
    messages = [*request.messages, {"role": "user", "content": context}]
    request = request.override(messages=messages)
    return handler(request)
```

---

## Context engineering

Context engineering is "the number one job of AI Engineers." Agents mostly fail because the LLM lacks the right context, not because the model is incapable.

### Context control framework

| Category | Control Scope | Persistence |
|----------|---------------|-------------|
| Model Context | Instructions, messages, tools, model selection, response formatting | Transient (per-call) |
| Tool Context | Tool access, data reads/writes, runtime state modifications | Persistent (state-saved) |
| Life-cycle Context | Inter-step operations, summarization, guardrails, logging | Persistent (state-saved) |

### Three memory layers

| Layer | Scope | Examples |
|-------|-------|---------|
| Runtime Context | Static configuration | User IDs, API keys, permissions, environment settings |
| State | Conversation-scoped | Messages, files, authentication status, tool results |
| Store | Cross-conversation | Preferences, insights, historical data |

### Tool context: reading

**State access:**

```python
@tool
def check_auth(runtime: ToolRuntime) -> str:
    is_authenticated = runtime.state.get("authenticated", False)
    return "User authenticated" if is_authenticated else "Not authenticated"
```

**Store access:**

```python
@tool
def get_preference(key: str, runtime: ToolRuntime[Context]) -> str:
    prefs = runtime.store.get(("preferences",), runtime.context.user_id)
    return prefs.value.get(key) if prefs else "Not found"
```

**Runtime context access:**

```python
@tool
def fetch_data(query: str, runtime: ToolRuntime[Context]) -> str:
    results = query_db(
        runtime.context.db_connection,
        query,
        runtime.context.api_key
    )
    return f"Found {len(results)} results"
```

### Tool context: writing

**State updates:**

```python
@tool
def authenticate_user(password: str, runtime: ToolRuntime) -> Command:
    is_valid = password == "correct"
    return Command(update={"authenticated": is_valid})
```

**Store persistence:**

```python
@tool
def save_preference(key: str, value: str, runtime: ToolRuntime[Context]) -> str:
    prefs = runtime.store.get(("preferences",), runtime.context.user_id)
    data = prefs.value if prefs else {}
    data[key] = value
    runtime.store.put(("preferences",), runtime.context.user_id, data)
    return f"Saved {key} = {value}"
```

### Summarization middleware

```python
agent = create_agent(
    model="gpt-4.1",
    tools=[...],
    middleware=[
        SummarizationMiddleware(
            model="gpt-4.1-mini",
            trigger={"tokens": 4000},
            keep={"messages": 20},
        ),
    ],
)
```

---

## Guardrails

### Built-in: PII detection

```python
from langchain.agents.middleware import PIIMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[customer_service_tool, email_tool],
    middleware=[
        PIIMiddleware("email", strategy="redact", apply_to_input=True),
        PIIMiddleware("credit_card", strategy="mask", apply_to_input=True),
        PIIMiddleware("api_key", detector=r"sk-[a-zA-Z0-9]{32}",
                     strategy="block", apply_to_input=True),
    ],
)
```

**PII handling strategies:**

| Strategy | Behavior |
|----------|----------|
| `redact` | Replace with `[REDACTED_{PII_TYPE}]` |
| `mask` | Partially obscure values |
| `hash` | Replace with deterministic hash |
| `block` | Raise exception when detected |

**Configuration parameters:**

| Parameter | Description | Default |
|-----------|-------------|---------|
| `pii_type` | Type of PII to detect | Required |
| `strategy` | How to handle detected PII | `"redact"` |
| `detector` | Custom detector function or regex | Built-in |
| `apply_to_input` | Check user messages | `True` |
| `apply_to_output` | Check AI messages | `False` |
| `apply_to_tool_results` | Check tool results | `False` |

### Custom: before-agent guardrail

```python
from langchain.agents.middleware import AgentMiddleware, AgentState, hook_config
from langgraph.runtime import Runtime

class ContentFilterMiddleware(AgentMiddleware):
    def __init__(self, banned_keywords: list[str]):
        super().__init__()
        self.banned_keywords = [kw.lower() for kw in banned_keywords]

    @hook_config(can_jump_to=["end"])
    def before_agent(self, state: AgentState, runtime: Runtime):
        if not state["messages"]:
            return None
        first_message = state["messages"][0]
        if first_message.type != "human":
            return None
        content = first_message.content.lower()
        for keyword in self.banned_keywords:
            if keyword in content:
                return {
                    "messages": [{
                        "role": "assistant",
                        "content": "Cannot process requests with inappropriate content."
                    }],
                    "jump_to": "end"
                }
        return None
```

### Custom: after-agent guardrail

```python
from langchain.agents.middleware import AgentMiddleware, AgentState, hook_config
from langchain.messages import AIMessage
from langchain.chat_models import init_chat_model

class SafetyGuardrailMiddleware(AgentMiddleware):
    def __init__(self):
        super().__init__()
        self.safety_model = init_chat_model("gpt-4.1-mini")

    @hook_config(can_jump_to=["end"])
    def after_agent(self, state: AgentState, runtime: Runtime):
        if not state["messages"]:
            return None
        last_message = state["messages"][-1]
        if not isinstance(last_message, AIMessage):
            return None
        safety_prompt = f"Evaluate if safe: {last_message.content}"
        result = self.safety_model.invoke([{"role": "user", "content": safety_prompt}])
        if "UNSAFE" in result.content:
            last_message.content = "Cannot provide that response."
        return None
```

### Combining multiple guardrails

```python
agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, send_email_tool],
    middleware=[
        ContentFilterMiddleware(banned_keywords=["hack", "exploit"]),
        PIIMiddleware("email", strategy="redact", apply_to_input=True),
        PIIMiddleware("email", strategy="redact", apply_to_output=True),
        HumanInTheLoopMiddleware(interrupt_on={"send_email": True}),
        SafetyGuardrailMiddleware(),
    ],
)
```

---

## Human-in-the-loop (HITL)

HITL middleware pauses execution when an agent action needs human review. It saves state through LangGraph's persistence layer so the run can resume later.

### Configuration

```python
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, send_email_tool, delete_database_tool],
    middleware=[
        HumanInTheLoopMiddleware(
            interrupt_on={
                "send_email": True,
                "delete_database": True,
                "search": False,
            }
        ),
    ],
    checkpointer=InMemorySaver(),  # Use AsyncPostgresSaver in production
)
```

The `interrupt_on` parameter accepts:
- `True` - interrupt with default settings
- `False` - auto-approve
- `InterruptOnConfig` object with `allowed_decisions` and custom `description`

### Human decision types

| Decision | Description |
|----------|-------------|
| `approve` | Execute the action without modifications |
| `edit` | Modify tool arguments before execution |
| `reject` | Decline with explanatory feedback |

### Responding to interrupts

```python
from langgraph.types import Command

result = agent.invoke(
    Command(resume={"decisions": [
        {"type": "approve"},
        # or {"type": "edit", "edited_action": {"name": "send_email", "args": {...}}},
        # or {"type": "reject", "message": "Do not send this email"},
    ]}),
    config={"configurable": {"thread_id": "thread-1"}}
)
```

### Execution flow

1. Agent invokes the model
2. Middleware inspects tool calls against policy
3. Matching calls trigger an interrupt with `HITLRequest`
4. Graph pauses, awaiting human decisions
5. Decisions execute approved/edited calls or synthesize rejection feedback

---

## Best practices

- Start with static components; introduce dynamics only when justified
- Add one context engineering feature per iteration
- Track model calls, token consumption, and latency metrics
- Use built-in middleware (`SummarizationMiddleware`, `PIIMiddleware`, `HumanInTheLoopMiddleware`) before building custom
- Document which context is passed and why
- Keep the transient (per-call) and persistent (state-saved) distinction in mind
- Use well-defined tool names, descriptions, and parameter specifications
- Keep agent names in snake_case for cross-provider compatibility
