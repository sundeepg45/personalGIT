trigger FundClaim_UpdateChannelManagers on SFDC_MDF_Claim__c (before insert, before update) {
    Set<Id> accountIds = new Set<Id>();

    for(SFDC_MDF_Claim__c fundClaim : Trigger.new)
        accountIds.add(fundClaim.Account__c);

    //
    // Build a map of the accountId to accountTeamMember object
    //
    Map<Id, AccountTeamMember> accountTeamMap = new Map<Id, AccountTeamMember>();

    List<AccountTeamMember> accountTeamList = [
        select AccountId
             , TeamMemberRole
             , UserId
          from AccountTeamMember
         where AccountId in :accountIds
           and TeamMemberRole in ('Channel Account Manager',
                                  'Channel Marketing Manager - Country',
                                  'Inside Channel Account Manager',
                                  'Marketing Program Manager',
                                  'Partner Manager')
    ];

    for(SFDC_MDF_Claim__c fundClaim : Trigger.new) {
        // Clear out old roles
        fundClaim.Channel_Marketing_Manager_Country__c = null;
        fundClaim.Marketing_Program_Manager__c = null;
        fundClaim.Partner_Manager__c = null;

        for(AccountTeamMember accountTeamMember : accountTeamList) {
            if (fundClaim.Account__c != accountTeamMember.AccountId)
                continue;

            if (accountTeamMember.TeamMemberRole == 'Marketing Program Manager')
                fundClaim.Marketing_Program_Manager__c = accountTeamMember.UserId;

            // EMEA fields
            if (accountTeamMember.TeamMemberRole == 'Channel Marketing Manager - Country')
                fundClaim.Channel_Marketing_Manager_Country__c = accountTeamMember.UserId;
            if (accountTeamMember.TeamMemberRole == 'Partner Manager')
                fundClaim.Partner_Manager__c = accountTeamMember.UserId;

            //populate CAM as requested: US76912 /[RH-00428858] - Kiran 1/11/16
            if (accountTeamMember.TeamMemberRole == 'Channel Account Manager')
                fundClaim.Channel_Account_Manager__c = accountTeamMember.UserId;

            fundClaim.Script_Last_Run_Date__c = Date.today();
        }
    }
}