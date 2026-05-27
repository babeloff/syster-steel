;; gen-self-diagrams.scm — Generate diagrams from data/self/ SysML models
;;
;; Produces .puml files (via Handlebars templates) and .svg files (via
;; layout-rs DOT rendering) from the syster-steel self-documenting model.
;;
;; Usage (from project root):
;;   syster-steel -L steel steel/gen-self-diagrams.scm
;;
;; Override directories:
;;   syster-steel -L steel \
;;     -e '(define *self-data-dir* "data/self")' \
;;     -e '(define *self-out-dir*  "wisdom/diagrams-gen")' \
;;     steel/gen-self-diagrams.scm

(require "plantuml.scm")
(require "dot.scm")
(require-builtin steel/filesystem)

;; ── Configuration ─────────────────────────────────────────────────────────────

(define *self-data-dir* "data/self")
(define *self-out-dir*  "wisdom/diagrams-gen")

;; ── Helpers ───────────────────────────────────────────────────────────────────

(define (ensure-dir path)
  (unless (path-exists? path)
    (create-directory! path)))

(define (out-path name)
  (string-append *self-out-dir* "/" name))

(define (write-puml text filename)
  (let ([path (out-path filename)])
    (displayln (string-append "  writing " path))
    (write-plantuml-file text path)))

(define (write-svg dot-text svg-name)
  (render-dot-file dot-text (out-path svg-name)))

;; ── Load model ────────────────────────────────────────────────────────────────

(define (load-self-symbols dir)
  (let* ([files (glob-list (string-append dir "/*.sysml"))])
    (displayln (string-append "  found " (number->string (length files)) " files"))
    (apply append
      (map (lambda (f)
             (displayln (string-append "    parsing " f))
             (syster/file-symbols (syster/parse-file f)))
           files))))

(displayln (string-append "Loading self-documenting model: " *self-data-dir*))
(define symbols (load-self-symbols *self-data-dir*))
(displayln (string-append "  loaded " (number->string (length symbols)) " symbols"))

(ensure-dir *self-out-dir*)
(displayln (string-append "Writing diagrams to " *self-out-dir* "/"))
(displayln "")

;; ── Diagram 1: Block Definition Diagram — full system structure ───────────────

(let ([opts (hash "title" "syster-steel — Block Definition Diagram" "theme" "plain")])
  (write-puml (generate-bdd symbols opts) "system-bdd.puml")
  (write-svg  (generate-bdd-dot symbols opts) "system-bdd.svg"))

;; ── Diagram 2: SysterSteelTool IBD ───────────────────────────────────────────

(define tool-sym (syster/find-by-name symbols "SysterSteelTool"))
(when tool-sym
  (let ([opts (hash "title" "SysterSteelTool — Internal Block Diagram")])
    (write-puml (generate-ibd tool-sym symbols opts) "tool-ibd.puml")
    (write-svg  (generate-ibd-dot tool-sym symbols opts) "tool-ibd.svg")))

;; ── Diagram 3: RustEngine IBD ─────────────────────────────────────────────────

(define engine-sym (syster/find-by-name symbols "RustEngine"))
(when engine-sym
  (let ([opts (hash "title" "RustEngine — Internal Block Diagram")])
    (write-puml (generate-ibd engine-sym symbols opts) "engine-ibd.puml")
    (write-svg  (generate-ibd-dot engine-sym symbols opts) "engine-ibd.svg")))

;; ── Diagram 4: SchemeLibrary IBD ──────────────────────────────────────────────

(define lib-sym (syster/find-by-name symbols "SchemeLibrary"))
(when lib-sym
  (let ([opts (hash "title" "SchemeLibrary — Internal Block Diagram")])
    (write-puml (generate-ibd lib-sym symbols opts) "library-ibd.puml")
    (write-svg  (generate-ibd-dot lib-sym symbols opts) "library-ibd.svg")))

;; ── Diagram 5: Action flow — GenerateDiagramPipeline ─────────────────────────

(define pipeline-sym (syster/find-by-name symbols "GenerateDiagramPipeline"))
(when pipeline-sym
  (let ([opts (hash "title" "Generate Diagram Pipeline — Action Flow")])
    (write-puml (generate-action-flow pipeline-sym symbols opts) "pipeline-flow.puml")
    (write-svg  (generate-action-flow-dot pipeline-sym symbols opts) "pipeline-flow.svg")))

;; ── Diagram 6: State machine — ToolLifecycle ─────────────────────────────────

(define lifecycle-sym (syster/find-by-name symbols "ToolLifecycle"))
(when lifecycle-sym
  (let ([opts (hash "title" "Tool Lifecycle — State Machine")])
    (write-puml (generate-state-machine lifecycle-sym symbols opts) "lifecycle-state.puml")
    (write-svg  (generate-state-machine-dot lifecycle-sym symbols opts) "lifecycle-state.svg")))

;; ── Diagram 7: Requirement diagram ───────────────────────────────────────────

(let ([opts (hash "title" "syster-steel — Requirements")])
  (write-puml (generate-requirement-diagram symbols opts) "requirements.puml")
  (write-svg  (generate-requirement-dot symbols opts) "requirements.svg"))

;; ── Diagram 8: Use case diagram ───────────────────────────────────────────────

(let ([opts (hash "title" "syster-steel — Use Cases" "system_name" "syster-steel")])
  (write-puml (generate-use-case-diagram symbols opts) "use-cases.puml")
  (write-svg  (generate-use-case-dot symbols opts) "use-cases.svg"))

;; ── Diagram 9: Viewpoints and view definitions ────────────────────────────────

(let ([opts (hash "title" "syster-steel — Viewpoints and Views")])
  (write-puml (generate-viewpoints-diagram symbols opts) "viewpoints.puml")
  (write-svg  (generate-viewpoints-dot symbols opts) "viewpoints.svg"))

;; ── Diagram 10: Package diagram ───────────────────────────────────────────────

(let ([opts (hash "title" "syster-steel — Package Diagram")])
  (write-puml (generate-package-diagram symbols opts) "packages.puml")
  (write-svg  (generate-package-dot symbols opts) "packages.svg"))

;; ── Summary ───────────────────────────────────────────────────────────────────

(displayln "")
(displayln "Done.  Files written:")
(for-each
  (lambda (stem)
    (displayln (string-append "  " (out-path stem) ".puml"))
    (displayln (string-append "  " (out-path stem) ".svg")))
  '("system-bdd" "tool-ibd" "engine-ibd" "library-ibd"
    "pipeline-flow" "lifecycle-state"
    "requirements" "use-cases" "viewpoints" "packages"))
