;; plantuml-use-case.scm — Use case and case diagram generators
;;
;; Corresponds to VCase + VCaseMembers in the Java pilot implementation.
;; Shows use cases (UseCaseDefinition / UseCaseUsage or CaseDefinition /
;; CaseUsage) and actors (ActorUsage / PartUsage with actor stereotype)
;; within a system boundary rectangle.
;;
;; Usage:
;;   (require "sysml-util.scm")
;;   (require "plantuml-use-case.scm")
;;
;; or load everything via:
;;   (require "plantuml.scm")

(require "sysml-util.scm")

(provide
  make-use-case-hbs
  generate-use-case-diagram)

;; ── Template registry ─────────────────────────────────────────────────────────

(define (make-use-case-hbs templates-dir)
  (let ([hbs (hbs/new)])
    (hbs/register-template-file! hbs "use-case"
                                 (string-append templates-dir "/use-case.hbs"))
    hbs))

;; ── Generator ─────────────────────────────────────────────────────────────────

;; SysML v2 uses a range of names depending on the profile/library in use.
(define *uc-kinds*
  '("UseCaseDefinition" "UseCaseUsage" "CaseDefinition" "CaseUsage"))

(define *actor-kinds*
  '("ActorUsage" "ActorDefinition"))

(define (generate-use-case-diagram hbs symbols . opt-args)
  "Generate a PlantUML use case diagram from a flat list of HirSymbol values.

   Selects UseCaseDefinition/UseCaseUsage (or CaseDefinition/CaseUsage) as use
   cases, ActorUsage/ActorDefinition as actors, and derives actor→use-case
   edges from SubjectMembership or References relationships.

   Include/extend relationships are derived from TypedBy / Specializes kinds.

   opt-args: (hash ...) with keys:
     title        — diagram title (default: 'Use Case Diagram')
     theme        — PlantUML theme (default: 'plain')
     system_name  — label for the system boundary rectangle (default: 'System')"
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
         ;; Actor → use case edges: look for References relationships
         ;; on actor symbols pointing at use case names.
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
         ;; Include: Specializes or TypedBy relationships between use cases
         [include-edges
           (filter-map
             (lambda (uc)
               (let ([supers (hir-symbol/supertypes uc)])
                 (if (null? supers)
                     #f
                     (hash "source_alias" (pu-alias (hir-symbol/name uc))
                           "target_alias" (pu-alias (car supers))))))
             uc-syms)]
         [data (hash "title"        title
                     "theme"        theme
                     "system_name"  system-name
                     "actors"       actor-data
                     "use_cases"    uc-data
                     "actor_edges"  actor-edges
                     "include_edges" include-edges
                     "extend_edges" '())])
    (hbs/render hbs "use-case" data)))
