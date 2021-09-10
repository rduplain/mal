ENV_DEL() {
  KEY_ENCODE "$2"
  TABLE_DEL $1 $R
}

ENV_DUMP() {
  TABLE_KEYS $1
  ENV_DUMP_KEYS="$R"

  {
    if [ -z "$1" ]; then
      echo "(no env)"
    elif [ -z "$ENV_DUMP_KEYS" ]; then
      echo "(empty)"
    fi

    for ENV_DUMP_KEY in $ENV_DUMP_KEYS; do
      TABLE_GET $1 $ENV_DUMP_KEY
      REPR
      ENV_DUMP_VALUE="$R"
      KEY_DECODE "$ENV_DUMP_KEY"
      ENV_DUMP_KEY="$R"
      printf "%s = %s\n" "$ENV_DUMP_KEY" "$ENV_DUMP_VALUE"
    done
  } >&2

  R=

  unset ENV_DUMP_KEY ENV_DUMP_KEYS ENV_DUMP_VALUE
}

ENV_FIND() {
  R=
  if [ $# -eq 2 ]; then
    KEY_ENCODE "$2"
    set -- $1 "$2" $R
  fi
  TABLE_GET $1 $3
  if [ -n "$R" ]; then
    R=$1
  else
    ENV_OUTER $1
    if [ -n "$R" ]; then
      ENV_FIND $R "$2" $3
    else
      R=
    fi
  fi
}

ENV_GET() {
  KEY_ENCODE "$2"
  set -- $1 "$2" $R
  ENV_FIND $1 "$2" $3
  TABLE_GET $R $3
}

ENV_LEN() {
  TABLE_LEN $1
}

ENV_NEW() {
  TABLE_NEW ENV

  if [ $# -eq 1 ]; then
    eval "ENV_${R}_OUTER=$1"
  fi
}

ENV_OUTER() {
  eval "R=\$ENV_${1}_OUTER"
}

ENV_SET() {
  R_STACK_PUSH
  KEY_ENCODE "$2"
  set -- $1 $R
  R_STACK_POP
  TABLE_SET $1 $2
}
