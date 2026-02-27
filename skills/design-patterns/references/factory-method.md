# Factory Method Pattern

## Overview

The Factory Method is a creational design pattern that provides an interface for creating objects while letting subclasses decide which class to instantiate. Instead of directly instantiating objects using the `new` keyword, you delegate object creation to specialized factory methods.

The pattern encapsulates the instantiation logic, making code more flexible, maintainable, and less coupled to concrete implementations.

## Intent

- Define an interface for creating objects that lets subclasses decide which class to instantiate
- Shift responsibility for object creation from client code to dedicated factory methods
- Eliminate the need for client code to know about concrete classes
- Enable easy addition of new product types without modifying existing code

## Problem & Solution

### The Problem

When you have multiple related classes and the client needs to instantiate them conditionally, direct instantiation leads to:

- **Tight coupling**: Client code depends on concrete classes
- **Code duplication**: Multiple `if/else` or `switch` statements checking types
- **Difficult extension**: Adding new types requires changing client code
- **Violation of Open/Closed Principle**: Open for extension but closed for modification

### The Solution

Create factory methods that encapsulate object creation logic. The client uses these methods instead of directly instantiating classes, delegating the "what type to create" decision to the factory.

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

## When to Use

Use the Factory Method pattern when:

- A class cannot anticipate the type of objects it needs to create
- You want to delegate object creation to subclasses
- Object creation logic is complex or varies by type
- You need to introduce new product types without modifying existing code
- You want to reduce coupling between client code and concrete classes
- Multiple if/else or switch statements are used for type checking

Avoid when:

- Creation logic is simple and you only have one implementation
- Adding factory methods adds unnecessary complexity for the use case

## Implementation

### Basic Example: Database Connection Factory

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

### Advanced Example: Payment Gateway Factory with Readonly Classes

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

## Real-World Analogies

- **Restaurant Kitchen**: A customer orders a dish (interface). The kitchen has different chefs who specialize in different cuisines (concrete creators). Each chef knows how to prepare their specific dishes (factory methods).

- **Vehicle Manufacturing**: A car manufacturer (factory) produces different vehicle types (sedans, SUVs, trucks) without customers needing to know the manufacturing process. Different plants (factories) specialize in different models.

- **Document Generation**: An application needs to generate various document types (PDF, Word, Excel). Each document type has its own generator, selected based on file extension.

## Pros and Cons

### Pros

- **Loose Coupling**: Client code doesn't depend on concrete classes
- **Open/Closed Principle**: Add new types without modifying existing code
- **Single Responsibility**: Separates object creation from usage
- **Code Reusability**: Factory logic can be reused across the application
- **Centralized Configuration**: Manage all creation logic in one place

### Cons

- **Added Complexity**: More classes and interfaces than direct instantiation
- **Overhead**: For simple cases with one implementation, adds unnecessary abstraction
- **Learning Curve**: Developers unfamiliar with the pattern may find it confusing
- **Maintenance**: Requires discipline to properly implement and maintain

## Relations with Other Patterns

- **Singleton Pattern**: Factory methods often create singleton instances
- **Strategy Pattern**: Often used together to encapsulate algorithm selection
- **Template Method**: Factory method is a special case of Template Method
- **Abstract Factory**: Factory Method is the basis for Abstract Factory
- **Dependency Injection**: Modern alternative using DI containers for automatic object creation
- **Builder Pattern**: For complex object construction; Factory Method for simple creation

## Tips for Implementation

1. **Use type hints**: Declare return types and parameter types explicitly
2. **Leverage modern PHP features**: Use match expressions, readonly classes, enums for variants
3. **Implement both Creator and Product interfaces**: Provides flexibility for variations
4. **Consider a simple factory class**: When you only have one factory, use a static factory method or simple factory class
5. **Prefer composition over inheritance**: Use factory interface implementations rather than factory base classes when possible
6. **Document the creation strategy**: Make it clear why different implementations exist

## Examples in Other Languages

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

*Source: [sourcemaking.com/design_patterns/factory_method](https://sourcemaking.com/design_patterns/factory_method)*
