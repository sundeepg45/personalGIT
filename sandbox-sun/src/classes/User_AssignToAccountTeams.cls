public with sharing class User_AssignToAccountTeams {
    public User_AssignToAccountTeams() {
        attachment = new Attachment();
        task = new Task();
    }

    public Task task {
        set;
        get;
    }

    public Attachment attachment {
        set;
        get;
    }
    
    public PageReference executeAssignment() {
        try {
            Map<Id, AccountShare> accountShareList = new Map<Id, AccountShare>();
            Map<Id, AccountTeamMember> accountTeamMemberList = new Map<Id, AccountTeamMember>();

            for(Map<String, String> importingMap : CSVReader.process(attachment)) {
                AccountShare accountShare = new AccountShare();
                accountShare.AccountId = getValue(importingMap, 'AccountId');
                accountShare.UserOrGroupId = attachment.OwnerId;
                accountShare.AccountAccessLevel = getValue(importingMap, 'AccountAccessLevel', 'Edit');
                accountShare.OpportunityAccessLevel = getValue(importingMap, 'OpportunityAccessLevel', 'Edit');
                accountShare.CaseAccessLevel = getValue(importingMap, 'CaseAccessLevel', 'Edit');
                accountShareList.put(getValue(importingMap, 'AccountId'), accountShare);
                
                AccountTeamMember accountTeamMember = new AccountTeamMember();
                accountTeamMember.AccountId = getValue(importingMap, 'AccountId');
                accountTeamMember.UserId = attachment.OwnerId;
                accountTeamMember.TeamMemberRole = getValue(importingMap, 'TeamMemberRole', 'Partner Relationship Manager');
                accountTeamMemberList.put(getValue(importingMap, 'AccountId'), accountTeamMember);
            }
            
            insert accountShareList.values();
            insert accountTeamMemberList.values();
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Changes saved.'));
        } catch (Exception pException) {
            ApexPages.addMessages(pException);
        }
        
        return null;
    }
    
    private String getValue(Map<String, String> referenceMap, String key) {
        return getValue(referenceMap, key, null);
    }

    private String getValue(Map<String, String> referenceMap, String key, String defaultValue) {
        return referenceMap != null && referenceMap.containsKey(key) ? referenceMap.get(key) : defaultValue;
    }
}