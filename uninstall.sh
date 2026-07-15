#!/usr/bin/env bash
set -euo pipefail

xdg_data() { printf '%s' "${XDG_DATA_HOME:-${HOME}/.local/share}"; }
xdg_config() { printf '%s' "${XDG_CONFIG_HOME:-${HOME}/.config}"; }

DATA_DIR="$(xdg_data)/oh-my-starship"
CONFIG_TARGET="$(xdg_config)/starship.toml"
MARKER_BEGIN="# >>> oh-my-starship >>>"
MARKER_END="# <<< oh-my-starship <<<"

info() { printf '\033[0;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m[warn]\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m[ok]\033[0m %s\n' "$1"; }

if [ -L "$CONFIG_TARGET" ]; then
  rm -f "$CONFIG_TARGET"
  ok "Removed config symlink $CONFIG_TARGET"
  latest_backup="$(ls -1t "$CONFIG_TARGET".bak.* 2>/dev/null | head -1 || true)"
  if [ -n "$latest_backup" ]; then
    mv "$latest_backup" "$CONFIG_TARGET"
    ok "Restored previous config from $latest_backup"
  fi
else
  warn "No oh-my-starship config symlink found at $CONFIG_TARGET"
fi

if [ -d "$DATA_DIR" ]; then
  rm -rf "$DATA_DIR"
  ok "Removed $DATA_DIR"
fi

strip_block() {
  rc="$1"
  [ -f "$rc" ] || return 0
  grep -qF "$MARKER_BEGIN" "$rc" || return 0
  tmp="$(mktemp)"
  awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip   { print }
  ' "$rc" > "$tmp"
  mv "$tmp" "$rc"
  ok "Removed shell init from $rc"
}

for rc in "${HOME}/.zshrc" "${HOME}/.bashrc" "${HOME}/.bash_profile" "$(xdg_config)/fish/config.fish"; do
  strip_block "$rc"
done

ok "Uninstalled. Restart your shell to take effect."
