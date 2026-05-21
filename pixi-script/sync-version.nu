#!/usr/bin/env nu
# sync-version.nu — copy version from Cargo.toml into pixi.toml using dasel v3

def main [] {
    let v = open Cargo.toml | get package.version
    open --raw pixi.toml
        | dasel -i toml --root $'workspace.version = "($v)"'
        | save --force pixi.toml.tmp
    mv pixi.toml.tmp pixi.toml
}
