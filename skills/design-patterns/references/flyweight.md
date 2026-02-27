# Flyweight Design Pattern

## Overview

The Flyweight pattern is a structural design pattern that optimizes memory usage by sharing common state across multiple objects. Instead of storing identical data in each object, the pattern separates intrinsic state (shared, immutable) from extrinsic state (unique, mutable) and reuses objects with the same intrinsic state through a factory mechanism.

## Intent

- Minimize memory consumption by sharing common state among multiple objects
- Reduce the number of object instances in memory by reusing objects with identical intrinsic state
- Improve application performance when dealing with large numbers of similar objects
- Support large numbers of fine-grained objects efficiently
- Decouple intrinsic state (shared) from extrinsic state (context-specific)

## Problem & Solution

### Problem

When an application creates thousands or millions of similar objects:

1. **Memory Bloat**: Each object stores complete data, duplicating identical state across instances
2. **Performance Degradation**: Creating and managing millions of objects consumes excessive memory and processing
3. **Garbage Collection Overhead**: The system spends significant time managing lifecycle of numerous objects
4. **Scalability Issues**: Application becomes unresponsive or crashes under load with many objects
5. **State Duplication**: Identical data is unnecessarily replicated across multiple instances

### Solution

Share common immutable state (intrinsic state) among objects while keeping unique state (extrinsic state) separate:

1. Extract intrinsic state that is shared and never changes across objects
2. Keep extrinsic state unique to each context but stored externally
3. Use a Flyweight Factory to create and reuse Flyweight objects with identical intrinsic state
4. Pass extrinsic state to Flyweight methods at runtime rather than storing it

## Structure

```
Client Code
    │
    ├─→ FlyweightFactory
    │       │
    │       ├─→ getFlyweight(intrinsicState)
    │       │
    │       └─→ cache/pool of Flyweights
    │
    └─→ Flyweight (Interface)
            ↑
        ├─ ConcreteFlyweight (intrinsic state)
        │
        └─ operation(extrinsicState)

Extrinsic State (Context): stored elsewhere, passed to operations
Intrinsic State (Shared): stored in Flyweight objects
```

Key participants:
- **Flyweight**: Interface defining operations accepting extrinsic state
- **ConcreteFlyweight**: Stores intrinsic state; reused across contexts
- **FlyweightFactory**: Creates/retrieves and pools Flyweight objects
- **Client**: Maintains extrinsic state and requests Flyweight operations

## When to Use

- **Text Editors**: Character objects sharing font/style properties across documents
- **Game Development**: Rendering thousands of trees, particles, or enemies sharing properties
- **Web Browsers**: DOM elements with shared CSS styles and properties
- **Databases**: Query result sets with repeated column values
- **Caching Systems**: Sharing expensive-to-create objects with identical configurations
- **String Interning**: Sharing identical strings across the application
- **Thread Pools**: Reusing thread objects with the same configuration
- **Connection Pooling**: Sharing database connections with identical properties

## Implementation

### PHP 8.3+ Example: Text Rendering with Flyweight Characters

```php
<?php
declare(strict_types=1);

namespace DesignPatterns\Structural\Flyweight;

// Flyweight interface
interface CharacterFlyweight
{
    public function render(int $fontSize, string $color): string;
}

// Concrete Flyweight - stores intrinsic state only
readonly class Character implements CharacterFlyweight
{
    public function __construct(
        private string $char,
        private string $fontFamily = 'Arial'
    ) {}

    public function render(int $fontSize, string $color): string
    {
        return "<span style=\"font-family: {$this->fontFamily}; font-size: {$fontSize}px; color: {$color};\">"
            . htmlspecialchars($this->char)
            . "</span>";
    }

    public function getChar(): string
    {
        return $this->char;
    }

    public function getFontFamily(): string
    {
        return $this->fontFamily;
    }
}

// Flyweight Factory
class CharacterFactory
{
    /** @var array<string, CharacterFlyweight> */
    private array $characters = [];

    public function getCharacter(string $char, string $fontFamily = 'Arial'): CharacterFlyweight
    {
        $key = $char . '::' . $fontFamily;

        if (!isset($this->characters[$key])) {
            $this->characters[$key] = new Character($char, $fontFamily);
        }

        return $this->characters[$key];
    }

    public function getFlyweightCount(): int
    {
        return count($this->characters);
    }

    /**
     * @return array<string, CharacterFlyweight>
     */
    public function getAllCharacters(): array
    {
        return $this->characters;
    }
}

// Usage
$factory = new CharacterFactory();

$charA1 = $factory->getCharacter('A', 'Arial');
$charA2 = $factory->getCharacter('A', 'Arial');
$charB = $factory->getCharacter('B', 'Arial');

// Same instance reused
assert($charA1 === $charA2);
assert($charA1 !== $charB);

echo $charA1->render(14, 'red');      // renders 'A' in red
echo $charB->render(14, 'blue');     // renders 'B' in blue
echo $factory->getFlyweightCount();  // 2 flyweight objects
```

### Game Rendering: Particle System with Shared Properties

```php
<?php
declare(strict_types=1);

namespace DesignPatterns\Structural\Flyweight;

// Flyweight for particle texture and behavior
readonly class ParticleType
{
    public function __construct(
        private string $texturePath,
        private float $mass,
        private float $friction,
        private string $color
    ) {}

    public function render(float $x, float $y, float $scale): string
    {
        return "Particle({$this->texturePath}) at ({$x}, {$y}) "
            . "scale={$scale} color={$this->color}";
    }

    public function getMass(): float
    {
        return $this->mass;
    }

    public function getFriction(): float
    {
        return $this->friction;
    }
}

// Context class stores extrinsic state (position, velocity, lifetime)
class Particle
{
    private float $x;
    private float $y;
    private float $velocityX;
    private float $velocityY;
    private float $lifespan;
    private float $lifetime;

    public function __construct(
        private ParticleType $type,
        float $x,
        float $y,
        float $velocityX,
        float $velocityY,
        float $lifetime
    ) {
        $this->x = $x;
        $this->y = $y;
        $this->velocityX = $velocityX;
        $this->velocityY = $velocityY;
        $this->lifespan = $lifetime;
        $this->lifetime = $lifetime;
    }

    public function update(float $deltaTime): void
    {
        $this->lifetime -= $deltaTime;
        $this->x += $this->velocityX * $deltaTime;
        $this->y += $this->velocityY * $deltaTime;

        // Apply friction
        $friction = $this->type->getFriction();
        $this->velocityX *= (1.0 - $friction * $deltaTime);
        $this->velocityY *= (1.0 - $friction * $deltaTime);
    }

    public function isAlive(): bool
    {
        return $this->lifetime > 0;
    }

    public function render(): string
    {
        $progress = ($this->lifespan - $this->lifetime) / $this->lifespan;
        $scale = 1.0 - $progress;
        return $this->type->render($this->x, $this->y, $scale);
    }
}

// Particle system using Flyweight objects
class ParticleSystem
{
    private ParticleTypeFactory $typeFactory;
    /** @var array<Particle> */
    private array $particles = [];

    public function __construct()
    {
        $this->typeFactory = new ParticleTypeFactory();
    }

    public function emit(
        string $particleTypeName,
        float $x,
        float $y,
        float $velocityX,
        float $velocityY,
        float $lifetime
    ): void {
        $type = $this->typeFactory->getType($particleTypeName);
        $this->particles[] = new Particle(
            $type,
            $x,
            $y,
            $velocityX,
            $velocityY,
            $lifetime
        );
    }

    public function update(float $deltaTime): void
    {
        foreach ($this->particles as $particle) {
            $particle->update($deltaTime);
        }

        // Remove dead particles
        $this->particles = array_filter(
            $this->particles,
            static fn(Particle $p) => $p->isAlive()
        );
    }

    public function render(): void
    {
        foreach ($this->particles as $particle) {
            echo $particle->render() . "\n";
        }
    }

    public function getParticleCount(): int
    {
        return count($this->particles);
    }

    public function getFlyweightCount(): int
    {
        return $this->typeFactory->getTypeCount();
    }
}

// Factory for ParticleType Flyweights
class ParticleTypeFactory
{
    /** @var array<string, ParticleType> */
    private array $types = [];

    public function getType(string $name): ParticleType
    {
        if (!isset($this->types[$name])) {
            $this->types[$name] = match ($name) {
                'fire' => new ParticleType('fire.png', 0.5, 0.98, '#FF6B00'),
                'smoke' => new ParticleType('smoke.png', 0.2, 0.95, '#AAAAAA'),
                'spark' => new ParticleType('spark.png', 1.0, 0.99, '#FFD700'),
                default => throw new InvalidArgumentException("Unknown particle type: $name"),
            };
        }
        return $this->types[$name];
    }

    public function getTypeCount(): int
    {
        return count($this->types);
    }
}

// Usage
$system = new ParticleSystem();

// Emit thousands of particles
for ($i = 0; $i < 5000; $i++) {
    $system->emit('fire', rand(0, 800), rand(0, 600), rand(-2, 2), rand(-5, -1), 2.0);
}

for ($i = 0; $i < 3000; $i++) {
    $system->emit('smoke', rand(0, 800), rand(0, 600), rand(-1, 1), rand(-3, 0), 3.0);
}

// Only 2 Flyweight objects exist (fire, smoke, spark)
// But 8000 particles are rendered efficiently
echo "Particles: " . $system->getParticleCount() . "\n";  // 8000
echo "Flyweights: " . $system->getFlyweightCount() . "\n"; // 2
```

### String Interning: Shared String Flyweights

```php
<?php
declare(strict_types=1);

namespace DesignPatterns\Structural\Flyweight;

readonly class InternedString
{
    public function __construct(private string $value) {}

    public function getValue(): string
    {
        return $this->value;
    }

    public function length(): int
    {
        return strlen($this->value);
    }

    public function equals(InternedString $other): bool
    {
        return $this->value === $other->value;
    }
}

class StringInternPool
{
    /** @var array<string, InternedString> */
    private array $pool = [];

    public function intern(string $value): InternedString
    {
        if (!isset($this->pool[$value])) {
            $this->pool[$value] = new InternedString($value);
        }
        return $this->pool[$value];
    }

    public function size(): int
    {
        return count($this->pool);
    }

    public function memoryUsed(): int
    {
        return array_sum(array_map(
            static fn(InternedString $s) => strlen($s->getValue()),
            $this->pool
        ));
    }
}

// Usage
$pool = new StringInternPool();

$s1 = $pool->intern('Hello');
$s2 = $pool->intern('World');
$s3 = $pool->intern('Hello');

// s1 and s3 are the same object
assert($s1 === $s3);
assert($s1 !== $s2);

echo "Pool size: " . $pool->size() . "\n";           // 2 unique strings
echo "Memory: " . $pool->memoryUsed() . " bytes\n";  // 10 bytes total
```

## Real-World Analogies

**Text in a Book**: Instead of storing the full alphabet set for each page, a printing press has one set of letter types (Flyweights) and positions them as needed for each page (extrinsic state).

**Lightbulbs in a Stadium**: A stadium doesn't create unique lightbulb objects for each fixture. Instead, it has shared lightbulb types and positions them in different locations with different states (on/off, brightness).

**Classroom Seating**: A school doesn't create new desk objects for every classroom. It has standard desk types (with shared properties) positioned in different locations with different assignments.

**Airline Seat Inventory**: Airlines don't track millions of individual seat objects. They store seat types (Flyweights) and seat assignments separately, combining them to represent booked seats.

**Music Staff Notation**: Sheet music doesn't store unique note objects. It reuses standardized note symbols positioned at different locations on the staff with different durations.

## Pros and Cons

### Advantages
- **Dramatic Memory Reduction**: Thousands of objects can be represented with minimal instances
- **Performance Improvement**: Fewer objects mean faster garbage collection and lower memory pressure
- **Scalability**: Enables applications to handle large volumes of similar objects
- **Shared State Efficiency**: Common immutable data is stored once, not duplicated
- **Transparent Optimization**: Pattern is internal; client code remains unchanged
- **Fine-Grained Object Model**: Supports large numbers of small, lightweight objects

### Disadvantages
- **Complexity**: Separating intrinsic and extrinsic state adds design complexity
- **CPU vs Memory Trade-off**: Recalculating extrinsic state at runtime may use more CPU
- **Thread Safety**: Shared Flyweight objects must be immutable or carefully synchronized
- **Harder to Debug**: Shared state can make bug tracking and testing more difficult
- **Not Always Beneficial**: Overhead of factory and management may exceed memory savings for few objects
- **Immutability Requirement**: Flyweight intrinsic state cannot be modified after creation

## Relations with Other Patterns

- **Factory Pattern**: FlyweightFactory implements Factory to create/retrieve shared objects
- **Object Pool**: Similar concept of reusing objects, but Object Pool is for managing active instances
- **Composite**: Often combined with Flyweight when tree nodes share common properties
- **Singleton**: Both manage object creation but Singleton creates one instance while Flyweight creates many shared ones
- **Iterator**: Used to traverse collections of Flyweight objects efficiently
- **Visitor**: Works well with Flyweights to perform operations on large object networks
- **Facade**: Can use Flyweights internally to optimize subsystem implementations
- **State**: Can combine with Flyweight to manage complex state efficiently

---

*Last updated: February 2026*

## Examples in Other Languages

### Java

#### Before Refactoring

```java
class Gazillion {
    private static int num = 0;
    private int row, col;

    public Gazillion(int maxPerRow) {
        row = num / maxPerRow;
        col = num % maxPerRow;
        num++;
    }

    void report() {
        System.out.print(" " + row + col);
    }
}

public class FlyweightDemo {
    public static final int ROWS = 6, COLS = 10;

    public static void main(String[] args) {
        Gazillion[][] matrix = new Gazillion[ROWS][COLS];
        for (int i = 0; i < ROWS; i++) {
            for (int j = 0; j < COLS; j++) {
                matrix[i][j] = new Gazillion(COLS);
            }
        }
        for (int i = 0; i < ROWS; i++) {
            for (int j = 0; j < COLS; j++) {
                matrix[i][j].report();
            }
            System.out.println();
        }
    }
}
```

#### After Refactoring (with Flyweight Factory)

```java
class Gazillion {
    private int row;

    public Gazillion(int row) {
        this.row = row;
        System.out.println("ctor: " + this.row);
    }

    void report(int col) {
        System.out.print(" " + row + col);
    }
}

class Factory {
    private Gazillion[] pool;

    public Factory(int maxRows) {
        pool = new Gazillion[maxRows];
    }

    public Gazillion getFlyweight(int row) {
        if (pool[row] == null) {
            pool[row] = new Gazillion(row);
        }
        return pool[row];
    }
}

public class FlyweightDemo {
    public static final int ROWS = 6, COLS = 10;

    public static void main(String[] args) {
        Factory theFactory = new Factory(ROWS);
        for (int i = 0; i < ROWS; i++) {
            for (int j = 0; j < COLS; j++)
                theFactory.getFlyweight(i).report(j);
            System.out.println();
        }
    }
}
```

### C++

#### Before Refactoring

```cpp
class Gazillion {
  public:
    Gazillion() {
        m_value_one = s_num / Y;
        m_value_two = s_num % Y;
        ++s_num;
    }
    void report() {
        cout << m_value_one << m_value_two << ' ';
    }
    static int X, Y;
  private:
    int m_value_one;
    int m_value_two;
    static int s_num;
};

int Gazillion::X = 6, Gazillion::Y = 10, Gazillion::s_num = 0;

int main() {
    Gazillion matrix[Gazillion::X][Gazillion::Y];
    for (int i = 0; i < Gazillion::X; ++i) {
        for (int j = 0; j < Gazillion::Y; ++j)
            matrix[i][j].report();
        cout << '\n';
    }
}
```

#### After Refactoring (with Flyweight Factory)

```cpp
class Gazillion {
  public:
    Gazillion(int value_one) {
        m_value_one = value_one;
        cout << "ctor: " << m_value_one << '\n';
    }
    ~Gazillion() {
        cout << m_value_one << ' ';
    }
    void report(int value_two) {
        cout << m_value_one << value_two << ' ';
    }
  private:
    int m_value_one;
};

class Factory {
  public:
    static Gazillion *get_fly(int in) {
        if (!s_pool[in])
            s_pool[in] = new Gazillion(in);
        return s_pool[in];
    }
    static void clean_up() {
        cout << "dtors: ";
        for (int i = 0; i < X; ++i)
            if (s_pool[i])
                delete s_pool[i];
        cout << '\n';
    }
    static int X, Y;
  private:
    static Gazillion *s_pool[];
};

int Factory::X = 6, Factory::Y = 10;
Gazillion *Factory::s_pool[] = {0, 0, 0, 0, 0, 0};

int main() {
    for (int i = 0; i < Factory::X; ++i) {
        for (int j = 0; j < Factory::Y; ++j)
            Factory::get_fly(i)->report(j);
        cout << '\n';
    }
    Factory::clean_up();
}
```

### Python

```python
import abc


class FlyweightFactory:
    """
    Create and manage flyweight objects.
    Ensure that flyweights are shared properly. When a client requests a
    flyweight, the FlyweightFactory object supplies an existing instance
    or creates one, if none exists.
    """

    def __init__(self):
        self._flyweights = {}

    def get_flyweight(self, key):
        try:
            flyweight = self._flyweights[key]
        except KeyError:
            flyweight = ConcreteFlyweight()
            self._flyweights[key] = flyweight
        return flyweight


class Flyweight(metaclass=abc.ABCMeta):
    """
    Declare an interface through which flyweights can receive and act on
    extrinsic state.
    """

    def __init__(self):
        self.intrinsic_state = None

    @abc.abstractmethod
    def operation(self, extrinsic_state):
        pass


class ConcreteFlyweight(Flyweight):
    """
    Implement the Flyweight interface and add storage for intrinsic
    state, if any. A ConcreteFlyweight object must be sharable. Any
    state it stores must be intrinsic; that is, it must be independent
    of the ConcreteFlyweight object's context.
    """

    def operation(self, extrinsic_state):
        pass


def main():
    flyweight_factory = FlyweightFactory()
    concrete_flyweight = flyweight_factory.get_flyweight("key")
    concrete_flyweight.operation(None)


if __name__ == "__main__":
    main()
```
