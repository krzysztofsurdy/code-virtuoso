# Long Method Code Smell

A Long Method has taken on far more responsibility than it should. As a rule of thumb, anything over ten lines deserves a closer look. Methods grow as developers add "just one more thing." Over time they become dense, intertwined, and fragile. The longer a method gets, the harder it is to name, test, and reason about.

## Contents

- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after examples](#before-and-after-examples)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Why it's a problem

- **Cognitive overload**: dense methods force readers to hold too much context at once.
- **Poor reusability**: when logic is woven together inside one method, individual pieces cannot be reused elsewhere.
- **Testing burden**: every extra responsibility multiplies the scenarios that need coverage.
- **Hidden repetition**: repeated patterns buried in long methods are easy to overlook, which leads to inconsistent bug fixes.
- **Performance blind spots**: real bottlenecks get buried among irrelevant code.
- **Change risk**: changing one section can break unrelated behavior in the same block.

## Signs and symptoms

- Methods longer than 10-20 lines
- Deeply nested control structures (loops inside conditionals inside loops)
- Temporary local variables that only hold intermediate values
- A single method handling several unrelated concerns
- A name that would need "and" or "or" to describe the method accurately
- Large conditional branches governing different execution paths
- Complex logic embedded directly in loop bodies

## Before and after examples

### Before: long, monolithic method

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

### After: refactored methods

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

## Recommended refactorings

1. **Extract Method**: the main tool. Find logical blocks within the method and pull each into its own well-named method that handles a single concern.

2. **Replace Temp with Query**: turn temporary local variables into method calls that compute the value on demand. This clears the way for further extraction.

3. **Introduce Parameter Object**: when a method takes many parameters or passes clusters of values together, consolidate them into a dedicated object. It pairs well with **Preserve Whole Object**: pass the source object rather than pulling individual fields from it.

4. **Replace Method with Method Object**: a fallback for when tangled local variables make extraction impractical. Promote the whole method into its own class, where the local variables become fields.

5. **Decompose Conditional**: extract complex conditional logic into descriptively named methods so the branching explains itself.

6. **Use enums and readonly classes**: PHP 8.1+ features give you self-describing, immutable data structures that remove the need for inline logic.

Breaking a method into shorter ones adds very little call overhead. The readability gain is larger.

## Exceptions

- **Procedural scripts**: simple scripts that perform sequential operations can reasonably run longer.
- **Algorithmic methods**: complex mathematical or scientific computations sometimes need more lines. If they are well structured with helper methods, that is acceptable.
- **Legacy constraints**: external dependencies may block certain refactorings, so direct effort at the highest-impact areas.

## Related smells

- **Duplicate Code**: often hides inside long methods, and decomposing them exposes it.
- **Feature Envy**: long methods often reach too far into other objects' data.
- **Primitive Obsession**: reliance on raw types instead of objects. Introduce Parameter Object is a shared remedy.
- **Data Clumps**: groups of variables that travel together are strong candidates for a Parameter Object.
