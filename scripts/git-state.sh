#!/bin/sh
d=$(git rev-parse --git-dir 2>/dev/null) || exit 1
test -f "$d/MERGE_HEAD" || \
test -d "$d/rebase-merge" || \
test -d "$d/rebase-apply" || \
test -f "$d/CHERRY_PICK_HEAD" || \
test -f "$d/REVERT_HEAD" || \
test -f "$d/BISECT_LOG"
