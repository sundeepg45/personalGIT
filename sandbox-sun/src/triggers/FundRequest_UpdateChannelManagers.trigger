trigger FundRequest_UpdateChannelManagers on SFDC_MDF__c (before insert, before update) {       
    Set<Id> accountIds = new Set<Id>();
        
    for(SFDC_MDF__c fundRequest : Trigger.new)
        accountIds.add(fundRequest.Account_Master__c);

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
    Map<ID,Account> acctOwners = new Map<ID,Account>([select Id, OwnerId from Account where Id in :accountIds]);
    
    for(SFDC_MDF__c fundRequest : Trigger.new) {
        // Clear out old roles
        fundRequest.Channel_Account_Manager__c = null;
        fundRequest.Channel_Marketing_Manager_Country__c = null;
        fundRequest.Inside_Channel_Account_Manager__c = null;
        fundRequest.Marketing_Program_Manager__c = null;
        fundRequest.Partner_Manager__c = null;

        for(AccountTeamMember accountTeamMember : accountTeamList) {
            if (fundRequest.Account_Master__c != accountTeamMember.AccountId)
                continue;
                
            if (accountTeamMember.TeamMemberRole == 'Channel Account Manager')
                fundRequest.Channel_Account_Manager__c = accountTeamMember.UserId;
            if (accountTeamMember.TeamMemberRole == 'Inside Channel Account Manager')
                fundRequest.Inside_Channel_Account_Manager__c = accountTeamMember.UserId;
            if (accountTeamMember.TeamMemberRole == 'Marketing Program Manager')
                fundRequest.Marketing_Program_Manager__c = accountTeamMember.UserId;

            // EMEA fields
            if (accountTeamMember.TeamMemberRole == 'Channel Marketing Manager - Country')
                fundRequest.Channel_Marketing_Manager_Country__c = accountTeamMember.UserId;
            if (accountTeamMember.TeamMemberRole == 'Partner Manager')
                fundRequest.Partner_Manager__c = accountTeamMember.UserId; 
                
            fundRequest.Script_Last_Run_Date__c = Date.today();
            
            if (fundRequest.Channel_Account_Manager__c == null) {
            	// set to account owner
            	fundRequest.Channel_Account_Manager__c = acctOwners.get(fundRequest.Account_Master__c).OwnerId;
            }
        }
    }
}