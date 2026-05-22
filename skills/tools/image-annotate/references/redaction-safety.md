# Redaction Safety

This reference explains when each obscuring operation in the skill is safe and when it actively leaks the thing it was meant to hide.

## The Short Version

| Operation | Safe for | Not safe for |
|---|---|---|
| **`redact`** (solid block) | Anything: passwords, tokens, secrets, faces, names | - |
| **`blur`** (Gaussian) | Faces, peripheral scenery, ambient background detail | Any readable text - it can be reversed |
| **Pixelation** (not exposed in this skill) | Nothing that needs to stay secret | Same as blur, often worse |

When in doubt, use `redact`. A solid block leaks zero information about what was beneath it.

## Why Blur and Pixelation Are Reversible for Text

Pixelation maps a block of pixels to their average colour. Blur convolves a region with a Gaussian kernel. Both transformations are *deterministic*: the same input produces the same output.

For text, this is fatal:

1. Text characters are drawn from a known font at a known size on a known background.
2. An attacker can render every plausible string ("password123", "p@ssw0rd", etc.) in the same font, apply the same blur or pixelation, and compare the result to the leaked region.
3. The match identifies the original string.

This is not theoretical. Open-source tools demonstrate the attack on real screenshots: Depixelization PoCs recover ASCII/numeric text from pixelated images, and Unredacter-style tools crack blurred text by the same rendering-and-matching loop. The principle is simple: if the transformation is deterministic and the search space is small, the original is recoverable.

For redacting *fields you cannot afford to leak*, the only safe operation is full-opacity replacement - a solid-colour rectangle, no transparency, no blur, no pixelation.

## The Skill's Defaults

The bundled `annotate.py` script:

- `redact` paints a solid rectangle with no alpha, no edge softening, no interpolation. This is the safe operation.
- `blur` applies a `PIL.ImageFilter.GaussianBlur`. Useful for faces and scenery; not useful for text.
- The skill does not expose a pixelation operation. Pixelation is strictly worse than blur for reversibility.

## What Must Be Redacted, Not Blurred

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

## What Is Acceptable to Blur

| Data class | Why blur is acceptable |
|---|---|
| Faces in casual marketing screenshots | Threat model is "general public viewing", not skilled adversary recovery |
| Peripheral background content (other browser tabs, desktop wallpapers) | Same |
| Decorative imagery that happens to contain a recognisable detail | Same |
| Branded artwork where the brand stays legible but surrounding context blurs | Same |

Rule of thumb: if a recovered version of the content has *no monetary, identity, or access value*, blur is fine. If a successful recovery would give an attacker something they could spend, replay, or impersonate with, use `redact`.

## Common Mistakes

| Mistake | Consequence |
|---|---|
| Pixelating an API token in a Slack screenshot | Token recovered, credential reused before rotation |
| Blurring a URL that contains a one-time signed token | URL reconstructed, action replayed |
| Solid-redacting only the visible part of a token that wraps to a second line | Second-line characters leaked - the rectangle must cover the bounding box on every line the secret occupies |
| Redacting in a separate image-editor layer that was not flattened before export | The redaction layer can be removed - always export to a flat raster |
| Picking the redact colour to match the page background | Looks tidy but creates visible character outlines if the underlying font had sub-pixel anti-aliasing - prefer high-contrast solid black or white |

## Verification

After redacting, view the output at 200-400% zoom. Faint outlines, residual colours, or sub-pixel ghosting mean the rectangle did not cover the full bounding box - widen it and re-run.

For high-stakes redactions (legal disclosure, security advisories), open the file in a second viewer to confirm the redacted region is uniform pixel-by-pixel. Some image editors will preserve weak transparency the original author thought was opaque.
