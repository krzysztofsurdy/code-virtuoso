# REST API Patterns

## Contents

- [Resource naming conventions](#resource-naming-conventions)
- [HTTP methods and idempotency](#http-methods-and-idempotency)
- [Status code guide](#status-code-guide)
- [Query parameters](#query-parameters)
- [Bulk operations](#bulk-operations)
- [Rate limiting](#rate-limiting)
- [Caching](#caching)

## Resource naming conventions

- Use plural nouns for collections: `/users`, `/orders`, `/products`
- Use identifiers for individual resources: `/users/{userId}`
- Nest sub-resources to express ownership, but limit to two levels maximum:
  - Good: `/users/{userId}/orders`
  - Avoid: `/users/{userId}/orders/{orderId}/items/{itemId}/reviews`
  - Instead: `/order-items/{itemId}/reviews`
- Use kebab-case for multi-word resource names: `/order-items`, `/payment-methods`
- Avoid verbs in URLs. The exception is "controller" actions that do not map to CRUD: `/orders/{id}/cancel`, `/reports/generate`
- Trailing slashes should be treated consistently (pick one convention and enforce it)

## HTTP methods and idempotency

| Method | Purpose | Idempotent | Safe | Request body |
|---|---|---|---|---|
| **GET** | Retrieve resource(s) | Yes | Yes | No |
| **POST** | Create a resource or trigger an action | No | No | Yes |
| **PUT** | Replace a resource entirely | Yes | No | Yes |
| **PATCH** | Partially update a resource | No* | No | Yes |
| **DELETE** | Remove a resource | Yes | No | No |

*PATCH can be made idempotent with merge-patch semantics (RFC 7396), but it is not inherently idempotent.

**Idempotency means** repeating the same request produces the same result. GET, PUT, and DELETE should be safe to retry. For non-idempotent operations (POST), support an `Idempotency-Key` header so clients can safely retry without creating duplicates. The header is a common convention (the IETF draft `draft-ietf-httpapi-idempotency-key-header` has not been published as an RFC).

## Status code guide

### 2xx Success

| Code | When to use |
|---|---|
| **200 OK** | Successful GET, PUT, PATCH, or DELETE that returns data |
| **201 Created** | Successful POST that created a resource. Include `Location` header with new resource URL |
| **202 Accepted** | Request accepted for async processing. Return a job/status URL |
| **204 No Content** | Successful DELETE or PUT/PATCH that returns no body |

### 3xx Redirection

| Code | When to use |
|---|---|
| **301 Moved Permanently** | Resource URL has permanently changed |
| **304 Not Modified** | Conditional request: resource has not changed since last fetch (ETag/If-None-Match) |

### 4xx Client errors

| Code | When to use |
|---|---|
| **400 Bad Request** | Malformed syntax, invalid JSON, missing required fields |
| **401 Unauthorized** | Missing or invalid authentication credentials |
| **403 Forbidden** | Authenticated but insufficient permissions |
| **404 Not Found** | Resource does not exist |
| **405 Method Not Allowed** | HTTP method not supported for this endpoint |
| **409 Conflict** | Request conflicts with current state (duplicate, concurrent edit) |
| **422 Unprocessable Entity** | Valid syntax but semantic errors (business rule violations) |
| **429 Too Many Requests** | Rate limit exceeded. Include `Retry-After` header |

### 5xx Server errors

| Code | When to use |
|---|---|
| **500 Internal Server Error** | Unhandled server error. Log details; return generic message |
| **502 Bad Gateway** | Upstream service failure |
| **503 Service Unavailable** | Temporary overload or maintenance. Include `Retry-After` header |
| **504 Gateway Timeout** | Upstream service did not respond in time |

## Query parameters

### Filtering

Use field names as query parameters:

```
GET /orders?status=shipped&customerId=42
```

For range filters, use suffixes or bracket notation:

```
GET /products?price_min=10&price_max=100
GET /events?start_date=2024-01-01&end_date=2024-12-31
```

### Sorting

Use a `sort` parameter with field name and direction:

```
GET /users?sort=created_at:desc
GET /products?sort=price:asc,name:asc
```

### Field selection

Allow clients to request only the fields they need:

```
GET /users?fields=id,name,email
```

This reduces payload size and can improve query performance.

## Bulk operations

When clients need to create, update, or delete multiple resources:

```
POST /users/bulk
Content-Type: application/json

{
  "operations": [
    { "action": "create", "data": { "name": "Alice", "email": "alice@example.com" } },
    { "action": "create", "data": { "name": "Bob", "email": "bob@example.com" } }
  ]
}
```

Response should report per-item results:

```json
{
  "results": [
    { "status": 201, "data": { "id": 1, "name": "Alice" } },
    { "status": 422, "error": { "code": "duplicate_email", "message": "Email already exists" } }
  ]
}
```

## Rate limiting

Include these headers in every response:

| Header | Purpose |
|---|---|
| `X-RateLimit-Limit` | Maximum requests allowed in the window |
| `X-RateLimit-Remaining` | Requests remaining in the current window |
| `X-RateLimit-Reset` | Unix timestamp when the window resets |
| `Retry-After` | Seconds to wait (only on 429 responses) |

The `X-RateLimit-*` headers are a widespread convention, not a standard, and their exact meaning differs between providers. The IETF HTTPAPI working group is standardizing `RateLimit` and `RateLimit-Policy` header fields in the Internet-Draft `draft-ietf-httpapi-ratelimit-headers` (still a draft, so syntax can change):

```
RateLimit-Policy: "burst";q=100;w=60
RateLimit: "burst";r=50;t=30
```

`q` is the quota, `w` the window in seconds, `r` the remaining quota, and `t` the seconds until the quota resets. New APIs can emit the draft fields, and keep `X-RateLimit-*` while existing clients depend on them. Document whichever you choose. `Retry-After` stays the standard way to tell a client when to retry.

**Strategies:**
- Fixed window: simple but allows burst at window boundaries
- Sliding window: smoother distribution, slightly more complex
- Token bucket: allows controlled bursts, best for most APIs

## Caching

### ETags

Server returns an `ETag` header with a fingerprint of the response:

```
HTTP/1.1 200 OK
ETag: "a1b2c3d4"
```

Client sends `If-None-Match` on subsequent requests:

```
GET /users/42
If-None-Match: "a1b2c3d4"
```

Server returns `304 Not Modified` if nothing changed, and no body is transferred.

### Cache-Control

```
Cache-Control: public, max-age=3600          # CDN + browser cache for 1 hour
Cache-Control: private, max-age=60           # Browser only, 1 minute
Cache-Control: no-store                      # Never cache (sensitive data)
```

### Conditional requests

Use `If-Modified-Since` / `Last-Modified` for time-based caching. Prefer ETags for precision.

For write operations, use `If-Match` to prevent lost updates (optimistic concurrency):

```
PUT /users/42
If-Match: "a1b2c3d4"
Content-Type: application/json

{ "name": "Updated Name" }
```

Server returns `412 Precondition Failed` if the ETag no longer matches.
