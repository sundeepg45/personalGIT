@IsTest
private class CloseBizPlanTest {
    public static testmethod void testConfirmUpdate() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        insert account1;
        
        SFDC_Channel_Account_Plan__c businessPlan1 = new SFDC_Channel_Account_Plan__c();
        businessPlan1.Name = 'Business Plan #1';
        businessPlan1.Partner_Name__c = account1.Id;
        insert businessPlan1;
        
        Id resultId = CloseBizPlan.BizPlan(businessPlan1.Id);
        
        SFDC_Channel_Account_Plan__c businessPlan2 = [
            select Partner_Name__c
              from SFDC_Channel_Account_Plan__c
             where Id = :resultId
        ];
        
        system.assertEquals(businessPlan1.Partner_Name__c, businessPlan2.Partner_Name__c);
    }
    
    public static testMethod void testLegacyUnitTest() 
    {
        Account acc = new Account();
        acc.Name = 'Account #1';
        acc.isAccountActive__c = true;
        insert acc;
        
        SFDC_Channel_Account_Plan__c Bplan=new SFDC_Channel_Account_Plan__c();
        Bplan.Partner_Name__c= acc.Id; 
        Bplan.Name='test';
        Bplan.Approval_Status__c='Draft';
        insert Bplan;

        SFDC_Plan_Resource_Association__c test_Redacc=new SFDC_Plan_Resource_Association__c();
        test_Redacc.Account_Name__c= acc.Id; 
        test_Redacc.Channel_Plan__c=Bplan.Id;
        insert test_Redacc;

        CloseBizPlan.BizPlan(Bplan.Id);
    }  
}