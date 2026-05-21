;; hello.scm — a simple syster-steel script

(define (greet name)
  (string-append "Hello, " name "!"))

(displayln (greet "SysML"))
(displayln (greet "Steel"))
