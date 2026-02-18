#!/usr/bin/env bash
set -euo pipefail

# zsh-clj-shell installer

INSTALL_DIR="${HOME}/.zsh-clj-shell"
ZSHRC="${HOME}/.zshrc"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_FILE="zsh-clj-shell.plugin.zsh"
COMPLETIONS_FILE="completions.zsh"

# Check Babashka
if ! command -v bb &> /dev/null; then
  echo "Error: Babashka (bb) was not found"
  echo "Install: https://github.com/babashka/babashka#installation"
  exit 1
fi

echo "Babashka found: $(bb --version)"

# Create install directory
mkdir -p "$INSTALL_DIR"

# Copy plugin files
cp "$SCRIPT_DIR/$PLUGIN_FILE" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/$COMPLETIONS_FILE" "$INSTALL_DIR/"
echo "Copied plugin files to ${INSTALL_DIR}/"

# Ensure zsh-clj-shell source line exists at the end of .zshrc
if [[ ! -f "$ZSHRC" ]]; then
  touch "$ZSHRC"
fi

tmp_zshrc="$(mktemp)"
awk '
  $0 !~ /source.*zsh-clj-shell\.plugin\.zsh/
' "$ZSHRC" > "$tmp_zshrc"
mv "$tmp_zshrc" "$ZSHRC"

{
  echo ""
  echo "# zsh-clj-shell - Clojure (Babashka) shell integration"
  echo "source ${INSTALL_DIR}/${PLUGIN_FILE}"
} >> "$ZSHRC"

echo "Updated .zshrc (source line moved to the end)"

echo ""
echo "zsh-clj-shell installation complete!"
echo "Restart your shell or run:"
echo "  source ~/.zshrc"
