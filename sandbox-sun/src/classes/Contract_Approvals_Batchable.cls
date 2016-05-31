/**
 * This class periodically reflects information about pending approvals onto Contract records.
 *
 * This job is scheduled with the Daily Scheduler.
 *
 * To run manually: Id batchInstanceId = Database.executeBatch(new Contract_Approvals_Batchable(), 100); 
 *
 * @version 2014-01-21
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-01-21 - Created
 */
global class Contract_Approvals_Batchable  implements Database.Batchable<SObject>, Database.Stateful {
	Integer days = 7;

	global Contract_Approvals_Batchable(Integer windowDays) {
		days = windowDays;
	}

	global Contract_Approvals_Batchable() {}

	/**
	 * start method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 * @return	List<SObject> - list of ProcessInstance objects
	 */
	global Database.QueryLocator start(Database.BatchableContext bc) {
		Date startOfWindow = System.today().addDays(-1*days);
		return Database.getQueryLocator([
			SELECT 
				Id,
				LastModifiedDate,
				Status,
				SystemModstamp,
				TargetObjectId,
				(SELECT 
					ActorId,
					CreatedDate,
					OriginalActorId,
					SystemModstamp,
					Actor.Name
				FROM Workitems
				ORDER BY SystemModstamp DESC, Actor.Name ASC)
			FROM ProcessInstance 
			WHERE SystemModstamp > :startOfWindow
			ORDER BY CreatedDate DESC]);
	}

	/**	
	 * execute method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 * @param	List<SObject> approvalObjects - list of ProcessInstance objects
	 */
	global void execute(Database.BatchableContext bc, List<SObject> approvalObjects) {
		
		Set<Id> contractIds = new Set<Id>();
		List<ProcessInstance> contractApprovals = new List<ProcessInstance>();
		
		for(sObject obj : approvalObjects) {
			
			ProcessInstance approval = (ProcessInstance)obj;
			
			// check if it's a Contract
			if(String.valueOf(approval.TargetObjectId).startsWith('800')) {
				contractApprovals.add(approval);
				contractIds.add(approval.TargetObjectId);
			}
		}

		// get contracts
		Map<Id,Contract> contracts = new Map<Id,Contract>([SELECT 
																Id, 
																Approval_Status__c, 
																Pending_Approval_By__c, 
																Pending_Approval_Date__c
															FROM Contract
															WHERE Id IN :contractIds]);
		
		// figure out which contracts need updating
		Map<Id,Contract> updateContracts = new Map<Id,Contract>();
		Set<Id> reviewedContracts = new Set<Id>();
		
		if(!contracts.isEmpty()) {
			
			for(ProcessInstance approval : contractApprovals) {
				
				if(contracts.containsKey(approval.TargetObjectId) && !reviewedContracts.contains(approval.TargetObjectId)) {
					
					String approvalStatus = approval.Status;
					String pendingApprovalBy = null;
					Datetime pendingApprovalDate = null;

					if(approval.Workitems != null && !approval.Workitems.isEmpty()) {
						
						for (ProcessInstanceWorkitem approvalItem : approval.Workitems) {
							
							if(pendingApprovalBy == null) {
								pendingApprovalBy = approvalItem.Actor.Name;
								pendingApprovalDate = approvalItem.SystemModstamp;
							}
							else if(pendingApprovalDate == approvalItem.SystemModstamp) {
								pendingApprovalBy = pendingApprovalBy + ', ' + approvalItem.Actor.Name;
							}
						}
					}
					
					Contract contract = contracts.get(approval.TargetObjectId);
					
					if(contract.Approval_Status__c != approvalStatus 
						|| contract.Pending_Approval_By__c != pendingApprovalBy
						|| contract.Pending_Approval_Date__c != pendingApprovalDate) {

						contract.Approval_Status__c = approvalStatus;
						contract.Pending_Approval_By__c = pendingApprovalBy;
						contract.Pending_Approval_Date__c = pendingApprovalDate;
						updateContracts.put(contract.Id, contract);
					}
					
					reviewedContracts.add(approval.TargetObjectId);
				}		 
			}
		}

		// update contracts
		if(!updateContracts.isEmpty()) {
			Database.update(updateContracts.values(),false);
		}
	}

	/**
	 * finish method impl for Database.Batchable interface
	 *
	 * @param	Database.BatchableContext bc
	 */
	global void finish(Database.BatchableContext bc) {
		//nothing to do here for now
	}
}