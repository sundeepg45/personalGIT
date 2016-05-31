/**
 * This class is test class for AccountProfile_ComponentController.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-01-04
 * 2013-01-04 - Refactored from the ProfileComponentController.
 */
@isTest
private class AccountProfile_ComponentControllerTest {

	@isTest
	static void coverageTest()
	{
		RecordType recordType = [select Id,name from RecordType where name = 'Strategic' limit 1];
		Account account = new Account(name='account',RecordTypeId=recordType.Id,AccountClassification__c='Strategic',CurrencyIsoCode='USD');
		insert account;
		
		Partner_Profile__c partnerProfile = new Partner_Profile__c(Partner__c=account.Id);
		insert partnerProfile;
		AccountProfile_ComponentController controller = new AccountProfile_ComponentController();
		controller.partner_Profile = [ select Id, Partner__c, Partner__r.Id, Partner__r.CurrencyIsoCode from Partner_Profile__c where Id = :partnerProfile.Id ];
		System.assertEquals(0,controller.assessmentSummaryCount);
		System.assert(controller.partnerAssessmentSummaryCount >= 0);

		Account_Profile__c accountProfile = new Account_Profile__c(Account__c=account.Id);
		insert accountProfile;
		controller = new AccountProfile_ComponentController();
		accountProfile = [ select Id, Account__c, Account__r.Id, Account__r.CurrencyIsoCode from Account_Profile__c where Id = :accountProfile.Id ];
		controller.account_Profile = accountProfile;
		System.assert(controller.assessmentSummaryCount >= 0);
		System.assertEquals(0,controller.partnerAssessmentSummaryCount);
	}
}