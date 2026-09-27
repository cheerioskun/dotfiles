if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    # Debian and Ubuntu package these separately on older fzf releases.
    for fzf_file in \
      /usr/share/doc/fzf/examples/key-bindings.zsh \
      /usr/share/doc/fzf/examples/completion.zsh; do
      [[ -r "$fzf_file" ]] && source "$fzf_file"
    done
    unset fzf_file
  fi
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

[[ -r "$HOME/.gvm/environments/default" ]] && source "$HOME/.gvm/environments/default"

[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
