trigger GPSGLSNotificationOnClonedOpportunity on Opportunity (after insert)
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    if(Util.adminByPass()) return;
    if(Trigger.isInsert)
    {
        new CloneGPSGLS().cloneOpportunity(Trigger.new);
    }
}