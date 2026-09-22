# Default `allowedTools` by stack

These are starting points for `config.allowedTools` in a generated `backlog.json`. Every pattern here is a specific, purpose-built binary or subcommand, never a bare general-purpose interpreter — that distinction is load-bearing, not a style preference. See "Why no bare interpreters" below before widening any of these.

## PHP / Symfony

```json
["Read", "Edit", "Write", "Glob", "Grep",
 "Bash(composer install*)", "Bash(composer dump-autoload*)", "Bash(vendor/bin/* *)", "Bash(bin/console *)",
 "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)", "Bash(git add *)", "Bash(git commit *)"]
```

## Node / TypeScript

```json
["Read", "Edit", "Write", "Glob", "Grep",
 "Bash(npm run *)", "Bash(npm test*)", "Bash(npx vitest *)", "Bash(npx tsc *)", "Bash(npx eslint *)", "Bash(pnpm run *)", "Bash(yarn run *)",
 "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)", "Bash(git add *)", "Bash(git commit *)"]
```

## Python

```json
["Read", "Edit", "Write", "Glob", "Grep",
 "Bash(pytest *)", "Bash(mypy *)", "Bash(pip install -r *)", "Bash(poetry install*)", "Bash(uv sync*)",
 "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)", "Bash(git add *)", "Bash(git commit *)"]
```

## Why no bare interpreters

Earlier versions of this list included `Bash(php *)`, `Bash(python *)`, `Bash(python3 *)`, and `Bash(node *)` as catch-alls. Cut them, and this is not a style choice: `php -r '<code>'`, `python -c '<code>'`, and `node -e '<code>'` are each a general-purpose interpreter with a code string attached — arbitrary file read/write with no scoping at all, from a single Bash call the allowlist pattern happily approves. That single gap is enough to defeat this plugin's entire tamper-detection design (see `iteration-loop`'s `write-boundary.md`): the content-tamper check's trusted snapshot lives outside the project directory specifically to be unreachable by the worker's Edit/Write tools, but a bare interpreter can write anywhere the OS user can write, snapshot location included, since Claude Code does not sandbox Bash to the project tree the way it scopes Edit/Write.

Every pattern that stays on this list is a specific binary or subcommand doing one auditable thing (run this test suite, run this linter, stage these files) — not "execute whatever code follows." `bin/console`, `vendor/bin/phpunit`, and similar are directly executable via shebang, so you don't lose anything by dropping the `php`-prefixed form; the same reasoning applies to preferring `npm run <script>`/`npx <specific-tool>` over bare `node`, and `pytest`/`mypy`/`poetry run` over bare `python`.

## Package-manager installs are a narrower, second-order version of the same risk

`composer install`, `pip install -r`, `poetry install`, and `uv sync` are still on these lists because a real verify cycle usually needs them, and dropping them entirely would make the defaults impractical. Be clear about what they actually are: each can execute arbitrary code by way of the *project's own config* — a `post-install-cmd` in `composer.json`, a custom build backend in a Python package, npm's `postinstall` (which is why the Node list above never grants bare `npm install` at all). This differs from the bare-interpreter case in one way that matters: it requires the worker to *also* have edited that config file first, since the install command's behavior is defined by project source, not the command itself. It is not, on its own, an unconditional arbitrary-execution grant the way `Bash(php *)` was — but it is a real, documented residual, not a closed one. For anything stronger than "narrower and conditional," this is the same answer as bare interpreters: an OS-level sandbox, not a bash-side allowlist trick.

Dropped from the original defaults for the same reason: `poetry run *` / `uv run *` (arbitrary script execution via whatever the project's config defines as a runnable command — narrower than a bare interpreter, but "run whatever this config file says to run" is close enough to cut by default). Add a narrower, specific form back (e.g. `Bash(poetry run pytest*)`) if a project's real verify command needs that prefix.

## If a project genuinely needs broader Bash

Sometimes a real build needs more than a curated list can enumerate — package installs that shell out further, codegen steps, Docker. If you widen past specific, auditable binaries into anything resembling general code execution, the tamper-detection guarantee no longer holds against a bare-Bash write, full stop — no bash-side trick closes that gap once the worker can execute arbitrary code. At that point the only real answer is running the worker inside an OS-level sandbox (a devcontainer with an egress-allowlist firewall, or a disposable cloud sandbox) where its write access is physically confined to the project directory, not just conventionally directed there. See `permission-modes.md`.

## What deliberately stays out of every default

No `rm`, `cp`, `mv`, `dd`, `tee`, shell output redirection as a bare grant, `curl`/`wget`, `docker`, `sudo`, package-publish commands (`npm publish`, `composer publish`-equivalents), or force-push variants. If a step's `verifyCommand` genuinely needs one of these, add the specific pattern explicitly rather than widening to a wildcard — and reconsider whether that step belongs in an unattended loop at all.
