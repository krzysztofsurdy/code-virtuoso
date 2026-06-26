# Default `allowedTools` by stack

These are starting points for `config.allowedTools` in a generated `backlog.json`. They are deliberately broad within a safe boundary — `acceptEdits` already covers file writes, so these patterns only need to cover the Bash commands an implementation-and-verify cycle realistically needs. Narrow them further if the project has unusually sensitive tooling; widen them if the loop keeps stalling on a denied command the protected-paths guard would have been fine with anyway.

## PHP / Symfony

```json
["Read", "Edit", "Write", "Glob", "Grep",
 "Bash(composer *)", "Bash(vendor/bin/* *)", "Bash(bin/console *)", "Bash(php *)",
 "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)", "Bash(git add *)", "Bash(git commit *)"]
```

## Node / TypeScript

```json
["Read", "Edit", "Write", "Glob", "Grep",
 "Bash(npm *)", "Bash(npx *)", "Bash(node *)", "Bash(pnpm *)", "Bash(yarn *)",
 "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)", "Bash(git add *)", "Bash(git commit *)"]
```

## Python

```json
["Read", "Edit", "Write", "Glob", "Grep",
 "Bash(python *)", "Bash(python3 *)", "Bash(pytest *)", "Bash(pip *)", "Bash(poetry *)", "Bash(uv *)",
 "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)", "Bash(git add *)", "Bash(git commit *)"]
```

## What deliberately stays out of every default

No `rm`, `curl`/`wget`, `docker`, `sudo`, package-publish commands (`npm publish`, `composer publish`-equivalents), or force-push variants. If a step's `verifyCommand` genuinely needs one of these, add the specific pattern explicitly rather than widening to a wildcard — and reconsider whether that step belongs in an unattended loop at all.
