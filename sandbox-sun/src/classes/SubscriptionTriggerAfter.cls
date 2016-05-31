/**
 * This class replaces all after insert and after update Subscription__c triggers.  The
 * processTrigger method is invoked by the Subscription_Before trigger and in turn invokes
 * all the processTrigger methods of the subclasses.  This gives us a way to control 
 * the order in which the code logic is invoked, as well as allowing other class features 
 * such as shared data, constant values, and complete test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class or it's subclasses
 * as that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2015-04-06
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-04-06 - Added the a static readyIds to allow deleting errors from subscriptions that were READY in the before trigger
 * 2015-02-19 - Updated comments
 * 2014-12-22 - Revised updateSubscriptionLines to accept a static queriedSubscriptionLines list
 * 2014-12-12 - Use a composite key for subscription partners
 * 2014-12-09 - Added line item updates based on matching logic in before trigger
 * 2014-11-24 - Updated for campaigns
 * 2011-09-12 - Created
 */
public without sharing class SubscriptionTriggerAfter extends AbstractTrigger{
	/** BooleanSetting__c key to enable the clearErrorsWhenReady trigger method. */
	public static final String CLEAR_ERRORS_SETTING = 'Sub_After.clearErrorsWhenReady';
	/** BooleanSetting__c key to enable the matchAccounts trigger method. */
	public static final String MATCH_ACCOUNTS_SETTING = 'Sub_After.matchAccounts';
	/** BooleanSetting__c key to enable the updateSubscriptionLines trigger method. */
	public static final String UPDATE_SUBSCRIPTION_LINES_SETTING = 'Sub_After.updateSubLines';
	/** BooleanSetting__c key to enable the updateSubscriptionPartnerRelations trigger method. */
	public static final String UPDATE_SUBSCRIPTION_PARTNER_RELATIONSHIP_SETTING = 'Sub_After.updateSubPartRel';

	/** List of subscription lines that may need to be updated */
	public static List<SubscriptionLine__c> queriedSubscriptionLines = new List<SubscriptionLine__c>();

	/** Set of subscription ids which were in a ready status */
	public static final Set<Id> readyIds = new Set<Id>();

	/** Normally populated as a copy of Trigger.oldMap */
	public final Map<Id,Subscription__c> oldMap = new Map<Id,Subscription__c>();
	/** Normally populated as Trigger.new */
	public final Map<Id,Subscription__c> newMap = new Map<Id,Subscription__c>();

	public static final String READY_STATUS = 'READY';
	public static final String READY_FOR_SSI_STATUS = 'READY for SSI';
	public static final String SUCCESS_STATUS = 'SUCCESS';

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	public SubscriptionTriggerAfter(Map<Id,Subscription__c> xoldMap,Map<Id,Subscription__c> xnewMap) {
		super(xoldMap,null,xnewMap);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	/**
	 * Call to delete the subscription errors.
	 */
	public void clearErrorsWhenReady() {
		if(isUpdate) {
			Set<Id> ids = new Set<Id>(readyIds);
			for(Subscription__c sub : newMap.values()) {
				if(sub.Status__c == READY_STATUS
					|| (sub.Status__c == READY_FOR_SSI_STATUS 
						&& (sub.SuperRegion__c == 'NA' || sub.SuperRegion__c == 'LATAM') ) )
				{
					ids.add(sub.Id);
				}
			}
			if(! ids.isEmpty()) {
				List<SubscriptionError__c> subErrors = [
					select Id 
					from SubscriptionError__c 
					where Subscription__c in :ids ];
				if(subErrors != null) {
					Database.delete(subErrors,false);
				}
			}
		}
	}

	/**
	 * Link all the relevant SubscriptionLine__c records.  This trigger is only useful if
	 * the composite keys have been assigned to the subscription line records at the time of
	 * loading.
	 */
	public void updateSubscriptionLines() {
		Map<String,Subscription__c> keyMap = new Map<String,Subscription__c>();
		for(Subscription__c sub : newMap.values()) {
			if(sub.CompositeKey__c != null && sub.Status__c != READY_STATUS) {
				keyMap.put(sub.CompositeKey__c,sub);
			}
		}
		if(! keyMap.isEmpty()) {
			List<SubscriptionLine__c> updateList = new List<SubscriptionLine__c>();
			List<SubscriptionLine__c> queriedList = queriedSubscriptionLines;
			queriedSubscriptionLines = null;
			if(queriedList == null) {
				queriedList = [
					select
						CurrencyIsoCode,
						OwnerId,
						OriginalCompositeKey__c,
						OriginalSubscription__c,
						Subscription__c,
						SubscriptionCompositeKey__c
					from SubscriptionLine__c
					where Subscription__c in : newMap.keySet()
						or OriginalSubscription__c in : newMap.keySet()
						or ( OriginalSubscription__c = null
							and OriginalCompositeKey__c in :keyMap.keySet() )
						or ( Subscription__c = null
							and SubscriptionCompositeKey__c in :keyMap.keySet() ) ];
			}
			for(SubscriptionLine__c subLine : queriedList ) {
				Boolean updated = false;
				Subscription__c sub = newMap.get(subLine.Subscription__c);
				if(subLine.Subscription__c == null) {
					sub = keyMap.get(subLine.SubscriptionCompositeKey__c);
				}
				if(sub != null) {
					if(sub.CurrencyIsoCode != subLine.CurrencyIsoCode) {
						subLine.CurrencyIsoCode = sub.CurrencyIsoCode;
						updated = true;
					}
					if(sub.OwnerId != subLine.OwnerId) {
						subLine.OwnerId = sub.OwnerId;
						updated = true;
					}
					if(sub.Id != subLine.Subscription__c) {
						subLine.Subscription__c = sub.Id;
						updated = true;
					}
					if(sub.CompositeKey__c != subLine.SubscriptionCompositeKey__c) {
						subLine.SubscriptionCompositeKey__c = sub.CompositeKey__c;
						updated = true;
					}
				}
				sub = newMap.get(subLine.OriginalSubscription__c);
				if(subLine.OriginalSubscription__c == null) {
					sub = keyMap.get(subLine.OriginalCompositeKey__c);
				}
				if(sub != null) {
					if(subLine.Subscription__c == null && sub.CurrencyIsoCode != subLine.CurrencyIsoCode) {
						subLine.CurrencyIsoCode = sub.CurrencyIsoCode;
						updated = true;
					}
					if(subLine.Subscription__c == null && sub.OwnerId != subLine.OwnerId) {
						subLine.OwnerId = sub.OwnerId;
						updated = true;
					}
					if(sub.Id != subLine.OriginalSubscription__c) {
						subLine.OriginalSubscription__c = sub.Id;
						updated = true;
					}
					if(sub.CompositeKey__c != subLine.OriginalCompositeKey__c) {
						subLine.OrderId__c = sub.OrderId__c;
						subLine.ContractId__c = sub.ContractId__c;
						subLine.OriginalCompositeKey__c = sub.CompositeKey__c;
						updated = true;
					}
				}
				if(updated) {
					updateList.add(subLine);
					System.debug(subLine);
				}
			}
			Database.update(updateList,false);
		}
	}

	/**
	 * Scan through all the related records and create missing SubscriptionPartnerRelationship__c objects.
	 */
	public void updateSubscriptionPartnerRelationship() {
		Set<Decimal> orderIds = new Set<Decimal>();
		Map<Long,List<Subscription__c>> subsMap = new Map<Long,List<Subscription__c>>();
		for(Subscription__c sub : newMap.values()) {
			if(sub.OrderId__c != null && sub.CompositeKey__c != null) {
				Subscription__c oldSub = oldMap.get(sub.Id);
				if(oldSub == null || oldSub.CompositeKey__c != sub.CompositeKey__c) {
					List<Subscription__c> subs = subsMap.get(sub.OrderId__c.longValue());
					if(subs == null) {
						subs = new List<Subscription__c>();
						orderIds.add(sub.OrderId__c);
						subsMap.put(sub.OrderId__c.longValue(),subs);
					}
					subs.add(sub);
				}
			}
		}
		if(! subsMap.isEmpty()) {
			Map<String,SubscriptionPartnerRelationship__c> subPartRelMap = new Map<String,SubscriptionPartnerRelationship__c>();
			for(SubscriptionPartner__c subPartner : [
				select
					AccountId__c,
					ApId__c,
					CompositeKey__c,
					OrderId__c
				from SubscriptionPartner__c
				where OrderId__c in :orderIds ])
			{
				if(subPartner.OrderId__c != null && subPartner.CompositeKey__c != null) {
					for(Subscription__c sub : subsMap.get(subPartner.OrderId__c.longValue())) {
						String compositeKey = sub.CompositeKey__c+':'+subPartner.CompositeKey__c;
						subPartRelMap.put(compositeKey,new SubscriptionPartnerRelationship__c(
							AccountId__c = subPartner.AccountId__c,
							ApId__c = subPartner.ApId__c,
							CompositeKey__c = compositeKey,
							ContractId__c = sub.ContractId__c,
							OrderId__c = subPartner.OrderId__c,
							Subscription__c = sub.Id,
							SubscriptionPartner__c = subPartner.Id ) );
					}
				}
			}
			if(! subPartRelMap.isEmpty()) {
				for(SubscriptionPartnerRelationship__c subPartRel : [
					select CompositeKey__c
					from SubscriptionPartnerRelationship__c
					where CompositeKey__c in : subPartRelMap.keySet() ])
				{
					subPartRelMap.remove(subPartRel.CompositeKey__c);
				}
				Database.insert(subPartRelMap.values(),false);
			}
		}
	}

	/**
	 * Continuation of the before matchAccounts trigger.  Update any subscription lines 
	 * that need to be updated and insert subscription errors.
	 */
	public void matchAccounts() {
		List<SubscriptionError__c> errorList = SubscriptionTriggerBefore.errorList;
		List<SubscriptionLine__c> updatedLines = SubscriptionTriggerBefore.updatedLines;
		SubscriptionTriggerBefore.errorList = null;
		SubscriptionTriggerBefore.updatedLines = null;
		if(errorList != null && !errorList.isEmpty()) {
			// any non-warning has been added to the subscription error
			// message, so we can safely ignore failures
			Database.insert(errorList,false);
		}
		if(updatedLines != null && ! updatedLines.isEmpty()) {
			// failures will be ignored.  This is not critical...
			Database.update(updatedLines,false);
		}
	}

	/**
	 * Method to invoke all triggers
	 */
	public static void processTrigger(Map<Id,Subscription__c> xoldMap,Map<Id,Subscription__c> xnewMap) {
		final SubscriptionTriggerAfter afterTrigger = new SubscriptionTriggerAfter(xoldMap,xnewMap);
		if(AbstractTrigger.isActive(CLEAR_ERRORS_SETTING,true)) {
			afterTrigger.clearErrorsWhenReady();
		}
		if(AbstractTrigger.isActive(MATCH_ACCOUNTS_SETTING,true)) {
			afterTrigger.matchAccounts();
		}
		if(AbstractTrigger.isActive(UPDATE_SUBSCRIPTION_LINES_SETTING,true)) {
			afterTrigger.updateSubscriptionLines();
		}
		if(AbstractTrigger.isActive(UPDATE_SUBSCRIPTION_PARTNER_RELATIONSHIP_SETTING,true)) {
			afterTrigger.updateSubscriptionPartnerRelationship();
		}
		queriedSubscriptionLines = null;
		AbstractTrigger.processTriggerComplete();
	}

}