/**
 * This class will replaces all after insert, update, and delete OpportunityPartner__c triggers.
 * The processTrigger method is invoked by the OpportunityPartner_Before trigger and 
 * in turn invokes all the processTrigger methods of the subclasses.  This gives us 
 * a way to control the order in which the code logic is invoked, as well as allowing 
 * other class features such as shared data, constant values, and complete test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class or it's subclasses
 * as that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2014-08-12
 * 2014-08-12 - refactored with new top level class and added new defere logic for bulk operations.
 * 
 */
public without sharing class OpportunityPartnerTriggerAfter  extends AbstractTrigger {
	/** String used in the Thread lock class to avoid recursion. */
	public static final String lockString = 'OpportunityPartnerTriggerAfter.Lock';
	/** BooleanSetting__c key to enable updating opportunities. */
	public static final String UPDATE_OPPS_SETTING = 'OppPart_Before.updateOpps';

	private final Map<Id,OpportunityPartner__c> oldMap = new Map<Id,OpportunityPartner__c>();
	private final Map<Id,OpportunityPartner__c> newMap = new Map<Id,OpportunityPartner__c>();

	/**
	 * Typical TriggerAfter type constructor
	 *
	 * @param xoldMap the mapping of old values
	 * @param xnewMap the mapping of new values
	 */
	public OpportunityPartnerTriggerAfter(Map<Id,OpportunityPartner__c> xoldMap,Map<Id,OpportunityPartner__c> xnewMap) {
		super(xoldMap,null,xnewMap);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	private void addErrorMessage(OpportunityPartner__c op, String message) {
		if(op != null) {
			op.addError(message);
			hasErrors = true;
		}
	}

	public Map<Id,OpportunityPartner__c> getPartnerMap(Map<Id,OpportunityPartner__c> relevantMap,String relationshipType) {
		Map<Id,OpportunityPartner__c> partnerMap = new Map<Id,OpportunityPartner__c>();
		for(OpportunityPartner__c op : relevantMap.values()) {
			if(op.RelationshipType__c == relationshipType) {
				if((! isDelete) && partnerMap.containsKey(op.Opportunity__c)) {
					addErrorMessage(op,'Duplicate '+relationshipType+' Partner');
					continue;
				}
				partnerMap.put(op.Opportunity__c,op);
			}
		}
		return partnerMap;
	}

	// trigger OpportunityPartnerUpdateOpportunities on OpportunityPartner__c (after insert, after update, after delete)
	public void updateOpportunities() {
		final Map<Id,OpportunityPartner__c> relevantMap = isDelete?oldMap:newMap;
		final Map<Id,OpportunityPartner__c> financialPartnerMap = getPartnerMap(relevantMap,'Financial');
		final Map<Id,OpportunityPartner__c> resellerPartnerMap = getPartnermap(relevantMap,'Reseller 2');
		final Set<Id> opportunityIds = financialPartnerMap.keySet().clone();
		opportunityIds.addAll(resellerPartnerMap.keySet());
		if(! opportunityIds.isEmpty()) {
			// Lets take care of book-keeping first.
			// Find existing partners
			final List<OpportunityPartner__c> existingOpportunityPartners = [
				select RelationshipType__c, Opportunity__c
				from OpportunityPartner__c
				where Opportunity__c in : opportunityIds
					and ((RelationshipType__c = 'Financial' and Opportunity__c in :financialPartnerMap.keySet())
						or (RelationshipType__c = 'Reseller 2' and Opportunity__c in :resellerPartnerMap.keySet()))
					and (not Id in :relevantMap.keySet()) ];
			if(isDelete) {
				// we can ignore deletes of partners that have duplicates
				System.debug('Ignoring the delete of '+existingOpportunityPartners);
				for(OpportunityPartner__c op : existingOpportunityPartners) {
					if(op.RelationshipType__c == 'Financial') {
						financialPartnerMap.remove(op.Opportunity__c);
					}
					else // if (op.RelationshipType__c == 'Reseller 2')
					{
						resellerPartnerMap.remove(op.Opportunity__c);
					}
				}
			}
			else
			{
				System.debug('Deleting '+existingOpportunityPartners);
				// if this is an insert or update we need to remove pre-existing partners first
				for(Database.DeleteResult r : Database.delete(existingOpportunityPartners,false)) {
					OpportunityPartner__c op = existingOpportunityPartners.remove(0);
					for(Database.Error e : r.getErrors() )
					{
						if(op.RelationshipType__c == 'Financial')
						{
							addErrorMessage(financialPartnerMap.remove(op.Opportunity__c),'Failed to remove existing financial partner: '+e.getMessage());
						}
						else // if (op.RelationshipType__c == 'Reseller 2')
						{
							addErrorMessage(resellerPartnerMap.remove(op.Opportunity__c),'Failed to remove existing reseller 2 partner: '+e.getMessage());
						}
					}
				}
			}
			final Map<Id,Opportunity> updateOpportunityMap = new Map<Id,Opportunity>();
			final Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([
				select Id,
					Name,
					FinancialPartner__c,
					Primary_Partner__c,
					ResellerPartner__c,
					Reseller__c
				from Opportunity where Id in :opportunityIds ]);
			if(! resellerPartnerMap.isEmpty()) {
				for(OpportunityPartner__c opportunityPartner : resellerPartnerMap.values()) {
					final Opportunity opp = opportunityMap.get(opportunityPartner.Opportunity__c);
					System.debug('Update opportunityPartner.Id='+opportunityPartner.Id+',Opportunity.Id='+opportunityPartner.Opportunity__c+'Opportunity.Name='+((opp!=null)?opp.Name:'null'));
					if(opp != null) {
						String partnerName = null;
						Id partnerId = null;
						Boolean changed = (opp.ResellerPartner__c == opportunityPartner.Partner__c)||(opp.Reseller__c == opportunityPartner.PartnerName__c);
						if(! isDelete) {
							partnerId = opportunityPartner.Partner__c;
							partnerName = opportunityPartner.PartnerName__c;
							changed = ((opp.ResellerPartner__c != partnerId)||(opp.Reseller__c != partnerName));
						}
						if(changed) {
							opp.ResellerPartner__c = partnerId;
							opp.Reseller__c = partnerName;
							updateOpportunityMap.put(opp.Id,opp);
						}
					}
				}
			}
			if(! financialPartnerMap.isEmpty()) {
				for(OpportunityPartner__c opportunityPartner : financialPartnerMap.values()) {
					final Opportunity opp = opportunityMap.get(opportunityPartner.Opportunity__c);
					if(opp != null) {
						String partnerName = null;
						Id partnerId = null;
						Boolean changed = (opp.FinancialPartner__c == opportunityPartner.Partner__c)||(opp.Primary_Partner__c == opportunityPartner.PartnerName__c);
						if( ! isDelete ) {
							partnerName = opportunityPartner.PartnerName__c;
							partnerId = opportunityPartner.Partner__c;
							changed = (opp.FinancialPartner__c != partnerId)||(opp.Primary_Partner__c != partnerName );
						}
						if(changed) {
							opp.FinancialPartner__c = partnerId;
							opp.Primary_Partner__c = partnerName;
							updateOpportunityMap.put(opp.Id,opp);
						}
					}
				}
			}
			if(! updateOpportunityMap.isEmpty()) {
				List<Opportunity> updateList = updateOpportunityMap.values().clone();
				for(Database.SaveResult r : Database.update(updateList,false)) {
					Opportunity o = updateList.remove(0);
					for(Database.Error e : r.getErrors()) {
						addErrorMessage(financialPartnerMap.get(o.Id),'Failed to update Opportunity: '+ e.getMessage());
						addErrorMessage(resellerPartnerMap.get(o.Id),'Failed to update Opportunity: '+ e.getMessage());
					}
				}
			}
		}
	}

	/**
	 * This method is called to invoke all the trigger methods.
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewMap normally assigned from Trigger.newMap
	 */
	public static void processTrigger(Map<Id,OpportunityPartner__c> xoldMap,Map<Id,OpportunityPartner__c> xnewMap) {
		if(ThreadLock.lock(lockString)) {
			final OpportunityPartnerTriggerAfter afterTrigger = new OpportunityPartnerTriggerAfter(xoldMap,xnewMap);
			try {
				if(AbstractTrigger.isActive(UPDATE_OPPS_SETTING,true)) {
					afterTrigger.updateOpportunities();
				}
				AbstractTrigger.processTriggerComplete();
			}
			finally {
				ThreadLock.unlock(lockString);
			}
		}
	}
}