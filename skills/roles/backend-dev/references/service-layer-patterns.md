# Service Layer Patterns

Patterns for organizing business logic in backend applications. Covers service class design, command/query separation, transaction boundaries, and common structures.

---

## Service Layer Principles

| Principle | Meaning |
|---|---|
| Controllers are thin | Controllers validate input, call a service, and return a response. No business logic. |
| Services own business logic | All domain rules, calculations, and orchestration live in service classes. |
| One service, one responsibility | A service handles one area of the domain. `OrderService` does not handle user registration. |
| Transport-agnostic | Services do not know about HTTP, CLI, or messaging. They accept typed arguments and return results. |
| Testable in isolation | Services can be unit tested with mocked dependencies. |

---

## Service Class Structure

### Basic Service (Pseudocode)

```
class ProductService:
    constructor(productRepository, unitOfWork):
        this.productRepository = productRepository
        this.unitOfWork = unitOfWork

    function create(request: CreateProductRequest) -> Product:
        if this.productRepository.findBySku(request.sku) is not null:
            throw DuplicateSkuException(request.sku)

        product = new Product(
            name: request.name,
            sku: request.sku,
            priceInCents: request.priceInCents,
        )

        this.unitOfWork.persist(product)
        this.unitOfWork.commit()

        return product
```

### Service Design Checklist

| # | Check |
|---|---|
| 1 | Class is final / sealed (prevents unintended inheritance) |
| 2 | Dependencies are injected via constructor |
| 3 | Public methods accept typed arguments (DTOs or primitives), not raw arrays or dictionaries |
| 4 | Return types are explicit |
| 5 | Domain exceptions are thrown for business rule violations |
| 6 | No HTTP-specific concerns (Request, Response, status codes) |
| 7 | No direct output (print, dump, console.log) |

---

## Command/Query Separation

Separate operations that change state (commands) from operations that read state (queries). This makes the codebase easier to reason about, test, and optimize.

### Commands (Write Operations)

Commands change state and typically return void or the created/updated entity.

```
class PlaceOrderHandler:
    constructor(unitOfWork, eventDispatcher):
        this.unitOfWork = unitOfWork
        this.eventDispatcher = eventDispatcher

    function handle(request: PlaceOrderRequest) -> Order:
        order = new Order(
            customerId: request.customerId,
            items: request.items,
        )

        this.unitOfWork.persist(order)
        this.unitOfWork.commit()

        this.eventDispatcher.dispatch(new OrderPlacedEvent(order.id))

        return order
```

### Queries (Read Operations)

Queries read state and return data. They never modify state.

```
class OrderQueryService:
    constructor(orderRepository):
        this.orderRepository = orderRepository

    function search(criteria: OrderSearchCriteria) -> OrderListResult:
        results = this.orderRepository.findByCriteria(criteria)
        total = this.orderRepository.countByCriteria(criteria)

        return new OrderListResult(
            items: results,
            total: total,
            page: criteria.page,
            limit: criteria.limit,
        )
```

### Directory Structure

```
src/
  services/
    commands/
      PlaceOrderHandler
      CancelOrderHandler
      UpdateProductHandler
    queries/
      OrderQueryService
      ProductQueryService
```

### When to Use Full Separation

| Project Size | Approach |
|---|---|
| Small (< 20 entities) | Single service class per domain area is fine. Separate when it grows. |
| Medium (20-50 entities) | Separate commands from queries in the directory structure. |
| Large (50+ entities) | Full CQRS with separate read/write models if query optimization demands it. |

---

## Transaction Boundaries

### Rules

| Rule | Rationale |
|---|---|
| One transaction per use case | A single user action should be atomic - it either fully succeeds or fully fails |
| Transactions wrap the service call, not individual repository calls | The service orchestrates the full operation |
| Read-only operations do not need explicit transactions | Most ORMs handle this automatically |
| Keep transactions short | Long transactions hold locks and increase deadlock risk |

### Patterns

**Implicit (single commit):**

```
# Simplest approach - single commit at the end of the service method
this.unitOfWork.persist(entity)
this.unitOfWork.commit()  # Commits in a single transaction
```

**Explicit (transaction block):**

```
# When multiple operations must be atomic
database.transaction do:
    this.unitOfWork.persist(order)
    this.unitOfWork.persist(payment)
    this.inventoryService.reserve(order.items)
end
```

**When to use explicit transactions:**

- Multiple entities across different aggregates must be saved together
- External side effects (API calls, file writes) must be coordinated with database changes
- You need to catch and handle transaction failures specifically

### Side Effects and Transactions

| Side Effect | Placement | Rationale |
|---|---|---|
| Dispatching domain events | After transaction commits | Event consumers should not see uncommitted state |
| Sending emails | After transaction commits | Do not send email if the save fails |
| External API calls | Before transaction (if needed for data) or after (if notification) | Minimize time holding the transaction open |
| Logging | Outside transaction | Logging should never fail the business operation |

```
# Dispatch events after successful commit
database.transaction do:
    order.markAsShipped()
    this.unitOfWork.commit()
end

# Only dispatch if the transaction succeeded
this.eventDispatcher.dispatch(new OrderShippedEvent(order.id))
```

---

## Exception Handling in Services

### Domain Exceptions

Create specific exception classes for business rule violations.

```
class InsufficientStockException extends DomainException:
    constructor(sku: string, requested: integer, available: integer):
        super("Insufficient stock for SKU '{sku}': requested {requested}, available {available}")
```

### Exception Mapping

Map domain exceptions to HTTP responses in the controller or via middleware.

| Domain Exception | HTTP Status | Error Code |
|---|---|---|
| `EntityNotFoundException` | 404 | `not_found` |
| `DuplicateSkuException` | 409 | `duplicate_resource` |
| `InsufficientStockException` | 422 | `insufficient_stock` |
| `AccessDeniedException` | 403 | `access_denied` |
| `InvalidArgumentException` | 422 | `invalid_input` |
| Unexpected exceptions | 500 | `internal_error` |

### Exception-to-Response Middleware (Pseudocode)

```
class ApiExceptionMiddleware:
    function handleException(exception):
        statusCode = match exception:
            EntityNotFoundException  -> 404
            DuplicateSkuException    -> 409
            InsufficientStockException -> 422
            default                  -> 500

        return JsonResponse(
            body: {
                "error": {
                    "code": resolveCode(exception),
                    "message": statusCode < 500 ? exception.message : "An internal error occurred."
                }
            },
            status: statusCode
        )
```

---

## Common Service Patterns

### Finder/Resolver Pattern

When a service needs to load and validate an entity from an ID:

```
function resolveProduct(productId: UUID) -> Product:
    product = this.productRepository.find(productId)

    if product is null:
        throw EntityNotFoundException("Product '{productId}' not found")

    return product
```

### Specification Pattern for Complex Queries

When query conditions become complex, extract them into specification objects:

```
class ProductSearchCriteria:
    status: string?       = null
    minPrice: integer?    = null
    maxPrice: integer?    = null
    category: string?     = null
    page: integer         = 1
    limit: integer        = 25
```

### Decorator Pattern for Cross-Cutting Concerns

Wrap services with decorators for logging, caching, or metrics without modifying the original service:

```
class CachedProductQueryService:
    constructor(inner: ProductQueryService, cache: Cache):
        this.inner = inner
        this.cache = cache

    function findBySku(sku: string) -> Product?:
        cacheKey = "product_sku_" + sku
        cached = this.cache.get(cacheKey)

        if cached is not null:
            return cached

        product = this.inner.findBySku(sku)

        this.cache.set(cacheKey, product, ttl: 3600)

        return product
```

---

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Fat controller | Business logic in controller makes it untestable and tightly coupled to HTTP | Move logic to a service class |
| Anemic services | Services that just call repository methods without adding value | If the service adds no logic, let the controller call the repository directly |
| Service locator | Getting services from the container at runtime instead of injecting | Use constructor injection |
| Mixed read/write in one method | Hard to optimize and reason about | Separate query methods from command methods |
| Catching all exceptions | Swallows errors, hides bugs | Catch specific exceptions, let unexpected ones propagate |
| Persistence logic in entities | Entities should not know about persistence | Keep persistence in services and repositories |
| Business logic in event listeners | Hidden execution paths, hard to debug | Keep core logic in services, use events for side effects only |
