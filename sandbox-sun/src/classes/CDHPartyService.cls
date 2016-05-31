/**
 * This class contains service methods for the CDH party object
 *
 * @version 2016-01-26
 * @author Scott Coleman <scoleman@redhat.com>
 * 2016-01-26 - Implementing merge history to aid troubleshooting (object: CDH_Party_Merge__c)
 * 2015-08-24 - Extended to include merge detection and account reparenting for US69276
 * 2015-07-05 - Created for US66997
 * Bill Riemers <briemers@redhat.com>
 * 2015-11-24 - Fixed null exception
 */
public with sharing class CDHPartyService {
    public static void processMergeVictims(List<CDH_Party__c> parties) {
        // get parties with accounts
        Set<Id> partyIds = new Set<Id>();
        for(CDH_Party__c party : parties) {
            if(party.Id != null) {
                partyIds.add(party.Id);
            }
        }

        // delete parties with no child accounts, deactivate parties with child accounts
        List<CDH_Party__c> partiesToUpdate = new List<CDH_Party__c>();
        List<CDH_Party__c> partiesToDelete = new List<CDH_Party__c>();

        for(CDH_Party__c party : [
            SELECT
                Id,
                Active__c,
                (SELECT
                    Id
                FROM Accounts__r)
            FROM CDH_Party__c
            WHERE Id IN :partyIds ]) {

            if(party.Accounts__r == null || party.Accounts__r.isEmpty()) {
                partiesToDelete.add(party);
            }
            else if(party.Active__c) {
                party.Active__c = false;
                partiesToUpdate.add(party);
            }
        }

        if(!partiesToDelete.isEmpty()) {
            for(Database.DeleteResult result : Database.delete(partiesToDelete, false)) {
                if(!result.isSuccess()) {
                    throw new Interface_ServiceException('Error deleting merge victim party: ' + result.getErrors()[0].getMessage());
                }
            }
        }

        if(!partiesToUpdate.isEmpty()) {
            for(Database.SaveResult result : Database.update(partiesToUpdate, false)) {
                if(!result.isSuccess()) {
                    throw new Interface_ServiceException('Error updating merge victim party: ' + result.getErrors()[0].getMessage());
                }
            }
        }
    }

    public static void processMergeSurvivors(Map<String,List<Id>> survivorPartyNumberToAccountIdMap) {
        System.debug(survivorPartyNumberToAccountIdMap);
        // build a map of account Ids to survivor party number
        Map<Id,String> accountIdToSurvivorPartyNumberMap = new Map<Id,String>();
        for(String partyNumber : survivorPartyNumberToAccountIdMap.keySet()) {
            if(survivorPartyNumberToAccountIdMap.get(partyNumber) != null) {
                for(Id accountId : survivorPartyNumberToAccountIdMap.get(partyNumber)) {
                    accountIdToSurvivorPartyNumberMap.put(accountId,partyNumber);
                    //System.debug('vvvv1 account Id: ' + accountId + '; survivor party number: ' + partyNumber);
                }
            }
        }

        // look for accounts associated with the survivor party in the message but still associated with the victim party in SFDC and
        // build a map of victim party ids to survivor party number
        Map<String,String> victimPartyNumberToSurvivorPartyNumberMap = new Map<String,String>();
        Map<String,CDH_Party__c> survivorPartyNumberToSurvivorPartyMap = new Map<String,CDH_Party__c>();
        Map<String,CDH_Party__c> victimPartyNumberToVictimPartyMap = new Map<String,CDH_Party__c>();
        for(Account account : [SELECT Id, CDH_Party_Name__c, CDH_Party_Name__r.Name FROM Account WHERE Id IN :accountIdToSurvivorPartyNumberMap.keySet()]) {
            if(account.CDH_Party_Name__r.Name == accountIdToSurvivorPartyNumberMap.get(account.Id)) {
                survivorPartyNumberToSurvivorPartyMap.put(account.CDH_Party_Name__r.Name, new CDH_Party__c(Id = account.CDH_Party_Name__c, Name = account.CDH_Party_Name__r.Name));
                //System.debug('vvvv2a survivor party number: ' + account.CDH_Party_Name__r.Name + '; victim survivor id ' + account.CDH_Party_Name__c);
            }
            else if(account.CDH_Party_Name__r.Name != accountIdToSurvivorPartyNumberMap.get(account.Id)) {
                victimPartyNumberToVictimPartyMap.put(account.CDH_Party_Name__r.Name, new CDH_Party__c(Id = account.CDH_Party_Name__c, Name = account.CDH_Party_Name__r.Name));
                //System.debug('vvvv2b victim party number: ' + account.CDH_Party_Name__r.Name + '; victim party id ' + account.CDH_Party_Name__c);
                victimPartyNumberToSurvivorPartyNumberMap.put(account.CDH_Party_Name__r.Name, accountIdToSurvivorPartyNumberMap.get(account.Id));
                //System.debug('vvvv3 victim party number: ' + account.CDH_Party_Name__r.Name + '; survivor party number: ' + accountIdToSurvivorPartyNumberMap.get(account.Id));
            }
        }

        // reparent ALL accounts under victim parties, even those not explicitly referenced in the message
        List<Account> reparentedAccounts = new List<Account>();
        Map<String,CDH_Party_Merge__c> mergeHistoryMap = new Map<String,CDH_Party_Merge__c>();
        if(!victimPartyNumberToSurvivorPartyNumberMap.isEmpty() && !survivorPartyNumberToSurvivorPartyMap.isEmpty()) {
            for(Account account : [SELECT Id, CDH_Party_Name__c, CDH_Party_Name__r.Name FROM Account WHERE CDH_Party_Name__r.Name IN :victimPartyNumberToVictimPartyMap.keySet()]) {
                //System.debug('vvvv4 victim party number: ' + account.CDH_Party_Name__r.Name + '; survivor party number: ' + victimPartyNumberToSurvivorPartyNumberMap.get(account.CDH_Party_Name__r.Name));
                String victimPartyNumber = account.CDH_Party_Name__r.Name;
                String survivorPartyNumber = victimPartyNumberToSurvivorPartyNumberMap.get(account.CDH_Party_Name__r.Name);
                account.CDH_Party_Name__c = survivorPartyNumberToSurvivorPartyMap.get(survivorPartyNumber).Id;
                reparentedAccounts.add(account);

                //create a shell merge history record for the victim/survivor pair if it doesn't already exist
                if(!mergeHistoryMap.containsKey(survivorPartyNumber)) {
                    mergeHistoryMap.put(survivorPartyNumber, new CDH_Party_Merge__c(
                        Surviving_CDH_Party__c = account.CDH_Party_Name__c,
                        Victim_CDH_Party__c = victimPartyNumber,
                        Account_Reparenting_Complete__c = false,
                        Address_Reconciliation_Complete__c = false,
                        EBS_Account_Reconciliation_Complete__c = false,
                        Success__c = false,
                        Message__c = null));
                }
            }
        }

        if(!reparentedAccounts.isEmpty()) {
            Boolean DoNotPublish = OutboundService.DoNotPublish;
            try {
                OutboundService.DoNotPublish = true;

                // commit parent updates
                String accountErrorMessage;
                Integer accountCount = 0;
                for(Database.SaveResult result : Database.update(reparentedAccounts, false)) {
                    String survivorPartyNumber = accountIdToSurvivorPartyNumberMap.get(reparentedAccounts[accountCount].Id);
                    CDH_Party_Merge__c mergeHistory = mergeHistoryMap.get(survivorPartyNumber);
                    if(!result.isSuccess()) {
                        if(accountErrorMessage == null) {
                            accountErrorMessage = 'Error moving accounts to merge survivor party: ' + result.getErrors()[0].getMessage();
                        }
                        mergeHistory.Account_Reparenting_Complete__c = false;
                        mergeHistory.Message__c = result.getErrors()[0].getMessage();
                    }
                    else if(mergeHistory.Message__c == null) {
                        mergeHistory.Account_Reparenting_Complete__c = true;
                    }
                    accountCount++;
                }

                if (accountErrorMessage != null) {
                    throw new Interface_ServiceException(accountErrorMessage);
                }

                // build maps to help us find missing Address and EBS Account records
                Map<String,Address__c> addressMap = new Map<String,Address__c>();
                Map<Id,Set<String>> accountIdToAddressPartySiteNumbersMap = new Map<Id,Set<String>>();
                Map<String,Set<String>> cdhPartyNumberToAddressPartySiteNumbersMap = new Map<String,Set<String>>();
                Map<String,EBS_Account__c> ebsAccountMap = new Map<String,EBS_Account__c>();
                Map<Id,Set<String>> accountIdToEBSAccountNumbersMap = new Map<Id,Set<String>>();
                Map<String,Set<String>> cdhPartyNumberToEBSAccountNumbersMap = new Map<String,Set<String>>();
                for(Account account : [
                    SELECT Id, CDH_Party_Name__r.Name,
                        (SELECT Id, Name, Address_External_Id__c, Address_Line1__c, Address_Line2__c, Address_Line3__c, Address_Line4__c, Address_Lines__c,
                            Bill_To_Address__c, CDH_Party_Site_Number__c, CDH_Party__c, City__c, Country__c, County__c, CurrencyIsoCode, Do_Not_Publish_To_Bus__c,
                            Entitle_To_Address__c, Identifying_Address__c, IsDuplicate__c, MasterRecord__c, Not_validated_by_Google__c, Province__c, RecordTypeId,
                            Sales_Account_Name__c, Sales_Account__c, Ship_To_Address__c, Sold_To_Address__c, State_Province__c, State__c, Status__c, Zip_Postal_Code__c
                        FROM Addresses__r
                        WHERE IsDuplicate__c != true and MasterRecord__c = null and Status__c != 'Merged'),
                        (SELECT Id, Name, Account_Type__c, CDH_Party_Number__c, Classification__c, Credit_Hold__c, Credit_Review_Cycle__c, CurrencyIsoCode,
                            EBS_Account_Description__c, EBS_Account_External_Id__c, EBS_Party_Name__c, EBS_Party_Number__c, Last_Credit_Review_Date__c,
                            MasterRecord__c, Next_Credit_Review_Date__c, Primary_EBS_Account__c, Sales_Account__c, Sales_channel__c, Status__c
                        FROM EBS_Account__r
                        WHERE MasterRecord__c = null)
                    FROM Account
                    WHERE (NOT RecordType.Name LIKE '%Partner%')
                    AND CDH_Party_Name__r.Name IN :survivorPartyNumberToAccountIdMap.keySet()
                ]) {
                    for(Address__c address : account.Addresses__r) {
                        addressMap.put(address.CDH_Party_Site_Number__c, address);

                        if(!accountIdToAddressPartySiteNumbersMap.containsKey(account.Id)) {
                            accountIdToAddressPartySiteNumbersMap.put(account.Id, new Set<String>());
                        }
                        accountIdToAddressPartySiteNumbersMap.get(account.Id).add(address.CDH_Party_Site_Number__c);

                        if(!cdhPartyNumberToAddressPartySiteNumbersMap.containsKey(account.CDH_Party_Name__r.Name)) {
                            cdhPartyNumberToAddressPartySiteNumbersMap.put(account.CDH_Party_Name__r.Name, new Set<String>());
                        }
                        cdhPartyNumberToAddressPartySiteNumbersMap.get(account.CDH_Party_Name__r.Name).add(address.CDH_Party_Site_Number__c);
                    }

                    for(EBS_Account__c ebsAccount : account.EBS_Account__r) {
                        ebsAccountMap.put(ebsAccount.Name, ebsAccount);

                        if(!accountIdToEBSAccountNumbersMap.containsKey(account.Id)) {
                            accountIdToEBSAccountNumbersMap.put(account.Id, new Set<String>());
                        }
                        accountIdToEBSAccountNumbersMap.get(account.Id).add(ebsAccount.Name);

                        if(!cdhPartyNumberToEBSAccountNumbersMap.containsKey(account.CDH_Party_Name__r.Name)) {
                            cdhPartyNumberToEBSAccountNumbersMap.put(account.CDH_Party_Name__r.Name, new Set<String>());
                        }
                        cdhPartyNumberToEBSAccountNumbersMap.get(account.CDH_Party_Name__r.Name).add(ebsAccount.Name);
                    }
                }

                // find and create missing Address records
                List<Address__c> missingAddresses = new List<Address__c>();
                for(Id accountId : accountIdToAddressPartySiteNumbersMap.keySet()) {
                    //System.debug('xxxx accountId: ' + accountId);
                    String partyNumber = accountIdToSurvivorPartyNumberMap.get(accountId);
                    //System.debug('xxxx partyNumber: ' + partyNumber);
                    System.debug(accountIdToAddressPartySiteNumbersMap.get(accountId));
                    System.debug(cdhPartyNumberToAddressPartySiteNumbersMap.get(partyNumber));
                    if(!accountIdToAddressPartySiteNumbersMap.get(accountId).containsAll(cdhPartyNumberToAddressPartySiteNumbersMap.get(partyNumber))) {
                        for(String partySiteNumber : cdhPartyNumberToAddressPartySiteNumbersMap.get(partyNumber)) {
                            //System.debug('xxxx partySiteNumber: ' + partySiteNumber);
                            if(!accountIdToAddressPartySiteNumbersMap.get(accountId).contains(partySiteNumber)) {
                                Address__c missingAddress = addressMap.get(partySiteNumber).clone();
                                missingAddress.Sales_Account__c = accountId;
                                missingAddress.CDH_Party__c = survivorPartyNumberToSurvivorPartyMap.get(partyNumber).Id;
                                missingAddresses.add(missingAddress);
                                //System.debug('xxxx missing address found!!');
                            }
                        }
                    }
                }
                if(!missingAddresses.isEmpty()) {
                    String addressErrorMessage;
                    Integer addressCount = 0;
                    for(Database.SaveResult result : Database.Insert(missingAddresses,false)) {
                        String survivorPartyNumber = accountIdToSurvivorPartyNumberMap.get(missingAddresses[addressCount].Sales_Account__c);
                        CDH_Party_Merge__c mergeHistory = mergeHistoryMap.get(survivorPartyNumber);                        
                        if(!result.isSuccess()) {
                            if(addressErrorMessage == null) {
                                addressErrorMessage = 'Error creating missing address for merge survivor party: ' + result.getErrors()[0].getMessage();
                            }
                            mergeHistory.Address_Reconciliation_Complete__c = false;
                            mergeHistory.Message__c = result.getErrors()[0].getMessage();
                        }
                        else if(mergeHistory.Message__c == null) {
                            mergeHistory.Address_Reconciliation_Complete__c = true;
                        }                        
                        addressCount++;
                    }

                    if (addressErrorMessage != null) {
                        throw new Interface_ServiceException(addressErrorMessage);
                    }
                }

                // find and create missing EBS Account records
                List<EBS_Account__c> missingEbsAccounts = new List<EBS_Account__c>();
                for(Id accountId : accountIdToEBSAccountNumbersMap.keySet()) {
                    String partyNumber = accountIdToSurvivorPartyNumberMap.get(accountId);
                    Set<String> ebsAccountNumbers = cdhPartyNumberToEBSAccountNumbersMap.get(partyNumber);
                    if(ebsAccountNumbers != null && ! accountIdToEBSAccountNumbersMap.get(accountId).containsAll( ebsAccountNumbers )) {
                        for(String ebsAccountNumber : ebsAccountNumbers ) {
                            if(!accountIdToEBSAccountNumbersMap.get(accountId).contains(ebsAccountNumber)) {
                                EBS_Account__c missingEbsAccount = ebsAccountMap.get(ebsAccountNumber).clone();
                                missingEbsAccount.Sales_Account__c = accountId;
                                missingEbsAccount.CDH_Party_Number__c = partyNumber;
                                missingEbsAccounts.add(missingEbsAccount);
                            }
                        }
                    }
                }
                if(!missingEbsAccounts.isEmpty()) {
                    String ebsAccountErrorMessage;
                    Integer ebsAccountCount = 0;                    
                    for(Database.SaveResult result : Database.Insert(missingEbsAccounts,false)) {
                        String survivorPartyNumber = accountIdToSurvivorPartyNumberMap.get(missingEbsAccounts[ebsAccountCount].Sales_Account__c);
                        CDH_Party_Merge__c mergeHistory = mergeHistoryMap.get(survivorPartyNumber);                          
                        if(!result.isSuccess()) {
                            if(ebsAccountErrorMessage == null) {
                                ebsAccountErrorMessage = 'Error creating missing EBS Account for merge survivor party: ' + result.getErrors()[0].getMessage();
                            }
                            mergeHistory.EBS_Account_Reconciliation_Complete__c = false;
                            mergeHistory.Message__c = result.getErrors()[0].getMessage();
                        }
                        else if(mergeHistory.Message__c == null) {
                            mergeHistory.EBS_Account_Reconciliation_Complete__c = true;
                        }                        
                        ebsAccountCount++;                        
                    }

                    if (ebsAccountErrorMessage != null) {
                        throw new Interface_ServiceException(ebsAccountErrorMessage);
                    }
                }

                // now run the merge logic against the victim parties to update/delete
                if(!victimPartyNumberToVictimPartyMap.isEmpty()) {
                    processMergeVictims(victimPartyNumberToVictimPartyMap.values());
                }

                if(!mergeHistoryMap.isEmpty()) {
                    for(String survivorPartyNumber : mergeHistoryMap.keySet()) {
                        CDH_Party_Merge__c mergeHistory = mergeHistoryMap.get(survivorPartyNumber);
                        mergeHistory.Success__c = true;
                    }
                }
            }
            finally {
                OutboundService.DoNotPublish = DoNotPublish;

                if(!mergeHistoryMap.isEmpty()) {
                    Database.Insert(mergeHistoryMap.values(),false);
                }
            }
        }
    }

    public static List<IntegrationObjects.SalesAccount> processSiteMergeSurvivors(List<IntegrationObjects.SalesAccount> accounts) {
        // build map address ids to site numbers found in the message and a set of address ids found in the message
        Map<Id, String> addressIdToPartySiteNumberMap = new Map<Id, String>();
        Set<Id> addressIds = new Set<Id>();
        if(accounts != null) {
            for(IntegrationObjects.SalesAccount account : accounts) {
                if(account.Addresses != null) {
                    for(IntegrationObjects.Address address : account.Addresses) {
                        if(address.IDList != null) {
                            for(Id addressId : address.IDList) {
                                addressIdToPartySiteNumberMap.put(addressId, address.CDH_Party_Site_Number);
                                addressIds.add(addressId);
                            }
                        }
                    }
                }
            }

            // examine existing address records and check to see if a site number update is needed
            List<Address__c> updatedAddresses = new List<Address__c>();
            Set<String> mergedPartySiteNumbers = new Set<String>();
            if(!addressIds.isEmpty()) {
                for(Address__c address : [SELECT Id, CDH_Party_Site_Number__c, Reparented__c FROM Address__c WHERE Id IN :addressIds]) {
                    if(address.CDH_Party_Site_Number__c != addressIdToPartySiteNumberMap.get(address.Id)) {
                        mergedPartySiteNumbers.add(address.CDH_Party_Site_Number__c);
                        address.CDH_Party_Site_Number__c = addressIdToPartySiteNumberMap.get(address.Id);
                        address.Reparented__c = true;
                        updatedAddresses.add(address);
                    }
                }
            }

            if(!updatedAddresses.isEmpty()) {
                Boolean DoNotPublish = OutboundService.DoNotPublish;
                try {
                    OutboundService.DoNotPublish = true;

                    // update addresses with new site number
                    for(Database.SaveResult result : Database.Update(updatedAddresses,false)) {
                        if(!result.isSuccess()) {
                            throw new Interface_ServiceException('Error updating address with site merge survivor site number: ' + result.getErrors()[0].getMessage());
                        }
                    }

                    // remove merged addresses from integration objects
                    for(IntegrationObjects.SalesAccount account : accounts) {
                        if(account.Addresses != null) {
                            List<IntegrationObjects.Address> addresses = new List<IntegrationObjects.Address>();
                            for(IntegrationObjects.Address address : account.Addresses) {
                                if(!mergedPartySiteNumbers.contains(address.CDH_Party_Site_Number)) {
                                    addresses.add(address);
                                }
                            }
                            account.Addresses = addresses;
                        }
                    }
                }
                finally {
                    OutboundService.DoNotPublish = DoNotPublish;
                }
            }
        }

        return accounts;
    }
}