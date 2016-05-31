/*****************************************************************************************
    Name    : OpportunityPartner_UpdatePartnerCode
    Desc    : This trigger updates the Oracle_Classification_Code__c
              based on PartnerType__c and PartnerTier__c
                       
                            
    Modification Log : 
---------------------------------------------------------------------------
    Developer                 Date              Description
---------------------------------------------------------------------------
    Anshul Kumar              04 DEC 2014       Created  (US59500)     
******************************************************************************************/
trigger OpportunityPartner_UpdatePartnerCode on OpportunityPartner__c (before Insert, before Update) {
        
    set<Id> setPartnerTypeIds = new set<Id>();
    set<Id> setPartnerTierIds = new set<Id>();
  
  //collect the PartnerType and PartnerTier values  
    for(OpportunityPartner__c oppPartnerInst : trigger.new){
        setPartnerTypeIds.add(oppPartnerInst.PartnerType__c);
        setPartnerTierIds.add(oppPartnerInst.PartnerTier__c);
    }
    
    system.debug('---setPartnerTypeIds---' + setPartnerTypeIds);
    system.debug('---setPartnerTierIds---' + setPartnerTierIds);
  
  //fetch Partner Program Tier matching the criteria  
    list<Partner_Program_Tier__c> listPartnerProgramPartnerTier = new list<Partner_Program_Tier__c>(
                            [SELECT Oracle_Classification_Code__c, Partner_Program_Definition__r.Legacy_Partner_Type__c,
                                Legacy_Partner_Tier__c
                            FROM Partner_Program_Tier__c 
                            WHERE Partner_Program_Definition__r.Legacy_Partner_Type__c IN: setPartnerTypeIds
                                AND Legacy_Partner_Tier__c IN: setPartnerTierIds
                                AND Is_Active__c = TRUE
                                AND Partner_Program_Definition__r.Program_Status__c = 'Active'
                            ]);
  
  //update the Oracle CLassification Code on Opportunity Partner record  
    for(OpportunityPartner__c oppPartnerInst : trigger.new){
        for(Partner_Program_Tier__c legPartnerTierInst : listPartnerProgramPartnerTier){
            if(oppPartnerInst.PartnerType__c == legPartnerTierInst.Partner_Program_Definition__r.Legacy_Partner_Type__c
            && oppPartnerInst.PartnerTier__c == legPartnerTierInst.Legacy_Partner_Tier__c)
                oppPartnerInst.Oracle_Classification_Code__c = legPartnerTierInst.Oracle_Classification_Code__c;
        }
    }
}