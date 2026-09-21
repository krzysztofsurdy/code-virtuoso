# Rename Method

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After Examples (PHP 8.3+)](#beforeafter-examples-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)

## Overview

Rename Method gives a method a name that describes what it does. When the name no longer matches the behavior, renaming restores clarity. The cause may be changed requirements, a hasty first name, or a method that grew in scope. Readers can then understand intent without reading the implementation.

## Motivation

Methods end up with poor names for several reasons:
- Rushed early development leaves temporary names in place
- The method's functionality grows beyond its original scope
- Naming conventions are inconsistent across the codebase
- Comments are needed to explain what a poorly named method does

A misleading name forces every reader to inspect the method body before trusting it. That slows reading and makes misuse more likely.

## Mechanics

1. **Declare a new method** with the desired name, copying the original implementation
2. **Delegate the old method** to the new one so existing callers keep working during the transition
3. **Find and update all references** in the codebase to use the new name
4. **Remove the old method** once all references are updated, or mark it as deprecated if it is a public API

## Before/After Examples (PHP 8.3+)

### Example 1: descriptive method name

**Before:**
```php
class UserRepository
{
    public function get(int $id): User
    {
        return $this->queryBuilder
            ->where('id = ?', $id)
            ->fetchOne();
    }
}

$user = $repository->get(1);
```

**After:**
```php
class UserRepository
{
    public function findUserById(int $id): User
    {
        return $this->queryBuilder
            ->where('id = ?', $id)
            ->fetchOne();
    }

    #[Deprecated(
        message: 'Use findUserById() instead',
        since: '2.0'
    )]
    public function get(int $id): User
    {
        return $this->findUserById($id);
    }
}

$user = $repository->findUserById(1);
```

### Example 2: boolean getter clarity

**Before:**
```php
class Order
{
    public function valid(): bool
    {
        return $this->items->count() > 0 &&
               $this->total > 0 &&
               $this->customer !== null;
    }
}

if ($order->valid()) {
    // process order
}
```

**After:**
```php
class Order
{
    public function isReadyForProcessing(): bool
    {
        return $this->items->count() > 0 &&
               $this->total > 0 &&
               $this->customer !== null;
    }

    #[Deprecated(
        message: 'Use isReadyForProcessing() instead',
        since: '1.5'
    )]
    public function valid(): bool
    {
        return $this->isReadyForProcessing();
    }
}

if ($order->isReadyForProcessing()) {
    // process order
}
```

### Example 3: transformation methods

**Before:**
```php
class ProductPresenter
{
    public function calc(Product $product): array
    {
        return [
            'name' => $product->name,
            'price' => $product->price * 1.19,
            'stock' => $product->quantity,
        ];
    }
}
```

**After:**
```php
class ProductPresenter
{
    public function formatProductForDisplay(Product $product): array
    {
        return [
            'name' => $product->name,
            'price' => $product->price * 1.19,
            'stock' => $product->quantity,
        ];
    }

    #[Deprecated(
        message: 'Use formatProductForDisplay() instead',
        since: '3.0'
    )]
    public function calc(Product $product): array
    {
        return $this->formatProductForDisplay($product);
    }
}
```

## Benefits

- **Instant comprehension**: A well-chosen name tells readers the purpose without opening the method body
- **Lower cognitive overhead**: Developers spend time building features, not deciphering cryptic labels
- **Fewer misuses**: A precise name makes it hard to call the wrong method by mistake
- **Fewer comments**: The name itself documents the method
- **Better IDE assistance**: Autocomplete and search work better with descriptive names
- **Consistent vocabulary**: The method matches the project's naming conventions

## When NOT to use

- **Public API contracts**: Renaming public methods breaks backward compatibility; deprecate instead
- **Framework hooks**: Methods that override parent or interface contracts should not be renamed
- **Legacy systems**: Widely dependent code cannot be updated all at once
- **Name conflicts**: The new name collides with an existing method in the class hierarchy
- **During active development**: Wait until the functionality stabilizes before settling on names

## Related Refactorings

- **Extract Method**: Often applied before Rename Method to isolate and clarify functionality
- **Move Method**: Combines renaming with relocating a method to a more appropriate class
- **Add Parameter** and **Remove Parameter**: Other changes to a method's signature
- For public API, mark the old name with the PHP 8.4+ `#[Deprecated]` attribute so callers can migrate safely
