public without sharing class PARFController {

	public PARF_Form__c parf 											{get; set;}
	public List<PARFProductWrapper> parfProducts 						{get; set;}
	public PARF_Product__c parfProduct 									{get; set;}
	public Integer productToDelete 										{get; set;}
	public String prodName												{get; set;}
	public String prodDesc												{get; set;}
	public String prodURL												{get; set;}
	public Partner_Onboarding_Registration__c onboardingRegistration	{get; private set;}
	public String federationId 											{get; private set;}
	public boolean addingNewProduct 									{get; private set;}
	public boolean showRequiredMessage 									{get; private set;}
	public boolean showProdDetsReqMessage								{get; private set;}
	public boolean isGuestUser                              			{get; private set;} // Prospective, not yet onboarded partner.
    public boolean isDistributor                            			{get; private set;} // Distributor referring a new/existing partner to Embedded.
    public boolean isRedHatUser                             			{get; private set;} // Red Hat user referring a new/existing partner to Embedded.
    public boolean isPartner                                			{get; private set;} // Existing partner being referred to or enrolling in Embedded.
	public boolean alreadyEnrolled                          			{get; private set;}
    public boolean inProgress                               			{get; private set;}
	public boolean isSelfEnrolling										{get; private set;}
	public boolean isEditable											{get; private set;}
	public boolean governmentPositionAnswered               			{get; private set;}
    public boolean convictedAnswered                       				{get; private set;}
    public boolean underlyingFactsProvided                  			{get; private set;}
	public String style				                                    {get; private set;}
	public String submitConfirmMessage							{get; private set;}
	public String submitButtonLabel										{get; private set;}
	public String parfTitle												{get; private set;}
	public Account partnerAccount										{get; private set;}

	private Id onboardingRegistrationId;
    private Id enrollProgramId;
	private Id standardOnboardingRecordTypeId;
	private Id partnerAccountId;
	private Id parfFormId;

	private PartnerUser_Email_Token__c emailToken;

	private boolean parfIsNew;

	private String token;
	private String retURL;

	private List<PARF_Product__c> products;

    public static final Map<String, List<Schema.PicklistEntry>> PICKLIST_ENTRIES = new Map<String, List<Schema.PicklistEntry>> {
        'Desired_RH_Prod_Desc__c' => PARF_Form__c.Desired_RH_Prod_Desc__c.getDescribe().getPicklistValues()
    };

	public PARFController(ApexPages.StandardController stdController) {
        parfFormId = stdController.getId();
    }

	public void init() {

		parf = new PARF_Form__c();
		parfProduct = new PARF_Product__c();
		parfProducts = new List<PARFProductWrapper>();

		addingNewProduct = true;
		showRequiredMessage = false;
		showProdDetsReqMessage = false;
		isSelfEnrolling = false;
		isEditable = true;

		federationId = ApexPages.currentPage().getParameters().get('federationId');
		partnerAccountId = (Id)ApexPages.currentPage().getParameters().get('accountId');
		enrollProgramId = (Id)ApexPages.currentPage().getParameters().get('enrollProgramId');
		onboardingRegistrationId = (Id)ApexPages.currentPage().getParameters().get('onboardingId');
		token = ApexPages.currentPage().getParameters().get('token');
		retURL = ApexPages.currentPage().getParameters().get('retURL');

		submitConfirmMessage = System.Label.CCSPForm_Are_You_Sure_to_Red_Hat;
		submitButtonLabel = System.Label.Submit;

		parfTitle = System.Label.PARF_Title;

		// If coming in from the public site, use the token to get the
        // onboarding registration record.
        if (!String.isEmpty(token)) {
        	emailToken = [
                select  Id,
                        Date_Confirmed__c,
                        Is_Active__c,
                        Partner_Onboarding__c,
                        Token__c
                from    PartnerUser_Email_Token__c
                where   Token__c = :token
                and     Is_Active__c = true
                limit   1
            ];
            onboardingRegistrationId = emailToken.Partner_Onboarding__c;
            if (emailToken.Date_Confirmed__c == null) {
                emailToken.Date_Confirmed__c = Datetime.now();
                update emailToken;
            }
        }

		standardOnboardingRecordTypeId = [
			select  Id
			from    RecordType
			where   SObjectType = 'Partner_Onboarding_Registration__c'
			and     DeveloperName = 'Business_Partner_Registration'
		].Id;

	    // Determine what kind of user is interacting with the PARF.
	    isDistributor = false;
	    isPartner = false;
	    isGuestUser = false;

		User me = new User();
		if (String.isEmpty(federationId)) {
			me = [
		    	select  Id,
						Contact.AccountId,
						Contact.LoginName__c,
						Name,
						Email,
						Phone,
						Profile.Name
		        from    User
		        where   Id = :UserInfo.getUserId()
		        limit   1
		    ];
		} else {
			List<User> users = [
		    	select  Id,
		                Contact.AccountId,
						Contact.LoginName__c,
		                Name,
		                Email,
		                Phone,
		                Profile.Name
		        from    User
		        where   Contact.LoginName__c = :federationId
		        limit   1
		    ];
			if (users != null && users.size() > 0) {
				me = users[0];
			}
			isGuestUser = true;
		}

		if (String.isEmpty(partnerAccountId)) {
			partnerAccountId = me.Contact.AccountId;
		}

	    // If we know we need to enroll instead of onboard,
	    // must be an existing partner.
	    if (!String.isEmpty(enrollProgramId)) {
	        isPartner = true;
	        isGuestUser = true; // Needed for consistency in formatting the PARF page.
	    }

		// If an account is present and not self-enrolling, must be a distributor.
		if (me.Contact.AccountId != null) {
			isPartner = true;
            Account myacct = [select Finder_Partner_Type__c from Account where Id = :me.Contact.AccountId];
            if (myacct.Finder_Partner_Type__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.DISTRIBUTOR').ObjectId__c) {
                isDistributor = true;
            }
		}

		if (isPartner && !isDistributor) {
	        isSelfEnrolling = true;
	    }

		if (!String.isEmpty(federationId)) {
			isGuestUser = true;
		}

	    // If nothing else, must be a Red Hat user.
	    isRedHatUser = (!isDistributor && !isPartner && !isGuestUser);
		if (isRedHatUser || isDistributor) {
			submitConfirmMessage = System.Label.Embedded_AreYouSurePartner;
		}

		System.debug('Is a partner: ' + isPartner);
		System.debug('Is a distributor: ' + isDistributor);
		System.debug('Is a guest user: ' + isGuestUser);
		System.debug('Is a Red Hat user: ' + isRedHatUser);
		System.debug('Is self-enrolling: ' + isSelfEnrolling);

		if (isSelfEnrolling) {
			List<Partner_Onboarding_Registration__c> ors = [
				select		Id,
							RHNLogin__c,
							Subtype__c,
							FirstName__c,
							LastName__c,
							Email__c,
							Company__c,
							LastModifiedDate,
							Created_By_User_Type__c,
							Do_they_act_in_any_government_position__c,
							Have_they_been_convicted__c,
							FCPA_Underlying_Facts__c
				from    	Partner_Onboarding_Registration__c
				where   	ConvertedAccount__c = :me.Contact.AccountId
				order by 	LastModifiedDate desc
				limit 1
			];

			if (ors != null && ors.size() > 0) {
				onboardingRegistration = ors[0];
			}
		}

		if (onboardingRegistrationId != null && !isSelfEnrolling) {
			List<Partner_Onboarding_Registration__c> ors = [
				select		Id,
							RHNLogin__c,
							Subtype__c,
							FirstName__c,
							LastName__c,
							Email__c,
							Company__c,
							LastModifiedDate,
							Created_By_User_Type__c,
							Do_they_act_in_any_government_position__c,
							Have_they_been_convicted__c,
							FCPA_Underlying_Facts__c
				from    	Partner_Onboarding_Registration__c
				where   	Id = :onboardingRegistrationId
				order by 	LastModifiedDate desc
				limit 1
			];

			if (ors != null && ors.size() > 0) {
				onboardingRegistration = ors[0];
			}
		}

		if (onboardingRegistration == null && !isPartner && isGuestUser && federationId != null) {
			List<Partner_Onboarding_Registration__c> ors = [
				select		Id,
							RHNLogin__c,
							Subtype__c,
							FirstName__c,
							LastName__c,
							Email__c,
							Company__c,
							LastModifiedDate,
							Created_By_User_Type__c,
							Do_they_act_in_any_government_position__c,
							Have_they_been_convicted__c,
							FCPA_Underlying_Facts__c
				from    	Partner_Onboarding_Registration__c
				where   	RHNLogin__c = :federationId
				order by 	LastModifiedDate desc
				limit 1
			];
			if (ors != null && ors.size() > 0) {
				onboardingRegistration = ors[0];
				onboardingRegistrationId = onboardingRegistration.Id;
			}
		}

		// if (onboardingRegistration != null) {
		// 	parf.Government_Position__c = onboardingRegistration.Do_they_act_in_any_government_position__c;
		// 	parf.Convicted__c = onboardingRegistration.Have_they_been_convicted__c;
		// 	parf.Underlying_Facts__c = onboardingRegistration.FCPA_Underlying_Facts__c;
		// 	parf.Partner_Onboarding_Record__c = onboardingRegistration.Id;
		// 	parf.Program_Contact__c = onboardingRegistration.FirstName__c + ' ' + onboardingRegistration.LastName__c;
		// 	parf.Program_Contact_Email__c = onboardingRegistration.Email__c;
		// }

	    if (!String.isEmpty(partnerAccountId)) {
	        partnerAccount = [
	            select  Id,
						Name,
	                    Finder_Partner_Type__c,
	                    Partner_Onboarding_Application__c
	            from    Account
	            where   Id = :partnerAccountId
	            limit   1
	        ];
	        if (!String.isEmpty(partnerAccount.Partner_Onboarding_Application__c) && !isSelfEnrolling) {
	            onboardingRegistrationId = partnerAccount.Partner_Onboarding_Application__c;
	        }
	    }

		// if (isSelfEnrolling) {
		// 	parf.Program_Contact__c = me.Name;
		// 	parf.Program_Contact_Email__c = me.Email;
		// 	parf.Account__c = me.Contact.AccountId;
		// }

	    style = (isGuestUser ? 'display:inline' : 'display:none');

        List<Partner_Program__c> embeddedEnrolledProgramMemberships = [
            select  Id
            from    Partner_Program__c
            where   Account__c = :partnerAccountId
            and     Program__c = :enrollProgramId
            and     Status__c in ('Active')
        ];

        List<Partner_Program__c> embeddedInProgressProgramMemberships = [
            select  Id
            from    Partner_Program__c
            where   Account__c = :partnerAccountId
            and     Program__c = :enrollProgramId
            and     Status__c in ('Approved', 'Pending', 'Pending Terms', 'Pending First Approver')
        ];

        alreadyEnrolled = (embeddedEnrolledProgramMemberships.size() > 0);
        inProgress = (embeddedInProgressProgramMemberships.size() > 0) && !alreadyEnrolled;
		//
		// if (partnerAccountId != null) {
		// 	parf.Account__c = partnerAccountId;
		// }

        if (onboardingRegistration != null && !isPartner && !isSelfEnrolling) {
            governmentPositionAnswered = !String.isEmpty(onboardingRegistration.Do_they_act_in_any_government_position__c);
            convictedAnswered = !String.isEmpty(onboardingRegistration.Have_they_been_convicted__c);
            underlyingFactsProvided = !String.isEmpty(onboardingRegistration.FCPA_Underlying_Facts__c);
        }

        if (isPartner) {
            governmentPositionAnswered = true;
            convictedAnswered = true;
        }

        if (!String.isEmpty(federationId) && !isPartner && !isSelfEnrolling) {
            onboardingRegistration.RHNLogin__c = federationId;
            // update onboardingRegistration;
        }

		List<PARF_Form__c> parfs = new List<PARF_Form__c>();

		if (!String.isEmpty(parfFormId)) {
            parfs = [
                select  Id,
						Account__c,
						Contact_Preferred_Language__c,
						Custom_Terms_Required__c,
						Desired_RH_Prod_Desc__c,
						Distributor_Directed__c,
						EDP_Email__c,
						EDP_Name__c,
						Admin_Contact__c,
						Partner_Onboarding_Record__c,
						Program_Contact__c,
						Program_Contact_Email__c,
						Program_Membership__c,
						RH_ISV_Embedded_Rep__c,
						Send_Email_to_Distributor__c,
						Status__c,
						Government_Position__c,
						Convicted__c,
						Underlying_Facts__c
                from    PARF_Form__c
                where   Id = :parfFormId
                limit   1
            ];
        } else if (isSelfEnrolling && isPartner && !isDistributor) {
			parfs = [
                select  Id,
						Account__c,
						Contact_Preferred_Language__c,
						Custom_Terms_Required__c,
						Desired_RH_Prod_Desc__c,
						Distributor_Directed__c,
						EDP_Email__c,
						EDP_Name__c,
						Admin_Contact__c,
						Partner_Onboarding_Record__c,
						Program_Contact__c,
						Program_Contact_Email__c,
						Program_Membership__c,
						RH_ISV_Embedded_Rep__c,
						Send_Email_to_Distributor__c,
						Status__c,
						Government_Position__c,
						Convicted__c,
						Underlying_Facts__c
                from    PARF_Form__c
                where   Account__c = :partnerAccountId
                limit   1
            ];
		} else {
            parfs = [
                select  Id,
						Account__c,
						Contact_Preferred_Language__c,
						Custom_Terms_Required__c,
						Desired_RH_Prod_Desc__c,
						Distributor_Directed__c,
						EDP_Email__c,
						EDP_Name__c,
						Admin_Contact__c,
						Partner_Onboarding_Record__c,
						Program_Contact__c,
						Program_Contact_Email__c,
						Program_Membership__c,
						RH_ISV_Embedded_Rep__c,
						Send_Email_to_Distributor__c,
						Status__c,
						Government_Position__c,
						Convicted__c,
						Underlying_Facts__c
                from    PARF_Form__c
                where   Partner_Onboarding_Record__c = :onboardingRegistrationId
                limit   1
            ];
        }

		if (parfs != null && parfs.size() > 0) {
			parf = parfs[0];
			parfIsNew = false;
			if ((parf.Status__c != null && parf.Status__c.equalsIgnoreCase('User Notified')) && isRedHatUser) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.Embedded_ThisApplicationHasAlreadyBeenSent));
				submitConfirmMessage = System.Label.Embedded_AreYouSureUpdate;
				submitButtonLabel = System.Label.Embedded_Update;
			}
			onboardingRegistrationId = parf.Partner_Onboarding_Record__c;
			// Load the parf products.
			products = [
				select 	Id,
						Account__c,
						Desired_RH_Prod_Desc__c,
						PARF_Form__c,
						Product_Description__c,
						Product_Name__c,
						Product_URL__c
				from 	PARF_Product__c
				where 	PARF_Form__c = :parf.Id
			];
			for (PARF_Product__c product : products) {
				parfProducts.add(new PARFProductWrapper(parfProducts.size(), product));
			}
			if (isDistributor && parf.Status__c != null && (parf.Status__c.equalsIgnoreCase('Complete') || parf.Status__c.equalsIgnoreCase('User Notified'))) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.Embedded_ThisApplicationHasAlreadyBeenSent));
				isEditable = false;
				parfTitle = '';
			} else if (parf.Status__c != null && parf.Status__c.equalsIgnoreCase('Complete')) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.Embedded_ThisApplicationHasBeenCompleted));
				// Internal users must still be able to edit PARF to specify if
				// custom terms are requested, but distributors do not.
				submitConfirmMessage = System.Label.Embedded_AreYouSureUpdate;
				submitButtonLabel = System.Label.Embedded_Update;
			}
		} else {
			parfIsNew = true;
            parf.Status__c = 'Draft';
            if (isDistributor) {
                Id contactId = [
                    select  ContactId
                    from    User
                    where   Id = :UserInfo.getUserId()
                    limit   1
                ].ContactId;

                Id referringAccountId = [
                    select  AccountId
                    from    Contact
                    where   Id = :ContactId
                    limit   1
                ].AccountId;

                Account account = [
                    select  Id,
                            Name
                    from    Account
                    where   Id = :referringAccountId
                    limit   1
                ];

                parf.Distributor_Directed__c = System.Label.yes;
                parf.EDP_Name__c = account.Name;
				parf.EDP_Email__c = UserInfo.getUserEmail();
            }
			parf.Partner_Onboarding_Record__c = null;
            if (!isSelfEnrolling && !isPartner && onboardingRegistrationId != null) {
                parf.Partner_Onboarding_Record__c = onboardingRegistrationId;
        	}
		}

		if (onboardingRegistration != null) {
			parf.Government_Position__c = onboardingRegistration.Do_they_act_in_any_government_position__c;
			parf.Convicted__c = onboardingRegistration.Have_they_been_convicted__c;
			parf.Underlying_Facts__c = onboardingRegistration.FCPA_Underlying_Facts__c;
			parf.Partner_Onboarding_Record__c = null;
			if (!isSelfEnrolling) {
				parf.Partner_Onboarding_Record__c = onboardingRegistration.Id;
			}
			parf.Program_Contact__c = onboardingRegistration.FirstName__c + ' ' + onboardingRegistration.LastName__c;
			parf.Program_Contact_Email__c = onboardingRegistration.Email__c;
		}

		if (isSelfEnrolling) {
			parf.Program_Contact__c = me.Name;
			parf.Program_Contact_Email__c = me.Email;
			parf.Account__c = me.Contact.AccountId;
		}

		if (partnerAccountId != null && !isDistributor) {
			parf.Account__c = partnerAccountId;
		}
	}

	public PageReference submit() {
		Boolean isProspectivePartnerUserAndDistiLedNotSpecified = parf.Distributor_Directed__c == null && !isRedHatUser && !isDistributor;
		Boolean isDistiLedButNoDistiSpecified = (parf.Distributor_Directed__c != null && parf.Distributor_Directed__c.equalsIgnoreCase('Yes')) && ((parf.EDP_Name__c == null) || (parf.EDP_Email__c == null));
		// Boolean isCompleteButCustomTermsReqNotSpecified = parf.Status__c.equalsIgnoreCase('Complete') && parf.Custom_Terms_Required__c == null;
		Boolean isFCPANotAnswered = !isSelfEnrolling && !isRedHatUser && !isDistributor && ((String.isEmpty(parf.Government_Position__c) || String.isEmpty(parf.Convicted__c)) || ((parf.Government_Position__c.equalsIgnoreCase('Yes') || parf.Convicted__c.equalsIgnoreCase('Yes')) && String.isEmpty(parf.Underlying_Facts__c)));
		System.debug('isProspectivePartnerUserAndDistiLedNotSpecified: ' + isProspectivePartnerUserAndDistiLedNotSpecified);
		System.debug('isDistiLedButNoDistiSpecified: ' + isDistiLedButNoDistiSpecified);
		System.debug('isFCPANotAnswered: ' + isFCPANotAnswered);
		if (isProspectivePartnerUserAndDistiLedNotSpecified || isDistiLedButNoDistiSpecified || isFCPANotAnswered) {
			showRequiredMessage = true;
			showProdDetsReqMessage = false;
			return null;
		} else {
			if (parf.Distributor_Directed__c != null && parf.Distributor_Directed__c.equalsIgnoreCase('No')) {
				parf.EDP_Name__c = '';
				parf.EDP_Email__c = '';
			}
			if (parfIsNew) {
				insert parf;
			}
			if (parf.Status__c != null && parf.Status__c.equalsIgnoreCase('Draft')) {
				parf.Status__c = 'Pending';
			}
			update parf;
			List<PARF_Product__c> productsToBeInserted = new List<PARF_Product__c>();
			for (PARFProductWrapper product : parfProducts) {
				productsToBeInserted.add(product.product);
			}
			for (PARF_Product__c parfProduct : productsToBeInserted) {
				parfProduct.PARF_Form__c = parf.Id;
				parfProduct.Desired_RH_Prod_Desc__c = parf.Desired_RH_Prod_Desc__c;
			}
			if (products != null && products.size() > 0) {
				delete products;
			}
			insert productsToBeInserted;
			if (!isRedHatUser && !isDistributor) { // Apply onboarding or enrolling.
				if (emailToken != null) {
					emailToken = [
		                select  Id,
		                        Date_Confirmed__c,
		                        Is_Active__c,
		                        Partner_Onboarding__c,
		                        Token__c
		                from    PartnerUser_Email_Token__c
		                where   Token__c = :token
		                and     Is_Active__c = true
		                limit   1
		            ];
					emailToken.Is_Active__c = false;
					update emailToken;
				}
				if (!isSelfEnrolling) {
					onboardingRegistration.RecordTypeId = standardOnboardingRecordTypeId;
		            if (!governmentPositionAnswered) {
		                onboardingRegistration.Do_they_act_in_any_government_position__c = parf.Government_Position__c;
		            }
		            if (!convictedAnswered) {
		                onboardingRegistration.Have_they_been_convicted__c = parf.Convicted__c;
		            }
		            if (!underlyingFactsProvided) {
		                onboardingRegistration.FCPA_Underlying_Facts__c = parf.Underlying_Facts__c;
		            }
					update onboardingRegistration;
					Id pId = parf.Id;
					parf = [
						select 	Id,
								Status__c
						from 	PARF_Form__c
						where 	Id = :parf.Id
						limit 	1
					];
					parf.Status__c = 'Complete';
					update parf;
				} else {
					if (!alreadyEnrolled && !inProgress) {
						parf.Status__c = 'Complete';
						update parf;
	                    PartnerPgmDashController ppdController = new PartnerPgmDashController();
	                    ppdController.init(federationId);
	                    return ppdController.enrollEmbedded(enrollProgramId, parf.Id);
	                }
				}
				return new PageReference('/partner/OnboardingApplyEmbeddedThankYou');
			}
			if (onboardingRegistration != null) {
				onboardingRegistration.RecordTypeId = standardOnboardingRecordTypeId;
				update onboardingRegistration;
			}
			System.debug('Onboarding Registration Id: ' + onboardingRegistrationId);
			if (!String.isEmpty(retURL)) {
				return new PageReference(retURL);
			}
			return new PageReference('/' + onboardingRegistrationId);
		}
	}

	public PageReference cancel() {
		if (isPartner) {
            return new PageReference('/apex/PartnerPrograms');
        }
		if (onboardingRegistration != null && isGuestUser && !isDistributor && !isPartner && !isSelfEnrolling && onboardingRegistration.Created_By_User_Type__c.equalsIgnoreCase('User')) {
			delete onboardingRegistration;
		}
		if (isRedHatUser) {
			if (parfIsNew) {
				insert parf;
			}
			if (!String.isEmpty(retURL)) {
				return new PageReference(retURL);
			}
			if (onboardingRegistrationId != null) {
				return new PageReference('/' + onboardingRegistrationId);
			}
			return null;
		}
		return new PageReference('/partner/');
	}

	public boolean moreProductsAllowed {
		get {
			return parfProducts.size() < 10;
		}
	}

	public boolean parfProductsExist {
		get {
			return parfProducts.size() > 0;
		}
	}

	public void addProduct() {
		// parfProduct = new PARF_Product__c();
		addingNewProduct = true;
	}

	public void save() {
		if (!String.isEmpty(prodName) && !String.isEmpty(prodDesc)) {
			// addingNewProduct = false;
			parfProduct = new PARF_Product__c();
			parfProduct.Product_Name__c = prodName;
			parfProduct.Product_Description__c = prodDesc;
			parfProduct.Product_URL__c = prodURL;
			parfProducts.add(new PARFProductWrapper(parfProducts.size(), parfProduct));
			prodName = '';
			prodDesc = '';
			prodURL = '';
			showProdDetsReqMessage = false;
		} else {
			showProdDetsReqMessage = true;
		}
	}

	public void cancelProduct() {
		// addingNewProduct = false;
		showRequiredMessage = false;
	}

	public void deleteProduct() {
		parfProducts.remove(productToDelete);
		Integer index = 0;
		for (PARFProductWrapper product : parfProducts) {
			product.index = index;
			index++;
		}
		if (parfProducts.size() < 1) {
			addingNewProduct = true;
		}
	}

	class PARFProductWrapper {
		public Integer index {get; set;}
		public PARF_Product__c product {get; set;}

		public PARFProductWrapper(Integer index, PARF_Product__c product) {
			this.index = index;
			/* We instantiate a new product object and populate all the values
			explicitly so that we can delete all the existing PARF Products and
			then re-add them without getting DML errors.*/
			this.product = new PARF_Product__c();
			this.product.Account__c = product.Account__c;
			this.product.Desired_RH_Prod_Desc__c = product.Desired_RH_Prod_Desc__c;
			this.product.PARF_Form__c = product.PARF_Form__c;
			this.product.Product_Description__c = product.Product_Description__c;
			this.product.Product_Name__c = product.Product_Name__c;
			this.product.Product_URL__c = product.Product_URL__c;
		}
	}

    public List<String> getSplitPicklistField(String values) {
        return values == null ? new List<String>() : values.split(';');
    }

    public List<SelectOption> getSelectOptions(List<Schema.PicklistEntry> picklistEntryList) {
        List<SelectOption> selectOptionList = new List<SelectOption>();

        for(Schema.PicklistEntry p : picklistEntryList) {
            selectOptionList.add(new SelectOption(p.Value, p.Label));
        }

        return selectOptionList;
    }

    public List<SelectOption> getDesiredRHProdDescOptions() {
        return getSelectOptions(PICKLIST_ENTRIES.get('Desired_RH_Prod_Desc__c'));
    }

    public List<String> getDesiredRHProdDesc() {
        return getSplitPicklistField(parf.Desired_RH_Prod_Desc__c);
    }

    public void setDesiredRHProdDesc(List<String> valuesList) {
        setSelectOptionsValuesToField('Desired_RH_Prod_Desc__c', valuesList);
    }

    public void setSelectOptionsValuesToField(String fieldName, List<String> valuesList) {
        String field = '';

        for(String value : valuesList) {
            if (field != '') {
                field += ';';
            }
            field += value;
        }

        parf.put(fieldName, field);
    }

	public String productDetailsRequired {
		get {
			return (((!parfProductsExist || showProdDetsReqMessage) && !isDistributor) ? 'display:inline' : 'display:none');
		}
	}

    public boolean underlyingFactsRequired {
        get {
            return (!isPartner &&
                    (!String.isEmpty(parf.Government_Position__c) &&
                    !String.isEmpty(parf.Convicted__c) &&
                    (parf.Government_Position__c.equalsIgnoreCase(System.Label.yes) ||
                        parf.Convicted__c.equalsIgnoreCase(System.Label.yes))));
        }
    }
}