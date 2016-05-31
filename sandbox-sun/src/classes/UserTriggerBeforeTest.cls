/**
 * Test class created for UserTriggerBefore class.
 *
 * @author Bill Riemers <briemers@redhat.com>
 * @version 2012-06-02
 *
 * 2012-06-02 - Created for SMR
 */
@isTest
private class UserTriggerBeforeTest {
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
	static void copyLegacyTest() {
		UserTriggerBefore beforeTrigger = new UserTriggerBefore(null,new List<User>{testUser});
		beforeTrigger.copyLegacy();
		System.assertEquals(testUser.Legacy_Profile__c,testUser.Legacy_Profile_Copy__c);
		System.assertEquals(testUser.Legacy_Role__c,testUser.Legacy_Role_Copy__c);
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('User_Before.',true);
		// update test
		UserTriggerBefore.processTrigger(new Map<Id,User>{null=>testUser},new List<User>{testUser});
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('User_Before.');
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('User_Before.',new List<User>{testUser},true,false,true);
	}
}