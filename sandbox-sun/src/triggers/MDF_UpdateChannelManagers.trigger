trigger MDF_UpdateChannelManagers on SFDC_Budget__c (before insert, before update) {       
    Set<Id> accountIds = new Set<Id>();       

    // Prepare a list of accounts
    for(SFDC_Budget__c mdf : Trigger.new)
        accountIds.add(mdf.Account_master__c);

    //
    // Build a map of the accountId to accountTeamMember object
    //    
    Map<Id, AccountTeamMember> accountTeamMap = new Map<Id, AccountTeamMember>();

    List<AccountTeamMember> accountTeamList = [
        select AccountId
             , TeamMemberRole
             , UserId 
             , User.Email
             , User.Phone
             , User.MobilePhone
             , User.Title
          from AccountTeamMember 
         where AccountId in :accountIds 
           and TeamMemberRole in ('Channel Account Manager',
                                  'Channel Marketing Manager - Country',
                                  'Inside Channel Account Manager',
                                  'Marketing Program Manager',
                                  'Partner Manager')
    ];
    
    // Update each MDF
    for(SFDC_Budget__c mdf : Trigger.new) {
    	// Clear out old roles
    	mdf.Channel_Account_Manager__c = null;
        mdf.Channel_Marketing_Manager_Country__c = null;
    	mdf.Inside_Channel_Account_Manager__c = null;
    	mdf.Marketing_Program_Manager__c = null;
    	mdf.Partner_Manager__c = null;

    	system.debug('mdf.Name: ' + mdf.Name);
        system.debug('mdf.Id: ' + mdf.Id);
        system.debug('accountTeamList.size(): ' + accountTeamList.size());

    	// Add current roles
        for(AccountTeamMember accountTeamMember : accountTeamList) {
            system.debug('accountTeamMember.AccountId: ' + accountTeamMember.AccountId);
            system.debug('accountTeamMember.TeamMemberRole: ' + accountTeamMember.TeamMemberRole);

            if (accountTeamMember.AccountId == mdf.Account_master__c) {
                if (accountTeamMember.TeamMemberRole == 'Channel Account Manager')
                    mdf.Channel_Account_Manager__c = accountTeamMember.UserId;
                if (accountTeamMember.TeamMemberRole == 'Inside Channel Account Manager')
                    mdf.Inside_Channel_Account_Manager__c = accountTeamMember.UserId;

                if (accountTeamMember.TeamMemberRole == 'Marketing Program Manager') {
                    mdf.Marketing_Program_Manager__c = accountTeamMember.UserId;
                    mdf.Marketing_Program_Manager_Email__c = accountTeamMember.User.Email;
                    mdf.Marketing_Program_Manager_Mobile__c = accountTeamMember.User.MobilePhone;
                    mdf.Marketing_Program_Manager_Phone__c = accountTeamMember.User.Phone;
                    mdf.Marketing_Program_Manager_Title__c = accountTeamMember.User.Title;
                }

                // EMEA team member roles
                if (accountTeamMember.TeamMemberRole == 'Channel Marketing Manager - Country')
                    mdf.Channel_Marketing_Manager_Country__c = accountTeamMember.UserId;
                if (accountTeamMember.TeamMemberRole == 'Partner Manager')
                    mdf.Partner_Manager__c = accountTeamMember.UserId;
                
                
                mdf.Script_Last_Run_Date__c = system.today();
            }
        }
    }
}