#!/bin/sh
# POSIX sh library — option parser and command/comment extractor
#
# WARNING:
# The argument parsing in `main()` relies on `eval` for dynamic
# variable assignment. This approach is flexible but unsafe with
# untrusted input and is discouraged in hardened scripts.
#
# This file is written to be:
# - POSIX compatible (/bin/sh)
# - Structured according to Google Shell Style Guide principles:
#   - Lowercase function names with underscores
#   - Short functions, clear names, and argument/return docs
#   - Avoid exporting globals unless necessary
# - Portable: uses awk/sed/grep where appropriate (POSIX utilities)
#
# Public API:
# - init_global_parameters
# - extract_all_comments <file> [target_function]
# - list_functions_in_file <file>
# - help <file> [command]
#
# Usage example (in your script):
#   __FUNCTION_PREFIX='cmd_'
#   . "$(cd "$(dirname -- "$0")" && pwd)/commands_options_and_comments_lib.sh"
#   main "$@"

# Multiple source guard.
if [ "${_COMMANDS_OPTIONS_AND_COMMENTS_LIB_SOURCED:-}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi
_COMMANDS_OPTIONS_AND_COMMENTS_LIB_SOURCED=1

# Prints out the inline help (callers may override and write their own)
usage() {
  cat <<EOF
USAGE:
  ${__SCRIPT_NAME} <command> [options] [arguments]

This script allows you to execute various commands with options.

Commands:
  <command>  The command to execute. Available commands include:
    hello     Prints a greeting message.
    goodbye   Prints a farewell message.

EOF

extract_all_comments "$__FILE"

cat <<EOF
Options:
  --help     Show this help message and exit.
  --verbose  Enable verbose mode for more detailed output.
  --file=<file>   Specify a file to be used by the command.

Examples:
  ${__SCRIPT_NAME} hello --verbose
    Executes the 'hello' command with verbose output.

  ${__SCRIPT_NAME} goodbye --file=output.txt
    Executes the 'goodbye' command and writes the output to 'output.txt'.

EOF
}

# -----------------------------------------------------------------------------
# Shell options (callers may override and set their own).
# -----------------------------------------------------------------------------
# Example for bash:
#  set_shell_options() {
#    set -o errexit
#    set -o pipefail
#    set -o nounset
#  #  set -o xtrace # trace for debugging.
#  }
set_shell_options() {
  # POSIX: set -eu is portable. Do not set pipefail here (not POSIX).
  set -eu
}

# -----------------------------------------------------------------------------
# Initialize globals.
# -----------------------------------------------------------------------------
# Note: do not export these variables; keep them internal to avoid environment
# pollution. Call init_global_parameters from your script if you need them.
init_global_parameters() {
  # Name of the invoked script (no path)
  __SCRIPT_NAME="${0##*/}"

  # Directory of the invoked script (resolved via cd/pwd)
  __DIR="$(cd "$(dirname -- "${0}")" && pwd)"

  # Path to the script file
  __FILE="${__DIR}/${__SCRIPT_NAME}"

  # Base name without .sh suffix
  __BASE="$(basename -- "${__FILE}" .sh)"
}

# Displays help for a specific command or general usage if no command is provided.
# Args:
#   $1 (optional): The command for which to display help.
help() {
  coac_cmd="${1-}"  # Get the command argument or default to empty.
  coac_cmd_func=""

  if is_not_empty "${coac_cmd}"; then
    coac_cmd_func="${__FUNCTION_PREFIX-}${coac_cmd}"
  fi
  extract_all_comments "${__FILE}" "${coac_cmd_func}"
}

# Checks if a string is empty.
# Args:
#   $1: string
# Returns:
#   0 (true) if empty, 1 otherwise
is_empty() {
  coac_str="${1-}"
  [ -z "$coac_str" ]
}

# Checks if a string is non-empty.
# Args:
#   $1: string
# Returns:
#   0 (true) if non-empty, 1 otherwise
is_not_empty() {
  coac_str="${1-}"
  [ -n "$coac_str" ]
}

# Checks if two strings are equal.
# Args:
#   $1: first string
#   $2: second string
# Returns:
#   0 (true) if equal, 1 otherwise
is_equal() {
  coac_a="${1-}"
  coac_b="${2-}"
  [ "$coac_a" = "$coac_b" ]
}

# Checks if two strings are not equal.
# Args:
#   $1: first string
#   $2: second string
# Returns:
#   0 (true) if not equal, 1 otherwise
is_not_equal() {
  coac_a="${1-}"
  coac_b="${2-}"
  [ "$coac_a" != "$coac_b" ]
}

# Checks if two integers are equal.
# Args:
#   $1: first integer
#   $2: second integer
# Returns:
#   0 (true) if equal, 1 otherwise
is_int_equal() {
  coac_a="${1-}"
  coac_b="${2-}"
  [ "$coac_a" -eq "$coac_b" ]
}

# Checks if two integers are not equal.
# Args:
#   $1: first integer
#   $2: second integer
# Returns:
#   0 (true) if not equal, 1 otherwise
is_int_not_equal() {
  coac_a="${1-}"
  coac_b="${2-}"
  [ "$coac_a" -ne "$coac_b" ]
}

# Checks if first integer is less than second.
# Args:
#   $1: first integer
#   $2: second integer
# Returns:
#   0 (true) if less, 1 otherwise
is_int_less() {
  coac_a="${1-}"
  coac_b="${2-}"
  [ "$coac_a" -lt "$coac_b" ]
}

# Checks if first integer is less than or equal to second.
# Args:
#   $1: first integer
#   $2: second integer
# Returns:
#   0 (true) if less or equal, 1 otherwise
is_int_less_equal() {
  coac_a="${1-}"
  coac_b="${2-}"
  [ "$coac_a" -le "$coac_b" ]
}

# Checks if first integer is greater than second.
# Args:
#   $1: first integer
#   $2: second integer
# Returns:
#   0 (true) if greater, 1 otherwise
is_int_greater() {
  coac_a="${1-}"
  coac_b="${2-}"
  [ "$coac_a" -gt "$coac_b" ]
}

# Checks if first integer is greater than or equal to second.
# Args:
#   $1: first integer
#   $2: second integer
# Returns:
#   0 (true) if greater or equal, 1 otherwise
is_int_greater_equal() {
  coac_a="${1-}"
  coac_b="${2-}"
  [ "$coac_a" -ge "$coac_b" ]
}

# Checks if a file or directory exists.
# Args:
#   $1: path
# Returns:
#   0 (true) if exists, 1 otherwise
file_exists() {
  coac_path="${1-}"
  [ -e "$coac_path" ]
}

# Checks if path is a regular file.
# Args:
#   $1: path
# Returns:
#   0 (true) if file, 1 otherwise
is_file() {
  coac_path="${1-}"
  [ -f "$coac_path" ]
}

# Checks if path is a directory.
# Args:
#   $1: path
# Returns:
#   0 (true) if directory, 1 otherwise
is_dir() {
  coac_path="${1-}"
  [ -d "$coac_path" ]
}

# Checks if path is readable.
# Args:
#   $1: path
# Returns:
#   0 (true) if readable, 1 otherwise
is_readable() {
  coac_path="${1-}"
  [ -r "$coac_path" ]
}

# Checks if path is writable.
# Args:
#   $1: path
# Returns:
#   0 (true) if writable, 1 otherwise
is_writable() {
  coac_path="${1-}"
  [ -w "$coac_path" ]
}

# Checks if path is executable.
# Args:
#   $1: path
# Returns:
#   0 (true) if executable, 1 otherwise
is_executable() {
  coac_path="${1-}"
  [ -x "$coac_path" ]
}

# Checks if file exists and is not empty.
# Args:
#   $1: file path
# Returns:
#   0 (true) if file not empty, 1 otherwise
file_not_empty() {
  coac_path="${1-}"
  [ -s "$coac_path" ]
}

# Checks if a string represents a valid integer (positive or negative).
# Args:
#   $1: string
# Returns:
#   0 (true) if integer, 1 otherwise
is_integer() {
  coac_str="${1-}"
  case "$coac_str" in
    ''|*[!0-9-]*) return 1 ;;
    -|--*) return 1 ;;
    *) return 0 ;;
  esac
}

# Checks if a string represents a positive integer (>0).
# Args:
#   $1: string
# Returns:
#   0 (true) if positive integer, 1 otherwise
is_positive_integer() {
  coac_str="${1-}"
  case "$coac_str" in
    ''|*[!0-9]*) return 1 ;;
    0) return 1 ;;
    *) return 0 ;;
  esac
}

# Checks if integer $1 is between $2 and $3 inclusive.
# Args:
#   $1: integer to check
#   $2: lower bound
#   $3: upper bound
# Returns:
#   0 (true) if $1 >= $2 and $1 <= $3, 1 otherwise
is_between() {
  coac_val="${1-}"
  coac_low="${2-}"
  coac_high="${3-}"
  [ "$coac_val" -ge "$coac_low" ] 2>/dev/null && [ "$coac_val" -le "$coac_high" ] 2>/dev/null
}

# Checks if integer is odd.
# Args:
#   $1: integer
# Returns:
#   0 (true) if odd, 1 otherwise
is_odd() {
  coac_val="${1-}"
  [ $((coac_val % 2)) -eq 1 ] 2>/dev/null
}

# Checks if integer is even.
# Args:
#   $1: integer
# Returns:
#   0 (true) if even, 1 otherwise
is_even() {
  coac_val="${1-}"
  [ $((coac_val % 2)) -eq 0 ] 2>/dev/null
}

# Checks if string $1 starts with prefix $2.
# Args:
#   $1: string
#   $2: prefix
# Returns:
#   0 (true) if $1 starts with $2, 1 otherwise
starts_with() {
  coac_str="${1-}"
  coac_prefix="${2-}"
  [ "${coac_str#"$coac_prefix"}" != "$coac_str" ]
}

# Checks if string $1 ends with suffix $2.
# Args:
#   $1: string
#   $2: suffix
# Returns:
#   0 (true) if $1 ends with $2, 1 otherwise
ends_with() {
  coac_str="${1-}"
  coac_suffix="${2-}"
  case "$coac_str" in
    *"$coac_suffix") return 0 ;;
    *) return 1 ;;
  esac
}

# Checks if string $1 contains substring $2.
# Args:
#   $1: string
#   $2: substring
# Returns:
#   0 (true) if substring is found, 1 otherwise
contains_substring() {
  coac_str="${1-}"
  coac_sub="${2-}"
  case "$coac_str" in
    *"$coac_sub"*) return 0 ;;
    *) return 1 ;;
  esac
}

# Checks if a path is absolute (starts with /).
# Args:
#   $1: path
# Returns:
#   0 (true) if absolute, 1 otherwise
is_absolute_path() {
  coac_path="${1-}"
  case "$coac_path" in
    /*) return 0 ;;
    *) return 1 ;;
  esac
}

# Checks if a path is relative (does not start with /).
# Args:
#   $1: path
# Returns:
#   0 (true) if relative, 1 otherwise
is_relative_path() {
  coac_path="${1-}"
  case "$coac_path" in
    /*) return 1 ;;
    *) return 0 ;;
  esac
}

# Checks if a path is a symbolic link.
# Args:
#   $1: path
# Returns:
#   0 (true) if symlink, 1 otherwise
is_symlink() {
  coac_path="${1-}"
  [ -L "$coac_path" ]
}

# Checks if path is a readable regular file.
# Args:
#   $1: path
# Returns:
#   0 (true) if file exists and readable, 1 otherwise
is_readable_file() {
  coac_path="${1-}"
  [ -f "$coac_path" ] && [ -r "$coac_path" ]
}

# Checks if path is a writable directory.
# Args:
#   $1: path
# Returns:
#   0 (true) if directory exists and writable, 1 otherwise
is_writable_dir() {
  coac_path="${1-}"
  [ -d "$coac_path" ] && [ -w "$coac_path" ]
}

# Checks if path is a file and executable.
# Args:
#   $1: path
# Returns:
#   0 (true) if executable file, 1 otherwise
file_is_executable() {
  coac_path="${1-}"
  [ -f "$coac_path" ] && [ -x "$coac_path" ]
}

# Checks if a string is empty or whitespace only.
# Args:
#   $1: string
# Returns:
#   0 (true) if empty, 1 otherwise
is_empty_or_whitespace() {
  coac_line="$1"
  if [ -z "$(printf '%s' "$coac_line" | tr -d '[:space:]')" ]; then
    return 0
  else
    return 1
  fi
}

# Checks if a string is an existing function.
# Args:
#   $1: string
# Returns:
#   0 (true) if function exists, 1 otherwise
is_function() {
  coac_string="$1"
  if ! command -v "$coac_string" >/dev/null 2>&1; then
    printf 'Error: Command %s is not recognized.\n' "$coac_string" >&2
    return 1
  else
    return 0
  fi

}

# Checks if a line is a comment (indented or not).
# Args:
#   $1: line
# Returns:
#   0 (true) if comment, 1 otherwise
is_comment_line() {
  coac_line="$1"
  case "$coac_line" in
    \#*|[[:space:]]*\#*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Checks if a line contains the start of a function definition (without '{').
# Args:
#   $1: line
# Returns:
#   0 (true) if function start, 1 otherwise
is_func_start_line() {
  coac_line="$1"
  coac_line=$(printf '%s' "$coac_line" | sed 's/^[[:space:]]*//')
  case "$coac_line" in
    function*|*'()'*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Checks if a line contains only '{' (with or without indentation).
# Args:
#   $1: line
# Returns:
#   0 (true) if line is '{', 1 otherwise
is_open_brace_line() {
  coac_line="$1"
  coac_line=$(printf '%s' "$coac_line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  [ "$coac_line" = "{" ]
}

# Extracts the function name from a function definition line.
# Args:
#   $1: line containing function definition
# Returns:
#   Function name or empty string
extract_func_name() {
  coac_line="$1"
  coac_line=$(printf '%s' "$coac_line" | sed 's/^[[:space:]]*//')
  coac_func_name=""

  case "$coac_line" in
    function\ *\(*)
      coac_func_name=$(printf '%s' "$coac_line" | awk '{print $2}' | sed 's/()$//')
      ;;
    function\ *)
      coac_func_name=$(printf '%s' "$coac_line" | awk '{print $2}')
      ;;
    *'()'*)
      coac_func_name=$(printf '%s' "$coac_line" | awk '{print $1}' | sed 's/()$//')
      ;;
  esac

  coac_func_name=$(printf '%s' "$coac_func_name" | tr -d ' ')

  printf '%s\n' "$coac_func_name"
}

# Appends a line to an existing comment block.
# Args:
#   $1: existing comment block
#   $2: new comment line
# Returns:
#   Combined comment block
collect_comment() {
  coac_existing_block="$1"
  coac_new_comment_line="$2"

  # Remove separators consisting only of '#' and repeated '#', '-' or '=' characters
  coac_new_comment_line=$(printf '%s' "$coac_new_comment_line" | sed '/^[[:space:]]*#[[:space:]]*$/d; /^[[:space:]]*#[[:space:]]*\([#=-]\)\1\{2,\}[[:space:]]*$/d')

  # Remove the '#' and any leading whitespace from the comment line
  coac_new_comment_line=$(printf '%s' "$coac_new_comment_line" | sed 's/^[[:space:]]*#[[:space:]]//')

  if is_empty "$coac_existing_block"; then
    printf '%s\n' "$coac_new_comment_line"
  elif is_empty_or_whitespace "$coac_new_comment_line"; then
    printf '%s\n' "$coac_existing_block"
  else
    append_comment "$coac_existing_block" "$coac_new_comment_line"
  fi
}

# Combines existing comment block with new line.
# Args:
#   $1: existing comment block
#   $2: new comment line
# Returns:
#   Combined comment block
append_comment() {
  coac_existing_block="$1"
  coac_new_comment_line="$2"

  printf '%s\n    %s\n' "$coac_existing_block" "$coac_new_comment_line"
}

# Processes the start of a function (either inline or multi-line).
# Args:
#   $1: line containing function definition
# Returns:
#   Function name
process_function_start() {
  coac_line="$1"
  coac_function_name=""

  case "$coac_line" in
    *'{')
      coac_function_name=$(extract_func_name "$coac_line")
      ;;
    *)
      coac_function_name=$(extract_func_name "$coac_line")
      ;;
  esac

  printf '%s\n' "$coac_function_name"
}

# Handles the function block after finding the opening brace.
# Args:
#   $1: current comment block
#   $2: function name
#   $3: target function name
# Returns:
#   None
handle_function_end() {
  coac_comment_block="$1"
  coac_function_name="$2"
  coac_target_function_name="$3"

  if is_not_empty "$coac_target_function_name" && [ "$coac_function_name" != "$coac_target_function_name" ]; then
    coac_comment_block=""
    return
  fi

  # If __FUNCTION_PREFIX is set, only process functions with this prefix
  if is_not_empty "${__FUNCTION_PREFIX-}"; then
    case "$coac_function_name" in
      "${__FUNCTION_PREFIX}"*)
        ;; # matches prefix, continue
      *)
        coac_comment_block=""
        return
        ;;
    esac
  fi

  # Remove the prefix from the function name, if __FUNCTION_PREFIX is set
  if is_not_empty "${__FUNCTION_PREFIX-}"; then
    case "$coac_function_name" in
      "${__FUNCTION_PREFIX}"*)
        coac_function_name=${coac_function_name#${__FUNCTION_PREFIX}}  # Entferne das Präfix
        ;;
      *)
        ;;
    esac
  fi

  if is_not_empty "$coac_comment_block"; then
    printf '  %s\n' "$coac_function_name"
    printf '    %s\n\n' "$coac_comment_block"
  else
    printf '  %s\n' "$coac_function_name"
  fi
}

# Extracts all functions and their comment blocks from a file.
# Supports multi-line function headers and '{' on the next line.
# Args:
#   $1: shell script file
#   $2: optional function name to filter
extract_all_comments() {
  coac_script_file="$1"
  coac_target_function_name="${2-}"
  coac_comment_block=""
  coac_inside_comment=0
  coac_pending_function_line=""

  while IFS= read -r coac_line || is_not_empty "$coac_line"; do
    if is_comment_line "$coac_line"; then
      coac_comment_block=$(collect_comment "$coac_comment_block" "$coac_line")
      coac_inside_comment=1
    elif is_not_empty "$coac_pending_function_line"; then
      if is_open_brace_line "$coac_line"; then
        coac_function_name=$(process_function_start "$coac_pending_function_line")
        handle_function_end "$coac_comment_block" "$coac_function_name" "$coac_target_function_name"
        coac_comment_block=""
        coac_inside_comment=0
        coac_pending_function_line=""
      else
        coac_pending_function_line=""
      fi
    elif is_func_start_line "$coac_line"; then
      case "$coac_line" in
        *'{')
          coac_function_name=$(process_function_start "$coac_line")
          handle_function_end "$coac_comment_block" "$coac_function_name" "$coac_target_function_name"
          coac_comment_block=""
          coac_inside_comment=0
          ;;
        *)
          coac_pending_function_line="$coac_line"
          ;;
      esac
    else
      coac_comment_block=""
      coac_inside_comment=0
      coac_pending_function_line=""
    fi
  done < "$coac_script_file"
}

# list_functions lists declared shell functions.
#
# If a prefix is provided, only functions whose names start with that prefix
# are listed. If no prefix is given, all declared shell functions are listed.
#
# This implementation assumes that the shell supports the `declare` command
# (e.g., Bash, Ksh). If you are using a POSIX shell, a different approach
# would be necessary.
#
# Usage:
#   list_functions
#   list_functions "cmd_"
#
# Arguments:
#   $1: Optional. Function name prefix to filter by.
#
# Outputs:
#   Writes matching function names, one per line, to stdout.
#
# Returns:
#   0: Success.
#   1: Error if no functions are declared or if an unexpected error occurs.
list_functions() {
  coac_prefix=${1-}

  if is_not_empty "$coac_prefix"; then
    # Filter functions by prefix
    declare -F | grep -o "^declare -f ${coac_prefix}[A-Za-z0-9_]*" | awk '{print $3}'
  else
    # List all functions
    declare -F | awk '{print $3}'
  fi
}

# Main function:
# - Implements a simple --key / --key=value parser and passes non-option
#   arguments as positional parameters.
# - Executes the first non-option argument as command
main() {
  # Parse command-line arguments
  coac_cmd=""
  coac_cmd_func=""
  coac_key=""
  coac_var=""

  for coac_arg in "$@"; do
    shift
    case ${coac_arg} in
      --[a-zA-Z0-9][-_a-zA-Z0-9]*)
        # Parse options of the form --key=value or --key
        coac_key=$(printf "%s" "${coac_arg}" | sed 's/^--//; s/[^-_a-zA-Z0-9].*$//')
        coac_var=$(printf "%s" "${coac_key}" | sed 's/-/_/g' | tr '[:lower:]' '[:upper:]')

        case ${coac_arg} in
          --"${coac_key}"=*)
            # Assign value to the variable (quoted to avoid eval word-splitting)
            eval "${coac_var}=\"${coac_arg#*=}\""
            ;;
          --"${coac_key}")
            # If no value is provided, set the variable to 1
            eval "${coac_var}=1"
            ;;
          *)
            # Invalid argument format
            printf '%s\n' "Invalid argument format: ${coac_arg}" >&2
            exit 1
            ;;
        esac
        ;;
      *)
        # Collect all non-option arguments
        set -- "$@" "${coac_arg}"
        ;;
    esac
  done

  # Set shell options for safety and debugging
  set_shell_options

  # Initialize global parameters (if any)
  init_global_parameters

  if ( is_not_empty "${HELP-}" ); then
    help "$@"
    exit 0
  fi

  # Check if the first argument (command) is provided
  if [ -z "${1-}" ]; then
    usage >&2  # Print usage message to stderr
    exit 1
  fi

  # The first argument is the command
  coac_cmd="$1"
  shift  # Remove the first argument (command) from the list

  # Construct the function name by prefixing '__FUNCTION_PREFIX' to the command
  coac_cmd_func="${__FUNCTION_PREFIX-}${coac_cmd}"

  # POSIX-safe existence check:
  # If `command -v` cannot find the name, treat it as unknown.
  if ! command -v "${coac_cmd_func}" >/dev/null 2>&1; then
    printf 'Error: Command %s is not recognized.\n' "$coac_cmd" >&2
    return 1
  fi

  # Call the function with the remaining arguments
  "${coac_cmd_func}" "$@"
}

# If invoked directly, run main.
# Fully POSIX-safe check: use parameter expansion to obtain basename.
# -----------------------------------------------------------------------------
if [ "${0##*/}" = "commands_options_and_comments_lib.sh" ] && [ "${0#-}" = "${0}" ]; then
  init_global_parameters 2>/dev/null || true
  main "$@"
fi
