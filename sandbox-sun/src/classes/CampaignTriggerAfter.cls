/**
 * This class replaces all before insert and before update campaign triggers.  The
 * processTrigger method is invoked by the Campaign_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2014-06-05
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-05-02 - Now touching related CampaignMember objects to invoke their triggers
 * 2013-02-07 - Use CampaignHierarchy class to manage data in memory to reduce query count
 * 2013-01-29 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2014-06-05 - Added mkt_cl_cmp_media_name__c (Tactic Name) to list fields to check in updateName
 * 2014-05-29 - Added updateName method, and locking to prevent recursion
 * 2013-05-14 - Now relying on roll-ups in the Campaign Hierarchy Details so using a future method to trigger recursive updates
 */
public without sharing class CampaignTriggerAfter extends AbstractTrigger {
	/** number DML operations needed to update Campaign Hierarchy Details records. */
	public static Integer neededDML = 1;
	/** true if future calls should be used when out of DML operations */
	public static Boolean useFuture = true;

	/** BooleanSetting__c key to enable hierarchy data maintenance */
	public static final String MAINTAIN_HIERARCHY_DATA_SETTING = 'Campaign_After.maintainHierarchyData';
	/** BooleanSetting__c key to enable the touchCampaignMembers trigger method. */
	public static final String TOUCH_CAMPAIGN_MEMBERS_SETTING = 'Campaign_After.touchCampaignMembers';
	/** BooleanSetting__c key to enable setting name */
	public static final String UPDATE_NAME_SETTING = 'Campaign_After.updateName';

	private final Map<Id,Campaign> oldMap = new Map<Id,Campaign>();
	private final Map<Id,Campaign> newMap = new Map<Id,Campaign>();
	// note: isUndelete == true => isInsert == true
	private Boolean isUndelete;

	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap the mapping of old values
	 * @param xnewMap the mapping of new values
	 */
	public CampaignTriggerAfter(Map<Id,Campaign> xoldMap,Map<Id,Campaign> xnewMap,Boolean isUndelete) {
		super(xoldMap,null,xnewMap);
		this.isUndelete = isUndelete;
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	// Prepare the list of campaigns that need to be updated.
	@TestVisible
	private List<Campaign> getUpdateNameAndUrlList() {
		List<Campaign> campaigns = newMap.values().deepClone(true,true,true);
		CampaignTriggerBefore triggerBefore = new CampaignTriggerBefore(oldMap,campaigns);
		triggerBefore.assignName(true);
		if(AbstractTrigger.isActive(CampaignTriggerBefore.ASSIGN_URLS_SETTING,true)) {
			triggerBefore.assignUrls(isInsert);
		}
		List<Campaign> updateList = new List<Campaign>();
		for( Campaign c : campaigns) {
			Campaign current = newMap.get(c.Id);
			if(current == null 
				|| c.Name != current.Name
				|| c.mkt_cl_cmp_cta__c != current.mkt_cl_cmp_cta__c
				|| c.Offer_Name__c != current.Offer_Name__c
				|| c.Tracking_Campaign_ID_URL__c != current.Tracking_Campaign_ID_URL__c
				|| c.mkt_cl_cmp_media_name__c != current.mkt_cl_cmp_media_name__c )
			{
				updateList.add(c);
			}
		}
		return updateList;
	}

	// Update the list of campaigns after inserting.
	@TestVisible
	private Boolean updateCampaigns(List<Campaign> updateList) {
		Boolean hasErrors = false;
		if(! updateList.isEmpty()) {
			for(Database.Saveresult sr : Database.update(updateList,false)) {
				if(!sr.isSuccess()) {
					Campaign c = newMap.get(sr.getId());
					if(c != null) {
						hasErrors = true;
						for(Database.Error e : sr.getErrors()) {
							c.addError(''+e);
						}
					}
				}
			}
		}
		return hasErrors;
	}

	/**
	 * Update campaign name when neccessary after inserting.
	 */ 
	public void updateName() {
		if(isInsert) {
			try {
				updateCampaigns(getUpdateNameAndUrlList());
			}
			finally {
				ThreadLock.unlock(UPDATE_NAME_SETTING);
			}
		}
	}

	/**
	 * Method to update the Campaign Design Hierarchy.  The rollup fields may trigger
	 * recursive updates.
	 *
	 * @param map of campaign parent ids
	 * @param remainingDML number of DML operations below the limit
	 */
	public static void updateCampaignDesignHierarchy(Map<Id,Id> parentMap,Integer remainingDML) {
		if(useFuture && remainingDML < neededDML && Limits.getLimitFutureCalls() > Limits.getFutureCalls()) {
			updateCampaignDesignHierarchyFuture(parentMap);
		}
		else {
			updateCampaignDesignHierarchyNotFuture(parentMap);
		}
	}

	/**
	 * Future method to update the Campaign Design Hierarchy.  The rollup fields may trigger
	 * recursive updates.
	 *
	 * @param map of campaign parent ids
	 */
	@future
	public static void updateCampaignDesignHierarchyFuture(Map<Id,Id> parentMap) {
		try {
			useFuture = false;
			updateCampaignDesignHierarchyNotFuture(parentMap);
		}
		finally {
			useFuture = true;
		}
	}

	/**
	 * Not future method to update the Campaign Design Hierarchy.  The rollup fields may trigger
	 * recursive updates.
	 *
	 * @param map of campaign parent ids
	 */
	public static void updateCampaignDesignHierarchyNotFuture(Map<Id,Id> parentMap) {
		List<Campaign_Hierarchy_Details__c> upsertList = new List<Campaign_Hierarchy_Details__c>();
		for(Id cId : parentMap.keySet()) {
			upsertList.add(new Campaign_Hierarchy_Details__c(
				Campaign__c=parentMap.get(cId),
				Campaign_Detail__c = cId,
				External_Id__c = cId));
		}
		Database.upsert(upsertList,Campaign_Hierarchy_Details__c.Fields.External_Id__c,false);
	} 

	/**
	 * Trigger class responsible for maintaining flattened hierarchy data used for custom rollups.
	 */
	public void maintainHierarchyData() {
		Integer remainingDML = Limits.getLimitDMLStatements() - Limits.getDMLStatements();
		if(isDelete) {
			Database.delete([select Id from Campaign_Hierarchy_Details__c where Campaign_Detail__c in :oldMap.keySet()],false);
		}
		else if(useFuture || remainingDML >= neededDML) {
			Map<Id,Id> parentMap = new Map<Id,Id>();
			for(Campaign c : newMap.values()) {
				if(c.ParentId != null) {
					parentMap.put(c.Id,c.ParentId);
				}
			}
			if(! parentMap.isEmpty()) {
				updateCampaignDesignHierarchy(parentMap,remainingDML);
			}
// this is legacy stuff
//			// create an instance of the object that will maintain campaign data in memory (to reduce query count)
//			CampaignHierarchy hierarchyData = new CampaignHierarchy(newMap.values());
//			for(Campaign c : newMap.values()) {
//				Campaign oldC;
//				if(isUpdate) {
//					oldC = oldMap.get(c.Id);
//				}
//				Boolean isReparent = (isUpdate && (oldC.ParentId != c.ParentId));
//				Boolean isSummarizedFieldChange = (isUpdate && (oldC.Expected_Number_of_Responses__c != c.Expected_Number_of_Responses__c));
//				// add/update detail records as necessary when campaign is inserted, reparented, or summarized field is updated
//				if(isInsert || isReparent || isSummarizedFieldChange) {
//					List<Campaign> childCampaigns = new List<Campaign>{c};
//					// get other child campaigns of inserted campaign if any (this can happen with an undelete or reparent)
//					if(isInsert || isReparent) {
//						childCampaigns.addAll(hierarchyData.getChildCampaigns(c.Id));
//					}
//					// detail records for affected campaigns
//					Campaign currentCampaign = c;
//					while(currentCampaign != null) {
//						for(Campaign childCampaign : childCampaigns) {
//							Id currentCampaignId = currentCampaign.Id;
//							Id childCampaignId = childCampaign.Id;
//							Double expectedResponses = childCampaign.Expected_Number_of_Responses__c;
//							hierarchyData.putHierarchyDetails(currentCampaignId, childCampaignId, expectedResponses);
//						}
//						currentCampaign = hierarchyData.getParentCampaign(currentCampaign.Id);
//					}
//				}
//			}
//			if(hierarchyData.upsertList.size() > 0) {
//				Database.upsert(hierarchyData.upsertList,Campaign_Hierarchy_Details__c.Fields.External_Id__c,true);
//			}
		}
	}

	/**
	 * This triggerMethod touches any CampaignMember objects related to
	 * updated campaigns that have a record type transition. 
	 * This lets CampaignMember triggers reevaluate CampaignMember.IsLeadActive__c.
	 */
	public void touchCampaignMembers() {
		if(isUpdate) {
			Set<Id> campaignIds = new Set<Id>();
			for(Campaign newCampaign : newMap.values()) {
				Campaign oldCampaign = oldMap.get(newCampaign.Id);
				if(newCampaign.RecordTypeId != oldCampaign.RecordTypeId) {
					campaignIds.add(newCampaign.Id);
				}
			}
			if(!campaignIds.isEmpty()) {
				List<CampaignMember> members = [
					select
						Id
					from CampaignMember
					where CampaignId in :campaignIds ];
				if(!members.isEmpty()) {
					Database.update(members,false);
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
	public static void processTrigger(Map<Id,Campaign> xoldMap,Map<Id,Campaign> xnewMap,Boolean isUndelete) {
		final String lockString = 'CampaignTriggerAfter.Lock';
		if(ThreadLock.lock(lockString)) {
			final CampaignTriggerAfter afterTrigger = new CampaignTriggerAfter(xoldMap,xnewMap,isUndelete);
			try {
				if(AbstractTrigger.isActive(MAINTAIN_HIERARCHY_DATA_SETTING,true)) {
					afterTrigger.maintainHierarchyData();
				}
				if(AbstractTrigger.isActive(TOUCH_CAMPAIGN_MEMBERS_SETTING,true)) {
					afterTrigger.touchCampaignMembers();
				}
				if(AbstractTrigger.isActive(UPDATE_NAME_SETTING,true)) {
					afterTrigger.updateName();
				}
				AbstractTrigger.processTriggerComplete();
			}
			finally {
				ThreadLock.unlock(lockString);
			}
		}
	}
}