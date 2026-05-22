# Messages

## Overview

Messages are the foundational unit for model interactions in LangChain. They encapsulate role identification, content payload, and optional metadata to represent conversation state with LLMs. LangChain provides a consistent message format across different providers, supporting text, multimodal content, tool calls, and structured content blocks.

## Installation

```bash
pip install langchain
```

## Core Message Components

Every message contains three essential elements:

| Element | Purpose |
|---------|---------|
| **Role** | Message type identifier (system, user, assistant, tool) |
| **Content** | Actual payload (text, images, audio, documents) |
| **Metadata** | Optional fields for response info, IDs, token counts |

## Message Types

### SystemMessage

Provides initial instructions that prime model behavior. Used to establish tone, define role, and set response guidelines.

```python
from langchain.messages import SystemMessage, HumanMessage

system_msg = SystemMessage("You are a helpful coding assistant.")
messages = [system_msg, HumanMessage("How do I create a REST API?")]
response = model.invoke(messages)
```

### HumanMessage

Represents user input supporting text, images, audio, files, and multimodal content.

```python
from langchain.messages import HumanMessage

human_msg = HumanMessage(content="Hello!", name="alice", id="msg_123")
```

### AIMessage

Contains model-generated output including text, tool calls, and provider-specific metadata.

| Attribute | Description |
|-----------|-------------|
| `text` | Text content of message |
| `content` | Raw message content |
| `content_blocks` | Standardized content blocks |
| `tool_calls` | Model-generated tool calls |
| `usage_metadata` | Token counts when available |
| `response_metadata` | Provider response information |

```python
response = model.invoke("Explain AI")
print(type(response))  # <class 'langchain.messages.AIMessage'>
```

### ToolMessage

Passes tool execution results back to the model. Must reference the corresponding tool call ID.

```python
from langchain.messages import ToolMessage

tool_message = ToolMessage(
    content=weather_result,
    tool_call_id="call_123",
    name="get_weather"
)
```

| Attribute | Required | Description |
|-----------|----------|-------------|
| `content` | Yes | Tool output (stringified) |
| `tool_call_id` | Yes | Matching AIMessage call ID |
| `name` | No | Tool name that was called |
| `artifact` | No | Supplementary data not sent to model |

## Usage Patterns

### Text Prompts

Simple string input for standalone requests:

```python
response = model.invoke("Write a haiku about spring")
```

### Message Prompts

List of message objects for multi-turn conversations:

```python
messages = [
    SystemMessage("You are a poetry expert"),
    HumanMessage("Write a haiku about spring"),
    AIMessage("Cherry blossoms bloom...")
]
response = model.invoke(messages)
```

### Dictionary Format

OpenAI-compatible format:

```python
messages = [
    {"role": "system", "content": "You are a poetry expert"},
    {"role": "user", "content": "Write a haiku about spring"},
    {"role": "assistant", "content": "Cherry blossoms bloom..."}
]
response = model.invoke(messages)
```

## Message Content Formats

Messages accept content in three formats:

### String Content

```python
human_message = HumanMessage("Hello, how are you?")
```

### Provider-Native List

```python
human_message = HumanMessage(content=[
    {"type": "text", "text": "Hello?"},
    {"type": "image_url", "image_url": {"url": "https://example.com/image.jpg"}}
])
```

### Standard Content Blocks

```python
human_message = HumanMessage(content_blocks=[
    {"type": "text", "text": "Hello?"},
    {"type": "image", "url": "https://example.com/image.jpg"}
])
```

## Standard Content Blocks Reference

### Core Blocks

| Block Type | Key Fields |
|------------|------------|
| `TextContentBlock` | `type: "text"`, `text`, `annotations`, `extras` |
| `ReasoningContentBlock` | `type: "reasoning"`, `reasoning`, `extras` |

### Multimodal Blocks

All multimodal blocks support `url`, `base64`, `id`, and `mime_type` fields.

| Block Type | Type Value |
|------------|------------|
| `ImageContentBlock` | `"image"` |
| `AudioContentBlock` | `"audio"` |
| `VideoContentBlock` | `"video"` |
| `FileContentBlock` | `"file"` |
| `PlainTextContentBlock` | `"text-plain"` |

### Tool Calling Blocks

| Block Type | Type Value | Key Fields |
|------------|------------|------------|
| `ToolCall` | `"tool_call"` | `name`, `args`, `id` (all required) |
| `ToolCallChunk` | `"tool_call_chunk"` | `name`, `args` (partial), `id`, `index` |
| `InvalidToolCall` | `"invalid_tool_call"` | `name`, `args`, `error` |

### Server-Side Tool Blocks

| Block Type | Type Value | Key Fields |
|------------|------------|------------|
| `ServerToolCall` | `"server_tool_call"` | `id`, `name`, `args` |
| `ServerToolCallChunk` | `"server_tool_call_chunk"` | `id`, `name`, `args`, `index` |
| `ServerToolResult` | `"server_tool_result"` | `tool_call_id`, `status`, `output` |

### Provider-Specific Block

`NonStandardContentBlock` - `type: "non_standard"`, `value` (provider-specific data).

## Multimodal Input Examples

### Image Input

```python
# From URL
message = {
    "role": "user",
    "content": [
        {"type": "text", "text": "Describe this image."},
        {"type": "image", "url": "https://example.com/image.jpg"}
    ]
}

# From base64
message = {
    "role": "user",
    "content": [
        {"type": "text", "text": "Describe this image."},
        {"type": "image", "base64": "AAAAIGZ0eXBtcDQyAAA...", "mime_type": "image/jpeg"}
    ]
}

# From File ID
message = {
    "role": "user",
    "content": [
        {"type": "text", "text": "Describe this image."},
        {"type": "image", "file_id": "file-abc123"}
    ]
}
```

### PDF Document Input

```python
# From URL
message = {
    "role": "user",
    "content": [
        {"type": "text", "text": "Describe this document."},
        {"type": "file", "url": "https://example.com/document.pdf"}
    ]
}

# From base64
message = {
    "role": "user",
    "content": [
        {"type": "text", "text": "Describe this document."},
        {"type": "file", "base64": "AAAAIGZ0eXBtcDQyAAA...", "mime_type": "application/pdf"}
    ]
}
```

### Audio Input

```python
# From base64
message = {
    "role": "user",
    "content": [
        {"type": "text", "text": "Describe this audio."},
        {"type": "audio", "base64": "AAAAIGZ0eXBtcDQyAAA...", "mime_type": "audio/wav"}
    ]
}

# From File ID
message = {
    "role": "user",
    "content": [
        {"type": "text", "text": "Describe this audio."},
        {"type": "audio", "file_id": "file-abc123"}
    ]
}
```

### Video Input

```python
# From base64
message = {
    "role": "user",
    "content": [
        {"type": "text", "text": "Describe this video."},
        {"type": "video", "base64": "AAAAIGZ0eXBtcDQyAAA...", "mime_type": "video/mp4"}
    ]
}

# From File ID
message = {
    "role": "user",
    "content": [
        {"type": "text", "text": "Describe this video."},
        {"type": "video", "file_id": "file-abc123"}
    ]
}
```

## Streaming Messages

During streaming, receive `AIMessageChunk` objects that combine into full messages:

```python
full_message = None
for chunk in model.stream("Hi"):
    full_message = chunk if full_message is None else full_message + chunk
```

## Token Usage Tracking

```python
response = model.invoke("Hello!")
response.usage_metadata
# Returns: {'input_tokens': 8, 'output_tokens': 304, 'total_tokens': 312}
```

## Tool Calls in AIMessage

```python
model_with_tools = model.bind_tools([get_weather])
response = model_with_tools.invoke("What's the weather in Paris?")

for tool_call in response.tool_calls:
    print(f"Tool: {tool_call['name']}")
    print(f"Args: {tool_call['args']}")
    print(f"ID: {tool_call['id']}")
```

## Tool Execution Flow

```python
from langchain.messages import AIMessage, HumanMessage, ToolMessage

ai_message = AIMessage(
    content=[],
    tool_calls=[{
        "name": "get_weather",
        "args": {"location": "San Francisco"},
        "id": "call_123"
    }]
)

tool_message = ToolMessage(
    content="Sunny, 72F",
    tool_call_id="call_123"
)

messages = [
    HumanMessage("What's the weather?"),
    ai_message,
    tool_message
]
response = model.invoke(messages)
```

## Standard Content Block Parsing

Messages from different providers parse into a consistent format:

```python
message = AIMessage(
    content=[{"type": "thinking", "thinking": "..."}],
    response_metadata={"model_provider": "anthropic"}
)
message.content_blocks  # Returns standardized format
```

Enable standard content output:

```python
model = init_chat_model("gpt-5-nano", output_version="v1")
```

## Key APIs

| Class | Description |
|-------|-------------|
| `SystemMessage` | System instructions for model behavior |
| `HumanMessage` | User input (text and multimodal) |
| `AIMessage` | Model-generated response |
| `AIMessageChunk` | Streaming response fragment |
| `ToolMessage` | Tool execution result |

## Best Practices

- Use text prompts for simple, single requests without conversation history
- Use message prompts for conversations requiring history and system instructions
- Include system messages to establish model behavior and constraints
- Use `content_blocks` property for type-safe, provider-agnostic content access
- Store supplementary tool data in `ToolMessage.artifact` (not sent to model)
- Check provider documentation for supported file formats and size limits
- Use dictionary format for OpenAI-compatible code
- Always match `tool_call_id` between AIMessage tool calls and ToolMessage responses
