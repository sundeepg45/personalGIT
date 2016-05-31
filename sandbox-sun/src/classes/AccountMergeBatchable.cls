/**
 * This class looks for duplicate records created by account merge operations and marks them as duplicates
 * 
 * @version 2015-11-10
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-11-10 - Use Merged status instead of Inactive for duplicate addresses
 * 2015-10-01 - Add Reparented__c to the sorting order
 * 2015-09-30 - support overwriting the discovered by parameter
 * 2015-08-19 - created
 */
global class AccountMergeBatchable extends AbstractBatchable {
	/**
	 * The limit on number of recent accounts we check in the hasWork method.
	 */
	global static Integer ACCOUNT_IDS_HAS_WORK_LIMIT = 50;

	/**
	 * If we are doing many merges to day eventually hasWork will be true...  When we
	 * actually do the processing lets future proof ourself with a higher limit.
	 */
	global static Integer ACCOUNT_IDS_START_LIMIT = 200;

	/** 
	 * Limit the number of accounts we check for recent merges.  This value will be adjusted
	 * to be one of the above two values.
	 */
	global Integer ACCOUNT_IDS_LIMIT = ACCOUNT_IDS_HAS_WORK_LIMIT;

	/**
	 * The local discoveredBy setting for the duplicate log.
	 */
	global String discoveredBy = 'Account Merge';

	/**
	 * Default constructor.
	 */
	global AccountMergeBatchable() {
		super('AccountMergeBatchable');
	}

	/**
	 * Find the set of the most recent accounts which have been merged in the last day.
	 */
	global Set<Id> accountIds {
		get {
			if(accountIds == null) {
				accountIds = new Set<Id>();
				final DateTime oldestTime = DateTime.now().addDays(-1);
				for(AggregateResult ar : [
					select MasterRecordId 
					from Account
					where MasterRecordId != null and SystemModStamp > :oldestTime
					group by MasterRecordId
					order by max(SystemModStamp) desc nulls last
					limit :ACCOUNT_IDS_LIMIT
					ALL ROWS ] )
				{
					accountIds.add((Id)String.valueOf(ar.get('MasterRecordId')));
				}
			}
			return accountIds;
		}
		set;
	}

	global List<AggregateResult> getEBSAccountResults(Integer rowLimit) {
		if(rowLimit > 10000) {
			rowLimit = 10000;
		}
		return [
			select Sales_Account__c, Name
			from EBS_Account__c
			where Sales_Account__c in :accountIds
				and ( MasterRecord__c = null or MasterRecord__r.MasterRecord__c != null)
			group by Sales_Account__c, Name
			having count(Id) > 1
			limit :rowLimit ];
	}

	global List<AggregateResult> getAddressResults(Integer rowLimit) {
		if(rowLimit > 10000) {
			rowLimit = 10000;
		}
		return [
			select Sales_Account__c, CDH_Party_Site_Number__c
			from Address__c
			where Sales_Account__c in :accountIds
				and ( IsDuplicate__c != true or MasterRecord__c != null)
				and ( MasterRecord__c = null or MasterRecord__r.MasterRecord__c != null)
				and CDH_Party_Site_Number__c != null
			group by Sales_Account__c, CDH_Party_Site_Number__c
			having count(Id) > 1
			limit :rowLimit ];
	}

	global List<AggregateResult> getContactResults(Integer rowLimit) {
		if(rowLimit > 10000) {
			rowLimit = 10000;
		}
		return [
			select AccountId, CDH_Party__c
			from Contact
			where AccountId in :accountIds
				and ( MasterRecord__c = null or MasterRecord__r.MasterRecord__c != null)
				and CDH_Party__c != null
			group by AccountId, CDH_Party__c
			having count(Id) > 1
			limit :rowLimit ];
	}

	/**
	 * Check if there is work for this job to do.
	 *
	 * @return false if there is no work to do.
	 */
	global override Boolean hasWork() {
		ACCOUNT_IDS_LIMIT = ACCOUNT_IDS_HAS_WORK_LIMIT;
		List<AggregateResult> results = null;
		if( ! accountIds.isEmpty() ) {
			results = getEBSAccountResults(1);
			if( results.isEmpty() ) {
				results = getAddressResults(1);
				if( results.isEmpty() ) {
					results = getContactResults(1);
				}
			}
		}
		return ( results != null && ! results.isEmpty());
	}

	/**
	 * Find the number of usable rows we can query.
	 * @param reservedQueryRows the number of rows we want to preserve for future queries
	 * @retval the number of rows we can query on the next query
	 */
	global static Integer getQueryRows(Integer reservedQueryRows) {
		return Limits.getLimitQueryRows() - Limits.getQueryRows() - reservedQueryRows;
	}

	global List<SObject> getEBSAccounts(List<SObject> records,final Integer reservedQueryRows) {
		Integer rowLimit = getQueryRows(reservedQueryRows);
		if(rowLimit >= 2) {
			Set<Id> salesAccountIds = new Set<Id>();
			Set<String> names = new Set<String>();
			for(AggregateResult ar : getEBSAccountResults(rowLimit / 2)) {
				salesAccountIds.add((Id)String.valueOf(ar.get('Sales_Account__c')));
				names.add(String.valueOf(ar.get('Name')));
			}
			List<SObject> ebsAccounts = [
				select
					Id,
					Name,
					MasterRecord__c,
					Sales_Account__c,
					Status__c
				from EBS_Account__c
				where Sales_Account__c in :salesAccountIds
					and Name in :names
					and ( MasterRecord__c = null or MasterRecord__r.MasterRecord__c != null)
				order by Sales_Account__r.LastModifiedDate desc,
					Sales_Account__c,
					Name,
					MasterRecord__c asc nulls first,
					Status__c asc nulls first,
					Primary_EBS_Account__c desc nulls last,
					LastModifiedDate
				limit :getQueryRows(reservedQueryRows) ];
			records.addAll(ebsAccounts);
		}
		return records;
	}

	global List<SObject> getAddresses(List<SObject> records,Integer reservedQueryRows) {
		Integer rowLimit = getQueryRows(reservedQueryRows);
		if(rowLimit >= 2) {
			Set<Id> salesAccountIds = new Set<Id>();
			Set<String> cdhPartySiteNumbers = new Set<String>();
			for(AggregateResult ar : getAddressResults(rowLimit / 2)) {
				salesAccountIds.add((Id)String.valueOf(ar.get('Sales_Account__c')));
				cdhPartySiteNumbers.add(String.valueOf(ar.get('CDH_Party_Site_Number__c')));
			}
			List<SObject> addresses = [
				select 
					Id,
					CDH_Party_Site_Number__c,
					IsDuplicate__c,
					MasterRecord__c,
					Reparented__c,
					Sales_Account__c,
					Status__c
				from Address__c
				where Sales_Account__c in :salesAccountIds
					and CDH_Party_Site_Number__c in :cdhPartySiteNumbers
					and ( MasterRecord__c = null or MasterRecord__r.MasterRecord__c != null)
					and CDH_Party_Site_Number__c != null
				order by Sales_Account__r.LastModifiedDate asc,
					Sales_Account__c,
					CDH_Party_Site_Number__c,
					IsDuplicate__c asc nulls first,
					Status__c asc nulls first,
					Identifying_Address__c desc nulls last,
					MasterRecord__c asc nulls first,
					CDH_Party_Site_Number_Previous__c asc nulls first,
					Reparented__c asc nulls first,
					LastModifiedDate desc
				limit :getQueryRows(reservedQueryRows) ];
			records.addAll(addresses);
		}
		return records;
	}

	global List<SObject> getContacts(List<SObject> records,Integer reservedQueryRows) {
		Integer rowLimit = getQueryRows(reservedQueryRows);
		if(rowLimit >= 2) {
			Set<Id> contactAccountIds = new Set<Id>();
			Set<Id> cdhPartyIds = new Set<Id>();
			for(AggregateResult ar : getContactResults(rowLimit / 2)) {
				contactAccountIds.add((Id)String.valueOf(ar.get('AccountId')));
				cdhPartyIds.add((Id)String.valueOf(ar.get('CDH_Party__c')));
			}
			List<SObject> contacts = [
				select 
					Id,
					AccountId,
					CDH_Party__c,
					MasterRecord__c,
					Status__c
				from Contact
				where AccountId in :contactAccountIds
					and CDH_Party__c in :cdhPartyIds
					and ( MasterRecord__c = null or MasterRecord__r.MasterRecord__c != null)
					and CDH_Party__c != null
				order by Account.LastModifiedDate asc,
					AccountId,
					CDH_Party__c,
					MasterRecord__c asc nulls first,
					Status__c asc nulls first,
					Reparented__c asc nulls first,
					LastModifiedDate desc
				limit :getQueryRows(reservedQueryRows) ];
			records.addAll(contacts);
		}
		return records;
	}

	/**
	 * Query the list of contacts, ebs accounts and addresses that need to be updated.
	 * @return list of object to update
	 */
	global List<SObject> start(Database.BatchableContext bc)
	{
		List<SObject> retval = new List<SObject>();
		ACCOUNT_IDS_LIMIT = ACCOUNT_IDS_START_LIMIT;
		if(! accountIds.isEmpty()) {
			// The following ratios were selected rather arbitrarily.  In truth it doesn't
			// matter, because we should never really hit any of these limits...
			// We try to order record types by least likely to have duplicates to most likely
			// to have duplicates.  That way we can always process some records of each at we
			// are least likely to hit any of the governor limits.

			// Get the list of contacts to update, reserving at least 1/5 of the
			// remaining DML row queries for ebs accounts and contacts.
			getContacts(retval,getQueryRows(0)/5);
			// Get the list of ebs accounts to update, reserving at least 1/3 of the
			// remaining DML row queries for contacts
			getEBSAccounts(retval,getQueryRows(0)/3);
			// use all the remaining dml row queries for addresses
			getAddresses(retval,0);
		}
		return retval;
	}

	Id blankValue(Id value,Id defaultValue) {
		if(value == null) {
			value = defaultValue;
		}
		return value;
	}

	global static void addToLog(
		List<DuplicateLog__c> duplicateLogList,
		Id masterRecordId,
		Id duplicateRecordId,
		String objectType,
		String discoveredBy)
	{
		if(masterRecordId != null && duplicateRecordId != null) {
			duplicateLogList.add(new DuplicateLog__c(
				DiscoveredBy__c = discoveredBy,
				DuplicateRecordId__c = duplicateRecordId,
				MasterRecordId__c = masterRecordId,
				ObjectType__c = objectType,
				Status__c = 'Pending'));
		}
		
	}

	/**
	 * Update an the current ebs account and add it to the update list, unless this is a new
	 * masterRecord.  We are assuming records are processed in order with the master record scene
	 * first in the list.
	 * 
	 * @param masterRecord the last scene master record
	 * @param currentRecord the current record we are processing
	 * @param updateList the list of updated records to append
	 * @param duplicateLogList the list of duplicates found or updated
	 * @return the new masterRecord
	 */
	global EBS_Account__c updateEBSAccount(
		EBS_Account__c masterRecord, 
		EBS_Account__c currentRecord,
		List<SObject> updateList,
		List<DuplicateLog__c> duplicateLogList )
	{
		if(currentRecord != null) {
			if(masterRecord == null || currentRecord.Sales_Account__c != masterRecord.Sales_Account__c || currentRecord.Name != masterRecord.Name) {
				masterRecord = currentRecord;
			}
			else {
				Id masterRecordId = null;
				// avoid circular references
				if(currentRecord.Id != masterRecord.MasterRecord__c) {
					currentRecord.Status__c = 'Inactive';
					masterRecordId = blankValue(masterRecord.MasterRecord__c,masterRecord.Id);
					addToLog(duplicateLogList,masterRecordId,currentRecord.Id,'EBS Account',discoveredBy);
				}
				currentRecord.MasterRecord__c = masterRecordId;
				updateList.add(currentRecord);
			}
		}
		return masterRecord;
	}

	/**
	 * Update an the current address and add it to the update list, unless this is a new
	 * masterRecord.  We are assuming records are processed in order with the master record scene
	 * first in the list.
	 * 
	 * @param masterRecord the last scene master record
	 * @param currentRecord the current record we are processing
	 * @param updateList the list of updated records to append
	 * @param duplicateLogList the list of duplicates found or updated
	 * @return the new masterRecord
	 */
	global Address__c updateAddress(
		Address__c masterRecord,
		Address__c currentRecord ,
		List<SObject> updateList,
		List<DuplicateLog__c> duplicateLogList )
	{
		if(currentRecord != null) {
			Boolean isUpdated = (currentRecord.Reparented__c != false);
			if(masterRecord == null || currentRecord.Sales_Account__c != masterRecord.Sales_Account__c || currentRecord.CDH_Party_Site_Number__c != masterRecord.CDH_Party_Site_Number__c) {
				masterRecord = currentRecord;
			}
			else {
				Id masterRecordId = null;
				// avoid circular references
				if(currentRecord.Id != masterRecord.MasterRecord__c) {
					if(currentRecord.IsDuplicate__c != true) {
						currentRecord.IsDuplicate__c = true;
						isUpdated =true;
					}
					masterRecordId = blankValue(masterRecord.MasterRecord__c,masterRecord.Id);
					addToLog(duplicateLogList,masterRecordId,currentRecord.Id,'Address',discoveredBy);
				}
				if(currentRecord.MasterRecord__c != masterRecordId) {
					currentRecord.MasterRecord__c = masterRecordId;
					isUpdated = true;
				}
			}
			if(isUpdated) {
				currentRecord.Reparented__c = false;
				updateList.add(currentRecord);
			}
		}
		return masterRecord;
	}

	/**
	 * Update an the current address and add it to the update list, unless this is a new
	 * masterRecord.  We are assuming records are processed in order with the master record scene
	 * first in the list.
	 * 
	 * @param masterRecord the last scene master record
	 * @param currentRecord the current record we are processing
	 * @param updateList the list of updated records to append
	 * @param duplicateLogList the list of duplicates found or updated
	 * @return the new masterRecord
	 */
	global Contact updateContact(
		Contact masterRecord,
		Contact currentRecord,
		List<SObject> updateList,
		List<DuplicateLog__c> duplicateLogList )
	{
		if(currentRecord != null) {
			if(masterRecord == null || currentRecord.AccountId != masterRecord.AccountId || currentRecord.CDH_Party__c != masterRecord.CDH_Party__c) {
				masterRecord = currentRecord;
			}
			else {
				Id masterRecordId = null;
				// avoid circular references
				if(currentRecord.Id != masterRecord.MasterRecord__c) {
					currentRecord.Status__c = 'Inactive';
					masterRecordId = blankValue(masterRecord.MasterRecord__c,masterRecord.Id);
					addToLog(duplicateLogList,masterRecordId,currentRecord.Id,'Contact',discoveredBy);
				}
				currentRecord.MasterRecord__c = masterRecordId;
			}
			currentRecord.Reparented__c = false;
			updateList.add(currentRecord);
		}
		return masterRecord;
	}


	/**
	 * Called to execute a subset of the inserts, updates, and deletes.
	 * 
	 * @param bc the batchable context (not used)
	 * @param accounts the list to update
	 */
	global void execute(Database.BatchableContext bc, List<SObject> records) {
		List<SObject> updateList = new List<SObject>();
		List<DuplicateLog__c> duplicateLogList = new List<DuplicateLog__c>();
		EBS_Account__c masterEBSAccount = null;
		Address__c masterAddress = null;
		Contact masterContact = null;
		for(SObject o : records) {
			if(o instanceof EBS_Account__c) {
				masterEBSAccount = updateEBSAccount(masterEBSAccount,(EBS_Account__c)o,updateList,duplicateLogList);
			}
			else if(o instanceof Address__c) {
				masterAddress = updateAddress(masterAddress,(Address__c)o,updateList,duplicateLogList);
			}
			else if(o instanceof Contact) {
				masterContact = updateContact(masterContact,(Contact)o,updateList,duplicateLogList);
			}
		}
		if(! updateList.isEmpty()) {
			for(Database.SaveResult result : Database.update(updateList,false)) {
				SObject o = updateList.remove(0);
				if(! result.isSuccess()) {
					errorList.add('Failed to update record '+o+': '+result.getErrors());
				}
			}
			if(! duplicateLogList.isEmpty()) {
				for(Database.UpsertResult result : Database.upsert(duplicateLogList,DuplicateLog__c.Fields.DuplicateRecordId__c,false)) {
					DuplicateLog__c dl = duplicateLogList.remove(0);
					if(! result.isSuccess()) {
						errorList.add('Failed to upsert record '+dl+': '+result.getErrors());
					}
				}
			}
		}
		// email any errors that resulted in an uncaught exception
		if(! errorList.isEmpty()) {
			super.finish(lookupJob(bc));
		}
	}
}