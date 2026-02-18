#!/usr/bin/env bb

;; Print all public functions from Babashka built-in namespaces
;; The list is based on https://book.babashka.org/#libraries

(def builtin-namespaces
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

(doseq [ns-sym builtin-namespaces]
  (try
    (require ns-sym)
    (println (str "\n;; " ns-sym))
    (->> (ns-publics ns-sym)
         (keys)
         (map name)
         (sort)
         (run! println))
    (catch Exception e
      (println (str ";; " ns-sym " - failed to load: " (.getMessage e))))))
