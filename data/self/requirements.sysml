// requirements.sysml — System requirements for syster-steel

package SysterSteelRequirements {

    requirement def EmbedSteelVM {
        doc /* The tool shall embed a Steel Scheme bytecode VM as its
               extension language. */
        attribute id : String = "REQ-001";
    }

    requirement def ParseSysmlModels {
        doc /* The tool shall parse SysML v2 source files using syster-base
               and expose the HIR symbol tree to Steel scripts. */
        attribute id : String = "REQ-002";
    }

    requirement def GeneratePlantUML {
        doc /* Steel scripts shall be able to generate PlantUML diagram source
               for BDD, IBD, state machine, action flow, requirement,
               sequence, use case, viewpoints, and package diagram types. */
        attribute id : String = "REQ-003";
    }

    requirement def RenderHeadless {
        doc /* plantuml rendering shall operate without a display server,
               using JAVA_TOOL_OPTIONS=-Djava.awt.headless=true. */
        attribute id : String = "REQ-004";
    }

    requirement def HandlebarsTemplating {
        doc /* PlantUML source structure shall be defined by Handlebars templates,
               allowing diagram styling changes without recompiling. */
        attribute id : String = "REQ-005";
    }

    requirement def ProvideREPL {
        doc /* The tool shall provide an interactive REPL with line editing
               and persistent history. */
        attribute id : String = "REQ-006";
    }

    requirement def ProvideScriptRunner {
        doc /* The tool shall accept a Steel script file on the command line
               and execute it non-interactively. */
        attribute id : String = "REQ-007";
    }

    requirement def SupportLoadPath {
        doc /* The tool shall support -L <dir> flags to add directories to
               the Steel module load path. */
        attribute id : String = "REQ-008";
    }

    requirement def CondaPackaging {
        doc /* The tool and its Scheme library shall be distributable as
               conda packages via meso-forge. */
        attribute id : String = "REQ-009";
    }

    requirement def SysterBaseBindings {
        doc /* syster-base types and accessors shall be registered with the
               Engine so Steel scripts can call hir-symbol/* and hir-rel/*
               functions without additional setup. */
        attribute id : String = "REQ-010";
    }

    requirement def SystemRequirements {
        doc /* Top-level grouping of all syster-steel requirements. */
        attribute id : String = "REQ-000";

        requirement r001 : EmbedSteelVM;
        requirement r002 : ParseSysmlModels;
        requirement r003 : GeneratePlantUML;
        requirement r004 : RenderHeadless;
        requirement r005 : HandlebarsTemplating;
        requirement r006 : ProvideREPL;
        requirement r007 : ProvideScriptRunner;
        requirement r008 : SupportLoadPath;
        requirement r009 : CondaPackaging;
        requirement r010 : SysterBaseBindings;
    }

} // end package SysterSteelRequirements
