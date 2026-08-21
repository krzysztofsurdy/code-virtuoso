# Parameterize Method

## Overview

Parameterize Method merges several methods that do nearly the same thing into one method controlled by a parameter. When methods share the same structure and differ only in a literal value or small constant, a parameter can carry that difference. This removes the duplication and leaves a single entry point.

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after example (PHP 8.3+)](#before-and-after-example-php-83)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Motivation

Codebases collect look-alike methods that vary only in a constant or threshold. This repetition causes:

- **Multiplied maintenance**: every fix or change must be applied to all variants
- **Divergence risk**: the copies drift apart and introduce subtle inconsistencies
- **Difficult extension**: each new variant needs yet another near-duplicate method

One parameterized method gives you a single source of truth, a smaller API, and an easy way to add variants.

## Mechanics

1. **Identify common code**: compare the similar methods and find their shared logic.
2. **Extract to a new method**: create a method with a parameter for the differing values.
3. **Update call sites**: replace calls to the old methods with calls to the new one, then delete the old methods.

## Before and after example (PHP 8.3+)

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

- **Single source of truth**: identical logic lives in one place, so copies cannot drift.
- **Lower maintenance cost**: a bug fix or change applies once.
- **Easy extension**: a new variant is a configuration change, not a new method.
- **Cleaner API**: callers see one well-named method instead of a family of near-duplicates.
- **Simpler testing**: one method with parameterized test cases replaces many test methods.

## When not to use

- **Excessive complexity**: if the conditional logic gets convoluted, the refactoring does more harm than good.
- **Different operations**: methods with a similar shape but distinct purposes should stay separate.
- **Performance-critical code**: checking the parameter adds overhead in hot paths.
- **Unclear intent**: the parameter hides what the method does instead of clarifying it.

This refactoring can be taken too far and leave one long, complicated method in place of several simple ones. If the conditional logic gets too complex, consider the inverse refactoring: Replace Parameter with Explicit Methods.

## Related refactorings

- **Extract Method**: identify common code patterns before parameterizing.
- **Replace Parameter with Explicit Methods**: the reverse operation, for when conditional logic gets too complex.
- **Remove Parameter**: simplify methods by removing unused parameters.
- **Introduce Parameter Object**: when several related parameters pile up, group them into an object.
