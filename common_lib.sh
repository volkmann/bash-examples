#!/bin/sh
# POSIX shell script library: Extract functions and comment blocks from scripts.
# Supports all common shell function definitions, including multi-line headers
# with '{' on the next line.

#__FUNCTION_PREFIX='cmd_'
#readonly SCRIPT_PATH="$(cd -- "$(dirname -- "${0}")" && pwd -P)"
#source "${SCRIPT_PATH}/common_lib.sh"

# ----------------------------------------------------------------------
# usage
# Prints out the inline help
# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
# Displays help for a specific command or general usage if no command is provided.
# Args:
#   $1 (optional): The command for which to display help.
# ----------------------------------------------------------------------
help() {
  local cmd="${1-}"  # Get the command argument or default to empty.
  local cmd_func=

  if is_non_empty "${cmd}"; then
    cmd_func="${__FUNCTION_PREFIX-}${cmd}"
  fi
  extract_all_comments "${__FILE}" "${cmd_func}"
}

# ----------------------------------------------------------------------
# set_shell_option
# ----------------------------------------------------------------------
set_shell_options() {
  set -o errexit
  set -o pipefail
  set -o nounset
#  set -o xtrace
}

# ----------------------------------------------------------------------
# init_global_parameters
# ----------------------------------------------------------------------
init_global_parameters() {
  readonly __SCRIPT_NAME="${0}"
  readonly __DIR="$(cd -- "$(dirname -- "${0}")" && pwd -P)"
  readonly __FILE="${__DIR}/$(basename -- "${0}")"
  readonly __BASE="$(basename -- ${__FILE} .sh)"
}

# ----------------------------------------------------------------------
# is_empty
# Checks if a string is empty.
# Args:
#   $1: string
# Returns:
#   0 (true) if empty, 1 otherwise
# ----------------------------------------------------------------------
is_empty() {
  local str="${1-}"
  [ -z "$str" ]
}

# ----------------------------------------------------------------------
# is_empty_or_whitespace
# Checks if a string is empty or whitespace only.
# Args:
#   $1: string
# Returns:
#   0 (true) if empty, 1 otherwise
# ----------------------------------------------------------------------
is_empty_or_whitespace() {
  local line="$1"
  if [ -z "$(echo "$line" | tr -d '[:space:]')" ]; then
    return 0
  else
    return 1
  fi
}

# ----------------------------------------------------------------------
# is_non_empty
# Checks if a string is non-empty.
# Args:
#   $1: string
# Returns:
#   0 (true) if non-empty, 1 otherwise
# ----------------------------------------------------------------------
is_non_empty() {
  local str="${1-}"
  [ -n "$str" ]
}

# ----------------------------------------------------------------------
# is_file
# Checks if a file exists and is a regular file.
# Args:
#   $1: file path
# Returns:
#   0 (true) if file exists, 1 otherwise
# ----------------------------------------------------------------------
is_file() {
  local file="$1"
  [ -f "$file" ]
}

# ----------------------------------------------------------------------
# is_function
# Checks if a string is an existing function.
# Args:
#   $1: string
# Returns:
#   0 (true) if function exists, 1 otherwise
# ----------------------------------------------------------------------
is_function() {
  local string="$1"
  if ! type "$string" > /dev/null 2>&1; then
    echo "Error: Command '$cmd' is not recognized." >&2
    return 1
  else
    return 0
  fi

}

# ----------------------------------------------------------------------
# is_comment_line
# Checks if a line is a comment (indented or not).
# Args:
#   $1: line
# Returns:
#   0 (true) if comment, 1 otherwise
# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
# is_func_start_line
# Checks if a line contains the start of a function definition (without '{').
# Args:
#   $1: line
# Returns:
#   0 (true) if function start, 1 otherwise
# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
# is_open_brace_line
# Checks if a line contains only '{' (with or without indentation).
# Args:
#   $1: line
# Returns:
#   0 (true) if line is '{', 1 otherwise
# ----------------------------------------------------------------------
is_open_brace_line() {
  local line="$1"
  line=$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  [ "$line" = "{" ]
}

# ----------------------------------------------------------------------
# extract_func_name
# Extracts the function name from a function definition line.
# Args:
#   $1: line containing function definition
# Returns:
#   Function name or empty string
# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
# collect_comment
# Appends a line to an existing comment block.
# Args:
#   $1: existing comment block
#   $2: new comment line
# Returns:
#   Combined comment block
# ----------------------------------------------------------------------
collect_comment() {
  local existing_block="$1"
  local new_comment_line="$2"

  # Entferne Trennlinien, die nur aus '#' und wiederholten '-' oder '=' Zeichen bestehen
  new_comment_line=$(echo "$new_comment_line" | sed '/^[[:space:]]*#[[:space:]]*\([-=]\)\1\{2,\}[[:space:]]*$/d')

  # Remove the '#' and any leading whitespace from the comment line
  new_comment_line=$(echo "$new_comment_line" | sed 's/^[[:space:]]*#[[:space:]]*//')

  if is_empty "$existing_block"; then
    echo "$new_comment_line"
  elif is_empty_or_whitespace "$new_comment_line"; then
    echo "$existing_block"
  else
    append_comment "$existing_block" "$new_comment_line"
  fi
}

# ----------------------------------------------------------------------
# append_comment
# Combines existing comment block with new line.
# Args:
#   $1: existing comment block
#   $2: new comment line
# Returns:
#   Combined comment block
# ----------------------------------------------------------------------
append_comment() {
  local existing_block="$1"
  local new_comment_line="$2"

  printf '%s\n    %s\n' "$existing_block" "$new_comment_line"
}

# ----------------------------------------------------------------------
# process_function_start
# Processes the start of a function (either inline or multi-line).
# Args:
#   $1: line containing function definition
# Returns:
#   Function name
# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
# handle_function_end
# Handles the function block after finding the opening brace.
# Args:
#   $1: current comment block
#   $2: function name
#   $3: target function name
# Returns:
#   None
# ----------------------------------------------------------------------
handle_function_end() {
  local comment_block="$1"
  local function_name="$2"
  local target_function_name="$3"

  if is_non_empty "$target_function_name" && [ "$function_name" != "$target_function_name" ]; then
    comment_block=""
    return
  fi

  # If __FUNCTION_PREFIX is set, only process functions with this prefix
  if is_non_empty "${__FUNCTION_PREFIX-}" &&
    [[ "$function_name" != "${__FUNCTION_PREFIX}"* ]]; then
    comment_block=""
    return
  fi

  # Remove the prefix from the function name, if __FUNCTION_PREFIX is set
  if is_non_empty "${__FUNCTION_PREFIX-}" && [[ "$function_name" == "${__FUNCTION_PREFIX}"* ]]; then
    function_name="${function_name#${__FUNCTION_PREFIX}}"  # Entferne das Präfix
  fi

  if is_non_empty "$comment_block"; then
    printf '  %s\n' "$function_name"
    echo "    $comment_block"
    echo
  else
    printf '  %s\n' "$function_name"
  fi
}

# ----------------------------------------------------------------------
# extract_all_comments
# Extracts all functions and their comment blocks from a file.
# Supports multi-line function headers and '{' on the next line.
# Args:
#   $1: shell script file
#   $2: optional function name to filter
# ----------------------------------------------------------------------
extract_all_comments() {
  local script_file="$1"
  local target_function_name="${2-}"
  local comment_block=""
  local inside_comment=0
  local pending_function_line=""

  while IFS= read -r line || is_non_empty "$line"; do
    if is_comment_line "$line"; then
      comment_block=$(collect_comment "$comment_block" "$line")
      inside_comment=1
    elif is_non_empty "$pending_function_line"; then
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

# ----------------------------------------------------------------------
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
# ----------------------------------------------------------------------
list_functions() {
  prefix=${1-}

  if is_non_empty "$prefix"; then
    # Filter functions by prefix
    declare -F | grep -o "^declare -f ${prefix}[A-Za-z0-9_]*" | awk '{print $3}'
  else
    # List all functions
    declare -F | awk '{print $3}'
  fi
}

# ----------------------------------------------------------------------
# Main
# Entry point of the script.
# Args:
#   $1: command (e.g., 'hallo')
#   $2+: remaining arguments to be passed to the function
# ----------------------------------------------------------------------
main() {
  # Set shell options for safety and debugging
  set_shell_options

  # Initialize global parameters (if any)
  init_global_parameters

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

