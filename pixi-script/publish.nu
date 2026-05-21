#!/usr/bin/env nu
# publish.nu — upload conda packages to prefix.dev/meso-forge

def main [] {
    let packages = glob 'output/linux-64/*.conda'
    if ($packages | is-empty) {
        error make { msg: "No packages found in output/linux-64/ — run pixi run package first" }
    }
    ^rattler-build upload prefix --channel meso-forge ...$packages
}
