// requirements.sysml — Campaign experiment requirements

package WorkflowModel {

    requirement def SearchCoverageRequirement {
        doc /* Scout vehicles must achieve the minimum area coverage fraction
               before mission time expires. */
        attribute minimumCoverage    : Real = 0.80;
        attribute maximumMissionTime : Real = 3600.0;
    }

    requirement def TrackingAccuracyRequirement {
        doc /* The position error of any tracked vehicle must remain below
               the specified threshold. */
        attribute maxPositionErrorMeters : Real = 5.0;
        attribute minUpdateRateHz        : Real = 1.0;
    }

    requirement def CommunicationRequirement {
        doc /* Each vehicle must successfully transmit contact reports
               within the specified latency bound. */
        attribute maxReportLatencySeconds : Real = 2.0;
        attribute minReliability          : Real = 0.95;
    }

    requirement def SafetyRequirement {
        doc /* No two vehicles may come within the minimum separation
               distance of each other during the simulation. */
        attribute minSeparationMeters : Real = 10.0;
    }

    requirement def ExperimentCompletionRequirement {
        doc /* Every experiment in the campaign must complete within its
               allotted time budget with a valid metrics record. */
        satisfy SearchCoverageRequirement;
        satisfy TrackingAccuracyRequirement;
        satisfy CommunicationRequirement;
        satisfy SafetyRequirement;
    }

} // end package WorkflowModel
