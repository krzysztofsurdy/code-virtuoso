# OWASP Top 10:2025 mapping

Key prevention steps for each category of the OWASP Top 10:2025. This file is a short map, not a copy of the standard. For the full description, example attacks, CWE lists, and testing guidance of a category, fetch the current page with the docs-lookup skill (or Context7 library `/owasp/top10`, or https://top10.owasp.org/2025).

## Contents

- [Changes from 2021](#changes-from-2021)
- [A01 Broken Access Control](#a01-broken-access-control)
- [A02 Security Misconfiguration](#a02-security-misconfiguration)
- [A03 Software Supply Chain Failures](#a03-software-supply-chain-failures)
- [A04 Cryptographic Failures](#a04-cryptographic-failures)
- [A05 Injection](#a05-injection)
- [A06 Insecure Design](#a06-insecure-design)
- [A07 Authentication Failures](#a07-authentication-failures)
- [A08 Software or Data Integrity Failures](#a08-software-or-data-integrity-failures)
- [A09 Security Logging and Alerting Failures](#a09-security-logging-and-alerting-failures)
- [A10 Mishandling of Exceptional Conditions](#a10-mishandling-of-exceptional-conditions)

## Changes from 2021

| 2021 | 2025 |
|---|---|
| A01 Broken Access Control | A01 Broken Access Control (still #1) |
| A02 Cryptographic Failures | A04 Cryptographic Failures |
| A03 Injection | A05 Injection (includes XSS) |
| A04 Insecure Design | A06 Insecure Design |
| A05 Security Misconfiguration | A02 Security Misconfiguration |
| A06 Vulnerable and Outdated Components | A03 Software Supply Chain Failures (broader scope) |
| A07 Identification and Authentication Failures | A07 Authentication Failures |
| A08 Software and Data Integrity Failures | A08 Software or Data Integrity Failures |
| A09 Security Logging and Monitoring Failures | A09 Security Logging and Alerting Failures |
| A10 Server-Side Request Forgery (SSRF) | Folded into A01 |
| (none) | A10 Mishandling of Exceptional Conditions (new) |

## A01 Broken Access Control

- Deny by default and enforce authorization server-side on every request
- Check that the current user may access the specific resource (prevents IDOR)
- Allowlist outbound destinations and URL schemes for server-side fetches, block private and metadata IP ranges (SSRF)
- Protect state-changing requests against CSRF; restrict CORS to known origins
- Log and alert on access control failures

## A02 Security Misconfiguration

- Apply a hardened baseline and validate it automatically in CI/CD
- Remove unused features, ports, sample apps, and default credentials
- Use different credentials per environment
- Send generic errors to clients, set security headers, review cloud permissions

## A03 Software Supply Chain Failures

- Keep an inventory (SBOM) of direct and transitive components, including build tools
- Pin versions with lock files and verify integrity (checksums, signatures, provenance)
- Scan dependencies continuously and patch on a defined schedule
- Secure the build and release pipeline: least-privilege tokens, reviewed changes, no unreviewed deploys
- Vet new dependencies and sources before adding them; remove unused ones

## A04 Cryptographic Failures

- Classify data and encrypt sensitive data in transit (TLS 1.2+, prefer 1.3) and at rest
- Use current algorithms and vetted libraries; never write your own
- Hash passwords with Argon2id, bcrypt, or scrypt
- Generate keys and tokens with a cryptographically secure generator; manage and rotate keys

## A05 Injection

- Use parameterized queries or prepared statements for all interpreters
- Validate input with allowlists and encode output for its context (HTML, URL, JavaScript)
- Avoid building OS commands, LDAP, XPath, or template strings from user input
- Prefer framework auto-escaping and a strict Content-Security-Policy

## A06 Insecure Design

- Threat model during design and write abuse cases next to use cases
- Reuse vetted secure design patterns and reference architectures
- Limit resource use by design (rate limits, quotas); separate trust boundaries
- Add unit and integration tests for the threat model's critical flows

## A07 Authentication Failures

- Support MFA and passkeys; rate limit and throttle login attempts
- Check new passwords against breached lists; no composition rules or forced rotation
- Regenerate session IDs on login and invalidate them on logout and password change
- Do not ship default credentials; return the same response for unknown users and wrong passwords

## A08 Software or Data Integrity Failures

- Accept code, updates, and serialized data only from verified, signed sources
- Do not deserialize untrusted data with native serializers; use data-only formats and type allowlists
- Protect CI/CD with review, separation of duties, and signed artifacts
- Verify the integrity of data that drives critical decisions (HMAC, signatures)

## A09 Security Logging and Alerting Failures

- Log logins, failures, access denials, and input validation failures with enough context
- Send logs to a central, tamper-resistant store and keep them out of reach of the app
- Alert on suspicious patterns and rehearse the response (incident plan, playbooks)
- Never log secrets, tokens, or unnecessary personal data

## A10 Mishandling of Exceptional Conditions

- Catch and handle errors where they occur, including resource exhaustion and missing input
- Fail closed: on error in a security check, deny; roll back partial transactions
- Never leak stack traces, paths, or internal state in error responses
- Add a global error handler as a backstop, with rate limits and monitoring for repeated faults
- Test error paths, not only the happy path
