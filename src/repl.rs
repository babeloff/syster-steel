use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

use anyhow::Result;
use rustyline::{DefaultEditor, error::ReadlineError};
use steel::steel_vm::engine::Engine;
use steel::steel_vm::register_fn::RegisterFn;

const HISTORY_FILE: &str = ".syster_steel_history";

pub fn start(engine: &mut Engine) -> Result<()> {
    let exit_flag = Arc::new(AtomicBool::new(false));

    let flag = Arc::clone(&exit_flag);
    engine.register_fn("exit", move || {
        flag.store(true, Ordering::Relaxed);
    });

    let mut rl = DefaultEditor::new()?;

    let history_path = dirs::home_dir().map(|h| h.join(HISTORY_FILE));
    if let Some(ref p) = history_path {
        let _ = rl.load_history(p);
    }

    println!("syster-steel v{}", env!("CARGO_PKG_VERSION"));
    println!("Steel Scheme — type (exit) or Ctrl-D to quit, Ctrl-C to cancel input.");

    let mut buf = String::new();

    loop {
        let prompt = if buf.is_empty() { "> " } else { ".. " };
        match rl.readline(prompt) {
            Ok(line) => {
                buf.push_str(&line);
                buf.push('\n');

                if paren_depth(&buf) > 0 {
                    // expression is incomplete — keep accumulating
                    continue;
                }

                let input = buf.trim().to_owned();
                buf.clear();

                if input.is_empty() {
                    continue;
                }

                let _ = rl.add_history_entry(&input);
                eval_and_print(engine, &input);

                if exit_flag.load(Ordering::Relaxed) {
                    break;
                }
            }

            Err(ReadlineError::Interrupted) => {
                // Ctrl-C: cancel current input
                if !buf.is_empty() {
                    buf.clear();
                } else {
                    println!("(Ctrl-D or (exit) to quit)");
                }
            }

            Err(ReadlineError::Eof) => break,

            Err(e) => return Err(e.into()),
        }
    }

    if let Some(ref p) = history_path {
        let _ = rl.save_history(p);
    }

    Ok(())
}

pub fn eval_and_print(engine: &mut Engine, input: &str) {
    match engine.run(input.to_owned()) {
        Ok(results) => {
            for val in results {
                let s = format!("{val}");
                if s != "#<void>" && !s.is_empty() {
                    println!("{s}");
                }
            }
        }
        Err(e) => eprintln!("error: {e}"),
    }
}

/// Returns the net open-paren depth, ignoring strings and line comments.
fn paren_depth(s: &str) -> i32 {
    let mut depth = 0i32;
    let mut in_string = false;
    let mut in_comment = false;
    let mut escape = false;

    for ch in s.chars() {
        if in_comment {
            if ch == '\n' {
                in_comment = false;
            }
            continue;
        }
        if escape {
            escape = false;
            continue;
        }
        if in_string {
            match ch {
                '\\' => escape = true,
                '"' => in_string = false,
                _ => {}
            }
            continue;
        }
        match ch {
            ';' => in_comment = true,
            '"' => in_string = true,
            '(' | '[' => depth += 1,
            ')' | ']' => depth -= 1,
            _ => {}
        }
    }
    depth
}
