;; sysml-util.scm — Shared utilities for SysML v2 PlantUML generation
;;
;; Load with:
;;   (require "sysml-util.scm")   ; with -L steel on the load path

(provide
  ;; PlantUML identifier safety
  pu-safe-char?
  pu-alias
  user-visible?

  ;; Symbol filtering
  filter-kind
  filter-kinds
  filter-map
  find-syster-by-name

  ;; Relationship helpers
  find-rel
  find-rels
  rel-targets

  ;; Option-hash helpers
  hash-try-get
  opts-title
  opts-theme)

;; ── PlantUML identifier helpers ───────────────────────────────────────────────

(define (pu-safe-char? c)
  (let ([n (char->integer c)])
    (or (and (>= n 65) (<= n 90))   ; A-Z
        (and (>= n 97) (<= n 122))  ; a-z
        (and (>= n 48) (<= n 57))   ; 0-9
        (= n 95))))                 ; _

(define (pu-alias name)
  "Return a PlantUML-safe identifier by replacing non-alphanumeric chars with _."
  (list->string
    (map (lambda (c) (if (pu-safe-char? c) c #\_))
         (string->list name))))

;; True for symbols whose names do NOT start with '<' (Steel internal reprs
;; leak through for unnamed SysML elements, e.g. anonymous type references).
(define (user-visible? sym)
  (let ([name (hir-symbol/name sym)])
    (or (= (string-length name) 0)
        (not (char=? (string-ref name 0) #\<)))))

;; ── Symbol filtering ──────────────────────────────────────────────────────────

(define (filter-kind symbols kind-str)
  (filter (lambda (s) (equal? (hir-symbol/kind s) kind-str)) symbols))

(define (filter-kinds symbols kind-list)
  (filter (lambda (s) (member (hir-symbol/kind s) kind-list)) symbols))

(define (filter-map f lst)
  (filter (lambda (x) (not (equal? x #f))) (map f lst)))

(define (find-syster-by-name symbols name)
  (let loop ([syms symbols])
    (cond [(null? syms) #f]
          [(equal? (hir-symbol/name (car syms)) name) (car syms)]
          [else (loop (cdr syms))])))

;; ── Relationship helpers ──────────────────────────────────────────────────────

(define (find-rel rels kind)
  "Return the first relationship of the given kind, or #f."
  (let loop ([rs rels])
    (cond [(null? rs) #f]
          [(string=? (hir-rel/kind (car rs)) kind) (car rs)]
          [else (loop (cdr rs))])))

(define (find-rels rels kind)
  "Return all relationships of the given kind."
  (filter (lambda (r) (string=? (hir-rel/kind r) kind)) rels))

(define (rel-targets sym kind)
  "Return the target strings of all relationships of kind on sym."
  (map hir-rel/target (find-rels (hir-symbol/relationships sym) kind)))

;; ── Option-hash helpers ───────────────────────────────────────────────────────

(define (hash-try-get h key)
  (if (hash-contains? h key) (hash-ref h key) #f))

(define (opts-title opt-args default-fn sym)
  "Extract title from opt-args hash, calling (default-fn sym) if absent."
  (let* ([opts (if (and (not (null? opt-args)) (hash? (car opt-args)))
                   (car opt-args)
                   (hash))]
         [t    (hash-try-get opts "title")])
    (or t (default-fn sym))))

(define (opts-theme opt-args)
  (let ([opts (if (and (not (null? opt-args)) (hash? (car opt-args)))
                  (car opt-args)
                  (hash))])
    (or (hash-try-get opts "theme") "plain")))
