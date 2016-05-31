public with sharing class MDF_DownloadTCs {
    public MDF_DownloadTCs(ApexPages.StandardController controller) {
        this.controller = controller;
    }

    public ApexPages.StandardController controller {
        set;
        get;
    }

    public class Partner_Attachment_Wrapper {
        public Partner_Attachment__c partnerAttachment {
            get;
            set;
        }

        public Partner_Attachment_Wrapper(Partner_Attachment__c partnerAttachment) {
            this.partnerAttachment = partnerAttachment;
        }

        public String partnerAttachmentUrl {
            get {
                if (partnerAttachment == null)
                    return null;
                if (partnerAttachment.Attachments.size() == 0)
                    return null;
                return '/servlet/servlet.FileDownload?file=' + partnerAttachment.Attachments[0].Id;
            }
        }
        
    }

    public List<Partner_Attachment_Wrapper> partnerAttachmentList {
        set;
        get {
            if (partnerAttachmentList == null) {
                partnerAttachmentList = new List<Partner_Attachment_Wrapper>();
                
                SFDC_Budget__c budget = [
                    select Account_Master__r.Global_Region__c
                         , Account_Master__r.Subregion__c
                         , Fiscal_Year__c
                      from SFDC_Budget__c
                     where Id = :controller.getId()
                ];
                
                System.assert (budget != null, 'Budget is null');
                System.assert (budget.Account_Master__r != null, 'Budget.Account_Master__r is null');
                System.assert (budget.Account_Master__r.Global_Region__c != null, 'Budget.Account_Master__r.Global_Region__c is null');

                for (Partner_Attachment__c partnerAttachment : [
                    select Attachment_Type__c
                         , Fiscal_Year__c
                         , Global_Region__c
                         , Language__c
                         , Module__c
                         , Subregion__c
                         , (select Id from Attachments) 
                      from Partner_Attachment__c
                     where (Global_Region__c = :budget.Account_Master__r.Global_Region__c)
                       and (Subregion__c = null or Subregion__c = :budget.Account_Master__r.Subregion__c)
                       and (Attachment_Type__c = 'Terms And Conditions')
                       and (Module__c = null or Module__c = 'MDF') 
                       and (Fiscal_Year__c = null or Fiscal_Year__c = :budget.Fiscal_Year__c)
                       and (Display_Type__c = 'Download')
                  order by Global_Region__c desc, Subregion__c desc
                     limit 1 // only for TCs.
                ]) partnerAttachmentList.add (new Partner_Attachment_Wrapper (partnerAttachment));

                // special handling for fed sled
                if (budget.Account_Master__r.Subregion__c == 'Fed Sled') {
                    List<Partner_Attachment_Wrapper> temporaryList = new List<Partner_Attachment_Wrapper>();
                    
                    for (Integer i = 0; i < partnerAttachmentList.size(); i++)
                        if (partnerAttachmentList[i].partnerAttachment.Subregion__c != null)
                            temporaryList.add(partnerAttachmentList[i]);
                            
                    partnerAttachmentList = temporaryList;
                }
            }
            
            return partnerAttachmentList;
        }
    }

}