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
$ echo '  aaa  \n  bbb  \nccc' | (map (comp upper-case trim) %) | cat -n
     1	AAA
     2	BBB
     3  CCC
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

`clojure.string` is auto-loaded with `:refer :all`, so functions like `trim`, `upper-case`, `replace`, etc. can be used without namespace prefix. (Note: `:refer :all` is deprecated and will be removed in a future version. Use `str/` prefix instead.)

Babashka startup is typically around ~20ms, so interactive lag is minimal.

## Tab Completion

Press `Tab` inside parentheses to get completion for Clojure functions.

```clojure
$ (map upper-c<Tab>
$ (map upper-case    # completes to upper-case

$ (fs/cre<Tab>
$ (fs/create-        # shows create-dir, create-file, create-temp-dir, etc.
```

### Supported Namespaces

Completions are available for all Babashka built-in namespaces:

| Alias | Namespace |
|-------|-----------|
| `str/` | `clojure.string` |
| `set/` | `clojure.set` |
| `io/` | `clojure.java.io` |
| `fs/` | `babashka.fs` |
| `proc/` | `babashka.process` |
| `http/` | `babashka.http-client` |
| `json/` | `cheshire.core` |
| `yaml/` | `clj-yaml.core` |
| `async/` | `clojure.core.async` |
| `csv/` | `clojure.data.csv` |
| `xml/` | `clojure.data.xml` |
| `transit/` | `cognitect.transit` |

And many more including `clojure.core`, `clojure.walk`, `clojure.zip`, `hiccup.core`, `rewrite-clj.*`, `taoensso.timbre`, etc.

## User Configuration / User Defined Functions

Define your own functions in a config file:

```
~/.config/zsh-clj-shell/init.bb   (preferred)
~/.config/zsh-clj-shell/init.clj  (fallback)
```

Example `init.bb`:

```clojure
(defn hello [name]
  (str "Hello, " name "!"))

(defn count-words [text]
  (count (str/split text #"\s+")))
```

Usage:

```clojure
$ (hello "world")
Hello, world!

$ echo "one two three" | (count-words %%)
3
```

To reload your config without restarting the shell:

```
zsh-clj-shell-reload-config
```

## Requirements

- zsh 5.0+
- [Babashka](https://github.com/babashka/babashka#installation)

## Installation

### Plugin Managers

#### [zinit](https://github.com/zdharma-continuum/zinit)

```zsh
zinit light hatappo/zsh-clj-shell
```

#### [zplug](https://github.com/zplug/zplug)

```zsh
zplug "hatappo/zsh-clj-shell"
```

#### [antigen](https://github.com/zsh-users/antigen)

```zsh
antigen bundle hatappo/zsh-clj-shell
```

#### [sheldon](https://github.com/rossmacarthur/sheldon)

Add to `~/.config/sheldon/plugins.toml`:

```toml
[plugins.zsh-clj-shell]
github = "hatappo/zsh-clj-shell"
```

#### [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)

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

## Notes

- Any input that starts with `(` is sent to Babashka. If you need zsh subshell syntax `(command)`, use `{ command }` instead.
- Ambiguous lines (for example, lines that contain `||`) are not transformed and are passed to zsh as-is.
- `zsh-clj-shell` hooks ZLE widgets (especially `accept-line` and `Tab`). Plugins that also override these widgets can interfere depending on load order.
- Known interaction point: `zsh-abbr` (`accept-line` / space expansion). Current releases include a compatibility path, but if expansion stops working, reload your shell and verify widget bindings with `print -- "$widgets[accept-line]"`.
- Recommended order: load abbreviation/autosuggestion plugins first, then load `zsh-clj-shell` near the end of `.zshrc`.

## License

MIT.
