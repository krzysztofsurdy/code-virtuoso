# Factory Method Pattern

## Overview

The Factory Method is a creational design pattern that delegates object instantiation to specialized methods rather than having client code call constructors directly. A base creator defines the contract for producing objects, while concrete subclasses determine which specific class gets instantiated. This indirection keeps client code decoupled from the concrete types it consumes.

## Intent

- Declare a creation interface and let subclasses choose the concrete class to build
- Move instantiation logic out of client code and into dedicated factory methods
- Free callers from needing to reference or import concrete product classes
- Make it straightforward to introduce new product variants without touching existing consumers

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

- The exact type of object needed cannot be predicted until runtime
- Subclasses should be the ones deciding which product class to instantiate
- Object construction logic differs meaningfully across product types
- New product variants should be addable without modifying callers
- You want client code to program against abstractions, not concrete classes
- Scattered conditional instantiation is creating maintenance headaches

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

- **Staffing Agency**: A company tells an agency it needs a software engineer. The agency (factory) selects and sends the right candidate (concrete product) without the company managing the recruitment process or knowing which individual will arrive.

- **Vending Machine**: You press a button for "hot beverage." The machine's internal mechanism (factory method) decides whether to brew coffee, tea, or hot chocolate based on the selection, dispensing the result through the same slot.

- **Print Shop**: A customer submits a document and selects the output format. The shop's production line (factory) routes the job to the right printer - laser, inkjet, or large-format - without the customer knowing which machine handles it.

## Pros and Cons

### Pros

- **Loose Coupling**: Client code programs against interfaces, not concrete implementations
- **Open/Closed Principle**: New product types slot in by adding new factory subclasses, not editing existing code
- **Single Responsibility**: Construction logic lives in one dedicated place, separate from usage
- **Code Reusability**: Multiple consumers share the same factory without duplicating creation logic
- **Centralized Configuration**: All instantiation decisions are consolidated in one location

### Cons

- **Added Complexity**: The pattern introduces additional interfaces and classes beyond direct construction
- **Overhead**: When only one product type exists, the factory layer adds ceremony with no payoff
- **Learning Curve**: Developers unfamiliar with the pattern may find the indirection confusing at first
- **Maintenance**: Each new product type requires a corresponding factory class

## Relations with Other Patterns

- **Singleton**: Factories often manage singleton instances to ensure one product per type
- **Strategy**: Frequently paired with Factory Method to select algorithms at runtime
- **Template Method**: Factory Method can be seen as a specialized form of Template Method focused on creation
- **Abstract Factory**: Abstract Factory typically uses Factory Methods internally for each product it creates
- **Dependency Injection**: Modern DI containers serve a similar purpose, automating object wiring at the composition root
- **Builder**: Builder handles multi-step construction of complex objects; Factory Method handles straightforward single-step creation

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
