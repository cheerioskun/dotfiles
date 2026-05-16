bindkey -v
export KEYTIMEOUT=1

bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^W' backward-kill-word
bindkey '^U' backward-kill-line
bindkey '^K' kill-line

if (( $+widgets[fzf-history-widget] )); then
  bindkey '^R' fzf-history-widget
else
  bindkey '^R' history-incremental-search-backward
fi

function zle-keymap-select zle-line-init {
  zle reset-prompt
  zle -R
}
function zle-line-finish {
  zle reset-prompt
}
zle -N zle-keymap-select
zle -N zle-line-init
zle -N zle-line-finish
