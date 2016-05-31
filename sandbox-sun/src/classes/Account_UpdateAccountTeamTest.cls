@IsTest
private class Account_UpdateAccountTeamTest {
	public static final String TEAM_MEMBER_ROLE = 'Apex Unit Test';
	
    public static final Map<String, String> DEFAULT_PARAMS = new Map<String, String> {
    	'Account.RecordType.Name' => 'NA Partner',
        'Account.Global_Region__c' => 'NA',
        'Account.Subregion__c' => 'Northeast',
        'AccountTeamRule__c.AccountAccessLevel__c' => 'Read/Write',
        'AccountTeamRule__c.CaseAccessLevel__c' => 'Private',
        'AccountTeamRule__c.ContactAccessLevel__c' => 'Private',
        'AccountTeamRule__c.OpportunityAccessLevel__c' => 'Private',
        'AccountTeamRule__c.TeamMemberRole__c' => 'Apex Unit Test',
        'AccountTeamRule__c.User__c' => UserInfo.getUserId(),
    	'PartnerStatus__c.PartnerTier__r.HierarchyKey__c' => 'PARTNER_TIER.READY',
        'PartnerStatus__c.PartnerType__r.HierarchyKey__c' => 'PARTNER_TYPE.ISV'
    };
    
    /**
     * Test that matching works.
     */	
    public static void testMatch(Map<String, String> params) {
        Account account = new Account();
        account.Name = 'Account';
        account.RecordTypeId = [
            select Id
              from RecordType
             where SObjectType = 'Account'
               and Name = :params.get('Account.RecordType.Name')
        ].Id;
        insert account;

        // test the rollup has no partner statuses
        system.assertEquals('None', [
            select PartnerStatuses__c
              from Account
             where Id = :account.Id
        ].PartnerStatuses__c);

        // Create the first partner status.
        PartnerStatus__c partnerStatus1 = new PartnerStatus__c();
        partnerStatus1.ActivationDate__c = Date.today();
        partnerStatus1.ApprovalStatus__c = 'Approved';
        partnerStatus1.ExpirationDate__c = Date.today().addDays(1);
        partnerStatus1.Partner__c = account.Id;

        partnerStatus1.PartnerTier__c = [
            select Id
              from Classification__c
             where HierarchyKey__c = 'PARTNER_TIER.READY'
             limit 1
        ].Id;

        partnerStatus1.PartnerType__c = [
            select Id
              from Classification__c
             where HierarchyKey__c = 'PARTNER_TYPE.ISV'
             limit 1
        ].Id;
        insert partnerStatus1;

        // confirm the status is active
        system.assertEquals('Active', [
            select ActivationStatus__c
              from PartnerStatus__c
             where Id = :partnerStatus1.Id
        ].ActivationStatus__c);

        // confirm our user isn't in the account team
        system.assertEquals(0, [
            select COUNT()
              from AccountTeamMember
             where UserId = :UserInfo.getUserId()
               and AccountId = :account.Id
               and TeamMemberRole = :TEAM_MEMBER_ROLE
        ]);

        // Add the new rule
        AccountTeamRule__c accountTeamRule = new AccountTeamRule__c();
        accountTeamRule.AccountAccessLevel__c = 'Read/Write';
        accountTeamRule.CaseAccessLevel__c = 'Private';
        accountTeamRule.ContactAccessLevel__c = 'Private';
        accountTeamRule.OpportunityAccessLevel__c = 'Private';
        accountTeamRule.TeamMemberRole__c = TEAM_MEMBER_ROLE;
        accountTeamRule.User__c = UserInfo.getUserId();
        accountTeamRule.IsActive__c = true;
        insert accountTeamRule;

        // update the account - this will recalculate the account team members
        update account;

        // reassert team member
        system.assertEquals(1, [
            select COUNT()
              from AccountTeamMember
             where UserId = :UserInfo.getUserId()
               and AccountId = :account.Id
               and TeamMemberRole = :TEAM_MEMBER_ROLE
        ]);
    }

    /** 
     * Test that restricting the rule to the matching partner status / partner tier works.
     */
    public static testmethod void testMatchPartnerType() {
    	
    }

}