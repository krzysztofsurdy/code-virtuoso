# Multi-agent systems

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Five primary patterns](#five-primary-patterns)
- [Performance comparison](#performance-comparison)
- [Pattern selection framework](#pattern-selection-framework)
- [Subagents pattern](#subagents-pattern)
- [Handoffs pattern](#handoffs-pattern)
- [Skills pattern](#skills-pattern)
- [Router pattern](#router-pattern)
- [Custom Workflow pattern](#custom-workflow-pattern)
- [Mixing patterns](#mixing-patterns)
- [Key APIs](#key-apis)
- [Best practices](#best-practices)

## Overview

Multi-agent systems coordinate specialized components for complex workflows. Many complex tasks do not need them: a single agent with the right tools and prompt can often do the same job. Multi-agent patterns pay off when a single agent has too many tools, tasks need specialized knowledge with extensive context, or sequential constraints unlock capabilities only after certain conditions are met.

Multi-agent design is mostly context engineering: deciding what information each agent sees.

## Installation

```bash
pip install langchain langgraph
```

## Five primary patterns

| Pattern | Description | Best For |
|---------|-------------|----------|
| Subagents | Main agent coordinates subagents as tools | Distributed dev, parallelization, multi-hop |
| Handoffs | State-driven behavior changes via tool calls | Direct user interaction, sequential workflows |
| Skills | Specialized prompts loaded on-demand | Single agent with many specializations |
| Router | Classification-based dispatch to specialized agents | Parallel multi-domain queries |
| Custom Workflow | Custom LangGraph execution flows | Complex routing, mixed deterministic/agentic |

## Performance comparison

### One-shot request ("Buy coffee")

| Pattern | Model Calls | Notes |
|---------|-------------|-------|
| Subagents | 4 | Results flow back through main agent |
| Handoffs | 3 | Optimal |
| Skills | 3 | Optimal |
| Router | 3 | Optimal |

### Repeat request (two turns)

| Pattern | Total Calls | Notes |
|---------|-------------|-------|
| Subagents | 8 (4+4) | Stateless by design |
| Handoffs | 5 (3+2) | Stateful - agent remains active |
| Skills | 5 (3+2) | Reuses loaded skill context |
| Router | 6 (3+3) | Stateless routing each time |

Stateful patterns (Handoffs, Skills) save 40-50% of calls on repeat requests.

### Multi-domain ("Compare Python, JavaScript, and Rust")

| Pattern | Model Calls | Total Tokens | Notes |
|---------|-------------|--------------|-------|
| Subagents | 5 | ~9K | Optimal - context isolation |
| Handoffs | 7+ | ~14K+ | Inefficient - sequential execution |
| Skills | 3 | ~15K | High token usage - loads all docs |
| Router | 5 | ~9K | Optimal - parallel execution |

## Pattern selection framework

| Requirement | Subagents | Handoffs | Skills | Router |
|-------------|-----------|----------|--------|--------|
| Distributed Development | 5/5 | - | 5/5 | 3/5 |
| Parallelization | 5/5 | - | 3/5 | 5/5 |
| Multi-Hop Support | 5/5 | 5/5 | 5/5 | - |
| Direct User Interaction | 1/5 | 5/5 | 5/5 | 3/5 |

---

## Subagents pattern

A central supervisor agent coordinates specialized subagents by invoking them as tools. Subagents operate statelessly with context isolation.

### Basic setup (tool per agent)

```python
from langchain.tools import tool
from langchain.agents import create_agent

subagent = create_agent(model="anthropic:claude-sonnet-4-6", tools=[...])

@tool("research", description="Research a topic and return findings")
def call_research_agent(query: str):
    result = subagent.invoke({
        "messages": [{"role": "user", "content": query}]
    })
    return result["messages"][-1].content

main_agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    tools=[call_research_agent]
)
```

### Single dispatch registry

```python
research_agent = create_agent(model="gpt-4.1", system_prompt="Research specialist...")
writer_agent = create_agent(model="gpt-4.1", system_prompt="Writing specialist...")

SUBAGENTS = {
    "research": research_agent,
    "writer": writer_agent,
}

@tool
def task(agent_name: str, description: str) -> str:
    """Launch ephemeral subagent for task.

    Available agents:
    - research: Research and fact-finding
    - writer: Content creation and editing
    """
    agent = SUBAGENTS[agent_name]
    result = agent.invoke({
        "messages": [{"role": "user", "content": description}]
    })
    return result["messages"][-1].content

main_agent = create_agent(
    model="gpt-4.1",
    tools=[task],
    system_prompt="Coordinate specialized sub-agents. Use task tool to delegate work.",
)
```

### Sync vs async execution

| Mode | When to Use |
|------|-------------|
| Synchronous (default) | Supervisor needs subagent output to formulate response. Dependent tasks. |
| Asynchronous | Independent work where users should not wait. Requires start/check/get tools. |

### Subagent discovery methods

| Method | Best For |
|--------|----------|
| System Prompt Enumeration | Small, static registries (< 10 agents) |
| Enum Constraint on Dispatch Tool | Fixed agent sets with type safety |
| Tool-Based Discovery (`list_agents`, `search_agents`) | Large, frequently-changing registries |

### Context engineering for subagents

**Controlling inputs** - pull from agent state:

```python
from langchain.agents import AgentState
from langchain.tools import tool, ToolRuntime

class CustomState(AgentState):
    example_state_key: str

@tool("subagent1_name", description="...")
def call_subagent1(query: str, runtime: ToolRuntime[None, CustomState]):
    subagent_input = some_logic(query, runtime.state["messages"])
    result = subagent1.invoke({
        "messages": subagent_input,
        "example_state_key": runtime.state["example_state_key"]
    })
    return result["messages"][-1].content
```

**Controlling outputs** - update state via Command:

```python
from typing import Annotated
from langchain.tools import InjectedToolCallId
from langgraph.types import Command

@tool("subagent1_name", description="...")
def call_subagent1(
    query: str,
    tool_call_id: Annotated[str, InjectedToolCallId],
) -> Command:
    result = subagent1.invoke({
        "messages": [{"role": "user", "content": query}]
    })
    return Command(update={
        "example_state_key": result["example_state_key"],
        "messages": [
            ToolMessage(
                content=result["messages"][-1].content,
                tool_call_id=tool_call_id
            )
        ]
    })
```

---

## Handoffs pattern

Behavior changes dynamically based on state. Tool calls update a state variable that triggers routing or configuration changes.

### Key characteristics

- State-driven behavior modification
- Tool-based state transitions
- Direct user interaction across different states
- Persistent state surviving across turns

### Implementation approaches

**Single Agent with Middleware:** A single agent dynamically adjusts its system prompt and available tools based on current state. Middleware intercepts model calls and applies configuration changes. Tools return `Command` objects to update state.

**Multiple Agent Subgraphs:** Distinct agents exist as separate graph nodes. Handoff tools navigate between nodes using `Command.PARENT`.

### Critical implementation detail

When tools update messages, they must include a `ToolMessage` with a matching `tool_call_id`. Without it, the conversation history becomes malformed.

For multi-agent systems, include both the triggering `AIMessage` and a `ToolMessage` acknowledgment to maintain valid conversation history. Avoid passing complete subagent histories.

---

## Skills pattern

Specialized prompts and knowledge loaded on-demand. A single agent stays in control while loading context from skills as needed.

### When to use

- Single agent with many possible specializations
- No constraints between skills
- Coding assistants, domain-organized knowledge bases, format-specific creative tools

### Basic implementation

```python
from langchain.tools import tool
from langchain.agents import create_agent

@tool
def load_skill(skill_name: str) -> str:
    """Load a specialized skill prompt."""
    # Load skill content from file/database
    ...

agent = create_agent(
    model="gpt-4.1",
    tools=[load_skill],
    system_prompt="You are a helpful assistant with access to skills..."
)
```

### Extension approaches

- **Dynamic tool registration** - register tools as skills load
- **Hierarchical skills** - nested specializations in tree structures
- **Reference awareness** - skills reference external assets loaded on-demand

---

## Router pattern

A routing step classifies input and directs it to specialized agents. Results are synthesized into a unified response.

### Single agent routing

Uses the `Command` class to direct queries to one appropriate agent after LLM-based classification.

### Parallel multi-agent routing

Uses the `Send` mechanism to fan out across multiple agents simultaneously:

```python
# Returns list of Send objects with classified query assignments
sends = [Send("agent_node", {"query": sub_query}) for sub_query in classified_queries]
```

### Stateless vs stateful

| Approach | Description |
|----------|-------------|
| Stateless | Processes each request independently. Suitable for single-turn interactions. |
| Stateful (tool wrapper) | Wrap stateless router as a tool within a conversational agent. |
| Stateful (full persistence) | Implement full persistence with message history management. |

### Router vs Subagents

Routers use lightweight classification for dispatch. Subagents involve dynamic supervisor decision-making across multi-turn conversations with maintained context.

---

## Custom Workflow pattern

Build custom execution flows with LangGraph, mixing deterministic logic and agentic behavior. Other patterns can be embedded as nodes.

### When to use

- Standard patterns do not apply
- Need to combine deterministic logic with agentic behavior
- Complex routing and multi-stage processing required

### Node types

| Type | Description | Example |
|------|-------------|---------|
| Model node | Uses structured output for query transformation | Query rewriting |
| Deterministic node | Performs operations without LLM calls | Vector similarity search |
| Agent node | Reasons over context with tool access | Research with live data |

### State management

Uses LangGraph TypedDict-based state to pass information between workflow steps:

```python
from typing import TypedDict

class WorkflowState(TypedDict):
    query: str
    context: list[str]
    messages: list
```

---

## Mixing patterns

Patterns can be combined. A subagents architecture can invoke tools that invoke custom workflows or router agents. Subagents can use the skills pattern to load context on-demand.

## Key APIs

| Class/Function | Purpose |
|----------------|---------|
| `create_agent()` | Create an agent with model, tools, and middleware |
| `Command` | Update state and trigger transitions from tools |
| `Command.PARENT` | Navigate to parent graph in multi-agent subgraphs |
| `Send` | Fan out to multiple agents in parallel (router pattern) |
| `ToolRuntime` | Access state, store, and runtime context from tools |
| `AgentState` | Base TypedDict for agent state schema |
| `@tool` | Decorator to define tools |
| `@wrap_model_call` | Middleware decorator for model call interception |
| `@wrap_tool_call` | Middleware decorator for tool call interception |

## Best practices

- Start with a single agent; add multi-agent patterns only when justified
- Choose patterns based on your optimization goal (latency, tokens, parallelism)
- Keep subagent names action-oriented (e.g., `research_agent`, `code_reviewer`)
- Always include `ToolMessage` with matching `tool_call_id` in handoff transitions
- Avoid passing complete subagent histories to receiving agents
- Use context isolation (subagents) for large-context domains
- Use stateful patterns (handoffs, skills) for conversational workflows with repeat requests
- Monitor model calls, token consumption, and latency per pattern
