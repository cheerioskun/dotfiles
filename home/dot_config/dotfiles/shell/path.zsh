path_prepend_if_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  case ":$PATH:" in
    *":$dir:"*) ;;
    *) export PATH="$dir:$PATH" ;;
  esac
}

path_prepend_if_dir "$HOME/.local/bin"
path_prepend_if_dir "$HOME/.cargo/bin"
path_prepend_if_dir "$HOME/go/bin"

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
path_prepend_if_dir "$BUN_INSTALL/bin"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1
