// environment.sysml — Simulated environment and challenge part definitions

package WorkflowModel {

    part def SimulatedEnvironment {
        attribute terrain      : TerrainKind;
        attribute bounds       : BoundingBox;
        attribute timeStep     : Real;
        attribute windSpeedMps : Real;
    }

    part def SimulatedChallenge {
        attribute kind            : ChallengeKind;
        attribute severity        : Real;
        attribute activationTime  : Real;
        attribute durationSeconds : Real;
        attribute affectedArea    : BoundingBox;
    }

} // end package WorkflowModel
