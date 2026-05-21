#!/usr/bin/env nu
# clean.nu — remove stale rattler-build output packages

def main [] {
    rm --recursive --force output/
}
