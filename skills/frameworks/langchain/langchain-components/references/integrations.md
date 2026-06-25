# LangChain Integrations

## Contents

- [Overview](#overview)
- [Integration categories](#integration-categories)
- [Chat models](#chat-models)
- [Embedding models](#embedding-models)
- [Document loaders](#document-loaders)
- [Vector stores](#vector-stores)
- [Retrievers](#retrievers)
- [Tools](#tools)
- [Text splitters](#text-splitters)
- [Stores (key-value)](#stores-key-value)
- [Popular providers](#popular-providers)
- [Best practices](#best-practices)

## Overview

LangChain has 1000+ integrations covering chat and embedding models, tools and toolkits, document loaders, vector stores, and more. A provider is a third-party service or platform that LangChain connects to. Each integration is published on PyPI as a `langchain-[provider]` package.

## Integration categories

| Category | Purpose | Count |
|---|---|---|
| Chat models | Conversational AI interfaces | 100+ |
| Embedding models | Text-to-vector transformation | 80+ |
| Document loaders | Data ingestion from many sources | 200+ |
| Vector stores | Similarity search and storage | 100+ |
| Retrievers | Document retrieval interfaces | 70+ |
| Tools | Agent-callable utilities | 150+ |
| Text splitters | Document chunking strategies | 20+ |
| Stores | Key-value storage for caching | 10+ |

## Chat models

Chat models take a sequence of messages as input and return a message, unlike traditional string-based LLMs.

### Featured models

| Provider | Package | Tool calling | Structured output | Multimodal |
|---|---|---|---|---|
| OpenAI | `langchain-openai` | Yes | Yes | Yes |
| Anthropic | `langchain-anthropic` | Yes | Yes | Yes |
| Google GenAI | `langchain-google-genai` | Yes | Yes | Yes |
| Azure OpenAI | `langchain-openai` | Yes | Yes | Yes |
| AWS Bedrock | `langchain-aws` | Yes | Yes | Varies |
| Groq | `langchain-groq` | Yes | Yes | Varies |
| Ollama | `langchain-ollama` | Yes | Yes | Varies |
| MistralAI | `langchain-mistralai` | Yes | Yes | No |

### Chat Completions API compatibility

Some providers expose endpoints compatible with OpenAI's Chat Completions API. Point `ChatOpenAI` at them with a custom `base_url`. Non-standard response fields may not be preserved.

### Routers and proxies

OpenRouter gives access to models from many providers through a single API, which centralizes credentials and makes switching models easy.

## Embedding models

Embedding models turn text into fixed-length vectors that capture semantic meaning, which makes similarity search and comparison possible.

### Core interface

```python
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings()

# Embed multiple documents
vectors = embeddings.embed_documents(["text 1", "text 2"])

# Embed a single query
query_vector = embeddings.embed_query("search query")
```

### Similarity metrics

| Metric | Description |
|---|---|
| Cosine similarity | Measures the angle between vectors |
| Euclidean distance | Measures straight-line distance |
| Dot product | Measures vector projection |

### Caching embeddings

`CacheBackedEmbeddings` stores embeddings in a key-value store, keyed by a hash of the text:

```python
from langchain.embeddings import CacheBackedEmbeddings
from langchain.storage import LocalFileStore

store = LocalFileStore("./cache/")
cached_embeddings = CacheBackedEmbeddings.from_bytes_store(
    underlying_embeddings=embeddings,
    document_embedding_cache=store,
    namespace="my-model"  # prevents collisions across models
)
```

Key parameters:
- `underlying_embedder` - the embedding model
- `document_embedding_cache` - ByteStore for caching
- `batch_size` - documents between store updates
- `namespace` - prevents collisions across models (always set this)
- `query_embedding_cache` - optional query caching

## Document loaders

Document loaders read data from many sources into LangChain's Document format through one interface.

### Core interface

```python
from langchain_community.document_loaders.csv_loader import CSVLoader

loader = CSVLoader(file_path="data.csv")

# Load all documents at once
documents = loader.load()

# Stream documents progressively (for large datasets)
for document in loader.lazy_load():
    print(document)
```

### Loader categories

| Category | Examples |
|---|---|
| Webpages | Web, RecursiveURL, Sitemap, Firecrawl, Spider |
| PDFs | PyPDF, PyMuPDF, PDFPlumber, PDFMiner, Unstructured |
| Cloud storage | AWS S3, Azure Blob, Google Cloud Storage, Google Drive, Dropbox, OneDrive |
| Databases | MongoDB, Cassandra, Snowflake, BigQuery |
| Social/Messaging | Twitter, Reddit, Telegram, WhatsApp, Discord, Slack |
| Productivity | Notion, GitHub, Figma, Jira, Trello |
| Academic | Arxiv, PubMed, Wikipedia |
| Common files | CSV, JSON, HTML, Markdown |

## Vector stores

Vector stores embed data and run similarity searches in two phases: indexing (documents to vectors) and querying (query to similar results).

### Core interface

```python
from langchain_core.vectorstores import InMemoryVectorStore

vector_store = InMemoryVectorStore(embedding=embeddings)

# Add documents
vector_store.add_documents(documents=[doc1, doc2], ids=["id1", "id2"])

# Delete documents
vector_store.delete(ids=["id1"])

# Similarity search
similar_docs = vector_store.similarity_search("your query here", k=5)
```

### Search parameters

| Parameter | Description |
|---|---|
| `k` | Number of results to return |
| `filter` | Metadata-based filtering (support varies by implementation) |

### Popular vector stores

| Store | Type | Package |
|---|---|---|
| Chroma | Open-source | `langchain-chroma` |
| FAISS | Open-source | `langchain-community` |
| Pinecone | Cloud | `langchain-pinecone` |
| Qdrant | Open-source/Cloud | `langchain-qdrant` |
| Milvus | Open-source | `langchain-milvus` |
| PostgreSQL (pgvector) | Self-hosted | `langchain-postgres` |
| Elasticsearch | Self-hosted/Cloud | `langchain-elasticsearch` |
| MongoDB Atlas | Cloud | `langchain-mongodb` |
| Redis | Self-hosted | `langchain-redis` |

## Retrievers

Retrievers take a string query and return Document objects. They are more general than vector stores and do not need to store anything. Every vector store can be turned into a retriever.

### Types

**Bring-your-own documents:**

| Retriever | Type | Package |
|---|---|---|
| AmazonKnowledgeBasesRetriever | Cloud | `langchain-aws` |
| AzureAISearchRetriever | Cloud | `langchain-community` |
| ElasticsearchRetriever | Self-hosted/Cloud | `langchain-elasticsearch` |
| NVIDIARetriever | Self-hosted | `langchain-nvidia-ai-endpoints` |
| VertexAISearchRetriever | Cloud | `langchain-google-community` |

**External index retrievers:**

| Retriever | Source | Package |
|---|---|---|
| ArxivRetriever | Scholarly articles | `langchain-community` |
| TavilySearchAPIRetriever | Internet search | `langchain-community` |
| WikipediaRetriever | Wikipedia | `langchain-community` |

## Tools

Tools are utilities a model calls: the model generates their inputs, and their outputs go back to the model. A toolkit groups related tools.

### Categories

| Category | Options | Notable free tier |
|---|---|---|
| Search | 16 options | DuckDuckGo, Brave, Exa (1K/mo), Tavily (1K/mo) |
| Code interpreters | 4 options | Azure Container Apps, Riza (self-hosted) |
| Productivity | GitHub, GitLab, Gmail, Jira, Slack, Twilio | Most free with rate limits |
| Web browsing | PlayWright, MultiOn | PlayWright (free) |
| Databases | SQL, Cassandra, Spark, Stardog | Varies |
| Financial | GOAT, Privy, Ampersend | GOAT, Privy (free) |

Composio provides 500+ integrations with OAuth handling and event-driven workflows on a freemium model.

## Text splitters

Text splitters break large documents into smaller chunks that can be retrieved individually.

### Installation

```bash
pip install -U langchain-text-splitters
```

### Splitting strategies

**1. Text structure-based (recommended default)**

```python
from langchain_text_splitters import RecursiveCharacterTextSplitter

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=100,
    chunk_overlap=0
)
texts = text_splitter.split_text(document)
```

RecursiveCharacterTextSplitter keeps larger units (paragraphs) intact where it can, and falls back to sentences, then words, only when needed.

**2. Length-based (token or character)**

```python
from langchain_text_splitters import CharacterTextSplitter

text_splitter = CharacterTextSplitter.from_tiktoken_encoder(
    encoding_name="cl100k_base",
    chunk_size=100,
    chunk_overlap=0
)
texts = text_splitter.split_text(document)
```

**3. Document structure-based**

Uses the formatting already present in structured documents:
- Markdown header-based splitting
- JSON object/array element splitting
- Code function/class splitting
- HTML tag-based splitting

## Stores (key-value)

Key-value stores are mainly used for caching embeddings. All implementations support the batch operations `mget()`, `mset()`, `mdelete()`, and `yield_keys()`.

### Available implementations

| Store | Use case |
|---|---|
| InMemoryByteStore | Local development |
| LocalFileStore | Local development |
| RedisStore | Production |
| AstraDBByteStore | Production (cloud) |
| CassandraByteStore | Production |
| ElasticsearchEmbeddingsCache | Production |
| UpstashRedisByteStore | Production (serverless) |
| BigtableByteStore | Production (Google Cloud) |

## Popular providers

| Provider | Package | Primary capabilities |
|---|---|---|
| OpenAI | `langchain-openai` | Chat, Embeddings, DALL-E, Moderation |
| Anthropic | `langchain-anthropic` | Chat (Claude), Middleware |
| Google | `langchain-google-genai` | Chat (Gemini), Embeddings, Search, Drive |
| AWS | `langchain-aws` | Bedrock, SageMaker, Kendra, S3, Lambda |
| Ollama | `langchain-ollama` | Local Chat, Embeddings |
| Groq | `langchain-groq` | Fast inference Chat |
| MistralAI | `langchain-mistralai` | Chat, Embeddings |
| Cohere | `langchain-cohere` | Chat, Embeddings, Reranking |
| Fireworks | `langchain-fireworks` | Chat, Embeddings |
| NVIDIA | `langchain-nvidia-ai-endpoints` | Chat, Embeddings, Retrieval |

## Best practices

- Start with `RecursiveCharacterTextSplitter` for text splitting unless you have structured documents
- Always set `namespace` when using `CacheBackedEmbeddings` to prevent collisions
- Use `lazy_load()` for large document collections to limit memory use
- Every vector store can be turned into a retriever. Use a retriever when you need broader search than similarity lookup
- Choose embedding similarity metrics based on your use case (cosine for normalized vectors, Euclidean for absolute distances)
- Use batch operations (`mget`, `mset`) with stores to cut network round-trips
