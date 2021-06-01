Notes on the Synthesis of Shell
===============================

Properties of Shell
-------------------

* One global namespace for all variables, shared with variables
  inherited from the process environment ("environment variables").
* One global namespace (separate from variables) for all functions,
  shared with the names of commands on the $PATH.
* Variables and functions are available to subshells, as copies;
  modifications within the subshell do not affect the caller.
* Everything is a string, and for operations of iteration or function
  application, an internal field separator (IFS) specified that the string is
  split on all whitespace.
  - Quoting is essential.
  - A variable containing only whitespace is impossible to capture on its own.
  - Arithmetic operations effectively coerce strings to numeric values.
* By default, empty strings are treated the same as unset values;
  the two are identical when quoted.


Properties of POSIX Shell
-------------------------

* No concept of a variable being marked as local to a function.
* No datatype for arrays (`declare -a`) or associative arrays (`declare -A`).
* Documented; portable code must only use features in the POSIX standard.
* POSIX is more than Shell; specified UNIX commands are mandatory in POSIX.


Observations
------------

* Functions must have globally unique names.
* Lexical scoping is impossible, meaning:
  - No function can assume ownership of a variable.
  - Shared data exists only through global variables.
* Subshells are useless when sharing data through global variables.
* Concurrency is impossible with shared data, with language primitives alone.
* Quoting is only reliable at the call site; saving and loading variables
  through text otherwise requires escaping of inner quotes and preservation of
  whitespace (in order to avoid being discarded by IFS).


Conventions
-----------

* All operations are single-threaded unless explicitly stated otherwise.
* Use ALL_CAPS for functionality in the host language;
  use lowercase for functionality in the hosted language.
* Use "registers" (variables) to pass data, which are generally and informally:
  - R: return data (and therefore the most important "register").
  - S: secondary data, often the index of a loop or scanning procedure.
  - T: tertiary data, often a lookup or loop invariant.
* Use a "register" variable `E` for low-level error messages.
* Whenever data requires a guarantee that it is local:
  - [immutable] Place the variable on the call stack; use $@ and $1, $2, ...
  - [mutable] Use deterministic globally unique variable names.
* Use `eval` whenever a variable name is determined at runtime
  (in order to bypass limitations of POSIX Shell).
