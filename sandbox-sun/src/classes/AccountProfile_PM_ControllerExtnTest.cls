/**
 * This class is a set of unit tests for the AccountProfile_PM_SetController class.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-01-10
 * 2012-01-10 - created
 */
@isTest
private class AccountProfile_PM_ControllerExtnTest {
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
	
	public static Contact contact {
		get {
			if(contact == null) {
				contact = new Contact(
					AccountId = account.Id,
					Email='test@redhat.com',
					FirstName='John',
					LastName='Smith');
				insert contact;
			}
			return contact;
		}
	}
	
	public static Account_Profile_Power_Map__c powerMapEntry {
		get {
			if (powerMapEntry == null) {
				powerMapEntry = new Account_Profile_Power_Map__c(
					Account_Profile__c = accountProfile.Id,
					Account__c = account.Id,
					CustomerKeyContact__c = contact.Id);
				insert powerMapEntry;
			}
			return powerMapEntry;
		}
	}

	static AccountProfile_PM_ControllerExtension controller {
		get {
			if(controller == null) {
				ApexPages.StandardController sc = new ApexPages.StandardController(accountProfile);
				controller = new AccountProfile_PM_ControllerExtension(sc);
			}
			return controller;
		}
	}

	@isTest
	static void testController() {
		insert new StringSetting__c(Name=AccountProfilePowerMap_ControllerExtn.ACCOUNT_PROFILE_FIELD_KEY,Value__c='TEST');
		System.assertEquals(0,controller.getPowerMap().size());
		PageReference newPage = controller.addPowerMapEntry();
		System.assertNotEquals(null, newPage);
		Account_Profile_Power_Map__c pm = powerMapEntry;
		List<AccountProfile_PM_ControllerExtension.PowerMapEntry> pme = controller.getPowerMap();
		System.assertEquals(1,pme.size());
		PageReference editPage = pme[0].editPowerMapEntry();
		System.assertNotEquals(null, editPage);
		PageReference viewPage = pme[0].viewPowerMapEntry();
		System.assertNotEquals(null, viewPage);
		PageReference deletePage = pme[0].deletePowerMapEntry();
		System.assertEquals(null, deletePage);
		System.assertEquals(0,controller.getPowerMap().size());
		AccountProfile_PM_ControllerExtension.PowerMapEntry appm = new AccountProfile_PM_ControllerExtension.PowerMapEntry(null);
		appm.deletePowerMapEntry();
	}
}