## Overview

The Builder pattern is a creational design pattern that separates the construction of a complex object from its representation. Instead of funneling dozens of parameters into a single constructor call or juggling overloaded variants, it hands the assembly work to a dedicated builder that configures the target step by step through clearly named methods.

## Intent

- Decouple how a complex object is assembled from what the finished object looks like
- Enable multiple representations of the same product by reusing identical construction steps
- Eliminate the "telescoping constructor" problem where parameter lists grow unwieldy with every new option
- Provide a fluent, self-documenting API for setting up objects that carry many required and optional attributes

## Problem & Solution

**Problem:**
Objects that require many parameters - particularly optional ones - create persistent difficulties:
- Long positional argument lists are fragile and opaque to callers
- Constructor overloads proliferate rapidly and blur the distinction between variants
- Post-construction mutation to set optional fields breaks immutability guarantees
- Call sites packed with unnamed arguments resist comprehension and review

**Solution:**
The Builder pattern supplies a separate builder class whose named setter methods accumulate configuration incrementally. The final object is produced only when the caller invokes `build()`, which validates all accumulated state and returns a fully initialized, consistent product.

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

## When to Use

Use the Builder pattern when:
- An object has more than a handful of constructor parameters, especially when many are optional
- You need to produce different variants or representations of the same type of object
- The assembly process must remain independent from the components that form the final product
- You want immutable objects but still need a flexible way to set them up
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
 * Modern builder leveraging PHP 8.3+ features
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

## Real-World Analogies

**Deli Sandwich Counter:** You specify bread, filling, toppings, and sauce one selection at a time. The sandwich maker assembles everything according to your choices, and only when you confirm "that's all" does the finished sandwich get wrapped and handed over.

**Custom PC Configuration:** When building a custom workstation, you pick the processor, memory, storage, and graphics card independently. The technician follows the same assembly process regardless of which specific parts you selected, and the machine is not powered on until every component is in place.

## Pros and Cons

**Advantages:**
- Yields readable, self-documenting call sites through fluent method chaining
- Accommodates many object configurations without spawning constructor overloads
- Complements readonly or immutable classes naturally - the product is finalized in one shot
- Concentrates all construction logic in the builder, away from the product class itself
- Runs validation at build time, before the object exists, catching invalid state early
- New optional fields can be added to the builder without breaking existing callers

**Disadvantages:**
- Requires an extra class per product type, increasing the project's class count
- Adds unnecessary ceremony when the product has only a handful of straightforward parameters
- Builder instances occupy memory until they go out of scope or are garbage collected
- Shared or reused builder instances need synchronization in concurrent environments

## Relations with Other Patterns

**Composite:** Builder can orchestrate the assembly of complex composite tree structures
**Abstract Factory:** Both create objects, but Factory coordinates families of products while Builder focuses on incremental, step-by-step construction of a single product
**Strategy:** Different construction strategies can be injected into a builder to produce distinct product variants
**Prototype:** Both address object creation, but Builder offers finer control when construction involves multiple configurable steps

---

**Key Takeaway:** Use the Builder pattern when constructing complex objects with multiple parameters or configuration options. It improves readability, maintainability, and provides a clear separation between construction logic and the product itself.

## Examples in Other Languages

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
