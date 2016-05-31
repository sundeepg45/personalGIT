trigger OpportunityCloseBookedNFR on Opportunity (before update) {
    Id nfrRecordTypeId = null;
    for(Opportunity opp : Trigger.new) {
        if(opp.StageName == 'Closed Booked' && opp.Order_Status__c != 'Booked') {
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
            if(oldOpp != null) {
                if(nfrRecordTypeId == null) {
                    nfrRecordTypeId = RecordTypeLookup.getRecordTypeId('NFR Opportunity','Opportunity');
                }
                if(oldOpp.RecordTypeId == nfrRecordTypeId) {
                    opp.Order_Status__c = 'Booked';
                }
            }
        } 
    }
}