#!/usr/bin/env bash
set -euo pipefail

# Runs the prompt against this repo's own config + scripts, without installing.
# OMS_DIR points at ./scripts so the custom git modules resolve locally.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OMS_DIR="$SCRIPT_DIR/scripts"
export STARSHIP_CONFIG="$SCRIPT_DIR/starship.toml"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass=0
fail=0

assert_arrow_count() {
  local label="$1" haystack="$2" expected="$3"
  local count
  count=$(echo "$haystack" | grep -o "$ARROW" | wc -l | tr -d ' ')
  if [ "$count" -eq "$expected" ]; then
    echo -e "  ${GREEN}✓${NC} $label ($count arrows)"
    pass=$((pass + 1))
  else
    echo -e "  ${RED}✗${NC} $label (expected $expected, got $count)"
    fail=$((fail + 1))
  fi
}

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo -e "  ${GREEN}✓${NC} $label"
    pass=$((pass + 1))
  else
    echo -e "  ${RED}✗${NC} $label"
    echo "    expected to contain: $(echo -n "$needle" | cat -v)"
    echo "    got: $(echo -n "$haystack" | cat -v)"
    fail=$((fail + 1))
  fi
}

assert_not_contains() {
  local label="$1" haystack="$2" needle="$3"
  if ! echo "$haystack" | grep -qF "$needle"; then
    echo -e "  ${GREEN}✓${NC} $label"
    pass=$((pass + 1))
  else
    echo -e "  ${RED}✗${NC} $label"
    echo "    expected NOT to contain: $(echo -n "$needle" | cat -v)"
    echo "    got: $(echo -n "$haystack" | cat -v)"
    fail=$((fail + 1))
  fi
}

BG_BLUE=$'\033[44'
BG_GREEN=$'\033[42'
BG_YELLOW=$'\033[43'
BG_RED=$'\033[41'
FG_BLUE=$'\033[34m'
FG_GREEN=$'\033[32m'
FG_YELLOW=$'\033[33m'
FG_RED=$'\033[31m'
ARROW=$(printf '\xee\x82\xb0')

TESTDIR=$(mktemp -d)
NOGIT="$TESTDIR/nogit"
REPO="$TESTDIR/repo"
mkdir -p "$NOGIT"
git init -q "$REPO"
git -C "$REPO" commit --allow-empty -m init -q 2>/dev/null

prompt_for() {
  STARSHIP_SHELL="" bash -c "cd '$1' && starship prompt 2>/dev/null" || true
}

# --- Non-git directory ---
echo "Non-git directory"
out=$(prompt_for "$NOGIT")
assert_contains "has blue background (directory)" "$out" "$BG_BLUE"
assert_contains "has trailing arrow" "$out" "$ARROW"
assert_contains "trailing arrow with color" "$out" "${FG_BLUE}${ARROW}"
RESET=$'\033[0m'
assert_contains "ends with space" "$out" "${ARROW}${RESET} "
assert_arrow_count "1 segment = 1 arrow" "$out" 1
assert_not_contains "no green segment" "$out" "$BG_GREEN"
assert_not_contains "no yellow segment" "$out" "$BG_YELLOW"

# --- Clean git repo ---
echo "Clean git repo"
out=$(prompt_for "$REPO")
assert_contains "has blue background (directory)" "$out" "$BG_BLUE"
assert_contains "has green background (branch)" "$out" "$BG_GREEN"
assert_contains "trailing arrow then space" "$out" "${FG_GREEN}${ARROW}"
assert_arrow_count "2 segments = 2 arrows" "$out" 2
assert_not_contains "no yellow segment" "$out" "$BG_YELLOW"
assert_not_contains "no red segment" "$out" "$BG_RED"
assert_contains "shows branch name" "$out" "main"
assert_contains "shows branch glyph" "$out" ""
assert_contains "space before trailing arrow" "$out" " ${RESET}${FG_GREEN}${ARROW}"

# --- Dirty git repo (untracked file) ---
echo "Dirty git repo (untracked)"
touch "$REPO/newfile"
out=$(prompt_for "$REPO")
assert_contains "has yellow background (dirty)" "$out" "$BG_YELLOW"
assert_arrow_count "2 segments = 2 arrows" "$out" 2
assert_not_contains "no green segment" "$out" "$BG_GREEN"
assert_not_contains "no red segment" "$out" "$BG_RED"
assert_contains "shows branch name" "$out" "main"
rm "$REPO/newfile"

# --- Dirty git repo (modified tracked file) ---
echo "Dirty git repo (modified)"
echo "content" > "$REPO/tracked"
git -C "$REPO" add tracked
git -C "$REPO" commit -q -m "add tracked" 2>/dev/null
echo "changed" > "$REPO/tracked"
out=$(prompt_for "$REPO")
assert_contains "has yellow background (dirty)" "$out" "$BG_YELLOW"
assert_arrow_count "2 segments = 2 arrows" "$out" 2
assert_not_contains "no green segment" "$out" "$BG_GREEN"

# --- Staged file indicator ---
echo "Staged file"
git -C "$REPO" add tracked
out=$(prompt_for "$REPO")
assert_contains "has yellow background (dirty)" "$out" "$BG_YELLOW"
assert_contains "shows staged indicator" "$out" "✚"

# --- Clean after commit ---
echo "Clean after commit"
git -C "$REPO" add -A
git -C "$REPO" commit -q -m "clean up" 2>/dev/null
out=$(prompt_for "$REPO")
assert_contains "has green background (clean)" "$out" "$BG_GREEN"
assert_arrow_count "2 segments = 2 arrows" "$out" 2
assert_not_contains "no yellow segment" "$out" "$BG_YELLOW"

# --- Detached HEAD ---
echo "Detached HEAD"
sha=$(git -C "$REPO" rev-parse --short HEAD)
git -C "$REPO" checkout -q --detach HEAD 2>/dev/null
out=$(prompt_for "$REPO")
assert_contains "has green background (clean detached)" "$out" "$BG_GREEN"
assert_contains "shows detached glyph" "$out" "➦"
assert_contains "shows short SHA" "$out" "$sha"
git -C "$REPO" checkout -q main 2>/dev/null

# --- Merge conflict ---
echo "Merge conflict"
git -C "$REPO" checkout -q -b conflict-branch 2>/dev/null
echo "conflict branch content" > "$REPO/tracked"
git -C "$REPO" add tracked
git -C "$REPO" commit -q -m "conflict change" 2>/dev/null
git -C "$REPO" checkout -q main 2>/dev/null
echo "main branch content" > "$REPO/tracked"
git -C "$REPO" add tracked
git -C "$REPO" commit -q -m "main conflict change" 2>/dev/null
git -C "$REPO" merge conflict-branch 2>/dev/null || true
out=$(prompt_for "$REPO")
assert_contains "has red background (conflict)" "$out" "$BG_RED"
assert_not_contains "no green segment" "$out" "$BG_GREEN"
assert_not_contains "no yellow segment" "$out" "$BG_YELLOW"
assert_contains "shows MERGING state" "$out" "MERGING"
assert_contains "shows conflict indicator" "$out" "✖"
git -C "$REPO" merge --abort 2>/dev/null

# Cleanup
rm -rf "$TESTDIR"

echo ""
echo "---"
echo -e "${GREEN}$pass passed${NC}, ${RED}$fail failed${NC}"
exit $fail
