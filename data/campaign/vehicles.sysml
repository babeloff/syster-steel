// vehicles.sysml — Simulated vehicle part definitions

package WorkflowModel {

    part def SimulatedVehicle {
        attribute vehicleId       : String;
        attribute role            : VehicleRole;
        attribute maxSpeedMps     : Real;
        attribute initialPosition : GeoCoordinate;

        part navigation : NavigationSystem;
        part sensor     : TrackingSensor;
        part comms      : CommunicationModule;
        part plan       : WaypointPlan;
    }

    part def ScoutVehicle :> SimulatedVehicle {
        doc /* A vehicle whose primary mission is to search for and locate
               other vehicles using a dynamic, coverage-driven waypoint plan. */
        attribute searchPattern : SearchPatternKind;
        redefines plan : SearchWaypointPlan;
    }

    part def PatrolVehicle :> SimulatedVehicle {
        doc /* A vehicle that follows a predetermined patrol route.
               It may detect other vehicles as a secondary objective. */
        attribute patrolLoopCount : Integer;
        redefines plan : FixedWaypointPlan;
    }

    part def EvaderVehicle :> SimulatedVehicle {
        doc /* A vehicle whose primary goal is to avoid detection by Scout
               and Patrol vehicles.
               It uses a reactive waypoint plan updated to maintain distance. */
        attribute evasionThresholdMeters : Real;
        attribute replanIntervalSeconds  : Real;
        redefines plan : SearchWaypointPlan;
    }

} // end package WorkflowModel
