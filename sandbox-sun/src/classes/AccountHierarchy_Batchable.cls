/**
 * This class maintains the UltimateParent__c field on accounts.
 *
 * @version 2013-08-29
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-08-29 - created
 */
global class AccountHierarchy_Batchable  implements Database.Batchable<SObject>, Database.Stateful {
	/** 
	 * Catch-up record count.  This is a small number of record to process each 
	 * time this process runs, so we get any missed records.
	 */
	global static Integer CATCHUP_COUNT = 200;

	/** Name of a custom setting key. */
	global static final String LAST_PROCESSED_KEY = 'AccountHierarchy.LastProcessed';

	/** Keep track of any errors. */
	global List<String> errorList = new List<String>();

	/** Keep track of the lastProcessedDateTime */
	global DateTime lastProcessedDateTime = DateTime.newInstance(0L);

	/** 
	 * There is sometimes a delay to when an account shows up in a query, and it 
	 * is not always the oldest that shows-up first.
	 */
	global DateTime maxLastProcessedDateTime = DateTime.now().addMinutes(-3);

	/**
	 * Lookup or insert parents.
	 * 
	 * @param updateList list of account hierarchy objects to assign parents to.
	 */
	global static void assignParents(List<AccountHierarchy__c> updateList) {
		// map of account hierarchy objects based on account id.
		Map<Id,AccountHierarchy__c> accountHierarchyMap = new Map<Id,AccountHierarchy__c>();

		// pre-populate new records in-case the parents don't exist yet
		for(AccountHierarchy__c ah : updateList) {
			ah.UltimateParent__c = ah.Parent__c = null; // these value will be calculated later
			if(ah.Account_ParentId__c != null) {
				accountHierarchyMap.put(ah.Account_ParentId__c,new AccountHierarchy__c(Account__c=ah.Account_ParentId__c));
			}
		}

		// no need to lookup the records we are updating
		accountHierarchyMap.keySet().removeAll(new Map<Id,AccountHierarchy__c>(updateList).keySet());

		// lookup all the parent records
		for(AccountHierarchy__c ah : [
			select
				Account__c,
				Account_ParentId__c,
				Parent__c,
				UltimateParent__c
			from AccountHierarchy__c
			where Account__c in : accountHierarchyMap.keySet() ] )
		{
			accountHierarchyMap.put(ah.Account__c,ah);
		}

		// insert new records for any of the records we could not find
		List<AccountHierarchy__c> insertList = new List<AccountHierarchy__c>();
		for(AccountHierarchy__c ah : accountHierarchyMap.values()) {
			if(ah.Id == null) {
				insertList.add(ah);
			}
		}
		Database.insert(insertList,false);

		// add the records we are updating to the map
		for(AccountHierarchy__c ah : updateList) {
			accountHierarchyMap.put(ah.Account__c,ah);
		}

		// assign correct parents for everything in the map
		for(AccountHierarchy__c ah : accountHierarchyMap.values()) {
			if(ah.Account_ParentId__c == null) {
				ah.UltimateParent__c = ah.Parent__c = null;
			}
			else {
				AccountHierarchy__c parent = accountHierarchyMap.get(ah.Account_ParentId__c);
				if(parent != null) {
					// the ultimate level parent will be corrected later
					ah.UltimateParent__c = ah.Parent__c = parent.Id;
				}
			}
		}

		// make a map of ultimate parent ids, or at least higher level ids
		Map<Id,Id> ultimateParentIdMap = new Map<Id,Id>();
		for(AccountHierarchy__c ah : accountHierarchyMap.values()) {
			if(ah.UltimateParent__c != null) {
				// it doesn't really matter if we map the highest level parent so long as we can recurse up the tree...
				ultimateParentIdMap.put(ah.Id,ah.UltimateParent__c);
			}
		}

		// now recurse each value up to the top of the tree for each object in the map
		for(Id currentId : ultimateParentIdMap.keySet()) {
			Id parentId = ultimateParentIdMap.get(currentId);
			if(parentId != null) {
				Set<Id> ids = new Set<Id>{currentId,parentId};
				for(
					parentId=ultimateParentIdMap.get(parentId);
					parentId != null && ! ids.contains(parentId);
					ids.add(parentId) )
				{
					for(Id cId : ids) {
						ultimateParentIdMap.put(cId,parentId);
					}
					ids.add(parentId);
				}
			}
		}

		// now that we have a map we can assign ultimate parent id values.
		for(AccountHierarchy__c ah : updateList) {
			ah.UltimateParent__c = ultimateParentIdMap.get(ah.Id);
		}
	}

	/**
	 * Query the account records which have changed, and delete any orphaned
	 * AccountHierarchy__c objects.
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		DateTime maxLastProcessedDateTime = DateTime.now().addMinutes(-3);
		DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
		if(lastProcessed != null) {
			lastProcessedDateTime = lastProcessed.Value__c;
		}
		Integer maxRows = (Limits.getLimitQueryRows()-Limits.getQueryRows());
		List<Account> accounts = [
			select LastModifiedDate
			from Account
			where Parent.Name != null
				and Id not in (select Account__c from AccountHierarchy__c where Account__r.LastModifiedDate >= :lastProcessedDateTime)
				and LastModifiedDate >= :lastProcessedDateTime
			order by LastModifiedDate
			limit :maxRows ];
		if(accounts.size() <= CATCHUP_COUNT) {
			execute(null,accounts);
			// return all rows which are not current
			return Database.getQueryLocator([
				select 
					AccountId__c,
					Account__c,
					Account_ParentId__c
				from AccountHierarchy__c
				where IsCurrent__c = false 
					or Parent__r.IsCurrent__c = false
					or Parent__r.Parent__r.IsCurrent__c = false
					or Parent__r.Parent__r.Parent__r.IsCurrent__c = false
					or Parent__r.Parent__r.Parent__r.Parent__r.IsCurrent__c = false 
				order by UltimateParent__c, Parent__c ]);
		}
		else {
			Set<Id> accountIds = new Map<Id,Account>(accounts).keySet();
			return Database.getQueryLocator([
				select LastModifiedDate
				from Account
				where Id in :accountIds
				order by LastModifiedDate ]);
		}
	}

	/**
	 * Called to execute the respective updates.
	 * 
	 * @param bc the batchable context (not used)
	 * @param accountHierarchies the list to update
	 */
	global void execute(Database.BatchableContext bc, List<Object> objList) {
		try {
			List<AccountHierarchy__c> deleteList = new List<AccountHierarchy__c>();
			List<AccountHierarchy__c> updateList = new List<AccountHierarchy__c>();
			List<AccountHierarchy__c> upsertList = new List<AccountHierarchy__c>();
			for(Object obj : objList ) {
				if(obj instanceof AccountHierarchy__c) {
					AccountHierarchy__c ah = (AccountHierarchy__c)obj;
					List<AccountHierarchy__c> lst = deleteList;
					if(ah.Account__c == ah.AccountId__c) {
						lst = updateList;
					}
					lst.add(ah);
				}
				else if(obj instanceof Account) {
					Account acc = (Account)obj;
					upsertList.add(new AccountHierarchy__c(Account__c=acc.Id,AccountId__c=acc.Id));
					if(acc.LastModifiedDate > lastProcessedDateTime) {
						lastProcessedDateTime = acc.LastModifiedDate;
					}
				}
			}
			for(Database.DeleteResult result : Database.delete(deleteList,false)) {
				AccountHierarchy__c ah = deleteList.remove(0);
				if(! result.isSuccess()) {
					errorList.add('Failed to delete record for '+ah.Id+': '+result.getErrors());
				}
			}
			assignParents(updateList);
			upsertList.addAll(updateList);
			for(Database.UpsertResult result : Database.upsert(upsertList,false)) {
				AccountHierarchy__c ah = upsertList.remove(0);
				if(! result.isSuccess()) {
					errorList.add('Failed to upsert record for '+ah+': '+result.getErrors());
				}
			}
		}
		catch(Exception ex2) {
			errorList.add('Exception: '+ex2+'\n'+ex2.getStackTraceString());
		}
	}


	/**
	 * finish method impl for Database.Batchable interface
	 *
	 * @param bc database context
	 */
	global void finish(Database.BatchableContext bc) {
		System.debug('Finish called');
		finish([
			SELECT
				Status,
				NumberOfErrors,
				JobItemsProcessed,
				TotalJobItems,
				CreatedBy.Email
			FROM AsyncApexJob 
			WHERE Id = :bc.getJobId()] );
	}

	/**
	 * finish method
	 *
	 * @param job the async apex job
	 *
	 */
	global void finish(AsyncApexJob job) {
		DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
		if(lastProcessed == null) {
			lastProcessed = new DateTimeSetting__c(Name=LAST_PROCESSED_KEY);
		}
		if(lastProcessedDateTime > maxLastProcessedDateTime) {
			lastProcessedDateTime = maxLastProcessedDateTime;
		}
		lastProcessed.Value__c = lastProcessedDateTime;
		try {
			upsert lastProcessed;
		}
		catch(Exception e) {
			errorList.add('Failed to update lastProcessed '+e);
		}
		sendErrors(job);
	}

	/**
	 * Called to send error message by e-mail.
	 *
	 * @param job the async apex job
	 * @return the message which was sent
	 */
	global Messaging.SingleEmailMessage sendErrors(AsyncApexJob job) {
		Messaging.SingleEmailMessage mail = null;
		// Send an email to notify us of the jobs status
		if(job == null || job.NumberOfErrors == null || job.NumberOfErrors > 0 || ! errorList.isEmpty()) {
			if(job == null) {
				job = new AsyncApexJob();
			}
			mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] { 'sf-error-list@redhat.com' };
			mail.setToAddresses( toAddresses );
			mail.setSubject( 'AccountHierarchy_Batchable failures ' + job.Status +' run as '+UserInfo.getUserName() );
			String body = 'The batch Apex job processed ' + job.TotalJobItems + ' batches with ' + job.NumberOfErrors + ' failures.\n';
			for(String e : errorList) {
				body += e+'\n';
			}
			mail.setPlainTextBody( body );
			Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
		}
		return mail;
	}
}