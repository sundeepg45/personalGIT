trigger Opportunity_ClosedNotifyPAR on Opportunity (after update) {

    final string triggerName = 'Opportunity_ClosedNotifyPAR';
    // TODO: Check booleanSettings if this trigger is enabled
    final string logTag = '[' + triggerName + ']';
    List<Partner_Registration__c> regUpdateList = new List<Partner_Registration__c>();
    Map<Id, Opportunity> processOppMap = new Map<Id, Opportunity>();

    for(Opportunity newOpp:trigger.new){
    	Opportunity oldOpp = trigger.oldMap.get(newOpp.Id);

    	// PAR-generated opportunity record types are * Sales Opportunity (ex: "LATAM Sales Opportunity"), we don't care about the other types
    	//if(!newOpp.RecordType.Name.containsIgnoreCase('Sales Opportunity'))
    	//   continue;
    	system.debug(logTag + 'Record Type: [' + newOpp.RecordType + ']');

    	// Has the opp Stage been changed to either Closed/Won or Closed/Lost?
    	if( (newOpp.StageName == 'Closed Booked' && oldOpp.StageName != 'Closed Booked') ||
    	     (newOpp.StageName == 'Closed Lost' && oldOpp.StageName != 'Closed Lost') ){

            processOppMap.put(newOpp.Id, newOpp);

        }
    }

    // Upate any Partner Registraton records that are related to the closed opp
    for(Partner_Registration__c pr:[select Id, Opportunity__c, Partner__c from Partner_Registration__c where Opportunity__c IN :processOppMap.keySet()]){
    	if(processOppMap.containsKey(pr.Opportunity__c)){
    		Opportunity opp = processOppMap.get(pr.Opportunity__c);
    		system.debug(logTag + 'Opportunity [' + opp.Name + '] has a related Partner Registration [' + pr.Id + ']. It will be updated with the final opp amount and close date.');
            pr.Opportunity_Close_Date__c = opp.CloseDate;
            pr.Opportunity_Close_Stage__c = opp.StageName;
    		regUpdateList.add(pr);
    	}
    }

    if(!regUpdateList.isEmpty()){
    	Database.Saveresult[] lsr = Database.update(regUpdateList);
    	system.debug(logTag + lsr);
    }


}