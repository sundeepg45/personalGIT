@IsTest
private class AcctPicklistSyncTest {
	public static testmethod void test() {
		RecordType rt = [select Id from RecordType where SobjectType = 'Account' and Name='NA Partner']; 

		for (Account acct : [
			select	Id
			  from  Account
			 where  RecordTypeId = :rt.Id
			  limit 5
		]) {
			acct.Application_Types__c = '';
			acct.Hardware_Platform__c = '';
			acct.Industry_Focus__c = '';
			acct.Middleware_Supported__c = '';
			acct.Operating_System_Supported__c = '';
			acct.Target_Market_Size__c = '';
			acct.Vertical__c = '';
			acct.Ownership_Type__c = '';
			acct.Software_Focus__c = '';
			update acct;
			AcctPicklistSync__c item = new AcctPicklistSync__c(AccountId__c=acct.Id);
			insert item;
		}
			
	}
}