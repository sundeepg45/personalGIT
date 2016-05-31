/**
 * Test class for TrackingEventLog_CalculateSummaryTest.cls
 *
 * @author  Scott Coleman <scoleman@redhat.com>
 *
 * @version 2012-07-10
 * 2012-07-10 - Role reference modified
 */
@isTest
private class TrackingEventLog_CalculateSummaryTest {
	
	static testMethod void validateBatch() {
		// get some roles
		List<UserRole> roleList = new List<UserRole>([
			select
				Name
			from UserRole
			where Name like 'NA | Comm | %' ]); 
			
		// create some users
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		
	  	User user1 = new User(
	  		Alias = 'testusr1', 
	  		Email='testuser1@testorg.abc', 
		 	EmailEncodingKey='UTF-8', 
		 	LastName='Testing', 
		 	LanguageLocaleKey='en_US', 
		 	LocaleSidKey='en_US', 
		 	ProfileId = p.Id,
		 	TimeZoneSidKey='America/Los_Angeles', 
		 	UserName='testuser1@testorg.abc');
		// use a runAs statement to create a new context to avoid mixed DML errors
		System.runAs(new User(Id = UserInfo.getUserId())) {		 	
			insert user1;
		}
		
		User user2 = new User(
	  		Alias = 'testusr2', 
	  		Email='testuser2@testorg.abc', 
		 	EmailEncodingKey='UTF-8', 
		 	LastName='Testing', 
		 	LanguageLocaleKey='en_US', 
		 	LocaleSidKey='en_US', 
		 	ProfileId = p.Id,
		 	TimeZoneSidKey='America/Los_Angeles', 
		 	UserName='testuser2@testorg.abc');
		// use a runAs statement to create a new context to avoid mixed DML errors
		System.runAs(new User(Id = UserInfo.getUserId())) {		 	
			insert user2;
		}
		
		// create TrackingEvent__c records
		TrackingEvent__c trackingEvent1 = new TrackingEvent__c(
			Name = 'Test Event 1',
			Code__c = 'Test1',
			Description__c = 'Test Description 1',
			Type__c = 'Page View');
		insert trackingEvent1;
			
		TrackingEvent__c trackingEvent2 = new TrackingEvent__c(
			Name = 'Test Event 2',
			Code__c = 'Test2',
			Description__c = 'Test Description 2',
			Type__c = 'Page View');
		insert trackingEvent2;
		
		// create TrackingEventLog__c records
		TrackingEventLog__c log1 = new TrackingEventLog__c(
			TrackingEvent__c = trackingEvent1.Id,
			User__c = user1.Id,
			UserRoleId__c = roleList[0].Id );
		insert log1;	
		
		TrackingEventLog__c log2 = new TrackingEventLog__c(
			TrackingEvent__c = trackingEvent2.Id,
			User__c = user2.Id,
			UserRoleId__c = roleList[0].Id );
		insert log2;
		
		TrackingEventLog__c log3 = new TrackingEventLog__c(
			TrackingEvent__c = trackingEvent1.Id,
			User__c = user2.Id,
			UserRoleId__c = roleList[0].Id );
		insert log3;
		
		TrackingEventLog__c log4 = new TrackingEventLog__c(
			TrackingEvent__c = trackingEvent1.Id,
			User__c = user2.Id,
			UserRoleId__c = roleList[0].Id );
		insert log4;
		
		TrackingEventLog__c log5 = new TrackingEventLog__c(
			TrackingEvent__c = trackingEvent1.Id,
			User__c = user2.Id,
			UserRoleId__c = roleList[0].Id );	
		insert log5;
		
		// create TrackingEventSummary__c records
		TrackingEventSummary__c summary1 = new TrackingEventSummary__c(
			Count__c = 14, 
			Date__c = DateTime.now().dateGMT(), 
			TrackingEvent__c = trackingEvent1.Id, 
			UserRole__c = 'Test Role' );
		insert summary1;
		
		// create custom setting
		StringSetting__c lastProcessed = new StringSetting__c(
			Name = 'TrackingEventLog.LastProcessedDate',
			Value__c = '2012-01-01T00:00:00Z',
			CurrencyIsoCode = 'USD' );
		insert lastProcessed;
		
		// execute batch process to populate TrackingEventSummary__c
		Test.StartTest();
		TrackingEventLog_CalculateSummary summarize = new TrackingEventLog_CalculateSummary();
		ApexPages.StandardSetController controller = new ApexPages.StandardSetController(summarize.start(null));
		controller.setPageSize(100);
		summarize.execute(null,controller.getRecords());
		System.assert(summarize.errorMessages.isEmpty());
		summarize.finish(null);
		Test.StopTest();
		
		// retrieve TrackingEventSummary_c records
		List<TrackingEventSummary__c> summaryList = new List<TrackingEventSummary__c>(); 
		
		summaryList = [
			select 
				Name,
				Count__c,
				Date__c,
				TrackingEvent__c,
				UserRole__c 
			from TrackingEventSummary__c
			order by Count__c];
			
		// assert that the counts are correct
		System.assertEquals(3, summaryList.size());
		// expected: Count__c = 1, TrackingEvent__c = trackingEvent2.Id, UserRole__c = roleList[0].Name
		System.assertEquals(1, summaryList[0].Count__c);
		System.assertEquals(trackingEvent2.Id, summaryList[0].TrackingEvent__c);
		System.assertEquals(roleList[0].Name, summaryList[0].UserRole__c);
		// expected: Count__c = 4, TrackingEvent__c = trackingEvent1.Id, UserRole__c = roleList[0].Name
		System.assertEquals(4, summaryList[1].Count__c);
		System.assertEquals(trackingEvent1.Id, summaryList[1].TrackingEvent__c);
		System.assertEquals(roleList[0].Name, summaryList[1].UserRole__c);
		// expected: Count__c = 14, TrackingEvent__c = trackingEvent1.Id, UserRole__c = 'Test Role'
		System.assertEquals(14, summaryList[2].Count__c);
		System.assertEquals(trackingEvent1.Id, summaryList[2].TrackingEvent__c);
		System.assertEquals('Test Role', summaryList[2].UserRole__c);		
	}
	
}