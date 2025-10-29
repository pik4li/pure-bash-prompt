# ╭────────────╮
# │  Settings  │
# ╰────────────╯
ENABLE_NERDFONTS=true # set to `false` if you do not have nerdfonts installed

ENABLE_GIT=true       # set to `false` to disable GIT module
ENABLE_SSH=true       # set to `false` to disable SSH module
ENABLE_DOCKER=true    # set to `false` to disable DOCKER module
ENABLE_DISKSPACE=true # set to `false` to disable DISKSPACE module
ENABLE_UPTIME=false   # set to `true` to enable UPTIME module

ENABLE_ERROR_CODES=true # set to `false` to disable the error codes inline

DOCKER_SANITIZE_NAME=false

# INFO:
# set custom left and right separators for the widgts like git, docker, diskspace,  uptime..
# you can for example set ( and ) | Default is [ and ]
#
# SEPARATOR_LEFT="("
# SEPARATOR_RIGHT=")"

## CAUTION:
## Do not edit anything beyond this line, unless you know what you are doing!

# Basic Colors
BLACK=$'\e[30m'
RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
ORANGE=$'\e[38;5;202m'
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

BRA_LEFT="${BOLD}${GRAY}${SEPARATOR_LEFT:-[}${NC}"
BRA_RIGHT="${BOLD}${GRAY}${SEPARATOR_RIGHT:-]}${NC}"

command-exists() {
  command -v "$@" >/dev/null 2>&1
}

__pure_get_diskspace_icon__() {
  local arg=$1

  if $ENABLE_NERDFONTS; then
    local ticks=(󰪞 󰪟 󰪠 󰪡 󰪢 󰪣 󰪤 󰪥)
  else
    local ticks=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
  fi

  arg=$((arg * ${#ticks[@]} / 101))

  printf "%s " "${ticks[$arg]}"
}

__get_diskspace__() {
  local space avail unit icon perc data

  data=($(df -h . | tail -1))

  avail=${data[1]}
  perc=${data[4]}

  space=${data[3]}
  unit=${space: -1} # like G or T depending on the size of the disk

  # make sure only numbers exist for equations
  perc=${perc%\%}
  avail=${avail%"$unit"}
  space=${space%"$unit"}

  icon=$(__pure_get_diskspace_icon__ "${perc}")

  if ((perc >= 85)); then
    printf "${BRA_LEFT}${BOLD}${RED}${icon:-}%s${NC}${BRA_RIGHT}" "${space}${unit}"
  elif ((perc >= 67)); then
    printf "${BRA_LEFT}${BOLD}${ORANGE}${icon:-}%s${NC}${BRA_RIGHT}" "${space}${unit}"
  elif ((perc >= 34)); then
    printf "${BRA_LEFT}${BOLD}${YELLOW}${icon:-}%s${NC}${BRA_RIGHT}" "${space}${unit}"
  else
    printf "${BRA_LEFT}${BOLD}${GREEN}${icon:-}%s${NC}${BRA_RIGHT}" "${space}${unit}"
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

    # if no branch was found, then use HEAD
    [[ -n "${git_status}" ]] || git_status="HEAD"

    git diff --quiet &>/dev/null

    local err=$? # get errorcode - 0 if no changes are there

    if ((err != 0)); then
      diff="$pure_symbol_dirty"
    else
      diff=""
    fi

    # coloring
    git_status="${GRAY}${git_status}${NC}"

    # check clean/dirty
    git_status="${git_status}${diff}"

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

  if $ENABLE_NERDFONTS; then
    local icon="${BLUE} ${NC}"
  fi

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
  else
    pure_compose_status=""
  fi

  if [[ -n "${pure_compose_status}" ]]; then
    printf "${icon} %s" "${pure_compose_status}"
  fi
}

__get_uptime__() {
  local ut=$(uptime -p)

  # replace all ", " with "," so that the space will get more tighter
  ut=${ut//, /" "}

  if grep -qi "year" <<<"${ut}"; then
    UPTIME_COLOR=${MAGENTA}
  elif grep -qi "months" <<<"${ut}"; then
    UPTIME_COLOR=${BLUE}
  elif grep -qi "week" <<<"${ut}"; then
    UPTIME_COLOR=${CYAN}
  elif grep -qi "day" <<<"${ut}"; then
    UPTIME_COLOR=${RED}
  elif grep -qi "hour" <<<"${ut}"; then
    UPTIME_COLOR=${ORANGE}
  elif grep -qi "minute" <<<"${ut}"; then
    UPTIME_COLOR=${YELLOW}
  else
    UPTIME_COLOR=${GRAY}
  fi

  if $ENABLE_NERDFONTS; then
    ut=${ut/up /"${BOLD}${UPTIME_COLOR}󰔛 ${NC}"}
  else
    ut=${ut/up/"${BOLD}${UPTIME_COLOR}up${NC}"}
  fi

  # ─< replace the fullname with colored symbols >────────────────────────────────
  # redraw minutes
  ut=${ut/ minutes/"${BOLD}${YELLOW}m${NC}"}
  ut=${ut/ minute/"${BOLD}${YELLOW}m${NC}"}

  # redraw hours
  ut=${ut/ hours/"${BOLD}${ORANGE}h${NC}"}
  ut=${ut/ hour/"${BOLD}${ORANGE}h${NC}"}

  # redraw days
  ut=${ut/ days/"${BOLD}${RED}d${NC}"}
  ut=${ut/ day/"${BOLD}${RED}d${NC}"}

  # redraw weeks
  ut=${ut/ weeks/"${BOLD}${CYAN}W${NC}"}
  ut=${ut/ week/"${BOLD}${CYAN}W${NC}"}

  # redraw months
  ut=${ut/ months/"${BOLD}${BLUE}M${NC}"}
  ut=${ut/ month/"${BOLD}${BLUE}M${NC}"}

  # redraw years
  ut=${ut/ years/"${BOLD}${MAGENTA}Y${NC}"}
  ut=${ut/ year/"${BOLD}${MAGENTA}Y${NC}"}

  # $ut exists, or return nothing
  [[ -n "${ut}" ]] || return

  printf "${BRA_LEFT}%s${BRA_RIGHT}" "${ut}"
}

__update__vars() {
  local err=$? # has to be the first, as it has to evaluate the last command state

  local CWD DISKSPACE USERCOLOR
  local info=""

  if [[ "$USER" == "root" ]]; then
    USERCOLOR="${RED}${UNDERLINE}"
  else
    USERCOLOR="${MAGENTA}"
  fi

  info="${USERCOLOR}${USER}${NC}"

  if $ENABLE_NERDFONTS; then
    local ssh_icon="${GRAY}󰢹 ${NC}"
  fi

  # status color for the prompt symbol
  if ((err == 0)); then
    STATUS=${MAGENTA}
  else
    if $ENABLE_ERROR_CODES; then
      STATUS="${RED}(${err}) ${MAGENTA}"
    else
      STATUS="${RED}"
    fi
  fi

  # current working directory with $HOME replcaed with ~
  CWD=${PWD/"$HOME"/"~"}

  if $ENABLE_SSH; then
    # for ssh connections
    if [[ -n $SSH_CONNECTION ]]; then
      info="${BOLD}${ssh_icon}${MAGENTA}${UNDERLINE}${USER}${MAGENTA}@${RED}${HOSTNAME}${NC}${CYAN}:${CWD}${NC}"
      # INFO_LINE="${BOLD}${MAGENTA}${USER}@${RED}${HOSTNAME}${NC}${CYAN}:${CWD}${NC} ${DISKSPACE} ${GIT_STATUS}"
    else
      info+="${CYAN}:${CWD}${NC}"
      # INFO_LINE="${MAGENTA}$USER${CYAN}:${CWD}${NC} ${DISKSPACE} ${GIT_STATUS}"
    fi
  else
    info+="${CYAN}:${CWD}${NC}"
    # INFO_LINE="${MAGENTA}$USER${CYAN}:${CWD}${NC} ${DISKSPACE} ${GIT_STATUS}"
  fi

  if $ENABLE_DOCKER; then
    if [[ -n "$(__get_docker_container__)" ]]; then
      DOCKER_LINE=$(__get_docker_container__)$'\n'
      info="${DOCKER_LINE}${info}"
    else
      DOCKER_LINE=""
    fi
  else
    DOCKER_LINE=""
  fi

  if $ENABLE_DISKSPACE; then
    DISKSPACE="$(__get_diskspace__)"

    info+=" ${DISKSPACE}"
  fi

  if $ENABLE_GIT; then
    GIT_STATUS="$(__get_git_status__)"

    [[ -n "$GIT_STATUS" ]] &&
      info+=" ${GIT_STATUS}"
  fi

  if $ENABLE_UPTIME; then
    UPTIME="$(__get_uptime__)"

    info+=" ${UPTIME}"
  fi

  INFO_LINE="${info}"
}

if $ENABLE_NERDFONTS; then
  __prompt_nerdfont_icon__="" # some other variants..: " "  "" "󰶻 "

  PROMPT_SYMBOL="\${STATUS}${__prompt_nerdfont_icon__} ${NC}"
else
  PROMPT_SYMBOL="\${STATUS}❯ ${NC}"
fi
PROMPT_COMMAND="__update__vars; ${PROMPT_COMMAND}"

# This ensures the docker line is set if a composefile was found. Otherwise does
# NOT generate an empty line above
PS1="\n\${INFO_LINE}\n${PROMPT_SYMBOL}"
