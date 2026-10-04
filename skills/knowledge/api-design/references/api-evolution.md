# API Evolution and Versioning

## Breaking vs non-breaking changes

Evolving an API safely starts with knowing what counts as a breaking change.

### Non-breaking changes (safe to ship anytime)

- Adding a new endpoint or resource
- Adding a new optional field to a response
- Adding a new optional query parameter or request field
- Adding a new enum value (if clients handle unknown values gracefully)
- Adding a new HTTP header
- Relaxing a constraint (e.g., making a required field optional)
- Increasing a rate limit

### Breaking changes (require versioning or migration)

- Removing or renaming a field, endpoint, or resource
- Changing a field's type (e.g., string to integer)
- Making an optional field required
- Changing the meaning/behavior of an existing field
- Removing an enum value
- Changing authentication or authorization requirements
- Changing error response format
- Reducing a rate limit

**Rule of thumb:** if an existing, well-behaved client could break without code changes, it is a breaking change.

## Versioning strategies compared

| Strategy | Example | Pros | Cons |
|---|---|---|---|
| **URL path** | `/v1/users`, `/v2/users` | Explicit, easy to route, visible in logs | URL proliferation, clients must update URLs |
| **Accept header** | `Accept: application/vnd.api+json;version=2` | Clean URLs, follows HTTP semantics | Less discoverable, harder to test with a browser |
| **Query parameter** | `/users?version=2` | Simple to add, easy to test | Easy to forget, complicates caching |
| **No versioning** | Additive evolution only | Simplest for clients, single codebase | Requires discipline, eventually limits design freedom |

**Recommendation:** for most APIs, URL path versioning (`/v1/`) gives the best balance of clarity and simplicity. Reserve version bumps for breaking changes. Prefer additive evolution within a version wherever possible.

## Deprecation process

A deprecation is a contract with your consumers. Follow the same steps every time:

1. **Announce:** document the deprecation in your changelog, API docs, and release notes. State what is deprecated, why, and what replaces it.
2. **Sunset header:** include the `Sunset` HTTP header (RFC 8594) with the removal date:
   ```
   Sunset: Mon, 01 Mar 2027 00:00:00 GMT
   ```
3. **Deprecation header:** return the `Deprecation` header (RFC 9745) on deprecated endpoints. Its value is a structured-field date, for example `Deprecation: @1788220800`. The sunset date must not be earlier than the deprecation date.
4. **Migration guide:** provide step-by-step instructions for moving to the replacement.
5. **Monitor usage:** track calls to deprecated endpoints. Reach out to high-volume consumers individually.
6. **Grace period:** maintain the deprecated endpoint for a reasonable period (typically 6-12 months for public APIs).
7. **Remove:** after the sunset date, return `410 Gone` with a message pointing to the replacement.

## Contract testing

Contract tests verify that the API producer and consumers agree on the shape and behavior of the API.

- **Consumer-driven contracts:** each consumer defines the subset of the API it depends on. The producer runs all consumer contracts in CI to catch breaking changes before deployment.
- **Schema validation:** validate responses against an OpenAPI or GraphQL schema in automated tests. Catch unintentional changes to response shape.
- **Provider verification:** the API producer verifies that its implementation satisfies all published contracts on every build.

Contract tests complement integration tests but do not replace them. They catch interface-level regressions early without requiring a running instance of every consumer.

## API documentation

Documentation matters as much as the design. Consumers cannot use what they cannot understand.

**OpenAPI / Swagger:**
- Define the API schema in OpenAPI 3.x format (YAML or JSON). The latest published version is 3.2.x (3.2.1); 3.1 is still widely supported by tooling, so check your tools before choosing
- Generate documentation, client SDKs, and server stubs from the schema
- Keep the schema as the single source of truth. Generate it from code annotations or maintain it manually, but never let docs and implementation diverge
- Include request/response examples for every endpoint

**GraphQL introspection:**
- The schema is itself the documentation
- Use descriptions on types, fields, and arguments
- Tools like GraphiQL and Apollo Studio provide interactive exploration

**Documentation checklist:**
- [ ] Every endpoint has a description, request example, and response example
- [ ] Error responses are documented with codes and meanings
- [ ] Authentication requirements are stated
- [ ] Rate limits are documented
- [ ] Changelog is maintained with every release

## Changelog practices

- Maintain a `CHANGELOG` or dedicated changelog page in your API documentation
- Categorize entries: **Added**, **Changed**, **Deprecated**, **Removed**, **Fixed**
- Include the date and API version for each entry
- For breaking changes, link to the migration guide
- Notify consumers proactively (email, webhook, status page) for breaking or deprecated changes
- Consider a machine-readable changelog format for automated tooling
