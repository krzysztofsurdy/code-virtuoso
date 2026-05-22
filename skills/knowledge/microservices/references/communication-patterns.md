# Communication Patterns

## Synchronous Communication

### REST

REST over HTTP remains the most common inter-service communication style. It is well understood, widely supported, and simple to debug with standard tools. Use it when the caller needs an immediate response and the interaction follows a resource-oriented model.

**Trade-offs:** Simple to implement and test. Generates tight temporal coupling - the caller blocks until the response arrives. If the downstream service is slow or down, the caller suffers directly.

### gRPC

gRPC uses HTTP/2 for transport and Protocol Buffers for serialization, producing compact binary messages with strongly typed contracts. It supports unary calls, server streaming, client streaming, and bidirectional streaming.

**When to prefer gRPC over REST:**
- High-throughput internal service-to-service calls where serialization overhead matters
- Streaming use cases (real-time feeds, large data transfers)
- Polyglot environments where auto-generated clients from a shared `.proto` file reduce integration effort

**Trade-offs:** Faster and more bandwidth-efficient than JSON/REST. Harder to debug without tooling (binary protocol). Browser support requires gRPC-Web or a proxy layer.

### GraphQL Federation

GraphQL federation composes a single graph from schemas owned by different services. Each service defines and resolves its own portion of the schema, and a gateway merges them into a unified API for clients.

**When it fits:**
- Multiple teams own different domain areas but clients need a single query endpoint
- Frontend clients have diverse data needs that would require many REST endpoints
- You want to avoid over-fetching and under-fetching across service boundaries

**Trade-offs:** Reduces client-side complexity. Adds gateway complexity and requires careful schema governance. Query planning and performance optimization across federated services can be challenging.

---

## Asynchronous Communication

### Message Queues (Point-to-Point)

A producer sends a message to a queue, and exactly one consumer picks it up. This decouples the sender from the receiver in time - the sender does not need the receiver to be running at the moment the message is sent.

**Common brokers:** RabbitMQ, Amazon SQS, Azure Service Bus.

**Use cases:**
- Task distribution across worker pools
- Workload buffering during traffic spikes
- Reliable command delivery where each command must be processed exactly once

### Event Bus and Pub/Sub

A producer publishes an event to a topic, and all subscribers receive a copy. The producer does not know or care who is listening.

**Common brokers:** Apache Kafka, Amazon SNS, Google Pub/Sub, NATS.

**Use cases:**
- Broadcasting domain events to multiple interested services
- Building event-driven architectures where services react to changes
- Feeding event sourcing projections or analytics pipelines

### Choosing Between Queues and Pub/Sub

| Need | Queue (Point-to-Point) | Pub/Sub (Fan-Out) |
|---|---|---|
| One consumer per message | Yes | No - all subscribers get every message |
| Multiple consumers per message | No | Yes |
| Load balancing across workers | Built-in (competing consumers) | Requires consumer groups (e.g., Kafka) |
| Message replay | Typically not supported | Supported by log-based brokers like Kafka |

---

## API Gateway Pattern

An API gateway sits at the edge of your microservices architecture and acts as the single entry point for all client requests. It handles cross-cutting concerns that individual services should not need to implement themselves.

### Responsibilities

| Function | Description |
|---|---|
| **Routing** | Directs incoming requests to the appropriate backend service based on path, headers, or other criteria |
| **Aggregation** | Combines responses from multiple services into a single response for the client |
| **Protocol translation** | Converts between external protocols (HTTP/REST) and internal ones (gRPC, message queues) |
| **Authentication** | Verifies identity at the edge before requests reach backend services |
| **Rate limiting** | Protects backend services from traffic surges by throttling requests per client |
| **TLS termination** | Handles encryption at the edge so internal traffic can use plaintext or mutual TLS |

### Gateway Anti-patterns

- **Business logic in the gateway** - the gateway should route and transform, not make business decisions
- **Gateway as single point of failure** - deploy multiple instances behind a load balancer
- **Monolithic gateway** - if the gateway grows too large, split it into multiple gateways per client type (Backend-for-Frontend pattern)

---

## Service Discovery

In a dynamic environment where service instances come and go (scaling, deployments, failures), callers need a way to find available instances.

### Client-Side Discovery

The client queries a service registry to get a list of available instances and selects one using a load-balancing strategy (round-robin, random, least connections).

**Flow:** Client -> Service Registry -> Client picks an instance -> Direct call to instance.

**Strengths:** No extra hop. Client can make intelligent routing decisions.
**Weaknesses:** Every client must implement discovery logic. Tightly couples clients to the registry.

### Server-Side Discovery

The client sends the request to a load balancer or router, which queries the registry and forwards the request to an available instance.

**Flow:** Client -> Load Balancer -> Load Balancer queries Registry -> Forward to instance.

**Strengths:** Clients are simple - they call one address. Discovery logic is centralized.
**Weaknesses:** Extra network hop. The load balancer can become a bottleneck or single point of failure.

### Service Registry

The registry is the source of truth for which instances are running. Services register on startup and deregister on shutdown. Health checks remove instances that stop responding.

**Common registries:** Consul, etcd, Kubernetes built-in service discovery, AWS Cloud Map.

---

## Sidecar Pattern

A sidecar is a helper process deployed alongside each service instance, sharing the same host or pod. It handles cross-cutting infrastructure concerns so the service code can focus on business logic.

### What Sidecars Handle

- Network proxying (routing, retries, circuit breaking)
- Mutual TLS and encryption
- Metrics collection and distributed tracing
- Log aggregation and formatting
- Configuration injection and secret management

### How It Works

The service communicates with the sidecar over localhost (fast, no network hops). The sidecar handles all outbound and inbound network traffic on behalf of the service. This means the service does not need libraries for retries, TLS, or tracing - the sidecar does it transparently.

**Trade-off:** Simplifies application code significantly. Adds memory and CPU overhead per instance. Debugging network issues requires understanding the sidecar's behavior.

---

## Service Mesh

A service mesh extends the sidecar pattern to the entire system. Every service instance gets a sidecar proxy, and a control plane manages all proxies centrally.

### Architecture

| Component | Role |
|---|---|
| **Data plane** | Sidecar proxies (e.g., Envoy) deployed alongside every service instance, handling all traffic |
| **Control plane** | Central management layer (e.g., Istio, Linkerd) that configures proxies, distributes policies, and collects telemetry |

### Capabilities

| Capability | Description |
|---|---|
| **Traffic management** | Canary deployments, blue-green routing, traffic splitting, fault injection for testing |
| **Security** | Automatic mutual TLS between all services, fine-grained access policies |
| **Observability** | Distributed tracing, metrics, and access logs without modifying application code |
| **Reliability** | Retries, timeouts, circuit breaking applied uniformly across all service-to-service calls |

### When a Service Mesh is Worth It

- You have many services (dozens or more) and need consistent networking policies
- You want mutual TLS everywhere without modifying each service
- You need traffic management features like canary deployments or fault injection
- Your teams want fine-grained observability without instrumenting every service

### When It is Overkill

- A handful of services that communicate simply
- Teams that lack the operational expertise to manage the mesh infrastructure
- Environments where the added latency and resource overhead per sidecar is not acceptable

---

## Choosing a Communication Style

| Scenario | Recommended Approach |
|---|---|
| Client needs immediate response | Synchronous (REST or gRPC) |
| Fire-and-forget command | Asynchronous queue |
| Broadcast state change to many consumers | Pub/sub event bus |
| High-throughput internal calls | gRPC with streaming |
| Diverse frontend data needs | GraphQL federation |
| Cross-cutting networking concerns at scale | Service mesh |
| Migration with mixed old/new services | API gateway with protocol translation |
