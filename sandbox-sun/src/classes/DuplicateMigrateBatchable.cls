/**
 * This class migrates duplicates found in the DuplicatesLog__c.
 * 
 * @version 2015-11-26
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-09-02 - created
 * 2015-11-26 - Make sure we update records at the end of every job to help avoid recursion
 */
global class DuplicateMigrateBatchable extends AbstractBatchable {
	global static Integer getIntegerSettingValue(String name,Integer retval) {
		LongSetting__c ls = LongSetting__c.getInstance(name);
		if(ls != null && ls.Value__c != null) {
			retval = ls.Value__c.intValue();
		}
		return retval;
	}
	global static final Integer UPDATE_SCOPE = getIntegerSettingValue('DuplicateMigration.Scope',2000);
	global static final Integer FAILED_MIGRATION_LIMIT = getIntegerSettingValue('DuplicateMigration.MaxFailures',8000);

	/**
	 * Default constructor.
	 */
	global DuplicateMigrateBatchable() {
		super('DuplicateMigrateBatchable');
	}

	/**
	 * Check if there is work for this job to do.
	 *
	 * @return false if there is no work to do.
	 */
	global override Boolean hasWork() {
		return [ 
			select count()
			from DuplicateLog__c
			where MasterRecordId__c != null
				and DuplicateRecordId__c != null
				and ObjectType__c in ('Address','EBS Account')
				and Status__c in ('Pending','In Progress')
				and FailedMigrations__c <= :FAILED_MIGRATION_LIMIT
				// exclude deleted records
				and ( MasterAddress__r.Id != null or MasterEBSAccount__r.Id != null )
				and ( Opportunities_Migrated__c != true
					or Staging_Headers_Migrated__c != true
					or Staging_Lines_Migrated__c != true
					or OM_Profiles_Migrated__c != true
					or Subscriptions_Migrated__c != true
					or Subscription_Lines_Migrated__c != true
					or Products_Migrated__c != true )
			limit 1 ] > 0;
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator([
			select Id,
				DuplicateRecordId__c,
				MasterRecordId__c,
				ObjectType__c,
				Opportunities_Migrated__c,
				Products_Migrated__c,
				Staging_Headers_Migrated__c,
				Staging_Lines_Migrated__c,
				OM_Profiles_Migrated__c,
				Subscriptions_Migrated__c,
				Subscription_Lines_Migrated__c
			from DuplicateLog__c
			where MasterRecordId__c != null
				and DuplicateRecordId__c != null
				and ObjectType__c in ('Address','EBS Account')
				and Status__c in ('Pending','In Progress')
				and FailedMigrations__c <= :FAILED_MIGRATION_LIMIT
				// exclude deleted records
				and ( MasterAddress__r.Id != null or MasterEBSAccount__r.Id != null )
				and ( Opportunities_Migrated__c != true
					or Staging_Headers_Migrated__c != true
					or Staging_Lines_Migrated__c != true
					or OM_Profiles_Migrated__c != true
					or Subscriptions_Migrated__c != true
					or Subscription_Lines_Migrated__c != true
					or Products_Migrated__c != true )
			order by
				Status__c,
				SuccessfulMigrations__c desc,
				DuplicateRecordId__c,
				MasterRecordId__c,
				OM_Profiles_Migrated__c nulls first,
				Staging_Headers_Migrated__c nulls first,
				Staging_Lines_Migrated__c nulls first,
				Subscriptions_Migrated__c nulls first,
				Subscription_Lines_Migrated__c nulls first,
				Opportunities_Migrated__c nulls first,
				Products_Migrated__c nulls first,
				ObjectType__c desc ]);
	}

	global static void addToDuplicateLogMap(
		Map<Id,DuplicateLog__c> duplicateLogAddressMap,
		Map<Id,DuplicateLog__c> duplicateLogEBSAccountMap,
//out-of-scope		Map<Id,DuplicateLog__c> duplicateLogContactMap,
		DuplicateLog__c dlog )
	{
		if(dlog != null && dlog.DuplicateRecordId__c != null && dlog.DuplicateRecordId__c.length() >= 15) {
			Map<Id,DuplicateLog__c> duplicateLogMap = null;
			if(dlog.ObjectType__c == 'Address') {
				duplicateLogMap = duplicateLogAddressMap;
			}
			else if(dlog.ObjectType__c == 'EBS Account') {
				duplicateLogMap = duplicateLogEBSAccountMap;
			}
//out-of-scope			else if(dlog.ObjectType__c == 'Contact') {
//out-of-scope				duplicateLogMap = duplicateLogContactMap;
//out-of-scope			}
			try {
				Id targetRecordId = (Id)dlog.MasterRecordId__c;
				if(targetRecordId != null) {
					duplicateLogMap.put((Id)dlog.DuplicateRecordId__c,dlog);
				}
			}
			catch(Exception ex) {}
		}
	}

	global static DuplicateMigrationLog__c putDuplicateMigrationLog(
		Map<String,DuplicateMigrationLog__c> migrationLogMap,
		Map<Id,Set<DuplicateMigrationLog__c>> migrationLogSetMap,
		DuplicateLog__c dlog,
		Id recordId,
		String objectType,
		String fieldName)
	{
		Id masterRecordId = (Id)dlog.MasterRecordId__c;
		String key = objectType+':'+masterRecordId+':'+recordId;
		DuplicateMigrationLog__c migrationLog = migrationLogMap.get(key);
		if(migrationLog == null) {
			migrationLog = new DuplicateMigrationLog__c(
				DuplicateLog__c=dlog.Id,
				ExternalId__c=key,
				FieldName__c=fieldName,
				MasterRecordId__c=masterRecordId,
				ObjectType__c=objectType,
				RecordId__c = recordId,
				Status__c = 'Success' );
			migrationLogMap.put(key,migrationLog);
			Set<DuplicateMigrationLog__c> migrationLogSet = migrationLogSetMap.get(recordId);
			if(migrationLogSet == null) {
				migrationLogSet = new Set<DuplicateMigrationLog__c>();
				migrationLogSetMap.put(recordId,migrationLogSet);
			}
			migrationLogSet.add(migrationLog);
		}
		else {
			migrationLog.FieldName__c += ';'+fieldName;
		}
		return migrationLog;
	}

	global static void updateSObjects(List<SObject> sobjects,Map<Id,Set<DuplicateMigrationLog__c>> migrationLogSetMap) {
		// update order management profiles
		for(Database.SaveResult result : Database.update(sobjects,false)) {
			SObject o = sobjects.remove(0);
			if(! result.isSuccess()) {
				for(DuplicateMigrationLog__c migrationLog : migrationLogSetMap.get(o.Id)) {
					migrationLog.Status__c = 'Failure';
					String errorMessage = (''+result.getErrors());
					if(errorMessage.length() > 255) {
						errorMessage = errorMessage.substring(0,255);
					}
					migrationLog.ErrorMessage__c = errorMessage;
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
	global void execute(Database.BatchableContext bc, List<DuplicateLog__c> records) {
		if(! records.isEmpty()) {
			Map<Id,DuplicateLog__c> duplicateLogAddressMap = new Map<Id,DuplicateLog__c>();
			Map<Id,DuplicateLog__c> duplicateLogEBSAccountMap = new Map<Id,DuplicateLog__c>();
//out-of-scope			Map<Id,DuplicateLog__c> duplicateLogContactMap = new Map<Id,DuplicateLog__c>();
			Map<String,DuplicateMigrationLog__c> migrationLogMap = new Map<String,DuplicateMigrationLog__c>();
			Map<Id,Set<DuplicateMigrationLog__c>> migrationLogSetMap = new Map<Id,Set<DuplicateMigrationLog__c>>();
			Boolean needOpportunityMigration = false;
			Boolean needProductMigration = false;
			Boolean needStagingHeaderMigration = false;
			Boolean needStagingLineMigration = false;
			Boolean needSubscriptionMigration = false;
			Boolean needSubscriptionLineMigration = false;
			Boolean needOMProfileMigration = false;
			for(DuplicateLog__c dlog : records) {
				needOpportunityMigration = needOpportunityMigration || (dlog.Opportunities_Migrated__c != true);
				needProductMigration = needProductMigration || (dlog.Products_Migrated__c != true);
				needStagingHeaderMigration = needStagingHeaderMigration || (dlog.Staging_Headers_Migrated__c != true);
				needStagingLineMigration = needStagingLineMigration || (dlog.Staging_Lines_Migrated__c != true);
				needSubscriptionMigration = needSubscriptionMigration || (dlog.Subscriptions_Migrated__c != true);
				needSubscriptionLineMigration = needSubscriptionLineMigration || (dlog.Subscription_Lines_Migrated__c != true);
				needOMProfileMigration = needOMProfileMigration || (dlog.OM_Profiles_Migrated__c != true);
				addToDuplicateLogMap(
					duplicateLogAddressMap,
					duplicateLogEBSAccountMap,
//out-of-scope					duplicateLogContactMap,
					dlog);
			}
			final Set<Id> addressIds = duplicateLogAddressMap.keySet();
			final Set<Id> ebsAccountIds = duplicateLogEBSAccountMap.keySet();
//out-of-scope			final Set<Id> contactIds = duplicateLogContactMap.keySet();
			Integer updateScope = UPDATE_SCOPE;
			if(needOMProfileMigration && updateScope > 0) {
				// migrate order management profiles
				List<Order_Management_Profile__c> omProfiles = [
					select Id,
//out-of-scope						Bill_To_Contact__c,
						Bill_To_EBS_Account__c,
						Bill_To_Address__c,
//out-of-scope						Entitle_To_Contact__c,
						Entitle_To_EBS_Account__c,
						Entitle_To_Address__c,
//out-of-scope						Ship_To_Contact__c,
						Ship_To_EBS_Account__c,
						Ship_To_Address__c,
//out-of-scope						Sold_To_Contact__c,
						Sold_To_EBS_Account__c,
						Sold_To_Address__c
					from Order_Management_Profile__c
					where Bill_To_EBS_Account__c in :ebsAccountIds
						or Bill_To_Address__c in :addressIds
//out-of-scope						or Bill_To_Contact__c in :contactIds
						or Entitle_To_EBS_Account__c in :ebsAccountIds
						or Entitle_To_Address__c in :addressIds
//out-of-scope						or Entitle_To_Contact__c in :contactIds
						or Ship_To_EBS_Account__c in :ebsAccountIds
						or Ship_To_Address__c in :addressIds
//out-of-scope						or Ship_To_Contact__c in :contactIds
						or Sold_To_EBS_Account__c in :ebsAccountIds
						or Sold_To_Address__c in :addressIds 
//out-of-scope						or Sold_To_Contact__c in :contactIds 
					limit :updateScope
					FOR UPDATE ];
				if(! omProfiles.isEmpty()) {
					updateScope -= omProfiles.size();
					for(Order_Management_Profile__c omProfile : omProfiles) {
						if(omProfile.Bill_To_EBS_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(omProfile.Bill_To_EBS_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,omProfile.Id,'Order_Management_Profile__c','Bill_To_EBS_Account__c');
								omProfile.Bill_To_EBS_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(omProfile.Bill_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(omProfile.Bill_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,omProfile.Id,'Order_Management_Profile__c','Bill_To_Address__c');
								omProfile.Bill_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(omProfile.Bill_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(omProfile.Bill_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,omProfile.Id,'Order_Management_Profile__c','Bill_To_Contact__c');
//out-of-scope								omProfile.Bill_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
						if(omProfile.Entitle_To_EBS_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(omProfile.Entitle_To_EBS_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,omProfile.Id,'Order_Management_Profile__c','Entitle_To_EBS_Account__c');
								omProfile.Entitle_To_EBS_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(omProfile.Entitle_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(omProfile.Entitle_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,omProfile.Id,'Order_Management_Profile__c','Entitle_To_Address__c');
								omProfile.Entitle_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(omProfile.Entitle_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(omProfile.Entitle_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,omProfile.Id,'Order_Management_Profile__c','Entitle_To_Contact__c');
//out-of-scope								omProfile.Entitle_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
						if(omProfile.Ship_To_EBS_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(omProfile.Ship_To_EBS_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,omProfile.Id,'Order_Management_Profile__c','Ship_To_EBS_Account__c');
								omProfile.Ship_To_EBS_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(omProfile.Ship_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(omProfile.Ship_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,omProfile.Id,'Order_Management_Profile__c','Ship_To_Address__c');
								omProfile.Ship_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(omProfile.Ship_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(omProfile.Ship_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,omProfile.Id,'Order_Management_Profile__c','Ship_To_Contact__c');
//out-of-scope								omProfile.Ship_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
						if(omProfile.Sold_To_EBS_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(omProfile.Sold_To_EBS_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,omProfile.Id,'Order_Management_Profile__c','Sold_To_EBS_Account__c');
								omProfile.Sold_To_EBS_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(omProfile.Sold_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(omProfile.Sold_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,omProfile.Id,'Order_Management_Profile__c','Sold_To_Address__c');
								omProfile.Sold_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(omProfile.Sold_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogAddressMap.get(omProfile.Sold_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,omProfile.Id,'Order_Management_Profile__c','Sold_To_Contact__c');
//out-of-scope								omProfile.Sold_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
					}
					updateSObjects(omProfiles,migrationLogSetMap);
				}
			}
			if(needStagingHeaderMigration && updateScope > 0) {
				// migrate opportunity header staging records
				List<Opportunity_Header_Staging__c> ohsList = [
					select Id,
//out-of-scope						Bill_To_Contact__c,
						Bill_To_Account__c,
						Bill_To_Address__c,
//out-of-scope						Entitle_To_Contact__c,
						Entitle_To_Account__c,
						Entitle_To_Address__c,
//out-of-scope						Ship_To_Contact__c,
						Ship_To_Account__c,
						Ship_To_Address__c,
//out-of-scope						Sold_To_Contact__c,
						Sold_To_Account__c,
						Sold_To_Address__c
					from Opportunity_Header_Staging__c
					where Bill_To_Account__c in :ebsAccountIds
						or Bill_To_Address__c in :addressIds
//out-of-scope						or Bill_To_Contact__c in :contactIds
						or Entitle_To_Account__c in :ebsAccountIds
						or Entitle_To_Address__c in :addressIds
//out-of-scope						or Entitle_To_Contact__c in :contactIds
						or Ship_To_Account__c in :ebsAccountIds
						or Ship_To_Address__c in :addressIds
//out-of-scope						or Ship_To_Contact__c in :contactIds
						or Sold_To_Account__c in :ebsAccountIds
						or Sold_To_Address__c in :addressIds 
//out-of-scope						or Sold_To_Contact__c in :contactIds 
					limit :updateScope
					FOR UPDATE ];
				if(! ohsList.isEmpty()) {
					updateScope -= ohsList.size();
					for(Opportunity_Header_Staging__c ohs : ohsList) {
						if(ohs.Bill_To_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(ohs.Bill_To_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ohs.Id,'Opportunity_Header_Staging__c','Bill_To_Account__c');
								ohs.Bill_To_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(ohs.Bill_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(ohs.Bill_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ohs.Id,'Opportunity_Header_Staging__c','Bill_To_Address__c');
								ohs.Bill_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(ohs.Bill_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(ohs.Bill_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ohs.Id,'Opportunity_Header_Staging__c','Bill_To_Contact__c');
//out-of-scope								ohs.Bill_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
						if(ohs.Entitle_To_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(ohs.Entitle_To_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ohs.Id,'Opportunity_Header_Staging__c','Entitle_To_Account__c');
								ohs.Entitle_To_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(ohs.Entitle_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(ohs.Entitle_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ohs.Id,'Opportunity_Header_Staging__c','Entitle_To_Address__c');
								ohs.Entitle_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(ohs.Entitle_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(ohs.Entitle_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ohs.Id,'Opportunity_Header_Staging__c','Entitle_To_Contact__c');
//out-of-scope								ohs.Entitle_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
						if(ohs.Ship_To_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(ohs.Ship_To_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ohs.Id,'Opportunity_Header_Staging__c','Ship_To_Account__c');
								ohs.Ship_To_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(ohs.Ship_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(ohs.Ship_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ohs.Id,'Opportunity_Header_Staging__c','Ship_To_Address__c');
								ohs.Ship_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(ohs.Ship_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(ohs.Ship_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ohs.Id,'Opportunity_Header_Staging__c','Ship_To_Contact__c');
//out-of-scope								ohs.Ship_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
						if(ohs.Sold_To_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(ohs.Sold_To_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ohs.Id,'Opportunity_Header_Staging__c','Sold_To_Account__c');
								ohs.Sold_To_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(ohs.Sold_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(ohs.Sold_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ohs.Id,'Opportunity_Header_Staging__c','Sold_To_Address__c');
								ohs.Sold_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(ohs.Sold_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogAddressMap.get(ohs.Sold_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ohs.Id,'Opportunity_Header_Staging__c','Sold_To_Contact__c');
//out-of-scope								ohs.Sold_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
					}
					updateSObjects(ohsList,migrationLogSetMap);
				}
			}
			if(needStagingLineMigration && updateScope > 0) {
				// migrate opportunity line staging records
				List<Opportunity_Line_Staging__c> olsList = [
					select Id,
//out-of-scope						Entitle_To_Contact__c,
						Entitle_To_Account__c,
						Entitle_To_Address__c
					from Opportunity_Line_Staging__c
					where Entitle_To_Account__c in :ebsAccountIds
						or Entitle_To_Address__c in :addressIds
//out-of-scope						or Entitle_To_Contact__c in :contactIds
					limit :updateScope
					FOR UPDATE ];
				if(! olsList.isEmpty()) {
					updateScope -= olsList.size();
					for(Opportunity_Line_Staging__c ols : olsList) {
						if(ols.Entitle_To_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(ols.Entitle_To_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ols.Id,'Opportunity_Line_Staging__c','Entitle_To_Account__c');
								ols.Entitle_To_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(ols.Entitle_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(ols.Entitle_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ols.Id,'Opportunity_Line_Staging__c','Entitle_To_Address__c');
								ols.Entitle_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(ols.Entitle_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(ols.Entitle_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,ols.Id,'Opportunity_Line_Staging__c','Entitle_To_Contact__c');
//out-of-scope								ols.Entitle_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
					}
					updateSObjects(olsList,migrationLogSetMap);
				}
			}
			if(needSubscriptionMigration && updateScope > 0) {
				// migrate subscription records
				List<Subscription__c> subscriptions = [
					select Id,
//out-of-scope						SellingContact__c,
//out-of-scope						ShippingContact__c,
//out-of-scope						BillToContact__c,
						BillToEBSAccount__c,
						BillToAddress__c,
//out-of-scope						EntitleToContact__c,
						EntitleToEBSAccount__c,
						EntitleToAddress__c,
//out-of-scope						ShipToContact__c,
						ShipToEBSAccount__c,
						ShipToAddress__c,
//out-of-scope						SoldToContact__c,
						SoldToEBSAccount__c,
						SoldToAddress__c
					from Subscription__c
					where BillToEBSAccount__c in :ebsAccountIds
						or BillToAddress__c in :addressIds
//out-of-scope						or BillToContact__c in :contactIds
						or EntitleToEBSAccount__c in :ebsAccountIds
						or EntitleToAddress__c in :addressIds
//out-of-scope						or EntitleToContact__c in :contactIds
						or ShipToEBSAccount__c in :ebsAccountIds
						or ShipToAddress__c in :addressIds
//out-of-scope						or ShipToContact__c in :contactIds
						or SoldToEBSAccount__c in :ebsAccountIds
						or SoldToAddress__c in :addressIds 
//out-of-scope						or SoldToContact__c in :contactIds 
//out-of-scope						or SellingContact__c in :contactIds
//out-of-scope						or ShippingContact__c in :contactIds
					limit :updateScope
					FOR UPDATE ];
				if(! subscriptions.isEmpty()) {
					updateScope -= subscriptions.size();
					for(Subscription__c subscription : subscriptions) {
						if(subscription.BillToEBSAccount__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(subscription.BillToEBSAccount__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','BillToEBSAccount__c');
								subscription.BillToEBSAccount__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(subscription.BillToAddress__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(subscription.BillToAddress__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','BillToAddress__c');
								subscription.BillToAddress__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(subscription.BillToContact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(subscription.BillToContact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','BillToContact__c');
//out-of-scope								subscription.BillToContact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
						if(subscription.EntitleToEBSAccount__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(subscription.EntitleToEBSAccount__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','EntitleToEBSAccount__c');
								subscription.EntitleToEBSAccount__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(subscription.EntitleToAddress__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(subscription.EntitleToAddress__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','EntitleToAddress__c');
								subscription.EntitleToAddress__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(subscription.EntitleToContact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(subscription.EntitleToContact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','EntitleToContact__c');
//out-of-scope								subscription.EntitleToContact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
						if(subscription.ShipToEBSAccount__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(subscription.ShipToEBSAccount__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','ShipToEBSAccount__c');
								subscription.ShipToEBSAccount__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(subscription.ShipToAddress__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(subscription.ShipToAddress__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','ShipToAddress__c');
								subscription.ShipToAddress__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(subscription.ShipToContact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(subscription.ShipToContact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','ShipToContact__c');
//out-of-scope								subscription.ShipToContact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
						if(subscription.SoldToEBSAccount__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(subscription.SoldToEBSAccount__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','SoldToEBSAccount__c');
								subscription.SoldToEBSAccount__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(subscription.SoldToAddress__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(subscription.SoldToAddress__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','SoldToAddress__c');
								subscription.SoldToAddress__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(subscription.SoldToContact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogAddressMap.get(subscription.SoldToContact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','SoldToContact__c');
//out-of-scope								subscription.SoldToContact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
//out-of-scope						if(subscription.SellingContact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogAddressMap.get(subscription.SellingContact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','SellingContact__c');
//out-of-scope								subscription.SellingContact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
//out-of-scope						if(subscription.ShippingContact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogAddressMap.get(subscription.ShippingContact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscription.Id,'Subscription__c','ShippingContact__c');
//out-of-scope								subscription.ShippingContact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
					}
					updateSObjects(subscriptions,migrationLogSetMap);
				}
			}
			if(needSubscriptionLineMigration && updateScope > 0) {
				// migrate subscriptionLine records
				List<SubscriptionLine__c> subscriptionLines = [
					select Id,
//out-of-scope						EntitleToContact__c,
						EntitleToEBSAccount__c,
						EntitleToAddress__c
					from SubscriptionLine__c
					where EntitleToEBSAccount__c in :ebsAccountIds
						or EntitleToAddress__c in :addressIds
//out-of-scope						or EntitleToContact__c in :contactIds
					limit :updateScope
					FOR UPDATE ];
				if(! subscriptionLines.isEmpty()) {
					updateScope -= subscriptionLines.size();
					for(SubscriptionLine__c subscriptionLine : subscriptionLines) {
						if(subscriptionLine.EntitleToEBSAccount__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(subscriptionLine.EntitleToEBSAccount__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscriptionLine.Id,'SubscriptionLine__c','EntitleToEBSAccount__c');
								subscriptionLine.EntitleToEBSAccount__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(subscriptionLine.EntitleToAddress__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(subscriptionLine.EntitleToAddress__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscriptionLine.Id,'SubscriptionLine__c','EntitleToAddress__c');
								subscriptionLine.EntitleToAddress__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(subscriptionLine.EntitleToContact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(subscriptionLine.EntitleToContact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,subscriptionLine.Id,'SubscriptionLine__c','EntitleToContact__c');
//out-of-scope								subscriptionLine.EntitleToContact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
					}
					updateSObjects(subscriptionLines,migrationLogSetMap);
				}
			}
			if(needOpportunityMigration && updateScope > 0) {
				// migrate opportunities
				List<Opportunity> opps = [
					select Id,
//out-of-scope						Account_Solution_Architect__c,
//out-of-scope						Bill_To_Contact__c,
						Bill_To_Account__c,
						Bill_To_Address__c,
//out-of-scope						Entitle_To_Contact__c,
						Entitle_To_Account__c,
						Entitle_To_Address__c,
//out-of-scope						Ship_To_Contact__c,
						Ship_To_Account__c,
						Ship_To_Address__c,
//out-of-scope						Sold_To_Contact__c,
						Sold_To_Account__c,
						Sold_To_Address__c
					from Opportunity
					where Bill_To_Account__c in :ebsAccountIds
						or Bill_To_Address__c in :addressIds
//out-of-scope						or Bill_To_Contact__c in :contactIds
						or Entitle_To_Account__c in :ebsAccountIds
						or Entitle_To_Address__c in :addressIds
//out-of-scope						or Entitle_To_Contact__c in :contactIds
						or Ship_To_Account__c in :ebsAccountIds
						or Ship_To_Address__c in :addressIds
//out-of-scope						or Ship_To_Contact__c in :contactIds
						or Sold_To_Account__c in :ebsAccountIds
						or Sold_To_Address__c in :addressIds 
//out-of-scope						or Sold_To_Contact__c in :contactIds 
//out-of-scope						or Account_Solutions_Architect__c in :contactIds 
//out-of-scope						or Services_Program_Manager__c in :contactIds 
//out-of-scope						or ShippingContact__c in :contactIds 
//out-of-scope						or Specialist_Solutions_Architect__c in :contactIds 
					limit :updateScope
					FOR UPDATE ];
				if(! opps.isEmpty()) {
					updateScope -= opps.size();
					for(Opportunity opp : opps) {
						if(opp.Bill_To_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(opp.Bill_To_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Bill_To_Account__c');
								opp.Bill_To_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(opp.Bill_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(opp.Bill_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Bill_To_Address__c');
								opp.Bill_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(opp.Bill_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(opp.Bill_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Bill_To_Contact__c');
//out-of-scope								opp.Bill_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
						if(opp.Entitle_To_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(opp.Entitle_To_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Entitle_To_Account__c');
								opp.Entitle_To_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(opp.Entitle_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(opp.Entitle_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Entitle_To_Address__c');
								opp.Entitle_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(opp.Entitle_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(opp.Entitle_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Entitle_To_Contact__c');
//out-of-scope								opp.Entitle_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
						if(opp.Ship_To_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(opp.Ship_To_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Ship_To_Account__c');
								opp.Ship_To_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(opp.Ship_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(opp.Ship_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Ship_To_Address__c');
								opp.Ship_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(opp.Ship_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogContactMap.get(opp.Ship_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Ship_To_Contact__c');
//out-of-scope								opp.Ship_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
						if(opp.Sold_To_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(opp.Sold_To_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Sold_To_Account__c');
								opp.Sold_To_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(opp.Sold_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(opp.Sold_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Sold_To_Address__c');
								opp.Sold_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(opp.Sold_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogAddressMap.get(opp.Sold_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Sold_To_Contact__c');
//out-of-scope								opp.Sold_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
//out-of-scope						if(opp.Account_Solutions_Architect__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogAddressMap.get(opp.Account_Solutions_Architect__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Account_Solutions_Architect__c');
//out-of-scope								opp.Account_Solutions_Architect__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
//out-of-scope						if(opp.Services_Program_Manager__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogAddressMap.get(opp.Services_Program_Manager__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Services_Program_Manager__c');
//out-of-scope								opp.Services_Program_Manager__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
//out-of-scope						if(opp.ShippingContact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogAddressMap.get(opp.ShippingContact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','ShippingContact__c');
//out-of-scope								opp.ShippingContact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
//out-of-scope						if(opp.Specialist_Solutions_Architect__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogAddressMap.get(opp.Specialist_Solutions_Architect__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,opp.Id,'Opportunity','Specialist_Solutions_Architect__c');
//out-of-scope								opp.Specialist_Solutions_Architect__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
					}
					updateSObjects(opps,migrationLogSetMap);
				}
			}
			if(needProductMigration && updateScope > 0) {
				// migrate opportunities
				List<OpportunityLineItem> oppLines = [
					select Id,
//out-of-scope						Entitle_To_Contact__c,
						Entitle_To_Account__c,
						Entitle_To_Address__c
					from OpportunityLineItem
					where Entitle_To_Account__c in :ebsAccountIds
						or Entitle_To_Address__c in :addressIds
//out-of-scope						or Entitle_To_Contact__c in :contactIds
					limit :updateScope
					FOR UPDATE ];
				if(! oppLines.isEmpty()) {
					updateScope -= oppLines.size();
					for(OpportunityLineItem oppLine : oppLines) {
						if(oppLine.Entitle_To_Account__c != null) {
							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(oppLine.Entitle_To_Account__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,oppLine.Id,'OpportunityLineItem','Entitle_To_Account__c');
								oppLine.Entitle_To_Account__c = (Id)dlog.MasterRecordId__c;
							}
						}
						if(oppLine.Entitle_To_Address__c != null) {
							DuplicateLog__c dlog = duplicateLogAddressMap.get(oppLine.Entitle_To_Address__c);
							if(dlog != null) {
								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,oppLine.Id,'OpportunityLineItem','Entitle_To_Address__c');
								oppLine.Entitle_To_Address__c = (Id)dlog.MasterRecordId__c;
							}
						}
//out-of-scope						if(oppLine.Entitle_To_Contact__c != null) {
//out-of-scope							DuplicateLog__c dlog = duplicateLogEBSAccountMap.get(oppLine.Entitle_To_Contact__c);
//out-of-scope							if(dlog != null) {
//out-of-scope								putDuplicateMigrationLog(migrationLogMap,migrationLogSetMap,dlog,oppLine.Id,'OpportunityLineItem','Entitle_To_Contact__c');
//out-of-scope								oppLine.Entitle_To_Contact__c = (Id)dlog.MasterRecordId__c;
//out-of-scope							}
//out-of-scope						}
					}
					updateSObjects(oppLines,migrationLogSetMap);
				}
			}
			if(! migrationLogMap.isEmpty()) {
				List<DuplicateMigrationLog__c> migrationLogs = migrationLogMap.values().clone();
				for(Database.UpsertResult result : Database.upsert(migrationLogs,DuplicateMigrationLog__c.Fields.ExternalId__c,false)) {
					DuplicateMigrationLog__c migrationLog = migrationLogs.remove(0);
					if(! result.isSuccess()) {
						errorList.add('Failed to update record '+migrationLog+' : '+result.getErrors());
					}
				}
			}
			Database.update(records,false);
			// email any errors that resulted in an uncaught exception
			if(! errorList.isEmpty()) {
				super.finish(lookupJob(bc));
			}
		}
	}
}