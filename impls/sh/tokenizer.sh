CHR_AT() {
  R="$(awk -- "BEGIN {print substr(ARGV[1], $2, 1)}" "$1")"
}

EOL_AT() {
  ORD_AT "$1" $2
  case $R in
    10 | 13) return 0;;
    *)       return 1;;
  esac
}

NEXT_TOKEN() {
  ORD_AT "$T" $S

  if [ $R -le 32 ] || [ $R -eq 44 ]; then
    S=$((S+1))
    unset R; return 1
  fi

  CHR_AT "$T" $S; __chr=$R

  case "$__chr" in
    "[" | "]" | "{" | "}" | "(" | ")" | "'" | '`' | "^" | "@")
      R="$__chr"
      S=$((S+1))
      ;;
    "~")
      CHR_AT "$T" $((S+1))
      if [ "$R" = "@" ]; then
        R="~@"
        S=$((S+2))
      else
        R="$__chr"
        S=$((S+1))
      fi
      ;;
    ";")
      __s=$((S+1))
      while :; do
        __s=$((__s+1))
        if [ $__s -gt $1 ] || EOL_AT "$T" $__s; then
          break
        fi
      done
      S=$__s; unset __chr R __s; return 1
      ;;
    '"')
      __s=$((S+1))
      while :; do
        CHR_AT "$T" $__s; __chr=$R
        case "$__chr" in
          '"')   break         ;;
          "\\")  __s=$((__s+2));;
          *)     __s=$((__s+1));;
        esac
        if [ $__s -gt $1 ]; then
            _error 'expected ", got EOF'; S=$__s; unset __chr R __s; return 1
        fi
      done
      R="$(awk -- "BEGIN {print substr(ARGV[1], $S, $((__s-S+1)))}" "$T")"
      S=$((__s+1))
      ;;
    *)
      __s=$S
      while [ $__s -le $1 ] && ! SEP_AT "$T" $__s; do
        __s=$((__s+1))
      done
      R="$(awk -- "BEGIN {print substr(ARGV[1], $S, $((__s-S)))}" "$T")"
      S=$__s
      ;;
  esac

  unset __chr __s
}

ORD_AT() {
  R=$(awk -- "BEGIN {print substr(ARGV[1], $2, 1)}" "$1" |
        od -An -t uC |
        awk '{ print $1 }')
}

SEP_AT() {
  if EOL_AT "$1" $2; then
    return
  fi

  CHR_AT "$1" $2
  case "$R" in
    " " | "[" | "]" | "{" | "}" | "(" | ")" | "'" | '"' | '`' | "," | ";")
      return 0
      ;;
  esac

  return 1
}

TOKENIZE() {
  if [ $# -ne 0 ]; then
    T="$@"
  else
    T="$R"
  fi

  TABLE_CLEAR TOKEN

  set -- $(printf "%s" "$T" | wc -m)

  S=1

  while [ $S -le $1 ]; do
    if NEXT_TOKEN $1; then
      TABLE_PUSH TOKEN
    fi
  done

  unset R S T
}

TOKENIZE_DEBUG() {
  __time_start="$(date +"%s.%N")"

  TOKENIZE "$@"

  __time_end="$(date +"%s.%N")"

  TABLE_DUMP TOKEN

  {
    if [ -z "$E" ]; then
      __time_elapsed="$(echo "($__time_end - $__time_start) * 1000" | bc)"
      printf "\n%0.2fms\n" "$__time_elapsed"
    else
      printf "\nerror: %s\n" "$E"
    fi
  } >&2

  unset __time_elapsed __time_end __time_start
  unset R S T
}
