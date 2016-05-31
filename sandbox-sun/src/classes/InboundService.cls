/*****************************************************************************************
    Name    : InboundService
    Desc    : This class is container for all the service method related to different business objects(for the inbound interface)       
                            
    Modification Log : 
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Vipul Jain            11 JUL 2014        
    Scott Coleman         11 JUL 2014      Updated to reference new domain objects from IntegrationObjects and combining SalesAccount methods
    Vipul Jain            14 JUL 2014      Updated the signature of Contact and Address service methods , to recieve the list of apex objects.
    Vipul Jain            23 JUL 2014      Invoked required service method for the processing of business logic.
******************************************************************************************/

public with sharing class InboundService {
    
    // Method used for EBS Inbound service
    public void EBS_Account_Service(IntegrationObjects.TransactionalAccount ebsAccount){
    
        EBSAccount_Inbound_Service ebsAccountInboundService = new EBSAccount_Inbound_Service ();
        ebsAccountInboundService.EbsAccountSync(ebsAccount);
    }
    
    // Method used for Contact Inbound service (to recieve the single contact domain objects )
    public void Contact_Service(IntegrationObjects.Contact contact){
        
        //invoke the method to execute business logic for contact service
        SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
        salesAccountInboundService.Contact_Service(contact);
    }
    // Method used for Contact Inbound service (to recieve the contact domain objects in list)
    public void Contact_Service(List<IntegrationObjects.Contact> contactList){
        
        //invoke the method to execute business logic for contact service
        SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
        salesAccountInboundService.Contact_Service(contactList);
    }
    
    // Method used for Sales Account Service and Address service both
    public void SalesAccount_Service(IntegrationObjects.SalesAccount account){
        
        //invoke the method to execute business logic for sales account service
        SalesAccount_Inbound_Service salesAccountInboundService = new SalesAccount_Inbound_Service();
        salesAccountInboundService.SalesAccount_Service(account);
    }
    
    // Method used for order Inbound service
    public void Opportunity_Service (IntegrationObjects.Order order){
    
        // Business logic here
        Order_Inbound_Service orderInboundService = new Order_Inbound_Service();
        orderInboundService.OpportunityStagingSync(Order);
    } 
}// class ends here