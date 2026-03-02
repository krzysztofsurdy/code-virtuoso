---
name: api-design
description: REST and GraphQL API design principles. Covers resource modeling, endpoint design, error handling, versioning, pagination, authentication patterns, and API evolution strategies.
user-invocable: false
---

# API Design

Principles and patterns for designing APIs that are consistent, predictable, and easy to evolve. Applies to any language or framework — the focus is on protocol-level design decisions, not implementation details.

A well-designed API treats its surface as a product: consumers should be able to predict behavior, recover from errors, and integrate without reading source code.

## When to Use

- Designing a new public or internal API from scratch
- Reviewing an existing API for consistency and usability
- Choosing between REST and GraphQL for a project
- Planning API versioning or migration strategy
- Defining error response contracts across services
- Establishing API standards for a team or organization

## REST vs GraphQL

| Aspect | REST | GraphQL |
|---|---|---|
| **Best for** | CRUD-heavy, resource-oriented domains | Complex, interconnected data with varied client needs |
| **Data fetching** | Fixed response shapes per endpoint | Client specifies exact fields needed |
| **Over-fetching** | Common — endpoints return full resources | Eliminated — clients request only what they need |
| **Under-fetching** | Common — requires multiple round trips | Eliminated — single query can span relations |
| **Caching** | Built-in HTTP caching (ETags, Cache-Control) | Requires custom caching (normalized stores, persisted queries) |
| **File uploads** | Native multipart support | Requires workarounds (multipart spec or separate endpoint) |
| **Real-time** | Webhooks, SSE, or polling | Subscriptions built into the spec |
| **Tooling maturity** | Mature — OpenAPI, Postman, HTTP clients | Growing — Apollo, Relay, GraphiQL |
| **Learning curve** | Lower — leverages existing HTTP knowledge | Higher — schema language, resolvers, query optimization |
| **Error handling** | HTTP status codes + response body | Always 200 — errors in response `errors` array |
| **Versioning** | URL path, headers, or query params | Schema evolution via deprecation + additive changes |

**Choose REST when:** your domain maps naturally to resources and CRUD operations, you need HTTP caching, or your clients are simple (mobile apps, third-party integrations).

**Choose GraphQL when:** clients have highly varied data needs, you are aggregating multiple backend services, or you want a strongly typed contract between frontend and backend.

**Both are valid.** Many systems use REST for external/public APIs and GraphQL for internal frontend-backend communication.

## REST Design Principles

REST APIs model the domain as resources and use HTTP semantics to operate on them.

**Core rules:**
- Resources are nouns, not verbs: `/orders`, not `/getOrders`
- HTTP methods are the verbs: GET reads, POST creates, PUT replaces, PATCH updates, DELETE removes
- URLs identify resources; query parameters filter, sort, or paginate them
- Use plural nouns for collections: `/users`, `/users/{id}`
- Limit nesting to two levels: `/users/{id}/orders` is fine; `/users/{id}/orders/{id}/items/{id}/variants` is not
- Use HTTP status codes meaningfully — do not return 200 for everything
- Support content negotiation via `Accept` and `Content-Type` headers

**HATEOAS** (Hypermedia as the Engine of Application State) adds discoverability by including links in responses. Useful for public APIs but often overkill for internal services:

```json
{
  "id": 42,
  "status": "shipped",
  "_links": {
    "self": { "href": "/orders/42" },
    "cancel": { "href": "/orders/42/cancel", "method": "POST" },
    "customer": { "href": "/customers/7" }
  }
}
```

See [REST Patterns Reference](references/rest-patterns.md) for detailed conventions.

## GraphQL Design Principles

GraphQL APIs expose a strongly typed schema that clients query declaratively.

**Core rules:**
- Design schema-first — define the type system before writing resolvers
- Types represent domain concepts; fields represent attributes and relations
- Queries read data, mutations write data, subscriptions stream data
- Use the type system to enforce constraints (non-null, enums, input types)
- Avoid deeply nested schemas that create unpredictable query costs
- Solve N+1 problems with batching (dataloader pattern)
- Limit query depth and complexity to prevent abuse

**Schema-first example:**

```graphql
type User {
  id: ID!
  name: String!
  email: String!
  orders(first: Int, after: String): OrderConnection!
}

type Order {
  id: ID!
  total: Float!
  status: OrderStatus!
  createdAt: DateTime!
}

enum OrderStatus {
  PENDING
  CONFIRMED
  SHIPPED
  DELIVERED
  CANCELLED
}
```

See [GraphQL Patterns Reference](references/graphql-patterns.md) for detailed conventions.

## Error Handling

A consistent error format is one of the most impactful API design decisions. Consumers should be able to parse errors programmatically without inspecting message strings.

**RFC 7807 Problem Details format (recommended for REST):**

```json
{
  "type": "https://api.example.com/errors/insufficient-funds",
  "title": "Insufficient Funds",
  "status": 422,
  "detail": "Account balance is $10.00 but the transfer requires $50.00.",
  "instance": "/transfers/abc-123",
  "errors": [
    {
      "field": "amount",
      "code": "insufficient_funds",
      "message": "Transfer amount exceeds available balance"
    }
  ]
}
```

**Key principles:**
- Use a machine-readable `type` or `code` — clients should branch on codes, not messages
- Include a human-readable `detail` for debugging
- Return field-level errors for validation failures so clients can highlight specific inputs
- Use appropriate HTTP status codes (REST) or structured error types (GraphQL)
- Never expose stack traces, internal paths, or SQL queries in production
- Include a correlation/request ID for tracing errors across services

**GraphQL error conventions:**

```json
{
  "data": { "createOrder": null },
  "errors": [
    {
      "message": "Insufficient funds",
      "extensions": {
        "code": "INSUFFICIENT_FUNDS",
        "field": "amount"
      }
    }
  ]
}
```

## Versioning

APIs evolve. Versioning strategies determine how you ship changes without breaking existing consumers.

| Strategy | Mechanism | Pros | Cons |
|---|---|---|---|
| **URL path** | `/v1/users` | Explicit, easy to route | URL pollution, hard to deprecate |
| **Accept header** | `Accept: application/vnd.api+json;version=2` | Clean URLs, HTTP-correct | Less visible, harder to test casually |
| **Query param** | `/users?version=2` | Simple to implement | Easy to forget, caching complications |

**Practical guidance:**
- URL path versioning is the most common and easiest for consumers to understand
- Only bump the major version for breaking changes
- Prefer evolving the API additively (new fields, new endpoints) over creating new versions
- When a version is deprecated, communicate a sunset date and provide migration guides

See [API Evolution Reference](references/api-evolution.md) for detailed strategies.

## Pagination

Every list endpoint needs pagination. The choice between cursor and offset affects performance, consistency, and client complexity.

| Approach | How it works | Pros | Cons |
|---|---|---|---|
| **Offset** | `?offset=20&limit=10` | Simple, supports "jump to page N" | Inconsistent with real-time inserts/deletes, slow on large tables |
| **Cursor** | `?after=abc123&limit=10` | Stable with real-time data, performant at scale | Cannot jump to arbitrary pages |

**Best practices:**
- Set a maximum page size (e.g., 100) and a sensible default (e.g., 20)
- Return pagination metadata: `hasNextPage`, `hasPreviousPage`, `totalCount` (if cheap to compute)
- If `totalCount` is expensive, make it optional or return an estimate
- Use cursors for feeds, activity streams, and any data that changes frequently
- Use offset for admin dashboards, reports, and datasets that rarely change during browsing

**Cursor pagination response example:**

```json
{
  "data": [ ... ],
  "pagination": {
    "hasNextPage": true,
    "hasPreviousPage": false,
    "startCursor": "eyJpZCI6MX0=",
    "endCursor": "eyJpZCI6MTB9"
  }
}
```

## Authentication & Authorization

**Authentication** verifies identity (who are you?). **Authorization** verifies permissions (what can you do?).

| Mechanism | Use case | Notes |
|---|---|---|
| **API keys** | Server-to-server, simple integrations | Easy to implement; rotate regularly; never expose in client code |
| **OAuth 2.0** | Third-party access, delegated permissions | Industry standard; use Authorization Code + PKCE for SPAs/mobile |
| **JWT (Bearer tokens)** | Stateless auth for microservices | Include only essential claims; set short expiry; validate signature and claims |
| **Session cookies** | Browser-based web apps | Pair with CSRF protection; use `Secure`, `HttpOnly`, `SameSite` flags |

**Best practices:**
- Always use HTTPS — no exceptions
- Transmit tokens in `Authorization: Bearer <token>` header, not in query strings
- Implement scopes/permissions for fine-grained access control
- Return `401 Unauthorized` for missing/invalid credentials, `403 Forbidden` for insufficient permissions
- Rate-limit authentication endpoints aggressively to prevent brute-force attacks
- Support token refresh flows to avoid forcing re-authentication

## Common Antipatterns

| Antipattern | Problem | Fix |
|---|---|---|
| **Chatty API** | Clients need 10+ requests to render a page | Aggregate related data; consider GraphQL or composite endpoints |
| **God endpoint** | Single endpoint accepts wildly different payloads via flags | Split into focused endpoints with clear semantics |
| **Inconsistent naming** | Mix of `snake_case`, `camelCase`, plural/singular | Pick one convention and enforce it project-wide |
| **Missing pagination** | List endpoints return unbounded results | Always paginate collections; set max page size |
| **Breaking changes without versioning** | Renaming or removing fields breaks clients silently | Use versioning or additive-only evolution |
| **Leaking internals** | Database column names, auto-increment IDs in URLs | Map to stable external identifiers (UUIDs, slugs) |
| **Ignoring idempotency** | Retrying a POST creates duplicate resources | Support idempotency keys for non-idempotent operations |
| **200 for everything** | Errors return HTTP 200 with an error body | Use appropriate HTTP status codes |
| **Timestamps without timezone** | `2024-01-15 14:30:00` is ambiguous | Always use ISO 8601 with timezone: `2024-01-15T14:30:00Z` |

## Quality Checklist

Before shipping or reviewing an API, verify:

- [ ] Resource naming is consistent (plural nouns, no verbs in URLs)
- [ ] HTTP methods match semantics (GET is safe, PUT/DELETE are idempotent)
- [ ] Every list endpoint is paginated with a max page size
- [ ] Error responses use a consistent format with machine-readable codes
- [ ] Authentication is required and uses HTTPS
- [ ] Rate limiting is in place with appropriate headers
- [ ] Breaking changes are versioned or avoided via additive evolution
- [ ] Request/response examples exist for every endpoint
- [ ] Timestamps use ISO 8601 with timezone
- [ ] IDs are stable external identifiers, not internal auto-increments
- [ ] CORS is configured for browser clients (if applicable)
- [ ] Compression (gzip/brotli) is enabled for responses
- [ ] API documentation is generated from the source of truth (OpenAPI schema, GraphQL introspection)
