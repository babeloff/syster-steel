;; plantuml.scm — PlantUML diagram generation via Handlebars templates
;;
;; Load with:
;;   (require "plantuml")            ; if script/ is on the load path (-L script)
;;   (require "script/plantuml.scm") ; from project root
;;
;; Templates are loaded from *templates-dir* (default: "script/templates/") relative
;; to the process working directory.  Override before the first require:
;;   (define *templates-dir* "path/to/templates")

(provide
  ;; Configuration
  *hbs*
  *templates-dir*

  ;; PlantUML identifier helpers
  pu-alias

  ;; Diagram generators (return PlantUML source strings)
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

(require-builtin steel/filesystem)

;; ── Template registry ─────────────────────────────────────────────────────────

(define *templates-dir* "script/templates")

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
          (list "viewpoints"    "viewpoints.hbs"))))

(hbs-init! *templates-dir*)

;; ── Utilities ─────────────────────────────────────────────────────────────────

(define (pu-alias name)
  "Return a PlantUML-safe identifier: replace non-alphanumeric chars with _."
  (list->string
    (map (lambda (c)
           (if (or (char-alphabetic? c) (char-numeric? c) (char=? c #\_))
               c
               #\_))
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
         [theme     (or (hash-try-get opts "theme") "default")]
         [def-kinds '("PartDefinition" "ItemDefinition" "AttributeDefinition"
                      "PortDefinition" "ConnectionDefinition" "ActionDefinition"
                      "StateDefinition" "RequirementDefinition"
                      "EnumerationDefinition")]
         [defs      (filter-kinds symbols def-kinds)]
         ;; per-definition data: name, alias, is_abstract, attrs, ports
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
         ;; inheritance: supertypes → child
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
         ;; composition: PartUsage children typed by another def
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
         [parts     (filter-kind children "PartUsage")]
         [ports     (filter-kind children "PortUsage")]
         [data      (hash "title"     (or title "")
                          "theme"     "default"
                          "direction" direction
                          "name"      pname
                          "parts" (map (lambda (p) (hash "name" (hir-symbol/name p))) parts)
                          "ports" (map (lambda (p) (hash "name" (hir-symbol/name p))) ports))])
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
                     "theme"         "default"
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
                          "children" (map (lambda (c) (hash "name" (hir-symbol/name c)))
                                         children))))
                packages)]
         [data (hash "title"    title
                     "theme"    "default"
                     "packages" pkg-data)])
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
                     "theme"            "default"
                     "viewpoints"       (map to-node vp-defs)
                     "view_definitions" (map to-node vd-defs)
                     "renderings"       (map to-node rd-defs)
                     "view_usages"      (map to-node vd-usages)
                     "instantiations"   instantiations
                     "render_edges"     render-edges)])
    (hbs/render *hbs* "viewpoints" data)))

;; ── File output ───────────────────────────────────────────────────────────────

(define (write-plantuml-file text path)
  "Write PlantUML source text to path, creating or overwriting the file."
  (let ([port (open-output-file path)])
    (display text port)
    (close-output-port port)))

;; ── Rendering ─────────────────────────────────────────────────────────────────

(define (render-diagram puml-path format)
  "Invoke plantuml to render puml-path.  format: svg | png | pdf | txt."
  (system (string-append "plantuml -t" format " " puml-path)))

(define (render-diagram-to puml-path format output-dir)
  "Render puml-path and write output to output-dir."
  (system (string-append "plantuml -t" format " -o " output-dir " " puml-path)))

(define (render-and-open puml-path format)
  "Render the diagram and open the result with xdg-open."
  (render-diagram puml-path format)
  (let* ([base (substring puml-path 0 (- (string-length puml-path) 5))]
         [out  (string-append base "." format)])
    (system (string-append "xdg-open " out))))
