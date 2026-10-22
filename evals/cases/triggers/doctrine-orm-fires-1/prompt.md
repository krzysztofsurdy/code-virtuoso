---
tags: [trigger, doctrine-orm]
max_turns: 6
allowed_tools: [Read, Glob, Grep, Skill]
---

The orders list page in our Symfony 7.4 app fires about 300 queries, I think it is N+1 on the customer and items relations. Should I just set those relations to fetch EAGER in the entity mapping, or is there a better fix?
