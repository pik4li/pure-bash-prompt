# vim:ft=sh
# ╭────────────╮
# │  Settings  │
# ╰────────────╯
PURE_CONFIG_FILE="${HOME}/.purerc"

[[ -e "${PURE_CONFIG_FILE}" ]] &&
  . "${PURE_CONFIG_FILE}" # source the config file if it exists.

: "${ENABLE_NERDFONTS:=true}" # set to `false` if you do not have nerdfonts installed
: "${ENABLE_GIT:=true}"       # set to `false` to disable GIT module
: "${ENABLE_SSH:=true}"       # set to `false` to disable SSH module
: "${ENABLE_DOCKER:=true}"    # set to `false` to disable DOCKER module
: "${ENABLE_YAZI:=true}"      # set to `false` to enable YAZI module
: "${ENABLE_DISKSPACE:=true}" # set to `false` to disable DISKSPACE module
: "${ENABLE_UPTIME:=false}"   # set to `true`  to enable UPTIME module

: "${ENABLE_ERROR_CODES:=true}"   # set to `false` to disable the error codes inline
: "${INFO_LINE_ON_NEWLINE:=true}" # set to `false` to set the info line next to the user line

: "${DOCKER_SANITIZE_NAME:=false}"

# INFO:
# You can set different symbols for your prompts (ssh and normal) if you'd like to

: "${USER_PROMPT_SYMBOL:=""}"     # you can set a symbol for a prompt here | some other variants..: "¶" " "  "" "󰶻 "
: "${USER_SSH_PROMPT_SYMBOL:="󰢹"}" # lets you choose a different symbol for ssh connections. If you dont want that, just copy the USER_PROMPT_SYMBOL to this var

# INFO:
# set custom left and right separators for the widgts like git, docker, diskspace,  uptime..
# you can for example set ( and ) | Default is [ and ]

# SEPARATOR_LEFT="("
# SEPARATOR_RIGHT=")"

## CAUTION:
## --------------------------------------------------------------------------
## Do not edit anything beyond this line, unless you know what you are doing!
## --------------------------------------------------------------------------

: "${PURE_THEME:=gruvbox}"
declare -Ag PURE=(
  ["bold"]=$'\e[1m'
  ["bolt"]=$'\e[1m'
  ["italic"]=$'\e[3m'
  ["blink"]=$'\e[5m'
  ["underline"]=$'\e[4m'
  ["undercurl"]=$'\e[4m'
  ["strike"]=$'\e[9m'
  ["invert"]=$'\e[7m'
  ["reset"]=$'\e[0m'
  ["nc"]=$'\e[0m'
) # for echo and stuff (ansi sequences)

case "$PURE_THEME" in
tokyonight)
  PURE+=(
    ["grey"]=$'\e[38;5;239m'
    ["black"]=$'\e[38;2;7;11;20m'       # #070B14 (bg/darker)
    ["red"]=$'\e[38;2;255;85;119m'      # #FF5577 (red/pink)
    ["green"]=$'\e[38;2;99;191;132m'    # #63BF84 (green)
    ["yellow"]=$'\e[38;2;255;199;120m'  # #FFC778 (yellow)
    ["blue"]=$'\e[38;2;124;160;255m'    # #7CA0FF (blue)
    ["magenta"]=$'\e[38;2;212;162;255m' # #D4A2FF (magenta/purple)
    ["cyan"]=$'\e[38;2;139;199;225m'    # #8BC7E1 (cyan)
    ["white"]=$'\e[38;2;197;203;215m'   # #C5CBD7 (foreground/light)
  )                                     # the tokyonight colors
  ;;
gruvbox)
  PURE+=(
    ["grey"]=$'\e[38;5;239m'
    ["black"]=$'\e[38;2;40;40;40m'     # #282828
    ["red"]=$'\e[38;2;204;36;29m'      # #CC241D
    ["green"]=$'\e[38;2;152;151;26m'   # #98971A
    ["yellow"]=$'\e[38;2;215;153;33m'  # #D79921
    ["blue"]=$'\e[38;2;69;133;136m'    # #458383
    ["magenta"]=$'\e[38;2;177;98;134m' # #B16286
    ["cyan"]=$'\e[38;2;104;157;106m'   # #688D6A
    ["white"]=$'\e[38;2;235;219;178m'  # #EBDBB2 (foreground/light)
  )                                    # the gruvbox colors
  ;;
esac

BRA_LEFT="${PURE[bold]}${PURE[grey]}${SEPARATOR_LEFT:-"["}${PURE[nc]}"
BRA_RIGHT="${PURE[bold]}${PURE[grey]}${SEPARATOR_RIGHT:-"]"}${PURE[nc]}"

if $ENABLE_NERDFONTS; then
  if [[ -n $SSH_CONNECTION ]]; then
    __prompt_nerdfont_icon__="${USER_SSH_PROMPT_SYMBOL:-${USER_PROMPT_SYMBOL:-}}"
  else
    __prompt_nerdfont_icon__="${USER_PROMPT_SYMBOL:-}"
  fi

  PROMPT_SYMBOL="\${STATUS}${__prompt_nerdfont_icon__} ${PURE[nc]}"

  DISKSPACE_ICONS_NF=(󰪞 󰪟 󰪠 󰪡 󰪢 󰪣 󰪤 󰪥)
else
  PROMPT_SYMBOL="\${STATUS}${USER_PROMPT_SYMBOL:-❯} ${PURE[nc]}"
  DISKSPACE_ICONS_NF=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
fi

# helper function
command-exists() {
  command -v "$@" >/dev/null 2>&1
}

# sanity checks
if $ENABLE_DOCKER; then
  if ! command-exists docker; then
    ENABLE_DOCKER=false
  fi
fi

if $ENABLE_GIT; then
  if ! command-exists git; then
    ENABLE_GIT=false
  fi
fi

if $ENABLE_DISKSPACE; then
  if ! command-exists df; then
    ENABLE_DISKSPACE=false
  fi
fi

if $ENABLE_UPTIME; then
  if ! command-exists uptime; then
    ENABLE_UPTIME=false
  fi
fi

if $ENABLE_YAZI; then
  if ! command-exists yazi; then
    ENABLE_YAZI=false
  fi
fi

__pure_get_diskspace_icon__() {
  local arg=$1

  arg=$((arg * ${#DISKSPACE_ICONS_NF[@]} / 101))
  printf "%s " "${DISKSPACE_ICONS_NF[$arg]}"
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

  if ((perc >= 88)); then
    printf "${BRA_LEFT}${PURE[bold]}${PURE[red]}${icon:-}%s${PURE[nc]}${BRA_RIGHT}" "${space}${unit}"
  elif ((perc >= 75)); then
    printf "${BRA_LEFT}${PURE[bold]}${PURE[magenta]}${icon:-}%s${PURE[nc]}${BRA_RIGHT}" "${space}${unit}"
  elif ((perc >= 44)); then
    printf "${BRA_LEFT}${PURE[bold]}${PURE[yellow]}${icon:-}%s${PURE[nc]}${BRA_RIGHT}" "${space}${unit}"
  else
    printf "${BRA_LEFT}${PURE[bold]}${PURE[green]}${icon:-}%s${PURE[nc]}${BRA_RIGHT}" "${space}${unit}"
  fi
}
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
      printf "%s" "${PURE[red]}${pure_symbol_unpulled}${pure_symbol_unpushed}${PURE[nc]}"
    else
      printf "%s" "${PURE[bold]}${PURE[red]}${pure_symbol_unpulled}${PURE[nc]}"
    fi

  elif ${pure_git_unpushed}; then
    printf "%s" "${PURE[bold]}${PURE[blue]}${pure_symbol_unpushed}${PURE[nc]}"
  fi
}

__get_git_status__() {
  local git_status=""

  pure_symbol_unpulled="${PURE[bold]}${PURE[blue]} ⇣${PURE[nc]}"
  pure_symbol_unpushed="${PURE[bold]}${PURE[magenta]} ⇡${PURE[nc]}"
  pure_symbol_dirty="${PURE[bold]}${PURE[red]} *${PURE[nc]}"

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
    git_status="${PURE[grey]}${git_status}${PURE[nc]}"

    # check clean/dirty
    git_status="${git_status}${diff}"

    # if repository have no remote, skip this
    if [[ -n $(git remote show) ]]; then
      # git_status+="$(__get_remote_status__)"
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
    local icon="${PURE[blue]} ${PURE[nc]}"
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
        temp_compose_status+="${BRA_LEFT}${PURE[blue]}${service} ${PURE[bold]}${GREEN}(up)${BRA_RIGHT}${RESET} " # keep the space to space out the projects
      done

      [[ -n "${temp_compose_status}" ]] &&
        pure_compose_status=${temp_compose_status}
    else
      pure_compose_status="${BRA_LEFT}${PURE[bold]}${PURE[red]}${project_name} ${PURE[red]}(down)${BRA_RIGHT}${RESET}"
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
    UPTIME_COLOR=${PURE[magenta]}
  elif grep -qi "months" <<<"${ut}"; then
    UPTIME_COLOR=${PURE[blue]}
  elif grep -qi "week" <<<"${ut}"; then
    UPTIME_COLOR=${PURE[cyan]}
  elif grep -qi "day" <<<"${ut}"; then
    UPTIME_COLOR=${PURE[red]}
  elif grep -qi "hour" <<<"${ut}"; then
    UPTIME_COLOR=${ORANGE}
  elif grep -qi "minute" <<<"${ut}"; then
    UPTIME_COLOR=${PURE[yellow]}
  else
    UPTIME_COLOR=${PURE[grey]}
  fi

  if $ENABLE_NERDFONTS; then
    ut=${ut/up /"${PURE[bold]}${UPTIME_COLOR}󰔛 ${PURE[nc]}"}
  else
    ut=${ut/up/"${PURE[bold]}${UPTIME_COLOR}up${PURE[nc]}"}
  fi

  # $ut exists, or return nothing
  [[ -n "${ut}" ]] || return

  # ─< replace the fullname with colored symbols >────────────────────────────────
  # redraw minutes
  ut=${ut/ minutes/"${PURE[bold]}${PURE[yellow]}m${PURE[nc]}"}
  ut=${ut/ minute/"${PURE[bold]}${PURE[yellow]}m${PURE[nc]}"}

  # redraw hours
  ut=${ut/ hours/"${PURE[bold]}${ORANGE}h${PURE[nc]}"}
  ut=${ut/ hour/"${PURE[bold]}${ORANGE}h${PURE[nc]}"}

  # redraw days
  ut=${ut/ days/"${PURE[bold]}${PURE[red]}d${PURE[nc]}"}
  ut=${ut/ day/"${PURE[bold]}${PURE[red]}d${PURE[nc]}"}

  # redraw weeks
  ut=${ut/ weeks/"${PURE[bold]}${PURE[cyan]}W${PURE[nc]}"}
  ut=${ut/ week/"${PURE[bold]}${PURE[cyan]}W${PURE[nc]}"}

  # redraw months
  ut=${ut/ months/"${PURE[bold]}${PURE[blue]}M${PURE[nc]}"}
  ut=${ut/ month/"${PURE[bold]}${PURE[blue]}M${PURE[nc]}"}

  # redraw years
  ut=${ut/ years/"${PURE[bold]}${PURE[magenta]}Y${PURE[nc]}"}
  ut=${ut/ year/"${PURE[bold]}${PURE[magenta]}Y${PURE[nc]}"}

  printf "${BRA_LEFT}%s${BRA_RIGHT}" "${ut}"
}

__setup_info_bar__() {
  local -n ptr=${1}
  local container
  local user="" info=""

  local CWD USERCOLOR

  if [[ "$USER" == "root" ]]; then
    USERCOLOR=${PURE[red]}${PURE[bold]}
  else
    USERCOLOR=${PURE[magenta]}
  fi

  user="${USERCOLOR}${USER}${PURE[nc]}"

  # current working directory with $HOME replcaed with ~
  CWD=${PWD/"$HOME"/"~"}

  if $ENABLE_SSH; then
    # for ssh connections
    if [[ -n $SSH_CONNECTION ]]; then
      user="${PURE[bold]}${USERCOLOR}${USER}${PURE[red]}@${HOSTNAME}${PURE[nc]}${PURE[cyan]}:${CWD}${PURE[nc]}"
    else
      user+="${PURE[cyan]}:${CWD}${PURE[nc]}"
    fi
  else
    user+="${PURE[cyan]}:${CWD}${PURE[nc]}"
  fi

  MODULES=()

  if $ENABLE_DOCKER; then
    container=$(__get_docker_container__)

    if [[ -n "${container}" ]]; then
      info+=${container}$'\n'
    fi
  fi

  # first goes to the left
  if $ENABLE_DISKSPACE; then
    MODULES+=("$(__get_diskspace__)")
  fi
  # every other module goes right nextto it

  if $ENABLE_GIT; then
    MODULES+=("$(__get_git_status__)")
  fi

  if $ENABLE_UPTIME; then
    MODULES+=("$(__get_uptime__)")
  fi

  for m in "${MODULES[@]}"; do
    [[ -n "${m}" ]] || continue

    info+="${m} "
  done

  info=${info%" "}

  if $INFO_LINE_ON_NEWLINE; then
    info=${info}$'\n'
    ptr=${info}${user}
  else
    ptr="${user} ${info}"
  fi
}

__update__vars() {
  local err=$? # has to be the first, as it has to evaluate the last command state

  # status color for the prompt symbol
  if ((err == 0)); then
    STATUS=${PURE[magenta]}
  else
    if $ENABLE_ERROR_CODES; then
      STATUS="${PURE[red]}(${err}) ${PURE[magenta]}"
    else
      STATUS="${PURE[red]}"
    fi
  fi

  __setup_info_bar__ INFO_LINE

  if $ENABLE_YAZI; then
    YAZI_TERM=""
    if [ -n "$YAZI_LEVEL" ]; then
      YAZI_TERM="${PURE[bold]}${PURE[red]} |  Yazi terminal:${PURE[nc]} "
    fi
  fi
}

PROMPT_COMMAND="__update__vars; ${PROMPT_COMMAND}"
PS1="\n\${INFO_LINE}\${YAZI_TERM}\n${PROMPT_SYMBOL}"
