/*
  This trigger detects newly assigned party ID to a sales account (from inbound CDH flow) and updates the related Partner account record
*/
trigger Account_PartyUpdatePartner on Account (after update) {

    // todo: come back and refactor this into something less brittle
    private static final ID APACAccount = '012300000000QglAAE';
    private static final ID EMEAAccount = '012300000000NBLAA2';
    private static final ID LATAMAccount = '0126000000053LRAAY';
    private static final ID NAAccount = '012300000000NBGAA2';


    //
    // Get list of all sales ccounts that just had the party_number field updated
    //
    Account[] salesAccountList = new List<Account>();
    for (Account acct : Trigger.new) {
        Account acctOld = Trigger.oldMap.get(acct.Id);
        System.debug('*****[debug]***** recordTypeId=' + acct.RecordTypeId);
        System.debug('*****[debug]***** party_number=' + acct.CDHPartyNumber__c);
        if (acctOld.CDHPartyNumber__c != acct.CDHPartyNumber__c &&
            (acct.RecordTypeId == APACAccount || acct.RecordTypeId == EMEAAccount || acct.RecordTypeId == LATAMAccount || acct.RecordTypeId == NAAccount)) {
            salesAccountList.add(acct);
        }
    }

    if (salesAccountList.isEmpty()) {
        System.debug('*****[debug]***** no accounts found');
        return;
    }

    //
    // Map the account to its related cdh_party__c record
    //
    Map<ID,ID> salesAccountToPartyRowMap = new Map<ID, ID>();
    for (Account acct : salesAccountList) {
        salesAccountToPartyRowMap.put(acct.Id, acct.CDH_Party_Name__c);
    }

    //
    // Get list of all onboarding registrations for our sales accounts
    //
    Partner_Onboarding_Registration__c[] reglist = [select Id, Sales_Account__c, ConvertedAccount__c from Partner_Onboarding_Registration__c where Sales_Account__c in :salesAccountToPartyRowMap.keySet()];
    if (reglist.isEmpty()) {
        System.debug('*****[debug]***** no registrations found');
        return;
    }

    //
    // Map sales account ID to partner account ID
    //
    Set<Id> partnerAccountIds = new Set<Id>();
    Map<ID,ID> salesToPartnerMap = new Map<ID,ID>();
    Map<ID,Partner_Onboarding_Registration__c> salesToRegMap = new Map<ID,Partner_Onboarding_Registration__c>();
    for (Partner_Onboarding_Registration__c reg : reglist) {
        salesToPartnerMap.put(reg.Sales_Account__c, reg.ConvertedAccount__c);
        partnerAccountIds.add(reg.ConvertedAccount__c);
        salesToRegMap.put(reg.Sales_Account__c, reg);
    }

    //
    // Now generate updates for each partner account to set the relevant fields
    //
    Account[] accountUpdates = new List<Account>();
    Partner_Onboarding_Registration__c[] regUpdates = new List<Partner_Onboarding_Registration__c>();
    for (ID salesAccountId : salesToPartnerMap.keySet()) {
        Account salesAccount = Trigger.newMap.get(salesAccountId);
        ID partnerAccountId = salesToPartnerMap.get(salesAccountId);
        if (partnerAccountId == null) {
            System.debug('*****[ error ] ***** partnerAccountId is null');
            continue;
        }

        System.debug('*****[debug]***** updating ' + partnerAccountId + ' with party ' + salesAccount.CDHPartyNumber__c);
        accountUpdates.add(new Account(Id = partnerAccountId, CDH_Party_Name__c = salesAccount.CDH_Party_Name__c));
        Partner_Onboarding_Registration__c reg = salestoRegMap.get(salesAccountId);
        reg.CDH_Party_Number__c = salesAccount.CDHPartyNumber__c;
        regUpdates.add(reg);
    }

    if (!accountUpdates.isEmpty()) {
        update accountUpdates;
        System.debug('*****[debug]***** accounts updated:' + accountUpdates.size());
        update regUpdates;
    }

}