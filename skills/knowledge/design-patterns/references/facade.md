# Facade Pattern

## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem and solution](#problem-and-solution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation (PHP 8.3+)](#implementation-php-83)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Additional considerations](#additional-considerations)
- [Examples in other languages](#examples-in-other-languages)

## Overview

The Facade pattern is a structural design pattern that puts a simplified interface between callers and a complex subsystem. Instead of every consumer having to understand and coordinate several interdependent classes, the facade provides a single entry point that handles coordination internally, so the subsystem's internals can change without affecting outside code.

## Intent

The Facade pattern addresses subsystem complexity by giving you:

- A single entry point that runs multi-step internal workflows on the caller's behalf
- Simple access to functionality that would otherwise need coordination across several objects
- A boundary that keeps internal implementation details out of client code
- Less to learn for developers who consume the subsystem
- A stable contract that absorbs internal restructuring

## Problem and solution

**Problem:** A subsystem consists of many cooperating classes, and every consumer must learn their roles, dependencies, and invocation order. This coupling makes client code verbose, fragile, and expensive to maintain.

**Solution:** Place a facade class in front of the subsystem that offers a small set of high-level operations. The facade delegates to the right subsystem objects and manages their sequencing, so callers use a narrow API and never see the machinery behind it.

## Structure

The Facade pattern involves these participants:

- **Facade:** Provides a simplified interface and knows which subsystem classes handle requests
- **Subsystem Classes:** Implement the actual functionality; unaware of the facade's existence
- **Client:** Uses the facade instead of directly accessing subsystem classes

Key characteristics:
- One-way dependency: Facade depends on subsystems, not vice versa
- Facade is optional (subsystems can still be used directly if needed)
- Often reduces the number of classes the client needs to know about

## When to use

Use the Facade pattern when:

- A subsystem's internal complexity should not leak into calling code
- Multiple consumers need to perform similar multi-step interactions with a subsystem
- You are integrating modern code on top of a legacy system and want a clean boundary
- You need clear layer boundaries, for example between presentation and business logic
- The subsystem's internal structure is likely to change while clients should remain stable
- You want to reduce the number of types that appear in a client's import list

## Implementation (PHP 8.3+)

```php
<?php declare(strict_types=1);

namespace DesignPatterns\Structural\Facade;

// Subsystem classes - complex internal implementation
class Database {
    public function connect(): void {
        echo "Connecting to database...\n";
    }

    public function query(string $sql): array {
        echo "Executing query: $sql\n";
        return [['id' => 1, 'name' => 'Example']];
    }
}

class Cache {
    private array $store = [];

    public function set(string $key, mixed $value): void {
        $this->store[$key] = $value;
        echo "Cache set: $key\n";
    }

    public function get(string $key): mixed {
        return $this->store[$key] ?? null;
    }
}

class Logger {
    public function log(string $message): void {
        echo "[LOG] $message\n";
    }
}

// Facade: Simplified interface to the subsystem
class DataRepository {
    public function __construct(
        private readonly Database $db,
        private readonly Cache $cache,
        private readonly Logger $logger
    ) {}

    public function fetchUser(int $userId): ?array {
        $cacheKey = "user_$userId";

        // Try cache first
        $cached = $this->cache->get($cacheKey);
        if ($cached !== null) {
            $this->logger->log("User $userId retrieved from cache");
            return $cached;
        }

        // Fall back to database
        $this->logger->log("Querying database for user $userId");
        $this->db->connect();
        $results = $this->db->query("SELECT * FROM users WHERE id = $userId");

        if (!empty($results)) {
            $this->cache->set($cacheKey, $results[0]);
            return $results[0];
        }

        return null;
    }

    public function saveUser(int $id, string $name): bool {
        $this->logger->log("Saving user $id: $name");
        $this->db->connect();
        $this->db->query("INSERT INTO users (id, name) VALUES ($id, '$name')");
        $this->cache->set("user_$id", ['id' => $id, 'name' => $name]);
        return true;
    }

    public function clearCache(): void {
        $this->logger->log("Clearing all cache entries");
        // Cache clearing logic
    }
}

// Client code - simple interface, no knowledge of subsystems
$db = new Database();
$cache = new Cache();
$logger = new Logger();

$repository = new DataRepository($db, $cache, $logger);

// Just use the facade - no need to orchestrate subsystems
$user = $repository->fetchUser(1);
$repository->saveUser(2, 'John Doe');
$repository->clearCache();
```

## Real-world analogies

- **Travel Agent**: Instead of booking flights, hotels, car rentals, and excursions separately through different agencies, you ask a travel agent, who does the coordination and gives you a single itinerary.
- **Hospital Reception Desk**: A patient checks in at the front desk, which routes them to the right department, schedules tests, and coordinates with insurance. The patient never contacts each department individually.
- **Smartphone Home Screen**: Tapping an app icon starts a chain of OS services (memory allocation, network access, GPU rendering), but the user sees a single tap.
- **API Gateway**: A single endpoint aggregates calls to multiple backend services, translating between external consumers and internal microservices.

## Pros and cons

**Pros:**
- Client code is shorter and easier to reason about
- Consumers depend on the facade's stable interface, not on internal subsystem classes
- Internal restructuring stays invisible to callers as long as the facade contract holds
- Complex multi-step workflows are encapsulated in one place
- Creates natural architectural boundaries between layers
- Tests can mock one facade interface instead of many subsystem collaborators

**Cons:**
- A facade that tries to cover every subsystem operation can become an oversized god object
- Simplification may hide subsystem features that power users need
- Trivial subsystems gain nothing from an extra abstraction layer
- The facade itself becomes a maintenance bottleneck, since every subsystem change may require a facade update
- If the facade fails, every client that depends on it is affected
- Developers still need subsystem knowledge for edge cases the facade does not cover

## Relations with other patterns

- **Adapter:** Adapter reconciles mismatched interfaces; Facade puts a simpler interface in front of a complex subsystem
- **Decorator:** Decorator augments a single object's behavior; Facade simplifies access to an entire group of objects
- **Strategy:** A facade can offer different strategy implementations for varying subsystem configurations
- **Factory Method:** Facades often use factories internally to instantiate the subsystem objects they coordinate
- **Singleton:** A facade is frequently a singleton when system-wide access to the subsystem is needed
- **Abstract Factory:** Can sit behind a facade to produce families of subsystem objects transparently
- **Command:** Commands can be queued through a facade to schedule subsystem operations
- **Observer:** A facade can expose event subscriptions from the subsystem to external listeners

## Additional considerations

**When Designing Facades:**
- Keep the facade interface simple and focused
- Delegate to subsystem classes, don't duplicate logic
- Consider providing multiple facades for different use cases
- Use dependency injection for subsystem components
- Document the facade's interface
- Allow direct subsystem access if advanced users need it

**Common Pitfalls:**
- Creating a facade that's as complex as the subsystem it hides
- Tightly coupling the facade to client code
- Making the facade responsible for subsystem creation (use factories instead)
- Preventing clients from accessing subsystem classes when needed
- Adding facades to simple systems that don't need them

## Examples in other languages

### Java

```java
// 1. Subsystem
class PointCartesian {
    private double x, y;
    public PointCartesian(double x, double y ) {
        this.x = x;
        this.y = y;
    }

    public void  move( int x, int y ) {
        this.x += x;
        this.y += y;
    }

    public String toString() {
        return "(" + x + "," + y + ")";
    }

    public double getX() {
        return x;
    }

    public double getY() {
        return y;
    }
}

// 1. Subsystem
class PointPolar {
    private double radius, angle;

    public PointPolar(double radius, double angle) {
        this.radius = radius;
        this.angle = angle;
    }

    public void  rotate(int angle) {
        this.angle += angle % 360;
    }

    public String toString() {
        return "[" + radius + "@" + angle + "]";
    }
}

// 1. Desired interface: move(), rotate()
class Point {
    // 2. Design a "wrapper" class
    private PointCartesian pointCartesian;

    public Point(double x, double y) {
        pointCartesian = new PointCartesian(x, y);
    }

    public String toString() {
        return pointCartesian.toString();
    }

    // 4. Wrapper maps
    public void move(int x, int y) {
        pointCartesian.move(x, y);
    }

    public void rotate(int angle, Point o) {
        double x = pointCartesian.getX() - o.pointCartesian.getX();
        double y = pointCartesian.getY() - o.pointCartesian.getY();
        PointPolar pointPolar = new PointPolar(
            Math.sqrt(x * x + y * y),
            Math.atan2(y, x) * 180 / Math.PI
        );
        // 4. Wrapper maps
        pointPolar.rotate(angle);
        System.out.println("  PointPolar is " + pointPolar);
        String str = pointPolar.toString();
        int i = str.indexOf('@');
        double r = Double.parseDouble(str.substring(1, i));
        double a = Double.parseDouble(str.substring(i + 1, str.length() - 1));
        pointCartesian = new PointCartesian(
            r * Math.cos(a * Math.PI / 180) + o.pointCartesian.getX(),
            r * Math.sin(a * Math.PI / 180) + o.pointCartesian.getY()
        );
    }
}

class Line {
    private Point o, e;
    public Line(Point ori, Point end) {
        o = ori;
        e = end;
    }

    public void move(int x, int y) {
        o.move(x, y);
        e.move(x, y);
    }

    public void rotate(int angle) {
        e.rotate(angle, o);
    }

    public String toString() {
        return "origin is " + o + ", end is " + e;
    }
}

public class FacadeDemo {
    public static void main(String[] args) {
        // 3. Client uses the Facade
        Line lineA = new Line(new Point(2, 4), new Point(5, 7));
        lineA.move(-2, -4);
        System.out.println("after move:  " + lineA);
        lineA.rotate(45);
        System.out.println("after rotate: " + lineA);
        Line lineB = new Line(new Point(2, 1), new Point(2.866, 1.5));
        lineB.rotate(30);
        System.out.println("30 degrees to 60 degrees: " + lineB);
    }
}
```

### C++

```cpp
#include <iostream>
using namespace std;

class MisDepartment {
  public:
    void submitNetworkRequest() { _state = 0; }
    bool checkOnStatus() {
        _state++;
        if (_state == Complete) return 1;
        return 0;
    }
  private:
    enum States {
        Received, DenyAllKnowledge, ReferClientToFacilities,
        FacilitiesHasNotSentPaperwork, ElectricianIsNotDone,
        ElectricianDidItWrong, DispatchTechnician, SignedOff,
        DoesNotWork, FixElectriciansWiring, Complete
    };
    int _state;
};

class ElectricianUnion {
  public:
    void submitNetworkRequest() { _state = 0; }
    bool checkOnStatus() {
        _state++;
        if (_state == Complete) return 1;
        return 0;
    }
  private:
    enum States {
        Received, RejectTheForm, SizeTheJob, SmokeAndJokeBreak,
        WaitForAuthorization, DoTheWrongJob, BlameTheEngineer,
        WaitToPunchOut, DoHalfAJob, ComplainToEngineer,
        GetClarification, CompleteTheJob, TurnInThePaperwork, Complete
    };
    int _state;
};

class FacilitiesDepartment {
  public:
    void submitNetworkRequest() { _state = 0; }
    bool checkOnStatus() {
        _state++;
        if (_state == Complete) return 1;
        return 0;
    }
  private:
    enum States {
        Received, AssignToEngineer, EngineerResearches,
        RequestIsNotPossible, EngineerLeavesCompany,
        AssignToNewEngineer, NewEngineerResearches,
        ReassignEngineer, EngineerReturns,
        EngineerResearchesAgain, EngineerFillsOutPaperWork, Complete
    };
    int _state;
};

class FacilitiesFacade {
  public:
    FacilitiesFacade() { _count = 0; }
    void submitNetworkRequest() { _state = 0; }
    bool checkOnStatus() {
        _count++;
        if (_state == Received) {
            _state++;
            _engineer.submitNetworkRequest();
            cout << "submitted to Facilities - "
                 << _count << " phone calls so far" << endl;
        } else if (_state == SubmitToEngineer) {
            if (_engineer.checkOnStatus()) {
                _state++;
                _electrician.submitNetworkRequest();
                cout << "submitted to Electrician - "
                     << _count << " phone calls so far" << endl;
            }
        } else if (_state == SubmitToElectrician) {
            if (_electrician.checkOnStatus()) {
                _state++;
                _technician.submitNetworkRequest();
                cout << "submitted to MIS - "
                     << _count << " phone calls so far" << endl;
            }
        } else if (_state == SubmitToTechnician) {
            if (_technician.checkOnStatus()) return 1;
        }
        return 0;
    }
    int getNumberOfCalls() { return _count; }
  private:
    enum States {
        Received, SubmitToEngineer, SubmitToElectrician, SubmitToTechnician
    };
    int _state;
    int _count;
    FacilitiesDepartment _engineer;
    ElectricianUnion _electrician;
    MisDepartment _technician;
};

int main() {
    FacilitiesFacade facilities;
    facilities.submitNetworkRequest();
    while (!facilities.checkOnStatus())
        ;
    cout << "job completed after only "
         << facilities.getNumberOfCalls() << " phone calls" << endl;
}
```

### Python

```python
class Facade:
    """
    Know which subsystem classes are responsible for a request.
    Delegate client requests to appropriate subsystem objects.
    """

    def __init__(self):
        self._subsystem_1 = Subsystem1()
        self._subsystem_2 = Subsystem2()

    def operation(self):
        self._subsystem_1.operation1()
        self._subsystem_1.operation2()
        self._subsystem_2.operation1()
        self._subsystem_2.operation2()

class Subsystem1:
    """
    Implement subsystem functionality.
    Handle work assigned by the Facade object.
    Have no knowledge of the facade; that is, they keep no references to it.
    """

    def operation1(self):
        pass

    def operation2(self):
        pass

class Subsystem2:
    """
    Implement subsystem functionality.
    Handle work assigned by the Facade object.
    Have no knowledge of the facade; that is, they keep no references to it.
    """

    def operation1(self):
        pass

    def operation2(self):
        pass

def main():
    facade = Facade()
    facade.operation()

if __name__ == "__main__":
    main()
```
