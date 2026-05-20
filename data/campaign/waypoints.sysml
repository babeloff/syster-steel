// waypoints.sysml — Waypoint and waypoint-plan part definitions

part def Waypoint {
    attribute position      : GeoCoordinate;
    attribute dwellTime     : Real;
    attribute sequenceIndex : Integer;
}

part def WaypointPlan {
    attribute totalDistance      : Real;
    attribute estimatedDuration  : Real;
    part waypoints : Waypoint[1..*];
}

part def FixedWaypointPlan :> WaypointPlan {
    doc /* A predetermined sequence of waypoints that does not change
           during the simulation run. */
    attribute missionObjective : String;
}

part def SearchWaypointPlan :> WaypointPlan {
    doc /* A dynamically updated waypoint plan driven by search coverage
           goals and detected target information. */
    attribute searchPattern         : SearchPatternKind;
    attribute coverageTarget        : Real;
    attribute updateIntervalSeconds : Real;
}

