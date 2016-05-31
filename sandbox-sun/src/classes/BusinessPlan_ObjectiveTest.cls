@IsTest
private class BusinessPlan_ObjectiveTest {
    public static BusinessPlan_ObjectiveSectionController instance {
        set;
        get;
    }
    
    public static testmethod void testGenerateCodeCoverage() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        account1.Global_Region__c = 'APAC';
        account1.Subregion__c = 'Japan';
        insert account1;
        
        SFDC_Channel_Account_Plan__c businessPlan1 = new SFDC_Channel_Account_Plan__c();
        businessPlan1.Name = 'Business Plan #1';
        businessPlan1.Partner_Name__c = account1.Id;
        insert businessPlan1;
        
        instance = new BusinessPlan_ObjectiveSectionController();
        instance = new BusinessPlan_ObjectiveSectionController(new ApexPages.StandardController(businessPlan1));
        
        system.assert(null != instance.businessPlanId);
        system.assert(null != instance.objectiveList);
    }

}