public without sharing class PartnerUtil {

	public class ContentPair {
		public RH_Content__c	rhcontent	{get; set; }
		public ContentVersion	content		{get; set; }
		public String			annotations {get; set; }
	}


    static public String getLanguageNameForCode(String code) {
        if (code == null) {
            return 'English';
        }
        code = code.toLowerCase();
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
            if (code.startsWith(key)) {
                return listmap.get(key);
            }
        }
        return listmap.get('en');
    }

    static public String getLanguageCodeForName(String name) {
        if (name == null) {
            return 'en';
        }
        name = name.toLowerCase();
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
            String val = listmap.get(key);
            if (name == val) {
                return key;
            }
        }
        return 'en';
    }

    static public Boolean isPartner(ID recordTypeId) {
        return recordTypeId == PartnerConst.NA_PARTNER || recordTypeId == PartnerConst.EMEA_PARTNER ||
            recordTypeId == PartnerConst.APAC_PARTNER || recordTypeId == PartnerConst.LATAM_PARTNER;
    }

    public static Boolean validateEmail(String email) {
    	String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; // source: http://www.regular-expressions.info/email.html
    	Pattern MyPattern = Pattern.compile(emailRegex);
    	Matcher MyMatcher = MyPattern.matcher(email);
    	return MyMatcher.matches();
    }

    static public Map<ID,Account> getPartnerAccountsForSales(Set<String> salesIdList) {
        Set<ID> idset = new Set<ID>();
        for (String s : salesIdList) idset.add((ID) s);
        return getPartnerAccountsForSales(idset);
    }

    static public Map<ID,Account> getPartnerAccountsForSales(Set<ID> salesIdList) {
        Account[] salesaccountlist = [
            select  Id, CDHPartyNumber__c, Finder_Partner_Type__c
            from    Account
            where   Id in :salesIdList
        ];

        if (salesaccountlist.isEmpty()) {
            return new Map<ID,Account>();
        }

        //
        // get partner accounts based on party numbers
        //
        Map<ID,Account> partnermap = new Map<ID,Account>();
        for (Account acct : [
            select  Id, CDHPartyNumber__c, Finder_Partner_Type__c
            from    Account
            where   CDHPartyNumber__c in :PartnerUtil.getStringFieldSet(salesaccountlist, 'CDHPartyNumber__c')
            and     RecordType.DeveloperName in ('APACPartner','EMEAPartner','LATAMPartner','NAPartner')
        ]) {
            for (Account salesacct : salesaccountlist) {
                if (salesacct.CDHPartyNumber__c == acct.CDHPartyNumber__c) {
                    partnermap.put(salesacct.Id, acct);
                    break;
                }
            }
        }
        return partnermap;
    }

    static public Map<ID,Account> getSalesAccountsForPartners(Set<String> partnerIdList) {
        Set<ID> idset = new Set<ID>();
        for (String s : partnerIdList) idset.add((ID) s);
        return getSalesAccountsForPartners(idset);
    }

    static public Map<ID,Account> getSalesAccountsForPartners(Set<ID> partnerIdList) {
        Account[] partneraccountlist = [
            select  Id, CDHPartyNumber__c
            from    Account
            where   Id in :partnerIdList
        ];

        if (partneraccountlist.isEmpty()) {
            return new Map<ID,Account>();
        }

        //
        // get partner accounts based on party numbers
        //
        Map<ID,Account> salesmap = new Map<ID,Account>();
        for (Account acct : [
            select  Id, CDHPartyNumber__c
            from    Account
            where   CDHPartyNumber__c in :PartnerUtil.getStringFieldSet(partneraccountlist, 'CDHPartyNumber__c')
            and     RecordType.DeveloperName in ('APACAccount','EMEAAccount','LATAMAccount','NAAccount', 'DLT')
        ]) {
            for (Account partneracct : partneraccountlist) {
                if (partneracct.CDHPartyNumber__c == acct.CDHPartyNumber__c) {
                    salesmap.put(partneracct.Id, acct);
                    break;
                }
            }
        }
        return salesmap;
    }


	//
	// remove dups from a list and maintain original ordering
	//
	static public List<SObject> dedup(List<SObject> input) {
		Set<SObject> myset = new Set<SObject>();
		List<SObject> result = new List<SObject>();
		for (SObject s : input) {
			if (myset.add(s)) {
    			result.add(s);
			}
  		}
		return result;
	}

	static public Set<String> getIdSet(SObject[] objects) {
		return getStringFieldSet(objects, 'Id');
	}

	static public Set<String> getStringFieldSet(SObject[] objects, String fieldName) {
		Set<String> idlist = new Set<String>();
		for (SObject obj : objects) {
			if (obj.get(fieldName) != null) {
				idlist.add((String) obj.get(fieldName));
			}
		}
		return idlist;

	}

	//
	// Dynamically generate SOQL to fetch all cloneable fields in a record
	//
    public static String getWritableFieldsSOQL(String objectName, String whereClause) {
        String selects = '';

        if (whereClause == null || whereClause == '') {
        	return null;
        }

        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        String[] selectFields = new List<String>();

        if (fieldMap != null) {
            for (Schema.SObjectField ft : fieldMap.values()) {
                Schema.DescribeFieldResult fd = ft.getDescribe();
                if (fd.isCreateable()) {
                    selectFields.add(fd.getName());
                }
            }
        }

        if (!selectFields.isEmpty()) {
            for (String s : selectFields) {
                selects += s + ',';
            }
            if (selects.endsWith(',')) {
            	selects = selects.substring(0,selects.lastIndexOf(','));
            }

        }
         return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
    }

    public static ContentPair[] fetchMatchingContent(RH_Content__c[] rhcontent) {
    	return fetchMatchingContent(rhcontent, false);
    }

    public static ContentPair[] fetchMatchingContent(RH_Content__c[] rhcontent, boolean inclMissingDocsAsNull) {

        Set<String> idlist = PartnerUtil.getStringFieldSet(rhcontent, 'ContentDocumentId__c');
		System.debug('****[debug]**** ID List contains ' + idlist);

        ContentVersion[] cvlist = [
        		select	Id,
        				FileType,
                        Document_Type__c,
        				Title,
        				Description,
        				ContentDocumentId,
        				ContentSize,
        				ContentUrl
        		from	ContentVersion
        		where	ContentDocumentId in :idlist
        		and		PublishStatus = 'P'
        		and		IsLatest = true
        		and		IsDeleted = false
        ];

        ContentPair[] pageContent = new List<ContentPair>();
		for (RH_Content__c c : rhcontent) {
			boolean found = false;
			for (ContentVersion cv : cvlist) {
				if (cv.ContentDocumentId == Id.valueOf(c.ContentDocumentId__c)) {
					found = true;
					ContentPair cp = new ContentPair();
					cp.rhcontent = c;
					cp.content = cv;
					if (c.Annotation__c != null) {
						String[] alist = c.Annotation__c.split(';');
						cp.annotations = PartnerUtil.joinArray(alist, ',');
					}
					pageContent.add(cp);
					break;
				}
			}
			if (!found) {
				System.debug('****[debug]**** ContentVersion missing for ' + c.ContentDocumentId__c);
				if (inclMissingDocsAsNull){
					ContentPair cp = new ContentPair();
					cp.rhcontent = c;
					pageContent.add(cp);
				}
			}
		}
		return pageContent;
    }

    static public String cleanSection(String section) {
    	if (section == null) {
    		return null;
    	}
    	String s = section.replaceAll('&', 'and');
    	s = s.replaceAll(', ', ' ');
    	s = s.replaceAll(',', ' ');
    	return s;
    }

    static public String[] removeTags(String[] taglist, String[] toRemove) {
    	Set<String> tagset = new Set<String>(taglist);
    	tagset.removeAll(toRemove);
    	return new List<String>(tagset);
    }

    static public String joinArray(Object[] objectArray, String separator) {
        if (objectArray == null) {
            return null;
        }
        return joinArray(objectArray, separator, 0, objectArray.size());
    }

    static public String joinArray(Object[] objectArray, String separator, Integer startIndex, Integer endIndex) {
        if (objectArray == null) {
            return null;
        }
        if (separator == null) {
            separator = '';
        }

        String buf = '';
        if(startIndex < 0){
            startIndex = 0;
        }
        Boolean isFirst = true;
        for (Integer i = startIndex; i < endIndex && i < objectArray.size(); i++) {
            if (objectArray[i] != null) {
	            if (isFirst) {
	                isFirst = false;
	            }
	            else {
	                buf += separator;
	            }
	            buf += objectArray[i];
            }
        }
        return buf;
    }

	static public Set<String> filterTIIndexedAccount(Account acct) {
		Set<String> clist = new Set<String>();
		Set<String> matchedCountries = new Set<String>();

		if (acct.BillingCountry != null) {
			clist.add(acct.BillingCountry);
		}
		if (acct.ShippingCountry != null) {
			clist.add(acct.ShippingCountry);
		}
		if (!clist.isEmpty()) {
			matchedCountries.addAll(PartnerUtil.filterTIIndexCountryCodes(clist));
			clist.clear();
		}


//		if (acct.Office_Location__r != null && acct.Office_Location__r.TI_Index__c == true) {
//			clist.add(acct.Office_Location__r.Name);
//		}
		if (acct.Additional_Countries_of_Operation__c != null) {
			String[] opCountries = acct.Additional_Countries_of_Operation__c.split(';');
			Set<String> opSet = new Set<String>(opCountries);
			clist.addAll(opSet);
//		    Set<String> tiIndexed = PartnerUtil.filterTIIndexCountries(opCountries);
//		    matchedCountries.addAll(tiIndexed);
		}
		matchedCountries.addAll(PartnerUtil.filterTIIndexCountries(clist));
		/*
		 * make sure to select Partner_Locations__r from Account if uncommenting this code
		 *
		if (acct.Partner_Locations__r != null) {
			String[] codes = new List<String>();
			for (Partner_Location__c pl : acct.Partner_Locations__r) {
				codes.add(pl.Country__c);
			}
			Set<String> tiIndexed = PartnerUtil.filterTIIndexCountryCodes(codes);
			matchedCountries.addAll(tiIndexed);
		}
		*/
		return matchedCountries;
	}

    static public Set<String> filterTIIndexCountries(Set<String> countryNames) {
    	Country__c[] countries = [
    		select	Id, Name, TI_Index__c
    		from	Country__c
    		where	Name in :countryNames
    		and		TI_Index__c = true
    	];
    	return PartnerUtil.getStringFieldSet(countries, 'Name');
    }

    static public Set<String> filterTIIndexCountryCodes(Set<String> countryCodes) {
    	Country__c[] countries = [
    		select	Id, Name, TI_Index__c
    		from	Country__c
    		where	Iso3166Alpha2__c in :countryCodes
    		and		TI_Index__c = true
    	];
    	return PartnerUtil.getStringFieldSet(countries, 'Name');
    }

    static public Profile onboardingProfileByClassificationId(String globalRegion, Id clfnHKey) {
    	//This method is used by OnboardingController, which can only pass in a Classification ID without further modification.
        //Eliminates a SOQL query from onboardingProfile(), used in CreateSSOUser_Controller and User_SetPartnerProfile.
        Classification__c c = [SELECT Id, HierarchyKey__c
                               FROM Classification__c
                               WHERE Id = : clfnHKey];
        Profile p = onboardingProfile(globalRegion, c.HierarchyKey__c);
		return p;

    }

    static public Profile onboardingProfile(String globalRegion, String clfnHKey) {

        String prof;

        if (clfnHKey == 'PARTNER_TYPE.SI' || clfnHKey == 'PARTNER_TYPE.OEM') {
            prof = '%OEM%SI';
        } else if (clfnHKey == 'PARTNER_TYPE.ISV' && globalRegion == 'EMEA') {
            prof = 'EMEA%ISV%';
        } else if (clfnHKey == 'PARTNER_TYPE.ISV') {
            prof = 'Partner%ISV%';
        } else if (clfnHKey == 'PARTNER_TYPE.TRAINING') {
            prof = '%Training%';
        } else if (globalRegion != NULL ) {
            prof = globalRegion + ' Partner Portal%Strategic License';
        }

        Profile p = [SELECT id, name
                     FROM Profile
                     WHERE Name LIKE : prof];

        System.debug('Classification Hierarchy Key:  ' + clfnHKey);
        System.debug('Partner Account Global Region:  ' + globalRegion);
        System.debug('Profile assignment:  ' + p.Name);

        return p;

    }

	public static List<Anti_Corruption__c> expireOldACRecords(Id accountId, List<Anti_Corruption__c> acRecordsToExpire) {
		List<Anti_Corruption__c> expiredACRecords = new List<Anti_Corruption__c>();
		for (Anti_Corruption__c acRecord : acRecordsToExpire) {
			if (acRecord.Partner_Account__c == accountId &&
				acRecord.Review_Status__c != 'Rejected') {
				acRecord.Review_Status__c = 'Expired';
				expiredACRecords.add(acRecord);
			}
		}
		return expiredACRecords;
	}

	public static Map<ID, Partner_State__c> fetchPartnerStateMap(Set<String> accountIdSet) {
		Map<ID, Partner_State__c> pgmap = new Map<ID, Partner_State__c>();
		for (Partner_State__c pg : [
			select 	Id, Account__c, Requal_Lockout_Exempt__c
			from 	Partner_State__c
			where 	Account__c in :accountIdSet
		]) {
			pgmap.put(pg.Account__c, pg);
		}
		return pgmap;
	}

	public static Boolean onbAsAdvancedOrPremier(String typeName) {
		List<Partners_Onb_Adv_Prem__c> partnerTypesOnboardingAsAdvOrPrem = Partners_Onb_Adv_Prem__c.getAll().values();
		for (Partners_Onb_Adv_Prem__c type : partnerTypesOnboardingAsAdvOrPrem) {
			if (typeName != null && typeName == type.Name) {
				return true;
			}
		}
		return false;
	}

    public static String getUserIPAddress() {
        String val = '';

        // True-Client-IP has the value when the request is coming via the caching integration.
        val = ApexPages.currentPage().getHeaders().get('True-Client-IP');

        // X-Salesforce-SIP has the value when no caching integration or via secure URL.
        if (val == '' || val == null) {
             val = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        }

        // get IP address when no caching (sandbox, dev, secure urls)
        if (val == '' || val == null) {
            val = ApexPages.currentPage().getHeaders().get('X-Forwarded-For');
        }

        return val;
    }

}