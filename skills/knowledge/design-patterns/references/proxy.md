## Overview

The Proxy Pattern is a structural design pattern that interposes a stand-in object between clients and the real target. This intermediary shares the same interface as the target and can layer on additional behavior - such as lazy loading, permission checks, result caching, or request logging - without the client ever knowing it is not talking to the real thing.

## Intent

The Proxy Pattern aims to:
- Supply a stand-in for another object in order to manage access to it
- Postpone the creation of heavyweight objects until the moment they are actually needed
- Layer on cross-cutting concerns like authorization, caching, and auditing transparently
- Keep these auxiliary responsibilities out of the real subject's code

## Problem/Solution

**Problem:** You want to defer expensive initialization, gate access to sensitive resources, record method invocations, or cache return values - all without cluttering the target class. Embedding this logic directly in the subject breaks the Single Responsibility Principle and becomes hard to evolve.

**Solution:** Create a proxy class that implements the same interface as the real subject. The proxy intercepts client requests, applies its extra logic (lazy instantiation, permission verification, logging, caching), and forwards the call to the actual subject. From the client's perspective, nothing changes.

## Structure

```
┌─────────────────────┐
│     Client          │
└──────────┬──────────┘
           │
     ┌─────▼─────────────┐         ┌──────────────────┐
     │  Subject           │◄────────┤ Proxy            │
     │ Interface          │ depends │                  │
     └──────────────────┘          │ - realSubject     │
     ▲                             │ - cachedData      │
     │                             │ - accessControl   │
     │                             └────┬─────────────┘
     │                                  │
     │                                  │delegates to
     │                                  │
     └──────────────────────────────────┘
           RealSubject
```

## When to Use

- **Lazy Initialization:** Hold off on creating resource-heavy objects until the first access
- **Access Control:** Enforce permission checks before allowing operations on the real object
- **Logging & Auditing:** Record every interaction with the real object for tracing or compliance
- **Caching:** Store method results to prevent redundant expensive calls
- **Remote Objects:** Represent services running on other machines behind a local interface
- **Copy-on-Write:** Use a lightweight wrapper that only duplicates the underlying data when a mutation occurs
- **Smart References:** Attach reference counting or automatic cleanup logic to object access

## Implementation (PHP 8.3+)

### Subject Interface

```php
<?php

declare(strict_types=1);

interface DocumentInterface
{
    public function getContent(): string;
    public function save(string $content): void;
    public function delete(): void;
}
```

### Real Subject

```php
<?php

declare(strict_types=1);

readonly class Document implements DocumentInterface
{
    public function __construct(private string $filename)
    {
    }

    public function getContent(): string
    {
        echo "Loading document: {$this->filename}\n";
        return file_get_contents($this->filename);
    }

    public function save(string $content): void
    {
        echo "Saving document: {$this->filename}\n";
        file_put_contents($this->filename, $content);
    }

    public function delete(): void
    {
        echo "Deleting document: {$this->filename}\n";
        unlink($this->filename);
    }
}
```

### Proxy Implementation

```php
<?php

declare(strict_types=1);

readonly class DocumentProxy implements DocumentInterface
{
    private ?DocumentInterface $realDocument = null;
    private ?string $cachedContent = null;
    private bool $isInitialized = false;

    public function __construct(
        private string $filename,
        private string $userRole = 'guest'
    ) {
    }

    private function getRealDocument(): DocumentInterface
    {
        if ($this->realDocument === null) {
            echo "Initializing real document...\n";
            $this->realDocument = new Document($this->filename);
            $this->isInitialized = true;
        }
        return $this->realDocument;
    }

    private function checkAccess(string $action): void
    {
        if ($this->userRole === 'guest' && $action !== 'read') {
            throw new \RuntimeException(
                "Access denied: {$this->userRole} cannot {$action}"
            );
        }
    }

    public function getContent(): string
    {
        $this->checkAccess('read');

        if ($this->cachedContent === null) {
            echo "Cache miss - fetching from document\n";
            $this->cachedContent = $this->getRealDocument()->getContent();
        } else {
            echo "Cache hit\n";
        }

        return $this->cachedContent;
    }

    public function save(string $content): void
    {
        $this->checkAccess('write');
        echo "Proxy logging save operation\n";
        $this->getRealDocument()->save($content);
        $this->cachedContent = $content;
    }

    public function delete(): void
    {
        $this->checkAccess('delete');
        echo "Proxy logging delete operation\n";
        $this->getRealDocument()->delete();
        $this->cachedContent = null;
    }
}
```

### Usage Example

```php
<?php

declare(strict_types=1);

// Create a proxy with lazy initialization
$document = new DocumentProxy('file.txt', 'user');

// First call: initializes real document and caches
echo "First read:\n";
$content = $document->getContent();

// Second call: uses cache
echo "\nSecond read:\n";
$content = $document->getContent();

// Write operation
echo "\nWrite operation:\n";
$document->save("New content");

// Guest access attempt (will throw exception)
try {
    $guest = new DocumentProxy('file.txt', 'guest');
    $guest->save("Unauthorized");
} catch (\RuntimeException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
```

## Real-World Analogies

- **Hotel Key Card (Access Control Proxy):** The card gates entry to rooms without requiring a manager to escort every guest
- **Proxy Voting (Delegation):** A designated representative casts votes on your behalf when you cannot attend
- **Bank Check (Protection Proxy):** A check stands in for actual currency, protecting the account holder from carrying cash
- **Remote Control (Remote Proxy):** Lets you operate a television from across the room without touching its circuitry
- **Library Catalog (Virtual Proxy):** Displays book metadata without physically loading the book itself

## Pros and Cons

### Advantages

- **Separation of Concerns:** Keeps access-control logic outside the real subject
- **Lazy Initialization:** Heavyweight objects are allocated only when first used
- **Client Transparency:** Callers interact through the same interface and need no code changes
- **Extensibility:** Logging, caching, and security can be added without modifying the subject
- **Open/Closed Principle:** New proxy behaviors can be introduced without touching existing classes

### Disadvantages

- **Structural Overhead:** Every proxied class requires a corresponding wrapper object
- **Indirection Cost:** Each method call passes through an extra layer
- **Latency Surprises:** Deferred initialization can cause unexpected pauses on first access
- **Test Complexity:** The proxy layer adds another component to mock or stub in tests

## Relations with Other Patterns

- **Adapter:** Both wrap another object, but Adapter changes the interface while Proxy preserves it
- **Decorator:** Both use composition and delegation; Decorator enriches behavior, Proxy controls access
- **Factory:** Factories can produce proxies, and proxies can lazily instantiate real subjects
- **Strategy:** Can complement each other - the proxy manages access while a strategy encapsulates the algorithm
- **Virtual Proxy vs Lazy Initialization:** A virtual proxy is one specific application of the Proxy pattern focused on deferred creation
- **Protection Proxy vs Access Control:** A protection proxy restricts operations based on caller identity or permissions
- **Remote Proxy:** A specialized variant for distributed systems, typically sitting in front of network services

## Examples in Other Languages

### Java

```java
// Interface for plug-compatibility between wrapper and target
interface SocketInterface {
    String readLine();
    void  writeLine(String str);
    void  dispose();
}

class SocketProxy implements SocketInterface {
    // Wrapper for a remote, expensive, or sensitive target
    private Socket socket;
    private BufferedReader in;
    private PrintWriter out;

    public SocketProxy(String host, int port, boolean wait) {
        try {
            if (wait) {
                // Encapsulate the complexity/overhead of the target
                ServerSocket server = new ServerSocket(port);
                socket = server.accept();
            } else {
                socket = new Socket(host, port);
            }
            in  = new BufferedReader(
                new InputStreamReader(socket.getInputStream()));
            out = new PrintWriter(socket.getOutputStream(), true);
        } catch(IOException e) {
            e.printStackTrace();
        }
    }

    public String readLine() {
        String str = null;
        try {
            str = in.readLine();
        } catch(IOException e) {
            e.printStackTrace();
        }
        return str;
    }

    public void writeLine(String str) {
        // Wrapper delegates to the target
        out.println(str);
    }

    public void dispose() {
        try {
            socket.close();
        } catch(IOException e) {
            e.printStackTrace();
        }
    }
}

public class ProxyDemo {
    public static void main(String[] args) {
        // Client deals with the wrapper
        SocketInterface socket = new SocketProxy(
            "127.0.0.1", 8080,
            args[0].equals("first") ? true : false
        );
        String str;
        boolean skip = true;
        while (true) {
            if (args[0].equals("second") && skip) {
                skip = !skip;
            } else {
                str = socket.readLine();
                System.out.println("Receive - " + str);
                if (str.equals(null)) break;
            }
            System.out.print("Send ---- ");
            str = new Scanner(System.in).nextLine();
            socket.writeLine(str);
            if (str.equals("quit")) break;
        }
        socket.dispose();
    }
}
```

### C++

#### Example 1: Lazy Initialization Proxy

Before (all objects created eagerly):

```cpp
class Image {
    int m_id;
    static int s_next;
  public:
    Image() {
        m_id = s_next++;
        cout << "   $$ ctor: " << m_id << '\n';
    }
    ~Image() {
        cout << "   dtor: " << m_id << '\n';
    }
    void draw() {
        cout << "   drawing image " << m_id << '\n';
    }
};
int Image::s_next = 1;

int main() {
    Image images[5];
    for (int i; true;) {
        cout << "Exit[0], Image[1-5]: ";
        cin >> i;
        if (i == 0) break;
        images[i - 1].draw();
    }
}
```

After (objects created on demand via Proxy):

```cpp
class RealImage {
    int m_id;
  public:
    RealImage(int i) {
        m_id = i;
        cout << "   $$ ctor: " << m_id << '\n';
    }
    ~RealImage() {
        cout << "   dtor: " << m_id << '\n';
    }
    void draw() {
        cout << "   drawing image " << m_id << '\n';
    }
};

class Image {
    RealImage *m_the_real_thing;
    int m_id;
    static int s_next;
  public:
    Image() {
        m_id = s_next++;
        m_the_real_thing = 0;
    }
    ~Image() {
        delete m_the_real_thing;
    }
    void draw() {
        if (!m_the_real_thing)
            m_the_real_thing = new RealImage(m_id);
        m_the_real_thing->draw();
    }
};
int Image::s_next = 1;

int main() {
    Image images[5];
    for (int i; true;) {
        cout << "Exit[0], Image[1-5]: ";
        cin >> i;
        if (i == 0) break;
        images[i - 1].draw();
    }
}
```

#### Example 2: Operator Overloading Proxy

```cpp
#include <iostream>
#include <string>
using namespace std;

class Subject {
  public:
    virtual void execute() = 0;
};

class RealSubject: public Subject {
    string str;
  public:
    RealSubject(string s) { str = s; }
    void execute() { cout << str << '\n'; }
};

class ProxySubject: public Subject {
    string first, second, third;
    RealSubject *ptr;
  public:
    ProxySubject(string s) {
        int num = s.find_first_of(' ');
        first = s.substr(0, num);
        s = s.substr(num + 1);
        num = s.find_first_of(' ');
        second = s.substr(0, num);
        s = s.substr(num + 1);
        num = s.find_first_of(' ');
        third = s.substr(0, num);
        s = s.substr(num + 1);
        ptr = new RealSubject(s);
    }
    ~ProxySubject() { delete ptr; }
    RealSubject *operator->() {
        cout << first << ' ' << second << ' ';
        return ptr;
    }
    void execute() {
        cout << first << ' ' << third << ' ';
        ptr->execute();
    }
};

int main() {
    ProxySubject obj(string("the quick brown fox jumped over the dog"));
    obj->execute();  // the quick fox jumped over the dog
    obj.execute();   // the brown fox jumped over the dog
}
```

### Python

```python
import abc


class Subject(metaclass=abc.ABCMeta):
    """
    Define the common interface for RealSubject and Proxy so that a
    Proxy can be used anywhere a RealSubject is expected.
    """

    @abc.abstractmethod
    def request(self):
        pass


class Proxy(Subject):
    """
    Maintain a reference that lets the proxy access the real subject.
    Provide an interface identical to Subject's.
    """

    def __init__(self, real_subject):
        self._real_subject = real_subject

    def request(self):
        # ...
        self._real_subject.request()
        # ...


class RealSubject(Subject):
    """
    Define the real object that the proxy represents.
    """

    def request(self):
        pass


def main():
    real_subject = RealSubject()
    proxy = Proxy(real_subject)
    proxy.request()


if __name__ == "__main__":
    main()
```
