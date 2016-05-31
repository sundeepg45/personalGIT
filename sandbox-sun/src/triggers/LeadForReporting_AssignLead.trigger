trigger LeadForReporting_AssignLead on LeadForReporting__c (before insert) {
    for(LeadForReporting__c lfr : Trigger.new) {
        if(lfr.LMH__c == null) {
            lfr.Lead__c = lfr.LeadId__c;
        } 
    }
}