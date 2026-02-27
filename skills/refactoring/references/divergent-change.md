## Overview

Divergent Change occurs when a single class is modified for different reasons and in unrelated ways. Unlike Shotgun Surgery (which involves modifying multiple classes for one reason), Divergent Change means one class has multiple reasons to change. This indicates the class has too many responsibilities and violates the Single Responsibility Principle.

## Why It's a Problem

- **Maintenance Burden**: Each change requires understanding and modifying scattered, unrelated parts of the same class
- **Reduced Cohesion**: Methods serve different concerns, making the class harder to understand as a whole
- **Higher Bug Risk**: Modifications in one area may unexpectedly affect unrelated functionality
- **Poor Testability**: Multiple responsibilities require complex test scenarios
- **Evolution Difficulty**: Adding new features requires modifying existing classes in unexpected ways

## Signs and Symptoms

- A class changes for multiple, unrelated reasons (e.g., when adding a product type, you modify finding, displaying, and ordering methods)
- Methods in the class serve fundamentally different business concerns
- Comments describing different "sections" or "parts" of the class functionality
- Difficulty naming the class because it does too many things
- Some instance variables are only used by certain methods

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

- **Shotgun Surgery**: The opposite problem—one change requires modifications across many classes
- **God Object**: A more severe version where one class handles too many responsibilities
- **Feature Envy**: Classes accessing too much of another class's data, indicating misplaced methods
- **Inappropriate Intimacy**: Classes that know too much about each other's internals

## Refactoring.guru Guidance

### Signs and Symptoms
You find yourself having to change many unrelated methods when you make changes to a class. For example, when adding a new product type you have to change the methods for finding, displaying, and ordering products.

### Reasons for the Problem
Divergent modifications frequently stem from inadequate program architecture or repetitive coding practices (copy-paste programming).

### Treatment
- **Extract Class** to split up the behavior of the class into separate components
- **Extract Superclass** and **Extract Subclass** when multiple classes exhibit identical behavior

### Payoff
- Improves code organization
- Reduces code duplication
- Simplifies support
