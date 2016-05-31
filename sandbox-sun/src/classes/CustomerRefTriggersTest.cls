public class CustomerRefTriggersTest {

    /*
    * Unit Test for processContactRequestApproval.trigger
    */
    public static testMethod void testProcessContactReqApproval() {
       
        Customer_Reference__c customerRef = new Customer_Reference__c(Approval_Status__c = 'Draft');
        insert customerRef;
        Contact_Reference_Request__c contactRefRequest 
            = new Contact_Reference_Request__c(Approval_Status__c = 'Draft', Customer_Reference__c = customerRef.id);
        insert contactRefRequest;
        
        Customer_Reference_Product__c customerReferencePrd = new Customer_Reference_Product__c( Customer_Reference__c=customerRef.Id,Product__c ='RHEL Server',Quantity__c=10);
        insert customerReferencePrd;
        contactRefRequest.Approval_Status__c = 'Approved';
        update contactRefRequest;
    }
    
    /*
    * Unit Test for processCustomerReferenceApprovals.trigger
    */
    public static testMethod void testProcessCustomerRefApproval() {
        Customer_Reference__c customerRef = new Customer_Reference__c(Approval_Status__c = 'Draft');
        insert customerRef;
        Customer_Reference_Product__c customerReferencePrd = new Customer_Reference_Product__c( Customer_Reference__c=customerRef.Id,Product__c ='RHEL Server',Quantity__c=10);
        insert customerReferencePrd;
        customerRef.Approval_Status__c = 'Approved';
        update customerRef;
    }
}