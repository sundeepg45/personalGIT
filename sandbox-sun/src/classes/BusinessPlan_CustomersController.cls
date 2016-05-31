public without sharing class BusinessPlan_CustomersController {

   	private	ID							bpId;
    public	Business_Plan_Customer__c	edited {get; set; }
    public	Business_Plan_Customer__c[]	customerList {get; private set; }
    public	Boolean						isLocked {get; private set; }
    
    public BusinessPlan_CustomersController() {
        String tmpid = (String) ApexPages.currentPage().getParameters().get('bpid');
        System.debug('*****[debug]***** tmpid=' + tmpid);
        if (tmpid != null) {
	        bpId = (ID) tmpid;
            SFDC_Channel_Account_Plan__c bp = [select RecordTypeId from SFDC_Channel_Account_Plan__c where Id = :bpId];
	        isLocked = [select DeveloperName from RecordType where Id = :bp.RecordTypeId].DeveloperName == 'Business_Plan_Locked';
        }
    }

    public Business_Plan_Customer__c[] getCustomers() {
        if (customerList == null) {
            customerList = [
                select	Id, Customer_Name__c, Technology__c, Technology_Goal__c, Delivering_All_Tech__c, Willing_To_Influence__c
                from	Business_Plan_Customer__c
                where	Business_Plan__c = :bpId
            ];
        }
        return customerList;
    }

    public PageReference newRecord() {
        if (bpId != null) {
	        edited = new Business_Plan_Customer__c();
    	    edited.Business_Plan__c = bpId;
        }
        return null;
    }
    
    public PageReference toPlan() {
        PageReference ref = new PageReference('/' + bpId);
        ref.setRedirect(true);
        return ref;
    }
    
    public PageReference save() {
        if (edited.Customer_Name__c == null || edited.Customer_Name__c.length() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Business_Plan_Customer_Name_Required));
        }
        if (edited.Technology_Goal__c == null || edited.Technology_Goal__c.length() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Business_Plan_Technology_Required));
        }
        if (ApexPages.hasMessages()) {
            return null;
        }
        upsert edited;
        edited = null;
        customerList = null;
        return null;
    }

    public PageReference cancel() {
        System.debug('*****[debug]***** cancel button');
        edited = null;
        return null;
    }
    
    public PageReference edit() {
        String custId = ApexPages.currentPage().getParameters().get('customerId');
        if (custId != null) {
            edited = [
                select	Id, Customer_Name__c, Technology__c, Technology_Goal__c, Delivering_All_Tech__c, Willing_To_Influence__c
                from	Business_Plan_Customer__c
                where	Id = :custId
            ];
        }
        return null;
    }

    public PageReference remove() {
        String custId = ApexPages.currentPage().getParameters().get('customerId');
        if (custId != null) {
            delete [select Id from Business_Plan_Customer__c where Id = :custId];
            customerList = null;
        }
        return null;
    }

}