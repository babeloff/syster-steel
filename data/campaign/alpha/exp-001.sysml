// exp-001.sysml — EXP-001: Baseline open-terrain search and track (no challenges)

package CampaignAlpha {

    part exp1 : Experiment {
        attribute experimentId = "EXP-001";
        attribute description  = "Baseline open-terrain search and track — no challenges.";
        attribute status       = SimulationStatus::Pending;

        part environment : SimulatedEnvironment {
            attribute terrain      = TerrainKind::Open;
            attribute timeStep     = 0.1;
            attribute windSpeedMps = 3.0;
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

        part scout1 : VehicleModel::ScoutVehicle {
            attribute vehicleId     = "SCOUT-001";
            attribute role          = VehicleRole::Scout;
            attribute maxSpeedMps   = 15.0;
            attribute searchPattern = SearchPatternKind::LawnMower;
            attribute initialPosition : GeoCoordinate {
                attribute latitude  = 35.005;
                attribute longitude = -85.995;
                attribute altitude  = 0.0;
            }
            part navigation = CampaignAlpha::highAccuracyNav;
            part sensor     = CampaignAlpha::longRangeSensor;
            part comms      = CampaignAlpha::meshComms;
            part plan : SearchWaypointPlan {
                attribute searchPattern         = SearchPatternKind::LawnMower;
                attribute coverageTarget        = 0.90;
                attribute updateIntervalSeconds = 30.0;
                attribute totalDistance         = 12000.0;
                attribute estimatedDuration     = 900.0;
            }
        }

        part patrol1 : VehicleModel::PatrolVehicle {
            attribute vehicleId       = "PATROL-001";
            attribute role            = VehicleRole::Patrol;
            attribute maxSpeedMps     = 12.0;
            attribute patrolLoopCount = 3;
            attribute initialPosition : GeoCoordinate {
                attribute latitude  = 35.010;
                attribute longitude = -85.990;
                attribute altitude  = 0.0;
            }
            part navigation = CampaignAlpha::highAccuracyNav;
            part sensor     = CampaignAlpha::shortRangeSensor;
            part comms      = CampaignAlpha::meshComms;
            part plan : FixedWaypointPlan {
                attribute missionObjective  = "Perimeter patrol of experiment area.";
                attribute totalDistance     = 8000.0;
                attribute estimatedDuration = 720.0;
                part wp1 : Waypoint {
                    attribute sequenceIndex = 1;
                    attribute dwellTime     = 10.0;
                    attribute position : GeoCoordinate {
                        attribute latitude  = 35.005;
                        attribute longitude = -85.955;
                        attribute altitude  = 0.0;
                    }
                }
                part wp2 : Waypoint {
                    attribute sequenceIndex = 2;
                    attribute dwellTime     = 10.0;
                    attribute position : GeoCoordinate {
                        attribute latitude  = 35.045;
                        attribute longitude = -85.955;
                        attribute altitude  = 0.0;
                    }
                }
                part wp3 : Waypoint {
                    attribute sequenceIndex = 3;
                    attribute dwellTime     = 10.0;
                    attribute position : GeoCoordinate {
                        attribute latitude  = 35.045;
                        attribute longitude = -85.995;
                        attribute altitude  = 0.0;
                    }
                }
                part wp4 : Waypoint {
                    attribute sequenceIndex = 4;
                    attribute dwellTime     = 10.0;
                    attribute position : GeoCoordinate {
                        attribute latitude  = 35.005;
                        attribute longitude = -85.995;
                        attribute altitude  = 0.0;
                    }
                }
            }
        }

        part evader1 : VehicleModel::EvaderVehicle {
            attribute vehicleId              = "EVADER-001";
            attribute role                   = VehicleRole::Evader;
            attribute maxSpeedMps            = 18.0;
            attribute evasionThresholdMeters = 200.0;
            attribute replanIntervalSeconds  = 15.0;
            attribute initialPosition : GeoCoordinate {
                attribute latitude  = 35.025;
                attribute longitude = -85.975;
                attribute altitude  = 0.0;
            }
            part navigation = CampaignAlpha::highAccuracyNav;
            part sensor     = CampaignAlpha::shortRangeSensor;
            part comms      = CampaignAlpha::jammableComms;
            part plan : SearchWaypointPlan {
                attribute searchPattern         = SearchPatternKind::RandomWalk;
                attribute coverageTarget        = 0.0;
                attribute updateIntervalSeconds = 15.0;
                attribute totalDistance         = 0.0;
                attribute estimatedDuration     = 0.0;
            }
        }

        part metrics : ExperimentMetrics;
    }

} // end package CampaignAlpha
