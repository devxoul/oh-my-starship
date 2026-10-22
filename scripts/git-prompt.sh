#!/bin/sh
# git-prompt.sh — Renders the whole git segment for starship in one pass.
# Called by the single custom.git module in starship.toml.
#
# Outside a repo: prints the closing arrow for the directory segment.
# Inside a repo:  prints a colored segment " <glyph> <branch> <indicators> <state> "
#   red = special state, yellow = dirty, green = clean.
#
# Uses exactly two git processes (rev-parse + status) on the common path.

esc=$(printf '\033')
arrow=$(printf '\356\202\260')
branch_icon=$(printf '\356\202\240')

git_dir=$(git rev-parse --git-dir 2>/dev/null) || {
  printf '%s[34m%s%s[0m' "$esc" "$arrow" "$esc"
  exit 0
}

# ── Status (branch + entries in one call) ───────────────
head="" oid="" dirty="" staged="" conflicted=""
status=$(git status --porcelain=v2 --branch 2>/dev/null)
while IFS= read -r line; do
  case "$line" in
    "# branch.head "*) head=${line#\# branch.head } ;;
    "# branch.oid "*)  oid=${line#\# branch.oid } ;;
    "#"*) ;;
    "u "*) dirty=1 conflicted="✖" ;;
    "1 "*|"2 "*)
      dirty=1
      xy=${line#? }
      case "$xy" in .*) ;; *) staged="✚" ;; esac
      ;;
    ?*) dirty=1 ;;
  esac
done <<EOF
$status
EOF

# ── Branch / Tag / SHA ──────────────────────────────────
if [ -n "$head" ] && [ "$head" != "(detached)" ]; then
  display="$branch_icon $head"
elif tag=$(git describe --exact-match --tags HEAD 2>/dev/null); then
  display="◈ $tag"
else
  display="➦ $(git rev-parse --short HEAD 2>/dev/null || printf '%.7s' "$oid")"
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

# ── Colors: bg code, fg code for text, fg code for arrow ─
if [ -n "$state" ]; then
  bg=41 fg=37 tip=31
elif [ -n "$dirty" ]; then
  bg=43 fg=30 tip=33
else
  bg=42 fg=30 tip=32
fi

# ── Compose ──────────────────────────────────────────────
ind="${staged}${conflicted}"
[ -n "$ind" ] && ind=" ${ind}"
ext=""
[ -n "$state" ] && ext=" ${state}"

printf '%s[%s;34m%s%s[0m%s[%s;%sm %s%s%s %s[0m%s[%sm%s%s[0m' \
  "$esc" "$bg" "$arrow" "$esc" \
  "$esc" "$bg" "$fg" "$display" "$ind" "$ext" "$esc" \
  "$esc" "$tip" "$arrow" "$esc"
