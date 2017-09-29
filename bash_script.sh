#!/usr/bin/env bash

show_usage() {
  cat <<-EOF
  usage: ${__base} parameter

  __dir=${__dir}
  __file=${__file}
  __base=${__base}
  __root=${__root}

  \$BASH_SOURCE=${BASH_SOURCE}
EOF
}

set_shell_options() {
  set -o errexit
  set -o pipefail
#  set -o xtrace
  set -o nounset
#  set -o noexec
}

init_global_parameters() {
  readonly __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  readonly __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
  readonly __base="$(basename ${__file})"
  readonly __root="$(cd "$(dirname "${__dir}")" && pwd)"

  readonly arg1="${1:-}"
}

cmdline() {
  return
}

# Processes a file.
# $1 - the name of the input file
# $2 - the name of the output file
process_file(){
  local -r input_file="$1";  shift
  local -r output_file="$1"; shift
}

change_owner_of_files() {
  local user=$1; shift
  local group=$1; shift
  local files=$@;
  local i

  for i in $files; do
    chown $user:$group $i
  done
}

write_error() {
  echo "An error message" >&2
}

is_empty() {
  local var=$1
  [[ -z $var ]]
}

is_not_empty() {
  local var=$1
  [[ -n $var ]]
}

is_file() {
  local file=$1
  [[ -f $file ]]
}

is_dir() {
  local dir=$1
  [[ -d $dir ]]
}

my_function() {
  echo "This is my function!"
}

main() {
  set_shell_options
  init_global_parameters "$@"
  show_usage
  my_function
}

# if script is usable as library
[[ "$0" == "$BASH_SOURCE" ]] \
  && main "$@"

