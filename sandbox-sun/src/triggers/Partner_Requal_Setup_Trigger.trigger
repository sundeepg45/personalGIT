trigger Partner_Requal_Setup_Trigger on Partner_Requal_Setup__c (before insert) {

    List<Id> accountIdList = new List<Id>();
    for (Partner_Requal_Setup__c prs : Trigger.new) {
        accountIdList.add(prs.AccountId__c);
    }

    List<Account> accounts = [select id, enrollment_date__c from Account where Id in :accountIdList];
    List<PartnerStatus__c> statuses = [
        select  id,
                partner__c,
                activationdate__c
          from  PartnerStatus__c
         where  Partner__c in :accountIdList
           and  ActivationStatus__c = 'Active'];

    Map<Id, PartnerStatus__c> statusMap = new Map<Id, PartnerStatus__c>();
    for (PartnerStatus__c ps : statuses) {
        statusMap.put(ps.partner__c, ps);
    }

    for (Account account : accounts) {
        PartnerStatus__c ps = statusMap.get(account.id);
        if (ps != null) {
            Date firstdate = ps.activationdate__c;
            if (account.Enrollment_Date__c != null) {
                firstdate = account.Enrollment_Date__c;
            }
            Integer mo = firstdate.month();
            if (mo < 7) {
                firstdate = Date.newinstance(2012, mo, 1);
            }
            else {
                firstdate = Date.newinstance(2011, mo, 1);
            }
            account.RequalificationDate__c = firstdate;
        }
    }
    update accounts;
}