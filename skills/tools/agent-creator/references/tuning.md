# Agent Tuning Pattern

## Contents

- [When to add tuning](#when-to-add-tuning)
- [How to implement](#how-to-implement)
- [Config format](#config-format)
- [Setup and scope](#setup-and-scope)
- [Rules](#rules)

Tuning lets agents adapt to team preferences without modifying the agent definition itself. Settings live in the layered Code Virtuoso config, under `agents.<agent-name>`. The agent reads them and never asks the user, because a subagent cannot prompt. A setup run in the main session asks the questions and writes the answers. The storage rules (paths, layers, precedence, secrets) are in [spec/config-spec.md](../../../../spec/config-spec.md).

Do not save settings next to the agent file. In a plugin install that directory is a version cache that is replaced on update, and in a skills.sh install it is deleted on reinstall.

## When to add tuning

Add tuning when an agent has 3+ behavioral knobs that different teams would reasonably set differently. Examples:

- A reviewer that some teams want deep and others want surface-level
- An architect that some teams want ADRs from and others want lightweight notes
- A product manager that some teams run with MoSCoW and others with RICE

Do not add tuning when:
- The agent's behavior is fixed by design (investigator, cold-reviewer)
- The "knobs" only reflect the agent handling each input differently
- There are fewer than 3 meaningful settings

## How to implement

### 1. Add a Tuning section to the agent body

State how the agent reads its settings, then list each knob with its camelCase key, options, default, and what it affects. The defaults table is the first layer of the config, so keep it complete.

```markdown
## Tuning

Read `agents.reviewer` from the layered Code Virtuoso config. Never ask the user.
Use the default below for any missing key.

1. Find the project root (`git rev-parse --show-toplevel`, else the current directory).
2. Read these files in order and skip any that do not exist: the user file
   (`$CODE_VIRTUOSO_CONFIG_HOME/config.json`, else
   `${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso/config.json`),
   `<project root>/.code-virtuoso/config.json`,
   `<project root>/.code-virtuoso/config.local.json`.
3. Merge them with later files winning. Objects merge key by key, and lists and
   single values replace.
4. Take the `agents.reviewer` object from the result.

If any key was missing, end the report with: `Defaults used for: <keys>. Run setup to save them.`

| Setting | Options | Default | Effect |
|---|---|---|---|
| `reviewDepth` | surface, standard, deep | standard | How many review categories to check |
| `severityThreshold` | all, warnings-and-above, critical-only | all | Minimum severity to report |
| `styleFeedback` | yes, no | no | Whether to include style/formatting findings |
```

### 2. Add config loading to Process step 1

```markdown
## Process

1. **Load preferences**: read `agents.reviewer` from the layered config (see
   Tuning). Never ask the user. Use the default for any missing key.
2. [rest of process...]
```

### 3. Reference settings throughout

Use the config key names in the process and rules:

```markdown
3. **Analyze**: check each category in the review checklist. If `reviewDepth`
   is `surface`, focus on correctness and security only. If `deep`, include all
   categories plus cross-cutting concerns.
```

## Config format

Settings are plain JSON values in the `agents.<agent-name>` object. The same file can hold other namespaces, so writers keep every key they do not own.

```json
{
  "version": 1,
  "agents": {
    "reviewer": {
      "reviewDepth": "standard",
      "severityThreshold": "all",
      "styleFeedback": "no",
      "frameworkContext": "symfony"
    }
  }
}
```

## Setup and scope

Setup runs in the main session (the orchestrator or the user's own session), never inside the agent. Each question is tagged with a scope, and the answer goes to that layer:

| Scope | File | Use for |
|---|---|---|
| `project` | `<project root>/.code-virtuoso/config.json` (committed) | Choices the team shares, such as review depth or ADR format |
| `user` | `$CODE_VIRTUOSO_CONFIG_HOME/config.json`, else `${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso/config.json` | Personal choices, such as coaching intensity |

After writing, show the user the path of the file written. Legacy `.<agent>.tune.md` files are imported once by the setup step, into the user layer, and then left in place for the user to delete. Legacy keys are converted from `UPPER_SNAKE` to camelCase (`REVIEW_DEPTH` becomes `reviewDepth`).

## Rules

- Never store tuning next to the agent file or in the plugin data directory
- The agent never prompts. Missing keys use the documented defaults, and the report ends with the "Defaults used for" line
- Never force tuning. If the user declines to answer during setup, save nothing and let the defaults apply
- Ask 3-5 questions at most. More is a configuration burden.
- Settings should be stable across sessions. Anything that changes per task is an input parameter, not a tuning knob.
- Never store secrets in the config. Writers reject keys that match token, secret, password, or apikey.
