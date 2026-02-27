## Overview

The Builder pattern is a creational design pattern that addresses the problem of constructing complex objects. Rather than passing numerous parameters to a constructor or creating multiple overloaded constructors, the Builder pattern uses a separate builder object to construct the target object step-by-step, with a fluent interface for clarity and flexibility.

## Intent

- Separate the construction logic of a complex object from its representation
- Allow the same construction process to create different representations
- Avoid "telescoping constructors" (multiple overloaded constructors with different parameter combinations)
- Provide a clear, readable way to build objects with many optional or required parameters

## Problem & Solution

**Problem:**
When creating objects with many parameters, especially optional ones, you face challenges:
- Constructor parameter lists become unwieldy and hard to maintain
- Multiple overloaded constructors create confusion about which to use
- Setting properties after construction violates immutability
- The client code becomes difficult to read with many parameters

**Solution:**
The Builder pattern introduces a builder class that handles the step-by-step construction. The client uses a fluent interface to configure the object, and only when `build()` is called does the final object get created.

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
- An object requires many constructor parameters (3+ optional parameters)
- You need to construct different variations/representations of an object
- The construction process should be independent of the parts that make up the object
- You want immutable objects with clear initialization
- You need validation or complex initialization logic
- Working with fluent/method-chaining APIs

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

**Restaurant Order:** A customer (builder) customizes their meal by choosing:
- Main ingredient (builder method)
- Sauce type (builder method)
- Side dishes (builder method)
- Drinks (builder method)
Then says "prepare order" (build method) and receives the complete meal.

**House Construction:** A contractor (director) builds a house following a construction plan (builder interface) that defines steps like foundation, walls, roof, interior finishing. Different builders can create different house styles following the same plan.

## Pros and Cons

**Advantages:**
- Cleaner, more readable code (fluent interface)
- Flexibility in object creation (different configurations)
- Immutable objects (when combined with readonly classes)
- Single Responsibility (construction logic separated from product)
- Better validation before object creation
- Easy to add new parameters without breaking existing code

**Disadvantages:**
- More classes to maintain (builder + product)
- Overhead for simple objects
- Builder instance needs garbage collection
- Thread safety requires careful implementation

## Relations with Other Patterns

**Composite:** Can use Builder to construct complex composite trees
**Abstract Factory:** Similar intent but different approach; Factory emphasizes families of objects, Builder emphasizes step-by-step construction
**Strategy:** Builder can be parameterized with different strategies for constructing variations
**Prototype:** Both deal with object creation; Builder is more flexible for complex construction

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

*Source: [sourcemaking.com/design_patterns/builder](https://sourcemaking.com/design_patterns/builder)*
