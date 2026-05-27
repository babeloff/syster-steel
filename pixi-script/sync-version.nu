#!/usr/bin/env nu
# sync-version.nu — copy version from Cargo.toml into pixi.toml and recipes/recipe.yaml

def main [] {
    let v = open Cargo.toml | get package.version

    open --raw pixi.toml
        | dasel -i toml --root $'workspace.version = "($v)"'
        | save --force pixi.toml.tmp
    mv pixi.toml.tmp pixi.toml

    open --raw recipes/recipe.yaml
        | dasel -i yaml --root $'context.version = "($v)"'
        | save --force recipes/recipe.yaml.tmp
    mv recipes/recipe.yaml.tmp recipes/recipe.yaml
}
