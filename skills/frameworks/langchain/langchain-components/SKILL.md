---
name: langchain-components
description: Reference for the LangChain ecosystem (LangChain, LangGraph, and Deep Agents) for Python 3.10+. Use when the user asks to build AI agents, implement RAG pipelines, configure chat models, create tool-calling agents, set up retrieval chains, manage conversation memory, orchestrate multi-agent workflows, or integrate with LLM providers (OpenAI, Anthropic, Google). Covers models, messages, output parsers, vector stores, embedding strategies, streaming, middleware, and LangGraph state machines.
allowed-tools: Read Grep Glob Bash
user-invocable: false
---

# LangChain Components

Reference for the LangChain ecosystem on Python 3.10+: models, agents, tools, retrieval, memory, middleware, streaming, multi-agent orchestration, LangGraph workflows, Deep Agents, and provider integrations.

## Component index

### Models and output
- **Models**: Chat models, tool calling, multimodal inputs, caching, rate limiting, custom models ([reference](references/models.md))
- **Messages**: Message types (Human, AI, System, Tool), message operations, serialization, OpenAI format conversion ([reference](references/messages.md))

### Agents
- **Agents**: create_agent, tools, structured output, guardrails, human-in-the-loop, context engineering ([reference](references/agents.md))
- **Multi-Agent**: Subagents, handoffs, skills, router, custom workflows, pattern selection ([reference](references/multi-agent.md))

### Tools and MCP
- **Tools**: Tool creation (@tool decorator, ToolNode), InjectedState, MCP integration, error handling ([reference](references/tools.md))

### Retrieval and RAG
- **Retrieval**: Document loaders, text splitters, embeddings, vector stores, agentic RAG, semantic search ([reference](references/retrieval.md))

### Memory
- **Memory**: Short-term (checkpointers, message trimming, summarization), long-term (store abstraction, namespaces) ([reference](references/memory.md))

### Middleware and streaming
- **Middleware**: 16 built-in middleware, custom middleware (decorator, class, wrap-style), execution order ([reference](references/middleware.md))
- **Streaming**: Stream modes (updates, messages, custom), token streaming, useStream React hook ([reference](references/streaming.md))

### Runtime and architecture
- **Runtime**: Dependency injection, context schemas, ToolRuntime, component architecture (5 layers) ([reference](references/runtime.md))

### Testing and deployment
- **Testing**: Unit testing (GenericFakeChatModel), integration testing (AgentEvals), LangSmith observability ([reference](references/testing.md))

### LangGraph
- **LangGraph Core**: Graph API, Functional API, workflows vs agents, state management, quickstart ([reference](references/langgraph-core.md))
- **LangGraph State**: Memory, persistence, durable execution, interrupts, checkpointers ([reference](references/langgraph-state.md))
- **LangGraph Advanced**: Subgraphs, time-travel, streaming, Graph API usage, Functional API usage ([reference](references/langgraph-advanced.md))

### Deep Agents
- **Deep Agents**: Harness framework, models, subagents, skills, sandboxes, human-in-the-loop, long-term memory ([reference](references/deep-agents.md))

### Integrations
- **Integrations**: Chat models, document loaders, retrievers, embeddings, vector stores, tools, stores, splitters ([reference](references/integrations.md))
- **Providers**: OpenAI, Anthropic, Google, AWS, Ollama setup and configuration ([reference](references/providers.md))

## Quick patterns

### Create an agent with tools

```python
from langchain.chat_models import init_chat_model
from langchain.agents import create_agent

model = init_chat_model("anthropic:claude-sonnet-4-6")

def get_weather(city: str) -> str:
    """Get weather for a city."""
    return f"Sunny, 72F in {city}"

agent = create_agent(model, [get_weather])
response = agent.invoke(
    {"messages": [{"role": "user", "content": "What's the weather in SF?"}]}
)
```

### Structured output

```python
from pydantic import BaseModel

class SearchQuery(BaseModel):
    query: str
    year: int

structured_model = model.with_structured_output(SearchQuery)
result = structured_model.invoke("Who won the World Cup in 2022?")
```

### RAG with retrieval

```python
from langchain_community.document_loaders import WebBaseLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_core.vectorstores import InMemoryVectorStore

docs = WebBaseLoader("https://example.com").load()
chunks = RecursiveCharacterTextSplitter(chunk_size=1000).split_documents(docs)
vector_store = InMemoryVectorStore.from_documents(chunks, OpenAIEmbeddings())
retriever_tool = vector_store.as_retriever()
```

### Multi-agent handoffs

```python
from langchain.agents import create_agent
from langchain.tools import tool

billing_agent = create_agent(model, [lookup_billing], name="billing")
tech_agent = create_agent(model, [check_status], name="tech_support")

@tool("billing", description="Handle billing questions")
def ask_billing(query: str) -> str:
    result = billing_agent.invoke({"messages": [{"role": "user", "content": query}]})
    return result["messages"][-1].content

@tool("tech_support", description="Handle technical support questions")
def ask_tech_support(query: str) -> str:
    result = tech_agent.invoke({"messages": [{"role": "user", "content": query}]})
    return result["messages"][-1].content

supervisor = create_agent(
    model,
    [ask_billing, ask_tech_support],
    system_prompt="Route to the appropriate specialist."
)
```

### LangGraph workflow

```python
from langgraph.graph import StateGraph, START, END

graph = StateGraph(dict)
graph.add_node("process", process_fn)
graph.add_node("review", review_fn)
graph.add_edge(START, "process")
graph.add_edge("process", "review")
graph.add_edge("review", END)
app = graph.compile()
```

### Streaming

```python
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "Hello"}]},
    stream_mode="messages"
):
    print(chunk)
```

## Best practices

- Use `init_chat_model()` for provider-agnostic model initialization
- Prefer `create_agent` over building custom agent loops
- Use LangGraph for complex workflows requiring state, persistence, or human-in-the-loop
- Use middleware for cross-cutting concerns (guardrails, rate limiting, PII detection)
- Use checkpointers for conversation persistence and short-term memory
- Use the Store abstraction for long-term memory across conversations
- Pick the multi-agent pattern by need: handoffs for specialization, routers for classification, subagents for parallel work
- Use `with_structured_output()` for type-safe LLM responses
- Prefer agentic RAG (tool-based retrieval) over chain-based RAG, which is less flexible
- Use `stream_mode="messages"` for token-level streaming to frontends
