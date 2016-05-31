/**
 * This class contains unit tests for validating the TaskTriggerAfter class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-04-08
 * 2013-04-08 - Add syncActionsTest
 * 2011-09-23 - Created
 */
@isTest
private class TaskTriggerAfterTest {
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
					Triage_Opportunity__c = false);
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

	static Task actionTask {
		get {
			return StrategicPlan_ActionControllerExtnTest.task;
		}
	}

	static StrategicPlan_Action__c action {
		get {
			return StrategicPlan_ActionControllerExtnTest.action;
		}
	}

	@isTest
	static void syncActionsTest() {
		Task task2 = actionTask.clone(true);
		task2.ActionSubject__c = 'new subject';
		Id actionId = action.Id;
		TaskTriggerAfter afterTrigger = new TaskTriggerAfter(new Map<Id,Task>{actionTask.Id=>actionTask},new Map<Id,Task>{task2.Id=>task2});
		afterTrigger.syncActions();
		StrategicPlan_Action__c action2 = [
			select
				ActionSubject__c
			from StrategicPlan_Action__c
			where Id = : action.Id ];
		System.assertEquals('new subject',action2.ActionSubject__c);
	}

	@isTest
	static void tandemNotifyTest() {
		Task tk = createTask(Util.tandemRecordTypeId,opp.Id,null);
		Task tk2 = tk.clone(true);
		TaskTriggerAfter afterTrigger = new TaskTriggerAfter(new Map<Id,Task>{tk.Id=>tk},new Map<Id,Task>{tk2.Id=>tk2});
		afterTrigger.tandemNotify();
	}

	@isTest
	static void oppTriageTest() {
		Task tk = createTask(Util.omCorrectionRequestRecordTypeId,opp.Id,null);
		TaskTriggerAfter afterTrigger = new TaskTriggerAfter(null,new Map<Id,Task>{tk.Id=>tk});
		afterTrigger.oppTriage();
		Opportunity opp2 = [select Triage_Opportunity__c from Opportunity where Id = :opp.Id];
		System.assert(opp2.Triage_Opportunity__c);
	}

	@isTest
	static void updateLeadsTest() {
		Task tk = createTask(Util.tandemRecordTypeId,null,ld.Id);
		Task tk2 = tk.clone(true);
		TaskTriggerAfter afterTrigger = new TaskTriggerAfter(new Map<Id,Task>{tk.Id=>tk},new Map<Id,Task>{tk2.Id=>tk2});
		afterTrigger.updateLeads();
		Lead ld2 = [select Status from Lead where Id = :ld.Id ];
		// The following assert is only true if the respective lead trigger is active
		// System.assertNotEquals(ld2.Status, ld.Status);
		System.debug('The following should be true: '+ld2.Status +'!=' + ld.Status);
	}

	@isTest
	static void monitorActivitiesTest() {
		Task tk = createTask(Util.tandemRecordTypeId,null,ld.Id);
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('Task_After.',false);
		insert tk;
		tk.Monitor__c = true;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Task_After.',true);
		TaskTriggerAfter afterTrigger = new TaskTriggerAfter(null,new Map<Id,Task>{tk.Id=>tk});
		afterTrigger.monitorActivities();
		MonitoredActivity__c ma = [
			select Subject__c from MonitoredActivity__c 
			where TaskId__c = :tk.Id];
		System.assertEquals(tk.Subject,ma.Subject__c);
		Task tk2 = tk.clone(true);
		tk2.Monitor__c = false;
		afterTrigger = new TaskTriggerAfter(new Map<Id,Task>{tk.Id=>tk},new Map<Id,Task>{tk2.Id=>tk2});
		afterTrigger.monitorActivities();
		System.assertEquals(0,[select COUNT() from MonitoredActivity__c where TaskId__c = :tk.Id]);
	}

	@isTest // (SeeAllData=true) is not needed anymore because we insert missing settings
	static void processTriggerTest() {
		Task tk = createTask(Util.tandemRecordTypeId,null,ld.Id);
		// Turn off all triggers as we just want to insert missing settings
		AbstractTrigger.setBooleanSettings('Task_After.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		TaskTriggerAfter.processTrigger(null,new Map<Id,Task>{null=>tk});
		// insert the task, again with the triggers off
		insert tk;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Task_After.',true);
		Task tk2 = tk.clone(true);
		AbstractTrigger.insertMissing = 0;
		Test.startTest();
		// insert test
		TaskTriggerAfter.processTrigger(null,new Map<Id,Task>{tk2.Id=>tk2});
		// update test
		TaskTriggerAfter.processTrigger(new Map<Id,Task>{tk.Id=>tk},new Map<Id,Task>{tk2.Id=>tk2});
		// delete test
		TaskTriggerAfter.processTrigger(new Map<Id,Task>{tk.Id=>tk},null);
		Test.stopTest();
		// Just confirm all the settings either exist or were inserted.
		AbstractTriggerTest.validateSettings('Task_After.');
	}

	@isTest
	static void deployTest() {
		Task tk = createTask(Util.tandemRecordTypeId,null,ld.Id);
		AbstractTriggerTest.deployTest('Task_After.',new List<Task>{tk});
	}
}