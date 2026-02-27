## Overview

Substitute Algorithm is a refactoring technique that replaces an existing algorithm with a clearer, simpler, or more efficient implementation. When you discover a better way to implement a method's logic, this refactoring allows you to safely swap the old algorithm for the new one while maintaining the same interface and behavior. This is particularly useful when you understand the problem better or when new, superior solutions become available.

## Motivation

### When to Apply

- **Found a clearer algorithm**: Discovered a simpler, more readable approach to the same problem
- **Performance bottleneck**: The current algorithm is inefficient for the use case
- **Using outdated approaches**: Modern techniques or libraries provide better solutions
- **Difficult to understand**: Current implementation is convoluted and hard to maintain
- **Algorithm no longer fits requirements**: Business logic changes make a different approach more suitable
- **Duplication with better solutions**: Found a library or pattern that handles it better

### Why It Matters

Substitute Algorithm improves code maintainability, performance, and clarity. It recognizes that as we understand problems better, we can implement them more elegantly. Refactoring to a superior algorithm reduces technical debt and makes code more professional.

## Mechanics: Step-by-Step

1. **Ensure test coverage**: Write comprehensive tests for the current algorithm's behavior
2. **Study the new algorithm**: Understand the alternative approach completely
3. **Prepare the new algorithm**: Write the new implementation alongside the old one
4. **Compare inputs and outputs**: Verify both algorithms handle edge cases identically
5. **Switch the algorithm**: Replace the old implementation with the new one
6. **Run all tests**: Verify behavior remains identical across all test cases
7. **Remove old code**: Clean up the deprecated algorithm once confident

## Before: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class StringFormatter
{
    /**
     * Checks if a string is a palindrome (reads same forwards and backwards)
     */
    public function isPalindrome(string $text): bool
    {
        // Remove spaces and convert to lowercase
        $cleaned = strtolower(str_replace(' ', '', $text));

        // Inefficient approach: build reversed string character by character
        $reversed = '';
        for ($i = strlen($cleaned) - 1; $i >= 0; $i--) {
            $reversed .= $cleaned[$i];
        }

        return $cleaned === $reversed;
    }

    /**
     * Extracts domain from email address
     */
    public function extractEmailDomain(string $email): string
    {
        // Manual string parsing approach
        $parts = [];
        $current = '';

        foreach (str_split($email) as $char) {
            if ($char === '@') {
                break;
            }
            $current .= $char;
        }

        $parts['local'] = $current;
        $parts['domain'] = substr($email, strlen($current) + 1);

        return $parts['domain'] ?? '';
    }
}
```

## After: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class StringFormatter
{
    /**
     * Checks if a string is a palindrome using two-pointer technique
     */
    public function isPalindrome(string $text): bool
    {
        // Remove spaces and convert to lowercase
        $cleaned = strtolower(str_replace(' ', '', $text));

        // More efficient: compare from both ends, meeting in the middle
        $length = strlen($cleaned);

        for ($i = 0; $i < $length / 2; $i++) {
            if ($cleaned[$i] !== $cleaned[$length - 1 - $i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Extracts domain from email address using built-in parsing
     */
    public function extractEmailDomain(string $email): string
    {
        // Use filter_var or parse_email equivalent
        if (!str_contains($email, '@')) {
            return '';
        }

        // Cleaner approach: explode at @ and take the domain part
        [, $domain] = explode('@', $email, 2);

        return $domain ?: '';
    }
}
```

## Benefits

- **Improved Performance**: Superior algorithms reduce execution time and resource consumption
- **Enhanced Readability**: Clearer implementations are easier for developers to understand
- **Better Maintainability**: Simpler logic reduces maintenance burden and bug potential
- **Professional Code Quality**: Modern, elegant solutions reflect well-engineered software
- **Reduced Cognitive Load**: Developers spend less mental effort understanding the code
- **Leverages Best Practices**: Incorporates industry-standard approaches and patterns
- **Future-Proof**: Better algorithms often scale better with changing requirements

## When NOT to Use

- **Premature Optimization**: Don't substitute algorithms to optimize code that isn't a bottleneck
- **Unproven Alternatives**: Avoid switching to algorithms without thorough testing and validation
- **Insufficient Testing**: Don't substitute without comprehensive test coverage guaranteeing behavior
- **Complex Behavior**: When the current algorithm handles edge cases the new one doesn't
- **High Risk/Reward Ratio**: Changing critical algorithms in production systems carries risk
- **Missing Context**: Don't substitute if you don't fully understand both algorithms' implications

## Related Refactorings

- **Extract Method**: Often precedes substitution by isolating the algorithm to replace
- **Replace Loop with Pipeline**: Modernizes iteration patterns to cleaner functional approaches
- **Replace Type Code with State/Strategy Pattern**: When algorithm choice depends on state or conditions
- **Decompose Conditional**: Simplifies algorithm selection logic before substitution
- **Replace Conditional with Polymorphism**: Enables different algorithms via inheritance or interfaces

## Examples in Other Languages

### Java

**Before:**
```java
String foundPerson(String[] people){
  for (int i = 0; i < people.length; i++) {
    if (people[i].equals("Don")){
      return "Don";
    }
    if (people[i].equals("John")){
      return "John";
    }
    if (people[i].equals("Kent")){
      return "Kent";
    }
  }
  return "";
}
```

**After:**
```java
String foundPerson(String[] people){
  List candidates =
    Arrays.asList(new String[] {"Don", "John", "Kent"});
  for (int i = 0; i < people.length; i++) {
    if (candidates.contains(people[i])) {
      return people[i];
    }
  }
  return "";
}
```

### C#

**Before:**
```csharp
string FoundPerson(string[] people)
{
  for (int i = 0; i < people.Length; i++)
  {
    if (people[i].Equals("Don"))
    {
      return "Don";
    }
    if (people[i].Equals("John"))
    {
      return "John";
    }
    if (people[i].Equals("Kent"))
    {
      return "Kent";
    }
  }
  return String.Empty;
}
```

**After:**
```csharp
string FoundPerson(string[] people)
{
  List<string> candidates = new List<string>() {"Don", "John", "Kent"};

  for (int i = 0; i < people.Length; i++)
  {
    if (candidates.Contains(people[i]))
    {
      return people[i];
    }
  }

  return String.Empty;
}
```

### Python

**Before:**
```python
def foundPerson(people):
    for i in range(len(people)):
        if people[i] == "Don":
            return "Don"
        if people[i] == "John":
            return "John"
        if people[i] == "Kent":
            return "Kent"
    return ""
```

**After:**
```python
def foundPerson(people):
    candidates = ["Don", "John", "Kent"]
    return people if people in candidates else ""
```

### TypeScript

**Before:**
```typescript
foundPerson(people: string[]): string {
  for (let person of people) {
    if (person.equals("Don")){
      return "Don";
    }
    if (person.equals("John")){
      return "John";
    }
    if (person.equals("Kent")){
      return "Kent";
    }
  }
  return "";
}
```

**After:**
```typescript
foundPerson(people: string[]): string {
  let candidates = ["Don", "John", "Kent"];
  for (let person of people) {
    if (candidates.includes(person)) {
      return person;
    }
  }
  return "";
}
```
