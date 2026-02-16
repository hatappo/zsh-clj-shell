# zsh-clj-shell

Clojure (Babashka) shell integration for Zsh, inspired by [Rash](https://docs.racket-lang.org/rash/).

Lines that start with `(` are evaluated as Clojure expressions by [Babashka](https://github.com/babashka/babashka).  
All other lines run as normal zsh commands.

## Examples

```clojure
$ (+ 1 2 3)
6

$ (str "hello" " " "world")
"hello world"

$ (-> 5 (+ 3) (* 2))
16

$ ls -la
drwxr-xr-x  5 user  staff  160 Feb 16 19:00 .
...

$ printf '  hello  ' | (clojure.string/trim %)
"hello"

$ (+ 10 20) | cat
30
```

## Requirements

- zsh 5.0+
- [Babashka](https://github.com/babashka/babashka#installation)

## Installation

### Automatic Installation

```bash
git clone https://github.com/fumihikohata/zsh-clj-shell.git
cd zsh-clj-shell
./install.sh
```

### Manual Installation

Add the following to `~/.zshrc`:

```zsh
source /path/to/zsh-clj-shell/zsh-clj-shell.plugin.zsh
```

Place this near the end of `~/.zshrc` so later plugins do not replace `accept-line`.

## Unload

To disable `zsh-clj-shell` in the current session:

```
zsh-clj-shell-unload
```

## How It Works

The plugin overrides the ZLE `accept-line` widget and checks the input when Enter is pressed:

1. Starts with `(`: evaluate with `bb -e`
2. Otherwise: execute as a normal zsh command

For pipelines with `|`, each stage that starts with `( ... )` is treated as a Clojure stage.
- Pipeline input is passed as a string to `%`
- String results are printed as plain text with a trailing newline
- Non-string results are printed via `pr-str` with a trailing newline
- `clojure.string` is auto-loaded (`trim`, `upper-case`, etc. can be used without namespace)

Babashka startup is typically around ~20ms, so interactive lag is minimal.

## Notes

- Any input that starts with `(` is sent to Babashka.
- If you need zsh subshell syntax `(command)`, use `{ command }` instead.
- Ambiguous lines (for example, lines that contain `||`) are not transformed and are passed to zsh as-is.
