/**
* Trigger Name:Opportunity_NewVerifiableOutcome
* Created Date :10/20/2011
* Description:  Created the trigger for Value Selling Enahncement - Dec 19th, 2011 Value 
*                            Selling release
*/

trigger OpportunityType_VerifiableOutcome on Opportunity (after update)
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
    else if(UserInfo.getUserName().contains(Util.dataCleanupUser))
    {
        System.debug('inside trigger');
        new OpptyType_VerifiableOutcome().opportunityTypeCreateVO(trigger.new);
    }
    else
        new OpptyType_VerifiableOutcome().opportunityTypeVO();
}