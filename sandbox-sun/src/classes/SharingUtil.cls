/*
* Name : SharingUtil
* Author : Rohit Mehta
* Date : 04192010
* Usage : Util class Used by the NFR Sharing Code
*/
public without sharing class SharingUtil {

  	public static Map<Id, Id> getRoles(List<Id> parIds){
    	Map<Id, Id> accountIdUserRoleIdMap = new Map<Id, Id>();
  		for (UserRole uRole : [Select  u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId In :parIds]) {
    		accountIdUserRoleIdMap.put(uRole.PortalAccountId, uRole.Id);
  		}

    	System.debug('accountIdUserRoleIdMap = ' + accountIdUserRoleIdMap);
    	return accountIdUserRoleIdMap;
  	}
  
  	public static Map<Id,Id> getGroups(List<Id> roleIds){
    	//get the group for the above roles
    	Map<Id, Id> gMap = new Map<Id, Id>();
    	List<Group> gList = [Select g.Name, g.Id, g.RelatedId From Group g where RelatedId In :roleIds and Type = 'RoleAndSubordinates'];
    	for (Group g : gList) {
      		gMap.put(g.RelatedId, g.Id);
    	}
    	
    	System.debug('gMap = ' + gMap);
    	return gMap;
  	}
  		
	public static SObject addToShare(Id sobjectId, Id accountId, Map<Id, Id> accountIdUserRoleIdMap, Map<Id,Id> gMap) {
		if (accountId == null) {
			return null;	
		}
    	Id roleId = accountIdUserRoleIdMap.get(accountId);
    	Id groupId = gMap.get(roleId);
    	
    	if (groupId == null) {
    		return null;
    	}

		NFR_Request__Share nfrShare = new NFR_Request__Share(
					        	ParentId = sObjectId,
					        	userOrGroupId = groupId,
					        	AccessLevel = 'Edit',
					        	RowCause = Schema.NFR_Request__Share.rowCause.Partner__c);
		return nfrShare;
	}
}