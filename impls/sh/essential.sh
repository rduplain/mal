# See README.md next to this file.

# The R Stack - A manually managed stack of procedure return values.
#
# Given the importance of the variable R as a "register" for return values, and
# the lack of local variables, procedures require a means to explicitly manage
# a stack of return values.
#
# Footnote: When multiple return values are required, use a TABLE.

R_STACK_PUSH() {
  R_COUNT=$((R_COUNT+1))
  eval "R_${R_COUNT}=\"\$R\""
}

R_STACK_POP() {
  eval "R=\"\$R_${R_COUNT}\"; unset R_${R_COUNT}"
  R_COUNT=$((R_COUNT-1))
}


# ID - Named global monotonic counters.
#
# A single, global namespace requires that functions have a means to create
# globally unique names. Given the single-threaded runtime, use a named global.

ID() {
  eval "ID_$1=\$((ID_$1+1)); R=\$ID_$1"
}


# TABLE - a general-purpose data structure persisted in the global namespace.
#
# Assoc. "Array" - store pairs with TABLE_SET; access with TABLE_GET.
# Stack          - add data with TABLE_PUSH; access with TABLE_POP.
# List           - add data with TABLE_PUSH; treat as an associative array with
#                  one-indexed numeric keys to access individual items.
# Set            - treat as associative array with every key having same value.
#
# N.B. Table keys must be valid shell identifiers (and can start with numbers).
#
# Every table operation takes an identifier as its first argument, as
# determined by the caller, in order to avoid collisions in the global
# namespace. TABLE_NEW provides an ID as a handle for convenience.
#
# Use TABLE_CLEAR to destroy a table, which is immediately available for
# operations using the same handle (i.e. no TABLE_NEW is required after
# TABLE_CLEAR).

TABLE_SEP=0SEP0

TABLE_CLEAR() {
  eval "TABLE_CLEAR_PATT=\"^TABLE_${1}_${TABLE_SEP}_.*_${TABLE_SEP}\$\""

  TABLE_CLEARS=$(set | awk -F= "{ if(\$1 ~ /$TABLE_CLEAR_PATT/) print \$1 }")

  for TABLE_CLEAR in $TABLE_CLEARS; do
    eval "unset $TABLE_CLEAR"
  done

  eval "unset TABLE_${1}_LENGTH"

  unset TABLE_CLEAR TABLE_CLEARS TABLE_CLEAR_PATT
}

TABLE_DEL() {
  eval "TABLE_DEL_NAME=TABLE_${1}_${TABLE_SEP}_${2}_${TABLE_SEP}"
  eval "if [ -n \"\$$TABLE_DEL_NAME\" ]; then TABLE_DEL_EXISTED=true; fi"

  eval "unset \$TABLE_DEL_NAME"

  if [ -n "$TABLE_DEL_EXISTED" ]; then _TABLE_DEC "$1"; fi

  unset TABLE_DEL_NAME TABLE_DEL_EXISTED
}

TABLE_DUMP() {
  TABLE_KEYS $1
  TABLE_DUMP_KEYS="$R"

  {
    if [ -z "$1" ]; then
      echo "(no table)"
      return
    else
      echo "$1:"
    fi

    if [ -z "$TABLE_DUMP_KEYS" ]; then
      echo "(empty)"
    fi

    for TABLE_DUMP_KEY in $TABLE_DUMP_KEYS; do
      TABLE_GET $1 $TABLE_DUMP_KEY
      printf "%3d: %s\n" "$TABLE_DUMP_KEY" "$R"
    done
  } >&2

  unset TABLE_DUMP_KEY TABLE_DUMP_KEYS
}

TABLE_GET() {
  eval "TABLE_GET_NAME=TABLE_${1}_${TABLE_SEP}_${2}_${TABLE_SEP}"
  eval "R=\"\$$TABLE_GET_NAME\""
  unset TABLE_GET_NAME
}

TABLE_KEYS() {
  eval "TABLE_KEYS_PATT_AWK=\"^TABLE_${1}_${TABLE_SEP}_.*_${TABLE_SEP}\$\""
  eval "TABLE_KEYS_PATT_SED=\"^TABLE_${1}_${TABLE_SEP}_\(.*\)_${TABLE_SEP}\$\""

  R=$(set |
        awk -F= "{ if(\$1 ~ /$TABLE_KEYS_PATT_AWK/) print \$1 }" |
        sed "s/$TABLE_KEYS_PATT_SED/\1/g" |
        sort -n)

  unset TABLE_KEYS_PATT_AWK TABLE_KEYS_PATT_SED
}

TABLE_LEN() {
  eval "R=\$TABLE_${1}_LENGTH; [ -z \"\$R\" ] && R=0"
}

TABLE_NEW() {
  ID "TABLE"
  R="TABLE$R"
}

TABLE_POP() {
  TABLE_LEN $1
  TABLE_POP_POSITION=$R

  TABLE_GET $1 $TABLE_POP_POSITION
  TABLE_DEL $1 $TABLE_POP_POSITION

  unset TABLE_POP_POSITION
}

TABLE_PUSH() {
  R_STACK_PUSH

  TABLE_LEN $1
  TABLE_PUSH_POSITION=$((R+1))

  R_STACK_POP

  TABLE_SET $1 "$TABLE_PUSH_POSITION"

  unset TABLE_PUSH_POSITION
}

TABLE_SET() {
  eval "TABLE_SET_NAME=TABLE_${1}_${TABLE_SEP}_${2}_${TABLE_SEP}"

  eval "if [ -n \"\$$TABLE_SET_NAME\" ]; then TABLE_SET_EXISTED=true; fi"

  eval "$TABLE_SET_NAME=\"\$R\""

  if [ -z "$TABLE_SET_EXISTED" ]; then _TABLE_INC "$1"; fi

  unset TABLE_SET_EXISTED TABLE_SET_NAME
}

_TABLE_DEC() {
  eval "TABLE_${1}_LENGTH=\$((TABLE_${1}_LENGTH-1))"
}

_TABLE_INC() {
  eval "TABLE_${1}_LENGTH=\$((TABLE_${1}_LENGTH+1))"
}


# TIMEIT - Run command, then print elapsed time to stderr (or error if exists).

TIMEIT() {
  __time_command="$1"
  shift

  __time_start="$(date +"%s.%N")"

  "$__time_command" "$@"

  __time_end="$(date +"%s.%N")"

  {
    if [ -z "$E" ]; then
      __time_elapsed="$(echo "($__time_end - $__time_start) * 1000" | bc)"
      printf "%0.2fms\n" "$__time_elapsed"
    else
      printf "error: %s\n" "$E"
    fi
  } >&2

  unset __time_command __time_elapsed __time_end __time_start
}
