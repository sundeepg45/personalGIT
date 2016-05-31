/*****************************************************************************************
    Name    :   Account_DirectPurchasingAgreementValidation
    Desc    :   Before update trigger to stop specific users from unchecking the Direct Purchasing Agreements flag
    Actions :   1. Nobody should be able to uncheck the flag unless you are an Admin
                2. Admins Ops can only uncheck it for SI, CCSP, Embedded programs


Modification Log :
---------------------------------------------------------------------------
 Developer                Date            Description
---------------------------------------------------------------------------
 Kiran Ravikanti         11/24/2015       Created.

******************************************************************************************/
trigger Account_DirectPurchasingAgreementValidation on Account (before update) {

    List<Account> DPAUncheckedAccounts = new List<Account>();

    //make a list of accounts whose DPA is unchecked
    for (Account acc : trigger.new) {
        if (acc.Direct_Purchasing_Agreement__c == false && Trigger.oldMap.get(acc.Id).Direct_Purchasing_Agreement__c == true) {
            DPAUncheckedAccounts.add(acc);
        }
    }

    //stop if no accounts
    if (DPAUncheckedAccounts.isEmpty())
        return;

    //make a list of program memberships for interested accounts
    List<Partner_Program__c> programs = [   select Program_Name__c, Status__c, Tier__c, Account__c
                                            from Partner_Program__c
                                            where Account__c = :DPAUncheckedAccounts];

    //Build Accounts-Program map
    Map<Id, Partner_Program__c> acctPrograms = new Map<Id, Partner_Program__c>();
    for (Partner_Program__c pgm :programs) {
        acctPrograms.put(pgm.Account__c, pgm);
    }

    //get who can override/ Uncheck the DPA from the custom settings //if(UserInfo.getProfileId())
    Direct_Purchasing_Agreement_Override__c DPA = Direct_Purchasing_Agreement_Override__c.getInstance();


    //Loop-through the Accounts and program to enforce the validation
    for (Account a :DPAUncheckedAccounts) {
        boolean error;
        //loop to check for overridable 'program category' types
        for(Partner_Program__c p: programs) {
        //for(Partner_Program__c p: acctPrograms.get(a.Id)) {
            //non-Admins should not be able to uncheck DPA
            if (DPA.Override__c == null || DPA.Applicable_Types__c == null) {
                error = true;
            } //Override true and program matches the Applicable Types in Direct_Purchasing_Agreement_Override__c Custom setting, Allow override:
            else if(DPA.Override__c == true &&
                    (DPA.Applicable_Types__c.contains('All') ||
                        DPA.Applicable_Types__c.contains(p.Program_Name__c))) {
                error = false;
            } else {
                error = true;
            }
        }
        if(error) {
            a.addError('This Partner is been identified as they have \'Direct Purchasing agreements\' with Red Hat. You can not uncheck the \'Direct Purchasing agreements\' flag once checked');
        }

    }

}