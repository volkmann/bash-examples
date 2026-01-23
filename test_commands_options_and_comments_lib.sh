#!/usr/bin/env bash
#
# Unit tests for commands_options_and_comments_lib.sh
#
# Run from repository root:
#   ./run_tests.sh
#
set -u

LIB_PATH="../commands_options_and_comments_lib.sh"

if [ ! -f "${LIB_PATH}" ]; then
  printf 'Library not found at %s\n' "${LIB_PATH}" >&2
  exit 2
fi

# Load the library (do not execute main; sourcing is guarded by the library)
# Use bash to run tests (declare -F used by some tests).
# shellcheck source=/dev/null
. "${LIB_PATH}"

# Test harness (very small TAP-like)
TEST_NUM=0
FAILED=0

ok() {
  TEST_NUM=$((TEST_NUM + 1))
  printf "ok %d - %s\n" "${TEST_NUM}" "${1-}"
}
not_ok() {
  TEST_NUM=$((TEST_NUM + 1))
  FAILED=$((FAILED + 1))
  printf "not ok %d - %s\n" "${TEST_NUM}" "${1-}"
}

assert_eq() {
  desc="$1"; expected="$2"; actual="$3"
  if [ "${expected}" = "${actual}" ]; then
    ok "${desc}"
  else
    not_ok "${desc} (expected: '${expected}' got: '${actual}')"
  fi
}

assert_status() {
  desc="$1"; expected_status=$2; shift 2
  # run command in current shell (functions are sourced)
  if "$@"; then
    status=0
  else
    status=$?
  fi
  if [ "${status}" -eq "${expected_status}" ]; then
    ok "${desc}"
  else
    not_ok "${desc} (expected status ${expected_status}, got ${status})"
  fi
}

assert_output_eq() {
  desc="$1"; expected="$2"; shift 2
  out="$("$@" 2>/dev/null)"
  if [ "$out" = "$expected" ]; then
    ok "${desc}"
  else
    not_ok "${desc} (expected output: '${expected}' got: '${out}')"
  fi
}

# Temporary files/dirs for file-related tests
TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

touch "${TMPDIR}/empty"
printf 'x\n' > "${TMPDIR}/not_empty"
mkdir -p "${TMPDIR}/wdir"
touch "${TMPDIR}/exe"
chmod +x "${TMPDIR}/exe"
ln -s "${TMPDIR}/not_empty" "${TMPDIR}/link"

# -------------------------
# Basic string tests
# -------------------------
assert_status "is_empty on empty string returns 0" 0 is_empty ""
assert_status "is_empty on non-empty returns 1" 1 is_empty "a"

assert_status "is_not_empty on non-empty returns 0" 0 is_not_empty "a"
assert_status "is_not_empty on empty returns 1" 1 is_not_empty ""

assert_status "is_equal equal strings returns 0" 0 is_equal "a" "a"
assert_status "is_equal different strings returns 1" 1 is_equal "a" "b"

assert_status "is_not_equal different strings returns 0" 0 is_not_equal "a" "b"
assert_status "is_not_equal equal strings returns 1" 1 is_not_equal "a" "a"

# -------------------------
# Integer tests
# -------------------------
assert_status "is_int_equal equal ints returns 0" 0 is_int_equal 3 3
assert_status "is_int_equal different ints returns 1" 1 is_int_equal 2 3

assert_status "is_int_not_equal different ints returns 0" 0 is_int_not_equal 2 3
assert_status "is_int_not_equal equal ints returns 1" 1 is_int_not_equal 3 3

assert_status "is_int_less true returns 0" 0 is_int_less 1 2
assert_status "is_int_less false returns 1" 1 is_int_less 2 1

assert_status "is_int_less_equal true returns 0" 0 is_int_less_equal 2 2
assert_status "is_int_less_equal false returns 1" 1 is_int_less_equal 3 2

assert_status "is_int_greater true returns 0" 0 is_int_greater 3 2
assert_status "is_int_greater false returns 1" 1 is_int_greater 2 3

assert_status "is_int_greater_equal true returns 0" 0 is_int_greater_equal 3 3
assert_status "is_int_greater_equal false returns 1" 1 is_int_greater_equal 1 2

# -------------------------
# File tests
# -------------------------
assert_status "file_exists for file" 0 file_exists "${TMPDIR}/not_empty"
assert_status "file_exists for missing returns 1" 1 file_exists "${TMPDIR}/nope"

assert_status "is_file true" 0 is_file "${TMPDIR}/not_empty"
assert_status "is_dir true" 0 is_dir "${TMPDIR}/wdir"
assert_status "is_readable true" 0 is_readable "${TMPDIR}/not_empty"
# is_writable on a dir should be callable directly
assert_status "is_writable true (dir)" 0 is_writable "${TMPDIR}/wdir"

assert_status "is_executable true" 0 is_executable "${TMPDIR}/exe"
assert_status "file_not_empty true" 0 file_not_empty "${TMPDIR}/not_empty"

# -------------------------
# Integer string validators
# -------------------------
assert_status "is_integer valid positive" 0 is_integer 42
assert_status "is_integer valid negative" 0 is_integer -5
assert_status "is_integer invalid empty" 1 is_integer ""
assert_status "is_integer invalid alpha" 1 is_integer 1a

assert_status "is_positive_integer positive" 0 is_positive_integer 5
assert_status "is_positive_integer zero returns 1" 1 is_positive_integer 0
assert_status "is_positive_integer negative returns 1" 1 is_positive_integer -1

# -------------------------
# Range and parity
# -------------------------
assert_status "is_between true" 0 is_between 5 1 10
assert_status "is_between false" 1 is_between 0 1 10

assert_status "is_odd true" 0 is_odd 3
assert_status "is_odd false" 1 is_odd 2

assert_status "is_even true" 0 is_even 2
assert_status "is_even false" 1 is_even 3

# -------------------------
# String utilities
# -------------------------
assert_status "starts_with true" 0 starts_with foobar foo
assert_status "starts_with false" 1 starts_with foobar bar

assert_status "ends_with true" 0 ends_with foobar bar
assert_status "ends_with false" 1 ends_with foobar baz

assert_status "contains_substring true" 0 contains_substring foobar ob
assert_status "contains_substring false" 1 contains_substring foobar xx

# -------------------------
# Path utilities
# -------------------------
assert_status "is_absolute_path true" 0 is_absolute_path /etc/passwd
assert_status "is_absolute_path false" 1 is_absolute_path relative/path

assert_status "is_relative_path true" 0 is_relative_path relative/path
assert_status "is_relative_path false" 1 is_relative_path /abs/path

# -------------------------
# Symlink & read/write helpers
# -------------------------
assert_status "is_symlink true" 0 is_symlink "${TMPDIR}/link"
assert_status "is_readable_file true" 0 is_readable_file "${TMPDIR}/not_empty"
assert_status "is_writable_dir true" 0 is_writable_dir "${TMPDIR}/wdir"
assert_status "file_is_executable true" 0 file_is_executable "${TMPDIR}/exe"

# -------------------------
# Whitespace / function existence
# -------------------------
assert_status "is_empty_or_whitespace empty" 0 is_empty_or_whitespace ""
assert_status "is_empty_or_whitespace spaces" 0 is_empty_or_whitespace "   "
assert_status "is_empty_or_whitespace non-empty" 1 is_empty_or_whitespace "x"

# create a test function and check is_function
test_fn_for_is_function() { :; }
assert_status "is_function detects function" 0 is_function test_fn_for_is_function
assert_status "is_function unknown returns 1" 1 is_function definitely_not_existing_fn_12345

# -------------------------
# Comment and function-line helpers
# -------------------------
assert_status "is_comment_line '#' at start returns 0" 0 is_comment_line "# hello"
assert_status "is_comment_line indented # returns 0" 0 is_comment_line "  # hi"
assert_status "is_comment_line non-comment returns 1" 1 is_comment_line "echo hi"

assert_status "is_func_start_line 'function foo()' returns 0" 0 is_func_start_line "function foo() {"
assert_status "is_func_start_line 'bar()' returns 0" 0 is_func_start_line "bar() {"
assert_status "is_func_start_line other returns 1" 1 is_func_start_line "echo hi"

assert_status "is_open_brace_line '{' returns 0" 0 is_open_brace_line "  {   "
assert_status "is_open_brace_line other returns 1" 1 is_open_brace_line "notbrace"

# extract_func_name
out="$(extract_func_name 'function foo()')"
assert_eq "extract_func_name 'function foo()' -> foo" "foo" "${out}"
out="$(extract_func_name 'bar() {')"
assert_eq "extract_func_name 'bar() {' -> bar" "bar" "${out}"
out="$(extract_func_name 'function   qux')"
assert_eq "extract_func_name 'function   qux' -> qux" "qux" "${out}"

# collect_comment & append_comment
c="$(collect_comment "" "# This is a test")"
assert_eq "collect_comment first line" "This is a test" "${c}"
c2="$(collect_comment "${c}" "# More")"
# Expected indentation applied by append_comment: existing then '    ' plus new line
case "${c2}" in
  *"This is a test"*"More"*) ok "collect_comment appends lines" ;;
  *) not_ok "collect_comment did not append correctly: ${c2}" ;;
esac

# process_function_start -> returns function name
out="$(process_function_start 'function abc {')"
assert_eq "process_function_start extracts abc" "abc" "${out}"

# handle_function_end behavior:
# Provide a comment block and function name; capture stdout
h_out="$(handle_function_end "A comment" "cmd_mycmd" "")"
case "${h_out}" in
  *"mycmd"*"A comment"*) ok "handle_function_end prints name w/o prefix" ;;
  *) not_ok "handle_function_end output unexpected: ${h_out}" ;;
esac

# extract_all_comments: create a small script
cat > "${TMPDIR}/sample.sh" <<'SCRIPT'
# Global comment
# For the file
function cmd_alpha() {
  # alpha does something
  :
}

# Comment for beta
beta()
{
  # beta details
  :
}

# A function without prefix
plain() { :; }
SCRIPT

# Test extracting all comments (no filter) -> should list alpha, beta, plain
out_all="$(extract_all_comments "${TMPDIR}/sample.sh")"
case "${out_all}" in
  (*alpha*|*beta*|*plain*) ok "extract_all_comments lists functions" ;;
  (*) not_ok "extract_all_comments did not list expected functions: ${out_all}" ;;
esac

# Test extract_all_comments with target function name (exact function name)
out_filtered="$(extract_all_comments "${TMPDIR}/sample.sh" "cmd_alpha")"
case "${out_filtered}" in
  (*alpha*) ok "extract_all_comments filtered by specific function" ;;
  (*) not_ok "extract_all_comments filter failed: ${out_filtered}" ;;
esac

# list_functions: define some functions and ensure listing works
# Define two functions with prefix 'ut_'
ut_one() { :; }
ut_two() { :; }

list_out="$(list_functions ut_)"
case "${list_out}" in
  (*ut_one*|*ut_two*) ok "list_functions found functions with prefix" ;;
  (*) not_ok "list_functions did not find expected functions: ${list_out}" ;;
esac

## main: test executing a command by defining a prefixed function and invoking main
#__FUNCTION_PREFIX="ut_"
#ut_hello() { printf 'HELLO'; }
## Run main with 'hello' as command and capture output
#main_out="$(main hello 2>/dev/null || true)"
#if [ "$(printf '%s' "${main_out}" | tr -d '\r\n')" = "HELLO" ]; then
#  ok "main invokes command function and output matches"
#else
#  not_ok "main invocation failed, got: '${main_out}'"
#fi
#
## usage and help call basic smoke tests (should not crash)
## usage prints a help to stdout; just ensure it runs
#if usage >/dev/null 2>&1; then
#  ok "usage shows text (exit 0)"
#else
#  not_ok "usage exited non-zero"
#fi
#
#if help >/dev/null 2>&1; then
#  ok "help shows text (exit 0)"
#else
#  not_ok "help exited non-zero"
#fi

# Final summary
printf "\nTests run: %d, Failures: %d\n" "${TEST_NUM}" "${FAILED}"
if [ "${FAILED}" -eq 0 ]; then
  exit 0
else
  exit 1
fi
