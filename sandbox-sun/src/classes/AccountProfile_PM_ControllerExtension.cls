/**
 * This is a controller extension of the Account_Profile__c class to
 * view Account_Profile_Power_Map__c records.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-08-01
 * 2013-08-01 - Added field to Power Map table
 * 2013-01-10 - Created based on AccountProfile_PS_ControllerExtension.
 */
public with sharing class AccountProfile_PM_ControllerExtension {
	final Account_Profile__c accountProfile;
	
	/**
	 * Standard controller extension constructor.
	 * @param stdController the StandardController for Account_Profile__c objects.
	 */
	public AccountProfile_PM_ControllerExtension(ApexPages.StandardController stdController) {
		accountProfile=(Account_Profile__c)stdController.getRecord();
	}
	
	/** The field Id for Account_Profile_Power_Map.Account_Profile__c */
	public String accountProfileFieldId {
		get {
			// we can replace this with a hardcoded value once the code has been deployed in prod
			return StringSetting__c.getInstance(AccountProfilePowerMap_ControllerExtn.ACCOUNT_PROFILE_FIELD_KEY).Value__c;
		}
	}
	
	/**
	 * Query the list of Account_Profile_Power_Map__c records and return them as a list
	 */
	public List<PowerMapEntry> getPowerMap() {
		List<PowerMapEntry> powerMap = new List<PowerMapEntry>();
		for(Account_Profile_Power_Map__c pm : [
			select
				Name,
				Account_Profile__c,
				Business_Agenda__c,
				CustomerKeyContact__r.Name,
				CustomerKeyContact__r.ReportsTo.Name,
				Personal_Agenda__c,
				Point_Person_on_Red_Hat_Account_Team__c,
				Reports_To__c,
				Title__c,
				Your_Relationship__c			
			from Account_Profile_Power_Map__c 
			where Account_Profile__c = :accountProfile.Id
			order by CreatedDate])
		{
			powerMap.add(new PowerMapEntry(pm));
		}

		return powerMap;
	}
	
	/**
	 * Called to add an Account_Profile_Power_Map__c record.
	 * @return null
	 */
	public PageReference addPowerMapEntry() {
		Schema.DescribeSObjectResult describeResult = Account_Profile_Power_Map__c.sObjectType.getDescribe();
		return new PageReference('/'+describeResult.getKeyPrefix()+'/e?CF'+accountProfileFieldId+'_lkid='+accountProfile.Id+'&CF'+accountProfileFieldId+'='+accountProfile.Name+'&retURL='+accountProfile.Id+'%23PowerMap_target&saveURL='+accountProfile.Id+'%23PowerMap_target');
	}
	
	public class PowerMapEntry {
		/**
		 * Simple constructor.
		 * @param xaccountProfile_PowerMapEntry the Account_Profile_Power_Map__c record to manage
		 */
		public PowerMapEntry(Account_Profile_Power_Map__c xaccountProfile_PowerMapEntry) {
			accountProfile_PowerMapEntry = xaccountProfile_PowerMapEntry;
		}

		/** The Account_Profile_Power_Map__c object passed in the constructor. */
		public Account_Profile_Power_Map__c accountProfile_PowerMapEntry {
			get;
			private set;
		}

		/**
		 * Called to delete the Account_Profile_Power_Map__c record.
		 * @return null
		 */
		public PageReference deletePowerMapEntry() {
			try {
				delete accountProfile_PowerMapEntry;
			}
			catch(Exception ex) {
				ApexPages.addMessages(ex);
			}
			return null;
		}

		/**
		 * Called to edit the Account_Profile_Power_Map__c record.
		 * @return null
		 */
		public PageReference editPowerMapEntry() {
			return new PageReference('/'+accountProfile_PowerMapEntry.Id+'/e?retURL='+accountProfile_PowerMapEntry.Account_Profile__c+'%23PowerMap_target');
		}
		
		/**
		 * Called to view the Account_Profile_Power_Map__c record.
		 * @return null
		 */
		public PageReference viewPowerMapEntry() {
			return new PageReference('/'+accountProfile_PowerMapEntry.Id);
		}
	}
}