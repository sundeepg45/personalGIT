/**
 * This class replaces all after insert and after update SubscriptionLine__c triggers.  The
 * processTrigger method is invoked by the SubscriptionLine_Before trigger and in turn invokes
 * all the processTrigger methods of the subclasses.  This gives us a way to control 
 * the order in which the code logic is invoked, as well as allowing other class features 
 * such as shared data, constant values, and complete test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class or it's subclasses
 * as that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2014-12-19
 * @author Bill C Riemers <briemers@redhat.com>
 * 2014-12-19 - Revised the updateSubscriptions method to update entitle to information
 * 2013-09-12 - Created
 */
public without sharing class SubscriptionLineTriggerAfter extends AbstractTrigger{
	/** Map of subscriptions by line item key to update entitle to information. */
	public static Map<Id,Subscription__c> queriedSubscriptionMap = null;

	/** BooleanSetting__c key to enable the updateSubscriptions trigger method. */
	public static final String UPDATE_SUBSCRIPTIONS_SETTING = 'SubLine_After.updateSubcriptions';

	/** Normally populated as a copy of Trigger.oldMap */
	public final Map<Id,SubscriptionLine__c> oldMap = new Map<Id,SubscriptionLine__c>();
	/** Normally populated as Trigger.new */
	public final Map<Id,SubscriptionLine__c> newMap = new Map<Id,SubscriptionLine__c>();

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	public SubscriptionLineTriggerAfter(Map<Id,SubscriptionLine__c> xoldMap,Map<Id,SubscriptionLine__c> xnewMap) {
		super(xoldMap,null,xnewMap);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	/**
	 * Update entitle to information on subscriptions.
	 */
	private Map<Id,Subscription__c> getUpdateEntitleToSubscriptionMap() {
		Map<Id,Subscription__c> retval = new Map<Id,Subscription__c>();
		Map<Id,Subscription__c> xqueriedSubscriptionMap = queriedSubscriptionMap;
		queriedSubscriptionMap = null;
		if(xqueriedSubscriptionMap == null) {
			Set<id> origSubIds = new Set<Id>();
			for(SubscriptionLine__c subLine : newMap.values()) {
				if(subLine.OriginalSubscription__c != null && subLine.EntitleToContactEmail__c != null) {
					origSubIds.add(subLine.OriginalSubscription__c);
				}
			}
			xqueriedSubscriptionMap = new Map<Id,Subscription__c>([
				select
					Id,
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
					EntitleToState__c
				from Subscription__c
				where Id in :origSubIds
					and EntitleToContactEmail__c = null ]);
		}
		if(! xqueriedSubscriptionMap.isEmpty()) {
			for(SubscriptionLine__c subLine : newMap.values()) {
				Subscription__c sub = xqueriedSubscriptionMap.get(subLine.OriginalSubscription__c);
				if( sub != null
					&& sub.EntitleToAddress1__c == null
					&& sub.EntitleToAddress2__c == null
					&& sub.EntitleToCDHPartyNumber__c == subLine.EntitleToCDHPartyNumber__c
					&& sub.EntitleToCDHPartySiteNumber__c == subLine.EntitleToCDHPartySiteNumber__c
					&& sub.EntitleToCity__c == null
					&& sub.EntitleToContactEmail__c == null
					&& sub.EntitleToContactFirstName__c == null
					&& sub.EntitleToContactLastName__c == null
					&& sub.EntitleToContactName__c == null
					&& sub.EntitleToContactPhone__c == null
					&& sub.EntitleToContCDHPartyNumber__c == subLine.EntitleToContCDHPartyNumber__c
					&& sub.EntitleToCountry__c == null
					&& sub.EntitleToPostalCode__c == null
					&& sub.EntitleToState__c == null )
				{
					if(sub.EntitleToAccountNumber__c == null) {
						sub.EntitleToAccountNumber__c = subLine.EntitleToAccountNumber__c;
					}
					if(sub.EntitleToPartyNumber__c == null) {
						sub.EntitleToPartyNumber__c = subLine.EntitleToPartyNumber__c;
					}
					if(sub.EntitleToPartyName__c == null) {
						sub.EntitleToPartyName__c = subLine.EntitleToPartyName__c;
					}
					sub.EntitleToAddress1__c = subLine.EntitleToAddress1__c;
					sub.EntitleToAddress2__c = subLine.EntitleToAddress2__c;
					sub.EntitleToCity__c = subLine.EntitleToCity__c;
					sub.EntitleToContactEmail__c = subLine.EntitleToContactEmail__c;
					sub.EntitleToContactFirstName__c = subLine.EntitleToContactFirstName__c;
					sub.EntitleToContactLastName__c = subLine.EntitleToContactLastName__c;
					sub.EntitleToContactName__c = subLine.EntitleToContactName__c;
					sub.EntitleToContactPhone__c = subLine.EntitleToContactPhone__c;
					sub.EntitleToCountry__c = subLine.EntitleToCountry__c;
					sub.EntitleToPostalCode__c = subLine.EntitleToPostalCode__c;
					sub.EntitleToState__c = subLine.EntitleToState__c;
					retval.put(sub.Id,sub);
				}
			}
		}
		return retval;
	}

	private void getForceRecomputeSubscriptionMap(Map<Id,Subscription__c> subMap) {
		Set<Id> subIds = new Set<Id>();
		for(SubscriptionLine__c subLine : newMap.values()) {
			SubscriptionLine__c oldSubLine = oldMap.get(subLine.Id);
			if(oldSubLine == null) {
				oldSubLine = new SubscriptionLine__c(
					CurrencyIsoCode = subLine.CurrencyIsoCode,
					RenewalTotalPrice__c=0.00,
					Subscription__c = null,
					DnrFlag__c = subLine.DnrFlag__c,
					NfrFlag__c = subLine.NfrFlag__c);
			}
			if( oldSubLine.RenewalTotalPrice__c != subLine.RenewalTotalPrice__c
				|| (subLine.RenewalTotalPrice__c != 0
					&& ( (oldSubLine.Subscription__c != null && oldSubLine.Subscription__c != subLine.Subscription__c )
						|| subLine.CurrencyIsoCode != oldSubLine.CurrencyIsoCode
						|| subLine.DnrFlag__c != oldSubLine.DnrFlag__c
						|| subLine.NfrFlag__c != oldSubLine.NfrFlag__c) ) )
			{
				subIds.add(subLine.Subscription__c);
				subIds.add(oldSubLine.Subscription__c);
			}
		}
		subIds.remove(null);
		subIds.removeAll(subMap.keySet());
		if(! subIds.isEmpty()) {
			List<Subscription__c> updateList = new List<Subscription__c>();
			for(Id subId : subIds) {
				subMap.put(subId,new Subscription__c(Id=subId));
			}
		}
	}

	/**
	 * Update subscriptions when neccessary.
	 */
	public void updateSubscriptions() {
		Map<Id,Subscription__c> subscriptionMap = getUpdateEntitleToSubscriptionMap();
		getForceRecomputeSubscriptionMap(subscriptionMap);
		if(!subscriptionMap.isEmpty()) {
			List<Subscription__c> subscriptions = new List<Subscription__c>(subscriptionMap.values());
			Database.update(subscriptions,false);
//		  for(Database.SaveResult sr : Database.update(subscriptions,false)) {
//			  Subscription__c subscription = subscriptions.remove(0);
//			  if(! sr.isSuccess()) {
//				  subscriptionIdMap.remove(subscription.Id);
//				  SubscriptionLine__c subLine = newMap.get(subscriptionIdMap.get(subscription.Id));
//				  if(subLine != null) {
//					  for(Database.Error e : sr.getErrors()) {
//						  subLine.addError(''+e);
//						  hasErrors = true;
//					  }
//				  }
//			  }
//		  }
		}
	}

	/**
	 * Method to invoke all triggers
	 */
	public static void processTrigger(Map<Id,SubscriptionLine__c> xoldMap,Map<Id,SubscriptionLine__c> xnewMap) {
		final SubscriptionLineTriggerAfter afterTrigger = new SubscriptionLineTriggerAfter(xoldMap,xnewMap);
		if(AbstractTrigger.isActive(UPDATE_SUBSCRIPTIONS_SETTING,true)) {
			afterTrigger.updateSubscriptions();
		}
		queriedSubscriptionMap = null;
		AbstractTrigger.processTriggerComplete();
	}
}