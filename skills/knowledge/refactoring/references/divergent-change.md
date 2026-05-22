## Overview

Divergent Change occurs when a single class must be modified for multiple, unrelated reasons. It is the mirror image of Shotgun Surgery: where Shotgun Surgery means one change touches many classes, Divergent Change means many different changes all land in the same class. This is a direct violation of the Single Responsibility Principle - the class has accumulated too many distinct responsibilities.

## Why It's a Problem

- **Tangled Maintenance**: Each change forces you to navigate unrelated parts of the same class, increasing the risk of accidental side effects
- **Weak Cohesion**: Methods within the class serve fundamentally different concerns, making the class hard to reason about as a unit
- **Collateral Damage**: Modifying one responsibility can inadvertently break another that shares the same class
- **Difficult Testing**: Multiple concerns interleaved in one class demand complex, scenario-heavy test setups
- **Friction on Growth**: Adding new features means modifying an already-overloaded class rather than creating focused new components

## Signs and Symptoms

- A single class changes for multiple unrelated reasons (e.g., adding a product type requires editing finder, display, and ordering methods in the same class)
- Methods within the class address fundamentally different business concerns
- Inline comments or region markers dividing the class into conceptual "sections"
- The class is hard to name concisely because it does too many things
- Certain instance variables are only relevant to a subset of the class's methods

## Before/After

### Before (PHP 8.3)

```php
readonly class ProductManager
{
    public function __construct(
        private string $databaseUrl,
        private string $cacheKey,
        private string $apiEndpoint,
    ) {}

    // Reason to change #1: Product finding logic changes
    public function findProduct(string $id): ?Product
    {
        $key = "{$this->cacheKey}:$id";
        if ($cached = apcu_fetch($key)) {
            return $cached;
        }

        $result = $this->queryDatabase($id);
        apcu_store($key, $result, 3600);
        return $result;
    }

    // Reason to change #2: Display format changes
    public function formatProductForDisplay(Product $product): array
    {
        return [
            'id' => $product->id,
            'name' => htmlspecialchars($product->name),
            'price' => number_format($product->price, 2),
        ];
    }

    // Reason to change #3: Order processing changes
    public function createOrder(string $productId, int $quantity): OrderResult
    {
        $product = $this->findProduct($productId);
        if (!$product) {
            throw new InvalidProductException($productId);
        }

        $this->publishToQueue('orders', [
            'product_id' => $productId,
            'quantity' => $quantity,
        ]);

        return OrderResult::Success;
    }

    private function queryDatabase(string $id): ?Product { /* ... */ }
}
```

### After (PHP 8.3)

```php
// Reason to change #1: Product finding logic
readonly class ProductRepository
{
    public function __construct(
        private string $databaseUrl,
        private string $cacheKey,
    ) {}

    public function find(string $id): ?Product
    {
        $key = "{$this->cacheKey}:$id";
        if ($cached = apcu_fetch($key)) {
            return $cached;
        }

        $result = $this->query($id);
        if ($result) {
            apcu_store($key, $result, 3600);
        }
        return $result;
    }

    private function query(string $id): ?Product { /* ... */ }
}

// Reason to change #2: Display format
readonly class ProductPresenter
{
    public function format(Product $product): array
    {
        return [
            'id' => $product->id,
            'name' => htmlspecialchars($product->name),
            'price' => number_format($product->price, 2),
        ];
    }
}

// Reason to change #3: Order processing
readonly class OrderService
{
    public function __construct(
        private ProductRepository $repository,
        private string $queueName,
    ) {}

    public function createOrder(string $productId, int $quantity): OrderResult
    {
        $product = $this->repository->find($productId);
        if (!$product) {
            throw new InvalidProductException($productId);
        }

        $this->publishToQueue($this->queueName, [
            'product_id' => $productId,
            'quantity' => $quantity,
        ]);

        return OrderResult::Success;
    }

    private function publishToQueue(string $queue, array $data): void { /* ... */ }
}
```

## Recommended Refactorings

### Extract Class
Split responsibilities into separate classes. Each class should have a single, well-defined reason to change. This is the primary solution and was demonstrated in the After example above.

### Extract Superclass
If multiple classes share similar behavior, create a base class. This works well with enums for type-specific behavior:

```php
enum ProductType: string
{
    case Physical = 'physical';
    case Digital = 'digital';
    case Service = 'service';
}

abstract readonly class ProductHandler
{
    public abstract function calculateShippingCost(Product $product): float;
    public abstract function validateInventory(Product $product, int $quantity): bool;
}

readonly class PhysicalProductHandler extends ProductHandler
{
    public function calculateShippingCost(Product $product): float
    {
        return $product->weight * 2.5;
    }

    public function validateInventory(Product $product, int $quantity): bool
    {
        return $product->stockQuantity >= $quantity;
    }
}
```

### Use Dependency Injection
Reduce coupling and improve testability by injecting dependencies rather than managing them all in one class.

## Exceptions

**When Divergent Change Is Acceptable:**

- **Utility Classes**: Helper classes with truly disparate utility methods (though even these benefit from organization)
- **Domain Value Objects**: Simple classes representing domain concepts may legitimately have several methods
- **Facade Classes**: Intentional facades that coordinate multiple subsystems may have diverse methods
- **Initial Development**: In early prototyping, some divergent change is acceptable before refactoring

## Related Smells

- **Shotgun Surgery**: The inverse problem - a single change scattered across many classes, while Divergent Change is many changes funneling into one class
- **God Object**: An extreme form of Divergent Change where one class has become the center of gravity for most of the system
- **Feature Envy**: Methods that work primarily with another class's data, suggesting they belong elsewhere
- **Inappropriate Intimacy**: Classes entangled in each other's internals, often a companion to classes with too many responsibilities

Divergent Change often stems from poor initial architecture or copy-paste habits that pile unrelated functionality into a convenient existing class. The remedy is straightforward: give each responsibility its own class.
