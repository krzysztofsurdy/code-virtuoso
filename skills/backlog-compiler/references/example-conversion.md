# Worked example

**Input — freeform feature request:**

> Add the ability to mark tasks with a status (pending/in progress/done), show it on each task card, let users change it, and filter the list by it. Project uses PHPUnit and PHPStan; tests live in `tests/`.

**Output — `.delivery-loop/backlog.json`:**

```json
{
  "project": "TaskApp",
  "branch": "loop/task-status",
  "description": "Track task progress with a status field, badge, toggle, and filter",
  "config": {
    "maxIterations": 20,
    "maxAttemptsPerItem": 3,
    "maxStallIterations": 3,
    "maxViolations": 3,
    "protectedPaths": ["tests/**", "phpunit.xml*"],
    "permissionMode": "acceptEdits",
    "allowedTools": ["Read", "Edit", "Write", "Glob", "Grep",
      "Bash(composer *)", "Bash(vendor/bin/* *)", "Bash(bin/console *)", "Bash(php *)",
      "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)", "Bash(git add *)", "Bash(git commit *)"],
    "totalBudgetUsd": null,
    "perIterationBudgetUsd": null,
    "perIterationMaxTurns": 40
  },
  "items": [
    {
      "id": "ITEM-001",
      "title": "Add status column to tasks table",
      "description": "As a developer, I need to persist task status in the database.",
      "acceptanceCriteria": [
        "Add `status` column: enum pending|in_progress|done, default 'pending'",
        "Migration runs cleanly against a fresh database"
      ],
      "priority": 1,
      "steps": [
        {
          "id": "implement",
          "instructions": "Add the status column and its migration.",
          "verifyCommand": "vendor/bin/phpunit --filter=TaskStatusMigrationTest && vendor/bin/phpstan analyse",
          "status": "pending",
          "attempts": 0,
          "notes": ""
        }
      ]
    },
    {
      "id": "ITEM-002",
      "title": "Display status badge on task cards",
      "description": "As a user, I want to see task status at a glance.",
      "acceptanceCriteria": [
        "Each task card renders a status badge",
        "Badge label matches the task's status field exactly"
      ],
      "priority": 2,
      "steps": [
        {
          "id": "implement",
          "instructions": "Render a status badge on each task card.",
          "verifyCommand": "vendor/bin/phpunit --filter=TaskCardStatusBadgeTest && vendor/bin/phpstan analyse",
          "status": "pending",
          "attempts": 0,
          "notes": ""
        }
      ]
    },
    {
      "id": "ITEM-003",
      "title": "Add status toggle to task rows",
      "description": "As a user, I want to change a task's status from the list.",
      "acceptanceCriteria": [
        "Each row has a status control",
        "Changing it persists immediately and the new value round-trips"
      ],
      "priority": 3,
      "steps": [
        {
          "id": "implement",
          "instructions": "Add a status control to each row and persist changes.",
          "verifyCommand": "vendor/bin/phpunit --filter=TaskStatusToggleTest && vendor/bin/phpstan analyse",
          "status": "pending",
          "attempts": 0,
          "notes": ""
        }
      ]
    },
    {
      "id": "ITEM-004",
      "title": "Filter task list by status",
      "description": "As a user, I want to see only tasks in a given status.",
      "acceptanceCriteria": [
        "Filter accepts all|pending|in_progress|done",
        "Filtered results contain only matching-status tasks"
      ],
      "priority": 4,
      "steps": [
        {
          "id": "implement",
          "instructions": "Add a status filter to the task list.",
          "verifyCommand": "vendor/bin/phpunit --filter=TaskStatusFilterTest && vendor/bin/phpstan analyse",
          "status": "pending",
          "attempts": 0,
          "notes": ""
        }
      ]
    }
  ]
}
```

Note the dependency order (schema → display → mutation → filtering) and that every criterion maps to something a step's `verifyCommand` actually checks — no item's "done" depends on a model's opinion.

Each item here is a single step, the common case. To add an independent review phase, you'd give an item a second step — e.g. an `implement` step run by a `backend-dev` participant followed by a `review` step run by a `qa-reviewer` persona — each with its own `verifyCommand`. See `references/teams-and-participants.md`.
