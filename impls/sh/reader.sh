READ_ATOM() {
  case "$T" in
    \"*)     STRING  "$T";;
    :*)      KEYWORD "$T";;
    [0-9]*)  NUMBER  "$T";;
    -[0-9]*) NUMBER  "$T";;
    false)   FALSE       ;;
    nil)     NIL         ;;
    true)    TRUE        ;;
    *)       SYMBOL  "$T";;
  esac
}

READ_FORM() {
  TOKEN_AT $S
  T="$R"

  S=$((S+1))

  case "$T" in
    "'" | '`' | "~" | "~@" | "@")
      TABLE_NEW AST
      set -- $R
      case "$T" in
        "'")  SYMBOL quote         ;;
        '`')  SYMBOL quasiquote    ;;
        "~")  SYMBOL unquote       ;;
        "~@") SYMBOL splice-unquote;;
        "@")  SYMBOL deref         ;;
      esac
      TABLE_PUSH $1
      READ_FORM
      TABLE_PUSH $1
      LIST $1
      ;;
    "^")
      TABLE_NEW AST
      set -- $R
      SYMBOL with-meta
      TABLE_PUSH $1
      READ_FORM
      R_STACK_PUSH
      READ_FORM
      TABLE_PUSH $1
      R_STACK_POP
      TABLE_PUSH $1
      LIST $1
      ;;
    "(" | "[" | "{")
      case "$T" in
        "(")
          READ_SEQ ")"
          LIST "$R"
          ;;
        "[")
          READ_SEQ "]"
          VECTOR "$R"
          ;;
        "{")
          READ_HASHMAP "}"
          HASHMAP "$R"
          ;;
      esac
      ;;
    ")" | "]" | "}")
      E="unexpected '$T'"; return 1
      ;;
    *)
      READ_ATOM
      ;;
  esac
}

READ_HASHMAP() {
  TABLE_NEW AST
  set -- $R $1

  while :; do
    TOKEN_AT $S
    T="$R"

    if [ -z "$T" ]; then
      E="expected '$2', got EOF"; return 1
    fi

    if [ "$T" = "$2" ]; then
      S=$((S+1))
      break
    fi

    READ_FORM
    if [ -z "$3" ]; then
      set -- $1 $2 $R
    else
      TABLE_SET $1 $3
      set -- $1 $2
    fi
  done

  if [ -n "$3" ]; then
    E="map literal must contain an even number of forms"
  fi

  R=$1
}

READ_SEQ() {
  TABLE_NEW AST
  set -- $R $1

  while :; do
    TOKEN_AT $S
    T="$R"

    if [ -z "$T" ]; then
      E="expected '$2', got EOF"; return 1
    fi

    if [ "$T" = "$2" ]; then
      S=$((S+1))
      break
    fi

    READ_FORM

    TABLE_PUSH $1
  done

  R=$1
}

READ_STR() {
  if [ $# -gt 0 ]; then
    R="$@"
  fi

  E=

  TOKENIZE

  if [ $TOKEN_COUNT -eq 0 ]; then
    unset R; return 1
  fi

  S=1

  READ_FORM
}
