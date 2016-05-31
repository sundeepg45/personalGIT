trigger Account_UpdateKeywords on Account (before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

    for (Account acct : Trigger.new) {
        String buf = '';
        if (acct.Hardware_Focus__c != null) {
            buf += ';' + acct.Hardware_Focus__c;
        }

        if (acct.Hardware_Platform__c != null) {
            buf += ';' + acct.Hardware_Platform__c;
        }

        if (acct.Industry_Focus__c != null) {
            buf += ';' + acct.Industry_Focus__c;
        }

        if (acct.Operating_System_Supported__c != null) {
            buf += ';' + acct.Operating_System_Supported__c;
        }

        if (acct.Software_Focus__c != null) {
            buf += ';' + acct.Software_Focus__c;
        }
        
        if (acct.Middleware_Supported__c != null) {
            buf += ';' + acct.Middleware_Supported__c;
        }

        if (acct.Application_Types__c != null) {
            buf += ';' + acct.Application_Types__c;
        }
        
        if (buf.length() > 255) {
            buf = buf.substring(0, 254);
        }
        
        acct.PartnerKeywords__c = buf;
    }
}