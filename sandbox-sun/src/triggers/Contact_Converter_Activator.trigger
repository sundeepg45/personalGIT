trigger Contact_Converter_Activator on Contact_Converter__c (before insert) {

            Set<Id> contactids = new Set<Id>();
            for (Contact_Converter__c cvt : Trigger.new) {
                contactids.add(cvt.ContactId__c);
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
                 where Id in :contactids
            ]) contactMap.put(c.Id, c);

            // Fetch duplicate federation IDs
            Map<String, User> existingFederationIdMap = new Map<String, User>();

            Set<String> currentFedIds = new Set<String>();
            for (Contact c : contactMap.values()) {
                if (c.LoginName__c != null && c.LoginName__c.length() > 0) {
                    currentFedIds.add(c.LoginName__c);
                }
            }
            if (currentFedIds.size() > 0) {
                for (User u : [
                        select  FederationIdentifier,
                                ContactId
                          from  User
                         where  IsActive = true
                           and  FederationIdentifier in :currentFedIds
                ]) existingFederationIdMap.put(u.FederationIdentifier, u);
            }
           
            // Fetch the existing active users
            Map<Id, User> existingUserMap = new Map<Id, User>();
            
            for(User existingUser : [
               select ContactId
                 from User
                where ContactId in :contactIds
                  and IsActive = true
            ]) existingUserMap.put(existingUser.ContactId, existingUser);

/*            
            Set<String> existingUsernames = new Set<String>();
            for (User u : [
                    select  Username
                      from  User
                ]) existingUsernames.add(u.Username);
*/

            // Fetch the profiles
            Map<String, Id> profileIds = new Map<String, Id>();
            for (Profile p : [
                select  Id, Name
                  from  Profile
                 where  name like '%Partner Portal – Strategic License'
            ])
            {
                if (p.Name.startsWith('NA')) {
                    profileIds.put('NA', p.Id);
                }
                else
                if (p.Name.startsWith('EMEA')) {
                    profileIds.put('EMEA', p.Id);
                }
                else
                if (p.Name.startsWith('APAC')) {
                    profileIds.put('APAC', p.Id);
                }
                else
                if (p.Name.startsWith('LATAM')) {
                    profileIds.put('LATAM', p.Id);
                }
            }
            OnboardingExecuteConversion converter = new OnboardingExecuteConversion();
            
            for (Contact_Converter__c cvt : Trigger.new) {

                Contact contact = contactMap.get(cvt.ContactId__c);

                try {
                    cvt.UserActivationResult__c = 'Success'; // default
                    
                    if (contact == null) {
                        cvt.UserActivationResult__c = 'Internal Error: Contact is null';
                        continue;
                    }
                    else if (contact.Account == null) {
                        cvt.UserActivationResult__c = 'Error: Account is missing';
                        continue;
                    }
                    else if (contact.Account.Global_Region__c == null) {
                        cvt.UserActivationResult__c = 'Error: Account - Global Region is blank';
                        continue;
                    }
                    else if (contact.LoginName__c == null) {
                        cvt.UserActivationResult__c = 'Error: Federation ID is blank';
                        continue;
                    }
                    else if (contact.FirstName == null) {
                        cvt.UserActivationResult__c = 'Error: First Name is blank';
                        continue;
                    }
                    else if (contact.LastName == null) {
                        cvt.UserActivationResult__c = 'Error: Last Name is blank';
                        continue;
                    }
                    else if (contact.Email == null) {
                        cvt.UserActivationResult__c = 'Error: Email is blank';
                        continue;
                    }
                    else if (profileIds.get(contact.Account.Global_Region__c) == null) {
                        cvt.UserActivationResult__c = 'Error: No profile found for Global Region ' + contact.Account.Global_Region__c;
                        continue;
                    }
                    else if (existingUserMap.containsKey(contact.Id)) {
                        cvt.UserActivationResult__c = 'Skipping: Contact was already converted to partner user ID ' + existingUserMap.get(contact.Id).Id;
                        continue;
                    }
                    else if (existingFederationIdMap.containsKey(contact.LoginName__c)) {
                        cvt.UserActivationResult__c = 'Error: Federation ID is already associated with partner user ID ' + existingFederationIdMap.get(contact.LoginName__c).Id;
                        continue;
                    }
                    /*
                    else if (existingUsernames.contains(converter.getPartnerUserUsername(contact))) {
                        cvt.UserActivationResult__c = 'Duplicate Username';
                        continue;
                    }
                    */
                     
                    boolean err = false;   
                    for (Contact c : contactMap.values()) {
                        if (c != contact && c.LoginName__c == contact.LoginName__c) {
                            cvt.UserActivationResult__c = 'Error: Same Federation ID is assigned to Contacts ' + contact.Id + ' and ' + c.Id;
                            err = true;
                            break;
                        }
                    }
                    if (err) {
                        continue;
                    }
    
                    System.debug('Converting contact ' + contact.FirstName + ' ' + contact.LastName);
                    User user = converter.getPartnerUser(contact);
                    System.debug('Creating user with user name ' + user.username);
                    /*
                    if (existingUsernames.contains(user.Username)) {
                        cvt.UserActivationResult__c = 'Error: Username already exists: ' + user.Username;
                        continue;
                    }
                    */
                    user.ProfileId = profileIds.get(contact.Account.Global_Region__c);
                    insert user;
                    
                    cvt.UserId__c = user.Id;
                }
                catch (Exception pException) {
                    QueryException qe;
                    cvt.UserActivationResult__c = pException.getMessage();
                }
            }
    
}