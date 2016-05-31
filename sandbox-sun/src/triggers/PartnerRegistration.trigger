trigger PartnerRegistration on Partner_Registration__c (after insert, after update, before insert, before update) {

    private final string logTag = '[PartnerRegistrationTrigger]';



/***************** AFTER  UPDATE ******************/

    if (Trigger.isUpdate && Trigger.isAfter) {
        ID[] updates = new List<ID>();
        for (Partner_Registration__c newReg : Trigger.new){
            Partner_Registration__c oldReg = Trigger.oldMap.get(newReg.Id);
            if (newReg.Status__c == 'Pending End Customer Owner Approval' && oldReg.Status__c != 'Pending End Customer Owner Approval') {
                updates.add(newReg.Id);
            }
        }
        if (!updates.isEmpty()) {
            PartnerRegistrationUtil.enableAutoApproval(updates);
        }
    }



/***************** BEFORE  UPDATE ******************/

    if(trigger.isUpdate && trigger.isBefore){
        
        // Check if the End_Customer__c field has been updated
        PartnerRegistrationUtil.setEndCustomerManager(trigger.new, trigger.oldMap);
        
        // Approval process validations
        for(Partner_Registration__c newReg:trigger.new){
            Partner_Registration__c oldReg = trigger.oldMap.get(newReg.Id);

            // If the registration is being moved from Step 1 to Step 2, check that they've selected an actual account in the End_Customer__c field
            if( (newReg.Status__c == 'Pending Partner Account Owner Approval' && oldReg.Status__c == 'Pending Channel Operations Approval') && newReg.End_Customer__c == null){
                newReg.addError('Please select the actual End Customer before advancing this Registration through the approval process.');
            }
           
           // Before being final approved, the Opportunity Close Amount must be filled in by the final approver
            if( (newReg.Status__c == 'Approved' && oldReg.Status__c != 'Approved') && newReg.MDF_Awarded__c == null){
                newReg.addError('MDF Awarded must not be empty before approving a Registration.');
            }
            
        }
        
        //
        // if approved verify or create new MDF budget for the account
        //
       // if (ThreadLock.lock('PartnerRegistration-MDFCreate')) {
            Partner_Registration__c[] approved = new List<Partner_Registration__c>();
            for (Partner_Registration__c par : Trigger.new) {
                Partner_Registration__c oldpar = Trigger.oldMap.get(par.Id);
                if (par.Status__c == 'Pending Opportunity Close' && oldpar.Status__c != par.Status__c) {
                    system.debug(logTag + 'Registration has moved to Pending Opportunity Close - checking for existing PAR MDF record next..');
                    approved.add(par);
                    par.Expiration_Date__c = System.today().addDays(270);
                }
            }
            
            if (approved.size() > 0) {
                
                // Create MDFs
                Map<ID, SFDC_Budget__c> existing = new Map<ID,SFDC_Budget__c>();
                
                for (SFDC_Budget__c mdf : [
                    select  Id, Account_master__c
                    from    SFDC_Budget__c
                    where   Account_master__c in :PartnerUtil.getStringFieldSet(approved, 'Partner__c')
                    and     RecordType.DeveloperName = 'PAR'
                ]) {
                    existing.put(mdf.Account_master__c, mdf);
                }
                
                
                ID parType = [select Id from RecordType where SobjectType = 'SFDC_Budget__c' and DeveloperName = 'PAR'].Id;
                SFDC_Budget__c[] budgets = new List<SFDC_Budget__c>();
                
                for (Partner_Registration__c par : approved) {
                    if (!existing.containsKey(par.Partner__c)) {
                        system.debug(logTag + 'Creating new PAR MDF for Registration [' + par.Name + ']');
                        SFDC_Budget__c newmdf = new SFDC_Budget__c();
                        newmdf.RecordTypeId = parType;
                        newmdf.Name = 'PAR Budget';
                        newmdf.Account_master__c = par.Partner__c;
                        newmdf.Active__c = true;
                        newmdf.Is_PAR__c = true;
                        newmdf.I_Agree_to_the_Terms_and_Conditions__c = true;
                        
                        budgets.add(newmdf);
                    } else {
                        system.debug(logTag + 'Existing PAR MDF found for Registration [' + par.Name + ']. A new MDF will NOT be created.');
                    }
                }
                
                system.debug(logTag + 'Inserting [' + budgets.size() + '] new PAR MDF records..');
                
                if (!budgets.isEmpty()) {
                    insert budgets;
                    //
                    // can't insert inactive mdf so go back and flip them
                    //
                    for (SFDC_Budget__C b : budgets) {
                        b.Active__c = false;
                    }
                    update budgets;
                }
            }
        //}       
        
        
        
    }
}