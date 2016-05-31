public with sharing class Contact_ConvertToUserBatch {
    private ApexPages.StandardController controller;
    private final String COL_CONTACT_ID = 'Id';
    
    public Contact_ConvertToUserBatch(ApexPages.StandardController controller) {
        this.controller = controller;
        this.attachment = new Attachment();
        this.resultList = new List<Result>();
    }
    
    public Attachment attachment {
        set;
        get;
    }
    
    public List<Result> resultList {
        set;
        get;
    }
    
    public Integer getTotalErrors() {
        Integer resultTotal = 0;
    
        for(Result result : resultList) {
            if (result.StatusMessage == 'Success')
                continue;
            if (result.StatusMessage.substring(0, 8) == 'Skipped')
                continue;
            resultTotal++;
        }
        
        return resultTotal;
    }
    
    public Integer getTotalSuccesses() {
        Integer resultTotal = 0;
    
        for(Result result : resultList) {
            if (result.StatusMessage != 'Success')
                continue;
            resultTotal ++;
        }
        
        return resultTotal;
    }
    
    public Integer getTotalSkipped() {
        Integer resultTotal = 0;
    
        for(Result result : resultList) {
            if (result.StatusMessage == 'Success')
                continue;
            if (result.StatusMessage.substring(0, 8) != 'Skipped')
                continue;
            resultTotal ++;
        }
        
        return resultTotal;
    }
    
    private String getValue(Map<String, String> referenceMap, String key) {
        return getValue(referenceMap, key, null);
    }

    private String getValue(Map<String, String> referenceMap, String key, String defaultValue) {
        return referenceMap != null && referenceMap.containsKey(key) ? referenceMap.get(key) : defaultValue;
    }

    public class Result {
        public User ContactUser {
            set;
            get;
        }
        
        public String ContactId {
            set;
            get;
        } 
        
        public String ContactAccountName {
            set;
            get;
        } 
        
        public String ContactFirstName {
            set;
            get;
        } 
        
        public String ContactLastName {
            set;
            get;
        } 
        
        public String ContactFederationId {
            set;
            get;
        } 
        
        public String StatusMessage {
            set;
            get;
        }
        
    }

    public PageReference execute() {
        try {
            List<Map<String, String>> processedCSV = CSVReader.process(attachment);
            Set<Id> contactIds = new Set<Id>();

            // Clear out any previous result set
            resultList.clear();

            // Clear out the attachment body
            attachment.Body = null;

            // Buld the list of contact ids
            for(Map<String, String> importingMap : processedCSV) {
                contactIds.add(importingMap.get(COL_CONTACT_ID));
            }

            // Fetch the contacts
            Map<Id, Contact> contactMap = new Map<Id, Contact>();
            for (Contact c : [
                select Account.Global_Region__c
                     , Account.Name
                     , FirstName
                     , LastName
                     , Email
                     , LoginName__c
                  from Contact
                 where Id in :contactIds
            ]) contactMap.put(c.Id, c);

            // Fetch duplicate federation IDs
            Map<String, User> existingFederationIdMap = new Map<String, User>();
//            Set<String> existingFederationIds = new Set<String>();
            
            for (User u : [
            		select	FederationIdentifier,
            				ContactId
            		  from	User
            		 where	IsActive = true
            ]) existingFederationIdMap.put(u.FederationIdentifier, u);

            /*
            for(Contact contact : contactMap.values()) {
                if (contact.LoginName__c == null)
                    continue;
                existingFederationIds.add(contact.LoginName__c);
            }
            
            for(User existingUser : [
                select FederationIdentifier
                  from User
                 where FederationIdentifier in :existingFederationIds
            ]) existingFederationIdMap.put(existingUser.FederationIdentifier, existingUser);
            */
            
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'existingFederationIds =' + existingFederationIds));
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'existingFederationIdMap =' + existingFederationIdMap));
            
            // Fetch the existing active users
            Map<Id, User> existingUserMap = new Map<Id, User>();
            
            for(User existingUser : [
               select ContactId
                 from User
                where ContactId in :contactIds
                  and IsActive = true
            ]) existingUserMap.put(existingUser.ContactId, existingUser);
            
            Set<String> existingUsernames = new Set<String>();
            for (User u : [
            		select	Username
            		  from	User
            	]) existingUsernames.add(u.Username);

            // Fetch the profiles
            Map<String, Id> profileIds = new Map<String, Id> {
                'NA' => [
                    select Id
                      from Profile
                     where Name = 'NA Partner Portal – Strategic License'
                ].Id,
                
                'EMEA' => [
                    select Id
                      from Profile
                     where Name = 'EMEA Partner Portal – Strategic License'
                ].Id,
                
                'APAC' => [
                    select Id
                      from Profile
                     where Name = 'APAC Partner Portal – Strategic License'
                ].Id,
                
                'LATAM' => [
                    select Id
                      from Profile
                     where Name = 'LATAM Partner Portal – Strategic License'
                ].Id,
                
                'ISV' => [
                    select Id
                      from Profile
                     where Name = 'Partner Portal – Strategic License - ISV'
                ].Id
            };
            
            // Build the conversion result list
            OnboardingExecuteConversion converter = new OnboardingExecuteConversion();
            List<User> userList = new List<User>();
            
            for(Map<String, String> importingMap : processedCSV) {
                Contact contact = contactMap.get(importingMap.get(COL_CONTACT_ID));
                

                if (contact == null)
                    continue;
                if (contact.Account == null)
                    continue;
                if (contact.Account.Global_Region__c == null)
                    continue;
                if (contact.LoginName__c == null)
                    continue;
                if (contact.FirstName == null)
                    continue;
                if (contact.LastName == null)
                    continue;
                if (contact.Email == null)
                    continue;
                if (profileIds.get(contact.Account.Global_Region__c) == null)
                    continue;
                if (existingFederationIdMap.containsKey(contact.LoginName__c)) {
                    continue;
                }
                if (existingUserMap.containsKey(contact.Id))
                    continue;
                boolean dup = false;
                for (Contact c : contactMap.values()) {
                	if (c != contact && c.LoginName__c == contact.LoginName__c) {
                		dup = true;
                		break;
                	}
                }
                if (dup) {
                	continue;
                }                
                User user = converter.getPartnerUser(contact);
                if (existingUsernames.contains(user.Username)) {
                	continue;
                }
                if (contact.Account.PartnerStatuses__c.equals('None')){
            		throw new DataRequiredException('Partner type not yet set, so we cannot create the user with the right profile');
            	}
            	if (contact.Account.PartnerStatuses__c.contains('ISV')){
            		user.ProfileId = profileIds.get('ISV');
            	} else {
                	user.ProfileId = profileIds.get(contact.Account.Global_Region__c);
            	}
            	userList.add(user);
                
            }

            insert userList;
            
            // Reverse map the user.ContactId back to the user
            Map<Id, User> userContactMap = new Map<Id, User>();
            
            for(User user : userList)
                userContactMap.put(user.ContactId, user);
            
            // Add in the results
            for(Map<String, String> importingMap : processedCSV) {
                Contact contact = contactMap.get(importingMap.get(COL_CONTACT_ID));
                
                Result result = new Result();
                result.ContactId = importingMap.get(COL_CONTACT_ID);
                result.StatusMessage = 'Success'; // default
                resultList.add(result);
                
                if (contact == null)
                    result.StatusMessage = 'Internal Error: Contact is null';
                else if (contact.Account == null)
                    result.StatusMessage = 'Error: Account is missing';
                else if (contact.Account.Global_Region__c == null)
                    result.StatusMessage = 'Error: Account - Global Region is blank';
                else if (contact.LoginName__c == null)
                    result.StatusMessage = 'Error: Federation ID is blank';
                else if (contact.FirstName == null)
                    result.StatusMessage = 'Error: First Name is blank';
                else if (contact.LastName == null)
                    result.StatusMessage = 'Error: Last Name is blank';
                else if (contact.Email == null)
                    result.StatusMessage = 'Error: Email is blank';
                else if (profileIds.get(contact.Account.Global_Region__c) == null)
                    result.StatusMessage = 'Error: No profile found for Global Region ' + contact.Account.Global_Region__c;
                else if (existingUserMap.containsKey(contact.Id))
                    result.StatusMessage = 'Skipping: Contact was already converted to partner user ID ' + existingUserMap.get(contact.Id).Id;
                else if (existingFederationIdMap.containsKey(contact.LoginName__c))
                    result.StatusMessage = 'Error: Federation ID is already associated with partner user ID ' + existingFederationIdMap.get(contact.LoginName__c).Id;
                else if (userContactMap.containsKey(contact.Id) == false)
                    result.StatusMessage = 'Internal Error: missing a related user object ??';
                else if (existingUsernames.contains(converter.getPartnerUserUsername(contact)))
                	result.StatusMessage = 'Duplicate Username';
                else
                    result.ContactUser = userContactMap.get(contact.Id);
                    
                for (Contact c : contactMap.values()) {
                	if (c != contact && c.LoginName__c == contact.LoginName__c) {
	                	result.StatusMessage = 'Error: Same Federation ID is assigned to Contacts ' + contact.Id + ' and ' + c.Id;
                		break;
                	}
                }

                // Additional information
                if (contact != null && contact.Account != null && contact.Account.Name != null)
                    result.ContactAccountName = contact.Account.Name;
                if (contact != null && contact.FirstName != null)
                    result.ContactFirstName = contact.FirstName;
                if (contact != null && contact.LastName != null)
                    result.ContactLastName = contact.LastName;
                if (contact != null && contact.LoginName__c != null)
                    result.ContactFederationId = contact.LoginName__c;
            }
        } catch (Exception pException) {
            ApexPages.addMessages(pException);
        }
        
        return null;
    }
}