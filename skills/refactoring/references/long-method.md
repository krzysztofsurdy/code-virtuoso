# Long Method Code Smell

## Overview

A Long Method is a code smell where a method contains excessive lines of code, typically more than ten lines. Methods that grow incrementally without refactoring become bloated, difficult to understand, and hard to maintain. The cumulative effect of "just adding a few more lines" creates unwieldy functions that lack clarity and obscure intent.

## Why It's a Problem

- **Reduced Readability**: Long methods are harder to understand at a glance
- **Lower Reusability**: Tightly-coupled logic cannot be extracted and reused elsewhere
- **Testing Complexity**: Large methods require more test cases and setup
- **Hidden Duplication**: Similar logic can hide within long methods, creating maintenance burdens
- **Performance Obscurity**: Genuine optimization opportunities are hidden among unnecessary code
- **Maintenance Costs**: Changes to one feature often require modifying the entire method

## Signs and Symptoms

- Methods exceeding 10-20 lines of code
- Methods with multiple levels of indentation (nested loops, conditionals)
- Local variables that serve only temporary purposes
- Methods doing multiple unrelated tasks
- Difficulty naming the method accurately (if it requires "and/or", it's doing too much)
- Large conditional blocks handling different scenarios
- Loop bodies with complex logic

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

1. **Extract Method**: The primary refactoring technique. Create new methods for logical blocks within the original method. Each new method should have a single responsibility.

2. **Replace Temp with Query**: Remove local variables that serve as temporary holders. Convert them to method calls that compute the value on-demand.

3. **Introduce Parameter Object**: If a method has many parameters or passes multiple values together, group them into a dedicated object.

4. **Replace Method with Method Object**: When other techniques fail, move the entire method logic to a separate class dedicated to that operation.

5. **Decompose Conditional**: Extract complex conditional logic into separate named methods that describe the condition.

6. **Use Enums and Readonly Classes**: Leverage PHP 8.1+ features to create self-documenting, immutable data structures.

## Exceptions

- **Procedural Script**: Simple scripts that perform sequential operations may legitimately be longer without being a smell.
- **Domain-Specific Logic**: Complex mathematical or algorithmic methods might require more lines; if well-structured with helper methods, this is acceptable.
- **Legacy Constraints**: Some refactoring may not be possible due to external dependencies; prioritize high-impact refactoring.

## Related Smells

- **Duplicate Code**: Often hidden within long methods; refactoring reveals duplication
- **Feature Envy**: Long methods frequently access other objects' data excessively
- **Primitive Obsession**: Overuse of primitives instead of objects; see Introduce Parameter Object
- **Data Clumps**: Groups of variables that move together; candidate for Parameter Object

## Refactoring.guru Guidance

### Signs and Symptoms
A method contains too many lines of code. Generally, any method longer than ten lines should make you start asking questions.

### Reasons for the Problem
Methods grow incrementally without refactoring because developers find it simpler to add code than create new methods. It is often harder to create a new method than to add to an existing one, resulting in accumulated complexity and tangled code structures.

### Treatment
- **Extract Method** to reduce method body length
- **Replace Temp with Query**, **Introduce Parameter Object**, or **Preserve Whole Object** when local variables interfere with extraction
- **Replace Method with Method Object** when other approaches fail
- **Decompose Conditional** for complex conditionals
- **Extract Method** for loops with complex bodies

### Payoff
- Short methods improve code longevity and maintainability
- Longer methods become difficult to understand and retain unwanted duplicate code
- Performance concerns from additional method calls prove negligible in practice
