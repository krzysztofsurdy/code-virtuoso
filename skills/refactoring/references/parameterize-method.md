## Overview

Parameterize Method is a refactoring technique that consolidates multiple similar methods into a single method by introducing parameters to handle the differing values. This technique eliminates duplicate code while making the codebase more flexible and maintainable.

## Motivation

When you have several methods that perform nearly identical operations with only minor variations, duplicate code accumulates. This leads to:

- **Increased maintenance burden**: Changes must be applied to multiple locations
- **Higher bug potential**: Inconsistencies between similar methods
- **Poor extensibility**: Adding new variants requires creating new methods

By introducing a parameter to handle the differences, you create a single, unified method that serves multiple purposes, reducing complexity and improving code quality.

## Mechanics

The refactoring process involves three main steps:

1. **Identify common code**: Analyze similar methods to find their common logic
2. **Extract to new method**: Create a new method with a parameter representing the differing values
3. **Update call sites**: Replace calls to the old methods with calls to the new parameterized method, then delete the old methods

## Before/After Example (PHP 8.3+)

### Before

```php
class DataProcessor
{
    public function getSalesPrice(Product $product): float
    {
        return $product->getBasePrice() * 0.9;
    }

    public function getPurchasePrice(Product $product): float
    {
        return $product->getBasePrice() * 1.1;
    }

    public function getTransferPrice(Product $product): float
    {
        return $product->getBasePrice() * 1.05;
    }
}

// Usage
$processor = new DataProcessor();
$salePrice = $processor->getSalesPrice($product);
$purchasePrice = $processor->getPurchasePrice($product);
$transferPrice = $processor->getTransferPrice($product);
```

### After

```php
class DataProcessor
{
    private const MULTIPLIERS = [
        'sale' => 0.9,
        'purchase' => 1.1,
        'transfer' => 1.05,
    ];

    public function getPrice(Product $product, string $type): float
    {
        $multiplier = self::MULTIPLIERS[$type]
            ?? throw new InvalidArgumentException("Unknown price type: $type");

        return $product->getBasePrice() * $multiplier;
    }
}

// Usage
$processor = new DataProcessor();
$salePrice = $processor->getPrice($product, 'sale');
$purchasePrice = $processor->getPrice($product, 'purchase');
$transferPrice = $processor->getPrice($product, 'transfer');
```

## Benefits

- **Reduced code duplication**: Single source of truth for similar logic
- **Easier maintenance**: Changes apply uniformly across all variants
- **Simpler extension**: Adding new variants requires minimal changes
- **Improved readability**: Clear intent through parameter names and constants
- **Better testability**: Fewer methods to test and maintain

## When NOT to Use

- **Excessive complexity**: If the conditional logic becomes convoluted, the refactoring is counterproductive
- **Fundamentally different operations**: Methods with similar patterns but truly distinct purposes should remain separate
- **Performance-critical code**: Parameter checking might introduce unnecessary overhead in hot paths
- **Unclear intent**: When parameterization obscures what the method does rather than clarifying it

Sometimes this refactoring can be taken too far, resulting in long, complicated methods instead of multiple simpler ones. If conditional logic becomes too complex, consider the inverse refactoring: Replace Parameter with Explicit Methods.

## Related Refactorings

- **Extract Method**: Identify common code patterns before parameterizing
- **Replace Parameter with Explicit Methods**: Reverse operation when conditional logic becomes too complex
- **Remove Parameter**: Simplify methods by eliminating unused parameters
- **Introduce Parameter Object**: When multiple related parameters accumulate, group them into an object
