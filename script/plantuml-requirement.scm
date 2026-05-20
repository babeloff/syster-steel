;; plantuml-requirement.scm — Requirement diagram generators
;;
;; Corresponds to VRequirement + VCompartment in the Java pilot implementation.
;; A requirement diagram shows RequirementDefinition and RequirementUsage
;; elements as labelled boxes (using a PlantUML class-with-stereotype layout),
;; with containment (*--), derivation (deriveReqt), satisfaction (satisfy),
;; and refinement (refine) relationships.
;;
;; Usage:
;;   (require "sysml-util.scm")
;;   (require "plantuml-requirement.scm")
;;
;; or load everything via:
;;   (require "plantuml.scm")

(require "sysml-util.scm")

(provide
  make-requirement-hbs
  generate-requirement-diagram
  generate-requirement-diagram-scoped)

;; ── Template registry ─────────────────────────────────────────────────────────

(define (make-requirement-hbs templates-dir)
  (let ([hbs (hbs/new)])
    (hbs/register-template-file! hbs "requirement"
                                 (string-append templates-dir "/requirement.hbs"))
    hbs))

;; ── Helpers ───────────────────────────────────────────────────────────────────

(define *req-def-kinds*
  '("RequirementDefinition" "SatisfactionRequirementDefinition"
    "VerificationCaseDefinition"))

(define *req-usage-kinds*
  '("RequirementUsage" "SatisfactionRequirementUsage"))

(define (req-stereotype sym)
  (let ([k (hir-symbol/kind sym)])
    (if (member k *req-def-kinds*) "requirementDef" "requirement")))

(define (req-node sym)
  (hash "name"        (hir-symbol/name sym)
        "alias"       (pu-alias (hir-symbol/name sym))
        "stereotype"  (req-stereotype sym)))

;; ── Generator ─────────────────────────────────────────────────────────────────

(define (generate-requirement-diagram hbs symbols . opt-args)
  "Generate a PlantUML requirement diagram from a flat list of HirSymbol values.

   Shows RequirementDefinition and RequirementUsage elements as labelled boxes
   with <<requirement>> or <<requirementDef>> stereotypes.

   Relationship kinds recognised in hir-symbol/relationships:
     DeriveReqt  — derivation edge (source <.. target)
     Satisfy     — satisfaction edge (satisfier ..|> requirement)
     Refine      — refinement edge
     Specializes — containment/nesting (parent *-- child)

   opt-args: (hash ...) with keys:
     title  — diagram title (default: 'Requirement Diagram')
     theme  — PlantUML theme (default: 'plain')"
  (let* ([opts      (if (and (not (null? opt-args)) (hash? (car opt-args)))
                        (car opt-args)
                        (hash))]
         [title     (or (hash-try-get opts "title") "Requirement Diagram")]
         [theme     (or (hash-try-get opts "theme") "plain")]
         [req-syms  (filter user-visible?
                            (filter-kinds symbols
                                          (append *req-def-kinds* *req-usage-kinds*)))]
         [req-data  (map req-node req-syms)]
         ;; Containment: child requirements that have a parent in the same set
         [contain-data
           (filter-map
             (lambda (sym)
               (let ([supers (hir-symbol/supertypes sym)])
                 (if (null? supers)
                     #f
                     (hash "parent_alias" (pu-alias (car supers))
                           "child_alias"  (pu-alias (hir-symbol/name sym))))))
             req-syms)]
         ;; Relationship edges: DeriveReqt, Satisfy, Refine
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
                           (hash "satisfier_alias"    (pu-alias (hir-symbol/name sym))
                                 "requirement_alias"  (pu-alias tgt)))
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
    (hbs/render hbs "requirement" data)))

(define (generate-requirement-diagram-scoped hbs sym all-symbols . opt-args)
  "Generate a requirement diagram scoped to the children of sym."
  (let ([children (filter user-visible?
                          (filter-kinds (syster/children-of all-symbols sym)
                                        (append *req-def-kinds* *req-usage-kinds*)))])
    (apply generate-requirement-diagram hbs children opt-args)))
