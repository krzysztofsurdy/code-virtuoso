# Long Method Code Smell

## Overview

A Long Method signals that a method has taken on far more responsibility than it should - as a rule of thumb, anything exceeding ten lines warrants a closer look. Methods expand gradually as developers tack on "just one more thing," and over time they become dense, intertwined, and fragile. The longer a method grows, the harder it becomes to name precisely, test comprehensively, and reason about with confidence.

## Why It's a Problem

- **Cognitive Overload**: Dense methods force readers to juggle too much context simultaneously
- **Poor Reusability**: When logic is woven together inside a single method, individual pieces cannot be extracted for use elsewhere
- **Testing Burden**: Every additional responsibility within a method multiplies the number of scenarios that need coverage
- **Hidden Repetition**: Repeated patterns buried deep inside long methods are easy to overlook, resulting in inconsistent bug fixes
- **Performance Blind Spots**: Genuine bottlenecks get buried among irrelevant code
- **Change Risk**: Modifying one section of a long method can inadvertently break unrelated behavior in the same block

## Signs and Symptoms

- Methods that stretch beyond 10-20 lines
- Deeply nested control structures (loops inside conditionals inside loops)
- Temporary local variables serving only as intermediate holders
- A single method handling multiple unrelated concerns
- The method name would require "and" or "or" to accurately describe its purpose
- Large conditional branches governing different execution paths
- Intricate logic embedded directly inside loop bodies

## Before/After Examples

### Before: Long, Monolithic Method

```php
declare(strict_types=1);

class OrderProcessor
{
    public function processOrder(array $orderData): array
    {
        $total = 0;
        $taxRate = 0.1;
        $discounts = [];

        foreach ($orderData['items'] as $item) {
            $price = $item['price'] * $item['quantity'];
            if ($item['quantity'] > 10) {
                $price *= 0.9;
                $discounts[] = $item['id'];
            }
            $total += $price;
        }

        $tax = $total * $taxRate;
        $total += $tax;

        if ($orderData['customer']['membership'] === 'gold') {
            $total *= 0.95;
        }

        if ($total > 1000) {
            $shippingCost = 0;
        } elseif ($total > 500) {
            $shippingCost = 5;
        } else {
            $shippingCost = 10;
        }

        $total += $shippingCost;

        return [
            'total' => $total,
            'tax' => $tax,
            'shipping' => $shippingCost,
            'discounts' => $discounts,
        ];
    }
}
```

### After: Refactored Methods

```php
declare(strict_types=1);

enum CustomerMembership: string
{
    case Standard = 'standard';
    case Gold = 'gold';
    case Platinum = 'platinum';
}

readonly class OrderItem
{
    public function __construct(
        public string $id,
        public float $price,
        public int $quantity,
    ) {}
}

readonly class OrderResult
{
    public function __construct(
        public float $total,
        public float $tax,
        public float $shipping,
        public array $appliedDiscounts = [],
    ) {}
}

class OrderProcessor
{
    private const BULK_DISCOUNT_THRESHOLD = 10;
    private const BULK_DISCOUNT_RATE = 0.9;
    private const TAX_RATE = 0.1;
    private const GOLD_MEMBER_DISCOUNT = 0.95;

    public function processOrder(array $orderData): OrderResult
    {
        $subtotal = $this->calculateSubtotal($orderData['items']);
        $tax = $this->calculateTax($subtotal);
        $memberDiscount = $this->applyMembershipDiscount($subtotal + $tax, $orderData['customer']);
        $shipping = $this->calculateShipping($memberDiscount);

        $discountedTotal = $this->applyMembershipDiscount($subtotal + $tax, $orderData['customer']);

        return new OrderResult(
            total: $discountedTotal + $shipping,
            tax: $tax,
            shipping: $shipping,
        );
    }

    private function calculateSubtotal(array $items): float
    {
        $subtotal = 0;
        foreach ($items as $item) {
            $subtotal += $this->calculateItemPrice($item);
        }
        return $subtotal;
    }

    private function calculateItemPrice(array $item): float
    {
        $price = $item['price'] * $item['quantity'];
        return $item['quantity'] >= self::BULK_DISCOUNT_THRESHOLD
            ? $price * self::BULK_DISCOUNT_RATE
            : $price;
    }

    private function calculateTax(float $subtotal): float
    {
        return $subtotal * self::TAX_RATE;
    }

    private function applyMembershipDiscount(float $amount, array $customer): float
    {
        $membership = CustomerMembership::from($customer['membership']);
        return $membership === CustomerMembership::Gold
            ? $amount * self::GOLD_MEMBER_DISCOUNT
            : $amount;
    }

    private function calculateShipping(float $subtotal): float
    {
        return match (true) {
            $subtotal > 1000 => 0,
            $subtotal > 500 => 5,
            default => 10,
        };
    }
}
```

## Recommended Refactorings

1. **Extract Method**: The primary weapon. Spot logical blocks within the method and pull them into their own well-named methods, each handling a single concern.

2. **Replace Temp with Query**: Remove temporary local variables by converting them into method calls that compute the value on demand. This clears obstacles for further extraction.

3. **Introduce Parameter Object**: When a method juggles numerous parameters or passes clusters of values together, consolidate them into a dedicated object. This pairs well with **Preserve Whole Object** - pass the source object rather than pulling individual fields from it.

4. **Replace Method with Method Object**: A fallback for cases where local variable entanglement makes extraction impractical. Promote the entire method into its own class where local variables become fields.

5. **Decompose Conditional**: Extract complex conditional logic into descriptively named methods, making branching structure self-explanatory.

6. **Use Enums and Readonly Classes**: Leverage PHP 8.1+ features to construct self-describing, immutable data structures that eliminate the need for inline logic.

Note that breaking methods into shorter ones carries negligible performance overhead from extra calls - modern runtimes optimize this efficiently, and the readability improvements far outweigh any micro-cost.

## Exceptions

- **Procedural Scripts**: Simple scripts that perform sequential operations may legitimately run longer without becoming problematic.
- **Algorithmic Methods**: Complex mathematical or scientific computations sometimes need more lines; if they are well-structured with helper methods, this is acceptable.
- **Legacy Constraints**: External dependencies may block certain refactorings; direct effort toward the highest-impact areas.

## Related Smells

- **Duplicate Code**: Frequently lurks inside long methods; decomposing them brings the repetition to light
- **Feature Envy**: Long methods often reach excessively into other objects' data
- **Primitive Obsession**: Over-reliance on raw types instead of objects; Introduce Parameter Object is a shared remedy
- **Data Clumps**: Groups of variables that travel together are strong candidates for Parameter Object extraction
