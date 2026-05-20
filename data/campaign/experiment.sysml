// experiment.sysml — Experiment and Campaign part definitions

part def ExperimentMetrics {
    attribute detectionRate         : Real;
    attribute trackingAccuracy      : Real;
    attribute missionCompletionTime : Real;
    attribute coverageAchieved      : Real;
    attribute evaderSurvivalTime    : Real;
}

part def Experiment {
    attribute experimentId : String;
    attribute description  : String;
    attribute timeLimit    : TimeInterval;
    attribute status       : SimulationStatus;

    part environment : SimulatedEnvironment;
    part vehicles    : VehicleModel::VehicleSystem[2..*];
    part challenges  : SimulatedChallenge[0..*];
    part metrics     : ExperimentMetrics;
}

part def Campaign {
    attribute campaignId : String;
    attribute objective  : String;
    attribute version    : String;

    part experiments : Experiment[1..*];
}

