# Streaming

## Overview

LangChain implements a streaming system that surfaces real-time updates from agent operations. The framework enables progressive output display before complete responses are ready, significantly improving user experience when dealing with LLM latency. Streaming works across agent progress, LLM tokens, reasoning tokens, and custom updates.

## Installation

```bash
pip install langchain langgraph
# For frontend React hook:
npm install @langchain/langgraph-sdk
```

## Stream Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| `updates` | State changes after each agent step | Tracking agent progress |
| `messages` | Tuples of `(token, metadata)` from LLM nodes | Real-time token display |
| `custom` | User-defined data via stream writer | Progress bars, status updates |

## Agent Progress Streaming

Use `stream()` or `astream()` with `stream_mode="updates"` to emit events after every agent step.

```python
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    stream_mode="updates",
):
    for step, data in chunk.items():
        print(f"step: {step}")
        print(f"content: {data['messages'][-1].content_blocks}")
```

## LLM Token Streaming

Access tokens as they are produced using `stream_mode="messages"`.

```python
for token, metadata in agent.stream(
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    stream_mode="messages",
):
    print(f"node: {metadata['langgraph_node']}")
    print(f"content: {token.content_blocks}")
```

## Custom Updates Streaming

Emit user-defined signals from tools using `get_stream_writer`.

```python
from langgraph.config import get_stream_writer

def get_weather(city: str) -> str:
    writer = get_stream_writer()
    writer(f"Looking up data for city: {city}")
    writer(f"Acquired data for city: {city}")
    return f"It's always sunny in {city}!"

for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    stream_mode="custom"
):
    print(chunk)
```

**Important:** Adding `get_stream_writer` inside tools prevents tool invocation outside LangGraph execution contexts.

## Multiple Stream Modes

Combine modes by passing a list. Returns tuples of `(mode, chunk)`.

```python
for stream_mode, chunk in agent.stream(
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    stream_mode=["updates", "custom"]
):
    print(f"stream_mode: {stream_mode}")
    print(f"content: {chunk}")
```

## Streaming Reasoning Tokens

Filter for reasoning content blocks when using `stream_mode="messages"`.

```python
from langchain_core.messages import AIMessageChunk

for token, metadata in agent.stream(
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    stream_mode="messages",
):
    if not isinstance(token, AIMessageChunk):
        continue
    reasoning = [b for b in token.content_blocks if b["type"] == "reasoning"]
    text = [b for b in token.content_blocks if b["type"] == "text"]
    if reasoning:
        print(f"[thinking] {reasoning[0]['reasoning']}", end="")
    if text:
        print(text[0]["text"], end="")
```

LangChain normalizes provider-specific formats (Anthropic thinking blocks, OpenAI reasoning summaries) into standard `"reasoning"` content block type via `content_blocks`.

## Streaming Tool Calls

Access both partial JSON as tool calls generate and completed parsed calls.

```python
for stream_mode, data in agent.stream(
    {"messages": [input_message]},
    stream_mode=["messages", "updates"],
):
    if stream_mode == "messages":
        token, metadata = data
        if isinstance(token, AIMessageChunk):
            _render_message_chunk(token)
    if stream_mode == "updates":
        for source, update in data.items():
            if source in ("model", "tools"):
                _render_completed_message(update["messages"][-1])
```

## Aggregating Completed Messages

When completed messages are not reflected in state updates, aggregate chunks during streaming.

```python
full_message = None
for stream_mode, data in agent.stream(
    {"messages": [input_message]},
    stream_mode=["messages", "updates"],
):
    if stream_mode == "messages":
        token, metadata = data
        if isinstance(token, AIMessageChunk):
            _render_message_chunk(token)
            full_message = token if full_message is None else full_message + token
            if token.chunk_position == "last":
                if full_message.tool_calls:
                    print(f"Tool calls: {full_message.tool_calls}")
                full_message = None
```

## Human-in-the-Loop Streaming

Configure agents with human-in-the-loop middleware and collect interrupts during updates stream.

```python
from langchain.agents import create_agent
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver

checkpointer = InMemorySaver()
agent = create_agent(
    "openai:gpt-5.2",
    tools=[get_weather],
    middleware=[
        HumanInTheLoopMiddleware(interrupt_on={"get_weather": True}),
    ],
    checkpointer=checkpointer,
)

config = {"configurable": {"thread_id": "some_id"}}
interrupts = []
for stream_mode, data in agent.stream(
    {"messages": [input_message]},
    config=config,
    stream_mode=["messages", "updates"],
):
    if stream_mode == "updates":
        for source, update in data.items():
            if source == "__interrupt__":
                interrupts.extend(update)
```

Respond to interrupts with decisions:

```python
decisions = {
    interrupt.id: {
        "decisions": [
            {
                "type": "edit",
                "edited_action": {
                    "name": "get_weather",
                    "args": {"city": "Boston, U.K."}
                },
            },
            {"type": "approve"},
        ]
    }
}

for stream_mode, data in agent.stream(
    Command(resume=decisions),
    config=config,
    stream_mode=["messages", "updates"],
):
    pass  # Continue streaming with modified decisions
```

## Sub-Agent Streaming

Assign names to agents to disambiguate message sources.

```python
weather_agent = create_agent(
    model=weather_model,
    tools=[get_weather],
    name="weather_agent",
)

supervisor_agent = create_agent(
    model=supervisor_model,
    tools=[call_weather_agent],
    name="supervisor",
)

current_agent = None
for _, stream_mode, data in agent.stream(
    {"messages": [input_message]},
    stream_mode=["messages", "updates"],
    subgraphs=True,
):
    if stream_mode == "messages":
        token, metadata = data
        if agent_name := metadata.get("lc_agent_name"):
            if agent_name != current_agent:
                print(f"Agent: {agent_name}")
                current_agent = agent_name
```

## Disabling Streaming

```python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1", streaming=False)

# Alternative (works on all chat models):
model = ChatOpenAI(model="gpt-4.1", disable_streaming=True)
```

## Frontend: useStream React Hook

The `useStream` hook from `@langchain/langgraph-sdk/react` enables React integration with LangGraph streaming.

### Basic Setup

```typescript
import { useStream } from "@langchain/langgraph-sdk/react";

const stream = useStream({
  assistantId: "agent",
  apiUrl: "http://localhost:2024",
});

// Submit a message
stream.submit({
  messages: [{ content: message, type: "human" }]
});
```

### Configuration

| Parameter | Type | Description |
|-----------|------|-------------|
| `assistantId` | string (required) | Agent identifier |
| `apiUrl` | string | Server URL (default: localhost:2024) |
| `apiKey` | string | Authentication for deployed agents |
| `threadId` | string | Resume existing conversation |
| `onThreadId` | callback | Notified when new thread created |
| `reconnectOnMount` | boolean/function | Auto-resume on component mount |
| `messagesKey` | string | Graph state messages array key |
| `throttle` | boolean | Batch updates for performance |
| `initialValues` | StateType | Display cached data while loading |

### Return Values

| Property | Type | Description |
|----------|------|-------------|
| `messages` | Message[] | All thread messages |
| `values` | StateType | Current graph state |
| `isLoading` | boolean | Stream progress indicator |
| `error` | Error | Streaming errors |
| `interrupt` | Interrupt | Interrupt requiring user input |
| `submit()` | function | Submit input to agent |
| `stop()` | function | Halt current stream |
| `setBranch()` | function | Switch conversation branches |
| `getToolCalls()` | function | Extract tool calls from message |
| `getMessagesMetadata()` | function | Access checkpoint/streaming info |

### Thread Persistence

```typescript
const [threadId, setThreadId] = useState<string | null>(null);
const stream = useStream({
  threadId: threadId,
  onThreadId: setThreadId,
});
```

### Page Refresh Recovery

```typescript
// Automatic
reconnectOnMount: true

// Custom storage
reconnectOnMount: () => window.localStorage
```

### Optimistic Updates

```typescript
stream.submit(
  { messages: [newMessage] },
  {
    optimisticValues(prev) {
      return {
        ...prev,
        messages: [...(prev.messages ?? []), newMessage]
      };
    }
  }
);
```

### Branching

```typescript
// Edit a human message
const parentCheckpoint = stream.getMessagesMetadata(message)
  ?.firstSeenState?.parent_checkpoint;
stream.submit(
  { messages: [{ type: "human", content: newText }] },
  { checkpoint: parentCheckpoint }
);

// Regenerate AI response
stream.submit(undefined, { checkpoint: parentCheckpoint });

// Switch branches
const meta = stream.getMessagesMetadata(message);
stream.setBranch(meta.branch);
```

### Tool Call Rendering

```typescript
const toolCalls = stream.getToolCalls(message);

toolCalls.map(toolCall => {
  const { call, result, state } = toolCall;
  // state: "pending" | "completed" | "error"
});
```

### Custom Events from Agent

Python side:
```python
config.writer({
  "type": "progress",
  "message": step,
  "progress": ((i + 1) / len(steps)) * 100
})
```

React side:
```typescript
onCustomEvent: (data) => {
  if (data.type === "progress") {
    setProgress(data.progress);
  }
}
```

### Human-in-the-Loop in UI

```typescript
const hitlRequest = stream.interrupt?.value;

if (hitlRequest) {
  // Display approval UI
  await stream.submit(null, {
    command: { resume: { decisions } }
  });
}
```

### Multi-Agent Message Sources

```typescript
const metadata = stream.getMessagesMetadata(message);
const nodeName = metadata?.streamMetadata?.langgraph_node;
// Render with distinct styling based on source agent
```

## Event Callbacks

| Callback | Trigger | Stream Mode |
|----------|---------|-------------|
| `onUpdateEvent` | State update post-step | updates |
| `onCustomEvent` | Custom agent events | custom |
| `onMetadataEvent` | Run/thread metadata | metadata |
| `onError` | Streaming error | - |
| `onFinish` | Stream completion | - |

## Best Practices

- Use `stream_mode="updates"` for progress tracking, `"messages"` for token-by-token display
- Combine multiple stream modes when you need both progress and tokens
- Use custom streaming for domain-specific progress indicators (file processing, data fetching)
- Name agents in multi-agent systems to disambiguate message sources
- Use `throttle: true` in React to batch rapid updates and improve performance
- Implement `reconnectOnMount` for production apps to handle page refreshes
- Use optimistic updates for immediate UI feedback before network responses
- Set `disable_streaming=True` on models where streaming is not needed to reduce overhead
