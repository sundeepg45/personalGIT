/**
 * Test class for Renewal_AutoClosure.cls
 *
 * @author  Bryan Bosely <bbosely@redhat.com>, Bill Riemers <briemers@redhat.com>
 * 
 * @version 2012-07-10
 * Modified: Bill Riemers <briemers@redhat.com>
 * 2012-07-10 - SMR test update
 * 2012-04-18 - Update for Security Model Redesign
 */
@isTest(SeeAllData=true) // need all data to access custom settings
private class Renewal_AutoClosureTest {
	//
	// get the id of the renewal record type
	//
	static RecordType renewalRecordType {
		get {
			if(renewalRecordType == null) {
				renewalRecordType = [
					SELECT Id 
					FROM RecordType 
					WHERE Name = 'Renewal'
						AND IsActive = true
						AND SObjectType = 'Opportunity' ];
			}
			return renewalRecordType;
		}
	}
	
	static Id salesUserProfileId {
		get {
			if (salesUserProfileId == null) {
				TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
				System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
				salesUserProfileId = salesUserProfileTesting.Id__c;
			}
			return salesUserProfileId;
		}
	}


	static User salesUser {
		get {
			if(salesUser == null) {
				salesUser = [
					select Id from User 
					where Profile.Id = :salesUserProfileId 
						and IsActive = true
					limit 1 ];
			}
			return salesUser;
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
	// create the source renewal opportunity
	//
	static Opportunity getOpportunity(Date closeDate,Id ownerId,Boolean doInsert) {
		Opportunity opp = new Opportunity(
			AccountId = account.Id,
			CloseDate = closeDate,
			Country_Of_Order__c = 'Narnia',
			CurrencyIsoCode = 'USD',
			Name = 'Renewal Source Opportunity',
			OpportunityType__c = 'Standard',
			OwnerId = ownerId,
			PaymentType__c = 'NA Purchase Order',
			RecordTypeId = renewalRecordType.Id,
			Renewal_Opportunity__c = true,
			StageName = 'Prepare');
		if(doInsert) {
			insert opp;
		}
		return opp;
	}


	static testMethod void emailCoverageTest() {
		System.assert(! Renewal_AutoClosure.emailTemplateMaps.isEmpty());
		Map<Integer,List<Opportunity>> oppMap = new Map<Integer,List<Opportunity>>();
		Set<Id> oppIds = new Set<Id>();
		Set<String> notificationRegions = new Set<String>();
		for(Map<String,EmailTemplate> m : Renewal_AutoClosure.emailTemplateMaps.values()) {
			for(EmailTemplate et : m.values()) {
				m.put('none',et);
				break;
			}
			notificationRegions.addAll(m.keySet());
		}
		System.assert(! notificationRegions.isEmpty());
		for(String r : notificationRegions) {
			for(User u : [
				select Profile.Name, UserRole.Name 
				from User 
				where profile.Id = :salesUserProfileId and Region__c = :r and IsActive = true limit 1])
			{
				Opportunity opp = getOpportunity(System.Today(),u.Id,true);
				opp = [ 
					select
						Name,
						OpportunityNumber__c,
						Owner.Email,
						Owner.EnterpriseServerUrl__c,
						Owner.Profile.Name,
						Super_Region__c
					from Opportunity where Id = :opp.Id ];
				for(Integer i : Renewal_AutoClosure.emailTemplateMaps.keySet()) {
					List<Opportunity> oppList = oppMap.get(i);
					if(oppList == null) {
						oppList = new List<Opportunity>();
						oppMap.put(i,oppList);
					}
					oppList.add(opp);
					oppIds.add(opp.Id);
				}
			}
		}
		System.assert(! oppMap.isEmpty());
		Renewal_AutoClosure.emailNotifications(oppMap);
		List<Task> tasks = [
			select
				ActivityDate,
				Description,
				OwnerId,
				RecordTypeId,
				Subject,
				Status,
				Type,
				WhatId
			from Task
			where WhatId in :oppIds ];
		System.debug(tasks);
		System.assert(! tasks.isEmpty());
		// check that e-mails are not sent twice
		Renewal_AutoClosure.emailNotifications(oppMap);
		Integer tasksSize = [
			select
				COUNT()
			from Task
			where WhatId in :oppIds ];
		System.assertEquals(tasks.size(),tasksSize);
	}

	static testMethod void autoClosureTest()
	{
		//
		// create opportunities that are past the 90 day expiration
		//
		
		Opportunity opportunity = getOpportunity(system.today().addDays( -91 ), salesUser.Id, true );
		Opportunity opportunity2 = getOpportunity(system.today().addDays( -100 ), salesUser.Id, true );
		
		
		//
		// execute the batch process
		//
		
		Test.StartTest();
		Renewal_AutoClosure rac = new Renewal_AutoClosure();
		rac.oppQuery += ' limit 10';
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(rac.start(null));
		ssc.setPageSize(100);
		Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>((List<Opportunity>)ssc.getRecords());
		oppMap.put(opportunity.Id,opportunity);
		oppMap.put(opportunity2.Id,opportunity2);
		rac.execute(null,oppMap.values());
		rac.finish(null);
		Test.StopTest();

		//
		// the opportunities should be closed with the correct closed lost reason code
		//
		
		List<Opportunity> updatedOpps = [SELECT stageName
				, reasonWonLostSalesProcess__c 
			 FROM Opportunity
			WHERE Id IN ( :opportunity.id, :opportunity2.id )
		];
		
		for ( Opportunity updatedOpp : updatedOpps )
		{
			system.assertEquals( updatedOpp.stageName, 'Closed Lost' );
			system.assertEquals( updatedOpp.reasonWonLostSalesProcess__c, '90 Days Post Expiration' );
		}
	}
}