public with sharing class ContentTechnicalContributions {
              
        public Boolean saved {get; set;}
        public User CurrentUser {get; set;}
        public String CaseDescription {get; set;}
        public String ContentTitle {get; set;}
        public String ContentDescription {get; set;}
        public transient Blob   attachmentFile {get;set;}
        public transient String attachmentFilename {get;set;}
        public Temporal_Content__c newtemporalcontent; 

        public ContentTechnicalContributions(ApexPages.StandardController controller) {
                CurrentUser = [Select id, contactid, name from User where id=:UserInfo.getUserId()]; 
                saved = false;
                newtemporalcontent = (Temporal_Content__c)controller.getRecord();
        }
     
        public PageReference addContent() {
                        if (attachmentFile == null) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.PartnerLogo_please_select_a_file_to_upload));
                        return null;
                }
                else {
                        Attachment contentfile = new Attachment(Name = attachmentFilename, Body = attachmentFile); 
                        newtemporalcontent.Approval_Status__c = 'Draft';
                        newtemporalcontent.Library_Associated__c = 'Partner Presales/Technical';
                        insert newtemporalcontent;
                        contentfile.parentid = newtemporalcontent.id;
                        insert contentfile;
                // Submit for Approval
                    Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                    approvalRequest.setComments('Submitting request for approval.');
                    approvalRequest.setObjectId(newtemporalcontent.id);
                 // Ensure the approval was submitted properly
                    Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
                    system.assert(approvalResult.isSuccess(), approvalResult.getErrors());
                    saved = true;
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Thanks for the Technical Contributions, your content it will be entering into an approval process you will get notified once get upload in the Technical Library'));
                    return Page.ContentTechnicalContributions;
                } 
         }  
                
     //    public PageReference CancelF() {
     //                           Temporal_Content__c newtemporalcontent  = new Temporal_Content__c(); 
     //                           return null;
     //    }
 
}