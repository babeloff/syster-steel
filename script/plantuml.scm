;; plantuml.scm — PlantUML generation procedures for syster-steel
;;
;; Provides helpers and diagram generators that consume lists of
;; HirSymbol values (as returned by syster/file-symbols) and produce
;; PlantUML source strings.
;;
;; Load this file with:
;;   (require "script/plantuml.scm")
;;
;; or, if script/ is on the load path:
;;   (require "plantuml")

(provide
  ;; Header / footer
  plantuml-header
  plantuml-footer

  ;; Low-level block builders
  symbol->class-block
  composition-line
  inheritance-line
  pu-alias

  ;; Diagram generators
  generate-bdd
  generate-ibd
  generate-viewpoints-diagram
  generate-package-diagram
  generate-state-machine

  ;; File output and rendering
  write-plantuml-file
  render-diagram
  render-diagram-to
  render-and-open)

;; ── Utilities ─────────────────────────────────────────────────────────────────

(define (pu-alias name)
  "Return a PlantUML-safe identifier by replacing non-alphanumeric chars."
  (define chars (string->list name))
  (list->string
    (map (lambda (c)
           (if (or (char-alphabetic? c) (char-numeric? c) (equal? c #\_))
               c
               #\_))
         chars)))

(define (string-join lst sep)
  "Join a list of strings with sep between each."
  (if (null? lst)
      ""
      (foldl (lambda (s acc)
               (if (equal? acc "")
                   s
                   (string-append acc sep s)))
             ""
             lst)))

(define (filter-kind symbols kind-str)
  "Return symbols whose kind string equals kind-str."
  (filter (lambda (s) (equal? (hir-symbol/kind s) kind-str)) symbols))

(define (filter-kinds symbols kind-list)
  "Return symbols whose kind string is in kind-list."
  (filter (lambda (s) (member (hir-symbol/kind s) kind-list)) symbols))

(define (display-or-empty v)
  "Return v if a string, else empty string."
  (if (string? v) v ""))

;; ── Header and footer ─────────────────────────────────────────────────────────

(define (plantuml-header . args)
  "Return the @startuml preamble.  Optional args: title, theme."
  (let* ((title (if (and (not (null? args)) (string? (car args)))
                    (car args)
                    #f))
         (theme (if (and (not (null? args)) (not (null? (cdr args)))
                         (string? (cadr args)))
                    (cadr args)
                    "default")))
    (string-append
      "@startuml\n"
      (if title (string-append "title " title "\n") "")
      (string-append "!theme " theme "\n")
      "skinparam componentStyle rectangle\n"
      "skinparam packageStyle rectangle\n"
      "skinparam defaultTextAlignment center\n"
      "\n")))

(define (plantuml-footer)
  "@enduml\n")

;; ── Class-block builder ───────────────────────────────────────────────────────

(define (symbol->class-block sym)
  "Render a HirSymbol as a PlantUML class block with <<block>> stereotype."
  (let* ((name    (hir-symbol/name sym))
         (doc     (hir-symbol/doc sym))
         (rels    (hir-symbol/relationships sym))
         (attrs   (filter (lambda (r) (equal? (hir-rel/kind r) "TypedBy")) rels)))
    (string-append
      "class \"" name "\" <<block>> {\n"
      (if (and doc (not (equal? doc "")))
          (string-append "  ' " (car (string-split doc "\n")) "\n")
          "")
      "}\n")))

(define (composition-line parent-name part-sym)
  "Return PlantUML composition line: parent *-- child : usage-name."
  (string-append
    "\"" parent-name "\" *-- \""
    (hir-symbol/name part-sym) "\" : "
    (hir-symbol/name part-sym) "\n"))

(define (inheritance-line child-sym)
  "Return PlantUML inheritance line for a symbol that specializes another, or #f."
  (let ((supers (hir-symbol/supertypes child-sym)))
    (if (null? supers)
        #f
        (string-append
          "\"" (car supers) "\" <|-- \""
          (hir-symbol/name child-sym) "\"\n"))))

;; ── Block Definition Diagram ──────────────────────────────────────────────────

(define (generate-bdd symbols . opt-args)
  "Generate a PlantUML BDD from a flat list of HirSymbol values.
   opt-args: (hash ...) with keys title, show-attrs, show-ports, theme."
  (let* ((opts       (if (and (not (null? opt-args)) (hash? (car opt-args)))
                         (car opt-args)
                         (hash)))
         (title      (hash-try-get opts "title"))
         (theme      (hash-try-get opts "theme"))
         (def-kinds  '("PartDefinition" "ItemDefinition" "AttributeDefinition"
                       "PortDefinition" "ConnectionDefinition" "ActionDefinition"
                       "StateDefinition" "RequirementDefinition" "EnumerationDefinition"))
         (defs       (filter-kinds symbols def-kinds))
         (usages     (filter-kind symbols "PartUsage"))
         (header     (if title
                         (plantuml-header title (or theme "default"))
                         (plantuml-header)))
         (class-blocks
           (map symbol->class-block defs))
         (inherit-lines
           (filter string?
                   (map inheritance-line defs)))
         (comp-lines
           (apply append
                  (map (lambda (def)
                         (let ((parts (filter
                                        (lambda (u)
                                          (let ((qn (hir-symbol/qualified-name u)))
                                            (string-contains qn
                                              (string-append
                                                (hir-symbol/qualified-name def) "::"))))
                                        usages)))
                           (map (lambda (p) (composition-line (hir-symbol/name def) p))
                                parts)))
                       defs))))
    (string-append
      header
      (string-join class-blocks "")
      "\n"
      (string-join inherit-lines "")
      "\n"
      (string-join comp-lines "")
      (plantuml-footer))))

;; ── Internal Block Diagram ────────────────────────────────────────────────────

(define (generate-ibd parent-sym all-symbols . opt-args)
  "Generate an IBD showing parts inside parent-sym."
  (let* ((opts      (if (and (not (null? opt-args)) (hash? (car opt-args)))
                        (car opt-args)
                        (hash)))
         (title     (hash-try-get opts "title"))
         (direction (or (hash-try-get opts "direction") "left to right direction"))
         (pname     (hir-symbol/name parent-sym))
         (children  (syster/children-of all-symbols parent-sym))
         (parts     (filter-kind children "PartUsage"))
         (ports     (filter-kind children "PortUsage"))
         (conns     (filter-kind children "ConnectionUsage"))
         (header    (if title
                        (plantuml-header title "default")
                        (plantuml-header)))
         (part-lines
           (map (lambda (p)
                  (string-append
                    "  [" (hir-symbol/name p) "]\n"))
                parts))
         (port-lines
           (map (lambda (p)
                  (string-append
                    "  () \"" (hir-symbol/name p) "\"\n"))
                ports))
         (conn-lines
           (map (lambda (c)
                  (let ((rels (hir-symbol/relationships c)))
                    (string-append
                      "  ' connection: " (hir-symbol/name c) "\n")))
                conns)))
    (string-append
      header
      direction "\n\n"
      "package \"" pname "\" {\n"
      (string-join part-lines "")
      (string-join port-lines "")
      (string-join conn-lines "")
      "}\n\n"
      (plantuml-footer))))

;; ── Viewpoints / views diagram ────────────────────────────────────────────────
;;
;; Mirrors the Python write_viewpoints_diagram function.
;; Draws stakeholders, viewpoints, view definitions, and their relationships.

(define (generate-viewpoints-diagram symbols . opt-args)
  "Generate a PlantUML diagram showing viewpoints, view definitions,
   and their relationships.  Mirrors the Python write_viewpoints_diagram."
  (let* ((opts      (if (and (not (null? opt-args)) (hash? (car opt-args)))
                        (car opt-args)
                        (hash)))
         (title     (or (hash-try-get opts "title") "Viewpoints and View Definitions"))
         (vp-defs   (filter-kind symbols "ViewpointDefinition"))
         (vd-defs   (filter-kind symbols "ViewDefinition"))
         (vp-usages (filter-kind symbols "ViewpointUsage"))
         (vd-usages (filter-kind symbols "ViewUsage"))
         (rd-defs   (filter-kind symbols "RenderingDefinition")))

    (define (vp-block vps)
      (if (null? vps)
          ""
          (string-append
            "package \"Viewpoints\" {\n"
            (string-join
              (map (lambda (vp)
                     (string-append
                       "  hexagon \""
                       (hir-symbol/name vp) "\" as "
                       (pu-alias (hir-symbol/name vp)) "\n"))
                   vps)
              "")
            "}\n\n")))

    (define (vd-block vds)
      (if (null? vds)
          ""
          (string-append
            "package \"View Definitions\" {\n"
            (string-join
              (map (lambda (vd)
                     (string-append
                       "  rectangle \""
                       (hir-symbol/name vd) "\" as "
                       (pu-alias (hir-symbol/name vd)) "\n"))
                   vds)
              "")
            "}\n\n")))

    (define (rd-block rds)
      (if (null? rds)
          ""
          (string-append
            "package \"Renderings\" {\n"
            (string-join
              (map (lambda (rd)
                     (string-append
                       "  file \""
                       (hir-symbol/name rd) "\" as "
                       (pu-alias (hir-symbol/name rd)) "\n"))
                   rds)
              "")
            "}\n\n")))

    (define (view-usage-block vus)
      (if (null? vus)
          ""
          (string-append
            "package \"Views\" {\n"
            (string-join
              (map (lambda (vu)
                     (string-append
                       "  rectangle \""
                       (hir-symbol/name vu) "\" as "
                       (pu-alias (hir-symbol/name vu)) "\n"))
                   vus)
              "")
            "}\n\n")))

    (define (specialization-lines syms)
      (apply string-append
             (filter-map
               (lambda (s)
                 (let ((supers (hir-symbol/supertypes s)))
                   (if (null? supers)
                       #f
                       (string-append
                         (pu-alias (hir-symbol/name s)) " ..|> "
                         (pu-alias (car supers)) " : instantiates\n"))))
               syms)))

    (define (satisfaction-lines vds all-syms)
      (apply string-append
             (filter-map
               (lambda (vd)
                 (let* ((expose  (hir-symbol/view-expose vd))
                        (render  (hir-symbol/view-rendering vd))
                        (vd-name (hir-symbol/name vd))
                        (render-line
                          (if render
                              (string-append
                                (pu-alias vd-name) " ..> "
                                (pu-alias render) " : renders with\n")
                              "")))
                   (string-append
                     render-line)))
               vds)))

    (string-append
      (plantuml-header title "default")
      "left to right direction\n\n"
      (vp-block vp-defs)
      (vd-block vd-defs)
      (rd-block rd-defs)
      (view-usage-block vd-usages)
      "' --- relationships ---\n"
      (specialization-lines vd-usages)
      (satisfaction-lines vd-defs symbols)
      "\n"
      (plantuml-footer))))

;; ── Package diagram ───────────────────────────────────────────────────────────

(define (generate-package-diagram symbols . opt-args)
  "Generate a package diagram showing packages and their contents."
  (let* ((opts     (if (and (not (null? opt-args)) (hash? (car opt-args)))
                       (car opt-args)
                       (hash)))
         (title    (or (hash-try-get opts "title") "Package Diagram"))
         (packages (filter-kind symbols "Package")))
    (string-append
      (plantuml-header title "default")
      (string-join
        (map (lambda (pkg)
               (let ((children (syster/children-of symbols pkg)))
                 (string-append
                   "package \"" (hir-symbol/name pkg) "\" {\n"
                   (string-join
                     (map (lambda (c)
                            (string-append
                              "  [" (hir-symbol/name c) "]\n"))
                          children)
                     "")
                   "}\n")))
             packages)
        "\n")
      "\n"
      (plantuml-footer))))

;; ── State machine diagram ─────────────────────────────────────────────────────

(define (generate-state-machine sym all-symbols . opt-args)
  "Generate a PlantUML state machine diagram for a StateDefinition symbol."
  (let* ((opts     (if (and (not (null? opt-args)) (hash? (car opt-args)))
                       (car opt-args)
                       (hash)))
         (title    (or (hash-try-get opts "title")
                       (string-append (hir-symbol/name sym) " State Machine")))
         (children (syster/children-of all-symbols sym))
         (states   (filter-kind children "StateUsage"))
         (trans    (filter-kind children "TransitionUsage")))
    (string-append
      (plantuml-header title "default")
      "[*] --> " (if (null? states) "End" (hir-symbol/name (car states))) "\n\n"
      (string-join
        (map (lambda (s)
               (string-append
                 "state \"" (hir-symbol/name s) "\" as "
                 (pu-alias (hir-symbol/name s)) "\n"))
             states)
        "")
      "\n"
      (string-join
        (map (lambda (t)
               (let ((rels (hir-symbol/relationships t)))
                 (let ((src-rel (find (lambda (r) (equal? (hir-rel/kind r) "References"))
                                      rels))
                       (tgt-rel (find (lambda (r) (equal? (hir-rel/kind r) "TypedBy"))
                                      rels)))
                   (if (and src-rel tgt-rel)
                       (string-append
                         (pu-alias (hir-rel/target src-rel)) " --> "
                         (pu-alias (hir-rel/target tgt-rel)) " : "
                         (hir-symbol/name t) "\n")
                       ""))))
             trans)
        "")
      "\n"
      (plantuml-footer))))

;; ── File output ───────────────────────────────────────────────────────────────

(define (write-plantuml-file text path)
  "Write PlantUML source text to path, creating or overwriting the file."
  (let ((port (open-output-file path)))
    (display text port)
    (close-output-port port)))

;; ── Rendering ─────────────────────────────────────────────────────────────────

(define (render-diagram puml-path format)
  "Invoke plantuml to render puml-path.
   format is a string: svg, png, pdf, or txt."
  (define cmd (string-append "plantuml -t" format " " puml-path))
  (system cmd))

(define (render-diagram-to puml-path format output-dir)
  "Render puml-path and place output in output-dir."
  (define cmd (string-append
                "plantuml -t" format
                " -o " output-dir
                " " puml-path))
  (system cmd))

(define (render-and-open puml-path format)
  "Render the diagram and open the result in the system default viewer."
  (render-diagram puml-path format)
  (let* ((base  (string-append (substring puml-path 0
                                 (- (string-length puml-path) 5))
                               "." format))
         (cmd   (string-append "xdg-open " base)))
    (system cmd)))

;; ── Internal helpers ──────────────────────────────────────────────────────────

(define (hash-try-get h key)
  "Return (hash-ref h key) or #f if key is absent."
  (if (hash-contains? h key)
      (hash-ref h key)
      #f))

(define (string-contains s sub)
  "Return #t if s contains sub as a substring."
  (let loop ((i 0))
    (cond
      ((> (+ i (string-length sub)) (string-length s)) #f)
      ((equal? (substring s i (+ i (string-length sub))) sub) #t)
      (else (loop (+ i 1))))))

(define (filter-map f lst)
  "Apply f to each element; collect non-#f results."
  (filter (lambda (x) (not (equal? x #f)))
          (map f lst)))

(define (find pred lst)
  "Return first element of lst satisfying pred, or #f."
  (cond
    ((null? lst) #f)
    ((pred (car lst)) (car lst))
    (else (find pred (cdr lst)))))
