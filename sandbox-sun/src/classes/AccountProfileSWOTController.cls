/**
 * This class is for visualizing the AccountProfileSWOT data.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-11-08
 * 2012-11-08 - created
 */
public with sharing class AccountProfileSWOTController {
	/** Red Hat Strength picklist value. */
	public static final String STRENGTH='Red Hat Strength';
	/** Red Hat Weakness picklist value. */
	public static final String WEAKNESS='Red Hat Weakness';
	/** Account Opportunity picklist value. */
	public static final String OPPORTUNITY='Account Opportunity';
	/** Account Threat picklist value. */
	public static final String THREAT='Account Threat';

	/** Account_Profile__c object Id. */
	public Id accountProfileId { get; set; }

	/** 
	 * Query the Account_Profile__c object.
	 * @return the object found, or a newly created object.
	 */
	public Account_Profile__c getAccountProfile() {
		Account_Profile__c accountProfile = new Account_Profile__c(Id=accountProfileId);
		for(Account_Profile__c ap : [
			select
				(	select
						Account_Profile__c,
						Statement__c,
						Type__c
					from Account_Profile_SWOTs__r
					order by Type__c, Statement__c )
			from Account_Profile__c 
			where Id = :accountProfileId] )
		{
			accountProfile = ap;
		}
		return accountProfile;
	}

	/** List of SWOT Analysis objects. */
	public List<Account_Profile_SWOT__c> accountProfileSWOTs {
		get {
			if(accountProfileSWOTs == null && accountProfileId != null) {
				accountProfileSWOTs = getAccountProfile().Account_Profile_SWOTs__r;
			}
			return accountProfileSWOTs;
		}
		set;
	}

	/**
	 * Filter a list of SWOT Analysis objects based on Type__c value.
	 * @param unfilteredList the list to filter
	 * @param value to match to Type__c
	 * @return a list of SWOT Analysis objects.
	 */
	public static List<Account_Profile_SWOT__c> getFilteredList(List<Account_Profile_SWOT__c> unfilteredList,String value) {
		List<Account_Profile_SWOT__c> retval = new List<Account_Profile_SWOT__c>();
		if(unfilteredList != null) {
			for(Account_Profile_SWOT__c swot : unfilteredList) {
				if(swot.Type__c == value) {
					retval.add(swot);
				}
			}
		}
		return retval;
	}

	/**
	 * Build a list of SWOT Analysis objects for Red Hat Strengths.
	 * @return the filtered list
	 */
	public List<Account_Profile_SWOT__c> getStrengths() {
		return getFilteredList(accountProfileSWOTs,STRENGTH);
	}

	/**
	 * Build a list of SWOT Analysis objects for Red Hat Weaknesses.
	 * @return the filtered list
	 */
	public List<Account_Profile_SWOT__c> getWeaknesses() {
		return getFilteredList(accountProfileSWOTs,WEAKNESS);
	}

	/**
	 * Build a list of SWOT Analysis objects for Account Opportunities.
	 * @return the filtered list
	 */
	public List<Account_Profile_SWOT__c> getOpportunities() {
		return getFilteredList(accountProfileSWOTs,OPPORTUNITY);
	}

	/**
	 * Build a list of SWOT Analysis objects for Account Threats.
	 * @return the filtered list
	 */
	public List<Account_Profile_SWOT__c> getThreats() {
		return getFilteredList(accountProfileSWOTs,THREAT);
	}
}