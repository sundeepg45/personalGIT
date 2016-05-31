public with sharing class CreateSSOUser_Controller {
   public String inviteFederationId {get; set; }
   public String inviteEmail {get; set; }
   public String inviteLocaleSidKey {get; set; }
   public String inviteEmailEncodingKey {get; set; }
   public String inviteTimeZoneSidKey {get; set; }
   public String inviteLanguageLocaleKey {get; set; }
   public boolean inviteIsAdmin {get; set; }
	
   public CreateSSOUser_Controller() {
       SelectableCountryList = [
            select Name, Abbreviation__c, Global_Region__c, Subregion__c,IsAgreementSignatureRequired__c, iso3166Alpha2__c
         , (select Name, Abbreviation__c from States__r order by Name asc)
              from Country__c order by Name asc
        ];
   } 
   
    public User me {
    	get {
    		return [
    		  select LocaleSidKey,
    		  		 EmailEncodingKey,
    		  		 TimeZoneSidKey,
    		  		 LanguageLocaleKey
    		    from User
    		   where Id = :UserInfo.getUserId()
    		   limit 1
    	    ];
    	}
    }

    public List<Country__c> SelectableCountryList {
        set;
        get;
    }
    
    public String CurrentCountry {
        set;
        get;
    }
    
    public List<Schema.PicklistEntry> LocaleOptions {
        set;
        get {
        	Schema.DescribeFieldResult f = Schema.SObjectType.User.fields.LocaleSidKey;
			return f.getPicklistValues();
        }
    }
    	
    public List<Schema.PicklistEntry> LanguageOptions {
        set;
        get {
        	Schema.DescribeFieldResult f = Schema.SObjectType.User.fields.LanguageLocaleKey;
			return f.getPicklistValues();
        }
    }

    public List<Schema.PicklistEntry> TimezoneOptions {
        set;
        get {
        	Schema.DescribeFieldResult f = Schema.SObjectType.User.fields.TimezoneSidKey;
			return f.getPicklistValues();
        }
    }
    
    public List<Schema.PicklistEntry> EmailEncodingOptions {
        set;
        get {
        	Schema.DescribeFieldResult f = Schema.SObjectType.User.fields.EmailEncodingKey;
			return f.getPicklistValues();
        }
    }	
    
    public Integer SelectableStateOptionsSize {
        get {
            return SelectableStateOptions.size();
        }
    }
    
    public List<SelectOption> SelectableCountryOptions {
        get {   	
        	return getSelectableCountryOptionsForLang();
        }
    }

	public List<SelectOption> getSelectableCountryOptionsForLang(){
            List<SelectOption> countryOptionList = new List<SelectOption>();
            
            Map<String, String> countryNames = new Map<String,String>();
            for(CountryTranslation__c cT: [select LanguageCode__c, CountryName__c, Country__r.Iso3166Alpha2__c 
            								from CountryTranslation__c where LanguageCode__c = :UserInfo.getLanguage()]){
            									
            	countryNames.put(cT.Country__r.Iso3166Alpha2__c, cT.CountryName__c);
            }

            for(Country__c country : SelectableCountryList){
            	String name = country.Name;
            	if (countryNames.get(country.Iso3166Alpha2__c) != null){
            		name = countryNames.get(country.Iso3166Alpha2__c);
            	}
                countryOptionList.add(new SelectOption(country.Abbreviation__c, name));
            }
            return countryOptionList;		
	}

    public List<SelectOption> SelectableStateOptions {
        get {
        	if (CurrentCountry == null || CurrentCountry == ''){
        		return new List<SelectOption>();
        	}
        	
            List<SelectOption> stateOptionList = new List<SelectOption>();

            for(Country__c country : SelectableCountryList) {
                if (CurrentCountry != country.Abbreviation__c)
                    continue;

                // add all of the states
                for(State__c state : country.States__r)
                    stateOptionList.add(new SelectOption(state.Abbreviation__c, state.Name));

                break;
            }

            return stateOptionList;
        }
    }
    
    public PageReference createInvite() {
    	Partner_User_Invitation__c pui = new Partner_User_Invitation__c();
               
		User u = [Select Id, Contact.AccountId, Contact.Account.Finder_Partner_Type__c, Contact.Account.Finder_Partner_Type__r.HierarchyKey__c, Contact.Account.Global_Region__c from User where id = :UserInfo.getUserId()];
        Profile p = PartnerUtil.onboardingProfile(u.Contact.Account.Global_Region__c, u.Contact.Account.Finder_Partner_Type__r.HierarchyKey__c);
        System.debug('CreateSSOUser Profile ID and Name:  ' + p.Id + ' ' + p.Name);
        pui.Account__c = u.Contact.AccountId;  	
        pui.ProfileId__c = p.Id;
    	pui.Email__c = inviteEmail;
    	pui.Federationid__c = inviteFederationId;
    	pui.LocaleSidKey__c = inviteLocaleSidKey;
    	pui.EmailEncodingKey__c = inviteEmailEncodingKey;
    	pui.TimeZoneSidKey__c = inviteTimeZoneSidKey;
    	pui.LanguageLocaleKey__c = inviteLanguageLocaleKey;
    	pui.IsUserAdmin__c = inviteIsAdmin;
    	insert pui;
    	
    	boolean success = PartnerUserInvitationController.sendMail(pui);    	
    	
    	return new PageReference('/apex/PartnerUserInvitation');
    }
}