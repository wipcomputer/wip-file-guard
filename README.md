###### WIP Computer
# File Guard

PreToolUse hook that blocks destructive edits to protected files. When an AI agent tries to overwrite or strip content from files like CLAUDE.md, SHARED-CONTEXT.md, or SOUL.md... it gets blocked with a clear explanation of what went wrong.

## The Problem

AI agents replace content instead of extending it. After context compaction, behavioral rules like "don't delete things" vanish. The agent rewrites your CLAUDE.md, strips 30 lines from SHARED-CONTEXT.md, or replaces your SOUL.md with a shorter version. Every time.

File Guard is a technical guardrail. It doesn't ask the agent to be careful. It blocks the operation before it happens.

## How It Works

Two rules:

1. **Write is blocked** on protected files. Always. Use Edit instead.
2. **Edit is blocked** when it removes more than 2 net lines from a protected file.

The agent gets a deny message explaining what happened and telling it to re-read the file and add content instead of replacing it.

### Protected Files

| File | What it protects |
|------|-----------------|
| `CLAUDE.md` | Project instructions, boot sequence, system docs |
| `SHARED-CONTEXT.md` | Cross-agent shared state |
| `SOUL.md` | Agent identity |
| `IDENTITY.md` | Agent identity (alternate format) |
| `CONTEXT.md` | Current state snapshot |
| `TOOLS.md` | Tool and workflow rules |
| `MEMORY.md` | Persistent memory and preferences |

## Install

### For AI Agents

Open your AI coding tool and say:

```
Clone wipcomputer/wip-file-guard and install it as a PreToolUse hook.
```

Your agent will clone the repo, read this README, and configure the hook in your settings. That's it.

### Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "node \"/path/to/wip-file-guard/guard.mjs\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Replace `/path/to/wip-file-guard/` with where you cloned the repo.

### OpenClaw

Add to your OpenClaw installation's `extensions/` directory:

```bash
cp -r wip-file-guard ~/.openclaw/extensions/wip-file-guard
```

The `openclaw.plugin.json` registers a `before_tool_use` lifecycle hook that applies the same rules.

### CLI

```bash
# List protected files
node guard.mjs --list

# Test the guard with a simulated input
echo '{"tool_name":"Write","tool_input":{"file_path":"/foo/CLAUDE.md"}}' | node guard.mjs

# Run the test suite
bash test.sh
```

## Four Doors

This tool follows the WIP.computer four-door architecture. One core, four interfaces.

| Door | File | What it does |
|------|------|-------------|
| **Core** | `guard.mjs` | Pure guard logic. Reads stdin JSON, decides allow/deny. |
| **Claude Code** | `guard.mjs` (PreToolUse hook) | Hooks into CC's PreToolUse event. Blocks before the edit happens. |
| **OpenClaw** | `openclaw.plugin.json` | Lifecycle hook for OpenClaw agents. Same rules, different runtime. |
| **CLI** | `guard.mjs --list`, `test.sh` | Testing and inspection from the command line. |

## Customization

### Adding Protected Files

Edit the `PROTECTED` set in `guard.mjs`:

```javascript
const PROTECTED = new Set([
  'CLAUDE.md',
  'SHARED-CONTEXT.md',
  'SOUL.md',
  'IDENTITY.md',
  'CONTEXT.md',
  'TOOLS.md',
  'MEMORY.md',
  'YOUR-FILE-HERE.md',   // add yours
]);
```

### Changing the Line Threshold

The default blocks edits that remove more than 2 net lines. Change the threshold in the Edit handler:

```javascript
if (removed > 2) {   // change 2 to your threshold
```

## Tests

```bash
bash test.sh
```

```
wip-file-guard tests
===================

PASS: Block Write to CLAUDE.md
PASS: Block Write to SHARED-CONTEXT.md
PASS: Allow Write to random file
PASS: Block Edit removing 5 lines from CLAUDE.md
PASS: Allow Edit adding lines to CLAUDE.md
PASS: Allow Edit on non-protected file (even removing lines)
PASS: Allow Edit with small removal (2 lines)
PASS: Block Edit with 4 line removal from SOUL.md
PASS: Block Write to IDENTITY.md
PASS: Block Write to TOOLS.md

Results: 10 passed, 0 failed
```

## Why This Exists

Context compaction erases behavioral rules. An agent that was told "never delete content from CLAUDE.md" forgets that instruction after compaction. It then proceeds to replace 50 lines with 10, confident it's improving the file.

This happened five times in one session. The fix isn't better prompting. It's a hook that blocks the operation before it executes. Behavioral rules degrade. Technical guards don't.

---

## License

MIT

Built by Parker Todd Brooks, with Claude Code and Lēsa (OpenClaw).
