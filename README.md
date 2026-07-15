# oh-my-starship

An opinionated, powerline-style [Starship](https://starship.rs/) prompt that stays out of your way. It shows exactly three things and nothing else:

- **who** you are (`user@`)
- **where** you are (the full path)
- **git** state as a single colored segment — clean, dirty, or in a special state (merge / rebase / cherry-pick / revert / bisect)

Every language/runtime/cloud module is disabled by design. No Node version, no Python venv, no AWS region — just a fast, quiet prompt.

```
 user@  ~/code/project   main   (green = clean)
 user@  ~/code/project   main ✚  (yellow = dirty, ✚ = staged)
 user@  ~/code/project   main ✖ MERGING  (red = conflict/special state)
```

## Requirements

- [**Starship**](https://starship.rs/#installation) on your `PATH`
- A [**Nerd Font**](https://www.nerdfonts.com/) enabled in your terminal (the segments use powerline glyphs — ``, ``, ``)
- `git` and a POSIX `sh` (both standard on macOS/Linux)

## Install

```sh
git clone https://github.com/devxoul/oh-my-starship.git ~/.oh-my-starship
~/.oh-my-starship/install.sh
```

The installer:

1. Copies the helper scripts to `${XDG_DATA_HOME:-~/.local/share}/oh-my-starship/`
2. Symlinks `~/.config/starship.toml` to this repo's `starship.toml` (backing up any existing config)
3. Adds an `OMS_DIR` export and `starship init` to your shell rc (`zsh`, `bash`, or `fish`), inside a clearly marked block

Restart your shell (or `exec $SHELL`) and you're done. Because the config is a symlink into the clone, `git pull` updates your prompt live.

## Uninstall

```sh
~/.oh-my-starship/uninstall.sh
```

Removes the scripts, restores your previous `starship.toml` from backup, and strips the shell-rc block.

## How it works

The prompt is driven by four `[custom.*]` modules in `starship.toml`. They shell out to two small scripts:

| Script | Role |
| --- | --- |
| `scripts/git-state.sh` | Fast boolean: exit 0 if the repo is in a special state (merge/rebase/etc.) |
| `scripts/git-prompt.sh` | Computes the branch/tag/SHA, staged (`✚`) and conflict (`✖`) indicators, and the state label |

The scripts are located at runtime via the `OMS_DIR` environment variable (set by the installer). Each module guards its `when` condition with `[ -x "$OMS_DIR/git-state.sh" ]`, so if `OMS_DIR` is unset or the scripts are missing, the prompt degrades gracefully to just the directory segment instead of erroring.

## Customizing

Edit `starship.toml` directly. The color scheme lives in the `style` fields of the four `custom.git_*` modules and the `directory` / `username` modules. Segment colors:

| State | Background |
| --- | --- |
| directory | blue |
| clean git | green |
| dirty git | yellow |
| special state | red |

## Tests

```sh
./test.sh
```

Spins up temporary git repos and asserts the rendered prompt (ANSI colors, arrow count, glyphs) across non-git, clean, dirty, staged, detached-HEAD, and merge-conflict scenarios. Runs against the repo's own config and scripts — no install required.

## License

MIT — see [LICENSE](./LICENSE).
