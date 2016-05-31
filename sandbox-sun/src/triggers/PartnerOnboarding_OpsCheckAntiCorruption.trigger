trigger PartnerOnboarding_OpsCheckAntiCorruption on Partner_Onboarding_Registration__c (before update) {

    //Map of CCSP forms for each onboarding registration
    Map<Id, CCSP_Form__c> formsByOnbMap = new Map<Id, CCSP_Form__c>();

    //make a map of the PARFs for each Onboarding registration
    Map<Id, PARF_Form__c> parfsByOnbMap = new Map<Id, PARF_Form__c>();

    Set<Id> approvedCCSPRegIds = new Set<Id>();
    Set<Id> approvedEmbedRegIds = new Set<Id>();

    Id antiCorruptionQueueGroupId = [
        select  Id,
                DeveloperName
        from    Group
        where   DeveloperName = 'AntiCorruption_Queue'
        limit   1
    ].Id;

    for (Partner_Onboarding_Registration__c l : Trigger.new)
    {
        // Get all of the process instance work items for the onboarding
        // record in question whose original actor is the anti-corruption
        // queue, which means that the approval process is at the
        // anti-corruption holding queue step.
        List<ProcessInstanceWorkItem> pIWIs = [
            select  p.Id,
                    p.OriginalActorId,
                    p.ProcessInstanceId,
                    p.ProcessInstance.TargetObjectId
            from    ProcessInstanceWorkItem p
            where   p.ProcessInstance.TargetObjectId = :l.Id
            and     p.OriginalActorId = :antiCorruptionQueueGroupId
        ];

        System.debug('Process instance work items: ' + pIWIs.size());
        if (pIWIs.size() > 0) {
            System.debug('Original Actor: ' + pIWIs[0].OriginalActorId);
        }
        System.debug('Onboarding registration Id: ' + l.Id);
        System.debug('Is approved by API? ' + OnboardingUtils.APPROVED_BY_API);

        // If we're at the anti-corruption holding queue step of
		// the approval process and we haven't come here through
		// code (APPROVED_BY_API is false), raise an error.
        if (pIWIs.size() > 0 && !OnboardingUtils.APPROVED_BY_API) {
            l.addError('This approval step must be completed through the anti-corruption record.');
        }

        //find the Onboarding registration first approval in-flight:
        if (l.Channel_Ops_Approved__c && !Trigger.oldMap.get(l.Id).Channel_Ops_Approved__c) {
            //build list of CCSP onboarding registrations:
            if(l.Partner_Type_Formula__c == PartnerConst.SCP || l.Subtype__c == PartnerConst.CCNSP) {
                approvedCCSPRegIds.add(l.id);
            }

            ////N/A for Embedded. Since, The Program approval validation doesn't in the first step:
            //build list of Embedded Onboarding registrations:
            //if(l.Subtype__c == PartnerConst.EMBEDDED) {
            //    approvedEmbedRegIds.add(l.Id);
            //}

            //Throw an error when AntiCorruption Review By RH Internal question is Unanswered:
            if ((l.AntiCorruption_Review_Channel_Ops__c == '' || l.AntiCorruption_Review_Channel_Ops__c == null) && !l.Manual_Onboard__c){
                l.addError('Please indicate on the field named "AntiCorruption Review by Red Hat" under the "AntiCorruption" section whether you believe this record should be reviewed by legal for Anti Corruption screening.');
            }
        }

        //capture the approvals by Regional Embedded team add them to a list:
        if(l.Subtype__c == PartnerConst.EMBEDDED &&
            l.Partner_Onboarding_Status__c == 'Program Team Reviewed' &&
            l.Partner_Onboarding_Status__c != trigger.oldMap.get(l.Id).Partner_Onboarding_Status__c) {
            approvedEmbedRegIds.add(l.Id);
        }
    }

    //build the Map with Onboarding registration ids and corresponding ccsp forms for CCSP Onboarding
    if (approvedCCSPRegIds.size() > 0) {
        for (CCSP_Form__c form : [SELECT Custom_Terms_Required__c, CCSPOnboardingRegistration__c
                                    FROM  CCSP_Form__c
                                    WHERE CCSPOnboardingRegistration__c in :approvedCCSPRegIds]) {
            formsByOnbMap.put(form.CCSPOnboardingRegistration__c, form);
        }
    }

    //build the map with Onboarding registrations and corresponding Embedded Forms for Embedded Onboarding
    if (approvedEmbedRegIds.size() > 0) {
        for (PARF_Form__c parf : [Select Custom_Terms_Required__c, Partner_Onboarding_Record__c
                                    From PARF_Form__c
                                    Where Partner_Onboarding_Record__c in :approvedEmbedRegIds]) {
            parfsByOnbMap.put(parf.Partner_Onboarding_Record__c, parf);
        }
    }

    //throw an error on each onboarding approval if the 'Custom Terms Required' field is empty on the corresponding ccsp/ parf
    for (Partner_Onboarding_Registration__c onb : Trigger.new) {
        if (formsByOnbMap.containsKey(onb.Id)) {
            CCSP_Form__c fm = formsByOnbMap.get(onb.id);
            if(fm != null) {
                if (fm.Custom_Terms_Required__c == '' || fm.Custom_Terms_Required__c == null) {
                    onb.addError('Please indicate on the field named "Custom Terms Required" on the CCSP Form whether you believe this partner should accept custom agreements/terms.');
                }
            }
        }
        if (parfsByOnbMap.containsKey(onb.Id)) {
            PARF_Form__c pf = parfsByOnbMap.get(onb.Id);
            if (pf.Custom_Terms_Required__c == '' || pf.Custom_Terms_Required__c == null) {
                onb.addError('Please indicate on the field named "Custom Terms Required" on the PARF Form whether you believe this partner should accept custom agreements/terms.');
            }
        }
    }

}