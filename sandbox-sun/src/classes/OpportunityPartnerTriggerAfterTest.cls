/**
 * Test class for OpportunityPartnerTriggerAfter.cls
 *
 * @version 2014-08-13
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * 2014-08-13 - Initial version
 */
@isTest
private class OpportunityPartnerTriggerAfterTest {

	static List<OpportunityPartner__c> oppPartners {
		get {
			if(oppPartners == null) {
				// Turn off all triggers, as we are going to test those next
				AbstractTrigger.setBooleanSettings('OppPart_After.',false);
				oppPartners = new List<OpportunityPartner__c>{
					OpportunityPartnerTriggerBeforeTest.oppPartnerFinancial,
					OpportunityPartnerTriggerBeforeTest.oppPartnerReseller2};
				insert oppPartners;
				Set<Id> oppPartnerIds = new Set<Id>{oppPartners[0].Id,oppPartners[1].Id};
				oppPartners.clear();
				oppPartners.addAll([
					select
						Opportunity__c,
						Partner__c,
						PartnerName__c,
						RelationshipType__c
					from OpportunityPartner__c
					where Id in :oppPartnerIds
					order by RelationshipType__c ]);
				// Turn on all the triggers, and make sure everything is tested.
				AbstractTrigger.setBooleanSettings('OppPart_After.',true);
			}
			return oppPartners;
		}
		set;
	}

	@isTest(SeeAllData=true)
	static void getPartnerMapTest() {
		Map<Id,OpportunityPartner__c> relevantMap = new Map<Id,OpportunityPartner__c>{null=>OpportunityPartnerTriggerBeforeTest.oppPartnerFinancial};
		OpportunityPartnerTriggerAfter triggerAfter = new OpportunityPartnerTriggerAfter(null,relevantMap);
		Test.startTest();
		Map<Id,OpportunityPartner__c> partnerMap = triggerAfter.getPartnerMap(relevantMap,'Reseller 2');
		System.assert(! triggerAfter.hasErrors,'Unexpected errors');
		System.assertEquals(0,partnerMap.size(),'Financial Partners should not be Reseller 2.');
		partnerMap = triggerAfter.getPartnerMap(relevantMap,'Financial');
		System.assertEquals(1,partnerMap.size(),'Financial Partners should match');
		System.assert(! triggerAfter.hasErrors,'Unexpected errors');
		relevantMap.put(UserInfo.getUserId(),relevantMap.get(null));
		triggerAfter = new OpportunityPartnerTriggerAfter(null,relevantMap);
		partnerMap = triggerAfter.getPartnerMap(relevantMap,'Financial');
		Test.stopTest();
		System.assert(triggerAfter.hasErrors,'Expected errors');
	}

	@isTest(SeeAllData=true)
	static void updateOpportunitiesTest() {
		// insert test
		Map<Id,OpportunityPartner__c> oppPartnerMap = new Map<Id,OpportunityPartner__c>(oppPartners);
		OpportunityPartnerTriggerAfter triggerAfter = new OpportunityPartnerTriggerAfter(null,oppPartnerMap);
		Test.startTest();
		triggerAfter.updateOpportunities();
		Opportunity opp = [
			select
				FinancialPartner__c,
				Primary_Partner__c,
				Reseller__c,
				ResellerPartner__c
			from Opportunity
			where Id = :OpportunityPartnerTriggerBeforeTest.oppPartnerFinancial.Opportunity__c];
		System.assertEquals(OpportunityPartnerTriggerBeforeTest.partner.Name,opp.Primary_Partner__c);
		System.assertEquals(OpportunityPartnerTriggerBeforeTest.partner.Id,opp.FinancialPartner__c);
		System.assertEquals(OpportunityPartnerTriggerBeforeTest.partner.Name,opp.Reseller__c);
		System.assertEquals(OpportunityPartnerTriggerBeforeTest.partner.Id,opp.ResellerPartner__c);
		// replace test
		List<OpportunityPartner__c> oppPartners2 = oppPartners;
		OpportunityPartnerTriggerBeforeTest.partner = null;
		OpportunityPartnerTriggerBeforeTest.oppPartnerFinancial = null;
		OpportunityPartnerTriggerBeforeTest.oppPartnerReseller2 = null;
		oppPartners = null;
		oppPartnerMap = new Map<Id,OpportunityPartner__c>(oppPartners);
		triggerAfter = new OpportunityPartnerTriggerAfter(null,oppPartnerMap);
		triggerAfter.updateOpportunities();
		opp = [
			select
				FinancialPartner__c,
				Primary_Partner__c,
				Reseller__c,
				ResellerPartner__c
			from Opportunity
			where Id = :OpportunityPartnerTriggerBeforeTest.oppPartnerFinancial.Opportunity__c];
		System.assertEquals(OpportunityPartnerTriggerBeforeTest.partner.Name,opp.Primary_Partner__c);
		System.assertEquals(OpportunityPartnerTriggerBeforeTest.partner.Id,opp.FinancialPartner__c);
		System.assertEquals(OpportunityPartnerTriggerBeforeTest.partner.Name,opp.Reseller__c);
		System.assertEquals(OpportunityPartnerTriggerBeforeTest.partner.Id,opp.ResellerPartner__c);

		// delete test
		triggerAfter = new OpportunityPartnerTriggerAfter(oppPartnerMap,null);
		triggerAfter.updateOpportunities();
		opp = [
			select
				FinancialPartner__c,
				Primary_Partner__c,
				Reseller__c,
				ResellerPartner__c
			from Opportunity
			where Id = :OpportunityPartnerTriggerBeforeTest.oppPartnerFinancial.Opportunity__c];
		System.assertEquals(null,opp.Primary_Partner__c);
		System.assertEquals(null,opp.FinancialPartner__c);
		System.assertEquals(null,opp.Reseller__c);
		System.assertEquals(null,opp.ResellerPartner__c);
		// boost coverage
		oppPartners2 = oppPartners.deepclone(true);
		delete new Account(Id=oppPartners2.get(0).Partner__c);
		triggerAfter = new OpportunityPartnerTriggerAfter(null,new Map<Id,OpportunityPartner__c>(oppPartners2));
		triggerAfter.updateOpportunities();
		Test.stopTest();
	}

	@isTest(SeeAllData=true)
	static void processTriggerTest() {
		// Turn off all triggers, as we are going to test those next
		AbstractTrigger.setBooleanSettings('OppPart_After.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		OpportunityPartnerTriggerAfter.processTrigger(null,new Map<Id,OpportunityPartner__c>(oppPartners));
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('OppPart_After.',true);

		List<OpportunityPartner__c> oppPartners2 = oppPartners.deepClone(true);
		Test.startTest();
		// insert test
		OpportunityPartnerTriggerAfter.processTrigger(null,new Map<Id,OpportunityPartner__c>(oppPartners2));
		// update test
		OpportunityPartnerTriggerAfter.processTrigger(new Map<Id,OpportunityPartner__c>(oppPartners),new Map<Id,OpportunityPartner__c>(oppPartners2));
		// delete test
		OpportunityPartnerTriggerAfter.processTrigger(new Map<Id,OpportunityPartner__c>(oppPartners),null);
		Test.stopTest();
		// Confirm all missing settings were added
		AbstractTriggerTest.validateSettings('OppPart_After.');
	}
}