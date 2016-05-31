trigger OpportunityPartner_Update on Opportunity (before insert, before update)
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    new OpportunityPartnerUpdate().updateOpportunityPartnerWorked(Trigger.new);
}