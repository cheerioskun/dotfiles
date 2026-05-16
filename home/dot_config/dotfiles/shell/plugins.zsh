ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"

if [[ -f "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"

  zinit ice depth=1
  zinit light romkatv/powerlevel10k

  zstyle ':catppuccin:p10k' theme lean
  zstyle ':catppuccin:p10k' flavour mocha
  zinit light tolkonepiu/catppuccin-powerlevel10k-themes

  zinit wait lucid for \
    OMZL::git.zsh \
    OMZP::git \
    OMZP::cp \
    OMZP::docker \
    OMZP::docker-compose \
    OMZP::kubectl \
    OMZP::kubectx

  zinit wait lucid for \
    atinit"zicompinit; zicdreplay" \
      zsh-users/zsh-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
      zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
      zsh-users/zsh-completions
fi
