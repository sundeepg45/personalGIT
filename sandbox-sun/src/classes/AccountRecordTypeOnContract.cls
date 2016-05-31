/**
*Class Name:AccountRecordTypeOnContract
*Author:Accenture
*Date:6/30/2010
*Requirement# added for Case RH-00036658
*Description:Class to update Account Record Type field from Account on to Contract
*/


public class AccountRecordTypeOnContract 
{
  
   /**
   * This method is called from after update trigger
   * It will update Account Record Type from Account on to the contract
   */
   public void populateAccRecordType()
   {
      Account objAccount;
	  Account objOldAccount;
	  List<Contract> listContract = new List<Contract>();
	  Map<Id,Id> accRecordType = new Map<Id,Id>();
      
      for(integer i=0; i < trigger.new.size();i++)
      {
          objAccount = (Account)Trigger.new[i];
          objOldAccount = (Account) Trigger.old[i];
          if (objAccount.RecordTypeId != objOldAccount.RecordTypeId) {
	          accRecordType.put(objAccount.Id,objAccount.RecordTypeId);
          }
      }
      try
      {
          if(accRecordType.keySet().size() > 0)
          {
          	listContract = [Select Id, Account_Record_Type__c, AccountId from Contract where AccountId IN:  accRecordType.keySet()];
          }
      }
      catch(System.Exception e)  
      {
          System.debug('Contract are:' +listContract);
          System.debug('Exception:' +e);
      }   
      
      // getting values from Custom Setting
      List<AccountRecordType__c> accRecordTypeList = AccountRecordType__c.getAll().values();
      Map<Id,String> recordTypeMap = new Map<Id,String>();
      for(AccountRecordType__c artc : accRecordTypeList)
      {
          recordTypeMap.put(artc.RecordTypeId__c,artc.RecordTypeName__c);
      }    
      
      for(Contract con : listContract)
      {         
  		  con.Account_Record_Type__c = recordTypeMap.get(accRecordType.get(con.AccountId));		 
      }   
      try
      {
      	  update listContract;
      }
      catch(Exception e)
      {
      	  System.debug('Contract are:' +listContract);
      	  System.debug('Exception:' +e);
      }
   } 
}