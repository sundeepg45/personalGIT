/**
 * This class contains unit tests for service methods for the CDH party object
 *
 * @version 2016-01-28
 * @author Scott Coleman <scoleman@redhat.com>
 * 2016-01-28 - Added merge history
 * 2015-07-05 - Created for US66997
 */
@isTest
private class CDHPartyServiceTest {

    public static CDH_Party__c party {
        get {
            if(party == null) {
                party = new CDH_Party__c(
                    Name = '123456',
                    Active__c = true);

                insert party;
            }
            return party;
        }
    }

    public static CDH_Party__c party2 {
        get {
            if(party2 == null) {
                party2 = new CDH_Party__c(
                    Name = 'NOACCOUNTS',
                    Active__c = true);

                insert party2;
            }
            return party2;
        }
    }

    public static CDH_Party__c party3{
        get {
            if(party3 == null) {
                party3 = new CDH_Party__c(
                    Name = '78910',
                    Active__c = true);

                insert party3;
            }
            return party3;
        }
    }

    public static Account account {
        get {
            if(account == null) {
                account = new Account(
                    Name='TestAccount',
                    CDH_Party_Name__c = party.Id,
                    CDH_Party_Name__r = party,
                    Data_Status__c=AccountTriggerBeforeLock.PENDING_DATA_REVIEW,
                    AccountClassification__c='EMEA - Hosting',
                    BillingCity='Testville',
                    BillingStreet='1 no where',
                    BillingCountry='US',
                    Middleware_Supported__c='None',
                    OwnerId = UserInfo.getUserId(),
                    Ownership = 'Private',
                    Total_of_Subsidiaries_if_Parent__c=5,
                    VATNumber__c=null,
                    What_Markets_are_Targeted__c='Vertical market');

                insert account;
            }
            return account;
        }

    }

    public static Account account2 {
        get {
            if(account2 == null) {
                account2 = new Account(
                    Name='TestAccount2',
                    CDH_Party_Name__c = party3.Id,
                    CDH_Party_Name__r = party3,
                    Data_Status__c=AccountTriggerBeforeLock.PENDING_DATA_REVIEW,
                    AccountClassification__c='EMEA - Hosting',
                    BillingCity='Testville',
                    BillingStreet='1 no where',
                    BillingCountry='US',
                    Middleware_Supported__c='None',
                    OwnerId = UserInfo.getUserId(),
                    Ownership = 'Private',
                    Total_of_Subsidiaries_if_Parent__c=5,
                    VATNumber__c=null,
                    What_Markets_are_Targeted__c='Vertical market');

                insert account2;
            }
            return account2;
        }

    }

    public static EBS_Account__c ebsAccount {
        get {
            if(ebsAccount == null) {
                ebsAccount = new EBS_Account__c(
                    Name='12345',
                    Sales_Account__c = account.Id,
                    Sales_Account__r = account);

                insert ebsAccount;
            }
            return ebsAccount;
        }
    }

    public static EBS_Account__c ebsAccount2 {
        get {
            if(ebsAccount2 == null) {
                ebsAccount2 = new EBS_Account__c(
                    Name='67890',
                    Sales_Account__c = account2.Id,
                    Sales_Account__r = account2);

                insert ebsAccount2;
            }
            return ebsAccount2;
        }
    }

    public static Address__c address {
        get {
            if(address == null) {
                address = new Address__c(
                    CDH_Party_Site_Number__c = '12345',
                    Sales_Account__c = account.Id,
                    Sales_Account__r = account,
                    Address_Line1__c = 'Line 1',
                    Address_Line2__c = 'Line 2',
                    Address_Line3__c = 'Line 3',
                    Address_Line4__c = 'Line 4',
                    City__c = 'City',
                    State__c = 'ON',
                    County__c = 'county',
                    Zip_Postal_Code__c = 'L8J 3S8',
                    Country__c = 'CA',
                    Identifying_Address__c = true,
                    CDH_Party__c = party.Id,
                    Status__c = 'Active');

                insert address;
            }
            return address;
        }
    }

    public static Address__c address2 {
        get {
            if(address2 == null) {
                address2 = new Address__c(
                    CDH_Party_Site_Number__c = '67890',
                    Sales_Account__c = account2.Id,
                    Sales_Account__r = account2,
                    Address_Line1__c = 'Line 1',
                    Address_Line2__c = 'Line 2',
                    Address_Line3__c = 'Line 3',
                    Address_Line4__c = 'Line 4',
                    City__c = 'City',
                    State__c = 'ON',
                    County__c = 'county',
                    Zip_Postal_Code__c = 'L8J 3S8',
                    Country__c = 'CA',
                    Identifying_Address__c = true,
                    CDH_Party__c = party3.Id,
                    Status__c = 'Active');

                insert address2;
            }
            return address2;
        }
    }

    @isTest static void processMergeVictimsTest() {
        List<CDH_Party__c> testParties = new List<CDH_Party__c>{party, party2};
        Account testAccount = account;

        Test.startTest();

        CDHPartyService.processMergeVictims(testParties);

        Test.stopTest();

        Set<Id> partyIds = new Set<Id>{party.Id, party2.Id};
        testParties = [SELECT Id, Active__c FROM CDH_Party__c WHERE Id IN :partyIds];
        System.assert(testParties.size() == 1);
        System.assert(testParties[0].Id == party.Id);
        System.assert(!testParties[0].Active__c);
    }

    @isTest static void processMergeSurvivorsTest() {
        List<CDH_Party__c> testParties = new List<CDH_Party__c>{party, party3};
        List<Account> testAccounts = new List<Account>{account, account2};
        List<EBS_Account__c> testEbsAccounts = new List<EBS_Account__c>{ebsAccount, ebsAccount2};
        List<Address__c> testAddresses = new List<Address__c>{address, address2};
        Map<String,List<Id>> survivorPartyNumberToAccountIdMap = new Map<String,List<Id>>{party3.Name => new List<Id>{account.Id, account2.Id}};

        Test.startTest();

        CDHPartyService.processMergeSurvivors(survivorPartyNumberToAccountIdMap);

        Test.stopTest();

        Set<Id> partyIds = new Set<Id>{party.Id, party3.Id};
        testParties = [SELECT Id, Active__c, (SELECT Id FROM Accounts__r) FROM CDH_Party__c WHERE Id IN :partyIds];
        System.assert(testParties.size() == 1);
        System.assert(testParties[0].Id == party3.Id);
        System.assert(testParties[0].Accounts__r != null);
        System.assert(!testParties[0].Accounts__r.isEmpty());

        Set<Id> accountIds = new Set<Id>{account.Id, account2.Id};
        testAccounts = [SELECT Id, (SELECT CDH_Party_Site_Number__c FROM Addresses__r), (SELECT Name FROM EBS_Account__r) FROM Account WHERE Id IN :accountIds];
        System.assertEquals(2, testAccounts.size());
        System.assert(testAccounts[0].Addresses__r != null);
        System.assertEquals(2, testAccounts[0].Addresses__r.size());
        System.assert(testAccounts[1].Addresses__r != null);
        System.assertEquals(2, testAccounts[1].Addresses__r.size());
        System.assert(testAccounts[0].EBS_Account__r != null);
        System.assertEquals(2, testAccounts[0].EBS_Account__r.size());
        System.assert(testAccounts[1].EBS_Account__r != null);
        System.assertEquals(2, testAccounts[1].EBS_Account__r.size());

        List<CDH_Party_Merge__c> mergeHistory = [SELECT Id, Success__c FROM CDH_Party_Merge__c WHERE Surviving_CDH_Party__c = :party3.Id];
        System.assert(!mergeHistory.isEmpty());
        System.assert(mergeHistory[0].Success__c);
    }

    @isTest static void processSiteMergeSurvivorsTest() {
        List<CDH_Party__c> testParties = new List<CDH_Party__c>{party, party3};
        List<Account> testAccounts = new List<Account>{account, account2};
        List<EBS_Account__c> testEbsAccounts = new List<EBS_Account__c>{ebsAccount, ebsAccount2};
        List<Address__c> testAddresses = new List<Address__c>{address, address2};

        IntegrationObjects.SalesAccount salesAccount = IntegrationObjectConverter.convertSalesAccount(OutboundSyncSelector.getAccountData(party3.Name));
        salesAccount.Addresses[0].IDList = new List<Id>{address.Id,address2.Id};

        Test.startTest();

        CDHPartyService.processSiteMergeSurvivors(new List<IntegrationObjects.SalesAccount>{salesAccount});

        Test.stopTest();
    }

    @isTest static void processSiteMergeSurvivorsNoAddressesTest() {
        List<CDH_Party__c> testParties = new List<CDH_Party__c>{party3};
        List<Account> testAccounts = new List<Account>{account2};
        List<EBS_Account__c> testEbsAccounts = new List<EBS_Account__c>{ebsAccount2};

        IntegrationObjects.SalesAccount salesAccount = IntegrationObjectConverter.convertSalesAccount(OutboundSyncSelector.getAccountData(party3.Name));

        Test.startTest();

        CDHPartyService.processSiteMergeSurvivors(new List<IntegrationObjects.SalesAccount>{salesAccount});

        Test.stopTest();
    }
}