trigger NFR_ValidateLineItems on NFR_Request__c (before update, before insert) {

    for(NFR_Request__c nfr : Trigger.new) {
        if (nfr.User_RHN_Entitlement_Login__c == Null || nfr.User_RHN_Entitlement_Login__c.length() == 0) {
        	nfr.addError(Label.NFR_ValidateRHLogin_Required_Error);
        }

        // Ignored statuses
        if (nfr.Status__c == 'Draft')
            continue;
        if (nfr.Status__c == 'Rejected')
            continue;
        if (nfr.Status__c == 'Extension Requested')
            continue;
        if (nfr.Status__c == 'Extension Rejected')
            continue;
//        if (nfr.Status__c == 'Submitted')
//            continue;

        // Validate the number of line items
        if (nfr.NFRLI_Count__c != 0 || nfr.Auto_Generated__c)
            continue;

        if (!UserInfo.getUserType().equals('PowerPartner')) {
            nfr.addError(Label.NFR_ValidateLineItems_trig_Line_Items_Required_Error);
        }

    }
}