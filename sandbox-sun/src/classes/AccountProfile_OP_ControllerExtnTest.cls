/**
 * This class is a set of unit tests for the AccountProfile_OP_SetController class.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-01-10
 * 2012-01-10 - created
 */
@isTest
private class AccountProfile_OP_ControllerExtnTest {
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
	
	public static Account_Profile_Other_Partner__c otherPartner {
		get {
			if (otherPartner == null) {
				otherPartner = new Account_Profile_Other_Partner__c(
					Account_Profile__c = accountProfile.Id);
				insert otherPartner;
			}
			return otherPartner;
		}
	}

	static AccountProfile_OP_ControllerExtension controller {
		get {
			if(controller == null) {
				ApexPages.StandardController sc = new ApexPages.StandardController(accountProfile);
				controller = new AccountProfile_OP_ControllerExtension(sc);
			}
			return controller;
		}
	}

	@isTest
	static void testController() {
		insert new StringSetting__c(Name=AccountProfileOtherPartner_ContExtn.ACCOUNT_PROFILE_FIELD_KEY,Value__c='000000000000000');
		System.assertEquals(0,controller.getOtherPartners().size());
		PageReference newPage = controller.addOtherPartner();
		System.assertNotEquals(null, newPage);
		Account_Profile_Other_Partner__c op = otherPartner;
		List<AccountProfile_OP_ControllerExtension.OtherPartner> ops = controller.getOtherPartners();
		System.assertEquals(1,ops.size());
		PageReference editPage = ops[0].editOtherPartner();
		System.assertNotEquals(null, editPage);
		PageReference deletePage = ops[0].deleteOtherPartner();
		System.assertEquals(null, deletePage);
		System.assertEquals(0,controller.getOtherPartners().size());
		AccountProfile_OP_ControllerExtension.OtherPartner apop = new AccountProfile_OP_ControllerExtension.OtherPartner(null,null);
		apop.deleteOtherPartner();
	}
}