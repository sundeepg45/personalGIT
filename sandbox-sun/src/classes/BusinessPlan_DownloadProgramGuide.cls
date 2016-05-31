public with sharing class BusinessPlan_DownloadProgramGuide {
    public BusinessPlan_DownloadProgramGuide(ApexPages.StandardController controller) {
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
                
                SFDC_Channel_Account_Plan__c businessPlan = [
                    select Partner_Name__r.Global_Region__c
                         , Partner_Name__r.Subregion__c
                         , Fiscal_Year__c
                      from SFDC_Channel_Account_Plan__c
                     where Id = :controller.getId()
                ];
                
                System.assert (businessPlan != null, 'Business Plan is null');
                System.assert (businessPlan.Partner_Name__r != null, 'Business Plan.Partner_Name__r is null');
                System.assert (businessPlan.Partner_Name__r.Global_Region__c != null, 'Business Plan.Partner_Name__r.Global_Region__c is null');
                
                for (Partner_Attachment__c partnerAttachment : [
                    select Attachment_Type__c
                         , Fiscal_Year__c
                         , Global_Region__c
                         , Language__c
                         , Module__c
                         , Subregion__c
                         , (select Id from Attachments)
                      from Partner_Attachment__c
                     where (Global_Region__c = :businessPlan.Partner_Name__r.Global_Region__c)
                       and (Subregion__c = null or Subregion__c = :businessPlan.Partner_Name__r.Subregion__c)
                       and (Attachment_Type__c = 'Program Guide')
                       and (Module__c = null or Module__c = 'Business Plan') 
                       and (Fiscal_Year__c = null or Fiscal_Year__c = :businessPlan.Fiscal_Year__c)
                  order by Global_Region__c desc, Subregion__c desc
                ]) partnerAttachmentList.add (new Partner_Attachment_Wrapper (partnerAttachment));

                // special handling for fed sled
                if (businessPlan.Partner_Name__r.Subregion__c == 'Fed Sled') {
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