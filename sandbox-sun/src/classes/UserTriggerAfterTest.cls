/**
 * Test class created for UserTriggerAfter class.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2012-09-06
 * 2012-09-06 - Created
 */
@isTest
private class UserTriggerAfterTest {
	static User testUser {
		get {
			if(testUser == null) {
				User u = [
					select 
						Alias,
						CommunityNickname,
						Email,
						EmailEncodingKey,
						FirstName,
						LastName,
						LocaleSidKey, 
						LanguageLocaleKey,
						TimeZoneSidKey
					from User 
					where Id = :UserInfo.getUserId()];
				testUser = new User(
					Alias=u.Alias,
					CommunityNickname=u.CommunityNickname+'test', 
					LocaleSidKey=u.LocaleSidKey,
					Email=u.Email+'.test',
					EmailEncodingKey=u.EmailEncodingKey, 
					FirstName = 'Me',
					LanguageLocaleKey=u.LanguageLocaleKey,
					LastName = 'Too',
					Legacy_Profile__c='bar',
					Legacy_Profile_Copy__c = null,
					Legacy_Role__c='foo',
					Legacy_Role_Copy__c = null,
					ProfileId = UserInfo.getProfileId(),
					Region__c = 'NA',
					TimeZoneSidKey=u.TimeZoneSidKey, 
					Username=u.Email+'.test',
					UserRoleId = UserInfo.getUserRoleId() );
			}
			return testUser;
		}
	}

	@isTest
	static void maintainGroupMembershipTest() {
		// insert user because we need an id
		insert testUser;
		// but clean up any group memberships added when the trigger ran on insert
		//  so we have a clean slate for testing the class method directly
		List<GroupMember> cleanUpMemberships = [SELECT Id
													FROM GroupMember
													WHERE UserOrGroupId = :testUser.Id
														AND GroupId IN :UserTriggerAfter.groupNameGroupId.values() 
													ORDER BY UserOrGroupId];
		delete cleanUpMemberships;
		
		// new user test
		UserTriggerAfter afterTrigger = new UserTriggerAfter(null,new List<User>{testUser});
		afterTrigger.maintainGroupMembership();
		List<GroupMember> testUserMemberships = [SELECT Id,UserOrGroupId,Group.DeveloperName 
													FROM GroupMember
													WHERE UserOrGroupId = :testUser.Id
														AND GroupId IN :UserTriggerAfter.groupNameGroupId.values() 
													ORDER BY UserOrGroupId];
		// user should only be in one public sales group
		System.assertEquals(1,testUserMemberships.size());
		// user should be in group that matches region
		System.assertEquals(UserTriggerAfter.groupNameGroupId.get('NA_Sales'),testUserMemberships[0].GroupId);
		
		// updated user test
		testUser.Region__c = 'EMEA';
		UserTriggerAfter.processTrigger(new Map<Id,User>{testUser.Id=>testUser},new List<User>{testUser});
		testUserMemberships = [SELECT Id,UserOrGroupId,Group.DeveloperName 
								FROM GroupMember
								WHERE UserOrGroupId = :testUser.Id
									AND GroupId IN :UserTriggerAfter.groupNameGroupId.values() 
								ORDER BY UserOrGroupId];
		// user should only be in one public sales group
		System.assertEquals(1,testUserMemberships.size());
		// user should be in group that matches region
		System.assertEquals(UserTriggerAfter.groupNameGroupId.get('EMEA_Sales'),testUserMemberships[0].GroupId);
		
		// updated user test
		testUser.Region__c = '';
		UserTriggerAfter.processTrigger(new Map<Id,User>{testUser.Id=>testUser},new List<User>{testUser});
		testUserMemberships = [SELECT Id,UserOrGroupId,Group.DeveloperName 
								FROM GroupMember
								WHERE UserOrGroupId = :testUser.Id
									AND GroupId IN :UserTriggerAfter.groupNameGroupId.values() 
								ORDER BY UserOrGroupId];
		// user should only be in one public sales group
		System.assertEquals(1,testUserMemberships.size());
		// user should be in group that matches region
		System.assertEquals(UserTriggerAfter.groupNameGroupId.get('NA_Sales'),testUserMemberships[0].GroupId);		
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('User_Before.',true);
		// update test
		insert testUser;
		UserTriggerAfter.processTrigger(new Map<Id,User>{testUser.Id=>testUser},new List<User>{testUser});
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('User_After.');
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('User_After.',new List<User>{testUser},true,false,true);
	}
}