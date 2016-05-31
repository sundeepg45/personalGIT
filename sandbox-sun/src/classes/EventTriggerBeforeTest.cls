/**
 * Test class created for EventTriggerBefore class.
 *
 * @author Bill Riemers <briemers@redhat.com>
 * @version 2012-06-02
 *
 * 2011-09-06 - created
 * 2012-06-02 - Updated for SMR
 */
@isTest
private class EventTriggerBeforeTest {
	static Event createEvent(Id whoId) {
		DateTime startDateTime = DateTime.now().addHours(1);
		return new Event(
			ActivityDateTime = startDateTime,
			ClosedDate__c = null,
			Due_Date_Time__c = null,
			StartDateTime = startDateTime,
			EndDateTime = startDateTime.addHours(1),
			ownerId = UserInfo.getUserId(),
			subject= 'Track Due date',
			whoId=whoId);
	}

	static Lead ld {
		get {
			if(ld == null) {
				ld = new Lead(
					OwnerId = UserInfo.getUserId(),
					LastName='Accenture',
					RecordTypeId = '012300000000Pmx',
					Company='Accenture',
					Stage__c = 'Marketing Accepted',
					Status='New',
					Products_of_Interest__c='JBoss',
					LeadSourceDetail__c='SD_RONA',
					Partner_Onboarding_Status__c = 'Pending',
					Partner_Onboarding_Profile__c = 'NA Partner Portal – Strategic License',
					Country = 'US',
					Partner_Opt_In__c=true,
					RHNLogin__c='test@redhat.com.test',
					Email = 'test@redhat.com.test');
				insert ld;
			}
			return ld;
		}
	}

	@isTest
	static void closedDateTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		AbstractTrigger.setBooleanSettings('Lead_Before.leadLock', false);

		Event ev = createEvent(ld.Id);
		Event ev2 = ev.clone(true);
		EventTriggerBefore triggerBefore = new EventTriggerBefore(
			new Map<Id,Event>{ev.Id=>ev},
			new List<Event>{ev2});
		triggerBefore.closedDate();
		System.assertEquals(ev2.StartDateTime,ev2.ClosedDate__c);
	}

	@isTest
	static void assignLegacyTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		User u=new User(
			Id=UserInfo.getUserId(),
			Legacy_Profile__c = 'testing profile',
			Legacy_Role__c = 'testing role');
		update u;
		Event ev = createEvent(null);
		EventTriggerBefore beforeTrigger = new EventTriggerBefore(null,new List<Event>{ev});
		beforeTrigger.assignLegacy();
		System.assertEquals(u.Legacy_Profile__c,ev.Legacy_Profile__c);
		System.assertEquals(u.Legacy_Role__c,ev.Legacy_Role__c);
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		Event ev = createEvent(null);
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Event_Before.',true);
		// insert
		EventTriggerBefore.processTrigger(null,new List<Event>{ev});
		// update
		EventTriggerBefore.processTrigger(new Map<Id,Event>{ev.Id=>ev.clone(true)},new List<Event>{ev});
		// delete
		EventTriggerBefore.processTrigger(new Map<Id,Event>{ev.Id=>ev},null);
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('Event_Before.');
	}

	@isTest
	static void deployTest() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		AbstractTriggerTest.deployTest('Event_Before.',new List<Event>{createEvent(null)});
	}
}