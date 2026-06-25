# Messages

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core message components](#core-message-components)
- [Message types](#message-types)
- [Usage patterns](#usage-patterns)
- [Message content formats](#message-content-formats)
- [Standard content blocks reference](#standard-content-blocks-reference)
- [Multimodal input examples](#multimodal-input-examples)
- [Streaming messages](#streaming-messages)
- [Token usage tracking](#token-usage-tracking)
- [Tool calls in AIMessage](#tool-calls-in-aimessage)
- [Tool execution flow](#tool-execution-flow)
- [Standard content block parsing](#standard-content-block-parsing)
- [Key APIs](#key-apis)
- [Best practices](#best-practices)

## Overview

Messages are the basic unit of model interaction in LangChain. Each one carries a role, a content payload, and optional metadata, and together they represent the conversation state sent to an LLM. The message format is the same across providers and supports text, multimodal content, tool calls, and structured content blocks.

## Installation

```bash
pip install langchain
```

## Core message components

Every message has three elements:

| Element | Purpose |
|---------|---------|
| **Role** | Message type (system, user, assistant, tool) |
| **Content** | The payload (text, images, audio, documents) |
| **Metadata** | Optional fields for response info, IDs, token counts |

## Message types

### SystemMessage

Gives the model its initial instructions: tone, role, and response guidelines.

```python
from langchain.messages import SystemMessage, HumanMessage

system_msg = SystemMessage("You are a helpful coding assistant.")
messages = [system_msg, HumanMessage("How do I create a REST API?")]
response = model.invoke(messages)
```

### HumanMessage

Represents user input: text, images, audio, files, and other multimodal content.

```python
from langchain.messages import HumanMessage

human_msg = HumanMessage(content="Hello!", name="alice", id="msg_123")
```

### AIMessage

Holds model-generated output: text, tool calls, and provider-specific metadata.

| Attribute | Description |
|-----------|-------------|
| `text` | Text content of the message |
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

Passes tool execution results back to the model. It must reference the ID of the corresponding tool call.

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
| `name` | No | Name of the tool that was called |
| `artifact` | No | Supplementary data not sent to the model |

## Usage patterns

### Text prompts

Simple string input for standalone requests:

```python
response = model.invoke("Write a haiku about spring")
```

### Message prompts

A list of message objects, for multi-turn conversations:

```python
messages = [
    SystemMessage("You are a poetry expert"),
    HumanMessage("Write a haiku about spring"),
    AIMessage("Cherry blossoms bloom...")
]
response = model.invoke(messages)
```

### Dictionary format

OpenAI-compatible format:

```python
messages = [
    {"role": "system", "content": "You are a poetry expert"},
    {"role": "user", "content": "Write a haiku about spring"},
    {"role": "assistant", "content": "Cherry blossoms bloom..."}
]
response = model.invoke(messages)
```

## Message content formats

Messages accept content in three formats:

### String content

```python
human_message = HumanMessage("Hello, how are you?")
```

### Provider-native list

```python
human_message = HumanMessage(content=[
    {"type": "text", "text": "Hello?"},
    {"type": "image_url", "image_url": {"url": "https://example.com/image.jpg"}}
])
```

### Standard content blocks

```python
human_message = HumanMessage(content_blocks=[
    {"type": "text", "text": "Hello?"},
    {"type": "image", "url": "https://example.com/image.jpg"}
])
```

## Standard content blocks reference

### Core blocks

| Block type | Key fields |
|------------|------------|
| `TextContentBlock` | `type: "text"`, `text`, `annotations`, `extras` |
| `ReasoningContentBlock` | `type: "reasoning"`, `reasoning`, `extras` |

### Multimodal blocks

All multimodal blocks support `url`, `base64`, `id`, and `mime_type` fields.

| Block type | Type value |
|------------|------------|
| `ImageContentBlock` | `"image"` |
| `AudioContentBlock` | `"audio"` |
| `VideoContentBlock` | `"video"` |
| `FileContentBlock` | `"file"` |
| `PlainTextContentBlock` | `"text-plain"` |

### Tool calling blocks

| Block type | Type value | Key fields |
|------------|------------|------------|
| `ToolCall` | `"tool_call"` | `name`, `args`, `id` (all required) |
| `ToolCallChunk` | `"tool_call_chunk"` | `name`, `args` (partial), `id`, `index` |
| `InvalidToolCall` | `"invalid_tool_call"` | `name`, `args`, `error` |

### Server-side tool blocks

| Block Type | Type Value | Key Fields |
|------------|------------|------------|
| `ServerToolCall` | `"server_tool_call"` | `id`, `name`, `args` |
| `ServerToolCallChunk` | `"server_tool_call_chunk"` | `id`, `name`, `args`, `index` |
| `ServerToolResult` | `"server_tool_result"` | `tool_call_id`, `status`, `output` |

### Provider-specific block

`NonStandardContentBlock`: `type: "non_standard"`, `value` (provider-specific data).

## Multimodal input examples

### Image input

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

# From file ID
message = {
    "role": "user",
    "content": [
        {"type": "text", "text": "Describe this image."},
        {"type": "image", "file_id": "file-abc123"}
    ]
}
```

### PDF document input

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

### Audio input

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

### Video input

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

## Streaming messages

Streaming yields `AIMessageChunk` objects that add up to a full message:

```python
full_message = None
for chunk in model.stream("Hi"):
    full_message = chunk if full_message is None else full_message + chunk
```

## Token usage tracking

```python
response = model.invoke("Hello!")
response.usage_metadata
# Returns: {'input_tokens': 8, 'output_tokens': 304, 'total_tokens': 312}
```

## Tool calls in AIMessage

```python
model_with_tools = model.bind_tools([get_weather])
response = model_with_tools.invoke("What's the weather in Paris?")

for tool_call in response.tool_calls:
    print(f"Tool: {tool_call['name']}")
    print(f"Args: {tool_call['args']}")
    print(f"ID: {tool_call['id']}")
```

## Tool execution flow

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

## Standard content block parsing

Messages from different providers parse into one consistent format:

```python
message = AIMessage(
    content=[{"type": "thinking", "thinking": "..."}],
    response_metadata={"model_provider": "anthropic"}
)
message.content_blocks  # Returns standardized format
```

To get standard content output:

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

## Best practices

- Use text prompts for simple, single requests without conversation history
- Use message prompts for conversations that need history and system instructions
- Include a system message to set model behavior and constraints
- Use `content_blocks` property for type-safe, provider-agnostic content access
- Store supplementary tool data in `ToolMessage.artifact` (not sent to model)
- Check provider documentation for supported file formats and size limits
- Use dictionary format for OpenAI-compatible code
- Always match `tool_call_id` between AIMessage tool calls and their ToolMessage responses
