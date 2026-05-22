# LangChain Integrations

## Overview

LangChain provides 1000+ integrations across chat and embedding models, tools and toolkits, document loaders, vector stores, and more. A provider is a third-party service or platform that LangChain integrates with to access AI capabilities. Each integration follows the `langchain-[provider]` package naming pattern on PyPI.

## Integration Categories

| Category | Purpose | Count |
|---|---|---|
| Chat Models | Conversational AI interfaces | 100+ |
| Embedding Models | Text-to-vector transformation | 80+ |
| Document Loaders | Data ingestion from diverse sources | 200+ |
| Vector Stores | Similarity search and storage | 100+ |
| Retrievers | Document retrieval interfaces | 70+ |
| Tools | Agent-callable utilities | 150+ |
| Text Splitters | Document chunking strategies | 20+ |
| Stores | Key-value storage for caching | 10+ |

## Chat Models

Chat models accept message sequences as input and return messages as output, differing from traditional string-based LLMs.

### Featured Models

| Provider | Package | Tool Calling | Structured Output | Multimodal |
|---|---|---|---|---|
| OpenAI | `langchain-openai` | Yes | Yes | Yes |
| Anthropic | `langchain-anthropic` | Yes | Yes | Yes |
| Google GenAI | `langchain-google-genai` | Yes | Yes | Yes |
| Azure OpenAI | `langchain-openai` | Yes | Yes | Yes |
| AWS Bedrock | `langchain-aws` | Yes | Yes | Varies |
| Groq | `langchain-groq` | Yes | Yes | Varies |
| Ollama | `langchain-ollama` | Yes | Yes | Varies |
| MistralAI | `langchain-mistralai` | Yes | Yes | No |

### Chat Completions API Compatibility

Certain model providers offer endpoints compatible with OpenAI's Chat Completions API. Use `ChatOpenAI` with a custom `base_url` parameter for compatible endpoints, though non-standard response fields may not be preserved.

### Routers and Proxies

OpenRouter provides unified access to models across multiple providers through a single API interface, simplifying credential management and enabling model switching.

## Embedding Models

Embedding models transform raw text into fixed-length vectors that capture semantic meaning, enabling similarity-based search and comparison.

### Core Interface

```python
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings()

# Embed multiple documents
vectors = embeddings.embed_documents(["text 1", "text 2"])

# Embed a single query
query_vector = embeddings.embed_query("search query")
```

### Similarity Metrics

| Metric | Description |
|---|---|
| Cosine Similarity | Measures angle between vectors |
| Euclidean Distance | Measures straight-line distance |
| Dot Product | Measures vector projection |

### Caching Embeddings

`CacheBackedEmbeddings` stores embeddings in key-value stores using hashed text as cache keys:

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

## Document Loaders

Document loaders provide a standardized interface for reading data from diverse sources into LangChain's Document format.

### Core Interface

```python
from langchain_community.document_loaders.csv_loader import CSVLoader

loader = CSVLoader(file_path="data.csv")

# Load all documents at once
documents = loader.load()

# Stream documents progressively (for large datasets)
for document in loader.lazy_load():
    print(document)
```

### Loader Categories

| Category | Examples |
|---|---|
| Webpages | Web, RecursiveURL, Sitemap, Firecrawl, Spider |
| PDFs | PyPDF, PyMuPDF, PDFPlumber, PDFMiner, Unstructured |
| Cloud Storage | AWS S3, Azure Blob, Google Cloud Storage, Google Drive, Dropbox, OneDrive |
| Databases | MongoDB, Cassandra, Snowflake, BigQuery |
| Social/Messaging | Twitter, Reddit, Telegram, WhatsApp, Discord, Slack |
| Productivity | Notion, GitHub, Figma, Jira, Trello |
| Academic | Arxiv, PubMed, Wikipedia |
| Common Files | CSV, JSON, HTML, Markdown |

## Vector Stores

Vector stores embed data and perform similarity searches through a two-phase workflow: indexing (documents to vectors) and querying (query to similar results).

### Core Interface

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

### Search Parameters

| Parameter | Description |
|---|---|
| `k` | Number of results to return |
| `filter` | Metadata-based filtering (support varies by implementation) |

### Popular Vector Stores

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

Retrievers accept string queries and return Document objects. They are more general than vector stores and do not require storage capabilities. All vector stores can be cast to retrievers.

### Types

**Bring-Your-Own Documents:**

| Retriever | Type | Package |
|---|---|---|
| AmazonKnowledgeBasesRetriever | Cloud | `langchain-aws` |
| AzureAISearchRetriever | Cloud | `langchain-community` |
| ElasticsearchRetriever | Self-hosted/Cloud | `langchain-elasticsearch` |
| NVIDIARetriever | Self-hosted | `langchain-nvidia-ai-endpoints` |
| VertexAISearchRetriever | Cloud | `langchain-google-community` |

**External Index Retrievers:**

| Retriever | Source | Package |
|---|---|---|
| ArxivRetriever | Scholarly articles | `langchain-community` |
| TavilySearchAPIRetriever | Internet search | `langchain-community` |
| WikipediaRetriever | Wikipedia | `langchain-community` |

## Tools

Tools are utilities designed to be called by a model: their inputs are generated by models, and their outputs are passed back to models. A toolkit groups related tools for collaborative use.

### Categories

| Category | Options | Notable Free-Tier |
|---|---|---|
| Search | 16 options | DuckDuckGo, Brave, Exa (1K/mo), Tavily (1K/mo) |
| Code Interpreters | 4 options | Azure Container Apps, Riza (self-hosted) |
| Productivity | GitHub, GitLab, Gmail, Jira, Slack, Twilio | Most free with rate limits |
| Web Browsing | PlayWright, MultiOn | PlayWright (free) |
| Databases | SQL, Cassandra, Spark, Stardog | Varies |
| Financial | GOAT, Privy, Ampersend | GOAT, Privy (free) |

Composio provides 500+ integrations with OAuth handling and event-driven workflows on a freemium model.

## Text Splitters

Text splitters break large documents into smaller, individually retrievable chunks.

### Installation

```bash
pip install -U langchain-text-splitters
```

### Splitting Strategies

**1. Text Structure-Based (Recommended Default)**

```python
from langchain_text_splitters import RecursiveCharacterTextSplitter

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=100,
    chunk_overlap=0
)
texts = text_splitter.split_text(document)
```

RecursiveCharacterTextSplitter preserves larger units (paragraphs) when possible, progressively breaking down to sentences, then words if needed.

**2. Length-Based (Token or Character)**

```python
from langchain_text_splitters import CharacterTextSplitter

text_splitter = CharacterTextSplitter.from_tiktoken_encoder(
    encoding_name="cl100k_base",
    chunk_size=100,
    chunk_overlap=0
)
texts = text_splitter.split_text(document)
```

**3. Document Structure-Based**

Exploits inherent formatting in structured documents:
- Markdown header-based splitting
- JSON object/array element splitting
- Code function/class splitting
- HTML tag-based splitting

## Stores (Key-Value)

Key-value stores primarily used for caching embeddings. All implementations support batch operations: `mget()`, `mset()`, `mdelete()`, `yield_keys()`.

### Available Implementations

| Store | Use Case |
|---|---|
| InMemoryByteStore | Local development |
| LocalFileStore | Local development |
| RedisStore | Production |
| AstraDBByteStore | Production (cloud) |
| CassandraByteStore | Production |
| ElasticsearchEmbeddingsCache | Production |
| UpstashRedisByteStore | Production (serverless) |
| BigtableByteStore | Production (Google Cloud) |

## Popular Providers

| Provider | Package | Primary Capabilities |
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

## Best Practices

- Start with `RecursiveCharacterTextSplitter` for text splitting unless you have structured documents
- Always set `namespace` when using `CacheBackedEmbeddings` to prevent collisions
- Use `lazy_load()` for large document collections to manage memory
- All vector stores can be cast to retrievers - use retrievers when you need broader search capabilities
- Choose embedding similarity metrics based on your use case (cosine for normalized vectors, Euclidean for absolute distances)
- Use batch operations (`mget`, `mset`) with stores to minimize network round-trips
