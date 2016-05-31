/**
 * Class Name:Opportunity_UpdateFirstYearPaymentTest
 * Description:Contains test methods for Opportunity related triggers. 
 * Modificaton History: 6/28/2011 - Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 * Modified By : Abhijeet Anand
 * Modified date : 6/28/2011
 * Reason for Modification: Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 */ 
 
@IsTest
private class Opportunity_UpdateFirstYearPaymentTest {
    /**
     *  This unit test will fire a trigger on Opportunity to populate
     *  First Year payment field on opportunity if Pay Now is Yes
     *
     *  New Account and Opportunity are created
     *  Author: Gaurav Gupte
     */
    public static testmethod void testUpdateFirstYear() {

        DeactivateAllTestUtil.setDeactivateAll(false);

        Account account = new Account();
        account.Name = 'Test Account';
        account.CurrencyIsoCode='USD';
        insert account;
    
        User username=[Select Id,Name,Department from User where IsActive=true limit 1];

        Opportunity opp=new Opportunity();
        opp.OwnerId=username.Id;
        opp.Name='Test opp';
        opp.StageName='Prepare'; //changed the opportunity stagename value to Prepare as part of Value Selling enhancement.July 20th release 
        opp.closedate=System.today();
        opp.AccountId=account.Id;
        opp.Amount=600;
        opp.Pay_Now__c='Yes';
        insert opp;
        System.assertEquals(600, [Select Year1PaymentAmount__c from Opportunity where Id =:opp.Id].Year1PaymentAmount__c);
        
        opp.Amount=null;
        update opp;
        
        System.assertEquals(null, [Select Year1PaymentAmount__c from Opportunity where Id =:opp.Id].Year1PaymentAmount__c);
    
    }
}