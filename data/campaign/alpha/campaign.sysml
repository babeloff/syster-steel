// campaign.sysml — CampaignAlpha: the Campaign instance assembling all four experiments

package WorkflowModel {
    package CampaignAlpha {

        part alpha : Campaign {
            attribute campaignId = "CAMPAIGN-ALPHA-2026";
            attribute objective  = "Evaluate search-and-track effectiveness across terrain types and challenge conditions.";
            attribute version    = "1.0.0";

            part e1 : Experiment = exp1;
            part e2 : Experiment = exp2;
            part e3 : Experiment = exp3;
            part e4 : Experiment = exp4;
        }

    } // end package CampaignAlpha
} // end package WorkflowModel
