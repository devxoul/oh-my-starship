#!/bin/sh
# git-prompt.sh — Computes formatted git prompt info for starship
# Called by custom modules in starship.toml
# Output: " <glyph> <branch> <indicators> <extras> <state> "

git_dir=$(git rev-parse --git-dir 2>/dev/null) || exit 1

# ── Branch / Tag / SHA ──────────────────────────────────
ref=$(git symbolic-ref --short HEAD 2>/dev/null)
if [ -n "$ref" ]; then
  display=" $ref"
elif tag=$(git describe --exact-match --tags HEAD 2>/dev/null); then
  display="◈ $tag"
else
  display="➦ $(git rev-parse --short HEAD 2>/dev/null)"
fi
# ── Status indicators (single git-status call) ──────────
porcelain=$(git status --porcelain 2>/dev/null)
staged="" conflicted=""
if [ -n "$porcelain" ]; then
  printf '%s\n' "$porcelain" | grep -q "^[MADRC]"                  && staged="✚"
  printf '%s\n' "$porcelain" | grep -qE "^(UU|AA|DD|AU|UA|DU|UD)"  && conflicted="✖"
fi

# ── Git state ────────────────────────────────────────────
state=""
if [ -f "$git_dir/MERGE_HEAD" ]; then
  state="MERGING"
elif [ -d "$git_dir/rebase-merge" ]; then
  step=$(cat "$git_dir/rebase-merge/msgnum" 2>/dev/null)
  total=$(cat "$git_dir/rebase-merge/end" 2>/dev/null)
  [ -n "$step" ] && [ -n "$total" ] && state="REBASING ${step}/${total}" || state="REBASING"
elif [ -d "$git_dir/rebase-apply" ]; then
  step=$(cat "$git_dir/rebase-apply/next" 2>/dev/null)
  total=$(cat "$git_dir/rebase-apply/last" 2>/dev/null)
  [ -n "$step" ] && [ -n "$total" ] && state="REBASING ${step}/${total}" || state="REBASING"
elif [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
  state="PICKING"
elif [ -f "$git_dir/REVERT_HEAD" ]; then
  state="REVERTING"
elif [ -f "$git_dir/BISECT_LOG" ]; then
  state="BISECTING"
fi

# ── Compose ──────────────────────────────────────────────
ind=""
[ -n "$staged" ]     && ind="${ind}${staged}"
[ -n "$conflicted" ] && ind="${ind}${conflicted}"
[ -n "$ind" ] && ind=" ${ind}"

ext=""
[ -n "$state" ] && ext="${ext} ${state}"

printf " %s%s%s " "$display" "$ind" "$ext"
