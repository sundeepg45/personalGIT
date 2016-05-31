/**
 * Test class created for TaskTriggerBefore class.
 *
 * @author Bill Riemers <briemers@redhat.com>
 * @version 2013-04-08
 * 2013-04-08 - Added test for actionFields
 * 2012-06-02 - Updare for SMR
 * 2011-09-30 - Created
 */
@isTest
private class TaskTriggerBeforeTest {
	static Opportunity opp {
		get {
			if(opp == null) {
				opp = new Opportunity(
					//AccountId = account.Id,
					CloseDate = System.today().addDays(30),
					Country_Of_Order__c = 'US',
					CurrencyIsoCode = 'USD',
					Name = 'OpportunityNew',
					OpportunityType__c = 'Standard',
					PaymentType__c = 'NA Purchase Order',
					StageName = 'Test Stage',
					Triage_Opportunity__c = true);
				insert opp;
			}
			return opp;
		}
	}

	static Task createTask(Id recordTypeId, Id whatId, Id whoId) {
		return new Task(
			ownerId = UserInfo.getUserId(),
			subject= 'Track Due date',
			ActivityDate=System.today().addDays(1),
			recordTypeId=recordTypeId,
			whatId=whatId,
			whoId=whoId,
			Send_Notification__c=true);
	}

	@isTest
	static void actionFieldsTest() {
		Task tk = createTask(null,null,null);
		tk.End__c = System.today().addDays(3);
		tk.Subject = 'Strategic Plan';
		Task tk2 = tk.clone(true);
		TaskTriggerBefore triggerBefore = new TaskTriggerBefore(
			new Map<Id,Task>{tk.Id=>tk},
			new List<Task>{tk2});
		triggerBefore.actionFields();
		System.assertEquals(tk.End__c,tk2.ActivityDate);
		tk2 = tk.clone(true);
		tk2.Start__c = System.today().addDays(2);
		triggerBefore = new TaskTriggerBefore(
			new Map<Id,Task>{tk.Id=>tk},
			new List<Task>{tk2});
		triggerBefore.actionFields();
		System.assertEquals(tk.End__c,tk2.ActivityDate);
		tk2 = tk.clone(true);
		tk2.Start__c = tk.End__c;
		tk2.End__c = null;
		triggerBefore = new TaskTriggerBefore(
			new Map<Id,Task>{tk.Id=>tk},
			new List<Task>{tk2});
		triggerBefore.actionFields();
		System.assertEquals(tk.End__c,tk2.ActivityDate);
		tk2 = tk.clone(true);
		// produce some errors
		tk2.Start__c = tk2.End__c.addDays(1);
		tk2.Subject = 'Strategic Plan Solution';
		triggerBefore = new TaskTriggerBefore(
			new Map<Id,Task>{tk.Id=>tk},
			new List<Task>{tk2});
		triggerBefore.actionFields();
	}

	@isTest
	static void trackDueDateTest() {
		Task tk = createTask(Util.tandemRecordTypeId,null,null);
		Task tk2 = tk.clone(true);
		TaskTriggerBefore triggerBefore = new TaskTriggerBefore(
			new Map<Id,Task>{tk.Id=>tk},
			new List<Task>{tk2});
		triggerBefore.trackDueDate();
		System.assertEquals(null,tk2.Due_Date_Changed_On__c);
		System.assertEquals(null,tk2.Last_Due_Date__c);
		tk2.ActivityDate = tk.ActivityDate.addDays(1);
		triggerBefore.trackDueDate();
		System.assertNotEquals(null,tk2.Due_Date_Changed_On__c);
		System.assertEquals(tk.ActivityDate,tk2.Last_Due_Date__c);
	}

	@isTest
	static void preventDeleteTest() {
		Task tk = createTask(Util.tandemRecordTypeId,null,null);
		tk.Subject = 'TRIAGE REQUEST';
		TaskTriggerBefore triggerBefore = new TaskTriggerBefore(
			new Map<Id,Task>{tk.Id=>tk},
			null);
		triggerBefore.preventDelete();
		// todo: add a way to test for success
	}

	@isTest
	static void leadPartnerTest() {
		Task tk = createTask(Util.tandemRecordTypeId,opp.Id,null);
		Task tk2 = tk.clone(true);
		TaskTriggerBefore triggerBefore = new TaskTriggerBefore(
			new Map<Id,Task>{tk.Id=>tk},
			new List<Task>{tk2});
		triggerBefore.leadPartner();
		Opportunity opp2 = triggerBefore.getOpportunityMap(new Set<Id>{opp.Id}).get(opp.Id);
		System.assertEquals(opp2.Country_of_Order__c,tk2.Related_Opportunity_Region__c);
	}

	@isTest
	static void sendNotifyTest() {
		Task tk = createTask(Util.tandemRecordTypeId,opp.Id,null);
		Task tk2 = tk.clone(true);
		TaskTriggerBefore triggerBefore = new TaskTriggerBefore(
			new Map<Id,Task>{tk.Id=>tk},
			new List<Task>{tk2});
		triggerBefore.sendNotify();
		System.assert(! tk2.Send_Notification__c);
		Opportunity opp2 = triggerBefore.getOpportunityMap(new Set<Id>{opp.Id}).get(opp.Id);
		System.assert(opp2.Send_Notification_to_Opp_Owner__c);
	}

	@isTest
	static void nullContentTest() {
		Task tk = createTask(Util.tandemRecordTypeId,null,null);
		Task tk2 = tk.clone(true);
		tk.Contents__c = 'anything';
		TaskTriggerBefore triggerBefore = new TaskTriggerBefore(
			new Map<Id,Task>{tk.Id=>tk},
			new List<Task>{tk2});
		triggerBefore.nullContent();
		// todo: add a way to test for success
	}

	@isTest
	static void closedDateTest() {
		// Turn off all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Task_Before.',false);
		AbstractTrigger.setBooleanSettings('Task_After.',false);
		Task tk = createTask(Util.tandemRecordTypeId,null,null);
		insert tk;
		Task tk1 = [select IsClosed from Task where Id = :tk.Id];
		tk.Status = 'Completed';
		tk.ActivityDate = null;
		update tk;
		Task tk2 = [select IsClosed from Task where Id = :tk.Id];
		TaskTriggerBefore triggerBefore = new TaskTriggerBefore(
			new Map<Id,Task>{tk1.Id=>tk1},
			new List<Task>{tk2});
		triggerBefore.closedDate();
		System.assertNotEquals(null,tk2.ClosedDate__c);
	}

	@isTest
	static void assignLegacyTest() {
		User u=new User(
			Id=UserInfo.getUserId(),
			Legacy_Profile__c = 'testing profile',
			Legacy_Role__c = 'testing role');
		update u;
		Task tk = createTask(Util.tandemRecordTypeId,opp.Id,null);
		TaskTriggerBefore beforeTrigger = new TaskTriggerBefore(null,new List<Task>{tk});
		beforeTrigger.assignLegacy();
		System.assertEquals(u.Legacy_Profile__c,tk.Legacy_Profile__c);
		System.assertEquals(u.Legacy_Role__c,tk.Legacy_Role__c);
	}

	@isTest // (SeeAllData=true) no longer needed
	static void processTriggerTest() {
		Task tk = createTask(Util.tandemRecordTypeId,opp.Id,null);
		// Turn off all triggers as we just want to insert missing settings
		AbstractTrigger.setBooleanSettings('Task_Before.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		TaskTriggerBefore.processTrigger(null,new List<Task>{tk});
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Task_Before.',true);
		Test.startTest();
		// insert
		TaskTriggerBefore.processTrigger(null,new List<Task>{tk});
		// update
		TaskTriggerBefore.processTrigger(new Map<Id,Task>{tk.Id=>tk.clone(true)},new List<Task>{tk});
		// delete
		TaskTriggerBefore.processTrigger(new Map<Id,Task>{tk.Id=>tk},null);
		Test.stopTest();
		// Confirm missing settings were added
		AbstractTriggerTest.validateSettings('Task_Before.');
	}

	@isTest
	static void deployTest() {
		Task tk = createTask(Util.tandemRecordTypeId,opp.Id,null);
		AbstractTriggerTest.deployTest('Task_Before.',new List<Task>{tk});
	}
}