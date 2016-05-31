/**
 * This class maintains a set of AccountReadOnly__c object that mirror Account
 * objects, so everyone can query some data about any account.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-09-19
 * 2012-09-19 - created
 */
global class AccountReadOnly_Batchable  implements Database.Batchable<SObject>, Database.Stateful {
	/** 
	 * Catch-up record count.  This is a small number of record to process each 
	 * time this process runs, so we get any missed records.
	 */
	global static final Integer CATCHUP_COUNT = 200;

	/** Name of a custom setting key. */
	global static final String LAST_PROCESSED_KEY = 'AccountReadOnly.LastProcessed';

	/** Keep track of any errors. */
	global List<String> errorList = new List<String>();

	/** Keep track of the lastProcessedDateTime */
	global DateTime lastProcessedDateTime = DateTime.newInstance(0L);

	/**
	 * Query the account records which have changed, and delete any orphaned
	 * AccountReadOnly__c objects.
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
		if(lastProcessed != null) {
			lastProcessedDateTime = lastProcessed.Value__c;
		}

		// Normally we don't do DML operations from within start.
		// This is needed to clean-up any orphans remaining from
		// emptying the trashbin.  We only do a couple of hundred
		// records each time, as normally deletes are done in the 
		// execute method.
		deleteAccountReadOnly([
			select Id
			from AccountReadOnly__c
			where Obsolete__c = true
			order by LastModifiedDate
			limit :CATCHUP_COUNT ]);

		// return all rows for inserts, updates, and deletes since the
		// last time we ran
		final DateTime lpt = lastProcessedDateTime;
		lastProcessedDateTime = DateTime.now();
		return Database.getQueryLocator([
			select 
				Account_Alias_Name__c,
				AccountClassification__c,
				BillingCity,
				BillingCountry,
				CurrencyIsoCode,
				IsDeleted,
				LastModifiedDate,
				Name,
				OwnerId,
				ParentId,
				PartnerStatuses__c,
				PrimaryBillingAccountNumber__c
			from Account
			where LastModifiedDate >= :lpt
			order by LastModifiedDate
			All Rows ]);
	}

	/**
	 * Called to delete Account (Read Only) objects.
	 */
	global void deleteAccountReadOnly(List<AccountReadOnly__c> deleteList) {
		if(! deleteList.isEmpty()) {
			for(Database.DeleteResult result : Database.delete(deleteList,false)) {
				AccountReadOnly__c a = deleteList.remove(0);
				if(! result.isSuccess()) {
					errorList.add('Failed to delete Account (Read Only): '+a.Id);
				}
			}
		}
	}

	/**
	 * Called to execute a subset of the inserts, updates, and deletes.
	 * 
	 * @param bc the batchable context (not used)
	 * @param accounts the list to update
	 */
	global void execute(Database.BatchableContext bc, List<Account> accounts) {
		try {
			// first loop through and find both parents and deleted records
			Set<String> accountDeletes = new Set<String>();
			for(Account a : accounts) {
				if(a.IsDeleted) {
					accountDeletes.add(''+a.Id);
				}
				if(a.LastModifiedDate > lastProcessedDateTime) {
					lastProcessedDateTime = a.LastModifiedDate;
				}
			}
			// create a record for each non-deleted account
			List<AccountReadOnly__c> upsertList = new List<AccountReadOnly__c>();
			for(Account a : accounts) {
				if(! a.IsDeleted) {
					try {
						upsertList.add(new AccountReadOnly__c(
							Account__c = a.Id,
							Account_Alias_Name__c = a.Account_Alias_Name__c,
							AccountClassification__c = a.AccountClassification__c,
							BillingCity__c = a.BillingCity,
							BillingCountry__c = a.BillingCountry,
							CurrencyIsoCode = a.CurrencyIsoCode,
							ExternalId__c = ''+a.Id,
							Name = (a.Name+'                                                                                ').substring(0,80).trim(),
							OwnerId__c = a.OwnerId,
							Parent__c = a.ParentId,
							PartnerStatuses__c = a.PartnerStatuses__c,
							PrimaryBillingAccountNumber__c = a.PrimaryBillingAccountNumber__c ));
					}
					catch(Exception ex) {
						errorList.add('Failed to create record for '+a.Id+': '+ex+'\n'+ex.getStackTraceString());
					}
				}
			}
			// upsert all the read only records
			if(! upsertList.isEmpty()) {
				for(Database.UpsertResult result : Database.upsert(upsertList,AccountReadOnly__c.Fields.ExternalId__c,false)) {
					AccountReadOnly__c aro = upsertList.remove(0);
					if(! result.isSuccess()) {
						errorList.add('Failed to upsert record for '+aro.Account__c+': '+result.getErrors());
					}
				}
			}
			// if we have deletes, handle those here
			if(! accountDeletes.isEmpty()) {
				deleteAccountReadOnly([
					select Id
					from AccountReadOnly__c
					where ExternalId__c in :accountDeletes ]);
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
			mail.setSubject( 'AccountReadOnlyBatchable failures ' + job.Status +' run as '+UserInfo.getUserName() );
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