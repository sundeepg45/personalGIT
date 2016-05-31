/**
 * This class will replaces all before insert, update and delete OpportunityPartner__c triggers.
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
public without sharing class OpportunityPartnerTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable oppLock */
	public static final String OPP_LOCK_SETTING = 'OppPart_Before.oppLock';
	/** BooleanSetting__c key to enable maintaining the legacy Opportunity Partners */
	public static final String LEGACY_PARTNER_SETTING = 'OppPart_Before.legacyPartners';

	private final Map<Id,OpportunityPartner__c> oldMap = new Map<Id,OpportunityPartner__c>();
	private final List<OpportunityPartner__c> newList = new List<OpportunityPartner__c>();

	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewList normally assigned from Trigger.newList
	 */
	public OpportunityPartnerTriggerBefore(Map<Id,OpportunityPartner__c> xoldMap,List<OpportunityPartner__c> xnewList) {
		super(xoldMap,xnewList,null);
		if(oldSObjectMap != null) {
			oldMap.putAll((Map<Id,OpportunityPartner__c>)oldSObjectMap);
		}
		if(newSObjectList != null) {
			newList.addAll((List<OpportunityPartner__c>)newSObjectList);
		}
	}

	public Set<Id> oppLockIds {
		get {
			if(oppLockIds == null) {
				Set<Id> oppIds = new Set<Id>();
				for(OpportunityPartner__c oppPartner: oldMap.values()) {
					oppIds.add(oppPartner.Opportunity__c);
				}

				oppLockIds = new Set<Id>();
				for(Opportunity opp : [
					SELECT Id
					FROM Opportunity
					WHERE Id IN :oppIds
					AND IsLockedForSales__c = true ])
				{
					oppLockIds.add(opp.Id);
				}
			}
			return oppLockIds;
		}
		set;
	}

	/**
	 * Called for Opportunity Locking to prevent PRL deletes.
	 */
	public void oppLock() {
		if(isDelete) {
			AdminByPass__c bypass = AdminByPass__c.getInstance();
			if(bypass != null && bypass.IsSalesUser__c == true) {
				for(OpportunityPartner__c oppPartner: oldMap.values().clone()) {
					if(oppLockIds.contains(oppPartner.Opportunity__c)) {
						oppPartner.addError(System.Label.Opp_Lock_Message);
						hasErrors = true;
					}
				}
			}
		}
	}

	/**
	 * Called to maintain the legacy OpportunityPartner objects.
	 */
	public void maintainLegacyOpportunityPartners() {
		List<OpportunityPartner__c> needLegacy = new List<OpportunityPartner__c>();
		Set<Id> opportunityIds = new Set<Id>();
		Map<Id,OpportunityPartner__c> oldLegacyIdMap = new Map<Id,OpportunityPartner__c>();
		for(OpportunityPartner__c op : oldMap.values()) {
			opportunityIds.add(op.Opportunity__c);
			oldLegacyIdMap.put(op.Legacy_PartnerId__c,op);
		}
		oldLegacyIdMap.remove(null);
		Set<Id> newLegacyIds = new Set<Id>();
		for(OpportunityPartner__c op : newList) {
			if(op.Partner__c == null) {
				op.addError('Partner is required.');
				hasErrors = true;
				continue;
			}
			opportunityIds.add(op.Opportunity__c);
			if(isUpdate) {
				OpportunityPartner__c o = oldMap.get(op.Id);
				if(op.Legacy_PartnerId__c == o.Legacy_PartnerId__c) {
					if(op.Partner__c != o.Partner__c || op.PartnerType__c != o.PartnerType__c || op.PartnerTier__c != o.PartnerTier__c) {
						op.Legacy_PartnerId__c = null;
					}
				}
			}
			String id = null;
			newLegacyIds.add((id=op.Legacy_PartnerId__c));
			if(id == null && op.RelationshipType__c != null) {
				needLegacy.add(op);
			}
		}
		if(! hasErrors) {
			oldLegacyIdMap.keySet().removeAll(newLegacyIds);
			opportunityIds.remove(null);
			List<Partner> partners = new List<Partner>();
			List<OpportunityPartner__c> ops = new List<OpportunityPartner__c>();
			// find and clean-up orphaned legacy opportunity partner records.
			List<Id> partnerIdsToRemove = new List<Id>(oldLegacyIdMap.keySet());
			if(isInsert && ! opportunityIds.isEmpty()) {
				// It seems that adding one partner record automatically adds a reverse partner record.
				// Removing the reverse partner, also removes the partner record we added.   So there 
				// is no way to simply remove any partners we did not add.
				// Instead we simply look for opportunity Id's for which we have not added any partners.
				System.debug('Opportunity Ids to scan = '+opportunityIds);
				for(AggregateResult ar : [select Opportunity__c from OpportunityPartner__c where Opportunity__c in : opportunityIds and Legacy_PartnerId__c != null Group By Opportunity__c Having Count(Id) > 0 ])
				{
				// We have added one or more partners to this opportunity, so remove it from the list.
					opportunityIds.remove((Id)ar.get('Opportunity__c'));
				}
				System.debug('Opportunity Ids to clean = '+opportunityIds);
				// add any Partners associated to these opportunities to our remove list.
				partnerIdsToRemove.addAll(new Map<Id,Partner>([select Id from Partner where OpportunityId in :opportunityIds]).keySet());
			}
			// clean-up old partner records
			System.debug('Partners to remove='+partnerIdsToRemove);
			if(! partnerIdsToRemove.isEmpty()) {
				for(Database.DeleteResult r : database.delete(partnerIdsToRemove,false)) {
					Id legacyId = partnerIdsToRemove.remove(0);
					OpportunityPartner__c op = oldLegacyIdMap.get(legacyId);
					for(Database.Error e : r.getErrors()) {
						String m = e.getMessage();
						System.debug('legacyId='+legacyId+',error='+m);
						if(op != null) {
							if(! m.contains('invalid cross reference')) {
								op.addError(e.getMessage());
								hasErrors = true;
							}
						}
					}
				}
			}
			// to do: add new legacy opportunity partner objects
			if(! needLegacy.isEmpty()) {
				Map<String,String> partnerRoleNameMap = new Map<String,String>{
					'Distributor'=>'Distributor',
					'Global Chip'=>'Chip',
					'ISP.Training'=>'Training',
					'ISP'=>'Other',
					'ISV'=>'ISV',
					'OEM'=>'OEM',
					'Reseller:Advanced'=>'Advanced Partner',
					'Reseller.'=>'Value Added Reseller',
					'Reseller'=>'Other',
					'SI'=>'System Integrator'};
				for(OpportunityPartner__c op : needLegacy)
				{
					String roleName = 'Distributor';
					if(! 'Financial'.equalsIgnoreCase(op.RelationshipType__c))
					{
						String subTypeName = op.PartnerSubTypeName__c;
						if(subTypeName == null)
						{
							subTypeName = '';
						}
						roleName = partnerRoleNameMap.get(op.PartnerTypeName__c+'.'+subTypeName+':'+op.PartnerTierName__c);
						if(roleName == null)
						{
							roleName = partnerRoleNameMap.get(op.PartnerTypeName__c+':'+op.PartnerTierName__c);
							if(roleName == null)
							{
								roleName = partnerRoleNameMap.get(op.PartnerTypeName__c+'.'+subTypeName);
								if(roleName == null)
								{
									roleName = partnerRoleNameMap.get(op.PartnerTypeName__c);
									if(roleName == null)
									{
										roleName = 'Other';
									}
								}
							}
						}
					}
					if(roleName != null)
					{
						ops.add(op);
						partners.add(new Partner(OpportunityId=op.Opportunity__c,AccountToId=op.Partner__c,Role=roleName));
					}
				}
				if(! partners.isEmpty())
				{
					for(Database.SaveResult r : database.insert(partners,false))
					{
						Partner p = partners.remove(0);
						OpportunityPartner__c op = ops.remove(0);
						op.Legacy_PartnerId__c = p.Id;
						if(! 'Financial'.equalsIgnoreCase(op.RelationshipType__c))
						{
							for(Database.Error e : r.getErrors())
							{
								String message = e.getMessage();
								if(! message.startsWith('field integrity exception:'))
								{
									op.addError(e.getMessage());
									hasErrors = true;
								}
							}
						}
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
	public static void processTrigger(Map<Id,OpportunityPartner__c> xoldMap,List<OpportunityPartner__c> xnewList) {
		final OpportunityPartnerTriggerBefore beforeTrigger = new OpportunityPartnerTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(OPP_LOCK_SETTING,true)) {
			beforeTrigger.oppLock();
		}
		if(AbstractTrigger.isActive(LEGACY_PARTNER_SETTING,true)) {
			beforeTrigger.maintainLegacyOpportunityPartners();
		}
		AbstractTrigger.processTriggerComplete();
	}

}