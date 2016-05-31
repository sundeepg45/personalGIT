trigger CCSP_Form_Trigger on CCSP_Form__c (before update) {

    LogSwarm log = new LogSwarm('CCSP', 'CCSP_Form_Trigger__c');

    CCSP_Form__c[] pendingList = new List<CCSP_Form__c>();
    CCSP_Form__c[] completedList = new List<CCSP_Form__c>();

    if (Trigger.isUpdate) {
        for (CCSP_Form__c form : Trigger.new) {
            CCSP_Form__c oldForm = Trigger.oldmap.get(form.Id);
            if (form.Status__c == oldForm.Status__c) {
                continue;
            }
            if (form.Status__c == 'Pending') {
                pendingList.add(form);
            }
            else if (form.Status__c == 'Complete') {
                completedList.add(form);
            }
            else {
                log.warn('Unknown CCSP_Form_Trigger__c.Status__c value: ' + form.Status__c);
            }
        }
    }

    //
    // Changed to pending - ready to notify user to fill out
    //
    if (!pendingList.isEmpty()) {
        Set<String> onbIdSet = PartnerUtil.getStringFieldSet(pendingList, 'CCSPOnboardingRegistration__c');
        Map<ID,Partner_Onboarding_Registration__c> regmap = new Map<ID,Partner_Onboarding_Registration__c>([
            select  Id, Created_By_User_Type__c, Onboarding_Language_Preference__c
            from    Partner_Onboarding_Registration__c
            where   Id in :onbIdSet
        ]);

        for (CCSP_Form__c form : pendingList) {
            Partner_Onboarding_Registration__c reg = regmap.get(form.CCSPOnboardingRegistration__c);
            if (reg != null) {
                if (reg.Created_By_User_Type__c == 'Distributor') {
                    PartnerEmailUtils.sendCCSPChecklistEmail(form.CCSPOnboardingRegistration__c, form.Contact_Email__c, 'Distributor',reg.Onboarding_Language_Preference__c);
                    form.Status__c = 'User Notified';
                }
                else
                if (reg.Created_By_User_Type__c == 'Internal') {
                    PartnerEmailUtils.sendCCSPChecklistEmail(form.CCSPOnboardingRegistration__c, form.Contact_Email__c, 'Internal',reg.Onboarding_Language_Preference__c);
                    form.Status__c = 'User Notified';
                }
                else
                if (reg.Created_By_User_Type__c == 'User') {
                    // US71671: Do not send this email to partner since the CCSP checklist is part of onboarding now.
                    //PartnerEmailUtils.sendCCSPChecklistEmail(form.CCSPOnboardingRegistration__c, form.Contact_Email__c, 'User',reg.Onboarding_Language_Preference__c);
                    PartnerEmailUtils.generateChecklistTokenURL(form.CCSPOnboardingRegistration__c, form.Contact_Email__c, 'CCSP_Checklist_Invitation_' + reg.Onboarding_Language_Preference__c.toUpperCase());
                    form.Status__c = 'User Notified';
                }
                else {
                    form.addError('Unable to complete - Unknown Created By User Type');
                }
            }
        }
    }

    //
    // Changed by checklist controller to complete - ready for approvals
    //
    if (!completedList.isEmpty()) {
        Id fullOnboardingRecordTypeId = [
            select  Id
            from    RecordType
            where   SObjectType = 'Partner_Onboarding_Registration__c'
            and     DeveloperName = 'Business_Partner_Registration'
        ].Id;

        for (CCSP_Form__c form : completedList) {
            if (!Test.isRunningTest()) {
                if (form.Account__c == null) { // Bypass this if the form is completed by an existing partner self-enrolling.
                    //
                    // Submit onboarding record into the approval process
                    //
                    Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                    approvalRequest.setComments('Submitting request for approval.');
                    approvalRequest.setObjectId(form.CCSPOnboardingRegistration__c);

                    // Ensure the approval was submitted properly
                    Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
                    System.Assert(approvalResult.isSuccess(), approvalResult.getErrors());
                }
            }
        }
    }
}