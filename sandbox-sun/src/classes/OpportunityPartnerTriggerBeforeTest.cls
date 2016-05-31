/**
 * Test class for OpportunityPartnerTriggerBefore.cls
 *
 * @version 2014-08-13
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * 2014-08-13 - Initial version
 */
@isTest
public class OpportunityPartnerTriggerBeforeTest {
	public static Account acc {
		get {
			if(acc == null)
			{
				acc = new Account(
					name='0OppUpFinPartTest',RecordTypeId='012300000000NBLAA2',
					AccountClassification__c='Sales - Territory',
					BillingCountry='US',
					OwnerId=UserInfo.getUserId());
				insert acc; 
			}
			return acc;
		}
	}

	public static Account partner {
		get {
			if(partner == null)
			{
				partner = new Account(
					name='1OppUpFinPartTest',RecordTypeId='012600000004yfaAAA',
					OracleAccountNumber__c='-555',
					BillingCountry='US',
					OwnerId=UserInfo.getUserId());
				insert partner;
				partner = [
					select name,
						RecordTypeId,OracleAccountNumber__c,OwnerId,AccountKey__c
					from Account where Id = :partner.Id ];
				System.debug(partner.Id);
			}
			return partner;
		}
		set;
	}

	public static Opportunity opp {
		get {
			if(opp == null)
			{
				//changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
				opp = new Opportunity(
					name='2OppUpFinPartTest',
					StageName='Prepare', 
					FulfillmentChannel__c='Direct - VAR/VAD',
					Amount=0.00, 
					RecordTypeId='012300000000TVDAA2', 
					OpportunityType__c='Royalty',
					AccountId=acc.Id, 
					OwnerId=UserInfo.getUserId(),
					Pay_Now__c='No', 
					ForecastCategoryName='Omitted',
					CloseDate=Date.today(), 
					PaymentType__c='NA Purchase Order');
			}
			return opp;
		}
		set;
	}

	public static Id getOppId() {
		if(opp.Id == null) {
			insert opp;
		}
		return opp.Id;
	}

	public static PartnerStatus__c partnerStat {
		get {
			if(partnerStat == null)
			{
				Classification__c partnerType = [
					select Id
					from Classification__c
					where Hierarchy__c = 'Partner Type » Distributor'
					and IsActive__c = true limit 1];
				List<PartnerStatus__c> partnerStats = new List<PartnerStatus__c>();
				for(Classification__c partnerTier : [
					select Id 
					from Classification__c 
					where Hierarchy__c like 'Partner Tier » %'
						and IsActive__c = true])
				{
					partnerStats.add(new PartnerStatus__c(
						ApprovalStatus__c='Approved', 
						PartnerTier__c=partnerTier.Id, 
						ActivationDate__c=Date.today().addDays(-1), 
						PartnerType__c=partnerType.Id, 
						Partner__c=partner.Id, 
						ExpirationDate__c=Date.today().addDays(1),
						IsVisible__c=true));
				}
				for(Database.Saveresult sr : Database.insert(partnerStats,false)) {
					PartnerStatus__c ps = partnerStats.remove(0);
					if(sr.isSuccess()) {
						partnerStat = ps;
						break;
					}
				}
				System.assertNotEquals(null,partnerStat);
			}
			return partnerStat;
		}
	}

	public static Opportunity queryOpportunity(Id id)
	{
		return [
			select
				Name,
				AccountId,
				Amount,
				CloseDate,
				FinancialPartner__c,
				ForecastCategoryName,
				FulfillmentChannel__c,
				IsLockedForSales__c,
				OpportunityNumber__c,
				OpportunityType__c,
				OwnerId,
				Pay_Now__c,
				PaymentType__c,
				Primary_Partner__c,
				RecordTypeId,
				ResellerPartner__c,
				Reseller__c,
				StageName
			from Opportunity
			where Id=:id ];	 
	}

	public static OpportunityPartner__c oppPartnerFinancial {
		get {
			if(oppPartnerFinancial == null) {
				oppPartnerFinancial = new OpportunityPartner__c(
					RelationshipType__c = 'Financial',
					Opportunity__c = getOppId(),
					Partner__c = partner.Id,
					PartnerType__c = partnerStat.PartnerType__c,
					PartnerTier__c = partnerStat.PartnerTier__c);
			}
			return oppPartnerFinancial;
		}
	}

	public static OpportunityPartner__c oppPartnerReseller2 {
		get {
			if(oppPartnerReseller2 == null) {
				oppPartnerReseller2 = new OpportunityPartner__c(
					RelationshipType__c = 'Reseller 2',
					Opportunity__c = getOppId(),
					Partner__c = partner.Id,
					PartnerType__c = partnerStat.PartnerType__c,
					PartnerTier__c = partnerStat.PartnerTier__c);
			}
			return oppPartnerReseller2;
		}
	}

	@isTest(SeeAllData=true)
	static void oppLockTest() {
		Id oppId = getOppId();
		for(Opportunity xopp : [
			SELECT Id
			FROM Opportunity
			WHERE IsLockedForSales__c = true
			LIMIT 1 ] ) 
		{
			oppId = xopp.Id;
		}
		oppPartnerFinancial.Opportunity__c = oppId;
		OpportunityPartnerTriggerBefore triggerBefore = new OpportunityPartnerTriggerBefore(new Map<Id,OpportunityPartner__c>{oppPartnerFinancial.Id=>oppPartnerFinancial},null);
		Test.startTest();
		Set<Id> oppLockIds = triggerBefore.oppLockIds;
		Opportunity xopp = queryOpportunity(oppId);
		System.assertEquals(xopp.IsLockedForSales__c,oppLockIds.contains(oppId),'Unexpected oppLockIds set');
		oppLockIds.add(oppId);
		AdminByPass__c bypass = AdminByPass__c.getInstance();
		if(bypass.IsSalesUser__c) {
			bypass.IsSalesUser__c = false;
			upsert bypass;
		}
		triggerBefore.oppLock();
		System.assert(! triggerBefore.hasErrors,'Did not expect oppLock error');
		bypass.IsSalesUser__c = true;
		upsert bypass;
		triggerBefore.oppLock();
		Test.stopTest();
		System.assert(triggerBefore.hasErrors,'Expected oppLock error');
	}

	@isTest(SeeAllData=true)
	static void maintainLegacyOpportunityPartnersTest() {
		AbstractTrigger.setBooleanSettings('Opp_Before.',false);
		AbstractTrigger.setBooleanSettings('Opp_After.',false);
		// insert test
		OpportunityPartnerTriggerBefore triggerBefore = new OpportunityPartnerTriggerBefore(null,new List<OpportunityPartner__c>{oppPartnerFinancial});
		Test.startTest();
		triggerBefore.maintainLegacyOpportunityPartners();
		System.assert(!triggerBefore.hasErrors,'Unexpected line item error');
		Id legacyId = oppPartnerFinancial.Legacy_PartnerId__c;
		System.assertNotEquals(null,legacyId,'Expected a Legacy_PartnerId__c value');
		// update test
		OpportunityPartner__c oppPartner2 = oppPartnerFinancial.clone(true);
		Account partner2 = partner;
		partner = null;
		oppPartner2.Partner__c = partner.Id;
		triggerBefore = new OpportunityPartnerTriggerBefore(new Map<Id,OpportunityPartner__c>{oppPartnerFinancial.Id=>oppPartnerFinancial},new List<OpportunityPartner__c>{oppPartner2});
		triggerBefore.maintainLegacyOpportunityPartners();
		System.assert(!triggerBefore.hasErrors,'Unexpected line item error');
		Id legacyId2 = oppPartner2.Legacy_PartnerId__c;
		System.assertNotEquals(null,legacyId2,'Expected a Legacy_PartnerId__c value');
		// delete test
		triggerBefore = new OpportunityPartnerTriggerBefore(new Map<Id,OpportunityPartner__c>{oppPartner2.Id=>oppPartner2},null);
		triggerBefore.maintainLegacyOpportunityPartners();
		System.assert(!triggerBefore.hasErrors,'Unexpected line item error');
		for(Partner p : [select Id from Partner where Id = :new Set<Id>{legacyId,legacyId2}]) {
			System.assertEquals(null,p,'Expected partner to be deleted');
		}
		// boost our coverage
		oppPartnerFinancial.Legacy_PartnerId__c = null;
		oppPartnerFinancial.RelationshipType__c = 'Dummy';
		triggerBefore = new OpportunityPartnerTriggerBefore(null,new List<OpportunityPartner__c>{oppPartnerFinancial});
		triggerBefore.maintainLegacyOpportunityPartners();
		oppPartnerFinancial.Partner__c = null;
		triggerBefore = new OpportunityPartnerTriggerBefore(null,new List<OpportunityPartner__c>{oppPartnerFinancial});
		triggerBefore.maintainLegacyOpportunityPartners();
		System.assert(triggerBefore.hasErrors,'Expected an error');
		partner = partner2;
		oppPartnerFinancial = null;
		delete partner;
		triggerBefore = new OpportunityPartnerTriggerBefore(null,new List<OpportunityPartner__c>{oppPartnerFinancial});
		triggerBefore.maintainLegacyOpportunityPartners();
		Test.stopTest();
	}

	@isTest(SeeAllData=true)
	static void processTriggerTest() {
		AbstractTrigger.setBooleanSettings('OppPart_Before.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		List<OpportunityPartner__c> oppPartners = new List<OpportunityPartner__c>{oppPartnerFinancial};
		Map<Id,OpportunityPartner__c> oldMap = new Map<Id,OpportunityPartner__c>{ oppPartnerFinancial.Id => oppPartnerFinancial };
		List<OpportunityPartner__c> newList = oppPartners.deepClone(true);
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('OppPart_Before.',true);
		// insert
		AbstractTrigger.insertMissing = 0;
		OpportunityPartnerTriggerBefore.processTrigger(null,newList);
		// update
		newList = oppPartners.deepClone(true);
		OpportunityPartnerTriggerBefore.processTrigger(oldMap,newList);
		// delete
		OpportunityPartnerTriggerBefore.processTrigger(oldMap,null);
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('OppPart_Before.');
	}

}