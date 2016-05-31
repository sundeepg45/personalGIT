@IsTest(SeeAllData=true)
private class BusinessPlan_CustomerSectionCtrlTest {
    static testmethod void simpletest() {
   		SFDC_Channel_Account_Plan__c bp = [select Id from SFDC_Channel_Account_Plan__c limit 1];

        ApexPages.StandardController stdctrl = new ApexPages.StandardController(bp);
        BusinessPlan_CustomerSectionController ctrl = new BusinessPlan_CustomerSectionController(stdctrl);
        Business_Plan_Customer__c[] bpclist = ctrl.getCustomers();
    }
    
}