trigger EventAssignOppId on Event__c (before insert,before update) {
    for(Event__c ev : Trigger.new) {
        if(ev.Opportunity__c != null && ev.OpportunityId__c != ev.Opportunity__c) {
            ev.OpportunityId__c = ev.Opportunity__c;
        }
    }
}