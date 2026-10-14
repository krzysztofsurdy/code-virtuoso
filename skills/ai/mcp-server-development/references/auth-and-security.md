# Auth and security

How a remote MCP server authenticates callers and what else must hold for it to be safe. Sources are the [authorization](https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization) and [security best practices](https://modelcontextprotocol.io/specification/2026-07-28/basic/security_best_practices) pages of spec 2026-07-28, read on 2026-10-21. Treat the spec text as the authority for MUST and SHOULD wording.

## Contents

- [When auth applies](#when-auth-applies)
- [Roles and standards](#roles-and-standards)
- [The flow](#the-flow)
- [Server duties](#server-duties)
- [Scopes](#scopes)
- [Client registration](#client-registration)
- [Confused deputy and token passthrough](#confused-deputy-and-token-passthrough)
- [SSRF](#ssrf)
- [Handles, local servers, and tool abuse](#handles-local-servers-and-tool-abuse)
- [Security checklist](#security-checklist)
- [Sources](#sources)

## When auth applies

| Transport | Rule |
|---|---|
| Streamable HTTP (remote) | Authorization is optional, and if you support it you should follow the spec |
| stdio (local) | Do not use the OAuth flow. Read credentials from the environment |
| Other transports | Follow the established security practice of that protocol |

Remote servers that act for a user, hold private data, or change state should require auth. An unauthenticated server is open to anyone who can reach it, and the spec says servers should authenticate all connections.

## Roles and standards

- The MCP server is an OAuth 2.1 resource server. It accepts and validates access tokens.
- The MCP client is an OAuth 2.1 client. It acts for the user.
- The authorization server issues tokens. It can be your own or a separate identity provider.

Standards used: OAuth 2.1 (IETF draft), RFC 6750 (bearer tokens), RFC 8414 (authorization server metadata), RFC 8707 (resource indicators), RFC 9728 (protected resource metadata), RFC 9207 (issuer identification), Client ID Metadata Documents (IETF draft), and OpenID Connect Discovery.

## The flow

1. The client calls the server with no token. The server answers 401 with a `WWW-Authenticate` header that holds `resource_metadata` (the URL of your RFC 9728 document) and, ideally, a `scope`.
2. The client fetches the Protected Resource Metadata, reads `authorization_servers`, and discovers the authorization server through RFC 8414 or OpenID Connect discovery.
3. The client obtains a client ID (see below), generates PKCE parameters, and records the expected issuer.
4. The client sends the user to the authorization endpoint with `code_challenge` and the `resource` parameter (the canonical URI of your server).
5. The authorization server redirects back with a code and `iss`. The client checks `iss` against the recorded issuer before sending the code anywhere.
6. The client redeems the code with `code_verifier` and `resource`, and gets an access token.
7. The client calls your server with `Authorization: Bearer <token>` on every request. Tokens never go in the query string.

## Server duties

| Duty | Detail |
|---|---|
| Publish Protected Resource Metadata (RFC 9728) | Required. Clients use it for authorization server discovery |
| Validate every token | Signature, expiry, issuer, and that the audience is your server (RFC 8707). Reject others with 401 |
| Accept only tokens issued for you | You must not accept or pass on any other token |
| Return correct statuses | 401 for missing or invalid tokens, 403 for insufficient scope or permission, 400 for malformed requests |
| Challenge with scope | On 403 use `error="insufficient_scope"`, `scope="..."`, and `resource_metadata` in `WWW-Authenticate` |
| Do not list `offline_access` | Refresh tokens are not a resource requirement |
| Use HTTPS | Authorization servers in production must use HTTPS. Plain HTTP only for loopback during development |

The canonical URI for the `resource` parameter is your server's identifier, for example `https://mcp.example.com/mcp`. No fragment. Be consistent about trailing slashes.

## Scopes

Poor scope design widens what a stolen token can do and trains users to click through consent screens.

- Start with a minimal scope set, such as read and discovery operations only.
- Raise scopes per operation. When a privileged tool is first called, answer 403 with `insufficient_scope` and the scopes that operation needs, all in one challenge. Do not hand out the missing scopes one by one over several retries.
- Accept tokens with fewer scopes than you asked for. Authorization servers may issue a subset.
- Do not publish every scope in `scopes_supported`, and do not use `*`, `all`, or `full-access`. Keep `scopes_supported` to the minimal set for basic function.
- Take scope hierarchy into account when judging whether a token suffices.
- Check authorization inside each tool, not only at the HTTP edge. A scope in a token does not replace an access check on the specific record.
- Log scope elevation events with correlation IDs.

Clients are expected to take the union of earlier and newly challenged scopes when they re-authorize, so servers can stay stateless about each client's scope set.

## Client registration

Clients must have a client ID before the flow starts. The spec names three ways:

| Mechanism | Status |
|---|---|
| Client ID Metadata Documents (the `client_id` is an HTTPS URL that serves the client's metadata) | Authorization servers and clients should support it. It is the recommended path |
| Pre-registration | A client ID issued ahead of time |
| Dynamic Client Registration (RFC 7591) | Deprecated in this revision. Kept for authorization servers without Client ID Metadata Document support |

If your authorization server accepts Client ID Metadata Documents, it fetches a URL supplied by an unknown client, so it needs the same SSRF protections as a client does. For `localhost` redirect URIs, a metadata document proves control of a domain but not which local process is listening, so show extra warnings and the redirect host during consent. Apply domain trust policies (allowlist, reputation checks, or open acceptance) to fit how open your server should be.

## Confused deputy and token passthrough

Token passthrough means accepting a token from a client without checking that it was issued to your server, then forwarding it to a downstream API. The spec forbids it: servers must not accept tokens that were not explicitly issued for them.

Why it matters:

- It sidesteps controls that depend on the audience, such as rate limiting and monitoring.
- Downstream logs show the wrong caller, so audits fail.
- A stolen token that works across services lets an attacker use your server as a proxy.

If your server calls a third-party API for the user, get a separate token for that API (a token exchange or a distinct authorization with the third party), and keep the two token sets apart.

If your server is an OAuth proxy in front of a third-party authorization server and uses one static client ID there, an attacker can combine dynamic client registration with the third party's consent cookie and skip consent. Proxy servers must:

- Keep a per-user registry of approved client IDs and check it before starting the third-party flow.
- Show their own consent page that names the client, the third-party scopes, and the redirect URI, with CSRF protection and clickjacking defenses (`frame-ancestors` or `X-Frame-Options: DENY`).
- Use `__Host-` cookies with `Secure`, `HttpOnly`, and `SameSite=Lax`, signed or backed by server-side sessions, and bound to the client ID.
- Match `redirect_uri` exactly against the registered value.
- Generate a random `state` per request, store it only after consent is approved, make it single-use with a short expiry (about 10 minutes), and reject callbacks where it is missing or does not match.

## SSRF

During discovery, clients fetch URLs that a malicious server controls: the `resource_metadata` URL, the `authorization_servers` entries, and endpoints in the authorization server metadata. A hostile server can point these at internal addresses or cloud metadata endpoints such as `169.254.169.254`.

If you build or deploy an MCP client, or an authorization server that fetches client metadata documents:

- Require HTTPS for OAuth URLs outside loopback development.
- Block private and reserved ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8, ::1, 169.254.0.0/16, fc00::/7, fe80::/10. Use a tested library for the IP checks, because octal, hex, and IPv4-mapped IPv6 encodings defeat hand-written parsers.
- Validate each redirect hop, or turn off automatic redirects.
- Pin DNS results between the check and the connection to defeat rebinding.
- Route server-side fetches through an egress proxy that enforces network policy.
- Clients must accept only `http` and `https` for authorization URLs, reject `javascript:`, `data:`, `file:`, and similar schemes, and never open URLs through a shell.

## Handles, local servers, and tool abuse

- State handles are names, not credentials. Make them random, expiring, and bound to the verified user.
- Origin check on Streamable HTTP is required, and 403 on an invalid origin. Bind local HTTP servers to 127.0.0.1 and require a token or use a Unix socket. stdio limits access to the client that launched the process.
- Local servers run with the user's privileges. Clients that offer one-click install must show the exact command and get consent. Server authors should ship minimal-privilege defaults and support sandboxing.
- Servers must validate all tool inputs, enforce access control, rate limit calls, and sanitize outputs. Treat tool outputs that carry third-party text (web pages, tickets, emails) as untrusted when you pass them to a model, since they can contain injected instructions.
- Clients should confirm sensitive operations with the user, show tool inputs before sending, set timeouts, and log usage.
- A server that reads untrusted content, holds private data, and can send data out is exposed to prompt-injection exfiltration. Split those capabilities across servers or sessions. See `agent-design`.
- Refresh tokens are the client's to keep confidential. Do not log tokens, and keep them out of traces and error messages.

## Security checklist

- [ ] Remote HTTP server requires auth, with RFC 9728 metadata published
- [ ] Token audience checked against your canonical URI. Foreign tokens rejected
- [ ] No token passthrough. Separate credentials for downstream APIs
- [ ] PKCE and `resource` supported through your authorization server
- [ ] Minimal initial scopes, per-operation step-up, no wildcard scopes
- [ ] 401 and 403 responses carry correct `WWW-Authenticate` parameters
- [ ] Authorization checked inside each tool against the specific resource
- [ ] Proxy servers: per-client consent, exact redirect match, single-use `state`
- [ ] Handles are random, bound to the user, and expire
- [ ] `requestState` integrity-protected with expiry and principal binding
- [ ] Origin validated, local binding to 127.0.0.1, HTTPS in production
- [ ] Inputs validated, calls rate limited, outputs sanitized
- [ ] Client-side fetches guarded against SSRF
- [ ] Secrets and tokens kept out of logs, errors, and traces

## Sources

- Authorization: https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization
- Security best practices: https://modelcontextprotocol.io/specification/2026-07-28/basic/security_best_practices
- RFC 9728 (Protected Resource Metadata): https://datatracker.ietf.org/doc/html/rfc9728
- RFC 8707 (Resource Indicators): https://www.rfc-editor.org/rfc/rfc8707.html
- RFC 9207 (Issuer Identification): https://datatracker.ietf.org/doc/html/rfc9207
- OWASP SSRF Prevention Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html
