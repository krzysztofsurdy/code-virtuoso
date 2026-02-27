## Overview

Decompose Conditional is a refactoring technique that breaks down complex conditional logic into separate methods with meaningful names. Instead of having long, difficult-to-understand if-else chains or multi-part conditions, this technique extracts each condition and its logic into a dedicated method. This improves code clarity by making the intent of each condition explicit and easier to test independently.

## Motivation

### When to Apply

- **Long conditionals**: Complex if-else chains that are hard to understand at a glance
- **Multiple conditions**: Conditions with AND/OR operators that obscure intent
- **Duplicated conditions**: Same complex conditions appear in multiple places
- **Business logic clarity**: Condition's purpose isn't immediately obvious from the code
- **Testing challenges**: Complex conditional logic is difficult to unit test comprehensively
- **Mixed concerns**: A conditional handles multiple responsibilities
- **High cognitive load**: Developers need to mentally parse complex boolean expressions

### Why It Matters

Decomposing conditionals makes code more readable, maintainable, and testable. Complex conditions with multiple operators are cognitive overhead for developers. By extracting conditions into well-named methods, the code becomes self-documenting and easier to modify safely.

## Mechanics: Step-by-Step

1. **Identify complex condition**: Locate if-else statements or complex boolean expressions
2. **Extract condition**: Create a new method that returns the boolean result
3. **Name meaningfully**: Choose a method name that describes what the condition checks
4. **Replace condition**: Replace the original condition with a call to the new method
5. **Extract branch logic**: If the conditional has substantial logic, extract that too (see Extract Method)
6. **Test thoroughly**: Verify behavior remains identical for all condition branches
7. **Repeat as needed**: Apply to other complex conditions in the codebase

## Before: PHP 8.3+ Example

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

## After: PHP 8.3+ Example

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

- **Improved Readability**: Method names clearly express the business logic being checked
- **Self-Documenting Code**: Well-named condition methods eliminate need for comments
- **Enhanced Testability**: Each condition can be tested independently in isolation
- **Reduced Complexity**: Breaks down cognitive load of parsing complex boolean expressions
- **Easier Maintenance**: Changes to a specific condition logic are localized to one method
- **Code Reusability**: Extracted condition methods can be used in multiple places
- **Better Composition**: Enables straightforward composition of related conditions
- **Safer Refactoring**: Smaller, focused methods are easier to refactor without breaking changes

## When NOT to Use

- **Simple conditions**: Single, clear conditions (e.g., `if ($age > 18)`) don't benefit from extraction
- **One-time conditions**: Conditions used only once might not justify method extraction
- **Performance-critical paths**: In tight loops, excessive method calls might impact performance (rarely a practical concern)
- **Already extracted**: If conditions are already simple and clear, further extraction adds clutter
- **Trivial business value**: Extracting conditions that have no business meaning might reduce clarity

## Related Refactorings

- **Extract Method**: For extracting the logic inside conditional branches
- **Replace Conditional with Polymorphism**: When conditions represent different types in a hierarchy
- **Extract Variable**: For breaking down complex expressions without creating methods
- **Guard Clauses**: A specific application of decompose conditional for handling preconditions
- **Introduce Explaining Variable**: Before full decomposition, extract variables for intermediate clarity
- **Replace Temp with Query**: To eliminate temporary variables in conditionals

## Examples in Other Languages

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
