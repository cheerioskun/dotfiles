mkcd() {
  [[ $# -eq 1 ]] || { echo 'usage: mkcd <dir>' >&2; return 2; }
  mkdir -p "$1" && cd "$1"
}

ff() {
  for cmd in fd fzf; do command -v "$cmd" >/dev/null 2>&1 || { echo "ff requires $cmd" >&2; return 1; }; done
  local file preview_cmd
  if command -v bat >/dev/null 2>&1; then
    preview_cmd='bat --style=numbers --color=always {}'
  else
    preview_cmd='sed -n "1,120p" {}'
  fi
  file=$(fd --type f --hidden --follow --exclude .git 2>/dev/null | fzf --height 40% --reverse --preview "$preview_cmd")
  [[ -n "$file" ]] && ${EDITOR:-vim} "$file"
}

rgz() {
  for cmd in rg fzf; do command -v "$cmd" >/dev/null 2>&1 || { echo "rgz requires $cmd" >&2; return 1; }; done
  local editor="${EDITOR:-vim}"
  local preview='sed -n "1,160p" {1}'
  command -v bat >/dev/null 2>&1 && preview='bat --color=always {1} --highlight-line {2}'

  rg --column --line-number --no-heading --color=always --smart-case "${*:-}" |
    fzf --ansi --delimiter : \
      --preview "$preview" \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
      --bind "enter:become($editor {1} +{2})"
}

killz() {
  command -v fzf >/dev/null 2>&1 || { echo 'killz requires fzf' >&2; return 1; }
  local pids
  pids=$(ps -ef | sed 1d | fzf --multi | awk '{print $2}')
  [[ -n "$pids" ]] && echo "$pids" | xargs kill -"${1:-9}"
}

extract() {
  [[ $# -eq 1 && -f "$1" ]] || { echo "usage: extract <archive>" >&2; return 2; }
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz) tar xzf "$1" ;;
    *.tar.xz) tar xJf "$1" ;;
    *.tar) tar xf "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.gz) gunzip "$1" ;;
    *.zip) unzip "$1" ;;
    *.Z) uncompress "$1" ;;
    *.7z) 7z x "$1" ;;
    *.rar) unrar x "$1" ;;
    *) echo "'$1' cannot be extracted by extract" >&2; return 1 ;;
  esac
}

cheat() {
  [[ $# -ge 1 ]] || { echo 'usage: cheat <topic>' >&2; return 2; }
  curl "cheat.sh/$1"
}
