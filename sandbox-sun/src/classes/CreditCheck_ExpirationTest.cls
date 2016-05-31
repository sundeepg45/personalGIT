/**
 * Test class for CreditCheck_Expiration.cls
 *
 * @author  Bill Riemers <briemers@redhat.com>
 */
@isTest
private class CreditCheck_ExpirationTest {
	//
	// get the id of the renewal record type
	//
	static RecordType naRecordType {
		get {
			if(naRecordType == null) {
				naRecordType = [
					SELECT Id 
					FROM RecordType 
					WHERE Name = 'NA Sales Opportunity'
						AND IsActive = true
						AND SObjectType = 'Opportunity' ];
			}
			return naRecordType;
		}
	}

	//
	// create an account
	//
	static Account account {
		get {
			if(account == null) {
				account = new Account(
					BillingCity = 'Raleigh',
					BillingCountry = 'US',
					BillingPostalCode = '27606',
					BillingState = 'North Carolina',
					BillingStreet = '1801 Varsity Drive',
					Name = 'Red Hat',
					OracleAccountNumber__c = '12345',
					ShippingCity = 'Raleigh',
					ShippingCountry = 'US',
					ShippingPostalCode = '27606',
					ShippingState = 'North Carolina',
					ShippingStreet = '1801 Varsity Drive',
					VATNumber__c = '67890' );
				insert account;
			}
			return account;
		}
	}
	
	//
	// intadmin user
	//
	static User user {
		get {
			if(user == null) {
				user = [select UserName from User where UserName like 'intadmin@redhat.com%' limit 1];
			}
			return user;
		}
	}

	//
	// create the source renewal opportunity
	//
	static Opportunity getOpportunity(Boolean doInsert) {
		Opportunity opp = new Opportunity(
			AccountId = account.Id,
			CloseDate = System.today(),
			Country_Of_Order__c = 'Narnia',
			CurrencyIsoCode = 'USD',
			Name = 'Renewal Source Opportunity',
			OpportunityType__c = 'Standard',
			PaymentType__c = 'NA Purchase Order',
			RecordTypeId = naRecordType.Id,
			Renewal_Opportunity__c = true,
			StageName = 'Prepare');
		if(doInsert) {
			insert opp;
		}
		return opp;
	}

	static Credit__c getCredit(Id oppId) {
		Credit__c credit = new Credit__c(
			Opportunity__c=oppId,
			Credit_Stage__c='Approved',
			Payment_Terms__c='IMMEDIATE',
			BillingAccountNumberUsed__c='1',
			isFinal__c=false);
		insert credit;
		return credit;
	}

	static testMethod void validateSettings() {
		String message = 'Missing IntegerSetting__c values:';
		String errorMessage = message;
		for(String key : CreditCheck_Expiration.longSettingMap.keySet()) {
			if(CreditCheck_Expiration.longSettingMap.get(key) == null) {
				errorMessage += ' '+key;
			}
		}
		System.assertEquals(message,errorMessage);
		// make sure the expiration is in the past
		System.assert(CreditCheck_Expiration.expirationDateTime.getTime() <= DateTime.now().getTime());
		// make sure the notice is in the past
		System.assert(CreditCheck_Expiration.newestNoticeDateTime.getTime() <= DateTime.now().getTime());
		// make sure the notice date is more newer than the expiration date
		System.assert(CreditCheck_Expiration.newestNoticeDateTime.getTime() >= CreditCheck_Expiration.expirationDateTime.getTime());
	}

	static testMethod void closeTest() {
		Opportunity opp = getOpportunity(true);
		Credit__c credit = getCredit(opp.Id);
		CreditCheck_Expiration.query += ' and Id = \''+credit.Id+'\'';
		CreditCheck_Expiration.expirationDateTime = DateTime.now().addDays(1);
		CreditCheck_Expiration.oldestNoticeDateTime = CreditCheck_Expiration.newestNoticeDateTime = CreditCheck_Expiration.expirationDateTime.addDays(5);
		Test.StartTest();
		CreditCheck_Expiration cce = new CreditCheck_Expiration();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(cce.start(null));
		ssc.setPageSize(100);
		System.runAs(user) {
			cce.execute(null,ssc.getRecords());
		}
		System.assert(cce.errorMessages.isEmpty());
		cce.finish(null);
		Test.StopTest();
		System.assertEquals(1,[select Count() from Credit__c where Id = :credit.Id and Credit_Stage__c = 'Closed']);
	}

	static testMethod void reminderTest() {
		Opportunity opp = getOpportunity(true);
		Credit__c credit = getCredit(opp.Id);
		CreditCheck_Expiration.query += ' and Id = \''+credit.Id+'\'';
		CreditCheck_Expiration.oldestNoticeDateTime = DateTime.now().addDays(-1);
		CreditCheck_Expiration.newestNoticeDateTime = DateTime.now().addDays(1);
		Test.StartTest();
		CreditCheck_Expiration cce = new CreditCheck_Expiration();
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(cce.start(null));
		ssc.setPageSize(100);
		System.runAs(user) {
			cce.execute(null,ssc.getRecords());
		}
		System.assert(cce.errorMessages.isEmpty());
		cce.finish(null);
		Test.StopTest();
		System.assertEquals(0,[select Count() from Credit__c where Id = :credit.Id and Credit_Stage__c = 'Closed']);
	}
}