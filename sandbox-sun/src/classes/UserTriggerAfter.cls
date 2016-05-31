/**
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2012-09-06
 * 2012-09-06 - Created
 */
public without sharing class UserTriggerAfter extends AbstractTrigger {
	/** BooleanSetting__c key to enable setting legacy copy values */
	public static final String MAINTAIN_GROUP_MEMBERSHIP_SETTING = 'User_After.maintainGroupMembership';
	
	/** map of in scope public group names and ids */
	public static Map<String,Id> groupNameGroupId = new Map<String,Id>{'APAC_Sales'=>'00G60000001OTS1',
																		'EMEA_Sales'=>'00G60000001OTS6',
																		'LATAM_Sales'=>'00G60000001OTRx',
																		'NA_Sales'=>'00G60000001OTSB',
																		'Public_Sector_Sales'=>'00G60000001OTSV'};
		
	/** map of super regions and desired groups */
	public static Map<String,String> superRegionGroup = new Map<String,String> {'APAC'=>'APAC_Sales',
																				'EMEA'=>'EMEA_Sales',
																				'LATAM'=>'LATAM_Sales',
																				'NA'=>'NA_Sales',
																				'GLOBAL'=>'NA_Sales',
																				'NONE'=>'NA_Sales'};

	private final Map<Id,User> oldMap;
	private final List<User> newList;

	/**
	 * Typical TriggerAfter type constructor
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewList normally assigned from Trigger.newList
	 */
	public UserTriggerAfter(Map<Id,User> xoldMap,List<User> xnewList) {
		super(xoldMap,xnewList,null);
		oldMap = (Map<Id,User>)oldSObjectMap;
		newList = (List<User>)newSObjectList;
	}

	private Map<Id,User> userMap {
		get {
			if (userMap == null) {
				userMap = new Map<Id,User>{};
				for(User u : newList) {
					Profile p = userProfileMap.get(u.ProfileId);
					if (!p.Name.contains('Partner') && !p.Name.contains('Chatter')) {
						userMap.put(u.Id,u);
					}
				}
			}
			return userMap;
		}
		set;
	}
	
	private Map<Id,UserRole> userRoleMap {
		get {
			if (userRoleMap == null) {
				userRoleMap = new Map<Id,UserRole>{};
				for (User u : newList) {
					userRoleMap.put(u.UserRoleId,null);
				}
				List<UserRole> userRoleList = [SELECT Id, Name FROM UserRole WHERE Id IN :userRoleMap.keySet()];
				for (UserRole ur : userRoleList) {
					userRoleMap.put(ur.Id,ur);
				}
			}
			return userRoleMap;
		}
		set;
	}
	
	private Map<Id,Profile> userProfileMap {
		get {
			if (userProfileMap == null) {
				userProfileMap = new Map<Id,Profile>{};
				for (User u : newList) {
					userProfileMap.put(u.ProfileId,null);
				}
				List<Profile> userProfileList = [SELECT Id, Name FROM Profile WHERE Id IN :userProfileMap.keySet()];
				for (Profile p : userProfileList) {
					userProfileMap.put(p.Id,p);
				}
			}
			return userProfileMap;
		}
		set;
	}

	private string getDesiredGroup(Id userId) {
		User u = userMap.get(userId);
		String superRegion = u.Region__c;
		if (superRegion == '' || superRegion == null) {
			superRegion = 'NONE';
		}
		String userRole;
		if (u.UserRoleId != null) {
		 	userRole = userRoleMap.get(u.UserRoleId).Name;
		}
		else {
			userRole = 'NONE';
		}
		String desiredGroup;
		// special case for NA Public Sector Sales
		if (superRegion == 'NA' && userRole.contains('Public Sector')) {
			desiredGroup = 'Public_Sector_Sales';
		}
		else {
			desiredGroup = superRegionGroup.get(superRegion);
		}
		return desiredGroup;
	}

	/**
	 * This method maintains a user's public group memberships ensuring
	 * they are added to the correct group on create and if necessary are moved
	 * to the correct group on update.
	 */
	
	public void maintainGroupMembership() {
																																		
		// get list of relevant group memberships
		List<GroupMember> groupMemberships = new List<GroupMember>{};
		if(oldMap != null) { 
			groupMemberships = [SELECT Id,UserOrGroupId,Group.DeveloperName 
									FROM GroupMember
									WHERE UserOrGroupId IN :userMap.keySet()
										AND GroupId IN :groupNameGroupId.values()
									ORDER BY UserOrGroupId];
		}
	
		// loop through existing group memberships and determine which need to be deleted or kept
		List<GroupMember> deleteMemberships = new List<GroupMember>{};
		Map<Id,GroupMember> userMembership = new Map<Id,GroupMember>{};
		for(GroupMember existingMembership : groupMemberships) {
			String desiredGroup = getDesiredGroup(existingMembership.UserOrGroupId);
			if(existingMembership.Group.DeveloperName == desiredGroup) {
				userMembership.put(existingMembership.UserOrGroupId,existingMembership);
			}
			else {
				deleteMemberships.add(existingMembership);
			}
		}
		
		// loop through users and determine which memberships need to be added
		List<GroupMember> insertMemberships = new List<GroupMember>{};
		for(User u : userMap.values()) {
			if(!userMembership.keySet().contains(u.Id)) {
				String desiredGroup = getDesiredGroup(u.Id);
				Id desiredGroupId = groupNameGroupId.get(desiredGroup);
				GroupMember newMembership = new GroupMember(GroupId=desiredGroupId,
				UserOrGroupId=u.Id);
				insertMemberships.add(newMemberShip);
			}
		}
		
		delete deleteMemberships;
		insert insertMemberships;
	}
	
	/**
	 * This method is called to invoke all the trigger methods.
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewMap normally assigned from Trigger.newMap
	 */
	public static void processTrigger(Map<Id,User> xoldMap,List<User> xnewList) {
		final UserTriggerAfter afterTrigger = new UserTriggerAfter(xoldMap,xnewList);
		if(AbstractTrigger.isActive(MAINTAIN_GROUP_MEMBERSHIP_SETTING,true)) {
			afterTrigger.maintainGroupMembership();
		}
	}
}