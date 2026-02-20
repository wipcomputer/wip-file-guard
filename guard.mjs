#!/usr/bin/env node
// cc-file-guard/guard.mjs
// PreToolUse hook for Claude Code.
// Blocks destructive edits to protected files.
// - Blocks Write tool on protected files entirely
// - Blocks Edit when net line removal > 2 lines

import { basename } from 'node:path';

const PROTECTED = new Set([
  'CLAUDE.md',
  'SHARED-CONTEXT.md',
  'SOUL.md',
  'IDENTITY.md',
  'CONTEXT.md',
  'TOOLS.md',
  'MEMORY.md',
]);

function deny(reason) {
  const output = {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: reason,
    },
  };
  process.stdout.write(JSON.stringify(output));
}

function countLines(str) {
  if (!str) return 0;
  return str.split('\n').length;
}

async function main() {
  let raw = '';
  for await (const chunk of process.stdin) {
    raw += chunk;
  }

  let input;
  try {
    input = JSON.parse(raw);
  } catch {
    // Can't parse input, allow by default
    process.exit(0);
  }

  const toolName = input.tool_name || '';
  const toolInput = input.tool_input || {};
  const filePath = toolInput.file_path || toolInput.filePath || '';
  const fileName = basename(filePath);

  // Only check protected files
  if (!PROTECTED.has(fileName)) {
    process.exit(0);
  }

  // Block Write on protected files
  if (toolName === 'Write') {
    deny(`BLOCKED: Write tool on ${fileName} is not allowed. Use Edit to make specific changes. Never overwrite protected files.`);
    process.exit(0);
  }

  // For Edit, check line removal
  if (toolName === 'Edit') {
    const oldString = toolInput.old_string || '';
    const newString = toolInput.new_string || '';
    const oldLines = countLines(oldString);
    const newLines = countLines(newString);
    const removed = oldLines - newLines;

    if (removed > 2) {
      deny(`BLOCKED: You are removing ${removed} lines from ${fileName} (old: ${oldLines} lines, new: ${newLines} lines). Re-read the file and add content instead of replacing it.`);
      process.exit(0);
    }
  }

  // Allow
  process.exit(0);
}

main().catch(() => process.exit(0));
