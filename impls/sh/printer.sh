PR_STR() {
  if [ $# -gt 0 ]; then
    R="$@"
  fi

  if [ -n "$E" ]; then
    printf "error: %s\n" "$E"
  elif [ -n "$R" ]; then
    printf "%s\n" "$R"
  fi
}
