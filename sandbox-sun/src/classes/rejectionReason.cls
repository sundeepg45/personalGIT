public class rejectionReason {
    public rejectionReason(ApexPages.StandardController controller) {
        this.controller = controller;
    }
    
    // private vars
    private ApexPages.StandardController controller; 

    // page refs
    public PageReference saveLead() {
        try {
            // run the update
            update (Lead) controller.getRecord();
            
            // Fetch the profile name of the user making the request
            String profileName = [
                select Name
                  from Profile
                 where Id = :UserInfo.getProfileId()
            ].Name;
            
            // Is this an admin?
            Boolean isAdministrator = profileName == 'Administrator - Level 1'
                                   || profileName == 'Administrator - Level 2'
                                   || profileName == 'Administrator - Operations'
                                   || profileName == 'Apex Deployment'
                                   || profileName == 'API'
                                   || profileName == 'API - Read Only';
            
            // fetch the process
            Id processWorkItemId = null; 
            
            if (isAdministrator) {
                processWorkItemId = [
                    select Id
                      from ProcessInstanceWorkitem
                     where ProcessInstance.TargetObjectId = :controller.getId()
                     limit 1
                ].Id;
            } else {    
                processWorkItemId = [
                    select Id
                      from ProcessInstanceWorkitem
                     where ProcessInstance.TargetObjectId = :controller.getId()
                       and ActorId = :UserInfo.getUserId()
                     limit 1
                ].Id;
            }

            // return the page
            PageReference pageReference = new PageReference('/p/process/ProcessInstanceWorkitemWizardStageManager');
            pageReference.getParameters().put('id',processWorkItemId);
            pageReference.setRedirect(true);
            return pageReference;
        } catch (Exception pException) {
            ApexPages.addMessages(pException);
            return null;
        }
    }    

     public static testMethod void deployrejectionReason() 
     {
        Lead NALead= new Lead();
        NALead.status='Deal Registartion';
        NALead.LastName='TEST_LEADReason'; 
        NALead.LeadSourceDetail__c='Deal Registartion';
        NALead.email='abc@xyz.com';
        NALead.Company='Accenture';
        NALead.STATE='OH';  
        NALead.Country='US';  
        NALead.RecordTypeId='0126000000058QX';
        NALead.Red_Hat_Subscription_Revenue__c = 100.00;
        insert NALead;

         ApexPages.StandardController testController=new ApexPages.StandardController(NALead);

        PageReference pageRef = new PageReference('Page.Reason_rej');

        rejectionReason rejectionReasonObj=new rejectionReason(testController);
      }
}