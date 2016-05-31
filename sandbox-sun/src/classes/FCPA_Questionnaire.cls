public without sharing class FCPA_Questionnaire {

	public Partner_Program_Approval__c program {get; set;}
    private String federationId;
    private PartnerUser_Email_Token__c tokenrec;
    public Boolean isError { get; set; }
    public Boolean completed {get; set; }
    public static Boolean isUserUpdating = false;

	public String 				partnerType 					{get; set;}
	public Id 					mainTermsAgreementAttachmentId 	{get; set;}
	public String 				agreeTerms 						{get; set;}
	public String 				declinedReason 					{get; set;}
	public Boolean              hasAgreements   				{get; private set;}
    public List<Agreement__c>   agreements      				{get; private set;}

	private Account             account;
    private Id                  countryId;

	public FCPA_Questionnaire() {
        isError = false;
        completed = false;
	}

    public void init() {
        String token = ApexPages.currentPage().getParameters().get('token');
        federationId = ApexPages.currentPage().getParameters().get('federationId');
        if (token == null || federationId == null) {
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid use of this page'));
            return;
        }

//tokenrec = new PartnerUser_Email_Token__c();
//tokenrec.Partner_Onboarding__c = 'a5C60000000F6Vn';
//tokenrec.Account__c = '001300000094UYh';
        PartnerUser_Email_Token__c[] tokenreclist = [select Id, Email__c, Program_Approval_Request__c,Account__c from PartnerUser_Email_Token__c where Token__c = :token and Is_Active__c = true limit 1];
        if (tokenreclist.size() == 0) {
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This request has already been fulfilled.  If you believe this is an error please contact your account manager for assistance'));
            return;
        }
        tokenrec = tokenreclist.get(0);

        program = [
            select  Id, Account__c, Convicted__c, FCPA_Underlying_Facts__c, Government_Position__c, Reason_Agreements_Declined__c, Agree_To_Partner_TC__c
            from    Partner_Program_Approval__c
            where   Id = :tokenrec.Program_Approval_Request__c
        ];

        program.FCPA_Responder_Login__c = federationId;

        account = [
            select  Id,
                    Name,
                    BillingCountry,
                    Finder_Partner_Type__c
            from    Account
            where   Id = :program.Account__c
        ];
        countryId = [
            select  Id,
                    Name,
                    Abbreviation__c
            from    Country__c
            where   Abbreviation__c = :account.BillingCountry
        ].Id;
        agreements = getAgreements();
        hasAgreements = (agreements != null && agreements.size() > 0);
    }

    public PageReference submitButton() {

		Boolean validationErrors = false;

		if ((program.Convicted__c == 'Yes' || program.Government_Position__c == 'Yes') && (program.FCPA_Underlying_Facts__c == '' || program.FCPA_Underlying_Facts__c == null)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.FCPA_Questionnaire_Underlying_Facts_Error));
			validationErrors = true;
		}

		if (hasAgreements && (agreeTerms == null || agreeTerms == '')) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.FCPA_Questionnaire_Terms_Error));
			validationErrors = true;
		}

		if (agreeTerms != null && agreeTerms == 'No' && (declinedReason == null || declinedReason == '')) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.FCPA_Questionnaire_Terms_Declined_Error));
			validationErrors = true;
		}

		if (validationErrors) {
				return null;
		}

		if (hasAgreements) {
			program.Agree_To_Partner_TC__c = agreementsAccepted;
			program.Reason_Agreements_Declined__c = declinedReason;
		}

        isUserUpdating = true;
        program.FCPA_Response_Date__c = System.now();
				program.User_IP__c = PartnerUtil.getUserIPAddress();
        program.Status__c = 'Draft';

        update program;

		List<PartnerAgreement__c> partnerAgreementList = new List<PartnerAgreement__c>();
		if (agreements != null && agreements.size() > 0) {
			for(Agreement__c agreement : agreements) {
				PartnerAgreement__c partnerAgreement = new PartnerAgreement__c();
				partnerAgreement.Agreement__c = agreement.Id;
				partnerAgreement.Partner_Program_Approval_Request__c = program.Id;
				partnerAgreement.ActivationDate__c = Date.today();
				partnerAgreement.PartnerApprovalStatus__c = 'Declined';
				if (agreementsAccepted) {
					partnerAgreement.PartnerApprovalStatus__c = 'Approved';
				}
				partnerAgreementList.add(partnerAgreement);
			}
			insert partnerAgreementList;
		}

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Partner tier change request.');
        req.setObjectId(program.Id);
        Approval.ProcessResult result = Approval.process(req, false);
        completed = true;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Information submitted. Thank you.'));

        tokenrec.Is_Active__c = false;
        update tokenrec;

        //
        // finally create a user and associate to federation id (if needed)
        //
        Contact[] contacts = [select Id, Email, FirstName, LastName, LanguagePreference__c from Contact where Email = :tokenRec.Email__c and AccountId = :program.Account__c];
        if (!contacts.isEmpty()) {
            User[] users = [select Id from User where FederationIdentifier = :federationId and ContactId = :contacts[0].Id];
            if (users.isEmpty()) {
                Contact c = contacts.get(0);
                createUser(c.Id);
            }
        }
        return null;
    }

    public void createUser(ID contactId) {
        Contact c = [select Id, AccountId, Email, FirstName, LastName, LanguagePreference__c from Contact where Id = :contactId];
        c.LoginName__c = federationId;
        update c;
        User me = new User();
        me.ContactId = c.Id;
        me.FirstName = c.FirstName;
        me.LastName = c.LastName;
        me.FederationIdentifier = federationId;
        me.Federation_Id__c = federationId;
        me.Email = c.Email;
        Account acct = [select Id, Global_Region__c, Finder_Partner_Type__r.HierarchyKey__c from Account where Id = :c.AccountId];
        Profile prof = PartnerUtil.onboardingProfile(acct.Global_Region__c, acct.Finder_Partner_Type__r.HierarchyKey__c);
        me.ProfileId = prof.Id;
        me.EmailEncodingKey = 'UTF-8';
        String langKey = PartnerUtil.getLanguageCodeForName(c.LanguagePreference__c);
        if (langKey == 'en') langKey = 'en_US';
        me.LanguageLocaleKey = langKey;
        me.LocaleSIdKey = langKey;
        me.TimeZoneSidKey = 'America/New_York';
        me.Username = OnboardingConversion.getPartnerUserUsername(c);
        me.Alias = OnboardingConversion.getPartnerUserAlias(c);
        insert me;
    }

	// public Agreement__c[] getAgreements() {
    //     // return getRelevantAgreementList();
    // }

	// public List<Agreement__c> getRelevantAgreementList() {
    //     System.debug('country=' + theLeadCountry);
    //     System.debug('partnerType=' + partnerType);
    //     List<Agreement__c> agreementList = new List<Agreement__c>();
	//
    //     if (this.selectedCountry != null && getLead() != null && partnerType != null ) {
	//
    //          System.debug('***** [DEBUG] ***** mylead.partnertype is ' + thelead.Partner_Type__c);
    //         // Here we are getting all the documents for a country.
    //         // We want all agreements for the Lead's preferred language and all non-specific ones
    //         Set<Id> agreementIdSet = new Set<Id>();
    //         List<Agreement_Country__c> agreementCountryList = [
    //             Select Agreement__c
    //               From Agreement_Country__c
    //              where Country__c = :this.selectedCountry.Id
    //                and Agreement__r.PartnerType__c = :thelead.Partner_Type__c
    //                and Agreement__r.ActivationStatus__c = 'Active'
    //                and Agreement__r.Partner_Program__c = null
    //                and (Agreement__r.Type__c = 'Partner' or Agreement__r.Type__c = 'Partner & User')
    //         ];
    //         for(Agreement_Country__c agreementCountry :agreementCountryList) {
    //             agreementIdSet.add(agreementCountry.Agreement__c);
    //         }
	//
    //         if (agreementIdSet != null && agreementIdSet.size() > 0) {
    //             if (skipAgreement) {
    //                 agreementList = [select Id,Name, Is_Terms_Document__c, IsSignatureRequired__c, Version__c, (select Name from Attachments) from Agreement__c where Id IN :agreementIdSet and Is_Terms_Document__c = False];
    //             }
    //             else {
    //                 agreementList = [select Id,Name, Is_Terms_Document__c, IsSignatureRequired__c, Version__c, (select Name from Attachments) from Agreement__c where Id IN :agreementIdSet];
    //             }
    //         }
	//
    //         // Here we are getting all the global documents.
    //         // Prefer language-specific ones over the non-language defaults
    //         List<Agreement__c> globalAgreementList  = [
    //                 select Id
    //                      , Name
    //                      , IsSignatureRequired__c
    //                      , Is_Terms_Document__c
    //                      , Version__c
    //                      , (select Name from Attachments)
    //                   from Agreement__c
    //                  where Country_Count__c = 0
    //                    and ActivationStatus__c = 'Active'
    //                    and PartnerType__c = :thelead.Partner_Type__c
    //                    and Partner_Program__c = null
    //                    and Type__c != 'User'
    //         ];
    //         if (globalAgreementList != null && globalAgreementList.size() > 0) {
    //             for (Agreement__c globalAgreement :globalAgreementList) {
    //                 agreementList.add(globalAgreement);
    //             }
    //         }
    //     }
	//
    //     for (Agreement__c agree : agreementList) {
    //         if (agree.Is_Terms_Document__c) {
    //             System.debug('*****[debug]***** attachment count=' + agree.Attachments.size());
    //             mainTermsAgreementAttachmentId = agree.Attachments[0].Id;
    //             System.debug('*****[debug]***** attachment name=' + agree.Attachments[0].Name);
    //             break;
    //         }
    //     }
	//
    //     if (agreementList != null && agreementList.size() > 0) {
    //         System.debug('Agreement List---------->::' + agreementList.size());
    //     }
    //     return agreementList;
    // }
	private List<Agreement__c> getAgreements() {
        List<Agreement__c> agreementList = new List<Agreement__c>();

        if (countryId != null && account != null) {

            // Here we are getting all the documents for a country.
            // We want all agreements for the user's preferred language and all non-specific ones
            Set<Id> agreementIdSet = new Set<Id>();
            List<Agreement_Country__c> agreementCountryList = [
                select  Agreement__c
                from    Agreement_Country__c
                where   Country__c = :countryId
                and     Agreement__r.PartnerType__c = :account.Finder_Partner_Type__c
                and 	Agreement__r.ActivationStatus__c = 'Active'
				and 	(Agreement__r.Type__c = 'Partner' or Agreement__r.Type__c = 'Partner & User')
            ];
            for(Agreement_Country__c agreementCountry :agreementCountryList) {
                agreementIdSet.add(agreementCountry.Agreement__c);
            }

            if (agreementIdSet != null && agreementIdSet.size() > 0) {
                    agreementList = [
                        select  Id,
                                Name,
                                Is_Terms_Document__c,
                                IsSignatureRequired__c,
                                Version__c,
                                (select Name
                                 from Attachments)
                        from    Agreement__c
                        where   Id
                        in      :agreementIdSet
                    ];
            }

            // Here we are getting all the global documents.
            // Prefer language-specific ones over the non-language defaults
            List<Agreement__c> globalAgreementList  = [
                    select  Id,
                            Name,
                            IsSignatureRequired__c,
                            Is_Terms_Document__c,
                            Version__c,
                            (select Name
                             from Attachments)
                    from    Agreement__c
                    where   Country_Count__c = 0
                    and     ActivationStatus__c = 'Active'
                    and     PartnerType__c = :account.Finder_Partner_Type__c
                    and     Partner_Program__c = null
                    and     Type__c != 'User'
            ];
            if (globalAgreementList != null && globalAgreementList.size() > 0) {
                for (Agreement__c globalAgreement :globalAgreementList) {
                    agreementList.add(globalAgreement);
                }
            }
        }

		for (Agreement__c agree : agreementList) {
            if (agree.Is_Terms_Document__c) {
                System.debug('*****[debug]***** attachment count=' + agree.Attachments.size());
                mainTermsAgreementAttachmentId = agree.Attachments[0].Id;
                System.debug('*****[debug]***** attachment name=' + agree.Attachments[0].Name);
                break;
            }
        }

        if (agreementList != null && agreementList.size() > 0) {
            System.debug('Agreement List---------->::' + agreementList.size());
        }

        return agreementList;
    }

	public Boolean agreementsAccepted {
        get {
            if (agreeTerms == null) return false;
            return agreeTerms.equalsIgnoreCase('yes') ? true : false;
        }
    }
}