/**
 * This class replaces all before insert and before update SubscriptionLine__c triggers.  The
 * processTrigger method is invoked by the SubscriptionLine_Before trigger and in turn invokes
 * all the processTrigger methods of the subclasses.  This gives us a way to control 
 * the order in which the code logic is invoked, as well as allowing other class features 
 * such as shared data, constant values, and complete test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class or it's subclasses
 * as that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2015-04-21
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-04-21 - relplace assignSalesAccountFields with syncAccountFields
 * 2015-04-20 - Corrected the assignSalesAccount method to query accounts before assignment.
 * 2015-02-19 - Updated composite key logic
 * 2015-01-27 - commenting out assigned batch
 * 2014-12-19 - Revised assignSubscription method to identify subscriptions that need updated entitle to information and pass to the after trigger.
 * 2014-12-12 - Revised composite key logic to treat null as nill
 * 2014-11-20 - Added support for merges in the composite key assignments
 * 2013-09-11 - Created
 */
public without sharing class SubscriptionLineTriggerBefore  extends AbstractTrigger {
	/** BooleanSetting__c key to enable the assignBatch trigger method. */
	public static final String ASSIGN_BATCH_SETTING = 'SubLine_Before.assignBatch';
	/** BooleanSetting__c key to enable the assignOwner trigger method. */
	public static final String ASSIGN_OWNER_SETTING = 'SubLine_Before.assignOwner';
	/** BooleanSetting__c key to enable the assignCompositeKey trigger method. */
	public static final String ASSIGN_COMPOSITE_KEY_SETTING = 'SubLine_Before.assignCompositeKey';
	/** BooleanSetting__c key to enable the syncAccountFields trigger method. */
	public static final String SYNC_ACCOUNT_SETTING = 'Sub_Before.syncAccount';
	/** BooleanSetting__c key to enable the assignSubscription trigger method. */
	public static final String ASSIGN_SUBSCRIPTION_SETTING = 'SubLine_Before.assignSubscription';
	/** BooleanSetting__c key to enable the calcRenewalValues trigger method. */
	public static final String ASSIGN_CALC_RENEWAL_VALUES_SETTING = 'SubLine_Before.calcRenewalValues';

	private final Map<Id,SubscriptionLine__c> oldMap = new Map<Id,SubscriptionLine__c>();
	private final List<SubscriptionLine__c> newList = new List<SubscriptionLine__c>();

	/**
	 * Standard constructor.
	 * 
	 * @param xoldMap
	 * @param xnewList
	 */
	public SubscriptionLineTriggerBefore(Map<Id,SubscriptionLine__c> xoldMap,List<SubscriptionLine__c> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

//depreciated	/**
//depreciated	 * Assign the batch.  If there are multiple batches running in 
//depreciated	 * parallel, there will be locking errors.  Those will be ignored
//depreciated	 * here and handled in future methods.
//depreciated	 */
//depreciated	public void assignBatch() {
//depreciated		Map<String,Id> batchIdMap = new Map<String,Id>();
//depreciated		Set<String> batchIds = new Set<String>();
//depreciated		for(SubscriptionLine__c subLine : newList) {
//depreciated			if(subLine.BatchId__c != null) {
//depreciated				if(subLine.Batch__c != null) {
//depreciated					batchIdMap.put(subLine.BatchId__c.toLowerCase(),subLine.Batch__c);
//depreciated				}
//depreciated				else {
//depreciated					batchIds.add(subLine.BatchId__c.toLowerCase());
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		batchIds.removeAll(batchIdMap.keySet());
//depreciated		if(! batchIds.isEmpty()) {
//depreciated			for(SubscriptionBatch__c batch : [
//depreciated				select BatchId__c
//depreciated				from SubscriptionBatch__c
//depreciated				where BatchId__c in :batchIds ] )
//depreciated			{
//depreciated				batchIdMap.put(batch.BatchId__c.toLowerCase(),batch.Id);
//depreciated			}
//depreciated			batchIds.removeAll(batchIdMap.keySet());
//depreciated			if(! batchIds.isEmpty()) {
//depreciated				List<SubscriptionBatch__c> subscriptionBatches = new List<SubscriptionBatch__c>();
//depreciated				for(String batchId : batchIds) {
//depreciated					subscriptionBatches.add(new SubscriptionBatch__c(
//depreciated						BatchId__c = batchId ));
//depreciated				}
//depreciated				for(Database.UpsertResult ur : Database.upsert(subscriptionBatches,SubscriptionBatch__c.Fields.BatchId__c,false)) {
//depreciated					SubscriptionBatch__c batch = subscriptionBatches.remove(0);
//depreciated					if(ur.isSuccess()) {
//depreciated						batchIdMap.put(batch.BatchId__c,batch.Id);
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		if(! batchIdMap.isEmpty()) {
//depreciated			for( SubscriptionLine__c subLine : newList ) {
//depreciated				if(subLine.BatchId__c != null) {
//depreciated					Id id = batchIdMap.get(subLine.BatchId__c.toLowerCase());
//depreciated					if(id != null && id != subLine.Batch__c) {
//depreciated						subLine.Batch__c = id;
//depreciated						System.debug('subLine.Batch__c=>'+id);
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}

	/**
	 * Calculate the RenewalUnitPrice__c and RenewalTotalPrice__c values.
	 */
	public void calcRenewalValues() {
		for(SubscriptionLine__c subLine : newList) {
			// This calculation is an over simplification.
			// We are suppose to also take into account 
			// changes in the exchange rate, but it is not 
			// clear how or why.  In any case this calculation
			// is just my best guess.
			Integer scale = 2;
			CurrencyType ct = SubscriptionTriggerBefore.currencyTypeMap.get(subLine.CurrencyIsoCode);
			if(ct != null) {
				scale = ct.DecimalPlaces;
			}
			Double orderedQuantity = 0;
			if(subLine.OrderedQuantity__c != null && subLine.OrderedQuantity__c != 0) {
				orderedQuantity = subLine.OrderedQuantity__c.doubleValue();
			}
			Double substituteQuantity = 1.0;
			if(subLine.SubstituteQuantity__c != null && subLine.SubstituteQuantity__c != 0) {
				substituteQuantity = subLine.SubstituteQuantity__c.doubleValue();
			}
			Double renewalQuantity = orderedQuantity * substituteQuantity;
			Double unitSellingPrice = 0.0;
			if(subLine.UnitSellingPrice__c != null) {
				unitSellingPrice = subLine.UnitSellingPrice__c.doubleValue();
			}
			Decimal renewalUnitPrice = Decimal.valueOf(unitSellingPrice / substituteQuantity).setScale(scale);
			if(subLine.SubstituteItemListPrice__c != null && subLine.SubstituteItemListPrice__c != 0) {
				Double discountFactor = 1.0;
				if(subLine.UnitListPrice__c != null && subLine.UnitListPrice__c != 0) {
					discountFactor = unitSellingPrice / subLine.UnitListPrice__c.doubleValue();
				}
				// this may not be correct.  It is unclear if this value should be divided by substitute quantity
				renewalUnitPrice = Decimal.valueOf(subLine.SubstituteItemListPrice__c.doubleValue() * discountFactor).setScale(scale);
			}
			if(renewalUnitPrice != subLine.RenewalUnitPrice__c) {
				subLine.RenewalUnitPrice__c = renewalUnitPrice;
			}
			Decimal renewalTotalPrice = Decimal.valueOf(renewalUnitPrice.doubleValue() * renewalQuantity).setScale(scale);
			if(renewalTotalPrice != subLine.RenewalTotalPrice__c) {
				subLine.RenewalTotalPrice__c = renewalTotalPrice;
			}
		}
	}

	/**
	 * assign the owner based on the solution owner.
	 */
	public void assignOwner() {
		for(SubscriptionLine__c subLine : newList ) {
			Id ownerId = subLine.SubscriptionOwnerId__c;
			if(ownerId != null && ownerId != subLine.OwnerId) {
				subLine.OwnerId = ownerId;
			}
		}
	}

	/**
	 * assign the original subscription composite key
	 */
	public void assignCompositeKey() {
		for(SubscriptionLine__c subLine : newList) {
			String subscriptionCompositeKey = null;
			String orderId = '';
			if(subLine.OrderId__c != null) {
				orderId = String.valueOf(subLine.OrderId__c.longValue());
			}
			String contractId = '';
			if(subLine.ContractId__c != null) {
				contractId = String.valueOf(subLine.ContractId__c.longValue());
			}
			String fiscalYear = '????';
			if(subLine.FiscalYear__c != null) {
				fiscalYear = String.valueOf(subLine.FiscalYear__c.longValue());
			}
			String fiscalQuarter = '?';
			if(subLine.FiscalQuarter__c != null) {
				fiscalQuarter = String.valueOf(subLine.FiscalQuarter__c.longValue());
			}
			if(orderId != '' || contractId != '') {
				subscriptionCompositeKey = orderId+':'+contractId+'FY'+fiscalYear+'Q'+fiscalQuarter;
			}
//			// once assigned the subscription composite key should not change
//			if(subLine.SubscriptionCompositeKey__c == null) {
//				subLine.SubscriptionCompositeKey__c = subscriptionCompositeKey;
//			}
			// the original subscription composite key should always match the order and contract id
			if(subscriptionCompositeKey != subLine.OriginalCompositeKey__c) {
				subLine.OriginalCompositeKey__c = subscriptionCompositeKey;
			}
		}
	}

	private static Id idValue(String value) {
		Id retval = null;
		try {
			retval = value;
		}
		catch(Exception ex) {}
		return retval;
	}

	/**
	 * Called to synchronize the EntitleToSfAccountId and EntitleToSalesAccount__c fields.
	 */
	public void syncAccountFields() {
		Set<Id> accountIds = new Set<Id>();
		for(SubscriptionLine__c subLine : newList) {
			Id entitleToSfAccountId = idValue(subLine.EntitleToSfAccountId__c);
			SubscriptionLine__c oldSubLine = oldMap.get(subLine.Id);
			if(oldSubLine == null) {
				oldSubLine = new SubscriptionLine__c();
			}
			if(oldSubLine.EntitleToSalesAccount__c != subLine.EntitleToSalesAccount__c) {
				subLine.EntitleToSfAccountId__c = subLine.EntitleToSalesAccount__c;
			}
			else if(entitleToSfAccountId != subLine.EntitleToSalesAccount__c) {
				accountIds.add(entitleToSfAccountId);
			}
		}
		if(! accountIds.isEmpty()) {
			accountIds.remove(null);
			if(! accountIds.isEmpty()) {
				accountIds = new Map<Id,Account>([
					select Id
					from Account
					where Id in :accountIds ]).keySet();
			}
			for(SubscriptionLine__c subLine : newList) {
				Id entitleToSfAccountId = idValue(subLine.EntitleToSfAccountId__c);
				if(entitleToSfAccountId != subLine.EntitleToSalesAccount__c) {
					if(! accountIds.contains(entitleToSfAccountId)) {
						entitleToSfAccountId = null;
					}
					subLine.EntitleToSfAccountId__c = subLine.EntitleToSalesAccount__c = entitleToSfAccountId;
				}
			}
		}
	}

	/**
	 * assign to a subscription
	 */
	public void assignSubscription() {
		Set<String> compositeKeys = new Set<String>();
		Set<Id> origSubIds = new Set<Id>();
		Set<Decimal> orderIds = new Set<Decimal>();
		Set<Decimal> fiscalYears = new Set<Decimal>();
		Set<Decimal> fiscalQuarters = new Set<Decimal>();
		for(SubscriptionLine__c subLine : newList) {
			if(subLine.OriginalCompositeKey__c != null) {
				if(subLine.Subscription__c == null) {
					if(subLine.SubscriptionCompositeKey__c != null) {
						compositeKeys.add(subLine.SubscriptionCompositeKey__c);
					}
					else {
						orderIds.add(subLine.OrderId__c);
						fiscalYears.add(subLine.FiscalYear__c);
						fiscalQuarters.add(subLine.FiscalQuarter__c);
					}
					compositeKeys.add(subLine.OriginalCompositeKey__c);
					if(subLine.OriginalSubscription__c != null && subLine.EntitleToContactEmail__c != null) {
						origSubIds.add(subLine.OriginalSubscription__c);
					}
				}
			}
		}
		if(! compositeKeys.isEmpty()) {
			Map<Id,Subscription__c> queriedSubscriptionMap = new Map<Id,Subscription__c>([
				select
					CompositeKey__c,
					CurrencyIsoCode,
					OrderId__c,
					EntitleToAccountNumber__c,
					EntitleToAddress1__c,
					EntitleToAddress2__c,
					EntitleToCDHPartyNumber__c,
					EntitleToCDHPartySiteNumber__c,
					EntitleToCity__c,
					EntitleToContactEmail__c,
					EntitleToContactFirstName__c,
					EntitleToContactLastName__c,
					EntitleToContactName__c,
					EntitleToContactPhone__c,
					EntitleToContCDHPartyNumber__c,
					EntitleToCountry__c,
					EntitleToPartyNumber__c,
					EntitleToPartyName__c,
					EntitleToPostalCode__c,
					EntitleToState__c,
					OwnerId
				from Subscription__c
				where CompositeKey__c <> null and 
					(	CompositeKey__c in :compositeKeys
						or ( Id in :origSubIds and EntitleToContactEmail__c = null)
						or ( OrderId__c in :orderIds 
							and FiscalYear__c in :fiscalYears
							and FiscalQuarter__c in :fiscalQuarters ) )
				order by ContractId__c ]);
			SubscriptionLineTriggerAfter.queriedSubscriptionMap = queriedSubscriptionMap;
			Map<String,Subscription__c> subscriptionMap = new Map<String,Subscription__c>();
			for(Subscription__c sub : queriedSubscriptionMap.values()) {
				subscriptionMap.put(sub.CompositeKey__c,sub);
				String key = sub.CompositeKey__c.replaceFirst(':.*FY','FY');
				subscriptionMap.put(key,sub);
				System.debug('Added '+key+' => '+sub.Id);
			}
			for(SubscriptionLine__c subLine : newList) {
				if(subLine.OriginalCompositeKey__c != null) {
					if(subLine.Subscription__c == null) {
						String key = subLine.SubscriptionCompositeKey__c;
						if(key == null && subLine.OrderId__c != null) {
							key = String.valueOf(subLine.OrderId__c.longValue())+subLine.OriginalCompositeKey__c.replaceFirst('.*FY','FY');
						}
						if(key != null) {
							Subscription__c sub = subscriptionMap.get(key);
							if(sub != null) {
								System.debug('Got '+key+' => '+sub.Id);
								subLine.SubscriptionCompositeKey__c = sub.CompositeKey__c;
								subLine.CurrencyIsoCode = sub.CurrencyIsoCode;
								subLine.OwnerId = sub.OwnerId;
								subLine.Subscription__c = sub.Id;
							}
						}
					}
					if(subLine.OriginalSubscription__c == null) {
						Subscription__c sub = subscriptionMap.get(subLine.OriginalCompositeKey__c);
						if(sub != null) {
							if(subLine.Subscription__c == null) {
								subLine.OwnerId = sub.OwnerId;
							}
							subLine.OriginalSubscription__c = sub.Id;
						}
					}
				}
			}
		}
	}

	/**
	 * This method is called from the SubscriptionLine_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Subscription Line objects as in Trigger.oldMap.
	 * @param xnewList the list of new Subscription Line objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,SubscriptionLine__c> xoldMap,List<SubscriptionLine__c> xnewList) {
		final SubscriptionLineTriggerBefore beforeTrigger = new SubscriptionLineTriggerBefore(xoldMap,xnewList);
		SubscriptionLineTriggerAfter.queriedSubscriptionMap = null;
//depreciated		if(AbstractTrigger.isActive(ASSIGN_BATCH_SETTING,true)) {
//depreciated			beforeTrigger.assignBatch();
//depreciated		}
		if(AbstractTrigger.isActive(ASSIGN_OWNER_SETTING,true)) {
			beforeTrigger.assignOwner();
		}
		if(AbstractTrigger.isActive(ASSIGN_COMPOSITE_KEY_SETTING,true)) {
			beforeTrigger.assignCompositeKey();
		}
		if(AbstractTrigger.isActive(SYNC_ACCOUNT_SETTING,true)) {
			beforeTrigger.syncAccountFields();
		}
		if(AbstractTrigger.isActive(ASSIGN_SUBSCRIPTION_SETTING,true)) {
			beforeTrigger.assignSubscription();
		}
		if(AbstractTrigger.isActive(ASSIGN_CALC_RENEWAL_VALUES_SETTING,true)) {
			beforeTrigger.calcRenewalValues();
		}
		AbstractTrigger.processTriggerComplete();
	}
}