EOL_AT() {
  INPUT_ORD_AT $1
  case $R in
    012 | 015) return 0;;
    *)         return 1;;
  esac
}

NEXT_TOKEN() {
  INPUT_ORD_AT $S

  if [ $R -le 040 ] || [ $R -eq 054 ]; then
    S=$((S+1))
    unset R; return 1
  fi

  INPUT_CHR_AT $S

  case "$R" in
    "[" | "]" | "{" | "}" | "(" | ")" | "'" | '`' | "^" | "@")
      S=$((S+1))
      ;;
    "~")
      R_STACK_PUSH
      INPUT_CHR_AT $((S+1))
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
        INPUT_CHR_AT $__s
        case "$R" in
          '"')   break         ;;
          "\\")  __s=$((__s+2));;
          *)     __s=$((__s+1));;
        esac
        if [ $__s -ge $1 ]; then
            E='expected ", got EOF'; S=$__s; unset R __s; return 1
        fi
      done
      SUBSTR $S $__s
      S=$((__s+1))
      ;;
    *)
      __s=$S
      while [ $__s -le $1 ] && ! SEP_AT $__s; do
        __s=$((__s+1))
      done
      SUBSTR $S $((__s-1))
      S=$__s
      ;;
  esac

  unset __s
}

SEP_AT() {
  if EOL_AT $1; then
    return
  fi

  INPUT_CHR_AT $1
  case "$R" in
    " " | "[" | "]" | "{" | "}" | "(" | ")" | "'" | '"' | '`' | "," | ";")
      return 0
      ;;
  esac

  return 1
}

SUBSTR() {
  while [ $1 -le $2 ]; do
    INPUT_CHR_AT $1
    set -- $(($1+1)) $2 "$3$R"
  done
  R="$3"
}

TOKENIZE() {
  if [ $# -ne 0 ]; then
    T="$@"
  else
    T="$R"
  fi

  TOKEN_COUNT=0
  INPUT_CHR_COUNT=0
  INPUT_ORD_COUNT=0

  S=1
  for ord in $(printf "%s" "$T" | od -An -b -w2048); do
    eval "chr=\$CHR_$ord"
    R="$chr"; INPUT_CHR_PUSH
    R="$ord"; INPUT_ORD_PUSH
    S=$((S+1))
  done

  set -- $S

  S=1
  while [ $S -lt $1 ]; do
    if NEXT_TOKEN $1; then
      TOKEN_PUSH
    fi
  done

  unset R S T
}

TOKENIZE_DEBUG() {
  TIMEIT TOKENIZE "$@"; echo >&2

  S=1
  while [ $S -le $TOKEN_COUNT ]; do
    TOKEN_AT $S
    printf "%3d: %s\n" "$S" "$R"
    S=$((S+1))
  done

  unset R S T
}


# INPUT_CHR, INPUT_ORD, TOKEN - Specialized stacks for TOKENIZE.

INPUT_CHR_AT() {
  if [ $1 -gt $INPUT_CHR_COUNT ]; then R=; return 1; fi
  eval "R=\"\$INPUT_CHR_${1}\""
}

INPUT_CHR_PUSH() {
  INPUT_CHR_COUNT=$((INPUT_CHR_COUNT+1))
  eval "INPUT_CHR_${INPUT_CHR_COUNT}=\"\$R\""
}

INPUT_ORD_AT() {
  if [ $1 -gt $INPUT_ORD_COUNT ]; then R=; return 1; fi
  eval "R=\"\$INPUT_ORD_${1}\""
}

INPUT_ORD_PUSH() {
  INPUT_ORD_COUNT=$((INPUT_ORD_COUNT+1))
  eval "INPUT_ORD_${INPUT_ORD_COUNT}=\"\$R\""
}

TOKEN_AT() {
  if [ $1 -gt $TOKEN_COUNT ]; then R=; return 1; fi
  eval "R=\"\$TOKEN_${1}\""
}

TOKEN_PUSH() {
  TOKEN_COUNT=$((TOKEN_COUNT+1))
  eval "TOKEN_${TOKEN_COUNT}=\"\$R\""
}
