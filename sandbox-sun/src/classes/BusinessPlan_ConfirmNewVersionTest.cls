@IsTest
private class BusinessPlan_ConfirmNewVersionTest {
    public static BusinessPlan_ConfirmNewVersion instance {
        set;
        get;
    }
    
    public static testmethod void testConfirmUpdate() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        insert account1;
        
        SFDC_Channel_Account_Plan__c businessPlan1 = new SFDC_Channel_Account_Plan__c();
        businessPlan1.Name = 'Business Plan #1';
        businessPlan1.Partner_Name__c = account1.Id;
        insert businessPlan1;
        
        instance = new BusinessPlan_ConfirmNewVersion(new ApexPages.StandardController(businessPlan1));
        instance.confirmUpdate();
    }

    public static testmethod void testCancelUpdate() {
        Account account1 = new Account();
        account1.Name = 'Account #1';
        insert account1;
        
        SFDC_Channel_Account_Plan__c businessPlan1 = new SFDC_Channel_Account_Plan__c();
        businessPlan1.Name = 'Business Plan #1';
        businessPlan1.Partner_Name__c = account1.Id;
        insert businessPlan1;
        
        instance = new BusinessPlan_ConfirmNewVersion(new ApexPages.StandardController(businessPlan1));
        instance.cancelUpdate();
    }
}