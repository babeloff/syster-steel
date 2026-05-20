// shared.sysml — Shared subsystem configurations reused across CampaignAlpha experiments

package WorkflowModel {
    package CampaignAlpha {

        part highAccuracyNav : NavigationSystem {
            attribute positionAccuracyMeters = 1.5;
            attribute headingAccuracyDegrees = 0.5;
            attribute useGPS   = true;
            attribute useIMU   = true;
            attribute useLIDAR = false;
        }

        part degradedNav : NavigationSystem {
            attribute positionAccuracyMeters = 8.0;
            attribute headingAccuracyDegrees = 2.0;
            attribute useGPS   = false;
            attribute useIMU   = true;
            attribute useLIDAR = true;
        }

        part longRangeSensor : TrackingSensor {
            attribute detectionRangeMeters = 500.0;
            attribute fieldOfViewDegrees   = 60.0;
            attribute updateRateHz         = 2.0;
            attribute noiseSigma           = 2.5;
        }

        part shortRangeSensor : TrackingSensor {
            attribute detectionRangeMeters = 150.0;
            attribute fieldOfViewDegrees   = 120.0;
            attribute updateRateHz         = 5.0;
            attribute noiseSigma           = 1.0;
        }

        part meshComms : CommunicationModule {
            attribute rangeMeters       = 1000.0;
            attribute bandwidthKbps     = 256.0;
            attribute encryptionEnabled = true;
        }

        part jammableComms : CommunicationModule {
            attribute rangeMeters       = 500.0;
            attribute bandwidthKbps     = 64.0;
            attribute encryptionEnabled = false;
        }

    } // end package CampaignAlpha
} // end package WorkflowModel
