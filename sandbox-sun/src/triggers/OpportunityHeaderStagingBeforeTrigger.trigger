/**
 *
* @author Scott Coleman <scoleman@redhat.com>
* @version 2015-06-28
* 2015-06-28 - initial version
*/
trigger OpportunityHeaderStagingBeforeTrigger on Opportunity_Header_Staging__c (before insert, before update) {

    Set<String> cdhPartyNumbers = new Set<String>();

    for(Opportunity_Header_Staging__c oHS:trigger.new) {
        if(oHS.Bill_To_CDH_Party_Number_Account__c != null) {
            cdhPartyNumbers.add(oHS.Bill_To_CDH_Party_Number_Account__c);
        }

        if(oHS.Entitle_To_CDH_Party_Number_Account__c != null) {
            cdhPartyNumbers.add(oHS.Entitle_To_CDH_Party_Number_Account__c);
        }

        if(oHS.Ship_To_CDH_Party_Number_Account__c != null) {
            cdhPartyNumbers.add(oHS.Ship_To_CDH_Party_Number_Account__c);
        }

        if(oHS.Sold_To_CDH_Party_Number_Account__c != null) {
            cdhPartyNumbers.add(oHS.Sold_To_CDH_Party_Number_Account__c);
        }
    }

    Map<String, Id> cdhPartyIds = new Map<String, Id>();

    if(!cdhPartyNumbers.isEmpty()) {
        for(CDH_Party__c cdhParty : [SELECT Id, Name FROM CDH_Party__c WHERE Name IN :cdhPartyNumbers]) {
            cdhPartyIds.put(cdhParty.Name, cdhParty.Id);
        }
    }

    for(Opportunity_Header_Staging__c oHS:trigger.new) {
        if(oHS.Bill_To_CDH_Party_Number_Account__c != null && cdhPartyIds.keySet().contains(oHS.Bill_To_CDH_Party_Number_Account__c)) {
            oHS.Bill_To_CDH_Party__c = cdhPartyIds.get(oHS.Bill_To_CDH_Party_Number_Account__c);
        }
        else {
            oHS.Bill_To_CDH_Party__c = null;
        }

        if(oHS.Entitle_To_CDH_Party_Number_Account__c != null && cdhPartyIds.keySet().contains(oHS.Entitle_To_CDH_Party_Number_Account__c)) {
            oHS.Entitle_To_CDH_Party__c = cdhPartyIds.get(oHS.Entitle_To_CDH_Party_Number_Account__c);
        }
        else {
            oHS.Entitle_To_CDH_Party__c = null;
        }

        if(oHS.Ship_To_CDH_Party_Number_Account__c != null && cdhPartyIds.keySet().contains(oHS.Ship_To_CDH_Party_Number_Account__c)) {
            oHS.Ship_To_CDH_Party__c = cdhPartyIds.get(oHS.Ship_To_CDH_Party_Number_Account__c);
        }
        else {
            oHS.Ship_To_CDH_Party__c = null;
        }

        if(oHS.Sold_To_CDH_Party_Number_Account__c != null && cdhPartyIds.keySet().contains(oHS.Sold_To_CDH_Party_Number_Account__c)) {
            oHS.Sold_To_CDH_Party__c = cdhPartyIds.get(oHS.Sold_To_CDH_Party_Number_Account__c);
        }
        else {
            oHS.Sold_To_CDH_Party__c = null;
        }
    }
}