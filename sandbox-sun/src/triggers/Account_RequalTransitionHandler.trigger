trigger Account_RequalTransitionHandler on Account (before update, after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    static private Map<ID,ID> processedACAccounts = new Map<ID,ID>();

    if (Trigger.isAfter) {
        Partner_State_Wrapper.load(PartnerUtil.getIdSet(Trigger.new));
        Set<Id> overdueAccounts = new Set<Id>();
        for (integer i = 0; i < trigger.new.size(); i++){
            Account newA = trigger.new[i];
            Account oldA = trigger.old[i];
            // Requalification became overdue
            if (oldA.RequalStatus__c != newA.RequalStatus__c && newA.RequalStatus__c == 'Overdue'){
                if (Partner_State_Wrapper.isRequalLockoutExempt(newA.Id)) {
                    continue;
                }

                overdueAccounts.add(newA.Id);
            }
        }
        if (overdueAccounts.size() > 0) {
            RequalificationHelper.markOverdueAccounts(overdueAccounts);
        }
    }
    else {
        List<Id> prqIds = new List<Id>();
        for (Account acct : trigger.new) prqIds.add(acct.RequalificationLatestId__c);
        List<PartnerRequalification__c> requal = null;
        List<Partner_Requalification_Agreement__c> requalAgreements = null;
        List<PartnerAgreement__c> agreements = new List<PartnerAgreement__c>();
        PartnerRequalification__c[] prqUpdates = new List<PartnerRequalification__c>();

/*
        Map<ID,Anti_Corruption__c> acmap = new Map<ID,Anti_Corruption__c>();
        for (Anti_Corruption__c ac : [
            select  Id, Partner_Account__c
            from    Anti_Corruption__c
            where   Partner_Account__c in :PartnerUtil.getIdSet(Trigger.new)
            and     Review_Status__c = 'Approved and Archived'
            and     RedFlagQuestionnaireComplete__c = True
        ]) {
            acmap.put(ac.Partner_Account__c, ac);
        }
*/
        List<Id> allAccountIds = new List<Id>();
        for (Account account : trigger.new) {
            allAccountIds.add(account.Id);
        }

        // Get all the non-expired AC records. We may need to
        // expire some.
        List<Anti_corruption__c> acRecordsToExpire = [
            select 	Id,
                    Partner_Account__c,
                    Review_Status__c
            from 	Anti_corruption__c
            where 	Review_Status__c != 'Expired'
            and     Partner_Account__c in :allAccountIds
        ];

        List<Anti_corruption__c> acRecordsToUpdate = new List<Anti_corruption__c>();

        for (integer i = 0; i < trigger.new.size(); i++){
            Account newA = trigger.new[i];
            Account oldA = trigger.old[i];

			// requalification completed by manager, send to legal queue if needed
            if (oldA.RequalStatus__c != newA.RequalStatus__c && newA.RequalStatus__c == 'Manager Completed' && !processedACAccounts.containsKey(newA.Id)) {
    			System.debug('*****[debug]***** requalStatus is Manager Completed');

				PartnerRequalification__c requalRec = [
					select	Id, FCPAConvictedOfCrime__c, FCPAActInGovernmentPosition__c, FCPA_Underlying_Facts__c, Internal_Review__c
					from	PartnerRequalification__c
					where	Id = :newA.RequalificationLatestId__c
				];

                if (requalRec.Internal_Review__c == null) {
                    // newA.addError('Please indicate on the Requalification field named "Internal Review" whether you believe this record should be reviewed by legal for Anti Corruption screening.');
                    throw new TriggerValidationException('<script>top.location=\'/apex/TriggerValidationError?message=' + System.Label.Requal_Internal_Review_Message + '&recordmessage=' + System.Label.Requal_Internal_Review_Link_Message + '&record=' + requalRec.Id + '\';</script>');
                    continue;
                }
				Account account = newA;
                Set<String> matchedCountries = PartnerUtil.filterTIIndexedAccount(account);

                /*
                   Truth Table for Tier Change approvals

                   Legal | DPA  | TI INDEX | Approval
                   ------+------+----------+---------
                   TRUE	 | FALSE| TRUE     | Level 2
                   TRUE  | TRUE | TRUE     | Level 2
                   FALSE | TRUE | TRUE     | Level 2
                   FALSE | FALSE| TRUE     | Level 2
                   TRUE  | TRUE | TRUE     | Level 2
                   FALSE | TRUE | FALSE    | Level 2
                   FALSE | FALSE| FALSE    | Auto
                   TRUE  | FALSE| FALSE    | Level 1
                */

                Boolean autoException = false;
                Boolean legalException = false;
                Boolean dpaException = false;
                Boolean tiException = false;

                if (account.Direct_Purchasing_Agreement__c) {
                    dpaException = true;
                }
                if ((requalRec.Internal_Review__c != null && requalRec.Internal_Review__c.startsWith('I know')) ||
                    requalRec.FCPAActInGovernmentPosition__c == 'Yes' || requalRec.FCPAConvictedOfCrime__c == 'Yes') {
                    legalException = true;
                }
                if (account.Finder_Partner_Tier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.ADVANCED').ObjectId__c && matchedCountries.size() > 0) {
                    tiException = true;
                }
                if (account.Finder_Partner_Tier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.PREMIER').ObjectId__c && matchedCountries.size() > 0) {
                    tiException = true;
                }

                if (!legalException && !dpaException && !tiException) {
                    autoException = true;
                }

                List<Anti_Corruption__c> newlyExpiredACRecords = PartnerUtil.expireOldACRecords(account.Id, acRecordsToExpire);
                if (!newlyExpiredACRecords.isEmpty()) {
                    acRecordsToUpdate.addAll(newlyExpiredACRecords);
                }
				Anti_Corruption__c ac = new Anti_Corruption__c();
				ac.Origin__c = 'Requalification';
				ac.Partner_Account__c = account.Id;
                ac.Account_Owner__c = account.OwnerId;
                ac.Internal_Review__c = requalrec.Internal_Review__c;
                ac.Level_1_Bypass__c = account.AC_Level_1_Bypass__c;
                ac.Ever_Convicted__c = requalRec.FCPAConvictedOfCrime__c == 'Yes';
                ac.Government_Position__c = requalRec.FCPAActInGovernmentPosition__c == 'Yes';
                ac.Underlying_Facts__c = requalRec.FCPA_Underlying_Facts__c;
                ac.Direct_Purchasing_Agreement__c = account.Direct_Purchasing_Agreement__c;
                ac.TI_Indexed_Countries__c = PartnerUtil.joinArray(new List<String>(matchedCountries), ';');

                if (autoException) {
                    ac.Anti_Corruption_Confirmed_By__c = UserInfo.getUserId();
                    ac.Anti_Corruption_Confirmed_Date_Time__c = System.now();
                    ac.Review_Status__c = 'Approved and Archived';
                    ac.Auto_Approved__c = true;
                    System.debug('*****[debug]***** added placeholder AC record');
                    insert ac;
                    processedACAccounts.put(account.Id, account.Id);
                }
                else {
                    ac.Review_Status__c = 'New';
//                    if (acmap.containsKey(account.Id)) {
//                        ac.Red_Flag_Skip__c = true;
//                    }
                    if (legalException && !dpaException && !tiException) {
                        ac.Review_Status__c = 'Legal Type 1 Review';
                        ac.Level_1_Bypass__c = false;
                    }
                    else {
                        ac.Level_1_Bypass__c = true;
                        ac.Needs_Level_2_Review__c = true;
                        ac.Review_Status__c = 'Channel Type 2 Review';
                    }
                    account.Anti_Corruption_Status__c = 'Review Required';
                    insert ac;
                    processedACAccounts.put(account.Id, account.Id);
                    System.debug('*****[debug]***** submitting for legal approval');
			        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
			        approvalRequest.setComments('Submitting request for legal approval.');
			        approvalRequest.setObjectId(ac.Id);
			        Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
                }

            }

            // Requalification Is Complete
            if (oldA.RequalStatus__c != newA.RequalStatus__c && newA.RequalStatus__c == 'Completed') {

    			System.debug('*****[debug]***** requalStatus is Completed');
                newA.Requalification_Extended__c = false;

                if (requal == null) {
                    //
                    // First time used, do the query.  This is to reduce the number of soql queries that run out of context.
                    // We only need the requal records if we know this trigger is handling one or more requal events.
                    //
                    requal = [
                        select  AccountId__c,
                                Id,
                                FCPAActInGovernmentPosition__c,
                        		FCPA_Underlying_Facts__c,
                                FCPAConvictedOfCrime__c,
                                AgreementState__c
                          from  PartnerRequalification__c
                         where  Id in :prqIds
                     ];

                     requalAgreements = [
                        select  Agreement__c,
                                Partner_Requalification__c
                          from  Partner_Requalification_Agreement__c
                         where  Partner_Requalification__c in :prqIds
                     ];
                }

                for (PartnerRequalification__c prq : requal) {
                    if (prq.AccountId__c == newA.Id) {
                        prq.Status__c = 'Complete';
                        prqUpdates.add(prq);
                        newA.Have_They_been_Convicted__c = prq.FCPAConvictedOfCrime__c;
                        newA.Do_they_act_in_any_government_position__c = prq.FCPAActInGovernmentPosition__c;
                        newA.AntiCorruption_Review_By_RedHat_Internal__c = prq.Internal_Review__c;
                        if (prq.FCPAActInGovernmentPosition__c == 'Yes' || prq.FCPAConvictedOfCrime__c == 'Yes') {
                            newA.FCPA_Check__c = 'Failed';
                            newA.Underlying_Facts__c = prq.FCPA_Underlying_Facts__c;
                            newA.Date_FCPA_Check_Performed__c = System.now();
                        }
                        else {
                            newA.FCPA_Check__c = 'Passed';
                            newA.Date_FCPA_Check_Performed__c = System.now();
                        }

                        if (prq.AgreementState__c == 'Accepted') {
                            for (Partner_Requalification_Agreement__c pra : requalAgreements) {
                                if (pra.Partner_Requalification__c == prq.Id) {
                                    PartnerAgreement__c pa = new PartnerAgreement__c();
                                    pa.Agreement__c = pra.Agreement__c;
                                    pa.Partner__c = newA.Id;
                                    pa.ActivationDate__c = Date.today();
                                    pa.PartnerApprovalStatus__c = 'Approved';
                                    agreements.add(pa);
                                }
                            }
                        }

                        break;
                    }
                }

            }

            // Submitted
            if (oldA.RequalStatus__c != newA.RequalStatus__c && newA.RequalStatus__c == 'Submitted'){
                PartnerRequalification__c req = new PartnerRequalification__c(Id = newA.RequalificationLatestId__c);
                req.Status__c = 'Submitted';
                prqUpdates.add(req);
            }

            // Not Approved at this time
            if (oldA.RequalStatus__c != newA.RequalStatus__c && newA.RequalStatus__c == 'Not Approved at this time'){
                if (newA.RequalificationLatestId__c != null) {
                    try {
                        PartnerRequalification__c req = new PartnerRequalification__c(Id = newA.RequalificationLatestId__c);
                        req.Status__c = 'Not Approved at this time';
                        prqUpdates.add(req);
                    }
                    catch (System.Dmlexception ex) {
                        // safe to ignore, may not exist
                    }
                }
            }
        }

        if (agreements.size() > 0) {
            insert agreements;
        }
        if (prqUpdates.size() > 0) {
            update prqUpdates;
        }

        if (!acRecordsToUpdate.isEmpty()) {
            update acRecordsToUpdate;
        }

    }
}