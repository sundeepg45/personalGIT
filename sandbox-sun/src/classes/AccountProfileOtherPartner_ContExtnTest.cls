/**
 * This class is a set of unit tests for the AccountProfile_OP_SetController class.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-01-22
 * 2012-01-22 - created
 */
@isTest
private class AccountProfileOtherPartner_ContExtnTest {

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
					Account__c = account.Id,
					Name = 'test profile');
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
	
	static ApexPages.StandardController standardController {
		get {
			if(standardController == null) {
				standardController = new ApexPages.StandardController(otherPartner);
			}
			return standardController;
		}
	}

	static AccountProfileOtherPartner_ContExtn controller {
		get {
			if(controller == null) {
				controller = new AccountProfileOtherPartner_ContExtn(standardController);
			}
			return controller;
		}
	}
	
	static AccountProfileOtherPartner_ContExtn brokenController {
		get {
			if(brokenController == null) {
				brokenController = new AccountProfileOtherPartner_ContExtn(null);
			}
			return brokenController;
		}
	}

	@isTest
	static void testController() {
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert new StringSetting__c(Name=AccountProfileOtherPartner_ContExtn.ACCOUNT_PROFILE_FIELD_KEY,Value__c='000000000000000');
		}
		Test.startTest();
		PageReference accountProfileViewPage = new PageReference('/'+accountProfile.Id);
		accountProfileViewPage.setAnchor('AccountObjectives_target');		
		String returnURL = '/'+accountProfile.Id;
		Schema.DescribeSObjectResult describeResult = standardController.getRecord().getSObjectType().getDescribe();
		PageReference otherPartnerNewPage = new PageReference('/' + describeResult.getKeyPrefix() + '/e');
		otherPartnerNewPage.getParameters().put('CF'+controller.accountProfileFieldId, accountProfile.Name);
		otherPartnerNewPage.getParameters().put('CF'+controller.accountProfileFieldId+'_lkid', accountProfile.Id);
		otherPartnerNewPage.getParameters().put('retURL', returnURL);
		Test.setCurrentPage(otherPartnerNewPage);
		// test Save and New action
		controller = null;
		PageReference saveAndNewReturn = controller.saveAndNew();
		System.assertEquals(otherPartnerNewPage.getUrl(),saveAndNewReturn.getUrl());
		// test Save action
		PageReference saveReturn = controller.saveAndReturn();
		System.assertEquals(accountProfileViewPage.getUrl(),saveReturn.getUrl());
		// test Cancel action
		PageReference cancelReturn = controller.cancelAndReturn();
		System.assertEquals(accountProfileViewPage.getUrl(),cancelReturn.getUrl());
		// test Partner type list
		Classification__c parentClassification = new Classification__c(Name='Partner Type', ReferenceKey__c='PARTNER_TYPE', IsActive__c = true);
		insert parentClassification;
		insert new Classification__c(Name='Test', ReferenceKey__c='TEST', IsActive__c = true, Parent__c = parentClassification.Id);
		List<SelectOption> partnerTypeList = controller.getPartnerTypeList();
		System.assertEquals(2,partnerTypeList.size());
		// test Save and New action exception
		try {
			brokenController.saveAndNew();
		}
		catch (Exception e) {
			System.assert(ApexPages.hasMessages());
		}
		// test Save action exception
		try {
			brokenController.saveAndReturn();
		}
		catch (Exception e) {
			System.assert(ApexPages.hasMessages());
		}
		// test Cancel action exception
		try {
			brokenController.cancelAndReturn();
		}
		catch (Exception e) {
			System.assert(ApexPages.hasMessages());
		}
		Test.stopTest();	
	}
}