# Agent Targets Reference

Output file paths, format requirements, limits, and testing instructions for each supported AI coding agent. Covers all three scopes: global, project team-shared, and project dev-specific.

---

## Tier 1 — Full Support

### Claude Code

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
- Plain Markdown, no frontmatter required
- Keep global file concise — Claude Code loads this into every conversation context
- Project rules in `.claude/rules/` are loaded automatically alongside CLAUDE.md
- For dev-specific rules, advise the user to add the file path to `.gitignore`
- Add a footer note on global: `For project-specific rules, use .claude/rules/*.md files.`

**Testing:** Start a new Claude Code session and ask "What are your rules?" — it should reference the content.

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
- The `alwaysApply: true` flag ensures rules are loaded in every conversation

**Testing:** Open Cursor, start a new chat, and ask about the rules.

---

### Windsurf

| Scope | Output File |
|---|---|
| Global | `~/.windsurf/rules/global-rules.md` |
| Project (team-shared) | `.windsurf/rules/team-rules.md` |
| Project (dev-specific) | `.windsurf/rules/dev-rules.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown |
| Character limit | **12,000 characters maximum** |

**Format notes:**
- Strict 12,000 character limit — content beyond this is truncated
- If generated content exceeds the limit, condense by removing examples and shortening descriptions
- Add a comment at the top: `<!-- Windsurf rules -->`

**Testing:** Open Windsurf, start a new Cascade session, and ask about the rules.

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

### Gemini CLI

| Scope | Output File |
|---|---|
| Global | `~/.gemini/GEMINI.md` |
| Project (team-shared) | `GEMINI.md` (project root) |
| Project (dev-specific) | `.gemini/rules/dev-rules.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown |
| Character limit | No hard limit |

**Format notes:**
- Global rules in `~/.gemini/GEMINI.md` are loaded for all sessions
- Project-level `GEMINI.md` at root is loaded when Gemini CLI runs in that directory
- Plain Markdown, no special syntax

**Testing:** Run `gemini` in the project directory and ask about the rules.

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
| Global | `~/.codex/instructions.md` |
| Project (team-shared) | `AGENTS.md` (project root) |
| Project (dev-specific) | `.agents/dev-rules.md` (add to `.gitignore`) |

| Property | Value |
|---|---|
| Format | Plain Markdown |
| Character limit | No hard limit |

**Format notes:**
- Project-level convention is `AGENTS.md` at project root (emerging cross-tool standard)
- Plain Markdown, no special syntax
- Global instructions at `~/.codex/instructions.md`

**Testing:** Run `codex` in the project directory and ask about the rules.

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

## Tier 2 — Generic Markdown Support

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

## Other / Universal

For agents not listed above, ask the user for the output path and write plain Markdown. No special formatting is applied.

Common conventions that may apply:
- Most agents look for rules in a dotfile directory (`.agent-name/rules/`)
- `AGENTS.md` at project root is an emerging cross-tool standard
- Global rules typically go under `~/` in the agent's config directory
