//! Handlebars template engine bindings for Steel.
//!
//! Exposes a Handlebars registry as an opaque Steel value so that scripts can
//! register templates and render them with Steel hash-map / list data.
//!
//! # Steel API
//!
//! ```scheme
//! (define hbs (hbs/new))
//! (hbs/register-template-file! hbs "bdd" "templates/bdd.hbs")
//! (hbs/render hbs "bdd" (hash "title" "My BDD" "theme" "plain" ...))
//! ; or render an inline template string without pre-registration:
//! (hbs/render-str hbs "Hello, {{name}}!" (hash "name" "world"))
//! ```

use std::sync::{Arc, Mutex};

use handlebars::Handlebars;
use serde_json::{Map, Number, Value};
use steel::rvals::{Custom, SteelVal};
use steel::steel_vm::engine::Engine;
use steel::steel_vm::register_fn::RegisterFn;

// ── Opaque registry type ──────────────────────────────────────────────────────

/// An opaque handle to a Handlebars template registry.
#[derive(Clone, Debug)]
pub struct SteelHandlebars(Arc<Mutex<Handlebars<'static>>>);
impl Custom for SteelHandlebars {}

// ── Steel → JSON conversion ───────────────────────────────────────────────────

/// Recursively convert a Steel value to a `serde_json::Value`.
///
/// Mapping:
/// - bool       → JSON boolean
/// - int        → JSON integer number
/// - float      → JSON float number (`null` if not finite)
/// - string     → JSON string
/// - list/vector → JSON array  (elements converted recursively)
/// - hash-map   → JSON object  (string keys only; other keys are skipped)
/// - void / other → JSON null
fn to_json(val: &SteelVal) -> Value {
    match val {
        SteelVal::BoolV(b) => Value::Bool(*b),
        SteelVal::IntV(i) => Value::Number(Number::from(*i as i64)),
        SteelVal::NumV(f) => Number::from_f64(*f)
            .map(Value::Number)
            .unwrap_or(Value::Null),
        SteelVal::StringV(s) => Value::String(s.to_string()),
        SteelVal::ListV(lst) => {
            Value::Array(lst.iter().map(to_json).collect())
        }
        SteelVal::VectorV(v) => {
            Value::Array(v.iter().map(to_json).collect())
        }
        SteelVal::HashMapV(m) => {
            let obj: Map<String, Value> = m
                .iter()
                .filter_map(|(k, v)| {
                    if let SteelVal::StringV(s) = k {
                        Some((s.to_string(), to_json(v)))
                    } else {
                        None
                    }
                })
                .collect();
            Value::Object(obj)
        }
        _ => Value::Null,
    }
}

// ── Registration ──────────────────────────────────────────────────────────────

/// Register all `hbs/*` functions with the Steel engine.
pub fn register(engine: &mut Engine) {
    // (hbs/new) → SteelHandlebars
    //   Create a new, empty Handlebars registry with HTML escaping disabled.
    engine.register_fn("hbs/new", || -> SteelHandlebars {
        let mut hbs = Handlebars::new();
        hbs.register_escape_fn(handlebars::no_escape);
        SteelHandlebars(Arc::new(Mutex::new(hbs)))
    });

    // (hbs/register-template! hbs name template-str) → void
    //   Register an inline template string under name.
    engine.register_fn(
        "hbs/register-template!",
        |hbs: SteelHandlebars, name: String, template: String| {
            hbs.0
                .lock()
                .unwrap()
                .register_template_string(&name, &template)
                .unwrap_or_else(|e| panic!("hbs/register-template! {name:?}: {e}"));
        },
    );

    // (hbs/register-template-file! hbs name path) → void
    //   Register a template from a file path under name.
    engine.register_fn(
        "hbs/register-template-file!",
        |hbs: SteelHandlebars, name: String, path: String| {
            hbs.0
                .lock()
                .unwrap()
                .register_template_file(&name, &path)
                .unwrap_or_else(|e| panic!("hbs/register-template-file! {name:?} {path:?}: {e}"));
        },
    );

    // (hbs/render hbs name data) → string
    //   Render the named template with data (a Steel hash-map / list tree).
    engine.register_fn(
        "hbs/render",
        |hbs: SteelHandlebars, name: String, data: SteelVal| -> String {
            hbs.0
                .lock()
                .unwrap()
                .render(&name, &to_json(&data))
                .unwrap_or_else(|e| panic!("hbs/render {name:?}: {e}"))
        },
    );

    // (hbs/render-str hbs template-str data) → string
    //   Render an inline template string without prior registration.
    engine.register_fn(
        "hbs/render-str",
        |hbs: SteelHandlebars, template: String, data: SteelVal| -> String {
            hbs.0
                .lock()
                .unwrap()
                .render_template(&template, &to_json(&data))
                .unwrap_or_else(|e| panic!("hbs/render-str: {e}"))
        },
    );
}
