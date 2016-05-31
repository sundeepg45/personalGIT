trigger LMS_Training_Request_SubmitForApproval on LMS_Training_Request__c (after insert) {
//This trigger submit for approval the training request after Created
    for (LMS_Training_Request__c newLMSTrainingRequest: Trigger.new) {
            Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();                   
            approvalReq.setObjectId(newLMSTrainingRequest.Id);
            // Submit the approval request
           Approval.ProcessResult result = Approval.process(approvalReq);
        }
}