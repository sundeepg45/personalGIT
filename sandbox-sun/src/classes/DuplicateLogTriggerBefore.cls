/**
 * This class replaces all before insert and before update address triggers.  The
 * processTrigger method is invoked by the DuplicateLog_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2015-09-04
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-09-04 - Changed activities on ebs accounts and addresses to be out-of-scope
 * 2015-09-02 - Created
 */
public without sharing class DuplicateLogTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable inactivateDuplicates method. */
	public static final String TOGGLE_MIGRATED_SETTING = 'DupLog_Before.toggleMigrated';

	private final Map<Id,DuplicateLog__c> oldMap = new Map<Id,DuplicateLog__c>();
	private final List<DuplicateLog__c> newList = new List<DuplicateLog__c>();

	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap the mapping of old values
	 * @param xnewList the mapping of new values
	 */
	public DuplicateLogTriggerBefore(Map<Id,DuplicateLog__c> xoldMap,List<DuplicateLog__c> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	private static void addToDuplicateLogMap(Map<Id,DuplicateLog__c> duplicateLogMap,String key,DuplicateLog__c value) {
		if(key != null && key.length() >= 15) {
			try {
				duplicateLogMap.put((Id)key,value);
			}
			catch(Exception ex) {}
		}
	}

	private static Integer failedMigrations(DuplicateLog__c dlog) {
		Integer retval = 1;
		try {
			retval = dlog.FailedMigrations__c.intValue();
		}
		catch(Exception ex) {}
		return retval;
	}

	private static Integer successfulMigrations(DuplicateLog__c dlog) {
		Integer retval = 0;
		try {
			retval = dlog.SuccessfulMigrations__c.intValue();
		}
		catch(Exception ex) {}
		return retval;
	}

	@TestVisible
	private Set<Id> duplicateLogIdsWithFailures {
		get {
			if(duplicateLogIdsWithFailures == null) {
				duplicateLogIdsWithFailures = new Set<Id>();
				if(isUpdate) {
					for(DuplicateLog__c dlog : newList) {
						if(failedMigrations(dlog) > 0) {
							duplicateLogIdsWithFailures.add(dlog.Id);
						}
					}
				}
			}
			return duplicateLogIdsWIthFailures;
		}
		set;
	}

	@TestVisible
	private Set<Id> ignoreRecordIds {
		get {
			if(ignoreRecordIds == null) {
				ignoreRecordIds = new Set<Id>();
				if(! duplicateLogIdsWithFailures.isEmpty()) {
					for(AggregateResult ar : [
						select RecordId__c
						from DuplicateMigrationLog__c
						where DuplicateLog__c in :duplicateLogIdsWithFailures
							and Status__c = 'Failure'
						Group By RecordId__c ])
					{
						try {
							ignoreRecordIds.add((Id)String.valueOf(ar.get('RecordId__c')));
						}
						catch(Exception ex) {}
					}
				}
			}
			return ignoreRecordIds;
		}
		set;
	}

	/**
	 * Assign the migrated fields appropriately.
	 */
	public void toggleMigrated() {
		Map<Id,DuplicateLog__c> duplicateLogAddressMap = new Map<Id,DuplicateLog__c>();
		Map<Id,DuplicateLog__c> duplicateLogAddressMap2 = new Map<Id,DuplicateLog__c>();
		Map<Id,DuplicateLog__c> duplicateLogEBSAccountMap = new Map<Id,DuplicateLog__c>();
		Map<Id,DuplicateLog__c> duplicateLogEBSAccountMap2 = new Map<Id,DuplicateLog__c>();
		Map<Id,DuplicateLog__c> duplicateLogContactMap = new Map<Id,DuplicateLog__c>();
		Map<Id,DuplicateLog__c> duplicateLogContactMap2 = new Map<Id,DuplicateLog__c>();
		final String addressKeyPrefix = Address__c.SObjectType.getDescribe().getKeyPrefix();
		final String contactKeyPrefix = Contact.SObjectType.getDescribe().getKeyPrefix();
		final String ebsAccountKeyPrefix = EBS_Account__c.SObjectType.getDescribe().getKeyPrefix();
		for(DuplicateLog__c dlog : newList) {
			DuplicateLog__c dlogOld = oldMap.get(dlog.Id);
			Id masterRecordIdOld = null;
			if(dlogOld != null) {
				masterRecordIdOld = dlogOld.MasterRecordId__c;
			}
			Boolean masterRecordIdChanged = (masterRecordIdOld != dlog.MasterRecordId__c);
			String objectType = dlog.ObjectType__c;
			if(masterRecordIdChanged || objectType == null) {
				Id masterRecordId = (Id)dlog.MasterRecordId__c;
				Id addressId = null;
				Id contactId = null;
				Id ebsAccountId = null;
				if(String.valueOf(masterRecordId).startsWith(addressKeyPrefix)) {
					objectType = 'Address';
					addressId = masterRecordId;
				}
				else if(String.valueOf(masterRecordId).startsWith(contactKeyPrefix)) {
					objectType = 'Contact';
					contactId = masterRecordId;
				}
				else if(String.valueOf(masterRecordId).startsWith(ebsAccountKeyPrefix)) {
					objectType = 'EBS Account';
					ebsAccountId = masterRecordId;
				}
				if(dlog.MasterAddress__c != addressId) {
					dlog.MasterAddress__c = addressId;
				}
				if(dlog.MasterContact__c != contactId) {
					dlog.MasterContact__c = contactId;
				}
				if(dlog.MasterEBSAccount__c != ebsAccountId) {
					dlog.MasterEBSAccount__c = ebsAccountId;
				}
				if(dlog.ObjectType__c != objectType) {
					dlog.ObjectType__c = objectType;
				}
			}
			if(masterRecordIdChanged
				|| dlog.Opportunities_Migrated__c != true
				|| dlog.Products_Migrated__c != true 
				|| dlog.Staging_Headers_Migrated__c != true
				|| dlog.Staging_Lines_Migrated__c != true
				|| dlog.OM_Profiles_Migrated__c != true
				|| (dlog.ObjectType__c != 'Contact' && dlog.Subscriptions_Migrated__c != true)
				|| (dlog.ObjectType__c != 'Contact' && dlog.Subscription_Lines_Migrated__c != true) )
			{
				if(dlog.ObjectType__c == 'EBS Account') {
					addToDuplicateLogMap(duplicateLogEBSAccountMap,dlog.DuplicateRecordId__c,dlog);
				}
				else if(dlog.ObjectType__c == 'Address') {
					addToDuplicateLogMap(duplicateLogAddressMap,dlog.DuplicateRecordId__c,dlog);
				}
				else if(dlog.ObjectType__c == 'Contact') {
					addToDuplicateLogMap(duplicateLogContactMap,dlog.DuplicateRecordId__c,dlog);
				}
			}
			if(masterRecordIdChanged
				|| (dlog.ObjectType__c == 'Contact' && dlog.Subscriptions_Migrated__c != true)
				|| (dlog.ObjectType__c == 'Contact' && dlog.Subscription_Lines_Migrated__c != true)
				|| dlog.OppContactRoles_Migrated__c != true
				|| dlog.PartnerPrograms_Migrated__c != true
				|| dlog.OpportunityPartners_Migrated__c != true
				|| dlog.Activities_Migrated__c != true )
			{
				if(dlog.ObjectType__c == 'EBS Account') {
					addToDuplicateLogMap(duplicateLogEBSAccountMap2,dlog.DuplicateRecordId__c,dlog);
				}
				else if(dlog.ObjectType__c == 'Address') {
					addToDuplicateLogMap(duplicateLogAddressMap2,dlog.DuplicateRecordId__c,dlog);
				}
				else if(dlog.ObjectType__c == 'Contact') {
					addToDuplicateLogMap(duplicateLogContactMap2,dlog.DuplicateRecordId__c,dlog);
				}
			}
		}
		if(! duplicateLogAddressMap.isEmpty()) {
			// there is a 20 child query limit...
			Map<Id,Address__c> addressMap = new Map<Id,Address__c>( [
				select Id,
					(select Id from OpportunitiesBillToAdd__r where Id not in :ignoreRecordIds limit 1),
					(select Id from OpportunitiesEntitleToAdd__r where Id not in :ignoreRecordIds limit 1),
					(select Id from OpportunitiesShipToAdd__r where Id not in :ignoreRecordIds limit 1),
					(select Id from OpportunitiesSoldToAdd__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Header_Staging1__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Header_Staging2__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Header_Staging3__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Header_Staging__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Line_Staging__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunity_Product__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Order_Management_Profiles1__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Order_Management_Profiles2__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Order_Management_Profiles3__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Order_Management_Profiles__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionLinesEntitleTo__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsBillTo__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsEntitleTo__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsShipTo__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsSoldTo__r where Id not in :ignoreRecordIds limit 1)
				from Address__c
				where Id in :duplicateLogAddressMap.keySet() ] );
			for(DuplicateLog__c dlog : duplicateLogAddressMap.values()) {
				Address__c a = addressMap.get((Id)dlog.DuplicateRecordId__c);
				Boolean opportunitiesMigrated = (a == null ||
					(	(a.OpportunitiesBillToAdd__r == null || a.OpportunitiesBillToAdd__r.isEmpty())
						&& (a.OpportunitiesEntitleToAdd__r == null || a.OpportunitiesEntitleToAdd__r.isEmpty())
						&& (a.OpportunitiesShipToAdd__r == null || a.OpportunitiesShipToAdd__r.isEmpty())
						&& (a.OpportunitiesSoldToAdd__r == null || a.OpportunitiesSoldToAdd__r.isEmpty()) ) );
				if(opportunitiesMigrated != dlog.Opportunities_Migrated__c) {
					dlog.Opportunities_Migrated__c = opportunitiesMigrated;
				}

				Boolean productsMigrated = (a == null ||
					(a.Opportunity_Product__r == null || a.Opportunity_Product__r.isEmpty()) );
				if(productsMigrated != dlog.Products_Migrated__c) {
					dlog.Products_Migrated__c = productsMigrated;
				}

				Boolean stagingHeadersMigrated = (a == null ||
					(	(a.Opportunities_Header_Staging__r == null || a.Opportunities_Header_Staging__r.isEmpty())
						&& (a.Opportunities_Header_Staging1__r == null || a.Opportunities_Header_Staging1__r.isEmpty())
						&& (a.Opportunities_Header_Staging2__r == null || a.Opportunities_Header_Staging2__r.isEmpty())
						&& (a.Opportunities_Header_Staging3__r == null || a.Opportunities_Header_Staging3__r.isEmpty()) ) );
				if(stagingHeadersMigrated != dlog.Staging_Headers_Migrated__c) {
					dlog.Staging_Headers_Migrated__c = stagingHeadersMigrated;
				}

				Boolean stagingLinesMigrated = (a == null ||
					(a.Opportunities_Line_Staging__r == null || a.Opportunities_Line_Staging__r.isEmpty()) );
				if(stagingLinesMigrated != dlog.Staging_Lines_Migrated__c) {
					dlog.Staging_Lines_Migrated__c = stagingLinesMigrated;
				}

				Boolean omProfilesMigrated = (a == null ||
					(	(a.Order_Management_Profiles__r == null || a.Order_Management_Profiles__r.isEmpty())
						&& (a.Order_Management_Profiles1__r == null || a.Order_Management_Profiles1__r.isEmpty())
						&& (a.Order_Management_Profiles2__r == null || a.Order_Management_Profiles2__r.isEmpty())
						&& (a.Order_Management_Profiles3__r == null || a.Order_Management_Profiles3__r.isEmpty()) ) );
				if(omProfilesMigrated != dlog.OM_Profiles_Migrated__c) {
					dlog.OM_Profiles_Migrated__c = omProfilesMigrated;
				}

				Boolean subscriptionsMigrated = (a == null ||
					(	(a.SubscriptionsBillTo__r == null || a.SubscriptionsBillTo__r.isEmpty())
						&& (a.SubscriptionsEntitleTo__r == null || a.SubscriptionsEntitleTo__r.isEmpty())
						&& (a.SubscriptionsShipTo__r == null || a.SubscriptionsShipTo__r.isEmpty())
						&& (a.SubscriptionsSoldTo__r == null || a.SubscriptionsSoldTo__r.isEmpty()) ) );
				if(subscriptionsMigrated != dlog.Subscriptions_Migrated__c) {
					dlog.Subscriptions_Migrated__c = subscriptionsMigrated;
				}

				Boolean subscriptionLinesMigrated = (a == null ||
					(a.SubscriptionLinesEntitleTo__r == null || a.SubscriptionLinesEntitleTo__r.isEmpty()) );
				if(subscriptionLinesMigrated != dlog.Subscription_Lines_Migrated__c) {
					dlog.Subscription_Lines_Migrated__c = subscriptionLinesMigrated;
				}
			}
		}
		if(! duplicateLogAddressMap2.isEmpty()) {
			for(DuplicateLog__c dlog : duplicateLogAddressMap2.values()) {
				Boolean activitiesMigrated = true; //out-of-scope
				if(activitiesMigrated != dlog.Activities_Migrated__c) {
					dlog.Activities_Migrated__c = activitiesMigrated;
				}

				Boolean oppContactRolesMigrated = true;
				if(oppContactRolesMigrated != dlog.OppContactRoles_Migrated__c) {
					dlog.OppContactRoles_Migrated__c = oppContactRolesMigrated;
				}

				Boolean oppPartnersMigrated = true;
				if(oppPartnersMigrated != dlog.OpportunityPartners_Migrated__c) {
					dlog.OpportunityPartners_Migrated__c = oppPartnersMigrated;
				}

				Boolean partnerProgramsMigrated = true;
				if(partnerProgramsMigrated != dlog.PartnerPrograms_Migrated__c) {
					dlog.PartnerPrograms_Migrated__c = partnerProgramsMigrated;
				}
			}
		}
		if(! duplicateLogEBSAccountMap.isEmpty()) {
			// there is a 20 child query limit...
			Map<Id,EBS_Account__c> ebsAccountMap = new Map<Id,EBS_Account__c>( [
				select Id,
					(select Id from OpportunitiesBillToAcc__r where Id not in :ignoreRecordIds limit 1),
					(select Id from OpportunitiesEntitleToAcc__r where Id not in :ignoreRecordIds limit 1),
					(select Id from OpportunitiesShipToAcc__r where Id not in :ignoreRecordIds limit 1),
					(select Id from OpportunitiesSoldToAcc__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Header_Staging1__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Header_Staging2__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Header_Staging3__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Header_Staging__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Line_Staging__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunity_Product__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Order_Management_Profiles1__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Order_Management_Profiles2__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Order_Management_Profiles3__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Order_Management_Profiles__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionLinesEntitleTo__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsBillTo__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsEntitleTo__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsShipTo__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsSoldTo__r where Id not in :ignoreRecordIds limit 1)
				from EBS_Account__c
				where Id in :duplicateLogEBSAccountMap.keySet() ] );
			for(DuplicateLog__c dlog : duplicateLogEBSAccountMap.values()) {
				EBS_Account__c a = ebsAccountMap.get((Id)dlog.DuplicateRecordId__c);

				Boolean opportunitiesMigrated = (a == null ||
					(	(a.OpportunitiesBillToAcc__r == null || a.OpportunitiesBillToAcc__r.isEmpty())
						&& (a.OpportunitiesEntitleToAcc__r == null || a.OpportunitiesEntitleToAcc__r.isEmpty())
						&& (a.OpportunitiesShipToAcc__r == null || a.OpportunitiesShipToAcc__r.isEmpty())
						&& (a.OpportunitiesSoldToAcc__r == null || a.OpportunitiesSoldToAcc__r.isEmpty()) ) );
				if(opportunitiesMigrated != dlog.Opportunities_Migrated__c) {
					dlog.Opportunities_Migrated__c = opportunitiesMigrated;
				}

				Boolean productsMigrated = (a == null ||
					(a.Opportunity_Product__r == null || a.Opportunity_Product__r.isEmpty()) );
				if(productsMigrated != dlog.Products_Migrated__c) {
					dlog.Products_Migrated__c = productsMigrated;
				}

				Boolean stagingHeadersMigrated = (a == null ||
					(	(a.Opportunities_Header_Staging__r == null || a.Opportunities_Header_Staging__r.isEmpty())
						&& (a.Opportunities_Header_Staging1__r == null || a.Opportunities_Header_Staging1__r.isEmpty())
						&& (a.Opportunities_Header_Staging2__r == null || a.Opportunities_Header_Staging2__r.isEmpty())
						&& (a.Opportunities_Header_Staging3__r == null || a.Opportunities_Header_Staging3__r.isEmpty()) ) );
				if(stagingHeadersMigrated != dlog.Staging_Headers_Migrated__c) {
					dlog.Staging_Headers_Migrated__c = stagingHeadersMigrated;
				}

				Boolean stagingLinesMigrated = (a == null ||
					(a.Opportunities_Line_Staging__r == null || a.Opportunities_Line_Staging__r.isEmpty()) );
				if(stagingLinesMigrated != dlog.Staging_Lines_Migrated__c) {
					dlog.Staging_Lines_Migrated__c = stagingLinesMigrated;
				}

				Boolean omProfilesMigrated = (a == null ||
					(	(a.Order_Management_Profiles__r == null || a.Order_Management_Profiles__r.isEmpty())
						&& (a.Order_Management_Profiles1__r == null || a.Order_Management_Profiles1__r.isEmpty())
						&& (a.Order_Management_Profiles2__r == null || a.Order_Management_Profiles2__r.isEmpty())
						&& (a.Order_Management_Profiles3__r == null || a.Order_Management_Profiles3__r.isEmpty()) ) );
				if(omProfilesMigrated != dlog.OM_Profiles_Migrated__c) {
					dlog.OM_Profiles_Migrated__c = omProfilesMigrated;
				}

				Boolean subscriptionsMigrated = (a == null ||
					(	(a.SubscriptionsBillTo__r == null || a.SubscriptionsBillTo__r.isEmpty())
						&& (a.SubscriptionsEntitleTo__r == null || a.SubscriptionsEntitleTo__r.isEmpty())
						&& (a.SubscriptionsShipTo__r == null || a.SubscriptionsShipTo__r.isEmpty())
						&& (a.SubscriptionsSoldTo__r == null || a.SubscriptionsSoldTo__r.isEmpty()) ) );
				if(subscriptionsMigrated != dlog.Subscriptions_Migrated__c) {
					dlog.Subscriptions_Migrated__c = subscriptionsMigrated;
				}

				Boolean subscriptionLinesMigrated = (a == null ||
					(a.SubscriptionLinesEntitleTo__r == null || a.SubscriptionLinesEntitleTo__r.isEmpty()) );
				if(subscriptionLinesMigrated != dlog.Subscription_Lines_Migrated__c) {
					dlog.Subscription_Lines_Migrated__c = subscriptionLinesMigrated;
				}
			}
		}
		if(! duplicateLogEBSAccountMap2.isEmpty()) {
			for(DuplicateLog__c dlog : duplicateLogEBSAccountMap2.values()) {
				Boolean activitiesMigrated = true;
				if(activitiesMigrated != dlog.Activities_Migrated__c) {
					dlog.Activities_Migrated__c = activitiesMigrated;
				}

				Boolean oppContactRolesMigrated = true;
				if(oppContactRolesMigrated != dlog.OppContactRoles_Migrated__c) {
					dlog.OppContactRoles_Migrated__c = oppContactRolesMigrated;
				}

				Boolean oppPartnersMigrated = true;
				if(oppPartnersMigrated != dlog.OpportunityPartners_Migrated__c) {
					dlog.OpportunityPartners_Migrated__c = oppPartnersMigrated;
				}

				Boolean partnerProgramsMigrated = true;
				if(partnerProgramsMigrated != dlog.PartnerPrograms_Migrated__c) {
					dlog.PartnerPrograms_Migrated__c = partnerProgramsMigrated;
				}
			}
		}
		if(! duplicateLogContactMap.isEmpty()) {
			// there is a 20 child query limit...
			Map<Id,Contact> contactMap = new Map<Id,Contact>( [
				select Id,
//broken					(select Id from Opportunities where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities1__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Proof_Of_Concepts__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Proof_Of_Concepts2__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Proof_Of_Concepts3__r where Id not in :ignoreRecordIds limit 1),
					(select Id from OpportunitiesBillToCon__r where Id not in :ignoreRecordIds limit 1),
					(select Id from OpportunitiesEntitleToCon__r where Id not in :ignoreRecordIds limit 1),
					(select Id from OpportunitiesShipToCon__r where Id not in :ignoreRecordIds limit 1),
					(select Id from OpportunitiesSoldToCon__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Header_Staging1__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Header_Staging2__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Header_Staging3__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Header_Staging__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunities_Line_Staging__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Opportunity_Product__r where Id not in :ignoreRecordIds limit 1),
					(select Id from OpportunityContactRoles where Id not in :ignoreRecordIds limit 1),
					(select Id from Order_Management_Profiles1__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Order_Management_Profiles2__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Order_Management_Profiles3__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Order_Management_Profiles__r where Id not in :ignoreRecordIds limit 1)
				from Contact
				where Id in :duplicateLogContactMap.keySet() ] );
			for(DuplicateLog__c dlog : duplicateLogContactMap.values()) {
				Contact a = contactMap.get((Id)dlog.DuplicateRecordId__c);

				Boolean opportunitiesMigrated = (a == null ||
					(	(a.Opportunities1__r == null || a.Opportunities1__r.isEmpty())
//broken						&& (a.Opportunities == null || a.Opportunities.isEmpty())
						&& (a.Proof_Of_Concepts__r == null || a.Proof_Of_Concepts__r.isEmpty())
						&& (a.Proof_Of_Concepts2__r == null || a.Proof_Of_Concepts2__r.isEmpty())
						&& (a.Proof_Of_Concepts3__r == null || a.Proof_Of_Concepts3__r.isEmpty())
						&& (a.OpportunitiesBillToCon__r == null || a.OpportunitiesBillToCon__r.isEmpty())
						&& (a.OpportunitiesEntitleToCon__r == null || a.OpportunitiesEntitleToCon__r.isEmpty())
						&& (a.OpportunitiesShipToCon__r == null || a.OpportunitiesShipToCon__r.isEmpty())
						&& (a.OpportunitiesSoldToCon__r == null || a.OpportunitiesSoldToCon__r.isEmpty()) ) );
				if(opportunitiesMigrated != dlog.Opportunities_Migrated__c) {
					dlog.Opportunities_Migrated__c = opportunitiesMigrated;
				}

				Boolean productsMigrated = (a == null ||
					(a.Opportunity_Product__r == null || a.Opportunity_Product__r.isEmpty()) );
				if(productsMigrated != dlog.Products_Migrated__c) {
					dlog.Products_Migrated__c = productsMigrated;
				}

				Boolean oppContactRolesMigrated = ( a == null || 
					(a.OpportunityContactRoles == null || a.OpportunityContactRoles.isEmpty() ) );
				if(oppContactRolesMigrated != dlog.OppContactRoles_Migrated__c) {
					dlog.OppContactRoles_Migrated__c = oppContactRolesMigrated;
				}

				Boolean stagingHeadersMigrated = (a == null ||
					(	(a.Opportunities_Header_Staging__r == null || a.Opportunities_Header_Staging__r.isEmpty())
						&& (a.Opportunities_Header_Staging1__r == null || a.Opportunities_Header_Staging1__r.isEmpty())
						&& (a.Opportunities_Header_Staging2__r == null || a.Opportunities_Header_Staging2__r.isEmpty())
						&& (a.Opportunities_Header_Staging3__r == null || a.Opportunities_Header_Staging3__r.isEmpty()) ) );
				if(stagingHeadersMigrated != dlog.Staging_Headers_Migrated__c) {
					dlog.Staging_Headers_Migrated__c = stagingHeadersMigrated;
				}

				Boolean stagingLinesMigrated = (a == null ||
					(a.Opportunities_Line_Staging__r == null || a.Opportunities_Line_Staging__r.isEmpty()) );
				if(stagingLinesMigrated != dlog.Staging_Lines_Migrated__c) {
					dlog.Staging_Lines_Migrated__c = stagingLinesMigrated;
				}

				Boolean omProfilesMigrated = (a == null ||
					(	(a.Order_Management_Profiles__r == null || a.Order_Management_Profiles__r.isEmpty())
						&& (a.Order_Management_Profiles1__r == null || a.Order_Management_Profiles1__r.isEmpty())
						&& (a.Order_Management_Profiles2__r == null || a.Order_Management_Profiles2__r.isEmpty())
						&& (a.Order_Management_Profiles3__r == null || a.Order_Management_Profiles3__r.isEmpty()) ) );
				if(omProfilesMigrated != dlog.OM_Profiles_Migrated__c) {
					dlog.OM_Profiles_Migrated__c = omProfilesMigrated;
				}
			}
		}
		if(! duplicateLogContactMap2.isEmpty()) {
			// there is a 20 child query limit...
			Map<Id,Contact> contactMap = new Map<Id,Contact>( [
				select Id,
					(select Id from Opportunity_Partners_contact__r where Id not in :ignoreRecordIds limit 1),
					(select Id from PartnerProgramContacts__r where Id not in :ignoreRecordIds limit 1),
					(select IsTask from ActivityHistories where Id not in :ignoreRecordIds limit 1), 
					(select IsTask from OpenActivities where Id not in :ignoreRecordIds limit 1),
					(select Id from Subscription_Lines__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsBillTo__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsEntitleTo__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsSellingContact__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsShipTo__r where Id not in :ignoreRecordIds limit 1),
					(select Id from SubscriptionsSoldTo__r where Id not in :ignoreRecordIds limit 1),
					(select Id from Subscriptions__r where Id not in :ignoreRecordIds limit 1)
				from Contact
				where Id in :duplicateLogContactMap2.keySet() ] );
			for(DuplicateLog__c dlog : duplicateLogContactMap2.values()) {
				Contact a = contactMap.get((Id)dlog.DuplicateRecordId__c);

				Boolean activitiesMigrated = ( a == null || 
					(	(a.ActivityHistories == null || a.activityHistories.isEmpty())
						&& (a.OpenActivities == null || a.OpenActivities.isEmpty()) ) );
				if(activitiesMigrated != dlog.Activities_Migrated__c) {
					dlog.Activities_Migrated__c = activitiesMigrated;
				}

				Boolean oppPartnersMigrated = ( a == null || 
					(a.Opportunity_Partners_contact__r == null || a.Opportunity_Partners_contact__r.isEmpty() ) );
				if(oppPartnersMigrated != dlog.OpportunityPartners_Migrated__c) {
					dlog.OpportunityPartners_Migrated__c = oppPartnersMigrated;
				}

				Boolean partnerProgramsMigrated = ( a == null || 
					(a.PartnerProgramContacts__r == null || a.PartnerProgramContacts__r.isEmpty() ) );
				if(partnerProgramsMigrated != dlog.PartnerPrograms_Migrated__c) {
					dlog.PartnerPrograms_Migrated__c = partnerProgramsMigrated;
				}

				Boolean subscriptionsMigrated = (a == null ||
					(	(a.Subscriptions__r == null || a.Subscriptions__r.isEmpty())
						&& (a.SubscriptionsBillTo__r == null || a.SubscriptionsBillTo__r.isEmpty())
						&& (a.SubscriptionsEntitleTo__r == null || a.SubscriptionsEntitleTo__r.isEmpty())
						&& (a.SubscriptionsSellingContact__r == null || a.SubscriptionsSellingContact__r.isEmpty())
						&& (a.SubscriptionsShipTo__r == null || a.SubscriptionsShipTo__r.isEmpty())
						&& (a.SubscriptionsSoldTo__r == null || a.SubscriptionsSoldTo__r.isEmpty()) ) );
				if(subscriptionsMigrated != dlog.Subscriptions_Migrated__c) {
					dlog.Subscriptions_Migrated__c = subscriptionsMigrated;
				}

				Boolean subscriptionLinesMigrated = (a == null ||
					(a.Subscription_Lines__r == null || a.Subscription_Lines__r.isEmpty()) );
				if(subscriptionLinesMigrated != dlog.Subscription_Lines_Migrated__c) {
					dlog.Subscription_Lines_Migrated__c = subscriptionLinesMigrated;
				}
			}
		}

		// now we can update the status
		for(DuplicateLog__c dlog : newList) {
			String status = 'In Progress';
			if(dlog.Opportunities_Migrated__c == true
				&& dlog.Products_Migrated__c == true 
				&& dlog.Staging_Headers_Migrated__c == true
				&& dlog.Staging_Lines_Migrated__c == true
				&& dlog.OM_Profiles_Migrated__c == true
				&& dlog.Subscriptions_Migrated__c == true
				&& dlog.Subscription_Lines_Migrated__c == true
				&& dlog.OppContactRoles_Migrated__c == true
				&& dlog.PartnerPrograms_Migrated__c == true
				&& dlog.OpportunityPartners_Migrated__c == true
				&& dlog.Activities_Migrated__c == true )
			{
				status = 'Completed';
			}
			else if(isInsert || ( failedMigrations(dlog) == 0 && successfulMigrations(dlog) == 0) ) {
				status = 'Pending';
			}
			if(status != dlog.Status__c) {
				dlog.Status__c = status ;
			}
		}
	}

	/**
	 * This method is called to invoke all the trigger methods.
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewList normally assigned from Trigger.newList
	 */
	public static void processTrigger(Map<Id,DuplicateLog__c> xoldMap,List<DuplicateLog__c> xnewList) {
		final DuplicateLogTriggerBefore beforeTrigger = new DuplicateLogTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(TOGGLE_MIGRATED_SETTING,true)) {
			beforeTrigger.toggleMigrated();
		}
		AbstractTrigger.processTriggerComplete();
	}
}