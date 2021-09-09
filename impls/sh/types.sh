# FUNCTION             TYPE     VALUE  META
FALSE()    { VALUE_NEW FALSE               ; }
FN()       { VALUE_NEW FN        "$1"  "$2"; }
HASHMAP()  { VALUE_NEW HASHMAP   "$1"  "$2"; }
KEYWORD()  { VALUE_NEW KEYWORD   "$1"      ; }
LIST()     { VALUE_NEW LIST      "$1"  "$2"; }
NATIVEFN() { VALUE_NEW NATIVEFN  "$1"  "$2"; }
NIL()      { VALUE_NEW NIL                 ; }
NUMBER()   { VALUE_NEW NUMBER    "$1"      ; }
STRING()   { VALUE_NEW STRING    "$1"      ; }
SYMBOL()   { VALUE_NEW SYMBOL    "$1"      ; }
TRUE()     { VALUE_NEW TRUE                ; }
VECTOR()   { VALUE_NEW VECTOR    "$1"  "$2"; }

VALUE_DEL() {
  eval "unset VALUE_${1}_TYPE VALUE_${1}_VALUE VALUE_${1}_META"
}

VALUE_GET() {
  eval "R=\"\$VALUE_${1}_VALUE\""
}

VALUE_META() {
  eval "R=\"\$VALUE_${1}_META\""
}

VALUE_NEW() {
  case $1 in
    FALSE|NIL|TRUE)
      R=$1
      ;;
    *)
      ID VALUE
      eval "
        VALUE_${R}_TYPE=\"\$1\";
        VALUE_${R}_VALUE=\"\$2\";
        VALUE_${R}_META=\"\$3\"
      "
      ;;
  esac
}

VALUE_SET() {
  eval "VALUE_${1}_VALUE=\"\${2:-\$R}\""
}

VALUE_TYPE() {
  case $1 in
    FALSE|NIL|TRUE)
      R=$1
      ;;
    *)
      eval "R=\"\$VALUE_${1}_TYPE\""
      ;;
  esac
}
