CHR_AT() {
  R="$(awk -- "BEGIN {print substr(ARGV[1], $2, 1)}" "$1")"
}

EOL_AT() {
  TABLE_GET TOKEN_ORD $1
  case $R in
    10 | 13) return 0;;
    *)       return 1;;
  esac
}

NEXT_TOKEN() {
  TABLE_GET TOKEN_ORD $S

  if [ $R -le 32 ] || [ $R -eq 44 ]; then
    S=$((S+1))
    unset R; return 1
  fi

  TABLE_GET TOKEN_CHR $S

  case "$R" in
    "[" | "]" | "{" | "}" | "(" | ")" | "'" | '`' | "^" | "@")
      S=$((S+1))
      ;;
    "~")
      R_STACK_PUSH
      TABLE_GET TOKEN_CHR $((S+1))
      if [ "$R" = "@" ]; then
        R_STACK_POP
        R="~@"
        S=$((S+2))
      else
        R_STACK_POP
        S=$((S+1))
      fi
      ;;
    ";")
      __s=$((S+1))
      while :; do
        __s=$((__s+1))
        if [ $__s -gt $1 ] || EOL_AT $__s; then
          break
        fi
      done
      S=$__s; unset R __s; return 1
      ;;
    '"')
      __s=$((S+1))
      while :; do
        TABLE_GET TOKEN_CHR $__s
        case "$R" in
          '"')   break         ;;
          "\\")  __s=$((__s+2));;
          *)     __s=$((__s+1));;
        esac
        if [ $__s -gt $1 ]; then
            E='expected ", got EOF'; S=$__s; unset R __s; return 1
        fi
      done
      R="$(awk -- "BEGIN {print substr(ARGV[1], $S, $((__s-S+1)))}" "$T")"
      S=$((__s+1))
      ;;
    *)
      __s=$S
      while [ $__s -le $1 ] && ! SEP_AT $__s; do
        __s=$((__s+1))
      done
      R="$(awk -- "BEGIN {print substr(ARGV[1], $S, $((__s-S)))}" "$T")"
      S=$__s
      ;;
  esac

  unset __s
}

ORD_AT() {
  R=$(awk -- "BEGIN {print substr(ARGV[1], $2, 1)}" "$1" |
        od -An -t uC |
        awk '{ print $1 }')
}

SEP_AT() {
  if EOL_AT $1; then
    return
  fi

  TABLE_GET TOKEN_CHR $1
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

  set -- $(printf "%s" "$T" | wc -m)

  TABLE_CLEAR TOKEN
  TABLE_CLEAR TOKEN_CHR
  TABLE_CLEAR TOKEN_ORD

  S=1
  while [ $S -le $1 ]; do
    R=
    CHR_AT "$T" $S
    R_STACK_PUSH
    TABLE_PUSH TOKEN_CHR
    R_STACK_POP
    eval "R=$(printf "%d" "'$R")"
    if [ $R -eq 0 ]; then ORD_AT "$T" $S; fi
    TABLE_PUSH TOKEN_ORD
    S=$((S+1))
  done

  S=1
  while [ $S -le $1 ]; do
    if NEXT_TOKEN $1; then
      TABLE_PUSH TOKEN
    fi
  done

  unset R S T
}

TOKENIZE_DEBUG() {
  TIMEIT TOKENIZE "$@"; echo >&2
  TABLE_DUMP TOKEN
  unset R S T
}
