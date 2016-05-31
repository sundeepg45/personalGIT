// 2015-09-22 - depreciated
@isTest
private class EBSAccount_TriggerTest{

//depreciated    public static Account account {
//depreciated        get {
//depreciated          if(account == null) {
//depreciated            RecordType recordType = [
//depreciated              select Id,name
//depreciated              from RecordType
//depreciated              where name = 'Strategic'
//depreciated                and SObjectType = 'Account'
//depreciated                and IsActive = true
//depreciated              limit 1 ];
//depreciated            account = new Account(
//depreciated              CurrencyIsoCode='USD',
//depreciated              name='Test Account',
//depreciated              RecordTypeId=recordType.Id,
//depreciated              AccountClassification__c=recordType.name );
//depreciated            insert account;
//depreciated            account.RecordType = recordType;
//depreciated          }
//depreciated          return account;
//depreciated        }
//depreciated    }
//depreciated    
//depreciated    public static testMethod void testUpdateEBSaccNumberOnAccount(){
//depreciated        
//depreciated        BooleanSetting__c boolS = new BooleanSetting__c(Name = 'EBSAccountTrigger.updtEBSaccNmbrOnAcc', Value__c = TRUE);
//depreciated        insert boolS;
//depreciated        
//depreciated        EBS_Account__c ebs = new EBS_Account__c(Name = '1231', 
//depreciated                                                Primary_EBS_Account__c = FALSE, 
//depreciated                                                Sales_Account__c = account.Id);
//depreciated        insert ebs;
//depreciated        
//depreciated        system.assert([SELECT EBS_Account_Numbers__c FROM Account WHERE Id =: account.Id].EBS_Account_Numbers__c == '1231');
//depreciated        
//depreciated        ebs = new EBS_Account__c(Name = '1232', 
//depreciated                                                Primary_EBS_Account__c = FALSE, 
//depreciated                                                Sales_Account__c = account.Id);
//depreciated        insert ebs;
//depreciated        
//depreciated        ebs = new EBS_Account__c(Name = '1233', 
//depreciated                                                Primary_EBS_Account__c = TRUE, 
//depreciated                                                Sales_Account__c = account.Id);
//depreciated        insert ebs;
//depreciated        
//depreciated        system.assert([SELECT EBS_Account_Numbers__c FROM Account WHERE Id =: account.Id].EBS_Account_Numbers__c == '1233*, 1231, 1232');
//depreciated    }
}