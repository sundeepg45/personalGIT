trigger PartnerRegistration_AutoApprove on Partner_Registration__c (after update) {

	Partner_Registration__c[] applicable = new List<Partner_Registration__c>();
	for (Partner_Registration__c reg : Trigger.new) {
		Partner_Registration__c old = Trigger.oldMap.get(reg.Id);
		if (reg.Status__c == 'Pending End Customer Owner Approval' && reg.Auto_Approved__c == true && old.Auto_Approved__c == false) {
			applicable.add(reg);
		}
	}
	
	for (Partner_Registration__c reg : applicable) {
		ProcessInstanceWorkItem[] wilist = [
			select	p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
			from	ProcessInstanceWorkitem p
			where	p.ProcessInstance.TargetObjectId = :reg.Id
			and		p.ProcessInstance.Status = 'Pending'
		];
		if (!wilist.isEmpty()) {
			ProcessInstanceWorkItem wi = wilist.get(0);
			Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
	        req.setAction('Approve');
			req.setComments('Auto-Approving request');
			req.setWorkitemId(wi.Id);
			Approval.ProcessResult result =  Approval.process(req);
			System.assert(result.isSuccess(), 'Unable to ' + req.getAction() + ' registration');
		}
		else {
			System.debug('***** [debug] No approval process found');
		}
	}
}