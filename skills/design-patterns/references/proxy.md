## Overview

The Proxy Pattern is a structural design pattern that creates an intermediary object (proxy) to control access to another object (subject). The proxy acts as a surrogate or placeholder, intercepting all calls to the real subject and performing additional functionality such as lazy initialization, access control, logging, or caching.

## Intent

The Proxy Pattern aims to:
- Provide a surrogate or placeholder for another object to control access to it
- Defer the initialization of expensive objects until they're actually needed
- Implement lazy initialization, access control, logging, caching, or other cross-cutting concerns
- Separate concerns from the original subject implementation

## Problem/Solution

**Problem:** You need to delay initialization of expensive objects, control access to sensitive resources, log method calls, cache results, or perform other operations transparently. Adding this logic directly to the subject class violates the Single Responsibility Principle and becomes difficult to maintain.

**Solution:** Introduce a proxy object that implements the same interface as the real subject. The proxy receives requests from clients, performs additional operations (lazy loading, access checks, logging, caching), and then delegates to the real subject. Clients work with the proxy transparently.

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

- **Lazy Initialization:** Defer expensive object creation until needed
- **Access Control:** Restrict access to objects based on permissions or conditions
- **Logging & Auditing:** Log all method calls and property accesses to the real object
- **Caching:** Cache method results to avoid redundant expensive operations
- **Remote Objects:** Represent objects on remote servers (RPC, HTTP calls)
- **Copy-on-Write:** Create a lightweight proxy and only copy the real object when modified
- **Smart References:** Add reference counting or cleanup logic

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

- **Hotel Key Card (Access Control Proxy):** A key card controls access to hotel rooms without requiring a manager to open every door
- **Proxy Voting (Access Control):** Someone votes on your behalf if you can't be present
- **Bank Check (Protection Proxy):** A check is a proxy for money that protects the account holder
- **Remote Control (Remote Service Proxy):** Controls a TV without direct access to its internals
- **Library Catalog (Virtual Proxy):** Shows book information without loading the actual book

## Pros and Cons

### Advantages

- **Single Responsibility:** Separates access control logic from the real subject
- **Lazy Initialization:** Create expensive objects only when needed
- **Transparent to Clients:** Proxy implements the same interface as the subject
- **Additional Features:** Add logging, caching, access control without modifying the subject
- **Open/Closed Principle:** Can extend functionality without changing existing code

### Disadvantages

- **Code Complexity:** Introduces additional objects and complexity
- **Performance Overhead:** Extra layer of indirection for every method call
- **Potential Delays:** Lazy initialization can cause unexpected delays on first access
- **Testing Difficulty:** Proxies can make unit testing more complex

## Relations with Other Patterns

- **Adapter:** Similar structure but different intent. Adapter changes an object's interface, while Proxy maintains the same interface
- **Decorator:** Both use composition and delegation. Decorator adds features dynamically; Proxy controls access
- **Factory:** Can be used together. Factory creates proxies, proxies create real subjects
- **Strategy:** Can work together. Proxy controls access; Strategy encapsulates algorithms
- **Virtual Proxy vs Lazy Initialization:** Virtual Proxy is a specific use case of Proxy for lazy initialization
- **Protection Proxy vs Access Control:** Protection Proxy controls access; useful with Authentication/Authorization patterns
- **Remote Proxy:** Specialized proxy for distributed systems, coordinates with RPC frameworks

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
