#!/usr/bin/env bash

# INFO:
# ╭─────────────────────────────────────────────────────────╮
# │ pure prompt on bash                                     │
# │ extended with git/docker(-compose)/filesize information │
# │                                                         │
# │ Author: Alexander Pieck (pika)                          │
# ╰─────────────────────────────────────────────────────────╯
ENABLE_SSH=false

FIRST_LINE=""
SECOND_LINE=""
PROMPT_COMMAND=""

ENABLE_DISKSPACE=true      # set to false to disable diskspace
ENABLE_DOCKER_DISPLAY=true # set to false to disable docker compose project detection and display
ENABLE_GIT_DISPLAY=true    # set to false to disable git status
DISK_THRESHHOLD=24         # how much GB is considered to be "low" -> red/orange colored
DOCKER_STRIP_NAME=false    # set this to true, to strip the name when it is too long

command-exists() {
  command -v "$@" >/dev/null 2>&1
}

get-icon() {
  local arg=$1 bar

  if command-exists spark; then
    bar=$(spark $arg,100)
    bar=${bar:0:1}

    printf "%s " "$bar"
  fi
}

__pure_diskspace_async=true # set to false to disable async fetch for diskspace
diskspace() {
  local space avail unit icon perc data
  data=($(df -h . | tail -1))

  space=${data[3]}
  avail=${data[1]}
  perc=${data[4]}

  # space=$(df -h . | tail -1 | awk '{print $4}')
  # avail=$(df -h . | tail -1 | awk '{print $2}')
  # perc=$(df -h . | tail -1 | awk '{print $5}')
  perc=${perc%\%}

  avail=${avail%*G}
  avail=${avail%*T}
  unit=${space: -1}

  icon=$(get-icon "${perc}")

  # displays the threshold in colors
  if ((${space%*"${unit}"} > avail / 2)); then
    printf "${BRIGHT_GREEN}${icon:-}%s${RESET}" "$space"
  elif ((${space%*"${unit}"} > DISK_THRESHHOLD)); then
    printf "${BRIGHT_YELLOW}${icon:-}%s${RESET}" "$space"
  else
    printf "${BRIGHT_RED}${icon:-}%s${RESET}" "$space"
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
sanitize-project-name() {
  local name=$1 length newname="" i char accum=0 dots=false
  local first=true
  local after=2
  length=${#name}

  if $DOCKER_STRIP_NAME; then
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

# Colors
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT_BLACK=$(tput setaf 8)
BRIGHT_RED=$(tput setaf 9)
BRIGHT_GREEN=$(tput setaf 10)
BRIGHT_YELLOW=$(tput setaf 11)
BRIGHT_BLUE=$(tput setaf 12)
BRIGHT_MAGENTA=$(tput setaf 13)
BRIGHT_CYAN=$(tput setaf 14)

BRA_LEFT="${BRIGHT_BLACK}[${RESET}"
BRA_RIGHT="${BRIGHT_BLACK}]${RESET}"

readonly RESET=$(tput sgr0)

# symbols
pure_prompt_symbol="❯"
pure_symbol_unpulled="⇣"
pure_symbol_unpushed="⇡"
pure_symbol_dirty="*"
# pure_git_stash_symbol="≡"

# if this value is true, remote status update will be async
pure_git_async_update=true
pure_git_raw_remote_status="+0 -0"

__pure_echo_git_remote_status() {
  # get unpulled & unpushed status
  # if ${pure_git_async_update}; then
  # do async
  # FIXME: this async execution doesn't change pure_git_raw_remote_status. so remote status never changes in async mode
  # FIXME: async mode takes as long as sync mode
  # pure_git_raw_remote_status=$(git status --porcelain=2 --branch | command grep --only-matching --perl-regexp '\+\d+ \-\d+') &
  # else
  # do sync
  pure_git_raw_remote_status=$(git status --porcelain=2 --branch | command grep --only-matching --perl-regexp '\+\d+ \-\d+')
  # fi

  # shape raw status and check unpulled commit
  local readonly UNPULLED=$(echo ${pure_git_raw_remote_status} | command grep --only-matching --perl-regexp '\-\d')
  if [[ ${UNPULLED} != "-0" ]]; then
    pure_git_unpulled=true
  else
    pure_git_unpulled=false
  fi

  # unpushed commit too
  local readonly UNPUSHED=$(echo ${pure_git_raw_remote_status} | command grep --only-matching --perl-regexp '\+\d')
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
      echo "${RED}${pure_symbol_unpulled}${pure_symbol_unpushed}${RESET}"
    else
      echo "${BRIGHT_RED}${pure_symbol_unpulled}${RESET}"
    fi

  elif ${pure_git_unpushed}; then
    echo "${BRIGHT_BLUE}${pure_symbol_unpushed}${RESET}"
  fi
}

__pure_update_git_status() {

  local git_status=""

  # if current directory isn't git repository, skip this
  if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == "true" ]]; then

    git_status="$(git branch --show-current)"

    # check clean/dirty
    git_status="${git_status}$(git diff --quiet || echo "${pure_symbol_dirty}")"

    # coloring
    git_status="${BRIGHT_BLACK}${git_status}${RESET}"

    # if repository have no remote, skip this
    if [[ -n $(git remote show) ]]; then
      git_status="${git_status} $(__pure_echo_git_remote_status)"
    fi
  fi

  pure_git_status=${git_status}
}

# detect remote session and if so display user and host
# if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]]; then
if ((${#SSH_CLIENT} > 0 || ${#SSH_TTY} > 0 || ${#SSH_CONNECTION} > 0)); then
  ENABLE_SSH=true
else
  ENABLE_SSH=false
fi

# if last command failed, change prompt color
__pure_echo_prompt_color() {

  if [[ $? = 0 ]]; then
    echo ${pure_user_color}
  else
    echo ${RED}
  fi
}

__pure_update_prompt_color() {
  pure_prompt_color=$(__pure_echo_prompt_color)
  if ${__pure_diskspace_async}; then
    DISK_SPACE=$(diskspace &)
  else
    DISK_SPACE=$(diskspace 2>/dev/null)
  fi

  SPACING=$(create-spacer)
}

create-spacer() {
  local cols diff grmstaus

  # if git status &>/dev/null; then
  #   grmstatus=$(__pure_echo_git_remote_status)
  #   grmstatus="${grmstatus}igitt"
  #   diff=$((${#PWD} + ${#USER} + ${#grmstatus} + 1))
  # else
  #   diff=$((${#PWD} + ${#USER}))
  # fi

  diff=$((${#PWD} + ${#USER} + ${#DISK_SPACE} - 8))

  cols=$((COLUMNS - diff))

  for ((i = 0; i < cols; i++)); do
    printf " "
  done
}

__pure_update_compose_status() {
  local compose_file=""
  local dir="$PWD"
  local service temp_compose_status

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
      project_name="$(sanitize-project-name "${project_name}")"
      # project_name="${project_name:0:5}.."
    }

    # check if containers are up
    docker_compose_services=($(docker compose -f "$compose_file" ps --status running --services))
    if ((${#docker_compose_services[@]} > 0)); then
      # if docker compose -f "$compose_file" ps --status running >/dev/null 2>&1; then
      # if [[ $(docker compose -f "$compose_file" ps --status running --services 2>/dev/null | wc -l) -gt 0 ]]; then
      for service in "${docker_compose_services[@]}"; do
        service=$(sanitize-project-name "${service}")
        temp_compose_status+="${BRA_LEFT}${BLUE}${service}${BRIGHT_GREEN}(up)${BRA_RIGHT}${RESET} " # keep the space to space out the projects
      done

      [[ -n "${temp_compose_status}" ]] &&
        pure_compose_status=${temp_compose_status}
    else
      pure_compose_status="${BRA_LEFT}${RED}${project_name}${BRIGHT_RED}(down)${BRA_RIGHT}${RESET}"
    fi
    # else
    #   pure_compose_status="${YELLOW}${project_name}(?)${RESET}"
    # fi
  else
    pure_compose_status=""
  fi
}

# if user is root, prompt is BRIGHT_YELLOW
case ${UID} in
0) pure_user_color=${BRIGHT_YELLOW} ;;
*) pure_user_color=${BRIGHT_MAGENTA} ;;
esac

# if git isn't installed when shell launches, git integration isn't activated -
# same for docker
if $ENABLE_GIT_DISPLAY; then
  if command-exists git; then
    # PROMPT_COMMAND+="; __pure_update_prompt_color"
    PROMPT_COMMAND="__pure_update_git_status; ${PROMPT_COMMAND}"
  fi
fi

if $ENABLE_DOCKER_DISPLAY; then
  DOCKER_LINE=""

  if command-exists docker; then
    PROMPT_COMMAND="__pure_update_compose_status; ${PROMPT_COMMAND}"
    DOCKER_LINE="\${pure_compose_status}\n"
  fi
fi

PROMPT_COMMAND="__pure_update_prompt_color; ${PROMPT_COMMAND}"

# : "${SPACING:=$(create-spacer)}"

if $ENABLE_DISKSPACE; then
  # FIRST_LINE="${USER_HOST}${CYAN}\w ${BRA_LEFT}\${DISK_SPACE}${BRA_RIGHT}\${SPACING}${MAGENTA}\${pure_git_status}\n"
  FIRST_LINE="${USER_HOST}${CYAN}\w ${BRA_LEFT}\${DISK_SPACE}${BRA_RIGHT} ${MAGENTA}\${pure_git_status}\n"
else
  FIRST_LINE="${USER_HOST}${CYAN}\w \${pure_git_status}\n"
fi

# raw using of $ANY_COLOR (or $(tput setaf ***)) here causes a creepy bug when go back history with up arrow key
# I couldn't find why it occurs
SECOND_LINE="\[\${pure_prompt_color}\]${pure_prompt_symbol}\[$RESET\] "
if $ENABLE_SSH; then
  PS1="\n${DOCKER_LINE}${pure_user_color}\u${RED}@\h:${FIRST_LINE}${SECOND_LINE}"
else
  PS1="\n${DOCKER_LINE}${pure_user_color}\u:${FIRST_LINE}${SECOND_LINE}"
fi

PS2="\[$BLUE\]${prompt_symbol}\[$RESET\] "

if command-exists zoxide; then
  eval "$(zoxide init bash)"
fi
