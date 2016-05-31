trigger PartnerProgram_EnforcePrimary on Partner_Program__c (after insert, after update) {

    Partner_Program__c[] programs = new List<Partner_Program__c>();
    for (Partner_Program__c pgm : Trigger.new) {
        if (Trigger.isInsert) {
            if (pgm.Is_Primary__c) {
                programs.add(pgm);
            }
        }
        else {
            Partner_Program__c old = Trigger.oldMap.get(pgm.Id);
            if (pgm.Is_Primary__c == true && old.Is_Primary__c == false) {
                programs.add(pgm);
            }
        }
    }

    if (programs.size() > 0) {
        Partner_Program__c[] previousPrimary = [
            select  Id, Is_Primary__c
            from    Partner_Program__c
            where   Is_Primary__c = true
            and     Account__c in :PartnerUtil.getStringFieldSet(programs, 'Account__c')
            and     Id not in :PartnerUtil.getIdSet(programs)
        ];
        for (Partner_Program__c pgm : previousPrimary) {
            pgm.Is_Primary__c = false;
        }
        if (previousPrimary.size() > 0) {
            update previousPrimary;
        }
    }
}