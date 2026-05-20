// use-cases.sysml — Use cases and actors for the syster-steel tool

package SysterSteelUseCases {

    use case def RunREPL {
        doc /* User starts an interactive REPL session, evaluates Scheme
               expressions, and inspects results. */
    }

    use case def ExecuteScript {
        doc /* User runs a .scm script file non-interactively via the CLI. */
    }

    use case def LoadSysmlModel {
        doc /* Script calls syster/parse-file to load a .sysml file and
               receive a HirSymbol list. */
    }

    use case def GenerateBDD {
        doc /* Script calls generate-bdd to produce a Block Definition Diagram
               PlantUML source string. */
    }

    use case def GenerateIBD {
        doc /* Script calls generate-ibd to produce an Internal Block Diagram
               PlantUML source string for a specific block. */
    }

    use case def GenerateStateMachine {
        doc /* Script calls generate-state-machine to produce a state machine
               diagram for a StateDefinition. */
    }

    use case def GenerateActionFlow {
        doc /* Script calls generate-action-flow to produce an action flow
               diagram for an ActionDefinition. */
    }

    use case def GenerateRequirementDiagram {
        doc /* Script calls generate-requirement-diagram to produce a
               requirement diagram with derivation, satisfaction, and
               refinement edges. */
    }

    use case def GenerateSequenceDiagram {
        doc /* Script calls generate-sequence-diagram to produce a sequence
               diagram for an interaction context. */
    }

    use case def GenerateUseCaseDiagram {
        doc /* Script calls generate-use-case-diagram to produce a use case
               diagram with actors, use cases, and system boundary. */
    }

    use case def RenderToSVG {
        doc /* Script calls render-diagram with format "svg" to invoke
               plantuml and produce an SVG output file. */
    }

    use case def RenderToPNG {
        doc /* Script calls render-diagram with format "png" to produce
               a raster image. */
    }

    use case def CustomiseTemplate {
        doc /* User edits a .hbs Handlebars template to change diagram styling
               without modifying Rust source. */
    }

} // end package SysterSteelUseCases
