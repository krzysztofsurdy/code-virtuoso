---
tags: [outcome, php-upgrade]
max_turns: 10
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill, Edit, Write]
---

We are bumping this app from PHP 8.4 to 8.5 and the application code is already clean after a Rector run. The only things left are the Dockerfile and docker/php.ini in this directory. Is anything in them going to break or misbehave on 8.5? Tell me exactly what to change.
