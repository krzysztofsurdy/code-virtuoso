---
name: symfony-components
description: Opinionated defaults, version facts, and pitfalls for Symfony and its components. Use when writing, reviewing, or upgrading Symfony code, to match the installed version's API and avoid known traps.
allowed-tools: Read Grep Glob Bash
user-invocable: false
---

# Symfony components

Symfony ships a new minor release twice a year and its APIs move. This skill does not restate the API. It tells you which version you are on, where to fetch the exact API for that version, which defaults to prefer when the docs offer several options, and which mistakes recur in real projects.

## Core principles

| Principle | Meaning |
|---|---|
| **Version first** | Read the installed version before suggesting any API. Memory of "Symfony 7" is often stale. |
| **Docs over memory** | Fetch the page for the component and version you need. Do not paste API from recall. |
| **Attributes and autowiring** | Prefer PHP attributes and autowiring. Use YAML or XML only for what attributes cannot express. |
| **Fail loudly, run long** | Code must survive long-running workers: no leaked state, idempotent handlers. |
| **Zero deprecations** | Treat deprecation notices as a ratchet. They are the upgrade path to the next major. |

## Step 1: find the installed version

Read it from `composer.lock`, not from `composer.json` constraints (`^7.2` says little).

```bash
jq -r '.packages[] | select(.name|test("^symfony/(framework-bundle|http-kernel)$")) | .name+" "+.version' composer.lock
```

Also check the `php` constraint in `composer.json` and the CLI version. A project on 6.4 or 7.4 needs different answers than one on 8.1: attribute names moved, features landed, and some APIs were removed in 8.0.

## Version matrix

Verified 2026-10-21 against https://symfony.com/releases.

| Branch | Status | Minimum PHP | Support ends |
|---|---|---|---|
| 8.1 | Current stable, not LTS | 8.4 | January 2027 (bugs and security) |
| 8.2 | In development, planned November 2026 | 8.4 | July 2027 |
| 7.4 | LTS | 8.2 | Bugs November 2028, security November 2029 |
| 6.4 | LTS | 8.1 | Bugs November 2026, security November 2027 |
| 8.0 | Unmaintained | 8.4 | Ended July 2026 |
| 5.4 | Security fixes only | 7.2.5 | February 2029 |

Rules of thumb:
- Minor versions of a major are non-LTS and live about 8 months. LTS versions end in `.4`. By that pattern 8.4 is the next LTS (not confirmed on the releases page).
- Moving from 7.4 to 8.x means moving to PHP 8.4 first. Do not write 8.x-only syntax for a project on 7.4 or 6.4.
- Do not state "PHP 8.3+" or "Symfony 7.x" as the baseline. Use the project's own constraint.

## Step 2: fetch API details through docs-lookup

Use the `docs-lookup` skill for the fetch procedure. If it is not installed, use any docs tool with the same rules: resolve the library, query one concept at a time, and check the version note in the result.

| Source | Context7 ID | Use for |
|---|---|---|
| Current docs site | `/websites/symfony_doc_current` | Latest stable behavior |
| Docs, pinned branch | `/symfony/symfony-docs/__branch__X.Y` | A project on a specific version |
| Docs, 7.4 site | `/websites/symfony_doc_7_4` | Projects on 7.4 |
| Docs, wide index | `/websites/symfony` | Fallback when the others miss a topic |

Pinned branches that existed on 2026-10-21: `6.4`, `7.4`, `8.0`. There was no `8.1` branch, so for 8.1 use the current-docs ID. Source repo docs also live at `/symfony/symfony` (tags `v8.0.0`, `v7.4.3` at that date).

Known traps:
- Results from the current-docs ID can include pages written for 7.4 or older. Look for "introduced in" and "deprecated in" notes and compare them with the installed version.
- A snippet that works on 8.1 may use syntax the project's PHP cannot run (for example `new` chained without parentheses needs PHP 8.4).
- Fall back to `https://symfony.com/doc/X.Y/` for a specific branch when the tool has no match.

Query one component and one concept per call, for example "Messenger retry strategy and failure transport", not "messenger and cache and forms".

## Opinionated defaults

The docs list options. These are the choices to make when the user has not said otherwise.

- **Attributes over YAML/XML** for routes, commands (`#[AsCommand]`), handlers (`#[AsMessageHandler]`), listeners (`#[AsEventListener]`), validation, and serializer groups. Keep YAML for `config/packages` and service parameters.
- **Autowiring and autoconfiguration** for application services. Register a service by hand only when it needs scalar arguments, a specific implementation of an interface, or a non-default tag.
- **Constructor injection**, private services, no `ContainerInterface` in application code. Inject a service locator or `#[AutowireIterator]` when you need a family of services.
- **Workflow component: state machine by default.** Use a full workflow only when an object must be in several places at once. Backed by a PHP enum for places.
- **Cache: use Cache Contracts** (`$cache->get($key, $callback)`) over raw PSR-6. It gives stampede protection and early expiration. Always set a TTL, tag by dependency, and invalidate with tags.
- **Messenger:** handlers idempotent (delivery is at least once), messages carry identifiers not entities, `doctrine_transaction` middleware on the command bus, a failure transport, and worker limits (`--time-limit`, `--memory-limit`).
- **Form `CollectionType`:** needs `allow_add`, `allow_delete`, `by_reference: false`, and both an adder and a remover on the model. Without the remover, removed rows come back.
- **Validator:** put constraints on the model with attributes, use validation groups for context-specific rules, and let custom validators return early on `null` and empty (leave that to `NotBlank` and `NotNull`).
- **Serializer:** expose API output through serializer groups or DTOs, never by serializing Doctrine entities whole. Map entity to DTO explicitly (the ObjectMapper component exists for this).
- **Security:** voters for object-level authorization, `access_control` only for coarse URL rules, `#[IsGranted]` on controllers. Do not scatter `in_array('ROLE_X', $user->getRoles())` checks.
- **Events:** custom event classes, class name as event name, listeners small and stateless. Move slow work from `kernel.response` to `kernel.terminate` or to Messenger.
- **Time:** inject `ClockInterface`, never call `new \DateTimeImmutable()` or `time()` in domain code. Use `MockClock` in tests.
- **Lock:** always give a TTL, refresh it during long work, and choose a store shared by all servers (not `flock` across hosts).
- **Process:** pass the command as an array, not a shell string. Use `fromShellCommandline()` only with trusted, escaped input.
- **Identifiers:** prefer UUIDv7 or ULID over UUIDv4 for primary keys, since time-ordered ids keep indexes compact.
- **Bundles:** extend `AbstractBundle` for new bundles. Give every config option a default and deprecate before removing.

## Cross-cutting pitfalls

- **N+1 queries from Doctrine lazy loading.** A loop that touches a relation issues one query per row. Fetch with a join (`addSelect`), use the profiler's query count, and test with realistic data volume.
- **Long-running worker leaks.** Messenger workers, Swoole, RoadRunner and FrankenPHP workers keep the kernel alive. Stateful services need `ResetInterface` (or the `kernel.reset` tag), the entity manager must be cleared between messages, and no static caches may grow without bound. Restart workers on deploy with `messenger:stop-workers`.
- **Env var processors.** `%env(int:PORT)%` and friends resolve at runtime, but container parameters resolve at compile time. Do not use env values in anything built at compile time (compiler passes, bundle extension logic). Cast types with processors, not in code.
- **Deprecations ratchet.** Run tests with deprecation reporting on and a baseline file, and fail CI when the count rises. Clear deprecations on the last minor of a major before upgrading to the next major.
- **Dev and prod drift.** Debug mode hides container errors that `cache:clear --env=prod` and `lint:container` expose. Run both in CI.
- **Forgetting `isMainRequest()`** in kernel listeners, so sub-requests run the logic twice.
- **Catching `\Throwable` in handlers** and returning, which tells Messenger the message succeeded. Let exceptions propagate or throw `UnrecoverableMessageHandlingException` on purpose.

More per-component notes with reasons: [references/pitfalls.md](references/pitfalls.md). Read it when working on Messenger, Form, Cache, Lock, Workflow, or Validator.

## Component index

Purpose only. Fetch the API through docs-lookup.

**HTTP and runtime:** HttpFoundation (request and response objects), HttpKernel (request to response pipeline and kernel events), Routing (URL matching and generation), Runtime (decoupled bootstrap, long-running servers), PSR-7 Bridge (convert to and from PSR-7), HttpClient (sync and async HTTP calls, retries, mock client), BrowserKit and DomCrawler and CssSelector (simulate a browser and query HTML), Mime and Mailer (build and send email), Asset and AssetMapper (asset URLs, build-free frontend assets).

**Messaging and time:** Messenger (message buses, transports, workers, retries), Scheduler (recurring messages), Webhook and RemoteEvent (receive third-party callbacks), Notifier (SMS, chat, push), Clock (testable time, `DatePoint`), RateLimiter (token bucket and window limits, attribute-driven in 8.1).

**Container and config:** DependencyInjection (container, autowiring, compiler passes), Config (config trees, bundle options), Contracts (framework-neutral interfaces for cache, events, HTTP, translation), EventDispatcher (listeners and subscribers), ExpressionLanguage (safe expression sandbox), Yaml (parse and dump), OptionsResolver (validated option arrays).

**Data and types:** Form (form types, data transformers, collections), Validator (constraints and groups), Serializer (object to array/JSON/XML), ObjectMapper (map one object to another, for DTOs), JsonStreamer (low-memory JSON encode and decode), JsonPath (RFC 9535 queries), PropertyAccess (read and write by path), PropertyInfo and TypeInfo (type and metadata extraction), Uid (UUID and ULID), Intl (locale data), Translation (messages and ICU formats), HtmlSanitizer (safe HTML from user input).

**Security:** Security (authenticators, firewalls, voters, access control, password hashing).

**Concurrency and system:** Cache (PSR-6 and PSR-16 pools, tags, stampede protection), Lock (exclusive locks across processes), Semaphore (limited concurrent access, backends broadened in 8.1), Process (run external commands), Filesystem and Finder (file operations and search), Ldap (directory access).

**Console and tooling:** Console (commands, input, output, helpers), Tui (full-screen terminal UIs, new in 8.1), VarDumper (readable dumps), VarExporter (OPcache-friendly export, lazy objects), PHPUnit Bridge (deprecation reporting and time or DNS mocking in tests).

**Not Symfony components but common:** Twig (templates, Twig Bridge), Doctrine ORM and DBAL (through DoctrineBundle and the Doctrine bridge, with Messenger and Validator integrations).

## Quick checklist

- [ ] Read the installed Symfony and PHP versions from `composer.lock` and the runtime.
- [ ] Fetch the API for that version before writing code.
- [ ] Prefer attributes, autowiring, constructor injection.
- [ ] Check long-running behavior: state reset, idempotency, limits.
- [ ] Run tests with deprecation reporting and fix new notices.

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| Fetching live library docs | `docs-lookup` |
| Moving between Symfony majors or minors | `symfony-upgrade` |
| Updating packages safely | `composer-dependencies` |
| Writing tests with PHPUnit | `testing` |
| Reviewing authorization or input handling | `security` |
| Finding query problems | `performance` |
| Designing layers and boundaries | `clean-architecture` |
