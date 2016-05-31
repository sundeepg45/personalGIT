/**
 * This is a controller extension of the Account_Profile__c class to
 * view Account_Profile_Other_Partner__c records.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-01-22
 * 2013-01-08 - Created based on AccountProfile_PS_ControllerExtension.
 * 2013-01-22 - Updated actions to support new/edit VisualForce page for Account_Profile_Other_Partner__c
 */
public with sharing class AccountProfile_OP_ControllerExtension {	
	final Account_Profile__c accountProfile;
	
	/**
	 * Standard controller extension constructor.
	 * @param stdController the StandardController for Account_Profile__c objects.
	 */
	public AccountProfile_OP_ControllerExtension(ApexPages.StandardController stdController) {
		accountProfile=(Account_Profile__c)stdController.getRecord();
	}
	
	/** The field Id for Account_Profile_Other_Partner__c.Account_Profile__c */
	public String accountProfileFieldId {
		get {
			if (accountProfileFieldId == null) {
				accountProfileFieldId = StringSetting__c.getInstance(AccountProfileOtherPartner_ContExtn.ACCOUNT_PROFILE_FIELD_KEY).Value__c;
			}
			// we can replace this with a hardcoded value once the code has been deployed in prod
			return accountProfileFieldId;
		}
		private set{}
	}	

	/**
	 * Query the list of Account_Profile_Other_Partner__c records and return them as a list
	 */
	public List<OtherPartner> getOtherPartners() {
		List<OtherPartner> otherPartners = new List<OtherPartner>();
		for(Account_Profile_Other_Partner__c op : [
			select
				Name,
				Account_Profile__c,
				Account_Profile__r.Name,
				Partner_Type__r.Name
			from Account_Profile_Other_Partner__c 
			where Account_Profile__c = :accountProfile.Id
			order by CreatedDate])
		{
			otherPartners.add(new OtherPartner(op,accountProfileFieldId));
		}

		return otherPartners;
	}
	
	/**
	 * Called to add an accountProfile_PartnerStatus record.
	 * @return null
	 */
	public PageReference addOtherPartner() {
		Schema.DescribeSObjectResult describeResult = Account_Profile_Other_Partner__c.sObjectType.getDescribe();
		return new PageReference('/'+describeResult.getKeyPrefix()+'/e?CF'+accountProfileFieldId+'_lkid='+accountProfile.Id+'&CF'+accountProfileFieldId+'='+accountProfile.Name+'&retURL='+accountProfile.Id+'%23AccountObjectives_target&saveURL='+accountProfile.Id+'%23AccountObjectives_target');
	}

	public class OtherPartner {
		private String accountProfileFieldId;

		/**
		 * Simple constructor.
		 * @param xaccountProfile_OtherPartner the Account_Profile_Other_Partner__c record to manage
		 */
		public OtherPartner(Account_Profile_Other_Partner__c xaccountProfile_OtherPartner, String xaccountProfileFieldId) {
			accountProfile_OtherPartner = xaccountProfile_OtherPartner;
			accountProfileFieldId = xaccountProfileFieldId;
		}

		/** The Account_Profile_Other_Partner__c object passed in the constructor. */
		public Account_Profile_Other_Partner__c accountProfile_OtherPartner {
			get;
			private set;
		}

		/**
		 * Called to delete the Account_Profile_Other_Partner__c record.
		 * @return null
		 */
		public PageReference deleteOtherPartner() {
			try {
				delete accountProfile_OtherPartner;
			}
			catch(Exception ex) {
				ApexPages.addMessages(ex);
			}
			return null;
		}

		/**
		 * Called to edit the Account_Profile_Other_Partner__c record.
		 * @return null
		 */
		public PageReference editOtherPartner() {
			return new PageReference('/'+accountProfile_OtherPartner.Id+'/e?CF'+accountProfileFieldId+'_lkid='+accountProfile_OtherPartner.Account_Profile__c+'&CF'+accountProfileFieldId+'='+accountProfile_OtherPartner.Account_Profile__r.Name+'&retURL='+accountProfile_OtherPartner.Account_Profile__c+'%23AccountObjectives_target&saveURL='+accountProfile_OtherPartner.Account_Profile__c+'%23AccountObjectives_target');
		}
	}
}