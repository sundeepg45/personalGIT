trigger PartnerRegistration_CreateOpp on Partner_Registration__c (after update) {

    // TODO: Add check if triggers are disabled
    
    final String logTag = '[PartnerRegistration_CreateOpportunity]';
    Set<String> approvedRegistrationSet = new Set<String>();
    
    for(Partner_Registration__c newReg:trigger.new){
        Partner_Registration__c oldReg = trigger.oldMap.get(newReg.Id);
        
        // Only process registrations whose Status has been changed to Pending Opportunity Close
        if( (newReg.Status__c != oldReg.Status__c && newReg.Status__c == 'Pending Opportunity Close') && newReg.Opportunity__c == null){
            system.debug(logTag + 'Partner Registration [' + newReg.Id + '] for customer [' + newReg.Company_Name__c  + '] has been approved [status:' + newReg.Status__c + '] and will be processed.');
            approvedRegistrationSet.add(newReg.Id);
        }
    }
    
    if(!approvedRegistrationSet.isEmpty()){
        PartnerRegistrationUtil.createOppFromPartnerReg(approvedRegistrationSet);
    }
    
}