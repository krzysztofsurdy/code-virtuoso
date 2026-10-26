---
tags: [outcome, composer-dependencies]
max_turns: 10
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill, Edit, Write]
---

We are on Composer 2.10. Our CI `composer audit` fails on the abandoned package acme/legacy-lib (replacement is planned next quarter) and on advisory PKSA-7k2m-9x4q-1b3d, which our code cannot reach. We also want `composer update` and `composer require` to refuse any new package that is abandoned or has a known advisory. Fix the config block in composer.json, record a reason for each exception, and paste the final config block in your answer.
