/*****************************************************************************************
    Name    :   PartnerProgram_Approved
    Desc    :   trigger gets fired before a partner program update executes the following:
    Actions :   1. Check 'Custom_Terms_Required__c' field is mandatory
                2. Send click-back Terms Email to partner (For CCSP, Embed)
                3. Send an email to Disti.

Modification Log :
---------------------------------------------------------------------------
 Developer                Date            Description
---------------------------------------------------------------------------
 Kiran Ravikanti         09/29/2015       updated to Send an email to Disti(#3)
 Jonathan Garrison       10/05/2015       Suppressed the terms email for
                                          embedded if custom terms are required.
 Jonathan Garrison       10/06/2015       Updated to create contract for embedded
                                          when custom terms are required.
******************************************************************************************/

trigger PartnerProgram_Approved on Partner_Program__c (before update) {

    Partner_Program__c[] programList = new List<Partner_Program__c>();
    Partner_Program__c[] termsAcceptedPrograms = new List<Partner_Program__c>();

    User me = [
        select  Id,
                Email
        from    User
        where   Id = :UserInfo.getUserId()
    ];

    for (Partner_Program__c program : Trigger.new) {
        Partner_Program__c old = Trigger.oldMap.get(program.Id);

        if (old.Status__c != program.Status__c && program.Status__c == 'Pending Terms' &&
            (program.Program_Name__c == PartnerConst.CCNSP || program.Program_Name__c == PartnerConst.EMBED)) {
            programList.add(program);
        }
        //get the list of programs being activated after partner accepts the terms:
        if ((program.Status__c == 'Approved' || program.Status__c == 'Active') &&
            program.Program_Name__c == PartnerConst.EMBED && old.Tier__c != program.Tier__c &&
            (program.Tier__c == PartnerConst.AFFILIATED || program.Tier__c == PartnerConst.ADVANCED)) {
            termsAcceptedPrograms.add(program);
            system.debug('**[DEBUG]** Embedded Program being Approved: '+program.Id);
        }
    }
    system.debug('**[DEBUG]** Embedded Programs list size '+ termsAcceptedPrograms.size());

    // get the Disti Email addresses from the list of the PARFs
    List<PARF_Form__c> termsCompletedParfs = new List<PARF_Form__c>();
    if(!termsAcceptedPrograms.isEmpty()) {
        termsCompletedParfs =  [select  Id,
                                        EDP_Email__c,
                                        Program_Membership__c,
                                        OwnerId,
                                        //Program_Membership__r.Program_Name__c,
                                        Account__r.Name
                                from    PARF_Form__c
                                where   Account__c in :PartnerUtil.getStringFieldSet(termsAcceptedPrograms, 'Account__c')];
    }
    system.debug('**[DEBUG]** PARFS: '+termsCompletedParfs.size());

    //iterate-through the terms accepted PARFS and send the email to corresponding Distis:
    for (PARF_Form__c parf :termsCompletedParfs) {
        if (parf.EDP_Email__c != null) {
            //PartnerEmailUtils.sendEmbeddedDistiEmail(parf.EDP_Email__c, parf.Program_Membership__r.Program_Name__c, parf.Account__r.Name);
            System.debug('Account name: ' + parf.Account__r.Name);
            PartnerEmailUtils.sendEmbeddedDistiEmail(parf.EDP_Email__c, parf.Account__r.Name);
        }
    }

    if (programList.isEmpty()) {
        return;
    }

    Map<ID, CCSP_Form__c> ccspforms = new Map<ID, CCSP_Form__c>();
    for (CCSP_Form__c form : [
        select  Id, Contact_Email__c, Account__c, Contact_Preferred_Language__c, Custom_Terms_Required__c
        from    CCSP_Form__c
        where   Account__c in :PartnerUtil.getStringFieldSet(programList, 'Account__c')
    ]) {
        ccspforms.put(form.Account__c, form);
    }
    Map<ID, PARF_Form__c> parfforms = new Map<ID, PARF_Form__c>();
    for (PARF_Form__c form : [
        select  Id, Program_Contact_Email__c, Account__c, Contact_Preferred_Language__c, Custom_Terms_Required__c
        from    PARF_Form__c
        where   Account__c in :PartnerUtil.getStringFieldSet(programList, 'Account__c')
    ]) {
        parfforms.put(form.Account__c, form);
    }
    for (Partner_Program__c program : programList) {
        if (program.Program_Name__c == PartnerConst.CCNSP) {
            CCSP_Form__c form = ccspforms.get(program.Account__c);
            if (form != null) {
                if (form.Custom_Terms_Required__c != 'Yes' && form.Custom_Terms_Required__c != 'No') {
                    program.addError('Please return to the CCSP form and select an answer for "Custom Terms Required?"');
                }
                else {
                    PartnerEmailUtils.sendCCSPTermsEmail(program.Account__c, form.Contact_Email__c, form.Contact_Preferred_Language__c);
                }
            }
            else {
                LogSwarm log = new LogSwarm('Onboarding', 'Email');
                log.push('accountid', program.Account__c).error('Missing CCSP_Form__c for account - unable to send Terms email');
                program.addError('Related CCSP Form for Account is missing - required in order to determine terms email and language');
            }
        }
        if (program.Program_Name__c == PartnerConst.EMBED) {
            PARF_Form__c form = parfforms.get(program.Account__c);
            if (form != null) {
                if (form.Custom_Terms_Required__c != 'Yes' && form.Custom_Terms_Required__c != 'No') {
                    program.addError('Please return to the PARF form and select an answer for "Custom Terms Required?"');
                }
                else {
                    if (form.Custom_Terms_Required__c != 'Yes') { // If custom terms are required, don't send the terms email. US71992
                        PartnerEmailUtils.sendEmbedTermsEmail(program.Account__c, form.Program_Contact_Email__c, form.Contact_Preferred_Language__c);
                    }
                    // Create contract for custom terms and submit for approval. US71992
                    if (form.Custom_Terms_Required__c == 'Yes') {
                        User requestingUser = [
                            select  Id,
                                    Federation_ID__c
                            from    User
                            where   Federation_ID__c = :program.RHN_Login_of_Program_Contact__c
                            limit   1
                        ];
                        Account partnerAccount = [
                            select  Id,
                                    Name,
                                    OwnerId,
                                    BillingCountry,
                                    ShippingCountry,
                                    Global_Region__c,
                                    Subregion__c
                            from    Account
                            where   Id = :program.Account__c
                        ];
                        String countryName = partnerAccount.BillingCountry;
                        if (partnerAccount.BillingCountry == null) {
                            countryName = partnerAccount.ShippingCountry;
                        }
                        Map<Id, Account> partnerSalesAccountMap = PartnerUtil.getSalesAccountsForPartners(new Set<Id> {partnerAccount.Id});
                        Account salesAccount = partnerSalesAccountMap.get(partnerAccount.Id);
                        Contract con = new Contract();
                        con.AccountId = salesAccount.Id;
                        con.OwnerId = partnerAccount.OwnerId;
                        con.CreatedById = partnerAccount.OwnerId;
                        con.Description = 'Embedded standard terms declined';
                        con.Super_Region__c = partnerAccount.Global_Region__c;
                        con.SubRegion__c = partnerAccount.Subregion__c;
                        con.CountryOfOrder__c = countryName;
                        con.Contract_Type__c = Embedded_Terms_Controller.CONTRACT_TYPE;
                        con.Stage__c = 'New';
                        // con.Requesting_User__c = me.Id;
                        con.Requesting_User__c = requestingUser.Id;
                        con.RecordTypeId = [
                            select  Id
                            from    RecordType
                            where   SObjectType = 'Contract'
                            and     DeveloperName = :PartnerConst.CONTRACT_RECORD_TYPE
                            and     IsActive = true
                        ].Id;
                        insert con;
                        System.assert(con.Id != null);
                        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                        approvalRequest.setComments('Submitting custom contract request');
                        approvalRequest.setObjectId(con.Id);
                        Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
                    }
                }
            }
            else {
                LogSwarm log = new LogSwarm('Onboarding', 'Email');
                log.push('accountid', program.Account__c).error('Missing PARF_Form__c for account - unable to send Terms email');
                program.addError('Related PARF Form for Account is missing - required in order to determine terms email and language');
            }
        }
    }
}