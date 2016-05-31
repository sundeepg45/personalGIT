trigger Lead_OwnerReassignment on Lead (before update) {

    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

    if (!ThreadLock.lock('Lead_OwnerReassignment')) {
//  if (ThreadLock.isExecuting) {
        System.debug('*****[debug]***** lock detected!');
        return;
    }
//  ThreadLock.isExecuting = true;
    Set<Id> userIdList = new Set<Id>();
    for (Lead lead : Trigger.new) {
        userIdList.add(lead.OwnerId);
    }
    RecordType[] rtypes = null;
    Map<Id,Contact> contacts = null;
    Map<Id,User> users = null;
    Map<Id,AccountTeamMember[]> teamMap = null;
    Map<Id,Account> userAccounts = null;
    for (Lead lead : Trigger.new) {
        String[] emailIdList = new List<String>();
        Lead orig = Trigger.oldMap.get(lead.Id);
        if (orig.OwnerId != lead.OwnerId) {
            System.debug('*****[debug]***** changing owner to ' + lead.OwnerId + ' of lead ' + lead.Id);
            //
            // found at least one, initialize for processing if not already (saves a soql query)
            //
            if (users == null) {
                users = new Map<Id,User>([select Id, AccountId, Name, Contact.Email from User where Id in :userIdList]);       
                if (users == null || users.size() == 0) {
                    return;
                }
                Set<Id> userAccountIds = new Set<Id>();
                for (User u : users.values()) {
                    System.debug('*****[debug]***** user: ' + u.Id + ', accountId:' + u.AccountId + ', contactId=' + u.ContactId);
                    userAccountIds.add(u.AccountId);
                }
                userAccounts = new Map<Id,Account>([select Id, isPartner, Owner.Email, Name from Account where Id in :userAccountIds]);

                // get list of account team memberships for determining email receivers
                AccountTeamMember[] acctteam = [
                    select  AccountId, User.Email
                    from    AccountTeamMember
                    where   AccountId in :userAccountIds
                ];
                //
                // build out a map of Account ID keys and list of account team member records for each
                //
                teamMap = new Map<ID,AccountTeamMember[]>();
                for (AccountTeamMember entry : acctteam) {
                    if (teamMap.containsKey(entry.AccountId)) {
                        AccountTeamMember[] memberlist = teamMap.get(entry.AccountId);
                        memberlist.add(entry);
                    }
                    else {
                        AccountTeamMember[] memberlist = new List<AccountTeamMember>();
                        teamMap.put(entry.AccountId, memberlist);
                        memberlist.add(entry);
                    }
                }
            }
            //
            // done inline initializing, back to normal processing
            //

            if (users != null && userAccounts != null) {
                User owner = users.get(lead.OwnerId);
                if (owner != null) {
                    Account ownerAccount = userAccounts.get(owner.AccountId);
                    if (Trigger.isBefore) {
                        if (ownerAccount != null && ownerAccount.isPartner) {
                            lead.Assigned_By__c = UserInfo.getUserId();
                            lead.Is_Partner_Owned_Lead__c = true;
                        }
                    }
                    
                    if (teamMap.containsKey(owner.AccountId)) {
                        Boolean found = false;
                        // send email to each team member
                        AccountTeamMember[] members = teamMap.get(ownerAccount.Id);
                        for (AccountTeamMember member : members) {
                            if (member.User.Email != null) {
                                emailIdList.add(member.User.Email);
                            }
                        }
                        System.debug('*****[debug]***** emailing account team');
                    }
                    else {
                        // send to account owner only
                        if (ownerAccount != null && ownerAccount.Owner != null && ownerAccount.Owner.Email != null) {
                            emailIdList.add(ownerAccount.Owner.Email);
                            System.debug('*****[debug]***** emailing account owner ' + ownerAccount.Owner.Email);
                        }
                    }
                }
            }
        }

        if (!emailIdList.isEmpty()) {

            if (rtypes == null) {
                rtypes = [select Id from RecordType where Name in ('NA Sales Lead')]; //,'EMEA Sales Lead','APAC Sales Lead','LATAM Sales Lead')]; 
            }
            //
            // check that this lead is in the allowable recordtypes for emailing
            //
            Boolean found = false;
            for (RecordType atype : rtypes) {
                if (lead.RecordTypeId == atype.Id) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                // don't send email for this recordtype
                continue;
            }

            if (lead.Email == null) {
                lead.addError('An email address is required for sales lead reassignment');
                continue;
            }
            User owner = users.get(lead.OwnerId);

            OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
//          EmailTemplate tpl = [select Id from EmailTemplate where DeveloperName = 'Lead_Passed_to_Partner'];
            Messaging.SingleEmailMessage[] messagelist = new List<Messaging.SingleEmailMessage>();
            ID accountId = users.get(lead.OwnerId).AccountId;
            String template = System.Label.New_Partner_Lead_Notification;
            for (String contactId : emailIdList) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] tmp = new List<String>();
                tmp.add(contactId);
                mail.setSubject('New Lead Assigned to Partner');
                String body = template;
                Account acct = userAccounts.get(accountId);
                body = body.replace('{!relatedTo.Name}', acct.Name);
                body = body.replace('{!recipient.Owner.Name}', owner.Name);
                mail.setPlainTextBody(body);
                mail.setToAddresses(tmp);
//                  mail.setTargetObjectId(lead.Id);
//                  mail.setWhatId(accountId);
//                  mail.setTemplateId(tpl.Id);
                mail.setReplyTo('noreply@redhat.com');
                mail.setOrgWideEmailAddressId(owe.id);
                mail.saveAsActivity = FALSE;
                messagelist.add(mail);
            }
            Messaging.sendEmail(messagelist);
            System.debug('*****[debug]***** send emails: ' + messagelist.size());
        }
    }


}