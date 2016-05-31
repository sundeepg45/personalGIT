/**
 * This class replaces all after insert and after update SubscriptionBatch__c triggers.  The
 * processTrigger method is invoked by the SubscriptionBatch_Before trigger and in turn invokes
 * all the processTrigger methods of the subclasses.  This gives us a way to control 
 * the order in which the code logic is invoked, as well as allowing other class features 
 * such as shared data, constant values, and complete test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class or it's subclasses
 * as that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2015-01-27
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-01-27 - Depreciated all methods
 * 2011-09-18 - Created
 */
public without sharing class SubscriptionBatchTriggerAfter /*depreciated extends AbstractTrigger */ {
	/** Status used for waiting for channel load. */
	public static final String WAIT_FOR_CHANNEL_LOAD_STATUS = 'WAIT for Channel Load';
	/** Status used to hold for user decision. */
	public static final String HOLD_FOR_DECISION_STATUS = 'HOLD for Decision';
	/** BooleanSetting__c key to enable the updateChildren trigger method. */

//depreciated	public static final String UPDATE_CHILDREN_SETTING = 'SubBatch_After.updateChildren';

//depreciated	/** Normally populated as a copy of Trigger.oldMap */
//depreciated	public final Map<Id,SubscriptionBatch__c> oldMap = new Map<Id,SubscriptionBatch__c>();
//depreciated	/** Normally populated as Trigger.new */
//depreciated	public final Map<Id,SubscriptionBatch__c> newMap = new Map<Id,SubscriptionBatch__c>();

//depreciated	/**
//depreciated	 * This constructor is normally called from the processTrigger method and
//depreciated	 * test methods.
//depreciated	 */
//depreciated	public SubscriptionBatchTriggerAfter(Map<Id,SubscriptionBatch__c> xoldMap,Map<Id,SubscriptionBatch__c> xnewMap) {
//depreciated		super(xoldMap,null,xnewMap);
//depreciated		if(xoldMap != null) {
//depreciated			oldMap.putAll(xoldMap);
//depreciated		}
//depreciated		if(xnewMap != null) {
//depreciated			newMap.putAll(xnewMap);
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * Future method to update children for the given batch ids.
//depreciated	 * 
//depreciated	 * @param batchIds
//depreciated	 */
//depreciated	@future
//depreciated	public static void updateChildrenFuture(Set<Id> batchIds) {
//depreciated		updateChildrenNotFuture(batchIds);
//depreciated	}

//depreciated	static Set<String> getValues(final Map<String,Set<String>> valuesMap,final String key) {
//depreciated		Set<String> values = valuesMap.get(key);
//depreciated		if(values == null) {
//depreciated			values = new Set<String>();
//depreciated			valuesMap.put(key,values);
//depreciated		}
//depreciated		return values;
//depreciated	}

//depreciated	/**
//depreciated	 * Method to update children for the given batch ids.
//depreciated	 * 
//depreciated	 * @param batchIds
//depreciated	 */
//depreciated	public static void updateChildrenNotFuture(Set<Id> batchIds) {
//depreciated		// I'm worried this may hit governor limits...
//depreciated		Map<String,Id> batchIdMap = new Map<String,Id>();
//depreciated		Map<String,Set<String>> batchIdsBySuperRegion = new Map<String,Set<String>>();
//depreciated		for(SubscriptionBatch__c subBatch : [
//depreciated			select 
//depreciated				BatchId__c,
//depreciated				APACChannelLoadComplete__c,
//depreciated				EMEAChannelLoadComplete__c,
//depreciated				LATAMChannelLoadComplete__c,
//depreciated				NAChannelLoadComplete__c
//depreciated			from SubscriptionBatch__c
//depreciated			where Id in :batchIds])
//depreciated		{
//depreciated			if(subBatch.BatchId__c != null) {
//depreciated				String batchId = subBatch.BatchId__c.toLowerCase();
//depreciated				batchIdMap.put(batchId,subBatch.Id);
//depreciated				if(subBatch.APACChannelLoadComplete__c == true) {
//depreciated					getValues(batchIdsBySuperRegion,'APAC').add(batchId);
//depreciated				}
//depreciated				if(subBatch.EMEAChannelLoadComplete__c == true) {
//depreciated					getValues(batchIdsBySuperRegion,'EMEA').add(batchId);
//depreciated				}
//depreciated				if(subBatch.LATAMChannelLoadComplete__c == true) {
//depreciated					getValues(batchIdsBySuperRegion,'LATAM').add(batchId);
//depreciated				}
//depreciated				if(subBatch.NAChannelLoadComplete__c == true) {
//depreciated					getValues(batchIdsBySuperRegion,'NA').add(batchId);
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		List<Subscription__c> subscriptions = [
//depreciated			select BatchId__c, Status__c, SuperRegion__c
//depreciated			from Subscription__c
//depreciated			where BatchId__c in :batchIdMap.keySet()
//depreciated				and ( Batch__c = null
//depreciated					or (Status__c = :WAIT_FOR_CHANNEL_LOAD_STATUS
//depreciated						and SuperRegion__c in :batchIdsBySuperRegion.keySet() )) ];
//depreciated		for(Subscription__c sub : subscriptions) {
//depreciated			String batchId = sub.BatchId__c.toLowerCase();
//depreciated			sub.Batch__c = batchIdMap.get(batchId);
//depreciated			if(sub.Status__c == WAIT_FOR_CHANNEL_LOAD_STATUS) {
//depreciated				for(String superRegion : batchIdsBySuperRegion.keySet()) {
//depreciated					if(sub.SuperRegion__c == superRegion && batchIdsBySuperRegion.get(superRegion).contains(batchId) ) {
//depreciated						sub.Status__c = HOLD_FOR_DECISION_STATUS;
//depreciated						break;
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			System.debug(sub.BatchId__c + '=>' + sub.Batch__c+' : '+sub.Status__c);
//depreciated		}
//depreciated		Database.update(subscriptions,false);
//depreciated		List<SubscriptionLine__c> subscriptionLines = [
//depreciated			select BatchId__c
//depreciated			from SubscriptionLine__c
//depreciated			where Batch__c = null and BatchId__c in :batchIdMap.keySet() ];
//depreciated		for(SubscriptionLine__c subLine : subscriptionLines) {
//depreciated			subLine.Batch__c = batchIdMap.get(subLine.BatchId__c.toLowerCase());
//depreciated			System.debug(subLine.BatchId__c + '=>' + subLine.Batch__c);
//depreciated		}
//depreciated		Database.update(subscriptionLines,false);
//depreciated		List<SubscriptionPartner__c> subscriptionPartners = [
//depreciated			select BatchId__c
//depreciated			from SubscriptionPartner__c
//depreciated			where Batch__c = null and BatchId__c in :batchIdMap.keySet() ];
//depreciated		for(SubscriptionPartner__c subPartner : subscriptionPartners) {
//depreciated			subPartner.Batch__c = batchIdMap.get(subPartner.BatchId__c.toLowerCase());
//depreciated			System.debug(subPartner.BatchId__c + '=>' + subPartner.Batch__c);
//depreciated		}
//depreciated		Database.update(subscriptionPartners,false);
//depreciated	}

//depreciated	/**
//depreciated	 * In case of locking errors, children won't have the batch id assigned
//depreciated	 * yet.  This method is to update those children.
//depreciated	 * 
//depreciated	 * We also update children that need to change to a new status.
//depreciated	 *
//depreciated	 * To do: Convert to scheduled job to avoid governor limit problems
//depreciated	 */
//depreciated	public void updateChildren() {
//depreciated		// normally we will only process one batch id at a time...
//depreciated		Set<Id> batchIds = new Set<Id>();
//depreciated		for(SubscriptionBatch__c subBatch : newMap.values()) {
//depreciated			if(subBatch.BatchId__c != null) {
//depreciated				batchIds.add(subBatch.Id);
//depreciated			}
//depreciated		}
//depreciated		if(! batchIds.isEmpty()) {
//depreciated			try {
//depreciated				updateChildrenFuture(batchIds);
//depreciated			}
//depreciated			catch(Exception ex) {
//depreciated				updateChildrenNotFuture(batchIds);
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * Method to invoke all triggers
//depreciated	 */
//depreciated	public static void processTrigger(Map<Id,SubscriptionBatch__c> xoldMap,Map<Id,SubscriptionBatch__c> xnewMap) {
//depreciated		final SubscriptionBatchTriggerAfter afterTrigger = new SubscriptionBatchTriggerAfter(xoldMap,xnewMap);
//depreciated		if(AbstractTrigger.isActive(UPDATE_CHILDREN_SETTING,true)) {
//depreciated			afterTrigger.updateChildren();
//depreciated		}
//depreciated		AbstractTrigger.processTriggerComplete();
//depreciated	}
}