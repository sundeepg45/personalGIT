public without sharing class PartnerGateway {

	public static final String ACTION_APPLY = 'apply';
	public static final String ACTION_JOIN = 'join';
    public static final String ACTION_CCNSP_CHECKLIST = 'ccnspcl';
    public static final String ACTION_CCNSP_TERMS = 'ccnspterms';
	public static final String ACTION_EMBED_TERMS = 'embedterms';
    public static final String ACTION_FCPA = 'fcpa';
	public static final String ACTION_PARF = 'parf';
	public static final String PARAM_PROGRAM = 'program';
    public static final String PARAM_ACTION = 'action';

    public String email {get; set; }

    private String action = null;
    private String program = null;
    public Boolean compliant {get; set; }
    private String federationId;
    private User   me;
    public Partner_Onboarding_Registration__c onb;
    public Case existingCase {get; private set; }
    public String existingCaseEmail {get; private set; }
    public Boolean missingAccount {get; private set; }
	public Boolean legalBlocked {get; private set; }



	public PageReference init() {
        missingAccount = false;
        compliant = True;
        legalBlocked = False;
        federationId = getParam(OnboardingApplyController.PARAM_FEDERATION_ID);
		program = getParam(PARAM_PROGRAM);
		action = getParam(PARAM_ACTION);

        if (federationId != null) {
            me = OnboardingUtils.getUserWithFederationId(federationId);
            onb = OnboardingUtils.getLeadWithFederationId(federationId);
            if (me == null) System.debug('****[debug]***** me is null');
            if (onb == null) System.debug('****[debug]***** Onboarding record is null');
        }

        if (action != null && action.startsWith(ACTION_CCNSP_CHECKLIST)) {
            // verify, then redirect to checklist
            if (me != null) {
                if (me.Contact.AccountId != null) {
                    Id enrollProgramId = [
                        select  Id
                        from    Partner_Program_Definition__c
                        where   Program_Category__c = :PartnerConst.CCNSP
                    ].Id;
                    PageReference ref = Page.CCSPForm;
                    String token = action.removeStart(ACTION_CCNSP_CHECKLIST);
                    ref.getParameters().put('token', token);
                    ref.getParameters().put('federationId', federationId);
                    ref.getParameters().put('enrollProgramId', enrollProgramId);
                    ref.setRedirect(true);
                    return ref;
                }
                // why is user trying to fill out the checklist after onboarding? Just ignore
            }
            else {
                PageReference ref = Page.CCSPForm;
                String token = action.removeStart(ACTION_CCNSP_CHECKLIST);
                ref.getParameters().put('token', token);
                ref.getParameters().put('federationId', federationId);
                ref.setRedirect(true);
                return ref;
            }
        }

        if (action != null && action.startsWith(ACTION_PARF)) {
            // verify, then redirect to checklist
            if (me != null) {
                if (me.Contact.AccountId != null) {
                    Id enrollProgramId = [
                        select  Id
                        from    Partner_Program_Definition__c
                        where   Program_Category__c = :PartnerConst.EMBED
						and 	Program_Status__c = 'Active'
                    ].Id;
                    PageReference ref = Page.PARF;
                    String token = action.removeStart(ACTION_PARF);
                    ref.getParameters().put('token', token);
                    ref.getParameters().put('federationId', federationId);
                    ref.getParameters().put('enrollProgramId', enrollProgramId);
                    ref.setRedirect(true);
                    return ref;
                }
                // why is user trying to fill out the checklist after onboarding? Just ignore
            }
            else {
                PageReference ref = Page.PARF;
                String token = action.removeStart(ACTION_PARF);
                ref.getParameters().put('token', token);
                ref.getParameters().put('federationId', federationId);
                ref.setRedirect(true);
                return ref;
            }
        }

        if (action != null && action.startsWith(ACTION_CCNSP_TERMS)) {
            // verify, then redirect to terms
            PageReference ref = Page.CCSP_Terms;
            String token = action.removeStart(ACTION_CCNSP_TERMS);
            ref.getParameters().put('token', token);
            ref.getParameters().put('federationId', federationId);
            ref.setRedirect(true);
            return ref;
        }

		if (action != null && action.startsWith(ACTION_EMBED_TERMS)) {
            // verify, then redirect to terms
            PageReference ref = Page.Embedded_Terms;
            String token = action.removeStart(ACTION_EMBED_TERMS);
            ref.getParameters().put('token', token);
            ref.getParameters().put('federationId', federationId);
            ref.setRedirect(true);
            return ref;
        }

        if (action != null && action.startsWith(ACTION_FCPA)) {
            PageReference ref = Page.FCPA_Questionnaire;
            String token = action.removeStart(ACTION_FCPA);
            ref.getParameters().put('token', token);
            ref.getParameters().put('federationId', federationId);
            ref.setRedirect(true);
            return ref;
        }

        //
        //US75121: redirect Embedded Partner with pending terms to Terms Page
        //

        //check if the user already exists
        if (me != null) {
            //check if the contact, Account, Onboarding record exists
            System.debug('[DEBUG*] User Exists: '+me.Id);
            if(me.Contact.AccountId != null && onb != null) {
                System.debug('[DEBUG*] Account for the user Exists: '+me.Contact.AccountId);
                System.debug('[DEBUG*] subType = '+ onb.Subtype__c +', stdTerms: '+onb.Agree_To_Partner_TC__c + ', CusTerms:' +onb.HasCustomTerms__c);
                System.debug('[DEBUG*]: User Declined Cust. Terms: ' +onb.User_Declined_Custom_Terms__c);
                //check the onboarding record exists and is embedded.
                if(onb.Subtype__c == PartnerConst.EMBEDDED && onb.Agree_To_Partner_TC__c == false && onb.HasCustomTerms__c == false) {
                    PartnerUser_Email_Token__c[] tkn = [SELECT Id, Email__c, Token__c
                                                        FROM PartnerUser_Email_Token__c
                                                        WHERE (Partner_onboarding__c = :onb.Id
                                                        OR Account__c = :me.contact.AccountId)
                                                        AND Is_Active__c = true
                                                        AND Notification_Type__c = 'Embedded Terms'
                                                        LIMIT 1];

                    if(tkn.size() > 0) {
                        System.debug('[DEBUG*] token =' +tkn[0].Id);
                        //redirect to terms page:
                        PageReference ref = Page.Embedded_Terms;
                        ref.getParameters().put('token', tkn[0].Token__c);
                        ref.getParameters().put('federationId', federationId);
                        ref.setRedirect(true);
                        return ref;
                    } else
                        System.debug('[DEBUG*]: NO Active Tokens with Embedded terms type Found for onboarding: ' +onb.Id);
                }
                // CCSP/ SCP Onboarding
                if((onb.partner_type__r.Name == PartnerConst.SCP || onb.Subtype__c == PartnerConst.CCNSP) &&
                    onb.Agree_To_Partner_TC__c == false &&
                    onb.HasCustomTerms__c == false && onb.User_Declined_Custom_Terms__c == false) {
                    PartnerUser_Email_Token__c[] tkn = [SELECT Id, Email__c, Token__c
                                                        FROM PartnerUser_Email_Token__c
                                                        WHERE Partner_onboarding__c = :onb.Id
                                                        AND Notification_Type__c = 'CCSP Terms'
                                                        AND Is_Active__c = true
                                                        LIMIT 1];
                    if(tkn.size() > 0) {
                        //redirect to terms page:
                        PageReference ref = Page.CCSP_Terms;
                        ref.getParameters().put('token', tkn[0].Token__c);
                        ref.getParameters().put('federationId', federationId);
                        ref.setRedirect(true);
                        return ref;
                    } else
                        System.debug('[DEBUG*]: NO Active Tokens with CCSP terms type Found for onboarding: ' +onb.Id);
                }
            }
        }


        if ((action == ACTION_APPLY || action == ACTION_JOIN) && me != null) {
            System.debug('*****[debug]***** isactive='  +me.IsActive);
            if (me.isActive) {
                //
                // Logged in to redhat.com and salesforce. Catch duplicate registrations
                //
                PageReference ref = Page.OnboardingUserAssociatedError;
                ref.setRedirect(true);
                return ref;
            }

        }
		if (action == ACTION_APPLY && federationId != null) {
			//
			// Logged in to redhat.com and requesting to onboard
			//
			PageReference ref = Page.OnboardingApply;
            copyParams(ApexPages.currentPage(), ref);
            ref.setRedirect(true);
			return ref;
		}
		if (action == ACTION_JOIN && federationId != null) {
			//
			// Logged in to redhat.com and requesting to join
			//
            PageReference page = new PageReference('/apex/OnboardingJoin');
            copyParams(ApexPages.currentPage(), page);
            return page;
		}

        if (federationId != null) {
            if (me != null && me.Contact != null && me.Contact.AccountId != null) {
                legalBlocked = Partner_State_Wrapper.isLegalBlocked(me.Contact.AccountId);
            }
			if (me == null || me.isActive == false || legalBlocked) {
				if (!legalBlocked) {
					//
					// does not exist in salesforce, get more direction from user
					//
	                missingAccount = true;
				}
                return null;
			}

			//
			// active user, update user details then send on to salesforce via SSO
			//
            updateUserFields(me);

            if (!isCompliantEmail(me)) {
                if (allowedLogins == 0) {
                    // deactivate deadbeat user, send to onboarding to handle case submit page
                    me.IsActive = false;
                    update me;
                    PageReference page = new PageReference('/apex/OnboardingJoin');
                    copyParams(ApexPages.currentPage(), page);
                    return page;
                }
                // oops, send to warning page
                email = me.Email;
                return new PageReference('/apex/PartnerEmailNotice');
            }

            existingCase = OnboardingUtils.getOnboardingCaseForAccountOrUser(me.Contact.AccountId, federationId);
            if (existingCase != null) {
                existingCaseEmail = OnboardingUtils.CASE_OWNER_QUEUE_EMAIL.get(existingCase.Owner.Name);
                PageReference ref = new PageReference('/apex/PartnerAccessCaseView');
                return ref;
            }

            PageReference page = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/protected/federate.html');
            //copyParams(ApexPages.currentPage(), page);
            page.setRedirect(true);
            return page;
        }
		return null;
	}



    public Integer allowedLogins {
        get {
            if (me.Compliant_Email_Notices__c == null) me.Compliant_Email_Notices__c = 0;
            return (Integer) (3 - me.Compliant_Email_Notices__c);
        }
    }

    public String[] getAllowedDomainList() {
        if (me != null) {
            return me.Contact.Account.AllowedEmailDomains__c.split(';');
        }
        return new String[0];
    }

    public PageReference goLogin() {
        me.Compliant_Email_Notices__c += 1;
        update me;
        PageReference page = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/protected/federate.html');
        page.setRedirect(true);
        return page;
    }

    public PageReference updateEmail() {
        me.Email = email;
        compliant = True;
        if (!isCompliantEmail(me)) {
            compliant = False;
            return null;
        }
        update me;
        Contact cme = new Contact(Id = me.ContactId, Email = email);
        update cme;
        PageReference page = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/protected/federate.html');
        page.setRedirect(true);
        return page;
    }

    private Boolean isCompliantEmail(User me) {
        if (me == null) return false;
        String email = me.Email;
        String domain = email.substring(email.indexOf('@') + 1, email.length()).toLowerCase();
        if (me.Contact.Account.AllowedEmailDomains__c == null) {
            return true;
        }
        String[] allowed = me.Contact.Account.AllowedEmailDomains__c.split(';');
        //
        // first, try the original way
        //
        for (String allow : allowed) {
            if (domain.endsWith(allow.trim())) {
                return true;
            }
//            if (allow.trim().endsWith(domain)) {
//                return true;
//            }
        }
        //
        // now try by chopping up the dotted parts of the domain
        //
//        Integer first = domain.indexOf('.');
//        while (first > 0) {
//            domain = domain.substring(first + 1, domain.length());
//            for (String allow : allowed) {
//                if (allow.trim().endsWith(domain)) {
//                    return true;
//                }
//            }
//            first = domain.indexOf('.');
//        }

        return false;
    }

    private void updateUserFields(User user) {
        if (user == null) return;
        String code = getLanguageLocaleCode(user);
        if (user.LanguageLocaleKey != code) {
            user.LanguageLocaleKey = code;
            updateUserLocaleKey(user.Id, code);
        }
        postOnboardingUpdates(user.AccountId, user.id, user.Contact.Id);
    }

    private static void updateUserLocaleKey(Id userId, String localeKey) {
        User user = new User(Id = userId);
        user.LanguageLocaleKey = localeKey;
        if (!Test.isRunningTest()) {
            update user;
        }
    }

    @future
    private static void postOnboardingUpdates(Id accountId, Id userId, Id contactId) {
        // Post onboarding updates
        Account a = [select PrimaryPartnerUser__c from Account where id = :accountId];
        if (a.PrimaryPartnerUser__c == null) {
            a.PrimaryPartnerUser__c = userId;
            update a;
            try {
                NFR_Request__c nfr = [select id, ownerid, Contact_at_Partner__c from NFR_Request__c where Contact_at_Partner__c = :contactId and ownerid != :userId];
                nfr.ownerid = userId;
                update nfr;
            } catch (System.QueryException qE){
                System.debug('Error loading query ' + qE.getMessage());
            }
        }
    }

    private static boolean isValidLocale(String localeKey, List<Schema.PicklistEntry> locales) {
        for (Schema.PicklistEntry locale : locales) {
            if (locale.getValue() == localeKey) {
                return true;
            }
        }
        return false;
    }

    private String getLanguageLocaleCode(User user) {
        Schema.DescribeFieldResult f = Schema.SObjectType.User.fields.LanguageLocaleKey;
        String languageCode = getParam(OnboardingApplyController.PARAM_LANGUAGE);
        if (languageCode == null) {
            languageCode = 'en';
        }
        String language = getLocalePicklistName(languageCode, null);
        List<Schema.PicklistEntry> locales = f.getPicklistValues();
        if (isValidLocale(LanguageCode, locales)) {
            return languageCode;
        }
        String localeKey = languageCode;
        if (user.Contact.MailingCountry == null || user.Contact.MailingCountry.length() != 2) {
            if (user.Contact.Account.BillingCountry != null && user.Contact.Account.BillingCountry.length() == 2) {
                localeKey = LanguageCode + '_' + user.Contact.Account.BillingCountry;
            }
            else {
                System.debug('** Valid country not found.  This should never happen');
                return 'en_US';
            }
        }
        else {
            localeKey = LanguageCode + '_' + user.Contact.MailingCountry;
        }
        if (!isValidLocale(localeKey, locales)) {
            if (localeKey.startsWith('zh')){
                localeKey = 'zh_CN';
            }
            if (!isValidLocale(localeKey, locales) && localeKey.startsWith('pt')){
                localeKey = 'pt_BR';
            }
            if (!isValidLocale(localeKey, locales)) {
                localeKey = 'en_US';
            }
        }
        return localeKey;
    }

    private String getLocalePicklistName(String localeCode, String defaultName) {
        if (localeCode == null) {
            return (defaultName != null) ? defaultName : 'en';
        }
        localeCode = localeCode.toLowerCase();
        Map<String,String> listmap = new Map<String,String> {
            'en'    => 'English',
            'zh_TW' => 'Chinese',
            'zh_tw' => 'Chinese',
            'zh_CN' => 'Chinese (simplified)',
            'zh_cn' => 'Chinese (simplified)',
            'zh'    => 'Chinese (simplified)',
            'ja'    => 'Japanese',
            'pt_BR' => 'Portuguese',
            'pt'    => 'Portuguese',
            'ko'    => 'Korean',
            'de'    => 'German',
            'es'    => 'Spanish',
            'fr'    => 'French',
            'it'    => 'Italian',
            'ru'    => 'Russian'
        };
        for (String key : listmap.keySet()) {
            if (localeCode.startsWith(key)) {
                return listmap.get(key);
            }
        }
        return (defaultName != null) ? defaultName : 'en';
    }

    private void copyParams(PageReference fromPage, PageReference toPage) {
        for (String key : fromPage.getParameters().keySet()) {
            toPage.getParameters().put(key, fromPage.getParameters().get(key));
        }
    }

/*
    private String thisPage() {
        String host = thisHost();
        String url = ApexPages.currentPage().getUrl();
        return 'https://' + host + url;
    }

    private String thisHost() {
        return ApexPages.currentPage().getHeaders().get('Host');
    }
*/

    public PageReference handleOnboardApply() {
        PageReference ref = Page.OnboardingApply;
        copyParams(ApexPages.currentPage(), ref);
        ref.setRedirect(true);
        return ref;
    }

    public PageReference handleOnboardJoin() {
        PageReference ref = Page.OnboardingJoin;
        copyParams(ApexPages.currentPage(), ref);
        ref.setRedirect(true);
        return ref;
    }

	public PageReference handleLogin() {
        PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/login.html');
        String redir = '/wapps/sfconnector/protected/partner.html';
        String params = passthruParams();
        if (params != null) redir += params;
        pageReference.getParameters().put('redirect', redir);
        pageReference.setRedirect(true);
        return pageReference;
	}

    private String passthruParams() {
        String[] params = new List<String>();
        if (action != null) params.add(PARAM_ACTION + '=' + action);
        if (program != null) params.add(PARAM_PROGRAM + '=' + program);
        String paramlist = PartnerUtil.joinArray(params, '&');
        if (paramlist.length() > 0) {
            return EncodingUtil.urlEncode('?' + paramlist, 'UTF-8');
        }
        return null;
    }

    public PageReference handleRegister() {
        PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/ugc/register.html');
        String redir = '/wapps/sfconnector/protected/partner.html';
        String params = passthruParams();
        if (params != null) redir += params;
        pageReference.getParameters().put('redirect', redir);
        pageReference.setRedirect(true);
        return pageReference;
    }

    private Contact getContactWithFederationId(String fedid) {
        Contact contact = null;
        if (federationId != null && [select count() from Contact where LoginName__c = :fedid and Contact.Account.IsPartner = true] > 0) {
            contact = [
                select id
                     , LoginName__c
                     , AccountId
                     , Name
                     , Account.BillingCountry
                  from Contact
                 where LoginName__c = :fedid
                        and Contact.Account.IsPartner = true
                 limit 1
            ];
        }
        return contact;
    }

    public static String getParam(String name) {
        return ApexPages.currentPage().getParameters().get(name);
    }
}