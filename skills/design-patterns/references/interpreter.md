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

## Examples in Other Languages

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

