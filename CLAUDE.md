# Code Virtuoso - Claude Code Instructions

@AGENTS.md

This file contains Claude Code specific optimizations. For general agent architecture and contribution guidelines, see the included files above.

## Claude Code Tool Mapping

Map the generic tool categories used in agent definitions to Claude Code tools:

| Generic Category | Claude Code Tool |
|---|---|
| File reading | `Read` |
| Code search | `Grep`, `Glob` |
| Shell | `Bash` |
| File editing | `Edit`, `Write` |

## Skill Research Process

When creating a new skill in this project:

1. **Search skills.sh** for existing skills: `npx skills find "{topic}"`
2. **Fetch skill details** from skills.sh URLs to understand what others have built
3. **Search the web** for official documentation, best practices, and community guides
4. **Use parallel research agents** to gather information on multiple subtopics simultaneously
5. **Read existing skills** in this project to match the structure and depth

## Marketplace Configuration

File: `.claude-plugin/marketplace.json`

**MANDATORY:** Any change to skills MUST include a marketplace.json update. This is non-negotiable.

- When adding a new skill: update skill paths in the appropriate plugin, bump **minor** version
- When updating an existing skill's content: bump **patch** version
- When renaming skills, reorganizing directories, or changing plugin structure: bump **major** version
- Also update README.md skill tables and repository structure when adding/renaming/moving skills

## Commit Conventions

- No AI co-author lines in commits
- Descriptive commit messages summarizing what was added/changed

## Resources

Reference documentation for the skills ecosystem and agent architecture:

- [Agent Skills Open Standard](https://agentskills.io) - cross-platform skill standard
- [Vercel Agent Skills](https://github.com/vercel-labs/skills/tree/main) - example skills from Vercel Labs
- [Anthropic Skills](https://github.com/anthropics/skills) - official Anthropic skills repository
- [Claude Code Skills Docs](https://code.claude.com/docs/en/skills) - how skills work in Claude Code
- [Claude Code Sub-Agents Docs](https://code.claude.com/docs/en/sub-agents) - sub-agent architecture and patterns
