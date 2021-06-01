CLEAR_ERROR() { unset E; }

# Stubs.
_error() { R="$@"; E="$@"; }
_false() { R="false"; }
_hash_map() { __seq "$1" "{" "}"; }
_keyword() { R="$@"; }
_list() { __seq "$1" "(" ")" "$2" "$3"; }
_nil() { R="nil"; }
_number() { R="$@"; }
_string() { R="$@"; }
_symbol() { R="$@"; }
_true() { R="true"; }
_vector() { __seq "$1" "[" "]"; }

__startswith() {
  # For testing step1.

  __sub="$1"
  shift

  case "$*" in "$__sub"*) unset __sub; return 0;; esac; unset __sub; return 1
}

__seq() {
  # For testing step1.

  if ! __startswith TABLE "$1"; then
    __r="$2$1"
  else
    __r="$2"
    TABLE_KEYS $1
    __table_keys="$R"
    for __table_key in $R; do
      TABLE_GET $1 "$__table_key"
      if [ -n "$R" ] && [ "$__r" != "$2" ]; then
        __r="$__r "
      fi
      __r="$__r$R"
    done
  fi

  if [ -n "$4" ]; then
    __r="$__r $4"
  fi

  if [ -n "$5" ]; then
    __r="$__r $5"
  fi

  if [ -z "$__r" ]; then
    __r="$2"
  fi
  __r="$__r$3"
  R="$__r"
  unset __r __table_key __table_keys
}
