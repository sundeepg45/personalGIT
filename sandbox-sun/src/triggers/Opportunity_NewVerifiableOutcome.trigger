/**
* Trigger Name:Opportunity_NewVerifiableOutcome
* Modificaton History: 6/29/2011 - Updated Stage value for Value Selling project - July 20th, 2011 release 
* Modified By : Nitesh Dokania
* Modified date :6/29/2011
* Reason for Modification: Updated Stage value for Value Selling project - July 20th, 2011 release
* Modified By : Nitesh Dokania
* Modified date :10/20/2011
* Reason for Modification:  Updated the trigger and moved all code into separate class - Dec 19th, 2011 Value 
*                            Selling release
* Modified By : Nitesh Dokania
* Modified date :12/22/2011
* Reason for Modification:  Updated the trigger so that only if User's Profile is a VO profile then logic will get execute through the class.
*/

trigger Opportunity_NewVerifiableOutcome on Opportunity (after insert, before update) 
{   
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    // getting profiles from custom setting for whom VO should not get created
    List<SalesOperations__c> customSettingObj  = null ;
    Set<Id> profileIdSet = new Set<Id>();
    
    customSettingObj  = SalesOperations__c.getall().values();      
    for(SalesOperations__c profileId : customSettingObj)
    {
        profileIdSet.add(profileId.ProfileId__c);
    }
    if(profileIdSet.contains(UserInfo.getProfileId()))
        return;
    else
        new Opportunity_VerifiableOutcome().opportunityVO();   
}