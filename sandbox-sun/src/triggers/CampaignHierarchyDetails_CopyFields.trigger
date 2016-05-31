trigger CampaignHierarchyDetails_CopyFields on Campaign_Hierarchy_Details__c (before insert, before update) {
    for(Campaign_Hierarchy_Details__c chd : Trigger.new) {
        if(chd.NumActiveLeadsFormula__c != chd.NumActiveLeads__c) {
            chd.NumActiveLeads__c = chd.NumActiveLeadsFormula__c;
        }
        if(chd.NumExpectedResponsesFormula__c != chd.Expected_Number_of_Responses__c) {
            chd.Expected_Number_of_Responses__c = chd.NumExpectedResponsesFormula__c;
        }
    } 
}