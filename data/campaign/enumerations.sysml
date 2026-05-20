// enumerations.sysml — Enumeration definitions for the WorkflowModel campaign

package WorkflowModel {

    enum def SearchPatternKind {
        Spiral;
        LawnMower;
        RandomWalk;
        SectorSweep;
    }

    enum def TerrainKind {
        Open;
        Urban;
        Forest;
        Mixed;
    }

    enum def ChallengeKind {
        GPSDenied;
        CommunicationJamming;
        VisibilityDegraded;
        ObstacleDense;
        AdversarialEvasion;
    }

    enum def VehicleRole {
        Scout;
        Patrol;
        Evader;
    }

    enum def SimulationStatus {
        Pending;
        Running;
        Completed;
        Failed;
    }

} // end package WorkflowModel
