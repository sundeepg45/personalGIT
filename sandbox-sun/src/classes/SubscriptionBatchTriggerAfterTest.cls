/**
 * Test the SubscriptionBatchTriggerAfter class.  We will create all the
 * Subscription objects needed in this class, all the other Subscription
 * objects will depend on SubscriptionBatch objects.
 *
 * @version 2015-02-19
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-02-19 - Update for fiscal period in composite key
 * 2015-01-27 - Depreciated all tests.  We still need the public objects for reference in other classes.
 * 2014-12-12 - Updated subscription partners for composite key
 * 2014-11-25 - Corrected test failure that results because we no longer use WAIT FOR CHANNELLOAD
 * 2013-09-19 - created
 */
@isTest
public class SubscriptionBatchTriggerAfterTest {
	public static final String BATCH_ID = 'TestBatch';
	public static final Decimal FISCAL_YEAR = Decimal.valueOf(System.now().year()+1);
	public static final Decimal FISCAL_QUARTER = Decimal.valueOf('3.0');
	public static final Decimal CONTRACT_ID0 = Decimal.valueOf('10000000.0');
	public static final Decimal ORDER_ID0 = Decimal.valueOf('20000000.0');
	public static final Decimal CONTRACT_ID1 = Decimal.valueOf('10000001.0');
	public static final Decimal ORDER_ID1 = Decimal.valueOf('20000001.0');
	public static final String COMPOSITE_KEY00 = '20000000:10000000FY'+FISCAL_YEAR.longValue()+'Q'+FISCAL_QUARTER.longValue();
	public static final String COMPOSITE_KEY01 = '20000000:10000001FY'+FISCAL_YEAR.longValue()+'Q'+FISCAL_QUARTER.longValue();
	public static final String COMPOSITE_KEY10 = '20000001:10000000FY'+FISCAL_YEAR.longValue()+'Q'+FISCAL_QUARTER.longValue();
	public static final String COMPOSITE_KEY11 = '20000001:10000001FY'+FISCAL_YEAR.longValue()+'Q'+FISCAL_QUARTER.longValue();
	public static final String CONTRACT_LINE_ID0 = '30000000';
	public static final String CONTRACT_LINE_ID1 = '30000001';
	public static final String CONTRACT_LINE_ID2 = '30000002';
	public static final String CONTRACT_LINE_ID3 = '30000003';
	public static final String CONTRACT_LINE_ID4 = '30000004';
	public static final String CONTRACT_LINE_ID5 = '30000005';
	public static final String CONTRACT_LINE_ID6 = '30000006';
	public static final String CONTRACT_LINE_ID7 = '30000007';
	public static final Decimal ADDITIONAL_PARTNER_ID0 = Decimal.valueOf('40000000.0');
	public static final Decimal ADDITIONAL_PARTNER_ID1 = Decimal.valueOf('40000001.0');
	public static final Decimal ACCOUNT_ID0 = Decimal.valueOf('50000000.0');
	public static final Decimal ACCOUNT_ID1 = Decimal.valueOf('50000001.0');
	public static final String PARTNER_COMPOSITE_KEY00 = '40000000:50000000';
	public static final String PARTNER_COMPOSITE_KEY01 = '40000000:50000001';
	public static final String PARTNER_COMPOSITE_KEY10 = '40000001:50000000';
	public static final String PARTNER_COMPOSITE_KEY11 = '40000001:50000001';

	public static SubscriptionBatch__c subscriptionBatch {
		get {
			if(subscriptionBatch == null) {
				subscriptionBatch = new SubscriptionBatch__c(
					BatchId__c = BATCH_ID);
			}
			return subscriptionBatch;
		}
	}

	public static Id getSubscriptionBatchId() {
		if(subscriptionBatch.Id == null) {
			AbstractTrigger.setBooleanSettings('SubBatch_After.',false);
			Database.upsert(new List<SubscriptionBatch__c>{subscriptionBatch},SubscriptionBatch__c.Fields.BatchId__c,true);
			AbstractTrigger.setBooleanSettings('SubBatch_After.',true);
		}
		return subscriptionBatch.Id;
	}

	public static Region__c region {
		get {
			if(region == null) {
				region = new Region__c(
					Name='Fantasia',
					Country__c = 'Narnia',
					Sub_Region__c = 'Warddrobe',
					Region__c = 'Fantasia',
					Super_Region__c='APAC');
				insert region;
			}
			return region;
		}
		private set;
	}

	public static List<Subscription__c> subscriptions {
		get {
			if(subscriptions == null) {
				subscriptions = new List<Subscription__c>{
					new Subscription__c(
						BatchId__c = BATCH_ID,
						CountryOfOrder__c = region.Country__c,
						CurrencyIsoCode='EUR',
						ContractId__c = CONTRACT_ID0,
						OrderId__c = ORDER_ID0,
						ContractAmount__c = 1.00,
						FiscalYear__c = FISCAL_YEAR,
						FiscalQuarter__c = FISCAL_QUARTER),
					new Subscription__c(
						BatchId__c = BATCH_ID,
						CountryOfOrder__c = region.Country__c,
						CurrencyIsoCode='EUR',
						ContractId__c = CONTRACT_ID1,
						OrderId__c = ORDER_ID0,
						ContractAmount__c = 1.00,
						FiscalYear__c = FISCAL_YEAR,
						FiscalQuarter__c = FISCAL_QUARTER),
					new Subscription__c(
						BatchId__c = BATCH_ID,
						CountryOfOrder__c = region.Country__c,
						CurrencyIsoCode='EUR',
						ContractId__c = CONTRACT_ID0,
						OrderId__c = ORDER_ID1,
						ContractAmount__c = 1.00,
						FiscalYear__c = FISCAL_YEAR,
						FiscalQuarter__c = FISCAL_QUARTER),
					new Subscription__c(
						BatchId__c = BATCH_ID,
						CountryOfOrder__c = region.Country__c,
						CurrencyIsoCode='EUR',
						ContractId__c = CONTRACT_ID1,
						OrderId__c = ORDER_ID1,
						ContractAmount__c = 1.00,
						FiscalYear__c = FISCAL_YEAR,
						FiscalQuarter__c = FISCAL_QUARTER)
				};
			}
			return subscriptions;
		}
		private set;
	}

	public static Map<Id,Subscription__c> subscriptionMap {
		get {
			if(subscriptionMap == null) {
				AbstractTrigger.setBooleanSettings('Sub_After.',false);
				insert subscriptions;
				subscriptionMap = new Map<Id,Subscription__c>(subscriptions);
				AbstractTrigger.setBooleanSettings('Sub_After.',true);
			}
			return subscriptionMap;
		}
		private set;
	}

	public static List<SubscriptionLine__c> subscriptionLines {
		get {
			if(subscriptionLines == null) {
				subscriptionLines = new List<SubscriptionLine__c>{
					new SubscriptionLine__c(
						BatchId__c = BATCH_ID,
						CurrencyIsoCode='EUR',
						DnrFlag__c = false,
						NfrFlag__c = false,
						ContractLineId__c=CONTRACT_LINE_ID0,
						ContractId__c = CONTRACT_ID0,
						OrderId__c = ORDER_ID0,
						FiscalYear__c = FISCAL_YEAR,
						FiscalQuarter__c = FISCAL_QUARTER),
					new SubscriptionLine__c(
						BatchId__c = BATCH_ID,
						CurrencyIsoCode='EUR',
						DnrFlag__c = false,
						NfrFlag__c = false,
						ContractLineId__c=CONTRACT_LINE_ID1,
						ContractId__c = CONTRACT_ID0,
						OrderId__c = ORDER_ID0,
						FiscalYear__c = FISCAL_YEAR,
						FiscalQuarter__c = FISCAL_QUARTER),
					new SubscriptionLine__c(
						BatchId__c = BATCH_ID,
						CurrencyIsoCode='EUR',
						DnrFlag__c = false,
						NfrFlag__c = false,
						ContractLineId__c=CONTRACT_LINE_ID2,
						ContractId__c = CONTRACT_ID1,
						OrderId__c = ORDER_ID0,
						FiscalYear__c = FISCAL_YEAR,
						FiscalQuarter__c = FISCAL_QUARTER),
					new SubscriptionLine__c(
						BatchId__c = BATCH_ID,
						CurrencyIsoCode='EUR',
						DnrFlag__c = false,
						NfrFlag__c = false,
						ContractLineId__c=CONTRACT_LINE_ID3,
						ContractId__c = CONTRACT_ID1,
						OrderId__c = ORDER_ID0,
						FiscalYear__c = FISCAL_YEAR,
						FiscalQuarter__c = FISCAL_QUARTER),
					new SubscriptionLine__c(
						BatchId__c = BATCH_ID,
						CurrencyIsoCode='EUR',
						DnrFlag__c = false,
						NfrFlag__c = false,
						ContractLineId__c=CONTRACT_LINE_ID4,
						ContractId__c = CONTRACT_ID0,
						OrderId__c = ORDER_ID1,
						FiscalYear__c = FISCAL_YEAR,
						FiscalQuarter__c = FISCAL_QUARTER),
					new SubscriptionLine__c(
						BatchId__c = BATCH_ID,
						CurrencyIsoCode='EUR',
						DnrFlag__c = false,
						NfrFlag__c = false,
						ContractLineId__c=CONTRACT_LINE_ID5,
						ContractId__c = CONTRACT_ID0,
						OrderId__c = ORDER_ID1,
						FiscalYear__c = FISCAL_YEAR,
						FiscalQuarter__c = FISCAL_QUARTER),
					new SubscriptionLine__c(
						BatchId__c = BATCH_ID,
						CurrencyIsoCode='EUR',
						DnrFlag__c = false,
						NfrFlag__c = false,
						ContractLineId__c=CONTRACT_LINE_ID6,
						ContractId__c = CONTRACT_ID1,
						OrderId__c = ORDER_ID1,
						FiscalYear__c = FISCAL_YEAR,
						FiscalQuarter__c = FISCAL_QUARTER),
					new SubscriptionLine__c(
						BatchId__c = BATCH_ID,
						CurrencyIsoCode='EUR',
						DnrFlag__c = false,
						NfrFlag__c = false,
						ContractLineId__c=CONTRACT_LINE_ID7,
						ContractId__c = CONTRACT_ID1,
						OrderId__c = ORDER_ID1,
						FiscalYear__c = FISCAL_YEAR,
						FiscalQuarter__c = FISCAL_QUARTER)
				};
			}
			return subscriptionLines;
		}
		private set;
	}

	public static Map<Id,SubscriptionLine__c> subscriptionLineMap {
		get {
			if(subscriptionLineMap == null) {
				AbstractTrigger.setBooleanSettings('SubLine_After.',false);
				insert subscriptionLines;
				subscriptionLineMap = new Map<Id,SubscriptionLine__c>(subscriptionLines);
				AbstractTrigger.setBooleanSettings('SubLine_After.',true);
			}
			return subscriptionLineMap;
		}
		private set;
	}

	public static List<SubscriptionPartner__c> subscriptionPartners {
		get {
			if(subscriptionPartners == null) {
				subscriptionPartners = new List<SubscriptionPartner__c>{
					new SubscriptionPartner__c(
						BatchId__c = BATCH_ID,
						AccountId__c = ACCOUNT_ID0,
						ApId__c = ADDITIONAL_PARTNER_ID0,
						OrderId__c = ORDER_ID0),
					new SubscriptionPartner__c(
						BatchId__c = BATCH_ID,
						AccountId__c = ACCOUNT_ID1,
						ApId__c = ADDITIONAL_PARTNER_ID0,
						OrderId__c = ORDER_ID0),
					new SubscriptionPartner__c(
						BatchId__c = BATCH_ID,
						AccountId__c = ACCOUNT_ID0,
						ApId__c = ADDITIONAL_PARTNER_ID1,
						OrderId__c = ORDER_ID1),
					new SubscriptionPartner__c(
						BatchId__c = BATCH_ID,
						AccountId__c = ACCOUNT_ID1,
						ApId__c = ADDITIONAL_PARTNER_ID1,
						OrderId__c = ORDER_ID1)
				};
			}
			return subscriptionPartners;
		}
		private set;
	}

	public static Map<Id,SubscriptionPartner__c> subscriptionPartnerMap {
		get {
			if(subscriptionPartnerMap == null) {
				AbstractTrigger.setBooleanSettings('SubPart_After.',false);
				insert subscriptionPartners;
				subscriptionPartnerMap = new Map<Id,SubscriptionPartner__c>(subscriptionPartners);
				AbstractTrigger.setBooleanSettings('SubPart_After.',true);
			}
			return subscriptionPartnerMap;
		}
		private set;
	}

	public static void setAllBooleanSettings(Boolean value) {
		AbstractTrigger.setBooleanSettings('Sub_Before.',value);
		AbstractTrigger.setBooleanSettings('SubBatch_Before.',value);
		AbstractTrigger.setBooleanSettings('SubLine_Before.',value);
		AbstractTrigger.setBooleanSettings('SubPart_Before.',value);
		AbstractTrigger.setBooleanSettings('Sub_After.',value);
		AbstractTrigger.setBooleanSettings('SubBatch_After.',value);
		AbstractTrigger.setBooleanSettings('SubLine_After.',value);
		AbstractTrigger.setBooleanSettings('SubPart_After.',value);
	}

//depreciated	@isTest
//depreciated	static void updateChildrenTest() {
//depreciated		AbstractTrigger.booleanSettingMap.put(SubscriptionTriggerBefore.ASSIGN_BATCH_SETTING,false);
//depreciated		Map<Id,Subscription__c> subMap = subscriptionMap;
//depreciated		AbstractTrigger.booleanSettingMap.put(SubscriptionLineTriggerBefore.ASSIGN_BATCH_SETTING,false);
//depreciated		Map<Id,SubscriptionLine__c> subLineMap = subscriptionLineMap;
//depreciated		AbstractTrigger.booleanSettingMap.put(SubscriptionPartnerTriggerBefore.ASSIGN_BATCH_SETTING,false);
//depreciated		Map<Id,SubscriptionPartner__c> subPartnerMap = subscriptionPartnerMap;
//depreciated		Map<Id,SubscriptionBatch__c> subBatchMap = new Map<Id,SubscriptionBatch__c>{
//depreciated			getSubscriptionBatchId() => subscriptionBatch
//depreciated		};
//depreciated		SubscriptionBatchTriggerAfter triggerAfter = new SubscriptionBatchTriggerAfter(null,subBatchMap);
//depreciated		Test.startTest();
//depreciated		triggerAfter.updateChildren();
//depreciated		Test.stopTest();
//depreciated		subMap.keySet().removeAll(new Map<Id,Subscription__c>([
//depreciated			select Id from Subscription__c
//depreciated			where Batch__c = :getSubscriptionBatchId() ]).keySet());
//depreciated		System.assert(subMap.isEmpty(),'Failed to map batch ids for all Subscriptions');
//depreciated		subLineMap.keySet().removeAll(new Map<Id,SubscriptionLine__c>([
//depreciated			select Id from SubscriptionLine__c
//depreciated			where Batch__c = :getSubscriptionBatchId() ]).keySet());
//depreciated		System.assert(subLineMap.isEmpty(),'Failed to map batch ids for all Subscription Lines');
//depreciated		subPartnerMap.keySet().removeAll(new Map<Id,SubscriptionPartner__c>([
//depreciated			select Id from SubscriptionPartner__c
//depreciated			where Batch__c = :getSubscriptionBatchId() ]).keySet());
//depreciated		System.assert(subPartnerMap.isEmpty(),'Failed to map batch ids for all Subscription Partners');
//depreciated	}

//depreciated	@isTest
//depreciated	static void updateChildrenTest2() {
//depreciated		setAllBooleanSettings(false);
//depreciated		subscriptionBatch.APACChannelLoadComplete__c = true;
//depreciated		subscriptions[0].SuperRegion__c = 'APAC';
//depreciated		subscriptionBatch.EMEAChannelLoadComplete__c = true;
//depreciated		subscriptions[1].SuperRegion__c = 'EMEA';
//depreciated		subscriptionBatch.LATAMChannelLoadComplete__c = true;
//depreciated		subscriptions[2].SuperRegion__c = 'LATAM';
//depreciated		subscriptionBatch.NAChannelLoadComplete__c = true;
//depreciated		subscriptions[3].SuperRegion__c = 'NA';
//depreciated		Map<Id,Subscription__c> subMap = subscriptionMap;
//depreciated		Map<Id,SubscriptionBatch__c> subBatchMap = new Map<Id,SubscriptionBatch__c>{
//depreciated			getSubscriptionBatchId() => subscriptionBatch
//depreciated		};
//depreciated		SubscriptionBatchTriggerAfter triggerAfter = new SubscriptionBatchTriggerAfter(null,subBatchMap);
//depreciated		Test.startTest();
//depreciated		triggerAfter.updateChildren();
//depreciated		Test.stopTest();
//depreciated		Integer i=0;
//depreciated		for(Subscription__c sub : [
//depreciated			select Status__c, SuperRegion__c
//depreciated			from Subscription__c 
//depreciated			where Id in :new Set<Id>{subscriptions[0].Id,subscriptions[1].Id,subscriptions[2].Id,subscriptions[3].Id} ])
//depreciated		{
//depreciated			i++;
//depreciated			System.assertEquals(SubscriptionBatchTriggerAfter.HOLD_FOR_DECISION_STATUS,sub.Status__c);
//depreciated		}
//depreciated		System.assertEquals(4,i);
//depreciated	}

//depreciated	@isTest
//depreciated	static void processTriggerTest() {
//depreciated		// Turn off all triggers, as we are going to test those next
//depreciated		AbstractTrigger.setBooleanSettings('SubBatch_After.',false);
//depreciated		// insert missing boolean settings
//depreciated		AbstractTrigger.insertMissing = 0;
//depreciated		SubscriptionBatchTriggerAfter.processTrigger(null,new Map<Id,SubscriptionBatch__c>{null=>subscriptionBatch});
//depreciated		// insert the subscriptionBatch, again with the triggers off
//depreciated		insert subscriptionBatch;
//depreciated		// Turn on all the triggers, and make sure everything is tested.
//depreciated		AbstractTrigger.setBooleanSettings('SubBatch_After.',true);
//depreciated		SubscriptionBatch__c subscriptionBatch2 = subscriptionBatch.clone(true);
//depreciated		Test.startTest();
//depreciated		// insert test
//depreciated		SubscriptionBatchTriggerAfter.processTrigger(null,new Map<Id,SubscriptionBatch__c>{subscriptionBatch2.Id=>subscriptionBatch2});
//depreciated		// update test
//depreciated		SubscriptionBatchTriggerAfter.processTrigger(new Map<Id,SubscriptionBatch__c>{subscriptionBatch.Id=>subscriptionBatch},new Map<Id,SubscriptionBatch__c>{subscriptionBatch2.Id=>subscriptionBatch2});
//depreciated		// delete test
//depreciated		SubscriptionBatchTriggerAfter.processTrigger(new Map<Id,SubscriptionBatch__c>{subscriptionBatch.Id=>subscriptionBatch},null);
//depreciated		Test.stopTest();
//depreciated	}

//depreciated	@isTest
//depreciated	static void deployTest() {
//depreciated		AbstractTriggerTest.deployTest('SubBatch_After.',new List<SubscriptionBatch__c>{subscriptionBatch});
//depreciated	}
}