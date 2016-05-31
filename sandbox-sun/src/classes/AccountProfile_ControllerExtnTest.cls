/**
 * This class is a set of unit tests for the AccountProfile_ControllerExtension class.
 *
 * @version 2015-10-27
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-10-27 - Added getter test
 * 2014-02-05 - Added tests for getPotentialOpportunitiesReportId and getTotalSpentReportId
 * 2013-06-21 - created
 * Scott Coleman <scoleman@redhat.com>
 * 2013-09-05 - added test for trigger AccountProfile_SetCurrency
 */
@isTest
private class AccountProfile_ControllerExtnTest {
	static Account account {
		get {
			if(account == null) {
				RecordType recordType = [select Id,name from RecordType where SObjectType = 'Account' limit 1];
				account = new Account(
						Name='customer',
						RecordTypeId=recordType.Id,
						AccountClassification__c=recordType.Name,
						BillingCountry = 'US',
						CurrencyIsoCode='USD');
				insert account;
			}
			return account;
		}
	}

	static Account_Profile__c accountProfile {
		get {
			if(accountProfile == null) {
				accountProfile = new Account_Profile__c(
					Account__c = account.Id);
				insert accountProfile;
			}
			return accountProfile;
		}
	}

	@isTest
	static void customSettingsTest() {
		ApexPages.StandardController sc = new ApexPages.StandardController(accountProfile);
		AccountProfile_ControllerExtension controller = new AccountProfile_ControllerExtension(sc);
		insert new BooleanSetting__c(Name=AccountProfile_ControllerExtension.SHOW_SUMMARY_SETTING,Value__c=false);
		System.assertNotEquals(null,controller.getShowSummary());
		insert new StringSetting__c(Name=AccountProfile_ControllerExtension.POTENTIAL_SPENDING_SETTING,Value__c='00O60000003cr02');
		System.assertNotEquals(null,controller.getPotentialSpendingReportId());
		insert new StringSetting__c(Name=AccountProfile_ControllerExtension.TOTAL_SPEND_SETTING,Value__c='00O60000003cr02');
		System.assertNotEquals(null,controller.getTotalSpendReportId());

	}

	@isTest
	static void getterTest() {
		ApexPages.StandardController sc = new ApexPages.StandardController(accountProfile);
		AccountProfile_ControllerExtension controller = new AccountProfile_ControllerExtension(sc);
		PageReference pageRef = Page.AccountProfile_View;
		Test.setCurrentPage(pageRef);
		System.assertEquals(false,controller.getIsRenderAsPDF());
		System.assertEquals(false,controller.getIsPrintableView());
		System.assertEquals(false,controller.getIsInfrastructureView());
		System.assertEquals(false,controller.getIsTopView());
		System.assertEquals(true,controller.getIsFullView());
	}

	@isTest
	static void currencyTest() {
		Account_Profile__c testProfile = accountProfile;
		List<Account_Profile__c> accountProfiles = [SELECT Id, CurrencyIsoCode FROM Account_Profile__c WHERE Id = :testProfile.Id];
		testProfile = accountProfiles[0];
		System.assertEquals(account.CurrencyIsoCode,testProfile.CurrencyIsoCode);
	}
}