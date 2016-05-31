/*
Name        : Opportunity_ResetReferenceName
Date Created: Feb 22, 2010
Created By  : Gaurav Gupte
Description : This Trigger will reset Opportunity Reference Name for cloned opportunities and Closed Lost backout.
*/


trigger Opportunity_ResetReferenceName on Opportunity (before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    // To reset Opportunity Reference Name field if Stage is changed from Closed Lost or when a new Opportunity is created.
    for(Integer i=0; i<Trigger.new.size(); i++)
    {     
         if(Trigger.isInsert)
         {
            Trigger.new[i].Opportunity_Reference_Name__c=null;
         }
         if(Trigger.isUpdate)
         {
             if(Trigger.old[i].StageName=='Closed Lost' && Trigger.new[i].StageName != 'Closed Lost')
             {
                  Trigger.new[i].Opportunity_Reference_Name__c=null;
             }
         }
    }
}