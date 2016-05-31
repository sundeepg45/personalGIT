/**
 * This class is a set of unit tests for the AccountProfile_Env_ControllerExtension class.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-04-25
 * 2013-04-25 - created
 */
@isTest
private class AccountProfile_Env_ControllerExtnTest {
	public static Account account {
		get {
			if(account == null) {
				RecordType recordType = [select Id,name from RecordType where SObjectType = 'Account' limit 1];
				account = new Account(
						Name='customer',
						RecordTypeId=recordType.Id,
						AccountClassification__c=recordType.Name,
						BillingCountry = 'US');
				insert account;
			}
			return account;
		}
	}

	public static Account_Profile__c accountProfile {
		get {
			if(accountProfile == null) {
				accountProfile = new Account_Profile__c(
					Account__c = account.Id);
				insert accountProfile;
			}
			return accountProfile;
		}
	}
	
	public static Environment__c environment {
		get {
			if (environment == null) {
				environment = new Environment__c(
					Account_Profile__c = accountProfile.Id,
					Name = 'Test Environment');
				insert environment;
			}
			return environment;
		}
	}

	static AccountProfile_Env_ControllerExtension controller {
		get {
			if(controller == null) {
				ApexPages.StandardController sc = new ApexPages.StandardController(accountProfile);
				controller = new AccountProfile_Env_ControllerExtension(sc);
			}
			return controller;
		}
	}

	@isTest
	static void testController() {
		insert new StringSetting__c(Name=AccountProfile_Env_ControllerExtension.ACCOUNT_PROFILE_FIELD_KEY,Value__c='TEST');
		System.assertEquals(0,controller.getEnvironments().size());
		PageReference newPage = controller.addEnvironment();
		System.assertNotEquals(null, newPage);
		Environment__c env = environment;
		List<AccountProfile_Env_ControllerExtension.Environment> envs = controller.getEnvironments();
		System.assertEquals(1,envs.size());
		PageReference editPage = envs[0].editEnvironment();
		System.assertNotEquals(null, editPage);
		PageReference viewPage = envs[0].viewEnvironment();
		System.assertNotEquals(null, viewPage);
		PageReference deletePage = envs[0].deleteEnvironment();
		System.assertEquals(null, deletePage);
		System.assertEquals(0,controller.getEnvironments().size());
		AccountProfile_Env_ControllerExtension.Environment apenv = new AccountProfile_Env_ControllerExtension.Environment(null);
		apenv.deleteEnvironment();
	}
}