public without sharing class AccountTeamRulesUtils {
    static Map<String, String> ACCESS_LEVELS = new Map<String, String> {
        'Private' => 'None',
        'Read Only' => 'Read',
        'Read/Write' => 'Edit',
        'Owner' => 'Full'
    };

    static public void updateRules(Account[] accountList, PartnerStatus__c[] partnerStatusListAll) {
        for (Account acct : accountList) {
            if (acct.HasAccountTeamAssigned__c) {
                //
                // already assigned, don't bother
                //
                continue;
            }

            PartnerStatus__c[] partnerStatusList = new List<PartnerStatus__c>();
            for (PartnerStatus__c ps : partnerStatusListAll) {
                if (ps.Partner__c == acct.Id) {
                    partnerStatusList.add(ps);
                }               
            }
            
            //
            // Find all of the current mapping rules
            //
        
            List<AccountTeamRule__c> accountTeamRuleList = [
                select AccountAccessLevel__c
                     , CaseAccessLevel__c
                     , ContactAccessLevel__c
                     , OpportunityAccessLevel__c
                     , TeamMemberRole__c
                     , GlobalRegion__c
                     , Subregion__c
                     , Country__r.Abbreviation__c
                     , PartnerTier__c
                     , PartnerType__c
                     , User__c
                  from AccountTeamRule__c
                 where IsActive__c = true
            ];

            //
            // Loop over partner statuses, then account rules, and add sharing and team membership as needed.
            //
        
            List<AccountShare> accountShareList = new List<AccountShare>();
            List<AccountTeamMember> accountTeamMemberList = new List<AccountTeamMember>();
            Set<Id> uniqueAcctIds = new Set<Id>();
        
            for(PartnerStatus__c ps : partnerStatusList) {
                if (ps.Partner__r == null)
                    continue;
            
                Account act = null;
                for(AccountTeamRule__c r : accountTeamRuleList) {
                    if (null != r.GlobalRegion__c && r.GlobalRegion__c != ps.Partner__r.Global_Region__c)
                        continue;
                    if (null != r.Subregion__c && r.Subregion__c != ps.Partner__r.Subregion__c)
                        continue;
                    if (null != r.Country__r.Abbreviation__c && r.Country__r.Abbreviation__c != ps.Partner__r.BillingCountry)
                        continue;
                    if (null != r.PartnerType__c && r.PartnerType__c != ps.PartnerType__c)
                        continue;
                    if (null != r.PartnerTier__c && r.PartnerTier__c != ps.PartnerTier__c)
                        continue;
                               
                    // HACK: Convert any sharing permissions defined as 'Owner' into 'Read/Write' for the
                    // purposes of this section. The logic behind this is that the value of 'Owner' 
                    // is only used (at the account access level) to flag those users eligible for
                    // assignment as the account owner. We can't actually create a sharing rule with the
                    // access defined as owner, so it has to become read/write instead.
                     
                    if (r.AccountAccessLevel__c == 'Owner')
                        r.AccountAccessLevel__c = 'Read/Write';
                    
                    // Add the team member 
                    if (null != r.User__c)
                        accountTeamMemberList.add(new AccountTeamMember(
                            AccountId = ps.Partner__r.Id,
                            TeamMemberRole = r.TeamMemberRole__c,
                            UserId = r.User__c
                        ));
        
                    // Add the account share (only for non-owners)
                    if (null != r.User__c && r.User__c != ps.Partner__r.OwnerId)
                        accountShareList.add(new AccountShare(
                            AccountId = ps.Partner__r.Id,
                            AccountAccessLevel = ACCESS_LEVELS.get(r.AccountAccessLevel__c),
                            CaseAccessLevel = ACCESS_LEVELS.get(r.CaseAccessLevel__c),
                            OpportunityAccessLevel = ACCESS_LEVELS.get(r.OpportunityAccessLevel__c),
                            UserOrGroupId = r.User__c
                        ));
        
                    //Mark this account as processed
                    if (!uniqueAcctIds.contains(ps.Partner__r.Id))
                    {
//                      act = new Account(Id = ps.Partner__r.Id);
//                      act.HasAccountTeamAssigned__c = true;
                        acct.HasAccountTeamAssigned__c = true;
//                      accountList.add(act);
                        uniqueAcctIds.add(ps.Partner__r.Id);
                    }
                        
                }
            }
            
            insert accountTeamMemberList;
            insert accountShareList;
        }
    }
    
    //
    // On exit, affected Account objects will have HasAccountTeamAssigned__c set to true and must be updated by caller to save on SOQL
    //
}