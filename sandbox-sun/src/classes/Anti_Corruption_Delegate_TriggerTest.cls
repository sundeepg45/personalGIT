@isTest(SeeAllData=true)
private class Anti_Corruption_Delegate_TriggerTest {


    static testMethod void testLeadApproval() {

		DeactivateAllTestUtil.setDeactivateAll(false);

		RecordType recordType = [Select r.Name, r.Id From RecordType r where r.Name='Partner Onboarding'];
		Lead testLead = PartnerTestUtils.makeLead('Mal', 'Reynolds', 'Serenity', PartnerTestUtils.getAdminUser());
		testLead.RecordTypeId = recordType.Id;
		testLead.Have_they_been_convicted__c = 'Yes';
		testLead.Partner_Type__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.ISV'].Id;
		testLead.Partner_Tier__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.READY'].Id;
		testLead.Is_Primary_Public_Sector__c = 'No';
        testLead.AntiCorruption_Review_Channel_Ops__c = 'I do not know of anything with this potential partner that should require additional checks';
		insert testLead;

        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setComments('Submitting request for approval.');
        approvalRequest.setObjectId(testLead.Id);

        // Ensure the approval was submitted properly
        Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
        system.assert(approvalResult.isSuccess(), approvalResult.getErrors());

		testLead = [select Id, Partner_Onboarding_Status__c from Lead where Id = :testLead.Id];
		System.assert(testLead.Partner_Onboarding_Status__c == 'Pending', 'Expected Pending status, found ' + testLead.Partner_Onboarding_Status__c);

		ID workItemId = approvalResult.getNewWorkitemIds().get(0);

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
		req.setComments('Approving request');
        req.setAction('Approve');
		req.setWorkitemId(workItemId);
		Approval.ProcessResult result =  Approval.process(req);
		System.assert(result.isSuccess(), 'Unable to auto-approve Lead');

		Anti_Corruption__c[] aclist = [
			select	Id
			from	Anti_Corruption__c
			where	Lead__c = :testLead.Id
			and		Review_Status__c != 'Approved'
		];
		System.assert(!aclist.isEmpty(), 'Anti_Corruption record not found for lead');

		Anti_Corruption__c ac = aclist.get(0);
		// kick off the trigger
		ac.Review_Status__c = 'Approved';
		update ac;

    }

    static testMethod void testOnboardingApproval() {

		DeactivateAllTestUtil.setDeactivateAll(false);

		Partner_Onboarding_Registration__c testLead = PartnerTestUtils.makeOnboarding('Mal', 'Reynolds', 'Serenity', PartnerTestUtils.getAdminUser());
		testLead.Have_they_been_convicted__c = 'Yes';
		testLead.Partner_Type__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.ISV'].Id;
		testLead.Partner_Tier__c = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.READY'].Id;
		testLead.Is_Primary_Public_Sector__c = 'No';
        testLead.AntiCorruption_Review_Channel_Ops__c = 'I do not know of anything with this potential partner that should require additional checks';
		insert testLead;

/*
        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setComments('Submitting request for approval.');
        approvalRequest.setObjectId(testLead.Id);

        // Ensure the approval was submitted properly
        Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
        system.assert(approvalResult.isSuccess(), approvalResult.getErrors());

		testLead = [select Id, Partner_Onboarding_Status__c from Partner_Onboarding_Registration__c where Id = :testLead.Id];
		System.assert(testLead.Partner_Onboarding_Status__c == 'Pending', 'Expected Pending status, found ' + testLead.Partner_Onboarding_Status__c);

		ID workItemId = approvalResult.getNewWorkitemIds().get(0);

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
		req.setComments('Approving request');
        req.setAction('Approve');
		req.setWorkitemId(workItemId);
		Approval.ProcessResult result =  Approval.process(req);
		System.assert(result.isSuccess(), 'Unable to auto-approve Lead');

		Anti_Corruption__c[] aclist = [
			select	Id
			from	Anti_Corruption__c
			where	Lead__c = :testLead.Id
			and		Review_Status__c != 'Approved'
		];
		System.assert(!aclist.isEmpty(), 'Anti_Corruption record not found for lead');

		Anti_Corruption__c ac = aclist.get(0);
		// kick off the trigger
		ac.Review_Status__c = 'Approved';
		update ac;
*/
    }

    static testMethod void testTierUpgradeApproval() {

		DeactivateAllTestUtil.setDeactivateAll(false);

		RecordType recordType = [Select r.Name, r.Id From RecordType r where r.Name='Partner Onboarding'];
		Account acct = PartnerTestUtils.makeAccount('testTierUpgradeApproval', PartnerTestUtils.getAdminUser());
		acct.Additional_Countries_of_Operation__c = 'Afghanistan';
		update acct;

		//
		// flag our test country as TI Indexed
		//
		Country__c ctmp = [select Id from Country__c where Name = 'Afghanistan'];
		ctmp.TI_Index__c = true;
		update ctmp;

        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
		Partner_Program__C pgm = PartnerTestUtils.makeAccountResellerProgram(acct.Id);
		Test.startTest();
		Partner_Program_Approval__c ps = new Partner_Program_Approval__c();
		ps.Program__c = pgm.Id;
		ps.Tier__c = PartnerConst.ADVANCED;
		ps.Approval_Request_Type__c = 'Tier Upgrade';
		insert ps;
/*
		PartnerStatus__c ps2 = [select Id, Anti_Corruption_Exception__c from PartnerStatus__c where Id = :ps.Id];
		System.assert(ps2.Anti_Corruption_Exception__c == true, 'Expected anti_corruption_exception__c to be True');

		ProcessInstanceWorkItem[] wilist = [
			select	p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
			from	ProcessInstanceWorkitem p
			where	p.ProcessInstance.TargetObjectId = :ps.Id
			and		p.ProcessInstance.Status = 'Pending'
		];
		System.assert(wilist.size() > 0, 'No approval process found for anti-corruption object');

		ProcessInstanceWorkItem wi = wilist.get(0);
		ID workItemId = wi.Id;

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
		req.setComments('Approving request');
        req.setAction('Approve');
		req.setWorkitemId(workItemId);
		Approval.ProcessResult result =  Approval.process(req);
		System.assert(result.isSuccess(), 'Unable to auto-approve partner status');

		acct = PartnerTestUtils.refreshAccount(acct);
		System.assert(acct.Anti_Corruption_Status__c == 'Review Required', 'Expected account anti_corruption_status__c to be Review Required');

		System.assert(ps.Id != null, 'ps.Id is null');
		Anti_Corruption__c[] aclist = [
			select	Id
			from	Anti_Corruption__c
			where	Partner_Account__c = :ps.Partner__c
		];
		System.assert(!aclist.isEmpty(), 'Anti_Corruption record not found for partner status');
		System.assert(aclist.size() == 1, 'Found multiple anti-corruption records');
		//
		// The ui controller would normally do this, so handle it here
		//
		aclist.get(0).Needs_Level_2_Review__c = false;
		update aclist.get(0);

		//
		// Approve legal
		//
		wilist = [
			select	p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
			from	ProcessInstanceWorkitem p
			where	p.ProcessInstance.TargetObjectId = :aclist.get(0).Id
			and		p.ProcessInstance.Status = 'Pending'
		];
		System.assert(wilist.size() > 0, 'No approval process found for anti-corruption object');
		System.assert(wilist.size() == 1, 'Multiple approvals active for same record');

		wi = wilist.get(0);
		workItemId = wi.Id;

        req = new Approval.ProcessWorkitemRequest();
		req.setComments('Approving request');
        req.setAction('Approve');
		req.setWorkitemId(workItemId);
		result =  Approval.process(req);
		System.assert(result.isSuccess(), 'Unable to auto-approve partner status in legal review');

//		Anti_Corruption__c ac = [select Id, Review_Status__c from Anti_Corruption__c where Id = :aclist.get(0).Id];
//		System.assert(ac.Review_Status__c == 'Approved and Archived', 'Expected anti-corruption review status to be Approved, found ' + ac.Review_Status__c);
		ps = [select Id, ApprovalStatus__c from PartnerStatus__c where Id = :ps.Id];
		System.assert(ps.ApprovalStatus__c == 'Approved', 'Status not approved: ' + ps.ApprovalStatus__c);

		Test.stopTest();
		*/
    }


    static testMethod void testRequalificationApproval() {

		DeactivateAllTestUtil.setDeactivateAll(false);

		Account acct = PartnerTestUtils.makeAccount('testRequalificationApproval', PartnerTestUtils.getAdminUser());
        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
		PartnerTestUtils.makeAccountISV(acct.Id);

		PartnerRequalification__c pr = new PartnerRequalification__c();
		pr.AccountId__c = acct.Id;
		pr.FCPAConvictedOfCrime__c = 'Yes';
        pr.Internal_Review__c = 'I do not know of anything with this potential partner that should require additional checks';
		insert pr;

		// kick off the anti-corruption approval via the requal completion trigger
		acct.RequalStatus__c = 'Manager Completed';
		acct.RequalificationLatestId__c = pr.Id;
		update acct;
		Anti_Corruption__c ac = [
			select	Id
			from	Anti_Corruption__c
			where	Partner_Account__c = :acct.Id
		];

		ProcessInstanceWorkItem[] wilist = [
			select	p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
			from	ProcessInstanceWorkitem p
			where	p.ProcessInstance.TargetObjectId = :ac.Id
			and		p.ProcessInstance.Status = 'Pending'
		];
		System.assert(wilist.size() > 0, 'No approval process found for anti-corruption object');

		// kick off the trigger
		ac.Review_Status__c = 'Approved';
		update ac;
    }

    static testMethod void testRequalificationRejected() {

		DeactivateAllTestUtil.setDeactivateAll(false);

        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
		Account acct = PartnerTestUtils.makeAccount('testRequalificationRejected', PartnerTestUtils.getAdminUser());
		PartnerTestUtils.makeAccountISV(acct.Id);

		PartnerRequalification__c pr = new PartnerRequalification__c();
		pr.AccountId__c = acct.Id;
		pr.FCPAConvictedOfCrime__c = 'Yes';
        pr.Internal_Review__c = 'I do not know of anything with this potential partner that should require additional checks';
		insert pr;

		// kick off the anti-corruption approval via the requal completion trigger
		acct.RequalStatus__c = 'Manager Completed';
		acct.RequalificationLatestId__c = pr.Id;
		update acct;

		Anti_Corruption__c ac = [
			select	Id, Review_Status__c
			from	Anti_Corruption__c
			where	Partner_Account__c = :acct.Id
		];

		ProcessInstanceWorkItem[] wilist = [
			select	p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
			from	ProcessInstanceWorkitem p
			where	p.ProcessInstance.TargetObjectId = :ac.Id
			and		p.ProcessInstance.Status = 'Pending'
		];
		System.assert(wilist.size() > 0, 'No approval process found for anti-corruption object');

		// kick off the trigger
		ac.Review_Status__c = 'Rejected';
		update ac;

		// verify the status is Unaffiliated
		PartnerStatus__c[] pslist = [
			select	Id, PartnerType__c, PartnerTier__c
			from	PartnerStatus__c
			where	Partner__c = :acct.Id
			and		PartnerTier__c = :RedHatObjectReferences__c.getInstance('PARTNER_TIER.UNAFFILIATED').ObjectId__c
		];
		System.assert(pslist.size() > 0, 'Expected account to be Unaffiliated');
    }


    static testMethod void testRequalificationReadyPartner() {

		DeactivateAllTestUtil.setDeactivateAll(false);

        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
		Account acct = PartnerTestUtils.makeAccount('testRequalificationReadyPartner', PartnerTestUtils.getAdminUser());
		PartnerTestUtils.makeAccountISV(acct.Id);

		PartnerRequalification__c pr = new PartnerRequalification__c();
		pr.AccountId__c = acct.Id;
		pr.FCPAConvictedOfCrime__c = 'No';
        pr.Internal_Review__c = 'I do not know of anything with this potential partner that should require additional checks';
		insert pr;

		// kick off the anti-corruption approval via the requal completion trigger.
		acct.RequalStatus__c = 'Manager Completed';
		acct.RequalificationLatestId__c = pr.Id;
        acct.Direct_Purchasing_Agreement__c = true;
		update acct;
		Anti_Corruption__c[] aclist = [
			select	Id
			from	Anti_Corruption__c
			where	Partner_Account__c = :acct.Id
		];
        System.assert(aclist.size() == 1, 'Anti corruption record created for Ready partner - expected one, found ' + aclist.size());
/*
        ProcessInstanceWorkItem[] wilist = [
            select	p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
            from	ProcessInstanceWorkitem p
            where	p.ProcessInstance.TargetObjectId = :acct.Id
            and		p.ProcessInstance.Status = 'Pending'
        ];
        System.assert(!wilist.isEmpty(), 'account for auto-approved requal stuck in approval process');
*/
    }

}