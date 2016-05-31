/**
 * Since we cannot add triggers for ProcessInstance objects, this class
 * implements a batch job to invoke after a ProcessInstance has been 
 * inserted or updated.  This replaces the Contract_Approvals_Batchable job
 * as well as implement methods for $0 orders.
 * 
 * @version 2015-11-18
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-11-18 - Do not consider records more than two days old in the hasWork method
 * 2014-09-18 - Added implements Database.Stateful as that was removed from the base class
 * 2014-04-21 - created ProcessInstance_Batchable
 * Original Author: Scott Coleman <scoleman@redhat.com>
 * 2014-01-21 - created Contract_Approvals_Batchable
 */
global class ProcessInstance_Batchable extends AbstractBatchable implements Database.Stateful {
	/** Minimum amount of time delay in seconds before processing a record. */
	global static Integer TIME_DELAY = 90;

	/** Picklist value used for pending approvals */
	global static final String PENDING_PLV = 'Pending';

	/** Name of a custom setting key. */
	global static final String LAST_PROCESSED_KEY = 'ProcessInstance.LastProcessed';

	/** 
	 * Keep track of the lastProcessedDateTime
	 */
	global DateTime lastProcessedDateTime {
		get {
			if(lastProcessedDateTime == null) {
				lastProcessedDateTime = DateTime.newInstance(0L);
				DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
				if(lastProcessed != null && lastProcessed.Value__c != null) {
					lastProcessedDateTime = lastProcessed.Value__c;
				}
			}
			return lastProcessedDateTime;
		}
		set;
	}

	/** Do not consider records older than the startWindow */
	global DateTime startWindow = DateTime.newInstance(0L);

	/**
	 * Default constructor.
	 */
	global ProcessInstance_Batchable() {
		super('ProcessInstance_Batchable');
	}

	/**
	 * Check if there is work for this job to do.
	 *
	 * @return false if there is no work to do.
	 */
	global override Boolean hasWork() {
		DateTime minSystemModstamp = DateTime.now().addDays(-2);
		if(lastProcessedDateTime > minSystemModstamp) {
			minSystemModstamp = lastProcessedDateTime;
		}
		// return all rows for inserts, updates, and deletes since the
		// last time we ran
		return (0 < [
			select count()
			from ProcessInstance
			where SystemModstamp > :minSystemModstamp
				and SystemModstamp <= :DateTime.now().addSeconds(-TIME_DELAY)
			limit 1]);
	}

	/**
	 * Query the ProcessInstances records which have been inserted, updated, or deleted.
	 */
	global Database.QueryLocator start(Database.BatchableContext bc) {
		// return all rows for inserts, updates, and deletes since the
		// last time we ran
		startWindow = lastProcessedDateTime;
		lastProcessedDateTime = DateTime.now().addSeconds(-TIME_DELAY);
		return Database.getQueryLocator([
			select
				Id,
				CreatedDate,
				LastModifiedDate,
				Status,
				SystemModstamp,
				TargetObjectId,
				(	select 
						ActorId,
						CreatedDate,
						OriginalActorId,
						SystemModstamp,
						Actor.Alias,
						Actor.Name
					from Workitems
					order by SystemModstamp DESC, Actor.Name ASC )
			from ProcessInstance 
			where SystemModstamp > :startWindow
				and SystemModstamp <= :lastProcessedDateTime
			order by CreatedDate ]);
	}

	/**
	 * Called to execute a subset of the inserts and updates.
	 * 
	 * @param bc the batchable context (not used)
	 * @param piList the list to update
	 */
	global void execute(Database.BatchableContext bc, List<ProcessInstance> piList) {
		Map<Id,ProcessInstance> piMap = new Map<Id,ProcessInstance>();
		for(ProcessInstance pi : piList) {
			piMap.put(pi.TargetObjectId,pi);
		}
		// filter out historical process instance records
		for(AggregateResult ar : [
			select
				TargetObjectId,
				MAX(CreatedDate) maxCreatedDate
			from ProcessInstance
			where TargetObjectId in :piMap.keySet()
				and SystemModstamp > :startWindow
			group by TargetObjectId ])
		{
			Id targetObjectId = (Id)ar.get('TargetObjectId');
			if(piMap.get(targetObjectId).CreatedDate <  (DateTime)ar.get('maxCreatedDate')) {
				piMap.remove(targetObjectId);
			}
		}
		Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([
			select
				Id,
				ApprovalStatus__c,
				AssignedApprovers__c
			from Opportunity
			where Id in :piMap.keySet()
				and ApprovalStatus__c = :PENDING_PLV ]);
		Map<Id,Contract> contractMap = new Map<Id,Contract>([
			select 
				Id, 
				Approval_Status__c, 
				Pending_Approval_By__c, 
				Pending_Approval_Date__c
			from Contract
			where Id IN :piMap.keySet() ]);
		// filter any ProccessInstances not associated to an Opportunity or a Contract
		Set<Id> ids = new Set<Id>(oppMap.keySet());
		ids.addAll(contractMap.keySet());
		piMap.keySet().retainAll(ids);
		execute(piMap,oppMap,contractMap);
	}

	/**
	 * Called to execute a subset of the inserts and updates.  We split this into a separate 
	 * method so it do unit test.
	 * 
	 * @param piMap map of process instances by target object id
	 * @param oppMap map of opportunities to update
	 * @param contractMap map of contracts to update
	 */
	global void execute(Map<Id,ProcessInstance> piMap,Map<Id,Opportunity> oppMap,Map<Id,Contract> contractMap) {
		try {
			if(! piMap.isEmpty()) {
				// figure out which contracts need updating
				Map<Id,Contract> updateContractMap = new Map<Id,Contract>();
				Map<Id,Opportunity> updateOppMap = new Map<Id,Opportunity>();
				for(ProcessInstance approval : piMap.values()) {
					String pendingApprovalBy = '';
					Datetime pendingApprovalDate = null;
					if(approval.Workitems != null && !approval.Workitems.isEmpty()) {
						String sep = '';
						String pendingApprovalBy2 = '';
						for (ProcessInstanceWorkitem approvalItem : approval.Workitems) {
							pendingApprovalBy += sep+approvalItem.Actor.Name;
							pendingApprovalBy2 += sep+approvalItem.Actor.Alias;
							pendingApprovalDate = approvalItem.SystemModstamp;
							sep = ', ';
						}
						if(pendingApprovalBy.length() > 255) {
							pendingApprovalBy = pendingApprovalBy2;
						}
					}
					Contract contract = contractMap.get(approval.TargetObjectId);
					if(contract != null) {
						if(contract.Approval_Status__c != approval.Status 
							|| contract.Pending_Approval_By__c != pendingApprovalBy
							|| contract.Pending_Approval_Date__c != pendingApprovalDate)
						{
							contract.Approval_Status__c = approval.Status;
							contract.Pending_Approval_By__c = pendingApprovalBy;
							contract.Pending_Approval_Date__c = pendingApprovalDate;
							updateContractMap.put(contract.Id, contract);
						}
					}
					else {
						Opportunity opp = oppMap.get(approval.TargetObjectId);
						if(opp != null 
							&& opp.AssignedApprovers__c != pendingApprovalBy
							&& opp.ApprovalStatus__c == approval.Status)
						{
							opp.AssignedApprovers__c = pendingApprovalBy;
							updateOppMap.put(opp.Id,opp);
						}
					}
				}
				// update contracts
				if(!updateContractMap.isEmpty()) {
					Database.update(updateContractMap.values(),false);
				}
				// update opportunities
				if(!updateOppMap.isEmpty()) {
					Database.update(updateOppMap.values(),false);
				}
			}
		}
		catch(Exception ex) {
			errorList.add('Exception: '+ex+'\n'+ex.getStackTraceString());
		}
	}

	/**
	 * finish method
	 *
	 * @param job the async apex job
	 */
	global override void finish(AsyncApexJob job) {
		DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
		if(lastProcessed == null) {
			lastProcessed = new DateTimeSetting__c(Name=LAST_PROCESSED_KEY);
		}
		lastProcessed.Value__c = lastProcessedDateTime;
		try {
			upsert lastProcessed;
		}
		catch(Exception e) {
			errorList.add('Failed to update lastProcessed '+e);
		}
		super.finish(job);
	}
}