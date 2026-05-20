// subsystems.sysml — Vehicle subsystem part definitions

part def TrackingSensor {
    attribute detectionRangeMeters : Real;
    attribute fieldOfViewDegrees   : Real;
    attribute updateRateHz         : Real;
    attribute noiseSigma           : Real;
}

part def NavigationSystem {
    attribute positionAccuracyMeters : Real;
    attribute headingAccuracyDegrees : Real;
    attribute useGPS   : Boolean;
    attribute useIMU   : Boolean;
    attribute useLIDAR : Boolean;
}

part def CommunicationModule {
    attribute rangeMeters       : Real;
    attribute bandwidthKbps     : Real;
    attribute encryptionEnabled : Boolean;
}

