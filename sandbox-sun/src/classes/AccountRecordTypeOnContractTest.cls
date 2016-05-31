/**
* Class Name: AccountRecordTypeOnContractTest
* Description: Test Class created for AccountRecordTypeOnContract Class
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date :09/20/2011
* Reason for Modification: Added assert statement and starttest stoptest.
*/

@isTest
private class AccountRecordTypeOnContractTest {

    static testMethod void contractTest() {
        // TO DO: implement unit test

        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acc = new Account();
        acc.Name = 'Test Account';
        //acc.RecordTypeId = '012300000000NBG';
        insert acc;
        
        Contract cont = new Contract();
        cont.Status = 'Draft';
        cont.Notes_from_Sales__c = 'Test Notes';
        cont.Deal_Type__c = 'Amentra';
        cont.CountryOfOrder__c = 'Japan';
        //cont.Contract_Type__c = 'Amendment';
        cont.AccountId = acc.Id;
        insert cont;
        
        acc.RecordTypeId = '012300000000Qgl';
        update acc;
        
        test.startTest();
        
        Contract con = [Select Account_Record_Type__c, Id from Contract where id=: cont.Id];
        
        System.assertEquals('APAC Account',con.Account_Record_Type__c);
        
        test.stopTest();
    }
}