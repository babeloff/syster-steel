#!/usr/bin/env nu
# render.nu — render all .puml files in a directory to SVG, PNG, or both
# Usage: nu pixi-script/render.nu <dir> [--format svg|png|both]

def main [
    dir: string
    --format: string = "both"  # output format: svg, png, or both
] {
    let files = glob $"($dir)/*.puml"
    if ($files | is-empty) {
        error make { msg: $"No .puml files found in ($dir)" }
    }
    let formats = match $format {
        "svg"  => ["svg"]
        "png"  => ["png"]
        "both" => ["svg" "png"]
        _      => { error make { msg: $"Unknown format '($format)' — use svg, png, or both" } }
    }
    with-env { JAVA_TOOL_OPTIONS: "-Djava.awt.headless=true" } {
        for fmt in $formats {
            ^plantuml $"-t($fmt)" ...$files
        }
    }
}
