// states.sysml — State machine definitions for vehicle and experiment lifecycle

package WorkflowModel {

    state def VehicleOperationalState {
        state Idle;
        state Navigating;
        state Scanning;
        state Reporting;
        state Evading;
        state MissionComplete;

        transition from Idle         to Navigating      [ waypointAvailable ];
        transition from Navigating   to Scanning        [ arrivedAtWaypoint ];
        transition from Scanning     to Reporting       [ contactsDetected ];
        transition from Scanning     to Navigating      [ noContactsDetected ];
        transition from Reporting    to Navigating      [ reportSent ];
        transition from Navigating   to Evading         [ threatDetected ];
        transition from Evading      to Navigating      [ evasivePlanReady ];
        transition from Navigating   to MissionComplete [ missionTimeExpired ];
        transition from Scanning     to MissionComplete [ missionTimeExpired ];
    }

    state def ExperimentLifecycleState {
        state Created;
        state Initializing;
        state Running;
        state Collecting;
        state Completed;
        state Failed;

        transition from Created      to Initializing [ experimentStarted ];
        transition from Initializing to Running      [ environmentReady ];
        transition from Initializing to Failed       [ initializationError ];
        transition from Running      to Collecting   [ allVehiclesFinished ];
        transition from Running      to Failed       [ criticalError ];
        transition from Collecting   to Completed    [ metricsCollected ];
    }

} // end package WorkflowModel
