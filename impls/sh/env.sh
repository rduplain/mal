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

ENV_GET() {
  KEY_ENCODE "$2"
  TABLE_GET $1 $R
}

ENV_LEN() {
  TABLE_LEN $1
}

ENV_NEW() {
  TABLE_NEW ENV
}

ENV_SET() {
  R_STACK_PUSH
  KEY_ENCODE "$2"
  set -- $1 $R
  R_STACK_POP
  TABLE_SET $1 $2
}
