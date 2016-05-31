public with sharing class ContentFeedbackCaseCreation {
        
        public  Id contentVersionId {get; set;}
        public  Case newFeedbackCase {get; set;}
        public  Boolean saved {get; set;}
        private Id caseRecordType;
        public  ContentVersion contentVersionU {get; set;}
        public  User CurrentUser {get; set;}
        public String CaseDescription {get; set;}
        
        public ContentFeedbackCaseCreation() {
      
        loadContentInformation();  
        saved = false;
        
     
                }
        
        private void loadContentInformation() {
                contentVersionId = ApexPages.currentPage().getParameters().get('id');
             //   CaseDescription = ApexPages.currentPage().getParameters().get('CaseDescription');
                System.debug('contentVersionId In Constructor --------->:::'+ contentVersionId);
                contentVersionU = [Select id, ContentDocumentId, Description, Title from ContentVersion WHERE id=: contentVersionId];
                CurrentUser = [Select id, contactid, name from User where id=:UserInfo.getUserId()];
                caseRecordType = [select Id from RecordType where DeveloperName = 'Partner_General_Issues'].Id;
                
                
         }
        
        public PageReference CreateCase() {
                
                if (CaseDescription == ''){
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, System.Label.ContentFeedbackCaseCreationError));
                return null;    
                }
                else{
                
                
            Case newFeedbackCase = new Case();
                newFeedbackCase.RecordTypeId = caseRecordType;
                newFeedbackCase.Priority = 'Low';
                newFeedbackCase.Description = 'This is the Feedback: '+CaseDescription;
                newFeedbackCase.Issue_Type__c = 'Content Feedback';
                newFeedbackCase.Issue_Type_Classification__c = 'General Questions';
                newFeedbackCase.Requester__c = UserInfo.getUserId();
                newFeedbackCase.Subject = 'Feedback for content: '+  contentVersionU.Title ;
                newFeedbackCase.ContactId = CurrentUser.ContactId;  
                newFeedbackCase.EnterURLWhereProblemOccurs__c = Label.ContentFeedbackCaseCreationLink + contentVersionU.ContentDocumentId;
                Database.Dmloptions dmo = new Database.Dmloptions();
                dmo.emailHeader.triggerUserEmail = true;
                dmo.assignmentRuleHeader.useDefaultRule = true;
                newFeedbackCase.setOptions(dmo);        
            try{             
                  insert newFeedbackCase;
                  
                  newFeedbackCase = new Case() ; 

            } catch (DMLException e){
                  ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Fatal error, Please contact helpdesk');
                  ApexPages.addMessage(myMsg);
  
            } 
                  loadContentInformation();
                  PageReference pageRef = new PageReference( Label.ContentFeedbackCaseCreationLink +contentVersionU.ContentDocumentId);
                  PageRef.SetRedirect(true); 
                  return pageRef;
        }
        }
        
        public PageReference CancelF() {
                  PageReference pageRef1 = new PageReference(Label.ContentFeedbackCaseCreationLink +contentVersionU.ContentDocumentId);
                  PageRef1.SetRedirect(true); 
                  return pageRef1;
               
                
        }       
        
        
        
}