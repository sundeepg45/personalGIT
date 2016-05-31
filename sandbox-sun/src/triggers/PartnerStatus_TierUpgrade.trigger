trigger PartnerStatus_TierUpgrade on PartnerStatus__c (after insert, before update) {
/*

	//
	// do the fcpa checks
	//
    if (Trigger.isBefore && Trigger.isUpdate) {
        //
        // Screen out status changes we are not interested in, to avoid unneccesary SOQL
        //
        PartnerStatus__c[] pslist = new List<PartnerStatus__c>();
        Map<ID, PartnerStatus__c> acctStatusMap = new Map<ID, PartnerStatus__c>();
        for (PartnerStatus__c ps : Trigger.new) {
            PartnerStatus__c old = Trigger.oldMap.get(ps.Id);
            System.debug('*****[debug]***** prev_status=' + ps.Previous_Partner_Status__c + ', approvalstatus=' + ps.ApprovalStatus__c);
            if (ps.Previous_Partner_Status__c != null
                && ps.ApprovalStatus__c == 'Pending' && old.ApprovalStatus__c != 'Pending'
                && ps.PartnerTier__c != RedHatObjectReferences__c.getInstance('PARTNER_TIER.UNAFFILIATED').ObjectId__c) {

                pslist.add(ps);
                acctStatusMap.put(ps.Partner__c, ps);
                System.debug('*****[debug]***** adding status to list');
            }
        }

        if (!pslist.isEmpty()) {
            //
            // Get all previous statuses
            //
            Map<ID, PartnerStatus__c> prevStatusMap = new Map<ID, PartnerStatus__c>([
                select  Id, PartnerTier__c
                from    PartnerStatus__c
                where   Id in :PartnerUtil.getStringFieldSet(pslist, 'Previous_Partner_Status__c')
            ]);

            System.debug('*****[debug]***** previous status count is ' + prevStatusMap.size());

            //
            // Second screening - only continue on with those accounts with specific status upgrades
            //
            ID[] eligibleAccountIds = new List<ID>();
            for (PartnerStatus__c ps : pslist) {

                PartnerStatus__c prevStatus = prevStatusMap.get(ps.Previous_Partner_Status__c);
                if (prevStatus.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.UNAFFILIATED').ObjectId__c && ps.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.READY').ObjectId__c) {
                    eligibleAccountIds.add(ps.Partner__c);
                }
                if (prevStatus.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.READY').ObjectId__c && ps.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.ADVANCED').ObjectId__c) {
                    eligibleAccountIds.add(ps.Partner__c);
                }
            }

            System.debug('*****[debug]***** eligible account size is ' + eligibleAccountIds.size());
            if (eligibleAccountIds.isEmpty()) {
                return;
            }

            //
            // Check for any TI index matches on account locations or any affiliated countries
            //
            Account[] accounts = [
                select  Id, Additional_Countries_of_Operation__c, OwnerId,
                        BillingCountry, ShippingCountry, Direct_Purchasing_Agreement__c
//                      (select Country__c from Partner_Locations__r)
                from    Account
                where   Id in :eligibleAccountIds
            ];

            Anti_Corruption__c[] acinserts = new List<Anti_Corruption__c>();
            Account[] accountUpdates = new List<Account>();
            Map<ID,Anti_Corruption__c> acmap = new Map<ID,Anti_Corruption__c>();
            for (Anti_Corruption__c ac : [
            	select	Id, Partner_Account__c
            	from	Anti_Corruption__c
            	where	Partner_Account__c in :eligibleAccountIds
            	and		Review_Status__c = 'Approved and Archived'
            	and		RedFlagQuestionnaireComplete__c = True
            ]) {
            	acmap.put(ac.Partner_Account__c, ac);
            }

            for (Account acct : accounts) {
                Set<String> matchedCountries = PartnerUtil.filterTIIndexedAccount(acct);
                if (!matchedCountries.isEmpty() || acct.Direct_Purchasing_Agreement__c) {
                    System.debug('*****[debug]***** matched countries = ' + matchedCountries);
                    Anti_Corruption__c ac = new Anti_Corruption__c();
                    ac.Review_Status__c = 'New';
                    PartnerStatus__c ps = acctStatusMap.get(acct.Id);

                    if (acmap.containsKey(ps.Partner__c)) {
						ac.Red_Flag_Skip__c = true;
					}

					//ac.Review_Status__c = 'Legal Type 2 Review';
					//ac.Needs_Level_2_Review__c = true;
					ac.Level_1_Bypass__c = true;
					ac.Account_Owner__c = acct.OwnerId;

                    ac.Origin__c = 'Tier Upgrade';
                    ac.Partner_Account__c = ps.Partner__c;
                    ac.Direct_Purchasing_Agreement__c = acct.Direct_Purchasing_Agreement__c;
                    ac.TI_Indexed_Countries__c = PartnerUtil.joinArray(new List<String>(matchedCountries), ';');
                    ac.Partner_Status__c = ps.Id;
                    ps.Anti_Corruption_Exception__c = true;
                    acct.Anti_Corruption_Status__c = 'Review Required';
                    acinserts.add(ac);
                    accountUpdates.add(acct);
                }
                else {
                    System.debug('*****[debug]***** no matched countries');
                }
            }

            if (!accountUpdates.isEmpty()) {
                update accountUpdates;
            }
            if (!acinserts.isEmpty()) {
                insert acinserts;
		        return;	// important to leave this here to keep next section from firing on same transaction
            }
        }
        else {
            System.debug('*****[debug]***** partner status list is empty');
        }
    }

	//
	// After manager approval kick into legal review if needed
	//
    if (Trigger.isBefore && Trigger.isUpdate) {
        //
        // Screen out status changes we are not interested in, to avoid unneccesary SOQL
        //
        PartnerStatus__c[] pslist = new List<PartnerStatus__c>();
        Map<ID, PartnerStatus__c> acctStatusMap = new Map<ID, PartnerStatus__c>();
        for (PartnerStatus__c ps : Trigger.new) {
            PartnerStatus__c old = Trigger.oldMap.get(ps.Id);
            if (ps.ApprovalStatus__c == 'Pending'
                && ps.Anti_Corruption_Exception__c == true
                && old.Manager_Completed__c != ps.Manager_Completed__c
                && ps.Manager_Completed__c == true) {

                pslist.add(ps);
                acctStatusMap.put(ps.Partner__c, ps);
                System.debug('*****[debug]***** adding status to list');
            }
        }

        if (!pslist.isEmpty()) {
        	Anti_Corruption__c[] aclist = [select Id from Anti_Corruption__c where Partner_Status__c in :PartnerUtil.getIdSet(pslist)];
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
        for (PartnerStatus__c ps : Trigger.new) {
            if (ps.ApprovalStatus__c == 'Draft' && ps.PartnerTier__c != RedHatObjectReferences__c.getInstance('PARTNER_TIER.UNAFFILIATED').ObjectId__c) {
                // submit for normal approval first
                Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                approvalRequest.setComments('Submitting request for approval.');
                approvalRequest.setObjectId(ps.Id);
                Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
            }
        }
    }
*/
}