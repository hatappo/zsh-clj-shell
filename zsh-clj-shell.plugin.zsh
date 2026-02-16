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

# Custom accept-line widget
zsh-clj-shell-accept-line() {
  local bb_expr_pattern='^[[:space:]]*[(]'

  # Keep empty lines on the normal execution path
  if [[ -z "$BUFFER" ]]; then
    zsh-clj-shell-call-original-accept-line
    return
  fi

  # Evaluate lines that start with "(" using Babashka
  if [[ "$BUFFER" =~ $bb_expr_pattern ]]; then
    local expr="$BUFFER"
    local bb_exit_code=0

    # Store the original expression in shell history
    print -s -- "$expr"

    # Flush ZLE state before writing command output
    zle -I
    bb -e "$expr"
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

# Preserve existing accept-line unless already managed by this plugin
if [[ "$(zle -lL accept-line 2>/dev/null)" != *"zsh-clj-shell-accept-line"* ]]; then
  zle -A accept-line zsh-clj-shell-orig-accept-line
fi

# Register widget
zle -N accept-line zsh-clj-shell-accept-line

# Unload function
zsh-clj-shell-unload() {
  if zle -l | grep -qx 'zsh-clj-shell-orig-accept-line'; then
    zle -A zsh-clj-shell-orig-accept-line accept-line
    zle -D zsh-clj-shell-orig-accept-line
  else
    zle -A .accept-line accept-line
  fi
  zle -D zsh-clj-shell-accept-line
  echo "zsh-clj-shell: unloaded"
}
