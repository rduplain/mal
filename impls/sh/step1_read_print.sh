#!/bin/sh

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

. $DIR/ascii.sh
. $DIR/essential.sh
. $DIR/printer.sh
. $DIR/reader.sh
. $DIR/tokenizer.sh
. $DIR/types.sh

READ() {
  read -r -p "user> " R || { echo; exit; }
  READ_STR
}

EVAL() {
  :
}

PRINT() {
  PR_STR
}

MAIN() {
  while :; do
    READ
    EVAL
    PRINT
  done
}

MAIN "$@"
