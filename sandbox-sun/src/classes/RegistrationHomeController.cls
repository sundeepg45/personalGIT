public with sharing class RegistrationHomeController {

	public String leadType = null;
	public String lastLeadType = null;
	public Lead[] lastLeadList = new List<Lead>();
	public Partner_Registration__c[] lastParList = null;
	public String global_region;
	public String leadKeyPrefix;
	public String partnerRegKeyPrefix;
	public ID accountId;
	public String accountName;
	private Boolean isFedSled;
	private Integer leadsBatchSize = 100;
	public Boolean moreBatches {get; private set;}
	public Boolean previousBatches {get; private set;}
	private Integer batchStartIndex = 0;

	public RegistrationHomeController() {
		getParRegistrations();
		Schema.DescribeSObjectResult leadSchema = null;
		for (Schema.SObjectType objectType : Schema.getGlobalDescribe().values()) {
			Schema.DescribeSObjectResult d = objectType.getDescribe();
			if (d != null && d.getName() == 'Lead') {
				leadSchema = d;
				break;
			}
 		}
		Schema.DescribeSObjectResult regSchema = null;
		for (Schema.SObjectType objectType : Schema.getGlobalDescribe().values()) {
			Schema.DescribeSObjectResult d = objectType.getDescribe();
			if (d != null && d.getName() == 'Partner_Registration__c') {
				regSchema = d;
				break;
			}
 		}
		partnerRegKeyPrefix = regSchema.getKeyPrefix();
 		leadKeyPrefix = leadSchema.getKeyPrefix();
		User me = [select Id, Profile.Name, Contact.AccountId, Contact.Account.Name, Contact.Account.Global_Region__c from User where Id = :UserInfo.getUserId()];
		if (me.Contact == null || me.Contact.Account == null) {
			global_region = 'NA';
			accountName = 'test';
		}
		else {
			global_region = me.Contact.Account.Global_Region__c;
			accountId = me.Contact.AccountId;
			accountName = me.Contact.Account.Name;
		}
		isFedSled = me.Profile.Name.indexOf('Fed/Sled') > 0;
		getLeadsBatch();
	}

	private String getDealRegRecordTypeName() {
		if (isFedSled) {
			return 'NA Fed/Sled Deal Registration';
		}
		else {
			if (global_region == 'NA') {
				return global_region + ' Subscription Deal Registration';
			}
		}
		return global_region + ' Deal Registration';
	}

	public Boolean getHasDealRegAccess() {
		return hasLeadRecordTypeAccess(getDealRegRecordTypeName());
	}

	private Boolean hasLeadRecordTypeAccess(String recordTypeName) {
		ID rectypeid = null;
		try {
			rectypeid = [select Id from RecordType where Name = :recordTypeName].Id;
		}
		catch (Exception ex) {
			return false;
		}
		Set<ID> names = getAvailableRecordTypesForSObject(Lead.sObjectType);
		System.debug('*****[debug]***** names for record type ' + recordTypeName);
		for (String name : names) System.debug('*****[debug]***** >> ' + name);
		if (!names.contains(rectypeid)) {
			return false;
		}
		return true;
	}

	public Boolean getHasParAccess() {
		Partner_Program__c[] proglist = [
			select	Id
			from	Partner_Program__c
			where	Account__c = :accountId
			and		Program__r.Program_Category__c = 'Partner Assistance Reward Program'
			and		Status__c in ('Active','Approved')
		];
		return !proglist.isEmpty();
	}

	public Boolean getHasTeamingAccess() {
		if (global_region != 'NA') return false;
		return hasLeadRecordTypeAccess('Reseller Teaming Agreement Deal Registration');
	}

	public Boolean getHasSalesLeadAccess() {
		return hasLeadRecordTypeAccess(global_region + ' Sales Lead');
	}


	public PageReference registerDeal() {
		String devname = getDealRegRecordTypeName();
		ID dealRegRecordId = [select Id from RecordType where Name = :devname limit 1].Id;

		String retUrl = EncodingUtil.urlEncode('/apex/RegistrationHome','UTF-8');
        PageReference pg = new PageReference(
                    '/' + leadKeyPrefix +
                    '/e?nooverride=0&RecordType=' + dealRegRecordId +
                    '&Status=Deal%20Registration' +
                    '&Deal_Registration_Status__c=Draft' +
                    '&retURL=' + retUrl);
        pg.setRedirect(true);
		return pg;
	}

	public PageReference registerTeaming() {
		ID teamingRecordId = [select Id from RecordType where Name like '%Reseller Teaming Agreement Deal Registration' limit 1].Id;

		String retUrl = EncodingUtil.urlEncode('/apex/RegistrationHome','UTF-8');
        PageReference pg = new PageReference(
                    '/' + leadKeyPrefix +
                    '/e?nooverride=0&RecordType=' + teamingRecordId +
                    '&Status=Deal%20Registration' +
                    '&Deal_Registration_Status__c=Draft' +
                    '&retURL=' + retUrl);
        pg.setRedirect(true);
        return pg;
	}

	public PageReference registerSales() {
		String devname = global_region + ' Sales Lead';
		ID salesRecordId = [select Id from RecordType where Name = :devname limit 1].Id;

		String retUrl = EncodingUtil.urlEncode('/apex/RegistrationHome','UTF-8');
        PageReference pg = new PageReference(
                    '/' + leadKeyPrefix +
                    '/e?nooverride=0&RecordType=' + salesRecordId +
                    '&retURL=' + retUrl);
        pg.setRedirect(true);
        return pg;
	}

	public PageReference registerPar() {
		String retUrl = EncodingUtil.urlEncode('/apex/RegistrationHome','UTF-8');
        PageReference pg = new PageReference('/apex/PAR_Registration_New' +
        	'?nooverride=0' +
        	'&CF00Nm0000000O01g='+ EncodingUtil.urlEncode(accountName,'UTF-8')+
        	'&CF00Nm0000000O01g_lkid=' + accountId +
        	'&sfdc.override=1'+
        	'&retURL='+retUrl);
        pg.setRedirect(true);
		return pg;
	}

	public Boolean getIsDealRegList() {
		if (isFedSled) {
				return leadType == 'NA Fed/Sled Deal Registration';
		} else {
			if (global_region == 'NA') {
				return leadType == global_region + ' Subscription Deal Registration';
			}
			else {
				return leadType == global_region + ' Deal Registration';
			}
		}
	}

	public Boolean getIsSalesLeadList() {
		return leadType == global_region + ' Sales Lead';
	}

	public Boolean getIsTeamingList() {
		return leadType == 'Reseller Teaming Agreement Deal Registration';
	}

	public Boolean getIsParList() {
		return leadType == 'par';
	}

	public PageReference dealRegLeadListSetup() {
		if (isFedSled) {
			leadType = 'NA Fed/Sled Deal Registration';
		} else {
			if (global_region == 'NA') {
				leadType = global_region + ' Subscription Deal Registration';
			}
			else {
				leadType = global_region + ' Deal Registration';
			}
		}
		return null;
	}

	public PageReference salesLeadListSetup() {
		leadType = global_region + ' Sales Lead';
		return null;
	}

	public PageReference teamingListSetup() {
		leadType = 'Reseller Teaming Agreement Deal Registration';
		return null;
	}

	public PageReference parListSetup() {
		leadType = 'par';
		return null;
	}

	public PageReference viewAll() {
		return Page.PartnerRegistrationHistory;
	}

	public Lead[] getLeadsBatch() {
		Lead[] allLeads = getAllLeads();
		moreBatches = false;
		previousBatches = false;
		if (allLeads != null) {
			List<Lead> leadsBatch = new List<Lead>();
			if (batchStartIndex < 0) {
				batchStartIndex = 0;
			}
			if (batchStartIndex > (allLeads.size() - 1)) {
				batchStartIndex = allLeads.size() - 1;
			}
			Integer endIndex = batchStartIndex + leadsBatchSize;
			if (allLeads.size() < endIndex) {
				endIndex = allLeads.size();
			}
			for (Integer counter = batchStartIndex; counter < endIndex; counter++) {
				leadsBatch.add(allLeads.get(counter));
			}
			moreBatches = endIndex < allLeads.size();
			previousBatches = batchStartIndex > 0;
			return leadsBatch;
		}
		return null;
	}

	public void getNextBatch() {
		batchStartIndex += leadsBatchSize;
	}

	public void getPreviousBatch() {
		batchStartIndex -= leadsBatchSize;
	}

	private Lead[] getAllLeads() {
		if (leadType == null) return null;

		Lead[] leadlist = [
			select	Id, Name, Company, State_Province__r.Name, Status, CreatedDate, Owner.Alias, Country_of_Order__c, Email, Deal_Registration_Status__c
			from	Lead
			where	RecordType.Name = :leadType
			and		OwnerId = :UserInfo.getUserId()
			order by CreatedDate desc
		];
		if (leadlist.isEmpty()) return null;
		return leadlist;
	}

	public Lead[] getLeads() {
		if (leadType == null) return null;
		if (leadType == lastLeadType) {
			return lastLeadList;
		}

		System.debug('*****[debug]****** leadtype=' + leadType);
		Lead[] leadlist = new List<Lead>();
//		User me = [select Id, Contact.AccountId from User where Id = :UserInfo.getUserId()];
		leadlist = [
			select	Id, Name, Company, State_Province__r.Name, Status, CreatedDate, Owner.Alias, Country_of_Order__c, Email, Deal_Registration_Status__c
			from	Lead
			where	RecordType.Name = :leadType
			and		OwnerId = :UserInfo.getUserId()
			and		(Rejected__c = 0 and Status not in ('Converted') and Deal_Registration_Status__c not in ('Approved', 'Rejected'))
			order by CreatedDate desc
		];
		if (leadlist.isEmpty()) return null;
		lastLeadList = leadList;
		lastLeadType = leadType;
		return leadlist;
	}

	public Partner_Registration__c[] getAllParRegistrations() {
		Partner_Registration__c[] lastParList = [
			select	id, Name, Company_Name__c, Status__c, CreatedDate, Company_Country__c, Company_Contact_Email__c
			from	Partner_Registration__c
			where	Partner__c = :accountId
			order by CreatedDate desc
		];
		if (lastParList.isEmpty()) {
			return null;
		}
		return lastParList;
	}

	public Partner_Registration__c[] getParRegistrations() {
		if (lastParList != null) return lastParList;
		Partner_Registration__c[] lastParList = [
			select	id, Name, Company_Name__c, Status__c, CreatedDate, Company_Country__c, Company_Contact_Email__c
			from	Partner_Registration__c
			where	Partner__c = :accountId
			and		(Status__c = 'Open' or Status__c like 'Pending%')
			order by CreatedDate desc
		];
		if (lastParList.isEmpty()) {
			lastParList = null;
			return null;
		}
		return lastParList;
	}

	private static Set<ID> getAvailableRecordTypesForSObject(Schema.SObjectType objType) {
	    Set<ID> names = new Set<ID>();
	    List<RecordTypeInfo> infos = objType.getDescribe().getRecordTypeInfos();
	    if (infos.size() > 1) {
	        for (RecordTypeInfo i : infos) {
	           // Ignore the Master Record Type, whose Id always ends with 'AAA'.
	           // We check the Id because Name can change depending on the user's language.
	           if (i.isAvailable() && !String.valueOf(i.getRecordTypeId()).endsWith('AAA')) {
	               names.add(i.getRecordTypeId());
	           }
	        }
	    }
	    // Otherwise there's just the Master record type,
	    // so add it in, since it MUST always be available
	    else {
	    	names.add(infos[0].getRecordTypeId());
	    }
	    return names;
	}

}