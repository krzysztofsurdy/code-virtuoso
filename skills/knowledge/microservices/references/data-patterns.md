# Data Patterns for Microservices

## Contents

- [CQRS - Command Query Responsibility Segregation](#cqrs---command-query-responsibility-segregation)
- [Event Sourcing](#event-sourcing)
- [Saga Pattern](#saga-pattern)
- [Eventual consistency strategies](#eventual-consistency-strategies)
- [Outbox Pattern](#outbox-pattern)

## CQRS - Command Query Responsibility Segregation

CQRS splits an application's data model into two sides: a write model for processing commands and enforcing business rules, and a read model for serving queries. The write side validates, applies domain logic, and persists changes. The read side maintains denormalized projections shaped for specific queries.

### When CQRS helps

- Read and write workloads have very different scaling requirements
- Query patterns need denormalized views that differ a lot from the write model
- The domain has complex business rules on the write side but simple read requirements
- You need to audit every state change (pairs well with event sourcing)

### When CQRS is overkill

- Simple CRUD operations where read and write models are nearly identical
- Small applications with uniform access patterns
- Teams unfamiliar with eventual consistency trade-offs

**PHP:**
```php
declare(strict_types=1);

final class PlaceOrderHandler
{
    public function __construct(
        private OrderRepository $orders,
        private EventBus $events,
    ) {}

    public function handle(PlaceOrderCommand $command): void
    {
        $order = Order::place($command->customerId, $command->items);
        $this->orders->save($order);
        $this->events->publish(new OrderPlaced($order->id(), $order->total()));
    }
}

final class OrderSummaryProjector
{
    public function __construct(private \PDO $readDb) {}

    public function onOrderPlaced(OrderPlaced $event): void
    {
        $stmt = $this->readDb->prepare(
            'INSERT INTO order_summaries (order_id, total, placed_at) VALUES (?, ?, ?)'
        );
        $stmt->execute([$event->orderId, $event->total, $event->occurredAt]);
    }
}
```

**Python:** Same structure: `PlaceOrderHandler` with `OrderRepository` and `EventBus` dependencies, calling `Order.place()` and publishing `OrderPlaced`. **TypeScript:** Async handler with `await` on repository save and event publish. **Java:** Handler class with repository and event bus fields, publishing `OrderPlaced` after `orders.save()`.

---

## Event Sourcing

Event sourcing stores every state change as an immutable event instead of storing only the current state. The current state is derived by replaying events from the beginning. This gives a full audit trail and the ability to reconstruct state at any point in time.

### Core concepts

| Concept | Description |
|---|---|
| **Event store** | Append-only log of domain events, partitioned by aggregate ID |
| **Aggregate** | Entity that produces and applies events to maintain its internal state |
| **Projection** | Read-optimized view built by processing a stream of events |
| **Snapshot** | Periodic checkpoint of aggregate state to avoid replaying the entire event history |

### Event store mechanics

Events are appended, never modified or deleted. Each event carries:
- A unique event ID
- The aggregate ID it belongs to
- A sequence number for ordering
- The event type and payload
- A timestamp

**Rebuilding state:** Load all events for an aggregate and apply them in sequence to get the current state. To speed this up, take periodic snapshots and replay only the events after the last one.

**Projections** transform the event stream into read-optimized views. A single event stream can feed several projections, for example one for a dashboard, one for search, and one for analytics. Projections can be rebuilt from scratch at any time by replaying events.

---

## Saga Pattern

A saga manages a business transaction that spans multiple services. Instead of a single distributed transaction with locks, a saga executes a sequence of local transactions. Each step either succeeds and triggers the next, or fails and triggers compensating actions to undo previous steps.

### Orchestration vs choreography

| Approach | How it works | Strengths | Weaknesses |
|---|---|---|---|
| **Orchestration** | A central coordinator directs each step, telling services what to do | Clear flow, easy to reason about, centralized error handling | Single point of coordination, the orchestrator can become complex |
| **Choreography** | Each service listens for events and decides independently what to do next | No central coordinator, services are more autonomous | Harder to track the overall flow, risk of circular dependencies |

### Orchestration example

**PHP:**
```php
declare(strict_types=1);

final class OrderSagaOrchestrator
{
    public function __construct(
        private PaymentService $payments,
        private InventoryService $inventory,
        private ShippingService $shipping,
    ) {}

    public function execute(OrderPlaced $event): SagaResult
    {
        try {
            $paymentId = $this->payments->charge($event->customerId, $event->total);
            $reservationId = $this->inventory->reserve($event->items);
            $this->shipping->schedule($event->orderId, $event->address);

            return SagaResult::completed($event->orderId);
        } catch (PaymentFailedException) {
            return SagaResult::failed($event->orderId, 'Payment declined');
        } catch (InventoryUnavailableException) {
            $this->payments->refund($paymentId);
            return SagaResult::failed($event->orderId, 'Items unavailable');
        } catch (ShippingException) {
            $this->inventory->release($reservationId);
            $this->payments->refund($paymentId);
            return SagaResult::failed($event->orderId, 'Shipping failed');
        }
    }
}
```

**Python:** Same orchestrator structure: try charge/reserve/schedule in sequence, catch each failure type, and call the compensating actions (refund, release) in reverse order. **TypeScript:** Async orchestrator with `await` on each step; the catch block checks which steps completed and compensates for them. **Java:** Orchestrator with `PaymentService`, `InventoryService`, `ShippingService` fields; catch blocks call `payments.refund()` and `inventory.release()` as needed.

---

## Eventual consistency strategies

When services own their own data, cross-service consistency cannot be immediate. Eventual consistency means all replicas converge to the same state given enough time and no new updates.

### Practical approaches

- **Idempotent consumers**: design message handlers so processing the same event twice gives the same result; use event IDs or deduplication keys
- **Causal ordering**: when order matters, use sequence numbers per aggregate or vector clocks to detect and enforce ordering
- **Read-your-writes consistency**: after a user writes, route their reads to a source that reflects the write, even if other replicas lag behind
- **Conflict resolution**: for concurrent updates, pick a strategy: last-write-wins, merge, or prompt the user to resolve

---

## Outbox Pattern

The outbox pattern solves the dual-write problem: how to update a database and publish an event atomically. Without it, the database update can succeed while the event publish fails (or the reverse), leaving the system inconsistent.

### How it works

1. Within the same database transaction that updates business data, insert a row into an `outbox` table containing the event payload
2. A separate process (relay or poller) reads new rows from the outbox table and publishes them to the message broker
3. After successful publishing, mark the outbox row as processed or delete it

Because the business write and the outbox insert share one transaction, they either both succeed or both fail. The relay process delivers to the external broker separately.

### Implementation considerations

- **Polling vs CDC**: the relay can poll the outbox table on a timer, or use change data capture (reading the database's transaction log) for lower latency
- **Idempotent consumers**: the relay may publish the same event more than once (at-least-once delivery), so consumers must handle duplicates
- **Ordering**: preserve ordering by processing outbox rows sequentially per aggregate ID
- **Cleanup**: purge old processed outbox rows periodically to prevent table bloat
