;; plantuml-sequence.scm — Sequence diagram generators
;;
;; Corresponds to VSequence in the Java pilot implementation.
;; The Java version derives participants from OccurrenceDefinition nesting and
;; messages from FlowUsage feature chains (very complex).  This Scheme
;; implementation provides a simplified version that:
;;
;;   1. Selects PartUsage / ItemUsage children of an interaction context as
;;      participants (lifelines).
;;   2. Selects ConnectionUsage / FlowUsage children and renders them as
;;      directed arrows between the endpoint-typed participants.
;;
;; For fully automatic ordering the Java relies on Succession-based
;; topological sort; here connections are emitted in declaration order.
;;
;; Usage:
;;   (require "sysml-util.scm")
;;   (require "plantuml-sequence.scm")
;;
;; or load everything via:
;;   (require "plantuml.scm")

(require "sysml-util.scm")

(provide
  make-sequence-hbs
  generate-sequence-diagram)

;; ── Template registry ─────────────────────────────────────────────────────────

(define (make-sequence-hbs templates-dir)
  (let ([hbs (hbs/new)])
    (hbs/register-template-file! hbs "sequence"
                                 (string-append templates-dir "/sequence.hbs"))
    hbs))

;; ── Generator ─────────────────────────────────────────────────────────────────

(define (generate-sequence-diagram hbs sym all-symbols . opt-args)
  "Generate a PlantUML sequence diagram for an interaction context sym.

   Selects PartUsage / ItemUsage children as participants and
   ConnectionUsage / FlowUsage children as messages.  The source and target
   of each connection are resolved via the TypedBy and References relationships
   on the connection's endpoint children.

   opt-args: (hash ...) with keys:
     title  — diagram title (default: '<name> Sequence')
     theme  — PlantUML theme (default: 'plain')"
  (let* ([opts      (if (and (not (null? opt-args)) (hash? (car opt-args)))
                        (car opt-args)
                        (hash))]
         [title     (or (hash-try-get opts "title")
                        (string-append (hir-symbol/name sym) " Sequence"))]
         [theme     (or (hash-try-get opts "theme") "plain")]
         [children  (syster/children-of all-symbols sym)]
         ;; Participants: PartUsage / ItemUsage / PortUsage children
         [part-kinds '("PartUsage" "ItemUsage" "OccurrenceUsage")]
         [participants (filter user-visible? (filter-kinds children part-kinds))]
         ;; Messages: ConnectionUsage / FlowUsage children
         [msg-kinds '("ConnectionUsage" "FlowUsage" "MessageUsage")]
         [connections (filter user-visible? (filter-kinds children msg-kinds))]
         [part-data
           (map (lambda (p)
                  (hash "name"  (hir-symbol/name p)
                        "alias" (pu-alias (hir-symbol/name p))))
                participants)]
         ;; For each connection attempt to resolve source/target from
         ;; connector-end children typed by a participant.
         [msg-data
           (filter-map
             (lambda (conn)
               (let* ([ends       (syster/children-of all-symbols conn)]
                      [end-names  (map hir-symbol/name
                                       (filter user-visible? ends))]
                      [n          (length end-names)])
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
    (hbs/render hbs "sequence" data)))
