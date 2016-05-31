/**
 * This class replaces all after insert and after update SubscriptionPartner__c triggers.  The
 * processTrigger method is invoked by the SubscriptionPartner_Before trigger and in turn invokes
 * all the processTrigger methods of the subclasses.  This gives us a way to control 
 * the order in which the code logic is invoked, as well as allowing other class features 
 * such as shared data, constant values, and complete test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class or it's subclasses
 * as that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2014-12-12
 * @author Bill C Riemers <briemers@redhat.com>
 * 2014-12-12 - Updated to use a composite key for subscription partners
 * 2013-09-12 - Created
 */
public without sharing class SubscriptionPartnerTriggerAfter extends AbstractTrigger{
	/** BooleanSetting__c key to enable the updateSubscriptionPartnerRelations trigger method. */
	public static final String UPDATE_SUBSCRIPTION_PARTNER_RELATIONSHIP_SETTING = 'SubPart_After.updateSubPartRel';

	/** Normally populated as a copy of Trigger.oldMap */
	public final Map<Id,SubscriptionPartner__c> oldMap = new Map<Id,SubscriptionPartner__c>();
	/** Normally populated as Trigger.new */
	public final Map<Id,SubscriptionPartner__c> newMap = new Map<Id,SubscriptionPartner__c>();

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	public SubscriptionPartnerTriggerAfter(Map<Id,SubscriptionPartner__c> xoldMap,Map<Id,SubscriptionPartner__c> xnewMap) {
		super(xoldMap,null,xnewMap);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	/**
	 * Scan through all the related records and create missing SubscriptionPartnerRelationship__c objects.
	 */
	public void updateSubscriptionPartnerRelationship() {
		Set<Decimal> orderIds = new Set<Decimal>();
		Map<Long,List<SubscriptionPartner__c>> subPartnersMap = new Map<Long,List<SubscriptionPartner__c>>();
		for(SubscriptionPartner__c subPartner : newMap.values()) {
			if(subPartner.OrderId__c != null && subPartner.CompositeKey__c != null) {
				SubscriptionPartner__c oldSubPartner = oldMap.get(subPartner.Id);
				if(oldSubPartner == null || oldSubPartner.OrderId__c != subPartner.OrderId__c || oldSubPartner.CompositeKey__c != subPartner.CompositeKey__c) {
					List<SubscriptionPartner__c> subPartners = subPartnersMap.get(subPartner.OrderId__c.longValue());
					if(subPartners == null) {
						subPartners = new List<SubscriptionPartner__c>();
						orderIds.add(subPartner.OrderId__c);
						subPartnersMap.put(subPartner.OrderId__c.longValue(),subPartners);
					}
					subPartners.add(subPartner);
				}
			}
		}
		if(! subPartnersMap.isEmpty()) {
			Map<String,SubscriptionPartnerRelationship__c> subPartRelMap = new Map<String,SubscriptionPartnerRelationship__c>();
			for(Subscription__c sub : [
				select
					OrderId__c,
					ContractId__c,
					CompositeKey__c
				from Subscription__c
				where OrderId__c in :orderIds
					and CompositeKey__c != null ])
			{
				for(SubscriptionPartner__c subPartner : subPartnersMap.get(sub.OrderId__c.longValue())) {
					String partnerCompositeKey = '';
					if(subPartner.CompositeKey__c != null) {
						partnerCompositeKey = subPartner.CompositeKey__c;
					}
					String compositeKey = sub.CompositeKey__c+':'+partnerCompositeKey;
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
			if(! subPartRelMap.isEmpty()) {
				for(SubscriptionPartnerRelationship__c subPartRel : [
					select CompositeKey__c
					from SubscriptionPartnerRelationship__c
					where CompositeKey__c in : subPartRelMap.keySet() ])
				{
					subPartRelMap.remove(subPartRel.CompositeKey__c);
				}
				for(Database.SaveResult sr : Database.insert(subPartRelMap.values(),false) ) {
					if(!sr.isSuccess()) {
						System.debug('PartRelInsert Errors: '+sr.getErrors());
					}
				}
			}
		}
	}

	/**
	 * Method to invoke all triggers
	 */
	public static void processTrigger(Map<Id,SubscriptionPartner__c> xoldMap,Map<Id,SubscriptionPartner__c> xnewMap) {
		final SubscriptionPartnerTriggerAfter afterTrigger = new SubscriptionPartnerTriggerAfter(xoldMap,xnewMap);
		if(AbstractTrigger.isActive(UPDATE_SUBSCRIPTION_PARTNER_RELATIONSHIP_SETTING,true)) {
			afterTrigger.updateSubscriptionPartnerRelationship();
		}
		AbstractTrigger.processTriggerComplete();
	}
}