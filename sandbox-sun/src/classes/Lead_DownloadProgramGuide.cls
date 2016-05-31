public with sharing class Lead_DownloadProgramGuide {
    public Lead_DownloadProgramGuide(ApexPages.StandardController controller) {
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
                
                Lead lead = [
                    select LanguagePreference__c
                         , RecordType.Name
                      from Lead
                     where Id = :controller.getId()
                ];
                
                //
                // This code naively assumes that (a) the entry point will always come from a
                // '* Deal Registration' record type, and that there are only five options for
                // this record type name.
                //
                // - APAC Deal Registration
                // - EMEA Deal Registration
                // - LATAM Deal Registration
                // - NA Deal Registration
                // - NA Fed/Sled Deal Registration
                
                String globalRegion = null;
                String subregion = null;
                
                if (lead.RecordType.Name == 'APAC Deal Registration')
                    globalRegion = 'APAC';
                if (lead.RecordType.Name == 'EMEA Deal Registration')
                    globalRegion = 'EMEA';
                if (lead.RecordType.Name == 'LATAM Deal Registration')
                    globalRegion = 'LATAM';
                if (lead.RecordType.Name == 'NA Deal Registration')
                    globalRegion = 'NA';
                    
                // Special handling for fed sled
                if (lead.RecordType.Name == 'NA Fed/Sled Deal Registration') {
                    globalRegion = 'NA';
                    subregion = 'Fed Sled'; // typo in the Partner Attachments list of subregions ??
                }
                
                //
                // Find the partner attachments
                //
                
                for (Partner_Attachment__c partnerAttachment : [
                    select Attachment_Type__c
                         , Fiscal_Year__c
                         , Global_Region__c
                         , Language__c
                         , Module__c
                         , Subregion__c
                         , (select Id from Attachments)
                      from Partner_Attachment__c
                     where (Global_Region__c = :globalRegion)
                       and (Subregion__c = null or Subregion__c = :subregion)
                       and (Attachment_Type__c = 'Program Guide')
                       and (Module__c = null or Module__c = 'Deal Registration') 
                       and (Language__c = 'English' or Language__c = :lead.LanguagePreference__c) 
                  order by Global_Region__c desc, Subregion__c desc
                ]) partnerAttachmentList.add (new Partner_Attachment_Wrapper (partnerAttachment));
            }
            
            return partnerAttachmentList;
        }
    }
}