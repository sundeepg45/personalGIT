/**
* Class Name:Opportunity_UpdateValueSellingStage
* Modificaton History: 6/29/2011 - Updated Stage value for Value Selling project - July 20th, 2011 release
* Modified By : Nitesh Dokania
* Modified date :6/29/2011
* Reason for Modification: Updated Stage value for Value Selling project - July 20th, 2011 release
*/

trigger Opportunity_UpdateValueSellingStage on Opportunity (before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    // Changed the opportunity stagename value as part of Value Selling enhancement.July 20th release
    Map <String, String> stageMap = new Map <String, String> {
        'Prepare' => 'Prepare',
        'Engage' => 'Engage',
        'Qualify' => 'Qualify',
        'Validate' => 'Validate',
        'Propose' => 'Propose',
        'Negotiate' => 'Negotiate',
        'Closed Won' => 'Closed Won',
        'Closed Lost' => 'Closed Lost',
        'Closed Booked' => 'Closed Booked'
    };

    for (Opportunity opportunity : Trigger.new)
        opportunity.Value_Selling_Stage__c = stageMap.get (opportunity.StageName);
}