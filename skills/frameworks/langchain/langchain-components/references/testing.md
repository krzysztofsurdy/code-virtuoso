# Testing, deployment, and observability

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Unit testing](#unit-testing)
- [Integration testing](#integration-testing)
- [Deployment with LangSmith](#deployment-with-langsmith)
- [Observability with LangSmith](#observability-with-langsmith)
- [Key APIs](#key-apis)
- [Best practices](#best-practices)

## Overview

This reference covers testing, deploying, and monitoring agentic applications. Testing combines unit tests built on deterministic fakes with integration tests against real models. LangSmith provides a managed deployment platform and tracing for observability.

## Installation

```bash
pip install langchain langgraph agentevals langsmith
pip install vcrpy pytest-recording  # For HTTP recording in tests
```

## Unit testing

Unit tests use small, deterministic pieces in isolation with in-memory fakes.

### GenericFakeChatModel

Mock model responses with deterministic iterators.

```python
from langchain_core.language_models import GenericFakeChatModel
from langchain.agents import create_agent

fake_model = GenericFakeChatModel(
    messages=iter([
        AIMessage(content="Let me search for that."),
        AIMessage(content="Here are the results."),
    ])
)

agent = create_agent(
    model=fake_model,
    tools=[search_tool],
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Find something"}]
})
```

Supports both regular and streaming modes.

### InMemorySaver for state testing

Test state-dependent behaviors by maintaining conversation history across invocations.

```python
from langgraph.checkpoint.memory import InMemorySaver

checkpointer = InMemorySaver()

agent = create_agent(
    model=fake_model,
    tools=[my_tool],
    checkpointer=checkpointer,
)

config = {"configurable": {"thread_id": "test-thread"}}

# First turn
agent.invoke(
    {"messages": [{"role": "user", "content": "Hello"}]},
    config=config,
)

# Second turn (maintains state)
result = agent.invoke(
    {"messages": [{"role": "user", "content": "Follow up"}]},
    config=config,
)
```

## Integration testing

Integration tests exercise real network calls to confirm that components work together, credentials are valid, and latency is acceptable. Agentic systems rely on them more heavily because they chain many components.

### AgentEvals: trajectory match

The `agentevals` package evaluates agent execution trajectories.

```python
from agentevals import trajectory_match

# Four matching modes:
result = trajectory_match(
    outputs=agent_output["messages"],
    reference=expected_messages,
    mode="strict",  # Identical message sequences with same tool calls
)
```

| Mode | Description |
|------|-------------|
| `strict` | Identical message sequences with same tool calls |
| `unordered` | Same tools callable in any order |
| `subset` | Agent calls only reference tools (no extras allowed) |
| `superset` | Agent calls at least reference tools (extras permitted) |

### AgentEvals: LLM-as-judge

Uses language models to qualitatively assess execution trajectories.

```python
from agentevals import llm_as_judge

result = llm_as_judge(
    outputs=agent_output["messages"],
    reference=expected_messages,
    rubric="The agent should search for weather data and provide a summary.",
)
```

### HTTP recording with vcrpy

Record and replay HTTP interactions to reduce API costs during repeated test runs.

```python
# pytest with cassette recording
import pytest

@pytest.mark.vcr()
def test_agent_search():
    result = agent.invoke({
        "messages": [{"role": "user", "content": "Search for Python docs"}]
    })
    assert "Python" in result["messages"][-1].content
```

Configure sensitive data masking in `conftest.py`:

```python
@pytest.fixture(scope="module")
def vcr_config():
    return {
        "filter_headers": ["authorization", "x-api-key"],
        "filter_query_parameters": ["api_key"],
    }
```

### LangSmith experiment tracking

Log test inputs, outputs, and reference trajectories to LangSmith.

```python
import os

os.environ["LANGSMITH_API_KEY"] = "your-api-key"
os.environ["LANGSMITH_TRACING"] = "true"

# Pytest integration logs automatically
# Or use evaluate() function for batch evaluation
```

## Deployment with LangSmith

LangSmith provides a managed platform for deploying stateful, long-running agents.

### Deployment steps

1. Push your LangGraph-compatible application code to a GitHub repository
2. Navigate to Deployments in LangSmith and create a new deployment
3. Connect your GitHub account and select your repository
4. Submit for deployment (approximately 15 minutes)
5. Access the Studio interface for graph visualization and testing

### API access

**Python SDK:**

```python
from langgraph_sdk import get_sync_client

client = get_sync_client(
    url="https://your-deployment.us.langgraph.app",
    api_key="your-langsmith-api-key",
)

result = client.runs.create(
    assistant_id="agent",
    input={"messages": [{"role": "user", "content": "Hello"}]},
)
```

**REST API:**

```bash
curl -X POST https://your-deployment.us.langgraph.app/runs \
  -H "x-api-key: your-langsmith-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "assistant_id": "agent",
    "input": {
      "messages": [{"role": "user", "content": "Hello"}]
    }
  }'
```

### Key features

- Purpose-built infrastructure for agent workloads
- Automatic scaling and operational management
- Direct repository deployment from GitHub
- Streaming support for real-time responses
- Studio interface for debugging and visualization

## Observability with LangSmith

LangSmith traces LangChain agents, recording tool calls, prompts, and decision steps.

### Enabling tracing

```bash
export LANGSMITH_TRACING=true
export LANGSMITH_API_KEY=<your-api-key>
```

Agents created with `create_agent` automatically support tracing without additional code.

### Basic usage

```python
from langchain.agents import create_agent

agent = create_agent(
    model="gpt-4.1",
    tools=[send_email, search_web],
    system_prompt="You are a helpful assistant...",
)

# Automatically traced when LANGSMITH_TRACING=true
response = agent.invoke({
    "messages": [{"role": "user", "content": "Your request here"}]
})
```

### Selective tracing

Control which operations get traced using `tracing_context`.

```python
import langsmith as ls

with ls.tracing_context(enabled=True):
    agent.invoke({"messages": [...]})  # Traced

# Outside context: not traced (unless env var is set)
```

### Project configuration

```python
# Static: set environment variable
os.environ["LANGSMITH_PROJECT"] = "my-project"

# Dynamic: specify per-invocation
with ls.tracing_context(project_name="my-project", enabled=True):
    agent.invoke({"messages": [...]})
```

### Adding metadata and tags

```python
# Via config
response = agent.invoke(
    {"messages": [...]},
    config={
        "tags": ["production", "v1.0"],
        "metadata": {"user_id": "123"}
    }
)

# Via tracing context
with ls.tracing_context(
    tags=["production"],
    metadata={"user_id": "123"}
):
    agent.invoke({"messages": [...]})
```

## Key APIs

| API | Purpose |
|-----|---------|
| `GenericFakeChatModel` | Mock chat model for unit tests |
| `InMemorySaver` | In-memory checkpointer for state testing |
| `trajectory_match()` | Evaluate agent trajectories against reference |
| `llm_as_judge()` | LLM-based qualitative assessment |
| `get_sync_client()` | Connect to deployed LangSmith agent |
| `ls.tracing_context()` | Control tracing scope and metadata |

## Best practices

- Use `GenericFakeChatModel` for deterministic unit tests that run fast without API calls
- Use `InMemorySaver` to test multi-turn conversations and state persistence
- Favor integration tests for agentic systems, since they chain multiple components
- Use trajectory matching with appropriate mode (`strict` for critical paths, `unordered` for flexible workflows)
- Record HTTP interactions with vcrpy to reduce API costs in CI/CD pipelines
- Mask sensitive data (API keys, tokens) in cassette recordings
- Enable LangSmith tracing in all environments
- Use tags and metadata to organize traces by environment, version, and user
- Use selective tracing in development to avoid noise from unrelated operations
- Deploy via LangSmith for stateful agents - it handles scaling and state management
