---
tags: [outcome, symfony-upgrade]
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill]
---

Our Docker image is pinned to php:8.4.0-fpm-alpine and the app is on Symfony 7.4.3. We want to go straight to Symfony 8.1 by changing only the symfony/* constraints in composer.json. Will composer install work with our PHP image? Give me the steps in the order you would do them.
