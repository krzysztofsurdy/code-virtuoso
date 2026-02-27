![Logo](logo.png)
# Code Virtuoso

AI agent skill sets for software engineering — built on the [Agent Skills](https://agentskills.io) open standard. Knowledge, Setup, and Frameworks.

Three categories of plugins, installable independently or as bundles:

- **Knowledge** — Design Patterns, Refactoring, SOLID Principles, Debugging, Clean Architecture, Testing, API Design, Security. Reference material with progressive disclosure.
- **Setup** — Agentic Rules Writer. Agent configuration and bootstrapping tools.
- **Frameworks** — Symfony. Component-level reference for framework-specific development.

---

## Knowledge Skills

### Design Patterns Virtuoso (26 patterns)

Covers all Gang of Four patterns plus Null Object, Object Pool, and Private Class Data — organized as creational, structural, and behavioral with PHP 8.3+ implementations.

See [skills/knowledge/design-patterns/SKILL.md](skills/knowledge/design-patterns/SKILL.md) for the full pattern index.

### Refactoring Virtuoso (89 skills)

Covers 67 refactoring techniques (composing methods, moving features, organizing data, simplifying conditionals, simplifying method calls, dealing with generalization) and 22 code smells (bloaters, OO abusers, change preventers, dispensables, couplers).

See [skills/knowledge/refactoring/SKILL.md](skills/knowledge/refactoring/SKILL.md) for the full technique and smell index.

### SOLID Virtuoso (5 principles)

Covers all five SOLID principles — Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion — with original explanations, violation detection, before/after PHP 8.3+ examples, and multi-language examples (Java, Python, TypeScript, C++).

See [skills/knowledge/solid/SKILL.md](skills/knowledge/solid/SKILL.md) for the full principle index.

### Debugging

Systematic debugging methodology — root cause analysis, bug category strategies (logic, data, state, integration, performance, environment, intermittent), evidence-based diagnosis, escalation criteria, and post-mortem templates. Stack-agnostic.

See [skills/knowledge/debugging/SKILL.md](skills/knowledge/debugging/SKILL.md) for the full methodology.

### Clean Architecture

Clean Architecture, Hexagonal Architecture (Ports & Adapters), and Domain-Driven Design fundamentals — dependency rules, layer responsibilities, DDD tactical patterns (entities, value objects, aggregates, repositories, domain services), and context mapping strategies. Stack-agnostic.

See [skills/knowledge/clean-architecture/SKILL.md](skills/knowledge/clean-architecture/SKILL.md) for the full architecture guide.

### Testing

Testing methodology and strategy — testing pyramid, TDD schools (London mock-based and Chicago state-based), test doubles taxonomy (dummy, stub, spy, mock, fake), and testing strategies by architectural layer (unit, integration, e2e, contract). Stack-agnostic.

See [skills/knowledge/testing/SKILL.md](skills/knowledge/testing/SKILL.md) for the full testing guide.

### API Design

REST and GraphQL API design principles — resource modeling, URL structure, HTTP method semantics, versioning strategies, pagination patterns, error handling, GraphQL schema design, query optimization, and API evolution strategies including backwards-compatible changes and deprecation workflows. Stack-agnostic.

See [skills/knowledge/api-design/SKILL.md](skills/knowledge/api-design/SKILL.md) for the full API design guide.

### Security

Application security fundamentals — OWASP Top 10 vulnerabilities with detection and prevention, authentication and authorization patterns (session-based, JWT, OAuth 2.0, RBAC, ABAC), and secure coding practices including input validation, output encoding, cryptography, secrets management, and security headers. Stack-agnostic.

See [skills/knowledge/security/SKILL.md](skills/knowledge/security/SKILL.md) for the full security guide.

---

## Setup Skills

### Agentic Rules Writer

Generate a rules file for any AI coding agent at global, project team-shared, or project dev-specific scope. Runs an interactive questionnaire about your workflow preferences, scans installed skills at runtime, and writes a tailored instruction file in the correct format and location for Claude Code, Cursor, Windsurf, GitHub Copilot, Gemini CLI, Roo Code, or Amp.

See [skills/setup/agentic-rules-writer/SKILL.md](skills/setup/agentic-rules-writer/SKILL.md) for the full interactive flow.

---

## Framework Skills

### Symfony Virtuoso (38 components)

Covers all Symfony components — HTTP handling, dependency injection, forms, validation, caching, messaging, console commands, event dispatching, workflows, serialization, testing, filesystem operations, configuration, and utility components. PHP 8.3+ and Symfony 7.x.

See [skills/frameworks/php/symfony/SKILL.md](skills/frameworks/php/symfony/SKILL.md) for the full component index.

---

## Installation

Clone (or add as a submodule) and copy the skills you need into the location your tool expects.

```bash
git clone https://github.com/krzysztofsurdy/code-virtuoso.git
```

### Claude Code

**Via plugin marketplace (recommended):**

```bash
# Add the marketplace
/plugin marketplace add krzysztofsurdy/code-virtuoso

# Bundle installs (recommended)
/plugin install knowledge-virtuoso@krzysztofsurdy-code-virtuoso
/plugin install setup-rules-writer@krzysztofsurdy-code-virtuoso
/plugin install symfony-virtuoso@krzysztofsurdy-code-virtuoso

# Or install individually
/plugin install knowledge-design-patterns@krzysztofsurdy-code-virtuoso
/plugin install knowledge-refactoring@krzysztofsurdy-code-virtuoso
/plugin install knowledge-solid@krzysztofsurdy-code-virtuoso
/plugin install knowledge-debugging@krzysztofsurdy-code-virtuoso
/plugin install knowledge-clean-architecture@krzysztofsurdy-code-virtuoso
/plugin install knowledge-testing@krzysztofsurdy-code-virtuoso
/plugin install knowledge-api-design@krzysztofsurdy-code-virtuoso
/plugin install knowledge-security@krzysztofsurdy-code-virtuoso
```

Or browse interactively: run `/plugin`, go to **Discover**, and install individual plugins.

**Manual install:**

```bash
# Project-level (committed to your repo)
cp -r code-virtuoso/skills/knowledge/design-patterns .claude/skills/

# User-level (available in all projects)
cp -r code-virtuoso/skills/knowledge/design-patterns ~/.claude/skills/
```

Skills are discovered automatically — just mention a component in conversation.

### OpenAI Codex CLI

```bash
cp -r code-virtuoso/skills/knowledge/design-patterns .codex/skills/
```

### Gemini CLI

```bash
cat code-virtuoso/skills/knowledge/design-patterns/SKILL.md >> GEMINI.md
```

### GitHub Copilot

```bash
mkdir -p .github/instructions
cp code-virtuoso/skills/knowledge/design-patterns/SKILL.md .github/instructions/design-patterns.instructions.md
```

### Amp / OpenCode / Kimi

```bash
cp -r code-virtuoso/skills/knowledge/design-patterns .agents/skills/
cp -r code-virtuoso/skills/knowledge/refactoring .agents/skills/
```

### Cursor

```bash
mkdir -p .cursor/rules
cp code-virtuoso/skills/knowledge/design-patterns/SKILL.md .cursor/rules/design-patterns.mdc
```

### Windsurf

```bash
mkdir -p .windsurf/rules
cp code-virtuoso/skills/knowledge/design-patterns/SKILL.md .windsurf/rules/design-patterns.md
```

## Repository Structure

```
code-virtuoso/
├── skills/
│   ├── knowledge/
│   │   ├── design-patterns/
│   │   │   ├── SKILL.md           # Overview + pattern index
│   │   │   └── references/        # 26 individual pattern docs
│   │   ├── refactoring/
│   │   │   ├── SKILL.md           # Overview + technique/smell index
│   │   │   └── references/        # 89 individual technique/smell docs
│   │   ├── solid/
│   │   │   ├── SKILL.md           # Overview + principle index
│   │   │   └── references/        # 5 individual principle docs
│   │   ├── debugging/
│   │   │   ├── SKILL.md           # Systematic debugging methodology
│   │   │   └── references/        # Bug categories + post-mortem template
│   │   ├── clean-architecture/
│   │   │   ├── SKILL.md           # Clean/Hexagonal Architecture + DDD
│   │   │   └── references/        # Layers, DDD patterns, context mapping
│   │   ├── testing/
│   │   │   ├── SKILL.md           # Testing methodology + TDD schools
│   │   │   └── references/        # Test doubles, TDD schools, strategies
│   │   ├── api-design/
│   │   │   ├── SKILL.md           # REST + GraphQL API design
│   │   │   └── references/        # REST patterns, GraphQL, API evolution
│   │   └── security/
│   │       ├── SKILL.md           # Application security fundamentals
│   │       └── references/        # OWASP Top 10, auth patterns, secure coding
│   ├── setup/
│   │   └── agentic-rules-writer/
│   │       ├── SKILL.md           # Interactive rules file generator
│   │       └── references/        # Questionnaire + agent targets
│   └── frameworks/
│       └── php/
│           └── symfony/
│               ├── SKILL.md       # Overview + component index
│               └── references/    # 38 individual component docs
├── spec/
│   └── agent-skills-spec.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Recommended Companion Tools

These tools pair well with Code Virtuoso skills to give your AI coding agent structured memory and efficient codebase navigation.

### Beads — Task Memory for AI Agents

[github.com/steveyegge/beads](https://github.com/steveyegge/beads)

A distributed, git-backed graph issue tracker that gives AI agents persistent, structured memory for long-horizon tasks. Replaces ad-hoc markdown planning files with a dependency-aware task graph stored in a version-controlled database.

- **Dependency tracking** — tasks can block other tasks; `bd next` finds ready-to-work items
- **Hierarchical structure** — epics, tasks, and subtasks
- **Memory compaction** — summarizes completed tasks to conserve context window
- **Git-backed** — task data is version-controlled alongside your code

Install system-wide via npm, Homebrew, or Go. Initialize per-project with `bd init`.

### Grepika — Token-Efficient Code Search

[github.com/agentika-labs/grepika](https://github.com/agentika-labs/grepika)

An MCP server that replaces built-in grep/file search with ranked, compact results using ~80% fewer tokens. Combines FTS5 full-text search, parallel grep, and trigram indexing with BM25 ranking.

- **11 specialized tools** — search, refs, outline, context, get, toc, stats, index, diff, add_workspace
- **Smart query routing** — auto-detects regex, natural language, or symbol lookups
- **2.3–2.8ms search latency** after indexing
- **Non-invasive** — indexes stored in system cache, not in your project

Works with Claude Code, Cursor, and OpenCode as an MCP server.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding or improving skills.

## License

MIT
