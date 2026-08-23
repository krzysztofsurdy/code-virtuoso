# Replace Parameter with Explicit Methods

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After Examples](#beforeafter-examples)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Replace Parameter with Explicit Methods splits one parameter-driven method into several methods, one per behavior variant. Instead of a parameter that steers branching inside the method, each variant gets its own clearly named method. You end up with small, single-purpose operations in place of one method that does many things based on conditional checks.

## Motivation

Parameter-driven methods become a problem when:

- **Readability suffers**: A call like `setValue("height", 100)` forces the reader to know what "height" means in context
- **Methods bloat**: Every new variant adds a branch and raises cyclomatic complexity
- **Maintenance risk grows**: Changing one variant's logic can break others that share the method body
- **Variants are stable**: When the set of parameter values rarely changes, separate methods fit better

The refactoring pays off most when each variant has its own non-trivial logic.

## Mechanics

1. **Define explicit methods**: Create a separate, descriptively named method for each parameter value
2. **Migrate logic**: Move each conditional branch's body into the matching new method
3. **Redirect callers**: Change every call site to call the right explicit method
4. **Delete the original**: Remove the parameter-driven method once no callers remain

## Before/After Examples

### Example 1: simple case (PHP 8.3+)

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

### Example 2: complex logic (PHP 8.3+)

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

- **Self-documenting code**: Names like `setHeight()` convey intent without comments
- **Type safety**: Each method declares the exact parameter types and count it needs
- **IDE support**: Autocompletion and parameter hints work with distinct methods
- **Easier testing**: Each method can be tested in isolation
- **Lower complexity**: The conditional branching inside one method body disappears
- **Easier follow-up changes**: Explicit methods are simpler to optimize or override in subclasses

## When NOT to use

Avoid this refactoring when:

- **Variants change often**: If new parameter values are added regularly, maintaining many methods gets tedious
- **Few variants**: A method with only one or two branches may not be worth splitting
- **Dynamic parameters**: When values come from user input or runtime configuration, you need the parameterized form
- **Generic APIs**: Framework-level methods designed to accept open-ended parameters should stay parameter-driven

## Related Refactorings

- **Parameterize Method**: The inverse refactoring; merges several similar methods into one that takes a parameter
- **Replace Conditional with Polymorphism**: When variants map to distinct types, use inheritance or interfaces
- **Extract Method**: Often applied first to pull conditional branches into helper methods
- **Remove Middle Man**: The counterpoint when explicit methods turn into trivial pass-through wrappers

## Examples in other languages

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
