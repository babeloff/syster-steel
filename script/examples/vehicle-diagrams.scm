;; vehicle-diagrams.scm — generate BDD and IBD for vehicle.sysml
;;
;; Usage (from project root):
;;   syster-steel -L script script/examples/vehicle-diagrams.scm
;;
;; Writes out/vehicle-bdd.puml and out/vehicle-ibd.puml, then renders to SVG.

(require "plantuml")
(require-builtin steel/filesystem)

(define model   (syster/parse-file "vehicle.sysml"))
(define symbols (syster/file-symbols model))

(unless (path-exists? "out")
  (create-directory! "out"))

; BDD for the whole model
(write-plantuml-file
  (generate-bdd symbols
    (hash "title" "Vehicle System — Block Definition Diagram"
          "theme" "plain"))
  "out/vehicle-bdd.puml")
(render-diagram "out/vehicle-bdd.puml" "svg")

; IBD for VehicleSystem
(define vs (syster/find-by-name symbols "VehicleSystem"))
(write-plantuml-file
  (generate-ibd vs symbols
    (hash "title" "VehicleSystem — Internal Block Diagram"))
  "out/vehicle-ibd.puml")
(render-diagram "out/vehicle-ibd.puml" "svg")

(displayln "Done — diagrams written to out/")
