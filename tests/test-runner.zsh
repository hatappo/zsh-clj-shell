#!/usr/bin/env zsh
# zsh-clj-shell test runner

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"

test_count=0
pass_count=0
fail_count=0

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  test_count=$((test_count + 1))

  if [[ "$expected" == "$actual" ]]; then
    pass_count=$((pass_count + 1))
    echo "  PASS: $message"
  else
    fail_count=$((fail_count + 1))
    echo "  FAIL: $message"
    echo "    expected: $expected"
    echo "    actual:   $actual"
  fi
}

assert_match() {
  local pattern="$1"
  local actual="$2"
  local message="$3"

  test_count=$((test_count + 1))

  if [[ "$actual" =~ $pattern ]]; then
    pass_count=$((pass_count + 1))
    echo "  PASS: $message"
  else
    fail_count=$((fail_count + 1))
    echo "  FAIL: $message"
    echo "    pattern:  $pattern"
    echo "    actual:   $actual"
  fi
}

echo "zsh-clj-shell tests"
echo "==========="
echo ""

# Run test files
source "${SCRIPT_DIR}/basic-tests.zsh"

echo ""
echo "==========="
echo "Total: $test_count | Passed: $pass_count | Failed: $fail_count"

if [[ $fail_count -gt 0 ]]; then
  exit 1
fi
