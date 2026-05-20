// exp-004.sysml — EXP-004: Mixed terrain with dense obstacles and adversarial evaders

package CampaignAlpha {

    part exp4 : Experiment {
        attribute experimentId = "EXP-004";
        attribute description  = "Mixed terrain with dense obstacles and adversarial evaders.";
        attribute status       = SimulationStatus::Pending;

        part environment : SimulatedEnvironment {
            attribute terrain      = TerrainKind::Mixed;
            attribute timeStep     = 0.05;
            attribute windSpeedMps = 7.0;
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

        part obstacleChallenge : SimulatedChallenge {
            attribute kind            = ChallengeKind::ObstacleDense;
            attribute severity        = 0.6;
            attribute activationTime  = 0.0;
            attribute durationSeconds = 3600.0;
            attribute affectedArea : BoundingBox {
                attribute minCoord : GeoCoordinate {
                    attribute latitude  = 35.015;
                    attribute longitude = -85.985;
                    attribute altitude  = 0.0;
                }
                attribute maxCoord : GeoCoordinate {
                    attribute latitude  = 35.035;
                    attribute longitude = -85.965;
                    attribute altitude  = 0.0;
                }
            }
        }

        part adversarialChallenge : SimulatedChallenge {
            attribute kind            = ChallengeKind::AdversarialEvasion;
            attribute severity        = 0.9;
            attribute activationTime  = 60.0;
            attribute durationSeconds = 2400.0;
            attribute affectedArea : BoundingBox {
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

        part scout4a : VehicleModel::ScoutVehicle {
            attribute vehicleId     = "SCOUT-004A";
            attribute role          = VehicleRole::Scout;
            attribute maxSpeedMps   = 12.0;
            attribute searchPattern = SearchPatternKind::LawnMower;
            attribute initialPosition : GeoCoordinate {
                attribute latitude  = 35.002;
                attribute longitude = -85.998;
                attribute altitude  = 0.0;
            }
            part navigation = CampaignAlpha::highAccuracyNav;
            part sensor     = CampaignAlpha::longRangeSensor;
            part comms      = CampaignAlpha::meshComms;
            part plan : SearchWaypointPlan {
                attribute searchPattern         = SearchPatternKind::LawnMower;
                attribute coverageTarget        = 0.80;
                attribute updateIntervalSeconds = 25.0;
                attribute totalDistance         = 9000.0;
                attribute estimatedDuration     = 900.0;
            }
        }

        part scout4b : VehicleModel::ScoutVehicle {
            attribute vehicleId     = "SCOUT-004B";
            attribute role          = VehicleRole::Scout;
            attribute maxSpeedMps   = 12.0;
            attribute searchPattern = SearchPatternKind::SectorSweep;
            attribute initialPosition : GeoCoordinate {
                attribute latitude  = 35.048;
                attribute longitude = -85.952;
                attribute altitude  = 0.0;
            }
            part navigation = CampaignAlpha::highAccuracyNav;
            part sensor     = CampaignAlpha::longRangeSensor;
            part comms      = CampaignAlpha::meshComms;
            part plan : SearchWaypointPlan {
                attribute searchPattern         = SearchPatternKind::SectorSweep;
                attribute coverageTarget        = 0.80;
                attribute updateIntervalSeconds = 25.0;
                attribute totalDistance         = 9000.0;
                attribute estimatedDuration     = 900.0;
            }
        }

        part patrol4 : VehicleModel::PatrolVehicle {
            attribute vehicleId       = "PATROL-004";
            attribute role            = VehicleRole::Patrol;
            attribute maxSpeedMps     = 10.0;
            attribute patrolLoopCount = 4;
            attribute initialPosition : GeoCoordinate {
                attribute latitude  = 35.025;
                attribute longitude = -86.000;
                attribute altitude  = 0.0;
            }
            part navigation = CampaignAlpha::highAccuracyNav;
            part sensor     = CampaignAlpha::longRangeSensor;
            part comms      = CampaignAlpha::meshComms;
            part plan : FixedWaypointPlan {
                attribute missionObjective  = "Central corridor patrol.";
                attribute totalDistance     = 10000.0;
                attribute estimatedDuration = 1200.0;
                part wp1 : Waypoint {
                    attribute sequenceIndex = 1;
                    attribute dwellTime     = 5.0;
                    attribute position : GeoCoordinate {
                        attribute latitude  = 35.025;
                        attribute longitude = -85.975;
                        attribute altitude  = 0.0;
                    }
                }
                part wp2 : Waypoint {
                    attribute sequenceIndex = 2;
                    attribute dwellTime     = 5.0;
                    attribute position : GeoCoordinate {
                        attribute latitude  = 35.025;
                        attribute longitude = -85.955;
                        attribute altitude  = 0.0;
                    }
                }
                part wp3 : Waypoint {
                    attribute sequenceIndex = 3;
                    attribute dwellTime     = 5.0;
                    attribute position : GeoCoordinate {
                        attribute latitude  = 35.025;
                        attribute longitude = -85.975;
                        attribute altitude  = 0.0;
                    }
                }
            }
        }

        part evader4a : VehicleModel::EvaderVehicle {
            attribute vehicleId              = "EVADER-004A";
            attribute role                   = VehicleRole::Evader;
            attribute maxSpeedMps            = 20.0;
            attribute evasionThresholdMeters = 250.0;
            attribute replanIntervalSeconds  = 8.0;
            attribute initialPosition : GeoCoordinate {
                attribute latitude  = 35.020;
                attribute longitude = -85.980;
                attribute altitude  = 0.0;
            }
            part navigation = CampaignAlpha::highAccuracyNav;
            part sensor     = CampaignAlpha::longRangeSensor;
            part comms      = CampaignAlpha::meshComms;
            part plan : SearchWaypointPlan {
                attribute searchPattern         = SearchPatternKind::RandomWalk;
                attribute coverageTarget        = 0.0;
                attribute updateIntervalSeconds = 8.0;
                attribute totalDistance         = 0.0;
                attribute estimatedDuration     = 0.0;
            }
        }

        part evader4b : VehicleModel::EvaderVehicle {
            attribute vehicleId              = "EVADER-004B";
            attribute role                   = VehicleRole::Evader;
            attribute maxSpeedMps            = 20.0;
            attribute evasionThresholdMeters = 250.0;
            attribute replanIntervalSeconds  = 8.0;
            attribute initialPosition : GeoCoordinate {
                attribute latitude  = 35.030;
                attribute longitude = -85.970;
                attribute altitude  = 0.0;
            }
            part navigation = CampaignAlpha::highAccuracyNav;
            part sensor     = CampaignAlpha::longRangeSensor;
            part comms      = CampaignAlpha::meshComms;
            part plan : SearchWaypointPlan {
                attribute searchPattern         = SearchPatternKind::RandomWalk;
                attribute coverageTarget        = 0.0;
                attribute updateIntervalSeconds = 8.0;
                attribute totalDistance         = 0.0;
                attribute estimatedDuration     = 0.0;
            }
        }

        part metrics : ExperimentMetrics;
    }

} // end package CampaignAlpha
