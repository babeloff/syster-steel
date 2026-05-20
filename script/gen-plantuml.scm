;; gen-plantuml.scm — Generate PlantUML diagrams from the SysML campaign model.
;;
;; Usage (from project root):
;;   syster-steel -L script script/gen-plantuml.scm
;;   syster-steel -L script -e '(define *campaign-dir* "data/other")' \
;;                script/gen-plantuml.scm
;;
;; By default loads all .sysml files under data/campaign/ and writes diagrams
;; to out/.  Override with:
;;   (define *campaign-dir* "path/to/campaign/")
;;   (define *output-dir*   "path/to/out/")
;;   (define *render-fmt*   "svg")   ; svg | png | pdf | txt | #f to skip

(require "plantuml")                ; script/plantuml.scm
(require-builtin steel/filesystem)  ; path-exists? create-directory! glob

;; ── Configuration ─────────────────────────────────────────────────────────────

(define *campaign-dir* "data/campaign")
(define *output-dir*   "out")
(define *render-fmt*   "svg")   ; set to #f to skip rendering

;; ── Helpers ───────────────────────────────────────────────────────────────────

(define (ensure-dir path)
  (unless (path-exists? path)
    (create-directory! path)))

(define (out-path name)
  (string-append *output-dir* "/" name))

(define (write-and-maybe-render text filename)
  (define path (out-path filename))
  (displayln (string-append "  writing " path))
  (write-plantuml-file text path)
  (when *render-fmt*
    (render-diagram path *render-fmt*)))

;; ── Load model from all .sysml files in the campaign directory ────────────────
;;
;; Each file contributes to the shared campaign namespace.
;; We parse each file independently and concatenate the symbol lists —
;; sufficient for diagram generation.

(define (load-campaign-symbols dir)
  (define top-files   (glob (string-append dir "/*.sysml")))
  (define alpha-files (glob (string-append dir "/alpha/*.sysml")))
  (define all-files   (append top-files alpha-files))
  (displayln (string-append "  found " (number->string (length all-files)) " files"))
  (apply append
    (map (lambda (f)
           (displayln (string-append "    parsing " f))
           (syster/file-symbols (syster/parse-file f)))
         all-files)))

(displayln (string-append "Loading campaign: " *campaign-dir*))
(define symbols (load-campaign-symbols *campaign-dir*))
(displayln (string-append "  loaded " (number->string (length symbols)) " symbols"))

(ensure-dir *output-dir*)
(displayln (string-append "Writing diagrams to " *output-dir* "/"))

;; ── Diagram 1: Viewpoints and View Definitions ────────────────────────────────
;;
;; Analogous to write_viewpoints_diagram in the Python script.
;; Shows all viewpoints, view definitions, renderings, and their
;; satisfaction / instantiation relationships.

(write-and-maybe-render
  (generate-viewpoints-diagram
    symbols
    (hash "title" "Workflow Model — Viewpoints and View Definitions"))
  "viewpoints.puml")

;; ── Diagram 2: Block Definition Diagram (full model) ─────────────────────────
;;
;; Shows all part/item/attribute/port definitions as <<block>> classes,
;; with composition lines derived from PartUsage nesting and
;; inheritance from specialization relationships.

(write-and-maybe-render
  (generate-bdd
    symbols
    (hash "title"      "Workflow Model — Block Definition Diagram"
          "theme"      "plain"))
  "workflow-bdd.puml")

;; ── Diagram 3: Campaign structural view (IBD) ────────────────────────────────
;;
;; Shows the interior of the Campaign part definition:
;; its experiment sub-parts and their relationships.

(define campaign-sym (syster/find-by-name symbols "Campaign"))
(when campaign-sym
  (write-and-maybe-render
    (generate-ibd
      campaign-sym
      symbols
      (hash "title" "Campaign — Internal Block Diagram"))
    "campaign-ibd.puml"))

;; ── Diagram 4: Experiment structural view (IBD) ──────────────────────────────

(define experiment-sym (syster/find-by-name symbols "Experiment"))
(when experiment-sym
  (write-and-maybe-render
    (generate-ibd
      experiment-sym
      symbols
      (hash "title" "Experiment — Internal Block Diagram"))
    "experiment-ibd.puml"))

;; ── Diagram 5: Vehicle hierarchy (BDD scoped to vehicle defs) ────────────────
;;
;; Analogous to write_architecture_diagram in the Python script.
;; Scope to VehicleModel::VehicleSystem and its subtypes.

(define vehicle-kinds
  '("PartDefinition"))

(define (vehicle-sym? s)
  (and (member (hir-symbol/kind s) vehicle-kinds)
       (or (equal? (hir-symbol/name s) "VehicleSystem")
           (equal? (hir-symbol/name s) "ScoutVehicle")
           (equal? (hir-symbol/name s) "PatrolVehicle")
           (equal? (hir-symbol/name s) "EvaderVehicle")
           (equal? (hir-symbol/name s) "TrackingSensor")
           (equal? (hir-symbol/name s) "NavigationSystem")
           (equal? (hir-symbol/name s) "CommunicationModule")
           (equal? (hir-symbol/name s) "WaypointPlan")
           (equal? (hir-symbol/name s) "FixedWaypointPlan")
           (equal? (hir-symbol/name s) "SearchWaypointPlan"))))

(define vehicle-symbols (filter vehicle-sym? symbols))
(when (not (null? vehicle-symbols))
  (write-and-maybe-render
    (generate-bdd
      vehicle-symbols
      (hash "title" "Simulated Vehicle Architecture — Block Definition Diagram"
            "theme" "plain"))
    "vehicle-bdd.puml"))

;; ── Diagram 6: Vehicle operational state machine ──────────────────────────────

(define vehicle-state-sym (syster/find-by-name symbols "VehicleOperationalState"))
(when vehicle-state-sym
  (write-and-maybe-render
    (generate-state-machine
      vehicle-state-sym
      symbols
      (hash "title" "Vehicle Operational State Machine"))
    "vehicle-state.puml"))

;; ── Diagram 7: Experiment lifecycle state machine ────────────────────────────

(define exp-state-sym (syster/find-by-name symbols "ExperimentLifecycleState"))
(when exp-state-sym
  (write-and-maybe-render
    (generate-state-machine
      exp-state-sym
      symbols
      (hash "title" "Experiment Lifecycle State Machine"))
    "experiment-state.puml"))

;; ── Diagram 8: Package diagram ────────────────────────────────────────────────

(write-and-maybe-render
  (generate-package-diagram
    symbols
    (hash "title" "Workflow Model — Package Diagram"))
  "packages.puml")

;; ── Summary ───────────────────────────────────────────────────────────────────

(displayln "")
(displayln "Done.  Diagrams written:")
(for-each (lambda (f)
            (displayln (string-append "  " (out-path f))))
          (list "viewpoints.puml"
                "workflow-bdd.puml"
                "campaign-ibd.puml"
                "experiment-ibd.puml"
                "vehicle-bdd.puml"
                "vehicle-state.puml"
                "experiment-state.puml"
                "packages.puml"))
(when *render-fmt*
  (displayln (string-append "Rendered as ." *render-fmt* " in " *output-dir* "/")))
