trigger FundRequest_ValidateAccess on SFDC_MDF__c (before insert, before update) {
    //
    // Build a list of account ids
    //
    
    Set<Id> accountIds = new Set<Id>();
    
    for(SFDC_MDF__c fundRequest : Trigger.new)
        accountIds.add(fundRequest.Account_Master__c);

    //
    // Fetch all of the associated account team members with read/write permissions, and convert 
    // to an accountId set of matching permissions
    //
    
    Set<Id> writableAccountIds = new Set<Id>();
    String errorExtras = '';
    
    for(AccountTeamMember accountTeamMember : [
        select AccountId
          from AccountTeamMember
         where AccountId in :accountIds
           and UserId = :UserInfo.getUserId()
           and AccountAccessLevel in ('Edit', 'Full', 'All')
    ]) writableAccountIds.add(accountTeamMember.AccountId);
    
    for(AccountShare accountShare : [
        select AccountId
          from AccountShare
         where AccountId in :accountIds
           and UserOrGroupId = :UserInfo.getUserId()
           and AccountAccessLevel in ('Edit', 'Full', 'All')
    ]) writableAccountIds.add(accountShare.AccountId);
    
    //
    // Fetch all of the admin-level profiles
    //
    
    Map<Id, Profile> excludedProfileMap = new Map<Id, Profile>([
        select Name
          from Profile
         where Name = 'System Administrator'
            or Name = 'System Administrator - Level1'
            or Name = 'Sys Admin - No Expire Password'
            or Name = 'API Channel Load'
            or Name = 'API'
            or Name = 'Apex Deployment'
            or Name = 'Administrator - Level 1'
            or Name = 'Administrator - Level 2'
            or Name = 'Marketing'
            or Name = 'Administrator - Operations'
            or Name = 'Order Entry/Billing User'
    ]);
    
    //
    // For each fund request, assert that the executing user has permissions.
    //
    
    for (SFDC_MDF__c fundRequest : Trigger.new) {
    	
        // Do not validate PAR fundRequests
    	if(fundRequest.Partner_Registration__c != null)
    	   continue;
    	
        if (writableAccountIds.contains(fundRequest.Account_Master__c))
           continue;
        if (excludedProfileMap.containsKey(UserInfo.getProfileId()))
           continue;
           
        //
        //
        // Little tricky: if a list of approvers exists, then check to see whether the currently running
        // userId is in the list of approvers. What position doesn't really matter, since the SF system
        // has locked the record and will prevent anyone other than the current approver (or a sysadmin)
        // to update the record anyways. All we need to do is see if the current user is in the approval 
        // history list, and if so, allow them to proceed.
        //
        
        Set<Id> approverIds = new Set<Id>();
        
        try {
            for(ProcessInstanceHistory history : [
                select (select OriginalActorId from ProcessSteps where StepStatus != 'Started') 
                  from SFDC_MDF__c 
                 where Id = :fundRequest.Id
            ].ProcessSteps) approverIds.add(history.OriginalActorId);
        } catch (System.QueryException e) {
            // no fund request approvals available, nothing to do.
        } 
        
        if (approverIds.contains(UserInfo.getUserId()))
            continue;

        //
        // Add the error
        //
    
        fundRequest.addError(System.Label.FundRequest_ErrorMissingAccountTeamReadWrite);
    }

}