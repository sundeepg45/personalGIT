public without sharing class TeamingAgreement_AccountTeam {
	
	@isTest
	public static void testAddTeamMember(){
		Account acct = PartnerTestUtils.quickGenericAccountSetup('AccountTeamTriggerTest');
		User adminUser = PartnerTestUtils.getAdminUser();
		TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
		System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
		
		List<User> salesUsers = [select Id from User where Profile.Id = :salesUserProfileTesting.Id__c and IsActive = true limit 4];
		
    	Teaming_Agreement__c ta = new Teaming_Agreement__c(Partner_Name__c = acct.Id, Channel_Account_Manager__c = adminUser.Id, Red_Hat_Sales_Rep__c = salesUsers[0].Id, Regional_Sales_Manager__c = salesUsers[1].Id);

		List<AccountTeamMember> atmList = [select Id, UserId, AccountId from AccountTeamMember where AccountId = :acct.Id];
		Integer befSize = atmList.size();

    	insert ta;
		
		atmList = [select Id, UserId, AccountId from AccountTeamMember where AccountId = :acct.Id];
		System.assertEquals(befSize + 2, atmList.size());
		
		ta.Red_Hat_Sales_Rep__c = salesUsers[2].Id;
		ta.Regional_Sales_Manager__c = salesUsers[3].Id;
		update ta;

		atmList = [select Id, UserId, AccountId from AccountTeamMember where AccountId = :acct.Id];
		System.assertEquals(befSize + 4, atmList.size());

		ta.Red_Hat_Sales_Rep__c = salesUsers[1].Id;
		update ta;

		atmList = [select Id, UserId, AccountId from AccountTeamMember where AccountId = :acct.Id];
		System.assertEquals(befSize + 4, atmList.size());
	}
}