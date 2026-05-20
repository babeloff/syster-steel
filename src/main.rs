mod bridge;
mod cli;
mod repl;

use anyhow::{Context, Result};
use clap::Parser;
use cli::Cli;
use steel::steel_vm::engine::Engine;
use tracing::debug;

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let cli = Cli::parse();
    let mut engine = Engine::new();
    bridge::register(&mut engine);

    for path in &cli.load_paths {
        debug!("adding load path: {}", path.display());
        engine.add_search_directory(path.clone());
    }

    if let Some(ref expr) = cli.eval {
        run_expr(&mut engine, expr)?;
    }

    for script in &cli.scripts {
        run_file(&mut engine, script)?;
    }

    if cli.wants_repl() {
        repl::start(&mut engine)?;
    }

    Ok(())
}

fn run_expr(engine: &mut Engine, expr: &str) -> Result<()> {
    engine
        .run(expr.to_owned())
        .map_err(|e| anyhow::anyhow!("{e}"))
        .context("expression eval failed")?;
    Ok(())
}

fn run_file(engine: &mut Engine, path: &std::path::Path) -> Result<()> {
    debug!("running script: {}", path.display());
    let code = std::fs::read_to_string(path)
        .with_context(|| format!("cannot read {}", path.display()))?;
    engine
        .run(code)
        .map_err(|e| anyhow::anyhow!("{e}"))
        .with_context(|| format!("error in {}", path.display()))?;
    Ok(())
}
