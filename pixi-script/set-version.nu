#!/usr/bin/env nu
# set-version.nu — set an explicit version in both Cargo.toml and pixi.toml using dasel v3
# Usage: pixi run set-version VERSION=x.y.z

def main [...args] {
    # pixi passes KEY=VALUE overrides as command-line args, not env vars
    let matches = $args | where { |a| $a | str starts-with 'VERSION=' }
    if ($matches | is-empty) {
        error make { msg: "Pass VERSION=x.y.z to set the version" }
    }
    let v = $matches | first | split row '=' | last

    open --raw Cargo.toml
        | dasel -i toml --root $'package.version = "($v)"'
        | save --force Cargo.toml.tmp
    mv Cargo.toml.tmp Cargo.toml

    open --raw pixi.toml
        | dasel -i toml --root $'workspace.version = "($v)"'
        | save --force pixi.toml.tmp
    mv pixi.toml.tmp pixi.toml
}
