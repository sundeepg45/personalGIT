/*
trigger User_SetPartnerProfile on User (before insert) {
    
    for (User u : trigger.new){
        if (UserInfo.getUserName().startswith('partnercenter_migration@redhat.com') && !Test.isRunningTest()){
            Contact c = [select Account.IsPartner, Account.Global_Region__c, Account.Finder_Partner_Type__c from Contact where Id = :u.ContactId]; //:u.Contact_Id__c];
            // We have to put this weird check in here to make sure we can run the unit tests as the migration user from StratoSource
            if (c.Account.IsPartner){
                u.profile = PartnerUtil.onboardingProfile(c.Account.Global_Region__c, c.Account.Finder_Partner_Type__c); //c.Account.Finder_Partner_Type__r.HierarchyKey__c);
                u.profileId = u.profile.Id;
                u.CommunityNickname = '';
            }
        }
    }    
}
*/


//Attempt to bulkify by a noob :)

trigger User_SetPartnerProfile on User (before insert) {
    
    List<Id> goOverThese = new List<Id>();
    List<Contact> contactsForMap = new List<Contact>();
    Map<Id,Contact> contactMap = new Map<Id,Contact>();
    
    for (Integer i = 0; Trigger.new.size() > i; i++) {
    	goOverThese.add(Trigger.new[i].ContactId);
    }
    
    if (UserInfo.getUserName().startswith('partnercenter_migration@redhat.com') && !Test.isRunningTest()) {
    
        contactsForMap.add([SELECT Id, AccountId, Account.Global_Region__c, Account.Finder_Partner_Type__r.HierarchyKey__c, Account.isPartner FROM Contact WHERE Id IN : goOverThese]);
        
        for (Integer i = 0; Trigger.new.size() >  i; i++) {
            if (Trigger.new[i].ContactId == contactsForMap.get(i).id) {
            	contactMap.put(Trigger.new[i].id, contactsForMap.get(i));
            } else {
            	System.debug('User.ContactId / Contact mismatch for User: ' + Trigger.new[i].id + ' ' + Trigger.new[i].Name + ' and Contact: ' + contactsForMap.get(i));
            }
        }
    	System.debug('&&&&&What kind of account is this?:');
        for (User usr : Trigger.new){
            System.debug('&&&&&What kind of account is this?: ' + contactMap.get(usr.Id).Account.Global_Region__c + ' Account Id: ' + contactMap.get(usr.Id).Account.Finder_Partner_Type__r.HierarchyKey__c);
            // We have to put this weird check in here to make sure we can run the unit tests as the migration user from StratoSource
            if (contactMap.get(usr.Id).Account.isPartner) {
                usr.profile = PartnerUtil.onboardingProfile(contactMap.get(usr.Id).Account.Global_Region__c, contactMap.get(usr.Id).Account.Finder_Partner_Type__r.HierarchyKey__c);
                usr.profileId = usr.profile.Id;
                usr.CommunityNickname = '';
                System.debug('Profile ID and Name: ' + usr.profile.Id + ' ' + usr.profile.Name);
            }
        }   
    }
}