/**
 * This is a controller extension used for the StrategicPlan_ActionTab page.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-04-22
 * 2013-03-19 - created
 * Scott Coleman <scoleman@redhat.com>
 * 2013-04-22 - Added contribution tracking  
 */
public with sharing class StrategicPlan_ActionControllerExtn extends TabUIController.Extension {
	private static final String TAB_NAME='StrategicPlan_Action__c';
	/** RecordType name used for Strategic Plan Actions. */
	public static final String SPA_RECORDTYPE_NAME = 'Strategic Plan Action';

	/**
	 * Construct using a TabUIController.
	 * 
	 * @param tabUIController
	 */
	public StrategicPlan_ActionControllerExtn(TabUIController tabUIController) {
		super(TAB_NAME,tabUIController);
		getRecord();
	}

	/**
	 * Construct using a standard controller.
	 * 
	 * @param stdController
	 */
	public StrategicPlan_ActionControllerExtn(ApexPages.StandardController stdController) {
		super(TAB_NAME);
		getRecord();
	}

	/**
	 * Get the Strategic Plan Id.
	 *
	 * @return strategicPlanId
	 */
	public Id getStrategicPlanId() {
		return tabUIController.getTabId('StrategicPlan__c');
	}

	/**
	 * Set the Strategic Plan Id.
	 *
	 * @param strategicPlanId
	 */
	public void setStrategicPlanId(Id planId) {
		tabUIController.setTabId('StrategicPlan__c',planId);
	}

	/**
	 * Get the Strategy Id.
	 *
	 * @return strategyId
	 */
	public Id getStrategyId() {
		return tabUIController.getTabId('StrategicPlan_Strategy__c');
	}

	/**
	 * Set the Strategy Id.
	 *
	 * @param strategyId
	 */
	public void setStrategyId(Id strategyId) {
		tabUIController.setTabId('StrategicPlan_Strategy__c',strategyId);
	}

	/**
	 * Get the Solution Id.
	 *
	 * @return solutionId
	 */
	public Id getSolutionId() {
		return tabUIController.getTabId('StrategicPlan_Solution__c');
	}

	/**
	 * Set the Solution Id.
	 *
	 * @param solutionId
	 */
	public void setSolutionId(Id solutionId) {
		tabUIController.setTabId('StrategicPlan_Solution__c',solutionId);
	}

	/**
	 * Overload of the getRecord method to call getAction.
	 *
	 * @return record
	 */
	public override SObject getRecord() {
		return getAction();
	}

	/**
	 * Query or create the action.
	 *
	 * @return action
	 */
	public StrategicPlan_Action__c getAction() {
		StrategicPlan_Action__c action = (StrategicPlan_Action__c)super.getRecord();
		Id id = getId();
		if(action == null || action.Id != id) {
			task = null;
			action = null;
			if(id != null) {
				action = [
					select
						ActionSubject__c,
						AssignedTo__c,
						CreatedBy.FirstName,
						CreatedBy.LastName,
						CreatedDate,
						End__c,
						LastModifiedBy.FirstName,
						LastModifiedBy.LastName,
						LastModifiedDate,
						Name,
						Solution__r.Name,
						Solution__r.SolutionNumber__c,
						Solution__r.StrategicPlan__c,
						Solution__r.StrategicPlan__r.Name,
						Solution__r.StrategicPlan__r.PlanNumber__c,
						Solution__r.Strategy__c,
						Solution__r.Strategy__r.StrategyNumber__c,
						Solution__r.Strategy__r.StrategicPlan__c,
						Solution__r.Strategy__r.StrategicPlan__r.Name,
						Solution__r.Strategy__r.StrategicPlan__r.PlanNumber__c,
						Start__c,
						Status__c,
						StrategicPlan__r.Name,
						StrategicPlan__r.PlanNumber__c,
						Strategy__r.Name,
						Strategy__r.StrategyNumber__c,
						Strategy__r.StrategicPlan__c,
						Strategy__r.StrategicPlan__r.Name,
						Strategy__r.StrategicPlan__r.PlanNumber__c,
						Subject__c,
						TaskId__c
					from StrategicPlan_Action__c
					where Id = :id ];
			}
			else if(getMode() == 'new') {
				action = new StrategicPlan_Action__c(AssignedTo__c=UserInfo.getUserId());
				action.Subject__c = tabUIController.sharedParams.get('StrategicPlan_Action__r.Subject__c');
				if(action.Subject__c == 'Strategic Plan Solution') {
					action.Solution__c = getSolutionId();
					action.Strategy__c = getStrategyId();
				}
				else if(action.Subject__c == 'Strategic Plan Strategy') {
					action.Strategy__c = getStrategyId();
				}
				else {
					action.Subject__c = 'Strategic Plan';
				}
				action.StrategicPlan__c = getStrategicPlanId();
			}
			setRelatedTo(action);
			setRecord(action);
		}
		return action;
	}

	private void setRelatedTo(StrategicPlan_Action__c action) {
		if(action != null) {
			if(action.Solution__c != null && (action.Subject__c == 'Strategic Plan Solution' || (action.Strategy__c == null && action.StrategicPlan__c == null))) {
				if(action.Solution__r == null || action.Solution__r.Id != action.Solution__c) {
					action.Solution__r = [
						select
							Name,
							SolutionNumber__c,
							StrategicPlan__c,
							StrategicPlan__r.Name,
							StrategicPlan__r.PlanNumber__c,
							Strategy__c,
							Strategy__r.Name,
							Strategy__r.StrategyNumber__c,
							Strategy__r.StrategicPlan__c,
							Strategy__r.StrategicPlan__r.Name,
							Strategy__r.StrategicPlan__r.PlanNumber__c
						from StrategicPlan_Solution__c
						where Id = :action.Solution__c ];
				}
				action.Strategy__c = action.Solution__r.Strategy__c;
				action.Strategy__r = action.Strategy__r;
				action.StrategicPlan__r = action.Solution__r.StrategicPlan__r;
			}
			else if(action.Strategy__c != null && (action.Subject__c == 'Strategic Plan Strategy' || action.StrategicPlan__c == null)) {
				if(action.Strategy__r == null || action.Strategy__r.Id != action.Strategy__c) {
					action.Strategy__r = [
						select
							Name,
							StrategicPlan__c,
							StrategicPlan__r.Name,
							StrategicPlan__r.PlanNumber__c,
							StrategyNumber__c
						from StrategicPlan_Strategy__c
						where Id = :action.Strategy__c ];
				}
				action.StrategicPlan__r = action.Strategy__r.StrategicPlan__r;
				action.Solution__r = null;
				action.Solution__c = null;
			}
			else if(action.StrategicPlan__c != null) {
				if(action.strategicPlan__r == null || action.strategicPlan__r.Id != action.StrategicPlan__c) {
					action.StrategicPlan__r = [
						select
							Name,
							PlanNumber__c
						from StrategicPlan__c
						where Id = :action.StrategicPlan__c ];
				}
				action.Solution__r = null;
				action.Solution__c = null;
				action.Strategy__r = null;
				action.Strategy__c = null;
			}
			if(action.StrategicPlan__c == null) {
				action.StrategicPlan__c = action.StrategicPlan__r.Id;
			}
			if(action.Solution__r != null) {
				action.Subject__c = 'Strategic Plan Solution';
				setSolutionId(action.Solution__c);
				setStrategyId(action.Solution__r.Strategy__c);
				setStrategicPlanId(action.Solution__r.StrategicPlan__c);
			}
			else if(action.Strategy__r != null) {
				action.Subject__c = 'Strategic Plan Strategy';
				setSolutionId(null);
				setStrategyId(action.Strategy__c);
				setStrategicPlanId(action.Strategy__r.StrategicPlan__c);
			}
			else if(action.StrategicPlan__r != null) {
				action.Subject__c = 'Strategic Plan';
				setSolutionId(null);
				setStrategyId(null);
				setStrategicPlanId(action.StrategicPlan__c);
			}
		}
	}

	private void setRelatedTo(StrategicPlan_Action__c action,Task task) {
		setRelatedTo(action);
		task.Subject = action.Subject__c;
		Id whatId = action.Solution__c;
		if(task.Subject != 'Strategic Plan Solution') {
			whatId = action.Strategy__c;
			if(task.Subject != 'Strategic Plan Strategy') {
				whatId = action.StrategicPlan__c;
			}
		}
		task.WhatId = whatId;
	}

	public Task task {
		get {
			StrategicPlan_Action__c action = getAction();
			if(task == null && action != null) {
				if(action.TaskId__c == null) {
					task = new Task(
						OwnerId = UserInfo.getUserId(),
						RecordTypeId=RecordTypeLookup.getRecordTypeId(SPA_RECORDTYPE_NAME,'Task'),
						Status = 'Not Started');
				}
				else {
					task = [
						select
							ActionSubject__c,
							ActivityDate,
							CreatedBy.FirstName,
							CreatedBy.LastName,
							CreatedDate,
							Description,
							End__c,
							IsReminderSet,
							LastModifiedBy.FirstName,
							LastModifiedBy.LastName,
							LastModifiedDate,
							OwnerId,
							ReminderDateTime,
							RecordTypeId,
							Start__c,
							Status,
							Subject,
							WhatId
						from Task where Id = :action.TaskId__c ];
				}
			}
			return task;
		}
		set;
	}

	public PageReference saveAction() {
		PageReference retval = null;
		Savepoint sp = Database.setSavepoint();
		try {
			StrategicPlan_Action__c action = getAction();
			if(task.Start__c != null) {
				task.ActivityDate = task.Start__c;
			}
			if(task.End__c != null) {
				task.ActivityDate = task.End__c;
			}
			task.IsReminderSet = (task.ReminderDateTime != null);
			task.OwnerId = action.AssignedTo__c;
			action.ActionSubject__c = task.ActionSubject__c;
			action.End__c = task.End__c;
			action.Start__c = task.Start__c;
			action.Status__c = task.Status;
			setRelatedTo(action,task);
			Boolean needsInsert = (task.Id == null);
			if(needsInsert) {
				insert task;
			}
			action.TaskId__c = task.Id;
			upsert action;
			if(! needsInsert) {
				update task;
			}
			task = null;
			setId(action.Id);
			setRecord(null);
			retval = new PageReference('/'+getRecord().Id);
			logEvent('SPActionEdit',getStrategicPlanId());
		}
		catch(Exception e) {
			ApexPages.addMessages(e);
			Database.rollback(sp);
		}
		return retval;
	}
}