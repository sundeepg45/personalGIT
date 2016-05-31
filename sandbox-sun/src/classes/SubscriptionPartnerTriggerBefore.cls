/**
 * This class replaces all before insert and before update SubscriptionPartner__c triggers.  The
 * processTrigger method is invoked by the SubscriptionPartner_Before trigger and in turn invokes
 * all the processTrigger methods of the subclasses.  This gives us a way to control 
 * the order in which the code logic is invoked, as well as allowing other class features 
 * such as shared data, constant values, and complete test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class or it's subclasses
 * as that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2015-02-24
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-02-24 - Allow any valid reseller partner type
 * 2015-01-27 - Commenting out assign batch, since we aren't using this feature and the tests are failing
 * 2014-12-12 - Updated to use a composite key
 * 2011-09-18 - Created
 * Scott Coleman <scoleman@redhat.com>
 * 2014-01-09 - Added mapping of reseller partners
 */
public without sharing class SubscriptionPartnerTriggerBefore  extends AbstractTrigger {
	/** BooleanSetting__c key to enable the assignBatch trigger method. */
	public static final String ASSIGN_BATCH_SETTING = 'SubPart_Before.assignBatch';
	/** BooleanSetting__c key to enable the assignCompositeKey trigger method. */
	public static final String ASSIGN_COMPOSITE_KEY_SETTING = 'SubPart_Before.assignCompositeKey';
	/** BooleanSetting__c key to enable the mapping of reseller partners */
	public static final String MAP_RESELLER_PARTNER_SETTING = 'SubPart_Before.mapResellerPartner';

	private final Map<Id,SubscriptionPartner__c> oldMap = new Map<Id,SubscriptionPartner__c>();
	private final List<SubscriptionPartner__c> newList = new List<SubscriptionPartner__c>();

	/**
	 * Standard constructor.
	 * 
	 * @param xoldMap
	 * @param xnewList
	 */
	public SubscriptionPartnerTriggerBefore(Map<Id,SubscriptionPartner__c> xoldMap,List<SubscriptionPartner__c> xnewList) {
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
//depreciated		for(SubscriptionPartner__c subPartner : newList) {
//depreciated			if(subPartner.BatchId__c != null) {
//depreciated				if(subPartner.Batch__c != null) {
//depreciated					batchIdMap.put(subPartner.BatchId__c.toLowerCase(),subPartner.Batch__c);
//depreciated				}
//depreciated				else {
//depreciated					batchIds.add(subPartner.BatchId__c.toLowerCase());
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
//depreciated			for( SubscriptionPartner__c subPartner : newList ) {
//depreciated				if(subPartner.BatchId__c != null) {
//depreciated					Id id = batchIdMap.get(subPartner.BatchId__c.toLowerCase());
//depreciated					if(id != null && id != subPartner.Batch__c) {
//depreciated						subPartner.Batch__c = id;
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}

	/**
	 * assign the composite key
	 */
	public void assignCompositeKey() {
		assignCompositeKey(newList);
	}

	/**
	 * assign the composite key
	 */
	public static void assignCompositeKey(List<SubscriptionPartner__c> partners) {
		for(SubscriptionPartner__c subPart : partners) {
			String compositeKey = null;
			if(subPart.ApId__c != null || subPart.AccountId__c != null) {
				String apId = '';
				if(subPart.ApId__c != null) {
					apId = String.valueOf(subPart.ApId__c.longValue());
				}
				String accountId = '';
				if(subPart.AccountId__c != null) {
					accountId = String.valueOf(subPart.AccountId__c.longValue());
				}
				compositeKey = apId+':'+accountId;
			}
			if(compositeKey != subPart.CompositeKey__c) {
				subPart.CompositeKey__c = compositeKey;
			}
		}
	}

	/**
	 * do we need to update reseller partner mapping for a subscription partner?
	 */
	private Boolean mapResellerPartner(SubscriptionPartner__c oldSubPartner, SubscriptionPartner__c newSubPartner) {
		return(newSubPartner != null);
				//&& (oldSubPartner == null 
				//	|| newSubPartner.Account__c != oldSubPartner.Account__c
				//	|| newSubPartner.PartyNumber__c != oldSubPartner.PartyNumber__c
				//	|| newSubPartner.TransactionRole__c != oldSubPartner.TransactionRole__c));
	}

	/**
	 * trigger method that maps reseller partner status to the subscription partner
	 */
	public void mapResellerPartner() {
		// create collections of partner Ids and oracle party numbers
		Set<Id> partnerIds = new Set<Id>();
		Set<String> oraclePartyNumbers = new Set<String>();
		List<SubscriptionPartner__c> partnerList2 = new List<SubscriptionPartner__c>();
		for ( SubscriptionPartner__c partner : newList ) {
			SubscriptionPartner__c oldSubPartner = null;
			if(isUpdate) {
				oldSubPartner = oldMap.get(partner.Id);
			}
			if(mapResellerPartner(oldSubPartner, partner)) {
				String tr = partner.TransactionRole__c;
				if(tr == null) {
					partnerList2.add(partner);
				}
				else if(tr != null) {
					tr = tr.toLowerCase().trim().replaceAll(' ','');
					if(tr.startsWith('reseller')) {
						partnerList2.add(partner);
					}
				}
			}
		}
		for ( SubscriptionPartner__c partner : partnerList2 ) {
			if ( partner.PartyNumber__c != null && partner.PartyNumber__c != '' ) {
				oraclePartyNumbers.add( partner.PartyNumber__c );
			}
			if ( partner.Account__c != null) {
				partnerIds.add( partner.Account__c );
			}
		}
		if ( ! (oraclePartyNumbers.isEmpty() && partnerIds.isEmpty() )) {
			Pattern resellerPattern = Opportunity_ManagePartners.getPartnerTypePattern('','Reseller 2');
			// create maps of partner statuses by oracle party number and partner Id
			Map<String, PartnerStatus__c> partnerStatusMap = new Map<String, PartnerStatus__c>();
			Map<Id, PartnerStatus__c> partnerStatusMap2 = new Map<Id, PartnerStatus__c>();
			for (PartnerStatus__c ps : [
				SELECT
					Partner__c,
					Partner__r.Name,
					Partner__r.OraclePartyNumber__c,
					PartnerType__r.Hierarchy__c,
					PartnerType__c,
					PartnerType__r.Name,
					PartnerTier__c,
					PartnerTier__r.Name
				FROM PartnerStatus__c
				WHERE ActivationStatus__c = 'Active'
					AND PartnerType__r.Hierarchy__c like 'Partner Type%'
					AND (Partner__c in :partnerIds
						OR Partner__r.OraclePartyNumber__c IN :oraclePartyNumbers) ] )
			{
				Boolean isResellerType = (ps.PartnerType__r.Name == Opportunity_Subscription.RESELLER_TYPE);
				if(isResellerType || (
					resellerPattern.matcher(ps.PartnerType__r.Hierarchy__c).matches()
						&& ! partnerStatusMap2.containsKey(ps.Partner__c) ) )
				{
					partnerStatusMap.put( ps.Partner__r.OraclePartyNumber__c, ps );
					partnerStatusMap2.put( ps.Partner__c, ps );
				}
			}

			// map reseller partner detials to the subscription partner
			for ( SubscriptionPartner__c partner : newList ) {
				SubscriptionPartner__c oldSubPartner = null;
				if(isUpdate) {
					oldSubPartner = oldMap.get(partner.Id);
				}
				if(mapResellerPartner(oldSubPartner, partner)) {
					PartnerStatus__c partnerStatus = partnerStatusMap2.get( partner.Account__c );
					if(partnerStatus == null) {
						partnerStatus = partnerStatusMap.get( partner.PartyNumber__c );
					}
					if(partnerStatus != null) {
						partner.Account__c = partnerStatus.Partner__c;
						partner.PartnerStatus__c = partnerStatus.Id;
					}
					else {
						partner.Account__c = null;
						partner.PartnerStatus__c = null;
					}
				}
			}
		}
	}

	/**
	 * This method is called from the SubscriptionPartner_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Subscription Partner objects as in Trigger.oldMap.
	 * @param xnewList the list of new Subscription Partner objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,SubscriptionPartner__c> xoldMap,List<SubscriptionPartner__c> xnewList) {
		final SubscriptionPartnerTriggerBefore beforeTrigger = new SubscriptionPartnerTriggerBefore(xoldMap,xnewList);
//depreciated		if(AbstractTrigger.isActive(ASSIGN_BATCH_SETTING,true)) {
//depreciated			beforeTrigger.assignBatch();
//depreciated		}
		if(AbstractTrigger.isActive(ASSIGN_COMPOSITE_KEY_SETTING,true)) {
			beforeTrigger.assignCompositeKey();
		}
		if(AbstractTrigger.isActive(MAP_RESELLER_PARTNER_SETTING,true)) {
			beforeTrigger.mapResellerPartner();
		}
		AbstractTrigger.processTriggerComplete();
	}
}