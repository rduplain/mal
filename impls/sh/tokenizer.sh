EOL_AT() {
  TABLE_GET TOKEN_ORD $1
  case $R in
    012 | 015) return 0;;
    *)         return 1;;
  esac
}

NEXT_TOKEN() {
  TABLE_GET TOKEN_ORD $S

  if [ $R -le 040 ] || [ $R -eq 054 ]; then
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

  TABLE_CLEAR TOKEN
  TABLE_CLEAR TOKEN_CHR
  TABLE_CLEAR TOKEN_ORD

  S=1
  for ord in $(printf "%s" "$T" | od -An -b -w256); do
    eval "chr=\$CHR_$ord"
    TABLE_PUSH TOKEN_CHR "$chr"
    TABLE_PUSH TOKEN_ORD "$ord"
    S=$((S+1))
  done

  set -- $S

  S=1
  while [ $S -lt $1 ]; do
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
