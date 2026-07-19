# vim:ft=sh
# ╭────────────╮
# │  Settings  │
# ╰────────────╯

# Bash only
# shellcheck disable=SC2317
if [ -z "${BASH_VERSION}" ]; then
  echo "pure.bash: requires bash" >&2
  return 1 2>/dev/null || exit 1
fi

PURE_CONFIG_FILE="${HOME}/.purerc"

# shellcheck disable=SC1090
[[ -e "${PURE_CONFIG_FILE}" ]] &&
  . "${PURE_CONFIG_FILE}"

: "${ENABLE_NERDFONTS:=true}"
: "${ENABLE_GIT:=true}"
: "${ENABLE_SSH:=true}"
: "${ENABLE_DOCKER:=true}"
: "${ENABLE_YAZI:=true}"
: "${ENABLE_DISKSPACE:=true}"
: "${ENABLE_UPTIME:=false}"

: "${ENABLE_ERROR_CODES:=true}"
: "${INFO_LINE_ON_NEWLINE:=true}"

: "${DOCKER_SANITIZE_NAME:=false}"

: "${USER_PROMPT_SYMBOL:=""}"
: "${USER_SSH_PROMPT_SYMBOL:="󰢹"}"

: "${PURE_THEME:=gruvbox}"

declare -Ag PURE=(
  ["bold"]=$'\\[\e[1m\\]'
  ["bolt"]=$'\\[\e[1m\\]'
  ["italic"]=$'\\[\e[3m\\]'
  ["blink"]=$'\\[\e[5m\\]'
  ["underline"]=$'\\[\e[4m\\]'
  ["undercurl"]=$'\\[\e[4m\\]'
  ["strike"]=$'\\[\e[9m\\]'
  ["invert"]=$'\\[\e[7m\\]'
  ["reset"]=$'\\[\e[0m\\]'
  ["nc"]=$'\\[\e[0m\\]'
)

case "$PURE_THEME" in
tokyonight | gruvbox | 8bit | ayu) ;;
*) PURE_THEME="ayu" ;;
esac

case "$PURE_THEME" in
tokyonight)
  PURE+=(
    ["grey"]=$'\\[\e[38;2;92;92;92m\\]'
    ["black"]=$'\\[\e[38;2;7;11;20m\\]'
    ["red"]=$'\\[\e[38;2;255;85;119m\\]'
    ["green"]=$'\\[\e[38;2;99;191;132m\\]'
    ["yellow"]=$'\\[\e[38;2;255;199;120m\\]'
    ["blue"]=$'\\[\e[38;2;124;160;255m\\]'
    ["magenta"]=$'\\[\e[38;2;212;162;255m\\]'
    ["cyan"]=$'\\[\e[38;2;139;199;225m\\]'
    ["white"]=$'\\[\e[38;2;197;203;215m\\]'
    ["orange"]=$'\\[\e[38;2;255;158;100m\\]'
  )
  ;;
gruvbox)
  PURE+=(
    ["grey"]=$'\\[\e[38;2;146;131;116m\\]'
    ["black"]=$'\\[\e[38;2;40;40;40m\\]'
    ["red"]=$'\\[\e[38;2;204;36;29m\\]'
    ["green"]=$'\\[\e[38;2;152;151;26m\\]'
    ["yellow"]=$'\\[\e[38;2;215;153;33m\\]'
    ["blue"]=$'\\[\e[38;2;69;133;136m\\]'
    ["magenta"]=$'\\[\e[38;2;177;98;134m\\]'
    ["cyan"]=$'\\[\e[38;2;104;157;106m\\]'
    ["white"]=$'\\[\e[38;2;235;219;178m\\]'
    ["orange"]=$'\\[\e[38;2;214;93;14m\\]'
  )
  ;;
8bit)
  PURE+=(
    ["grey"]=$'\\[\e[38;2;92;92;92m\\]'
    ["black"]=$'\\[\e[38;2;15;15;15m\\]'
    ["red"]=$'\\[\e[38;2;255;0;57m\\]'
    ["green"]=$'\\[\e[38;2;10;255;10m\\]'
    ["yellow"]=$'\\[\e[38;2;255;255;73m\\]'
    ["blue"]=$'\\[\e[38;2;0;105;255m\\]'
    ["magenta"]=$'\\[\e[38;2;255;105;255m\\]'
    ["cyan"]=$'\\[\e[38;2;105;255;255m\\]'
    ["white"]=$'\\[\e[38;2;250;250;250m\\]'
    ["orange"]=$'\\[\e[38;2;255;165;0m\\]'
  )
  ;;
ayu)
  PURE+=(
    ["grey"]=$'\[\e[38;2;91;98;120m\]'      # #5B6278
    ["black"]=$'\[\e[38;2;11;19;30m\]'      # #0B131E
    ["red"]=$'\[\e[38;2;255;51;102m\]'      # #FF3366
    ["green"]=$'\[\e[38;2;186;218;85m\]'    # #BADA55
    ["yellow"]=$'\[\e[38;2;255;203;107m\]'  # #FFCB6B
    ["blue"]=$'\[\e[38;2;57;186;230m\]'     # #39BAE6
    ["magenta"]=$'\[\e[38;2;211;134;155m\]' # #D3869B
    ["cyan"]=$'\[\e[38;2;149;230;203m\]'    # #95E6CB
    ["white"]=$'\[\e[38;2;230;225;220m\]'   # #E6E1DC
    ["orange"]=$'\[\e[38;2;255;180;84m\]'   # #FFB454
  )
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
  DISKSPACE_ICONS_NF=(󰪞 󰪟 󰪠 󰪡 󰪢 󰪣 󰪤 󰪥)
else
  __prompt_nerdfont_icon__="${USER_PROMPT_SYMBOL:-❯}"
  DISKSPACE_ICONS_NF=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
fi

cmd:exists() {
  command -v "$@" >/dev/null 2>&1
}

if $ENABLE_DOCKER; then
  if ! cmd:exists docker; then
    ENABLE_DOCKER=false
  fi
fi

if $ENABLE_GIT; then
  if ! cmd:exists git; then
    ENABLE_GIT=false
  fi
fi

if $ENABLE_DISKSPACE; then
  if ! cmd:exists df; then
    ENABLE_DISKSPACE=false
  fi
fi

if $ENABLE_UPTIME; then
  if ! cmd:exists uptime; then
    ENABLE_UPTIME=false
  fi
fi

if $ENABLE_YAZI; then
  if ! cmd:exists yazi; then
    ENABLE_YAZI=false
  fi
fi

__pure_get_diskspace_icon__() {
  local arg=$1
  arg=$((arg * ${#DISKSPACE_ICONS_NF[@]} / 101))
  echo -n "${DISKSPACE_ICONS_NF[$arg]} "
}

__get_diskspace__() {
  local space avail unit icon perc data

  data=($(df -h . | tail -1))

  avail=${data[1]}
  perc=${data[4]}

  space=${data[3]}
  unit=${space: -1}

  perc=${perc%\%}
  avail=${avail%"$unit"}
  space=${space%"$unit"}

  icon=$(__pure_get_diskspace_icon__ "${perc}")

  if ((perc >= 88)); then
    echo -n "${BRA_LEFT}${PURE[bold]}${PURE[red]}${icon:-}${space}${unit}${PURE[nc]}${BRA_RIGHT}"
  elif ((perc >= 75)); then
    echo -n "${BRA_LEFT}${PURE[bold]}${PURE[magenta]}${icon:-}${space}${unit}${PURE[nc]}${BRA_RIGHT}"
  elif ((perc >= 44)); then
    echo -n "${BRA_LEFT}${PURE[bold]}${PURE[yellow]}${icon:-}${space}${unit}${PURE[nc]}${BRA_RIGHT}"
  else
    echo -n "${BRA_LEFT}${PURE[bold]}${PURE[green]}${icon:-}${space}${unit}${PURE[nc]}${BRA_RIGHT}"
  fi
}

__get_remote_status__() {
  local pure_git_raw_remote_status
  local UNPULLED

  pure_git_raw_remote_status=$(git status --porcelain=2 --branch | command grep --only-matching --perl-regexp '\+\d+ \-\d+')

  UNPULLED=$(echo ${pure_git_raw_remote_status} | command grep --only-matching --perl-regexp '\-\d')
  if [[ ${UNPULLED} != "-0" ]]; then
    pure_git_unpulled=true
  else
    pure_git_unpulled=false
  fi

  UNPUSHED=$(echo ${pure_git_raw_remote_status} | command grep --only-matching --perl-regexp '\+\d')
  if [[ ${UNPUSHED} != "+0" ]]; then
    pure_git_unpushed=true
  else
    pure_git_unpushed=false
  fi

  # if unpulled -> ⇣
  # if unpushed -> ⇡
  # if both (branched from remote) -> *
  if ${pure_git_unpulled}; then
    if ${pure_git_unpushed}; then
      echo -n "${PURE[red]}${pure_symbol_unpulled}${pure_symbol_unpushed}${PURE[nc]}"
    else
      echo -n "${PURE[bold]}${PURE[red]}${pure_symbol_unpulled}${PURE[nc]}"
    fi
  elif ${pure_git_unpushed}; then
    echo -n "${PURE[bold]}${PURE[blue]}${pure_symbol_unpushed}${PURE[nc]}"
  fi
}

__get_git_status__() {
  local git_status=""

  pure_symbol_unpulled="${PURE[bold]}${PURE[blue]} ⇣${PURE[nc]}"
  pure_symbol_unpushed="${PURE[bold]}${PURE[magenta]} ⇡${PURE[nc]}"
  pure_symbol_dirty="${PURE[bold]}${PURE[red]} *${PURE[nc]}"

  if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == "true" ]]; then

    git_status="$(git branch --show-current)"

    [[ -n "${git_status}" ]] || git_status="HEAD"

    git diff --quiet &>/dev/null

    local err=$?

    if ((err != 0)); then
      diff="$pure_symbol_dirty"
    else
      diff=""
    fi

    git_status="${PURE[grey]}${git_status}${PURE[nc]}"

    git_status="${git_status}${diff}"

    if [[ -n $(git remote show) ]]; then
      git_status+="$(__get_remote_status__)"
    fi
  fi

  if [[ -n "${git_status}" ]]; then
    echo -n "${BRA_LEFT}${git_status}${BRA_RIGHT}"
  fi
}

__sanitize_docker_project_name__() {
  local name=$1 length newname="" i char accum=0 dots=false
  local first=true
  local after=2
  length=${#name}

  if $DOCKER_SANITIZE_NAME; then
    for ((i = 0; i < "$length"; i++)); do
      char=${name:${i}:1}
      if [[ "${char}" =~ ([a-z]|[A-Z]|[0-9]) ]]; then
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

    echo -n "${newname}"
  else
    echo -n "${name}"
  fi
}

__get_docker_container__() {
  local compose_file=""
  local dir="$PWD"
  local service temp_compose_status

  if $ENABLE_NERDFONTS; then
    local icon="${PURE[blue]} ${PURE[nc]}"
  fi

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

    ((${#project_name} > 8)) && {
      project_name="$(__sanitize_docker_project_name__ "${project_name}")"
    }

    docker_compose_services=($(docker compose -f "$compose_file" ps --status running --services))
    if ((${#docker_compose_services[@]} > 0)); then
      for service in "${docker_compose_services[@]}"; do
        service=$(__sanitize_docker_project_name__ "${service}")
        temp_compose_status+="${BRA_LEFT}${PURE[blue]}${service} ${PURE[bold]}${PURE[green]}(up)${BRA_RIGHT}${PURE[nc]} "
      done

      [[ -n "${temp_compose_status}" ]] &&
        pure_compose_status=${temp_compose_status}
    else
      pure_compose_status="${BRA_LEFT}${PURE[bold]}${PURE[red]}${project_name} ${PURE[red]}(down)${BRA_RIGHT}${PURE[nc]}"
    fi
  else
    pure_compose_status=""
  fi

  if [[ -n "${pure_compose_status}" ]]; then
    echo -n "${icon} ${pure_compose_status}"
  fi
}

__get_uptime__() {
  local ut=$(uptime -p)

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
    UPTIME_COLOR=${PURE[orange]}
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

  [[ -n "${ut}" ]] || return

  ut=${ut/ minutes/"${PURE[bold]}${PURE[yellow]}m${PURE[nc]}"}
  ut=${ut/ minute/"${PURE[bold]}${PURE[yellow]}m${PURE[nc]}"}

  ut=${ut/ hours/"${PURE[bold]}${PURE[orange]}h${PURE[nc]}"}
  ut=${ut/ hour/"${PURE[bold]}${PURE[orange]}h${PURE[nc]}"}

  ut=${ut/ days/"${PURE[bold]}${PURE[red]}d${PURE[nc]}"}
  ut=${ut/ day/"${PURE[bold]}${PURE[red]}d${PURE[nc]}"}

  ut=${ut/ weeks/"${PURE[bold]}${PURE[cyan]}W${PURE[nc]}"}
  ut=${ut/ week/"${PURE[bold]}${PURE[cyan]}W${PURE[nc]}"}

  ut=${ut/ months/"${PURE[bold]}${PURE[blue]}M${PURE[nc]}"}
  ut=${ut/ month/"${PURE[bold]}${PURE[blue]}M${PURE[nc]}"}

  ut=${ut/ years/"${PURE[bold]}${PURE[magenta]}Y${PURE[nc]}"}
  ut=${ut/ year/"${PURE[bold]}${PURE[magenta]}Y${PURE[nc]}"}

  echo -n "${BRA_LEFT}${ut}${BRA_RIGHT}"
}

__setup_info_bar__() {
  local container
  local user="" info=""
  local CWD USERCOLOR

  if [[ "$USER" == "root" ]]; then
    USERCOLOR="${PURE[red]}${PURE[bold]}"
  else
    USERCOLOR="${PURE[magenta]}"
  fi

  CWD=${PWD/"$HOME"/"~"}

  if $ENABLE_SSH && [[ -n $SSH_CONNECTION ]]; then
    user="${PURE[bold]}${USERCOLOR}${USER}${PURE[red]}@${HOSTNAME}${PURE[nc]}${PURE[cyan]}:${CWD}${PURE[nc]}"
  else
    user="${USERCOLOR}${USER}${PURE[nc]}${PURE[cyan]}:${CWD}${PURE[nc]}"
  fi

  MODULES=()

  if $ENABLE_DOCKER; then
    container=$(__get_docker_container__)

    if [[ -n "${container}" ]]; then
      info="${info}${container}"$'\n'
    fi
  fi

  if $ENABLE_DISKSPACE; then
    MODULES+=("$(__get_diskspace__)")
  fi

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
    echo -n "${info}"$'\n'"${user}"
  else
    echo -n "${user} ${info}"
  fi
}

__build_ps1() {
  local err=$?
  local status="" info_line="" yazi_term=""

  if ((err == 0)); then
    status="${PURE[magenta]}"
  else
    if $ENABLE_ERROR_CODES; then
      status="${PURE[red]}(${err}) ${PURE[magenta]}"
    else
      status="${PURE[red]}"
    fi
  fi

  info_line=$(__setup_info_bar__)

  if $ENABLE_YAZI; then
    if [ -n "$YAZI_LEVEL" ]; then
      yazi_term="${PURE[bold]}${PURE[red]} |  Yazi terminal:${PURE[nc]} "
    fi
  fi

  local prompt_symbol="${status}${__prompt_nerdfont_icon__} ${PURE[nc]}"

  PS1="\n${info_line}${yazi_term}\n${prompt_symbol}"
}

PROMPT_COMMAND="__build_ps1; ${PROMPT_COMMAND}"
