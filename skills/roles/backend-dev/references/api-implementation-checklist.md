# API Implementation Checklist

A step-by-step checklist for implementing API endpoints. Use this as a working reference during implementation, not just a final review.

---

## Pre-Implementation

| # | Check | Notes |
|---|---|---|
| 1 | API contract is available (endpoint, method, request/response shapes, status codes) | From the architect or API design document |
| 2 | Acceptance criteria are available and unambiguous | From the product manager |
| 3 | Data model changes are identified and migration strategy is clear | Coordinate with architect if schema changes affect other components |
| 4 | Authentication and authorization requirements are understood | Which roles, which policies, which ownership checks |
| 5 | Error response format matches the project standard | Consistent structure across all endpoints |

---

## Request Handling

### Route Definition

Define routes following your framework's conventions:

```
# Example route definitions (pseudocode)
GET    /api/v1/products/{id}    -> ProductController.show
POST   /api/v1/products         -> ProductController.create
PUT    /api/v1/products/{id}    -> ProductController.update
DELETE /api/v1/products/{id}    -> ProductController.destroy
```

| # | Check |
|---|---|
| 1 | Route path follows RESTful conventions (nouns for resources, no verbs) |
| 2 | HTTP method matches the operation (GET=read, POST=create, PUT/PATCH=update, DELETE=remove) |
| 3 | Route name follows the project naming convention |
| 4 | API version is included in the path or header as agreed |

### Input Validation

| # | Check |
|---|---|
| 1 | Request body is deserialized into a typed DTO or schema object, not accessed as raw dictionary/array |
| 2 | Validation rules are defined on the DTO using the framework's validation mechanism |
| 3 | Validation runs before any business logic executes |
| 4 | Validation errors return 422 with a structured error response |
| 5 | Path parameters are validated (type, format, existence) |
| 6 | Query parameters have defaults and are validated (pagination limits, sort fields) |
| 7 | File uploads have size and type restrictions |

**DTO validation example (pseudocode):**

```
class CreateProductRequest:
    name: string
        - required
        - length: min=3, max=255
    priceInCents: integer
        - required
        - positive
    status: string
        - required
        - one_of: ["active", "draft", "archived"]
```

### Authentication and Authorization

| # | Check |
|---|---|
| 1 | Endpoint requires authentication (unless explicitly public) |
| 2 | Role-based access control is enforced via middleware, decorators, or policy objects |
| 3 | Resource ownership is verified where applicable (user can only access their own resources) |
| 4 | Complex authorization logic uses dedicated policy/guard objects instead of inline checks |
| 5 | Unauthenticated requests return 401 |
| 6 | Unauthorized requests return 403 |

---

## Business Logic

| # | Check |
|---|---|
| 1 | Business logic lives in a service class, not in the controller |
| 2 | The service class has a single responsibility |
| 3 | External dependencies are injected, not instantiated |
| 4 | Domain exceptions are thrown for business rule violations |
| 5 | Side effects (sending emails, dispatching events) are separated from core logic |
| 6 | Transaction boundaries are explicit - use the ORM's transactional pattern or a unit-of-work |

### Transaction Boundaries

```
# Pseudocode - wrap related operations in a transaction
database.transaction do:
    repository.save(product)
    inventory.decrement_stock(product.sku, 1)
end
```

| # | Check |
|---|---|
| 1 | Operations that must be atomic are wrapped in a single transaction |
| 2 | Read-only operations do not open unnecessary transactions |
| 3 | Long-running operations are not held inside a transaction |
| 4 | Transaction failures result in a clear error response |

---

## Response Handling

### Success Responses

| Status Code | When to Use | Response Body |
|---|---|---|
| 200 OK | Successful read or update | Resource representation |
| 201 Created | Successful resource creation | Created resource with Location header |
| 204 No Content | Successful delete or action with no response body | Empty |

### Error Responses

| Status Code | When to Use | Response Body |
|---|---|---|
| 400 Bad Request | Malformed request (unparseable JSON, wrong content type) | Error message |
| 401 Unauthorized | Missing or invalid authentication | Error with code |
| 403 Forbidden | Authenticated but insufficient permissions | Error with code |
| 404 Not Found | Resource does not exist | Error with code |
| 409 Conflict | Duplicate creation or state conflict | Error with details |
| 422 Unprocessable Entity | Validation errors on a well-formed request | Validation error details |
| 429 Too Many Requests | Rate limit exceeded | Error with Retry-After header |
| 500 Internal Server Error | Unexpected server failure | Generic error (no internal details) |

**Standard error response structure:**

```json
{
    "error": {
        "code": "validation_failed",
        "message": "The request contains invalid data.",
        "details": [
            {
                "field": "priceInCents",
                "message": "This value should be positive."
            }
        ]
    }
}
```

| # | Check |
|---|---|
| 1 | Success responses use the correct HTTP status code |
| 2 | Response body matches the agreed contract (field names, types, nesting) |
| 3 | Error responses follow the project standard format |
| 4 | 500 errors do not expose internal details (stack traces, SQL, file paths) |
| 5 | Location header is set for 201 responses |
| 6 | Null fields are handled consistently (omitted vs explicit null) |

### Pagination

| # | Check |
|---|---|
| 1 | List endpoints are paginated by default |
| 2 | Pagination parameters have sensible defaults (page=1, limit=25) |
| 3 | Maximum limit is enforced (e.g., limit cannot exceed 100) |
| 4 | Response includes pagination metadata (total, page, limit, pages) |
| 5 | Cursor-based pagination is used for large or frequently-changing datasets |

**Pagination response structure:**

```json
{
    "data": [],
    "meta": {
        "total": 142,
        "page": 2,
        "limit": 25,
        "pages": 6
    }
}
```

### Serialization

| # | Check |
|---|---|
| 1 | Serialization configuration controls which fields are exposed per endpoint |
| 2 | Internal fields (database IDs used only internally, soft delete flags) are not exposed |
| 3 | Date/time fields use ISO 8601 format |
| 4 | Money fields use integer cents, not floating-point |
| 5 | Enum fields serialize to string values, not internal codes |

---

## Data Access

| # | Check |
|---|---|
| 1 | Queries use parameterized values (no string concatenation in queries) |
| 2 | Eager loading is configured for relationships used in the response to avoid N+1 queries |
| 3 | List queries have result limits and are paginated |
| 4 | Indexes exist for fields used in WHERE, JOIN, and ORDER BY clauses |
| 5 | Soft delete is handled consistently (global filter or explicit query conditions) |
| 6 | Read-only queries do not trigger unnecessary write operations (e.g., ORM dirty checking, flush) |

---

## Testing

| Test Type | What to Cover |
|---|---|
| **Unit tests** | Service class methods: business logic, edge cases, exception throwing |
| **Integration tests** | Repository queries: correct results with test data, pagination, filtering |
| **API tests** | Full request/response cycle: happy path, validation errors, auth failures, not-found |

### API Test Coverage Matrix

For each endpoint, verify:

| Scenario | Expected Status | Tested |
|---|---|---|
| Valid request with valid auth | 200/201/204 | |
| Valid request without auth token | 401 | |
| Valid request with insufficient role | 403 | |
| Request with validation errors | 422 | |
| Request for non-existent resource | 404 | |
| Duplicate creation | 409 | |
| Malformed request body | 400 | |

---

## Logging and Observability

| # | Check |
|---|---|
| 1 | Error conditions are logged with sufficient context (request ID, user ID, input summary) |
| 2 | Sensitive data is not logged (passwords, tokens, PII) |
| 3 | Key business operations have info-level log entries |
| 4 | External service calls are logged with duration and outcome |
| 5 | Correlation/request IDs are included in all log entries |

---

## Final Review

| # | Check |
|---|---|
| 1 | All tests pass locally |
| 2 | No hardcoded secrets, URLs, or environment-specific values |
| 3 | Code follows project coding standards and conventions |
| 4 | API documentation is updated to reflect the implementation |
| 5 | Database migrations are included and tested (up and down) |
| 6 | The implementation matches the API contract exactly |
