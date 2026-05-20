// exp-002.sysml — EXP-002: Urban terrain with active communication jamming

package WorkflowModel {
    package CampaignAlpha {

        part exp2 : Experiment {
            attribute experimentId = "EXP-002";
            attribute description  = "Urban terrain with active communication jamming.";
            attribute status       = SimulationStatus::Pending;

            part environment : SimulatedEnvironment {
                attribute terrain      = TerrainKind::Urban;
                attribute timeStep     = 0.1;
                attribute windSpeedMps = 1.5;
                attribute bounds : BoundingBox {
                    attribute minCoord : GeoCoordinate {
                        attribute latitude  = 35.000;
                        attribute longitude = -86.000;
                        attribute altitude  = 0.0;
                    }
                    attribute maxCoord : GeoCoordinate {
                        attribute latitude  = 35.050;
                        attribute longitude = -85.950;
                        attribute altitude  = 0.0;
                    }
                }
            }

            part jammingChallenge : SimulatedChallenge {
                attribute kind            = ChallengeKind::CommunicationJamming;
                attribute severity        = 0.8;
                attribute activationTime  = 120.0;
                attribute durationSeconds = 600.0;
                attribute affectedArea : BoundingBox {
                    attribute minCoord : GeoCoordinate {
                        attribute latitude  = 35.010;
                        attribute longitude = -85.990;
                        attribute altitude  = 0.0;
                    }
                    attribute maxCoord : GeoCoordinate {
                        attribute latitude  = 35.040;
                        attribute longitude = -85.960;
                        attribute altitude  = 0.0;
                    }
                }
            }

            part scout2a : ScoutVehicle {
                attribute vehicleId     = "SCOUT-002A";
                attribute role          = VehicleRole::Scout;
                attribute maxSpeedMps   = 10.0;
                attribute searchPattern = SearchPatternKind::SectorSweep;
                attribute initialPosition : GeoCoordinate {
                    attribute latitude  = 35.005;
                    attribute longitude = -85.998;
                    attribute altitude  = 0.0;
                }
                part navigation = CampaignAlpha::highAccuracyNav;
                part sensor     = CampaignAlpha::shortRangeSensor;
                part comms      = CampaignAlpha::jammableComms;
                part plan : SearchWaypointPlan {
                    attribute searchPattern         = SearchPatternKind::SectorSweep;
                    attribute coverageTarget        = 0.85;
                    attribute updateIntervalSeconds = 20.0;
                    attribute totalDistance         = 6000.0;
                    attribute estimatedDuration     = 720.0;
                }
            }

            part scout2b : ScoutVehicle {
                attribute vehicleId     = "SCOUT-002B";
                attribute role          = VehicleRole::Scout;
                attribute maxSpeedMps   = 10.0;
                attribute searchPattern = SearchPatternKind::SectorSweep;
                attribute initialPosition : GeoCoordinate {
                    attribute latitude  = 35.045;
                    attribute longitude = -85.952;
                    attribute altitude  = 0.0;
                }
                part navigation = CampaignAlpha::highAccuracyNav;
                part sensor     = CampaignAlpha::shortRangeSensor;
                part comms      = CampaignAlpha::jammableComms;
                part plan : SearchWaypointPlan {
                    attribute searchPattern         = SearchPatternKind::SectorSweep;
                    attribute coverageTarget        = 0.85;
                    attribute updateIntervalSeconds = 20.0;
                    attribute totalDistance         = 6000.0;
                    attribute estimatedDuration     = 720.0;
                }
            }

            part evader2 : EvaderVehicle {
                attribute vehicleId              = "EVADER-002";
                attribute role                   = VehicleRole::Evader;
                attribute maxSpeedMps            = 12.0;
                attribute evasionThresholdMeters = 150.0;
                attribute replanIntervalSeconds  = 10.0;
                attribute initialPosition : GeoCoordinate {
                    attribute latitude  = 35.025;
                    attribute longitude = -85.975;
                    attribute altitude  = 0.0;
                }
                part navigation = CampaignAlpha::degradedNav;
                part sensor     = CampaignAlpha::shortRangeSensor;
                part comms      = CampaignAlpha::jammableComms;
                part plan : SearchWaypointPlan {
                    attribute searchPattern         = SearchPatternKind::RandomWalk;
                    attribute coverageTarget        = 0.0;
                    attribute updateIntervalSeconds = 10.0;
                    attribute totalDistance         = 0.0;
                    attribute estimatedDuration     = 0.0;
                }
            }

            part metrics : ExperimentMetrics;
        }

    } // end package CampaignAlpha
} // end package WorkflowModel
