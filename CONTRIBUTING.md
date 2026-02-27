# Contributing to Code Virtuoso

## Structure

Each plugin is a single consolidated skill with an overview `SKILL.md` and individual reference files in `references/`.

```
skills/<plugin>/
├── SKILL.md              # Overview, index, quick patterns
└── references/
    └── <topic>.md        # One file per component/pattern/technique
```

## Adding a New Reference

1. Create `skills/<plugin>/references/<name>.md` with the component/pattern/technique documentation
2. Add an entry to the corresponding `SKILL.md` index with a link to the reference file
3. No frontmatter in reference files — only the `SKILL.md` has frontmatter

## Improving Existing Documentation

Edit the relevant `references/*.md` file directly.

## Content Guidelines

- Target PHP 8.3+ and Symfony 7.x (for Symfony skills)
- Use strict typing in all code examples (`declare(strict_types=1)`)
- Show realistic, production-quality code — not toy examples
- Include both the "happy path" and error handling where relevant
- Reference official documentation where appropriate
- Keep instructions actionable — tell the agent what to do, not just what exists

## Format Specification

Skills follow the [Agent Skills standard](https://agentskills.io/specification).

Key rules:
- `SKILL.md` frontmatter: `name` must be lowercase, `description` under 1024 chars
- Keep `SKILL.md` under 500 lines — use `references/` for detailed content
- Reference files do not have frontmatter
