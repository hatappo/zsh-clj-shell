#!/usr/bin/env bb

;; Generate completion list for zsh-clj-shell plugin
;; Output format is zsh array syntax
;; The list is based on https://book.babashka.org/#libraries

;; Namespace aliases (commonly used short names)
(def namespace-aliases
  {"clojure.string"         "str"
   "clojure.set"            "set"
   "clojure.java.io"        "io"
   "clojure.java.shell"     "shell"
   "clojure.edn"            "edn"
   "clojure.walk"           "walk"
   "clojure.zip"            "zip"
   "clojure.math"           "math"
   "clojure.pprint"         "pp"
   "clojure.test"           "test"
   "clojure.tools.cli"      "tools.cli"
   "clojure.core.async"     "async"
   "babashka.fs"            "fs"
   "babashka.process"       "proc"
   "babashka.http-client"   "http"
   "cheshire.core"          "json"
   "clojure.data.csv"       "csv"
   "clojure.data.xml"       "xml"
   "bencode.core"           "bencode"
   "clj-yaml.core"          "yaml"
   "cognitect.transit"      "transit"})

;; Namespaces to include (from Babashka documentation)
(def namespaces
  '[;; From Clojure
    clojure.core
    clojure.core.protocols
    clojure.data
    clojure.datafy
    clojure.edn
    clojure.math
    clojure.java.browse
    clojure.java.io
    clojure.java.shell
    clojure.main
    clojure.pprint
    clojure.set
    clojure.string
    clojure.stacktrace
    clojure.test
    clojure.walk
    clojure.zip

    ;; Babashka specific
    babashka.cli
    babashka.classpath
    babashka.deps
    babashka.fs
    babashka.http-client
    babashka.process
    babashka.signal
    babashka.tasks
    babashka.wait

    ;; Additional libraries
    bencode.core
    cheshire.core
    clojure.core.async
    clojure.data.csv
    clojure.data.xml
    clojure.tools.cli
    clj-yaml.core
    cognitect.transit
    org.httpkit.client
    org.httpkit.server
    clojure.core.match
    hiccup.core
    hiccup2.core
    clojure.test.check
    clojure.test.check.generators
    clojure.test.check.properties
    rewrite-clj.parser
    rewrite-clj.node
    rewrite-clj.zip
    rewrite-clj.paredit
    selmer.parser
    clojure.tools.logging
    taoensso.timbre
    edamame.core
    nextjournal.markdown])

(defn get-funcs [ns-sym]
  (try
    (require ns-sym)
    (->> (ns-publics ns-sym)
         (keys)
         (map name)
         (sort))
    (catch Exception _ [])))

(defn safe-for-zsh? [s]
  ;; Exclude function names that cause zsh parse errors
  (not (or (re-find #"[<>]" s)        ; redirection chars
           (re-find #"'" s)            ; single quote in name (like +')
           (re-find #"^\*" s)          ; dynamic vars like *out*
           (re-find #"^\." s))))       ; .. etc

(defn quote-for-zsh [s]
  (str "'" s "'"))

(defn generate-completions []
  (let [all-completions (atom [])]
    (doseq [ns-sym namespaces]
      (let [ns-name (name ns-sym)
            alias (get namespace-aliases ns-name)
            funcs (get-funcs ns-sym)]
        (doseq [func funcs]
          (if (= ns-name "clojure.core")
            ;; clojure.core: no prefix needed
            (swap! all-completions conj func)
            ;; Other namespaces: full qualified name
            (do
              (swap! all-completions conj (str ns-name "/" func))
              ;; Also add alias if available
              (when alias
                (swap! all-completions conj (str alias "/" func))))))))
    ;; Sort, dedupe, and filter unsafe names
    (->> @all-completions
         (filter safe-for-zsh?)
         (distinct)
         (sort))))

(defn -main []
  (let [completions (generate-completions)]
    (println "  local -a clj_completions=(")
    (doseq [c completions]
      (println (str "    " (quote-for-zsh c))))
    (println "  )")))

(-main)
