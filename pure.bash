# ╭────────────╮
# │  Settings  │
# ╰────────────╯
ENABLE_GIT=true
ENABLE_SSH=true
ENABLE_DOCKER=true
ENABLE_DISKSPACE=true
DOCKER_SANITIZE_NAME=false

# Basic Colors
BLACK=$'\e[30m'
RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
MAGENTA=$'\e[35m'
CYAN=$'\e[36m'
WHITE=$'\e[37m'

GRAY=$'\e[38;5;239m'

# Styles
BOLD=$'\e[1m'
ITALIC=$'\e[3m'
UNDERLINE=$'\e[4m'
BLINK=$'\e[5m'  # May not work in all terminals
INVERT=$'\e[7m' # Invert foreground/background
STRIKE=$'\e[9m' # Strikethrough

NC=$'\e[0m' # Reset all styles/colors

BRA_LEFT="${BOLD}${GRAY}[${NC}"
BRA_RIGHT="${BOLD}${GRAY}]${NC}"

command-exists() {
  command -v "$@" >/dev/null 2>&1
}

__pure_get_diskspace_icon__() {
  local arg=$1 bar
  local ticks=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

  arg=$((arg * ${#ticks[@]} / 100))

  printf "%s " "${ticks[$arg]}"
}

__get_diskspace__() {
  local space avail unit icon perc data

  data=($(df -h . | tail -1))

  space=${data[3]}
  avail=${data[1]}
  perc=${data[4]}

  perc=${perc%\%}

  avail=${avail%*G}
  avail=${avail%*T}
  unit=${space: -1}

  icon=$(__pure_get_diskspace_icon__ "${perc}")

  # displays the threshold in colors
  local DISK_THRESHHOLD=$((avail / 5))

  if ((${space%*"${unit}"} > avail / 2)); then
    printf "${BRA_LEFT}${GREEN}${icon:-}%s${NC}${BRA_RIGHT}" "$space"
  elif ((${space%*"${unit}"} > DISK_THRESHHOLD)); then
    printf "${BRA_LEFT}${BOLD}${YELLOW}${icon:-}%s${NC}${BRA_RIGHT}" "$space"
  else
    printf "${BRA_LEFT}${BOLD}${RED}${icon:-}%s${NC}${BRA_RIGHT}" "$space"
  fi
}

__get_git_status__() {
  local git_status=""

  pure_symbol_unpulled="${BOLD}${BLUE} ⇣${NC}"
  pure_symbol_unpushed="${BOLD}${MAGENTA} ⇡${NC}"
  pure_symbol_dirty="${BOLD}${RED} *${NC}"

  __get_remote_status__() {
    local pure_git_raw_remote_status
    local UNPULLED

    pure_git_raw_remote_status=$(git status --porcelain=2 --branch | command grep --only-matching --perl-regexp '\+\d+ \-\d+')

    # shape raw status and check unpulled commit
    UNPULLED=$(echo ${pure_git_raw_remote_status} | command grep --only-matching --perl-regexp '\-\d')
    if [[ ${UNPULLED} != "-0" ]]; then
      pure_git_unpulled=true
    else
      pure_git_unpulled=false
    fi

    # unpushed commit too
    UNPUSHED=$(echo ${pure_git_raw_remote_status} | command grep --only-matching --perl-regexp '\+\d')
    if [[ ${UNPUSHED} != "+0" ]]; then
      pure_git_unpushed=true
    else
      pure_git_unpushed=false
    fi

    # if unpulled -> ⇣
    # if unpushed -> ⇡
    # if both (branched from remote) -> ⇣⇡
    if ${pure_git_unpulled}; then

      if ${pure_git_unpushed}; then
        printf "%s" "${RED}${pure_symbol_unpulled}${pure_symbol_unpushed}${NC}"
      else
        printf "%s" "${BOLD}${RED}${pure_symbol_unpulled}${NC}"
      fi

    elif ${pure_git_unpushed}; then
      printf "%s" "${BOLD}${BLUE}${pure_symbol_unpushed}${NC}"
    fi
  }

  # if current directory isn't git repository, skip this
  if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == "true" ]]; then

    git_status="$(git branch --show-current)"

    # check clean/dirty
    git_status="${git_status}$(git diff --quiet || echo "${pure_symbol_dirty}")"

    # coloring
    git_status="${GRAY}${git_status}${NC}"

    # if repository have no remote, skip this
    if [[ -n $(git remote show) ]]; then
      git_status+="$(__get_remote_status__)"
    fi
  fi

  if [[ -n "${git_status}" ]]; then
    printf "${BRA_LEFT}%s${BRA_RIGHT}" "${git_status}"
  fi
}

# INFO:
# ╭─────────────────────────────────────────────────────────────────────────╮
# │ sanitizes the name, so that it displays the first word, and after it    │
# │ detects something which isnt a-z or A-Z or 0-9 it will use this         │
# │ character as a separator, printing only one more character after that   │
# │ separator.                                                              │
# │ This goes on for the whole name                                         │
# │                                                                         │
# │ if name=caddy-local-reverse-proxy                                       │
# │ then newname=caddy-l-r-p                                                │
# │                                                                         │
# │ This behaviour can be changed with the `$after` variable, 2 is the      │
# │ default, so                                                             │
# │ it prints the separator (e.g. '-') and one more character               │
# ╰─────────────────────────────────────────────────────────────────────────╯
__sanitize_docker_project_name__() {
  local name=$1 length newname="" i char accum=0 dots=false
  local first=true
  local after=2
  length=${#name}

  if $DOCKER_SANITIZE_NAME; then
    for ((i = 0; i < "$length"; i++)); do
      char=${name:${i}:1}                             # get one char from the name
      if [[ "${char}" =~ ([a-z]|[A-Z]|[0-9]) ]]; then # char is a a-z character
        if $first; then
          newname+="${char}"
          ((accum++))
        fi
      else
        dots=true
        first=false
        newname+="${name:${i}:${after}}"
      fi

      ((accum >= 8)) && {
        dots=true
        break
      }
    done

    if $dots; then
      newname+=".."
    fi

    printf "%s" "${newname}" # keep the space after %s to get the projects spaced out
  else
    printf "%s" "${name}"
  fi
}

__get_docker_container__() {
  local compose_file=""
  local dir="$PWD"
  local service temp_compose_status
  local icon="${BLUE} ${NC}"

  # walk up until root to find docker-compose.yml or compose.yml
  while [[ "$dir" != "/" ]]; do
    for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
      if [[ -f "$dir/$f" ]]; then
        compose_file="$dir/$f"
        break 2
      fi
    done
    dir="$(dirname "$dir")"
  done

  if [[ -n "$compose_file" ]]; then
    DOCKER_FILE_FOUND=true

    local project_name
    project_name=$(basename "$(dirname "$compose_file")")
    # project_name=$(docker compose -f "$compose_file" ps --status running --services | head -1)

    ((${#project_name} > 8)) && {
      project_name="$(__sanitize_docker_project_name__ "${project_name}")"
      # project_name="${project_name:0:5}.."
    }

    # check if containers are up
    docker_compose_services=($(docker compose -f "$compose_file" ps --status running --services))
    if ((${#docker_compose_services[@]} > 0)); then
      # if docker compose -f "$compose_file" ps --status running >/dev/null 2>&1; then
      # if [[ $(docker compose -f "$compose_file" ps --status running --services 2>/dev/null | wc -l) -gt 0 ]]; then
      for service in "${docker_compose_services[@]}"; do
        service=$(__sanitize_docker_project_name__ "${service}")
        temp_compose_status+="${BRA_LEFT}${BLUE}${service} ${BOLD}${GREEN}(up)${BRA_RIGHT}${RESET} " # keep the space to space out the projects
      done

      [[ -n "${temp_compose_status}" ]] &&
        pure_compose_status=${temp_compose_status}
    else
      pure_compose_status="${BRA_LEFT}${BOLD}${RED}${project_name} ${RED}(down)${BRA_RIGHT}${RESET}"
    fi
    # else
    #   pure_compose_status="${YELLOW}${project_name}(?)${RESET}"
    # fi
  else
    DOCKER_FILE_FOUND=false
    pure_compose_status=""
  fi

  if [[ -n "${pure_compose_status}" ]]; then
    printf "${icon} %s" "${pure_compose_status}"
  fi
}

__update__vars() {
  local err=$? # has to be the first, as it has to evaluate the last command state

  local CWD DISKSPACE
  local info=""

  # status color for the prompt symbol
  if ((err <= 0)); then
    STATUS=${MAGENTA}
  else
    STATUS=${RED}
  fi

  info="${MAGENTA}${USER}${NC}"

  if $ENABLE_DOCKER; then
    if [[ -n "$(__get_docker_container__)" ]]; then
      DOCKER_LINE=$(__get_docker_container__)$'\n'
      info="${DOCKER_LINE}$info"
    else
      DOCKER_LINE=""
    fi
  else
    DOCKER_LINE=""
  fi

  # current working directory with $HOME replcaed with ~
  CWD=${PWD/"$HOME"/"~"}
  if $ENABLE_SSH; then
    # for ssh connections
    if [[ -n $SSH_CONNECTION ]]; then
      info="${BOLD}${MAGENTA}${USER}@${RED}${HOSTNAME}${NC}${CYAN}:${CWD}${NC}"
      # INFO_LINE="${BOLD}${MAGENTA}${USER}@${RED}${HOSTNAME}${NC}${CYAN}:${CWD}${NC} ${DISKSPACE} ${GIT_STATUS}"
    else
      info+="${CYAN}:${CWD}${NC}"
      # INFO_LINE="${MAGENTA}$USER${CYAN}:${CWD}${NC} ${DISKSPACE} ${GIT_STATUS}"
    fi
  else
    info+="${CYAN}:${CWD}${NC}"
    # INFO_LINE="${MAGENTA}$USER${CYAN}:${CWD}${NC} ${DISKSPACE} ${GIT_STATUS}"
  fi

  if $ENABLE_DISKSPACE; then
    DISKSPACE="$(__get_diskspace__)"

    info+=" ${DISKSPACE}"
  fi

  if $ENABLE_GIT; then
    GIT_STATUS="$(__get_git_status__)"

    info+=" ${GIT_STATUS}"
  fi

  INFO_LINE="$info"
}

PROMPT_SYMBOL="\${STATUS}❯ ${NC}"
PROMPT_COMMAND="__update__vars; ${PROMPT_COMMAND}"

# This ensures the docker line is set if a composefile was found. Otherwise does
# NOT generate an empty line above
PS1="\n\${INFO_LINE}\n${PROMPT_SYMBOL}"

if command-exists zoxide; then
  eval "$(zoxide init bash)"
  alias zz="zoxide query --interactive"
fi
alias ..="cd .."
. "$HOME/.bashenv"
