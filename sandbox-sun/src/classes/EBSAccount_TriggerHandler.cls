/**
 * This is a handler class for EBSAccount_Trigger
 *
 * @version 2015-09-22
 * @author Anshul Kumar <ankumar@redhat.com>
 * 2015-02-23 - created
 * Bill C Riemers
 * 2015-09-22 - depreciated, refactored into EBSAccountTriggerAfter
 */
@isTest // to depreciated
/* depreciated public */ private class EBSAccount_TriggerHandler{
//depreciated    
//depreciated  /**
//depreciated   * Used for updating the EBS Account Numbers on parent accounts
//depreciated   * @return void
//depreciated   * @param list of EBS_Account__c
//depreciated   */
//depreciated    public static void updateEBSaccNumberOnAccount(){
//depreciated        
//depreciated        set<Id> setParentAccountIds = new set<Id>();
//depreciated      
//depreciated      //collect all the parent account ids  
//depreciated        for(EBS_Account__c ebsAccInst : (list<EBS_Account__c>)trigger.New){
//depreciated            
//depreciated            setParentAccountIds.add(ebsAccInst.Sales_Account__c);
//depreciated        }
//depreciated        
//depreciated        list<String> listEbsAccountNumbers;
//depreciated        list<Account> listParentAccounts = new list<Account>();
//depreciated        
//depreciated      //populate the EBS Account Numbers on the parent accounts
//depreciated        for(Account accInst : [
//depreciated                                SELECT 
//depreciated                                    EBS_Account_Numbers__c, 
//depreciated                                    (
//depreciated                                    SELECT 
//depreciated                                        Name,
//depreciated                                        Primary_EBS_Account__c
//depreciated                                    FROM 
//depreciated                                        EBS_Account__r
//depreciated                                    ORDER BY
//depreciated                                        Primary_EBS_Account__c DESC
//depreciated                                    )
//depreciated                                FROM
//depreciated                                    Account
//depreciated                                WHERE
//depreciated                                    Id IN: setParentAccountIds
//depreciated                            ]){

//depreciated            listEbsAccountNumbers  = new list<String>();
//depreciated            for(EBS_Account__c ebsAccInst : accInst.EBS_Account__r){

//depreciated                if(ebsAccInst.Primary_EBS_Account__c){
//depreciated                    listEbsAccountNumbers.add(ebsAccInst.Name + '*');
//depreciated                }else{
//depreciated                    listEbsAccountNumbers.add(ebsAccInst.Name);
//depreciated                }
//depreciated        
//depreciated            }
//depreciated            
//depreciated            String ebsAccNumbers = String.join(listEbsAccountNumbers, ', ');
//depreciated            if(String.isNotBlank(ebsAccNumbers)){
//depreciated                if(ebsAccNumbers.length()>131070)
//depreciated                    accInst.EBS_Account_Numbers__c = ebsAccNumbers.subString(0, 131070).subStringBeforeLast(',');
//depreciated                else
//depreciated                    accInst.EBS_Account_Numbers__c = ebsAccNumbers;
//depreciated            }
//depreciated            
//depreciated            listParentAccounts.add(accInst);
//depreciated        }
//depreciated     
//depreciated      //update all the parent accounts
//depreciated        update listParentAccounts;
//depreciated        
//depreciated    }
}