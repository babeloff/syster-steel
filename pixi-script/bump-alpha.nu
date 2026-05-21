#!/usr/bin/env nu
# bump-alpha.nu — bump the patch version then sync it to pixi.toml

def main [] {
    cargo set-version --bump patch
    pixi run sync-version
}
