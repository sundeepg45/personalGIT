@IsTest
private class CloneBizPlanTest {
    public static testmethod void testConfirmUpdate() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        insert account1;
        
        SFDC_Channel_Account_Plan__c businessPlan1 = new SFDC_Channel_Account_Plan__c();
        businessPlan1.Name = 'Business Plan #1';
        businessPlan1.Partner_Name__c = account1.Id;
        insert businessPlan1;
        
        Id resultId = CloneBizPlan.BizPlan(businessPlan1.Id);
        
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
        Bplan.Business_Plan_Version__c=1;
        insert Bplan;

        SFDC_Objective__c test_obj=new SFDC_Objective__c();
        test_obj.Name='test';
        test_obj.Account_Name__c= acc.Id; 
        test_obj.Channel_Plan__c=Bplan.Id;
        insert test_obj;

        SFDC_Plan_Resource_Association__c test_Redacc=new SFDC_Plan_Resource_Association__c();
        test_Redacc.Account_Name__c= acc.Id; 
        test_Redacc.Channel_Plan__c=Bplan.Id;
        insert test_Redacc;

        Key_Joint_Sales_Engagement__c test_Key=new Key_Joint_Sales_Engagement__c();
        test_Key.Name='test';
        test_Key.Account_Name__c= acc.Id; 
        test_Key.Channel_Plan__c=Bplan.Id;
        insert test_Key;

        Campaign_Plan__c test_Camp=new Campaign_Plan__c();
        test_Camp.Name='test';
        test_Camp.Account__c= acc.Id; 
        test_Camp.Business_Plan__c=Bplan.Id;
        insert test_Camp;
        
        CloneBizPlan.BizPlan(Bplan.Id);
    }  
}