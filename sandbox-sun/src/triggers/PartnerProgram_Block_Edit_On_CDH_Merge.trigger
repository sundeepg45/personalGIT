trigger PartnerProgram_Block_Edit_On_CDH_Merge on Partner_Program__c (before insert, before update, before delete) {

    Map<Id, Partner_Program__c> programAccountMap = new Map<Id, Partner_Program__c>();

    // Build the map of partner programs and their associted accounts.
    if (Trigger.isDelete) {
        for (Partner_Program__c oldProgram : Trigger.old) {
            programAccountMap.put(oldProgram.Account__c, oldProgram);
        }
    } else {
        for (Partner_Program__c newProgram : Trigger.new) {
            programAccountMap.put(newProgram.Account__c, newProgram);
        }
    }

    if (programAccountMap.isEmpty()) {
        return;
    }

    // Find all the accounts with inactive CDH parties which are associated
    // with the partner programs being modified.
    Account[] accountsWithInactiveCDHParty = [
        select  Id,
                CDH_Party_Name__r.Active__c
        from    Account
        where   CDH_Party_Name__r.Active__c = false
        and     Id in :programAccountMap.keySet()
    ];

    if (!System.Test.isRunningTest()) {
        for (Account account : accountsWithInactiveCDHParty) {
            Partner_Program__c program = programAccountMap.get(account.Id);
            if (program != null) {
                program.AddError(System.Label.PartnerProgram_CDH_Merge_Block_Error);
            }
        }
    }
}