READ_ATOM() {
  case "$T" in
    \"*)     _string  "$T";;
    :*)      _keyword "$T";;
    [0-9]*)  _number  "$T";;
    -[0-9]*) _number  "$T";;
    false)   _false       ;;
    nil)     _nil         ;;
    true)    _true        ;;
    *)      _symbol   "$T";;
  esac
}

READ_FORM() {
  TOKEN_AT $S
  T="$R"

  S=$((S+1))

  case "$T" in
    "'" | '`' | "~" | "~@" | "@")
      case "$T" in
        "'")  _symbol quote         ;;
        '`')  _symbol quasiquote    ;;
        "~")  _symbol unquote       ;;
        "~@") _symbol splice-unquote;;
        "@")  _symbol deref         ;;
      esac
      set -- "$R"
      READ_FORM
      _list "$1" "$R"
      ;;
    "^")
      _symbol with-meta; set -- "$R"
      READ_FORM; set -- "$1" "$R"
      READ_FORM
      _list "$1" "$R" "$2"
      ;;
    "(" | "[" | "{")
      case "$T" in
        "(")
          READ_SEQ ")"
          _list "$R"
          ;;
        "[")
          READ_SEQ "]"
          _vector "$R"
          ;;
        "{")
          READ_SEQ "}"
          _hash_map "$R"
          ;;
      esac
      ;;
    ")" | "]" | "}")
      _error "unexpected '$T'"; return 1
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
    TOKEN_AT $S
    T="$R"

    if [ -z "$T" ]; then
      _error "expected '$2', got EOF"; return 1
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

  CLEAR_ERROR

  TOKENIZE

  if [ $TOKEN_COUNT -eq 0 ]; then
    unset R; return 1
  fi

  S=1

  READ_FORM
}
