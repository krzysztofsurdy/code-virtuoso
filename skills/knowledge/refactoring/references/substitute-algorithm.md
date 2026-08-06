## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before: PHP 8.3+ example](#before-php-83-example)
- [After: PHP 8.3+ example](#after-php-83-example)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Substitute Algorithm replaces an existing algorithm with a clearer, simpler, or faster one. The method keeps the same interface and behavior, and only its internals change. Use it when you understand the problem better than you did, or when a better solution is now available.

## Motivation

### When to apply

- **A clearer algorithm exists**: you found a simpler, more readable approach to the same problem.
- **Performance bottleneck**: the current algorithm is too slow for the use case.
- **Outdated approach**: a newer technique or library gives a better solution.
- **Hard to understand**: the current implementation is convoluted and hard to maintain.
- **Changed requirements**: business logic changed, and a different approach now fits better.
- **Duplicated effort**: a library or pattern already solves the problem.

### Why it matters

A better algorithm makes the code easier to maintain, faster, or clearer. It also reduces technical debt.

## Mechanics

1. **Check test coverage**: write tests that pin down the current algorithm's behavior.
2. **Study the new algorithm**: understand the alternative before using it.
3. **Prepare the new algorithm**: write the new implementation next to the old one.
4. **Compare inputs and outputs**: verify that both algorithms handle edge cases the same way.
5. **Switch the algorithm**: replace the old implementation with the new one.
6. **Run all tests**: verify that behavior is identical across all test cases.
7. **Remove the old code**: delete the old algorithm once you are confident.

## Before: PHP 8.3+ example

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

## After: PHP 8.3+ example

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

- **Performance**: a better algorithm cuts execution time and resource use.
- **Readability**: a clearer implementation is easier to understand.
- **Maintainability**: simpler logic means less maintenance work and fewer bugs.
- **Lower cognitive load**: readers spend less effort understanding the code.
- **Established practice**: the new version can use standard approaches and patterns.
- **Scaling**: a better algorithm often scales better as requirements change.

## When not to use

- **Premature optimization**: do not swap algorithms to speed up code that is not a bottleneck.
- **Unproven alternatives**: do not switch without testing and validating the new algorithm.
- **Insufficient tests**: do not substitute without test coverage that pins down current behavior.
- **Edge cases**: the current algorithm handles cases the new one does not.
- **High risk**: changing critical algorithms in production systems carries risk.
- **Missing context**: do not substitute if you do not understand the implications of both algorithms.

## Related refactorings

- **Extract Method**: often comes first, to isolate the algorithm to replace.
- **Replace Loop with Pipeline**: turns iteration into a cleaner functional form.
- **Replace Type Code with State/Strategy**: for when the choice of algorithm depends on state or conditions.
- **Decompose Conditional**: simplifies algorithm selection logic before substitution.
- **Replace Conditional with Polymorphism**: lets different algorithms live behind an inheritance hierarchy or interface.

## Examples in other languages

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
