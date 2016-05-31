public with sharing class MDF_DisplayTCs {
    public MDF_DisplayTCs() {}
    public MDF_DisplayTCs(ApexPages.StandardController controller) {
        budgetId = controller.getId();
    }

    public Id budgetId {
        set;
        get;
    } 

    public String getEncodedTCs() {
        try {
            SFDC_Budget__c budget = [
               select Account_Master__c
                    , Account_Master__r.Global_Region__c
                    , Account_Master__r.Subregion__c 
                 from SFDC_Budget__c 
                where Id = :budgetId
            ];
            
            List<Partner_Attachment__c> partnerAttachments = [
                select (select Id from Attachments)
                  from Partner_Attachment__c
                 where (Global_Region__c = :budget.Account_Master__r.Global_Region__c)
                   and (Subregion__c = null or Subregion__c = :budget.Account_Master__r.Subregion__c)
                   and (Display_Type__c = 'Web') 
                   and (Attachment_Type__c = 'Terms And Conditions')                   
              order by Subregion__c desc
            ];
            
            // Display an error message on the view side if this happens.
            if (partnerAttachments.size() == 0)
                return null;
            
            return EncodingUtil.base64Encode([
                select Body
                  from Attachment
                 where Id = :partnerAttachments[0].Attachments[0].Id
            ].Body);
        } catch (Exception e) {
            return e.getMessage();
        }       
    }
}