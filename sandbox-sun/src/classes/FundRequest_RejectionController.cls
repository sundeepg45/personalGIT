public class FundRequest_RejectionController {
    public final SFDC_MDF__c fundRequest; 
    
    public FundRequest_RejectionController(ApexPages.StandardController controller) {
        this.fundRequest = (SFDC_MDF__c)controller.getRecord();

    }

    public PageReference saveRejectionReason() {
        PageReference page = null;

        if (fundRequest.Id == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Fund Request ID is missing.'));
            return null;
        }

        try {
            String actorIdFR = UserInfo.getUserId();
            String profileId = UserInfo.getProfileId();
            String profileName = null;
            Profile profile = null;
            
            try {
                profile = [
                    select Name 
                      from Profile 
                     where Id = :profileId 
                       and Name like 'System Administrator'
                     limit 1
                ];
            } catch (Exception e) {} // profile not found.
            
            if (profile != null && profile.Name != null) {    
                update fundRequest;
                
                ProcessInstance processInstance = [
                    select CreatedDate
                         , Status
                         , TargetObjectId 
                      from ProcessInstance
                     where TargetObjectId = :fundRequest.Id 
                       and Status = 'Pending' 
                     limit 1
                ];
                                
                ProcessInstanceWorkItem processInstanceWorkItem = [
                    select ProcessInstanceId 
                      from ProcessInstanceWorkitem 
                     where ProcessInstanceId = :processInstance.Id
                     limit 1
                ];  
                                
                                
                page = new PageReference('/p/process/ProcessInstanceWorkitemWizardStageManager');
                page.getParameters().put('id', processInstanceWorkItem.Id); 
            } else {
                update fundRequest;
                            
                ProcessInstance processInstance = [
                    select CreatedDate
                         , Status
                         , TargetObjectId 
                      from ProcessInstance 
                     where TargetObjectId = :fundRequest.Id 
                       and Status = 'Pending' 
                     limit 1
                ];
                            
                ProcessInstanceWorkItem processInstanceWorkItem = [
                    select ProcessInstanceId 
                      from ProcessInstanceWorkItem 
                     where ProcessInstanceId = :processInstance.Id 
                       and ActorId = :actorIdFR
                ];  
                            
                page = new PageReference('/p/process/ProcessInstanceWorkitemWizardStageManager');
                page.getParameters().put('id', processInstanceWorkItem.Id);   
            }         
        } catch(Exception e) {
           ApexPages.addMessages(e);
        }

        return page;
    }
}