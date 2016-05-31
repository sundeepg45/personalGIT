/*****************************************************************************************
    Name    : EBSAccount_Inbound_Service
    Desc    : This class defines the logic for  inserts/updates operation into EBS_Account object           
                            
Modification Log : 
---------------------------------------------------------------------------
Developer              Date            Description
---------------------------------------------------------------------------
Pankaj Banik         12/06/2014          Created
******************************************************************************************/

public with sharing class EBSAccount_Inbound_Service {
       
    public void EbsAccountSync(IntegrationObjects.TransactionalAccount ioTransactionalAccount) {    
    
        try{
            SYSTEM.DEBUG('EBS SERVICE CALLED-->');
            // variable to hold the ebsAccount records to be processed.
            List<EBS_Account__c> ebsAccountList = new List<EBS_Account__c>();
            
            // List to hold all salesAccount which comes under CDH Party# coming in the message from EBS.
            List<Account> salesAccountList = new List<Account>(); 
            system.debug('ioTransactionalAccount --->'+ioTransactionalAccount );
            if(ioTransactionalAccount != null && ioTransactionalAccount.Sales_Account !=Null && ioTransactionalAccount.Sales_Account.trim().length() > 0 ){    
            
                // Query on CDH Party record based on the CDH Party# coming in the message from CDH.
                List<CDH_Party__c> cdhPartyList  = new List<CDH_Party__c>();
                cdhPartyList  = [Select Id,Name from CDH_Party__c where Name=: ioTransactionalAccount.Sales_Account];
                
                //Check if Given CDH Party Exists or not
                if(cdhPartyList.size()>0) {
                
                    // Querying all sales account and their associated EBS account having the EBS number coming in the message.
                    salesAccountList = [Select Id,Name ,(Select Id,Name,Account_Type__c,Credit_Hold__c,Credit_Review_Cycle__c,EBS_Account_Description__c,
                                                         EBS_Party_Name__c,EBS_Party_Number__c,CDH_Party_Number__c,Last_Credit_Review_Date__c,Next_Credit_Review_Date__c,
                                                         Primary_EBS_Account__c,Sales_channel__c,Sales_Account__c,Status__c from EBS_Account__r where Name=:ioTransactionalAccount.Account_Number) 
                                        from Account where CDH_Party_Name__c=:cdhPartyList[0].Id];
                    
                    //Check if Sales Account Exist for given CDH Party
                    if(salesAccountList.size()>0) {
                        system.debug('sales account list-->'+salesAccountList);
                        // check for all sales account , whether they have EBS Account or not (for the EBS Account Number coming in message from EBS)
                        for(Account SalesAccount:salesAccountList) {  
                            
                            // if EBS account exist under this sales account , update all those EBS account records
                            system.debug('SalesAccount.EBS_Account__r list-->'+SalesAccount.EBS_Account__r);
                            if(SalesAccount.EBS_Account__r.size() > 0) {
                                for(EBS_Account__c ebsAccountObject : SalesAccount.EBS_Account__r) {   
                                    EBS_Account__c ebsAccount = new EBS_Account__c();
                                    
                                    // invoke method to convert integration transactional account object into EBS Account.
                                    ebsAccount = SystemObjectConverter.ConvertioTransactionalAccount(ioTransactionalAccount);
                                    ebsAccount.Sales_Account__c = SalesAccount.Id;
                                    ebsAccount.Id = ebsAccountObject.Id;
                                    ebsAccountList.add(ebsAccount);
                                }
                            }
                            
                            // If no EBS Account record exist under sales account , create the instance of the EBS Account.
                            else {
                                EBS_Account__c ebsAccount = new EBS_Account__c();
                                
                                // invoke method to convert integration transactional account object into EBS Account.
                                ebsAccount = SystemObjectConverter.ConvertioTransactionalAccount(ioTransactionalAccount);
                                ebsAccount.Sales_Account__c = SalesAccount.Id;
                                ebsAccountList.add(ebsAccount);
                            }
                        }
                        
                        // upsert the EBS Account records.
                        upsert ebsAccountList; 
                        system.debug('Records Upserted for EBS Account-->'+ebsAccountList[0].id);                                             
                    }
                    else{
                        
                        // Throw exception in case no sales account exist under CDH Party.
                        throw new Interface_ServiceException('No Sales account under this CDH Party#.');
                    }
                }
                else{
                    
                    // Throw exception in case CDH Party record does not exist.
                    throw new Interface_ServiceException('CDH Party does not exist');
                }
            } 
        }
        catch(exception e){
            system.debug('exception occured-->'+e.getmessage());
        }
    } 
}