/**
* Class Name:ContactRefRequestControllerTest
* Description:Test Class created for ContactRefRequestController business Class.
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :4/26/2011
* Reason for Modification: Separated test class from business class and created a new test class
* Modified By :Abhijeet Anand
* Reason for Modification:Enhanced code coverage and added assert statements.
*/

@isTest
private class ContactRefRequestControllerTest
{
    public static testMethod void unit() 
    {
        //create a test account
        Account acc = new Account(Name = 'Test Account', BillingState = 'CA', OwnerId = UserInfo.getUserId());
        insert acc;
        
        //create a test opp
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Solution', CloseDate = Date.today());
        insert opp;
        
        //create a test contact
        Contact con = new Contact(AccountId = acc.Id, LastName = 'tester', OwnerId = UserInfo.getUserId());
        insert con; 
        
        //create a test Customer_Reference__c
        Customer_Reference__c c = new Customer_Reference__c(Contact__c = con.Id,
            Account__c = acc.Id, OwnerId = UserInfo.getUserId());
        insert c; 
       
        test.startTest();
        
        //set the page ref to this Customer_Reference__c
        Test.setCurrentPageReference(new PageReference('Page.ContactRefRequest')); 
        System.currentPageReference().getParameters().put('id', c.id);
        
        //call the controller and set the oppty 
        ContactRefRequestController controller = new ContactRefRequestController();
        controller.getContactRefRequest();
        //call proceed 
        controller.proceed();
        
        Contact_Reference_Request__c c1= new Contact_Reference_Request__c();
        c1 = [Select Supported_Opportunity__c from Contact_Reference_Request__c where Id = :controller.getContactRefRequest().id];
        
        System.assertEquals(controller.getContactRefRequest().Supported_Opportunity__c,c1.Supported_Opportunity__c);
            
        controller.doCancel();
        
        test.stopTest();
        
    }
    
    public static testMethod void unitTest() 
    {
        test.startTest();
        
        //set the page ref to this Customer_Reference__c
        Test.setCurrentPageReference(new PageReference('Page.ContactRefRequest')); 
        System.currentPageReference().getParameters().put('id', null);
        
        ContactRefRequestController cntrlr = new ContactRefRequestController();
        cntrlr.getContactRefRequest();
        
        test.stopTest();
    }
}