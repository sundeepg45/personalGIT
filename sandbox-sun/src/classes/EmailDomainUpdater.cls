global class EmailDomainUpdater implements Database.Batchable<sObject>, Database.Stateful {
    
    private string query; 
    global final string logTag = '[EmailDomainUpdater]';
    //global List<Account> accountsToUpdate;
    global Integer successes;
    global Integer failures;
    
    // Map of free email domains
    private Map<String,String> freeEmailDomains = new Map<String,String>{ 
        'hotmail.com' => 'hotmail',
        'outlook.com' => 'outlook',
        'gmail.com' => 'gmail',
        'yahoo.com' => 'yahoo',
        'aol.com'  => 'aol',
        'mail.com' => 'mail.com',
        'me.com' => 'me.com',
        'mac.com' => 'mac.com'
    }; 
    
    
    global EmailDomainUpdater(){
        query = 'SELECT id, name, website, AllowedEmailDomains__c FROM Account ' + 
                     'WHERE AllowedEmailDomains__c = NULL AND isAccountActive__c = true ';        
    }
    
    
    
    global Database.Querylocator start(Database.BatchableContext bc){
        return Database.getQuerylocator(query);
    }
    
    
    
     global void execute(Database.BatchableContext bc, List<sObject> scope){
        system.debug(logTag + 'TOTAL RECORDS TO PROCESS: ' + scope.size());
        List<Account> accountsToUpdate = new List<Account>();        
        List<Account> acctList = ((List<Account>)scope);
        
        for(Account a:acctList){
        	if(processAccount(a) != null){
        		accountsToUpdate.add(a);
        	}
        	
        	// Watch the DML limit for how many records we can update..
        	if(accountsToUpdate.size() == Limits.getLimitDmlStatements()){
        		updateAccounts(accountsToUpdate);
        	}
        }
       
    }
    
    private void updateAccounts(List<Account> acctList){
    	Database.SaveResult[] lsr = Database.update(acctList,false);
        Integer i = 0;
        for(Database.Saveresult sr:lsr){
            Account a = acctList[i];
            if(sr.isSuccess()){
                system.debug(logTag + 'Updated account [' + a.Name + '] with email domain(s) [' + a.AllowedEmailDomains__c + '].');
            } else {
                system.debug(logTag + 'Failed to update account [' + a.Name + ']. Error: ' + sr.getErrors()[0].getMessage());
            }
            i++;
        }
        
        // reset this list so we don't update the same accounts again               
        acctList.clear();
    }
    
    global void finish(Database.BatchableContext BC){
       // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
       // Query the AsyncApexJob object to retrieve the current job's information.
       AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
          TotalJobItems, CreatedBy.Email
          FROM AsyncApexJob WHERE Id =
          :BC.getJobId()];
       // Send an email to the Apex job's submitter notifying of job completion.
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       String[] toAddresses = new String[] {a.CreatedBy.Email}; 
       mail.setToAddresses(toAddresses);
       mail.setSubject('AccountEmailDomainUpdate ' + a.Status + '.');
       mail.setPlainTextBody
       ('The batch Apex job ' + logTag + ' processed ' + a.TotalJobItems +
       ' batches with '+ a.NumberOfErrors + ' failures.');
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    private Account processAccount(Account acct){
        system.debug(logTag + 'Processing account [' + acct.Name + ']...');
        String domainList = '';
        if(!String.isEmpty(acct.Website))
           domainList = parseDomainFromWebsite(acct);
        else 
            domainList = parseDomainsFromContacts(acct);
            
        system.debug(logTag + 'Domains for ' + acct.name + ': '  + domainList); 
        
        if(!String.isEmpty(acct.AllowedEmailDomains__c))
            acct.AllowedEmailDomains__c += ',' + domainList;
        else
            acct.AllowedEmailDomains__c = domainList;         
        
        if(acct.AllowedEmailDomains__c != ''){    
            //accountsToUpdate.add(acct);       
            return acct;
        } else {
        	return null;
        }
        
    }
    
    
    private String parseDomainFromWebsite(Account a){
        
        if(String.isEmpty(a.Website) || a.Website.length() < 3) return '';
        
        String domain = a.website.trim();
        
        // https
        if(domain.containsIgnoreCase('https://'))
           domain = domain.replace('https://','');
        
        // http
        if(domain.containsIgnoreCase('http://'))
           domain = domain.replace('http://',''); 
           
        // www
        if(domain.containsIgnoreCase('www.'))
           domain = domain.replace('www.','');
           
         return domain;
    }
    
     
    
    private String  parseDomainsFromContacts(Account a){
        String domainList = '';
        Map<String, String> emailMap = new Map<String,String>();
         
        // Inspect each contact for new email domains, excluding those who use free email like hotmail    
        for(Contact c: [select Id, Name, Email from Contact where AccountId = :a.Id and Email != null and Email != '']){
            String emailDomain = parseDomainFromEmail(c.Email);
            if(emailDomain =='') continue;
            
            if(!emailMap.containsKey(emailDomain) && !freeEmailDomains.containsKey(emailDomain) ){
              emailMap.put(emailDomain, '');
            }
        }
        
        for(String domain:emailMap.keySet()){
            if(domainList == '')
              domainList += domain;
            else
              domainList += ',' + domain;
        }
        return domainList;
    }
    
    private string parseDomainFromEmail(String email){
        if(!email.contains('@')) return '';
        return email.substringAfterLast('@'); 
    }
    
   
    
    
    
}