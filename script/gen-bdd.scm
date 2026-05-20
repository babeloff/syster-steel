;; generate-bdd.scm
;; Reads vehicle.sysml and writes vehicle-bdd.puml
;; syster/base functions are registered automatically — no require needed

(require-builtin steel/process)

;;; ── helpers ───────────────────────────────────────────────────────────────

(define (kind? sym k)
  (string=? (hir-symbol/kind sym) k))

(define (get-usages-of sym all-syms)
  "Return symbols whose qualified name starts with sym's qualified name."
  (let ([prefix (string-append (hir-symbol/qualified-name sym) "::")])
    (filter (lambda (s)
              (starts-with? (hir-symbol/qualified-name s) prefix))
            all-syms)))

;;; ── PlantUML class block for a part def ───────────────────────────────────

(define (part-def->plantuml sym all-syms)
  (let* ([name     (hir-symbol/name sym)]
         [members  (get-usages-of sym all-syms)]
         [attrs    (filter (lambda (s) (kind? s "AttributeUsage")) members)]
         [ports    (filter (lambda (s) (kind? s "PortUsage"))      members)]
         [attr-lines
          (map (lambda (a)
                 (string-append "  + " (hir-symbol/name a) " : Real\n"))
               attrs)]
         [port-lines
          (map (lambda (p)
                 (string-append "  ~ " (hir-symbol/name p) "\n"))
               ports)])
    (apply string-append
           (append
            (list (string-append "class \"" name "\" <<block>> {\n"))
            attr-lines
            port-lines
            (list "}\n\n")))))

;;; ── composition relationships ────────────────────────────────────────────

(define (composition-lines sym all-syms)
  (let* ([name    (hir-symbol/name sym)]
         [members (get-usages-of sym all-syms)]
         [parts   (filter (lambda (s) (kind? s "PartUsage")) members)])
    (map (lambda (p)
           (let ([rels (hir-symbol/relationships p)])
             (let ([typed-by (filter (lambda (r)
                                       (string=? (hir-rel/kind r) "TypedBy"))
                                     rels)])
               (if (pair? typed-by)
                   (string-append
                    "\"" name "\" *-- \""
                    (hir-rel/target (car typed-by))
                    "\" : "
                    (hir-symbol/name p) "\n")
                   ""))))
         parts)))

;;; ── assemble the diagram ─────────────────────────────────────────────────

(define (generate-bdd model-path output-path)
  (let* ([model    (syster/parse-file model-path)]
         [syms     (syster/file-symbols model)]
         [part-defs (filter (lambda (s) (kind? s "PartDefinition")) syms)]
         [classes  (apply string-append
                          (map (lambda (s) (part-def->plantuml s syms))
                               part-defs))]
         [composes (apply string-append
                          (apply append
                                 (map (lambda (s) (composition-lines s syms))
                                      part-defs)))]
         [diagram  (string-append
                    "@startuml\n"
                    "skinparam classBackgroundColor<<block>> LightSteelBlue\n\n"
                    classes
                    composes
                    "@enduml\n")])
    (let ([port (open-output-file output-path)])
      (display diagram port)
      (close-output-port port))
    (displayln (string-append "Wrote " output-path))))
