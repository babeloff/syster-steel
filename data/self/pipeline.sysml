// pipeline.sysml — Behavioral pipeline for diagram generation

package SysterSteelPipeline {

    action def ParseSysmlFile {
        doc /* Read a .sysml source file and parse it into a HirSymbol list. */
        in  filePath  : String;
        out symbols   : String;
    }

    action def FilterSymbols {
        doc /* Select symbols by kind (e.g. PartDefinition, ActionDefinition). */
        in  symbols   : String;
        in  kind      : String;
        out filtered  : String;
    }

    action def BuildDataHash {
        doc /* Assemble a Steel hash-map representing diagram data for the
               Handlebars template. */
        in  symbols   : String;
        in  opts      : String;
        out dataHash  : String;
    }

    action def RenderTemplate {
        doc /* Invoke hbs/render to produce PlantUML source from the template
               and the data hash. */
        in  registry  : String;
        in  template  : String;
        in  dataHash  : String;
        out pumlText  : String;
    }

    action def WritePumlFile {
        doc /* Write PlantUML source text to a .puml file on disk. */
        in  pumlText  : String;
        in  filePath  : String;
    }

    action def RenderDiagram {
        doc /* Invoke plantuml to render a .puml file to SVG or PNG.
               Sets JAVA_TOOL_OPTIONS=-Djava.awt.headless=true. */
        in  pumlPath  : String;
        in  format    : String;
    }

    action def GenerateDiagramPipeline {
        doc /* End-to-end pipeline: parse SysML, build data, render template,
               write file, and optionally invoke plantuml. */

        action parseFile   : ParseSysmlFile;
        action selectKinds : FilterSymbols;
        action buildHash   : BuildDataHash;
        action renderTmpl  : RenderTemplate;
        action writeFile   : WritePumlFile;
        action drawDiagram : RenderDiagram;
    }

    state def ToolLifecycle {
        doc /* Lifecycle states of a syster-steel invocation. */

        state Initializing {
            doc /* Engine created; bindings being registered. */
        }
        state LoadingScript {
            doc /* Script file(s) being evaluated. */
        }
        state RunningREPL {
            doc /* Interactive REPL accepting user expressions. */
        }
        state RunningScript {
            doc /* Batch script executing. */
        }
        state Done {
            doc /* Script or REPL session completed. */
        }
    }

} // end package SysterSteelPipeline
