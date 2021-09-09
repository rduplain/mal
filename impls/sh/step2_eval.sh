#!/bin/sh

DIR=${0%/*}
[ -d "$DIR" ] || DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

. $DIR/ascii.sh
. $DIR/env.sh
. $DIR/essential.sh
. $DIR/printer.sh
. $DIR/reader.sh
. $DIR/tokenizer.sh
. $DIR/types.sh

APPLY() {
  set --

  if [ -n "$E" ]; then
    R=
    return 1
  fi

  VALUE_GET $R

  T=$R
  TABLE_KEYS $T

  for key in $R; do
    TABLE_GET $T $key
    set -- $@ $R
  done

  VALUE_GET $1
  shift 1
  set -- $R $@

  unset R S T

  eval "$@"
}

DIVIDE() {
  S=
  for value in $@; do
    VALUE_GET $value
    S=$R
    break
  done
  shift
  for value in $@; do
    VALUE_GET $value
    S=$((S/R))
  done
  NUMBER $S
  unset S value
}

EVAL() {
  set -- $1 $R

  VALUE_TYPE $2
  case $R in
    LIST)
      VALUE_GET $2
      TABLE_LEN $R
      if [ $R -gt 0 ]; then
        R=$2
        EVAL_AST $1
        APPLY
      else
        R=$2
      fi
      ;;
    *)
      R=$2
      EVAL_AST $1
      ;;
  esac
}

EVAL_AST() {
  set -- $1 $R

  VALUE_TYPE $2
  set -- $1 $2 $R

  VALUE_GET $2
  set -- $1 $2 $3 "$R"

  VALUE_META $2
  set -- $1 $2 $3 "$4" $R

  case $3 in
    HASHMAP|LIST|VECTOR)
      TABLE_MAPCOPY $4 EVAL $1
      $3 $R $5
      ;;
    SYMBOL)
      ENV_GET $1 "$4"
      if [ -z "$R" ]; then
        KEY_DECODE "$4"
        E="'$R' not found"
        unset R
      fi
      ;;
    *)
      R=$2
      ;;
  esac
}

SUBTRACT() {
  S=0
  for value in $@; do
    VALUE_GET $value
    S=$R
    break
  done
  shift
  for value in $@; do
    VALUE_GET $value
    S=$((S-R))
  done
  NUMBER $S
  unset S value
}

MULTIPLY() {
  S=1
  for value in $@; do
    VALUE_GET $value
    S=$((S*R))
  done
  NUMBER $S
  unset S value
}

ADD() {
  S=0
  for value in $@; do
    VALUE_GET $value
    S=$((S+R))
  done
  NUMBER $S
  unset S value
}

PRINT() {
  PR_STR
}

READ() {
  read -r -p "user> " R || { echo; exit; }
  READ_STR
}

TOPLEVEL() {
  NATIVEFN DIVIDE
  ENV_SET $1 "/"

  NATIVEFN SUBTRACT
  ENV_SET $1 "-"

  NATIVEFN MULTIPLY
  ENV_SET $1 "*"

  NATIVEFN ADD
  ENV_SET $1 "+"
}

MAIN() {
  ENV_NEW
  set -- $R

  TOPLEVEL $1

  while :; do
    READ
    EVAL $1
    PRINT

    E=
  done
}

MAIN "$@"
