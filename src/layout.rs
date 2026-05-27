//! layout-rs bindings for Steel.
//!
//! Renders DOT-format graph descriptions to SVG using the layout-rs crate
//! (Sugiyama hierarchical layout). No external process is required.
//!
//! # Steel API
//!
//! ```scheme
//! ; Render a DOT string to SVG and return the SVG as a string.
//! (layout/dot->svg dot-string) → string
//!
//! ; Render a DOT string to SVG and write the result to svg-path.
//! (layout/render-dot dot-string svg-path) → void
//! ```

use layout::backends::svg::SVGWriter;
use layout::gv::{DotParser, GraphBuilder};
use steel::steel_vm::engine::Engine;
use steel::steel_vm::register_fn::RegisterFn;

fn dot_to_svg(dot: String) -> String {
    let mut parser = DotParser::new(&dot);
    let ast = parser
        .process()
        .unwrap_or_else(|_| { parser.print_error(); panic!("layout/dot->svg: DOT parse error") });
    let mut builder = GraphBuilder::new();
    builder.visit_graph(&ast);
    let mut vg = builder.get();
    let mut svg = SVGWriter::new();
    vg.do_it(false, false, false, &mut svg);
    svg.finalize()
}

fn render_dot(dot: String, path: String) {
    let svg = dot_to_svg(dot);
    std::fs::write(&path, svg)
        .unwrap_or_else(|e| panic!("layout/render-dot: cannot write {path:?}: {e}"));
}

pub fn register(engine: &mut Engine) {
    engine.register_fn("layout/dot->svg", dot_to_svg);
    engine.register_fn("layout/render-dot", render_dot);
}
