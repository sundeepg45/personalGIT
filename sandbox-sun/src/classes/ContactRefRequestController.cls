/**
* Class Name: ContactRefRequestController
* Author: Accenture
* Description: Creates a new Contact Reference and Submits it for approval
* Modificaton History:
* Modified By : Nitesh Dokania
* Modified date : 4/26/2011
* Reason for Modification: Separated test class from business class.
*/

public class ContactRefRequestController {
    
    private Contact_Reference_Request__c contactRefRequest;
        
    /*
    * Constructor - instantiates a new Contact_Reference_Request__c
    */
    public ContactRefRequestController(){
        this.contactRefRequest = new Contact_Reference_Request__c();
    }
    
    /*
    * Returns  Contact_Reference_Request__c
    */
    public Contact_Reference_Request__c getContactRefRequest(){   
        if (this.contactRefRequest == null){
            this.contactRefRequest = new Contact_Reference_Request__c();
        }
        return contactRefRequest;
    }
    
    /*
    * Action method called from the page
    * Creates the Contact_Reference_Request__c object and submits it for approval
    * Returns the result page which displays the submission message
    */
    public PageReference proceed() {
        
        //create new contact ref request  
        try{
            Id custRefId = ApexPages.currentPage().getParameters().get('id');
            createRecord(custRefId);            
        }
        catch(DmlException ex){
            ApexPages.addMessages(ex);
            return null;            
        }
        return Page.ContactRefRequestResult;            
    }
        
    /*
    * Action method called from the page
    * Returns back the Customer Reference page
    */
    public PageReference doCancel() {
        String url = '/' + System.currentPageReference().getParameters().get('id');
        PageReference pageRef = new PageReference(url);  
        pageRef.setRedirect(true); 
        return pageRef;
    }
    
    
    /*
    * Create the Contact Reference Request Record 
    */
    private void createRecord(Id custRefId){
        Customer_Reference__c cr = [select id, ownerId, Account__r.OwnerId, Private_Contact__c from Customer_Reference__c where Id = : custRefId];
        
        contactRefRequest.ownerId = getOwnerId(cr); 
        contactRefRequest.Customer_Reference__c = custRefId;
        contactRefRequest.Requested_Contact__c = cr.Private_Contact__c;
                
        //Create the record and submit it for approval
        insert contactRefRequest;
        
        submitForApproval(contactRefRequest.Id);
    }   
    
    
    /*
    * Submit the Record for approval
    */
    private void submitForApproval(Id contactRefRequestId){
    
        Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();
        approvalReq.setComments('Submitted.');
        approvalReq.setObjectId(contactRefRequestId);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(approvalReq);
        
        // Verify the result
        System.assert(result.isSuccess());  
          
        
    }
    
    /*
    * Returns the ownerId to be set on the new record
    * Returns - The account OwnerId if owner is active else the owner of the Customer Reference
    */
    private Id getOwnerId(Customer_Reference__c cr) {
        Id crAccountOwnerId = cr.Account__r.OwnerId;
        //check if the user is active
        Boolean active = [Select IsActive from user where Id = :crAccountOwnerId].IsActive;
        
        return (active) ? crAccountOwnerId : cr.OwnerId;
    }  
}