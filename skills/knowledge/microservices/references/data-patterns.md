# Data Patterns for Microservices

## CQRS - Command Query Responsibility Segregation

CQRS splits your application's data model into two distinct sides: a write model optimized for processing commands and enforcing business rules, and a read model optimized for serving queries. The write side validates, applies domain logic, and persists changes. The read side maintains denormalized projections tailored to specific query needs.

### When CQRS Helps

- Read and write workloads have vastly different scaling requirements
- Query patterns demand denormalized views that differ significantly from the write model
- The domain has complex business rules on the write side but simple read requirements
- You need to audit every state change (pairs well with event sourcing)

### When CQRS is Overkill

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

**Python:** Same structure - `PlaceOrderHandler` with `OrderRepository` and `EventBus` dependencies, calling `Order.place()` and publishing `OrderPlaced`. **TypeScript:** Async handler with `await` on repository save and event publish. **Java:** Handler class with repository and event bus fields, publishing `OrderPlaced` after `orders.save()`.

---

## Event Sourcing

Instead of storing only the current state, event sourcing persists every state change as an immutable event. The current state is derived by replaying events from the beginning. This gives you a complete audit trail and the ability to reconstruct state at any point in time.

### Core Concepts

| Concept | Description |
|---|---|
| **Event store** | Append-only log of domain events, partitioned by aggregate ID |
| **Aggregate** | Entity that produces and applies events to maintain its internal state |
| **Projection** | Read-optimized view built by processing a stream of events |
| **Snapshot** | Periodic checkpoint of aggregate state to avoid replaying the entire event history |

### Event Store Mechanics

Events are appended, never modified or deleted. Each event carries:
- A unique event ID
- The aggregate ID it belongs to
- A sequence number for ordering
- The event type and payload
- A timestamp

**Rebuilding state:** Load all events for an aggregate, apply them in sequence, and the result is the current state. For performance, take periodic snapshots and replay only events after the last snapshot.

**Projections** transform the event stream into read-optimized views. A single event stream can feed multiple projections - one for a dashboard, another for search, another for analytics. Projections can be rebuilt from scratch at any time by replaying events.

---

## Saga Pattern

A saga manages a business transaction that spans multiple services. Instead of a single distributed transaction with locks, a saga executes a sequence of local transactions. Each step either succeeds and triggers the next, or fails and triggers compensating actions to undo previous steps.

### Orchestration vs Choreography

| Approach | How It Works | Strengths | Weaknesses |
|---|---|---|---|
| **Orchestration** | A central coordinator directs each step, telling services what to do | Clear flow, easy to reason about, centralized error handling | Single point of coordination, the orchestrator can become complex |
| **Choreography** | Each service listens for events and decides independently what to do next | No central coordinator, services are more autonomous | Harder to track the overall flow, risk of circular dependencies |

### Orchestration Example

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

**Python:** Same orchestrator structure - try charge/reserve/schedule in sequence, catch each failure type and call compensating actions (refund, release) in reverse order. **TypeScript:** Async orchestrator with `await` on each step; catch block checks which steps completed and compensates accordingly. **Java:** Orchestrator with `PaymentService`, `InventoryService`, `ShippingService` fields; catch blocks call `payments.refund()` and `inventory.release()` as needed.

---

## Eventual Consistency Strategies

When services own their own data, cross-service consistency cannot be immediate. Eventual consistency means that all replicas will converge to the same state given enough time and no new updates.

### Practical Approaches

- **Idempotent consumers** - design message handlers so processing the same event twice produces the same result; use event IDs or deduplication keys
- **Causal ordering** - when order matters, use sequence numbers per aggregate or vector clocks to detect and enforce ordering
- **Read-your-writes consistency** - after a user performs a write, route subsequent reads to a source that reflects the write, even if other replicas lag behind
- **Conflict resolution** - for concurrent updates, decide a strategy: last-write-wins, merge, or prompt the user to resolve

---

## Outbox Pattern

The outbox pattern solves the dual-write problem: how to atomically update a database and publish an event. Without it, you risk updating the database but failing to publish the event (or vice versa), leaving the system in an inconsistent state.

### How It Works

1. Within the same database transaction that updates business data, insert a row into an `outbox` table containing the event payload
2. A separate process (relay or poller) reads new rows from the outbox table and publishes them to the message broker
3. After successful publishing, mark the outbox row as processed or delete it

Because the business write and the outbox insert share a single transaction, they either both succeed or both fail. The relay process handles delivery to the external broker independently.

### Implementation Considerations

- **Polling vs CDC** - the relay can poll the outbox table on a timer, or use change data capture (reading the database's transaction log) for lower latency
- **Idempotent consumers** - the relay may publish the same event more than once (at-least-once delivery), so consumers must handle duplicates
- **Ordering** - preserve ordering by processing outbox rows sequentially per aggregate ID
- **Cleanup** - periodically purge old processed outbox rows to prevent table bloat
