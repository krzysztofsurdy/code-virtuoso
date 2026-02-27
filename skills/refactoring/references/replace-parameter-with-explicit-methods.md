# Replace Parameter with Explicit Methods

## Overview

This refactoring extracts parameter-dependent method variants into separate, dedicated methods. Instead of passing parameters to control which code path executes, you create explicit methods for each behavior variant. This transforms methods that handle multiple concerns based on conditional logic into focused, single-purpose methods.

## Motivation

Parameter-driven methods become problematic when:

- **Code clarity suffers** - Method calls like `setValue("height", 100)` require understanding what "height" means
- **Methods grow large** - Each parameter variant adds branches, increasing cyclomatic complexity
- **Maintenance becomes difficult** - Changes to one variant may inadvertently affect others
- **Variants are stable** - When parameter values rarely change, explicit methods are justified

The refactoring is particularly valuable when each parameter variant contains substantial, non-trivial logic.

## Mechanics

The refactoring process involves three main steps:

1. **Create explicit methods** - For each parameter value variant, create a dedicated method with a descriptive name
2. **Transfer logic** - Move the conditional branch logic into the corresponding explicit method
3. **Update callers** - Replace all calls to the parameterized method with appropriate explicit method calls
4. **Remove original** - Delete the original parameter-driven method once migration is complete

## Before/After Examples

### Example 1: Simple Case (PHP 8.3+)

**Before:**
```php
class Rectangle
{
    private float $width = 0;
    private float $height = 0;

    public function setValue(string $name, float $value): void
    {
        match ($name) {
            'height' => $this->height = $value,
            'width' => $this->width = $value,
            default => throw new InvalidArgumentException("Unknown dimension: {$name}"),
        };
    }
}

// Usage
$rect = new Rectangle();
$rect->setValue('height', 100);
$rect->setValue('width', 50);
```

**After:**
```php
class Rectangle
{
    private float $width = 0;
    private float $height = 0;

    public function setHeight(float $value): void
    {
        $this->height = $value;
    }

    public function setWidth(float $value): void
    {
        $this->width = $value;
    }
}

// Usage
$rect = new Rectangle();
$rect->setHeight(100);
$rect->setWidth(50);
```

### Example 2: Complex Logic (PHP 8.3+)

**Before:**
```php
class Employee
{
    public function getDaysOff(string $type): int
    {
        return match ($type) {
            'annual' => $this->calculateAnnualDaysOff(),
            'sick' => $this->calculateSickDaysOff(),
            'parental' => $this->calculateParentalDaysOff(),
            default => 0,
        };
    }

    private function calculateAnnualDaysOff(): int
    {
        // Complex calculation based on tenure, location, etc.
        return $this->yearsOfService * 2 + 5;
    }

    private function calculateSickDaysOff(): int
    {
        // Country-specific rules
        return match ($this->country) {
            'US' => 5,
            'EU' => 10,
            default => 0,
        };
    }

    private function calculateParentalDaysOff(): int
    {
        // Complex calculation with gender and local laws
        return $this->gender === 'F' ? 180 : 90;
    }
}

// Usage
$employee = new Employee();
$annual = $employee->getDaysOff('annual');
$sick = $employee->getDaysOff('sick');
```

**After:**
```php
class Employee
{
    public function getAnnualDaysOff(): int
    {
        return $this->yearsOfService * 2 + 5;
    }

    public function getSickDaysOff(): int
    {
        return match ($this->country) {
            'US' => 5,
            'EU' => 10,
            default => 0,
        };
    }

    public function getParentalDaysOff(): int
    {
        return $this->gender === 'F' ? 180 : 90;
    }
}

// Usage
$employee = new Employee();
$annual = $employee->getAnnualDaysOff();
$sick = $employee->getSickDaysOff();
```

## Benefits

- **Self-documenting code** - Method names like `setHeight()` immediately convey intent without documentation
- **Type safety** - Each method can accept appropriate parameter types and counts
- **IDE support** - Better autocomplete and parameter hints from IDEs
- **Easier testing** - Each explicit method can be tested independently
- **Reduced complexity** - Eliminates conditional logic and branching within methods
- **Better refactoring** - Explicit methods are easier to further optimize or override in subclasses

## When NOT to Use

Avoid this refactoring when:

- **High frequency of change** - If new parameter variants are added frequently, maintaining many methods becomes tedious
- **Very few variants** - Simple methods with only one or two conditional branches may not justify the extra methods
- **Dynamic parameters** - If parameter values come from user input or configuration, a parameterized approach may be necessary
- **Generic APIs** - Framework methods that must accept generic parameters should remain parameter-driven

## Related Refactorings

- **Parameterize Method** - The inverse refactoring; consolidates multiple similar methods into one parameter-driven method
- **Replace Conditional with Polymorphism** - When variants represent different types, use inheritance/interfaces instead
- **Extract Method** - Often used as a first step; extract conditional branches into helper methods
- **Remove Middle Man** - Opposite pattern when explicit methods become excessive wrappers

## Examples in Other Languages

### Java

**Before:**
```java
void setValue(String name, int value) {
  if (name.equals("height")) {
    height = value;
    return;
  }
  if (name.equals("width")) {
    width = value;
    return;
  }
  Assert.shouldNeverReachHere();
}
```

**After:**
```java
void setHeight(int arg) {
  height = arg;
}
void setWidth(int arg) {
  width = arg;
}
```

### C#

**Before:**
```csharp
void SetValue(string name, int value)
{
  if (name.Equals("height"))
  {
    height = value;
    return;
  }
  if (name.Equals("width"))
  {
    width = value;
    return;
  }
  Assert.Fail();
}
```

**After:**
```csharp
void SetHeight(int arg)
{
  height = arg;
}
void SetWidth(int arg)
{
  width = arg;
}
```

### Python

**Before:**
```python
def output(self, name):
    if name == "banner"
        # Print the banner.
        # ...
    if name == "info"
        # Print the info.
        # ...
```

**After:**
```python
def outputBanner(self):
    # Print the banner.
    # ...

def outputInfo(self):
    # Print the info.
    # ...
```

### TypeScript

**Before:**
```typescript
setValue(name: string, value: number): void {
  if (name.equals("height")) {
    height = value;
    return;
  }
  if (name.equals("width")) {
    width = value;
    return;
  }
}
```

**After:**
```typescript
setHeight(arg: number): void {
  height = arg;
}
setWidth(arg: number): number {
  width = arg;
}
```
