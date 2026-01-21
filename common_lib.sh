#!/bin/sh
# POSIX shell script library: Extract functions and comment blocks from scripts.
# Supports all common shell function definitions, including multi-line headers
# with '{' on the next line.
#
# Provides extended is_* functions for:
#   - Strings
#   - Integers
#   - Files/Paths

# ===Multiple source guard ===
if [ "${_COMMON_LIB_SOURCED:-}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi
_COMMON_LIB_SOURCED=1

## Copy the following three lines to your script and uncomment them!
#__FUNCTION_PREFIX='cmd_'
#readonly SCRIPT_PATH="$(cd -- "$(dirname -- "${0}")" && pwd -P)"
#source "${SCRIPT_PATH}/common_lib.sh"

# Prints out the inline help
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

# Displays help for a specific command or general usage if no command is provided.
# Args:
#   $1 (optional): The command for which to display help.
help() {
  local cmd="${1-}"  # Get the command argument or default to empty.
  local cmd_func=

  if is_not_empty "${cmd}"; then
    cmd_func="${__FUNCTION_PREFIX-}${cmd}"
  fi
  extract_all_comments "${__FILE}" "${cmd_func}"
}

# set_shell_option
set_shell_options() {
  set -o errexit
  set -o pipefail
  set -o nounset
#  set -o xtrace
}

# init_global_parameters
init_global_parameters() {
  readonly __SCRIPT_NAME="${0}"
  readonly __DIR="$(cd -- "$(dirname -- "${0}")" && pwd -P)"
  readonly __FILE="${__DIR}/$(basename -- "${0}")"
  readonly __BASE="$(basename -- ${__FILE} .sh)"
}

# Checks if a string is empty.
# Args:
#   $1: string
# Returns:
#   0 (true) if empty, 1 otherwise
is_empty() {
  local str="${1-}"
  [ -z "$str" ]
}

# Checks if a string is non-empty.
# Args:
#   $1: string
# Returns:
#   0 (true) if non-empty, 1 otherwise
is_not_empty() {
  local str="${1-}"
  [ -n "$str" ]
}

# Checks if two strings are equal.
# Args:
#   $1: first string
#   $2: second string
# Returns:
#   0 (true) if equal, 1 otherwise
is_equal() {
  local a="${1-}"
  local b="${2-}"
  [ "$a" = "$b" ]
}

# Checks if two strings are not equal.
# Args:
#   $1: first string
#   $2: second string
# Returns:
#   0 (true) if not equal, 1 otherwise
is_not_equal() {
  local a="${1-}"
  local b="${2-}"
  [ "$a" != "$b" ]
}

# Checks if two integers are equal.
# Args:
#   $1: first integer
#   $2: second integer
# Returns:
#   0 (true) if equal, 1 otherwise
is_int_equal() {
  local a="${1-}"
  local b="${2-}"
  [ "$a" -eq "$b" ]
}

# Checks if two integers are not equal.
# Args:
#   $1: first integer
#   $2: second integer
# Returns:
#   0 (true) if not equal, 1 otherwise
is_int_not_equal() {
  local a="${1-}"
  local b="${2-}"
  [ "$a" -ne "$b" ]
}

# Checks if first integer is less than second.
# Args:
#   $1: first integer
#   $2: second integer
# Returns:
#   0 (true) if less, 1 otherwise
is_int_less() {
  local a="${1-}"
  local b="${2-}"
  [ "$a" -lt "$b" ]
}

# Checks if first integer is less than or equal to second.
# Args:
#   $1: first integer
#   $2: second integer
# Returns:
#   0 (true) if less or equal, 1 otherwise
is_int_less_equal() {
  local a="${1-}"
  local b="${2-}"
  [ "$a" -le "$b" ]
}

# Checks if first integer is greater than second.
# Args:
#   $1: first integer
#   $2: second integer
# Returns:
#   0 (true) if greater, 1 otherwise
is_int_greater() {
  local a="${1-}"
  local b="${2-}"
  [ "$a" -gt "$b" ]
}

# Checks if first integer is greater than or equal to second.
# Args:
#   $1: first integer
#   $2: second integer
# Returns:
#   0 (true) if greater or equal, 1 otherwise
is_int_greater_equal() {
  local a="${1-}"
  local b="${2-}"
  [ "$a" -ge "$b" ]
}

# Checks if a file or directory exists.
# Args:
#   $1: path
# Returns:
#   0 (true) if exists, 1 otherwise
file_exists() {
  local path="${1-}"
  [ -e "$path" ]
}

# Checks if path is a regular file.
# Args:
#   $1: path
# Returns:
#   0 (true) if file, 1 otherwise
is_file() {
  local path="${1-}"
  [ -f "$path" ]
}

# Checks if path is a directory.
# Args:
#   $1: path
# Returns:
#   0 (true) if directory, 1 otherwise
is_dir() {
  local path="${1-}"
  [ -d "$path" ]
}

# Checks if path is readable.
# Args:
#   $1: path
# Returns:
#   0 (true) if readable, 1 otherwise
is_readable() {
  local path="${1-}"
  [ -r "$path" ]
}

# Checks if path is writable.
# Args:
#   $1: path
# Returns:
#   0 (true) if writable, 1 otherwise
is_writable() {
  local path="${1-}"
  [ -w "$path" ]
}

# Checks if path is executable.
# Args:
#   $1: path
# Returns:
#   0 (true) if executable, 1 otherwise
is_executable() {
  local path="${1-}"
  [ -x "$path" ]
}

# Checks if file exists and is not empty.
# Args:
#   $1: file path
# Returns:
#   0 (true) if file not empty, 1 otherwise
file_not_empty() {
  local path="${1-}"
  [ -s "$path" ]
}

# Checks if a string represents a valid integer (positive or negative).
# Args:
#   $1: string
# Returns:
#   0 (true) if integer, 1 otherwise
is_integer() {
  local str="${1-}"
  case "$str" in
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
  local str="${1-}"
  case "$str" in
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
  local val="${1-}" low="${2-}" high="${3-}"
  [ "$val" -ge "$low" ] 2>/dev/null && [ "$val" -le "$high" ] 2>/dev/null
}

# Checks if integer is odd.
# Args:
#   $1: integer
# Returns:
#   0 (true) if odd, 1 otherwise
is_odd() {
  local val="${1-}"
  [ $((val % 2)) -eq 1 ] 2>/dev/null
}

# Checks if integer is even.
# Args:
#   $1: integer
# Returns:
#   0 (true) if even, 1 otherwise
is_even() {
  local val="${1-}"
  [ $((val % 2)) -eq 0 ] 2>/dev/null
}

# Checks if string $1 starts with prefix $2.
# Args:
#   $1: string
#   $2: prefix
# Returns:
#   0 (true) if $1 starts with $2, 1 otherwise
starts_with() {
  local str="${1-}" prefix="${2-}"
  [ "${str#"$prefix"}" != "$str" ]
}

# Checks if string $1 ends with suffix $2.
# Args:
#   $1: string
#   $2: suffix
# Returns:
#   0 (true) if $1 ends with $2, 1 otherwise
ends_with() {
  local str="${1-}" suffix="${2-}"
  case "$str" in
    *"$suffix") return 0 ;;
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
  local str="${1-}" sub="${2-}"
  case "$str" in
    *"$sub"*) return 0 ;;
    *) return 1 ;;
  esac
}

# Checks if a path is absolute (starts with /).
# Args:
#   $1: path
# Returns:
#   0 (true) if absolute, 1 otherwise
is_absolute_path() {
  local path="${1-}"
  case "$path" in
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
  local path="${1-}"
  case "$path" in
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
  local path="${1-}"
  [ -L "$path" ]
}

# Checks if path is a readable regular file.
# Args:
#   $1: path
# Returns:
#   0 (true) if file exists and readable, 1 otherwise
is_readable_file() {
  local path="${1-}"
  [ -f "$path" ] && [ -r "$path" ]
}

# Checks if path is a writable directory.
# Args:
#   $1: path
# Returns:
#   0 (true) if directory exists and writable, 1 otherwise
is_writable_dir() {
  local path="${1-}"
  [ -d "$path" ] && [ -w "$path" ]
}

# Checks if path is a file and executable.
# Args:
#   $1: path
# Returns:
#   0 (true) if executable file, 1 otherwise
file_is_executable() {
  local path="${1-}"
  [ -f "$path" ] && [ -x "$path" ]
}

# Checks if a string is empty or whitespace only.
# Args:
#   $1: string
# Returns:
#   0 (true) if empty, 1 otherwise
is_empty_or_whitespace() {
  local line="$1"
  if [ -z "$(echo "$line" | tr -d '[:space:]')" ]; then
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
  local string="$1"
  if ! type "$string" > /dev/null 2>&1; then
    echo "Error: Command '$cmd' is not recognized." >&2
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
  local line="$1"
  case "$line" in
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
  local line="$1"
  line=$(echo "$line" | sed 's/^[[:space:]]*//')
  case "$line" in
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
  local line="$1"
  line=$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  [ "$line" = "{" ]
}

# Extracts the function name from a function definition line.
# Args:
#   $1: line containing function definition
# Returns:
#   Function name or empty string
extract_func_name() {
  local line="$1"
  line=$(echo "$line" | sed 's/^[[:space:]]*//')
  local func_name=""

  case "$line" in
    function\ *\(*)
      func_name=$(echo "$line" | awk '{print $2}' | sed 's/()$//')
      ;;
    function\ *)
      func_name=$(echo "$line" | awk '{print $2}')
      ;;
    *'()'*)
      func_name=$(echo "$line" | awk '{print $1}' | sed 's/()$//')
      ;;
  esac

  func_name=$(echo "$func_name" | tr -d ' ')

  printf '%s\n' "$func_name"
}

# Appends a line to an existing comment block.
# Args:
#   $1: existing comment block
#   $2: new comment line
# Returns:
#   Combined comment block
collect_comment() {
  local existing_block="$1"
  local new_comment_line="$2"

  # Remove separators consisting only of '#' and repeated '#', '-' or '=' characters
  new_comment_line=$(echo "$new_comment_line" | sed '/^[[:space:]]*#[[:space:]]*\([-=#]\)\1\{2,\}[[:space:]]*$/d')

  # Remove the '#' and any leading whitespace from the comment line
  new_comment_line=$(echo "$new_comment_line" | sed 's/^[[:space:]]*#[[:space:]]//')

  if is_empty "$existing_block"; then
    echo "$new_comment_line"
  elif is_empty_or_whitespace "$new_comment_line"; then
    echo "$existing_block"
  else
    append_comment "$existing_block" "$new_comment_line"
  fi
}

# Combines existing comment block with new line.
# Args:
#   $1: existing comment block
#   $2: new comment line
# Returns:
#   Combined comment block
append_comment() {
  local existing_block="$1"
  local new_comment_line="$2"

  printf '%s\n    %s\n' "$existing_block" "$new_comment_line"
}

# Processes the start of a function (either inline or multi-line).
# Args:
#   $1: line containing function definition
# Returns:
#   Function name
process_function_start() {
  local line="$1"
  local function_name

  case "$line" in
    *'{')
      function_name=$(extract_func_name "$line")
      ;;
    *)
      function_name=$(extract_func_name "$line")
      ;;
  esac

  printf '%s\n' "$function_name"
}

# Handles the function block after finding the opening brace.
# Args:
#   $1: current comment block
#   $2: function name
#   $3: target function name
# Returns:
#   None
handle_function_end() {
  local comment_block="$1"
  local function_name="$2"
  local target_function_name="$3"

  if is_not_empty "$target_function_name" && [ "$function_name" != "$target_function_name" ]; then
    comment_block=""
    return
  fi

  # If __FUNCTION_PREFIX is set, only process functions with this prefix
  if is_not_empty "${__FUNCTION_PREFIX-}" &&
    [[ "$function_name" != "${__FUNCTION_PREFIX}"* ]]; then
    comment_block=""
    return
  fi

  # Remove the prefix from the function name, if __FUNCTION_PREFIX is set
  if is_not_empty "${__FUNCTION_PREFIX-}" && [[ "$function_name" == "${__FUNCTION_PREFIX}"* ]]; then
    function_name="${function_name#${__FUNCTION_PREFIX}}"  # Entferne das Präfix
  fi

  if is_not_empty "$comment_block"; then
    printf '  %s\n' "$function_name"
    echo "    $comment_block"
    echo
  else
    printf '  %s\n' "$function_name"
  fi
}

# Extracts all functions and their comment blocks from a file.
# Supports multi-line function headers and '{' on the next line.
# Args:
#   $1: shell script file
#   $2: optional function name to filter
extract_all_comments() {
  local script_file="$1"
  local target_function_name="${2-}"
  local comment_block=""
  local inside_comment=0
  local pending_function_line=""

  while IFS= read -r line || is_not_empty "$line"; do
    if is_comment_line "$line"; then
      comment_block=$(collect_comment "$comment_block" "$line")
      inside_comment=1
    elif is_not_empty "$pending_function_line"; then
      if is_open_brace_line "$line"; then
        local function_name
        function_name=$(process_function_start "$pending_function_line")
        handle_function_end "$comment_block" "$function_name" "$target_function_name"
        comment_block=""
        inside_comment=0
        pending_function_line=""
      else
        pending_function_line=""
      fi
    elif is_func_start_line "$line"; then
      case "$line" in
        *'{')
          local function_name
          function_name=$(process_function_start "$line")
          handle_function_end "$comment_block" "$function_name" "$target_function_name"
          comment_block=""
          inside_comment=0
          ;;
        *)
          pending_function_line="$line"
          ;;
      esac
    else
      comment_block=""
      inside_comment=0
      pending_function_line=""
    fi
  done < "$script_file"
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
  prefix=${1-}

  if is_not_empty "$prefix"; then
    # Filter functions by prefix
    declare -F | grep -o "^declare -f ${prefix}[A-Za-z0-9_]*" | awk '{print $3}'
  else
    # List all functions
    declare -F | awk '{print $3}'
  fi
}

# Entry point of the script.
# Args:
#   $1: command (e.g., 'hallo')
#   $2+: remaining arguments to be passed to the function
main() {
  # Set shell options for safety and debugging
  set_shell_options

  # Parse command-line arguments
  local cmd=""
  local cmd_func=""
  local key=""
  local var=""

  for arg in "$@"; do
    shift
    case ${arg} in
      --[a-zA-Z0-9][-_a-zA-Z0-9]*)
        # Parse options of the form --key=value or --key
        key=$(printf "%s" "${arg}" | sed 's/^--//; s/[^-_a-zA-Z0-9].*$//')
        var=$(printf "%s" "${key}" | sed 's/-/_/g' | tr '[:lower:]' '[:upper:]')

        case ${arg} in
          --"${key}"=*)
            # Assign value to the variable
            eval "${var}"="${arg#*=}"
            ;;
          --"${key}")
            # If no value is provided, set the variable to 1
            eval "${var}"=1
            ;;
          *)
            # Invalid argument format
            echo "Invalid argument format: ${arg}" >&2
            exit 1
            ;;
        esac
        ;;
      *)
        # Collect all non-option arguments
        set -- "$@" "${arg}"
        ;;
    esac
  done

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
  cmd="$1"
  shift  # Remove the first argument (command) from the list

  # Construct the function name by prefixing '__FUNCTION_PREFIX' to the command
  cmd_func="${__FUNCTION_PREFIX-}${cmd}"

  # Check if the corresponding function exists
  if ! declare -F "${cmd_func}" >/dev/null 2>&1; then
    echo "Error: Command '${cmd}' is not recognized." >&2
    exit 1
  fi

  # Call the function with the remaining arguments
  "${cmd_func}" "$@"
}

