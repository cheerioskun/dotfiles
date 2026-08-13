bindkey -v
export KEYTIMEOUT=1

bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^W' backward-kill-word
bindkey '^U' backward-kill-line
bindkey '^K' kill-line

mkcd() {
  [[ $# -eq 1 ]] || { print -u2 'usage: mkcd <dir>'; return 2; }
  mkdir -p -- "$1" && cd -- "$1"
}

lfcd() {
  local tmp dir
  tmp="$(mktemp -t lfcd.XXXXXX)" || return 1
  command lf -last-dir-path="$tmp" "$@"
  dir="$(<"$tmp")"
  command rm -f -- "$tmp"

  [[ -d "$dir" && "$dir" != "$PWD" ]] && cd -- "$dir"
}

ff() {
  local file
  file="$(fd --type f --hidden --follow --exclude .git |
    fzf --preview 'bat --style=numbers --color=always {}')" || return
  [[ -n "$file" ]] && "${EDITOR:-nvim}" "$file"
}

rgz() {
  local editor="${EDITOR:-nvim}"
  rg --column --line-number --no-heading --color=always --smart-case "$@" |
    fzf --ansi --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
      --bind "enter:become($editor {1} +{2})"
}

gb() {
  local branch
  branch="$(git for-each-ref --sort=-committerdate \
    --format='%(refname:short)' refs/heads/ | fzf)" || return
  [[ -n "$branch" ]] && git switch "$branch"
}

killz() {
  local signal="${1:-TERM}" pids
  pids="$(ps -ef | sed 1d | fzf --multi | awk '{print $2}')" || return
  [[ -n "$pids" ]] && print -r -- "$pids" | xargs kill -s "$signal"
}

extract() {
  [[ $# -eq 1 && -f "$1" ]] || { print -u2 'usage: extract <archive>'; return 2; }
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz) tar xzf "$1" ;;
    *.tar.xz|*.txz) tar xJf "$1" ;;
    *.tar) tar xf "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.gz) gunzip "$1" ;;
    *.zip) unzip "$1" ;;
    *.Z) uncompress "$1" ;;
    *) print -u2 -- "extract: unsupported archive: $1"; return 1 ;;
  esac
}

cheat() {
  [[ $# -ge 1 ]] || { print -u2 'usage: cheat <topic>'; return 2; }
  curl --fail --silent --show-error "https://cheat.sh/$1"
}
