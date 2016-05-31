public without sharing class BusinessPlan_CustomerSectionController {

    public SFDC_Channel_Account_Plan__c	bp {get; private set; }
	private Business_Plan_Customer__c[]	customerList;


	public BusinessPlan_CustomerSectionController(ApexPages.StandardController controller)  { 
		bp = (SFDC_Channel_Account_Plan__c) controller.getRecord();
    }
    
    public Business_Plan_Customer__c[] getCustomers() {
        if (customerList == null) {
            customerList = [
                select	Id, Customer_Name__c, Technology__c, Technology_Goal__c, Delivering_All_Tech__c, Willing_To_Influence__c
                from	Business_Plan_Customer__c
                where	Business_Plan__c = :bp.Id
            ];
        }
        return customerList;
    }
    
}