// exp-003.sysml — EXP-003: Forest terrain with GPS-denied navigation challenge

package WorkflowModel {
    package CampaignAlpha {

        part exp3 : Experiment {
            attribute experimentId = "EXP-003";
            attribute description  = "Forest terrain with GPS-denied navigation challenge.";
            attribute status       = SimulationStatus::Pending;

            part environment : SimulatedEnvironment {
                attribute terrain      = TerrainKind::Forest;
                attribute timeStep     = 0.1;
                attribute windSpeedMps = 5.0;
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

            part gpsDeniedChallenge : SimulatedChallenge {
                attribute kind            = ChallengeKind::GPSDenied;
                attribute severity        = 1.0;
                attribute activationTime  = 0.0;
                attribute durationSeconds = 3600.0;
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

            part scout3 : ScoutVehicle {
                attribute vehicleId     = "SCOUT-003";
                attribute role          = VehicleRole::Scout;
                attribute maxSpeedMps   = 8.0;
                attribute searchPattern = SearchPatternKind::Spiral;
                attribute initialPosition : GeoCoordinate {
                    attribute latitude  = 35.025;
                    attribute longitude = -85.975;
                    attribute altitude  = 0.0;
                }
                part navigation = CampaignAlpha::degradedNav;
                part sensor     = CampaignAlpha::longRangeSensor;
                part comms      = CampaignAlpha::meshComms;
                part plan : SearchWaypointPlan {
                    attribute searchPattern         = SearchPatternKind::Spiral;
                    attribute coverageTarget        = 0.75;
                    attribute updateIntervalSeconds = 45.0;
                    attribute totalDistance         = 10000.0;
                    attribute estimatedDuration     = 1500.0;
                }
            }

            part patrol3 : PatrolVehicle {
                attribute vehicleId       = "PATROL-003";
                attribute role            = VehicleRole::Patrol;
                attribute maxSpeedMps     = 8.0;
                attribute patrolLoopCount = 2;
                attribute initialPosition : GeoCoordinate {
                    attribute latitude  = 35.010;
                    attribute longitude = -85.960;
                    attribute altitude  = 0.0;
                }
                part navigation = CampaignAlpha::degradedNav;
                part sensor     = CampaignAlpha::shortRangeSensor;
                part comms      = CampaignAlpha::meshComms;
                part plan : FixedWaypointPlan {
                    attribute missionObjective  = "Forest corridor patrol.";
                    attribute totalDistance     = 5000.0;
                    attribute estimatedDuration = 800.0;
                    part wp1 : Waypoint {
                        attribute sequenceIndex = 1;
                        attribute dwellTime     = 15.0;
                        attribute position : GeoCoordinate {
                            attribute latitude  = 35.010;
                            attribute longitude = -85.990;
                            attribute altitude  = 0.0;
                        }
                    }
                    part wp2 : Waypoint {
                        attribute sequenceIndex = 2;
                        attribute dwellTime     = 15.0;
                        attribute position : GeoCoordinate {
                            attribute latitude  = 35.040;
                            attribute longitude = -85.960;
                            attribute altitude  = 0.0;
                        }
                    }
                }
            }

            part evader3a : EvaderVehicle {
                attribute vehicleId              = "EVADER-003A";
                attribute role                   = VehicleRole::Evader;
                attribute maxSpeedMps            = 10.0;
                attribute evasionThresholdMeters = 300.0;
                attribute replanIntervalSeconds  = 20.0;
                attribute initialPosition : GeoCoordinate {
                    attribute latitude  = 35.015;
                    attribute longitude = -85.985;
                    attribute altitude  = 0.0;
                }
                part navigation = CampaignAlpha::degradedNav;
                part sensor     = CampaignAlpha::shortRangeSensor;
                part comms      = CampaignAlpha::jammableComms;
                part plan : SearchWaypointPlan {
                    attribute searchPattern         = SearchPatternKind::RandomWalk;
                    attribute coverageTarget        = 0.0;
                    attribute updateIntervalSeconds = 20.0;
                    attribute totalDistance         = 0.0;
                    attribute estimatedDuration     = 0.0;
                }
            }

            part evader3b : EvaderVehicle {
                attribute vehicleId              = "EVADER-003B";
                attribute role                   = VehicleRole::Evader;
                attribute maxSpeedMps            = 10.0;
                attribute evasionThresholdMeters = 300.0;
                attribute replanIntervalSeconds  = 20.0;
                attribute initialPosition : GeoCoordinate {
                    attribute latitude  = 35.035;
                    attribute longitude = -85.965;
                    attribute altitude  = 0.0;
                }
                part navigation = CampaignAlpha::degradedNav;
                part sensor     = CampaignAlpha::shortRangeSensor;
                part comms      = CampaignAlpha::jammableComms;
                part plan : SearchWaypointPlan {
                    attribute searchPattern         = SearchPatternKind::RandomWalk;
                    attribute coverageTarget        = 0.0;
                    attribute updateIntervalSeconds = 20.0;
                    attribute totalDistance         = 0.0;
                    attribute estimatedDuration     = 0.0;
                }
            }

            part metrics : ExperimentMetrics;
        }

    } // end package CampaignAlpha
} // end package WorkflowModel
