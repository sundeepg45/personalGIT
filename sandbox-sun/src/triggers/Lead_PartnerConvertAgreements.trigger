trigger Lead_PartnerConvertAgreements on Lead (after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    Set<Id> leadConvertedIds = new Set<Id>();
    
    for(Lead lead : Trigger.new) {
        if (lead.Partner_Onboarding_Status__c != 'Approved')
            continue; // wrong entry criteria
        if (lead.IsConverted != true)
            continue; // wrong entry criteria
        if (Trigger.oldMap.get(lead.Id).IsConverted == true)
            continue; // no change to conversion status

        leadConvertedIds.add(lead.Id);
    }

    if (leadConvertedIds.size() == 0)
        return;

// Onboarding already does this - mls
//    OnboardingExecuteConversion.convertPartnerAgreements(leadConvertedIds);
}