/**
 * Class Name:Opportunity_UpdateOwnerDepartmentTest
 * Modificaton History: 6/29/2011 - Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 * Modified By : Nitesh Dokania
 * Modified date :6/29/2011
 * Reason for Modification: Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 */ 
 
@IsTest
private class Opportunity_UpdateOwnerDepartmentTest {
    /**
     *  This unit test will fire a trigger on Opportunity to populate
     *  owner's department on opportunity.
     *
     *  New Account and Opportunity are created
     *  Author: Gaurav Gupte
     */
    public static testmethod void testUpdateDept() {

        Account account = new Account();
        account.Name = 'Test Account';
        account.CurrencyIsoCode='USD';
        insert account;
    
        User username=[Select Id,Name,Department from User where IsActive=true limit 1];

        // changed Opportunity StageName to 'Prepare' as Value Selling Enhancement July 20th Release.
        Opportunity opp=new Opportunity();
        opp.OwnerId=username.Id;
        opp.Name='Test opp';
        opp.StageName='Prepare';    
        opp.closedate=System.today();
        opp.AccountId=account.Id;
        insert opp;

        // changed Opportunity StageName to 'Negotiate' as Value Selling Enhancement July 20th Release.
        opp.StageName='Negotiate';
        update opp;

        System.assertEquals(username.Department, [Select Department__c from Opportunity where Id =:opp.Id].Department__c);

        opp.StageName='Closed Won';
        update opp;
    
    }
}