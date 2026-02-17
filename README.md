# zsh-clj-shell

Clojure (Babashka) shell integration for Zsh, inspired by [Rash](https://docs.racket-lang.org/rash/) and [Closh](https://github.com/dundalek/closh).

Lines that start with `(` are evaluated as Clojure expressions by [Babashka](https://github.com/babashka/babashka).  
All other lines run as normal zsh commands.

## Examples

### Basic Clojure Expressions

```clojure
$ (+ 1 2 3)
6

$ (str "hello" " " "world")
"hello world"

$ (-> 5 (+ 3) (* 2))
16
```

### Pipeline with Sequences (`%`)

Input lines are split into a vector. Use `map`, `filter`, etc. to process each line.

```clojure
$ printf 'hello\nworld' | (map upper-case %)
HELLO
WORLD

$ printf '  a  \n  b  ' | (map (comp upper-case trim) %)
A
B

$ printf 'apple\nbanana\ncherry' | (filter #(> (count %) 5) %)
banana
cherry

$ printf 'a\nb\nc' | (count %)
3
```

### Pipeline with Raw String (`%%`)

Use `%%` when you need the entire input as a single string.

```clojure
$ printf 'hello world' | (upper-case %%)
HELLO WORLD

$ printf 'a\nb\nc' | (count %%)
5

$ printf 'hello\nworld' | (replace %% "\n" ", ")
hello, world
```

### Mixed with Shell Commands

```clojure
$ ls -la
drwxr-xr-x  5 user  staff  160 Feb 16 19:00 .
...

$ (+ 10 20) | cat
30

$ printf '  aaa  \n  bbb  ' | (map (comp upper-case trim) %) | cat -n
     1	AAA
     2	BBB
```

## Requirements

- zsh 5.0+
- [Babashka](https://github.com/babashka/babashka#installation)

## Installation

### Plugin Managers

#### zinit

```zsh
zinit light hatappo/zsh-clj-shell
```

#### zplug

```zsh
zplug "hatappo/zsh-clj-shell"
```

#### antigen

```zsh
antigen bundle hatappo/zsh-clj-shell
```

#### sheldon

Add to `~/.config/sheldon/plugins.toml`:

```toml
[plugins.zsh-clj-shell]
github = "hatappo/zsh-clj-shell"
```

#### oh-my-zsh

Clone the repository to oh-my-zsh custom plugins directory:

```bash
git clone https://github.com/hatappo/zsh-clj-shell.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-clj-shell
```

Then add `zsh-clj-shell` to your plugins in `~/.zshrc`:

```zsh
plugins=(... zsh-clj-shell)
```

### Automatic Installation

```bash
git clone https://github.com/hatappo/zsh-clj-shell.git
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

### Pipeline Input

| Variable | Description | Example |
|----------|-------------|---------|
| `%` | Input lines as a vector | `"a\nb"` → `["a" "b"]` |
| `%%` | Raw input as a single string | `"a\nb"` → `"a\nb"` |

### Pipeline Output

| Result Type | Output Format |
|-------------|---------------|
| Sequential (vector, list) | Each element on a new line |
| String | Plain text |
| Other | `pr-str` representation |

### Auto-loaded Libraries

`clojure.string` is auto-loaded with `:refer :all`, so functions like `trim`, `upper-case`, `replace`, etc. can be used without namespace prefix.

Babashka startup is typically around ~20ms, so interactive lag is minimal.

## Notes

- Any input that starts with `(` is sent to Babashka.
- If you need zsh subshell syntax `(command)`, use `{ command }` instead.
- Ambiguous lines (for example, lines that contain `||`) are not transformed and are passed to zsh as-is.
