global class AccountEmailDomainUpdate implements Database.Batchable<sObject>, Database.Stateful {

    private string query;
    global final string logTag = '[AccountEmailDomainUpdate]';
    global List<Account> accountsToUpdate;

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

    global AccountEmailDomainUpdate(Integer recordLimit){
    	accountsToUpdate = new List<Account>();
    	query = 'select id, name, website, AllowedEmailDomains__c, PrimaryPartnerUser__r.Email from Account ' +
                                         'WHERE IsPartner = true and AllowedEmailDomains__c = NULL AND isAccountActive__c = true ';

        if(recordLimit != null && recordLimit > 0)
            query += 'LIMIT '  + recordLimit;

    }

    global Database.Querylocator start(Database.BatchableContext bc){
        return Database.getQuerylocator(query);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope){
    	system.debug(logTag + 'TOTAL RECORDS TO PROCESS: ' + scope.size());
        List<Account> acctList = ((List<Account>)scope);
    	for(Account a:acctList) processAccount(a);

    	if(!accountsToUpdate.isEmpty()) Database.update(accountsToUpdate,false);
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
	   mail.setSubject('AccountEmailDomainUpdate ' + a.Status + ' (' + accountsToUpdate.size() + ') accounts affected.');
	   mail.setPlainTextBody
	   ('The batch Apex job ' + logTag + ' processed ' + a.TotalJobItems +
	   ' batches with '+ a.NumberOfErrors + ' failures. There were ' +
	   accountsToUpdate.size() + ' accounts updated.');
	   Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}

    private void processAccount(Account acct){
    	system.debug(logTag + 'Processing account [' + acct.Name + ']...');
    	String domainList = '';
    	if(!String.isEmpty(acct.Website)) {
    	   domainList = parseDomainFromWebsite(acct);
           String d = parseDomainForPrimaryUser(acct);
           if (d != null) {
                if (domainList.length() > 0) {
                    domainList += ';' + d;
                }
                else {
                    domainList = d;
                }
           }
        }
        else
            domainList = parseDomainsFromContacts(acct);

        system.debug(logTag + 'Domains for ' + acct.name + ': '  + domainList);

        if(!String.isEmpty(acct.AllowedEmailDomains__c))
            acct.AllowedEmailDomains__c += ';' + domainList;
        else
            acct.AllowedEmailDomains__c = domainList;

        if(acct.AllowedEmailDomains__c != '')
            accountsToUpdate.add(acct);
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

        Integer i = domain.indexOf('/');
        if (i > 0) {
            domain = domain.substring(0, i);
        }
        i = domain.indexOf('?');
        if (i > 0) {
            domain = domain.substring(0, i);
        }

         return domain;
    }


    private String parseDomainForPrimaryUser(Account a) {
        if (a.PrimaryPartnerUser__r == null) return null;
        String email = a.PrimaryPartnerUser__r.Email;
        if (email == null || email.length() == 0) return null;
        String emailDomain = parseDomainFromEmail(email);
        if(emailDomain =='') return null;

        if(!freeEmailDomains.containsKey(emailDomain) ){
            return emailDomain;
        }
        return null;
    }

    private String  parseDomainsFromContacts(Account a){
    	String domainList = '';
    	Map<String, String> emailMap = new Map<String,String>();

        // Inspect each contact for new email domains, excluding those who use free email like hotmail
    	for(User c: [select Id, Name, Email from User where Contact.AccountId = :a.Id and Email != null]) { // and Email != '']){
            if (c.Email.length() == 0) continue;
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
    		  domainList += ';' + domain;
    	}
    	return domainList;
    }

    private string parseDomainFromEmail(String email){
    	if(!email.contains('@')) return '';
    	return email.substringAfterLast('@');
    }



}