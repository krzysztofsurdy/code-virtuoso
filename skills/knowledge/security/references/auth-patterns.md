# Authentication and Authorization Patterns

Reference for identity verification and permission management. The patterns are stack-agnostic and apply to any web application or API.

## Contents

- [Password storage](#password-storage)
- [Session-based authentication](#session-based-authentication)
- [Token-based authentication (JWT)](#token-based-authentication-jwt)
- [OAuth2 flows](#oauth2-flows)
- [API key management](#api-key-management)
- [Multi-factor authentication (MFA)](#multi-factor-authentication-mfa)
- [Authorization patterns](#authorization-patterns)

## Password storage

**Hashing:**
- Use Argon2id (preferred), bcrypt, or scrypt. They are designed for password hashing and have configurable cost factors
- Never use MD5, SHA-1, or SHA-256 alone. They are too fast for password hashing, which makes brute force trivial
- Never store passwords in plain text or with reversible encryption

**Salting:**
- Each password must have a unique, cryptographically random salt
- Modern password hashing libraries (bcrypt, Argon2) generate and store salts automatically
- Never reuse salts across passwords

**Policy:**
- Enforce a minimum length (12+ characters recommended)
- Check passwords against breached password databases (e.g., Have I Been Pwned)
- Avoid restrictive rules (mandatory special characters) that encourage predictable patterns like `Password1!`
- Allow long passphrases and do not cap password length at a low value

## Session-based authentication

**How it works:** Server creates a session on login, stores session data server-side, sends a session ID to the client via a cookie.

**Secure cookie attributes:**
- `HttpOnly`: prevents JavaScript access, mitigating XSS-based session theft
- `Secure`: cookie sent only over HTTPS
- `SameSite=Lax` (or `Strict`): prevents CSRF by limiting cross-origin cookie sending
- Set a reasonable `Max-Age` or `Expires` value

**Session lifecycle:**
- Generate session IDs using a cryptographically secure random generator (128+ bits of entropy)
- Regenerate the session ID after login to prevent session fixation attacks
- Implement idle timeout (e.g., 30 minutes of inactivity) and absolute timeout (e.g., 8 hours)
- Invalidate sessions server-side on logout. Deleting the client cookie is not enough
- Store sessions in a server-side store (database, Redis) rather than only in memory for scalability

## Token-based authentication (JWT)

**JWT structure:** Header (algorithm, type) + Payload (claims) + Signature. The payload is base64url-encoded, not encrypted, so anyone can read it.

**Signing vs. encryption:**
- Signing (JWS) verifies the token was not tampered with. Use RS256 or ES256
- Encryption (JWE) hides the payload contents. Use it when tokens contain sensitive claims
- Most implementations use signing only; do not put sensitive data in the payload

**Best practices:**
- Validate the algorithm server-side; reject `alg: none` and unexpected algorithms
- Keep access tokens short-lived (5-15 minutes)
- Use refresh tokens for long-lived sessions; store refresh tokens securely (HttpOnly cookie or secure server-side storage)
- Include `iss` (issuer), `aud` (audience), `exp` (expiration), and `iat` (issued at) claims
- Validate all claims on every request

**Token revocation:**
- JWTs are stateless, so there is no built-in revocation mechanism
- Options: short expiration + refresh tokens, token denylist (checked on each request), or database-backed sessions with JWT format
- If you need instant revocation, consider session-based auth or a hybrid approach

## OAuth2 flows

**Authorization Code with PKCE:**
- Standard for web applications, single-page apps, and mobile apps
- Client redirects user to authorization server; receives an authorization code; exchanges code for tokens
- PKCE (Proof Key for Code Exchange) prevents authorization code interception
- Always use PKCE, even for confidential clients

**Client Credentials:**
- For machine-to-machine communication where no user is involved
- Client authenticates directly with the authorization server using its own credentials
- Returns an access token scoped to the client's permissions

**Deprecated flows:**
- Implicit flow: deprecated; tokens exposed in URL fragments, vulnerable to interception
- Resource Owner Password Credentials: deprecated; requires the client to handle user passwords directly

## API key management

- Generate keys using cryptographically secure random generators with sufficient length (256+ bits)
- Scope keys to specific permissions and resources, and avoid master keys
- Implement rate limiting per API key
- Support key rotation: allow multiple active keys during transition periods
- Log API key usage for auditing
- Transmit keys in headers (not URL query parameters, which appear in logs and browser history)
- Hash stored API keys (they are secrets, like passwords)

## Multi-factor authentication (MFA)

**TOTP (Time-Based One-Time Passwords):**
- Standard algorithm (RFC 6238) supported by most authenticator apps
- Server and client share a secret; codes rotate every 30 seconds
- Allow a small time window for clock drift (1 step before and after)

**WebAuthn / Passkeys:**
- Strongest authentication factor, resistant to phishing
- Uses public key cryptography; private key never leaves the device
- Supports biometrics (fingerprint, face) as a local verification step
- Supported across major platforms and browsers

**SMS-based MFA:**
- Better than no MFA, but the weakest factor
- Vulnerable to SIM swapping, SS7 attacks, and social engineering at carriers
- Use only as a fallback, not as the primary second factor

**Recovery:**
- Provide recovery codes at MFA enrollment time
- Store recovery codes securely (hashed, like passwords)
- Limit the number of recovery codes and regenerate them when used

## Authorization patterns

**RBAC (Role-Based Access Control):**
- Assign permissions to roles; assign roles to users
- Check permissions in code, not role names: `user.hasPermission('edit_post')` rather than `user.hasRole('editor')`
- Keep roles coarse-grained to avoid role explosion
- Support role hierarchies where useful (admin inherits editor permissions)

**ABAC (Attribute-Based Access Control):**
- Decisions based on attributes: user attributes (department, clearance), resource attributes (classification, owner), action attributes (read, write), and environment attributes (time, IP)
- Express policies as rules: "Allow if user.department == resource.department AND action == read"
- More flexible than RBAC but more complex to implement and audit

**Permission checking patterns:**
- Enforce authorization on every request. Middleware or decorators are good enforcement points
- Check both collection-level access (can the user list posts?) and resource-level access (can the user view this specific post?)
- Avoid authorization bypass: do not expose admin endpoints without protection, do not rely on client-side checks, do not trust user-supplied role claims

**Common pitfalls:**
- Horizontal privilege escalation: user A accesses user B's data by changing an ID parameter
- Vertical privilege escalation: a regular user accesses admin functionality
- Missing function-level access control: an API endpoint exists but has no authorization check
- Inconsistent enforcement: some endpoints check authorization, others do not
