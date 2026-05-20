;; greetings.scm — a Steel module that exports the greet procedure

(provide greet)

(define (greet name)
  (string-append "Hello, " name "!"))
