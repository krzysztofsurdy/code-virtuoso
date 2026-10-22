---
tags: [trigger, php-quality]
max_turns: 6
allowed_tools: [Read, Glob, Grep, Skill]
---

Our phpstan.neon is at level 6 and CI is green. We want to move to the strictest level PHPStan has, but that shows about 400 new errors. How do we set that up without blocking the team?
