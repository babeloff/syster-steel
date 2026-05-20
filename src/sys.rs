//! Shell and filesystem bindings for Steel.
//!
//! Registers `system` and `glob-list` so Steel scripts can invoke external
//! programs and enumerate files without depending on Steel's optional builtins.
//!
//! # Steel API
//!
//! ```scheme
//! (system "plantuml -tsvg out/diagram.puml")  ; run via /bin/sh -c, returns bool
//! (glob-list "data/campaign/*.sysml")          ; returns a list of matching paths
//! ```

use steel::steel_vm::engine::Engine;
use steel::steel_vm::register_fn::RegisterFn;

/// Register shell and filesystem utility functions with the Steel engine.
pub fn register(engine: &mut Engine) {
    // (system cmd) → bool
    //   Run cmd via /bin/sh -c.  Returns #t on success (exit 0), #f otherwise.
    engine.register_fn("system", |cmd: String| -> bool {
        std::process::Command::new("sh")
            .arg("-c")
            .arg(&cmd)
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
    });

    // (glob-list pattern) → list of strings
    //   Expand a glob pattern and return matching paths as a Steel list.
    //   Returns an empty list if the pattern matches nothing or the directory
    //   does not exist.
    engine.register_fn("glob-list", |pattern: String| -> Vec<String> {
        glob::glob(&pattern)
            .unwrap_or_else(|e| panic!("glob-list: invalid pattern {pattern:?}: {e}"))
            .filter_map(|entry| entry.ok())
            .map(|p| p.display().to_string())
            .collect()
    });
}
