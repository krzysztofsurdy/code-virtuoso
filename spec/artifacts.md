# Artifact Specification

Artifacts are the structured outputs that agents produce and the structured inputs they consume. This spec defines standard artifact types so agents can declare explicit handoff contracts via `expects` and `produces` frontmatter fields.

Artifact types are conventions, not file formats. The agent producing an artifact writes it in its Output section. The consuming agent reads it as part of its Input. There is no runtime enforcement - these contracts exist so orchestrators and teams can validate that the output of one agent matches the expected input of the next.

## Artifact catalog

| Artifact | What it contains | Typical producer | Typical consumer |
|---|---|---|---|
| `investigation-report` | Entry points, code flow traces, dependency map, observations | investigator | architect, implementer |
| `architecture-decision` | Context, decision, alternatives considered, consequences | architect | backend-dev, frontend-dev, implementer |
| `requirements-spec` | Problem, goals, acceptance criteria, non-goals, constraints | product-manager | architect, qa-engineer, acceptance-verifier |
| `review-report` | Scope, verdict, severity-ranked findings, strengths | reviewer, cold-reviewer, acceptance-verifier | implementer |
| `smell-report` | Hotspot locations, smell classifications, refactoring recommendations | refactor-scout | reviewer, implementer |
| `test-plan` | Risk areas, test cases, coverage criteria, sign-off conditions | qa-engineer | implementer, reviewer |
| `test-gap-report` | Missing tests by priority, source-to-test file map | test-gap-analyzer | implementer |
| `migration-plan` | Risk classification per operation, execution steps, rollback paths | migration-planner | implementer, reviewer |

## Using contracts

### In agent frontmatter

Agents declare what they expect and produce using optional `expects` and `produces` fields:

```yaml
---
name: architect
expects:
  - investigation-report
  - requirements-spec
produces:
  - architecture-decision
---
```

Both fields are lists of artifact type names from the catalog above. Agents may also use custom artifact types not in this catalog.

### In teams

Teams use contracts to validate their workflow: the `produces` of phase N should match the `expects` of phase N+1. When reviewing a team definition, check that the chain is consistent.

### Graceful degradation

Agents should handle missing artifacts gracefully. If an agent expects an `investigation-report` but receives raw text or a verbal description instead, it proceeds with a note: "Expected structured investigation report. Proceeding with available context." The contract is a signal for orchestrators, not a hard gate.

## Adding new artifact types

If an agent produces output that does not fit any existing type:

1. Check whether an existing type covers it with a broader name
2. If genuinely new, add a row to the catalog table above
3. The type name should be kebab-case and describe the content, not the producer (e.g., `migration-plan` not `migration-planner-output`)
4. Update any agents that would naturally produce or consume the new type

## Portability

The `expects` and `produces` fields are portable across agent platforms. They carry no platform-specific semantics - they are documentation that any orchestrator can read and act on.
