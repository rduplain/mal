PR_STR() {
  if [ $# -eq 1 ]; then
    R="$1"
  fi

  if [ -n "$E" ]; then
    printf "error: %s\n" "$E"
  elif [ -n "$R" ]; then
    REPR
    printf "%s\n" "$R"
  fi
}

REPR() {
  if [ $# -eq 1 ]; then
    R="$1"
  fi

  set -- "$R"

  case $1 in
    FALSE)
      R="false"
      ;;
    NIL)
      R="nil"
      ;;
    TRUE)
      R="true"
      ;;
    *)
      VALUE_TYPE $1
      case $R in
        FN)
          R="#<fn>"
          ;;
        HASHMAP)
          REPR_HASHMAP $1
          ;;
        LIST|VECTOR)
          REPR_SEQ $1
          ;;
        NATIVEFN)
          R="#<nativefn>"
          ;;
        *)
          VALUE_GET $1
          ;;
      esac
      ;;
  esac
}

REPR_HASHMAP() {
  VALUE_GET $1
  set -- $1 $R

  TABLE_KEYS $2
  for key in $R; do
    REPR "$key"
    if [ -z "$3" ]; then
      set -- $1 $2 "$R"
    else
      set -- $1 $2 "$3 $R"
    fi
    TABLE_GET $2 "$key"
    REPR
    set -- $1 $2 "$3 $R"
  done

  R="{$3}"
}

REPR_SEQ() {
  VALUE_GET $1
  set -- $1 $R

  TABLE_KEYS $2
  for key in $R; do
    TABLE_GET $2 "$key"
    REPR
    if [ -z "$3" ]; then
      set -- $1 $2 "$R"
    else
      set -- $1 $2 "$3 $R"
    fi
  done

  VALUE_TYPE $1
  case $R in
    LIST)
      R="($3)"
      ;;
    VECTOR)
      R="[$3]"
      ;;
  esac
}
