// actions.sysml — Action definitions for vehicle behaviors and experiment flow

action def NavigateToWaypoint {
    in  currentPosition : GeoCoordinate;
    in  targetWaypoint  : Waypoint;
    out arrivedPosition : GeoCoordinate;
    out elapsedTime     : Real;
}

action def ScanForTargets {
    in  sensorConfig     : TrackingSensor;
    in  ownPosition      : GeoCoordinate;
    out detectedCount    : Integer;
    out targetPositions  : GeoCoordinate[0..*];
}

action def UpdateSearchPlan {
    in  detectedTargets : GeoCoordinate[0..*];
    in  currentPlan     : SearchWaypointPlan;
    out updatedPlan     : SearchWaypointPlan;
}

action def TransmitContactReport {
    in  targets     : GeoCoordinate[0..*];
    in  commsModule : CommunicationModule;
    out reportSent  : Boolean;
}

action def EvasiveReplan {
    in  threatPositions : GeoCoordinate[0..*];
    in  currentPlan     : SearchWaypointPlan;
    in  threshold       : Real;
    out evasivePlan     : SearchWaypointPlan;
}

action def ScoutMission {
    doc /* Full scout vehicle mission cycle: navigate, scan, update plan,
           report contacts, and repeat until mission time expires. */
    in  vehicle   : VehicleModel::ScoutVehicle;
    in  timeLimit : Real;
    out coverage  : Real;

    first action nav    : NavigateToWaypoint;
    then  action scan   : ScanForTargets;
    then  action update : UpdateSearchPlan;
    then  action report : TransmitContactReport;
}

action def PatrolMission {
    doc /* Patrol vehicle mission: navigate each fixed waypoint in sequence,
           scanning for other vehicles at each stop. */
    in  vehicle      : VehicleModel::PatrolVehicle;
    in  timeLimit    : Real;
    out contactsMade : Integer;

    first action nav    : NavigateToWaypoint;
    then  action scan   : ScanForTargets;
    then  action report : TransmitContactReport;
}

action def EvaderMission {
    doc /* Evader vehicle mission: monitor for scout/patrol proximity,
           replan when threatened, navigate away. */
    in  vehicle      : VehicleModel::EvaderVehicle;
    in  threatData   : GeoCoordinate[0..*];
    out survivalTime : Real;

    first action scan   : ScanForTargets;
    then  action replan : EvasiveReplan;
    then  action nav    : NavigateToWaypoint;
}

action def InitializeEnvironment {
    in  env        : SimulatedEnvironment;
    in  challenges : SimulatedChallenge[0..*];
    out ready      : Boolean;
}

action def ExecuteVehicleMissions {
    in  vehicles  : VehicleModel::VehicleSystem[2..*];
    in  timeLimit : Real;
}

action def CollectMetrics {
    in  experiment : Experiment;
    out metrics    : ExperimentMetrics;
}

action def FinalizeExperiment {
    in  metrics : ExperimentMetrics;
    out report  : String;
}

action def RunExperiment {
    doc /* Orchestrates a single experiment: initialize the environment,
           launch all vehicle missions concurrently, collect metrics,
           and finalize results. */
    in  experiment : Experiment;
    out metrics    : ExperimentMetrics;

    first action init     : InitializeEnvironment;
    then  action execute  : ExecuteVehicleMissions;
    then  action collect  : CollectMetrics;
    then  action finalize : FinalizeExperiment;
}

