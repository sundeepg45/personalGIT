/*
 * This class contains unit tests for validating the behavior of Apex trigger User_Contact
 *
 * @version 2015-10-07
 * @author Nitesh Dokania
 * 2012-10-26 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2015-10-07 - Updated to actually check the results
 */
@isTest
private class User_ContactTest 
{
	@IsTest
	static void associatedContact() 
	{
		User_Contact.isUserContactRunningTest = true;
		Account acc = new Account(Name='Red Hat (Internal Use Only)');
		insert acc;
		test.startTest();
		
		User usr = new User(Alias = 'standt68', Email='example@example.org',
			Emailencodingkey='UTF-8', LastName='Testing', Languagelocalekey='en_US',
			Localesidkey='en_US', Profileid = UserInfo.getProfileId(), Region__c='APAC',
			Timezonesidkey='America/Los_Angeles', Username='standarduser68@testorg.com');
			System.runAs(new User(Id = UserInfo.getUserId())) {
				insert usr;
			}
		
		test.stopTest();
		User usr2 = [select Contact_Id__c from User where Id = : usr.Id];
		System.assertNotEquals(null,usr2.Contact_Id__c);
	
	}
}