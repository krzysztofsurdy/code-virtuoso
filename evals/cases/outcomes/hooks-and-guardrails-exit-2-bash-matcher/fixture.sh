#!/usr/bin/env bash
set -euo pipefail
mkdir -p .claude/hooks
cat > .claude/settings.json <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read",
        "hooks": [
          { "type": "command", "command": "./.claude/hooks/block-env.sh" }
        ]
      }
    ]
  }
}
JSON
cat > .claude/hooks/block-env.sh <<'BASH'
#!/usr/bin/env bash
input=$(cat)
path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
case "$path" in
  *.env|*.env.*)
    echo "Blocked: .env files are off limits"
    exit 1
    ;;
esac
exit 0
BASH
chmod +x .claude/hooks/block-env.sh
