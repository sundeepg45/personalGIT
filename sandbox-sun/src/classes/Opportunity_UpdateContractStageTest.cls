/**
 * Class Name:Opportunity_UpdateContractStageTest
 * Modificaton History: 6/28/2011 - Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 * Modified By : Nitesh Dokania
 * Modified date :6/28/2011
 * Reason for Modification: Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 */
@IsTest
private class Opportunity_UpdateContractStageTest {
    public static testmethod void  deployOpportunity_UpdateContractStage()
    {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acc=new Account();
        acc.Name='TestAcc';
        acc.CurrencyIsoCode='USD';
        insert acc;
        
        // changed Opportunity StageName to 'Prepare' as Value Selling Enhancement July 20th Release.
        Opportunity testOpp=new Opportunity();
        testOpp.Name='test';
        testOpp.StageName='Prepare';    
        testOpp.closedate=System.today();
        testOpp.AccountId=acc.Id;
        insert testOpp;
        
        Contract con=new Contract();
        con.AccountId=acc.Id;
        con.Opportunity__c=testOpp.Id;
        con.Deal_Type__c='Amentra';
        con.Region__c='APAC';
        con.SubRegion__c='Australia';
      //  con.Contract_Type__c='Assignments';
        con.Stage__c='New';
        con.Status='Draft';
        con.Notes_from_Sales__c='ABC';
        insert con;

        
        testOpp.StageName='Closed Won';
        update testOpp;

        System.assertEquals('Completed', [ Select Status
                                    from Contract
                                    where Id= :con.Id].Status, 'Not matched');


    }
}