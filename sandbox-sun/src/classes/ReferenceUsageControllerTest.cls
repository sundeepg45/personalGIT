/**
* Class Name:ReferenceUsageControllerTest
* Author:Accenture
* Date:4/12/2011
* Description: Test Class created for ReferenceUsageController business Class
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :4/12/2011
* Reason for Modification:Separated test class from business class and created a new test class
*/




@isTest
private class ReferenceUsageControllerTest
{
    public static testMethod void unit() {

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
            Account__c = acc.Id, OwnerId = UserInfo.getUserId(), Opportunity__c = opp.Id);
        c.Industry__c = 'Education';
        c.dealSize__c = '< $50,000';
        c.Type__c = 'Quote';
        c.solutionList__c = 'Multimedia';
        c.Search_Keywords__c = 'test';
        insert c;   
        
        Reference_Collateral__c rcc = new Reference_Collateral__c();
        rcc.Customer_Reference__c = c.Id;
        rcc.Email_Template_ID__c = '00X456789012345';
        insert rcc; 

        PageReference pageRef = Page.ReferenceUsage;
        Test.setCurrentPage(pageRef);
        ReferenceUsageController controller = new ReferenceUsageController();
        ApexPages.currentPage().getParameters().put('cid', c.Id);         
        ApexPages.currentPage().getParameters().put('rid', rcc.Id);
        controller.getcusRefIn();
        
        controller.cusRefin = [select OwnerId, Industry__c, dealSize__c, Type__c, solutionList__c, Search_Keywords__c, Opportunity__c, Contact__c
                                from Customer_Reference__c 
                                where OwnerId!=null and Industry__c!=null and dealSize__c!=null and Type__c!=null and solutionList__c!=null and Search_Keywords__c!=null
                                limit 1];           
        
        
        controller.proceed();
        controller.cancel();
        //controller.getcusRefIn();
    }
}