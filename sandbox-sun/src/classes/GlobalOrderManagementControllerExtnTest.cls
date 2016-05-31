/**
 * This is the test class for GlobalOrderManagementController.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-05-11
 *
 * Nitesh Dokania
 * 2011-09-12 Test coverage enhanced
 * Bill C Riemers <briemers@redhat.com>
 * 2012-05-11 Updated for SMR
 */
@isTest(SeeAllData=true) // need all data to access custom settings
private class GlobalOrderManagementControllerExtnTest
{
	static Account account {
		get {
			if(account == null) {
				RecordType recordType = [select Name from RecordType where name = 'Strategic' limit 1];
				account = new Account(Name='account',RecordTypeId=recordType.Id,AccountClassification__c='Strategic');
				insert account;
			}
			return account;
		}
	}

	static User emeaUser {
		get {
			if(emeaUser == null) {
				TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
				TestingIds__c salesUserProfileTesting2 = TestingIds__c.getValues('Sales User Profile 2');
				System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
				System.assertNotEquals(null,salesUserProfileTesting2,'"Sales User Profile 2" needs to be set in the TestingIds__c');
				emeaUser = [
					select Region__c
					from User
					where Region__c='EMEA'
						and ProfileId in (:salesUserProfileTesting.Id__c, :salesUserProfileTesting2.Id__c)
						and IsActive = true
					limit 1];
			}
			return emeaUser;
		}
	}

	static User naUser {
		get {
			if(naUser == null) {
				TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
				TestingIds__c salesUserProfileTesting2 = TestingIds__c.getValues('Sales User Profile 2');
				System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
				System.assertNotEquals(null,salesUserProfileTesting2,'"Sales User Profile 2" needs to be set in the TestingIds__c');
				naUser = [
					select Region__c
					from User
					where Region__c='NA'
						and ProfileId in (:salesUserProfileTesting.Id__c, :salesUserProfileTesting2.Id__c)
						and IsActive = true
					limit 1];
			}
			return naUser;
		}
	}

	static Opportunity emeaOpportunity {
		get {
			if(emeaOpportunity == null) {
				emeaOpportunity = new Opportunity(Name='GlobalOrderManagementControllerExtension EMEA Test',closedate=System.today(),stageName='Closed Booked',owner=emeaUser,account=account,Country_of_Order__c ='India',ContractStartDate__c=System.today());
				insert emeaOpportunity;
			}
			return emeaOpportunity;
		}
	}

	static Opportunity naOpportunity {
		get {
			if(naOpportunity == null) {
				naOpportunity = new Opportunity(Name='GlobalOrderManagementControllerExtension APAC Test',closedate=System.today(),stageName='Closed Booked',owner=naUser,account=account,Country_of_Order__c ='India');
				insert naOpportunity;
			}
			return naOpportunity;
		}
	}
	
	static Opportunity globalOpportunity {
		get {
			if(globalOpportunity == null) {
				globalOpportunity = new Opportunity(Name='GlobalOrderManagementControllerExtension Global Test',closedate=System.today(),stageName='Closed Booked',account=account,Country_of_Order__c ='India');
				insert globalOpportunity;
			}
			return globalOpportunity;
		}
	}

	static Contact contact{
		get {
				contact = new Contact(LastName='GOM Test',account=account,email ='test@niTest.com');
				insert contact;
				return contact;
		}
	}
	
	static OpportunityContactRole oppConRoleShipping{
		get {
				oppConRoleShipping = new OpportunityContactRole(OpportunityId=emeaOpportunity.Id,Role = 'Payables Contact',ContactId=contact.Id);
				insert oppConRoleShipping;
				return oppConRoleShipping;
		}
	}
	
	static OpportunityContactRole oppConRolePaybles{
		get {
				oppConRolePaybles = new OpportunityContactRole(OpportunityId=emeaOpportunity.Id,Role = 'Shipping Contact',ContactId=contact.Id);
				insert oppConRolePaybles;
				return oppConRolePaybles;
		}
	}
	
	static Quote__c activeQuote {
		get {
			if(activeQuote == null) {
				activeQuote = new Quote__c(Amount__c=0,LastCalculatedDate__c=Datetime.newInstance(2009,1,1),IsActive__c=true,OpportunityId__c=naOpportunity.Id);
				insert activeQuote;
			}
			return activeQuote;
		}
	}

	/*static GlobalOrderManagementControllerExtension getController(Opportunity opp) {
		ApexPages.StandardController sc = new ApexPages.StandardController(opp);
		return new GlobalOrderManagementControllerExtension(sc);
	}*/

	// This method calls methods to test them in the trivial case.
	@isTest
	static void trivialTests()
	{
		System.assertNotEquals(null,activeQuote);
		List<Credit__c> creditList = new List<Credit__c>();
		OpportunityContactRole oppConRoleShippin = new OpportunityContactRole(OpportunityId=emeaOpportunity.Id,Role = 'Payables Contact',ContactId=contact.Id);
				insert oppConRoleShippin;
		OpportunityContactRole oppConRolePayble = new OpportunityContactRole(OpportunityId=emeaOpportunity.Id,Role = 'Shipping Contact',ContactId=contact.Id);
				insert oppConRolePayble;
		Credit__c firstCredit = new Credit__c(isFinal__c=true,Opportunity__c=emeaOpportunity.Id);
		creditList.add(firstCredit);
		Credit__c secCredit = new Credit__c(Opportunity__c=emeaOpportunity.Id);
		creditList.add(secCredit);
		insert creditList;
		
		test.startTest();
		
		ApexPages.StandardController sc = new ApexPages.StandardController(emeaOpportunity);
		GlobalOrderManagementControllerExtension controller = new GlobalOrderManagementControllerExtension(sc);
		
		controller.getCredit();
		System.assertEquals(contact.LastName,controller.getShippingContact().Name);
		System.assertEquals(contact.LastName,controller.getPayableContact().Name);
		System.assertEquals(null,controller.getQuoteContact());
		System.assert(controller.getRecentApprovalCustomList().isEmpty());
		System.assert(controller.getOpportunityLineItemList().isEmpty());
		System.assertNotEquals(null,controller.getContractStartDate());
		System.assertEquals('',controller.getContractEndDate());
		System.assertEquals('',controller.getExpirationDate());
		System.assertEquals(null,controller.getQuoteContact());
		
		ApexPages.StandardController sct = new ApexPages.StandardController(globalOpportunity);
		GlobalOrderManagementControllerExtension cntroller = new GlobalOrderManagementControllerExtension(sct);
		cntroller.getCredit();
		
		test.stopTest();
	}

	// This method test the region checking code.
	@IsTest
	static void regionTests()
	{
		test.startTest();
		
		ApexPages.StandardController sc = new ApexPages.StandardController(emeaOpportunity);
		GlobalOrderManagementControllerExtension controller = new GlobalOrderManagementControllerExtension(sc);
		// test that the region is EMEA
		System.assert(! controller.getIsAPAC());
		System.assert(controller.getIsEMEA());
		System.assert(!controller.getIsLATAM());
		System.assert(!controller.getIsNA());	   
		
		ApexPages.StandardController scnt = new ApexPages.StandardController(naOpportunity);
		controller = new GlobalOrderManagementControllerExtension(scnt);
		// test that the region is NA
		System.assert(! controller.getIsAPAC());
		System.assert(! controller.getIsEMEA());
		System.assert(! controller.getIsLATAM());
		System.assert(controller.getIsNA());
		
		Quote__c activeQuotes = new Quote__c(ContactId__c=contact.Id,Amount__c=0,LastCalculatedDate__c=Datetime.newInstance(2009,1,1),IsActive__c=true,OpportunityId__c=naOpportunity.Id);
				insert activeQuotes;
		controller.getQuoteContact();
		
		test.stopTest();
	}

	@IsTest
	static void creditCardNumberTest() {
		System.runAs(new User(Id=UserInfo.getUserId())) {
			insert new GlobalOrderManagementConfig__c(SetupOwnerId = UserInfo.getUserId(),OperatingUnitsAllowedCCView__c='Canada,NA\n Ireland ');
		}
		naOpportunity.Credit_Card_Number__c = '1111222233334444';
		naOpportunity.Operating_Unit__c = null;
		ApexPages.StandardController sc = new ApexPages.StandardController(naOpportunity);
		GlobalOrderManagementControllerExtension controller = new GlobalOrderManagementControllerExtension(sc);
		Test.startTest();
		System.assertEquals('****-****-****-****',controller.getCreditCardNumber());
		naOpportunity.Operating_Unit__c = 'RH NA Operating Unit';
		System.assertEquals('1111-2222-3333-4444',controller.getCreditCardNumber());
		naOpportunity.Operating_Unit__c = 'RH Canada Operating Unit';
		System.assertEquals('1111-2222-3333-4444',controller.getCreditCardNumber());
		naOpportunity.Operating_Unit__c = 'RH Ireland Operating Unit';
		System.assertEquals('1111-2222-3333-4444',controller.getCreditCardNumber());
		naOpportunity.Operating_Unit__c = 'RH Singapore Operating Unit';
		System.assertEquals('****-****-****-****',controller.getCreditCardNumber());
		Test.stopTest();
	}
}