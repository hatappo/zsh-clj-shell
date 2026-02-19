# Changelog

All notable changes to this project are documented in this file.

## [v0.1.2] - 2026-02-19

### Added
- User-defined functions support for config files (`init.bb` / `init.clj`).
- User-defined functions in completion candidates.

### Fixed
- `accept-line` widget compatibility for `zsh-abbr` chains.
- History navigation for the first command.
- Installer update logic to avoid touching commented `zshrc` lines.

## [v0.1.1] - 2026-02-18

### Fixed
- Completion performance and cleanup.

## [v0.1.0] - 2026-02-18

### Added
- Initial release of `zsh-clj-shell`.
- Clojure stage support in shell pipelines.
- `%` (line vector) and `%%` (raw string) pipeline input variables.
- Tab completion for Babashka/Clojure functions.

### Docs
- Installation instructions for plugin managers.
