# LangChain providers

## Contents

- [Overview](#overview)
- [OpenAI](#openai)
- [Anthropic](#anthropic)
- [Google](#google)
- [AWS](#aws)
- [Ollama](#ollama)
- [Provider comparison](#provider-comparison)
- [Best practices](#best-practices)

## Overview

LangChain integrates with AI and cloud providers through dedicated packages. Each provider offers a different mix of chat models, embedding models, tools, document loaders, vector stores, and retrievers. This reference covers five providers: OpenAI, Anthropic, Google, AWS, and Ollama.

## OpenAI

### Installation

```bash
pip install langchain-openai
```

### Chat models

```python
from langchain_openai import ChatOpenAI

# Standard usage
llm = ChatOpenAI(model="gpt-4o")

# Azure-hosted
from langchain_openai import AzureChatOpenAI
llm = AzureChatOpenAI(deployment_name="gpt-4o")
```

### Embedding models

```python
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings()

# Azure-hosted
from langchain_openai import AzureOpenAIEmbeddings
embeddings = AzureOpenAIEmbeddings()
```

### Available integrations

| Component | Class | Description |
|---|---|---|
| Chat Model | `ChatOpenAI` | OpenAI chat models (GPT-4o, o1, etc.) |
| Chat Model | `AzureChatOpenAI` | Azure-hosted OpenAI chat models |
| Embeddings | `OpenAIEmbeddings` | Text embedding models |
| Embeddings | `AzureOpenAIEmbeddings` | Azure-hosted embeddings |
| Tool | `DallEAPIWrapper` | Text-to-image generation with DALL-E |
| Retriever | `ChatGPTPluginRetriever` | Real-time data access (sports, finance) |
| Document Loader | `ChatGPTLoader` | Import ChatGPT conversation histories |
| Chain | `OpenAIModerationChain` | Content safety detection |

## Anthropic

### Installation

```bash
pip install langchain-anthropic
```

### Chat models

```python
from langchain_anthropic import ChatAnthropic

llm = ChatAnthropic(model="claude-sonnet-4-6")

# With extended thinking
llm = ChatAnthropic(
    model="claude-sonnet-4-6",
    thinking={"type": "enabled", "budget_tokens": 10000},
)
```

### Available integrations

| Component | Class | Description |
|---|---|---|
| Chat Model | `ChatAnthropic` | Claude chat models |
| Middleware | `AnthropicMiddleware` | Anthropic-specific middleware for Claude |
| LLM (Legacy) | `AnthropicLLM` | Legacy text completion models |

### Vertex AI access

Anthropic models are also available through Google's Vertex AI:

```python
from langchain_google_vertexai import ChatAnthropicVertex

llm = ChatAnthropicVertex(model_name="claude-sonnet-4-6")
```

## Google

### Installation

```bash
# Unified SDK (recommended, v4.0.0+)
pip install langchain-google-genai

# Vertex AI specific features
pip install langchain-google-vertexai

# Community integrations
pip install langchain-google-community
```

### Chat models

```python
from langchain_google_genai import ChatGoogleGenerativeAI

# Gemini Developer API (quick setup with API key)
llm = ChatGoogleGenerativeAI(model="gemini-2.0-flash")

# Vertex AI backend (enterprise Google Cloud integration)
llm = ChatGoogleGenerativeAI(
    model="gemini-2.0-flash",
    project="my-project",
    location="us-central1"
)
```

Since `langchain-google-genai` v4.0.0, the unified `google-genai` SDK supports both the Gemini Developer API and Vertex AI backends.

### Embedding models

```python
from langchain_google_genai import GoogleGenerativeAIEmbeddings

embeddings = GoogleGenerativeAIEmbeddings(model="models/embedding-001")
```

### Available integrations

| Category | Components |
|---|---|
| Chat Models | ChatGoogleGenerativeAI, ChatAnthropicVertex, VertexModelGardenLlama, VertexModelGardenMistral |
| Embeddings | GoogleGenerativeAIEmbeddings |
| Document Loaders | BigQuery, Cloud SQL (MySQL/PostgreSQL/SQL Server), Firestore, Cloud Storage, Google Drive, Speech-to-Text, Cloud Vision |
| Vector Stores | AlloyDB, BigQuery Vector Search, Cloud Spanner, Cloud Bigtable, Firestore, Vertex AI Vector Search |
| Retrievers | Vertex AI Search, Document AI Warehouse |
| Tools | Text-to-Speech, Document AI, Google Translate, Google Search, Gmail, Drive, Finance, Places, Scholar |
| Evaluators | VertexStringEvaluator, VertexPairWiseStringEvaluator |

### Vertex AI vs Gemini Developer API

| Feature | Gemini Developer API | Vertex AI |
|---|---|---|
| Setup | API key | Google Cloud project |
| Best for | Quick prototyping | Enterprise production |
| Package | `langchain-google-genai` | `langchain-google-genai` (v4+) or `langchain-google-vertexai` |

## AWS

### Installation

```bash
pip install langchain-aws
```

### Chat models

```python
# Amazon Bedrock
from langchain_aws import ChatBedrock
llm = ChatBedrock(model_id="anthropic.claude-v2")

# Bedrock Converse (recommended for standard use cases)
from langchain_aws import ChatBedrockConverse
llm = ChatBedrockConverse(model_id="anthropic.claude-v2")
```

Bedrock provides managed access to foundation models from AI21 Labs, Anthropic, Cohere, Meta, and Stability AI.

### Embedding models

```python
from langchain_aws import BedrockEmbeddings
embeddings = BedrockEmbeddings()
```

### Available integrations

| Category | Components |
|---|---|
| Chat Models | ChatBedrock, ChatBedrockConverse |
| LLMs | BedrockLLM, AmazonAPIGateway, SagemakerEndpoint |
| Embeddings | BedrockEmbeddings, SagemakerEndpointEmbeddings |
| Document Loaders | S3 (Directory/File), Textract, Athena, Glue Catalog |
| Vector Stores | OpenSearch, DocumentDB, MemoryDB |
| Retrievers | Amazon Kendra, Bedrock Knowledge Bases |
| Tools | AWS Lambda, Bedrock AgentCore Browser, Bedrock AgentCore Code Interpreter |
| Graphs | Amazon Neptune (Cypher/SPARQL) |
| Memory | AgentCoreMemorySaver, AgentCoreMemoryStore |
| Runtime | AgentCore Runtime (serverless LangGraph execution) |

### Key AWS services

| Service | Purpose |
|---|---|
| Bedrock | Managed foundation model access |
| Bedrock Converse | Unified conversational API (recommended) |
| SageMaker | Custom model hosting and inference |
| Kendra | Enterprise search with NLP |
| Textract | Text/data extraction from scanned documents |
| Lambda | Serverless compute for tool execution |
| AgentCore | Managed agent runtime with observability |

## Ollama

### Installation

```bash
pip install langchain-ollama
```

Requires Ollama installed locally. See the Ollama model library for supported models.

### Chat models

```python
from langchain_ollama import ChatOllama

llm = ChatOllama(model="llama3.1")
```

### Embedding models

```python
from langchain_ollama import OllamaEmbeddings

embeddings = OllamaEmbeddings(model="llama3.1")
```

### Available integrations

| Component | Class | Description |
|---|---|---|
| Chat Model | `ChatOllama` | Local chat models |
| Embeddings | `OllamaEmbeddings` | Local text embeddings |
| LLM (Legacy) | `OllamaLLM` | Legacy text completion (deprecated) |

### Use cases

- Local development and testing without API costs
- Privacy-sensitive applications (data stays on-device)
- Offline usage scenarios
- Running open-source models (Llama, Mistral, Gemma, etc.)

## Provider comparison

| Feature | OpenAI | Anthropic | Google | AWS | Ollama |
|---|---|---|---|---|---|
| Chat Models | Yes | Yes | Yes | Yes | Yes |
| Embeddings | Yes | No | Yes | Yes | Yes |
| Document Loaders | Yes | No | Yes | Yes | No |
| Vector Stores | No | No | Yes | Yes | No |
| Retrievers | Yes | No | Yes | Yes | No |
| Tools | Yes | No | Yes | Yes | No |
| Local Execution | No | No | No | No | Yes |
| Cloud-Native | Yes | Yes | Yes | Yes | No |

## Best practices

- Use `ChatBedrockConverse` over `ChatBedrock` for standard AWS use cases
- For Google, use `langchain-google-genai` v4+ for unified Gemini/Vertex AI support
- Use Ollama for local development to avoid API costs during prototyping
- Keep provider-specific API keys in environment variables, never in code
- Consider Azure-hosted variants (AzureChatOpenAI, AzureOpenAIEmbeddings) for enterprise deployments with compliance requirements
- Use `init_chat_model("provider:model")` for provider-agnostic model initialization
