public without sharing class Embedded_Terms_Controller {

	public static final String CONTRACT_TYPE = 'Embedded Deal';
    private Partner_Onboarding_Registration__c reg;
    private PartnerUser_Email_Token__c tokenrec;
    public Partner_Onboarding_Registration__c lead {get; private set;}
    public Account acct {get; private set; }
    public List<Agreement__c> agreementList {get; private set;}
    private String federationId;
    public Boolean thankYou {get; set; }
    public Boolean customThankYou {get; set; }
    public String customText {get; set; }
    private Boolean submitted = false;
    public Boolean thankYouDeclined {get; set; }
    public String termType {get; set; }
    public Boolean unsure {get; set; }
    public Boolean customTermsReq {get; set;}
    public PARF_Form__c checklist {get; set; }
    private Country__c country;
    private Account salesAccount;
	public Boolean declineInProcess {get; private set;}

    public Embedded_Terms_Controller() {
        thankYou = false;
        customThankYou = false;
        thankYouDeclined = false;
        unsure = false;
        customTermsReq = false;
        customText = '';
    }

    public void init() {
		declineInProcess = false;
        String token = ApexPages.currentPage().getParameters().get('token');
        federationId = ApexPages.currentPage().getParameters().get('federationId');
        System.assert(token != null, 'Invalid use of this page');
        System.assert(federationId != null, 'Invalid use of this page');

//tokenrec = new PartnerUser_Email_Token__c();
//tokenrec.Partner_Onboarding__c = 'a5C60000000F6Vn';
//tokenrec.Account__c = '001300000094UYh';
        PartnerUser_Email_Token__c[] tokenreclist = [select Id, Partner_Onboarding__c, Account__c, Is_Active__c from PartnerUser_Email_Token__c where Token__c = :token limit 1];
        System.assert(tokenreclist.size() > 0, 'Invalid token detected');
        tokenrec = tokenreclist.get(0);

        //
        // The email token record MUST contain either a Partner_Onboarding__c or Account__c value
        //
        ID partnerId = tokenrec.Account__c;

        //
        // Its not always true that the Token is associated to the Onboarding record itself.
        // It could be associated to Account when contract rejection initiates terms process. Changing the query to always run
        //

        //if (tokenrec.Partner_Onboarding__c != null) {
        //lead = [
        //        select  Id, Country__c, Country__r.IsAgreementSignatureRequired__c, Partner_Type__c, RHNLogin__c, ConvertedAccount__c, ConvertedAccount__r.OwnerId, Country__r.Name,
        //                Onboarding_Language_Preference__c
        //        from    Partner_Onboarding_Registration__c
        //        where   Id = :tokenrec.Partner_Onboarding__c or (RHNLogin__c = :federationId and SubType__c = :PartnerConst.Embedded)
        //    ];

        Partner_Onboarding_Registration__c[] onbs = [
                select  Id, Country__c, Country__r.IsAgreementSignatureRequired__c, Partner_Type__c, RHNLogin__c, ConvertedAccount__c, ConvertedAccount__r.OwnerId, Country__r.Name,
                        Onboarding_Language_Preference__c
                from    Partner_Onboarding_Registration__c
                where   Id = :tokenrec.Partner_Onboarding__c or (RHNLogin__c = :federationId and SubType__c = :PartnerConst.Embedded)
            ];
        if(onbs.size() > 0) {
            lead = onbs[0];
            System.assert(lead.RHNLogin__c == federationId, 'Invalid use of this page - not authorized');
            partnerId = lead.ConvertedAccount__c;
            country = [select Id, Name from Country__c where Id = :lead.Country__c];
        }
        else {
            lead = new Partner_Onboarding_Registration__c();
        }

        System.debug('[DEBUG]* Onboarding Record Found was: '+lead.Id);

        acct = [
            select     Id, OwnerId, BillingCountry, ShippingCountry, Finder_Partner_Type__c, Finder_Partner_Type_Name__c, Global_Region__c, SubRegion__c
            from       Account
            where      Id = :partnerId
        ];

        if (country == null) {
            String abbr = acct.BillingCountry;
            if (abbr == null) abbr = acct.ShippingCountry;
            if (abbr != null) {
                Country__c[] tmplist = [select Id, Name from Country__c where Abbreviation__c = :abbr];
                if (tmplist.size() > 0) {
                    country = tmplist.get(0);
                }
            }
        }

        Map<ID, Account> salesAccountMap = PartnerUtil.getSalesAccountsForPartners(new Set<ID> { acct.Id });
        if (salesAccountMap.isEmpty()) {
            LogSwarm log = new LogSwarm('Onboarding', 'Terms');
            log.push('partner account id', acct.Id);
            log.error('Unable to complete Embedded Terms submission - sales account not found');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unexpected data integrity problem - Customer account not found. Please contact support.'));
        }
        salesAccount = salesAccountMap.get(acct.Id);

		if (tokenrec.Is_Active__c == false) {
			System.debug('***** [debug] ***** token is inactive');
        	Contract[] tmp = [
				select 	Id
				from 	Contract
				where 	AccountId = :salesAccount.Id
				and 	Contract_Type__c = :CONTRACT_TYPE
                and     RecordType.DeveloperName = :PartnerConst.CONTRACT_RECORD_TYPE
				and 	Status = 'Rejected'
				order by LastModifiedDate desc
				limit 	1
			];
			if (tmp.size() > 0) {
				// user is returning to this page after contract has been rejected.  Allow him back in.
				tokenrec.Is_Active__c = true;
				System.debug('***** [debug] ***** rejected contract found');
			}
			else {
				System.debug('***** [debug] ***** no contract found');
			}
		}
		System.assert(tokenrec.Is_Active__c, 'Invalid token detected');

        //Custom terms page is not applicable for Embedded
        PARF_Form__c[] checklists = [select Custom_Terms_Required__c from PARF_Form__c where Account__c = :acct.Id];
        if (checklists.size() > 0) {
            checklist = checklists.get(0);
            if (checklist.Custom_Terms_Required__c != null) {
                termType = 'standard';
                //customTermsReq = true;
            }
        }
        else {
            // this shouldn't ever happen, here to support testing only
            checklist = new PARF_Form__c();
            System.debug('****[debug]***** PARF record not found');
        }

        agreementList = getRelevantAgreementList();
    }

    public void acceptStandardTerms() {

        // remove unaffiliated status here
        Partner_Program__c[] proglist = [
            select   Id, Tier__c, Program__r.Program_Category__c, Is_Primary__c
            from     Partner_Program__c
            where    Account__c = :acct.Id
            and      (Program__r.Program_Category__c in (:PartnerConst.EMBED, :PartnerConst.ISV, :PartnerConst.RESELLER))
            and      Tier__c = :PartnerConst.UNAFFILIATED
        ];

        System.debug('[DEBUG]* Number of Memberships returned and were to be upgraded: ' +proglist.size());
        System.debug('[DEBUG]* hasOnbRec: ' +hasOnbRec);

        if (hasOnbRec) {
            lead.Agree_to_Partner_TC__c = true;
        }
        for (Partner_Program__c prog : proglist) {
            System.debug('[DEBUG] Program operating on is: '+prog.Program__r.Program_Category__c);
            if (!hasOnbRec && prog.Is_Primary__c) {
                // don't update anything on the primary if enrolling
                continue;
            }
            if (prog.Program__r.Program_Category__c == PartnerConst.EMBED) {
                prog.Tier__c = 'Affiliated';
            }
            else {
                prog.Tier__c = 'Ready';
            }
            prog.IsVisible__c = true;
            prog.Status__c = 'Active';
			if (!hasOnbRec) {
				prog.Agree_to_Partner_T_C__c = true;
			}
			if (prog.Enroll_Date__c == null) {
				prog.Enroll_Date__c = System.today();
			}
        }
        update proglist;

        PartnerAgreement__c[] partnerAgreementList = new List<PartnerAgreement__c>();
        if (agreementList != null && agreementList.size() > 0) {
            for(Agreement__c agreement : getRelevantAgreementList()) {
                PartnerAgreement__c partnerAgreement = new PartnerAgreement__c();
                partnerAgreement.Agreement__c = agreement.Id;
                if (hasOnbRec) {
                    partnerAgreement.Partner_Onboarding__c = lead.Id;
                }
                partnerAgreement.ActivationDate__c = Date.today();
                partnerAgreement.Partner__c = acct.Id;

                //According to, US79276, Program guides should be marked as 'Approved' - Kiran on 12/15
                //if (agreement.Is_Terms_Document__c) {
                    partnerAgreement.PartnerApprovalStatus__c = 'Approved';
                    partnerAgreementList.add(partnerAgreement);
                //}
            }
            insert partnerAgreementList;
        } else {
            if (hasOnbRec) {
                lead.No_Agreements__c = true;
            }
        }

        if (hasOnbRec) {
            update lead;
        }

        tokenrec.Is_Active__c = false;
        update tokenrec;
        thankYou = true;
        submitted = true;
    }

    public PageReference acceptButton() {
        acceptStandardTerms();
        return null;
    }

    public PageReference gobackButton() {
        unsure = false;
        return null;
    }

    public PageReference unsureButton() {
        unsure = true;
        return null;
    }

    public Boolean showCustomTerms {
        get {
            return unsure;
            //cusotm terms page does not exists for embedded:
            //|| checklist.Custom_Terms_Required__c == 'Yes';
        }
    }

    public Boolean hasOnbRec {
        get {
            return lead != null && lead.Id != null;
        }
    }

	public void declineButton() {
		declineInProcess = true;
	}

	public void cancelDeclineButton() {
		declineInProcess = false;
	}

	public PageReference submitDeclineButton() {
		if (customText != null && customText.trim() != '') {
			declineInProcess = false;
		}
		termType = 'decline';
		return submitButton();
	}

    public PageReference submitButton() {

        System.debug('****[debug]**** termsType=' + termType);

        if (submitted) {
            // protect from Back button
            return null;
        }
        Contract[] tmp = [select Id from Contract where AccountId = :acct.Id and Contract_Type__c = :CONTRACT_TYPE and Stage__c = 'Deal Design Request Submitted'];
        if (tmp.size() > 0) {
            // prevent Back button dups
            return null;
        }

        Partner_Program__c[] progs = [
            select Id, Tier__c
            from Partner_Program__c
            where Account__c = :acct.Id
            // and Program__r.Program_Category__c in (:PartnerConst.EMBED, :PartnerConst.ISV, :PartnerConst.RESELLER)
			and Program__r.Program_Category__c = :PartnerConst.EMBED
            and Tier__c = :PartnerConst.UNAFFILIATED
        ];
        if (progs.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unexpected data integrity problem - Program not found. Please contact support.'));
            return null;
        }
        Partner_Program__c prog = progs.get(0);
//        if (prog.Tier__c == 'Advanced') {
            // prevent Back button issues
//            return null;
//        }

        if (termType == 'standard') {
            acceptStandardTerms();
            return null;
        }

        User me = null;
        if (!Test.isRunningTest()) {
            me = [select Id, Email from User where Federation_ID__c = :federationId and Contact.AccountId = :acct.Id];
        }
        else {
            me = [select Id, Email from User where Id = :UserInfo.getUserId()];
        }

        if (hasOnbRec) lead.CustomTerms__c = null;

        if (termType == 'custom') {
			if (customText == null || customText.length() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.CCSP_Terms_Please_provide_text));
                return null;
            }
            if (hasOnbRec) {
                lead.CustomTerms__c = customText;
                // lead.User_Declined_Custom_Terms__c = false;
            }
            if (!hasOnbRec) {	// enrolling
                prog.CustomTerms__c = customText;
                // prog.User_Declined_Custom_Terms__c = false;
                update prog;
            }
        }

        if (termType == 'decline') {
            // thankYouDeclined = true;
			if (customText == null || customText.length() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Embedded_Custom_Reason));
                return null;
            }
            if (hasOnbRec) {
                // lead.User_Declined_Custom_Terms__c = true;
                lead.CustomTerms__c = customText;
				update lead;
            }
            if (!hasOnbRec) {	// enrolling
				prog.CustomTerms__c = customText;
                // prog.User_Declined_Custom_Terms__c = true;
                update prog;
            }

            // disable the token
            tokenrec.Is_Active__c = false;
            update tokenrec;

            // return null;
        }
        if (hasOnbRec) {
            update lead;
        }

        //
        // Custom terms requested, create contract and send for approval
        //

        System.debug('*****[debug]***** requestingUser=' + me.Id);
//Savepoint sp = Database.setSavepoint();
        Contract con = new Contract();
        con.AccountId = salesAccount.Id;
        con.OwnerId = acct.OwnerId;
        con.CreatedById = acct.OwnerId;
        con.Description = 'Embedded standard terms declined';
        con.Super_Region__c = acct.Global_Region__c;
        con.SubRegion__c = acct.Subregion__c;
        con.CountryOfOrder__c = country.Name;
        con.Contract_Type__c = CONTRACT_TYPE;
        con.Stage__c = 'New';
        con.Requesting_User__c = me.Id;
        //US77004
        // (hasOnbRec) {
        //	con.Reason_Partner_Declined_Terms__c = lead.CustomTerms__c;
        //else {
        //  con.Reason_Partner_Declined_Terms__c = prog.CustomTerms__c;
        //
        con.Reason_Partner_Declined_Terms__c = customText;
        con.RecordTypeId = [
            select  Id
            from    RecordType
            where   SObjectType = 'Contract'
            and     DeveloperName = :PartnerConst.CONTRACT_RECORD_TYPE
            and     IsActive = true
        ].Id;
        insert con;


        if (!Test.isRunningTest()) {
            //
            // Submit contract record into the approval process
            //
/****
    String templName = 'CCSP_ONB_CustomTerms_Request_Acknowledge';
    EmailTemplate[] tmpllist = [select Id, Subject, Body from EmailTemplate where DeveloperName = :templName];

    OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    String[] tolist = new List<String>();
    tolist.add(me.Email);
    mail.setTargetObjectId(me.Id);
    mail.setTemplateId(tmpllist.get(0).Id);
    mail.setToAddresses(tolist);
    mail.setReplyTo('noreply@redhat.com');
    mail.setOrgWideEmailAddressId(owe.id);
    mail.saveAsActivity = FALSE;
    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
****/
            System.assert(con.Id != null);
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setComments('Submitting custom contract request');
            approvalRequest.setObjectId(con.Id);
            Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
            //System.Assert(approvalResult.isSuccess(), approvalResult.getErrors());
        }

        tokenrec.Is_Active__c = false;
        update tokenrec;
		customThankYou = true;
        submitted = true;
//Database.rollback(sp);

        return null;

//        return Page.CCSPTermsCustomThankYou;
    }

    public PageReference loginButton() {
        PageReference page = new PageReference('/partner');
        page.setRedirect(true);
        page.getParameters().put(OnboardingApplyController.PARAM_FEDERATION_ID, federationId);
        return page;
    }

    public List<Agreement__c> getRelevantAgreementList() {
        List<Agreement__c> agreementList = new List<Agreement__c>();

        User me = [select Id, Contact.LanguageCode__c from User where Id = :UserInfo.getUserId()];
        String languageName = PartnerUtil.getLanguageNameForCode(me.Contact.LanguageCode__c);

		Partner_Program_Definition__c pgm = [select Id from Partner_Program_Definition__c where Program_Category__c = :PartnerConst.EMBED limit 1];

        if (country != null && acct.Finder_Partner_Type__c != null ) {
            // Here we are getting all the documents for a country.
            // We want all agreements for the Lead's preferred language and all non-specific ones
            Set<Id> agreementIdSet = new Set<Id>();
            List<Agreement_Country__c> agreementCountryList = [
                Select Agreement__c
                  From Agreement_Country__c
                 where Country__c = :country.Id
                   and Agreement__r.ActivationStatus__c = 'Active'
                   and Agreement__r.Partner_Program__c = :pgm.Id
                   and (Agreement__r.Type__c = 'Partner' or Agreement__r.Type__c = 'Partner & User')
                   and (Language__c = null or Language__c = :languageName)
            ];
            for(Agreement_Country__c agreementCountry :agreementCountryList) {
                agreementIdSet.add(agreementCountry.Agreement__c);
            }

            if (agreementIdSet != null && agreementIdSet.size() > 0) {
                agreementList = [
                    select  Id,Name, Is_Terms_Document__c, IsSignatureRequired__c, Version__c,
                            (select Name from Attachments)
                    from    Agreement__c
                    where   Id IN :agreementIdSet
                ];
            }

            // Here we are getting all the global documents.
            // Prefer language-specific ones over the non-language defaults
            List<Agreement__c> globalAgreementList  = [
                    select Id
                         , Name
                         , IsSignatureRequired__c
                         , Is_Terms_Document__c
                         , Version__c
                         , (select Name from Attachments)
                      from Agreement__c
                     where Country_Count__c = 0
                       and ActivationStatus__c = 'Active'
                       and Partner_Program__c = :pgm.Id
                       and (Type__c = 'User' or Type__c = 'Partner & User')
                       and (Language__c = null or Language__c = :languageName)

            ];
            if (globalAgreementList != null && globalAgreementList.size() > 0) {
                for (Agreement__c globalAgreement :globalAgreementList) {
                    agreementList.add(globalAgreement);
                }
            }
        }

        for (Agreement__c agree : agreementList) {
            if (agree.Is_Terms_Document__c) {
                mainTermsAgreementAttachmentId = agree.Attachments[0].Id;
                break;
            }
        }

        System.debug('*****[debug]***** agreementList.size = ' + agreementList.size());
        return agreementList;
    }

    public ID mainTermsAgreementAttachmentId {get;set;}

}