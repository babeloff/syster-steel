;; dot.scm — DOT-format graph generation for layout-rs rendering
;;
;; Generates DOT digraph strings from SysML HIR symbols.
;; SVG is produced via (layout/render-dot dot-string svg-path), which is
;; registered by src/layout.rs using the layout-rs crate (Sugiyama
;; hierarchical layout, no external process required).
;;
;; Load with:
;;   (require "dot.scm")   ; with -L steel on the load path
;;
;; Each generator accepts an optional opts hash with key "title".

(provide
  render-dot-file
  generate-bdd-dot
  generate-ibd-dot
  generate-state-machine-dot
  generate-action-flow-dot
  generate-requirement-dot
  generate-use-case-dot
  generate-package-dot
  generate-viewpoints-dot)

(require "sysml-util.scm")

;; ── DOT string primitives ─────────────────────────────────────────────────────

(define (dot-quote s)
  (string-append "\"" s "\""))

(define (dot-attrs pairs)
  "Format an assoc list as [ key=\"val\" ... ] or empty string."
  (if (null? pairs)
      ""
      (string-append " ["
        (apply string-append
          (map (lambda (p)
                 (string-append (car p) "=" (dot-quote (cdr p)) " "))
               pairs))
        "]")))

(define (dot-node id attrs)
  (string-append "  " (dot-quote id) (dot-attrs attrs) "\n"))

(define (dot-edge from to attrs)
  (string-append "  " (dot-quote from) " -> " (dot-quote to) (dot-attrs attrs) "\n"))

(define (dot-graph rankdir title body)
  (string-append
    "digraph {\n"
    "  rankdir=" rankdir "\n"
    (if title
        (string-append "  labelloc=t\n  label=" (dot-quote title) "\n")
        "")
    "  node [fontname=\"Helvetica\" fontsize=10]\n"
    "  edge [fontname=\"Helvetica\" fontsize=9]\n"
    body
    "}\n"))

;; ── Render helper ─────────────────────────────────────────────────────────────

(define (render-dot-file dot-string svg-path)
  "Render a DOT string to SVG via layout-rs and write to svg-path."
  (displayln (string-append "  rendering " svg-path))
  (layout/render-dot dot-string svg-path))

;; ── BDD ────────────────────────────────────────────────────────────────────────

(define (generate-bdd-dot symbols . opt-args)
  "Generate a DOT BDD from a flat list of HirSymbol values."
  (let* ([opts      (if (and (not (null? opt-args)) (hash? (car opt-args)))
                        (car opt-args) (hash))]
         [title     (hash-try-get opts "title")]
         [def-kinds '("PartDefinition" "ItemDefinition" "AttributeDefinition"
                      "PortDefinition" "ConnectionDefinition" "ActionDefinition"
                      "StateDefinition" "RequirementDefinition"
                      "EnumerationDefinition")]
         [defs      (filter user-visible? (filter-kinds symbols def-kinds))]
         [nodes
           (apply string-append
             (map (lambda (def)
                    (dot-node (hir-symbol/name def)
                              `(("shape"     . "box")
                                ("style"     . ,(if (hir-symbol/is-abstract? def)
                                                    "dashed" "filled"))
                                ("fillcolor" . "lightyellow"))))
                  defs))]
         [edges
           (apply string-append
             (filter-map
               (lambda (def)
                 (let ([supers (filter
                                 (lambda (s)
                                   (not (string=? s "Requirements::RequirementCheck")))
                                 (hir-symbol/supertypes def))])
                   (if (null? supers)
                       #f
                       (dot-edge (car supers) (hir-symbol/name def)
                                 '(("arrowhead" . "open"))))))
               defs))])
    (dot-graph "TB" title (string-append nodes edges))))

;; ── IBD ────────────────────────────────────────────────────────────────────────

(define (generate-ibd-dot root-sym symbols . opt-args)
  "Generate a DOT IBD showing parts and ports of root-sym."
  (let* ([opts     (if (and (not (null? opt-args)) (hash? (car opt-args)))
                       (car opt-args) (hash))]
         [title    (hash-try-get opts "title")]
         [root-name (hir-symbol/name root-sym)]
         [children  (syster/children-of symbols root-sym)]
         [parts     (filter user-visible?
                            (filter-kinds children '("PartUsage" "ItemUsage")))]
         [ports     (filter user-visible?
                            (filter-kind children "PortUsage"))]
         [part-nodes
           (apply string-append
             (map (lambda (p)
                    (dot-node (hir-symbol/name p)
                              '(("shape" . "box3d") ("style" . "filled")
                                ("fillcolor" . "lightblue"))))
                  parts))]
         [port-nodes
           (apply string-append
             (map (lambda (p)
                    (dot-node (hir-symbol/name p)
                              '(("shape" . "circle") ("width" . "0.3") ("label" . ""))))
                  ports))])
    (dot-graph "LR" title
      (string-append
        "  subgraph cluster_root {\n"
        "    label=" (dot-quote root-name) "\n"
        "    style=filled\n    fillcolor=lightgrey\n"
        part-nodes port-nodes
        "  }\n"))))

;; ── State machine ──────────────────────────────────────────────────────────────

(define (generate-state-machine-dot root-sym symbols . opt-args)
  "Generate a DOT state machine from a StateDefinition symbol."
  (let* ([opts       (if (and (not (null? opt-args)) (hash? (car opt-args)))
                         (car opt-args) (hash))]
         [title      (hash-try-get opts "title")]
         [children   (syster/children-of symbols root-sym)]
         [states     (filter user-visible? (filter-kind children "StateUsage"))]
         [names      (map hir-symbol/name states)]
         [start-node (dot-node "__start"
                               '(("shape" . "point") ("width" . "0.2") ("label" . "")))]
         [start-edge (if (null? names) ""
                         (dot-edge "__start" (car names) '()))]
         [state-nodes
           (apply string-append
             (map (lambda (s)
                    (dot-node (hir-symbol/name s)
                              '(("shape" . "box") ("style" . "rounded,filled")
                                ("fillcolor" . "lightcyan"))))
                  states))]
         [seq-edges
           (let loop ([ns names] [acc ""])
             (if (or (null? ns) (null? (cdr ns)))
                 acc
                 (loop (cdr ns) (string-append acc
                                  (dot-edge (car ns) (cadr ns) '())))))])
    (dot-graph "LR" title
               (string-append start-node start-edge state-nodes seq-edges))))

;; ── Action flow ────────────────────────────────────────────────────────────────

(define (generate-action-flow-dot root-sym symbols . opt-args)
  "Generate a DOT action flow diagram from an ActionDefinition symbol."
  (let* ([opts    (if (and (not (null? opt-args)) (hash? (car opt-args)))
                      (car opt-args) (hash))]
         [title   (hash-try-get opts "title")]
         [children (syster/children-of symbols root-sym)]
         [actions  (filter user-visible? (filter-kind children "ActionUsage"))]
         [names    (map hir-symbol/name actions)]
         [nodes
           (apply string-append
             (map (lambda (a)
                    (dot-node (hir-symbol/name a)
                              '(("shape" . "box") ("style" . "rounded,filled")
                                ("fillcolor" . "lightblue"))))
                  actions))]
         [edges
           (let loop ([ns names] [acc ""])
             (if (or (null? ns) (null? (cdr ns)))
                 acc
                 (loop (cdr ns) (string-append acc
                                  (dot-edge (car ns) (cadr ns) '())))))])
    (dot-graph "TB" title (string-append nodes edges))))

;; ── Requirements ──────────────────────────────────────────────────────────────

(define *stdlib-req* "Requirements::RequirementCheck")

(define (generate-requirement-dot symbols . opt-args)
  "Generate a DOT requirements diagram."
  (let* ([opts     (if (and (not (null? opt-args)) (hash? (car opt-args)))
                       (car opt-args) (hash))]
         [title    (hash-try-get opts "title")]
         [req-defs (filter user-visible? (filter-kind symbols "RequirementDefinition"))]
         [nodes
           (apply string-append
             (map (lambda (r)
                    (dot-node (hir-symbol/name r)
                              '(("shape" . "box") ("style" . "filled")
                                ("fillcolor" . "lightyellow"))))
                  req-defs))]
         [edges
           (apply string-append
             (filter-map
               (lambda (r)
                 (let ([supers (filter
                                 (lambda (s) (not (string=? s *stdlib-req*)))
                                 (hir-symbol/supertypes r))])
                   (if (null? supers)
                       #f
                       (dot-edge (car supers) (hir-symbol/name r)
                                 '(("style" . "dashed") ("arrowhead" . "open"))))))
               req-defs))])
    (dot-graph "TB" title (string-append nodes edges))))

;; ── Use case ──────────────────────────────────────────────────────────────────

(define (generate-use-case-dot symbols . opt-args)
  "Generate a DOT use-case diagram."
  (let* ([opts      (if (and (not (null? opt-args)) (hash? (car opt-args)))
                        (car opt-args) (hash))]
         [title     (hash-try-get opts "title")]
         [use-cases (filter user-visible?
                            (filter-kinds symbols '("UseCaseDefinition" "UseCaseUsage")))]
         [actors    (filter user-visible?
                            (filter-kinds symbols '("PartDefinition" "ItemDefinition")))]
         [uc-nodes
           (apply string-append
             (map (lambda (u) (dot-node (hir-symbol/name u) '(("shape" . "ellipse"))))
                  use-cases))]
         [actor-nodes
           (apply string-append
             (map (lambda (a)
                    (dot-node (hir-symbol/name a)
                              '(("shape" . "box") ("style" . "filled")
                                ("fillcolor" . "lightblue"))))
                  actors))])
    (dot-graph "LR" title (string-append actor-nodes uc-nodes))))

;; ── Package ───────────────────────────────────────────────────────────────────

(define (generate-package-dot symbols . opt-args)
  "Generate a DOT package diagram."
  (let* ([opts     (if (and (not (null? opt-args)) (hash? (car opt-args)))
                       (car opt-args) (hash))]
         [title    (hash-try-get opts "title")]
         [packages (filter user-visible? (filter-kind symbols "PackageMember"))]
         [nodes
           (apply string-append
             (map (lambda (p)
                    (dot-node (hir-symbol/name p) '(("shape" . "folder"))))
                  packages))])
    (dot-graph "TB" title nodes)))

;; ── Viewpoints ────────────────────────────────────────────────────────────────

(define (generate-viewpoints-dot symbols . opt-args)
  "Generate a DOT viewpoints and views diagram."
  (let* ([opts   (if (and (not (null? opt-args)) (hash? (car opt-args)))
                     (car opt-args) (hash))]
         [title  (hash-try-get opts "title")]
         [vps    (filter user-visible? (filter-kind symbols "ViewpointDefinition"))]
         [views  (filter user-visible? (filter-kind symbols "ViewDefinition"))]
         [vp-nodes
           (apply string-append
             (map (lambda (v)
                    (dot-node (hir-symbol/name v)
                              '(("shape" . "box") ("style" . "filled")
                                ("fillcolor" . "lightsteelblue"))))
                  vps))]
         [view-nodes
           (apply string-append
             (map (lambda (v) (dot-node (hir-symbol/name v) '(("shape" . "box"))))
                  views))]
         [conform-edges
           (apply string-append
             (filter-map
               (lambda (v)
                 (let ([supers (hir-symbol/supertypes v)])
                   (if (null? supers)
                       #f
                       (dot-edge (hir-symbol/name v) (car supers)
                                 '(("label" . "conform") ("style" . "dashed")
                                   ("arrowhead" . "open"))))))
               views))])
    (dot-graph "TB" title
               (string-append vp-nodes view-nodes conform-edges))))
