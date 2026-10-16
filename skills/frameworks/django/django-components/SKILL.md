---
name: django-components
description: Django version facts, where to fetch exact API details, and pitfalls that cause real bugs (N+1, signals, async ORM, transactions, migrations, settings, security). Use for any Django model, view, form, admin, auth, cache, or deploy work.
allowed-tools: Read Grep Glob Bash
user-invocable: false
---

# Django components

Django is stable and well documented, so this skill does not copy its API reference. It holds what the docs do not tell you: which versions to target, where to fetch exact signatures, and the opinions that keep a Django codebase healthy. Look up the API in the versioned docs, then apply the pitfalls below.

## Core principles

| Principle | Meaning |
|---|---|
| **Read the installed version first** | Django changes names and defaults between releases. Answer for the version the project runs, not the latest one. |
| **Fetch, do not recall** | Field options, setting names, and method signatures come from the versioned docs. Memory goes stale quickly. |
| **Let the database do the work** | Filter, aggregate, and update in SQL (`F`, `Q`, `annotate`, `update`), not in Python loops. |
| **Prefer explicit over signals** | A direct function call is easier to trace, test, and order than a receiver in another app. |
| **Keep transactions short and visible** | Wrap the unit of work in `atomic`, and push side effects behind `on_commit`. |

## Version matrix

Verified 2026-10-21 against https://docs.djangoproject.com/en/6.1/releases/6.1 and https://www.djangoproject.com/download/. Re-check before quoting dates, they move.

| Series | Python | Mainstream support ends | Extended (security) ends | Notes |
|---|---|---|---|---|
| 6.1 | 3.12, 3.13, 3.14 | April 2027 | December 2027 | Latest feature release. Adds `QuerySet.fetch_mode()` and `@task(**kwargs)`. |
| 6.0 | 3.12, 3.13, 3.14 | August 2026 (ended) | April 2027 | Added CSP support, template partials, built-in tasks framework. `DEFAULT_AUTO_FIELD` defaults to `BigAutoField`. |
| 5.2 LTS | 3.10 to 3.14 (3.14 since 5.2.8) | December 2025 (ended) | April 2028 | Last series that supports Python 3.10 and 3.11. |
| 6.2 LTS | planned | April 2027 release | April 2030 | Next LTS. |

- Django now uses calendar versioning (DEP 20). The releases once planned as 7.0 and 7.1 are named Django 2028 (January 2028) and Django 2029 (January 2029). Deprecation warnings follow, for example `RemovedInDjango2028Warning`.
- Support rule: the latest and previous feature releases get security and data-loss fixes. The one before gets security fixes only. Support for a series ends when the next one ships.
- Pick 5.2 LTS only if the project must stay on Python 3.10 or 3.11. Otherwise target the newest series the dependencies allow, and plan the move to 6.2 LTS.

### Find the installed version first

1. Read the lockfile or pin: `uv.lock`, `poetry.lock`, `Pipfile.lock`, `requirements*.txt`, or `pyproject.toml`.
2. If none exists, run `python -m django --version` in the project environment.
3. Pick the docs ID from the major and minor only (patch versions share docs).
4. For a version question the lockfile cannot answer (current release, end-of-support date), read the download page above or the release notes for the latest series.

## Fetch API details through docs-lookup

Use the `docs-lookup` skill for the fetch procedure. It resolves a library ID, queries the docs with a full question, and handles the case where no docs tool is installed. For Django, use the versioned websites ID instead of the unversioned `/django/django`, so the answer matches the project:

```
/websites/djangoproject_en_<major>_<minor>    e.g. /websites/djangoproject_en_6_1, /websites/djangoproject_en_5_2
```

Without a docs tool, open `https://docs.djangoproject.com/en/<major>.<minor>/` and use the topic guide for concepts and the reference section for exact signatures.

Good queries are whole questions that name the feature and the version behavior you doubt, for example "QuerySet.bulk_update batch_size and signals behavior" or "CSP middleware configuration in Django 6.1".

## Opinions and pitfalls

### Queries and N+1

- Use `select_related()` for forward `ForeignKey` and `OneToOneField` (one JOIN). Use `prefetch_related()` for many-to-many and reverse foreign keys (a second query). Use `Prefetch()` with a filtered queryset when you need a subset.
- Django 6.1 adds fetch modes. `QuerySet.fetch_mode(models.FETCH_PEERS)` loads a missing relation or deferred field for every instance from the same queryset on first access, which turns most N+1 loops into two queries. `FETCH_RAISE` throws `FieldFetchBlocked`, which is useful in hot paths and in tests that must not query. `FETCH_ONE` is the old default. Treat `FETCH_PEERS` as a safety net, not a replacement for an explicit `select_related` where you know the shape.
- Catch N+1 in tests with `assertNumQueries`, not by inspection.
- `exists()` instead of `bool(qs)`, `count()` instead of `len(qs)`, `iterator()` for large reads, `bulk_create` and `bulk_update` for batches.
- `update()` and `bulk_*` skip `save()` and `pre_save`/`post_save`. `QuerySet.delete()` skips the model's `delete()` but still sends `pre_delete` and `post_delete`. Do not rely on signals for bulk paths.
- Use `F()` for in-place updates (`views=F("views") + 1`) to avoid read-modify-write races. Use `select_for_update()` inside `atomic` when you must read, decide, then write.
- Prefer `constraints` (`UniqueConstraint`, `CheckConstraint`) over `unique_together`, and `TextChoices`/`IntegerChoices` over raw tuples. Use `DecimalField` for money.
- Set `related_name` explicitly on relations, and use a lazy reference (`"app.Model"`) to avoid circular imports.
- Start every project with a custom user model (`AUTH_USER_MODEL`), even if it only subclasses `AbstractUser`. Changing it later is painful.

### Signals as a last resort

- Signals hide control flow. A reader of `save()` cannot see what else runs, and order across receivers is not a contract.
- Prefer a service function or an overridden model method called from the view or command. Keep signals for decoupling that is real: a reusable app reacting to a model it does not own.
- If you do use them: connect in `AppConfig.ready()`, put receivers in `signals.py`, accept `**kwargs`, pass `dispatch_uid` when registration may run twice, and never put slow I/O in a receiver. A failing receiver breaks the `save()` that sent it unless you use `send_robust()`.
- Side effects that leave the process (email, webhooks, tasks) belong behind `transaction.on_commit()`, not directly in `post_save`.

### Transactions and on_commit

- `ATOMIC_REQUESTS = True` is a simple default for CRUD apps. It holds a transaction for the whole request, so avoid it where views make slow external calls.
- Use `transaction.atomic()` as a context manager around the smallest unit of work. Nested `atomic` blocks create savepoints. Do not catch `DatabaseError` inside an `atomic` block and carry on, since the transaction is already broken. Catch outside the block.
- Register side effects with `transaction.on_commit(partial(fn, arg))`. If the transaction rolls back, the callback never runs. Outside a transaction it runs immediately.
- Tests: `TestCase` wraps each test in a transaction that is rolled back, so `on_commit` callbacks never run. Use `self.captureOnCommitCallbacks(execute=True)` to run them, or `TransactionTestCase`.

### Async and ORM

- Async views only pay off under ASGI and when the view awaits I/O. A sync view on ASGI runs in a thread and is fine. Do not rewrite working sync code just to be async.
- The ORM has async methods (`aget`, `acreate`, `asave`, `async for`, `acount`), but transactions do not work in async code. Put transactional code in a sync function and call it with `sync_to_async`.
- Calling blocking ORM code directly from async code raises `SynchronousOnlyOperation`. Keep `thread_sensitive=True` (the default) so the call runs on the same thread as other Django code.
- Do not wrap a whole sync library in `sync_to_async` per call inside a loop. Batch the work into one sync function.
- Connections are per thread. Long-running async code that opens many threads can exhaust database connections, so cap concurrency.

### Migrations safety

- Separate schema and data migrations. Never mix `RunPython` and schema operations in one migration, because on databases that run DDL inside a transaction they interact badly and locks last longer.
- Every `RunPython` needs a reverse function. Use `migrations.RunPython.noop` when going back is genuinely a no-op. Use `apps.get_model()`, never import the real model, since the real model may have moved on.
- Zero-downtime order for a column change: add nullable, deploy code that writes both, backfill in batches, then add the constraint, then remove the old column in a later release.
- Review `makemigrations` output and `sqlmigrate` for table rewrites and long locks (adding a column with a default, adding an index on a big table without concurrent creation, changing a column type).
- Commit migrations with the model change. Never edit a migration that has run in a shared environment. Squash only when the old ones are applied everywhere.
- Run `makemigrations --check --dry-run` in CI to catch missing migrations.

### Settings and secrets

- Split settings by environment (`base.py`, `local.py`, `production.py`) or read one file from environment variables. Pick one approach per project and keep it. Never mutate `settings` at runtime.
- `SECRET_KEY`, database credentials, and API keys come from the environment or a secret store. They are never committed. Use `SECRET_KEY_FALLBACKS` to rotate the key without logging everyone out.
- `DEBUG = False` and an explicit `ALLOWED_HOSTS` in production. Never `["*"]`.
- Set `CONN_MAX_AGE` (or use connection pooling where the backend supports it) to avoid a new connection per request.

### Security checklist

- Run `python manage.py check --deploy` against the production settings in CI and before each release. Fix every warning or document why it stays.
- HTTPS everywhere: `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, and HSTS (`SECURE_HSTS_SECONDS`). Start HSTS with a small value and raise it. Behind a proxy, set `SECURE_PROXY_SSL_HEADER` only if the proxy strips that header from clients.
- Keep `CsrfViewMiddleware` on. Use `@csrf_exempt` only on a specific endpoint that authenticates another way (signed webhook). Put `{% csrf_token %}` in every POST form.
- Never build SQL with string formatting. Use the ORM, or parameterized `raw()` and `cursor.execute(sql, params)`. Do not mark user input `|safe` or `mark_safe`.
- Content Security Policy is built in from Django 6.0. Check the docs for the middleware and settings of your series before copying snippets from older articles.
- Serve user uploads from a separate domain or storage, and validate file type and size. Do not trust the client-supplied content type or name.
- Use `Signer` or `TimestampSigner` with a salt for tokens, so one signed value cannot be replayed in another context.

### Tasks framework

- The `django.tasks` framework ships from 6.0. It defines `@task`, `enqueue()`, and results. It does not ship a production worker. Production use needs a backend package that provides a durable queue and a worker process. Check that a backend exists for your infrastructure before building on it.
- Built-in backends are `ImmediateBackend` (the default, runs inline) and `DummyBackend` (stores results, never runs). Use Immediate while developing, Dummy to assert enqueues in tests, and a real backend in production. Neither built-in is for production.
- Task arguments must be JSON-serializable. Pass IDs, not model instances, and reload inside the task.
- Enqueue after commit: `transaction.on_commit(partial(my_task.enqueue, thing_id=thing.pk))`. Otherwise the worker can run before the row is visible.
- Make tasks idempotent, since backends may retry. Django 6.1 lets `@task` pass extra keyword arguments through to the backend's task class, which custom backends can use.
- Celery and similar tools are still fine where you need chains, groups, or a mature scheduler. Do not mix two systems for the same job.

### Testing

- Default to `TestCase` (transaction rollback, fast). Use `TransactionTestCase` only when the test needs real commits or rollbacks, threads, or `on_commit`. Use `SimpleTestCase` when no database is touched.
- Build data with factories (factory_boy, or small helper functions) rather than JSON fixtures. Fixtures rot as models change and hide what each test depends on. Use `setUpTestData` for shared read-only data.
- Use `force_login` instead of the login form, a fast password hasher in test settings, and `--keepdb` locally.
- Assert query counts for list views with `assertNumQueries`. Use `override_settings` and `mail.outbox` rather than patching Django internals.
- Test migrations with `makemigrations --check` in CI. For data migrations, write a test that applies the migration to a prepared state.

### Deployment

- Serve with Gunicorn (WSGI) or Uvicorn/Daphne/Granian (ASGI) behind a reverse proxy. Never use `runserver` in production. Choose ASGI only if you use async views, WebSockets, or streaming. Otherwise WSGI is simpler.
- Static files: `collectstatic --noinput` in the build, then serve from the proxy, a CDN, or WhiteNoise. Use a manifest static files storage for hashed filenames and long cache lifetimes. Uploaded media needs separate storage from static.
- Configure `LOGGING` to write to stdout and send errors to a tracker. Run migrations as a deploy step, not at app startup, and keep them backward compatible with the previous code release.
- Use a shared cache (Redis or Memcached) in production. `LocMemCache` is per process and gives inconsistent results across workers.

## Component index

Purpose only. Fetch details with `docs-lookup`.

- **Models** - define tables as classes: fields, Meta options, constraints, inheritance, managers.
- **QuerySets** - lazy database queries: filtering, lookups, Q and F, aggregation, prefetching.
- **Migrations** - versioned schema and data changes with forward and reverse operations.
- **Database functions** - SQL functions and conditional expressions (Coalesce, Case/When, search).
- **Views** - function-based views and shortcuts (`render`, `redirect`, `get_object_or_404`).
- **Class-based views** - generic CRUD views and mixins for reusable behavior.
- **URL routing** - map paths to views with `path()`, converters, namespaces, and `reverse()`.
- **Middleware** - hooks that wrap every request and response.
- **Request and response** - `HttpRequest`, `HttpResponse`, `JsonResponse`, streaming responses.
- **Templates** - the template language: tags, filters, inheritance, partials, custom tags.
- **Forms** - validation and rendering for user input, including `ModelForm` and formsets.
- **Admin** - generated back-office UI configured through `ModelAdmin`.
- **Authentication** - users, login, permissions, groups, and custom user models.
- **Security** - CSRF, XSS, clickjacking, HTTPS settings, CSP, signing.
- **Sessions** - per-visitor server-side state and its storage backends.
- **Cache** - per-site, per-view, template-fragment, and low-level caching with pluggable backends.
- **Signals** - decoupled notifications such as `post_save` and `request_finished`.
- **Email** - `send_mail`, `EmailMessage`, HTML alternatives, and email backends.
- **Messages** - one-time user notifications stored across redirects.
- **Testing** - test case classes, the test client, `RequestFactory`, and assertions.
- **Files** - file objects, storage API, uploads, and custom storage backends.
- **Static files** - collect and serve CSS, JS, and images, with hashed filenames.
- **Internationalization** - translation, localization, time zones, and message files.
- **Serialization** - convert model data to JSON or XML, fixtures, natural keys.
- **Content types** - generic references to any model, used for generic relations.
- **Validators** - reusable field and model validation functions.
- **Pagination** - split large result sets into pages.
- **Async** - async views, async ORM methods, and the sync/async adapters.
- **Tasks** - background task definition and enqueueing through pluggable backends.
- **Settings** - configuration by name, with environment-specific values.
- **Management commands** - built-in and custom `manage.py` commands, `call_command`.
- **Logging** - Python logging configuration and Django's loggers.
- **Deployment** - WSGI/ASGI entry points, servers, static files, and the deploy checklist.

## Quick checklist

- [ ] Installed Django and Python versions read from the lockfile
- [ ] API details fetched for that exact series, not recalled
- [ ] Related objects loaded with `select_related`, `prefetch_related`, or a fetch mode
- [ ] Side effects behind `transaction.on_commit`, not in signals or inside `atomic`
- [ ] Schema and data migrations separate, with reverse functions
- [ ] Secrets from the environment, `check --deploy` clean
- [ ] Tests use `TestCase` and factories, with query-count assertions on list views

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| Fetching exact Django API details | `docs-lookup` |
| Test strategy beyond Django specifics | `testing` |
| Schema design and indexing | `database-design` |
| Security review beyond Django settings | `security` |
| N+1 diagnosis and profiling | `performance` |
