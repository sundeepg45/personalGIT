/*
Name        : Opportunity_UpdateOwnerDepartment
Date Created: March 23, 2010
Created By  : Gaurav Gupte
Description : This Trigger will update Department field on Opporutnity with Opportunity Owner's Department(From User record)
Modified    : October 6, 2010
Modified By : Bill C. Riemers
Description : Add protections for failed lookups, and properly deal with mixed lists of open and closed opportunities
*/


trigger Opportunity_UpdateOwnerDepartment on Opportunity (before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
 
    //Create a set of all the unique ownerIds related to Opportunities
    Set<Id> ownerIds = new Set<Id>();
    List<Opportunity> opps = new List<Opportunity>();
    List<SalesOperations__c> customSettingObj  = null ;
    Set<Id> profileIdSet = new Set<Id>();
    for (Opportunity opp : Trigger.new)
    {
        // START
        
        /*  This part of code has been written for Value Selling enahncement Dec 2011 release. This code updates a Boolean field depending on the
            profile of the loggedin User.
        */
        customSettingObj  = SalesOperations__c.getall().values();
        for(SalesOperations__c profileId : customSettingObj)
        {
            profileIdSet.add(profileId.ProfileId__c);
        }
        if(profileIdSet.contains(UserInfo.getProfileId()))
            opp.VOUpdate__c=true;
        else
            opp.VOUpdate__c=false;
        
        // END
        
        // only update opportunities if admin by pass or in an open stage.
        if(Util.adminByPassForOpportunity()||!(opp.StageName == 'Closed Booked' || opp.StageName == 'Closed Won' || opp.StageName == 'Closed Lost'))
        {
            ownerIds.add(opp.OwnerId);
            opps.add(opp);
        }
    }
    // If owner id is null, the update should fail anyway.  This just avoids the extra lookup.
    ownerIds.remove(null);
    System.debug('ownerIds='+ownerIds);
    
    if(! ownerIds.isEmpty())
    {
        // Query for all the User records for the unique and create a map for a lookup / hash table for the user info
        Map<id, User> ownerMap = new Map<id, User>([Select Id, Department from User Where Id IN :ownerIds]);  
        System.debug('ownerMap='+ownerMap);
        // Iterate over the list and set the Department before being inserted or updated.
        for(Opportunity op: opps)
        {
            User owner = ownerMap.get(op.OwnerId);
            if(owner != null)
            {
                op.Department__c = owner.Department;
                System.debug('op.Department__c='+op.Department__c);
            }
        }
    }
 }