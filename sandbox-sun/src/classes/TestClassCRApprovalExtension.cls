/**
* Class Name:TestClassCRApprovalExtension
* Modified by : Nitesh Dokania
* Reason for Modification: Enhanced the test coverage.
*/


@IsTest
private class TestClassCRApprovalExtension 
{
	static testmethod void CRApprovalExtension() 
	{
    	User user  = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
        RecordType partnerRecordType =[Select r.Name, r.Id From RecordType r where r.name='EMEA Partner'];
        Account a = new Account();
    	a.ownerId = user.Id;
	    a.name = 'Test';
	    a.BillingStreet = 'Test';
	    a.BillingCity = 'Test';
	    a.BillingState = 'CA';
	    a.BillingCountry = 'US';
	    a.ShippingState = 'CA';
	    a.ShippingCountry = 'US';
	    a.RecordTypeId = partnerRecordType.Id;
	    insert a;
    
    	Contact contact = new Contact();
        contact.FirstName = 'FirstName';
        contact.LastName = 'LastName';
        contact.Email = 'email@example.com';
        contact.AccountId = a.Id;
        contact.ownerId = user.Id;
        insert contact;
        
        Customer_Reference__c customerRef = new Customer_Reference__c();
        customerRef.Account__c = a.Id;
        customerRef.Contact__c = contact.Id;
        customerRef.Approval_Status__c ='Draft';
        customerRef.Greeting__c ='Mr';
        customerRef.Contact_First_Name__c = 'TestFS';
        customerRef.Contact_Last_Name__c ='TestLS';
        customerRef.Contact_Phone__c ='4156325768';
        customerRef.Contact_Email__c='a@b.com';
        customerRef.Company_Name__c ='Apprivo';
        customerRef.Industry__c ='Tech - SW';
        customerRef.Quote_from__c = 'Test';
        customerRef.Please_describe_how_the_customer_benefit__c ='Test';
        customerRef.Please_describe_the_solution_benefit__c ='Test';
        customerRef.Pl__c = 'Test';
        insert customerRef;
        
        Customer_Reference_Product__c customerRefPrd = new Customer_Reference_Product__c();
        customerRefPrd.Product__c = 'RHEL Server';
        customerRefPrd.Customer_Reference__c = customerRef.Id;
        customerRefPrd.Quantity__c = 4;
        customerRefPrd.Version__c = '1.1';
        insert customerRefPrd;
        
        Customer_Reference__c customerRefObj = new Customer_Reference__c();
        customerRefObj.Account__c = a.Id;
        customerRefObj.Contact__c = contact.Id;
        customerRefObj.Approval_Status__c ='Draft';
        customerRefObj.Greeting__c ='Mr';
        customerRefObj.Contact_First_Name__c = 'TestFS';
        customerRefObj.Contact_Last_Name__c ='TestLS';
        customerRefObj.Contact_Phone__c ='4156325768';
        customerRefObj.Contact_Email__c='a@b.com';
        customerRefObj.Company_Name__c ='Apprivo';
        customerRefObj.Industry__c ='Tech - SW';
        customerRefObj.Quote_from__c = 'Test';
        customerRefObj.Please_describe_how_the_customer_benefit__c ='Test';
        customerRefObj.Please_describe_the_solution_benefit__c ='Test';
        customerRefObj.Pl__c = 'Test';
        insert customerRefObj;
        
        test.startTest();
        
        Customer_Reference__c custRef = new Customer_Reference__c();
        CRApprovalExtension controller = new CRApprovalExtension(new ApexPages.StandardController(customerRef));
        custRef = controller.getCustomerReference();
        controller.submitForApproval();
        controller.addProducts();
        Approval.ProcessResult result = CRApprovalExtension.submitForApproval(customerRef.Id, 'Submitting Customer Reference for Approval.');
        
        System.assertEquals(customerRef, custRef);
        System.assertEquals(true, result.isSuccess());
        
        Customer_Reference__c custRefe = new Customer_Reference__c();
        CRApprovalExtension controllerObj = new CRApprovalExtension(new ApexPages.StandardController(customerRefObj));
        custRefe = controllerObj.getCustomerReference();
        controllerObj.submitForApproval();
        controllerObj.addProducts();
        Approval.ProcessResult result1 = CRApprovalExtension.submitForApproval(customerRefObj.Id, 'Submitting Customer Reference for Approval.');
        
        System.assertEquals(customerRefObj, custRefe);
        System.assertEquals(true, result1.isSuccess());
        
        test.stopTest();
     }
}