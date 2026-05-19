use clap::Parser;
use std::path::PathBuf;

/// SysML v2 scripting via Steel Scheme.
///
/// Without arguments, starts an interactive REPL.
/// With script files, runs them in order then exits (unless -i is given).
#[derive(Parser, Debug)]
#[command(name = "syster-steel", version, about, long_about = None)]
pub struct Cli {
    /// Script files to run, in order
    #[arg(value_name = "SCRIPT")]
    pub scripts: Vec<PathBuf>,

    /// Start interactive REPL after running scripts (or -e expressions)
    #[arg(short, long)]
    pub interactive: bool,

    /// Evaluate expression before running scripts
    #[arg(short, long = "eval", value_name = "EXPR")]
    pub eval: Option<String>,

    /// Add a directory to the Steel module load path
    #[arg(short = 'L', long = "load-path", value_name = "DIR")]
    pub load_paths: Vec<PathBuf>,
}

impl Cli {
    /// True if we should drop into the REPL after running any scripts/-e.
    pub fn wants_repl(&self) -> bool {
        self.interactive || (self.scripts.is_empty() && self.eval.is_none())
    }
}
