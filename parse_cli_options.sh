#!/bin/sh
# POSIX-compliant script to process options like --option or --option=value.
# The script parses arguments and creates corresponding variables from options.

set -eu  # Enable strict mode (fail on errors, unset variables, etc.)

arg=
key=
var=
while [ $# -gt 0 ]; do
  arg="$1"
  shift

  # Check if argument starts with "--"
  case "$arg" in
    --[[:alnum:]][-_[:alnum:]]*)
      # Extract key (remove -- and invalid characters)
      key=$(printf "%s" "$arg" | sed 's/^--//; s/[^-_[:alnum:]].*$//')
      var=$(printf "%s" "$key" | sed 's/-/_/g' | tr '[:lower:]' '[:upper:]')

      # Check if the option has a value (e.g., --option=value)
      case "$arg" in
        --"${key}"=*)
          eval "$var=\"${arg#*=}\""  # Set the variable with the value
          ;;
        --"${key}")
          eval "$var=1"  # Set the variable to 1 (flag)
          ;;
        *)
          echo "Error: Invalid option format: $arg" >&2
          exit 1
          ;;
      esac
      ;;
    *)
      # Non-option arguments, retain for further processing
      set -- "$@" "$arg"
      ;;
  esac
done

