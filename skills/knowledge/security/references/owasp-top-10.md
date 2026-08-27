# OWASP Top 10 (2021)

The OWASP Top 10 is the most widely recognized standard for web application security risks. This reference covers each vulnerability with concrete defenses.

## Contents

- [A01: Broken Access Control](#a01-broken-access-control)
- [A02: Cryptographic Failures](#a02-cryptographic-failures)
- [A03: Injection](#a03-injection)
- [A04: Insecure Design](#a04-insecure-design)
- [A05: Security Misconfiguration](#a05-security-misconfiguration)
- [A06: Vulnerable and Outdated Components](#a06-vulnerable-and-outdated-components)
- [A07: Identification and Authentication Failures](#a07-identification-and-authentication-failures)
- [A08: Software and Data Integrity Failures](#a08-software-and-data-integrity-failures)
- [A09: Security Logging and Monitoring Failures](#a09-security-logging-and-monitoring-failures)
- [A10: Server-Side Request Forgery (SSRF)](#a10-server-side-request-forgery-ssrf)

## A01: Broken Access Control

**What it is:** Users can act outside their intended permissions: viewing other users' data, modifying records they should not access, or elevating privileges.

**How it happens:**
- Missing authorization checks on API endpoints or server-side functions
- Insecure Direct Object References (IDOR): changing an ID in a URL to access another user's data
- CORS misconfiguration allowing unauthorized origins
- Metadata manipulation (tampering with JWT, cookies, or hidden fields)
- Accessing admin pages as an unprivileged user

**Primary defenses:**
- Deny by default: require explicit grants for every resource
- Enforce authorization server-side on every request, not just in the UI
- Validate that the current user owns or has access to the specific resource
- Disable directory listing on web servers
- Log and alert on access control failures

**Detection:** Review every endpoint and verify it checks authorization. Test by accessing resources with different user roles and with manipulated IDs.

## A02: Cryptographic Failures

**What it is:** Sensitive data exposed due to weak, missing, or misused cryptography. Formerly called "Sensitive Data Exposure."

**How it happens:**
- Transmitting data in clear text (HTTP, FTP, SMTP without TLS)
- Using deprecated algorithms (MD5, SHA-1, DES, RC4)
- Using default or weak encryption keys
- Not enforcing TLS (missing HSTS, mixed content)
- Storing passwords with reversible encryption instead of hashing

**Primary defenses:**
- Classify data by sensitivity; apply appropriate protection to each tier
- Encrypt all data in transit with TLS 1.2+
- Encrypt sensitive data at rest with AES-256 or equivalent
- Use bcrypt, scrypt, or Argon2id for password hashing
- Generate keys with cryptographically secure random number generators
- Disable caching for responses containing sensitive data

**Detection:** Identify all places sensitive data is stored, transmitted, or processed. Check for plain-text storage, weak algorithms, and missing TLS.

## A03: Injection

**What it is:** Untrusted data is sent to an interpreter as part of a command or query, allowing attackers to execute unintended commands or access unauthorized data.

**How it happens:**
- String concatenation in SQL queries with user input
- User input embedded in OS commands, LDAP queries, or XPath expressions
- Template injection in server-side rendering engines
- NoSQL query injection through JSON or other structured input

**Primary defenses:**
- Use parameterized queries or prepared statements for all database access
- Use ORM query builders; avoid raw query methods with user input
- Apply input validation with allowlists (not denylist)
- Escape special characters for the specific interpreter context
- Use LIMIT and other controls to minimize data exposure if injection occurs

**Detection:** Search for string concatenation in queries. Audit all points where user input reaches an interpreter. Use static analysis tools that detect injection patterns.

## A04: Insecure Design

**What it is:** Missing or ineffective security controls resulting from flawed design. These are architectural weaknesses, not implementation bugs.

**How it happens:**
- No threat modeling during design phase
- Missing rate limiting on sensitive operations (password reset, account creation)
- Business logic flaws (e.g., negative quantities in orders)
- No separation between trust boundaries
- Assuming clients will follow the expected workflow

**Primary defenses:**
- Perform threat modeling during design (STRIDE, attack trees)
- Establish secure design patterns and use them consistently
- Write abuse cases alongside use cases
- Limit resource consumption by design (rate limits, quotas)
- Implement defense in depth: multiple layers of controls

**Detection:** Review architectural decisions and design documents. Ask "what if an attacker does X?" for every user-facing flow. Conduct design reviews with security-focused team members.

## A05: Security Misconfiguration

**What it is:** Insecure default configurations, incomplete configurations, open cloud storage, misconfigured HTTP headers, or verbose error messages containing sensitive information.

**How it happens:**
- Default credentials left unchanged
- Unnecessary features, ports, or services enabled
- Error handling revealing stack traces or internal details to users
- Missing security headers
- Cloud storage permissions set to public
- Outdated or unpatched systems

**Primary defenses:**
- Establish a hardened baseline configuration and apply it consistently
- Remove or disable unused features, frameworks, and endpoints
- Automate configuration validation in CI/CD pipelines
- Use different credentials for each environment
- Review cloud permissions regularly (principle of least privilege)
- Send generic error messages to clients; log detailed errors server-side

**Detection:** Automated scanners can detect many misconfigurations. Regularly review configurations against hardened baselines. Audit cloud resource permissions.

## A06: Vulnerable and Outdated Components

**What it is:** Using libraries, frameworks, or other software components with known vulnerabilities.

**How it happens:**
- Not tracking dependency versions
- Using end-of-life or unmaintained components
- Not scanning for known vulnerabilities
- Slow or absent patching process
- Not testing compatibility after updates, leading teams to avoid upgrading

**Primary defenses:**
- Maintain an inventory of all components and their versions
- Monitor vulnerability databases (CVE, NVD, GitHub Advisories)
- Use automated dependency scanning tools in CI/CD
- Subscribe to security advisories for critical dependencies
- Remove unused dependencies
- Prefer components with active maintenance and security track records

**Detection:** Run dependency audit tools regularly. Check component versions against known vulnerability databases. Review the age and maintenance status of dependencies.

## A07: Identification and Authentication Failures

**What it is:** Weaknesses in authentication mechanisms that allow attackers to compromise passwords, session tokens, or exploit implementation flaws to assume other users' identities.

**How it happens:**
- Permitting brute force attacks (no rate limiting or lockout)
- Allowing weak or common passwords
- Using plain text or weakly hashed passwords
- Missing or broken multi-factor authentication
- Exposing session IDs in URLs
- Not invalidating sessions after logout or password change
- Not rotating session IDs after login

**Primary defenses:**
- Implement multi-factor authentication
- Enforce password complexity requirements and check against breached password lists
- Rate limit and progressively delay failed login attempts
- Use secure session management (see Authentication patterns in SKILL.md)
- Invalidate sessions on logout, password change, and after inactivity
- Generate high-entropy session IDs with a cryptographically secure generator

**Detection:** Test login flows for brute force resilience. Verify session handling (fixation, expiration, invalidation). Check password storage mechanism.

## A08: Software and Data Integrity Failures

**What it is:** Code and infrastructure that does not verify integrity, which lets attackers inject malicious updates, tamper with data, or compromise CI/CD pipelines.

**How it happens:**
- Using libraries from untrusted sources without integrity verification
- Auto-update mechanisms without signed updates
- Insecure CI/CD pipelines that allow unauthorized code deployment
- Insecure deserialization of untrusted data
- Unsigned or unverified data used in critical decisions

**Primary defenses:**
- Verify digital signatures on software updates and dependencies
- Use package managers with integrity checking (lock files, checksums)
- Secure CI/CD pipelines: require code review, limit deployment permissions
- Avoid deserializing untrusted data; if unavoidable, use allowlists for permitted types
- Implement integrity checks on critical data (checksums, HMAC)

**Detection:** Review CI/CD pipeline security. Check whether dependencies are fetched with integrity verification. Audit deserialization points.

## A09: Security Logging and Monitoring Failures

**What it is:** Insufficient logging, monitoring, and alerting that lets attackers operate undetected, maintain persistence, and pivot to other systems.

**How it happens:**
- Not logging security-relevant events (logins, failed logins, access denials)
- Logs not monitored or reviewed
- No alerting on suspicious patterns
- Logs stored only locally and lost when systems are compromised
- Sensitive data included in logs (creating a secondary exposure surface)

**Primary defenses:**
- Log authentication events (successes and failures), authorization failures, and input validation failures
- Use a structured log format for automated analysis
- Send logs to a centralized, append-only log management system
- Set up alerts for suspicious patterns (brute force, unusual access times, privilege escalation attempts)
- Protect logs from tampering and unauthorized access
- Do not log sensitive data (passwords, tokens, PII)

**Detection:** Review what events are logged. Test whether failed logins and access denials generate log entries. Verify that alerts are configured and functioning.

## A10: Server-Side Request Forgery (SSRF)

**What it is:** An attacker makes the server send requests to unintended destinations, such as internal services, cloud metadata endpoints, or other protected resources.

**How it happens:**
- Application fetches URLs provided by users without validation
- Accessing cloud instance metadata (169.254.169.254) through SSRF
- Internal service discovery through port scanning via SSRF
- Bypassing firewall rules by making requests from a trusted server

**Primary defenses:**
- Validate and sanitize all user-supplied URLs
- Use an allowlist of permitted domains, IP ranges, and protocols
- Block requests to private/internal IP ranges (10.x, 172.16-31.x, 192.168.x, 169.254.x, localhost)
- Disable unnecessary URL schemes (file://, gopher://, dict://)
- Do not send raw server responses back to the client
- Use network-level segmentation to limit server egress

**Detection:** Identify all places the application fetches user-supplied URLs. Test with internal IP addresses, cloud metadata URLs, and various URL schemes.
