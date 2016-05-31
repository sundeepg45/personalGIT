public without sharing class CommunityTools{

    private static User cachedUser;
    private static Boolean trackLoaded = false;
    private static Boolean cachedHasTrack;
    private static Account cachedAccount;
    private static Map<String,Set<String>> cachedAllowedTabs;
    private static Map<String,List<String>> cachedPartnerStatus;
    private static Set<Id> cachedAudiences;


    public static User getUser(Id userId){
        if (cachedUser != null)
            return cachedUser;

        cachedUser = [SELECT Id
                ,FirstName
                ,LastName
                ,Contact.Id
                ,ProfileId
                ,FullPhotoUrl
                ,Profile.Name
                ,LanguageLocaleKey
                ,Username
                ,SumTotal_ID__c
                ,FederationIdentifier
                ,IsPartnerAdmin__c
                FROM User where Id = :userId];
        return cachedUser;
    }

    public static Boolean getHasTrack(User u){
        if (trackLoaded)
            return cachedHasTrack;


        List<Contact_Track__c> tracks = [SELECT
            Partner_Track__r.Partner_Function__c
            ,Partner_Track__r.Product_of_Interest__c
            FROM Contact_Track__c
            WHERE Contact__c = :u.ContactId
            AND Primary__c = True
        ];

        trackLoaded = true;
        cachedHasTrack = (tracks.size() > 0 || u.Profile.Name =='Administrator - Level 2' || u.Profile.Name == 'Administrator - Level 1');
        return cachedHasTrack;
    }

    public static Account getAccount(User u){
        if (cachedAccount != null)
            return cachedAccount;

        if(u.Profile.Name.contains('Guest') || u.Contact.Id == null  || u.Contact == null){
            return null;
        }

        cachedAccount = [SELECT Id, Name, Global_Region__c, Subregion__c, Finder_Partner_Tier__r.Name,CDHPartyNumber__c,
                    Owner.Name, Owner.Email, RequalStatus__c, RequalificationDate__c, Select_Specialization_s__c, BillingCountry, ShippingCountry,
                    (SELECT Program_Name__c, Status__c FROM Partner_Programs__r WHERE Status__c = 'Active')
                    FROM Account WHERE Id = :[SELECT Account.Id FROM Contact WHERE Id = :u.Contact.id].Account.Id];
        return cachedAccount;
    }

    public static String getLanguage(User u){
        String languageCode;
        if(u.LanguageLocaleKey!=null && u.LanguageLocaleKey!=''){
            languageCode = u.LanguageLocaleKey;
        }else{
            languageCode='en_US';
        }
        return languageCode;
    }

    public static String getLanguage(String browserLang){
        String[] primaryLanguage = browserLang.split(',',0);
        return primaryLanguage[0];
    }

    public static Boolean getIsExternalUser(User u){
        if(u.Profile.Name.contains('Profile') && u.Profile.Name.contains('Partner')){
            return true;
        }else{
            return false;
        }
    }

     public static Map<String,Set<String>> getAllowedTabs(){
     	string logTag = '[getAllowedTabs]';
        if (cachedAllowedTabs != null){
        	system.debug(logTag + 'returning cachedAllowedTabs..');
            return cachedAllowedTabs;
        }

        cachedAllowedTabs = new Map<String,Set<String>>();
        Set<String> allowedTabs = new Set<String>();
        List<Schema.DescribeTabSetResult> tabSet = Schema.describeTabs();
        List<Schema.DescribeTabResult> tabs = new List<Schema.DescribeTabResult>();

        for(Schema.DescribeTabSetResult tsr : tabSet){
            if(tsr.getLabel() == 'Partner Community'){
                tabs = tsr.getTabs();
                break;
            }
        }
        Set<String> tabNamesThatAreSObjects = new Set<String>();
        for(Schema.DescribeTabResult tab : tabs){
            String tabIdentifier;
            if(tab.getSObjectName()==null || tab.getSObjectName()==''){
                tabIdentifier='pageTab'+tab.getLabel();
            }else{
                tabIdentifier=tab.getSObjectName();
                tabNamesThatAreSObjects.add(tabIdentifier);
            }
            allowedTabs.add(tabIdentifier);
        }
        cachedAllowedTabs.put('allowedTabs',allowedTabs);
        system.debug(logTag + 'allowedTabs: [' + allowedTabs + ']');

        cachedAllowedTabs.put('SObjects',tabNamesThatAreSObjects);

        return cachedAllowedTabs;
    }




    public static Map<String,List<String>> getPartnerStatus(Account a, Id contactId, User u){
        if (cachedPartnerStatus != null)
            return cachedPartnerStatus;

        cachedPartnerStatus = new Map<String,List<String>>();

        //return the empty map if the user is a guest user or isn't associated to any partner account
        if(a==null){
            return cachedPartnerStatus;
        }

        PartnerStatus__c partnerStatus = [SELECT Id, PartnerType__c, PartnerTier__c from PartnerStatus__c where Partner__c = :a.Id and ActivationStatus__c = 'Active' Limit 1];
        String partnerTier = [SELECT Name from Classification__c where Id = :partnerStatus.PartnerTier__c].Name;
        String partnerType = [SELECT Name from Classification__c where Id = :partnerStatus.PartnerType__c].Name;
        List<Contact_Track__c> contactTracks = [SELECT Partner_Track__r.Partner_Function__c FROM Contact_Track__c
                                 WHERE Contact__r.Id = :contactId];
        String profileId = u.ProfileId;
        List<String> permissionSetIds = New List<String>();
        List<PermissionSetAssignment> psaList = [SELECT Assignee.Name, PermissionSet.Id, PermissionSet.Label
                                                FROM PermissionSetAssignment WHERE AssigneeId = :u.id];
        For(PermissionSetAssignment psa : psaList){
            permissionSetIds.add(psa.PermissionSet.Id);
        }

        cachedPartnerStatus.put('PermissionSet',permissionSetIds);
        cachedPartnerStatus.put('Profile',New List<String>{profileId});
        cachedPartnerStatus.put('Tier',New List<String>{partnerTier});
        cachedPartnerStatus.put('Type',New List<String>{partnerType});
        cachedPartnerStatus.put('Region',New List<String>{a.Global_Region__c});
        cachedPartnerStatus.put('Subregion',New List<String>{a.Subregion__c});
        cachedPartnerStatus.put('Specializations', new List<String>{a.Select_Specialization_s__c});
       // String countryName = convertCountryCode(a.BillingCountry);
        cachedPartnerStatus.put('Country', new List<String>{ convertCountryCode(a.BillingCountry) });

        List<String> tracks = new List<String>();
        for(Contact_Track__c ct : contactTracks){
            tracks.add(ct.Partner_Track__r.Partner_Function__c);
        }
        cachedPartnerStatus.put('Track',tracks);


        List<String> programs = new List<String>();
        for(Partner_Program__c pp : a.Partner_Programs__r){
            programs.add(pp.Program_Name__c);
        }
        cachedPartnerStatus.put('Program',programs);

        cachedPartnerStatus.put('Id',New List<String>{a.Id});
        return cachedPartnerStatus;

    }


    private static String convertCountryCode(String countryCode){
        return [SELECT c.Iso3166Alpha2__c, c.Abbreviation__c, c.Name FROM Country__c c WHERE c.IsDeleted = false AND c.Abbreviation__c = :countryCode LIMIT 1].Name;
    }



    public static Set<Id> getMatchingAudiences(Map<String,List<String>> partnerStatusMap){

        string logTag = '[getMatchingAudiences]';

        system.debug(logTag + 'partnerStatusMap: [' + partnerStatusMap + ']');

        if (cachedAudiences != null)
            return cachedAudiences;

        cachedAudiences = new Set<Id>();


        List<Audience__c> allAudiences = [SELECT Id, Name, Partner_Region__c, Partner_Tier__c, Partner_Type__c,
                                            Available_to_Unauthenticated_Users__c, Partner_Program__c,
                                            Partner_SubRegion__c,
                                            //Target_Account__r.id,
                                            Role__c,
                                            Profile_Id__c, Permission_Set_Id__c, Specialization__c
                                           ,Partner_Country__c
                                          FROM Audience__c];



        // *** Unauthenticated Users ***
        if(partnerStatusMap.keyset().isEmpty()){

            // Iterate through the list and include only the externally available audiences
            for(Audience__c a : allAudiences){

                if(a.Available_to_Unauthenticated_Users__c){
                    cachedAudiences.add(a.id);
                }
            }

            return cachedAudiences;

        }


        //
        // Build a list of Audiences with Target Accounts
        //
        Set<Id> audienceIdSet = new Set<Id>();
        for(Audience__c a: allAudiences){
        	audienceIdSet.add(a.Id);
        }
        System.debug(logTag + 'audienceIdSet contains [' + audienceIdSet.size() + '] audience ids.');

        Map<Id,Set<Id>> targetAccountMap = new Map<Id,Set<Id>>();
        List<Audience_Account__c> audienceAccountList = [select Id, Audience__c, Account__c from Audience_Account__c where Audience__c IN :audienceIdSet];
        System.debug(logTag + 'audienceAccountList contains [' + audienceAccountList.size() + '] records.');

        for(Audience_Account__c ata:audienceAccountList){
            System.debug(logTag + 'Creating targetAccountMap for Account [' + ata.Account__c + ']');
            Set<Id> acctIdSet = new Set<Id>();

            // See if an Id set has already been initialized for this audience.
            if(targetAccountMap.containsKey(ata.Audience__c)){
                acctIdSet = targetAccountMap.get(ata.Audience__c);
            }

            // Add the account id to the set
            acctIdSet.add(ata.Account__c);
            System.debug(logTag + 'Added Account [' + ata.Account__c + '] to targetAccountMap for Audience [' + ata.Audience__c + ']');

            // update the target account map with the new account id set
            targetAccountMap.put(ata.Audience__c, acctIdSet);
        }





        // *** Authenticated Users ***
        // Iterate through the list, adding the ids of matches to the filtered id set
        for(Audience__c a : allAudiences){



            // filter on Id (single-item list)
            /*
            if(a.Target_Account__r.id != null){
                if(partnerStatusMap.get('Id')[0].startsWith(a.Target_Account__r.id)){
                    cachedAudiences.add(a.id);
                    continue;
                }
            }*/
            //if(a.Target_Account__r.id != null){


            // Filter for Targeted Accounts
            Set<Id> targetAcctIdSet = targetAccountMap.get(a.Id);

            if(targetAcctIdSet != null && !targetAcctIdSet.isEmpty()){
                System.debug(logTag + targetAcctIdSet.size() + ' Target Accounts are specified for Audience [' + a.Id + ']');
                String acctId = partnerStatusMap.get('Id')[0];
                for(Id targetId:targetAcctIdSet){
                    if(acctId.startsWith(targetId)){
                        system.debug(logTag + 'TargetAccounts: Adding audience [' + a.Name + '] to cachedAudiences for account [' + partnerStatusMap.get('Id')[0] + '].');
                        cachedAudiences.add(a.id);
                        continue;
                    } /*else {
                        System.debug(logTag + 'Account [' + acctId + '] is NOT in the target account list for Audience [' + a.Id + '].');
                    }*/
                }
                continue; // don't process any other filters
            } else {
                System.debug(logTag + 'No Target Accounts.');
            }

            //filter on Programs (multiple-item list)
            if(a.Partner_Program__c!=null && a.Partner_Program__c!=''){
                List<String> programs = a.Partner_Program__c.split(';');
                if(includeAudience(partnerStatusMap.get('Program'),programs)){
                    system.debug(logTag + 'Partner Programs: Adding audience [' + a.Name + '] to cachedAudiences for account [' + partnerStatusMap.get('Id')[0] + '].');
                    cachedAudiences.add(a.id);
                    continue;
                }
            }

            //filter on profile Id (single-item list)
            if(a.Profile_Id__c!=null && a.Profile_Id__c!=''){
                for(String audienceProfileId : a.Profile_Id__c.split(';')){
                    if(partnerStatusMap.get('Profile')[0].startsWith(audienceProfileId)){
                        system.debug(logTag + 'Profile Ids: Adding audience [' + a.Name + '] to cachedAudiences for account [' + partnerStatusMap.get('Id')[0] + '].');
                        cachedAudiences.add(a.id);
                        continue;
                    }
                }
            }

            //filter on permission set id (multiple-item list)
            if(a.Permission_Set_Id__c!=null && a.Permission_Set_Id__c!=''){
                List<String> permissionSetIds = a.Permission_Set_Id__c.split(';');
                if(includeAudience(partnerStatusMap.get('PermissionSet'),permissionSetIds)){
                    system.debug(logTag + 'Permission Sets: Adding audience [' + a.Name + '] to cachedAudiences for account [' + partnerStatusMap.get('Id')[0] + '].');
                    cachedAudiences.add(a.id);
                    continue;
                }
            }

            //filter on partner account information (series of single-item lists & multiple item list)
            if(a.Partner_Tier__c!=null && a.Partner_Tier__c!=''){

            	System.debug(logTag + a.Name + ' ** Partner Country ** : [' + partnerStatusMap.get('Country') + '], audience country: [' + a.Partner_Country__c + ']');

                //Tier, Type, Region, Subregion, Role
                if(
                includeAudience(partnerStatusMap.get('Tier'),a.Partner_Tier__c.split(';'))
                && includeAudience(partnerStatusMap.get('Type'),a.Partner_Type__c.split(';'))
                && includeAudience(partnerStatusMap.get('Region'),a.Partner_Region__c.split(';'))
                && includeAudience(partnerStatusMap.get('Subregion'),a.Partner_Subregion__c.split(';'))
                && (a.Partner_Country__c != null && includeAudience(partnerStatusMap.get('Country'),a.Partner_Country__c.split(';')))
                && (a.Specialization__c != null && includeAudience(partnerStatusMap.get('Specializations'),a.Specialization__c.split(';')))
                && includeAudience(partnerStatusMap.get('Track'),a.Role__c.split(';'))
                ){
                    system.debug(logTag + 'Type/Region/Tier/Track: Adding audience [' + a.Name + '] to cachedAudiences for account [' + partnerStatusMap.get('Id')[0] + '].');
                    cachedAudiences.add(a.id);
                    continue;
                } else {
                	system.debug(logTag + '@@ Partner [' + partnerStatusMap.get('Id') + '] is NOT in Audience [' + a.Name + ']. PartnerStatusMap dump: [' + partnerStatusMap + '], Audience: [' + a + ']');
                }
            }
/*
            // Country filter
            if(!String.isEmpty(a.Partner_Country__c)){ // && includeAudience(partnerStatusMap.get('Country'),a.Partner_Country__c.split(';'))){
            	system.debug(logTag + '[Country] audience (' + a.Name + ') debug: \n\tpartner country (list): [' + a.Partner_Country__c.split(';') + ']\n\tpartnerStatusMap country: [' + partnerStatusMap.get('Country') + ']');

            	if(includeAudience(partnerStatusMap.get('Country'),a.Partner_Country__c.split(';'))){
                    system.debug(logTag + '[Country] Adding audience [' + a.Name + '] to cachedAudiences for account [' + partnerStatusMap.get('Id')[0] + '].');
                    cachedAudiences.add(a.id);
                    continue;
            	} else {
            		system.debug(logTag + '[Country] Partner country was not in the audience partner country filter.');
            	}
            }

            // Specialization filter
            if( a.Specialization__c != '' && a.Specialization__c != null){

                if( !partnerStatusMap.get('Specializations').isEmpty()){
	            	if(includeAudience(partnerStatusMap.get('Specializations'), a.Specialization__c.split(';'))){
		                system.debug(logTag + 'Specializations: Adding audience [' + a.Id + '] to cachedAudiences for account [' + partnerStatusMap.get('Id')[0] + '].');
		                cachedAudiences.add(a.id);
		                continue;
	            	}
                }
            }

            */

            //include any externally available audiences
            if(a.Available_to_Unauthenticated_Users__c){
                cachedAudiences.add(a.id);
                continue;
            }
        }


        System.debug(logTag + 'Cached Audiences: ['+ cachedAudiences + ']');

        return cachedAudiences;
    }

    private static Boolean includeAudience(List<String> userValues, List<String>audienceValues){
         string logTag = '[includeAudience]';
         for(string av : audienceValues){
            if(av=='All'){
                return true;
            }else{
                for(string uv : userValues){
                	system.debug(logTag + 'audience value: [' + av + '], user value: [' + uv + ']');
                    if(uv != null && uv.startsWith(av)){
                        return true;
                    }
                }
            }
        }
        return false;
    }
}