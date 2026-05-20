//! Steel bindings for syster-base SysML v2 types.
//!
//! Registers opaque wrapper types and accessor functions with the Steel engine,
//! exposing the syster-base parsing and HIR API to Steel scripts.

use std::sync::Arc;

use steel::rvals::Custom;
use steel::steel_vm::engine::Engine;
use steel::steel_vm::register_fn::RegisterFn;

use syster::hir::{HirRelationship, HirSymbol, RelationshipKind, SymbolKind};
use syster::ide::AnalysisHost;

// ── Wrapper types ─────────────────────────────────────────────────────────────

/// Opaque handle to a parsed SysML model (ordered list of all HIR symbols).
#[derive(Clone, Debug)]
pub struct SteelSysmlModel(pub Arc<[HirSymbol]>);
impl Custom for SteelSysmlModel {}

/// Opaque handle to a single HIR symbol.
#[derive(Clone, Debug)]
pub struct SteelHirSymbol(pub HirSymbol);
impl Custom for SteelHirSymbol {}

/// Opaque handle to a single HIR relationship.
#[derive(Clone, Debug)]
pub struct SteelHirRelationship(pub HirRelationship);
impl Custom for SteelHirRelationship {}

// ── Helpers ───────────────────────────────────────────────────────────────────

fn symbol_kind_str(k: SymbolKind) -> &'static str {
    match k {
        SymbolKind::Package => "Package",
        SymbolKind::PartDefinition => "PartDefinition",
        SymbolKind::ItemDefinition => "ItemDefinition",
        SymbolKind::ActionDefinition => "ActionDefinition",
        SymbolKind::PortDefinition => "PortDefinition",
        SymbolKind::AttributeDefinition => "AttributeDefinition",
        SymbolKind::ConnectionDefinition => "ConnectionDefinition",
        SymbolKind::InterfaceDefinition => "InterfaceDefinition",
        SymbolKind::AllocationDefinition => "AllocationDefinition",
        SymbolKind::RequirementDefinition => "RequirementDefinition",
        SymbolKind::ConstraintDefinition => "ConstraintDefinition",
        SymbolKind::StateDefinition => "StateDefinition",
        SymbolKind::CalculationDefinition => "CalculationDefinition",
        SymbolKind::UseCaseDefinition => "UseCaseDefinition",
        SymbolKind::AnalysisCaseDefinition => "AnalysisCaseDefinition",
        SymbolKind::ConcernDefinition => "ConcernDefinition",
        SymbolKind::ViewDefinition => "ViewDefinition",
        SymbolKind::ViewpointDefinition => "ViewpointDefinition",
        SymbolKind::RenderingDefinition => "RenderingDefinition",
        SymbolKind::EnumerationDefinition => "EnumerationDefinition",
        SymbolKind::MetadataDefinition => "MetadataDefinition",
        SymbolKind::Interaction => "Interaction",
        SymbolKind::DataType => "DataType",
        SymbolKind::Class => "Class",
        SymbolKind::Structure => "Structure",
        SymbolKind::Behavior => "Behavior",
        SymbolKind::Function => "Function",
        SymbolKind::Association => "Association",
        SymbolKind::PartUsage => "PartUsage",
        SymbolKind::ItemUsage => "ItemUsage",
        SymbolKind::ActionUsage => "ActionUsage",
        SymbolKind::PortUsage => "PortUsage",
        SymbolKind::AttributeUsage => "AttributeUsage",
        SymbolKind::ConnectionUsage => "ConnectionUsage",
        SymbolKind::InterfaceUsage => "InterfaceUsage",
        SymbolKind::AllocationUsage => "AllocationUsage",
        SymbolKind::RequirementUsage => "RequirementUsage",
        SymbolKind::ConstraintUsage => "ConstraintUsage",
        SymbolKind::StateUsage => "StateUsage",
        SymbolKind::TransitionUsage => "TransitionUsage",
        SymbolKind::CalculationUsage => "CalculationUsage",
        SymbolKind::ReferenceUsage => "ReferenceUsage",
        SymbolKind::OccurrenceUsage => "OccurrenceUsage",
        SymbolKind::FlowConnectionUsage => "FlowConnectionUsage",
        SymbolKind::ViewUsage => "ViewUsage",
        SymbolKind::ViewpointUsage => "ViewpointUsage",
        SymbolKind::RenderingUsage => "RenderingUsage",
        SymbolKind::ExposeRelationship => "ExposeRelationship",
        SymbolKind::Import => "Import",
        SymbolKind::Alias => "Alias",
        SymbolKind::Comment => "Comment",
        SymbolKind::Dependency => "Dependency",
        SymbolKind::Other => "Other",
    }
}

fn rel_kind_str(k: RelationshipKind) -> &'static str {
    match k {
        RelationshipKind::Specializes => "Specializes",
        RelationshipKind::TypedBy => "TypedBy",
        RelationshipKind::Redefines => "Redefines",
        RelationshipKind::Subsets => "Subsets",
        RelationshipKind::References => "References",
        RelationshipKind::Satisfies => "Satisfies",
        RelationshipKind::Performs => "Performs",
        RelationshipKind::Exhibits => "Exhibits",
        RelationshipKind::Includes => "Includes",
        RelationshipKind::Asserts => "Asserts",
        RelationshipKind::Verifies => "Verifies",
    }
}

// ── Registration ──────────────────────────────────────────────────────────────

/// Register all syster-base bindings with the Steel engine.
pub fn register(engine: &mut Engine) {
    // ── Model functions ───────────────────────────────────────────────────────

    engine.register_fn("syster/parse-file", |path: String| -> SteelSysmlModel {
        let content = std::fs::read_to_string(&path)
            .unwrap_or_else(|e| panic!("syster/parse-file: cannot read {path}: {e}"));
        let mut host = AnalysisHost::new();
        host.set_file_content(&path, &content);
        host.rebuild_index();
        let symbols: Vec<HirSymbol> = host.symbol_index().all_symbols().cloned().collect();
        SteelSysmlModel(symbols.into())
    });

    engine.register_fn(
        "syster/file-symbols",
        |model: SteelSysmlModel| -> Vec<SteelHirSymbol> {
            model.0.iter().map(|s| SteelHirSymbol(s.clone())).collect()
        },
    );

    // ── Utility search functions ──────────────────────────────────────────────

    engine.register_fn(
        "syster/find-by-name",
        |symbols: Vec<SteelHirSymbol>, name: String| -> Option<SteelHirSymbol> {
            symbols.into_iter().find(|s| s.0.name.as_ref() == name.as_str())
        },
    );

    engine.register_fn(
        "syster/find-by-qname",
        |symbols: Vec<SteelHirSymbol>, qname: String| -> Option<SteelHirSymbol> {
            symbols
                .into_iter()
                .find(|s| s.0.qualified_name.as_ref() == qname.as_str())
        },
    );

    engine.register_fn(
        "syster/children-of",
        |symbols: Vec<SteelHirSymbol>, parent: SteelHirSymbol| -> Vec<SteelHirSymbol> {
            let parent_qname = parent.0.qualified_name.clone();
            symbols
                .into_iter()
                .filter(|s| {
                    // A direct child's qualified name is  "ParentQName::ChildName"
                    // with no further "::" after the separator.
                    if let Some(rest) = s.0.qualified_name.strip_prefix(parent_qname.as_ref()) {
                        rest.starts_with("::") && !rest[2..].contains("::")
                    } else {
                        false
                    }
                })
                .collect()
        },
    );

    engine.register_fn(
        "syster/descendants-of",
        |symbols: Vec<SteelHirSymbol>, parent: SteelHirSymbol| -> Vec<SteelHirSymbol> {
            let parent_qname = parent.0.qualified_name.clone();
            let prefix = format!("{parent_qname}::");
            symbols
                .into_iter()
                .filter(|s| s.0.qualified_name.starts_with(prefix.as_str()))
                .collect()
        },
    );

    // ── HirSymbol accessors ───────────────────────────────────────────────────

    engine.register_fn("hir-symbol/name", |s: SteelHirSymbol| -> String {
        s.0.name.to_string()
    });

    engine.register_fn(
        "hir-symbol/qualified-name",
        |s: SteelHirSymbol| -> String { s.0.qualified_name.to_string() },
    );

    engine.register_fn("hir-symbol/kind", |s: SteelHirSymbol| -> String {
        symbol_kind_str(s.0.kind).to_owned()
    });

    engine.register_fn(
        "hir-symbol/doc",
        |s: SteelHirSymbol| -> Option<String> { s.0.doc.as_deref().map(|d| d.to_owned()) },
    );

    engine.register_fn(
        "hir-symbol/supertypes",
        |s: SteelHirSymbol| -> Vec<String> {
            s.0.supertypes.iter().map(|n| n.to_string()).collect()
        },
    );

    engine.register_fn(
        "hir-symbol/relationships",
        |s: SteelHirSymbol| -> Vec<SteelHirRelationship> {
            s.0.relationships
                .iter()
                .map(|r| SteelHirRelationship(r.clone()))
                .collect()
        },
    );

    engine.register_fn("hir-symbol/file", |s: SteelHirSymbol| -> String {
        s.0.file.index().to_string()
    });

    engine.register_fn("hir-symbol/line", |s: SteelHirSymbol| -> i64 {
        (s.0.start_line + 1) as i64
    });

    // Boolean flags
    engine.register_fn("hir-symbol/is-abstract?", |s: SteelHirSymbol| -> bool {
        s.0.is_abstract
    });
    engine.register_fn("hir-symbol/is-variation?", |s: SteelHirSymbol| -> bool {
        s.0.is_variation
    });
    engine.register_fn("hir-symbol/is-readonly?", |s: SteelHirSymbol| -> bool {
        s.0.is_readonly
    });
    engine.register_fn("hir-symbol/is-derived?", |s: SteelHirSymbol| -> bool {
        s.0.is_derived
    });
    engine.register_fn("hir-symbol/is-ordered?", |s: SteelHirSymbol| -> bool {
        s.0.is_ordered
    });
    engine.register_fn("hir-symbol/is-nonunique?", |s: SteelHirSymbol| -> bool {
        s.0.is_nonunique
    });
    engine.register_fn("hir-symbol/is-portion?", |s: SteelHirSymbol| -> bool {
        s.0.is_portion
    });
    engine.register_fn("hir-symbol/is-individual?", |s: SteelHirSymbol| -> bool {
        s.0.is_individual
    });
    engine.register_fn("hir-symbol/is-end?", |s: SteelHirSymbol| -> bool {
        s.0.is_end
    });

    engine.register_fn(
        "hir-symbol/direction",
        |s: SteelHirSymbol| -> Option<String> {
            s.0.direction.map(|d| {
                match d {
                    syster::parser::Direction::In => "In",
                    syster::parser::Direction::Out => "Out",
                    syster::parser::Direction::InOut => "InOut",
                }
                .to_owned()
            })
        },
    );

    engine.register_fn(
        "hir-symbol/multiplicity",
        |s: SteelHirSymbol| -> Option<Vec<i64>> {
            s.0.multiplicity.map(|m| {
                let lower = m.lower.map(|v| v as i64).unwrap_or(0);
                let upper = m.upper.map(|v| v as i64).unwrap_or(-1);
                vec![lower, upper]
            })
        },
    );

    // View-specific accessors
    engine.register_fn(
        "hir-symbol/view-expose",
        |s: SteelHirSymbol| -> Vec<String> {
            use syster::hir::ViewData;
            match s.0.view_data {
                Some(ViewData::ViewDefinition(vd)) => vd
                    .expose
                    .iter()
                    .map(|e| e.import_path.target.to_string())
                    .collect(),
                Some(ViewData::ViewUsage(vu)) => vu
                    .expose
                    .iter()
                    .map(|e| e.import_path.target.to_string())
                    .collect(),
                _ => Vec::new(),
            }
        },
    );

    engine.register_fn(
        "hir-symbol/view-rendering",
        |s: SteelHirSymbol| -> Option<String> {
            use syster::hir::ViewData;
            match s.0.view_data {
                Some(ViewData::ViewDefinition(vd)) => {
                    vd.rendering.map(|r| r.rendering.to_string())
                }
                Some(ViewData::ViewUsage(vu)) => {
                    vu.rendering.map(|r| r.rendering.to_string())
                }
                _ => None,
            }
        },
    );

    // ── HirRelationship accessors ─────────────────────────────────────────────

    engine.register_fn("hir-rel/kind", |r: SteelHirRelationship| -> String {
        rel_kind_str(r.0.kind).to_owned()
    });

    engine.register_fn("hir-rel/target", |r: SteelHirRelationship| -> String {
        r.0.target.to_string()
    });

    engine.register_fn(
        "hir-rel/resolved-target",
        |r: SteelHirRelationship| -> Option<String> {
            r.0.resolved_target.as_deref().map(|s| s.to_owned())
        },
    );
}
