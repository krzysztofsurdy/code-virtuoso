# Agent Targets Reference

Output file paths, format requirements, limits, and testing instructions for each supported AI coding agent. Covers all three scopes: global, project team-shared, and project dev-specific.

For project team-shared rules, prefer `AGENTS.md` at the repository root when the tool reads it (Claude Code, Codex, Cursor, Copilot, Gemini or Antigravity, Devin Desktop). Write the rules once there. The per-tool project paths below are for rules that must be scoped or tool-specific, and a tool file that must exist should import or point to `AGENTS.md` instead of copying it.

## Contents

- [Tier 1: full support](#tier-1-full-support)
- [Tier 2: generic Markdown support](#tier-2-generic-markdown-support)
- [Other / universal](#other--universal)

---

## Tier 1: full support

### Claude Code

| Scope | Output File |
|---|---|
| Global | `~/.claude/CLAUDE.md` |
| Project (team-shared) | `AGENTS.md` at the repo root (single source of truth, see the AGENTS.md note below). Use `.claude/rules/*.md` with `paths:` only for rules that apply to part of the repo |
| Project (dev-specific) | `.claude/rules/dev-rules.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown |
| Line limit | Under about 200 lines per `CLAUDE.md` file |

**Format notes:**
- Plain Markdown. Frontmatter is optional and only `paths` is read
- Keep every always-on file concise. Longer files use more context and reduce adherence
- Rules in `.claude/rules/` without `paths` frontmatter load at launch, like `.claude/CLAUDE.md`. Rules with `paths` load only when Claude reads or edits a matching file:
  ```
  ---
  paths:
    - "src/api/**/*.ts"
  ---
  ```
  Use path-scoped rules for anything that matters to only part of the codebase
- Imports (`@path`) organize a long file but do not reduce its cost, because imported files also load at launch
- **One source of truth:** write project rules once, to `AGENTS.md`. Either create no `CLAUDE.md`, or create a thin one that starts with `@AGENTS.md` and holds only Claude-specific lines. Never put the same rules in both files. The import avoids a second copy of the text but does not reduce context cost
- **Global:** Claude Code documents `~/.claude/CLAUDE.md` as the user file and does not list a user-level `AGENTS.md`. Codex reads `~/.codex/AGENTS.md`. Keep a separate short global file per tool
- **No skill lists:** do not write skill routing tables or agent rosters into `CLAUDE.md`. Skill descriptions already reach the model, and Claude Code truncates the skill listing when many are installed (1% of the context window, 1,536 characters per skill). A generic line plus rules for skills the user names (and that are installed) is enough. To check for dropped descriptions run `/context`, and `/skill-doctor` for per-skill cost
- **AGENTS.md:** Claude Code reads `AGENTS.md` as project instructions when there is no `CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md` in the working directory or above it (Claude Code 2.1.277 or later). If any of those exists, only the `CLAUDE.md` files are read, so a `CLAUDE.md` in a repository that uses `AGENTS.md` should contain `@AGENTS.md`. `~/.claude/CLAUDE.md` and `.claude/rules/` files do not count for that check and keep loading next to `AGENTS.md`
- For dev-specific rules, advise the user to add the file path to `.gitignore`
- Add a footer note on global: `For project-specific rules, use .claude/rules/*.md files.`
- To audit existing instruction files, run `/doctor prompt-audit` or delegate to the `instruction-auditor` agent

**Testing:** Start a new Claude Code session and ask "What are your rules?" It should reference the content. In an interactive session, a line such as `no CLAUDE.md found; AGENTS.md loaded: <path>` confirms `AGENTS.md` loading.

**Sources:** [How Claude remembers your project](https://code.claude.com/docs/en/memory).

---

### Cursor

| Scope | Output File |
|---|---|
| Global | `~/.cursor/rules/global-rules.mdc` |
| Project (team-shared) | `.cursor/rules/team-rules.mdc` |
| Project (dev-specific) | `.cursor/rules/dev-rules.mdc` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Markdown with YAML frontmatter |
| Frontmatter | Required: `alwaysApply: true` |
| Extension | `.mdc` |

**Format notes:**
- Must include YAML frontmatter at the top:
  ```
  ---
  alwaysApply: true
  ---
  ```
- File extension is `.mdc` (Markdown Cursor)
- The `alwaysApply: true` flag loads the rules in every conversation

**Testing:** Open Cursor, start a new chat, and ask about the rules.

---

### Windsurf (now Devin Desktop)

Devin Desktop is the new name for Windsurf: the same editor under the Devin brand.

| Scope | Output File |
|---|---|
| Global | `~/.codeium/windsurf/memories/global_rules.md` |
| Project (team-shared) | `.devin/rules/team-rules.md` (fallback location: `.windsurf/rules/`) |
| Project (dev-specific) | `.devin/rules/dev-rules.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown, frontmatter on workspace rules |
| Character limit | **6,000 characters** for the global file, **12,000 characters** per workspace rule file |

**Format notes:**
- `.devin/rules/` is the preferred workspace location and takes precedence. `.windsurf/rules/` is still read as a fallback, and so is the legacy single file `.windsurfrules`. There is no `.devinrules` single-file equivalent
- Workspace rule files use a `trigger` frontmatter field: `always_on` (in the prompt on every message), `model_decision` (only the description is in the prompt, the model reads the file when relevant), `glob` (applies when a file matching `globs` is read or edited), or `manual` (only on `@rule-name`). Generate `trigger: always_on` for team-wide rules and `trigger: glob` with `globs` for rules scoped to part of the repo
- The global file and root-level `AGENTS.md` files take no frontmatter. Devin Desktop reads `AGENTS.md` through the same rules engine: a root file is always on, and a file in a subdirectory applies to that directory
- If generated content exceeds a limit, condense by removing examples and shortening descriptions

**Testing:** Open Devin Desktop (Windsurf), start a new Cascade session, and ask about the rules.

**Sources:** [Devin Desktop FAQ](https://docs.devin.ai/desktop/devin-desktop-faq.md), [Devin Desktop rules and memories](https://docs.devin.ai/desktop/cascade/memories.md).

---

### GitHub Copilot

| Scope | Output File |
|---|---|
| Global | `~/.github/copilot-instructions.md` (copy into projects) |
| Project (team-shared) | `.github/copilot-instructions.md` |
| Project (dev-specific) | `.github/instructions/dev-rules.instructions.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown |
| Character limit | No hard limit |

**Format notes:**
- GitHub Copilot's primary supported location is project-level `.github/copilot-instructions.md`
- For global scope, write to `~/.github/copilot-instructions.md` and advise the user to copy or symlink it into each project's `.github/` directory
- Dev-specific instructions files can use `applyTo` frontmatter to target specific file patterns

**Testing:** Open VS Code with Copilot, start a chat, and ask about coding conventions.

---

### Gemini CLI and Antigravity CLI

Antigravity CLI replaced Gemini CLI on 2026-06-18 for unpaid (free) users and for Google AI Pro and Ultra users, including use through Gemini Code Assist IDE extensions. Gemini CLI stays available for enterprise users with a Gemini Code Assist Standard or Enterprise license, and through paid Gemini or Gemini Enterprise Agent Platform API keys. Ask the user which one they run, and write the files for it.

**Antigravity CLI**

| Scope | Output File |
|---|---|
| Global | `~/.gemini/AGENTS.md` (CLI-only rules also load from `~/.gemini/antigravity-cli/rules/*.md`) |
| Project (team-shared) | `AGENTS.md` (project root) |
| Project (dev-specific) | `.agents/rules/dev-rules.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown. `AGENTS.md` and `GEMINI.md` take no frontmatter |
| Limits | 24 KB per rule file (larger files are truncated). A 20,000-token budget covers all active global and `always_on` rules, and the largest files are demoted to pointers |

**Format notes:**
- Antigravity reads `AGENTS.md` or `GEMINI.md` in the workspace folder and in each directory on the path from a touched file up to the workspace root, plus `.agents/AGENTS.md`, `.agents/GEMINI.md`, and `.agents/rules/*.md`. Global files are `~/.gemini/AGENTS.md`, `~/.gemini/GEMINI.md`, and `~/.gemini/config/rules/*.md`
- Rules are cumulative across global, workspace, and directory scopes. When they conflict, the more specific directory rule wins
- Every `.md` file in a `rules/` directory must start with frontmatter that declares `trigger` (`always_on`, `model_decision`, `glob`, or `manual`). A file without valid frontmatter is silently discarded. `model_decision` needs a `description`, and `glob` needs `globs`:
  ```
  ---
  trigger: always_on
  ---
  ```

**Gemini CLI (enterprise and paid API key users)**

| Scope | Output File |
|---|---|
| Global | `~/.gemini/GEMINI.md` |
| Project (team-shared) | `GEMINI.md` (project root) |
| Project (dev-specific) | Not verified. Use the global file |

Gemini CLI loads `GEMINI.md` context files. If the team uses both tools, keep one source of truth: Antigravity reads either file name, so a `GEMINI.md` that holds the shared rules serves both.

**Testing:** Start the CLI in the project directory and ask about the rules.

**Sources:** [Antigravity rules](https://antigravity.google/docs/rules), [Transitioning Gemini CLI to Antigravity CLI](https://github.com/google-gemini/gemini-cli/discussions/27274), [Gemini CLI README](https://github.com/google-gemini/gemini-cli).

---

### Roo Code

| Scope | Output File |
|---|---|
| Global | `~/.roo/rules/global-rules.md` |
| Project (team-shared) | `.roo/rules/team-rules.md` |
| Project (dev-specific) | `.roo/rules/dev-rules.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown |
| Character limit | No hard limit |

**Format notes:**
- Plain Markdown
- Rules in `.roo/rules/` are loaded automatically

**Testing:** Open VS Code with Roo Code extension, start a conversation, and ask about the rules.

---

### Amp

| Scope | Output File |
|---|---|
| Global | `~/.claude/CLAUDE.md` |
| Project (team-shared) | `.claude/rules/team-rules.md` |
| Project (dev-specific) | `.claude/rules/dev-rules.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown |
| Line limit | Under 200 lines recommended (global) |

**Format notes:**
- Uses the same file locations and format as Claude Code
- Add footer note on global: `For project-specific rules, use .claude/rules/*.md files.`

**Testing:** Start a new Amp session and ask about the rules.

---

### Codex (OpenAI)

| Scope | Output File |
|---|---|
| Global | `~/.codex/AGENTS.md` (in `CODEX_HOME` if set) |
| Project (team-shared) | `AGENTS.md` (project root) |
| Project (dev-specific) | Not layered. Put personal rules in the global file |

| Property | Value |
|---|---|
| Format | Plain Markdown |
| Size limit | 32 KiB combined (`project_doc_max_bytes`). Codex stops adding files once the limit is reached |

**Format notes:**
- Codex reads one file per directory (`AGENTS.override.md` first, else `AGENTS.md`) from the Codex home, then from the project root down to the current directory, and concatenates them. Files closer to the working directory come later and override earlier guidance
- An `AGENTS.override.md` in a project directory replaces the `AGENTS.md` there instead of adding to it, so it is not a place for a small personal layer
- Plain Markdown, no special syntax

**Testing:** Run `codex` in the project directory and ask about the rules.

**Sources:** [AGENTS.md in Codex](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

---

### Cline

| Scope | Output File |
|---|---|
| Global | `~/.agents/rules/global-rules.md` |
| Project (team-shared) | `.agents/rules/team-rules.md` |
| Project (dev-specific) | `.agents/rules/dev-rules.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown |
| Character limit | No hard limit |

**Format notes:**
- Plain Markdown
- Rules in `.agents/rules/` are loaded automatically

**Testing:** Open VS Code with Cline extension and ask about the rules.

---

### OpenCode

| Scope | Output File |
|---|---|
| Global | `~/.config/opencode/rules/global-rules.md` |
| Project (team-shared) | `.agents/rules/team-rules.md` |
| Project (dev-specific) | `.agents/rules/dev-rules.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown |
| Character limit | No hard limit |

**Format notes:**
- Global path differs from project path
- Plain Markdown, no special syntax

**Testing:** Run `opencode` and ask about the rules.

---

### Continue

| Scope | Output File |
|---|---|
| Global | `~/.continue/rules/global-rules.md` |
| Project (team-shared) | `.continue/rules/team-rules.md` |
| Project (dev-specific) | `.continue/rules/dev-rules.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown |
| Character limit | No hard limit |

**Format notes:**
- Plain Markdown
- Rules in `.continue/rules/` are loaded by the Continue extension

**Testing:** Open IDE with Continue extension and ask about the rules.

---

### Trae

| Scope | Output File |
|---|---|
| Global | `~/.trae/rules/global-rules.md` |
| Project (team-shared) | `.trae/rules/team-rules.md` |
| Project (dev-specific) | `.trae/rules/dev-rules.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown |
| Character limit | No hard limit |

**Format notes:**
- Plain Markdown
- Trae (by ByteDance) uses `.trae/rules/` directory

**Testing:** Open Trae and ask about the rules.

---

## Tier 2: generic Markdown support

These agents use plain Markdown with no special formatting. Paths follow vercel-labs/skills conventions.

### Goose

| Scope | Output File |
|---|---|
| Global | `~/.config/goose/rules/global-rules.md` |
| Project (team-shared) | `.goose/rules/team-rules.md` |
| Project (dev-specific) | `.goose/rules/dev-rules.md` (add to `.gitignore`) |

### Augment

| Scope | Output File |
|---|---|
| Global | `~/.augment/rules/global-rules.md` |
| Project (team-shared) | `.augment/rules/team-rules.md` |
| Project (dev-specific) | `.augment/rules/dev-rules.md` (add to `.gitignore`) |

### Kilo Code

| Scope | Output File |
|---|---|
| Global | `~/.kilocode/rules/global-rules.md` |
| Project (team-shared) | `.kilocode/rules/team-rules.md` |
| Project (dev-specific) | `.kilocode/rules/dev-rules.md` (add to `.gitignore`) |

---

## Other / universal

For agents not listed above, ask the user for the output path and write plain Markdown. The file gets no special formatting.

Common conventions that may apply:
- Most agents look for rules in a dotfile directory (`.agent-name/rules/`)
- `AGENTS.md` at project root is an emerging cross-tool standard. Claude Code, Codex, Devin Desktop, and Antigravity all read it
- Keep always-on files short. Put rules for part of a codebase in the tool's path-scoped or glob-triggered rules, if it has them
- Global rules typically go under `~/` in the agent's config directory
