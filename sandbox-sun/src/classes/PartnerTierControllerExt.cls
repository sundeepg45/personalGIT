public with sharing class PartnerTierControllerExt {
    private static final String ACCOUNT_ID = 'AccountId';
    private static final String PARTNER_PROGRAM_ID = 'PartnerProgramId';
    private static final String TIER_UPGRADE = 'Tier Upgrade';
    private static final String PENDING = 'Pending';
    private static final String DRAFT = 'Draft';
    private static final String HOLD = 'Hold';

    public static Boolean APPROVED_BY_API = false;

    public Boolean validationFailed {get;  set;}

    public Partner_Program__c partnerProgram {get; set;}

    public Partner_Program_Approval__c partnerProgramApprovalRequest {get; set;}

    public Id partnerProgramId {get; set;}
    public Id accountId {get; set;}
    public String selectedContact {public get; public set; }
    public String contactEmail {public get; public set; }
    public String contactFirstName { public get; public set; }
    public String contactLastName { public get; public set; }
    public String selectedLanguage {public get; public set; }
    public Boolean completed {public get; private set; }

    private List<String> tiers = new List<String>();

    public PartnerTierControllerExt() {
        completed = false;
        selectedLanguage = 'en';
        partnerProgramApprovalRequest = new Partner_Program_Approval__c();
        partnerProgramId = ApexPages.currentPage().getParameters().get(PARTNER_PROGRAM_ID);
        accountId = ApexPages.currentPage().getParameters().get(ACCOUNT_ID);
        System.debug('Account ID------------>' + accountId);
        partnerProgram = getProgramDetails(partnerProgramId);
        getAvailableTiers();
        validationFailed = false;
    }

    public PageReference submitTierChangeRequest() {
        if (completed || checkForOutstandingTierChangeRequests()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Request already submitted'));
            return null;
        }
        try {
            String email = null;
            if (isUnaffiliated) {
                //
                // do validations for FCPA section
                //
                if ((selectedContact == null || selectedContact.equals('null')) && (contactEmail == null || contactEmail.length() == 0)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Select a contact or provide an email address for FCPA completion'));
                    return null;
                }
                if (selectedContact != null && selectedContact.equals('null') == false && contactEmail != null && contactEmail.length() > 0) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Select either a contact or provide an email address for FCPA completion, not both'));
                    return null;
                }
                if (contactEmail != null && contactEmail.length() > 0 && !PartnerUtil.validateEmail(contactEmail)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid email address format'));
                    return null;
                }
                if (contactEmail != null && contactEmail.length() > 0 && (contactFirstName == null || contactFirstName.length() == 0)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'First name is required'));
                    return null;
                }
                if (contactEmail != null && contactEmail.length() > 0 && (contactLastName == null || contactLastName.length() == 0)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Last name is required'));
                    return null;
                }
                if (selectedContact != null && selectedContact.equals('null') == false) {
                    Contact c = [select Id, Email, LanguagePreference__c from Contact where Id = :selectedContact];
                    email = c.Email;
                    selectedLanguage = languageNameLookup(c.LanguagePreference__c);
                }
                else {
                    email = contactEmail;
                }
            }
            partnerProgramApprovalRequest.Program__c = partnerProgramId;
            partnerProgramApprovalRequest.Partner__c = accountId;
            partnerProgramApprovalRequest.Status__c = DRAFT;
            partnerProgramApprovalRequest.Approval_Request_Type__c = TIER_UPGRADE;

            if (isUnaffiliated) {
                if (partnerProgramApprovalRequest.Id == null) {
                    partnerProgramApprovalRequest.Status__c = HOLD;
                    insert partnerProgramApprovalRequest;
                }
                Contact[] contacts = [select Id from Contact where AccountId = :accountId and Email = :email];
                if (contacts.isEmpty()) {
                    // no contact already there, create one
                    Contact c = new Contact();
                    c.FirstName = contactFirstName;
                    c.LastName = contactLastName;
                    c.Email = email;
                    c.AccountId = accountId;
                    c.LanguagePreference__c = languageNameLookup(selectedLanguage);
                    insert c;
                }
                PartnerEmailUtils.sendTierChangeFCPAEmail(partnerProgramApprovalRequest.Id, email, selectedLanguage);
                completed = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Email sent to contact. Approval on hold until contact fulfills FCPA requirements.'));
                return null;
            }
            insert partnerProgramApprovalRequest;
            if (!Test.isRunningTest()) {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Partner tier change request.');
                req.setObjectId(partnerProgramApprovalRequest.Id);
                Approval.ProcessResult result = Approval.process(req, false);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Partner tier change request submitted.'));
            }
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            return null;
        }
        return new PageReference('/' + partnerProgramApprovalRequest.Id);
    }

    // Method to go back to the contact page.
    public PageReference back() {
        PageReference pageReference = new PageReference('/' + partnerProgramId);
        pageReference.setRedirect(true);
        return pageReference;
    }

    private String languageNameLookup(String name) {
        for (SelectOption opt : getLanguages()) {
            if (opt.getLabel() == name) {
                return opt.getValue();
            }
        }
        return 'en';
    }

    private Partner_Program__c getProgramDetails(Id partnerProgramId) {
        Partner_Program__c partnerProgram = [
            select  Id,
                    Account__r.Name,
                    Program_Name__c,
                    Tier__c,
                    Program__c,
                    Program__r.Partner_Tier__c
            from    Partner_Program__c
            where   Id = :partnerProgramId
        ];
        return partnerProgram;
    }

    public Boolean isUnaffiliated {
        get {
            if (isUnaffiliated == null) {
                try {
                    Partner_Program__c primary = [select Id, Tier__c from Partner_Program__c where Account__c = :accountId and Is_Primary__c = true];
                    isUnaffiliated = primary.Tier__c == PartnerConst.UNAFFILIATED;
                }
                catch (Exception ex) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Primary program missing on account - tier change not possible'));
                }
            }
            System.debug('***** [debug] ***** isUnaffiliated=' + isUnaffiliated);
            return isUnaffiliated;
        }
        set;
    }

    public SelectOption[] getAccountContacts() {
        SelectOption[] options = new List<SelectOption>();
        options.add(new SelectOption('null', '--None--'));
        for (Contact contact : [select Id, FirstName, LastName, Email from Contact where AccountId = :accountId order by LastName]) {
            options.add(new SelectOption(contact.Id, contact.LastName + ', ' + contact.FirstName + ' <' + contact.Email + '>'));
        }
        return options;
    }

    // See PartnerStatus_ObserveRequalWindow.trigger
    private boolean checkForRequal() {
        boolean requalIsInProgress = false;
        Account partner = [
            select  Id,
                    RequalStatus__c
            from    Account
            where   Id = :accountId
            limit   1
        ];
        System.debug('Requal Status: ' + partner.RequalStatus__c);
        if (partner.RequalStatus__c == 'Eligible' || partner.RequalStatus__c == 'In Progress' || partner.RequalStatus__c == 'Submitted') {
            requalIsInProgress = true;
        }
        return requalIsInProgress;
    }

    // Method to check if there are any pending partner tier change requests
    // before allowing the user to create any new ones.
    private boolean checkForOutstandingTierChangeRequests() {
        boolean hasPendingTierChange = false;
        List<Partner_Program_Approval__c> programApprovalList = [
            select  Account__c,
                    Program__c,
                    Status__c
            from    Partner_Program_Approval__c
            where   Status__c
            in      ('Pending', 'Draft', 'Hold')
            and     Program__c = :partnerProgramId
        ];
        System.debug('>>>>>>>>>> programApprovalList Size: ' + programApprovalList.size() + ' | ' + accountId);
        if (programApprovalList != null && programApprovalList.size() > 0) {
            hasPendingTierChange = true;
        }
        return hasPendingTierChange;
    }

    private boolean checkForPendingSCP() {
        Account partner = [
            select  Id, Finder_Partner_Type__c, Finder_Partner_Tier__c
            from    Account
            where   Id = :accountId
        ];

        System.debug('*****[debug]***** Partner_Type__c=' + partner.Finder_Partner_Type__c);
        System.debug('*****[debug]***** Partner_Tier__c=' + partner.Finder_Partner_Tier__c);

        if (partner.Finder_Partner_Type__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SERVICECLOUD_PROVIDER').ObjectId__c &&
            partner.Finder_Partner_Tier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.UNAFFILIATED').ObjectId__c) {
            System.debug('*****[debug]***** looking for registration info');
            Partner_Onboarding_Registration__c[] reg = [
                select  Id, HasCustomTerms__c, Agree_to_Partner_TC__c
                from    Partner_Onboarding_Registration__c
                where   ConvertedAccount__c = :accountId
                and     (HasCustomTerms__c = true or Agree_to_Partner_TC__c = true)
                limit 1
            ];
            if (reg.size () > 0) {
                System.debug('*****[debug]***** hascustomterms=' + reg[0].HasCustomTerms__c + ', agree_to_partner_tc__c=' + reg[0].Agree_to_Partner_TC__c);
            }
            return reg.size() == 0;   // nothing pending if no records returned
//            return reg.HasCustomTerms__c == false && reg.Agree_to_Partner_TC__c == false;
        }
        return false;
    }

    // This is called from the ChangePartnerTier page on load
    // to make sure that there are no reasons why a new tier
    // change request may not be created.
    public PageReference validatePendingTierChange() {
        if (checkForRequal()) {
            validationFailed = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'A tier change may not be requested for this program membership while its associated account is undergoing requalification.'));
        }
        if (checkForOutstandingTierChangeRequests()) {
            validationFailed = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This program membership already has a tier change request awaiting approval.'));
        }
        if (checkForPendingSCP()) {
            validationFailed = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This account is pending legal approval and cannot be changed'));
        }
        if (tiers == null || tiers.size() < 1) {
            validationFailed = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'There are no other tier options available for this program membership.'));
        }
        if (isUnaffiliated == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Primary program missing on account - tier change not possible'));
            return null;
        }
        if (isUnaffiliated) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Partner accounts designated with affiliated, ready, advanced or premier tiers must have Terms & Conditions attached in the terms section of the account. By clicking Save, you agree to attach the Terms & Conditions.'));
        }
        return null;
    }

    public List<SelectOption> getLanguages() {
        SelectOption[] options = new List<SelectOption>();
        options.add(new SelectOption('en', 'English'));
        options.add(new SelectOption('fr', 'French'));
        options.add(new SelectOption('de', 'German'));
        options.add(new SelectOption('it', 'Italian'));
        options.add(new SelectOption('es', 'Spanish'));
        options.add(new SelectOption('ja', 'Japanese'));
        options.add(new SelectOption('zh_CN', 'Chinese (Simplified)'));
        options.add(new SelectOption('ko', 'Korean'));
        options.add(new SelectOption('ru', 'Russian'));
        options.add(new SelectOption('pt_BR', 'Portuguse (Brazilian)'));
        return options;
    }

    public List<SelectOption> getAvailableTiers() {
        String tierString = partnerProgram.Program__r.Partner_Tier__c;
        List<SelectOption> options = new List<SelectOption>();
        if (tierString != null && tierString.contains(';')) {
            tierString = tierString.replace(partnerProgram.Tier__c + ';', '').replace(';' + partnerProgram.Tier__c, '');
            tiers = tierString.split(';');
            for (String tier : tiers) {
                options.add(new SelectOption(tier, tier));
            }
        } else {
            tiers.clear();
        }
        return options;
    }
}