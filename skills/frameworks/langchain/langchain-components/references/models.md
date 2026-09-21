# Models

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Model initialization](#model-initialization)
- [Key parameters](#key-parameters)
- [Invocation methods](#invocation-methods)
- [Tool calling](#tool-calling)
- [Structured output](#structured-output)
- [Structured output in agents](#structured-output-in-agents)
- [Advanced features](#advanced-features)
- [Key APIs](#key-apis)
- [Best practices](#best-practices)

## Overview

LangChain gives one interface to large language models (LLMs) across providers. Models support tool calling, structured output, multimodal input and output (images, audio, video), and reasoning. `init_chat_model` is the recommended entry point because it is provider-agnostic; provider-specific classes are also available.

## Installation

```bash
pip install langchain
# Provider-specific packages:
pip install langchain-openai
pip install langchain-anthropic
pip install langchain-google-genai
pip install langchain-aws
pip install langchain-huggingface
```

## Model initialization

### Using `init_chat_model` (recommended)

```python
from langchain.chat_models import init_chat_model
model = init_chat_model("model-name")
response = model.invoke("Your question here")
```

### Provider-specific initialization

```python
# OpenAI
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.2")

# Anthropic
from langchain_anthropic import ChatAnthropic
model = ChatAnthropic(model="claude-sonnet-4-6")

# Google Gemini
from langchain_google_genai import ChatGoogleGenerativeAI
model = ChatGoogleGenerativeAI(model="gemini-2.5-flash-lite")

# AWS Bedrock
from langchain_aws import ChatBedrock
model = ChatBedrock(model="us.anthropic.claude-sonnet-4-6")

# HuggingFace
from langchain_huggingface import ChatHuggingFace, HuggingFaceEndpoint
llm = HuggingFaceEndpoint(repo_id="microsoft/Phi-3-mini-4k-instruct")
model = ChatHuggingFace(llm=llm)
```

## Key parameters

| Parameter | Description |
|-----------|-------------|
| `model` | Model identifier string |
| `api_key` | Authentication credential |
| `temperature` | Controls randomness (higher = more creative) |
| `max_tokens` | Limits response length |
| `timeout` | Maximum wait time in seconds |
| `max_retries` | Retry count (default: 6) |

```python
model = init_chat_model(
    "claude-sonnet-4-6",
    temperature=0.7,
    timeout=30,
    max_tokens=1000,
    max_retries=6
)
```

## Invocation methods

### Invoke (synchronous)

```python
response = model.invoke("Why do parrots talk?")
```

With conversation history:

```python
conversation = [
    {"role": "system", "content": "You are helpful..."},
    {"role": "user", "content": "Translate: I love programming."},
]
response = model.invoke(conversation)
```

### Stream (real-time output)

```python
for chunk in model.stream("Your question"):
    print(chunk.text, end="|", flush=True)
```

Advanced streaming with event filtering:

```python
async for event in model.astream_events("Hello"):
    if event["event"] == "on_chat_model_stream":
        print(f"Token: {event['data']['chunk'].text}")
```

### Batch (parallel processing)

```python
responses = model.batch([
    "Why do parrots have colorful feathers?",
    "How do airplanes fly?"
])
```

With concurrency limit:

```python
model.batch(inputs, config={'max_concurrency': 5})
```

With completion handling:

```python
for response in model.batch_as_completed(inputs):
    print(response)
```

## Tool calling

### Binding tools

```python
from langchain.tools import tool

@tool
def get_weather(location: str) -> str:
    """Get weather at a location."""
    return f"Sunny in {location}."

model_with_tools = model.bind_tools([get_weather])
response = model_with_tools.invoke("What's the weather in Boston?")

for tool_call in response.tool_calls:
    print(f"Tool: {tool_call['name']}")
    print(f"Args: {tool_call['args']}")
```

### Tool execution loop

```python
messages = [{"role": "user", "content": "Weather in Boston?"}]
ai_msg = model_with_tools.invoke(messages)
messages.append(ai_msg)

for tool_call in ai_msg.tool_calls:
    tool_result = get_weather.invoke(tool_call)
    messages.append(tool_result)

final_response = model_with_tools.invoke(messages)
```

### Forcing tool calls

```python
model.bind_tools([tool_1], tool_choice="any")
model.bind_tools([tool_1], tool_choice="tool_1")
```

### Parallel tool calls

```python
response = model_with_tools.invoke("Weather in Boston and Tokyo?")
# Returns multiple tool_calls simultaneously

# Disable parallelization
model.bind_tools([get_weather], parallel_tool_calls=False)
```

### Streaming tool calls

```python
for chunk in model_with_tools.stream("Weather in Boston?"):
    for tool_chunk in chunk.tool_call_chunks:
        if name := tool_chunk.get("name"):
            print(f"Tool: {name}")
```

## Structured output

### Using Pydantic models

```python
from pydantic import BaseModel, Field

class Movie(BaseModel):
    title: str = Field(..., description="Movie title")
    year: int = Field(..., description="Release year")
    director: str
    rating: float

model_with_structure = model.with_structured_output(Movie)
response = model_with_structure.invoke("Details about Inception")
```

### Using TypedDict

```python
from typing_extensions import TypedDict, Annotated

class MovieDict(TypedDict):
    title: Annotated[str, "Movie title"]
    year: Annotated[int, "Release year"]

model_with_structure = model.with_structured_output(MovieDict)
```

### Using JSON schema

```python
json_schema = {
    "title": "Movie",
    "type": "object",
    "properties": {
        "title": {"type": "string"},
        "year": {"type": "integer"}
    },
    "required": ["title", "year"]
}

model_with_structure = model.with_structured_output(
    json_schema,
    method="json_schema"
)
```

### Include raw output

```python
model_with_structure = model.with_structured_output(Movie, include_raw=True)
response = model_with_structure.invoke("Details...")
# Returns {'raw': AIMessage(...), 'parsed': Movie(...), 'parsing_error': None}
```

### Nested structures

```python
class Actor(BaseModel):
    name: str
    role: str

class MovieDetails(BaseModel):
    title: str
    cast: list[Actor]
    genres: list[str]
```

## Structured output in agents

### Response format configuration

The `response_format` parameter in `create_agent` accepts:

- `ProviderStrategy[T]` - uses native provider structured output (OpenAI, Anthropic, xAI, Gemini)
- `ToolStrategy[T]` - uses tool calling for structured output
- Schema type directly - auto-selects appropriate strategy
- `None` - no structured output

### Provider strategy

```python
from pydantic import BaseModel, Field
from langchain.agents import create_agent

class ContactInfo(BaseModel):
    name: str = Field(description="The name of the person")
    email: str = Field(description="Email address")
    phone: str = Field(description="Phone number")

agent = create_agent(model="gpt-5", response_format=ContactInfo)
result = agent.invoke({"messages": [{"role": "user", "content": "..."}]})
print(result["structured_response"])
```

### Tool calling strategy

For models lacking native structured output support:

```python
from langchain.agents import ToolStrategy

class ToolStrategy(Generic[SchemaT]):
    schema: type[SchemaT]
    tool_message_content: str | None
    handle_errors: Union[bool, str, type[Exception], ...]
```

Supports Union types for multiple response schemas:

```python
response_format = ToolStrategy(Union[ProductReview, CustomerComplaint])
```

### Error handling options

| Option | Behavior |
|--------|----------|
| `True` (default) | Catches all errors with default template |
| String value | Uses custom message for all errors |
| Exception type | Only catches specified exceptions |
| Tuple of types | Catches multiple specific exceptions |
| Callable | Custom error message generator |
| `False` | Disables retries, propagates exceptions |

Available exception classes:
- `StructuredOutputValidationError` - schema validation failures
- `MultipleStructuredOutputsError` - multiple tools incorrectly called

## Advanced features

### Model profiles

```python
model.profile
# Returns: {"max_input_tokens": 400000, "image_inputs": True, "tool_calling": True}

custom_profile = {"max_input_tokens": 100_000, "tool_calling": True}
model = init_chat_model("...", profile=custom_profile)
```

### Multimodal output

```python
response = model.invoke("Create a picture of a cat")
print(response.content_blocks)
# [{"type": "text", ...}, {"type": "image", "base64": "...", ...}]
```

### Reasoning

```python
for chunk in model.stream("Why colorful feathers?"):
    reasoning = [r for r in chunk.content_blocks if r["type"] == "reasoning"]
    print(reasoning if reasoning else chunk.text)
```

### Rate limiting

```python
from langchain_core.rate_limiters import InMemoryRateLimiter

rate_limiter = InMemoryRateLimiter(
    requests_per_second=0.1,
    check_every_n_seconds=0.1,
    max_bucket_size=10
)

model = init_chat_model("gpt-5", rate_limiter=rate_limiter)
```

### Custom base URL

```python
model = init_chat_model(
    model="MODEL_NAME",
    model_provider="openai",
    base_url="BASE_URL",
    api_key="YOUR_API_KEY"
)
```

### Token usage tracking

```python
from langchain_core.callbacks import get_usage_metadata_callback

with get_usage_metadata_callback() as cb:
    model.invoke("Hello")
    print(cb.usage_metadata)
```

### Configurable models

```python
configurable_model = init_chat_model(temperature=0)

configurable_model.invoke(
    "what's your name",
    config={"configurable": {"model": "gpt-5-nano"}}
)
```

With multiple configurable fields:

```python
model = init_chat_model(
    model="gpt-4.1-mini",
    temperature=0,
    configurable_fields=("model", "model_provider", "temperature", "max_tokens"),
    config_prefix="first"
)

model.invoke(
    "question",
    config={
        "configurable": {
            "first_model": "claude-sonnet-4-6",
            "first_temperature": 0.5,
            "first_max_tokens": 100
        }
    }
)
```

### Invocation configuration

```python
response = model.invoke(
    "Tell me a joke",
    config={
        "run_name": "joke_generation",
        "tags": ["humor", "demo"],
        "metadata": {"user_id": "123"},
        "callbacks": [handler],
        "max_concurrency": 5,
        "recursion_limit": 25
    }
)
```

### Log probabilities

```python
model = init_chat_model("gpt-4.1", model_provider="openai").bind(logprobs=True)
response = model.invoke("Question?")
print(response.response_metadata["logprobs"])
```

### Server-side tool use

```python
model = init_chat_model("gpt-4.1-mini")
tool = {"type": "web_search"}
model_with_tools = model.bind_tools([tool])

response = model_with_tools.invoke("Positive news from today?")
print(response.content_blocks)
```

## Key APIs

| Class/Function | Description |
|----------------|-------------|
| `init_chat_model()` | Provider-agnostic model initialization |
| `ChatOpenAI` | OpenAI-specific model class |
| `ChatAnthropic` | Anthropic-specific model class |
| `model.invoke()` | Synchronous single invocation |
| `model.stream()` | Real-time streaming output |
| `model.batch()` | Parallel batch processing |
| `model.bind_tools()` | Attach tools to a model |
| `model.with_structured_output()` | Constrain output format |
| `model.profile` | Access model capabilities |
| `InMemoryRateLimiter` | Client-side rate limiting |

## Best practices

- Use `init_chat_model` for provider-agnostic code that can switch models easily
- Set `temperature=0` for deterministic, reproducible outputs
- Keep `max_retries` at its default of 6 in production
- Use `batch()` with `max_concurrency` for throughput-sensitive workloads
- Use `with_structured_output()` with Pydantic models for type-safe responses
- Prefer `ProviderStrategy` for structured output when the model supports it
- Use `configurable_fields` to make model selection dynamic at runtime
- Track token usage with `get_usage_metadata_callback` for cost monitoring
