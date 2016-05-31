trigger PartnerProgram_CCPFormRequired on Partner_Program__c (before update) {
    final string logTag = '[PartnerProgram_CCPFormRequired]';
    
   
    Map<Partner_Program__c,Id> pgmAcctMap = new Map<Partner_Program__c,Id>();
    
    for (Partner_Program__c newPP : Trigger.new) {
        Partner_Program__c oldPP = Trigger.oldMap.get(newPP.Id);

        // If it's a CCP program request AND the record has just been approved by the first approver, check if the CCP form has been completed..
        if( newPP.Name == 'Certified Cloud Provider' && ( newPP.Status__c == 'Pending Second Approver' && oldPP.Status__c == 'Pending First Approver')) {
            system.debug(logTag + 'Program [' + newPP.Name + '] for Partner [' + newPP.Account__c + '] will be checked for CCP Form completeness.');
            pgmAcctMap.put(newPP, newPP.Account__c);
        }
    }
    
    
    
    // Build a map of Partner Program -> CCP Form
    if(pgmAcctMap.isEmpty()) return;
     
    Partner_CCP_Form__c[] ccpForms = [
      SELECT  Id, Partner__c
      FROM  Partner_CCP_Form__c
      WHERE  Partner__c in :pgmAcctMap.values()
        AND Is_Complete__c = true
    ];
    
    system.debug(logTag + 'ccpForms size: [' + ccpForms.size() + ']');
    
    // Check for completedness of the CCP form and flag any Partner Programs that aren't yet ready
    Map<Id, Partner_CCP_Form__c> acctFormMap = new Map<Id, Partner_CCP_Form__c>();
    for(Partner_CCP_Form__c f:ccpForms){
        acctFormMap.put(f.Partner__c, f);
    }
    
    for(Partner_Program__c prog: pgmAcctMap.keySet()){
        Partner_CCP_Form__c ccpForm = acctFormMap.get(prog.Account__c);
        if(ccpForm == null){
            prog.AddError('The CCP Form must be completed before advancing through the approval process.');
        }
        
    }
    
    
    
    

}