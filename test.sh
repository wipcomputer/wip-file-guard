#!/bin/bash
# test.sh - Test wip-file-guard hook
# Run: bash test.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GUARD="$SCRIPT_DIR/guard.mjs"
PASS=0
FAIL=0

check() {
  local desc="$1"
  local input="$2"
  local expect="$3" # "block" or "allow"

  local output
  output=$(echo "$input" | node "$GUARD" 2>/dev/null)
  local code=$?

  if [ "$expect" = "block" ]; then
    if echo "$output" | grep -q "deny"; then
      echo "PASS: $desc"
      ((PASS++))
    else
      echo "FAIL: $desc (expected block, got allow)"
      ((FAIL++))
    fi
  else
    if [ -z "$output" ] && [ $code -eq 0 ]; then
      echo "PASS: $desc"
      ((PASS++))
    else
      echo "FAIL: $desc (expected allow, got: $output)"
      ((FAIL++))
    fi
  fi
}

echo "wip-file-guard tests"
echo "==================="
echo ""

# Write tests
check "Block Write to CLAUDE.md" \
  '{"tool_name":"Write","tool_input":{"file_path":"/foo/CLAUDE.md","content":"new"}}' \
  "block"

check "Block Write to SHARED-CONTEXT.md" \
  '{"tool_name":"Write","tool_input":{"file_path":"/bar/workspace/SHARED-CONTEXT.md","content":"new"}}' \
  "block"

check "Allow Write to random file" \
  '{"tool_name":"Write","tool_input":{"file_path":"/foo/bar.js","content":"new"}}' \
  "allow"

# Edit tests - line removal
check "Block Edit removing 5 lines from CLAUDE.md" \
  '{"tool_name":"Edit","tool_input":{"file_path":"/foo/CLAUDE.md","old_string":"a\nb\nc\nd\ne\nf","new_string":"replaced"}}' \
  "block"

check "Allow Edit adding lines to CLAUDE.md" \
  '{"tool_name":"Edit","tool_input":{"file_path":"/foo/CLAUDE.md","old_string":"a","new_string":"a\nb\nc"}}' \
  "allow"

check "Allow Edit on non-protected file (even removing lines)" \
  '{"tool_name":"Edit","tool_input":{"file_path":"/foo/bar.js","old_string":"a\nb\nc\nd\ne","new_string":"x"}}' \
  "allow"

check "Allow Edit with small removal (2 lines)" \
  '{"tool_name":"Edit","tool_input":{"file_path":"/foo/SOUL.md","old_string":"a\nb\nc","new_string":"x"}}' \
  "allow"

check "Block Edit with 4 line removal from SOUL.md" \
  '{"tool_name":"Edit","tool_input":{"file_path":"/foo/SOUL.md","old_string":"a\nb\nc\nd\ne\nf","new_string":"x\ny"}}' \
  "block"

# Protected file coverage
check "Block Write to IDENTITY.md" \
  '{"tool_name":"Write","tool_input":{"file_path":"/any/path/IDENTITY.md","content":"new"}}' \
  "block"

check "Block Write to TOOLS.md" \
  '{"tool_name":"Write","tool_input":{"file_path":"/any/path/TOOLS.md","content":"new"}}' \
  "block"

# Large replacement (same line count, different content)
check "Block Edit replacing 8 lines with 8 different lines in SHARED-CONTEXT.md" \
  '{"tool_name":"Edit","tool_input":{"file_path":"/foo/SHARED-CONTEXT.md","old_string":"line1\nline2\nline3\nline4\nline5\nline6\nline7\nline8","new_string":"new1\nnew2\nnew3\nnew4\nnew5\nnew6\nnew7\nnew8"}}' \
  "block"

check "Allow Edit replacing 3 lines in CLAUDE.md" \
  '{"tool_name":"Edit","tool_input":{"file_path":"/foo/CLAUDE.md","old_string":"a\nb\nc","new_string":"x\ny\nz"}}' \
  "allow"

# Pattern matching
check "Block Write to file in memory/ directory" \
  '{"tool_name":"Write","tool_input":{"file_path":"/workspace/memory/2026-02-19.md","content":"new"}}' \
  "block"

check "Block Write to memories.md" \
  '{"tool_name":"Write","tool_input":{"file_path":"/foo/memories.md","content":"new"}}' \
  "block"

check "Block Write to journal file" \
  '{"tool_name":"Write","tool_input":{"file_path":"/docs/journals/2026-02-19-the-receipt.md","content":"new"}}' \
  "block"

check "Block Edit removing lines from daily log" \
  '{"tool_name":"Edit","tool_input":{"file_path":"/memory/daily/2026-02-19.md","old_string":"a\nb\nc\nd\ne","new_string":"x"}}' \
  "block"

check "Allow Write to unrelated file with no pattern match" \
  '{"tool_name":"Write","tool_input":{"file_path":"/src/utils/helper.js","content":"new"}}' \
  "allow"

echo ""
echo "Results: $PASS passed, $FAIL failed"
