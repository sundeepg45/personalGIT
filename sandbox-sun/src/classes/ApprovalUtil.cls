/**
 * This is a static util class that supports apex classes
 * that interface with standard approval processes.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-04-04
 * 2013-04-04 - created for use with Strategic Plan approval
 */
public without sharing class ApprovalUtil {
	public static Id getApprovalWorkItemId(Id userId, Id id) {
		Id approvalWorkItemId = null;
		List<Id> delegatorIds = getApprovalDelegatorIds(userId);
		List<ProcessInstanceWorkitem> workItems = [
			select 
				Id
			from ProcessInstanceWorkitem 
			where (ActorId = :userId or ActorId in :delegatorIds)
				and ProcessInstance.TargetObjectId = :id];
		if(workItems != null && workItems.size() > 0) {
			approvalWorkItemId = workItems[0].Id;
		}
		return approvalWorkItemId;
	}
	
	public static List<Id> getApprovalDelegatorIds(Id userId) {
		List<Id> delegatorIds = new List<Id>();
		List<User> delegators = [
			select
				Id,
				Name
			from User
			where DelegatedApproverId = :userId ];
		for(user delegator : delegators) {
			delegatorIds.add(delegator.Id);
		}
		return delegatorIds;
	}

	public static Approval.ProcessResult processWorkitemRequest(Id workItemId, String action, String comments) {
		Approval.ProcessWorkitemRequest approvalRequest = new Approval.ProcessWorkitemRequest();
		approvalRequest.setComments(comments);
		approvalRequest.setAction(action);
		approvalRequest.setWorkitemId(workItemId);
		Approval.ProcessResult result =  Approval.process(approvalRequest);
		return result;
	}
}