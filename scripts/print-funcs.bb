(if-let [ns-name (first *command-line-args*)]
  (let [ns-sym (symbol ns-name)]
    (require ns-sym)
    (->> (ns-publics ns-sym)
         (keys)
         (map name)
         (sort)
         (run! println)))
  (do
    (println "Usage: bb print-funcs <namespace>")
    (System/exit 1)))
