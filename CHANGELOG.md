# Changelog

All notable changes to this project are documented in this file.

## [v0.1.3] - 2026-02-19

### Fixed
- Installer now skips `.zshrc` updates when a `zsh-clj-shell.plugin.zsh` source line already exists.
- Expanded `.gitignore` with additional Zsh runtime artifacts and editor temporary files.

### Docs
- Added notes about widget interaction and plugin load order in `README.md`.
- Added this changelog file for release tracking.

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
