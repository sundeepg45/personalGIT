/**
 * This class maintains several collections used by Campaign triggers
 * to keep the data that supports custom hierarchy rollup fields current.
 *
 * The primary goal of this class is to reduce the number of queries necessary
 * in those triggers to make bulk insert/update of Campaign records feasible.
 *
 * The custom object Campaign_Hierarchy_Details__c is used to store a
 * flattened representation of each Campaign tree that makes it easy to
 * use a standard Salesforce rollup field to summarize data at each node
 * of the tree. This could be extended for use with additional custom 
 * hierarchy rollup fields without too much trouble.
 *
 * This class maintains lists of modified and removed
 * Campaign_Hierarchy_Details__c records but leaves the actual upsert
 * and delete to the calling class.
 *
 * @version 2013-05-15
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-02-07 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2013-05-15 - Depreciated
 */
public without sharing class CampaignHierarchy {
//	//Set<Campaign.Id>
//	private Set<Id> campaignIds {
//		get {
//			if(campaignIds == null) {
//				campaignIds = new Set<Id>();	
//			}
//			return campaignIds;
//		}
//		set;
//	}

//	//Map<Campaign.Id,Campaign>
//	private Map<Id,Campaign> campaignMap {
//		get {
//			if(campaignMap == null) {
//				//get initial list of campaigns
//				List<Campaign> campaigns = [SELECT Id,
//												Ultimate_Parent_Campaign_Id__c 
//											FROM Campaign WHERE Id IN :campaignIds];
//				//build unique set of ultimate parent Id values found in the initial list of campaigns
//				Set<String> ultimateParentIds = new Set<String>();
//				for(Campaign campaign : campaigns) {
//					ultimateParentIds.add(campaign.Ultimate_Parent_Campaign_Id__c.left(15));
//				}
//				for(String id : ultimateParentIds) {
//					System.Debug('CH1 ultimateParentId: ' + id);
//				}
//				//get all the campaigns that fill out all the trees represented by the initial list
//				campaignMap = new Map<Id,Campaign>([SELECT Id, 
//														Name, 
//														ParentId, 
//														Expected_Number_of_Responses__c, 
//														Total_Expected_Responses_in_Hierarchy__c, 
//														Ultimate_Parent_Campaign_Id__c 
//													FROM Campaign WHERE Ultimate_Parent_Campaign_Id__c IN :ultimateParentIds]);
//			}
//			return campaignMap;
//		}
//		private set;
//	}

//	//Map<Campaign.ParentId,Set<Campaign.Id>>
//	private Map<Id,Set<Id>> childCampaignMap {
//		get {
//			if(childCampaignMap == null) {
//				//now break all the child campaigns out into their individual trees
//				childCampaignMap = new Map<Id,Set<Id>>();
//				for(Campaign campaign : campaignMap.values()) {
//					if(campaign.ParentId != null) {
//						Set<Id> childCampaignIds = childCampaignMap.get(campaign.ParentId);
//						if(childCampaignIds == null) {
//							childCampaignIds = new Set<Id>{campaign.Id};
//						}
//						else {
//							childCampaignIds.add(campaign.Id);
//						}
//						childCampaignMap.put(campaign.ParentId,childCampaignIds);
//					}
//				}
//			}
//			return childCampaignMap;
//		}
//		private set;
//	}

//	//Map<Campaign.ParentId,Map<Campaign.Id,Campaign_Hierarchy_Details__c>>
//	private Map<Id,Map<Id,Campaign_Hierarchy_Details__c>> campaignDetailsMap {
//		get {
//			if(campaignDetailsMap == null) {
//				campaignDetailsMap = new Map<Id,Map<Id,Campaign_Hierarchy_Details__c>>();
//				List<Campaign_Hierarchy_Details__c> campaignDetails = [SELECT Campaign__c,
//																			Campaign_Detail__c, 
//																			Expected_Number_of_Responses__c, 
//																			External_ID__c
//																		FROM Campaign_Hierarchy_Details__c
//																		WHERE Campaign__c IN :campaignMap.keySet()
//																		FOR UPDATE];
//				for(Campaign_Hierarchy_Details__c details : campaignDetails) {
//					putHierarchyDetails(details, false);
//				}
//			}
//			return campaignDetailsMap;
//		}
//		private set;
//	}

//	private Map<String,Campaign_Hierarchy_Details__c> upsertMap {
//		get {
//			if(upsertMap == null) {
//				upsertMap = new Map<String,Campaign_Hierarchy_Details__c>();
//			}
//			return upsertMap;
//		}
//		private set;
//	}

//	private Map<String,Campaign_Hierarchy_Details__c> deleteMap {
//		get {
//			if(deleteMap == null) {
//				deleteMap = new Map<String,Campaign_Hierarchy_Details__c>();
//			}
//			return deleteMap;
//		}
//		private set;		
//	}

//	//constructor
//	// accepts a Set of Campaign ids. based on these ids, the necessesary full trees will be fetched.
//	public CampaignHierarchy(Set<Id> xcampaignIds) {
//		campaignIds = xcampaignIds;
//	}

//	public CampaignHierarchy(List<Campaign> campaigns) {
//		for(Campaign campaign : campaigns) {
//			campaignIds.add(campaign.Id);
//		}
//	}

//	public List<Campaign_Hierarchy_Details__c> upsertList {
//		get {
//			return upsertMap.values();
//		}
//	}

//	public List<Campaign_Hierarchy_Details__c> deleteList{
//		get {
//			return deleteMap.values();
//		}
//	}

//	//returns all campaigns below a given campaign in the tree (not just immediate children). returns empty List if no children.
//	public List<Campaign> getChildCampaigns(Id campaignId) {
//		List<Campaign> childCampaigns = new List<Campaign>();
//		Set<Id> childCampaignIds = childCampaignMap.get(campaignId); 
//		while(childCampaignIds != null && childCampaignIds.size() > 0) {
//			Set<Id> nextLevelChildCampaignIds = new Set<Id>();
//			for(Id childCampaignId : childCampaignIds) {
//				if(campaignMap.containsKey(childCampaignId)) {
//					childCampaigns.add(campaignMap.get(childCampaignId));
//					if(childCampaignMap.containsKey(childCampaignId)) {
//						nextLevelChildCampaignIds.addAll(childCampaignMap.get(childCampaignId));
//					}
//				}
//			}
//			childCampaignIds = nextLevelChildCampaignIds;
//		}
//		return childCampaigns;
//	}

//	//returns a given campaign's parent campaign. returns null if no parent.
//	public Campaign getParentCampaign(Id campaignId) {
//		Campaign campaign = campaignMap.get(campaignId);
//		Campaign parentCampaign;
//		if(campaign != null) {
//			if(campaign.ParentId != null) {
//				parentCampaign = campaignMap.get(campaign.ParentId);
//			}
//		}
//		else {
//			throw new CampaignHierarchyException('Campaign not found. The campaignId supplied may not exist in the hierarchy of any campaignId(s) provided in the constructor.');
//		}
//		return parentCampaign;
//	}

//	public Campaign_Hierarchy_Details__c putHierarchyDetails(Id parentId, Id childId, Double expectedResponses) {
//		String externalId = parentId + '.' + childId;
//		Campaign_Hierarchy_Details__c details = new Campaign_Hierarchy_Details__c(Campaign__c = parentId, 
//																						Campaign_Detail__c = childId,
//																						External_Id__c = externalId,
//																						Expected_Number_of_Responses__c = expectedResponses);
//		return putHierarchyDetails(details, true);
//	}

//	public Campaign_Hierarchy_Details__c putHierarchyDetails(Campaign_Hierarchy_Details__c details) {
//		return putHierarchyDetails(details, true);
//	}

//	public Campaign_Hierarchy_Details__c putHierarchyDetails(Campaign_Hierarchy_Details__c details, Boolean upsertDetails) {
//		Map<Id,Campaign_Hierarchy_Details__c> detailsMap = campaignDetailsMap.get(details.Campaign__c);
//		if(detailsMap == null) {
//			detailsMap = new Map<Id,Campaign_Hierarchy_Details__c>{details.Campaign_Detail__c => details};
//		}
//		else {
//			detailsMap.put(details.Campaign_Detail__c,details);
//		}
//		campaignDetailsMap.put(details.Campaign__c,detailsMap);
//		if(upsertDetails) {
//			upsertMap.put(details.External_Id__c,details);
//		}
//		return details;
//	}

//	public Campaign_Hierarchy_Details__c getHierarchyDetails(Id parentId, Id childId) {
//		Campaign_Hierarchy_Details__c details;
//		Map<Id, Campaign_Hierarchy_Details__c> detailsMap = campaignDetailsMap.get(parentId);
//		if(detailsMap != null) {
//			details = detailsMap.get(childId);
//		}
//		return details;
//	}

//	public List<Campaign_Hierarchy_Details__c> getHierarchyDetails(Id parentId) {
//		List<Campaign_Hierarchy_Details__c> details = new List<Campaign_Hierarchy_Details__c>();
//		Map<Id, Campaign_Hierarchy_Details__c> detailsMap = campaignDetailsMap.get(parentId);
//		if(detailsMap != null) {
//			details = detailsMap.values();
//		}
//		return details;
//	}

//	public Campaign_Hierarchy_Details__c removeHierarchyDetails(Id parentId, Id childId) {
//		Campaign_Hierarchy_Details__c details;
//		Map<Id, Campaign_Hierarchy_Details__c> detailsMap = campaignDetailsMap.get(parentId);
//		if(detailsMap != null) {
//			details = detailsMap.remove(childId);
//		}
//		deleteMap.put(details.External_Id__c,details);
//		return details;
//	}

//	public class CampaignHierarchyException extends Exception {}
}