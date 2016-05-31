/**
 * Test class for Opportunity_Split_Batchable2
 *
 * @version 2016-01-06
 * @author Scott Coleman <scoleman@redhat.com>
 * 2015-02-07 - Updated to fix bug
 * 2014-10-08 - Created
 * Bill C Riemers
 * 2015-01-06 - rollback
 * 2015-11-24 - Test for rewritten functionality
 */
@isTest
private class Opportunity_Split_Batchable2Test {
//US80608(rollback DE7583) 	public static Account account { get { 
//US80608(rollback DE7583) 		return OpportunityLineItemTriggerBefore2Test.account;
//US80608(rollback DE7583) 	}}

//US80608(rollback DE7583) 	static Opportunity opportunity { get {
//US80608(rollback DE7583) 		return OpportunityLineItemTriggerBefore2Test.opportunity;
//US80608(rollback DE7583) 	}}

//US80608(rollback DE7583) 	static OpportunityLineItem lineItem { get {
//US80608(rollback DE7583) 		if(lineItem == null) {
//US80608(rollback DE7583) 			lineItem = OpportunityLineItemTriggerBefore2Test.lineItem;
//US80608(rollback DE7583) 			AbstractTrigger.setBooleanSettings('LineItem_After.',false);
//US80608(rollback DE7583) 			AbstractTrigger.setBooleanSettings('LineItem_Before.',false);
//US80608(rollback DE7583) 			insert lineItem;
//US80608(rollback DE7583) 			AbstractTrigger.setBooleanSettings('LineItem_After.',true);
//US80608(rollback DE7583) 			AbstractTrigger.setBooleanSettings('LineItem_Before.',true);
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		return lineItem;
//US80608(rollback DE7583) 	}}

//US80608(rollback DE7583) 	static List<Event__c> events {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(events == null) {
//US80608(rollback DE7583) 				events = new List<Event__c>{
//US80608(rollback DE7583) 					new Event__c(Opportunity__c = lineItem.OpportunityId,Processed__c=false), 
//US80608(rollback DE7583) 					new Event__c(Opportunity__c = lineItem.OpportunityId,Processed__c=false), 
//US80608(rollback DE7583) 					new Event__c(Opportunity__c = lineItem.OpportunityId,Processed__c=false)};
//US80608(rollback DE7583) 				insert events;
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return events;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	static List<User> users {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(users == null) {
//US80608(rollback DE7583) 				users = [select Id from User where Profile.Name like '%Direct Sales User%' and IsActive = true limit 3];
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return users;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	static List<OpportunityTeamMember> opportunityTeamMembers {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(opportunityTeamMembers == null) {
//US80608(rollback DE7583) 				opportunityTeamMembers = new List<OpportunityTeamMember>{
//US80608(rollback DE7583) 					new OpportunityTeamMember(
//US80608(rollback DE7583) 						TeamMemberRole='Sales Manager',
//US80608(rollback DE7583) 						OpportunityId = events[0].Opportunity__c,
//US80608(rollback DE7583) 						UserId = users[0].Id),
//US80608(rollback DE7583) 					new OpportunityTeamMember(
//US80608(rollback DE7583) 						TeamMemberRole='Sales Manager',
//US80608(rollback DE7583) 						OpportunityId = events[0].Opportunity__c,
//US80608(rollback DE7583) 						UserId = users[1].Id),
//US80608(rollback DE7583) 					new OpportunityTeamMember(
//US80608(rollback DE7583) 						TeamMemberRole='Sales Manager',
//US80608(rollback DE7583) 						OpportunityId = events[0].Opportunity__c,
//US80608(rollback DE7583) 						UserId = users[2].Id) };
//US80608(rollback DE7583) 				insert opportunityTeamMembers;
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return opportunityTeamMembers;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	static List<OpportunitySplit> opportunitySplits {
//US80608(rollback DE7583) 		get {
//US80608(rollback DE7583) 			if(opportunitySplits == null) {
//US80608(rollback DE7583) 				Id ostId = [
//US80608(rollback DE7583) 					SELECT Id
//US80608(rollback DE7583) 					FROM OpportunitySplitType
//US80608(rollback DE7583) 					WHERE MasterLabel = 'Overlay Credit' Limit 1 ].Id;
//US80608(rollback DE7583) 				opportunitySplits = new List<OpportunitySplit>{
//US80608(rollback DE7583) 					new OpportunitySplit(
//US80608(rollback DE7583) 						OpportunityId=opportunityTeamMembers[0].OpportunityId,
//US80608(rollback DE7583) 						SplitOwnerId=opportunityTeamMembers[0].UserId,
//US80608(rollback DE7583) 						SplitPercentage=20,
//US80608(rollback DE7583) 						SplitTypeId=ostId),
//US80608(rollback DE7583) 					new OpportunitySplit(
//US80608(rollback DE7583) 						OpportunityId=opportunityTeamMembers[0].OpportunityId,
//US80608(rollback DE7583) 						SplitOwnerId=opportunityTeamMembers[1].UserId,
//US80608(rollback DE7583) 						SplitPercentage=80,
//US80608(rollback DE7583) 						SplitTypeId=ostId) };
//US80608(rollback DE7583) 				insert opportunitySplits;
//US80608(rollback DE7583) 			}
//US80608(rollback DE7583) 			return opportunitySplits;
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	@isTest
//US80608(rollback DE7583) 	static void eventsTest() {
//US80608(rollback DE7583) 		events.isEmpty();
//US80608(rollback DE7583) 		Opportunity_Split_Batchable2 batchable = new Opportunity_Split_Batchable2();

//US80608(rollback DE7583) 		Test.startTest();
//US80608(rollback DE7583) 		List<SObject> records = batchable.start(null);
//US80608(rollback DE7583) 		Integer eventsSize = batchable.events.size();
//US80608(rollback DE7583) 		System.assert(eventsSize >= events.size(),'Expected at least '+events.size()+' events but got '+eventsSize);
//US80608(rollback DE7583) 		System.assertNotEquals(0,records.size());
//US80608(rollback DE7583) 		batchable.events = null;
//US80608(rollback DE7583) 		System.assertEquals(eventsSize,batchable.events.size());
//US80608(rollback DE7583) 		batchable.events.clear();
//US80608(rollback DE7583) 		System.assertEquals(0,batchable.events.size());
//US80608(rollback DE7583) 		batchable.events = null;
//US80608(rollback DE7583) 		System.assertEquals(eventsSize,batchable.events.size());
//US80608(rollback DE7583) 		batchable.events.clear();
//US80608(rollback DE7583) 		records = batchable.start(null);
//US80608(rollback DE7583) 		Test.stopTest();

//US80608(rollback DE7583) 		System.assertNotEquals(0,records.size());
//US80608(rollback DE7583) 		System.assertNotEquals(eventsSize,batchable.events.size());
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	@isTest
//US80608(rollback DE7583) 	static void executeTest() {
//US80608(rollback DE7583) 		opportunitySplits.isEmpty(); // this is sufficient to allocate
//US80608(rollback DE7583) 		Opportunity_Split_Batchable2 batchable = new Opportunity_Split_Batchable2();
//US80608(rollback DE7583) 		Test.startTest();
//US80608(rollback DE7583) 		List<SObject> records = batchable.start(null);
//US80608(rollback DE7583) 		System.assertEquals(1,records.size());
//US80608(rollback DE7583) 		Integer eventsSize = batchable.events.size();
//US80608(rollback DE7583) 		System.assert(eventsSize >= events.size(),'Expected at least '+events.size()+' events but got '+eventsSize);
//US80608(rollback DE7583) 		batchable.execute(null,records);
//US80608(rollback DE7583) 		System.assertEquals(eventsSize,[
//US80608(rollback DE7583) 			SELECT count()
//US80608(rollback DE7583) 			FROM Event__c
//US80608(rollback DE7583) 			WHERE Processed__c = false ] );
//US80608(rollback DE7583) 		List<SObject> details = [
//US80608(rollback DE7583) 			SELECT Id
//US80608(rollback DE7583) 			FROM Opportunity_Split_Detail__c ];
//US80608(rollback DE7583) 		System.assert(details.size() >= opportunityTeamMembers.size(),'Exected at least :'+opportunityTeamMembers.size()+' split detail records but got '+details.size());
//US80608(rollback DE7583) 		List<SObject> xevents = [
//US80608(rollback DE7583) 			SELECT Id,
//US80608(rollback DE7583) 				Processed__c,
//US80608(rollback DE7583) 				Opportunity__c
//US80608(rollback DE7583) 			FROM Event__c 
//US80608(rollback DE7583) 			WHERE Processed__c = false ];
//US80608(rollback DE7583) 		System.assertEquals(eventsSize,xevents.size());
//US80608(rollback DE7583) 		List<SObject> queriedList = new List<SObject>();
//US80608(rollback DE7583) 		queriedList.addAll(details);
//US80608(rollback DE7583) 		queriedList.addAll(xevents);
//US80608(rollback DE7583) 		batchable.events.clear();
//US80608(rollback DE7583) 		batchable.execute(null,queriedList);
//US80608(rollback DE7583) 		System.assertEquals(0,[
//US80608(rollback DE7583) 			SELECT count()
//US80608(rollback DE7583) 			FROM Opportunity_Split_Detail__c ] );
//US80608(rollback DE7583) 		xevents = [
//US80608(rollback DE7583) 			SELECT Id,
//US80608(rollback DE7583) 				Processed__c,
//US80608(rollback DE7583) 				Opportunity__c
//US80608(rollback DE7583) 			FROM Event__c
//US80608(rollback DE7583) 			WHERE Processed__c = true];
//US80608(rollback DE7583) 		System.assertEquals(eventsSize,xevents.size());
//US80608(rollback DE7583) 		batchable.execute(null,xevents);
//US80608(rollback DE7583) 		System.assertEquals(0,[
//US80608(rollback DE7583) 			SELECT count()
//US80608(rollback DE7583) 			FROM Event__c ] );
//US80608(rollback DE7583) 		batchable.errorList.add('Anything');
//US80608(rollback DE7583) 		batchable.execute(null,new List<SObject>());
//US80608(rollback DE7583) 		Test.stopTest();
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	@isTest
//US80608(rollback DE7583) 	static void finishTest() {
//US80608(rollback DE7583) 		Opportunity_Split_Batchable2 batchable = new Opportunity_Split_Batchable2();
//US80608(rollback DE7583) 		Test.startTest();
//US80608(rollback DE7583) 		try {
//US80608(rollback DE7583) 			batchable.finish((Database.BatchableContext)null);
//US80608(rollback DE7583) 		}
//US80608(rollback DE7583) 		catch(Exception e) {}
//US80608(rollback DE7583) 		batchable.finish((AsyncApexJob)null);
//US80608(rollback DE7583) 		Test.stopTest();
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	@isTest
//US80608(rollback DE7583) 	static void sendErrorsTest() {
//US80608(rollback DE7583) 		Opportunity_Split_Batchable2 batchable = new Opportunity_Split_Batchable2();
//US80608(rollback DE7583) 		batchable.errorList.add('anything');
//US80608(rollback DE7583) 		Test.startTest();
//US80608(rollback DE7583) 		System.assertNotEquals(null,batchable.sendErrors(null));
//US80608(rollback DE7583) 		Test.stopTest();
//US80608(rollback DE7583) 	}

//US80608(rollback DE7583) 	@IsTest
//US80608(rollback DE7583) 	static void coverageTest() {
//US80608(rollback DE7583) 		Test.startTest();
//US80608(rollback DE7583) 		AbstractBatchableTest.coverageTest(new Opportunity_Split_Batchable2(),new List<Event__c>());
//US80608(rollback DE7583) 		Test.stopTest();
//US80608(rollback DE7583) 	}
}