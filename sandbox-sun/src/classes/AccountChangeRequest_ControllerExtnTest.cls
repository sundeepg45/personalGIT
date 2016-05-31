/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class AccountChangeRequest_ControllerExtnTest {
    static Account queryAccount(Id id) {
        return [
            select
                Name,
                Data_Status__c,
                RecordTypeId,
                AccountClassification__c,
                BillingCity,
                BillingStreet,
                Certified_Service_Provider__c,
                CreatedDate,
                Hours_to_Review__c,
                Middleware_Supported__c,
                OwnerId,
                Ownership,
                Total_of_Subsidiaries_if_Parent__c,
                VATNumber__c,
                What_Markets_are_Targeted__c
            from Account
            where Id = :id ];
    }

    static Account account {
        get {
            if(account == null) {
                RecordType recordType = [select Id,name from RecordType where name = 'Strategic' and SObjectType = 'Account' limit 1];
                account = new Account(
                        Name='TestAccount '+recordType.id,
                        Data_Status__c=AccountTriggerBefore.PENDING_UPDATE,
                        RecordTypeId=recordType.Id,
                        AccountClassification__c='EMEA - Hosting',
                        BillingCity='Testville',
                        BillingStreet='1 no where',
                        Certified_Service_Provider__c=false,
                        Middleware_Supported__c='None',
                        OwnerId = UserInfo.getUserId(),
                        Ownership='Private',
                        Total_of_Subsidiaries_if_Parent__c=5,
                        VATNumber__c=null,
                        What_Markets_are_Targeted__c='Vertical market');
                AccountChangeRequest_ControllerExtension.isDataStatusUpdateable = true;
                insert account;
                AccountChangeRequest_ControllerExtension.isDataStatusUpdateable = null;
                account = queryAccount(account.Id);
            }
            return account;
        }
    }

    static Account refAccount {
        get {
            if(refAccount == null) {
                refAccount = new Account(
                    Name='TestAccount2 '+recordType.id,
                    BillingCity='Testville 2',
                    Certified_Service_Provider__c=true,
                    OwnerId = UserInfo.getUserId(),
                    Ownership='Public',
                    Total_of_Subsidiaries_if_Parent__c=1);
            }
            return refAccount;
        }
    }

    static AccountChangeRequest__c accountChangeRequest {
        get {
            if(accountChangeRequest == null) {
                accountChangeRequest = new AccountChangeRequest__c(Account__c=account.Id);
                insert accountChangeRequest;
                accountChangeRequest = [select Account__c,Status__c,Comments__c from AccountChangeRequest__c where Id = :accountChangeRequest.Id];
            }
            return accountChangeRequest;
        }
    }

    static List<AccountChangeRequestField__c> acrfs {
        get {
            if(acrfs == null) {
                acrfs = new List<AccountChangeRequestField__c>();
                acrfs.add(new AccountChangeRequestField__c(
                    ChangeRequest__c = accountChangeRequest.Id,
                    FieldName__c = 'Name',
                    TextValue__c = refAccount.Name,
                    OriginalTextValue__c = account.Name));
                acrfs.add(new AccountChangeRequestField__c(
                    ChangeRequest__c = accountChangeRequest.Id,
                    FieldName__c = 'BillingCity',
                    TextValue__c = refAccount.BillingCity,
                    OriginalTextValue__c = account.BillingCity));
                acrfs.add(new AccountChangeRequestField__c(
                    ChangeRequest__c = accountChangeRequest.Id,
                    FieldName__c = 'OwnerId',
                    TextValue__c = refAccount.OwnerId,
                    OriginalTextValue__c = account.OwnerId));
                acrfs.add(new AccountChangeRequestField__c(
                    ChangeRequest__c = accountChangeRequest.Id,
                    FieldName__c = 'Certified_Service_Provider__c',
                    TextValue__c = String.valueof(refAccount.Certified_Service_Provider__c),
                    BooleanValue__c = refAccount.Certified_Service_Provider__c,
                    OriginalTextValue__c = String.valueof(account.Certified_Service_Provider__c),
                    OriginalBooleanValue__c = account.Certified_Service_Provider__c));
                acrfs.add(new AccountChangeRequestField__c(
                    ChangeRequest__c = accountChangeRequest.Id,
                    FieldName__c = 'Ownership',
                    TextValue__c = refAccount.Ownership,
                    OriginalTextValue__c = account.Ownership));
                acrfs.add(new AccountChangeRequestField__c(
                    ChangeRequest__c = accountChangeRequest.Id,
                    FieldName__c = 'Total_of_Subsidiaries_if_Parent__c',
                    TextValue__c = String.valueof(refAccount.Total_of_Subsidiaries_if_Parent__c),
                    OriginalTextValue__c = String.valueof(account.Total_of_Subsidiaries_if_Parent__c)));
                insert acrfs;
            }
            return acrfs;
        }
    }

    static AccountChangeRequest_ControllerExtension getController(AccountChangeRequest__c changeRequest) {
        ApexPages.StandardController sc = new ApexPages.StandardController(changeRequest);
        AccountChangeRequest_ControllerExtension controller = new AccountChangeRequest_ControllerExtension(sc);
        return controller;
    }

    static testMethod void controllerTest() {
        System.assert(! acrfs.isEmpty());
        AccountChangeRequest_ControllerExtension controller = getController(accountChangeRequest);
        System.assert(AccountChangeRequest_ControllerExtension.isDataStatusUpdateable);
        System.assert(! controller.isReviewed);
        System.assert(controller.isEdit);
        System.assertEquals(acrfs.size(),controller.pendingChanges.size());
        System.assertEquals(0,controller.approvedChanges.size());
        System.assertEquals(0,controller.rejectedChanges.size());
        System.assertEquals(account.Name,controller.account.Name);
        System.assertEquals(account.BillingCity,controller.account.BillingCity);
        System.assertEquals(account.OwnerId,controller.account.OwnerId);
        User u1 = [select Name from User where Id = :account.OwnerId];
        System.assertEquals(u1.Name,controller.account.Owner.Name);
        System.assertEquals(account.Total_of_Subsidiaries_if_Parent__c,controller.account.Total_of_Subsidiaries_if_Parent__c);
        controller.updateRefAccount();
        System.assertEquals(refAccount.Name,controller.refAccount.Name);
        System.assertEquals(refAccount.BillingCity,controller.refAccount.BillingCity);
        System.assertEquals(refAccount.OwnerId,controller.refAccount.OwnerId);
        System.assertEquals(refAccount.Total_of_Subsidiaries_if_Parent__c,controller.refAccount.Total_of_Subsidiaries_if_Parent__c);
        User u2 = [select Name from User where Id = :refAccount.OwnerId];
        System.assertEquals(u2.Name,controller.refAccount.Owner.Name);
        System.assertNotEquals(null,controller.cancel());
        for(AccountChangeRequest_ControllerExtension.Change c : controller.pendingChanges) {
            System.assert(! c.accountChangeRequestField.Approved__c);
            System.assertNotEquals(null,c.label);
            System.assertNotEquals(null,c.displayType);
            System.assertNotEquals(null,c.newValue);
            System.assertNotEquals(null,c.oldValue);
            System.assertNotEquals(null,c.newTextValue);
            System.assertNotEquals(null,c.oldTextValue);
            if(c.accountChangeRequestField.FieldName__c == 'OwnerId') {
                System.assertNotEquals(null,c.oldReference);
                System.assertNotEquals(null,c.newReference);
                System.assertNotEquals(null,c.oldName);
                System.assertNotEquals(null,c.newName);
            }
            else {
                System.assertEquals(null,c.oldReference);
                System.assertEquals(null,c.newReference);
                System.assertEquals(null,c.oldName);
                System.assertEquals(null,c.newName);
            }
            c.accountChangeRequestField.Approved__c = true;
        }
        System.assertNotEquals(null,controller.save());
        for(AccountChangeRequestField__c acrf : [
            select
                Approved__c
            from AccountChangeRequestField__c
            where ChangeRequest__c = :accountChangeRequest.Id]
        ) {
            System.assert(acrf.Approved__c);
        }
        // C360 has disabled the part of this feature that writes the pending changes to the account upon approval
        //Account a = [select Name,BillingCity,OwnerId,Total_of_Subsidiaries_if_Parent__c from Account where Id = :account.Id];
        //System.assertEquals(a.Name,controller.refAccount.Name);
        //System.assertEquals(a.BillingCity,controller.refAccount.BillingCity);
        //System.assertEquals(a.OwnerId,controller.refAccount.OwnerId);
        //System.assertEquals(a.Total_of_Subsidiaries_if_Parent__c,controller.refAccount.Total_of_Subsidiaries_if_Parent__c);
        accountChangeRequest.Status__c = AccountChangeRequest_ControllerExtension.REVIEWED;
        controller = getController(accountChangeRequest);
        System.assertEquals(0,controller.pendingChanges.size());
        System.assertEquals(acrfs.size(),controller.approvedChanges.size());
        System.assertEquals(0,controller.rejectedChanges.size());
        List<AccountChangeRequestField__c> xacrfs = new List<AccountChangeRequestField__c>();
        for(AccountChangeRequest_ControllerExtension.Change c : controller.approvedChanges) {
            c.accountChangeRequestField.Approved__c = false;
            xacrfs.add(c.accountChangeRequestField);
        }
        update xacrfs;
        controller = getController(accountChangeRequest);
        System.assertEquals(0,controller.pendingChanges.size());
        System.assertEquals(0,controller.approvedChanges.size());
        System.assertEquals(acrfs.size(),controller.rejectedChanges.size());
    }

    static testMethod void putValueTest() {
        Account a = new Account();
        Integer i = 1;
        AccountChangeRequest_ControllerExtension.putValue(a,'NumberOfEmployees',i,null);
        System.assertEquals(i,a.NumberOfEmployees);
        AccountChangeRequest_ControllerExtension.putValue(a,'NumberOfEmployees',null,i);
        System.assertEquals(null,a.NumberOfEmployees);
        Decimal d = 1.0;
        AccountChangeRequest_ControllerExtension.putValue(a,'Total_of_Subsidiaries_if_Parent__c',d,null);
        System.assertEquals(d,a.Total_of_Subsidiaries_if_Parent__c);
        AccountChangeRequest_ControllerExtension.putValue(a,'Total_of_Subsidiaries_if_Parent__c',null,d);
        System.assertEquals(null,a.Total_of_Subsidiaries_if_Parent__c);
        Date t = System.today();
        AccountChangeRequest_ControllerExtension.putValue(a,'RequalificationDate__c',t,null);
        System.assertEquals(t,a.RequalificationDate__c);
        AccountChangeRequest_ControllerExtension.putValue(a,'RequalificationDate__c',null,t);
        System.assertEquals(null,a.RequalificationDate__c);
        DateTime n = DateTime.now();
        AccountChangeRequest_ControllerExtension.putValue(a,'Time_and_Date_Approved__c',n,null);
        System.assertEquals(n,a.Time_and_Date_Approved__c);
        AccountChangeRequest_ControllerExtension.putValue(a,'Time_and_Date_Approved__c',null,n);
        System.assertEquals(null,a.Time_and_Date_Approved__c);
        Boolean b = false;
        AccountChangeRequest_ControllerExtension.putValue(a,'I_Agree_to_the_Terms_and_Conditions__c',b,null);
        System.assertEquals(b,a.I_Agree_to_the_Terms_and_Conditions__c);
        AccountChangeRequest_ControllerExtension.putValue(a,'I_Agree_to_the_Terms_and_Conditions__c',null,b);
//      System.assertEquals(null,a.I_Agree_to_the_Terms_and_Conditions__c);
        String s = 'anything';
        AccountChangeRequest_ControllerExtension.putValue(a,'BillingCity',s,null);
        System.assertEquals(s,a.BillingCity);
        AccountChangeRequest_ControllerExtension.putValue(a,'BillingCity',null,s);
        System.assertEquals(null,a.BillingCity);
        Id ownerId = UserInfo.getUserId();
        AccountChangeRequest_ControllerExtension.putValue(a,'OwnerId',ownerId,null);
        System.assertEquals(ownerId,a.OwnerId);
        AccountChangeRequest_ControllerExtension.putValue(a,'OwnerId',null,ownerId);
        System.assertEquals(null,a.OwnerId);
    }

    static testMethod void testDataStatusAdminPermissions() {
        System.assert(AccountChangeRequest_ControllerExtension.isDataStatusAccessible);
        System.assert(AccountChangeRequest_ControllerExtension.isDataStatusUpdateable);
    }
}