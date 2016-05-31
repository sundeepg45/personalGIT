trigger Onboarding_PartnerFCPAReviewKickoff on Partner_Onboarding_Registration__c (after insert, after update) {
    List<Partner_Onboarding_Registration__c> fcpaFailures = new List<Partner_Onboarding_Registration__c>();

    for (Partner_Onboarding_Registration__c l : Trigger.new){
        if ((Trigger.isInsert && l.Anti_Corruption_Status__c == 'Anti-Corruption Review Required') ||
            (l.Anti_Corruption_Status__c == 'Anti-Corruption Review Required' && Trigger.oldMap.get(l.Id).Anti_Corruption_Status__c != l.Anti_Corruption_Status__c)) {
            fcpaFailures.add(l);
        }
    }

    if (fcpaFailures.size() > 0){
        List<Anti_corruption__c> acl = new List<Anti_corruption__c>();
        for (Partner_Onboarding_Registration__c l : fcpaFailures){
            Anti_corruption__c ac = new Anti_corruption__c();

            ac.Origin__c = 'Onboarding';
            ac.Partner_Onboarding__c = l.Id;
            ac.Ever_Convicted__c = l.Have_they_been_convicted__c == 'Yes';
            ac.Government_Position__c = l.Do_they_act_in_any_government_position__c == 'Yes';
            ac.Underlying_Facts__c = l.FCPA_Underlying_Facts__c;
            ac.Internal_Review__c = l.AntiCorruption_Review_Channel_Ops__c;
            System.debug('Onb as Advanced or Premier? ' + l.Onb_As_Adv_Or_Prem__c);
            if ((ac.Ever_Convicted__c || ac.Government_Position__c || (ac.Internal_Review__c != null && ac.Internal_Review__c.startsWith('I know'))) && !l.Onb_As_Adv_Or_Prem__c) {
                ac.Review_Status__c = 'Legal Type 1 Review';
            }
            else {
                ac.Needs_Level_2_Review__c = true;
                ac.Review_Status__c = 'Channel Type 2 Review';
            }

            acl.add(ac);

        }
        insert acl;

//        if (Test.isRunningTest() == false) {
            for (Anti_corruption__c ac : acl){
                Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();
                approvalReq.setComments('Lead Submitted for Anti-Corruption Check.');
                approvalReq.setObjectId(ac.Id);
                System.debug('AC id: ' + ac.Id);
                // Submit the approval request
                Approval.ProcessResult result = Approval.process(approvalReq);
            }
//        }
    }
}