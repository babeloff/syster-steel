;; plantuml.scm — PlantUML diagram generation via Handlebars templates
;;
;; All generators are defined inline so that closures only reference names
;; within this module's own scope — Steel closures store name references,
;; not captured values, so cross-module captures do not work.
;;
;; Sub-library files (plantuml-action.scm etc.) exist for standalone use
;; with an explicit hbs registry parameter; do not require them here.
;;
;; Load with:
;;   (require "plantuml.scm")         ; if steel/ is on the load path (-L steel)
;;   (require "steel/plantuml.scm") ; from project root
;;
;; Override the templates directory before the first require:
;;   (define *templates-dir* "path/to/templates")

(provide
  ;; Configuration
  *hbs*
  *templates-dir*

  ;; PlantUML identifier helpers
  pu-alias
  pu-safe-char?
  user-visible?

  ;; Symbol/relationship utilities (re-exported from sysml-util.scm)
  filter-kind
  filter-kinds
  filter-map
  find-syster-by-name
  find-rel
  find-rels
  rel-targets
  hash-try-get

  ;; Structural diagram generators
  generate-bdd
  generate-ibd
  generate-package-diagram
  generate-viewpoints-diagram

  ;; Behavioral diagram generators
  generate-state-machine
  generate-action-flow
  generate-action-flow-all

  ;; Requirement diagram generators
  generate-requirement-diagram
  generate-requirement-diagram-scoped

  ;; Interaction diagram generators
  generate-sequence-diagram
  generate-use-case-diagram

  ;; File output and rendering
  write-plantuml-file
  render-diagram
  render-diagram-to
  render-and-open)

(require "sysml-util.scm")

;; ── Template registry ─────────────────────────────────────────────────────────

(define *templates-dir* "steel/templates")

(define *hbs* (hbs/new))

(define (hbs-init! dir)
  (for-each
    (lambda (pair)
      (let ([name (car pair)]
            [file (string-append dir "/" (cadr pair))])
        (hbs/register-template-file! *hbs* name file)))
    (list (list "bdd"           "bdd.hbs")
          (list "ibd"           "ibd.hbs")
          (list "state-machine" "state-machine.hbs")
          (list "package"       "package.hbs")
          (list "viewpoints"    "viewpoints.hbs")
          (list "action-flow"   "action-flow.hbs")
          (list "requirement"   "requirement.hbs")
          (list "sequence"      "sequence.hbs")
          (list "use-case"      "use-case.hbs")
          (list "allocation"    "allocation.hbs"))))

(hbs-init! *templates-dir*)

;; ── Utilities ─────────────────────────────────────────────────────────────────

(define (pu-safe-char? c)
  (let ([n (char->integer c)])
    (or (and (>= n 65) (<= n 90))    ; A-Z
        (and (>= n 97) (<= n 122))   ; a-z
        (and (>= n 48) (<= n 57))    ; 0-9
        (= n 95))))                  ; _

(define (user-visible? sym)
  (let ([name (hir-symbol/name sym)])
    (or (= (string-length name) 0)
        (not (char=? (string-ref name 0) #\<)))))

(define (pu-alias name)
  "Return a PlantUML-safe identifier: replace non-alphanumeric chars with _."
  (list->string
    (map (lambda (c) (if (pu-safe-char? c) c #\_))
         (string->list name))))

(define (filter-kind symbols kind-str)
  (filter (lambda (s) (equal? (hir-symbol/kind s) kind-str)) symbols))

(define (filter-kinds symbols kind-list)
  (filter (lambda (s) (member (hir-symbol/kind s) kind-list)) symbols))

(define (filter-map f lst)
  (filter (lambda (x) (not (equal? x #f))) (map f lst)))

(define (find-rel rels kind)
  (let loop ([rs rels])
    (cond [(null? rs) #f]
          [(string=? (hir-rel/kind (car rs)) kind) (car rs)]
          [else (loop (cdr rs))])))

(define (hash-try-get h key)
  (if (hash-contains? h key) (hash-ref h key) #f))

;; ── Block Definition Diagram ──────────────────────────────────────────────────

(define (generate-bdd symbols . opt-args)
  "Generate a PlantUML BDD from a flat list of HirSymbol values.
   opt-args: (hash ...) with keys title, theme."
  (let* ([opts      (if (and (not (null? opt-args)) (hash? (car opt-args)))
                        (car opt-args)
                        (hash))]
         [title     (hash-try-get opts "title")]
         [theme     (or (hash-try-get opts "theme") "plain")]
         [def-kinds '("PartDefinition" "ItemDefinition" "AttributeDefinition"
                      "PortDefinition" "ConnectionDefinition" "ActionDefinition"
                      "StateDefinition" "RequirementDefinition"
                      "EnumerationDefinition")]
         [defs      (filter-kinds symbols def-kinds)]
         [def-data
           (map (lambda (def)
                  (let* ([children (syster/children-of symbols def)]
                         [attrs    (filter-kind children "AttributeUsage")]
                         [ports    (filter-kind children "PortUsage")])
                    (hash "name"        (hir-symbol/name def)
                          "alias"       (pu-alias (hir-symbol/name def))
                          "is_abstract" (hir-symbol/is-abstract? def)
                          "attrs" (map (lambda (a) (hash "name" (hir-symbol/name a))) attrs)
                          "ports" (map (lambda (p) (hash "name" (hir-symbol/name p))) ports))))
                defs)]
         [inherit-data
           (filter-map
             (lambda (def)
               (let ([supers (hir-symbol/supertypes def)])
                 (if (null? supers)
                     #f
                     (hash "parent"       (car supers)
                           "parent_alias" (pu-alias (car supers))
                           "child"        (hir-symbol/name def)
                           "child_alias"  (pu-alias (hir-symbol/name def))))))
             defs)]
         [comp-data
           (apply append
             (map (lambda (def)
                    (let* ([children (syster/children-of symbols def)]
                           [parts    (filter-kind children "PartUsage")])
                      (filter-map
                        (lambda (p)
                          (let ([typed-by (find-rel (hir-symbol/relationships p) "TypedBy")])
                            (if typed-by
                                (hash "parent"       (hir-symbol/name def)
                                      "parent_alias" (pu-alias (hir-symbol/name def))
                                      "child"        (hir-rel/target typed-by)
                                      "child_alias"  (pu-alias (hir-rel/target typed-by))
                                      "role"         (hir-symbol/name p))
                                #f)))
                        parts)))
                  defs))]
         [data (hash "title"        (or title "")
                     "theme"        theme
                     "definitions"  def-data
                     "inheritances" inherit-data
                     "compositions" comp-data)])
    (hbs/render *hbs* "bdd" data)))

;; ── Internal Block Diagram ────────────────────────────────────────────────────

(define (generate-ibd parent-sym all-symbols . opt-args)
  "Generate an IBD showing parts inside parent-sym."
  (let* ([opts      (if (and (not (null? opt-args)) (hash? (car opt-args)))
                        (car opt-args)
                        (hash))]
         [title     (hash-try-get opts "title")]
         [direction (or (hash-try-get opts "direction") "left to right direction")]
         [pname     (hir-symbol/name parent-sym)]
         [children  (syster/children-of all-symbols parent-sym)]
         [parts     (filter user-visible? (filter-kind children "PartUsage"))]
         [ports     (filter user-visible? (filter-kind children "PortUsage"))]
         [data      (hash "title"     (or title "")
                          "theme"     "plain"
                          "direction" direction
                          "name"      pname
                          "parts" (map (lambda (p) (hash "name"  (hir-symbol/name p)
                                                         "alias" (pu-alias (hir-symbol/name p)))) parts)
                          "ports" (map (lambda (p) (hash "name"  (hir-symbol/name p)
                                                         "alias" (pu-alias (hir-symbol/name p)))) ports))])
    (hbs/render *hbs* "ibd" data)))

;; ── State Machine Diagram ─────────────────────────────────────────────────────

(define (generate-state-machine sym all-symbols . opt-args)
  "Generate a PlantUML state machine diagram for a StateDefinition symbol."
  (let* ([opts      (if (and (not (null? opt-args)) (hash? (car opt-args)))
                        (car opt-args)
                        (hash))]
         [title     (or (hash-try-get opts "title")
                        (string-append (hir-symbol/name sym) " State Machine"))]
         [children  (syster/children-of all-symbols sym)]
         [states    (filter-kind children "StateUsage")]
         [trans     (filter-kind children "TransitionUsage")]
         [initial   (if (null? states) "" (hir-symbol/name (car states)))]
         [state-data
           (map (lambda (s)
                  (hash "name"  (hir-symbol/name s)
                        "alias" (pu-alias (hir-symbol/name s))))
                states)]
         [trans-data
           (filter-map
             (lambda (t)
               (let ([src-rel (find-rel (hir-symbol/relationships t) "References")]
                     [tgt-rel (find-rel (hir-symbol/relationships t) "TypedBy")])
                 (if (and src-rel tgt-rel)
                     (hash "source"       (hir-rel/target src-rel)
                           "source_alias" (pu-alias (hir-rel/target src-rel))
                           "target"       (hir-rel/target tgt-rel)
                           "target_alias" (pu-alias (hir-rel/target tgt-rel))
                           "guard"        (hir-symbol/name t))
                     #f)))
             trans)]
         [data (hash "title"         title
                     "theme"         "plain"
                     "initial_state" initial
                     "states"        state-data
                     "transitions"   trans-data)])
    (hbs/render *hbs* "state-machine" data)))

;; ── Package Diagram ───────────────────────────────────────────────────────────

(define (generate-package-diagram symbols . opt-args)
  "Generate a package diagram showing packages and their contents."
  (let* ([opts     (if (and (not (null? opt-args)) (hash? (car opt-args)))
                       (car opt-args)
                       (hash))]
         [title    (or (hash-try-get opts "title") "Package Diagram")]
         [packages (filter-kind symbols "Package")]
         [pkg-data
           (map (lambda (pkg)
                  (let ([children (syster/children-of symbols pkg)])
                    (hash "name" (hir-symbol/name pkg)
                          "children" (filter-map
                                       (lambda (c)
                                         (if (user-visible? c)
                                             (hash "name" (hir-symbol/name c))
                                             #f))
                                       children))))
                packages)]
         ;; Merge packages that share the same name (one per source file).
         [merged-data
           (let loop ([pkgs pkg-data] [acc '()])
             (if (null? pkgs)
                 (reverse acc)
                 (let* ([pkg  (car pkgs)]
                        [name (hash-ref pkg "name")]
                        [dup  (filter (lambda (p) (equal? (hash-ref p "name") name)) acc)])
                   (if (null? dup)
                       (loop (cdr pkgs) (cons pkg acc))
                       (let* ([existing  (car dup)]
                              [merged    (hash "name" name
                                               "children" (append (hash-ref existing "children")
                                                                   (hash-ref pkg "children")))]
                              [rest      (filter (lambda (p) (not (equal? (hash-ref p "name") name))) acc)])
                         (loop (cdr pkgs) (cons merged rest)))))))]
         [data (hash "title"    title
                     "theme"    "plain"
                     "packages" merged-data)])
    (hbs/render *hbs* "package" data)))

;; ── Viewpoints / View Definitions Diagram ─────────────────────────────────────

(define (generate-viewpoints-diagram symbols . opt-args)
  "Generate a diagram showing viewpoints, view definitions, and relationships."
  (let* ([opts       (if (and (not (null? opt-args)) (hash? (car opt-args)))
                         (car opt-args)
                         (hash))]
         [title      (or (hash-try-get opts "title") "Viewpoints and View Definitions")]
         [vp-defs    (filter-kind symbols "ViewpointDefinition")]
         [vd-defs    (filter-kind symbols "ViewDefinition")]
         [rd-defs    (filter-kind symbols "RenderingDefinition")]
         [vd-usages  (filter-kind symbols "ViewUsage")]
         [to-node    (lambda (s)
                       (hash "name"  (hir-symbol/name s)
                             "alias" (pu-alias (hir-symbol/name s))))]
         [instantiations
           (filter-map
             (lambda (vu)
               (let ([supers (hir-symbol/supertypes vu)])
                 (if (null? supers)
                     #f
                     (hash "child"        (hir-symbol/name vu)
                           "child_alias"  (pu-alias (hir-symbol/name vu))
                           "parent"       (car supers)
                           "parent_alias" (pu-alias (car supers))))))
             vd-usages)]
         [render-edges
           (filter-map
             (lambda (vd)
               (let ([rendering (hir-symbol/view-rendering vd)])
                 (if rendering
                     (hash "view"            (hir-symbol/name vd)
                           "view_alias"      (pu-alias (hir-symbol/name vd))
                           "rendering"       rendering
                           "rendering_alias" (pu-alias rendering))
                     #f)))
             vd-defs)]
         [data (hash "title"            title
                     "theme"            "plain"
                     "viewpoints"       (map to-node vp-defs)
                     "view_definitions" (map to-node vd-defs)
                     "renderings"       (map to-node rd-defs)
                     "view_usages"      (map to-node vd-usages)
                     "instantiations"   instantiations
                     "render_edges"     render-edges)])
    (hbs/render *hbs* "viewpoints" data)))

;; ── Action Flow Diagram ───────────────────────────────────────────────────────

(define (generate-action-flow sym all-symbols . opt-args)
  "Generate a PlantUML action-flow diagram for an ActionDefinition symbol.
   Corresponds to VAction + VActionMembers in the Java pilot."
  (let* ([opts     (if (and (not (null? opt-args)) (hash? (car opt-args)))
                       (car opt-args)
                       (hash))]
         [title    (or (hash-try-get opts "title")
                       (string-append (hir-symbol/name sym) " Action Flow"))]
         [theme    (or (hash-try-get opts "theme") "plain")]
         [children (syster/children-of all-symbols sym)]
         [actions  (filter user-visible?
                           (filter-kinds children
                                         '("ActionUsage" "PerformActionUsage"
                                           "SendActionUsage" "AcceptActionUsage")))]
         [trans    (filter-kind children "TransitionUsage")]
         [initial  (if (null? actions)
                       ""
                       (pu-alias (hir-symbol/name (car actions))))]
         [final    (if (null? actions)
                       #f
                       (let ([last (car (reverse actions))])
                         (hash "name"  (hir-symbol/name last)
                               "alias" (pu-alias (hir-symbol/name last)))))]
         [action-data
           (map (lambda (a)
                  (hash "name"  (hir-symbol/name a)
                        "alias" (pu-alias (hir-symbol/name a))))
                actions)]
         [trans-data
           (filter-map
             (lambda (t)
               (let ([src-rel (find-rel (hir-symbol/relationships t) "References")]
                     [tgt-rel (find-rel (hir-symbol/relationships t) "TypedBy")])
                 (if (and src-rel tgt-rel)
                     (hash "source"       (hir-rel/target src-rel)
                           "source_alias" (pu-alias (hir-rel/target src-rel))
                           "target"       (hir-rel/target tgt-rel)
                           "target_alias" (pu-alias (hir-rel/target tgt-rel))
                           "guard"        (hir-symbol/name t))
                     #f)))
             trans)]
         [data (hash "title"              title
                     "theme"              theme
                     "initial_action"     initial
                     "final_action"       (if final (hash-ref final "name") #f)
                     "final_action_alias" (if final (hash-ref final "alias") #f)
                     "actions"            action-data
                     "transitions"        trans-data)])
    (hbs/render *hbs* "action-flow" data)))

(define (generate-action-flow-all symbols . opt-args)
  "Generate action flow diagrams for every ActionDefinition in symbols.
   Returns a list of (name . puml-string) pairs."
  (let ([action-defs (filter-kinds symbols '("ActionDefinition"))])
    (filter-map
      (lambda (def)
        (let ([children (syster/children-of symbols def)])
          (if (null? (filter-kinds children '("ActionUsage" "PerformActionUsage")))
              #f
              (cons (hir-symbol/name def)
                    (apply generate-action-flow def symbols opt-args)))))
      action-defs)))

;; ── Requirement Diagram ───────────────────────────────────────────────────────

(define *req-def-kinds*
  '("RequirementDefinition" "SatisfactionRequirementDefinition"
    "VerificationCaseDefinition"))

(define *req-usage-kinds*
  '("RequirementUsage" "SatisfactionRequirementUsage"))

(define (req-stereotype sym)
  (if (member (hir-symbol/kind sym) *req-def-kinds*) "requirementDef" "requirement"))

(define (generate-requirement-diagram symbols . opt-args)
  "Generate a PlantUML requirement diagram.
   Corresponds to VRequirement + VCompartment in the Java pilot."
  (let* ([opts      (if (and (not (null? opt-args)) (hash? (car opt-args)))
                        (car opt-args)
                        (hash))]
         [title     (or (hash-try-get opts "title") "Requirement Diagram")]
         [theme     (or (hash-try-get opts "theme") "plain")]
         [req-syms  (filter user-visible?
                            (filter-kinds symbols
                                          (append *req-def-kinds* *req-usage-kinds*)))]
         [req-data  (map (lambda (sym)
                           (hash "name"       (hir-symbol/name sym)
                                 "alias"      (pu-alias (hir-symbol/name sym))
                                 "stereotype" (req-stereotype sym)))
                         req-syms)]
         [contain-data
           (filter-map
             (lambda (sym)
               (let ([supers (hir-symbol/supertypes sym)])
                 (if (null? supers)
                     #f
                     (hash "parent_alias" (pu-alias (car supers))
                           "child_alias"  (pu-alias (hir-symbol/name sym))))))
             req-syms)]
         [derive-data
           (apply append
             (map (lambda (sym)
                    (map (lambda (tgt)
                           (hash "source_alias" (pu-alias (hir-symbol/name sym))
                                 "target_alias" (pu-alias tgt)))
                         (rel-targets sym "DeriveReqt")))
                  req-syms))]
         [satisfy-data
           (apply append
             (map (lambda (sym)
                    (map (lambda (tgt)
                           (hash "satisfier_alias"   (pu-alias (hir-symbol/name sym))
                                 "requirement_alias" (pu-alias tgt)))
                         (rel-targets sym "Satisfy")))
                  req-syms))]
         [refine-data
           (apply append
             (map (lambda (sym)
                    (map (lambda (tgt)
                           (hash "source_alias" (pu-alias (hir-symbol/name sym))
                                 "target_alias" (pu-alias tgt)))
                         (rel-targets sym "Refine")))
                  req-syms))]
         [data (hash "title"         title
                     "theme"         theme
                     "requirements"  req-data
                     "contain_edges" contain-data
                     "derive_edges"  derive-data
                     "satisfy_edges" satisfy-data
                     "refine_edges"  refine-data)])
    (hbs/render *hbs* "requirement" data)))

(define (generate-requirement-diagram-scoped sym all-symbols . opt-args)
  "Generate a requirement diagram scoped to the children of sym."
  (let ([children (filter user-visible?
                          (filter-kinds (syster/children-of all-symbols sym)
                                        (append *req-def-kinds* *req-usage-kinds*)))])
    (apply generate-requirement-diagram children opt-args)))

;; ── Sequence Diagram ──────────────────────────────────────────────────────────

(define (generate-sequence-diagram sym all-symbols . opt-args)
  "Generate a PlantUML sequence diagram for an interaction context sym.
   Corresponds to VSequence in the Java pilot (simplified, declaration order)."
  (let* ([opts      (if (and (not (null? opt-args)) (hash? (car opt-args)))
                        (car opt-args)
                        (hash))]
         [title     (or (hash-try-get opts "title")
                        (string-append (hir-symbol/name sym) " Sequence"))]
         [theme     (or (hash-try-get opts "theme") "plain")]
         [children  (syster/children-of all-symbols sym)]
         [participants (filter user-visible?
                               (filter-kinds children
                                             '("PartUsage" "ItemUsage" "OccurrenceUsage")))]
         [connections  (filter user-visible?
                               (filter-kinds children
                                             '("ConnectionUsage" "FlowUsage" "MessageUsage")))]
         [part-data
           (map (lambda (p)
                  (hash "name"  (hir-symbol/name p)
                        "alias" (pu-alias (hir-symbol/name p))))
                participants)]
         [msg-data
           (filter-map
             (lambda (conn)
               (let* ([ends      (syster/children-of all-symbols conn)]
                      [end-names (map hir-symbol/name (filter user-visible? ends))]
                      [n         (length end-names)])
                 (if (>= n 2)
                     (hash "name"         (hir-symbol/name conn)
                           "source_alias" (pu-alias (car end-names))
                           "target_alias" (pu-alias (cadr end-names)))
                     #f)))
             connections)]
         [data (hash "title"        title
                     "theme"        theme
                     "participants" part-data
                     "messages"     msg-data)])
    (hbs/render *hbs* "sequence" data)))

;; ── Use Case Diagram ──────────────────────────────────────────────────────────

(define *uc-kinds*
  '("UseCaseDefinition" "UseCaseUsage" "CaseDefinition" "CaseUsage"))

(define *actor-kinds*
  '("ActorUsage" "ActorDefinition"))

(define (generate-use-case-diagram symbols . opt-args)
  "Generate a PlantUML use case diagram.
   Corresponds to VCase + VCaseMembers in the Java pilot."
  (let* ([opts        (if (and (not (null? opt-args)) (hash? (car opt-args)))
                          (car opt-args)
                          (hash))]
         [title       (or (hash-try-get opts "title") "Use Case Diagram")]
         [theme       (or (hash-try-get opts "theme") "plain")]
         [system-name (or (hash-try-get opts "system_name") "System")]
         [uc-syms     (filter user-visible? (filter-kinds symbols *uc-kinds*))]
         [actor-syms  (filter user-visible? (filter-kinds symbols *actor-kinds*))]
         [uc-data     (map (lambda (uc)
                             (hash "name"  (hir-symbol/name uc)
                                   "alias" (pu-alias (hir-symbol/name uc))))
                           uc-syms)]
         [actor-data  (map (lambda (a)
                             (hash "name"  (hir-symbol/name a)
                                   "alias" (pu-alias (hir-symbol/name a))))
                           actor-syms)]
         [uc-names    (map hir-symbol/name uc-syms)]
         [actor-edges
           (apply append
             (map (lambda (actor)
                    (filter-map
                      (lambda (tgt)
                        (if (member tgt uc-names)
                            (hash "actor_alias"    (pu-alias (hir-symbol/name actor))
                                  "use_case_alias" (pu-alias tgt))
                            #f))
                      (rel-targets actor "References")))
                  actor-syms))]
         [include-edges
           (filter-map
             (lambda (uc)
               (let ([supers (hir-symbol/supertypes uc)])
                 (if (null? supers)
                     #f
                     (hash "source_alias" (pu-alias (hir-symbol/name uc))
                           "target_alias" (pu-alias (car supers))))))
             uc-syms)]
         [data (hash "title"         title
                     "theme"         theme
                     "system_name"   system-name
                     "actors"        actor-data
                     "use_cases"     uc-data
                     "actor_edges"   actor-edges
                     "include_edges" include-edges
                     "extend_edges"  '())])
    (hbs/render *hbs* "use-case" data)))

;; ── File output ───────────────────────────────────────────────────────────────

(define (write-plantuml-file text path)
  "Write PlantUML source text to path, creating or overwriting the file."
  (let ([port (open-output-file path)])
    (display text port)
    (close-output-port port)))

;; ── Rendering ─────────────────────────────────────────────────────────────────

(define *plantuml-env* "JAVA_TOOL_OPTIONS=-Djava.awt.headless=true")

(define (render-diagram puml-path format)
  "Invoke plantuml to render puml-path.  format: svg | png | pdf | txt."
  (system (string-append *plantuml-env* " plantuml -t" format " " puml-path)))

(define (render-diagram-to puml-path format output-dir)
  "Render puml-path and write output to output-dir."
  (system (string-append *plantuml-env* " plantuml -t" format " -o " output-dir " " puml-path)))

(define (render-and-open puml-path format)
  "Render the diagram and open the result with xdg-open."
  (render-diagram puml-path format)
  (let* ([base (substring puml-path 0 (- (string-length puml-path) 5))]
         [out  (string-append base "." format)])
    (system (string-append "xdg-open " out))))
