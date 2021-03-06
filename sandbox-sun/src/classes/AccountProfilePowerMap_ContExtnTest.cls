/**
 * This is a test class for AccountProfilePowerMap_ControllerExtension.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-11-13
 * 2012-11-13 - created
 */
@isTest
private class AccountProfilePowerMap_ContExtnTest {
	static final String ACCOUNT_FIELD_ID='00Ng0000000OC9h';

	static final String ACCOUNT_PROFILE_FIELD_ID='00Ng0000000OC9c';

	static String BASE_URL = 'https://c.cs17.visual.force.com/apex/AccountProfilePowerMap_New/e?saveURL=%2Fa0Ng0000000ChKfEAK&returnURL=%2Fa0Ng0000000ChKfEAK';
	static String ACCOUNT_FIELD_PARAMS {
		get {
			return '&CF'+ACCOUNT_FIELD_ID+'='+EncodingUtil.urlEncode(AccountProfileSWOTControllerTest.account.Name,'UTF8')+
				'&CF'+ACCOUNT_FIELD_ID+'_lkid='+AccountProfileSWOTControllerTest.accountId;
		}
	}
	static String ACCOUNT_PROFILE_FIELD_PARAMS {
		get {
			return '&CF'+ACCOUNT_PROFILE_FIELD_ID+'=AutoGenerated'+
				'&CF'+ACCOUNT_PROFILE_FIELD_ID+'_lkid='+AccountProfileSWOTControllerTest.accountProfileId;
		}
	}

	static AccountProfilePowerMap_ControllerExtn getController() {
		return getController(new Account_Profile_Power_Map__c());
	}

	static AccountProfilePowerMap_ControllerExtn getController(Account_Profile_Power_Map__c value) {
		ApexPages.StandardController sc = new ApexPages.StandardController(value);
		return new AccountProfilePowerMap_ControllerExtn(sc);
	}

	static void insertStringSettings() {
		insert new StringSetting__c(Name=AccountProfilePowerMap_ControllerExtn.ACCOUNT_PROFILE_FIELD_KEY,Value__c=ACCOUNT_PROFILE_FIELD_ID);
		insert new StringSetting__c(Name=AccountProfilePowerMap_ControllerExtn.ACCOUNT_FIELD_KEY,Value__c=ACCOUNT_FIELD_ID);
	}

	@isTest
	static void accountProfileTest() {
		insertStringSettings();
		// the normal use case
		PageReference pageRef = new PageReference(BASE_URL+'&'+ACCOUNT_PROFILE_FIELD_PARAMS);
		Test.setCurrentPage(pageRef);
		AccountProfilePowerMap_ControllerExtn controller = getController();
		System.assertEquals(ACCOUNT_FIELD_ID,controller.accountFieldId);
		System.assertEquals(ACCOUNT_PROFILE_FIELD_ID,controller.accountProfileFieldId);
		System.assertNotEquals(null,controller.objectPrefix);
		Account_Profile__c ap = controller.accountProfile;
		System.assertNotEquals(null,ap);
		System.assertEquals(AccountProfileSWOTControllerTest.accountProfileId,ap.Id);
		System.assertEquals(AccountProfileSWOTControllerTest.accountId,ap.Account__c);
		// Test this scenario just incase we start using it
		pageRef = new PageReference(BASE_URL+'&'+ACCOUNT_FIELD_PARAMS);
		Test.setCurrentPage(pageRef);
		controller = getController();
		ap = controller.accountProfile;
		System.assertEquals(AccountProfileSWOTControllerTest.accountProfileId,ap.Id);
		System.assertEquals(AccountProfileSWOTControllerTest.accountId,ap.Account__c);
	}
}