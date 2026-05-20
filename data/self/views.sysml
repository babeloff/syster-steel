// views.sysml — Viewpoints and view definitions for the syster-steel project

package SysterSteelViews {

    viewpoint def StructuralViewpoint {
        doc /* Concerns the decomposition of the syster-steel tool into its
               Rust and Scheme subsystems and their interconnections. */
        attribute stakeholder : String = "developer";
    }

    viewpoint def BehavioralViewpoint {
        doc /* Concerns the runtime lifecycle and diagram generation pipeline
               behaviors. */
        attribute stakeholder : String = "developer";
    }

    viewpoint def RequirementsViewpoint {
        doc /* Concerns system requirements and their allocation to
               tool subsystems. */
        attribute stakeholder : String = "architect";
    }

    viewpoint def UserViewpoint {
        doc /* Concerns the interactions between users (developers / script
               authors) and the tool. */
        attribute stakeholder : String = "user";
    }

    view def StructuralView {
        doc /* Shows the SysterSteelTool block decomposition: RustEngine,
               SteelVM, SchemeLibrary, HandlebarsEngine, and their ports. */

        rendering BDDRendering;
    }

    view def PipelineView {
        doc /* Shows the action flow of the GenerateDiagramPipeline: from
               ParseSysmlFile through to RenderDiagram. */

        rendering ActionFlowRendering;
    }

    view def LifecycleView {
        doc /* Shows the ToolLifecycle state machine. */

        rendering StateMachineRendering;
    }

    view def RequirementsView {
        doc /* Shows the SystemRequirements group and all requirement elements
               with their containment and derivation relationships. */

        rendering RequirementRendering;
    }

    view def UserView {
        doc /* Shows use cases, actors, and system boundary. */

        rendering UseCaseRendering;
    }

    rendering def BDDRendering {
        doc /* Renders structural decomposition as a Block Definition Diagram. */
    }

    rendering def ActionFlowRendering {
        doc /* Renders behavioral pipelines as an action flow diagram. */
    }

    rendering def StateMachineRendering {
        doc /* Renders lifecycle states as a state machine diagram. */
    }

    rendering def RequirementRendering {
        doc /* Renders requirements and their relationships as a requirement
               diagram. */
    }

    rendering def UseCaseRendering {
        doc /* Renders actors, use cases, and system boundary as a use case
               diagram. */
    }

} // end package SysterSteelViews
