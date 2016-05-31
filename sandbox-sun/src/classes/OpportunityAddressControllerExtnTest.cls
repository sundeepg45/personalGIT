/**
 * Test class for OpportunityAddressControllerExtension.cls
 *
 * @author Bill Riemers <briemers@redhat.com>
 * 
 * @version 2012-07-10
 * Modified: Bill Riemers <briemers@redhat.com>
 * 2012-07-10 - Corrected test failure
 * 2012-05-17 - refactored to a separate class, updated for SMR
 */
@isTest(SeeAllData=true) // need all data to access custom settings
private class OpportunityAddressControllerExtnTest {
	static Account account {
		get {
			if(account == null) {
				RecordType recordType = [
					select Name
					from RecordType
					where name = 'Strategic'
					limit 1];
				account = new Account(
					Name='account',
					RecordTypeId=recordType.Id,
					AccountClassification__c=recordType.Name);
				insert account;
			}
			return account;
		}
	}

	static User salesUser {
		get {
			if(salesUser == null) {
				TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
				System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
				salesUser = [
					select Email from User 
					where profileId = :salesUserProfileTesting.Id__c
						and IsActive = true limit 1 ];
			}
			return salesUser;
		}
	}

	static Opportunity opportunity {
		get {
			if(opportunity == null) {
				opportunity = new Opportunity(
					Name='OpportunityAddressControllerExtension Test',
					CloseDate=System.today(),
					StageName='Closed Booked',
					Owner=salesUser,
					DateOrderSubmitted__c=Datetime.newInstance(2009,1,1),
					AccountId=account.Id,
					Country_of_Order__c='India');
				insert opportunity;
				opportunity = [
					select 
						Name,
						CloseDate,
						StageName,
						OwnerId,
						Owner.Id,
						DateOrderSubmitted__c,
						AccountId,
						Account.Id,
						Country_of_Order__c
					from Opportunity
					where Id = : opportunity.Id ];
			}
			return opportunity;
		}
	}

	static testMethod void addressListTest() {
		ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
		OpportunityAddressControllerExtension controller = new OpportunityAddressControllerExtension(sc);
		System.assertEquals(0,controller.nonPrimaryBillingAddressList.size());
		System.assertEquals(0,controller.nonPrimaryShippingAddressList.size());
		NonPrimaryBillingAddress__c billingAddress = new NonPrimaryBillingAddress__c(
			Account__c=account.Id,BillingAddress__c='11 Foxtrot Drive',
			BillingCity__c='Stoney Creek',
			BillingState__c='ON',
			BillingZipPostalCode__c='L8J 3S8',
			CurrencyIsoCode='CAD'); 
		insert billingAddress;
		NonPrimaryShippingAddress__c shippingAddress = new NonPrimaryShippingAddress__c(
			Account__c=account.Id,ShippingAddress__c='11 Foxtrot Drive',
			ShippingCity__c='Stoney Creek',
			ShippingState__c='ON',
			ShippingZipPostalCode__c='L8J 3S8',
			CurrencyIsoCode='CAD');
		insert shippingAddress;
		controller = new OpportunityAddressControllerExtension(sc);
		System.assertEquals(1,controller.nonPrimaryBillingAddressList.size());
		System.assertEquals(1,controller.nonPrimaryShippingAddressList.size());
		System.assertEquals(0,controller.getShippingAccountList().size());
		System.assertEquals(0,controller.getBillingAccountList().size());
	}
}