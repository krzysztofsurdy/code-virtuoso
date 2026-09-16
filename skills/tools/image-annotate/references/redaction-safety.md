# Redaction safety

This reference explains when each obscuring operation in the skill is safe and when it leaks the thing it was meant to hide.

## The short version

| Operation | Safe for | Not safe for |
|---|---|---|
| **`redact`** (solid block) | Anything: passwords, tokens, secrets, faces, names | - |
| **`blur`** (Gaussian) | Faces, peripheral scenery, ambient background detail | Any readable text, because it can be reversed |
| **Pixelation** (not exposed in this skill) | Nothing that needs to stay secret | Same as blur, often worse |

When in doubt, use `redact`. A solid block leaks zero information about what was beneath it.

## Why blur and pixelation are reversible for text

Pixelation maps a block of pixels to their average color. Blur convolves a region with a Gaussian kernel. Both transformations are deterministic: the same input produces the same output.

For text, this is fatal:

1. Text is drawn in a known font at a known size on a known background.
2. An attacker can render every plausible string ("password123", "p@ssw0rd", etc.) in the same font, apply the same blur or pixelation, and compare the result to the leaked region.
3. The match identifies the original string.

This is not theoretical. Open-source tools demonstrate the attack on real screenshots: depixelization proofs of concept recover ASCII and numeric text from pixelated images, and unredacter-style tools crack blurred text with the same render-and-match loop. If the transformation is deterministic and the search space is small, the original is recoverable.

For fields you cannot afford to leak, the only safe operation is full-opacity replacement: a solid-color rectangle with no transparency, no blur, and no pixelation.

## The skill's defaults

The bundled `annotate.py` script:

- `redact` paints a solid rectangle with no alpha, no edge softening, no interpolation. This is the safe operation.
- `blur` applies a `PIL.ImageFilter.GaussianBlur`. It suits faces and scenery, not text.
- The skill does not expose a pixelation operation. Pixelation is worse than blur for reversibility.

## What must be redacted, not blurred

| Data class | Why |
|---|---|
| Passwords, password hints | Direct credential reuse |
| API tokens, JWTs, OAuth tokens | Credential reuse |
| Session cookies | Account takeover until rotation |
| Secret keys, signing keys, .env values | Long-term credential reuse |
| TOTP / 2FA recovery codes | MFA bypass |
| Credit-card numbers, CVV | Direct fraud |
| Social security / national-id numbers | Identity fraud |
| Bank-account and routing numbers | Direct fraud |
| Customer PII when sharing externally | Legal exposure under GDPR, CCPA, etc. |
| Medical record numbers and patient data | HIPAA exposure |
| Private SSH keys, GPG keys | Direct reuse |
| Internal hostnames, IP addresses, infrastructure paths | Reconnaissance value |

## What is acceptable to blur

| Data class | Why blur is acceptable |
|---|---|
| Faces in casual marketing screenshots | The threat model is "general public viewing", not skilled adversary recovery |
| Peripheral background content (other browser tabs, desktop wallpapers) | Same |
| Decorative imagery that happens to contain a recognizable detail | Same |
| Branded artwork where the brand stays legible but surrounding context blurs | Same |

Rule of thumb: if a recovered version of the content has no monetary, identity, or access value, blur is fine. If a successful recovery would give an attacker something to spend, replay, or impersonate with, use `redact`.

## Common mistakes

| Mistake | Consequence |
|---|---|
| Pixelating an API token in a Slack screenshot | Token recovered, credential reused before rotation |
| Blurring a URL that contains a one-time signed token | URL reconstructed, action replayed |
| Solid-redacting only the visible part of a token that wraps to a second line | Second-line characters leaked. The rectangle must cover the bounding box on every line the secret occupies |
| Redacting in a separate image-editor layer that was not flattened before export | The redaction layer can be removed. Always export to a flat raster |
| Picking the redact color to match the page background | Looks tidy but can leave visible character outlines if the underlying font had sub-pixel anti-aliasing. Prefer high-contrast solid black or white |

## Verification

After redacting, view the output at 200-400% zoom. Faint outlines, residual colors, or sub-pixel ghosting mean the rectangle did not cover the full bounding box. Widen it and re-run.

For high-stakes redactions (legal disclosure, security advisories), open the file in a second viewer to confirm the redacted region is uniform pixel-by-pixel. Some image editors keep weak transparency that the author thought was opaque.
