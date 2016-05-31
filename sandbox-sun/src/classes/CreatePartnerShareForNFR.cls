/*
* Name : CreatePartnerShareForNFR
* Author : Rohit Mehta
* Date : 04192010
* Usage : Class Used by the NFR Trigger to create sharing for partners
*/
public without sharing class CreatePartnerShareForNFR {

	/*
	* Deletes all Shares where the rowCause is partner
	*/
	public static void removeNFRShare(Map<Id, Id> sObject_oldPartner_map) {	
		delete [select Id from NFR_Request__Share where ParentId In :sObject_oldPartner_map.keySet() 
			And RowCause = 'Partner__c'];
	}

	/*
	* Future Method. Create Shares for NFR
	*/
	@future
	public static void createNFRShareAsync(Map<Id, Id> sObject_partner_map) {
	    createNFRShare(sObject_partner_map);
	}

	/*
	* Create Shares for NFR
	*/
	public static void createNFRShare(Map<Id, Id> sObject_partner_map) {
	    List<NFR_Request__Share> newSObjectShares = new List<NFR_Request__Share>();
		createSObjectShare(sObject_partner_map, newSObjectShares);
	}
	
	/*
	* Common Method which creates the Shares. 
	*/
	public static void createSObjectShare(Map<Id, Id> sObject_partner_map, 
		List<SObject> newSObjectShares) 
	{

        System.debug('sObject_partner_map = ' + sObject_partner_map);     	
		
		
		Map<Id, Id> accountIdUserRoleIdMap = SharingUtil.getRoles(sObject_partner_map.values());
		Map<Id,Id> gMap = SharingUtil.getGroups(accountIdUserRoleIdMap.values());
        System.debug('accountIdUserRoleIdMap = ' + accountIdUserRoleIdMap);     	
		System.debug('gMap = ' + gMap);

    	for (Id sObjectId : sObject_partner_map.keySet()) { 
    		Id partnerId =  sObject_partner_map.get(sObjectId);
			System.debug('partnerId = ' + partnerId);
			SObject sobjectShare = SharingUtil.addToShare(sobjectId, partnerId, accountIdUserRoleIdMap, gMap);
			System.debug('sobjectShare = ' + sobjectShare);
			if (sobjectShare != null) {
				newSObjectShares.add(sobjectShare);
			}
			
        }
        
    	if(newSObjectShares.size() > 0)
    		insert newSObjectShares;
    	
        System.debug('newSObjectShares => ' + newSObjectShares);  
	}		
}