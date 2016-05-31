@isTest(SeeAllData=true)
private class User_EmailDomainCheckTest {

	//
	// Unfortunately we must use existing data here to avoid mixed DML errors
	//
    static testMethod void myUnitTest() {
    	Account acct = [
    		select	Id, Global_Region__c
    		from	Account
    		where	(Finder_Partner_Type__c = :RedHatObjectReferences__c.getInstance('PARTNER_TYPE.OEM').ObjectId__c
    		or		Finder_Partner_Type__c = :RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SI').ObjectId__c)
    		and		Global_Region__c = 'NA'
    		limit	1
   		];
   		if (acct != null) {
   			User[] userlist = [select Id from User where Contact.AccountId = :acct.Id];
   			if (userlist.size() > 0) {
				User u = userlist.get(0);
	
				acct.AllowedEmailDomains__c = 'unittest.com';
				update acct;
			
				u.Email = 'somethingelse@gmail.com';
		
				try {
					System.runAs(u) {
						update u;
					}
				}
				catch (System.Dmlexception ex) {
					// good, we expected this
					u.Email = 'somethingelse@unittest.com';
					System.runAs(u) {
						update u;
					}
				}
   			}
   		}
    }
}