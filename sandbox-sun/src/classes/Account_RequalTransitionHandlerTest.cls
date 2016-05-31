@isTest
private class Account_RequalTransitionHandlerTest {

    static testMethod void agreementTest() {

        DeactivateAllTestUtil.setDeactivateAll(false);

        Account account = PartnerTestUtils.makeAccount('RequalTransitionTest1', PartnerTestUtils.getAdminUser());
        account.RequalStatus__c = null;
        update account;
        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        insert PartnerTestUtils.makeProgram(account.id, PartnerConst.ISV, PartnerConst.READY);

        PartnerRequalification__c requal = new PartnerRequalification__c();
        requal.accountId__c = account.id;
        requal.AgreementConfirmed__c = true;

        Agreement__c agree = [select id from Agreement__c where ActivationStatus__c = 'Active' limit 1];
        requal.Submitted__c = true;
        requal.AgreementState__c = 'Accepted';
        insert requal;

        Partner_Requalification_Agreement__c pra = new Partner_Requalification_Agreement__c();
        pra.Partner_Requalification__c = requal.id;
        pra.Agreement__c = agree.id;
        insert pra;

        account.RequalStatus__c = 'Completed';
        account.RequalificationLatestId__c = requal.Id;
        update account;

        List<Partner_Requalification_Agreement__c> praList = [
            select id from Partner_Requalification_Agreement__c where Partner_Requalification__c = :requal.Id
        ];

        System.assert(praList != null && praList.size() > 0);
    }

    static testMethod void defaultACTest() {

        DeactivateAllTestUtil.setDeactivateAll(false);

        Account account = PartnerTestUtils.makeAccount('RequalTransitionTest2', PartnerTestUtils.getAdminUser());
        account.RequalStatus__c = null;
        update account;
        PartnerTestUtils.IGNORE_BLOCK_EDIT_ON_CDH_MERGE = true;
        insert PartnerTestUtils.makeProgram(account.id, PartnerConst.ISV, PartnerConst.READY);

        PartnerRequalification__c requal = new PartnerRequalification__c();
        requal.accountId__c = account.id;
        requal.AgreementConfirmed__c = true;

        Agreement__c agree = [select id from Agreement__c where ActivationStatus__c = 'Active' limit 1];
        requal.Submitted__c = true;
        requal.AgreementState__c = 'Accepted';
        requal.Internal_Review__c = 'I do not know of anything with this potential partner that should require additional checks';
        insert requal;

        Partner_Requalification_Agreement__c pra = new Partner_Requalification_Agreement__c();
        pra.Partner_Requalification__c = requal.id;
        pra.Agreement__c = agree.id;
        insert pra;

        account.RequalStatus__c = 'Manager Completed';
        account.RequalificationLatestId__c = requal.Id;
        update account;

        Anti_Corruption__c ac = [select Id, Review_Status__c, Auto_Approved__c from Anti_Corruption__c where Partner_Account__c = :account.Id];
        System.assert(ac.Review_Status__c == 'Approved and Archived', 'Unexpected anti-corruption status: ' + ac.Review_Status__c);
        System.assert(ac.Auto_Approved__c, 'Expected auto approved True');
    }

}