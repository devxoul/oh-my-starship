#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

xdg_data() { printf '%s' "${XDG_DATA_HOME:-${HOME}/.local/share}"; }
xdg_config() { printf '%s' "${XDG_CONFIG_HOME:-${HOME}/.config}"; }

DATA_DIR="$(xdg_data)/oh-my-starship"
CONFIG_DIR="$(xdg_config)"
CONFIG_TARGET="$CONFIG_DIR/starship.toml"
MARKER_BEGIN="# >>> oh-my-starship >>>"
MARKER_END="# <<< oh-my-starship <<<"

info() { printf '\033[0;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m[warn]\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m[ok]\033[0m %s\n' "$1"; }

if ! command -v starship >/dev/null 2>&1; then
  warn "starship is not on your PATH. Install it first: https://starship.rs/#installation"
  warn "Continuing anyway; the prompt activates once starship is installed."
fi

info "Installing helper scripts to $DATA_DIR"
mkdir -p "$DATA_DIR"
install -m 0755 "$REPO_DIR/scripts/git-prompt.sh" "$DATA_DIR/git-prompt.sh"
install -m 0755 "$REPO_DIR/scripts/git-state.sh" "$DATA_DIR/git-state.sh"
ok "Scripts installed"

mkdir -p "$CONFIG_DIR"
if [ -e "$CONFIG_TARGET" ] && [ ! -L "$CONFIG_TARGET" ]; then
  backup="$CONFIG_TARGET.bak.$(date +%Y%m%d%H%M%S)"
  mv "$CONFIG_TARGET" "$backup"
  warn "Backed up existing config to $backup"
fi
ln -sfn "$REPO_DIR/starship.toml" "$CONFIG_TARGET"
ok "Linked starship.toml into place"

detect_rc() {
  case "${SHELL##*/}" in
    zsh)  printf '%s' "${HOME}/.zshrc" ;;
    bash) if [ -f "${HOME}/.bashrc" ]; then printf '%s' "${HOME}/.bashrc"; else printf '%s' "${HOME}/.bash_profile"; fi ;;
    fish) printf '%s' "$(xdg_config)/fish/config.fish" ;;
    *)    printf '' ;;
  esac
}

RC_FILE="$(detect_rc)"
SHELL_NAME="${SHELL##*/}"
if [ -z "$RC_FILE" ]; then
  warn "Unrecognized shell '$SHELL_NAME'. Add these lines to your shell rc manually:"
  printf '  export OMS_DIR="%s"\n  eval "$(starship init %s)"\n' "$DATA_DIR" "$SHELL_NAME"
else
  if grep -qF "$MARKER_BEGIN" "$RC_FILE" 2>/dev/null; then
    ok "Shell init already present in $RC_FILE"
  else
    info "Adding shell init to $RC_FILE"
    if [ "$SHELL_NAME" = "fish" ]; then
      {
        printf '\n%s\n' "$MARKER_BEGIN"
        printf 'set -gx OMS_DIR "%s"\n' "$DATA_DIR"
        printf 'starship init fish | source\n'
        printf '%s\n' "$MARKER_END"
      } >> "$RC_FILE"
    else
      {
        printf '\n%s\n' "$MARKER_BEGIN"
        printf 'export OMS_DIR="%s"\n' "$DATA_DIR"
        printf 'eval "$(starship init %s)"\n' "$SHELL_NAME"
        printf '%s\n' "$MARKER_END"
      } >> "$RC_FILE"
    fi
    ok "Shell init added"
  fi
fi

if command -v fc-list >/dev/null 2>&1; then
  if ! fc-list 2>/dev/null | grep -qi "nerd"; then
    warn "No Nerd Font detected. The powerline glyphs need one: https://www.nerdfonts.com/"
  fi
else
  warn "Ensure your terminal uses a Nerd Font for the powerline glyphs: https://www.nerdfonts.com/"
fi

ok "Done. Restart your shell or run: exec $SHELL_NAME"
