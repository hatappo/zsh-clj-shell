#!/usr/bin/env zsh
# zsh-clj-shell - Clojure (Babashka) Shell Integration for Zsh
# https://github.com/fumihikohata/zsh-clj-shell
#
# A Clojure/Babashka-style shell flow inspired by Racket Rash.
# Lines that start with "(" are evaluated by Babashka,
# and all other lines are handled as regular zsh commands.

# Check that Babashka is available
if ! command -v bb &> /dev/null; then
  echo "zsh-clj-shell: warning: 'bb' (Babashka) was not found" >&2
  echo "zsh-clj-shell: install: https://github.com/babashka/babashka#installation" >&2
  return 1
fi

# Call the original accept-line if it was preserved
zsh-clj-shell-call-original-accept-line() {
  zle zsh-clj-shell-orig-accept-line 2>/dev/null || zle .accept-line
}

# Ensure our accept-line wrapper is installed, while preserving current target.
zsh-clj-shell-install-widget() {
  local current_widget
  current_widget="$(zle -lL accept-line 2>/dev/null)"

  if [[ "$current_widget" == *"zsh-clj-shell-accept-line"* ]]; then
    return 0
  fi

  zle -A accept-line zsh-clj-shell-orig-accept-line
  zle -N accept-line zsh-clj-shell-accept-line
}

# Trim leading and trailing whitespace
zsh-clj-shell-trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  print -r -- "$value"
}

# Build a bb stage from a Clojure expression
zsh-clj-shell-build-bb-stage() {
  local expr="$1"
  local has_input="$2"
  local input_form='""'
  local script

  if (( has_input )); then
    input_form='(slurp *in*)'
  fi

  script="(do (require '[clojure.string :as str :refer :all]) (let [input ${input_form} % input result ${expr}] (if (string? result) (println result) (println (pr-str result)))))"
  print -r -- "bb -e ${(q)script}"
}

# Transform a command line that may include pipe-separated Clojure stages.
# On success: REPLY contains transformed command and return 0.
# On fallback: REPLY is unchanged and return 1.
zsh-clj-shell-transform-line() {
  local line="$1"
  local current=""
  local ch next_ch
  local in_single=0
  local in_double=0
  local escape_next=0
  local i len
  local -a raw_stages
  local -a transformed_stages
  local stage trimmed transformed_line=""
  local has_clj_stage=0

  len=${#line}
  for (( i = 1; i <= len; i++ )); do
    ch="${line[i]}"

    if (( escape_next )); then
      current+="$ch"
      escape_next=0
      continue
    fi

    if [[ "$ch" == "\\" ]]; then
      current+="$ch"
      if (( ! in_single )); then
        escape_next=1
      fi
      continue
    fi

    if (( ! in_double )) && [[ "$ch" == "'" ]]; then
      current+="$ch"
      (( in_single = 1 - in_single ))
      continue
    fi

    if (( ! in_single )) && [[ "$ch" == '"' ]]; then
      current+="$ch"
      (( in_double = 1 - in_double ))
      continue
    fi

    if (( ! in_single && ! in_double )) && [[ "$ch" == "|" ]]; then
      next_ch="${line[i+1]}"
      # Keep || unsupported for now to avoid changing boolean semantics.
      if [[ "$next_ch" == "|" ]]; then
        return 1
      fi
      raw_stages+=("$current")
      current=""
      continue
    fi

    current+="$ch"
  done

  if (( in_single || in_double || escape_next )); then
    return 1
  fi

  raw_stages+=("$current")

  for (( i = 1; i <= ${#raw_stages}; i++ )); do
    stage="${raw_stages[i]}"
    trimmed="$(zsh-clj-shell-trim "$stage")"

    if [[ -z "$trimmed" ]]; then
      return 1
    fi

    if [[ "$trimmed" == [\(]* ]]; then
      transformed_stages+=("$(zsh-clj-shell-build-bb-stage "$trimmed" $(( i > 1 )))")
      has_clj_stage=1
    else
      transformed_stages+=("$trimmed")
    fi
  done

  if (( ! has_clj_stage )); then
    return 1
  fi

  transformed_line="${transformed_stages[1]}"
  for (( i = 2; i <= ${#transformed_stages}; i++ )); do
    transformed_line+=" | ${transformed_stages[i]}"
  done

  REPLY="$transformed_line"
  return 0
}

# Custom accept-line widget
zsh-clj-shell-accept-line() {
  local bb_expr_pattern='^[[:space:]]*[(]'
  local line="$BUFFER"
  local transformed_line
  local bb_exit_code=0

  # Keep empty lines on the normal execution path
  if [[ -z "$line" ]]; then
    zsh-clj-shell-call-original-accept-line
    return
  fi

  transformed_line=""
  if zsh-clj-shell-transform-line "$line"; then
    transformed_line="$REPLY"
  fi

  # If the line is a Clojure stage or contains Clojure stages in a pipeline,
  # evaluate the transformed command directly to keep history/user input stable.
  if [[ -n "$transformed_line" ]] || [[ "$line" =~ $bb_expr_pattern ]]; then
    if [[ -z "$transformed_line" ]]; then
      transformed_line="$(zsh-clj-shell-build-bb-stage "$line" 0)"
    fi

    # Store the original expression/line in shell history
    print -s -- "$line"

    # Flush ZLE and execute transformed command
    zle -I
    eval -- "$transformed_line"
    bb_exit_code=$?

    # Clear editor state and redraw prompt
    BUFFER=""
    CURSOR=0
    zle end-of-history
    zle -R
    return $bb_exit_code
  else
    # Run normal shell commands through original flow
    zsh-clj-shell-call-original-accept-line
  fi
}

# Register/refresh widget and keep it active even if other plugins replace it later
zsh-clj-shell-install-widget
autoload -Uz add-zsh-hook
add-zsh-hook precmd zsh-clj-shell-install-widget

# Unload function
zsh-clj-shell-unload() {
  autoload -Uz add-zsh-hook
  add-zsh-hook -d precmd zsh-clj-shell-install-widget

  if zle -l | grep -qx 'zsh-clj-shell-orig-accept-line'; then
    zle -A zsh-clj-shell-orig-accept-line accept-line
    zle -D zsh-clj-shell-orig-accept-line
  else
    zle -A .accept-line accept-line
  fi
  zle -D zsh-clj-shell-accept-line
  echo "zsh-clj-shell: unloaded"
}
