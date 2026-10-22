# Research notes template

Fill this in during Phase 0 and keep it with the work. Headings and the table below are the contract. Delete guidance text once filled.

```markdown
# Research notes: <skill topic>

Date: <YYYY-MM-DD>
Depth: quick | standard | deep
Research skill used: yes | no (inline) | skipped at user request
Prior-art search: done | local only | skipped at user request

## Scope

What the skill covers, what it does not, and the questions the research answered.

## Sources

| Source | Tier | Publisher | Published | Retrieved |
|---|---|---|---|---|
| <URL or local path> | official / standard / vendor / practitioner / community / local | <name> | <date or unknown> | <date> |

## Prior art

Queries run (commands and search terms), so the search can be repeated. One row per candidate, 3 to 5 candidates, read from the actual SKILL.md. See [prior-art.md](prior-art.md).

| Name | Source URL | Maintainer | Adoption and last update | Scope | Does well | Gets wrong or misses | License |
|---|---|---|---|---|---|---|---|
| <owner/repo@skill> | <URL of the SKILL.md> | official / community | <stars or installs>, <YYYY-MM-DD> | <what it covers> | <specific strengths> | <stale facts, too long, textbook content, weak triggers, no verification, platform lock-in> | <SPDX id, per skill, or none stated> |

Decision: install or extend `<candidate>` and stop | extend a local skill | write a new skill | nothing relevant found.

If writing a new skill: strengths adopted (idea and candidate named), weaknesses avoided, and the gap this skill fills. No text was copied.

## Fact ledger

One row for every checkable claim that will land in the skill.

| # | Claim | Source URL | Retrieved | Version | Confidence | Verified by |
|---|---|---|---|---|---|---|
| 1 | <API name, flag, version, limit, URL, command, or number> | <URL> | <date> | <version or n/a> | confirmed / likely / single-source / unverified | <read page, ran command, second source> |

## Not confirmed

Claims that stayed unverified, each with the reason and what was done: cut, rewritten as "check the official page" with a link, or kept marked (unverified).

## Left out

What was found but not put in the skill, and why (the agent already knows it, volatile, off scope).
```

## Confidence labels

| Label | Meaning |
|---|---|
| confirmed | A primary source plus an independent second source, or reproduced by running it |
| likely | One primary source, or several consistent secondary sources |
| single-source | Only one source found, and it is not primary |
| unverified | No usable source. Cut it, link the official page, or mark it in the skill text |

Independent means the sources do not trace back to the same original. A claim with no row in the ledger does not go in the skill.
