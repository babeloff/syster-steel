#!/usr/bin/env nu
# gen-self-diagrams.nu — Generate self-documenting PlantUML diagrams for syster-steel.
#
# Loads data/self/*.sysml and runs script/gen-self-diagrams.scm to produce
# PlantUML files in wisdom/diagrams-gen/, then optionally renders them.
#
# Usage (run from project root):
#   nu pixi-script/gen-self-diagrams.nu
#   nu pixi-script/gen-self-diagrams.nu --render
#   nu pixi-script/gen-self-diagrams.nu --render --format png --out-dir docs/images

def main [
    --render              # also invoke plantuml to render each .puml file
    --format: string = "svg"          # output format: svg, png, pdf, txt
    --out-dir: string = "wisdom/diagrams-gen"  # directory for .puml (and rendered) files
    --data-dir: string = "data/self"  # directory containing .sysml source files
] {
    # Detect whether syster-steel is on PATH; fall back to cargo run
    let steel_cmd = if (which syster-steel | is-empty) {
        ["cargo" "run" "--" ]
    } else {
        ["syster-steel"]
    }

    print $"Using: ($steel_cmd | str join ' ')"

    # Ensure the output directory exists
    mkdir $out_dir

    # Run the generation script, passing overrides as inline -e expressions
    let args = [
        "-e" $"(define *self-data-dir* \"($data_dir)\")"
        "-e" $"(define *self-out-dir*  \"($out_dir)\")"
        "-L" "script"
        "script/gen-self-diagrams.scm"
    ]

    print $"\nGenerating diagrams from ($data_dir) → ($out_dir)/"
    run-external ...$steel_cmd ...$args

    # List generated .puml files
    let puml_files = (ls $"($out_dir)/*.puml" | get name)
    print $"\n($puml_files | length) .puml file(s) in ($out_dir)/:"
    $puml_files | each { |f| print $"  ($f)" }

    # Optionally render with plantuml
    if $render {
        if (which plantuml | is-empty) {
            print "\nWarning: plantuml not found on PATH — skipping render step."
            return
        }

        print $"\nRendering to .($format) ..."
        with-env { JAVA_TOOL_OPTIONS: "-Djava.awt.headless=true" } {
            $puml_files | each { |f|
                print $"  plantuml -t($format) ($f)"
                run-external "plantuml" $"-t($format)" $f
            }
        }

        let rendered = (ls $"($out_dir)/*.($format)" | get name)
        print $"\n($rendered | length) rendered file(s):"
        $rendered | each { |f| print $"  ($f)" }
    }
}
