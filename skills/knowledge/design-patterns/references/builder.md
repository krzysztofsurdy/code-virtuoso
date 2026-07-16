# Builder Pattern

## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem and solution](#problem-and-solution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation](#implementation)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Examples in other languages](#examples-in-other-languages)

## Overview

The Builder pattern is a creational design pattern that separates the construction of a complex object from its representation. Instead of passing dozens of parameters to one constructor or juggling overloaded variants, you give the assembly work to a dedicated builder that configures the target step by step through named methods.

## Intent

- Decouple how a complex object is assembled from what the finished object looks like
- Produce multiple representations of the same product by reusing the same construction steps
- Avoid the "telescoping constructor" problem, where parameter lists grow with every new option
- Give objects with many required and optional attributes a fluent, self-documenting setup API

## Problem and solution

**Problem:**
Objects that need many parameters, especially optional ones, cause recurring problems:
- Long positional argument lists are fragile and opaque to callers
- Constructor overloads multiply and blur the distinction between variants
- Setting optional fields after construction breaks immutability
- Call sites full of unnamed arguments are hard to read and review

**Solution:**
The Builder pattern supplies a separate builder class whose named setter methods accumulate configuration incrementally. The final object is produced only when the caller invokes `build()`, which validates the accumulated state and returns a fully initialized, consistent product.

## Structure

```
┌─────────────────┐
│   Director      │ (optional - orchestrates building)
└────────┬────────┘
         │ uses
         ▼
┌─────────────────┐       builds      ┌─────────────────┐
│     Builder     │◄─────────────────▶│     Product     │
└─────────────────┘                   └─────────────────┘
```

**Key Components:**
- **Product:** The complex object being constructed
- **Builder:** Abstract interface for building parts of the product
- **ConcreteBuilder:** Implements the builder interface; constructs and assembles parts
- **Director:** (Optional) Orchestrates the building process with a defined algorithm

## When to use

Use the Builder pattern when:
- An object has more than a handful of constructor parameters, especially when many are optional
- You need to produce different variants or representations of the same type of object
- The assembly process must remain independent from the components that form the final product
- You want immutable objects but still need a flexible way to configure them
- Construction involves validation or multi-step initialization logic
- You are designing fluent or method-chaining APIs

Common scenarios:
- Building configuration objects
- Creating query builders (SQL, search criteria)
- Constructing complex domain models
- Creating objects with many optional attributes

## Implementation

### Basic Builder Pattern (PHP 8.3+)

```php
<?php

declare(strict_types=1);

namespace App\Design\Builder;

/**
 * Complex product requiring multiple parameters
 */
readonly class DatabaseConnection
{
    public function __construct(
        public string $host,
        public int $port,
        public string $database,
        public string $username,
        public string $password,
        public array $options,
        public int $poolSize,
        public bool $ssl,
        public ?string $charset,
    ) {}

    public function connectionString(): string
    {
        return sprintf(
            'mysql://%s:%d/%s?ssl=%s&pool=%d',
            $this->host,
            $this->port,
            $this->database,
            $this->ssl ? 'true' : 'false',
            $this->poolSize,
        );
    }
}

/**
 * Builder for DatabaseConnection
 */
class DatabaseBuilder
{
    private string $host = 'localhost';
    private int $port = 3306;
    private string $database = '';
    private string $username = '';
    private string $password = '';
    private array $options = [];
    private int $poolSize = 10;
    private bool $ssl = false;
    private ?string $charset = 'utf8mb4';

    public function host(string $host): self
    {
        $this->host = $host;
        return $this;
    }

    public function port(int $port): self
    {
        $this->port = $port;
        return $this;
    }

    public function database(string $database): self
    {
        $this->database = $database;
        return $this;
    }

    public function credentials(string $username, string $password): self
    {
        $this->username = $username;
        $this->password = $password;
        return $this;
    }

    public function enableSSL(bool $enable = true): self
    {
        $this->ssl = $enable;
        return $this;
    }

    public function poolSize(int $size): self
    {
        $this->poolSize = $size;
        return $this;
    }

    public function options(array $options): self
    {
        $this->options = array_merge($this->options, $options);
        return $this;
    }

    public function build(): DatabaseConnection
    {
        $this->validate();

        return new DatabaseConnection(
            host: $this->host,
            port: $this->port,
            database: $this->database,
            username: $this->username,
            password: $this->password,
            options: $this->options,
            poolSize: $this->poolSize,
            ssl: $this->ssl,
            charset: $this->charset,
        );
    }

    private function validate(): void
    {
        if (empty($this->database)) {
            throw new \InvalidArgumentException('Database name is required');
        }
        if (empty($this->username)) {
            throw new \InvalidArgumentException('Username is required');
        }
        if ($this->port < 1 || $this->port > 65535) {
            throw new \InvalidArgumentException('Invalid port number');
        }
    }
}

// Usage
$connection = (new DatabaseBuilder())
    ->host('prod.example.com')
    ->port(5432)
    ->database('myapp_db')
    ->credentials('admin', 'secret123')
    ->enableSSL()
    ->poolSize(20)
    ->options(['timeout' => 30])
    ->build();

echo $connection->connectionString();
```

### Advanced: Builder with Named Arguments (PHP 8.3)

```php
<?php

declare(strict_types=1);

namespace App\Design\Builder;

/**
 * Using enums for configuration options
 */
enum SSLMode: string
{
    case DISABLED = 'disabled';
    case ENABLED = 'enabled';
    case REQUIRED = 'required';
}

/**
 * Modern builder using PHP 8.3+ features
 */
class QueryBuilder
{
    private array $select = [];
    private array $from = [];
    private array $joins = [];
    private array $where = [];
    private array $groupBy = [];
    private array $having = [];
    private array $orderBy = [];
    private int $limit = 0;
    private int $offset = 0;

    public function select(string|array $columns): self
    {
        $this->select = array_merge(
            $this->select,
            is_array($columns) ? $columns : [$columns]
        );
        return $this;
    }

    public function from(string $table, ?string $alias = null): self
    {
        $this->from[] = $alias ? "$table AS $alias" : $table;
        return $this;
    }

    public function where(string $condition, mixed $value): self
    {
        $this->where[] = ['condition' => $condition, 'value' => $value];
        return $this;
    }

    public function orderBy(string $column, string $direction = 'ASC'): self
    {
        $this->orderBy[] = "$column $direction";
        return $this;
    }

    public function limit(int $limit): self
    {
        $this->limit = $limit;
        return $this;
    }

    public function offset(int $offset): self
    {
        $this->offset = $offset;
        return $this;
    }

    public function build(): string
    {
        if (empty($this->select) || empty($this->from)) {
            throw new \InvalidArgumentException('SELECT and FROM are required');
        }

        $query = 'SELECT ' . implode(', ', $this->select);
        $query .= ' FROM ' . implode(', ', $this->from);

        if (!empty($this->where)) {
            $conditions = array_map(
                fn($w) => "{$w['condition']} = ?",
                $this->where
            );
            $query .= ' WHERE ' . implode(' AND ', $conditions);
        }

        if (!empty($this->orderBy)) {
            $query .= ' ORDER BY ' . implode(', ', $this->orderBy);
        }

        if ($this->limit > 0) {
            $query .= " LIMIT {$this->limit}";
        }

        if ($this->offset > 0) {
            $query .= " OFFSET {$this->offset}";
        }

        return $query;
    }
}

// Usage
$sql = (new QueryBuilder())
    ->select(['users.id', 'users.name', 'posts.title'])
    ->from('users')
    ->from('posts')
    ->where('users.id', 123)
    ->orderBy('posts.created_at', 'DESC')
    ->limit(10)
    ->build();
```

## Real-world analogies

**Deli Sandwich Counter:** You specify bread, filling, toppings, and sauce one selection at a time. The sandwich maker assembles everything to your choices, and the finished sandwich is wrapped and handed over only when you say "that's all".

**Custom PC Configuration:** When building a custom workstation, you pick the processor, memory, storage, and graphics card independently. The technician follows the same assembly process whichever parts you picked, and the machine is not powered on until every component is in place.

## Pros and cons

**Advantages:**
- Call sites read well through fluent method chaining
- Many object configurations are possible without constructor overloads
- Works well with readonly or immutable classes, since the product is finalized in one step
- Construction logic lives in the builder, not in the product class
- Validation runs at build time, before the object exists, so invalid state is caught early
- New optional fields can be added to the builder without breaking existing callers

**Disadvantages:**
- Needs an extra class per product type
- Adds ceremony when the product has only a few simple parameters
- Builder instances hold memory until they go out of scope or are garbage collected
- Shared or reused builder instances need synchronization in concurrent environments

## Relations with other patterns

**Composite:** Builder can orchestrate the assembly of complex composite tree structures
**Abstract Factory:** Both create objects, but Abstract Factory produces families of products while Builder constructs a single product step by step
**Strategy:** Different construction strategies can be injected into a builder to produce distinct product variants
**Prototype:** Both address object creation, but Builder gives finer control when construction has multiple configurable steps

---

**Key takeaway:** Use Builder for complex objects with many parameters or configuration options. It keeps construction logic out of the product class and makes call sites readable.

## Examples in other languages

### Java

```java
/* "Product" */
class Pizza {
    private String dough = "";
    private String sauce = "";
    private String topping = "";

    public void setDough(String dough) {
        this.dough = dough;
    }

    public void setSauce(String sauce) {
        this.sauce = sauce;
    }

    public void setTopping(String topping) {
        this.topping = topping;
    }
}

/* "Abstract Builder" */
abstract class PizzaBuilder {
    protected Pizza pizza;

    public Pizza getPizza() {
        return pizza;
    }

    public void createNewPizzaProduct() {
        pizza = new Pizza();
    }

    public abstract void buildDough();
    public abstract void buildSauce();
    public abstract void buildTopping();
}

/* "ConcreteBuilder" */
class HawaiianPizzaBuilder extends PizzaBuilder {
    public void buildDough() {
        pizza.setDough("cross");
    }

    public void buildSauce() {
        pizza.setSauce("mild");
    }

    public void buildTopping() {
        pizza.setTopping("ham+pineapple");
    }
}

/* "ConcreteBuilder" */
class SpicyPizzaBuilder extends PizzaBuilder {
    public void buildDough() {
        pizza.setDough("pan baked");
    }

    public void buildSauce() {
        pizza.setSauce("hot");
    }

    public void buildTopping() {
        pizza.setTopping("pepperoni+salami");
    }
}

/* "Director" */
class Waiter {
    private PizzaBuilder pizzaBuilder;

    public void setPizzaBuilder(PizzaBuilder pb) {
        pizzaBuilder = pb;
    }

    public Pizza getPizza() {
        return pizzaBuilder.getPizza();
    }

    public void constructPizza() {
        pizzaBuilder.createNewPizzaProduct();
        pizzaBuilder.buildDough();
        pizzaBuilder.buildSauce();
        pizzaBuilder.buildTopping();
    }
}

public class PizzaBuilderDemo {
    public static void main(String[] args) {
        Waiter waiter = new Waiter();
        PizzaBuilder hawaiianPizzabuilder = new HawaiianPizzaBuilder();
        PizzaBuilder spicyPizzaBuilder = new SpicyPizzaBuilder();

        waiter.setPizzaBuilder(hawaiianPizzabuilder);
        waiter.constructPizza();

        Pizza pizza = waiter.getPizza();
    }
}
```

### C++

```cpp
#include <iostream.h>
#include <stdio.h>
#include <string.h>

enum PersistenceType {
  File, Queue, Pathway
};

struct PersistenceAttribute {
  PersistenceType type;
  char value[30];
};

class DistrWorkPackage {
  public:
    DistrWorkPackage(char *type) {
        sprintf(_desc, "Distributed Work Package for: %s", type);
    }
    void setFile(char *f, char *v) {
        sprintf(_temp, "\n  File(%s): %s", f, v);
        strcat(_desc, _temp);
    }
    void setQueue(char *q, char *v) {
        sprintf(_temp, "\n  Queue(%s): %s", q, v);
        strcat(_desc, _temp);
    }
    void setPathway(char *p, char *v) {
        sprintf(_temp, "\n  Pathway(%s): %s", p, v);
        strcat(_desc, _temp);
    }
    const char *getState() {
        return _desc;
    }
  private:
    char _desc[200], _temp[80];
};

class Builder {
  public:
    virtual void configureFile(char*) = 0;
    virtual void configureQueue(char*) = 0;
    virtual void configurePathway(char*) = 0;
    DistrWorkPackage *getResult() {
        return _result;
    }
  protected:
    DistrWorkPackage *_result;
};

class UnixBuilder: public Builder {
  public:
    UnixBuilder() {
        _result = new DistrWorkPackage("Unix");
    }
    void configureFile(char *name) {
        _result->setFile("flatFile", name);
    }
    void configureQueue(char *queue) {
        _result->setQueue("FIFO", queue);
    }
    void configurePathway(char *type) {
        _result->setPathway("thread", type);
    }
};

class VmsBuilder: public Builder {
  public:
    VmsBuilder() {
        _result = new DistrWorkPackage("Vms");
    }
    void configureFile(char *name) {
        _result->setFile("ISAM", name);
    }
    void configureQueue(char *queue) {
        _result->setQueue("priority", queue);
    }
    void configurePathway(char *type) {
        _result->setPathway("LWP", type);
    }
};

class Reader {
  public:
    void setBuilder(Builder *b) {
        _builder = b;
    }
    void construct(PersistenceAttribute[], int);
  private:
    Builder *_builder;
};

void Reader::construct(PersistenceAttribute list[], int num) {
  for (int i = 0; i < num; i++)
    if (list[i].type == File)
      _builder->configureFile(list[i].value);
    else if (list[i].type == Queue)
      _builder->configureQueue(list[i].value);
    else if (list[i].type == Pathway)
      _builder->configurePathway(list[i].value);
}

const int NUM_ENTRIES = 6;
PersistenceAttribute input[NUM_ENTRIES] = {
  {File, "state.dat"}, {File, "config.sys"},
  {Queue, "compute"}, {Queue, "log"},
  {Pathway, "authentication"}, {Pathway, "error processing"}
};

int main() {
  UnixBuilder unixBuilder;
  VmsBuilder vmsBuilder;
  Reader reader;

  reader.setBuilder(&unixBuilder);
  reader.construct(input, NUM_ENTRIES);
  cout << unixBuilder.getResult()->getState() << endl;

  reader.setBuilder(&vmsBuilder);
  reader.construct(input, NUM_ENTRIES);
  cout << vmsBuilder.getResult()->getState() << endl;
}
```

### Python

```python
import abc

class Director:
    def __init__(self):
        self._builder = None

    def construct(self, builder):
        self._builder = builder
        self._builder._build_part_a()
        self._builder._build_part_b()
        self._builder._build_part_c()

class Builder(metaclass=abc.ABCMeta):
    def __init__(self):
        self.product = Product()

    @abc.abstractmethod
    def _build_part_a(self):
        pass

    @abc.abstractmethod
    def _build_part_b(self):
        pass

    @abc.abstractmethod
    def _build_part_c(self):
        pass

class ConcreteBuilder(Builder):
    def _build_part_a(self):
        pass

    def _build_part_b(self):
        pass

    def _build_part_c(self):
        pass

class Product:
    pass

def main():
    concrete_builder = ConcreteBuilder()
    director = Director()
    director.construct(concrete_builder)
    product = concrete_builder.product

if __name__ == "__main__":
    main()
```
