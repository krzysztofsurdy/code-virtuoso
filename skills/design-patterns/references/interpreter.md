## Overview

The Interpreter pattern provides a way to evaluate sentences in a formal language by defining classes for grammar rules and an interpreter that processes them. It's part of the Behavioral design patterns and is essential for building domain-specific languages (DSLs), query processors, and expression evaluators.

## Intent

- Define a grammatical representation for a language
- Implement an interpreter to process sentences conforming to the grammar
- Separate the grammar structure from its interpretation logic

## Problem and Solution

**Problem:**
When you need to process text or expressions that follow a specific grammar (like SQL queries, mathematical expressions, or configuration languages), hardcoding the logic becomes inflexible and difficult to maintain.

**Solution:**
Create a class hierarchy representing each grammar rule, where each class knows how to interpret itself. Build an interpreter that traverses the grammar tree and executes interpretation logic recursively.

## Structure

```
                    ┌─────────────────────┐
                    │    Expression       │
                    │  (abstract)         │
                    │  + interpret()      │
                    └──────────┬──────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
        ┌───────▼─────┐  ┌────▼────────┐  ┌──▼──────────────┐
        │TerminalExpr │  │NonterminalExpr│  │  Client/Context│
        │ + interpret()│  │ + interpret()  │  │  + interpret() │
        └──────────────┘  └────┬──────────┘  └────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
            ┌──────▼──────┐         ┌──────▼──────┐
            │  Sequence   │         │  Repetition │
            │ + interpret()│         │ + interpret()│
            └─────────────┘         └─────────────┘
```

## Key Participants

- **AbstractExpression**: Declares the `interpret()` method
- **TerminalExpression**: Implements interpretation for leaf nodes
- **NonterminalExpression**: Implements interpretation for compound nodes
- **Context**: Contains information needed for interpretation
- **Client**: Builds the abstract syntax tree and initiates interpretation

## When to Use

- Building domain-specific languages (DSLs)
- Implementing query languages or expression evaluators
- Creating configuration file parsers
- Processing mathematical expressions or regular expressions
- Building rule engines or workflow interpreters
- When grammar changes infrequently but interpretations do

## Implementation (PHP 8.3+ Strict Types)

```php
<?php

declare(strict_types=1);

namespace DesignPatterns\Interpreter;

// Context to hold interpretation state
readonly class Context
{
    public function __construct(
        private string $statement,
        private array $variables = []
    ) {}

    public function getStatement(): string
    {
        return $this->statement;
    }

    public function getVariable(string $name): mixed
    {
        return $this->variables[$name] ?? null;
    }

    public function setVariable(string $name, mixed $value): void
    {
        $this->variables[$name] = $value;
    }
}

// Abstract expression interface
interface Expression
{
    public function interpret(Context $context): mixed;
}

// Terminal expression - represents literals or variables
readonly class VariableExpression implements Expression
{
    public function __construct(private string $name) {}

    public function interpret(Context $context): mixed
    {
        return $context->getVariable($this->name);
    }
}

readonly class LiteralExpression implements Expression
{
    public function __construct(private mixed $value) {}

    public function interpret(Context $context): mixed
    {
        return $this->value;
    }
}

// Nonterminal expressions - represent operations
readonly class AddExpression implements Expression
{
    public function __construct(
        private Expression $left,
        private Expression $right
    ) {}

    public function interpret(Context $context): mixed
    {
        return $this->left->interpret($context) +
               $this->right->interpret($context);
    }
}

readonly class MultiplyExpression implements Expression
{
    public function __construct(
        private Expression $left,
        private Expression $right
    ) {}

    public function interpret(Context $context): mixed
    {
        return $this->left->interpret($context) *
               $this->right->interpret($context);
    }
}

// Usage example
$context = new Context('x + y * 2', [
    'x' => 10,
    'y' => 20,
]);

// Build AST: (x) + ((y) * (2))
$ast = new AddExpression(
    new VariableExpression('x'),
    new MultiplyExpression(
        new VariableExpression('y'),
        new LiteralExpression(2)
    )
);

$result = $ast->interpret($context); // 50
```

## Real-World Analogies

- **Language Translation**: Grammar rules define syntax; interpreter translates to machine code
- **Musical Sheet**: Notes and symbols (grammar) interpreted by musicians (interpreter)
- **Recipe**: Instructions (grammar) interpreted by chef (interpreter)
- **Traffic Signals**: Color codes (language) interpreted by drivers
- **Mathematical Notation**: Operators and operands interpreted by calculator

## Pros and Cons

**Advantages:**
- Makes grammar easily extensible with new expression types
- Separates grammar from interpretation logic
- Simplifies adding new operations
- Clear structure for complex grammars
- Supports multiple interpretations of same grammar

**Disadvantages:**
- Complex grammars require many classes (class proliferation)
- Performance overhead for deep expression trees
- Difficult to handle left-recursive grammars
- Can become memory-intensive with large expressions
- Debugging complex interpretation chains is challenging

## Relations with Other Patterns

- **Composite**: Expression classes form a composite tree structure
- **Visitor**: Can alternative to Interpreter for separating operations from structure
- **Strategy**: Different expression interpretations are different strategies
- **Builder**: Often used to construct abstract syntax trees
- **Factory**: Used to create appropriate expression instances
- **Flyweight**: Can optimize shared terminal expressions

## Additional Considerations

Use a parser generator or parsing library for complex grammars (ANTLR, Lemon). Consider caching interpretation results for frequently-evaluated expressions. For recursive descent parsing, implement proper error handling and recovery strategies. Combine with pattern matching for more elegant implementations in PHP 8.1+.

