# Per-component pitfalls and defaults

Short notes where the docs describe an option but not the rule of thumb. Each entry says what to do and why.

## Messenger

- **Make handlers idempotent.** Transports deliver at least once, and retries re-run handlers. Use a natural key or a processed-message table, so a repeat is a no-op.
- **Send identifiers, not entities.** A queued entity is stale or detached when the worker reads it. Load it fresh in the handler and handle "not found" (treat as success or throw `UnrecoverableMessageHandlingException`).
- **Add `doctrine_transaction` to the command bus** so a handler's writes commit or roll back together and handlers need no `flush()`. Add `doctrine_ping_connection` and `doctrine_close_connection` for workers that outlive database timeouts.
- **Bound every worker.** Run with `--time-limit` and `--memory-limit` under Supervisor or systemd so a leak ends in a clean restart. Restart on deploy with `messenger:stop-workers`.
- **Configure a failure transport and a retry strategy** (`max_retries`, `delay`, `multiplier`, `jitter`). Inspect with `messenger:failed:show`. Use `RecoverableMessageHandlingException` to force a retry and `UnrecoverableMessageHandlingException` to stop retrying.
- **Separate buses** for commands (one handler, transactional) and events (many handlers, may be async) so middleware fits each.
- **Sign messages** on transports other systems can write to (message signing exists since 7.4).

## Form

- **`CollectionType` needs four parts:** `allow_add`, `allow_delete`, `by_reference: false`, and `addX()` plus `removeX()` methods on the parent model. With only an adder, deleted rows reappear on save.
- **Use validation groups** when one model backs several forms (registration versus profile edit).
- **Keep CSRF on** for every state-changing form. Do not disable it to make an API test pass.
- **Dynamic fields:** use form events (`PRE_SET_DATA`, `PRE_SUBMIT`), not controller conditionals. Put reusable setups in a form type class.
- Prefer a DTO as `data_class` when the form shape differs from the entity.

## Validator

- **Custom validators accept `null` and `''` and return**, so `NotBlank` stays in charge of presence.
- **Class-level constraints** (for example `Callback`) for rules across fields. Property-level for single fields.
- **Cache metadata in production** with a PSR-6 pool. Test custom constraints with `ConstraintValidatorTestCase`.
- Use `payload` to carry severity or error codes to the presentation layer instead of parsing messages.

## Cache

- **Cache Contracts `get()` first**, so concurrent misses compute the value once (stampede protection) and early expiration refreshes hot keys.
- **Tag by dependency** (`products`, `product_42`) and invalidate by tag. This needs a tag-aware pool.
- **Namespaces** isolate contexts. **Chain pools** for an in-process layer in front of Redis.
- Avoid write-heavy use of APCu (fragmentation). Set Redis eviction policy on purpose, since the default may drop live data.
- Prune adapters that do not expire entries themselves.

## Lock and Semaphore

- **Always set a TTL.** A crashed process otherwise holds the lock forever. For long work, call `refresh()` before expiry and abort if `isExpired()`.
- **Pick the store for the topology.** `flock` only works on one filesystem. Redis and Memcached locks vanish on restart. PostgreSQL advisory locks end with the session.
- **Keep clocks synced** (NTP) when expiring locks span servers.
- **One Semaphore instance per resource.** Separate instances for the same key do not coordinate with each other.

## Workflow

- **State machine unless you need parallel places.** It is simpler to reason about and to guard.
- **Use an enum** for places and a `marking_store` property on the entity.
- **Block in guard events with a clear message**, and keep labels and descriptions in metadata, not code.
- **Log and notify through workflow events**, not inside entity methods.
- With several workflows, inject a service locator (`#[AutowireLocator]`) rather than each workflow.

## HttpKernel and events

- Return early responses from `kernel.request`, not `kernel.controller`.
- Do slow work in `kernel.terminate`, which runs after the response is sent.
- Check `isMainRequest()` in listeners. Guard against sub-request recursion.
- Implement `ResetInterface` on any service that keeps per-request state.
- Let exceptions propagate. A `kernel.exception` listener that handles one must set a `Response`.

## Dependency injection and config

- Keep services private. The container can then inline or remove them.
- Inject a locator or tagged iterator, not the container.
- Make heavy, rarely used services lazy.
- Use compiler passes for behavior that spans many services. Refactor on circular dependencies.
- Validate bundle config with the config tree builder, document each option with `info()`, and deprecate before removing.
