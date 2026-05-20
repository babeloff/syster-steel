// views.sysml — Viewpoints and views for the WorkflowModel campaign

package WorkflowModel {

    viewpoint def SystemArchitectViewpoint {
        doc /* Audience: system architects.
               Concern: structural decomposition of the campaign. */
    }

    viewpoint def SimulationEngineerViewpoint {
        doc /* Audience: simulation engineers.
               Concern: action flows, state machines, and timing. */
    }

    viewpoint def RequirementsAnalystViewpoint {
        doc /* Audience: requirements analysts.
               Concern: requirements and their satisfaction. */
    }

    view def CampaignStructureView {
        doc /* Shows the structural hierarchy of the campaign, experiments,
               vehicles, environments, and challenges. */
        expose WorkflowModel::Campaign;
        expose WorkflowModel::Experiment;
        expose WorkflowModel::SimulatedVehicle;
        expose WorkflowModel::ScoutVehicle;
        expose WorkflowModel::PatrolVehicle;
        expose WorkflowModel::EvaderVehicle;
        expose WorkflowModel::SimulatedEnvironment;
        expose WorkflowModel::SimulatedChallenge;
    }

    view def VehicleBehaviorView {
        doc /* Shows the action definitions and state machines governing
               vehicle behavior during a simulation run. */
        expose WorkflowModel::ScoutMission;
        expose WorkflowModel::PatrolMission;
        expose WorkflowModel::EvaderMission;
        expose WorkflowModel::VehicleOperationalState;
        expose WorkflowModel::NavigateToWaypoint;
        expose WorkflowModel::ScanForTargets;
        expose WorkflowModel::UpdateSearchPlan;
        expose WorkflowModel::EvasiveReplan;
    }

    view def ExperimentFlowView {
        doc /* Shows the end-to-end action flow of a single experiment
               from initialization through metrics collection. */
        expose WorkflowModel::RunExperiment;
        expose WorkflowModel::InitializeEnvironment;
        expose WorkflowModel::ExecuteVehicleMissions;
        expose WorkflowModel::CollectMetrics;
        expose WorkflowModel::FinalizeExperiment;
        expose WorkflowModel::ExperimentLifecycleState;
    }

    view def RequirementsView {
        doc /* Shows all requirements and their satisfaction relationships. */
        expose WorkflowModel::SearchCoverageRequirement;
        expose WorkflowModel::TrackingAccuracyRequirement;
        expose WorkflowModel::CommunicationRequirement;
        expose WorkflowModel::SafetyRequirement;
        expose WorkflowModel::ExperimentCompletionRequirement;
    }

} // end package WorkflowModel
