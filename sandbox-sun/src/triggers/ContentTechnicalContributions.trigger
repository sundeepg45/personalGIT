trigger ContentTechnicalContributions on Temporal_Content__c (after update) {
    
      public Attachment attachmentToUpload; 
    

      for (Temporal_Content__c temporalContentUpdate : Trigger.new) {
        
             Temporal_Content__c old = Trigger.oldMap.get(temporalContentUpdate.Id);
             if (temporalContentUpdate.Approval_Status__c == 'Approved' && old.Approval_Status__c != 'Approved') {
              
              try {
                //Get Attachment
                attachmentToUpload = [Select Name,Body,ParentId,Id from Attachment where ParentId =:temporalContentUpdate.id Limit 1];
                if (attachmentToUpload <> null) {
                    ContentWorkspace workspace = [select  Id, DefaultRecordTypeId, Name from ContentWorkspace where Name ='Partner Presales/Technical']; 
                    ContentVersion cv = new ContentVersion();
                    cv.VersionData = attachmentToUpload.Body;
                    cv.Title = temporalContentUpdate.Content_Title__c;
                    cv.Description = temporalContentUpdate.Content_Description__c;
                    cv.pathOnClient = attachmentToUpload.Name;
                    cv.RecordTypeId = workspace.DefaultRecordTypeId;
                    cv.FirstPublishLocationId = workspace.Id;
                    cv.Tech_Topics__c =temporalContentUpdate.Technical_Topics__c;
                    cv.Tech_Topics_in_Detail__c = temporalContentUpdate.Technical_Topics_Categories__c;
                    cv.Expiration_Date__c = temporalContentUpdate.Expiration_Date__c;  
                    cv.Document_Date__c = temporalContentUpdate.Document_Date__c;          
                    insert cv;
              }
                } catch (Exception e) {
               //    System.debug(e);
                     temporalContentUpdate.addError('Please enter an attachment before approving this record');
                }

                

            }    
        } 
    

}