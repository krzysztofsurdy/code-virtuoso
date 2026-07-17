# Factory Method Pattern

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
- [Tips for implementation](#tips-for-implementation)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Factory Method is a creational design pattern that moves object instantiation into dedicated methods instead of having client code call constructors directly. A base creator defines the contract for producing objects, and concrete subclasses decide which class gets instantiated. Client code never depends on the concrete types it consumes.

## Intent

- Declare a creation interface and let subclasses choose the concrete class to build
- Move instantiation logic out of client code and into dedicated factory methods
- Free callers from referencing or importing concrete product classes
- Allow new product variants without touching existing consumers

## Problem and solution

### The problem

When several related classes must be instantiated conditionally, direct instantiation leads to:

- **Tight coupling**: client code depends on concrete classes
- **Code duplication**: repeated `if/else` or `switch` statements checking types
- **Difficult extension**: adding a type means changing client code
- **Open/Closed violation**: the code cannot be extended without modification

### The solution

Create factory methods that encapsulate object creation. The client calls these methods instead of instantiating classes, and the factory decides which type to create.

## Structure

```
┌─────────────────────────────────────────────────────┐
│                Creator (Interface)                  │
│─────────────────────────────────────────────────────│
│ + createProduct(): Product                          │
│ + businessLogic()                                   │
└─────────────────────────────────────────────────────┘
         △                          △
         │                          │
         │ implements              │ uses
         │                          │
    ┌────┴────────┐          ┌─────┴──────────┐
    │ ConcreteCreatorA│      │ Product        │
    ├──────────────┤      │ (Interface)    │
    │+ createProduct()├──────▶ ├────────────┤
    │  return new │      │+ operation()   │
    │  ProductA() │      └─────▲──────────┘
    └──────────────┘            │
    ┌──────────────┐            │
    │ConcreteCreatorB│      ┌───┴──────────┐
    ├──────────────┤      │ ConcreteProductA│
    │+ createProduct()├──────▶ ├────────────┤
    │  return new │      │+ operation()   │
    │  ProductB() │      └────────────────┘
    └──────────────┘
                            ┌────────────────┐
                            │ ConcreteProductB│
                            ├────────────────┤
                            │+ operation()   │
                            └────────────────┘
```

## When to use

Use Factory Method when:

- The exact type of object needed is not known until runtime
- Subclasses should decide which product class to instantiate
- Construction logic differs meaningfully across product types
- New product variants should be addable without modifying callers
- Client code should program against abstractions, not concrete classes
- Conditional instantiation is scattered across the codebase

Avoid when:

- Creation logic is simple and there is only one implementation
- The factory adds more complexity than the use case needs

## Implementation

### Basic example: database connection factory

```php
<?php declare(strict_types=1);

namespace App\Database;

interface DatabaseConnection
{
    public function connect(): void;
    public function query(string $sql): mixed;
    public function disconnect(): void;
}

final class PostgresConnection implements DatabaseConnection
{
    public function connect(): void
    {
        echo "Connecting to PostgreSQL...\n";
    }

    public function query(string $sql): mixed
    {
        echo "Executing PostgreSQL query: $sql\n";
        return [];
    }

    public function disconnect(): void
    {
        echo "Disconnecting from PostgreSQL\n";
    }
}

final class MySQLConnection implements DatabaseConnection
{
    public function connect(): void
    {
        echo "Connecting to MySQL...\n";
    }

    public function query(string $sql): mixed
    {
        echo "Executing MySQL query: $sql\n";
        return [];
    }

    public function disconnect(): void
    {
        echo "Disconnecting from MySQL\n";
    }
}

interface DatabaseFactory
{
    public function createConnection(): DatabaseConnection;
}

final class PostgresFactory implements DatabaseFactory
{
    public function createConnection(): DatabaseConnection
    {
        return new PostgresConnection();
    }
}

final class MySQLFactory implements DatabaseFactory
{
    public function createConnection(): DatabaseConnection
    {
        return new MySQLConnection();
    }
}

// Usage
$factory = match($_ENV['DB_TYPE']) {
    'postgres' => new PostgresFactory(),
    'mysql' => new MySQLFactory(),
    default => throw new \InvalidArgumentException('Unknown database type'),
};

$connection = $factory->createConnection();
$connection->connect();
$connection->query('SELECT * FROM users');
$connection->disconnect();
```

### Advanced example: payment gateway factory with readonly classes

```php
<?php declare(strict_types=1);

namespace App\Payment;

readonly class PaymentRequest
{
    public function __construct(
        public float $amount,
        public string $currency,
        public string $description,
    ) {}
}

interface PaymentGateway
{
    public function charge(PaymentRequest $request): PaymentResponse;
    public function refund(string $transactionId, float $amount): PaymentResponse;
}

readonly class PaymentResponse
{
    public function __construct(
        public bool $success,
        public string $transactionId,
        public string $message,
    ) {}
}

final class StripeGateway implements PaymentGateway
{
    public function __construct(private readonly string $apiKey) {}

    public function charge(PaymentRequest $request): PaymentResponse
    {
        // Stripe-specific implementation
        return new PaymentResponse(
            success: true,
            transactionId: 'stripe_' . uniqid(),
            message: 'Payment processed via Stripe'
        );
    }

    public function refund(string $transactionId, float $amount): PaymentResponse
    {
        return new PaymentResponse(
            success: true,
            transactionId: $transactionId,
            message: 'Refund processed via Stripe'
        );
    }
}

final class PayPalGateway implements PaymentGateway
{
    public function __construct(private readonly string $clientId) {}

    public function charge(PaymentRequest $request): PaymentResponse
    {
        // PayPal-specific implementation
        return new PaymentResponse(
            success: true,
            transactionId: 'paypal_' . uniqid(),
            message: 'Payment processed via PayPal'
        );
    }

    public function refund(string $transactionId, float $amount): PaymentResponse
    {
        return new PaymentResponse(
            success: true,
            transactionId: $transactionId,
            message: 'Refund processed via PayPal'
        );
    }
}

interface PaymentGatewayFactory
{
    public function createGateway(): PaymentGateway;
}

final class StripeFactory implements PaymentGatewayFactory
{
    public function __construct(private readonly string $apiKey) {}

    public function createGateway(): PaymentGateway
    {
        return new StripeGateway($this->apiKey);
    }
}

final class PayPalFactory implements PaymentGatewayFactory
{
    public function __construct(private readonly string $clientId) {}

    public function createGateway(): PaymentGateway
    {
        return new PayPalGateway($this->clientId);
    }
}

// Simple factory class
final class PaymentGatewayProvider
{
    private static PaymentGateway $gateway;

    public static function initialize(string $provider): void
    {
        $factory = match($provider) {
            'stripe' => new StripeFactory($_ENV['STRIPE_KEY']),
            'paypal' => new PayPalFactory($_ENV['PAYPAL_ID']),
            default => throw new \InvalidArgumentException("Unknown provider: $provider"),
        };

        self::$gateway = $factory->createGateway();
    }

    public static function process(PaymentRequest $request): PaymentResponse
    {
        return self::$gateway->charge($request);
    }
}

// Usage
PaymentGatewayProvider::initialize($_ENV['PAYMENT_PROVIDER']);
$response = PaymentGatewayProvider::process(
    new PaymentRequest(99.99, 'USD', 'Premium Subscription')
);
echo $response->message;
```

## Real-world analogies

- **Staffing agency**: a company tells an agency it needs a software engineer. The agency (factory) picks and sends the right candidate (concrete product), and the company neither runs the recruitment nor knows in advance who will arrive.

- **Vending machine**: you press the "hot beverage" button. The machine's internals (factory method) decide whether to brew coffee, tea, or hot chocolate, and the result comes out of the same slot.

- **Print shop**: a customer submits a document and selects the output format. The production line (factory) routes the job to a laser, inkjet, or large-format printer without the customer knowing which machine handles it.

## Pros and cons

### Pros

- **Loose coupling**: client code programs against interfaces, not concrete implementations
- **Open/Closed Principle**: new product types are added with new factory subclasses, without editing existing code
- **Single Responsibility**: construction logic lives in one place, separate from usage
- **Reuse**: several consumers share one factory without duplicating creation logic
- **Central configuration**: instantiation decisions are consolidated in one location

### Cons

- **Extra classes**: the pattern adds interfaces and classes beyond direct construction
- **Overhead**: with only one product type, the factory layer buys nothing
- **Indirection**: developers unfamiliar with the pattern may find it confusing at first
- **Maintenance**: each new product type needs a matching factory class

## Relations with other patterns

- **Singleton**: factories often manage singleton instances so there is one product per type
- **Strategy**: often paired with Factory Method to select algorithms at runtime
- **Template Method**: Factory Method is a specialization of Template Method focused on creation
- **Abstract Factory**: usually implemented with a Factory Method for each product it creates
- **Dependency Injection**: DI containers serve a similar purpose by wiring objects at the composition root
- **Builder**: Builder handles multi-step construction of complex objects; Factory Method handles simple single-step creation

## Tips for implementation

1. **Use type hints**: declare return types and parameter types explicitly
2. **Use modern PHP features**: match expressions, readonly classes, and enums for variants
3. **Implement both Creator and Product interfaces**: this keeps variations flexible
4. **Start with a simple factory class**: when there is only one factory, a static factory method or simple factory class is enough
5. **Prefer composition over inheritance**: use factory interface implementations rather than factory base classes where possible
6. **Document the creation strategy**: make clear why different implementations exist

## Examples in other languages

### Java

```java
interface ImageReader {
    DecodedImage getDecodeImage();
}

class DecodedImage {
    private String image;

    public DecodedImage(String image) {
        this.image = image;
    }

    @Override
    public String toString() {
        return image + ": is decoded";
    }
}

class GifReader implements ImageReader {
    private DecodedImage decodedImage;

    public GifReader(String image) {
        this.decodedImage = new DecodedImage(image);
    }

    @Override
    public DecodedImage getDecodeImage() {
        return decodedImage;
    }
}

class JpegReader implements ImageReader {
    private DecodedImage decodedImage;

    public JpegReader(String image) {
        decodedImage = new DecodedImage(image);
    }

    @Override
    public DecodedImage getDecodeImage() {
        return decodedImage;
    }
}

public class FactoryMethodDemo {
    public static void main(String[] args) {
        DecodedImage decodedImage;
        ImageReader reader = null;
        String image = args[0];
        String format = image.substring(image.indexOf('.') + 1, (image.length()));
        if (format.equals("gif")) {
            reader = new GifReader(image);
        }
        if (format.equals("jpeg")) {
            reader = new JpegReader(image);
        }
        assert reader != null;
        decodedImage = reader.getDecodeImage();
        System.out.println(decodedImage);
    }
}
```

### C++

**Before: client depends on concrete classes**

```cpp
class Stooge {
  public:
    virtual void slap_stick() = 0;
};

class Larry: public Stooge {
  public:
    void slap_stick() {
        cout << "Larry: poke eyes\n";
    }
};
class Moe: public Stooge {
  public:
    void slap_stick() {
        cout << "Moe: slap head\n";
    }
};
class Curly: public Stooge {
  public:
    void slap_stick() {
        cout << "Curly: suffer abuse\n";
    }
};

int main() {
  vector<Stooge*> roles;
  int choice;
  while (true) {
    cout << "Larry(1) Moe(2) Curly(3) Go(0): ";
    cin >> choice;
    if (choice == 0) break;
    else if (choice == 1) roles.push_back(new Larry);
    else if (choice == 2) roles.push_back(new Moe);
    else roles.push_back(new Curly);
  }
  for (int i = 0; i < roles.size(); i++)
    roles[i]->slap_stick();
  for (int i = 0; i < roles.size(); i++)
    delete roles[i];
}
```

**After: factory method encapsulates creation**

```cpp
class Stooge {
  public:
    static Stooge *make_stooge(int choice);
    virtual void slap_stick() = 0;
};

class Larry: public Stooge {
  public:
    void slap_stick() {
        cout << "Larry: poke eyes\n";
    }
};
class Moe: public Stooge {
  public:
    void slap_stick() {
        cout << "Moe: slap head\n";
    }
};
class Curly: public Stooge {
  public:
    void slap_stick() {
        cout << "Curly: suffer abuse\n";
    }
};

Stooge *Stooge::make_stooge(int choice) {
  if (choice == 1) return new Larry;
  else if (choice == 2) return new Moe;
  else return new Curly;
}

int main() {
  vector<Stooge*> roles;
  int choice;
  while (true) {
    cout << "Larry(1) Moe(2) Curly(3) Go(0): ";
    cin >> choice;
    if (choice == 0) break;
    roles.push_back(Stooge::make_stooge(choice));
  }
  for (int i = 0; i < roles.size(); i++)
    roles[i]->slap_stick();
  for (int i = 0; i < roles.size(); i++)
    delete roles[i];
}
```

### Python

```python
import abc


class Creator(metaclass=abc.ABCMeta):

    def __init__(self):
        self.product = self._factory_method()

    @abc.abstractmethod
    def _factory_method(self):
        pass

    def some_operation(self):
        self.product.interface()


class ConcreteCreator1(Creator):
    def _factory_method(self):
        return ConcreteProduct1()


class ConcreteCreator2(Creator):
    def _factory_method(self):
        return ConcreteProduct2()


class Product(metaclass=abc.ABCMeta):
    @abc.abstractmethod
    def interface(self):
        pass


class ConcreteProduct1(Product):
    def interface(self):
        pass


class ConcreteProduct2(Product):
    def interface(self):
        pass


def main():
    concrete_creator = ConcreteCreator1()
    concrete_creator.product.interface()
    concrete_creator.some_operation()


if __name__ == "__main__":
    main()
```
