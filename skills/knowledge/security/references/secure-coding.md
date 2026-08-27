# Secure Coding Practices

Stack-agnostic secure coding patterns for preventing common vulnerabilities. Each section covers what the vulnerability is, how to prevent it, and how to detect it in your code.

## Contents

- [SQL injection prevention](#sql-injection-prevention)
- [XSS (Cross-Site Scripting) prevention](#xss-cross-site-scripting-prevention)
- [CSRF (Cross-Site Request Forgery) prevention](#csrf-cross-site-request-forgery-prevention)
- [Path traversal prevention](#path-traversal-prevention)
- [Deserialization safety](#deserialization-safety)
- [Error handling](#error-handling)
- [Dependency security](#dependency-security)
- [HTTPS everywhere](#https-everywhere)

## SQL injection prevention

**Parameterized queries:** Use parameterized queries (prepared statements) for all database access. The query structure and the data are sent separately, so the database engine never interprets user data as SQL commands.

**ORM safety:** ORMs generally produce parameterized queries, but raw query methods bypass this protection. Audit any use of raw SQL within ORM code for injection risks.

**Stored procedures:** Can reduce injection surface if they use parameterized inputs internally. A stored procedure that concatenates strings is still vulnerable.

**Detection:** Search for string concatenation or interpolation in SQL queries. Look for raw query methods in ORM usage. Static analysis tools can flag most injection patterns.

## XSS (Cross-Site Scripting) prevention

**Output encoding:** Encode all dynamic content before rendering it in HTML. The encoding must match the output context:
- HTML body: HTML-entity encode (`<` becomes `&lt;`)
- HTML attributes: attribute-encode and always quote attribute values
- JavaScript context: JavaScript-encode (or avoid inserting dynamic data into scripts entirely)
- URL parameters: URL-encode
- CSS: CSS-encode (or avoid dynamic CSS values)

**Content Security Policy (CSP):** Deploy a strict CSP that disallows inline scripts and restricts script sources. This adds defense in depth in case encoding is missed somewhere.

**Sanitization:** When you must accept HTML input (rich text editors), use a well-tested sanitization library with an allowlist of permitted tags and attributes. Never write your own HTML sanitizer.

**Detection:** Review all places dynamic data is rendered in templates. Check whether the templating engine auto-escapes by default. Test with payloads like `<script>alert(1)</script>` and event handlers.

## CSRF (Cross-Site Request Forgery) prevention

**Synchronizer token pattern:** Include a unique, unpredictable token in each form and validate it server-side. The token must be tied to the user's session.

**SameSite cookies:** Set `SameSite=Lax` or `SameSite=Strict` on session cookies. This prevents the browser from sending cookies on cross-origin requests.

**Double-submit pattern:** Send the CSRF token in both a cookie and a request header/body. The server verifies they match. Useful for stateless architectures.

**What is not enough:** Checking the `Referer` header alone is unreliable, because it can be stripped or spoofed in some scenarios. Use it as an additional signal, not the sole defense.

**Detection:** Review all state-changing endpoints (POST, PUT, DELETE) and verify they require a CSRF token or use SameSite cookies. Test by submitting requests from a different origin.

## Path traversal prevention

**Never use user input directly in file paths.** An attacker submitting `../../etc/passwd` can escape the intended directory.

**Defenses:**
- Use an allowlist of permitted filenames or a mapping from user-facing identifiers to actual file paths
- Resolve the canonical path and verify it starts with the expected base directory
- Strip or reject input containing `..`, `/`, and `\`
- Run the application with minimal filesystem permissions

**Detection:** Search for file operations that use user input (query parameters, form fields, headers) in file paths. Test with traversal sequences.

## Deserialization safety

**Avoid deserializing untrusted data.** Deserialization can instantiate arbitrary objects and trigger dangerous side effects (remote code execution, file system access).

**If you must deserialize:**
- Use data-only formats (JSON, protocol buffers) rather than language-native serialization
- If using language-native serialization, maintain a strict allowlist of permitted classes
- Validate and sanitize the data after deserialization
- Run deserialization in a sandboxed environment if possible

**Detection:** Search for deserialization calls that accept external input. Review whether the input source is trusted.

## Error handling

**For clients:** Return generic, user-friendly error messages. Never expose stack traces, internal file paths, database queries, or component versions in responses to clients.

**For operations:** Log detailed error information server-side, including stack traces, request context, and relevant state. Use structured logging for automated analysis.

**Fail securely:** When an error occurs in a security-critical path (authorization check, input validation), default to deny. An exception during an access check should result in access denied, not access granted.

**Detection:** Review error handling code. Check whether catch blocks expose details to clients. Trigger errors in security-critical paths and verify the response.

## Dependency security

**Scanning:** Integrate dependency vulnerability scanning into CI/CD pipelines. Most package managers have built-in audit commands. Use additional tools for deeper analysis.

**Version management:**
- Use lock files to pin exact dependency versions for reproducible builds
- Update dependencies regularly and do not let them drift for months
- Monitor security advisories for your direct and transitive dependencies
- Test after updates to catch compatibility issues early

**Minimizing risk:**
- Prefer dependencies with active maintenance and a security response process
- Remove unused dependencies. They add attack surface for no benefit
- Evaluate new dependencies before adding them: check maintenance activity, known vulnerabilities, and the scope of permissions required

**Detection:** Run dependency audit tools regularly. Review the age and maintenance status of critical dependencies. Check whether CI/CD enforces vulnerability scanning.

## HTTPS everywhere

**TLS configuration:**
- Enforce TLS 1.2 as the minimum version; prefer TLS 1.3
- Disable SSL 2.0, SSL 3.0, TLS 1.0, and TLS 1.1
- Use strong cipher suites; disable weak ciphers (RC4, DES, 3DES, export ciphers)
- Enable Perfect Forward Secrecy (ECDHE key exchange)

**Certificate management:**
- Use certificates from a trusted Certificate Authority
- Automate certificate renewal (e.g., Let's Encrypt with auto-renewal)
- Monitor certificate expiration dates
- Use Certificate Transparency logs to detect mis-issued certificates

**HSTS (HTTP Strict Transport Security):**
- Send the `Strict-Transport-Security` header on all HTTPS responses
- Set a long `max-age` (at least 1 year: `max-age=31536000`)
- Include `includeSubDomains` to protect all subdomains
- Consider HSTS preloading for critical domains

**Internal traffic:** Encrypt internal service-to-service communication too. Internal networks are not inherently trusted. Use mutual TLS (mTLS) for service mesh scenarios.

**Detection:** Test TLS configuration with tools like SSL Labs or testssl.sh. Check for mixed content warnings. Verify HSTS headers are present and correctly configured.
