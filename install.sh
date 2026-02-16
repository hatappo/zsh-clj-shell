#!/usr/bin/env bash
set -euo pipefail

# zsh-clj-shell installer

INSTALL_DIR="${HOME}/.zsh-clj-shell"
ZSHRC="${HOME}/.zshrc"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_FILE="zsh-clj-shell.plugin.zsh"

# Check Babashka
if ! command -v bb &> /dev/null; then
  echo "Error: Babashka (bb) was not found"
  echo "Install: https://github.com/babashka/babashka#installation"
  exit 1
fi

echo "Babashka found: $(bb --version)"

# Create install directory
mkdir -p "$INSTALL_DIR"

# Copy plugin file
cp "$SCRIPT_DIR/$PLUGIN_FILE" "$INSTALL_DIR/"
echo "Copied plugin to ${INSTALL_DIR}/"

# Add config to .zshrc if needed
if [[ -f "$ZSHRC" ]] && grep -q 'source.*zsh-clj-shell\.plugin\.zsh' "$ZSHRC"; then
  echo "zsh-clj-shell config already exists in .zshrc (skipped)"
else
  {
    echo ""
    echo "# zsh-clj-shell - Clojure (Babashka) shell integration"
    echo "source ${INSTALL_DIR}/${PLUGIN_FILE}"
  } >> "$ZSHRC"
  echo "Added config to .zshrc"
fi

echo ""
echo "zsh-clj-shell installation complete!"
echo "Restart your shell or run:"
echo "  source ~/.zshrc"
