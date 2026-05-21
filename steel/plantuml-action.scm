;; plantuml-action.scm — Action flow diagram generators
;;
;; Corresponds to VAction + VActionMembers in the Java pilot implementation.
;; An action flow diagram shows the ActionUsage nodes inside an ActionDefinition
;; and the TransitionUsage edges that connect them — structurally equivalent to
;; a state machine diagram but scoped to behavioral action elements.
;;
;; Usage:
;;   (require "sysml-util.scm")
;;   (require "plantuml-action.scm")
;;
;; or load everything via:
;;   (require "plantuml.scm")

(require "sysml-util.scm")

(provide
  make-action-hbs
  generate-action-flow
  generate-action-flow-all)

;; ── Template registry ─────────────────────────────────────────────────────────

(define (make-action-hbs templates-dir)
  "Create a Handlebars registry with the action-flow template registered."
  (let ([hbs (hbs/new)])
    (hbs/register-template-file! hbs "action-flow"
                                 (string-append templates-dir "/action-flow.hbs"))
    hbs))

;; ── Generator ─────────────────────────────────────────────────────────────────

(define (generate-action-flow hbs sym all-symbols . opt-args)
  "Generate a PlantUML action-flow diagram for an ActionDefinition symbol.

   Shows ActionUsage nodes as states (with <<action>> stereotype) and
   TransitionUsage children as directed edges.  Mirrors VAction /
   VActionMembers from the Java pilot implementation.

   opt-args: (hash ...) with keys:
     title   — diagram title (default: '<name> Action Flow')
     theme   — PlantUML theme (default: 'plain')"
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
         ;; Transitions: References rel gives the source action,
         ;;              TypedBy rel gives the target type / named element.
         ;; (Same convention used in generate-state-machine.)
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
         [data (hash "title"             title
                     "theme"             theme
                     "initial_action"    initial
                     "final_action"      (if final (hash-ref final "name") #f)
                     "final_action_alias" (if final (hash-ref final "alias") #f)
                     "actions"           action-data
                     "transitions"       trans-data)])
    (hbs/render hbs "action-flow" data)))

(define (generate-action-flow-all hbs symbols . opt-args)
  "Generate action flow diagrams for every ActionDefinition in symbols.
   Returns a list of (name . puml-string) pairs."
  (let ([action-defs (filter-kinds symbols '("ActionDefinition"))])
    (filter-map
      (lambda (def)
        (let ([children (syster/children-of symbols def)])
          (if (null? (filter-kinds children '("ActionUsage" "PerformActionUsage")))
              #f
              (cons (hir-symbol/name def)
                    (apply generate-action-flow hbs def symbols opt-args)))))
      action-defs)))
