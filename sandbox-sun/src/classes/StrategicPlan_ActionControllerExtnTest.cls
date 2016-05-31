/**
 * This is a test class for StrategicPlan_ActionControllerExtn.
 * 
 * @version 2013-06-19
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-06-19 - added task delete for trigger coverage
 * 2013-05-23 - updated test object references
 * 2013-04-08 - created
 */
@IsTest
public class StrategicPlan_ActionControllerExtnTest {
	static StrategicPlan_Solution__c solution {
		get {
			return StrategicPlan_SolutionControllerExtnTest.solution;
		}
	}

	static Id solutionId {
		get {
			return StrategicPlan_SolutionControllerExtnTest.solutionId;
		}
	}

	public static Task task {
		get {
			if(task == null) {
				task = new Task(
					ActionSubject__c='Action Subject',
					ActivityDate=System.today(),
					Description='Anything',
					End__c=System.today(),
					OwnerId=UserInfo.getUserId(),
					RecordTypeId=RecordTypeLookup.getRecordTypeId(StrategicPlan_ActionControllerExtn.SPA_RECORDTYPE_NAME,'Task'),
					Start__c=System.today(),
					Status='Draft',
					Subject='Strategic Plan Solution',
					WhatId=solutionId );
				insert task;
			}
			return task;
		}
	}

	public static StrategicPlan_Action__c action {
		get {
			if(action == null) {
				action = new StrategicPlan_Action__c(
					ActionSubject__c = task.ActionSubject__c,
					AssignedTo__c = task.OwnerId,
					End__c = task.End__c,
					Solution__c = solutionId,
					Start__c = task.Start__c,
					Status__c = task.Status,
					StrategicPlan__c = solution.StrategicPlan__c,
					Strategy__c = solution.Strategy__c,
					Subject__c = task.Subject,
					TaskId__c = task.Id );
				insert action;
			}
			return action;
		}
	}

	@isTest
	static void createFromSolutionTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_ActionNew?ids='+solutionId));
		TabUIController controller = new TabUIController();
		controller.sharedParams.put('StrategicPlan_Action__r.Subject__c','Strategic Plan Solution');
		StrategicPlan_ActionControllerExtn extension = new StrategicPlan_ActionControllerExtn(controller);
		System.assertEquals(null,extension.getId());
		System.assertEquals(solution.StrategicPlan__c,extension.getStrategicPlanId());
		System.assertEquals(solution.Strategy__c,extension.getStrategyId());
		System.assertEquals(solutionId,extension.getSolutionId());
		StrategicPlan_Action__c a = extension.getAction();
		System.assertEquals(null,a.Id);
		System.assertEquals(solution.StrategicPlan__c,a.StrategicPlan__c);
		System.assertEquals(solution.Strategy__c,a.Strategy__c);
		System.assertEquals(solutionId,a.Solution__c);
		extension.task.Start__c = System.today();
		extension.task.End__c = extension.task.Start__c.addDays(1);
		Task t = extension.task;
		a.ActionSubject__c = 'anything';
		t.ActionSubject__c = 'anything';
		extension.saveAction();
		t = [
			select
				ActionSubject__c 
			from Task
			where WhatId = :solutionId ];
		System.assertEquals('anything',t.ActionSubject__c);
		a = [
			select
				ActionSubject__c,
				TaskId__c
			from StrategicPlan_Action__c 
			where TaskId__c = :t.Id ];
		System.assertEquals('anything',a.ActionSubject__c);
		extension.saveAction();
	}

	@isTest
	static void createFromStrategyTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_ActionNew?ids='+solution.Strategy__c));
		TabUIController controller = new TabUIController();
		controller.sharedParams.put('StrategicPlan_Action__r.Subject__c','Strategic Plan Strategy');
		StrategicPlan_ActionControllerExtn extension = new StrategicPlan_ActionControllerExtn(controller);
		System.assertEquals(null,extension.getId());
		System.assertEquals(solution.StrategicPlan__c,extension.getStrategicPlanId());
		System.assertEquals(solution.Strategy__c,extension.getStrategyId());
		System.assertEquals(null,extension.getSolutionId());
		StrategicPlan_Action__c a = extension.getAction();
		System.assertEquals(null,a.Id);
		System.assertEquals(solution.StrategicPlan__c,a.StrategicPlan__c);
		System.assertEquals(solution.Strategy__c,a.Strategy__c);
		System.assertEquals(null,a.Solution__c);
		Task t = extension.task;
		a.ActionSubject__c = 'anything';
		t.ActionSubject__c = 'anything';
		extension.saveAction();
		t = [
			select
				ActionSubject__c 
			from Task
			where WhatId = :solution.Strategy__c ];
		System.assertEquals('anything',t.ActionSubject__c);
		a = [
			select
				ActionSubject__c,
				TaskId__c
			from StrategicPlan_Action__c 
			where TaskId__c = :t.Id ];
		System.assertEquals('anything',a.ActionSubject__c);
		// added strictly for coverage
		delete t;
	}

	@isTest
	static void createFromPlanTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_ActionNew?ids='+solution.StrategicPlan__c));
		TabUIController controller = new TabUIController();
		controller.sharedParams.put('StrategicPlan_Action__r.Subject__c','Strategic Plan');
		StrategicPlan_ActionControllerExtn extension = new StrategicPlan_ActionControllerExtn(controller);
		System.assertEquals(null,extension.getId());
		System.assertEquals(solution.StrategicPlan__c,extension.getStrategicPlanId());
		System.assertEquals(null,extension.getStrategyId());
		System.assertEquals(null,extension.getSolutionId());
		StrategicPlan_Action__c a = extension.getAction();
		System.assertEquals(null,a.Id);
		System.assertEquals(solution.StrategicPlan__c,a.StrategicPlan__c);
		System.assertEquals(null,a.Strategy__c);
		System.assertEquals(null,a.Solution__c);
		Task t = extension.task;
		a.ActionSubject__c = 'anything';
		t.ActionSubject__c = 'anything';
		extension.saveAction();
		t = [
			select
				ActionSubject__c 
			from Task
			where WhatId = :solution.StrategicPlan__c ];
		System.assertEquals('anything',t.ActionSubject__c);
		a = [
			select
				ActionSubject__c,
				TaskId__c
			from StrategicPlan_Action__c 
			where TaskId__c = :t.Id ];
		System.assertEquals('anything',a.ActionSubject__c);
	}

	@isTest
	static void viewTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_ActionView?id='+action.Id));
		ApexPages.StandardController stdController = new ApexPages.StandardController(solution);
		StrategicPlan_ActionControllerExtn extension = new StrategicPlan_ActionControllerExtn(stdController);
		System.assertEquals(action.Id,extension.getId());
		System.assertEquals(solution.StrategicPlan__c,extension.getStrategicPlanId());
		System.assertEquals(solution.Strategy__c,extension.getStrategyId());
		System.assertEquals(solutionId,extension.getSolutionId());
		StrategicPlan_Action__c s = extension.getAction();
		System.assertEquals(action.Id,s.Id);
		System.assertEquals(solution.StrategicPlan__c,s.StrategicPlan__c);
		System.assertEquals(solution.Strategy__c,s.Strategy__c);
		System.assertEquals(solutionId,s.Solution__c);
		System.assertEquals(solution.Strategy__r.Name,s.Strategy__r.Name);
		System.assertEquals(solution.StrategicPlan__c,s.Strategy__r.StrategicPlan__c);
		System.assertEquals(solution.Name,s.Solution__r.Name);
		Task t = extension.task;
		System.assertEquals(task.Id,t.Id);
		extension.getIsDeletable();
	}

}