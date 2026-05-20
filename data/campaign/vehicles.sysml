// vehicles.sysml — Simulated vehicle part definitions

package VehicleModel {

    port def DrivePort;
    port def FuelPort;

    part def Engine {
        attribute power      : Real;
        attribute efficiency : Real;
        port fuelIn   : FuelPort;
        port driveOut : DrivePort;
    }

    part def Chassis {
        attribute weight : Real;
    }

    part def VehicleSystem {
        attribute vehicleId       : String;
        attribute role            : VehicleRole;
        attribute mass            : Real;
        attribute velocity        : Real;
        attribute maxSpeedMps     : Real;
        attribute initialPosition : GeoCoordinate;

        part engine     : Engine;
        part chassis    : Chassis;
        part navigation : NavigationSystem;
        part sensor     : TrackingSensor;
        part comms      : CommunicationModule;
        part plan       : WaypointPlan;
        port drivePort  : DrivePort;
    }

    part def ScoutVehicle :> VehicleSystem {
        doc /* A vehicle whose primary mission is to search for and locate
               other vehicles using a dynamic, coverage-driven waypoint plan. */
        attribute searchPattern : SearchPatternKind;
        redefines plan : SearchWaypointPlan;
    }

    part def PatrolVehicle :> VehicleSystem {
        doc /* A vehicle that follows a predetermined patrol route.
               It may detect other vehicles as a secondary objective. */
        attribute patrolLoopCount : Integer;
        redefines plan : FixedWaypointPlan;
    }

    part def EvaderVehicle :> VehicleSystem {
        doc /* A vehicle whose primary goal is to avoid detection by Scout
               and Patrol vehicles.
               It uses a reactive waypoint plan updated to maintain distance. */
        attribute evasionThresholdMeters : Real;
        attribute replanIntervalSeconds  : Real;
        redefines plan : SearchWaypointPlan;
    }

} // end package VehicleModel
