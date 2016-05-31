/**
 * This class replaces all before insert and before update and before delete
 * task triggers.  The processTrigger method is invoked by the Task_Before trigger 
 * and in turn invokes all the methods of this class.  This gives us a way to control 
 * the order in which the code logic is invoked, as well as allowing other class 
 * features such as shared data, constant values, and rigorous test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-04-08
 * 2013-04-08 - Added the actionFields method
 * 2012-06-02 - Updated for SMR
 * 2011-09-26 - Created
 */
public without sharing class TaskTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable the actionFields trigger method. */
	public static final String ACTION_FIELDS_SETTING = 'Task_Before.actionFields';
	/** BooleanSetting__c key to enable the trackDueDate trigger method. */
	public static final String TRACK_DUE_DATE_SETTING = 'Task_Before.trackDueDate';
	/** BooleanSetting__c key to enable the preventDelete trigger method. */
	public static final String PREVENT_DELETE_SETTING = 'Task_Before.preventDelete';
	/** BooleanSetting__c key to enable the updateStatus trigger method. */
	public static final String LEAD_PARTNER_SETTING = 'Task_Before.leadPartner';
	/** BooleanSetting__c key to enable the sendNotify trigger method. */
	public static final String SEND_NOTIFY_SETTING = 'Task_Before.sendNotify';
	/** BooleanSetting__c key to enable the nullContent trigger method. */
	public static final String NULL_CONTENT_SETTING = 'Task_Before.nullContent';
	/** BooleanSetting__c key to enable the closedDate trigger method. */
	public static final String CLOSED_DATE_SETTING = 'Task_Before.closedDate';
	/** BooleanSetting__c key to enable the assignLegacy trigger method. */
	public static final String ASSIGN_LEGACY_SETTING = 'Task_Before.assignLegacy';
	private final Map<Id,Task> oldMap = new Map<Id,Task>();
	private final List<Task> newList = new List<Task>();
	
	/**
	 * This is a typical TriggerBefore type constructor.
	 *
	 * @param oldMap typically assigned from Trigger.oldMap
	 * @param newList typically assigned from Trigger.newList
	 */
	public TaskTriggerBefore(Map<Id,Task> xoldMap,List<Task> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	/**
	 * Method to use keep the action fields with sane settings.
	 */
	public void actionFields() {
		for(Task t : newList) {
			Task o = null;
			if(isUpdate) {
				o = oldMap.get(t.Id);
			}
			if(o != null && o.Subject != null && o.Subject != t.Subject && o.Subject.toUpperCase().startsWith('STRATEGIC PLAN')) {
				t.addError('This value cannot be changed.');
			}
			if(t.Start__c != null) {
				if(t.ActivityDate == null || t.ActivityDate.daysBetween(t.Start__c) > 0) {
					t.ActivityDate = t.Start__c;
				}
				if(t.End__c != null && t.End__c.daysBetween(t.Start__c) > 0) {
					t.addError('You cannot end this task before starting.');
				}
			}
			if(t.End__c != null) {
				if(t.ActivityDate == null || t.ActivityDate.daysBetween(t.End__c) > 0) {
					t.ActivityDate = t.End__c;
				}
			}
		}
	}

	/**
	 * Method to replace the TrackDueDate trigger
	 */
	public void trackDueDate() {
		if(isUpdate) {
			DateTime n = null;
			for(Task tk : newList) {
				if( tk.RecordTypeId==Util.tandemRecordTypeId) {
					Task tkOld = oldMap.get(tk.Id);
					if(tkOld.ActivityDate != tk.ActivityDate ) {
						if(n == null) {
							n = DateTime.now();
						}
						tk.Due_Date_Changed_On__c = n;
						tk.Last_Due_Date__c = tkOld.ActivityDate;
					}
				}
			}
		}
	}

	/**
	 * Method to replace the DeletionOMCorrection trigger
	 */
	public void preventDelete() {
		if(isDelete) {
			for(Task tk : oldMap.values()) {
				if(tk.Subject=='OM Correction Requested' || tk.Subject=='TRIAGE REQUEST' ) {
					tk.adderror('OM Correction Task cannot be deleted!!');
				}
			}
		}
	}

	public List<Task> oppRelatedTasks {
		get {
			if(oppRelatedTasks == null) {
				oppRelatedTasks = new List<Task>();
				for(Task tk : newList) {
					if((tk.WhatId+'').startsWith('006')) {
						oppRelatedTasks.add(tk);
					}
				}
			}
			return oppRelatedTasks;
		}
		set;
	}

	public Set<Id> requestedOppIds = new Set<Id>();
	public Map<Id,Opportunity> retainedOppMap = new Map<Id,Opportunity>();

	public Map<Id,Opportunity> getOpportunityMap(Set<Id> oppIds) {
		Set<Id> oppIds2 = oppIds.clone();
		oppIds2.removeAll(requestedOppIds);
		if(! oppIds2.isEmpty()) {
			retainedOppMap.putAll([
				select
					Country_of_Order__c,
					Triage_Opportunity__c
				from Opportunity 
				where Id in :oppIds2 ]);
			requestedOppIds.addAll(oppIds2);
		}
		Map<Id,Opportunity> retval = retainedOppMap.clone();
		retval.keySet().retainAll(oppIds);
		return retval;
	}

	/**
	 * This method replaces the LeadTaskPartner_update trigger.
	 */
	public void leadPartner() {
		if(isInsert || isUpdate) {
			//This logic will update task with corresponding opportunity region.
			Set<Id> oppIds = new Set<Id>();
			for(Task tk : oppRelatedTasks) {
				oppIds.add(tk.WhatId);
			}

			Map<Id,Opportunity> oppMap = getOpportunityMap(oppIds);
			for(Task tk : oppRelatedTasks) {
				Opportunity opp = oppMap.get(tk.WhatId);
				if(opp != null) {
					tk.Related_Opportunity_Region__c = opp.Country_of_Order__c;
				}
			}

			//This logic will update task with partner related details 
			if(! Util.adminByPass()) {
				new LeadTaskUpdate().updateLeadTask(newList);
			}
		}
	}

	/**
	 * Method to replace the updateSendNotification trigger
	 */
	public void sendNotify() {
		if(isUpdate) {
			Map<Id,List<Task>> tasksByOppId=new Map<Id,List<Task>>();
			for(Task tk : oppRelatedTasks) {
				if(tk.Send_Notification__c == true) {
					List<Task> tasks = tasksByOppId.get(tk.WhatId);
					if(tasks == null) {
						tasks = new List<Task>();
						tasksByOppId.put(tk.WhatId,tasks);
					}
					tasks.add(tk);
				}
			}
			List<Opportunity> opps = new List<Opportunity>();
			for(Opportunity opp : getOpportunityMap(tasksByOppId.keySet()).values()) {
				if(opp.Triage_Opportunity__c == true) {
					opp.Send_Notification_to_Opp_Owner__c = true;
					opps.add(opp);
					for(Task tk : tasksByOppId.get(opp.Id)) {
						tk.Send_Notification__c = false;
					}
				}
			}
			if(! opps.isEmpty()) {
				for(Database.SaveResult sr : Database.update(opps,false)) {
					Opportunity opp = opps.remove(0);
					for(Database.Error e : sr.getErrors()) {
						for(Task tk : tasksByOppId.get(opp.Id)) {
							tk.addError('Failed to update '+opp+': '+e);
						}
					}
				}
			}
		}
	}

	/**
	 * Method to replace the TaskContentNull trigger
	 */
	public void nullContent() {
		if(isUpdate && ! Util.adminByPass(true)) {
			for(Task task : oldMap.values()) {
				if(task.Contents__c != null && task.Contents__c != '') {
					task.addError('Permission denied to update this task.');
				}
			}
		}
	}

	/**
	 * Method to set the ClosedDate__c field when the activity is closed.
	 * It turns out IsClosed is a calculated value that is not update until
	 * after the before trigger run.  So we always set the ClosedDate__c value
	 * to the current time, unless the previous state was IsClosed.
	 */
	public void closedDate() {
		if(isInsert || isUpdate) {
			DateTime n = null;
			for(Task task : newList) {
				if(isInsert || oldMap.get(task.Id).IsClosed == false) {
					if(n == null) {
						n = DateTime.now();
					}
					task.ClosedDate__c = n;
					DateTime dueDateTime = null;
					if(task.ActivityDate != null) {
						dueDateTime = DateTime.newInstance(task.ActivityDate.addDays(1),Time.newInstance(0,0,0,0));
					}
					task.Due_Date_Time__c = dueDateTime;
				}
			}
		}
	}

	/**
	 * Trigger method to assign Legacy_Profile__c and Legacy_Role__c values.
	 */
	public override void assignLegacy() {
		Set<Id> ownerIds = new Set<Id>();
		Map<Id,User> ownerMap = new Map<Id,User>{
			null=>new User(Legacy_Profile__c=null,Legacy_Role__c=null) };
		for(Task t : newList) {
			Id ownerId = null;
			if((''+t.OwnerId).startsWith('005')) {
				ownerId = t.OwnerId;
			}
			if(t.Owner__c != ownerId) {
				t.Owner__c = ownerId;
				ownerIds.add(ownerId);
			}
			else {
				ownerMap.put(
					t.Owner__c,
					new User(
						Legacy_Profile__c=t.Legacy_Profile__c,
						Legacy_Role__c=t.Legacy_Role__c));
			}
		}
		ownerIds.removeAll(ownerMap.keySet());
		if(! ownerIds.isEmpty()) {
			ownerMap.putAll(
				new Map<Id,User>([
					select
						Legacy_Profile__c,
						Legacy_Role__c
					from User
					where Id in :ownerIds]) );
			for(Task t : newList) {
				User u = ownerMap.get(t.Owner__c);
				if(u != null) {
					if(u.Legacy_Profile__c != t.Legacy_Profile__c) {
						t.Legacy_Profile__c = u.Legacy_Profile__c;
					}
					if(u.Legacy_Role__c != t.Legacy_Role__c) {
						t.Legacy_Role__c = u.Legacy_Role__c;
					}
				}
			}
		}
	}

	/**
	 * This method is called from the Task_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Task objects as in Trigger.oldMap.
	 * @param xnewList the list of new Task objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,Task> xoldMap,List<Task> xnewList) {
		final TaskTriggerBefore beforeTrigger = new TaskTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(ACTION_FIELDS_SETTING,true)) {
			beforeTrigger.actionFields();
		}
		if(AbstractTrigger.isActive(CLOSED_DATE_SETTING,true)) {
			beforeTrigger.closedDate();
		}
		if(AbstractTrigger.isActive(TRACK_DUE_DATE_SETTING,true)) {
			beforeTrigger.trackDueDate();
		}
		if(AbstractTrigger.isActive(PREVENT_DELETE_SETTING,true)) {
			beforeTrigger.preventDelete();
		}
		if(AbstractTrigger.isActive(LEAD_PARTNER_SETTING,true)) {
			beforeTrigger.leadPartner();
		}
		if(AbstractTrigger.isActive(SEND_NOTIFY_SETTING,true)) {
			beforeTrigger.sendNotify();
		}
		if(AbstractTrigger.isActive(NULL_CONTENT_SETTING,true)) {
			beforeTrigger.nullContent();
		}
		if(AbstractTrigger.isActive(ASSIGN_LEGACY_SETTING,true)) {
			beforeTrigger.assignLegacy();
		}
		AbstractTrigger.processTriggerComplete();
	}
}