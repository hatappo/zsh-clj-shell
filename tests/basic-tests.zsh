#!/usr/bin/env zsh
# zsh-clj-shell basic tests

echo "--- Babashka tests ---"

# Test: bb command is available
if command -v bb &> /dev/null; then
  assert_equals "true" "true" "bb command is available"
else
  assert_equals "true" "false" "bb command is available"
fi

# Test: simple Clojure expression
result=$(bb -e '(+ 1 2)')
assert_equals "3" "$result" "simple addition (+ 1 2)"

# Test: string expression
result=$(bb -e '(str "hello" " " "world")')
assert_equals '"hello world"' "$result" "string concatenation (str ...)"

# Test: multiline expression
result=$(bb -e '(do
  (+ 1 2)
  (+ 3 4))')
assert_equals "7" "$result" "multiline expression (do ...)"

echo ""
echo "--- Pattern matching tests ---"

# Test: matching lines that start with "("
test_pattern='^[[:space:]]*[(]'

buffer="(+ 1 2)"
if [[ "$buffer" =~ $test_pattern ]]; then
  assert_equals "true" "true" "\"(+ 1 2)\" is recognized as a Clojure expression"
else
  assert_equals "true" "false" "\"(+ 1 2)\" is recognized as a Clojure expression"
fi

buffer="  (+ 1 2)"
if [[ "$buffer" =~ $test_pattern ]]; then
  assert_equals "true" "true" "\"  (+ 1 2)\" (leading whitespace) is recognized as a Clojure expression"
else
  assert_equals "true" "false" "\"  (+ 1 2)\" (leading whitespace) is recognized as a Clojure expression"
fi

buffer="ls -la"
if [[ "$buffer" =~ $test_pattern ]]; then
  assert_equals "false" "true" "\"ls -la\" is recognized as a shell command"
else
  assert_equals "false" "false" "\"ls -la\" is recognized as a shell command"
fi

buffer="echo hello"
if [[ "$buffer" =~ $test_pattern ]]; then
  assert_equals "false" "true" "\"echo hello\" is recognized as a shell command"
else
  assert_equals "false" "false" "\"echo hello\" is recognized as a shell command"
fi

buffer=""
if [[ "$buffer" =~ $test_pattern ]]; then
  assert_equals "false" "true" "empty string is recognized as a shell command"
else
  assert_equals "false" "false" "empty string is recognized as a shell command"
fi

echo ""
echo "--- Subshell conflict tests ---"

# Test: subshell syntax "(command)" is also matched as Clojure
buffer="(cd /tmp && ls)"
if [[ "$buffer" =~ $test_pattern ]]; then
  assert_equals "true" "true" "subshell \"(cd /tmp && ls)\" is also recognized as Clojure input"
else
  assert_equals "true" "false" "subshell \"(cd /tmp && ls)\" is also recognized as Clojure input"
fi

buffer="(echo hello)"
if [[ "$buffer" =~ $test_pattern ]]; then
  assert_equals "true" "true" "subshell \"(echo hello)\" is also recognized as Clojure input"
else
  assert_equals "true" "false" "subshell \"(echo hello)\" is also recognized as Clojure input"
fi

# Test: subshell syntax causes errors in Babashka
bb -e '(cd /tmp && ls)' 2>/dev/null
assert_equals "1" "$?" "\"(cd /tmp && ls)\" fails in Babashka"

bb -e '(echo hello)' 2>/dev/null
assert_equals "1" "$?" "\"(echo hello)\" fails in Babashka"

# Test: alternative syntax using { } works
result=$(eval '{ cd /tmp && pwd }')
assert_equals "/tmp" "$result" "\"{ cd /tmp && pwd }\" can replace subshell-like behavior"

result=$(eval '{ echo hello }')
assert_equals "hello" "$result" "\"{ echo hello }\" can replace subshell-like behavior"

# Test: { } is not recognized as Clojure input
buffer="{ cd /tmp && ls }"
if [[ "$buffer" =~ $test_pattern ]]; then
  assert_equals "false" "true" "\"{ cd /tmp && ls }\" is recognized as a shell command"
else
  assert_equals "false" "false" "\"{ cd /tmp && ls }\" is recognized as a shell command"
fi

echo ""
echo "--- Plugin file tests ---"

plugin_file="${PROJECT_DIR}/zsh-clj-shell.plugin.zsh"
if [[ -f "$plugin_file" ]]; then
  assert_equals "true" "true" "zsh-clj-shell.plugin.zsh exists"
else
  assert_equals "true" "false" "zsh-clj-shell.plugin.zsh exists"
fi

# Verify zsh-clj-shell-accept-line is defined
if grep -q 'zsh-clj-shell-accept-line' "$plugin_file"; then
  assert_equals "true" "true" "zsh-clj-shell-accept-line is defined"
else
  assert_equals "true" "false" "zsh-clj-shell-accept-line is defined"
fi

# Verify zsh-clj-shell-unload is defined
if grep -q 'zsh-clj-shell-unload' "$plugin_file"; then
  assert_equals "true" "true" "zsh-clj-shell-unload is defined"
else
  assert_equals "true" "false" "zsh-clj-shell-unload is defined"
fi

echo ""
echo "--- Pipeline transform tests ---"

# Test: pipeline line with a Clojure stage is transformed
result=$(zsh -ic "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line '(+ 1 2) | cat'; print -r -- \"\$?::\$REPLY\"")
assert_match '^0::bb -e .* \| cat$' "$result" "Clojure stage in a pipeline is transformed"

# Test: pure shell pipeline is not transformed
result=$(zsh -ic "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line 'echo hi | cat'; print -r -- \"\$?::\$REPLY\"")
assert_match '^1::' "$result" "Pure shell pipeline is not transformed"

# Test: || line falls back to zsh behavior
result=$(zsh -ic "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line '(+ 1 2) || echo ng'; print -r -- \"\$?::\$REPLY\"")
assert_match '^1::' "$result" "Boolean OR line is not transformed"

# Test: string output from a Clojure stage is emitted without extra quotes (using map for sequence)
result=$(zsh -fc "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line \"printf '  hello  ' | (map clojure.string/trim %) | (map clojure.string/upper-case %)\"; eval -- \"\$REPLY\"")
assert_equals "HELLO" "$result" "String pipeline output stays plain text"

# Test: count now returns element count (sequence length), not string length
result=$(zsh -fc "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line \"printf 'hello' | (count %)\"; eval -- \"\$REPLY\"")
assert_equals "1" "$result" "Single line input becomes 1-element vector"

# Test: clojure.string functions are available without namespace qualification (using map)
result=$(zsh -fc "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line \"printf '  hello  ' | (map trim %) | (map upper-case %)\"; eval -- \"\$REPLY\"")
assert_equals "HELLO" "$result" "clojure.string functions can be used without namespace"

echo ""
echo "--- Sequence input/output tests ---"

# Test: multiline input becomes a vector
result=$(zsh -fc "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line \"printf 'a\nb\nc' | (count %)\"; eval -- \"\$REPLY\"")
assert_equals "3" "$result" "Multiline input becomes a 3-element vector"

# Test: map over lines
result=$(zsh -fc "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line \"printf 'a\nb' | (map upper-case %)\"; eval -- \"\$REPLY\"")
assert_equals $'A\nB' "$result" "map upper-case over lines"

# Test: %% provides raw string
result=$(zsh -fc "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line \"printf 'a\nb' | (count %%)\"; eval -- \"\$REPLY\"")
assert_equals "3" "$result" "%% provides raw string (length of 'a\\nb' is 3)"

# Test: empty input becomes empty vector
result=$(zsh -fc "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line \"printf '' | (count %)\"; eval -- \"\$REPLY\"")
assert_equals "0" "$result" "Empty input becomes empty vector"

# Test: chained map pipeline
result=$(zsh -fc "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line \"printf '  a  \n  b  ' | (map trim %) | (map upper-case %)\"; eval -- \"\$REPLY\"")
assert_equals $'A\nB' "$result" "Chained map operations"

# Test: filter operation
result=$(zsh -fc "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line \"printf 'a\nbb\nccc' | (filter #(> (count %) 1) %)\"; eval -- \"\$REPLY\"")
assert_equals $'bb\nccc' "$result" "filter operation on lines"

# Test: reverse operation (use clojure.core/reverse explicitly to avoid conflict with clojure.string/reverse)
result=$(zsh -fc "source '${PROJECT_DIR}/zsh-clj-shell.plugin.zsh'; zsh-clj-shell-transform-line \"printf 'a\nb\nc' | (clojure.core/reverse %)\"; eval -- \"\$REPLY\"")
assert_equals $'c\nb\na' "$result" "reverse operation on lines"
