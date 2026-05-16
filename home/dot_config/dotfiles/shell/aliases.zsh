alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias preview='bat --style=numbers --color=always'
else
  alias preview='less -N'
fi

alias gb='git checkout $(git for-each-ref --sort=-committerdate --format="%(refname:short)" refs/heads/ | fzf)'
alias tat='tmux attach'
alias lf='lfcd'
alias zshconfig='${EDITOR:-vim} ~/.zshrc'
