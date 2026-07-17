# Interpreter Pattern

## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem and solution](#problem-and-solution)
- [Structure](#structure)
- [Key participants](#key-participants)
- [When to use](#when-to-use)
- [Implementation (PHP 8.3+ strict types)](#implementation-php-83-strict-types)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Additional considerations](#additional-considerations)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Interpreter is a behavioral design pattern that maps grammar rules to a class hierarchy, where each class knows how to evaluate itself against a given input. Use it to build domain-specific languages, expression evaluators, query processors, and rule engines that parse and execute structured input.

## Intent

- Model a formal grammar as a set of classes, one per rule
- Provide a recursive evaluation mechanism for sentences that conform to the grammar
- Keep the grammar structure independent of the logic that interprets it

## Problem and solution

**Problem:**
An application has to process structured expressions such as mathematical formulas, search queries, or configuration directives. If the parsing and evaluation logic is embedded in procedural code, the implementation is rigid and breaks whenever the grammar changes.

**Solution:**
Represent each grammar rule as its own class and build an abstract syntax tree (AST) from those classes. Each node interprets itself by recursively delegating to its children, which gives a modular, extensible evaluation pipeline.

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

## Key participants

- **AbstractExpression**: declares the `interpret()` method
- **TerminalExpression**: implements interpretation for leaf nodes
- **NonterminalExpression**: implements interpretation for compound nodes
- **Context**: holds the information needed for interpretation
- **Client**: builds the abstract syntax tree and starts interpretation

## When to use

- Building domain-specific languages where grammar rules map cleanly to classes
- Evaluating mathematical expressions, search queries, or filter criteria at runtime
- Parsing configuration files or template languages
- Building rule engines or workflow interpreters that must be extended without recompilation
- The grammar changes rarely, but the ways of interpreting it keep multiplying

## Implementation (PHP 8.3+ strict types)

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

## Real-world analogies

- **Legal contract clauses**: a contract is a structured document where each clause (expression) has defined terms (terminals) and compound conditions (nonterminals). A lawyer interprets it by recursively evaluating clauses in context.
- **Assembly instructions**: furniture guides use a symbolic language of arrows, numbered parts, and action icons that the builder interprets step by step.
- **Cooking recipes**: a recipe is a small language with ingredients (terminals) and operations like "mix," "fold," or "bake" (nonterminals) that a cook interprets to produce a dish.

## Pros and cons

**Advantages:**
- New expression types are added to the hierarchy without altering existing classes
- Grammar rules and evaluation logic are separated
- The same AST can be interpreted in different ways by swapping the interpretation strategy
- The class-per-rule structure mirrors the grammar, so the code documents itself
- Composite-style recursion handles arbitrarily nested expressions

**Disadvantages:**
- A rich grammar produces many classes, one per rule, which can clutter the codebase
- Deeply nested trees pay for recursive dispatch on every evaluation
- Left-recursive grammars need special handling to avoid infinite loops
- Large expressions use significant memory for the tree
- Tracing a deep chain of recursive `interpret` calls makes debugging harder

## Relations with other patterns

- **Composite**: expression trees are composite structures with leaves and branches
- **Visitor**: an alternative way to add operations to the tree without modifying expression classes
- **Strategy**: different interpretation algorithms can be packaged as interchangeable strategies
- **Builder**: often used to construct the abstract syntax tree from raw input
- **Factory**: selects and instantiates the right expression class from parsed tokens
- **Flyweight**: shared terminal expressions (such as common variable references) can be pooled to save memory

## Additional considerations

Use a parser generator or parsing library for complex grammars (ANTLR, Lemon). Cache interpretation results for frequently evaluated expressions. For recursive descent parsing, implement error handling and recovery. In PHP 8.1+, combine the pattern with `match` expressions for more compact implementations.

## Examples in other languages

### Java

Before and after: building an expression syntax tree for a Celsius-to-Fahrenheit converter:

```java
interface Operand {
    double evaluate(Map<String, Integer> context);
    void traverse(int level);
}

class Expression implements Operand {
    private char operation;
    public Operand left, right;

    public Expression(char operation) {
        this.operation = operation;
    }

    public void traverse(int level) {
        left.traverse(level + 1);
        System.out.print("" + level + operation + level + " ");
        right.traverse(level + 1);
    }

    public double evaluate(Map<String, Integer> context) {
        double result = 0;
        double a = left.evaluate(context);
        double b = right.evaluate(context);
        if (operation == '+') result = a + b;
        if (operation == '-') result = a - b;
        if (operation == '*') result = a * b;
        if (operation == '/') result = a / b;
        return result;
    }
}

class Variable implements Operand {
    private String name;

    public Variable(String name) {
        this.name = name;
    }

    public void traverse(int level) {
        System.out.print(name + " ");
    }

    public double evaluate(Map<String, Integer> context) {
        return context.get(name);
    }
}

class Number implements Operand {
    private double value;

    public Number(double value) {
        this.value = value;
    }

    public void traverse(int level) {
        System.out.print(value + " ");
    }

    public double evaluate(Map context) {
        return value;
    }
}

public class InterpreterDemo {
    public static Operand buildSyntaxTree(String tree) {
        Stack<Operand> stack = new Stack<>();
        String operations = "+-*/";
        String[] tokens = tree.split(" ");
        for (String token : tokens)
            if (operations.indexOf(token.charAt(0)) == -1) {
                Operand term;
                try {
                    term = new Number(Double.parseDouble(token));
                } catch (NumberFormatException ex) {
                    term = new Variable(token);
                }
                stack.push(term);
            } else {
                Expression expr = new Expression(token.charAt(0));
                expr.right = stack.pop();
                expr.left = stack.pop();
                stack.push(expr);
            }
        return stack.pop();
    }

    public static void main(String[] args) {
        String postfix = "celsius 9 * 5 / thirty + ";
        Operand expr = buildSyntaxTree(postfix);
        HashMap<String, Integer> map = new HashMap<>();
        map.put("thirty", 30);
        for (int i = 0; i <= 100; i += 10) {
            map.put("celsius", i);
            System.out.println("C is " + i + ",  F is " + expr.evaluate(map));
        }
    }
}
```

### Python

```python
import abc


class AbstractExpression(metaclass=abc.ABCMeta):
    """
    Declare an abstract Interpret operation that is common to all nodes
    in the abstract syntax tree.
    """

    @abc.abstractmethod
    def interpret(self):
        pass


class NonterminalExpression(AbstractExpression):
    """
    Implement an Interpret operation for nonterminal symbols in the grammar.
    """

    def __init__(self, expression):
        self._expression = expression

    def interpret(self):
        self._expression.interpret()


class TerminalExpression(AbstractExpression):
    """
    Implement an Interpret operation associated with terminal symbols in
    the grammar.
    """

    def interpret(self):
        pass


def main():
    abstract_syntax_tree = NonterminalExpression(TerminalExpression())
    abstract_syntax_tree.interpret()


if __name__ == "__main__":
    main()
```

### C++

Roman numeral interpreter using hierarchical expression classes:

```cpp
#include <iostream>
#include <cstring>
using namespace std;

class RNInterpreter
{
  public:
    RNInterpreter();
    RNInterpreter(int){}
    int interpret(char*);
    virtual void interpret(char *input, int &total)
    {
        int index = 0;
        if (!strncmp(input, nine(), 2))
        {
            total += 9 * multiplier();
            index += 2;
        }
        else if (!strncmp(input, four(), 2))
        {
            total += 4 * multiplier();
            index += 2;
        }
        else
        {
            if (input[0] == five())
            {
                total += 5 * multiplier();
                index = 1;
            }
            else
              index = 0;
            for (int end = index + 3; index < end; index++)
              if (input[index] == one())
                total += 1 * multiplier();
              else
                break;
        }
        strcpy(input, &(input[index]));
    }
  protected:
    virtual char one(){}
    virtual char *four(){}
    virtual char five(){}
    virtual char *nine(){}
    virtual int multiplier(){}
  private:
    RNInterpreter *thousands;
    RNInterpreter *hundreds;
    RNInterpreter *tens;
    RNInterpreter *ones;
};

class Thousand: public RNInterpreter
{
  public:
    Thousand(int): RNInterpreter(1){}
  protected:
    char one()      { return 'M'; }
    char *four()    { return ""; }
    char five()     { return '\0'; }
    char *nine()    { return ""; }
    int multiplier(){ return 1000; }
};

class Hundred: public RNInterpreter
{
  public:
    Hundred(int): RNInterpreter(1){}
  protected:
    char one()      { return 'C'; }
    char *four()    { return "CD"; }
    char five()     { return 'D'; }
    char *nine()    { return "CM"; }
    int multiplier(){ return 100; }
};

class Ten: public RNInterpreter
{
  public:
    Ten(int): RNInterpreter(1){}
  protected:
    char one()      { return 'X'; }
    char *four()    { return "XL"; }
    char five()     { return 'L'; }
    char *nine()    { return "XC"; }
    int multiplier(){ return 10; }
};

class One: public RNInterpreter
{
  public:
    One(int): RNInterpreter(1){}
  protected:
    char one()      { return 'I'; }
    char *four()    { return "IV"; }
    char five()     { return 'V'; }
    char *nine()    { return "IX"; }
    int multiplier(){ return 1; }
};

RNInterpreter::RNInterpreter()
{
  thousands = new Thousand(1);
  hundreds = new Hundred(1);
  tens = new Ten(1);
  ones = new One(1);
}

int RNInterpreter::interpret(char *input)
{
  int total = 0;
  thousands->interpret(input, total);
  hundreds->interpret(input, total);
  tens->interpret(input, total);
  ones->interpret(input, total);
  if (strcmp(input, ""))
    return 0;
  return total;
}

int main()
{
  RNInterpreter interpreter;
  char input[20];
  cout << "Enter Roman Numeral: ";
  while (cin >> input)
  {
    cout << "   interpretation is " << interpreter.interpret(input) << endl;
    cout << "Enter Roman Numeral: ";
  }
}
```
