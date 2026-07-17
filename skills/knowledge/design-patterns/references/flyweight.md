# Flyweight Design Pattern

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

Flyweight is a structural design pattern that reduces memory use by moving shared, immutable data out of individual objects into a small set of reusable instances. Each flyweight holds only the intrinsic state common to many contexts. The extrinsic state, the part that varies per use, stays outside and is passed in at call time.

## Intent

- Cut memory usage when an application manages large populations of nearly identical objects
- Pool duplicate state into shared instances managed by a central factory
- Reduce allocation volume and garbage-collection load
- Make it practical to represent millions of fine-grained objects
- Draw a clear boundary between state that can be shared (intrinsic) and state that varies per context (extrinsic)

## Problem and solution

### Problem

When an application creates thousands or millions of similar objects:

1. **Memory bloat**: every object carries its own copy of the data, duplicating identical fields across instances
2. **Allocation cost**: allocating and tracking that many objects drains memory and CPU
3. **Garbage collection pressure**: the runtime spends disproportionate time managing short-lived or redundant objects
4. **Scalability ceiling**: the application slows or crashes as object counts climb
5. **Redundant state**: the same values are replicated across many objects for no benefit

### Solution

Move common, immutable data (intrinsic state) into shared flyweight objects and keep context-specific data (extrinsic state) outside:

1. Identify the intrinsic state that is identical across objects and never changes after creation
2. Store extrinsic state outside the flyweight and pass it in at call time
3. Use a flyweight factory that returns an existing instance when the requested intrinsic state has already been created
4. Supply extrinsic state as method arguments instead of embedding it in the flyweight

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
- **Flyweight**: interface defining operations that accept extrinsic state
- **ConcreteFlyweight**: stores intrinsic state and is reused across contexts
- **FlyweightFactory**: creates, retrieves, and pools Flyweight objects
- **Client**: holds extrinsic state and requests Flyweight operations

## When to use

- **Text editors**: character objects sharing font and style properties across documents
- **Game development**: rendering thousands of trees, particles, or enemies that share properties
- **Web browsers**: DOM elements with shared CSS styles and properties
- **Databases**: query result sets with repeated column values
- **Caching**: sharing expensive-to-create objects that have identical configurations
- **String interning**: sharing identical strings across the application
- **Thread pools**: reusing thread objects with the same configuration
- **Connection pooling**: sharing database connections with identical properties

## Implementation

### PHP 8.3+ example: text rendering with flyweight characters

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

### Game rendering: particle system with shared properties

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

### String interning: shared string flyweights

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

## Real-world analogies

**Movable type printing**: a print shop keeps one physical block for each letter of the alphabet. To compose a page, the typesetter arranges these shared blocks in position. The blocks (intrinsic state) are reused on every page, while the position on the page (extrinsic state) changes each time.

**Emoji keyboard**: a phone stores each emoji graphic once. When the same emoji appears in dozens of messages, the rendering engine references that single asset and places it at different positions. It does not duplicate the image data for every occurrence.

**Color swatches in a paint store**: the store keeps one physical swatch card per color. Customers refer to these shared cards when choosing paint for their own rooms. The swatch is shared; the room and wall it applies to are extrinsic.

## Pros and cons

### Advantages

- **Memory savings**: shared instances replace thousands of near-identical objects
- **Throughput**: fewer allocations mean less garbage collection work and lower memory pressure
- **Scaling**: applications can handle object counts that would otherwise be prohibitive
- **Single source of truth**: common data lives in one place, so there are no inconsistent duplicates
- **Transparent to callers**: clients use flyweights through the same interface as regular objects
- **Fine-grained modeling**: individual characters, pixels, or particles can be objects without exhausting memory

### Disadvantages

- **Design complexity**: deciding what is intrinsic versus extrinsic and managing the split adds overhead
- **CPU trade-off**: extrinsic state must be passed or recomputed at each call
- **Concurrency**: shared flyweights must be immutable or protected by synchronization
- **Harder debugging**: many contexts share one object, so tracing a bug to a specific usage site is trickier
- **Break-even point**: for small object counts, the factory and pooling machinery may cost more than it saves
- **Immutability**: intrinsic state is frozen at creation and cannot be updated later

## Relations with other patterns

- **Factory**: the FlyweightFactory is itself a factory that manages a pool of shared instances
- **Object Pool**: both reuse objects, but Object Pool manages instances that are borrowed and returned, while Flyweight shares immutable data
- **Composite**: trees of composite nodes often benefit from flyweight leaves when many leaves share the same properties
- **Singleton**: Singleton guarantees exactly one instance; Flyweight guarantees one instance per unique intrinsic-state key
- **Iterator**: useful for traversing large collections of flyweight-backed objects
- **Visitor**: pairs well with Flyweight to run operations across large object graphs without modifying shared instances
- **Facade**: a facade may use flyweights internally to keep its subsystem memory-efficient
- **State**: State objects shared across contexts can be implemented as flyweights

---

## Examples in other languages

### Java

#### Before refactoring

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

#### After refactoring (with Flyweight Factory)

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

#### Before refactoring

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

#### After refactoring (with Flyweight Factory)

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
