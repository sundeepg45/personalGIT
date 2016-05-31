trigger Lead_DR_populateTeamingAgreement on Lead (after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

 if (Trigger.new.size() == 1) {
     System.debug('Teaming agreement In Constructor --------->:::'+ Trigger.new[0].Teaming_Agreement__r.id);
      System.debug('Teaming agreement In Constructor --------->:::'+ Trigger.new[0].Teaming_Agreement__c);
 
    if (Trigger.old[0].isConverted == false && Trigger.new[0].isConverted == true) {
 
      
      // if a new opportunity was created
      if (Trigger.new[0].ConvertedOpportunityId != null) {
 
        // update the converted opportunity with some text from the lead
        Opportunity opp = [Select o.Id, o.Description, o.Teaming_Agreement__c from Opportunity o Where o.Id = :Trigger.new[0].ConvertedOpportunityId];
        opp.Teaming_Agreement__c = Trigger.new[0].Teaming_Agreement__c;
        update opp;
     }
      
    }
 
 }      
 
 
}