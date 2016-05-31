/**
 * Test Class created for EMEAUserNotification business Class.
 *
 * @author Nitesh Dokania
 *
 * @version 2012-04-18
 *
 * Modified: Bill Riemers <briemers@redhat.com>
 * 2012-04-18 - Update for Security Model Redesign
 * Modified: Nitesh Dokania
 * 2011-11-04 - Separated test class from business class and created a new test class
 * 2011-11-06 - Enhanced code coverage and added assert statements.
 */
@isTest(SeeAllData=true) // need all data to access custom settings
private class EMEAUserNotificationTest
{
	static testmethod void deployEMEAUserNotification()
	{
		TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
		System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
		User user = new User(
			alias = 'st4921',
			email='standarduser4921@testorg.com',
			emailencodingkey='UTF-8',
			lastname='Testing',
			languagelocalekey='en_US',
			localesidkey='en_US',
			profileid = salesUserProfileTesting.Id__c,
			timezonesidkey='America/Los_Angeles', 
			username='standarduser4921@testorg.com',
			Region__c='EMEA');
		insert user;

		test.startTest();

		EMEAUserNotification.createMail(user);
		//Messaging.SendEmailResult result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		//System.assertEquals(true, result.isSuccess());
		EMEAUserNotification.createMail(null);

		test.stopTest();
	}
}