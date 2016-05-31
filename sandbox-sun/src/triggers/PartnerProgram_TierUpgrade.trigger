trigger PartnerProgram_TierUpgrade on Partner_Program_Approval__c (after insert, before update, after update) {
    static private Map<ID,ID> processedACApprovals = new Map<ID,ID>();


    if (Trigger.isBefore && Trigger.isUpdate) {

        Id partnerCenterAPIUserId = [
            select  Id,
                    Name
            from    User
            where   Name
            in      ('Partner Center API User', 'API User Partner Center')
            limit   1
        ].Id;
        //
        // Handle approved Tier Change requests
        //
        Partner_Program_Approval__c[] pslist = new List<Partner_Program_Approval__c>();
        Map<Id, Id> programApprovalRequestAccountMap = new Map<Id, Id>();
        for (Partner_Program_Approval__c ps : Trigger.new) {
            programApprovalRequestAccountMap.put(ps.Id, ps.Partner__c);
            Partner_Program_Approval__c old = Trigger.oldMap.get(ps.Id);
            System.debug('Status / old status: ' + ps.Status__c + '/' + old.Status__c);
            if (ps.Approval_Request_Type__c == 'Tier Upgrade') {
                // Get all of the process instance work items for the partner
                // program approval in question whose original actor is the
                // partner center api user, which means that the approval
                // process is at the anti-corruption holding queue step.
                List<ProcessInstanceWorkItem> pIWIs = [
                    select  p.Id,
                            p.OriginalActorId,
                            p.ProcessInstanceId,
                            p.ProcessInstance.TargetObjectId
                    from    ProcessInstanceWorkItem p
                    where   p.ProcessInstance.TargetObjectId = :ps.Id
                    and     p.OriginalActorId = :partnerCenterAPIUserId
                ];
                // If we're at the anti-corruption holding queue step of
                // the approval process and we haven't come here through
                // code (APPROVED_BY_API is false), raise an error.
                if (!pIWIs.isEmpty() && !PartnerTierControllerExt.APPROVED_BY_API) {
                    ps.addError('This approval step must be completed through the anti-corruption form.');
                }
            }

            Boolean downgrade = false;
            if (ps.From_Tier__c == 'Premier' && (ps.Tier__c == 'Advanced' || ps.Tier__c == 'Ready')) {
                downgrade = true;
            }
            if (ps.From_Tier__c == 'Advanced' && ps.Tier__c == 'Ready') {
                downgrade = true;
            }
            if (ps.Status__c == 'Pending' &&
                old.Manager_Completed__c != ps.Manager_Completed__c && ps.Manager_Completed__c == true) {

                if (!downgrade && ps.Internal_Review__c == null && ps.Tier__c != 'Unaffiliated') {
                    ps.addError('Please indicate on the field named "Internal Review" whether you believe this record should be reviewed by legal for Anti Corruption screening.');
                    continue;
                }
            }

            if (ps.Approval_Request_Type__c == 'Tier Upgrade' && ps.Status__c == 'Approved' && old.Status__c != 'Approved') {
                pslist.add(ps);
            }
        }

        if (!pslist.isEmpty()) {
            Map<ID, Partner_Program__c> programMap = new Map<ID,Partner_Program__c>([
                select  Id, Tier__c
                from    Partner_Program__c
                where   Id in :PartnerUtil.getStringFieldSet(pslist, 'Program__c')
            ]);
            Account[] accountUpdates = new List<Account>();
            for (Partner_Program_Approval__c ps : Trigger.new) {
                Partner_Program__c pgm = programMap.get(ps.Program__c);
                if (pgm != null) {
                    pgm.Tier__c = ps.Tier__c;

                    Account acct = new Account(Id = ps.Partner__c);
                    acct.AntiCorruption_Review_By_RedHat_Internal__c = ps.Internal_Review__c;
                    acct.Do_they_act_in_any_government_position__c = ps.Government_Position__c;
                    acct.Have_They_been_Convicted__c = ps.Convicted__c;
                    acct.Date_FCPA_Check_Performed__c = System.now();
                    acct.FCPA_Check__c = 'Passed';
                    if (ps.Government_Position__c == 'Yes' || ps.Convicted__c == 'Yes') {
                        acct.FCPA_Check__c = 'Failed';
                        acct.Underlying_Facts__c = ps.FCPA_Underlying_Facts__c;
                    }
                    accountUpdates.add(acct);
                }
            }

            List<PartnerAgreement__c> partnerAgreementList = [
                select  Id,
                        Partner_Program_Approval_Request__c
                from    PartnerAgreement__c
                where   Partner_Program_Approval_Request__c
                in      :programApprovalRequestAccountMap.keyset()
            ];

            if (partnerAgreementList != null && partnerAgreementList.size() > 0) {
                System.debug('*****[debug]***** agreements=' + partnerAgreementList.size());
                for(PartnerAgreement__c partnerAgreement : partnerAgreementList) {
                    partnerAgreement.Partner__c = programApprovalRequestAccountMap.get(partnerAgreement.Partner_Program_Approval_Request__c);
                    if (partnerAgreement.Partner__c == null) {
                        System.debug('*****[debug]***** Account not found for approval request ' + partnerAgreement.Partner_Program_Approval_Request__c);
                    }
                }

                update partnerAgreementList;
            }

            PartnerProgram_TierUpgrade.isTierUpgradeApproved = true;
            update programMap.values();
            if (!accountUpdates.isEmpty()) {
                update accountUpdates;
            }
            return; // if you remove this, you will get duplicate A/C records
        }
        else {
            System.debug('***** [debug] ***** pslist is empty');
        }

    }
    //
    // do the fcpa checks
    //
    if (Trigger.isBefore && Trigger.isUpdate) {
        //
        // Screen out changes we are not interested in, to avoid unneccesary SOQL
        //
        Partner_Program_Approval__c[] pslist = new List<Partner_Program_Approval__c>();
        for (Partner_Program_Approval__c ps : Trigger.new) {
            Partner_Program_Approval__c old = Trigger.oldMap.get(ps.Id);
            System.debug('*****[debug]***** approval_request_type__c = ' + ps.Approval_Request_Type__c);
            System.debug('*****[debug]***** ps.status__c = ' + ps.Status__c);

            if (!FCPA_Questionnaire.isUserUpdating && ps.Anti_Corruption_Exception__c && ps.Internal_Review__c == null && ps.Tier__c != PartnerConst.UNAFFILIATED) {
//                ps.addError('Please indicate on the field named "Internal Review" whether you believe this record should be reviewed by legal for Anti Corruption screening.');
            }
            if (ps.Approval_Request_Type__c == 'Tier Upgrade' && old.Manager_Completed__c != ps.Manager_Completed__c && ps.Manager_Completed__c == true &&
                !processedACApprovals.containsKey(ps.Id)) {
//            if (ps.Approval_Request_Type__c == 'Tier Upgrade' && ps.Status__c == 'Pending' && old.Status__c != 'Pending') {
                pslist.add(ps);
            }
        }

        if (!pslist.isEmpty()) {
            Map<ID, Partner_Program__c> programMap = new Map<ID, Partner_Program__c>([
                select      Id, Tier__c
                from        Partner_Program__c
                where       Id in :PartnerUtil.getStringFieldSet(pslist, 'Program__c')
            ]);
            System.debug('*****[debug]***** programMap size=' + programMap.size());

            //
            // Check for any TI index matches on account locations or any affiliated countries
            //
            Map<ID, Account> accountMap = new Map<ID, Account>([
                select  Id, Additional_Countries_of_Operation__c, OwnerId,
                        BillingCountry, ShippingCountry, Direct_Purchasing_Agreement__c
    //                      (select Country__c from Partner_Locations__r)
                from    Account
                where   Id in :PartnerUtil.getStringFieldSet(pslist, 'Account__c')
            ]);

            Account[] accountUpdates = new List<Account>();
/*
            Map<ID,Anti_Corruption__c> acmap = new Map<ID,Anti_Corruption__c>();
            for (Anti_Corruption__c ac : [
                select  Id, Partner_Account__c
                from    Anti_Corruption__c
                where   Partner_Account__c in :PartnerUtil.getStringFieldSet(pslist, 'Account__c')
                and     Review_Status__c = 'Approved and Archived'
                and     RedFlagQuestionnaireComplete__c = True
            ]) {
                acmap.put(ac.Partner_Account__c, ac);
            }
*/

            List<Id> allAccountIds = new List<Id>();
            for (Partner_Program_Approval__c ps : pslist) {
                allAccountIds.add(ps.Account__c);
            }

            List<Anti_corruption__c> acRecordsToUpdate = new List<Anti_corruption__c>();

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

            Anti_Corruption__c[] acinserts = new List<Anti_Corruption__c>();
            //
            // Second screening - only continue on with those accounts with specific status upgrades
            //
            for (Partner_Program_Approval__c ps : pslist) {
                if (ps.Tier__c == PartnerConst.UNAFFILIATED) {
                    continue;
                }
                Account acct = accountMap.get(ps.Account__c);
                Set<String> matchedCountries = PartnerUtil.filterTIIndexedAccount(acct);
                System.debug('*****[debug]***** matched countries = ' + matchedCountries);

                Partner_Program__c program = programMap.get(ps.Program__c);
                System.debug('*****]debug]***** ps.tier=' + ps.Tier__c);
                System.debug('*****[debug]***** program.tier=' + program.Tier__c);

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

                if (acct.Direct_Purchasing_Agreement__c) {
                    dpaException = true;
                }
                if ((ps.Internal_Review__c != null && ps.Internal_Review__c.startsWith('I know')) ||
                    ps.Government_Position__c == 'Yes' || ps.Convicted__c == 'Yes') {
                    legalException = true;
                }
                if ((ps.Tier__c == PartnerConst.ADVANCED || ps.Tier__c == PartnerConst.PREMIER) && matchedCountries.size() > 0) {
                    tiException = true;
                }
//                else {
//                    autoException = true;
//                }

                if (!legalException && !dpaException && !tiException) {
                    autoException = true;
                }

                List<Anti_Corruption__c> newlyExpiredACRecords = PartnerUtil.expireOldACRecords(ps.Account__c, acRecordsToExpire);
                if (!newlyExpiredACRecords.isEmpty()) {
                    acRecordsToUpdate.addAll(newlyExpiredACRecords);
                }
                Anti_Corruption__c ac = new Anti_Corruption__c();
                ac.Partner_Account__c = ps.Account__c;
                ac.Direct_Purchasing_Agreement__c = acct.Direct_Purchasing_Agreement__c;
                ac.TI_Indexed_Countries__c = PartnerUtil.joinArray(new List<String>(matchedCountries), ';');
                ac.Internal_Review__c = ps.Internal_Review__c;
                ac.Government_Position__c = ps.Government_Position__c == 'Yes';
                ac.Partner_Program_Approval__c = ps.Id;
                ac.Account_Owner__c = acct.OwnerId;
                ac.Ever_Convicted__c = ps.Convicted__c == 'Yes';
                ac.Underlying_Facts__c = ps.FCPA_Underlying_Facts__c;
                ac.Origin__c = 'Tier Upgrade';

                if (autoException) {
                    ac.Anti_Corruption_Confirmed_By__c = UserInfo.getUserId();
                    ac.Anti_Corruption_Confirmed_Date_Time__c = System.now();
                    ac.Review_Status__c = 'Approved and Archived';
                    ac.Auto_Approved__c = true;
                    ac.Needs_Level_2_Review__c = false;
                    System.debug('*****[debug]***** added placeholder AC record');
                }
                else {
                    ac.Review_Status__c = 'New';
//                    if (acmap.containsKey(ps.Account__c)) {
//                        ac.Red_Flag_Skip__c = true;
//                    }
                    ps.Anti_Corruption_Exception__c = true;
                    if (legalException && !dpaException && !tiException) {
                        ac.Review_Status__c = 'Legal Type 1 Review';
                    }
                    else {
                        ac.Level_1_Bypass__c = true;
                        ac.Review_Status__c = 'Channel Type 2 Review';
    //                    ac.Needs_Level_2_Review__c = True;
                    }
                    acct.Anti_Corruption_Status__c = 'Review Required';
                    accountUpdates.add(acct);
                }
                acinserts.add(ac);
                processedACApprovals.put(ps.Id, ps.Id);
            }

            if (!accountUpdates.isEmpty()) {
                update accountUpdates;
            }
            if (!acinserts.isEmpty()) {
                insert acinserts;
                System.debug(acinserts.size() + ' Anticorruption records inserted.');
            }
            if (!acRecordsToUpdate.isEmpty()) {
                update acRecordsToUpdate;
            }
        }   // !pslist.isEmpty()
    }

    //
    // After manager approval kick into legal review if needed
    //
    if (Trigger.isAfter && Trigger.isUpdate) {
        //
        // Screen out status changes we are not interested in, to avoid unneccesary SOQL
        //
        Partner_Program_Approval__c[] pslist = new List<Partner_Program_Approval__c>();
        for (Partner_Program_Approval__c ps : Trigger.new) {
            System.debug('***** ps.status=' + ps.Status__c);
            System.debug('***** ps.Anti_Corruption_Exception__c=' + ps.Anti_Corruption_Exception__c);
            System.debug('***** ps.Manager_Completed__c=' + ps.Manager_Completed__c);
            Partner_Program_Approval__c old = Trigger.oldMap.get(ps.Id);
            if (ps.Status__c == 'Pending' &&
                ps.Anti_Corruption_Exception__c == true &&
                old.Manager_Completed__c != ps.Manager_Completed__c &&
                ps.Manager_Completed__c == true) {

                pslist.add(ps);
                System.debug('*****[debug]***** adding program to list');
            }
        }

        if (!pslist.isEmpty()) {
            Anti_Corruption__c[] aclist = [select Id, Partner_Program_Approval__c from Anti_Corruption__c where Partner_Program_Approval__c in :PartnerUtil.getIdSet(pslist)];
            for (Anti_Corruption__c ac : aclist) {
                Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                approvalRequest.setComments('Submitting request for legal approval.');
                approvalRequest.setObjectId(ac.Id);
                Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
            }
        }
        else {
            System.debug('*****[debug]***** partner status list is empty');
        }
    }

    //
    // insert, kick off manager approval
    //
    if (Trigger.isAfter && Trigger.isInsert) {
        for (Partner_Program_Approval__c ps : Trigger.new) {
            if (ps.Status__c == 'Draft' && ps.Tier__c != PartnerConst.UNAFFILIATED) {
                // submit for normal approval first
                Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                approvalRequest.setComments('Submitting request for approval.');
                approvalRequest.setObjectId(ps.Id);
                if (!Test.isRunningTest()) {
                    Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
                }
            }
        }
/*
        // now that we have the status ID we need to update the anti corruption record since the id isn't available until after insert

        Anti_Corruption__c[] aclist = [
            select  Id, Partner_Account__c
            from    Anti_Corruption__c
            where   Origin__c = 'Tier Upgrade'
            and     Partner_Status__c = null
            and     Partner_Account__c in :PartnerUtil.getStringFieldSet(Trigger.new, 'Partner__c')
        ];
        Anti_Corruption__c[] acupdates = new List<Anti_Corruption__c>();
        PartnerStatus__c[] pslist = new List<PartnerStatus__c>();
        for (Anti_Corruption__c ac : aclist) {
            for (PartnerStatus__c ps : Trigger.new) {
                if (ps.Partner__c == ac.Partner_Account__c) {
                    ac.Partner_Status__c = ps.Id;
                    acupdates.add(ac);
                    break;
                }
            }
        }
        if (!acupdates.isEmpty()) {
            update acupdates;
        }
    */
    }
}