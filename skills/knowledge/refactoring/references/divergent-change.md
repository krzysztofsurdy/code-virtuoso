## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Overview

Divergent Change occurs when one class must be modified for several unrelated reasons. It is the mirror image of Shotgun Surgery. Shotgun Surgery means one change touches many classes. Divergent Change means many different changes land in the same class. It violates the Single Responsibility Principle: the class has too many responsibilities.

## Why it's a problem

- **Tangled maintenance**: Each change takes you through unrelated parts of the same class, which risks accidental side effects
- **Weak cohesion**: Methods in the class serve different concerns, so the class is hard to reason about as a unit
- **Collateral damage**: Changing one responsibility can break another in the same class
- **Difficult testing**: Several concerns interleaved in one class need complex, scenario-heavy test setups
- **Friction on growth**: New features mean modifying an already overloaded class instead of creating focused new components

## Signs and symptoms

- A single class changes for multiple unrelated reasons (e.g., adding a product type requires editing finder, display, and ordering methods in the same class)
- Methods in the class address different business concerns
- Inline comments or region markers dividing the class into conceptual "sections"
- The class is hard to name concisely because it does too many things
- Some instance variables are used by only a subset of the class's methods

## Before and after

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

## Recommended refactorings

### Extract Class
Split responsibilities into separate classes. Each class should have one reason to change. This is the main fix, shown in the After example above.

### Extract Superclass
If several classes share similar behavior, create a base class. This pairs well with enums for type-specific behavior:

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

### Use dependency injection
Inject dependencies instead of managing them all in one class. This lowers coupling and makes testing easier.

## Exceptions

**When Divergent Change is acceptable:**

- **Utility classes**: Helper classes with unrelated utility methods (though even these benefit from organization)
- **Domain value objects**: Simple classes representing domain concepts may have several methods
- **Facade classes**: Intentional facades that coordinate several subsystems may have varied methods
- **Initial development**: Some divergent change is acceptable in early prototyping, before refactoring

## Related smells

- **Shotgun Surgery**: The inverse problem: a single change scattered across many classes, while Divergent Change is many changes funneling into one class
- **God Object**: An extreme form of Divergent Change where one class sits at the center of most of the system
- **Feature Envy**: Methods that work mostly with another class's data, which suggests they belong there
- **Inappropriate Intimacy**: Classes entangled in each other's internals, often found alongside classes with too many responsibilities

Divergent Change often comes from weak initial architecture or from copy-paste habits that pile unrelated functionality into a convenient existing class. The fix is to give each responsibility its own class.
