/**
 * This class is a very simple controller extension that allows us
 * to create Account_Profile_Power_Map__c objects without having to
 * manually populate the Account__c field.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-11-13
 * 2012-11-13 - created
 */
public with sharing class AccountProfilePowerMap_ControllerExtn {
	/** Custom setting name for the field Id of Account_Profile_Power_Map.Account_Profile__c */
	public static final String ACCOUNT_PROFILE_FIELD_KEY = 'PowerMap.AccountProfileCF';
	/** Custom setting name for the field Id of Account_Profile_Power_Map.Account__c */
	public static final String ACCOUNT_FIELD_KEY = 'PowerMap.AccountCF';

	/** The Account_Profile_Power_Map__c Id. */
	private final Id recordId;
	/** The Account_Profile_Power_Map__c object. */
	private final Account_Profile_Power_Map__c powerMap;

	/**
	 * ControllerExtension constructor.
	 * @param stdController
	 */
	public AccountProfilePowerMap_ControllerExtn(ApexPages.StandardController stdController) {
		this.recordId = stdController.getId();
		this.powerMap = (Account_Profile_Power_Map__c)stdController.getRecord();
	}

	/** The field Id for Account_Profile_Power_Map.Account_Profile__c */
	public String accountProfileFieldId {
		get {
			// we can replace this with a hardcoded value once the code has been deployed in prod
			return StringSetting__c.getInstance(ACCOUNT_PROFILE_FIELD_KEY).Value__c;
		}
	}

	/** The field Id for Account_Profile_Power_Map.Account__c */
	public String accountFieldId {
		get {
			// we can replace this with a hardcoded value once the code has been deployed in prod
			return StringSetting__c.getInstance(ACCOUNT_FIELD_KEY).Value__c;
		}
	}

	/** The first three charactors of Account_Profile_Power_Map.Id values */
	public String objectPrefix {
		get { 
			// we can replace this with a hardcoded value once the code has been deployed in prod
			return Account_Profile_Power_Map__c.SObjectType.getDescribe().getKeyPrefix();
		}
	}

	/** Query the Account_Profile__c parent for this record. */
	public Account_Profile__c accountProfile {
		get {
			if(accountProfile == null) {
				System.debug('PageReference='+ApexPages.currentPage());
				Id accountProfileId = (Id)ApexPages.currentPage().getParameters().get('CF'+accountProfileFieldId+'_lkid');
				System.debug('accountProfileId='+accountProfileId);
				if(accountProfileId == null && powerMap != null) {
					accountProfileId = powerMap.Account_Profile__c;
				}
				Id accountId = null;
				if(accountProfileId == null) {
					accountId = (Id)ApexPages.currentPage().getParameters().get('CF'+accountFieldId+'_lkid');
				}
				System.debug('accountId='+accountId);
				for(Account_Profile__c ap : [
					select Account__r.Name, Name
					from Account_Profile__c
					where Id = :accountProfileId 
						or Account__c = :accountId ])
				{
					accountProfile = ap;
				}
			}
			return accountProfile;
		}
		set;
	}
}