/*****************************************************************************************
    Name    : Contact_Trigger_Helper
    Desc    : This class will act as helper class for Contact trigger to process different business logic related to Contact
              1.) Invoke the method provided by RH Team to process domain object.
                       
                            
    Modification Log : 
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Vipul Jain          23 JULY 2014        Created
    Chandan Prusty      24 SEP 2014         Added Message priority Logic
    Bill C Riemers      12 AUG 2015         Depreciated (replaced with ContactTriggerAfter)
******************************************************************************************/
@IsTest
private /* depreciated public with sharing */ class Contact_Trigger_Handler {
//depreciated	        
//depreciated	    // Method used to send contact outbound message to the method to process the outbound  domain object.
//depreciated	    public static void Contact_Outbound_Message (map<Id,Contact> newmap,map<Id,Contact> oldmap){
//depreciated	        String recordTypeLabel = Label.AccountPartnerRecordType;
//depreciated	        Set<String> recordTypeSet = new Set<String>();
//depreciated	        if(recordTypeLabel.contains(',')){
//depreciated	           List<String> recordTypeList = recordTypeLabel.split(',');
//depreciated	           for(String recordType : recordTypeList){
//depreciated	              recordTypeSet.add(recordType); 
//depreciated	           }
//depreciated	        } 
//depreciated	        //This logic is for defining the priority of the outbound message
//depreciated	        String piorityStatus = '';
//depreciated	        if(newmap.size() == 1){
//depreciated	            piorityStatus = 'SingleInsertUpdate';
//depreciated	        }
//depreciated	        else{
//depreciated	            piorityStatus = 'BulkInsertUpdate';
//depreciated	        }
//depreciated	        
//depreciated	        // iterating on the list of contacts created/updated.
//depreciated	        for(Contact contact:[select id ,Name,Account.id,Status__c,Account.CDH_Party_Name__r.Name,CDH_Party__r.Name,FirstName,lastName,Salutation,Email,Phone,
//depreciated	                                MobilePhone,Fax,LoginName__c,CDH_Party_Number__c, Account_Record_Type__c from Contact where id IN:newmap.keyset()]){
//depreciated	            if(!recordTypeSet.contains(contact.Account_Record_Type__c)){
//depreciated	                /*Generating the Integration object of contact using , Integration object converter class
//depreciated	                  Invoke QueueContactMessage method of OutBoundService class.*/
//depreciated	                IntegrationObjects.Contact  ioContact  = new IntegrationObjects.Contact();
//depreciated	                ioContact = IntegrationObjectConverter.convertContact(contact);
//depreciated	                
//depreciated	                // setting reference related attribute because those would not be set in integration object converter method.
//depreciated	                ioContact.SalesAccount_CDH_Party_Number = contact.Account.CDH_Party_Name__r.Name;
//depreciated	                ioContact.CDH_Party_Number = contact.CDH_Party__r.Name;
//depreciated	                
//depreciated	                // set this attribute because it was not set in integration object converter class.
//depreciated	                //ioContact.Name = contact.Name;
//depreciated	                //ioContact.CDH_Party_Type = 'PERSON';
//depreciated	                // Scenario for contact update.Because Operation passed would be "Update" in this case.
//depreciated	                if(oldmap !=Null && oldmap.get(contact.Id) != Null){
//depreciated	                    system.debug('Update event ---->'+ioContact);
//depreciated	                    OutboundService.queueContactMessage(ioContact,'Update',piorityStatus);
//depreciated	                }
//depreciated	                
//depreciated	                // Scenario contact create.Because Operation passed would be "Create" in this case.
//depreciated	                if(oldmap == Null || oldmap.get(contact.Id) == Null){
//depreciated	                    
//depreciated	                    system.debug('Create event ---->'+ioContact);
//depreciated	                    OutboundService.queueContactMessage(ioContact,'Create',piorityStatus);
//depreciated	                    system.debug('++++++TUT Success');
//depreciated	                }
//depreciated	            }    
//depreciated	        }
//depreciated	    }

}