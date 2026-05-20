// views.sysml — Viewpoints and views for the campaign model

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
    expose Campaign;
    expose Experiment;
    expose VehicleModel::VehicleSystem;
    expose VehicleModel::ScoutVehicle;
    expose VehicleModel::PatrolVehicle;
    expose VehicleModel::EvaderVehicle;
    expose SimulatedEnvironment;
    expose SimulatedChallenge;
}

view def VehicleBehaviorView {
    doc /* Shows the action definitions and state machines governing
           vehicle behavior during a simulation run. */
    expose ScoutMission;
    expose PatrolMission;
    expose EvaderMission;
    expose VehicleOperationalState;
    expose NavigateToWaypoint;
    expose ScanForTargets;
    expose UpdateSearchPlan;
    expose EvasiveReplan;
}

view def ExperimentFlowView {
    doc /* Shows the end-to-end action flow of a single experiment
           from initialization through metrics collection. */
    expose RunExperiment;
    expose InitializeEnvironment;
    expose ExecuteVehicleMissions;
    expose CollectMetrics;
    expose FinalizeExperiment;
    expose ExperimentLifecycleState;
}

view def RequirementsView {
    doc /* Shows all requirements and their satisfaction relationships. */
    expose SearchCoverageRequirement;
    expose TrackingAccuracyRequirement;
    expose CommunicationRequirement;
    expose SafetyRequirement;
    expose ExperimentCompletionRequirement;
}

