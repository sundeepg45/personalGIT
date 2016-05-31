/**
 *
* @author Scott Coleman <scoleman@redhat.com>
* @version 2015-06-28
* 2015-06-28 - initial version
*/
trigger OpportunityLineStagingBeforeTrigger on Opportunity_Line_Staging__c (before insert, before update) {

    Set<String> cdhPartyNumbers = new Set<String>();

    for(Opportunity_Line_Staging__c oLS:trigger.new) {
        if(oLS.Entitle_To_CDH_Party_Number_Account__c != null) {
            cdhPartyNumbers.add(oLS.Entitle_To_CDH_Party_Number_Account__c);
        }
    }

    Map<String, Id> cdhPartyIds = new Map<String, Id>();

    if(!cdhPartyNumbers.isEmpty()) {
        for(CDH_Party__c cdhParty : [SELECT Id, Name FROM CDH_Party__c WHERE Name IN :cdhPartyNumbers]) {
            cdhPartyIds.put(cdhParty.Name, cdhParty.Id);
        }
    }

    for(Opportunity_Line_Staging__c oLS:trigger.new) {
        if(oLS.Entitle_To_CDH_Party_Number_Account__c != null && cdhPartyIds.keySet().contains(oLS.Entitle_To_CDH_Party_Number_Account__c)) {
            oLS.Entitle_To_CDH_Party__c = cdhPartyIds.get(oLS.Entitle_To_CDH_Party_Number_Account__c);
        }
        else {
            oLS.Entitle_To_CDH_Party__c = null;
        }
    }
}