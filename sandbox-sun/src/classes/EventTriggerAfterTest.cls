/**
 * This class contains unit tests for validating the EventTriggerAfter class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @version 2014-05-02
 * @author Bill C Riemers <briemers@redhat.com>
 * 2014-05-02 - Minimal updates to fix errors running in production
 */
@isTest
private class EventTriggerAfterTest {
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
					Stage__c = 'Prospect',
					Status='New',
					Products_of_Interest__c='JBoss',
					LeadSourceDetail__c='SD_RONA',
					Partner_Onboarding_Status__c = 'Pending',
					Partner_Onboarding_Profile__c = 'NA Partner Portal – Strategic License',
					Country = 'US',
					Partner_Opt_In__c=true,
					RHNLogin__c='test@redhat.com.test',
					Email = 'test@redhat.com.test');
				AbstractTrigger.setBooleanSettings('Lead_Before.',false);
				AbstractTrigger.setBooleanSettings('Lead_After.',false);
				insert ld;
				AbstractTrigger.setBooleanSettings('Lead_Before.',true);
				AbstractTrigger.setBooleanSettings('Lead_After.',true);
			}
			return ld;
		}
	}

	@IsTest(SeeAllData=true)
	static void validateSettings() {
		String message = 'Missing BooleanSetting__c values:';
		String errorMessage = message;
		for(String key : EventTriggerAfter.booleanSettingMap.keySet()) {
			if(EventTriggerAfter.booleanSettingMap.get(key) == null) {
				errorMessage += ' '+key;
			}
		}
		System.assertEquals(message,errorMessage);
	}

	@IsTest
	static void updateLeads() {
		Event ev = createEvent(ld.Id);
		Event ev2 = ev.clone(true);
		EventTriggerAfter afterTrigger = new EventTriggerAfter(new Map<Id,Event>{ev.Id=>ev},new Map<Id,Event>{ev2.Id=>ev2});
		afterTrigger.updateLeads();
		Lead ld2 = [select Status from Lead where Id = :ld.Id ];
		// The following assert is only true if the respective lead trigger is active
		// System.assertNotEquals(ld2.Status, ld.Status);
		System.debug('The following should be true: '+ld2.Status +'!=' + ld.Status);
	}

	@IsTest
	static void closedDate() {
		Event ev = createEvent(ld.Id);
		// disable all trigger methods so we can control the test conditions
		AbstractTrigger.setBooleanSettings('Event_Before.',false);
		for(String key : EventTriggerAfter.booleanSettingMap.keySet()) {
			EventTriggerAfter.booleanSettingMap.put(key,false);
		}
		insert ev;
		System.debug(ev);
		Event ev2 = ev.clone(true);
		System.debug(ev2);
		EventTriggerAfter triggerAfter = new EventTriggerAfter(
			new Map<Id,Event>{ev2.Id=>ev2},
			new Map<Id,Event>{ev.Id=>ev});
		triggerAfter.closedDate();
		for(Event ev3 : [select StartDateTime,ClosedDate__c,Due_Date_Time__c from Event where Id = :ev.Id]) {
			System.assertEquals(ev3.StartDateTime,ev3.ClosedDate__c);
			System.assertEquals(ev3.StartDateTime,ev3.Due_Date_Time__c);
		}
	}

	@IsTest(SeeAllData=true)
	static void processTriggerTest() {
		Event ev = createEvent(ld.Id);
		Event ev2 = ev.clone(true);
		// insert test
		EventTriggerAfter.processTrigger(null,new Map<Id,Event>{ev2.Id=>ev2});
		// update test
		EventTriggerAfter.processTrigger(new Map<Id,Event>{ev.Id=>ev},new Map<Id,Event>{ev2.Id=>ev2});
		// delete test
		EventTriggerAfter.processTrigger(new Map<Id,Event>{ev.Id=>ev},null);
	}

	@IsTest(SeeAllData=true)
	static void deployTest() {
		Event ev = createEvent(ld.Id);
		insert ev;
		update ev;
		delete ev;
	}
}