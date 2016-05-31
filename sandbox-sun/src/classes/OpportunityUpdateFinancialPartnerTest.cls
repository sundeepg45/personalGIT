/**
 * Test class for OpportunityUpdateFinancialPartner trigger (Depreciated).
 *
 * @version 2015-01-27
 * @author Ratan Sharma
 * 2011-06-28 Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 * Bill Riemers <briemers@redhat.com>
 * 2015-01-27 - Depreciated
 * 2012-07-10 - Updated to work with PartnerTierPartnerTypeMatrix validation rule 
 */
@isTest
private class OpportunityUpdateFinancialPartnerTest {
//depreciated	static final String ORACLE_ACCOUNT_NUMBER='2@Test';
//depreciated	static Account acc {
//depreciated		get {
//depreciated			if(acc == null)
//depreciated			{
//depreciated				acc = new Account(
//depreciated					name='0OppUpFinPartTest',RecordTypeId='012300000000NBLAA2',
//depreciated					AccountClassification__c='Sales - Territory',
//depreciated					BillingCountry='US',
//depreciated					OwnerId=UserInfo.getUserId());
//depreciated				insert acc; 
//depreciated			}
//depreciated			return acc;
//depreciated		}
//depreciated	}
//depreciated	static Account partner {
//depreciated		get {
//depreciated			if(partner == null)
//depreciated			{
//depreciated				partner = new Account(
//depreciated					name='1OppUpFinPartTest',RecordTypeId='012600000004yfaAAA',
//depreciated					OracleAccountNumber__c=ORACLE_ACCOUNT_NUMBER,
//depreciated					BillingCountry='US',
//depreciated					OwnerId=UserInfo.getUserId());
//depreciated				insert partner;
//depreciated				partner = [
//depreciated					select name,
//depreciated						RecordTypeId,OracleAccountNumber__c,OwnerId,AccountKey__c
//depreciated					from Account where Id = :partner.Id ];
//depreciated				System.debug(partner.Id);
//depreciated			}
//depreciated			return partner;
//depreciated		}
//depreciated	}
//depreciated	static Opportunity opp {
//depreciated		get {
//depreciated			if(opp == null)
//depreciated			{
//depreciated				//changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
//depreciated				opp = new Opportunity(
//depreciated					name='2OppUpFinPartTest',
//depreciated					StageName='Prepare', FulfillmentChannel__c='Direct - VAR/VAD',
//depreciated					Amount=0.00, RecordTypeId='012300000000TVDAA2', 
//depreciated					OpportunityType__c='Royalty', AccountId=acc.Id, 
//depreciated					OwnerId=UserInfo.getUserId(), Pay_Now__c='No', 
//depreciated					ForecastCategoryName='Omitted', CloseDate=Date.today(), 
//depreciated					PaymentType__c='NA Purchase Order');
//depreciated			}
//depreciated			return opp;
//depreciated		}
//depreciated		set;
//depreciated	}
//depreciated	static PartnerStatus__c partnerStat {
//depreciated		get {
//depreciated			if(partnerStat == null)
//depreciated			{
//depreciated				Classification__c partnerType = [select Id from Classification__c where Hierarchy__c = 'Partner Type » Distributor' and IsActive__c = true limit 1];
//depreciated				List<PartnerStatus__c> partnerStats = new List<PartnerStatus__c>();
//depreciated				for(Classification__c partnerTier : [
//depreciated					select Id 
//depreciated					from Classification__c 
//depreciated					where Hierarchy__c like 'Partner Tier » %'
//depreciated						and IsActive__c = true])
//depreciated				{
//depreciated					partnerStats.add(new PartnerStatus__c(
//depreciated						ApprovalStatus__c='Approved', 
//depreciated						PartnerTier__c=partnerTier.Id, 
//depreciated						ActivationDate__c=Date.today().addDays(-1), 
//depreciated						PartnerType__c=partnerType.Id, 
//depreciated						Partner__c=partner.Id, 
//depreciated						ExpirationDate__c=Date.today().addDays(1),
//depreciated						IsVisible__c=true));
//depreciated				}
//depreciated				for(Database.Saveresult sr : Database.insert(partnerStats,false)) {
//depreciated					PartnerStatus__c ps = partnerStats.remove(0);
//depreciated					if(sr.isSuccess()) {
//depreciated						partnerStat = ps;
//depreciated						break;
//depreciated					}
//depreciated				}
//depreciated				System.assertNotEquals(null,partnerStat);
//depreciated			}
//depreciated			return partnerStat;
//depreciated		}
//depreciated	}
//depreciated	static Opportunity queryOpportunity(Id id)
//depreciated	{
//depreciated		return [
//depreciated		   select Name, OpportunityType__c, FinancialPartner__c, Primary_Partner__c,
//depreciated			   OwnerId,AccountId,FulfillmentChannel__c,PaymentType__c,
//depreciated			   RecordTypeId,Amount,StageName,CloseDate,ForecastCategoryName,
//depreciated			   Pay_Now__c,OpportunityNumber__c 
//depreciated			   from Opportunity where Id=:id ];	 
//depreciated	}
//depreciated	
//depreciated	static testMethod void sanityTest() {
//depreciated		// just confirm we can insert the opportunity and partner
//depreciated		insert opp;
//depreciated		System.debug((opp=queryOpportunity(opp.Id)));
//depreciated		System.debug(partner);
//depreciated		System.assertNotEquals(null,opp.Id);
//depreciated		System.assertNotEquals(null,partner.Id);
//depreciated		System.assertEquals(partner.OracleAccountNumber__c,partner.AccountKey__c);
//depreciated		System.assertNotEquals(null,partnerStat.Id);
//depreciated	}
//depreciated	
//depreciated	static void upsertOpp()
//depreciated	{
//depreciated		System.assertNotEquals(null,partnerStat.Id);
//depreciated		upsert opp;
//depreciated		System.debug((opp=queryOpportunity(opp.Id)));
//depreciated		System.assertEquals(partner.Id,opp.FinancialPartner__c);
//depreciated		System.assertEquals(partner.Name,opp.Primary_Partner__c); 
//depreciated		OpportunityPartner__c oppPartner = [select Id from OpportunityPartner__c where Opportunity__c = :opp.Id];
//depreciated		System.debug(oppPartner);
//depreciated	}
//depreciated	
//depreciated	static testMethod void insertOppWithBothTest() {
//depreciated		// just confirm we can insert the opportunity and partner
//depreciated		opp.Primary_Partner__c = partner.Name;
//depreciated		opp.BillingAccountNumber__c = partner.OracleAccountNumber__c;
//depreciated		upsertOpp();
//depreciated	}
//depreciated	static testMethod void insertOppWithNameTest() {
//depreciated		// just confirm we can insert the opportunity and partner
//depreciated		opp.Primary_Partner__c = partner.Name;
//depreciated		upsertOpp();
//depreciated	}
//depreciated	static testMethod void insertOppWithAccountNumberTest() {
//depreciated		// just confirm we can insert the opportunity and partner
//depreciated		opp.Primary_Partner__c = partner.Name+'x';
//depreciated		opp.BillingAccountNumber__c = partner.OracleAccountNumber__c;
//depreciated		upsertOpp();
//depreciated	}
//depreciated	static testMethod void failedInsertOppWithAccountNumberTest() {
//depreciated		// just confirm we can insert the opportunity and partner
//depreciated		opp.Primary_Partner__c = partner.Name;
//depreciated		opp.BillingAccountNumber__c = partner.OracleAccountNumber__c+'x';
//depreciated		System.assertNotEquals(null,partnerStat.Id);
//depreciated		System.assert(! Database.insert(opp,false).isSuccess());
//depreciated	}
//depreciated	static testMethod void failedInsertOppWithNameTest() {
//depreciated		// just confirm we can insert the opportunity and partner
//depreciated		opp.Primary_Partner__c = partner.Name+'x';
//depreciated		System.assertNotEquals(null,partnerStat.Id);
//depreciated		System.assert(! Database.insert(opp,false).isSuccess());
//depreciated	}
//depreciated	static testMethod void updateOppWithBothTest() {
//depreciated		insert opp;
//depreciated		// just confirm we can insert the opportunity and partner
//depreciated		opp.Primary_Partner__c = partner.Name;
//depreciated		opp.BillingAccountNumber__c = partner.OracleAccountNumber__c;
//depreciated		upsertOpp();
//depreciated	}
//depreciated	static testMethod void updateOppWithNameTest() {
//depreciated		insert opp;
//depreciated		// just confirm we can insert the opportunity and partner
//depreciated		opp.Primary_Partner__c = partner.Name;
//depreciated		upsertOpp();
//depreciated	}
//depreciated	static testMethod void updateOppWithAccountNumberTest() {
//depreciated		insert opp;
//depreciated		// just confirm we can insert the opportunity and partner
//depreciated		opp.Primary_Partner__c = partner.Name+'x';
//depreciated		opp.BillingAccountNumber__c = partner.OracleAccountNumber__c;
//depreciated		upsertOpp();
//depreciated	}
}