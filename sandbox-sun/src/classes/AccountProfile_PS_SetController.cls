/**
 * This is a controller of the Account_Profile__c class to
 * manage the related set of AccountProfile_PartnerStatus__c records.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-01-07
 * 2013-01-07 - Created.
 */
public with sharing class AccountProfile_PS_SetController {
	private Id accountProfileId;

	/**
	 * Basic constructor for the controller.  Reads the URL parameters for the
	 * currentPage and initialize the class.
	 */
	public AccountProfile_PS_SetController()
	{
		Map<String,String> paramMap = ApexPages.currentPage().getParameters();
		accountProfileId = paramMap.get('id');
		System.debug('accountProfileId='+accountProfileId);
	}

	/**
	 * The Account_Profile__c record specified by the currentPage Id parameter.
	 */
	public Account_Profile__c accountProfile {
		get {
			if(accountProfile == null) {
				accountProfile = [
					select
						Account__r.Name,
						Name
					from Account_Profile__c
					where Id = :accountProfileId ];
			}
			return accountProfile;
		}
		private set;
	}

	/**
	 * Contains the StandardSetController for listed all the PartnerStatus__c records 
	 * related to the Account_Profile__c via a reseller OpportunityPartner__c object.
	 * @return the StandardSetController of PartnerStatus__c records.
	 */
	public ApexPages.StandardSetController partnerStatusRecords{
		get {
			if(partnerStatusRecords == null) {
				String s = searchString;
				if(s == null) {
					s = '';
				}
				s=s.replace('%','_').replace('*','%').replace('?','_')+'%';
				System.debug('searchString='+s);
				System.debug('AccountId='+accountProfile.Account__c);
				Integer maxQuerySize = 100*((10000 - Limits.getQueryRows() - 100)/100);
				partnerStatusRecords = new ApexPages.StandardSetController(Database.getQueryLocator([
					select 
						Partner__r.Name,
						Partner__r.Account_Alias_Name__c,
						Partner__r.Site,
						Partner__r.OracleAccountNumber__c,
						Partner__r.Owner.Alias,
						Partner__r.RecordType.Name,
						Partner__r.Type,
						PartnerTier__r.Name,
						PartnerTier__r.Hierarchy__c,
						PartnerTier__r.IsActive__c,
						PartnerType__r.Name,
						PartnerType__r.Hierarchy__c,
						PartnerType__r.IsActive__c
					from PartnerStatus__c 
					where Partner__r.Name like :s
						and ActivationStatus__c = 'Active'
						and Partner__c in (
							select Partner__c 
							from OpportunityPartner__c 
							where Opportunity__r.AccountId = :accountProfile.Account__c)
						and ActivationStatus__c = 'Active'
					order by Partner__r.Name,PartnerType__r.Hierarchy__c,PartnerTier__r.Hierarchy__c,Partner__r.RecordType.Name,Partner__r.Site,Partner__r.OracleAccountNumber__c
					limit :maxQuerySize ] ));
			}
			return partnerStatusRecords;
		}
		private set;
	}

	/**
	 * The partnerName (search String) to use.
	 */
	public String searchString {
		get;
		set {
			if(value != searchString) {
				searchString = value;
				partnerStatusRecords = null;
			}
		}
	}

	/**
	 * The field name to set the partnerName into.
	 */
	public String partnerNameField {
		get;
		set;
	}

	/**
	 * The field name to set the PartnerStatus__c.Id value into.
	 */
	public String partnerStatusIdField {
		get;
		set;
	}

	/**
	 * The number of pages available.
	 * @return number of pages
	 */
	public Integer getPageCount() {
		Integer rs = partnerStatusRecords.getResultSize();
		Integer ps = partnerStatusRecords.getPageSize();
		return (ps+rs-1)/ps;
	}

	/**
	 * Dummy call.
	 * @return null
	 */
	public PageReference updateSearchString()
	{
		return null;
	}

	/**
	 * The current page of PartnerStatus__c records.
	 * @return list of PartnerStatus__c records.
	 */
	public List<AccountProfile_PS_ControllerExtension.PartnerStatus> getPartnerStatusPagination() {
		List<PartnerStatus__c> partnerStatuses = partnerStatusRecords.getRecords();
		Map<Id,AccountProfile_PartnerStatus__c> appsMap = new Map<Id,AccountProfile_PartnerStatus__c>();
		for(AccountProfile_PartnerStatus__c apps : [
			select
				PartnerStatus__c
			from AccountProfile_PartnerStatus__c
			where PartnerStatus__c in :partnerStatuses 
				and Account_Profile__c = :accountProfileId ])
		{
			appsMap.put(apps.PartnerStatus__c,apps);
		}
		List<AccountProfile_PS_ControllerExtension.PartnerStatus> retval = new List<AccountProfile_PS_ControllerExtension.PartnerStatus>();
		for(PartnerStatus__c ps : partnerStatuses) {
			AccountProfile_PartnerStatus__c apps = appsMap.get(ps.Id);
			if(apps == null) {
				apps = new AccountProfile_PartnerStatus__c(
					Account_Profile__c = accountProfileId,
					PartnerStatus__c = ps.Id);
			}
			retval.add(new AccountProfile_PS_ControllerExtension.PartnerStatus(apps,ps));
		}
		return retval;
	}

	/**
	 * Navigate to the first page.
	 * @return null
	 */
	public PageReference first()
	{
		partnerStatusRecords.first();
		return null;
	}

	/**
	 * Navigate to the next page.
	 * @return null
	 */
	public PageReference next()
	{
		partnerStatusRecords.next();
		return null;
	}

	/**
	 * Navigate to the previous page.
	 * @return null
	 */
	public PageReference previous()
	{
		partnerStatusRecords.previous();
		return null;
	}

	/**
	 * Navigate to the last page.
	 * @return null
	 */
	public PageReference last()
	{
		partnerStatusRecords.last();
		return null;
	}

	/**
	 * Called to navigate back the the Account_Profile__c view page.
	 * @retval PageReference to view the Account_Profile__c record.
	 */
	public PageReference cancel() {
		String retURL = ApexPages.currentPage().getParameters().get('retURL');
		if(retURL == null) {
			retURL = '/'+accountProfileId+'#PreferredPartners_target';
		}
		Integer i = retURL.indexOf('#');
		String anchor = null;
		if(i > 0) {
			anchor = retURL.substring(i+1);
			retURL = retURL.substring(0,i);
		}
		PageReference retval = new PageReference(retURL);
		if(anchor != null) {
			retval.setAnchor(anchor);
		}
		retval.setRedirect(true);
		return retval;
	}

}