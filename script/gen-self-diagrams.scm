;; gen-self-diagrams.scm — Generate PlantUML diagrams from data/self/ SysML models
;;
;; Generates self-documenting diagrams for the syster-steel project itself.
;;
;; Usage (from project root):
;;   syster-steel -L script script/gen-self-diagrams.scm
;;
;; Override directories:
;;   syster-steel -L script \
;;     -e '(define *self-data-dir* "data/self")' \
;;     -e '(define *self-out-dir*  "wisdom/diagrams-gen")' \
;;     script/gen-self-diagrams.scm

(require "plantuml.scm")
(require-builtin steel/filesystem)

;; ── Configuration ─────────────────────────────────────────────────────────────

(define *self-data-dir* "data/self")
(define *self-out-dir*  "wisdom/diagrams-gen")
(define *render-fmt*    #f)   ; set to "svg" or "png" to also render

;; ── Helpers ───────────────────────────────────────────────────────────────────

(define (ensure-dir path)
  (unless (path-exists? path)
    (create-directory! path)))

(define (out-path name)
  (string-append *self-out-dir* "/" name))

(define (write-and-maybe-render text filename)
  (let ([path (out-path filename)])
    (displayln (string-append "  writing " path))
    (write-plantuml-file text path)
    (when *render-fmt*
      (render-diagram path *render-fmt*))))

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

(write-and-maybe-render
  (generate-bdd
    symbols
    (hash "title" "syster-steel — Block Definition Diagram"
          "theme" "plain"))
  "system-bdd.puml")

;; ── Diagram 2: SysterSteelTool IBD — top-level parts and ports ───────────────

(define tool-sym (syster/find-by-name symbols "SysterSteelTool"))
(when tool-sym
  (write-and-maybe-render
    (generate-ibd
      tool-sym
      symbols
      (hash "title" "SysterSteelTool — Internal Block Diagram"))
    "tool-ibd.puml"))

;; ── Diagram 3: RustEngine IBD — bridge/REPL/runner parts ─────────────────────

(define engine-sym (syster/find-by-name symbols "RustEngine"))
(when engine-sym
  (write-and-maybe-render
    (generate-ibd
      engine-sym
      symbols
      (hash "title" "RustEngine — Internal Block Diagram"))
    "engine-ibd.puml"))

;; ── Diagram 4: SchemeLibrary IBD — sub-library parts ─────────────────────────

(define lib-sym (syster/find-by-name symbols "SchemeLibrary"))
(when lib-sym
  (write-and-maybe-render
    (generate-ibd
      lib-sym
      symbols
      (hash "title" "SchemeLibrary — Internal Block Diagram"))
    "library-ibd.puml"))

;; ── Diagram 5: Action flow — GenerateDiagramPipeline ─────────────────────────

(define pipeline-sym (syster/find-by-name symbols "GenerateDiagramPipeline"))
(when pipeline-sym
  (write-and-maybe-render
    (generate-action-flow pipeline-sym symbols
      (hash "title" "Generate Diagram Pipeline — Action Flow"))
    "pipeline-flow.puml"))

;; ── Diagram 6: State machine — ToolLifecycle ─────────────────────────────────

(define lifecycle-sym (syster/find-by-name symbols "ToolLifecycle"))
(when lifecycle-sym
  (write-and-maybe-render
    (generate-state-machine
      lifecycle-sym
      symbols
      (hash "title" "Tool Lifecycle — State Machine"))
    "lifecycle-state.puml"))

;; ── Diagram 7: Requirement diagram ───────────────────────────────────────────

(write-and-maybe-render
  (generate-requirement-diagram symbols
    (hash "title" "syster-steel — Requirements"))
  "requirements.puml")

;; ── Diagram 8: Use case diagram ───────────────────────────────────────────────

(write-and-maybe-render
  (generate-use-case-diagram symbols
    (hash "title"       "syster-steel — Use Cases"
          "system_name" "syster-steel"))
  "use-cases.puml")

;; ── Diagram 9: Viewpoints and view definitions ────────────────────────────────

(write-and-maybe-render
  (generate-viewpoints-diagram
    symbols
    (hash "title" "syster-steel — Viewpoints and Views"))
  "viewpoints.puml")

;; ── Diagram 10: Package diagram ───────────────────────────────────────────────

(write-and-maybe-render
  (generate-package-diagram
    symbols
    (hash "title" "syster-steel — Package Diagram"))
  "packages.puml")

;; ── Summary ───────────────────────────────────────────────────────────────────

(displayln "")
(displayln "Done.  Self-documenting diagrams written:")
(for-each
  (lambda (f) (displayln (string-append "  " (out-path f))))
  '("system-bdd.puml"
    "tool-ibd.puml"
    "engine-ibd.puml"
    "library-ibd.puml"
    "pipeline-flow.puml"
    "lifecycle-state.puml"
    "requirements.puml"
    "use-cases.puml"
    "viewpoints.puml"
    "packages.puml"))
(when *render-fmt*
  (displayln (string-append "Rendered as ." *render-fmt* " in " *self-out-dir* "/")))
