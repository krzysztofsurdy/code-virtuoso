## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before (PHP 8.3+)](#before-php-83)
- [After (PHP 8.3+)](#after-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Decompose Conditional breaks a tangled conditional into well-named methods. Readers no longer parse compound boolean logic or long if-else chains in their heads. Each condition and its action gets a descriptive name that states the intent.

## Motivation

### When to apply

- **Dense boolean expressions**: Conditions composed of multiple `&&` and `||` operators that take effort to read
- **Long if-else chains**: Multi-branch conditionals where each branch handles a different scenario
- **Repeated conditions**: The same compound expression appears in several places
- **Hidden business rules**: The purpose of a condition is not obvious from the raw expression
- **Hard-to-test logic**: Complex conditionals resist focused unit testing
- **Mixed responsibilities**: One conditional handles validation, business rules, and side effects
- **Cognitive strain**: Developers have to stop and think to see what the condition checks

### Why it matters

A well-named method documents itself and stays in sync with the code. Extracting conditions into named methods turns opaque boolean logic into readable steps, lets you test each piece alone, and keeps future changes in one spot.

## Mechanics

1. **Find the complex condition**: Locate if-else statements or compound boolean expressions
2. **Extract the condition**: Move it into a new method that returns a boolean
3. **Choose a meaningful name**: The name should describe the question being asked, not the implementation
4. **Substitute the method call**: Replace the inline condition with a call to the new method
5. **Extract branch bodies if needed**: If the code inside a branch is long, extract it into a named method too
6. **Confirm behavior is preserved**: Run all tests
7. **Repeat**: Do the same for other complex conditionals

## Before (PHP 8.3+)

```php
<?php

declare(strict_types=1);

class UserValidator
{
    public function validateUserRegistration(User $user, string $email): bool
    {
        // Complex condition with mixed concerns
        if (strlen($email) > 5 && str_contains($email, '@') &&
            $user->getAge() >= 18 && $user->getAge() <= 120 &&
            !$this->userRepository->emailExists($email) &&
            $user->getCountry() !== 'BLOCKED') {

            $this->emailService->sendConfirmation($email);
            $this->logger->info("User registration validated");
            return true;
        }

        if ($user->getAge() < 18 || $user->getAge() > 120) {
            $this->logger->warning("Invalid age: " . $user->getAge());
            return false;
        }

        if (strlen($email) <= 5 || !str_contains($email, '@')) {
            $this->logger->warning("Invalid email format");
            return false;
        }

        return false;
    }
}
```

## After (PHP 8.3+)

```php
<?php

declare(strict_types=1);

class UserValidator
{
    public function validateUserRegistration(User $user, string $email): bool
    {
        if (!$this->isValidEmail($email)) {
            $this->logger->warning("Invalid email format");
            return false;
        }

        if (!$this->isValidAge($user->getAge())) {
            $this->logger->warning("Invalid age: {$user->getAge()}");
            return false;
        }

        if (!$this->isRegistrationAllowed($user, $email)) {
            return false;
        }

        $this->emailService->sendConfirmation($email);
        $this->logger->info("User registration validated");
        return true;
    }

    private function isValidEmail(string $email): bool
    {
        return strlen($email) > 5 && str_contains($email, '@');
    }

    private function isValidAge(int $age): bool
    {
        return $age >= 18 && $age <= 120;
    }

    private function isRegistrationAllowed(User $user, string $email): bool
    {
        return !$this->userRepository->emailExists($email) &&
               $user->getCountry() !== 'BLOCKED';
    }
}
```

## Benefits

- **Self-documenting logic**: Method names explain the business rules without comments
- **Independent tests**: Each extracted condition can be tested in isolation
- **Lower cognitive load**: Readers follow the flow without decoding boolean algebra
- **Localized changes**: Changing a business rule touches only its own method
- **Reuse**: Other methods that need the same check can call the extracted condition
- **Composable checks**: Small predicates combine into larger validations
- **Safer changes**: Narrow, well-tested methods are easier to modify without side effects

## When NOT to use

- **Trivial conditions**: A single, readable comparison like `if ($age > 18)` gains nothing from extraction
- **Single-use, clear conditions**: If a condition is used once and already reads naturally, extraction adds indirection for no gain
- **Hot loops**: In extremely performance-sensitive paths, the cost of method calls may matter (rarely a practical concern)
- **Already decomposed**: If conditions are already short and descriptive, more decomposition adds clutter
- **No business meaning**: A condition with no meaningful name gains no readability from extraction

## Related refactorings

- **Extract Method**: Used for the branch body when it contains a lot of logic
- **Replace Conditional with Polymorphism**: Fits when conditions distinguish between object types
- **Extract Variable**: Adds a named variable as a lighter alternative to extracting a method
- **Guard Clauses**: A form of decomposition for precondition checks
- **Introduce Explaining Variable**: An intermediate step before full decomposition
- **Replace Temp with Query**: Removes temporary variables that hold intermediate condition results

## Examples in other languages

### Java

**Before:**
```java
if (date.before(SUMMER_START) || date.after(SUMMER_END)) {
  charge = quantity * winterRate + winterServiceCharge;
}
else {
  charge = quantity * summerRate;
}
```

**After:**
```java
if (isSummer(date)) {
  charge = summerCharge(quantity);
}
else {
  charge = winterCharge(quantity);
}
```

### C#

**Before:**
```csharp
if (date < SUMMER_START || date > SUMMER_END)
{
  charge = quantity * winterRate + winterServiceCharge;
}
else
{
  charge = SummerCharge(quantity);
}
```

**After:**
```csharp
if (isSummer(date))
{
  charge = SummerCharge(quantity);
}
else
{
  charge = WinterCharge(quantity);
}
```

### Python

**Before:**
```python
if date.before(SUMMER_START) or date.after(SUMMER_END):
    charge = quantity * winterRate + winterServiceCharge
else:
    charge = quantity * summerRate
```

**After:**
```python
if isSummer(date):
    charge = summerCharge(quantity)
else:
    charge = winterCharge(quantity)
```

### TypeScript

**Before:**
```typescript
if (date.before(SUMMER_START) || date.after(SUMMER_END)) {
  charge = quantity * winterRate + winterServiceCharge;
}
else {
  charge = quantity * summerRate;
}
```

**After:**
```typescript
if (isSummer(date)) {
  charge = summerCharge(quantity);
}
else {
  charge = winterCharge(quantity);
}
```
