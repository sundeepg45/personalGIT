public without sharing class PartnerPgmDashController {

    public class Definition {
        public  ID      programId       {get; set;}
        public  ID      definitionId    {get; set;}
        public  String  name            {get; set;}
        public  String  description     {get; set;}
        public  Date    enrolled        {get; set;}
        public  DateTime    created         {get; set;}
        public  Attachment[]    attachments {get; set;}
        public  Attachment[]    agreementAttachments {get; set;}
        public  Agreement__c[]  agreements {get; set;}
        public  Boolean isEnrolled      {get; set;}
        public  String status           {get; set;}
    }

    public Definition[] accountPrograms { public get; private set; }
    public Definition[] availablePrograms { public get; private set; }
    public String enrollProgramId {get; set; }
    public Boolean isPAR {get; set;}

    private User me;
    public Partner_Program__c currentRequest {get; private set; }
    public Attachment[] currentAgreementDocuments {get; private set; }
    private Account acct;
    private String federationId;
    private Id parfId = null;

    //
    // Embed stuff
    //
    public Partner_Program_Product__c currentProduct {get; private set; }



    public PartnerPgmDashController() {
    }

    private void loadAccount() {
        if (!String.isEmpty(federationId)) {
            me = [
                select  Id,
                        Federation_ID__c,
                        ContactId,
                        Contact.Account.Id,
                        LanguageLocaleKey
                from    User
                where   Federation_ID__c = :federationId
            ];
        } else {
            me = [select Id, Federation_ID__c, ContactId, Contact.Account.Id, LanguageLocaleKey from User where Id = :UserInfo.getUserId()];
        }
        acct = [
            select  Id, Name, Finder_Partner_Type__c, Finder_Partner_Tier__c, Global_Region__c, ShippingCountry, BillingCountry, OwnerId
            from    Account
            where   Id = :me.Contact.Account.Id
        ];
    }

    public void init(String federationId) {
        this.federationId = federationId;
        init();
    }

    public void init() {
        loadAccount();
        String languageCode = me.LanguageLocaleKey;
        /*billing address
        if (languageCode.startsWith('zh') == false) {
            if (languageCode.indexOf('_') != -1) {
                languageCode = languageCode.split('_')[0];
            }
        }
        */
        System.debug('*****[debug]****** languageCode=' + languageCode);
        Classification__c ptype = [select Name from Classification__c where Id = :acct.Finder_Partner_Type__c];
        Classification__c ptier = [select Name from Classification__c where Id = :acct.Finder_Partner_Tier__c];

        Partner_Program__c[] enrolled = [
            select  Status__c, Program__r.Name, Program__c, Id, CreatedDate,
                    Enroll_Date__c, CurrencyIsoCode, Account__c, Program__r.Id
            from    Partner_Program__c
            where   Status__c != 'Rejected'
            //and Status__c != 'Terms Declined By User'
            and     Account__c = :acct.id
            order by Enroll_Date__c desc
        ];
        ID[] enrolledIdList = new List<ID>();
        accountPrograms = new List<Definition>();

        for (Partner_Program__c pgm : enrolled) {

            Partner_Program_Description__c[] ppdesc = [
                select  Name, Language_Code__c
                from    Partner_Program_Description__c
                where   Definition__c = :pgm.Program__r.Id
                and     Language_Code__c in (:languageCode, 'en_US')
            ];

            Definition d = new Definition();

            d.name = findLanguageName(ppdesc, languageCode);
            if (d.name == null) d.name = findLanguageName(ppdesc, 'en_US');
            if (d.name == null) d.name = 'description unavailable';

            d.programId = pgm.Id;
            d.definitionId = pgm.Program__r.Id;
            d.created = pgm.CreatedDate;
            d.enrolled = pgm.Enroll_Date__c;
            d.status = pgm.Status__c;
            accountPrograms.add(d);

            if(pgm.Status__c != 'Terms Declined By User')
                enrolledIdList.add(pgm.Program__r.Id);
        }

        Partner_Program_Description__c[] allprograms = [
            select  p.Program_Description__c,
                    Definition__r.Id, p.Id, Name, Definition__r.Is_Internal_Only__c
            from    Partner_Program_Description__c p
            where   p.Language_Code__c = :languageCode
            and     (p.Definition__r.Global_Region__c = null or p.Definition__r.Global_Region__c includes (:acct.Global_Region__c))
            and     (p.Definition__r.Partner_Type__c = null or p.Definition__r.Partner_Type__c includes (:pType.Name))
            and     (p.Definition__r.Partner_Tier__c = null or p.Definition__r.Partner_Tier__c includes (:pTier.Name))
            and     p.Definition__r.Program_Status__c = 'Active'
            order by    Name
        ];

		//
		// Unfortunate hack to only show PAR for pilot accounts
		//
		if (!Test.isRunningTest()) {
			Map<String,PAR_Pilot_Account__c> pilots = PAR_Pilot_Account__c.getAll();
			if (pilots.size() > 0) {
				// check if this account is eligible for the pilot
				Boolean found = false;
				for (PAR_Pilot_Account__c ppa : pilots.values()) {
					if (ppa.AccountId__c == acct.id) {
						found = true;
					}
				}
				if (!found) {
					// filter out PAR
					Partner_Program_Description__c[] keepers = new List<Partner_Program_Description__c>();
					for (Partner_Program_Description__c ppd : allprograms) {
						if (ppd.Name != 'Partner Assistance Reward Program') {
							keepers.add(ppd);
						}
					}
					allprograms = keepers;
				}
			}
		}
        system.debug('allprograms: [' + allprograms + ']');


        //
        // get list of all definition IDs
        //
        Set<ID> defIdList = new Set<ID>();
        for (Partner_Program_Description__c ppdesc : allprograms) {
            defIdList.add(ppdesc.Definition__r.Id);
        }

        //
        // country specific stuff
        //
        Country__c accountCountry = getAccountCountry();
        System.debug('*****[debug]***** accountCountry=' + accountCountry.Abbreviation__c);
        List<Agreement_Country__c> agreementCountryList = [
            Select Agreement__c
              From Agreement_Country__c
             where Country__c = :accountCountry.Id
               and Agreement__r.Partner_Program__c in :defIdList
               and Agreement__r.ActivationStatus__c = 'Active'
        ];

        Agreement__c[] flatAgreements = [
            select  Id, Partner_Program__c, Name, Country__c
            from    Agreement__c
            where   Id in :PartnerUtil.getStringFieldSet(agreementCountryList, 'Agreement__c')
        ];
        System.debug('*****[debug]***** agreements=' + flatAgreements.size());

        //
        // make definition-to-agreements map
        //
        Map<ID,Agreement__c[]> agreementMap = new Map<ID, Agreement__c[]>();
        for (Agreement__c agreement : flatAgreements) {
            Agreement__c[] mapAgreements = agreementMap.get(agreement.Partner_Program__c);
            if (mapAgreements == null) {
                mapAgreements = new List<Agreement__c>();
                agreementMap.put(agreement.Partner_Program__c, mapAgreements);
            }
            mapAgreements.add(agreement);
            System.debug('*****[debug]***** added agreement for program ' + agreement.Partner_Program__c);
        }

        availablePrograms = new List<Definition>();
        for (Partner_Program_Description__c pgm : allprograms) {
            Definition d = new Definition();
            d.name = pgm.Name;
            d.isEnrolled = containsID(enrolledIdList, pgm.Definition__r.Id);
            d.definitionId = pgm.Definition__r.Id;
            d.description = pgm.Program_Description__c;
            d.attachments = [select Id, Name from Attachment where ParentId = :pgm.Id];
            d.agreements = agreementMap.get(pgm.Definition__r.Id);
            if (d.agreements == null || d.agreements.size() == 0) {
                continue;
            }
            // If account partner type is Service/Cloud Provider, they should not see the CCP program in the available programs list.
            if (pgm.Name == 'Certified Cloud Provider' && acct.Finder_Partner_Type__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SERVICECLOUD_PROVIDER').ObjectId__c){
                system.debug('Partner Type is Service/Cloud Provider - the CCP program will be hidden from them.');
                continue;
            }
            if (pgm.Definition__r.Is_Internal_Only__c) {
                // Hide all type-based programs.
                continue;
            }
            d.agreementAttachments = getAttachmentsForAgreements(d.agreements);
            availablePrograms.add(d);
        }

    }

    private Country__c getAccountCountry() {
        String countryAbbr = acct.BillingCountry;
        if (countryAbbr == null) {
            countryAbbr = acct.ShippingCountry;
        }
        try {
            return [select Id, Iso3166Alpha2__c, IsAgreementSignatureRequired__c, Abbreviation__c from Country__c where Abbreviation__c = :countryAbbr];
        } catch (Dmlexception de){
            // We potentially have a bad billing / shipping country, try the other way around
            countryAbbr = acct.ShippingCountry;
            return [select Id, Iso3166Alpha2__c, IsAgreementSignatureRequired__c from Country__c where Abbreviation__c = :countryAbbr];
        }
        return null;
    }

    public Agreement__c[] getAgreementsForProgram(ID definitionId) {
        System.debug('*****[debug]***** definitionId=' + definitionId);
        List<Agreement_Country__c> agreementCountryList = [
            Select Agreement__c
              From Agreement_Country__c
             where Country__c = :getAccountCountry().Id
               and Agreement__r.Partner_Program__c = :definitionId
               and Agreement__r.ActivationStatus__c = 'Active'
        ];

        Agreement__c[] flatAgreements = [
            select  Id, Partner_Program__c, Name, Version__c
            from    Agreement__c
            where   Id in :PartnerUtil.getStringFieldSet(agreementCountryList, 'Agreement__c')
        ];

        System.debug('*****[debug]***** agreements found: ' + flatAgreements.size());
        return flatAgreements;
    }

    private Attachment[] getAttachmentsForAgreements(Agreement__c[] agreements) {
        if (agreements == null) {
            return new List<Attachment>();
        }
        Attachment[] attachments = [select Id, Name, ParentId from Attachment where ParentId in :PartnerUtil.getIdSet(agreements)];
        for (Attachment attachment : attachments) {
            for (Agreement__c agreement : agreements) {
                if (agreement.Id == attachment.ParentId) {
                    attachment.Name = agreement.Name;
                    break;
                }
            }
        }
        System.debug('*****[debug]***** attachments found: ' + attachments.size());
        return attachments;
    }

    private Boolean containsID(List<ID> aList, ID target) {
        for (ID a : aList) {
            if (a == target) return true;
        }
        return false;
    }

    private ID getAttachmentId(ID descId) {
        Attachment[] alist = [select Id from Attachment where ParentId = :descId limit 1];
        if (!alist.isEmpty()) {
            return alist.get(0).Id;
        }
        return null;
    }

    public PageReference enroll() {
        enrollProgramId = ApexPages.currentPage().getParameters().get('enrollProgramId');
        System.debug('*****[debug]***** enrollProgramId=' + enrollProgramId);
        for (Definition d : availablePrograms) {
            if (d.definitionId == enrollProgramId) {
                createRequest();
                if (currentRequest.Program__r.Program_Category__c == PartnerConst.CCNSP) {
                    return new PageReference('/apex/CCSPForm?accountId=' + acct.Id + '&enrollProgramId=' + enrollProgramId);
                }
                if (currentRequest.Program__r.Program_Category__c == PartnerConst.EMBED) {
                    return new PageReference('/apex/PARF?accountId=' + acct.Id + '&enrollProgramId=' + enrollProgramId);
                }
                return Page.PartnerProgramApplication;
            }
        }
        return null;
    }

    public PageReference enrollCCSP(Id programId, Id ccspFormId) {
        enrollProgramId = programId;
        for (Definition d : availablePrograms) {
            if (d.definitionId == enrollProgramId) {
                createRequest();
                currentRequest.CCSP_Form__c = ccspFormId;
                currentRequest.Enroll_Date__c = System.today();
                if (currentRequest.Program__r.Program_Category__c == PartnerConst.CCNSP) {
                    currentRequest.Tier__c = PartnerConst.UNAFFILIATED;
                    return submitRequest();
                }
                return Page.PartnerProgramApplication;
            }
        }
        return null;
    }

    public PageReference enrollEmbedded(Id programId, Id parfId) {
        enrollProgramId = programId;
        for (Definition d : availablePrograms) {
            if (d.definitionId == enrollProgramId) {
                createRequest();
                currentRequest.Enroll_Date__c = System.today();
                if (currentRequest.Program__r.Program_Category__c == PartnerConst.EMBED) {
                    this.parfId = parfId;
                    currentRequest.Tier__c = PartnerConst.UNAFFILIATED;
                    return submitRequest();
                }
                return Page.PartnerProgramApplication;
            }
        }
        return null;
    }

    private PageReference submitForApproval() {
        Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();
        approvalReq.setComments('Submitted for partner program enrollment approval');
        approvalReq.setObjectId(currentRequest.Id);
        Approval.ProcessResult result = Approval.process(approvalReq);

        System.assert(result.isSuccess(), 'Approval process failed for program enrollment');

        ProcessInstanceWorkItem[] wilist = [
            select  p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
            from    ProcessInstanceWorkitem p
            where   p.ProcessInstance.TargetObjectId = :currentRequest.Id
            and     p.ProcessInstance.Status = 'Pending'
        ];
        if (wilist.isEmpty()) {

            // autoapproved, so skip right to t&c
            currentAgreementDocuments = getAttachmentsForAgreements(getAgreementsForProgram(currentRequest.Program__r.Id));
            return Page.PartnerProgramAgreement;
        }
        else {
            // not autoapproved, we are done until user clicks on email link to accept t&c
            PageReference page = new PageReference('/apex/PartnerProgramThankYou');
            if (!String.isEmpty(federationId)) {
                page.setRedirect(true);
                page.getParameters().put(OnboardingApplyController.PARAM_FEDERATION_ID, federationId);
            }
            return page;
        }
    }

    public PageReference submitRequest() {
        //
        // validation
        //
        // if (currentRequest.Program__r.Program_Category__c == 'Embedded') {
        //     // if (currentRequest.Program_Contact__c == null && currentRequest.Admin_Contact__c == null) {
        //     if (currentRequest.Program_Contact__c == null) {
        //         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Program_Controller_Validation_Contact_Req));
        //     }
        //     if (currentProduct.Product_Name__c == null) {
        //         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Program_Controller_Validation_Prod_Name_Req));
        //     }
        //     if (currentProduct.Requested_Descriptions__c == null) {
        //         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Program_Controller_Validation_Desc_Req));
        //     }
        //     if (currentProduct.Developer_Support__c == null) {
        //         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Program_Controller_Validation_Dev_Support_Req));
        //     }
        //     if (currentRequest.EDP_name__c == null) {
        //         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Program_Controller_Validation_EDP_name));
        //     }
        //     if (currentProduct.Product_Description__c == null) {
        //         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'A product description is required'));
        //     }
        //
        //     if (ApexPages.hasMessages()) {
        //         return null;
        //     }
        // }

        insert currentRequest;
        system.debug('currentRequest: ' + currentRequest);
        if (currentRequest.Program__r.Program_Category__c == PartnerConst.EMBED) {
            PARF_Form__c parf = [
                select  Id
                from    PARF_Form__c
                where   Id = :parfId
            ];
            parf.Program_Membership__c = currentRequest.Id;
            update parf;
            List<PARF_Product__c> parfProducts = [
                select  Id,
                        PARF_Form__c,
                        Product_Description__c,
                        Product_Name__c,
                        Product_URL__c,
                        Desired_RH_Prod_Desc__c
                from    PARF_Product__c
                where   PARF_Form__c = :parfId
            ];
            if (parfProducts.size() > 0) {
                List<Partner_Program_Product__c> programProducts = new List<Partner_Program_Product__c>();
                for (PARF_Product__c parfProduct : parfProducts) {
                    Partner_Program_Product__c product = new Partner_Program_Product__c();
                    product.Program__c = currentRequest.Id;
                    product.Product_Description__c = parfProduct.Product_Description__c;
                    product.Product_Name__c = parfProduct.Product_Name__c;
                    product.Product_URL__c = parfProduct.Product_URL__c;
                    product.Requested_Descriptions__c = parfProduct.Desired_RH_Prod_Desc__c;
                    programProducts.add(product);
                }
                if (programProducts.size() > 0) {
                    insert programProducts;
                }
            }
        }
        if(currentRequest.Name == 'Certified Cloud Provider'){
        	// Create a CCP Form for this account
        	createCCPForm();
        }

        if (currentProduct != null){
            currentProduct.Program__c = currentRequest.Id;
            insert currentProduct;
        }


        currentAgreementDocuments = getAttachmentsForAgreements(getAgreementsForProgram(currentRequest.Program__r.Id));
        update currentRequest;
        if (currentProduct != null) {
            update currentProduct;
            currentProduct = null;
        }
        return submitForApproval();
    }

    private void createCCPForm(){
    	Partner_CCP_Form__c[] existingForms = [
		      select  Id, Lead__c
		      from  Partner_CCP_Form__c
		      where  Partner__c = :currentRequest.Account__c];

		// We only want to create one CCP form for the partner
		if(!existingForms.isEmpty()) return;

    	try{

    	   Partner_CCP_Form__c ccpForm = new Partner_CCP_Form__c(Partner__c = currentRequest.Account__c);
    	   insert(ccpForm);
    	   currentRequest.CCP_Form__c = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/PartnerCCPForm?id=' + ccpForm.Id;

    	} catch(DmlException e){
    	   system.debug('Error creating CCP form: [' + e + ']');
    	}
    }

    public PageReference cancelRequest() {
        currentRequest = null;
        currentProduct = null;
        return Page.PartnerPrograms;
    }

    public PageReference approvedClicked() {
        enrollProgramId = ApexPages.currentPage().getParameters().get('enrollProgramId');
        currentRequest = [
            select  Id, Name, Program__r.Name, Program__r.Program_Category__c, Program_Contact__c, Account__r.Name
            from    Partner_Program__c
            where   Id = :enrollProgramId
        ];
        loadAccount();
        currentAgreementDocuments = getAttachmentsForAgreements(getAgreementsForProgram(currentRequest.Program__r.Id));
        return Page.PartnerProgramAgreement;
    }

    public PageReference acceptAgreement() {
        currentRequest.Status__c = 'Active';
        currentRequest.Agreement_Contact__c = [select ContactId from User where Id = :UserInfo.getUserId()].ContactId;
        currentRequest.Enroll_Date__c = System.today();
        update currentRequest;

        system.debug('DEMEG: currentRequest: [' + currentRequest + ']');

        Agreement__c[] agreements = getAgreementsForProgram(currentRequest.Program__r.Id);
        if (agreements != null && !agreements.isEmpty()) {
            PartnerAgreement__c[] palist = new List<PartnerAgreement__c>();
            for (Agreement__c agreement : agreements) {
                PartnerAgreement__c pa = new PartnerAgreement__c();
                pa.Partner__c = acct.Id;
                pa.PartnerUser__c = UserInfo.getUserId();
                pa.Agreement__c = agreement.Id;
                pa.ActivationDate__c = System.today();
                pa.PartnerApprovalStatus__c = 'Approved';
                palist.add(pa);
            }
            if (!palist.isEmpty()) {
                insert palist;
            }
        }


        // If this is a PAR Program enrollment, the last step in the process is the financial info form.
        if(currentRequest.Name == 'Partner Assistance Reward Program'){
            return Page.PartnerProgramThankYou;

            // **** TODO: Update this when Andreina gets the final oracle link ****
            /*
            PageReference financialForm = new PageReference('https://www.redhat.com/PAR_Finacial_Info.html');
            financialForm.setRedirect(true);
            return financialForm;
            */

        } else {
            return Page.PartnerPrograms;
        }

    }

    public PageReference declineAgreement() {
        currentRequest.Status__c = 'Terms Declined By User';
        currentRequest.Agreement_Contact__c = [select ContactId from User where Id = :UserInfo.getUserId()].ContactId;
        update currentRequest;

        Agreement__c[] agreements = getAgreementsForProgram(currentRequest.Program__r.Id);
        System.debug('*****[debug]***** declined agreements=' + agreements.size());
        if (agreements != null && !agreements.isEmpty()) {
            PartnerAgreement__c[] palist = new List<PartnerAgreement__c>();
            for (Agreement__c agreement : agreements) {
                PartnerAgreement__c pa = new PartnerAgreement__c();
                pa.Partner__c = acct.Id;
                pa.PartnerUser__c = UserInfo.getUserId();
                pa.ActivationDate__c = System.today();
                pa.Agreement__c = agreement.Id;
                pa.PartnerApprovalStatus__c = 'Rejected';
                palist.add(pa);
            }
            if (!palist.isEmpty()) {
                insert palist;
            }
        }
        return Page.PartnerPrograms;
    }


    public PageReference sendToFinancialApp(){
        return null;
    }


    private String findLanguageName(Partner_Program_Description__c[] ppdesc, String language) {
        for (Partner_Program_Description__c ppd : ppdesc) {
            if (ppd.Language_Code__c == language) {
                return ppd.Name;
            }
        }
        return null;
    }

    private void createRequest() {
        System.debug('*****[debug]***** programId=' + enrollProgramId);

        Partner_Program__c req = new Partner_Program__c();
        Partner_Program_Description__c[] ppdesc = [
            select  Language_Code__c, Name
            from    Partner_Program_Description__c
            where   Definition__c = :enrollProgramId
            and     Language_Code__c in (:me.LanguageLocaleKey, 'en_US')
        ];

        Partner_Program_Definition__c ppd = [
            select Id, Name, Program_Category__c
            from Partner_Program_Definition__c
            where Id = :enrollProgramId
        ];

        system.debug('PROGRAM DEFINITION: [' + ppd + '], ACCOUNT: [' + me.Contact.Account.Id + ']');

        req.Name = findLanguageName(ppdesc, me.LanguageLocaleKey);
        if (req.Name == null) req.Name = findLanguageName(ppdesc, 'en_US');
        if (req.Name == null) req.Name = 'description unavailable';

        req.Program__r = ppd;
        req.Program__c = enrollProgramId;
        req.Program_Contact__c = me.ContactId;
        req.RHN_Login_of_Program_Contact__c = me.Federation_ID__c;
        req.Account__c = me.Contact.Account.Id;
        req.Account__r = [select Id, Name from Account where Id = :me.Contact.Account.Id];
        req.Status__c = 'Pending';
        req.User__c = acct.OwnerId;

        currentRequest = req;

        // if (currentRequest.Program__r.Program_Category__c == 'Embedded') {
        //     currentProduct = new Partner_Program_Product__c();
        // }
    }

    public PageReference createContact() {

        PageReference pg = new PageReference('/003/e?con4=');
        pg.setRedirect(true);
        return pg;
    }

    @IsTest(SeeAllData=true)
    private static void normalTest() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        //
        // make an account and user
        //
        Account acct = PartnerTestUtils.quickGenericAccountSetup('Partner Program Controller test');
        Contact c = PartnerTestUtils.makeContact(acct.Id, 'Partner.Pgm.Test');
        insert c;
        User u = PartnerTestUtils.makeUser(acct, c);
        insert u;

        //
        // make a new program
        //
        Partner_Program_Definition__c ppd = new Partner_Program_Definition__c();
        ppd.Global_Region__c = 'NA';
        ppd.Partner_Type__c = 'Reseller';
        ppd.Partner_Tier__c = 'Advanced';
        ppd.Program_Status__c = 'Active';
        insert ppd;

        Partner_Program_Description__c ppdesc = new Partner_Program_Description__c();
        ppdesc.Name = 'Test Program';
        ppdesc.Definition__c = ppd.Id;
        ppdesc.Language_Code__c = 'en_US';
        ppdesc.Program_Description__c = 'A wholly inappropriate description for production use';
        insert ppdesc;

        //
        // make a test agreement
        //
        Agreement__c ag = new Agreement__c();
        ag.Language__c = 'English';
        ag.ActivationDate__c = System.today();
        ag.Type__c = 'Partner';
        ag.Version__c = 1.0;
        ag.Partner_Program__c = ppd.Id;
        insert ag;

        Agreement_Country__c ac = new Agreement_Country__c();
        ac.Agreement__c = ag.Id;
        ac.Country__c = [select Id from Country__c where Name = 'UNITED STATES'].Id;
        insert ac;

        ag.ApprovalStatus__c = 'Approved';
        update ag;


        //
        // make a dummy agreement attachment
        //
        Attachment att = new Attachment();
        att.ParentId = ag.Id;
        att.ContentType = 'Application/Text';
        att.Name = 'test attachment';
        att.Body = EncodingUtil.base64Decode('Veni Vidi Vicci');
        insert att;

        Test.startTest();
        PartnerPgmDashController ctrl = new PartnerPgmDashController();
        System.runAs(u) {
            ctrl.init();
            System.currentPageReference().getParameters().put('enrollProgramId', ppd.Id);
            PageReference pageref = ctrl.enroll();
            System.assert(pageref != null, 'Page reference is null');
            System.assert(pageref.getUrl().endsWith('partnerprogramapplication'), 'Unexpected page reference: ' + pageref.getUrl());

            pageref = ctrl.submitRequest();
            System.assert(pageref != null, 'Page reference is null');
            System.assert(pageref.getUrl().endsWith('partnerprogramagreement'), 'Unexpected page reference: ' + pageref.getUrl());

            pageref = ctrl.acceptAgreement();
            System.assert(pageref != null, 'Page reference is null');
            System.assert(pageref.getUrl().endsWith('partnerprograms'), 'Unexpected page reference: ' + pageref.getUrl());

            pageref = ctrl.cancelRequest();

            pageref = ctrl.createContact();
        }

        Test.stopTest();
    }

    // @IsTest(SeeAllData=true)
    // private static void embedTest() {
    //     DeactivateAllTestUtil.setDeactivateAll(false);
    //
    //     //
    //     // make an account and user
    //     //
    //     Account acct = PartnerTestUtils.quickGenericAccountSetup('Partner Program Controller test');
    //     Contact c = PartnerTestUtils.makeContact(acct.Id, 'Partner.Pgm.Test');
    //     insert c;
    //     User u = PartnerTestUtils.makeUser(acct, c);
    //     insert u;
    //
    //     //
    //     // make a new program
    //     //
    //     Partner_Program_Definition__c ppd = new Partner_Program_Definition__c();
    //     ppd.Global_Region__c = 'NA';
    //     ppd.Partner_Type__c = 'Reseller';
    //     ppd.Partner_Tier__c = 'Advanced';
    //     ppd.Program_Status__c = 'Active';
    //     ppd.Program_Category__c = 'Embedded';
    //     insert ppd;
    //
    //     Partner_Program_Description__c ppdesc = new Partner_Program_Description__c();
    //     ppdesc.Name = 'Test Program';
    //     ppdesc.Definition__c = ppd.Id;
    //     ppdesc.Language_Code__c = 'en_US';
    //     ppdesc.Program_Description__c = 'A wholly inappropriate description for production use';
    //     insert ppdesc;
    //
    //
    //     //
    //     // make a test agreement
    //     //
    //     Agreement__c ag = new Agreement__c();
    //     ag.Language__c = 'English';
    //     ag.ActivationDate__c = System.today();
    //     ag.Type__c = 'Partner';
    //     ag.Version__c = 1.0;
    //     ag.Partner_Program__c = ppd.Id;
    //     insert ag;
    //
    //     Agreement_Country__c ac = new Agreement_Country__c();
    //     ac.Agreement__c = ag.Id;
    //     ac.Country__c = [select Id from Country__c where Name = 'UNITED STATES'].Id;
    //     insert ac;
    //
    //     ag.ApprovalStatus__c = 'Approved';
    //     update ag;
    //
    //
    //     //
    //     // make a dummy agreement attachment
    //     //
    //     Attachment att = new Attachment();
    //     att.ParentId = ag.Id;
    //     att.ContentType = 'Application/Text';
    //     att.Name = 'test attachment';
    //     att.Body = EncodingUtil.base64Decode('Veni Vidi Vicci');
    //     insert att;
    //
    //     Test.startTest();
    //     PartnerPgmDashController ctrl = new PartnerPgmDashController();
    //     System.runAs(u) {
    //         ctrl.init();
    //         System.currentPageReference().getParameters().put('enrollProgramId', ppd.Id);
    //         PageReference pageref = ctrl.enroll();
    //         System.assert(pageref != null, 'Page reference is null');
    //         // System.assert(pageref.getUrl().endsWith('partnerprogramapplication'), 'Unexpected page reference: ' + pageref.getUrl());
    //
    //         ctrl.currentRequest.Program_Contact__c = c.Id;
    //         ctrl.currentProduct.Product_Name__c = 'Abc';
    //         ctrl.currentProduct.Requested_Descriptions__c = 'Def';
    //         ctrl.currentProduct.Developer_Support__c = 'abc';
    //         ctrl.currentRequest.EDP_name__c = 'Dell';
    //         ctrl.currentProduct.Product_Description__c = 'SOme Description';
    //
    //         pageref = ctrl.submitRequest();
    //         System.assert(pageref != null, 'Page reference is null');
    //         System.assert(pageref.getUrl().endsWith('partnerprogramagreement'), 'Unexpected page reference: ' + pageref.getUrl());
    //
    //         pageref = ctrl.acceptAgreement();
    //         System.assert(pageref != null, 'Page reference is null');
    //         System.assert(pageref.getUrl().endsWith('partnerprograms'), 'Unexpected page reference: ' + pageref.getUrl());
    //
    //         pageref = ctrl.cancelRequest();
    //     }
    //
    //     Test.stopTest();
    // }

    @IsTest(SeeAllData=true)
    private static void declineAgreementTest() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        //
        // make an account and user
        //
        Account acct = PartnerTestUtils.quickGenericAccountSetup('Partner Program Controller test');
        Contact c = PartnerTestUtils.makeContact(acct.Id, 'Partner.Pgm.Test');
        insert c;
        User u = PartnerTestUtils.makeUser(acct, c);
        insert u;

        //
        // make a new program
        //
        Partner_Program_Definition__c ppd = new Partner_Program_Definition__c();
        ppd.Global_Region__c = 'NA';
        ppd.Partner_Type__c = 'Reseller';
        ppd.Partner_Tier__c = 'Advanced';
        ppd.Program_Status__c = 'Active';
        insert ppd;

        Partner_Program_Description__c ppdesc = new Partner_Program_Description__c();
        ppdesc.Name = 'Test Program';
        ppdesc.Definition__c = ppd.Id;
        ppdesc.Language_Code__c = 'en_US';
        ppdesc.Program_Description__c = 'A wholly inappropriate description for production use';
        insert ppdesc;

        //
        // make a test agreement
        //
        Agreement__c ag = new Agreement__c();
        ag.Language__c = 'English';
        ag.ActivationDate__c = System.today();
        ag.Type__c = 'Partner';
        ag.Version__c = 1.0;
        ag.Partner_Program__c = ppd.Id;
        insert ag;

        Agreement_Country__c ac = new Agreement_Country__c();
        ac.Agreement__c = ag.Id;
        ac.Country__c = [select Id from Country__c where Name = 'UNITED STATES'].Id;
        insert ac;

        ag.ApprovalStatus__c = 'Approved';
        update ag;

        //
        // make a dummy agreement attachment
        //
        Attachment att = new Attachment();
        att.ParentId = ag.Id;
        att.ContentType = 'Application/Text';
        att.Name = 'test attachment';
        att.Body = EncodingUtil.base64Decode('Veni Vidi Vicci');
        insert att;

        Test.startTest();
        PartnerPgmDashController ctrl = new PartnerPgmDashController();
        System.runAs(u) {
            ctrl.init();
            System.currentPageReference().getParameters().put('enrollProgramId', ppd.Id);
            PageReference pageref = ctrl.enroll();
            System.assert(pageref != null, 'Page reference is null');
            System.assert(pageref.getUrl().endsWith('partnerprogramapplication'), 'Unexpected page reference: ' + pageref.getUrl());

            pageref = ctrl.submitRequest();
            System.assert(pageref != null, 'Page reference is null');
            System.assert(pageref.getUrl().endsWith('partnerprogramagreement'), 'Unexpected page reference: ' + pageref.getUrl());

            pageref = ctrl.declineAgreement();
            System.assert(pageref != null, 'Page reference is null');
            System.assert(pageref.getUrl().endsWith('partnerprograms'), 'Unexpected page reference: ' + pageref.getUrl());

            PartnerAgreement__c[] declineList = [select Id from PartnerAgreement__c where Partner__c = :acct.Id and Agreement__c = :ag.Id];
            System.assert(declineList.size() > 0, 'Expected declined agreements, found none');
        }

        Test.stopTest();
    }

    @IsTest(SeeAllData=true)
    private static void twoStepTest() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        //
        // make an account and user
        //
        Account acct = PartnerTestUtils.quickGenericAccountSetup('Partner Program Controller test');
        Contact c = PartnerTestUtils.makeContact(acct.Id, 'Partner.Pgm.Test');
        insert c;
        User u = PartnerTestUtils.makeUser(acct, c);
        insert u;

        //
        // make a new program
        //
        Partner_Program_Definition__c ppd = new Partner_Program_Definition__c();
        ppd.Global_Region__c = 'NA';
        ppd.Partner_Type__c = 'Reseller';
        ppd.Partner_Tier__c = 'Advanced';
        ppd.Program_Status__c = 'Active';
        insert ppd;

        Partner_Program_Description__c ppdesc = new Partner_Program_Description__c();
        ppdesc.Name = 'Test Program';
        ppdesc.Definition__c = ppd.Id;
        ppdesc.Language_Code__c = 'en_US';
        ppdesc.Program_Description__c = 'A wholly inappropriate description for production use';
        insert ppdesc;

        //
        // make a test agreement
        //
        Agreement__c ag = new Agreement__c();
        ag.Language__c = 'English';
        ag.ActivationDate__c = System.today();
        ag.Type__c = 'Partner';
        ag.Version__c = 1.0;
        ag.Partner_Program__c = ppd.Id;
        insert ag;

        Agreement_Country__c ac = new Agreement_Country__c();
        ac.Agreement__c = ag.Id;
        ac.Country__c = [select Id from Country__c where Name = 'UNITED STATES'].Id;
        insert ac;

        ag.ApprovalStatus__c = 'Approved';
        update ag;

        //
        // make a dummy agreement attachment
        //
        Attachment att = new Attachment();
        att.ParentId = ag.Id;
        att.ContentType = 'Application/Text';
        att.Name = 'test attachment';
        att.Body = EncodingUtil.base64Decode('Veni Vidi Vicci');
        insert att;

        //
        // make another test agreement
        //
        ag = new Agreement__c();
        ag.Language__c = 'English';
        ag.ActivationDate__c = System.today();
        ag.Type__c = 'Partner';
        ag.Version__c = 1.0;
        ag.Partner_Program__c = ppd.Id;
        insert ag;

        ac = new Agreement_Country__c();
        ac.Agreement__c = ag.Id;
        ac.Country__c = [select Id from Country__c where Name = 'UNITED STATES'].Id;
        insert ac;

        ag.ApprovalStatus__c = 'Approved';
        update ag;

        //
        // make a dummy agreement attachment
        //
        att = new Attachment();
        att.ParentId = ag.Id;
        att.ContentType = 'Application/Text';
        att.Name = 'test attachment';
        att.Body = EncodingUtil.base64Decode('Veni Vidi Vicci');
        insert att;

        Test.startTest();
        PartnerPgmDashController ctrl = new PartnerPgmDashController();
        System.runAs(u) {
            ctrl.init();
            System.currentPageReference().getParameters().put('enrollProgramId', ppd.Id);
            PageReference pageref = ctrl.enroll();
            System.assert(pageref != null, 'Page reference is null');
            System.assert(pageref.getUrl().endsWith('partnerprogramapplication'), 'Unexpected page reference: ' + pageref.getUrl());

            pageref = ctrl.submitRequest();
            System.assert(pageref != null, 'Page reference is null');
            System.assert(pageref.getUrl().endsWith('partnerprogramagreement'), 'Unexpected page reference: ' + pageref.getUrl());

            // simulate abandoning the agreement screen and going back to the dashboard link to accept terms
            ID programId = [select Id from Partner_Program__c where Account__c = :acct.Id limit 1].Id;
            System.currentPageReference().getParameters().put('enrollProgramId', programId);
            System.debug('*****[debug]***** START');
            pageref = ctrl.approvedClicked();
            System.debug('*****[debug]***** END');
            System.assert(pageref != null, 'Page reference is null');
            System.assert(pageref.getUrl().endsWith('partnerprogramagreement'), 'Unexpected page reference: ' + pageref.getUrl());
//            System.assert(ctrl.currentAgreementDocuments.size() == 2, 'Expected 2 agreements, found ' + ctrl.currentAgreementDocuments.size());
        }

        Test.stopTest();
    }

}