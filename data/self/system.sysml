// system.sysml — Structural decomposition of the syster-steel tool

package SysterSteel {

    part def SysterSteelTool {
        doc /* The syster-steel command-line tool: embeds a Steel Scheme VM,
               registers SysML v2 and Handlebars bindings, and drives
               scripts from the command line. */
        attribute version    : String;
        attribute cliFlags   : String;

        part engine    : RustEngine;
        part vm        : SteelVM;
        part schemeLib : SchemeLibrary;
        part hbsEngine : HandlebarsEngine;

        port scriptIn  : ScriptPort;
        port modelIn   : ModelPort;
        port pumlOut   : PumlPort;
    }

    part def RustEngine {
        doc /* The Rust application layer: parses CLI args, wires the Engine,
               and delegates to REPL or script-runner. */
        attribute crate : String;

        part cli  : CliParser;
        part repl : ReplRunner;
        part run  : ScriptRunner;
        part bridge : SysterBridge;
        part hbs    : HbsBridge;
        part sys    : SysBridge;

        port scriptIn : ScriptPort;
    }

    part def SteelVM {
        doc /* The steel-core bytecode VM — the embedded Scheme engine. */
        attribute crate   : String;
        attribute version : String;

        port evalIn  : ScriptPort;
        port valueOut : ValuePort;
    }

    part def SchemeLibrary {
        doc /* Steel Scheme libraries in script/ providing diagram generators. */
        attribute loadPath : String;

        part util        : SysmlUtil;
        part plantumlLib : PlantumlLib;
        part actionLib   : ActionLib;
        part reqLib      : RequirementLib;
        part seqLib      : SequenceLib;
        part ucLib       : UseCaseLib;
    }

    part def HandlebarsEngine {
        doc /* The handlebars-rust template engine: renders PlantUML source
               from .hbs templates and Steel data hashes. */
        attribute crate   : String;
        attribute version : String;

        port templateIn : TemplatePort;
        port dataIn     : DataPort;
        port pumlOut    : PumlPort;
    }

    part def CliParser {
        attribute crate : String;
    }

    part def ReplRunner {
        attribute historyFile : String;
        attribute crate       : String;
    }

    part def ScriptRunner;

    part def SysterBridge {
        doc /* src/bridge.rs — registers syster-base types with the Engine. */
    }

    part def HbsBridge {
        doc /* src/hbs.rs — registers hbs/* Handlebars bindings with the Engine. */
    }

    part def SysBridge {
        doc /* src/sys.rs — registers system and glob-list with the Engine. */
    }

    part def SysmlUtil {
        attribute file : String;
    }

    part def PlantumlLib {
        attribute file : String;
    }

    part def ActionLib {
        attribute file : String;
    }

    part def RequirementLib {
        attribute file : String;
    }

    part def SequenceLib {
        attribute file : String;
    }

    part def UseCaseLib {
        attribute file : String;
    }

    port def ScriptPort;
    port def ModelPort;
    port def PumlPort;
    port def ValuePort;
    port def TemplatePort;
    port def DataPort;

} // end package SysterSteel
