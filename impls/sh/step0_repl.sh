#!/bin/sh

READ() {
  read -p "user> " R
}

EVAL() {
  :
}

PRINT() {
  printf "%s\n" "$R"
}

MAIN() {
  while :; do
    READ || exit $?
    EVAL
    PRINT
  done
}

MAIN "$@"
