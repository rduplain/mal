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
  TABLE_GET TOKEN $S
  T="$R"

  S=$((S+1))

  case "$T" in
    "'" | '`' | "~" | "~@" | "@")
      case "$T" in
        "'")  SYMBOL quote         ;;
        '`')  SYMBOL quasiquote    ;;
        "~")  SYMBOL unquote       ;;
        "~@") SYMBOL splice-unquote;;
        "@")  SYMBOL deref         ;;
      esac
      set -- "$R"
      READ_FORM
      LIST "$1" "$R"
      ;;
    "^")
      SYMBOL with-meta; set -- "$R"
      READ_FORM; set -- "$1" "$R"
      READ_FORM
      LIST "$1" "$R" "$2"
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
          READ_SEQ "}"
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

READ_SEQ() {
  TABLE_NEW
  set -- $R $1

  while :; do
    TABLE_GET TOKEN $S
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

  TABLE_LEN TOKEN
  if [ $R -eq 0 ]; then
    unset R; return 1
  fi

  S=1

  READ_FORM
}
