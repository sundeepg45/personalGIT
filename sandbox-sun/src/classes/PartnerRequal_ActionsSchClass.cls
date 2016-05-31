global class PartnerRequal_ActionsSchClass Implements Schedulable
{
    private Date todayDate = System.today();
    private Date minusSixty = todayDate.addDays(60);
    private Map<Id, Account> sixtydayNARedResAccountMap;
    private Date minusThirty = todayDate.addDays(30);
    private Date plusFifteen = todayDate.addDays(-15);
    private Date plusThirty = todayDate.addDays(-30);
    private Date plusNinety = todayDate.addDays(-90);
    private Map<String, EmailTemplate> emailtemplateMap;
    private Map<Id, List<User>> accountUserListMap;
    private List<Account> overdueAccounts;
    private Id caseRecordType;
    private transient List<Messaging.SingleEmailMessage> emails;
    private transient List<Partner_Requalification_Log__c> logMessages;
    private transient List<Case> cases;
    private List<Account> eligibleAccounts;
    private OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
    public Boolean testMode {get; set; }
    public Date dateOverride {get; set; }
    public String statusBody = '';
    private LogSwarm log;


	public PartnerRequal_ActionsSchClass() {
		testMode = False;
	}

    global void execute (SchedulableContext SC){
        run();
    }

    public void run() {
        log = new LogSwarm('Requal', 'Scheduler');
        try {
            init();
            if (dateOverride != null) {
            	initWithDate(dateOverride);
            }
            else {
            	initWithDate(System.today());
            }
    	    statusBody = '';
            List<Account> accts = findAccounts();
            emails = new List<Messaging.SingleEmailMessage>();
            logMessages = new List<Partner_Requalification_Log__c>();
            cases = new List<Case>();
            processAccounts(accts);

            if (!Test.isRunningTest() && accts.size() > 0) {
                log.info('requal scheduler complete');
                log.flush();
            }
        }
        catch (Exception ex) {
            log.exception(ex);
        }
/*
		if (!testMode) {
			List<String> to = new List<String>();
			to.add('masmith@redhat.com');
			String subject = 'Requal scheduled job for ' + System.now();
	        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	        mail.setToAddresses(to);
	        mail.setSubject(subject);
	        mail.setPlainTextBody(statusBody);
	        Messaging.SingleEmailMessage[] maillist = new List<Messaging.SingleEmailMessage>();
	        maillist.add(mail);
	        Messaging.sendEmail(maillist);
		}
*/
    }

    private void initWithDate(Date theDate) {
	    todayDate = theDate;
	    minusSixty = todayDate.addDays(60);
	    minusThirty = todayDate.addDays(30);
	    plusFifteen = todayDate.addDays(-15);
	    plusThirty = todayDate.addDays(-30);
	    plusNinety = todayDate.addDays(-90);
        System.debug('*****[debug]***** plusNinety=' + plusNinety);
    }

    private void init(){
        emailtemplateMap = new Map<String, EmailTemplate>();
        caseRecordType = [select Id from RecordType where DeveloperName = 'Partner_General_Issues'].Id;

        for (
            EmailTemplate e : [
                select Id,Name from EmailTemplate where name like 'PRQ%'
            ]
        ) emailtemplateMap.put(e.name, e);

        overdueAccounts = new List<Account>();
        eligibleAccounts = new List<Account>();
        sixtydayNARedResAccountMap = new Map<Id, Account>();
    }

    private List<Account> findAccounts(){

        Integer lim = 100000;
        if (testMode) {
        	lim = 2;
        }
        List<Account> acctList = [
            select
                Id,
                Name,
                RequalificationDate__c ,
                RequalStatus__c,
                Global_Region__c,
                PartnerStatuses__c,
                OwnerId
            from Account
            where RequalificationDate__c in (:minusSixty, :minusThirty, :todayDate, :plusFifteen, :plusThirty, :plusNinety)
            and   RecordType.DeveloperName in (:PartnerConst.NA_PARTNER_DN, :PartnerConst.EMEA_PARTNER_DN,
                  :PartnerConst.APAC_PARTNER_DN, :PartnerConst.LATAM_PARTNER_DN, :PartnerConst.FEDSLED_PARTNER_DN)
            limit :lim
        ];

        // MD - debugging
        string acctDump = '';
        for(Account a:acctList) acctDump += a.Name + ' (' + a.Id + ')\n';
        System.debug('[requal]--------------- Accounts=[' + acctList.size() + ']:\n' + acctDump);
        // end

		statusBody += 'Accounts queried: ' + acctList.size() + '\n';
        log.push('accounts_queried', acctList.size());

		//
		// Get list of accounts from previous runs for the same day
		Map<ID, Partner_Requalification_Log__c> logs = new Map<ID, Partner_Requalification_Log__c>();
		for (Partner_Requalification_Log__c log : [
	        	select	Account__c, Event_Date__c
	        	  from	Partner_Requalification_Log__c
	        	 where	Account__c in :acctList
	        	   and	Event_Date__c = :todayDate
	       	]) {
	       logs.put(log.Account__c, log);
	    }

		System.debug('[requal]--------------- Logs=' + logs.size());
		statusBody += 'Logs found: ' + logs.size() + '\n';
        log.push('logs_found', logs.size());

		Integer skipped = 0;
		Integer unaffiliated = 0;
		//
		// Build list of accounts that have not already been run, and limit
		//
		Account[] accts = new List<Account>();
		for (Account acct : acctList) {
			if (acct.PartnerStatuses__c != null && acct.PartnerStatuses__c.indexOf('Unaffiliated') >= 0) {
				unaffiliated += 1;
				continue;
			}
			if (logs.containsKey(acct.Id) == false) {
				accts.add(acct);
				if (accts.size() >= 300) {
					break;
				}
			}
			else {
				skipped += 1;
				system.debug('MD - skipping account [' + acct.Name + ' (' + acct.Id + ')]');
			}
		}

		System.debug('[requal]--------------- Skipped accounts=' + skipped);
		System.debug('[requal]--------------- Working accounts=' + accts.size());
		statusBody += 'Skipped unaffiliated: ' + unaffiliated + '\n';
		statusBody += 'Skipped accounts: ' + skipped + '\n';
		statusBody += 'Working accounts: ' + accts.size() + '\n';
        log.push('skipped_unaffiliated', unaffiliated);
        log.push('skipped_accounts', skipped);
        log.push('working_accounts', accts.size());

        loadUsers(accts);

        return accts;
    }

    private void loadUsers(List<Account> accts){
        accountUserListMap = new Map<Id, List<User>>();
        Set<Id> acctIds = new Set<Id>();
        for(Account a : accts){
            acctIds.add(a.Id);
            accountUserListMap.put(a.Id, new List<User>());
        }

        List<User> acctUsers = [
            select AccountId,
                Id,
                Email,
                Firstname,
                Lastname,
                IsPartnerAdmin__c,
                IsActive,
                ContactId
            from User
            where
                User.AccountId in :acctIds
                and IsPartnerAdmin__c = true
                and IsActive = true
        ];

        for (User u : acctUsers){
            accountUserListMap.get(u.AccountId).add(u);
        }

    }

    private void processAccounts(List<Account> accts){
        Integer rejected = 0;
        for (Account a : accts){
        	if (accountUserListMap.get(a.Id).size() == 0) {
	        	createEventLog(a.id, null, 'Partner missing users to notify');
//	        	continue;
        	}
	        if( a.PartnerStatuses__c <> null){
//                Boolean isReseller = isResellerFlow(a);
                boolean isISV = isISVFlow(a);
                boolean isReadyReseller = a.PartnerStatuses__c.contains('Ready - Reseller');
/*
	            if (a.RequalificationDate__c == minusSixty && (a.RequalStatus__c == 'Completed' || a.RequalStatus__c == 'Eligible' || a.RequalStatus__c == null) && isReseller){
	                processResellerMinusSixty(a);
	                if (a.Global_Region__c == 'NA' &&
                        (a.PartnerStatuses__c.contains('Ready - Reseller') || a.PartnerStatuses__c.contains('Ready - Systems Integrator') || a.PartnerStatuses__c.contains('Ready - Distributor'))) {
	                    sixtydayNARedResAccountMap.put(a.Id, a);
                    }
	            } else if (a.RequalificationDate__c == minusThirty && (a.RequalStatus__c == 'Eligible' || a.RequalStatus__c == 'In Progress') && isReseller){
	                processResellerMinusThirty(a);
	            } else if (a.RequalificationDate__c == todayDate && (a.RequalStatus__c == 'Eligible' || a.RequalStatus__c == 'In Progress') && isReseller){
	                processResellerMinusZero(a);
	            } else if (a.RequalificationDate__c == plusFifteen && (a.RequalStatus__c == 'Eligible' || a.RequalStatus__c == 'In Progress') && isReseller){
	                processResellerPlusFifteen(a);
	            } else if (a.RequalificationDate__c == plusThirty && (a.RequalStatus__c == 'Overdue' || a.RequalStatus__c == 'Eligible' || a.RequalStatus__c == 'In Progress') && isReseller){
	                processResellerPlusThirty(a);
	            } else if (a.RequalificationDate__c == plusNinety && (a.RequalStatus__c == 'Overdue' || a.RequalStatus__c == 'Eligible' || a.RequalStatus__c == 'In Progress' || a.RequalStatus__c == 'Not Approved at this time') && isReseller){
	                processResellerPlusNinety(a);
*/
	            if (a.RequalificationDate__c == minusSixty && (a.RequalStatus__c == 'Completed' || a.RequalStatus__c == 'Not Completed' || a.RequalStatus__c == null || a.RequalStatus__c == 'Eligible' || a.RequalStatus__c == 'In Progress')) {
	               processMinusSixty(a);
                   if (a.Global_Region__c == 'NA' && isReadyReseller) {
                       sixtydayNARedResAccountMap.put(a.Id, a);
                   }
	            } else if (a.RequalificationDate__c == minusThirty && (a.RequalStatus__c == 'Eligible' || a.RequalStatus__c == 'In Progress')) {
	               processMinusThirty(a);
	            } else if (a.RequalificationDate__c == todayDate && (a.RequalStatus__c == 'Eligible' || a.RequalStatus__c == 'In Progress')) {
	               processMinusZero(a);
               } else if (a.RequalificationDate__c == plusFifteen && (a.RequalStatus__c == 'Eligible' || a.RequalStatus__c == 'In Progress')) {
                   processPlusFifteen(a);
               } else if (a.RequalificationDate__c == plusThirty && (a.RequalStatus__c == 'Overdue' || a.RequalStatus__c == 'Eligible' || a.RequalStatus__c == 'In Progress')) {
                   processPlusThirty(a);
               } else if (a.RequalificationDate__c == plusNinety && (a.RequalStatus__c == 'Overdue' || a.RequalStatus__c == 'Eligible' || a.RequalStatus__c == 'In Progress' || a.RequalStatus__c == 'Not Approved at this time')) {
                   processPlusNinety(a);
                } else {
	            	createEventLog(a.id, null, 'Partner not processed (' + a.RequalStatus__c + ','+a.PartnerStatuses__c+','+a.RequalificationDate__c+')');
	            	statusBody += 'Not processed: ' + a.Id + ' , ' + a.Name + ' , ' + a.RequalStatus__c + ' , ' + a.PartnerStatuses__c + ' , ' +  a.RequalificationDate__c + '\n';
	            	system.debug(statusBody);
                    rejected++;
	            }
	        }
	        else {
	        	createEventLog(a.id, null, 'Partner Status Missing');
	        }
	    }
        updateSixtyDayAccountPams(sixtydayNARedResAccountMap);
        processAllOverdue(overdueAccounts);
        log.push('rejected_accounts', rejected);
   		statusBody += 'Overdue processed: ' + overdueAccounts.size() + '\n';
        log.push('overdue', overdueAccounts.size());
        Messaging.sendEmail(emails);
        insert cases;
   		statusBody += 'Cases inserted: ' + cases.size() + '\n';
        log.push('cases_inserted', cases.size());
        insert logMessages;
   		statusBody += 'Logs inserted: ' + logMessages.size() + '\n';
        log.push('logs_inserted', logMessages.size());
        update eligibleAccounts;
   		statusBody += 'Eligible accounts: ' + eligibleAccounts.size() + '\n';
        log.push('eligible', eligibleAccounts.size());
    }

    private boolean isISVFlow(Account a) {
        return   a.PartnerStatuses__c.contains('Ready - ISV') ||
                 a.PartnerStatuses__c.contains('Advanced - ISV') ||
                 a.PartnerStatuses__c.contains('Premier - ISV');
    }

/*
    private Boolean isResellerFlow(Account a) {
		return 	a.PartnerStatuses__c.contains('Ready - Reseller') || a.PartnerStatuses__c.contains('Advanced - Reseller') || a.PartnerStatuses__c.contains('Premier - Reseller') ||
				a.PartnerStatuses__c.contains('Affiliated - Distributor') ||
				a.PartnerStatuses__c.contains('Ready - Systems Integrator') || a.PartnerStatuses__c.contains('Advanced - Systems Integrator') || a.PartnerStatuses__c.contains('Premier - Systems Integrator');
   }

    //General INFO  select all the admin user in the account
            // IsPartnerAdmin__c  = true

    private void processResellerMinusSixty(Account a){
        eligibleAccounts.add(new Account(Id=a.Id, RequalStatus__c = 'Eligible'));
        EmailTemplate e = emailTemplateMap.get('PRQ - Reseller 60');
        for (User u : accountUserListMap.get(a.Id)) {
            sendEmail(u.Id,e.id,a.id);
            createEventLog(a.id,u.Id,'Partner Notification -60');
            //setting up the eligible status
        }
    }

    private void processResellerMinusThirty(Account a){
        EmailTemplate e = emailTemplateMap.get('PRQ - Reseller 30');

        for (User u : accountUserListMap.get(a.Id)) {
            sendEmail(u.Id,e.id,a.id);
            createEventLog(a.id,u.Id,'Partner Notification -30');
        }
    }

    private void processResellerMinusZero(Account a){
        EmailTemplate e = emailTemplateMap.get('PRQ - Reseller 0');

        for (User u : accountUserListMap.get(a.Id)) {
            sendEmail(u.Id,e.id,a.id);
            createEventLog(a.id,u.Id,'Partner Notification 0');
        }
    }

    private void processResellerPlusFifteen(Account a){
        EmailTemplate e = emailTemplateMap.get('PRQ - Reseller plus15');
        List<User> ul = accountUserListMap.get(a.Id);
        for (User u : ul) {
           sendEmail(u.Id,e.id,a.id);
           createEventLog(a.id,u.Id,'Partner Notification +15');
        }
        if (ul.size() > 0){
            createCase (a.id, ul.get(0).ContactId);
            createEventLog(a.id,ul.get(0).Id,'Case Created +15');
        } else {
            createCase (a.id, null);
            createEventLog(a.id,null,'No Case Created for +15');
        }
    }

    private void processResellerPlusThirty(Account a){
        EmailTemplate e = emailTemplateMap.get('PRQ - Reseller plus30');

        for (User u : accountUserListMap.get(a.Id)) {
            sendEmail(u.Id,e.id,a.id);
            createEventLog(a.id,u.Id,'Partner Notification +30');
        }
    }

    private void processResellerPlusNinety(Account a){
    	system.debug('Adding account [' + a.Name + '] to overdueAccounts list..');
        overdueAccounts.add(a);
    }
*/

    private void processMinusSixty(Account a){
        eligibleAccounts.add(new Account(Id=a.Id, RequalStatus__c = 'Eligible'));
        EmailTemplate e = emailTemplateMap.get('PRQ - 60');

        for (User u : accountUserListMap.get(a.Id)) {
            sendEmail(u.Id,e.id,a.id);
            createEventLog(a.id,u.Id,'Partner Notification -60');
        }
    }

    private void processMinusThirty(Account a){
        EmailTemplate e = emailTemplateMap.get('PRQ - 30');
        for (User u : accountUserListMap.get(a.Id)) {
            sendEmail(u.Id,e.id,a.id);
            createEventLog(a.id,u.Id,'Partner Notification -30');
        }
    }

    private void processMinusZero(Account a){
        EmailTemplate e = emailTemplateMap.get('PRQ - 0');
        for (User u : accountUserListMap.get(a.Id)) {
            sendEmail(u.Id,e.id,a.id);
            createEventLog(a.id,u.Id,'Partner Notification 0');
        }
    }

    private void processPlusFifteen(Account a){
        EmailTemplate e = emailTemplateMap.get('PRQ - plus15');
        List<User> ul = accountUserListMap.get(a.Id);
        for (User u : ul) {
           sendEmail(u.Id,e.id,a.id);
           createEventLog(a.id,u.Id,'Partner Notification +15');
        }
        if (ul.size() > 0){
            createCase (a.id, ul.get(0).ContactId);
            createEventLog(a.id,ul.get(0).Id,'Case Created +15');
        } else {
            createCase (a.id, null);
            createEventLog(a.id,null,'No Case Created for +15');
        }
    }

    private void processPlusThirty(Account a){
        EmailTemplate e = emailTemplateMap.get('PRQ - plus30'); // TODO JDG: Have to chagne this to ISV.

        for (User u : accountUserListMap.get(a.Id)) {
            sendEmail(u.Id,e.id,a.id);
            createEventLog(a.id,u.Id,'Partner Notification +30');
        }
    }

    private void processPlusNinety(Account a){
    	system.debug('Adding account [' + a.Name + '] to overdueAccounts list..');
        overdueAccounts.add(a);
    }

    // Known issue - not updating the users to disabled
    // because it cannot be done in the same moment due to
    // Mixed DML error
    private void processAllOverdue(List<Account> overdueList) {

        Set<Id> overdueAccountIds = new Set<Id>();
        Set<String> uList = new Set<String>();
        for (Account a : overdueList){
            a.RequalStatus__c = 'Overdue';
            if (!overdueAccountIds.contains(a.Id)){
                overdueAccountIds.add(a.Id);
            }
            List<User> pul = accountUserListMap.get(a.Id);
            System.debug('Number of users deactivating: ' + pul.size());
            for (User u : pul) {
                uList.add(u.Id);
            }
            createEventLog(a.id,null,'Partner Overdue');
        }
        Database.SaveResult[] results = Database.update(overdueList);
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                System.debug('***** [debug] ***** Account=' + result.getId() + ': ' + result.getErrors().get(0));
                createEventLog(result.getId(), null, 'Error:' + result.getErrors().get(0));
            }
            else {
            }
        }
        // Commented out for US76540. We don't want users deactivated because
        // we want them to be able to submit cases to get back in.
        // PartnerEmailUtils.deactivateUsers(uList);
     }

     private void updateSixtyDayAccountPams(Map<id, Account> sixtyDayAccts){

        // Look for the PAM in all Ready-Reseller account and fill out the Requalification Approver field in account.
        // Find Account team member with Role 'Partner Relationship Manager - Regional'
        // Setting the account custom field 'Requalification_Approver__c'

        for (AccountTeamMember atm : [
            select UserId,
                TeamMemberRole,
                AccountId
            from AccountTeamMember a
            where TeamMemberRole = 'Partner Relationship Manager - Regional'
                and AccountId in :sixtyDayAccts.keySet()
        ]) sixtyDayAccts.get(atm.AccountId).Requalification_Approver__c = atm.UserId;

        update sixtyDayAccts.values();
    }


    private void sendEmail(Id userId, Id templateId, Id accountId )
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(userId); //email recipient id
        mail.setTemplateId(templateId); //email template id
        mail.setReplyTo('noreply@redhat.com');

        mail.setOrgWideEmailAddressId(owe.id);

        mail.saveAsActivity = FALSE;
        mail.setWhatID(accountId); //account id (show cases for this account)
        emails.add(mail);
    }

    private void createCase(Id accountId, ID contactId) {
        Case c = new Case();
        c.AccountId = accountId;
        c.RecordTypeId = caseRecordType;
        c.Priority = 'Urgent';
        c.Issue_Type__c = 'Requalification Request';
        c.Issue_Type_Classification__c = 'General Questions';
        c.Requester__c = UserInfo.getName();
        c.Subject = Label.PRQ_Email_Subject_Reseller_plus15;
        c.ContactId = contactId;

        Database.Dmloptions dmo = new Database.Dmloptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        c.setOptions(dmo);

        cases.add(c);
    }

    private void createEventLog(Id accountId, ID userId, STRING eventType) {
        Partner_Requalification_Log__c prq = new Partner_Requalification_Log__c();
        prq.Account__c = accountId;
        prq.User__c = userId;
        prq.Event_Type__c = eventType;
        prq.Event_Date__c = todayDate;
        logMessages.add(prq);
    }
}