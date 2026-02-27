# Code Virtuoso

AI agent skill sets for **Design Patterns**, **Refactoring**, and **SOLID Principles** — built on the [Agent Skills](https://agentskills.io) open standard.

Each plugin is a single consolidated skill with an overview SKILL.md and individual reference files for progressive disclosure. AI agents get the index automatically and load detailed references on demand.

> **Looking for Symfony?** See [symfony-virtuoso](https://github.com/krzysztofsurdy/symfony-virtuoso).

## Plugins

### Design Patterns Virtuoso (26 patterns)

Covers all Gang of Four patterns plus Null Object, Object Pool, and Private Class Data — organized as creational, structural, and behavioral with PHP 8.3+ implementations.

See [skills/design-patterns/SKILL.md](skills/design-patterns/SKILL.md) for the full pattern index.

### Refactoring Virtuoso (89 skills)

Covers 67 refactoring techniques (composing methods, moving features, organizing data, simplifying conditionals, simplifying method calls, dealing with generalization) and 22 code smells (bloaters, OO abusers, change preventers, dispensables, couplers).

See [skills/refactoring/SKILL.md](skills/refactoring/SKILL.md) for the full technique and smell index.

### SOLID Virtuoso (5 principles)

Covers all five SOLID principles — Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion — with original explanations, violation detection, before/after PHP 8.3+ examples, and multi-language examples (Java, Python, TypeScript, C++).

See [skills/solid/SKILL.md](skills/solid/SKILL.md) for the full principle index.

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

# Install a specific plugin
/plugin install design-patterns-virtuoso@krzysztofsurdy-code-virtuoso
/plugin install refactoring-virtuoso@krzysztofsurdy-code-virtuoso
/plugin install solid-virtuoso@krzysztofsurdy-code-virtuoso
```

Or browse interactively: run `/plugin`, go to **Discover**, and install individual plugins.

**Manual install:**

```bash
# Project-level (committed to your repo)
cp -r code-virtuoso/skills/design-patterns .claude/skills/
cp -r code-virtuoso/skills/refactoring .claude/skills/

# User-level (available in all projects)
```

Skills are discovered automatically — just mention a component in conversation.

### OpenAI Codex CLI

```bash
cp -r code-virtuoso/skills/design-patterns .codex/skills/
```

### Gemini CLI

```bash
cat code-virtuoso/skills/design-patterns/SKILL.md >> GEMINI.md
```

### GitHub Copilot

```bash
mkdir -p .github/instructions
cp code-virtuoso/skills/design-patterns/SKILL.md .github/instructions/design-patterns.instructions.md
```

### Amp / OpenCode / Kimi

```bash
cp -r code-virtuoso/skills/design-patterns .agents/skills/
cp -r code-virtuoso/skills/refactoring .agents/skills/
```

### Cursor

```bash
mkdir -p .cursor/rules
cp code-virtuoso/skills/design-patterns/SKILL.md .cursor/rules/design-patterns.mdc
```

### Windsurf

```bash
mkdir -p .windsurf/rules
cp code-virtuoso/skills/design-patterns/SKILL.md .windsurf/rules/design-patterns.md
```

## Repository Structure

```
code-virtuoso/
├── skills/
│   ├── design-patterns/
│   │   ├── SKILL.md              # Overview + pattern index
│   │   └── references/           # 26 individual pattern docs
│   ├── refactoring/
│   │   ├── SKILL.md              # Overview + technique/smell index
│   │   └── references/           # 89 individual technique/smell docs
│   └── solid/
│       ├── SKILL.md              # Overview + principle index
│       └── references/           # 5 individual principle docs
├── spec/
│   └── agent-skills-spec.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding or improving skills.

## License

MIT
