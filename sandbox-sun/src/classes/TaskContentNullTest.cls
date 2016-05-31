/**
 * Test Class created for TaskContentNull trigger.
 *
 * @author Accenture
 * 
 * @version 2012-04-18
 *
 * Modified: Bill Riemers <briemers@redhat.com>
 * 2012-04-18 - Update for Security Model Redesign
 * Modified: Nitesh Dokania
 * 2011-06-20 - Code coverage enhancement.
 */
@isTest(SeeAllData=true) // need all data to access custom settings
private class TaskContentNullTest
{

	static testMethod void contectNullTest()
	{
		// TO DO: implement unit test
		TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
		System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
		User user = new User(
			alias = 'st4209', 
			email='standarduser4209@testorg.com',
			emailencodingkey='UTF-8',
			lastname='Testing',
			languagelocalekey='en_US',
			localesidkey='en_US',
			profileid = salesUserProfileTesting.Id__c,
			timezonesidkey='America/Los_Angeles',
			username='standarduser4209@testorg.com');
		insert user;

		test.startTest();

		System.runAs(user)
		{
			try{
				Account acc = new Account(Name='Test Account');
				insert acc;
				Opportunity  opp = new Opportunity(Name='Test Opp',Triage_Opportunity__c=true,FulfillmentChannel__c='Indirect – VAR/VAD',CloseDate=System.today(),StageName='Unqualified',AccountId=acc.Id,Country_of_Order__c='India');
				insert opp;
				Task tk = new Task();
				tk.Subject = 'Conference Call';
				tk.Contents__c = 'Test1';
				tk.WhatId = opp.Id;
				insert tk;
				tk.Contents__c = 'test';
				update tk;
			}
			catch(Exception e)
			{}
		}

		test.stopTest();

	}
}