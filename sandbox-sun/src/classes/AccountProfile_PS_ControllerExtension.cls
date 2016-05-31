/**
 * This is a controller extension of the Account_Profile__c class to
 * view AccountProfile_PartnerStatus__c records.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-01-07
 * 2013-01-07 - Created.
 */
public with sharing class AccountProfile_PS_ControllerExtension {
	final Account_Profile__c accountProfile;

	/**
	 * Standard controller extension constructor.
	 * @param stdController the StandardController for Account_Profile__c objects.
	 */
	public AccountProfile_PS_ControllerExtension(ApexPages.StandardController stdController)
	{
		accountProfile=(Account_Profile__c)stdController.getRecord();
	}

	/**
	 * Query the list of AccountPartner_PartnerStatus__c records and return them as a list
	 * of PartnerStatus class instances.
	 */
	public List<PartnerStatus> getPartnerStatuses() {
		List<PartnerStatus> partnerStatuses = new List<PartnerStatus>();
		for(AccountProfile_PartnerStatus__c apps : [
			select
				PartnerStatus__r.Partner__r.Name,
				PartnerStatus__r.Partner__r.Account_Alias_Name__c,
				PartnerStatus__r.Partner__r.Site,
				PartnerStatus__r.Partner__r.OracleAccountNumber__c,
				PartnerStatus__r.Partner__r.Owner.Alias,
				PartnerStatus__r.Partner__r.RecordType.Name,
				PartnerStatus__r.Partner__r.Type,
				PartnerStatus__r.PartnerTier__r.Name,
				PartnerStatus__r.PartnerTier__r.Hierarchy__c,
				PartnerStatus__r.PartnerTier__r.IsActive__c,
				PartnerStatus__r.PartnerType__r.Name,
				PartnerStatus__r.PartnerType__r.Hierarchy__c,
				PartnerStatus__r.PartnerType__r.IsActive__c
			from AccountProfile_PartnerStatus__c 
			where Account_Profile__c = :accountProfile.Id
			order by PartnerStatus__r.Partner__r.Name,
				PartnerStatus__r.PartnerType__r.Hierarchy__c,
				PartnerStatus__r.PartnerTier__r.Hierarchy__c,
				PartnerStatus__r.Partner__r.RecordType.Name,
				PartnerStatus__r.Partner__r.Site,
				PartnerStatus__r.Partner__r.OracleAccountNumber__c ])
		{
			partnerStatuses.add(new PartnerStatus(apps,apps.PartnerStatus__r));
		}
		return partnerStatuses;
	}

	/**
	 * Called to managed preferred partner records.
	 * @return page reference
	 */
	public PageReference managePreferredPartners() {
		PageReference retval = new PageReference('/apex/AccountProfile_PS_Manage');
		retval.getParameters().put('id',accountProfile.Id);
		retval.getParameters().put('retURL','/'+accountProfile.Id+'#PreferredPartners_target');
		retval.setRedirect(true);
		return retval;
	}

	/**
	 * Class to manage the actions for AccountProfile_PartnerStatus__c records.
	 */
	public class PartnerStatus {
		/**
		 * Simple constructor.
		 * @param xaccountProfile_PartnerStatus the AccountProfile_PartnerStatus__c record to manage
		 * @param xpartnerStatus the PartnerStatus__c associated with this record
		 */
		public PartnerStatus(AccountProfile_PartnerStatus__c xaccountProfile_PartnerStatus,PartnerStatus__c xpartnerStatus) {
			accountProfile_PartnerStatus = xaccountProfile_PartnerStatus;
			partnerStatus = xpartnerStatus;
		}

		/** The AccountProfile_PartnerStatus__c object passed in the constructor. */
		public AccountProfile_PartnerStatus__c accountProfile_PartnerStatus {
			get;
			private set;
		}

		/** The PartnerStatus__c object passed in the constructor. */
		public PartnerStatus__c partnerStatus {
			get;
			private set;
		}

		/**
		 * Called to upsert the accountProfile_PartnerStatus record.
		 * @return null
		 */
		public PageReference addPartnerStatus() {
			try {
				upsert accountProfile_PartnerStatus;
			}
			catch(Exception ex) {
				ApexPages.addMessages(ex);
			}
			return null;
		}

		/**
		 * Called to delete the accountProfile_PartnerStatus record.
		 * @return null
		 */
		public PageReference deletePartnerStatus() {
			try {
				delete accountProfile_PartnerStatus;
			}
			catch(Exception ex) {
				ApexPages.addMessages(ex);
			}
			return null;
		}
	}
}