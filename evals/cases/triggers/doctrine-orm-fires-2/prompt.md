---
tags: [trigger, doctrine-orm]
max_turns: 6
allowed_tools: [Read, Glob, Grep, Skill]
---

Our Messenger worker runs fine for hours, then after one failed message every following message dies with "The EntityManager is closed". We are on Symfony 7.4 with Doctrine ORM 3. What should I change in the bus config?
