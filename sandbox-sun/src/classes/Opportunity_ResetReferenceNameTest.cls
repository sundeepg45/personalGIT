/**
 * Class Name:Opportunity_ResetReferenceNameTest
 * Modificaton History: 6/28/2011 - Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 * Modified By : Nitesh Dokania
 * Modified date : 6/28/2011
 * Reason for Modification: Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 */
@IsTest
private class Opportunity_ResetReferenceNameTest {
    public static testmethod void  deployResetOpportunityReference()
    {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acc=new Account();
        acc.Name='TestAcc';
        acc.CurrencyIsoCode='USD';
        insert acc;
        
        Opportunity testOpp=new Opportunity();
        testOpp.Name='test';
        testOpp.StageName='Closed Won';    
        testOpp.closedate=System.today();
        testOpp.AccountId=acc.Id;
        testOpp.Reason_Closed_Lost_Marketing__c='Product';
        insert testOpp;
        
        // changed Opportunity StageName to 'propose' as Value Selling Enhancement July 20th Release.
        Opportunity opp=new Opportunity();
        opp.Name='test';
        opp.StageName='Propose';    
        opp.closedate=System.today();
        opp.AccountId=acc.Id;
        opp.Opportunity_Reference_Name__c=testOpp.Id;
        opp.Reason_Closed_Lost_Marketing__c='Product';
        insert opp;
        
        opp.StageName='Closed Lost';
        opp.ReasonWonLostSalesProcess__c='Per Finance Request';
        opp.Reason_Closed_Lost_Marketing__c='Product';
        update opp;

        // changed Opportunity StageName to 'propose' as Value Selling Enhancement July 20th Release.
        opp.StageName='Propose';
        opp.Reason_Closed_Lost_Marketing__c='Product';
        update opp;
    
        System.assertEquals(null, [Select Opportunity_Reference_Name__c
                                    from Opportunity
                                    where Id = :opp.Id].Opportunity_Reference_Name__c, 'The reference name field was not reset to null');

    }
}