public with sharing class Teaming_Agreement_ActionItems {

    public Id teamingAgreementId {get; set;}
    public Id actionItemId {get; set;}
    public Id actionId {get; set;}
    public List<Action_Items__c> teamingAgreementActions {get; set;}
    public Action_Items__c newteamingAgreementAction {get; set;}
    public Action_Items__c updateteamingAgreementAction {get; set;}
    public Boolean saved {get; set;}
 
    public ApexPages.StandardController controller {get;set;}

    public Teaming_Agreement_ActionItems(ApexPages.StandardController std)
    {
                controller = std;
                loadTeaminAgreementInformation();  
                saved = false;
    }
    
    public User currentUser {
		get {
			if(currentUser == null) {
				currentUser = [ select Profile.Name from User where Id = :UserInfo.getUserId() ];
			}
			return currentUser;
		}
		set;
	}
    
    public boolean showEditButton {
    	get {
    		String profile = currentUser.Profile.Name;
    		return (profile == 'Administrator - Level 1' || profile == 'Administrator - Level 2' || profile == 'Order Entry/Billing User' || profile == 'Administrator - Operations');
    	}
    }

    private void loadTeaminAgreementInformation() {
                teamingAgreementId = ApexPages.currentPage().getParameters().get('id');
                System.debug('teamingAgreementId In Constructor --------->:::'+ teamingAgreementId);
                if (teamingAgreementId != null) {
                        loadteamingAgreementActions(teamingAgreementId);
                } 
                if ( newteamingAgreementAction == null){
                        newteamingAgreementAction = new Action_Items__c() ; 
                }   
    }
     
     private void loadteamingAgreementActions(String teamingAgreementId) {
                teamingAgreementActions = [Select Action_Item__c, Name, Completed__c, Due_Date__c,  Red_Hat_Partner_Owner__c, Teaming_Agreement__c, Id  From Action_Items__c where Teaming_Agreement__c=:teamingAgreementId order by CreatedDate];
     
                if (teamingAgreementActions == null) {
                        teamingAgreementActions = new List<Action_Items__c>() ; 
                }
     } 
     
    public PageReference AddActionItem() {
                newteamingAgreementAction.Teaming_Agreement__c = teamingAgreementId;
                Savepoint sp = Database.setSavepoint(); 
            
                try {
                        insert newteamingAgreementAction;
                        
                        newteamingAgreementAction = new Action_Items__c() ; 
                        loadTeaminAgreementInformation();
                        
                } catch (DMLException e) {
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'The Teaming Agreement has been locked and you can not add/edit action items during this process');
                        ApexPages.addMessage(myMsg);
                } 

        loadTeaminAgreementInformation();  
                return Page.TeamingAgreementPageLayout;
    }
    
    public PageReference MarkComplete() {
                System.debug('teamingAgreementId In Constructor --------->:::'+ actionId);

                actionitemid =ApexPages.currentPage().getParameters().get('actionid');
                Action_Items__c actionitem  = [Select Action_Item__c, Name, Completed__c, Due_Date__c,  Red_Hat_Partner_Owner__c, Teaming_Agreement__c, Id  From Action_Items__c where Id=:actionItemId];
                actionitemid =ApexPages.currentPage().getParameters().get('actionitem');
                actionitem.completed__c = true;
                
                try {           
                        update actionitem ;
                        loadTeaminAgreementInformation();
                        return Page.TeamingAgreementPageLayout ;
            } catch (DMLException e){
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'The Teaming Agreement has been locked and you can not add/edit action items during this process');
                        ApexPages.addMessage(myMsg);
                } 
                
                return Page.TeamingAgreementPageLayout;
    }
    
    public PageReference DeleteActionItem() {
                System.debug('teamingAgreementId In Constructor --------->:::'+ actionId);

                actionitemid =ApexPages.currentPage().getParameters().get('actionid');
                Action_Items__c actionitem  = [Select Action_Item__c, Name, Completed__c, Due_Date__c,  Red_Hat_Partner_Owner__c, Teaming_Agreement__c, Id  From Action_Items__c where Id=:actionItemId];
                actionitemid =ApexPages.currentPage().getParameters().get('actionitem');
                
                
                try {           
                        delete actionitem ;
                        loadTeaminAgreementInformation();
                        return Page.TeamingAgreementPageLayout ;
            } catch (DMLException e){
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'The Teaming Agreement has been locked and you can not add/edit action items during this process');
                        ApexPages.addMessage(myMsg);
                } 
                
                return Page.TeamingAgreementPageLayout;
    }
    public PageReference EditActionItem() {
                System.debug('teamingAgreementId In Constructor --------->:::'+ actionId);

                actionitemid =ApexPages.currentPage().getParameters().get('actionid');
                Action_Items__c actionitem  = [Select Action_Item__c, Name, Completed__c, Due_Date__c,  Red_Hat_Partner_Owner__c, Teaming_Agreement__c, Id  From Action_Items__c where Id=:actionItemId];
                actionitemid =ApexPages.currentPage().getParameters().get('actionitem');
                
                
                try {           
                PageReference pageRef = new PageReference('/apex/TeamingAgreementEditActionitem?id='+actionitem.id);       
                                return pageRef;
            } catch (DMLException e){
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'The Teaming Agreement has been locked and you can not add/edit action items during this process');
                        ApexPages.addMessage(myMsg);
                } 
                
                return Page.TeamingAgreementPageLayout;
    }
    
    
     public PageReference submitforApproval() {
                
                // Submit for Approval
                Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                approvalRequest.setComments('Submitting request for approval.');
                approvalRequest.setObjectId(teamingAgreementId);

                // Ensure the approval was submitted properly
                Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
                system.assert(approvalResult.isSuccess(), approvalResult.getErrors());
                saved = true;
                return Page.TeamingAgreementPageLayout ;
                    
    }   
    
    
    

}