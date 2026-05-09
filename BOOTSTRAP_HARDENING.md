# Bootstrap Hardening Checklist

This is the current laundry list for making bootstrap predictable on a fresh Mac/Linux machine.

## P0: Make the install complete reliably

- [x] Move `create_symlinks` earlier in [bootstrap.sh](/Users/hemant/repos/dotfiles/bootstrap.sh:54), before optional tool installers such as `rustup`, `bun`, `opencode`, `weave`, `zinit`, and `tpm`.
  Why: the script no longer relies on late installers finishing before `~/.zshrc` exists.

- [x] Split installers into `required` and `optional`.
  Required: shell config linkage, `zsh`, package manager, baseline CLI tools needed by the config.
  Optional: `rustup`, `bun`, `opencode`, `weave`, plugin managers, extras.

- [x] Replace fail-fast behavior for optional installers with failure collection and a final summary.
  Acceptance: bootstrap can finish with warnings and still leave a working `~/.zshrc`.

- [x] Add an explicit post-install verification step.
  Acceptance:
  - `~/.zshrc` exists
  - `~/.zshrc` points into the repo
  - `zsh -ic 'alias ..'` succeeds
  - `zsh -ic 'command -v zoxide fzf'` succeeds when those tools were requested

## P0: Make the shell usable immediately

- [x] Add a supported "reload into zsh now" path at the end of bootstrap.
  Candidate behavior:
  - if already running under `zsh`, `exec zsh -l`
  - if running under another interactive shell, print a one-liner to run: `exec zsh -l`
  - if non-interactive, skip with a message
  Acceptance: users can run bootstrap and immediately get aliases/functions in the same terminal session.

- [x] Set `zsh` as the default shell on macOS too, not only Linux.
  Current gap: closed in [tools/macos.sh](/Users/hemant/repos/dotfiles/tools/macos.sh:6).

- [ ] Add a clear note when terminal app settings may still override the login shell.
  Acceptance: bootstrap tells the user what to verify in iTerm/Terminal if `zsh` still does not start.

## P0: PATH and binary placement sanity

- [x] Audit every installer and document exactly where it installs binaries.
  Current known locations:
  - `brew`: Homebrew prefix
  - GitHub tarballs via `install_github_release`: `~/.local/bin`
  - `rustup`: `~/.cargo/bin`
  - `bun`: `~/.bun/bin`
  - `opencode`: `~/.opencode/bin`

- [x] Ensure bootstrap itself exports every install location needed for subsequent steps in the same process.
  Current gaps:
  - `ensure_local_bin` now runs on macOS and Linux before GitHub-release installers.
  - `install_opencode` now installs with `--no-modify-path` and refreshes PATH for the current shell after install.
  Acceptance: a tool installed earlier in bootstrap is discoverable later in the same bootstrap run.

- [x] Normalize PATH handling into one place instead of spreading it across installer scripts and the bottom of `zshrc`.
  Acceptance: one helper owns "add this path if directory exists and it is not already present."

- [x] Verify `opencode` integration end to end.
  Questions to answer:
  - where does the upstream install script place the binary on macOS?
  - is [config/zshrc](/Users/hemant/repos/dotfiles/config/zshrc:213) pointing at the right directory?
  - does bootstrap need to source an env file or completion script too?
  Acceptance: `zsh -ic 'command -v opencode'` succeeds after bootstrap.

## P1: Clean up `.zshrc` structure

- [ ] Keep `config/zshrc` sectioned, but tighten the ordering so it reads as one pipeline.
  Suggested order:
  1. early environment and repo discovery
  2. PATH helpers
  3. package-manager environment
  4. plugin manager init
  5. tool init
  6. aliases/functions
  7. shell UX bindings/history
  8. local machine overrides

- [ ] Move ad hoc tail additions into proper sections.
  Current examples:
  - [config/zshrc](/Users/hemant/repos/dotfiles/config/zshrc:213) `opencode`
  - [config/zshrc](/Users/hemant/repos/dotfiles/config/zshrc:218) bun completions
  - [config/zshrc](/Users/hemant/repos/dotfiles/config/zshrc:221) `nvm`

- [ ] Add small helper functions in `zshrc` for repeated logic such as `path_prepend_if_dir`.
  Acceptance: fewer raw `export PATH=...` lines and less ordering ambiguity.

- [ ] Decide what belongs in tracked config versus local overrides.
  Candidate: move machine- or language-manager-specific setup like `nvm` into `~/.zshrc.local` unless it is intentionally required everywhere.

## P1: Idempotence

- [ ] Make symlink creation idempotent and less destructive.
  Current behavior in [bootstrap.sh](/Users/hemant/repos/dotfiles/bootstrap.sh:69) always overwrites symlinks and renames plain files to `.backup`.
  Improvements:
  - do nothing if the destination already points to the correct source
  - use timestamped backups instead of a single `.backup`
  - avoid deleting a symlink before confirming the target exists

- [ ] Make installer checks semantic, not just "command exists".
  Examples:
  - `opencode`, `bun`, `weave-cli`, `jj`, `delta`
  - version checks where installer behavior or paths may have changed

- [ ] Ensure repeated runs do not duplicate PATH exports, duplicate shell entries, or repeatedly force-link packages.
  Acceptance: running bootstrap twice produces no harmful changes and mostly "already installed" messages.

## P1: Reversibility

- [ ] Add an uninstall or rollback script.
  Scope:
  - remove repo-managed symlinks
  - restore the latest backup when available
  - optionally remove repo-managed plugin clones
  - never uninstall shared package managers without explicit confirmation

- [ ] Track exactly what bootstrap changed.
  Candidate: write a manifest file under `~/.local/state/dotfiles-bootstrap/`.
  Acceptance: rollback can act on recorded state instead of guesswork.

- [ ] Define what is in scope for reversal.
  Likely reversible:
  - symlinks
  - plugin manager clones
  - repo-owned downloaded binaries in `~/.local/bin`
  Less reversible by default:
  - Homebrew packages
  - Rust toolchains
  - system shell changes

## P2: Documentation and verification UX

- [ ] Update [README.md](/Users/hemant/repos/dotfiles/README.md:22) to describe actual behavior on macOS.
  Current drift:
  - iTerm config is not managed here
  - macOS does not currently set default shell
  - failure behavior is not documented

- [ ] Add a short "fresh machine smoke test" section for macOS as well as Linux.
  Acceptance:
  - one command to run bootstrap
  - one command to verify aliases, PATH, and core binaries
  - one command to reload shell

- [ ] Print a final success report with actionable next steps.
  Example:
  - shell symlinks created
  - optional installers failed: `opencode`, `weave-cli`
  - run `exec zsh -l`
  - if using iTerm, verify profile shell is login shell

## P2: Nice-to-have platform coverage

- [x] Decide whether iTerm settings should live in this repo.
  The current iTerm2 preference plist is now tracked and linked from [bootstrap.sh](/Users/hemant/repos/dotfiles/bootstrap.sh).

- [ ] Consider separating "core shell bootstrap" from "developer tool bootstrap".
  Acceptance: users can get a working shell even if heavier tool installs are skipped.
