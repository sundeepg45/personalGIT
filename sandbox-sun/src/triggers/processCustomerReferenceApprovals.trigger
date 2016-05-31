/*
* trigger before & after update of Customer Reference
* if status changed to approve set the private contact field with the contact field and null the contact field
* if status is approved create sharing
* if status is rejected remove sharing
* Creates reference usage object and sets its owner to the owner of the Customer reference
*/
trigger processCustomerReferenceApprovals on Customer_Reference__c (before update, after update) {
    
    //Manages sharing related tasks for approved and rejected references
    
    //Approval Status'
    String APPROVED = 'Accepted';
    if (Trigger.isBefore == true) {
        for (Customer_Reference__c crf : Trigger.new) {
            if (crf.Approval_Status__c == APPROVED && Trigger.OldMap.get(crf.Id).Approval_Status__c != APPROVED) {
                //Populate the Private Contactg field which should be configured to have limited field level security
                //and null the Contact field so most users will not automatically see the contact associated with the 
                //reference but instead need to go through the process to request the contact information                 
                crf.Private_Contact__c= crf.Contact__c;
                crf.Contact__c = null;
            }
        }
    }

}