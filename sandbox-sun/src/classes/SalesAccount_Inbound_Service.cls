/**
 * This class will take care the business logic to process CDH Party data.
 *	- Sales Account
 *	- Address
 *	- Contact
 * 
 * @version 2016-02-22
 * 
 * @author Vipul Jain
 * @since 2014-10-31 - Updated the class to remove mapping of contact points in case of contact update/sales account update and
 *		maintain the contact point mapping for the sales account creation scenario (US56664-TA154960 ,TA154961)
 * @since 2014-08-13 - Record type assignment of the account record being created through CDH->SFDC Interface.
 *		Record type assignment based on region of country.
 *		 - Momentum Ticket Number : RH-00343537
 * @since 2014-06-19 - Created
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2016-02-22 - Support multiple sales account ids
 * @since 2015-12-01 - DE9454 - allow addresses to have identifying addresses, improve address clone functionality.  Various bug fixes.
 * @since 2015-11-24 - US77119 - Ignore record type errors
 * @since 2015-11-05 - Added boolean setting to allow site merge
 * @since 2015-09-10 - US69489 - update all addresses, changes comment with story number
 * @since 2015-06-17 - For User Story US69226 - Removed assign owner id before update.
 * @since 2015-05-28 - For User Story US67948
 *			 -  Assign a default owner for accounts based the RecordTypeLookup__c table
 * @author Sagar Mehta
 * @since 2015-01-08 - For User Story DE7587
 *		- Hierarchy Relationships created in reverse in SFDC via the CDH Party Inbound
 * @since 2015-01-05 - For User Story DE7588
 *		- Exceptions in SFDC inbound message business logic layer do not result in outbound error message
 * @since 2014-12-15 - For User Story US55552
 *		- Ability to create/update partner CDH -> SFDC
 * @author Neha Jaiswal
 * @since 2014-12-01 - For User Story US55552
 *		- Ability to create/update partner CDH -> SFDC
 * @author Scott Coleman <scoleman@redhat.com>
 * @since 2015-11-18 - US73124, don't clone addresses to newly created partner accounts
 * @since 2015-11-04 - Temporarily disabling site merge for November deployment
 * @since 2015-10-14 - Now handling CDH party site merges
 * @since 2015-07-01 - For User Story US66997, add handling for parties merged in CDH US66997
 * @author Mark Smith <masmith@redhat.com>
 * @since 2015-09-28 - US72170 - Ignore Unaffiliated updates to partner programs created by CDH.
 */
public with sharing class  SalesAccount_Inbound_Service{
	/** Name of BooleanSetting__c value to allow/disallow site merge. */
	public static final String ALLOW_SITE_MERGE_SETTING = 'CDH.AllowSiteMerge';

	private Set<Id> addressSalesAccountIds = new Set<Id>(); // DE9454 - We need all the account ids, not just one
	private String cdhPartyNumber;
	private string BillingCountry;
	private String headQuarterNumber;
	private String partnerRecordTypeId;
	private String globalUltimateNumber;
	private String domesticUltimateNumber;
	private String partnerRegion;
	private String partnerSubregion;

	private boolean errorFlag = true;
	private boolean cdhMasteredFlag = false;

	private List<Account> partnerAccountList = new List<Account>();
	private List<Account> updatedPartnerAccountList = new List<Account>();
	private List<Account> insertedPartnerAccountList = new List<Account>();
	// variable to hold the List of CDH Party records to be processed.
	private List<CDH_Party__c> cdhPartyListToBeProcessed = new List<CDH_Party__c>();

	// variable to hold the set of CDH Party records to be processed.
	private Set<Id> updatedAccountIdSet = new Set<Id>();
	private Set<String> setOfInsertCDHMasteredCode = new Set<String>();
	private Set<CDH_Party__c> setofCDHPartyToBeProcessed = new Set<CDH_Party__c>();

	// map to hold the CDH Party# and it`s associated Sales Account
	private Map<String, Account> ppdIDAccountMap = new Map<String, Account>();
	private Map<String, String> mapCDHWithProgramDefinition = new Map<String, String>();
	private Map<String, Account> classificationCodeAccountMap = new Map<String, Account>();
	private Map<String,CDH_Party__c> mapOfCDHPartyNumberandCDHPartyRecord = new map<String,CDH_Party__c>();
	private Map<String, List<Partner_Program_Tier__c>> mapCodeWithMatchedTier = new Map<String, List<Partner_Program_Tier__c>>();
	private Map<String, IntegrationObjects.Classification> mapCodeStatusInInbound = new Map<String, IntegrationObjects.Classification>();

	private static String ACTIVE = 'Active';
	private static String APPROVED = 'Approved';
	private static String INACTIVE = 'Inactive';
	private static String NO_MATCHING_TIER_ERROR_MESSAGE = 'No matched tier exists in system';
	private static String MORE_THAN_ONE_TIER_ERROR_MESSAGE = 'More then one matched tier exists in system';
	private static String MULTIPLE_ACTIVE_SAME_CDH_ERROR_MESSAGE = 'More than one active classification codes.';
	private static String CDH_PARTY_REQUIRED_ERROR_MESSAGE = 'CDH Party# is required to process Sales Account data';
	private static String CDHPARTY_REQUIRED_FOR_ADDRESS = 'CDH Party Site# is required to process the address data.';
	private static String CDHPARTY_REQUIRED_FOR_CONTACT = 'CDH Party # and CDH Person Party# is required to process contact data';
	private static String MULTIPLE_PPD_SAME_CDH_ERROR_MESSAGE = 'More than one partner program definition record exists under same CDH.';
	private static String MULTIPLE_CODE_SAME_PARTNER_PROGRAM = 'All the codes for the same Partner Program are either active or inactive.';

	private static Id getDefaultOwnerId(Id recordTypeId) {
		RecordTypeFields__c rtf = RecordTypeFields__c.getInstance((String)recordTypeId);
		Id retval = null;
		if(rtf != null) {
			retval = rtf.DefaultOwnerId__c;
		}
		if(retval == null) {
			retval = UserInfo.getUserId();
		}
		return retval;
	}

	// Method added for US77119.  Get the record type id without null exceptions.
	private static Id getRecordTypeId(String recordTypeName) {
		Schema.RecordTypeInfo rti = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordTypeName);
		Id retval = null;
		if(rti != null) {
			retval = rti.getRecordTypeId();
		}
		return retval;
	}

	// Method added for DE9454.  Get the record type name without null exceptions.
	private static String getRecordTypeName(Id recordTypeId) {
		Schema.RecordTypeInfo rti = Account.sObjectType.getDescribe().getRecordTypeInfosById().get(recordTypeId);
		String retval = null;
		if(rti != null) {
			retval = rti.getName();
		}
		return retval;
	}

	private static void upsertIgnoreInvalidAndDeleted(List<SObject> objects) {
		if(objects != null && ! objects.isEmpty()) {
			for(Database.UpsertResult ur : Database.upsert(objects,false)) {
				if(! ur.isSuccess()) {
					String m = String.join(ur.getErrors(),'\n');
					if(m == null 
						|| ( m.indexOf('ENTITY_IS_DELETED') < 0
							&& (m.indexOf('INVALID_CROSS_REFERENCE_KEY') < 0
									|| m.indexOf('RecordTypeId') < 0 ) ) )
					{
						throw new Interface_ServiceException(m);
					}
					System.debug('Error: '+m);
				}
			}
		}
	}

	/**
	 * Method to process business logic for Sales Account data
	 * 
	 * @param account SalesAccount and associated classficiation codes, address, cdh information.
	 */
	public void SalesAccount_Service(IntegrationObjects.SalesAccount account){
		System.debug('$$$$$$ -- > Account : '+account);
		Savepoint savepoint = Database.setSavepoint();

		// US66997
		List<CDH_Party__c> partyMergeVictims = new List<CDH_Party__c>();

		try {
			System.debug('Stop: 1');
			// throw an exception when CDH Party details is missing from the message.
			if(account.CDH_Party_Number == Null || account.CDH_Party_Number.trim().length() ==0){
				errorFlag = false;
				throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + CDH_PARTY_REQUIRED_ERROR_MESSAGE);
				//throw new Interface_ServiceException(CDH_PARTY_REQUIRED_ERROR_MESSAGE);
			}
			// variable to hold the list of accounts to be processed.
			List<Account> accountListToBeProcessed = new List<Account>();

			if(account != Null && account.CDH_Party_Number != Null && account.CDH_Party_Number.trim().length() > 0){
				System.debug('Create Scenario account.CDH_Party_Number: '+account.CDH_Party_Number);
				cdhPartyNumber = account.CDH_Party_Number;

				CDH_Party__c cdhPartyRecord = CDHParty_Instance_Prepare(account.CDH_Party_Number, account.Name, account.CDH_Party_Type, account.D_U_N_S);
				cdhPartyRecord.CDH_Party_Number_Ext__c = account.CDH_Party_Number;

				// US63853
				// 11/4/2015 disabled for November release
				if(AbstractTrigger.isActive(ALLOW_SITE_MERGE_SETTING,false)) {
					account = CDHPartyService.processSiteMergeSurvivors(new List<IntegrationObjects.SalesAccount>{account})[0];
				}
				// US66997
				if(account.Status == 'Merged') {
					partyMergeVictims.add(cdhPartyRecord);
				}
				// US69276
				else {
					CDHPartyService.processMergeSurvivors(new Map<String,List<Id>>{account.CDH_Party_Number => account.IDList});
				}

				mapOfCDHPartyNumberandCDHPartyRecord.put(account.CDH_Party_Number,Null);
//depreciated				if (account.IDs != null) {
//depreciated					Account[] existingSalesAccount = [select Id, CDH_Party_Name__c from Account where Id = :account.IDs and CDH_Party_Name__c != null];
//depreciated					if (existingSalesAccount.size() > 0) {
//depreciated						Account salesAcct = existingSalesAccount[0];
//depreciated						cdhPartyRecord.Id = salesAcct.CDH_Party_Name__c; // force an update instead of insert
//depreciated						mapOfCDHPartyNumberandCDHPartyRecord.put(account.CDH_Party_Number, cdhPartyRecord);
//depreciated					}
//depreciated					else {
//depreciated						mapOfCDHPartyNumberandCDHPartyRecord.put(account.CDH_Party_Number,Null);
//depreciated					}
//depreciated				}
//depreciated				else {
//depreciated					mapOfCDHPartyNumberandCDHPartyRecord.put(account.CDH_Party_Number,Null);
//depreciated				}

				if(account.CorporateRelationships != null
					&& account.CorporateRelationships.HeadQuartersOrParent != null
					&& account.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber != null
					&& account.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber.trim().length() > 0){
					mapOfCDHPartyNumberandCDHPartyRecord.put(account.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber, null);
				}
				if(account.CorporateRelationships != null
					&& account.CorporateRelationships.DomesticUltimate != null
					&& account.CorporateRelationships.DomesticUltimate.CDHPartyNumber != null
					&& account.CorporateRelationships.DomesticUltimate.CDHPartyNumber.trim().length() > 0){
					 mapOfCDHPartyNumberandCDHPartyRecord.put(account.CorporateRelationships.DomesticUltimate.CDHPartyNumber, null);
				}
				if(account.CorporateRelationships != null
					&& account.CorporateRelationships.GlobalUltimate != null
					&& account.CorporateRelationships.GlobalUltimate.CDHPartyNumber != null
					&& account.CorporateRelationships.GlobalUltimate.CDHPartyNumber.trim().length() > 0){
					 mapOfCDHPartyNumberandCDHPartyRecord.put(account.CorporateRelationships.GlobalUltimate.CDHPartyNumber, null);
				}

				// add the CDH Party record in the set of CDH Party records (to avoid the duplicate)
				setofCDHPartyToBeProcessed.add(cdhPartyRecord);

				// DE9454 - We need all the sales account ids, not just one
				// iterating on all CDH Party record and prepare the map of CDH Party# and it`s associated Sales Accounts.
				for(CDH_Party__c cdhParty: [
					SELECT id, Name,
						(SELECT Id FROM Accounts__r)
					FROM CDH_Party__c
					WHERE Name IN: mapOfCDHPartyNumberandCDHPartyRecord.keyset() ])
				{
					mapOfCDHPartyNumberandCDHPartyRecord.put(cdhParty.Name,cdhParty);
					if(cdhParty.Accounts__r != null && ! cdhParty.Accounts__r.isEmpty()){
						for(Account a : cdhParty.Accounts__r) {
							addressSalesAccountIds.add(a.Id);
						}
					}
				}

				CDH_Party__c cdhParty = mapOfCDHPartyNumberandCDHPartyRecord.get(account.CDH_Party_Number);
				System.debug('Stop 2: setofCDHPartyToBeProcessed: '+setofCDHPartyToBeProcessed);
				//scenario 1 :When CDH Party record does not exist in SFDC.
				//			  Create CDH Party record in SFDC , Put the sales account under this CDH Party record.
				if(cdhParty == Null){
					System.debug('Stop 3');
					// prepare the instance of CDH Party record
					// if OSR Number is null then we need to create new record of sales account under CDH Party
					if(account.IDList.isEmpty() || [select count() from Account where Id in : account.IDList limit 1] == 0){
						System.debug('Stop 4');
						Account accountRecord = new Account();
						// prepare the attribute of account record as per the message coming in sfdc.
						accountRecord = processSalesAccount(account);

						// set the reference of CDH Party on sales account using external Id field on CDH Party.
						accountRecord.CDH_Party_Name__r = new CDH_Party__c(CDH_Party_Number_Ext__c = account.CDH_Party_Number);
						// set the account record type id based on country and region.
						if( account != Null ){
							accountRecord.recordtypeid = GetAccountRecordTypeIdAsPerCountry(account);
							if(accountRecord.Id == null && accountRecord.RecordTypeId != null && accountRecord.OwnerId == null) {
								accountRecord.OwnerId = getDefaultOwnerId(accountRecord.RecordTypeId);
							}
							System.debug('Stop 5 accountRecord.recordtypeid: '+accountRecord.recordtypeid);
						}
						if(errorFlag){
							// add account in the list of accounts to be processed.
							accountListToBeProcessed.add(accountRecord);
						}
					}
				}
				// scenario 2 b : when CDH Party record exist and at least one sales account record exist under this CDH Party.
				//				  we need to update the existing sales account under this CDH Party record.
				else if(cdhParty.Accounts__r != null && ! cdhParty.Accounts__r.isEmpty()) {
					// List<Account> accountList = new List<Account>();
					// iterating on the account record under the CDH Party.
					System.debug('Stop 17');
					Set<Id> accountIds = new Set<Id>(account.IDList);
					for(Account accountrecord :  cdhParty.Accounts__r){
						// exclude the Id coming as OSR number.
						if(! accountIds.contains(accountrecord.Id)){
							//prepare the attribute of account record as per the message coming in sfdc.
							Account accountInstance = processSalesAccount(account);
							// set the ID of account record.
							accountInstance.Id = accountrecord.Id;
							// set the reference of CDH Party on sales account record.
							accountInstance.CDH_Party_Name__c = cdhParty.id;
							//will not update record type and partner program list.
							System.debug('#####&&&: '+accountInstance);
							accountListToBeProcessed.add(accountInstance);
						}
					}
				}
				// scenario 2: when OSR (i.e. SFDC Id ) of sales account is not in the message , but CDH Party record exist in salesforce.
				//				In this case create one sales account record under CDH Party , with the information coming in message.
				else if(account.IDList.isEmpty() || [select count() from Account where Id in :account.IDList limit 1] == 0) {
					System.debug('Stop 15');
					// prepare the instance of the account.
					Account accountRecord = new Account();
					// prepare the attribute of account record as per the message coming in sfdc.
					accountRecord = processSalesAccount(account);
					// set the reference of CDH Party on sales account using external Id field on CDH Party.
					accountRecord.CDH_Party_Name__c = mapOfCDHPartyNumberandCDHPartyRecord.get(account.CDH_Party_Number).id;
					// set the account record type id based on country and region.
					if(account != Null ){
						accountRecord.recordtypeid = GetAccountRecordTypeIdAsPerCountry(account);
						if(accountRecord.Id == null && accountRecord.RecordTypeId != null && accountRecord.OwnerId == null) {
							accountRecord.OwnerId = getDefaultOwnerId(accountRecord.RecordTypeId);
						}
					}
					if(errorFlag){
						//add account in the list of accounts to be processed.
						accountListToBeProcessed.add(accountRecord);
					}
					System.debug('Stop 16');
				}

				// Below logic to update the accounts record those have same SFDC Id = OSR coming in message.
				for(Id accountId : account.IDList) {
					System.debug('Stop 18');
					// prepare the attribute of account record as per the message coming in sfdc.
					Account accountInstance = processSalesAccount(account);
					System.debug('#####: '+accountInstance);
					//set the reference of CDH Party on sales account record.
					accountInstance.CDH_Party_Name__r = new CDH_Party__c(CDH_Party_Number_Ext__c = account.CDH_Party_Number);
					//set the ID of account record.
					System.debug('accountId: ****'+accountId);
					accountInstance.Id = accountId;

					//add account record in the list to be processed.
					if(errorFlag) {
						accountListToBeProcessed.add(accountInstance);
					}
				}
				// Do partner tracking
				if(account.PartnerClassifications != null && account.PartnerClassifications.size() > 0){
					partnerAccountList = processPartnerClassificationData(account.PartnerClassifications, account);
				}
				System.debug('Stop 19');
			}else{
				errorFlag = false;
			}
			System.debug('errorFlag: '+errorFlag);
			if(errorFlag){
				// add the set of CDH Party record in the list
				cdhPartyListToBeProcessed.addall(setofCDHPartyToBeProcessed);
				// upsert CDH Party records to be processed - cdhPartyListToBeProcessed

				// US77119 - We need to ignore failures do to an invalid cross reference key
				Database.upsertResult[] sr = Database.upsert(cdhPartyListToBeProcessed, Schema.CDH_Party__c.CDH_Party_Number_Ext__c, false);

				// upsert account list to be processed.
				System.debug('accountListToBeProcessed: '+accountListToBeProcessed);
				upsertIgnoreInvalidAndDeleted(accountListToBeProcessed);

				List<Account> uList;
				if(!partnerAccountList.isEmpty()){
					if(!updatedPartnerAccountList.isEmpty()){
						updatedPartnerAccountList.clear();
						for(String accId : updatedAccountIdSet){
							Account acc = ConvertioAccount(account);
							acc.Id = accId;
							acc.RecordTypeId = partnerRecordTypeId;
							acc.CDH_Party_Name__r = new CDH_Party__c(CDH_Party_Number_Ext__c = account.CDH_Party_Number);
							if(headQuarterNumber != '')
								acc.Headquarters__r = new CDH_Party__c(CDH_Party_Number_Ext__c = headQuarterNumber);

							if(globalUltimateNumber != '')
								acc.Global_Ultimate__r = new CDH_Party__c(CDH_Party_Number_Ext__c = globalUltimateNumber);

							if(domesticUltimateNumber != '')
								acc.Domestic_Ultimate__r = new CDH_Party__c(CDH_Party_Number_Ext__c = domesticUltimateNumber);

							acc.JigSaw = null;
							updatedPartnerAccountList.add(acc);
						}
						if(updatedPartnerAccountList.size() > 0){
							update updatedPartnerAccountList;

							partnerAccountList = updatedPartnerAccountList;
						}
					}

					if(!insertedPartnerAccountList.isEmpty())
						uList = createMissingPartnerAccounts(insertedPartnerAccountList, account);

					if(uList != null){
						partnerAccountList.addAll(uList);
					}
				}

				///need to include method to clone here.....except partner classification
				if(account.PartnerClassifications != null && account.PartnerClassifications.size() > 0 ){
					PartnerClassification_Service(account.PartnerClassifications, account, uList);
				}

				// if address list is there in sales account message , call the address method to process address data.
				Address_Service(account.Addresses, account, uList);
				Set<String> hierarchyRelationSet = new Set<String>();
				if(account.CorporateRelationships != null && account.CorporateRelationships.HeadQuartersOrParent != null
					&& String.isNotBlank(account.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber)){
					hierarchyRelationSet.add(account.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber);
				}
				if(account.CorporateRelationships != null && account.CorporateRelationships.DomesticUltimate != null
					&& String.isNotBlank(account.CorporateRelationships.DomesticUltimate.CDHPartyNumber)){
					hierarchyRelationSet.add(account.CorporateRelationships.DomesticUltimate.CDHPartyNumber);
				}

				if(account.CorporateRelationships != null && account.CorporateRelationships.GlobalUltimate != null
					&& String.isNotBlank(account.CorporateRelationships.GlobalUltimate.CDHPartyNumber)){
					hierarchyRelationSet.add(account.CorporateRelationships.GlobalUltimate.CDHPartyNumber);
				}
				List<Account> accountHierarchyList = new List<Account>();
				accountHierarchyList = [Select Id, Name from Account where Headquarters__c IN: hierarchyRelationSet OR Global_Ultimate__c IN: hierarchyRelationSet OR Domestic_Ultimate__c IN: hierarchyRelationSet];
				for(Account act : accountHierarchyList){
					act.Name = account.Name;
				}
				if(accountHierarchyList.size() > 0) {
					for(Database.SaveResult sr2 : Database.update(accountHierarchyList,false) ) {
						for(Database.Error e : sr2.getErrors()) {
							String m = String.join(sr2.getErrors(),'\n');
							if(m.containsIgnoreCase('ENTITY_IS_DELETED')) {
								throw new Interface_ServiceException('Account Update Error: '+m);
							}
						}
					}
				}
			}
		}catch(Exception e){
			// exception block to cathc the exception if any.
			// roll back the data base to previous stage.
			system.debug('exception occured-->'+e.getmessage());
			Database.rollback(savepoint);
			// US77119 - A stack trace really helps to find and fix problems
			throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + e.getmessage()+'\n'+e.getStackTraceString());
		}finally{
			// US66997
			if(!partyMergeVictims.isEmpty()) {
				CDHPartyService.processMergeVictims(partyMergeVictims);
			}
		}
	}

	/**
	 * Assign the IntegrationObjects.SalesAccount values to the Account record to be processed.
	 * 
	 * @param account - SalesAccount and associated classficiation codes, address, cdh information.
	 * @return the newly created standard Account 
	 */
	private Account processSalesAccount(IntegrationObjects.SalesAccount account){
		Account accountInstance = ConvertioAccount(account);
		// set the contact point as contact point mapping is required in case of sales account creation.
		//Commented as a part of user story US64014 : To suppress the code to copy fields when coming as a CDH outbound - SFDC inbound.
		//accountInstance.Website = account.Website;
		//accountInstance.Phone = account.Phone;
		//accountInstance.Fax = account.Fax;
		accountInstance.Linkedin_URL__c = account.Linkedin_URL;
		return accountInstance;
	}

	/**
	 * Method used to process the contact data (this will receive the single contact record)
	 * 
	 * @param contact
	 */
	public void Contact_Service (IntegrationObjects.Contact contact ){

		Savepoint savepoint = Database.setSavepoint();
		try{
			List<IntegrationObjects.Contact> contactDomainObjectList = new List<IntegrationObjects.Contact>();

			// if CDH Party# and CDH Person Party# is missing in the message then below logic will throw an error.
			if(contact.CDH_Party_Number == Null || contact.CDH_Party_Number.trim().length() == 0 ||
				contact.SalesAccount_CDH_Party_Number == Null || contact.SalesAccount_CDH_Party_Number.trim().length() ==0){
				//throw new Interface_ServiceException('CDH Party # and CDH Person Party# is required to process contact data');
				throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + CDHPARTY_REQUIRED_FOR_CONTACT);
			}

			// add contact domain object into one list.
			contactDomainObjectList.add(contact);

			// Invoke the method which recieves the contact doamain object as List.
			Contact_Service(contactDomainObjectList);
		}

		// catch block to catch if any exception is there.
		catch(exception e){
			system.debug('exception occurred ----->'+e.getmessage());
			database.rollback(savepoint);
			throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + e.getmessage());
		}
	}

	/**
	 * Method to process the List of contact domain object.
	 * 
	 * @param contactRecordList list of intergration object contacts to process
	 */
	public void Contact_Service(List<IntegrationObjects.Contact> contactRecordList){

		Savepoint savepoint = Database.setSavepoint();
		try{

			// List variable to hold the CDH Person Party records to be created.
			List<CDH_Party__c> cdhPartyList = new List<CDH_Party__c>();

			// Set variable to hold the CDH Person Party records to be created.
			set<CDH_Party__c>  cdhPartySet = new Set<CDH_Party__c>();
			// list variable to contain all contacts to be processed.
			List<Contact> contactListToProcess = new List<Contact>();
			system.debug('contact list is-->'+contactRecordList);

			// check for the size of list.
			if(contactRecordList != Null && contactRecordList.size() >0){

				// set variable to hold all CDH Party# coming in message.
				Set<String> setOfCDHPartyNumber = new Set<String>();

				// set variable to hold all CDH Person Party#
				Set<String> setOfCDHPersonPartyNumber = new Set<String>();

				// set variable to hold all OSR Number coming in message.
				Set<String> setOfOSRNumber = new Set<String>();

				// iterating on the list of contact domain object
				for(IntegrationObjects.Contact contact : contactRecordList){

					if(contact.CDH_Party_Number == Null || contact.CDH_Party_Number.trim().length() == 0 || contact.SalesAccount_CDH_Party_Number == Null || contact.SalesAccount_CDH_Party_Number.trim().length() ==0){
						//throw new Interface_ServiceException('CDH Party # and CDH Person Party# is required to process contact data');
						throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + CDHPARTY_REQUIRED_FOR_CONTACT);
					}

					// Preparation of set of CDH Party#
					setOfCDHPartyNumber.add(contact.SalesAccount_CDH_Party_Number);

					// preperation of CDH Person Party#
					setOfCDHPersonPartyNumber.add(contact.CDH_Party_Number);

					// Preparation of OSR Number set.
					if(contact.Ids != Null){
						setOfOSRNumber.add(contact.Ids);
					}
				}

				// prepare map of CDH Person Party# and CDH Party record which exist in SFDC.
				Map<string,CDH_Party__c> mapofCDHPersonParty_CDHParty = new Map<string,CDH_Party__c>();
				for(CDH_Party__c cdhparty: [select id ,Name from CDH_Party__c where Name in :setOfCDHPersonPartyNumber]){
					mapofCDHPersonParty_CDHParty.put(cdhparty.Name , cdhparty);
				}
				// Querying on all contact record where CDH Person Party # and CDH Party# is in list of data coming in the message.
				List<Contact> contactList = new List<Contact>();
				contactList = [select id ,Name,CDH_Party__r.Name,Account.CDH_Party_Name__r.Name from Contact where CDH_Party__r.Name in :setOfCDHPersonPartyNumber and Account.CDH_Party_Name__r.Name in :setOfCDHPartyNumber and Id not in :setOfOSRNumber  ];

				// if no contact record exist with this data and OSR number is also not in the message then throw an error message.
				if(contactList.size() == 0 && setOfOSRNumber.size() == 0){
					throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + CDHPARTY_REQUIRED_FOR_CONTACT);
					//throw new Interface_ServiceException('No contact record associated with this CDH Party# and CDH Person Party # data');
				}

				// Map of CDH Person Party#+CDH Party # and contact associated to this combination
				Map<String,List<Contact>> mapOfCDHPartyAndPersonParty_ContactList = new Map<String,List<Contact>>();

				// iterating on the list of contact records.
				for(Contact contact : contactList){

					// prepare the map of CDH Person Party#+CDH Party # and contacts associated to this combination
					List<Contact> contactTempList = new List<Contact>();// one temporary list of contacts to hold the contact list
					if(mapOfCDHPartyAndPersonParty_ContactList.get(contact.CDH_Party__r.Name + contact.Account.CDH_Party_Name__r.Name) != Null){
						contactTempList.addall(mapOfCDHPartyAndPersonParty_ContactList.get(contact.CDH_Party__r.Name + contact.Account.CDH_Party_Name__r.Name));
					}
					contactTempList.add(contact);
					mapOfCDHPartyAndPersonParty_ContactList.put(contact.CDH_Party__r.Name + contact.Account.CDH_Party_Name__r.Name ,contactTempList);
				}

				// iterating on the list of contact domain object list.
				for(IntegrationObjects.Contact contact : contactRecordList){

					// check if contact list exist where CDH Person Party# and CDH Party# combination matched.
					if(contact.SalesAccount_CDH_Party_Number != Null && contact.CDH_Party_Number != Null && mapOfCDHPartyAndPersonParty_ContactList.get(contact.CDH_Party_Number+contact.SalesAccount_CDH_Party_Number )!=Null && mapOfCDHPartyAndPersonParty_ContactList.get(contact.CDH_Party_Number+contact.SalesAccount_CDH_Party_Number ).size() > 0){

						// iterating on the list of contacts associated with CDH Person Party# and CDH Party#.
						for(Contact contactDetails : mapOfCDHPartyAndPersonParty_ContactList.get(contact.CDH_Party_Number+contact.SalesAccount_CDH_Party_Number)){
							string contactId = contactDetails.Id;
							contactDetails = ConvertioContact(contact);
							contactDetails.id = contactId;
							contactListToProcess.add(contactDetails);
						}
					}

					// update the contact based on the OSR Number if coming in the message.
					if(contact.Ids != Null){
						Contact contactRecord = ConvertioContact(contact);
						contactRecord.Id =  contact.Ids;
						system.debug('mapofCDHPersonParty_CDHParty---->>>>>>>'+mapofCDHPersonParty_CDHParty);
						String contactFullName = contact.FirstName != null ? contact.FirstName + ' ' + contact.LastName : contact.LastName;
						if(mapofCDHPersonParty_CDHParty.get(contact.CDH_Party_Number) == Null){
							cdhPartySet.add(CDHParty_Instance_Prepare(contact.CDH_Party_Number, contactFullName, 'PERSON', null));
						}
						contactRecord.CDH_Party__r = new CDH_Party__c(CDH_Party_Number_Ext__c = contact.CDH_Party_Number);
						contactListToProcess.add(contactrecord);

					}
				}
				if(cdhPartySet != Null && cdhPartySet.size() >0){
					cdhPartyList.addall(cdhPartySet);
					insert cdhPartyList;
				}
				update contactListToProcess;
			}
		}
		catch(exception e){
			system.debug('exception occured-->'+e.getmessage());
			database.rollback(savepoint);
			throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + e.getmessage());
		}
	}

	/**
	 * Method to process the List of address.
	 * 
	 * @param addressList list of integration object addreses to process
	 * @param account the integration object sales account to use
	 * @param insertedAccountList the list of newly inserted salesforce accounts
	 */
	public void Address_Service (List<IntegrationObjects.Address> addressList, IntegrationObjects.SalesAccount account, List<Account> insertedAccountList){
		Savepoint savepoint = Database.setSavepoint();
		try{
			if( account.CDH_Party_Number != null && addressList != null && ! addressList.isEmpty()){
				// map for the CDH Party Site# and the address records coming
				Map<String,IntegrationObjects.Address> mapOfCDHPartySiteNumberAndAddress = new map<String,IntegrationObjects.Address>();
				Set<Id> setOfOSR = new Set<Id>();
				for(IntegrationObjects.Address address : addressList){
					if(address.CDH_Party_Site_Number == Null || address.CDH_Party_Site_Number.trim().length() == 0){
						//throw new Interface_ServiceException(CDHPARTY_REQUIRED_FOR_ADDRESS);
						throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + CDHPARTY_REQUIRED_FOR_ADDRESS);
						return;
					}
					mapOfCDHPartySiteNumberAndAddress.put(address.CDH_Party_Site_Number , address);

					// prepare the set of OSR coming in the message.
					setOfOSR.addAll(address.IDList);
				}
				// query all accounts having the CDH Party# coming in the message and and associated address record having CDH Party Site# coming in the message.
				List<Account> accountList = [
					SELECT Id ,
						(	SELECT Id,
								CDH_Party_Site_Number__c,
								IsDuplicate__c
							FROM Addresses__r
							WHERE Id IN: setOfOSR
								OR CDH_Party_Site_Number__c IN: mapOfCDHPartySiteNumberAndAddress.keyset() )
					FROM ACCOUNT
					WHERE CDH_Party_Name__c in (select Id from CDH_Party__c where Name =:account.CDH_Party_Number) ];

				if(! accountList.isEmpty()){

//US69489					// Map of Account Id+CDH Party Site# and their associated address records.
//US69489					Map<string,Address__c> mapOfAccountId_CDHPartySiteNumber_Address = new Map<string,Address__c>();
//US69489
//US69489					// Map of Account Id and Set of associated address id.
//US69489					Map<Id,Set<Id>> mapOfAccountId_SetOfAddressId = new Map<Id,Set<Id>>();
					Map<String,Set<Id>> addressIdsMap = new Map<String,Set<Id>>(); // US69489
					Set<String> nonDuplicateKeys = new Set<String>();

					// iterate on the list of account and prepare the above mentioned maps
					for(Account accountRecord: accountList){

						// Iterating on the account records associated with account.
						for(Address__c address : accountRecord.Addresses__r){
//US68489							if(address.CDH_Party_Site_Number__c != Null){
//US69489								mapOfAccountId_CDHPartySiteNumber_Address.put(accountRecord.Id+address.CDH_Party_Site_Number__c,address);
//US69489							}
//US69489							if(address.CDH_Party_Site_Number__c == Null){
//US69489								set<Id> setofAddressId = new Set<Id>();
//US69489								if(mapOfAccountId_SetOfAddressId.get(accountRecord.Id) != Null){
//US69489									setofAddressId = mapOfAccountId_SetOfAddressId.get(accountRecord.Id);
//US69489								}
//US69489								setofAddressId.add(address.Id);
//US69489								mapOfAccountId_SetOfAddressId.put(accountRecord.Id,setofAddressId);
//US69489							}
//US68489 - begin new code
							String key = accountRecord.Id;
							Set<Id> addressIds = addressIdsMap.get(key);
							if(addressIds == null) {
								addressIds = new Set<Id>();
								addressIdsMap.put(key,addressIds);
							}
							addressIds.add(address.Id);
							if(address.CDH_Party_Site_Number__c != null) {
								key += address.CDH_Party_Site_Number__c;
								addressIds = addressIdsMap.get(key);
								if(addressIds == null) {
									addressIds = new Set<Id>();
									addressIdsMap.put(key,addressIds);
								}
								addressIds.add(address.Id);
							}
							if(address.IsDuplicate__c != true) {
								nonDuplicateKeys.add(key);
							}
//US68489 - end new code
						}
					}

					// list of address records to be processed.
					List<Address__c> addressListToProcess = new List<Address__c>();

					// iterating on the list of address domain objects
					for(IntegrationObjects.Address address : addressList){
						if(address.CDH_Party_Site_Number != null && address.CDH_Party_Site_Number.trim() != ''){
							for(Account accountRecord : accountList ){
//US68489								 Address__c addressRecord = new Address__c();

//US68489								// check whether address record with this party site# does not exist under this sales account , if exists update that address record
//US68489								//	if not then create the new address record under this sales account.
//US68489								 // One assumption is there i.e. under one sales account there would not be > 1 address record having same cdh party site#.
//US68489								if(mapOfAccountId_CDHPartySiteNumber_Address.get(accountRecord.id+address.CDH_Party_Site_Number) != Null &&
//US68489								  ((address.Ids == Null) || (address.Ids != Null && mapOfAccountId_SetOfAddressId.get(accountRecord.id) != Null &&
//US68489								  mapOfAccountId_SetOfAddressId.get(accountRecord.id).contains(address.Ids) == False))){
//US68489
//US68489									addressRecord = ConvertioAddress(address);
//US68489									addressRecord.Id = mapOfAccountId_CDHPartySiteNumber_Address.get(accountRecord.id+address.CDH_Party_Site_Number).Id;
//US68489									addressListToProcess.add(addressRecord);
//US68489								}else if(mapOfAccountId_CDHPartySiteNumber_Address.get(accountRecord.id+address.CDH_Party_Site_Number) == Null &&
//US68489										((address.Ids == Null) || (address.Ids != Null &&(mapOfAccountId_SetOfAddressId.get(accountRecord.id) == Null ||
//US68489										(mapOfAccountId_SetOfAddressId.get(accountRecord.id) != Null && mapOfAccountId_SetOfAddressId.get(accountRecord.id).contains(address.Ids) == False))))){
//US68489									addressRecord = ConvertioAddress (address);
//US68489									addressRecord.Sales_Account__c = accountRecord.id;
//US68489									addressListToProcess.add(addressRecord);
//US68489								}
//US68489 - begin new code
								// if we have existing addresses, update any which where NOT in the id list
								if(addressIdsMap.containsKey(accountRecord.Id+address.CDH_Party_Site_Number)) {
									Set<Id> addressIds = addressIdsMap.get(accountRecord.Id+address.CDH_Party_Site_Number).clone();
									addressIds.removeAll(address.IDList);
									if(! addressIds.isEmpty()) {
										Address__c addressRecord = ConvertioAddress(address);
										// update existing addresses
										for(Id addressId : addressIds) {
											Address__c xaddressRecord = addressRecord.clone();
											xaddressRecord.Id = addressId;
											addressListToProcess.add(xaddressRecord);
										}
									}
								}
								// make sure we do not already have the specified address id
								// without a cdh party site number assigned to it yet
								if( ! nonDuplicateKeys.contains(accountRecord.Id+address.CDH_Party_Site_Number)) {
									Set<Id> addressIds = new Set<Id>();
									if(addressIdsMap.containsKey(accountRecord.Id) ) {
										addressIds.addAll(address.IDList);
										addressIds.retainAll(addressIdsMap.get(accountRecord.Id));
									}
									if( addressIds.isEmpty() ) {
										// create a new address
										Address__c addressRecord = ConvertioAddress(address);
										addressRecord.Sales_Account__c = accountRecord.id;
										addressListToProcess.add(addressRecord);
									}
								}
//US68489 - end new code
							}
						}

						// updating the address record where SFDC Id = OSR Number coming in the  message.
						for(Id addressId : address.IDList) {
							Address__c addressRecord = ConvertioAddress (address);
							addressRecord.Id = addressId;
							addressListToProcess.add(addressRecord);
						}
					}
					// upsert the list of address records to be processed once.
					upsertIgnoreInvalidAndDeleted(addressListToProcess);
				}
			}
			if(insertedAccountList != null && ! insertedAccountList.isEmpty()) {
				System.debug('Inside Address cloning Account List: '+insertedAccountList);

				// DE9454 - Query all addresses from multiple sales accounts
				// DE9454 - Exclude the addresses we don't need like duplicates and
				//          and non-identifying addresses missing cdh party site numbers
				List<Address__c> existingAddressList = [
					SELECT Id,
						Address_Line1__c,
						Address_Line2__c,
						Address_Line3__c,
						Address_Line4__c,
						Bill_To_Address__c,
						CDH_Party__c,
						CDH_Party_Site_Number__c,
						City__c,
						Country__c,
						County__c,
						Entitle_To_Address__c,
						Identifying_Address__c,
						IsDuplicate__c, // DE9454 - clone this value
						Province__c,
						// RecordTypeId, // DE9454 - do not clone this value
						Sales_Account__c,
						Ship_To_Address__c,
						Sold_To_Address__c,
						State__c,
						Status__c,
						Zip_Postal_Code__c
					FROM Address__c
					WHERE Sales_Account__c in :addressSalesAccountIds
						and IsDuplicate__c != true
						and (Identifying_Address__c = true OR CDH_Party_Site_Number__c != null)
					ORDER BY CDH_Party_Site_Number__c NULLS LAST ];

				System.debug('Inside Address cloning Address List: '+existingAddressList);

				if(! existingAddressList.isEmpty()) {
					// DE9454 - Use a map instead of a list to avoid duplicates...
					Map<String,Address__c> cloneAddressMap = new Map<String,Address__c>();
					for(Account acc : insertedAccountList){
						// US73124 - don't clone addresses to newly created partner accounts
						// DE9454 - unless it is an identifying addresss...
						Boolean isPartner = (''+getRecordTypeName(acc.RecordTypeId)).containsIgnoreCase('Partner');
						Boolean needsIdentifyingAddress = true;
						// Yuck, we will need to duplicate the identifying address even if no cdh party site number has been assigned.
						// This will cause duplication in cdh...
						for(Address__c existingAddress : existingAddressList){
							if((existingAddress.Identifying_Address__c == true && needsIdentifyingAddress)
								|| (existingAddress.CDH_Party_Site_Number__c != null && ! isPartner) )
							{
								needsIdentifyingAddress = needsIdentifyingAddress && (existingAddress.Identifying_Address__c != true);
								// DE9454 - there is less chance of error if we clone the address rather than copying it
								Address__c cloneAddress = existingAddress.clone(false);
								// DE9454 - We need the external id to avoid duplicates
								cloneAddress.Address_External_Id__c = acc.Id;
								if(existingAddress.CDH_Party_Site_Number__c != null) {
									cloneAddress.Address_External_Id__c = acc.Id+existingAddress.CDH_Party_Site_Number__c;
								}
								cloneAddress.Sales_Account__c = acc.Id;
								cloneAddressMap.put(cloneAddress.Address_External_Id__c,cloneAddress);
							}
						}
					}
					// upsert the list of address records to be processed once.
					if(! cloneAddressMap.isEmpty()) {
						// DE9454 - Doing an upsert and more complete list might introduce new errors.
						//          it is probably better to swallow the errors and do an incomplete
						//          insert rather than to fail on an error that cannot be easily corrected.
						//          Since these are all net new, we could still do an insert, but an upsert 
						//          will help deal with race conditions.
						Database.upsert(cloneAddressMap.values(),Address__c.field.Address_External_Id__c,true);
					}
				}
			}
		}
		catch(Exception e) {
			system.debug('exception occured--->'+e.getmessage());
			database.rollback(savepoint);
			throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + e.getmessage());
		}
	}

	/**
	 * method called by inbound account if has partner program associated with it.
	 * 
	 * @param classificationList list of integration object classifications to process
	 * @param account the integration object sales account to use
	 * @param insertedAccountList list of newly inserted salesforce accounts
	 */
	public void PartnerClassification_Service (List<IntegrationObjects.Classification> classificationList, IntegrationObjects.SalesAccount account, List<Account> insertedAccountList){

		Set<Id> accountIdSet = new Set<Id>();
		list<Partner_Program__c> partnerProgramListToProcess = new list<Partner_Program__c>();
		Savepoint savepoint = Database.setSavepoint();
		try{
			Set<String> updatedCodeSet = new Set<String>();
			for(String ppdId : mapCDHWithProgramDefinition.keySet()){
				if(ppdIDAccountMap.containsKey(ppdId)){
					Account acc = ppdIDAccountMap.get(ppdId);
					Partner_Program__c existingPgm = acc.Partner_Programs__r[0];
					Partner_Program__c partnerProgram = new Partner_Program__c();
					partnerProgram.id = existingPgm.Id;
					partnerProgram.Name = mapCodeWithMatchedTier.get(mapCDHWithProgramDefinition.get(ppdId))[0].Partner_Program_Definition__r.Program_Category__c;
					partnerProgram.Status__c = existingPgm.Status__c;	// do no allow inbound flows to alter existing status
//depreciated					if(mapCodeStatusInInbound.get(mapCDHWithProgramDefinition.get(ppdId)).Status != ACTIVE && mapCodeStatusInInbound.get(mapCDHWithProgramDefinition.get(ppdId)).Status != APPROVED){
//depreciated						partnerProgram.Status__c = INACTIVE;
//depreciated					}
//depreciated					else{
//depreciated						partnerProgram.Status__c = ACTIVE;
//depreciated					}
					partnerProgram.Is_Primary__c = existingPgm.Is_Primary__c;
					partnerProgram.Program__c = ppdId;
					partnerProgram.Tier__c = mapCodeWithMatchedTier.get(mapCDHWithProgramDefinition.get(ppdId))[0].Tier__c;

					//
					// mls 9/28/2015
					// Yes, this is nasty, but it solves a design fault where CDH is sending 2 update records
					// for a tier change, and we want to ignore the Unaffiliated one.
					//
					if (partnerProgram.Tier__c == 'Unaffiliated') {
						continue;
					}

					partnerProgram.Oracle_Classification_Code__c = mapCDHWithProgramDefinition.get(ppdId);
					partnerProgramListToProcess.add(partnerProgram);
					updatedCodeSet.add(mapCDHWithProgramDefinition.get(ppdId));
				}
			}

			if(insertedAccountList != null && !insertedAccountList.isEmpty()){
				for(String CodeToUpdatePartnerProgram : setOfInsertCDHMasteredCode){ //C1, C2, C3
					for(Account acc : insertedAccountList){  //P1, P2, P3
						if(!updatedCodeSet.contains(CodeToUpdatePartnerProgram) && !accountIdSet.contains(acc.Id)){
							Partner_Program__c partnerProgram = new Partner_Program__c();
							if(mapCodeStatusInInbound.get(CodeToUpdatePartnerProgram).Status != ACTIVE && mapCodeStatusInInbound.get(CodeToUpdatePartnerProgram).Status != APPROVED){
								partnerProgram.Status__c = INACTIVE;
							}
							else{
								partnerProgram.Status__c = ACTIVE;
							}
							partnerProgram.Is_Primary__c = True;
							partnerProgram.Name = mapCodeWithMatchedTier.get(CodeToUpdatePartnerProgram)[0].Partner_Program_Definition__r.Program_Category__c;
							partnerProgram.Program__c = mapCodeWithMatchedTier.get(CodeToUpdatePartnerProgram)[0].Partner_Program_Definition__c;
							partnerProgram.Tier__c = mapCodeWithMatchedTier.get(CodeToUpdatePartnerProgram)[0].Tier__c;
							partnerProgram.Account__c = acc.Id;
							partnerProgram.Oracle_Classification_Code__c = CodeToUpdatePartnerProgram;
							partnerProgramListToProcess.add(partnerProgram);
							accountIdSet.add(acc.Id);
							break;
						}
					}
				}
			}
			system.debug('test partnerProgramListToProcess=========='+partnerProgramListToProcess);
			upsert partnerProgramListToProcess;
		}
		// catch block to catch if any exception is there.
		catch(exception e){
			system.debug('exception occurred ----->'+e.getmessage());
			database.rollback(savepoint);
			throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + e.getmessage());
		}
	}

	/**
	 * process the classification codes to create or update partner program member records.
	 * 
	 * @param classificationList list of integration object classifications to process
	 * @param account the integration object sales account to use
	 * @return lost of salesforce partner accounts
	 */
	public List<Account> processPartnerClassificationData(List<IntegrationObjects.Classification> codesList, IntegrationObjects.SalesAccount account){
		Set<String> setOfActiveCode = new Set<String>();
		Set<String> setOfCDHMasteredCode = new Set<String>();
		Set<String> setProgramDefinitonId= new Set<String>();
		Set<String> codesWithMatchingTierSet = new Set<String>();

		List<String> recordTypeList = new List<String>();
		List<Account> partnerAccountList = new List<Account>();
		List<Partner_Program_Tier__c> allTierList = new List<Partner_Program_Tier__c>();
		List<Partner_Program_Tier__c> listOfPartnerTierOfCode = new List<Partner_Program_Tier__c>();
		List<Partner_Program_Tier__c> listPartnerProgramDefinitionTierOfInboundCode = new List<Partner_Program_Tier__c>();

		Map<String, IntegrationObjects.Classification> allCodesMap = new Map<String, IntegrationObjects.Classification>();
		Map<String, List<IntegrationObjects.Classification>> ppdWithCodeMap = new Map<String, List<IntegrationObjects.Classification>>();

		try{
			System.debug('processPartnerClassificationData 1');
			List<IntegrationObjects.Classification> classificationList = new List<IntegrationObjects.Classification>();
			classificationList = processCodesForDuplicate(codesList);
			//classificationList = codesList;
			if(! classificationList.isEmpty()){
				System.debug('processPartnerClassificationData 2');
				//get all partner record type from a custom label and putting them in a array of string.
				if(String.isNotBlank(system.label.Record_types_of_Account_for_partner_program_inbounds)){
					for(String recordtypeName : Label.Record_types_of_Account_for_partner_program_inbounds.split(';')){
						recordTypeList.add(recordtypeName);
					}
				}

				//iterate through the classification list form inbound integration object structure.
				for(IntegrationObjects.Classification classificationObject : classificationList){
					//adding up the code in a set.
					allCodesMap.put(classificationObject.Code, classificationObject);
				}

				allTierList = [Select CDH_Mastered__c,
									  Oracle_Classification_Code__c,
									  Partner_Program_Definition__c,
									  Partner_Program_Definition__r.Id,
									  Partner_Program_Definition__r.Program_Category__c,
									  Tier__c
									  From Partner_Program_Tier__c
									  where Oracle_Classification_Code__c IN: allCodesMap.keySet()];

				if(allTierList == null){
					errorFlag = false;
					//throw new Interface_ServiceException(NO_MATCHING_TIER_ERROR_MESSAGE);
					throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + NO_MATCHING_TIER_ERROR_MESSAGE);
				}

				for(Partner_Program_Tier__c tier : allTierList){
					codesWithMatchingTierSet.add(tier.Oracle_Classification_Code__c);
					if(tier.CDH_Mastered__c){
						cdhMasteredFlag = true;
						mapCodeStatusInInbound.put(tier.Oracle_Classification_Code__c, allCodesMap.get(tier.Oracle_Classification_Code__c));
					}
				}

				System.debug('processPartnerClassificationData 3');

				//list of partner program definition tier that has oracle classification code inbounded and present in setOFCode.
				listPartnerProgramDefinitionTierOfInboundCode = [Select CDH_Mastered__c,
																	Oracle_Classification_Code__c,
																	Partner_Program_Definition__c,
																	Partner_Program_Definition__r.Id,
																	Partner_Program_Definition__r.Program_Category__c,
																	Tier__c
																	From Partner_Program_Tier__c
																	where Oracle_Classification_Code__c IN: allCodesMap.keySet()
																	AND CDH_Mastered__c = true];

				System.debug('Stop 7 listPartnerProgramDefinitionTierOfInboundCode: '+listPartnerProgramDefinitionTierOfInboundCode);

				// iterating through the list of definition tier record and putting that in the map of code and list that has the same code.
				for(Partner_Program_Tier__c partnerProgramTierObjectDetailWithCode : listPartnerProgramDefinitionTierOfInboundCode){

					// iterate through the list of partner program definition tier record to get the id of the partner program definiton.
					setProgramDefinitonId.add(partnerProgramTierObjectDetailWithCode.Partner_Program_Definition__c);

					// create a map of Code and List of Partner Program Tier.
					if(!mapCodeWithMatchedTier.containsKey(partnerProgramTierObjectDetailWithCode.Oracle_Classification_Code__c))
						mapCodeWithMatchedTier.put(partnerProgramTierObjectDetailWithCode.Oracle_Classification_Code__c, new List<Partner_Program_Tier__c>());

					mapCodeWithMatchedTier.get(partnerProgramTierObjectDetailWithCode.Oracle_Classification_Code__c).add(partnerProgramTierObjectDetailWithCode);

					// create a map of Partner Program Definition Id and List of Classification Code.
					if(!ppdWithCodeMap.containsKey(partnerProgramTierObjectDetailWithCode.Partner_Program_Definition__r.id))
						ppdWithCodeMap.put(partnerProgramTierObjectDetailWithCode.Partner_Program_Definition__r.id, new List<IntegrationObjects.Classification>());

					ppdWithCodeMap.get(partnerProgramTierObjectDetailWithCode.Partner_Program_Definition__r.id).add(mapCodeStatusInInbound.get(partnerProgramTierObjectDetailWithCode.Oracle_Classification_Code__c));
				}

				System.debug('Stop 8 ppdWithCodeMap: '+ppdWithCodeMap);

				//iterating through the map to get the list size for the code as the key in map.
				for(string codeOfMapWithListOfTierAssocaited : mapCodeWithMatchedTier.keyset()){
					if(mapCodeWithMatchedTier.get(codeOfMapWithListOfTierAssocaited).size() == 0){
						//checking if the list is not greater than 0.
						errorFlag = false;
						throw new Interface_ServiceException(NO_MATCHING_TIER_ERROR_MESSAGE);
						return null;
					}

					if(mapCodeWithMatchedTier.get(codeOfMapWithListOfTierAssocaited).size() > 1){
						//checking if the list is greater than 1.
						errorFlag = false;
						throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + MORE_THAN_ONE_TIER_ERROR_MESSAGE + ' for '+codeOfMapWithListOfTierAssocaited);
					}
				}

				for(String ppdId : ppdWithCodeMap.keySet()){ //iterate through partner program definition ids
					if(ppdWithCodeMap.get(ppdId).size() == 1){
						mapCDHWithProgramDefinition.put(ppdId, ppdWithCodeMap.get(ppdId)[0].Code);
						setOfCDHMasteredCode.add(ppdWithCodeMap.get(ppdId)[0].Code);
					}
					if(ppdWithCodeMap.get(ppdId).size() >= 2){
						String activeCode;
						Integer activeCount = 0, inActiveCount = 0;
						List<ClassificationCodeWrapper> classificationCodeWrapperList = new List<ClassificationCodeWrapper>();
						for(IntegrationObjects.Classification classificationCode : ppdWithCodeMap.get(ppdId)){
						  if(classificationCode.Status == ACTIVE || classificationCode.Status == APPROVED){
							 activeCount++;
							 activeCode = classificationCode.Code;
						  }else{
							inActiveCount++;
							classificationCodeWrapperList.add(new ClassificationCodeWrapper(classificationCode));
						  }
						}
						if(activeCount >= 2){
							throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + MULTIPLE_ACTIVE_SAME_CDH_ERROR_MESSAGE);
						}else if(activeCount == 1){
							mapCDHWithProgramDefinition.put(ppdId, activeCode);
							setOfCDHMasteredCode.add(activeCode);
						}else if(inActiveCount == ppdWithCodeMap.get(ppdId).size()){
							if(!classificationCodeWrapperList.isEmpty()){
								IntegrationObjects.Classification largeDateSortedCode = processCodeWithDates(classificationCodeWrapperList);
								mapCDHWithProgramDefinition.put(ppdId, largeDateSortedCode.Code);
								setOfCDHMasteredCode.add(largeDateSortedCode.Code);
							}
						}
					}
				}

				System.debug('Stop 9 mapCDHWithProgramDefinition: '+mapCDHWithProgramDefinition);

				System.debug('Stop 10');

				// list of account that holds the same cdh party of the inbounded account and has record type as partner.
				list<Account> listAccountForSameCDHInInbound = new list<Account>();

				listAccountForSameCDHInInbound = [Select Id,
													RecordTypeId,
													(select
														Account__c,
														oracle_classification_code__c,
														Program__c,
														Status__c,
														Tier__c,
														Is_Primary__c
														from Partner_Programs__r where Program__c IN: setProgramDefinitonId LIMIT 1)
														from Account
														where CDH_Party_Name__r.Name =: account.CDH_Party_Number
														And recordType.Name IN: recordTypeList];

				System.debug('Stop 11 listAccountForSameCDHInInbound: '+listAccountForSameCDHInInbound);

				//code to check for list of partner program tier record for oracle classification code coming
				//iterating through the list of account to associate partner programs with them.
				if(listAccountForSameCDHInInbound != null && listAccountForSameCDHInInbound.size() > 0){
					for(Account accountToPopulatePartnerProgram : listAccountForSameCDHInInbound){
						if(accountToPopulatePartnerProgram.Partner_Programs__r != null && !accountToPopulatePartnerProgram.Partner_Programs__r.isEmpty()){
							if(mapCDHWithProgramDefinition.containsKey(accountToPopulatePartnerProgram.Partner_Programs__r[0].Program__c)){
								partnerRecordTypeId = accountToPopulatePartnerProgram.RecordTypeId;
								classificationCodeAccountMap.put(mapCDHWithProgramDefinition.get(accountToPopulatePartnerProgram.Partner_Programs__r[0].Program__c), accountToPopulatePartnerProgram);
								ppdIDAccountMap.put(accountToPopulatePartnerProgram.Partner_Programs__r[0].Program__c, accountToPopulatePartnerProgram);
								updatedAccountIdSet.add(accountToPopulatePartnerProgram.Id);
								updatedPartnerAccountList.add(accountToPopulatePartnerProgram);
								partnerAccountList.add(accountToPopulatePartnerProgram);
								if(setOfCDHMasteredCode.contains(mapCDHWithProgramDefinition.get(accountToPopulatePartnerProgram.Partner_Programs__r[0].Program__c))){
									setOfCDHMasteredCode.remove(mapCDHWithProgramDefinition.get(accountToPopulatePartnerProgram.Partner_Programs__r[0].Program__c));
								}
							}
						}
						//calling up the method by passing parameters to upsert the partner programs.
					}
				}
				//create instances of partner accounts to be created for new partner classification codes
				for(String code : setOfCDHMasteredCode){
					Account pAccount = new Account();
					pAccount.Name = 'Test Account';
					partnerAccountList.add(pAccount);
					insertedPartnerAccountList.add(pAccount);
				}
				setOfInsertCDHMasteredCode = setOfCDHMasteredCode;
				System.debug('Stop 12 partnerAccountList: '+partnerAccountList);
				System.debug('Stop 13 insertedPartnerAccountList: '+insertedPartnerAccountList);
				System.debug('Stop 14 updatedPartnerAccountList: '+updatedPartnerAccountList);
			}
		}catch(Exception e){
			System.debug('message: '+e.getMessage());
			throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + e.getmessage());
		}
		return partnerAccountList;
	}

	/**
	 * filters the classification codes to only active classifications
	 * 
	 * @param classificationList list of integration object classifications to filter
	 * @return filtered list of integration object classifications
	 * @throws Interface_ServiceException if any classification code has more than one active classification
	 */
	private List<IntegrationObjects.Classification> processCodesForDuplicate(List<IntegrationObjects.Classification> classificationList){
		Map<String, List<IntegrationObjects.Classification>> classificationCodeMap = new Map<String, List<IntegrationObjects.Classification>>();
		List<IntegrationObjects.Classification> classificationCodeList = new List<IntegrationObjects.Classification>();
		List<IntegrationObjects.Classification> codeList;
		List<ClassificationCodeWrapper> classificationCodeWrapperList;
		IntegrationObjects.Classification activeWinnerCode;
		Set<String> codeKeySet = new Set<String>();
		for(IntegrationObjects.Classification classificationCode : classificationList){
			if(!classificationCodeMap.keySet().contains(classificationCode.Code))
				classificationCodeMap.put(classificationCode.Code, new List<IntegrationObjects.Classification>());

			classificationCodeMap.get(classificationCode.Code).add(classificationCode);
		}

		codeKeySet = classificationCodeMap.keySet();

		for(String code : codeKeySet){
			Integer inActiveCount = 0;
			Integer activeCount = 0;
			classificationCodeWrapperList = new List<ClassificationCodeWrapper>();
			if(classificationCodeMap.containsKey(code)){
				codeList = classificationCodeMap.get(code);
				// Check if all the classification codes are inactive
				for(IntegrationObjects.Classification c : codeList){
					if(c.Status == ACTIVE || c.Status == APPROVED){
					  activeCount++;
					  activeWinnerCode = c;
					}else{
					  inActiveCount++;
//					  classificationCodeWrapperList.add(new ClassificationCodeWrapper(c));
					}
				}
//depreciated				if(inActiveCount == codeList.size()){
//depreciated					if(!classificationCodeWrapperList.isEmpty()){
//depreciated						IntegrationObjects.Classification largeDateSortedCode = processCodeWithDates(classificationCodeWrapperList);
//depreciated						classificationCodeList.add(largeDateSortedCode);
//depreciated					}
//depreciated				}else if(activeCount >= 2){

				if (activeCount >= 2) {
					throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + MULTIPLE_ACTIVE_SAME_CDH_ERROR_MESSAGE);
				}else if(activeCount == 1){
					classificationCodeList.add(activeWinnerCode);
				}
			}
			classificationCodeWrapperList.clear();
		}
		return classificationCodeList;
	}

	private IntegrationObjects.Classification processCodeWithDates(List<ClassificationCodeWrapper> classificationList){
		classificationList.sort();
		return classificationList.get(0).merchItem;
	}

	/**
	 * method to prepare the contact instance .This method receives the contact domain object and return the contact instance
	 * 
	 * @param ioContact
	 * @return contact
	 */
	public  Contact ConvertioContact(IntegrationObjects.Contact ioContact){
		return SystemObjectConverter.ConvertToioContact(ioContact);
	}

	/**
	 * method to prepare the address instance .This method receives the address domain object and return the address instance.
	 * 
	 * @param ioAddress
	 * @return address
	 */
	public Address__c ConvertioAddress (IntegrationObjects.Address ioAddress){
		return SystemObjectConverter.ConvertToioAddress(ioAddress);
	}

	/**
	 * method to prepare the account instance .This method receives the account domain object and return the account instance.
	 * 
	 * @param ioAccount
	 * @return account
	 */
	public Account ConvertioAccount(IntegrationObjects.SalesAccount ioAccount){
		// setting the account instance.
		Account account = SystemObjectConverter.ConvertToioAccount(ioAccount);

		// below logic checks that whether CDH Party record already exist for the hierarchy coming in the message or not , if exist associate it with the existing one else create new CDH Party record.
		if(ioAccount.CorporateRelationships != null && ioAccount.CorporateRelationships.HeadQuartersOrParent != null
			&& String.isNotBlank(ioAccount.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber)
			&& mapOfCDHPartyNumberandCDHPartyRecord.get(ioAccount.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber.trim()) != null){

			CDH_Party__c hqCDHParty = CDHParty_Instance_Prepare(ioAccount.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber,
			ioAccount.CorporateRelationships.HeadQuartersOrParent.Name, '', ioAccount.CorporateRelationships.HeadQuartersOrParent.DUNS);
			hqCDHParty.CDH_Party_Number_Ext__c = ioAccount.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber;

			setofCDHPartyToBeProcessed.add(hqCDHParty);

			account.Headquarters__r = new CDH_Party__c(CDH_Party_Number_Ext__c = ioAccount.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber);
			headQuarterNumber = ioAccount.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber;
		}
		else if(ioAccount.CorporateRelationships != null && ioAccount.CorporateRelationships.HeadQuartersOrParent != null
				&& String.isNotBlank(ioAccount.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber)){
			CDH_Party__c hqCDHParty = CDHParty_Instance_Prepare(ioAccount.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber,
			ioAccount.CorporateRelationships.HeadQuartersOrParent.Name, '', ioAccount.CorporateRelationships.HeadQuartersOrParent.DUNS);

			hqCDHParty.CDH_Party_Number_Ext__c = ioAccount.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber;
			// add the CDH Party record in the set of CDH Party records (to avoid the duplicate)
			setofCDHPartyToBeProcessed.add(hqCDHParty);

			headQuarterNumber = ioAccount.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber;
			account.Headquarters__r = new CDH_Party__c(CDH_Party_Number_Ext__c = ioAccount.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber);
		}
		//Below else if is added by Pradeep to resolve DE7245.
		else if(ioAccount.CorporateRelationships != null && ioAccount.CorporateRelationships.HeadQuartersOrParent != null
				&& ioAccount.CorporateRelationships.HeadQuartersOrParent.CDHPartyNumber == null){
			 account.Headquarters__c = null;
			 headQuarterNumber = '';
		}

		if(ioAccount.CorporateRelationships != null && ioAccount.CorporateRelationships.DomesticUltimate != null
			&& String.isNotBlank(ioAccount.CorporateRelationships.DomesticUltimate.CDHPartyNumber)
			&& mapOfCDHPartyNumberandCDHPartyRecord.get(ioAccount.CorporateRelationships.DomesticUltimate.CDHPartyNumber.trim()) != null){

			CDH_Party__c duCDHParty = CDHParty_Instance_Prepare(ioAccount.CorporateRelationships.DomesticUltimate.CDHPartyNumber,
			ioAccount.CorporateRelationships.DomesticUltimate.Name, '', ioAccount.CorporateRelationships.DomesticUltimate.DUNS);
			duCDHParty.CDH_Party_Number_Ext__c = ioAccount.CorporateRelationships.DomesticUltimate.CDHPartyNumber;

			setofCDHPartyToBeProcessed.add(duCDHParty);

			account.Domestic_Ultimate__r = new CDH_Party__c(CDH_Party_Number_Ext__c = ioAccount.CorporateRelationships.DomesticUltimate.CDHPartyNumber);

			domesticUltimateNumber = ioAccount.CorporateRelationships.DomesticUltimate.CDHPartyNumber;
		}else if(ioAccount.CorporateRelationships != null && ioAccount.CorporateRelationships.DomesticUltimate != null
				&& String.isNotBlank(ioAccount.CorporateRelationships.DomesticUltimate.CDHPartyNumber)){

			domesticUltimateNumber = ioAccount.CorporateRelationships.DomesticUltimate.CDHPartyNumber;

			CDH_Party__c duCDHParty = CDHParty_Instance_Prepare(ioAccount.CorporateRelationships.DomesticUltimate.CDHPartyNumber,
			ioAccount.CorporateRelationships.DomesticUltimate.Name, '', ioAccount.CorporateRelationships.DomesticUltimate.DUNS);
			duCDHParty.CDH_Party_Number_Ext__c = ioAccount.CorporateRelationships.DomesticUltimate.CDHPartyNumber;

			setofCDHPartyToBeProcessed.add(duCDHParty);

			account.Domestic_Ultimate__r = new CDH_Party__c(CDH_Party_Number_Ext__c = ioAccount.CorporateRelationships.DomesticUltimate.CDHPartyNumber);
		}
		//Below else if is added by Pradeep to resolve DE7245.
		else if(ioAccount.CorporateRelationships != null && ioAccount.CorporateRelationships.DomesticUltimate != null
				&& ioAccount.CorporateRelationships.DomesticUltimate.CDHPartyNumber == null){
			account.Domestic_Ultimate__c = null;
			domesticUltimateNumber = '';
		}

		if(ioAccount.CorporateRelationships != null && ioAccount.CorporateRelationships.GlobalUltimate != null
			&& String.isNotBlank(ioAccount.CorporateRelationships.GlobalUltimate.CDHPartyNumber)
			&& mapOfCDHPartyNumberandCDHPartyRecord.get(ioAccount.CorporateRelationships.GlobalUltimate.CDHPartyNumber.trim()) != null){

			CDH_Party__c guCDHParty = CDHParty_Instance_Prepare(ioAccount.CorporateRelationships.GlobalUltimate.CDHPartyNumber, ioAccount.CorporateRelationships.GlobalUltimate.Name, '', ioAccount.CorporateRelationships.GlobalUltimate.DUNS);
			guCDHParty.CDH_Party_Number_Ext__c = ioAccount.CorporateRelationships.GlobalUltimate.CDHPartyNumber;
			// add the CDH Party record in the set of CDH Party records (to avoid the duplicate)
			setofCDHPartyToBeProcessed.add(guCDHParty);

			account.Global_Ultimate__r = new CDH_Party__c(CDH_Party_Number_Ext__c = ioAccount.CorporateRelationships.GlobalUltimate.CDHPartyNumber);

			globalUltimateNumber = ioAccount.CorporateRelationships.GlobalUltimate.CDHPartyNumber;
		}else if(ioAccount.CorporateRelationships != null && ioAccount.CorporateRelationships.GlobalUltimate != null
				&& String.isNotBlank(ioAccount.CorporateRelationships.GlobalUltimate.CDHPartyNumber)){

			CDH_Party__c guCDHParty = CDHParty_Instance_Prepare(ioAccount.CorporateRelationships.GlobalUltimate.CDHPartyNumber, ioAccount.CorporateRelationships.GlobalUltimate.Name, '', ioAccount.CorporateRelationships.GlobalUltimate.DUNS);
			guCDHParty.CDH_Party_Number_Ext__c = ioAccount.CorporateRelationships.GlobalUltimate.CDHPartyNumber;

			// add the CDH Party record in the set of CDH Party records (to avoid the duplicate)
			setofCDHPartyToBeProcessed.add(guCDHParty);

			globalUltimateNumber = ioAccount.CorporateRelationships.GlobalUltimate.CDHPartyNumber;

			account.Global_Ultimate__r = new CDH_Party__c(CDH_Party_Number_Ext__c = ioAccount.CorporateRelationships.GlobalUltimate.CDHPartyNumber);
		}
		//Below else if is added by Pradeep to resolve DE7245.
		else if(ioAccount.CorporateRelationships != null && ioAccount.CorporateRelationships.GlobalUltimate != null
				&& ioAccount.CorporateRelationships.GlobalUltimate.CDHPartyNumber == null){
			 account.Global_Ultimate__c = null;
			 globalUltimateNumber = '';
		}
		return account;
	}

	/**
	 * method to prepare the CDH Party instance .This method receives the CDH Party domain object and return the CDH Party instance.
	 * 
	 * @param CDHPartyNumber
	 * @param cdhPartyName
	 * @param cdhPartyType
	 * @param dunsNumber
	 * @return cdh party
	 */
	public CDH_Party__c CDHParty_Instance_Prepare(String CDHPartyNumber, String cdhPartyName, String cdhPartyType, String dunsNumber) {
		system.debug('=============================================================>'+CDHPartyNumber);
		CDH_Party__c cdhParty = new CDH_Party__c();
		cdhParty.Name = CDHPartyNumber;
		cdhParty.CDH_Party_Name__c = cdhPartyName;
		cdhParty.CDH_Party_Type__c = cdhPartyType;
		cdhParty.DUNS__c = dunsNumber;
		return cdhParty;
	}

	/**
	 * method used to assign record type to the account record created based on the region of identifying address of sales account.
	 * 
	 * @param account the integration object sales account to use
	 * @return record type id
	 */
	public Id GetAccountRecordTypeIdAsPerCountry (IntegrationObjects.SalesAccount account) {
		String countryOfIdentifyingAddress = null;

		if(account.Addresses != null && ! account.Addresses.isEmpty()) {
			system.debug('==============line no 794'+account.Addresses);
			for(IntegrationObjects.Address address : account.Addresses){
				if(address.Identifying_Address == true && address.Country != Null && address.Country != ''){
					countryOfIdentifyingAddress = address.Country.toUpperCase();
					system.debug('==============line no 799'+countryOfIdentifyingAddress);
					break;
				}
			}
		}
		else if(! addressSalesAccountIds.isEmpty()) {
			// DE9454 - Logic update to work with multiple sales account ids rather
			//          than a single value.
			system.debug('==============line no 804'+addressSalesAccountIds);
			for(Address__c address : [
				SELECT Id,
					Country__c,
					Identifying_Address__c,
					Sales_Account__c
				FROM Address__c
				WHERE Identifying_Address__c = true
					AND Sales_account__c in :addressSalesAccountIds
					AND Country__c != null
				LIMIT 1])
			{
				system.debug('==============line no 806'+address);
				countryOfIdentifyingAddress = address.Country__c.toUpperCase();
				system.debug('==============line no 809'+countryOfIdentifyingAddress);
			}
		}
		if(countryOfIdentifyingAddress != null){
			// US77119 - Update to avoid a null exception found in a test method
			for(Country__c country : [
				Select
					Iso3166Alpha2__c,
					Global_Region__c
				from Country__c
				where  Iso3166Alpha2__c = :countryOfIdentifyingAddress 
					and Global_Region__c != null
				order by Global_Region__c
				limit 1] )
			{
				BillingCountry = country.Iso3166Alpha2__c;
				system.debug('==============line no 815'+BillingCountry);
				Id recordTypeId = getRecordTypeId(country.Global_Region__c+' Account');
				system.debug('==============line no 825'+recordTypeId);
				return recordTypeId;
			}
		}
		return null;
	}

	/**
	 * method used to assign record type to the account record created based on the region of identifying address only for partner accounts
	 * @param account the integration object sales account to use
	 * @return record type id
	 */
	public Id GetAccountRecordTypeIdAsPerCountryForPartner(IntegrationObjects.SalesAccount account) {
		String countryOfIdentifyingAddress = null;
		String stateOfIndentifyingAddress = null;

		if(account.Addresses != Null && account.Addresses.size() > 0){
			system.debug('==============line no 794'+account.Addresses);
			for(IntegrationObjects.Address address : account.Addresses){
				if(address.Identifying_Address == True && address.Country != Null && address.Country != ''){
					countryOfIdentifyingAddress = address.Country.toUpperCase();
					system.debug('==============line no 799'+countryOfIdentifyingAddress);
					break;
				}
			}
		}
		else if(! addressSalesAccountIds.isEmpty()) { // DE9454 -updated to deal with multiple sales account ids
			system.debug('==============line no 804'+addressSalesAccountIds);
			for(Address__c address : [
				SELECT Id,
					Country__c,
					State__c,
					Province__c,
					Identifying_Address__c,
					Sales_Account__c
				FROM Address__c
				WHERE Identifying_Address__c = true
					AND Sales_account__c in : addressSalesAccountIds
					AND Country__c != null
				ORDER BY State__c NULLS LAST, Province__c NULLS LAST
				LIMIT 1 ])
			{
				system.debug('==============line no 806'+address);
				countryOfIdentifyingAddress = address.Country__c.toUpperCase();
				stateOfIndentifyingAddress = address.Province__c;
				if (address.State__c != null) {
					stateOfIndentifyingAddress = address.State__c;
				}
			}

			system.debug('==============line no 809'+countryOfIdentifyingAddress);
		}
		if(countryOfIdentifyingAddress != null && cdhMasteredFlag && account.PartnerClassifications != null && ! account.PartnerClassifications.isEmpty())
		{
			// DE9454 - Resolved null exceptions found in test class
			List<Country__c> countryList = new List<Country__c>();
			for(Country__c country : [
				Select Id,
					Iso3166Alpha2__c,
					Global_Region__c,
					(Select Abbreviation__c, Subregion__c from States__r)
				from Country__c 
				where  Iso3166Alpha2__c = :countryOfIdentifyingAddress 
					and Global_Region__c != Null
				limit 1] )
			{
				BillingCountry = country.Iso3166Alpha2__c;
				system.debug('==============line no 815'+BillingCountry);
				partnerRegion = country.Global_Region__c;
				if (partnerRegion == 'NA' && country.States__r != null) {
					for (State__c state : country.States__r){
						if (state.Abbreviation__c == stateOfIndentifyingAddress){
							partnerSubregion = state.Subregion__c;
							break;
						}
					}
				}
				return getRecordTypeId(country.Global_Region__c+' Partner');
			}
		}
		return null;
	}

	/**
	 * Will pass list of account created / updated for partner classifiction here
	 * @param accountListToClone
	 * @param account the integration object sales account to use
	 * @return account list
	 */
	public List<Account> createMissingPartnerAccounts(list<Account> accountListToCreate, IntegrationObjects.SalesAccount account){
		Savepoint savepoint = Database.setSavepoint();
		List<Account> accList = new List<Account>();
		try{
			String rId;
			if(account != Null){

				rId = GetAccountRecordTypeIdAsPerCountryForPartner(account);
			}
			// the following code makes absolutely no sense...
			for(Integer i = 1; i <= accountListToCreate.size(); i++){
				Account accountToBeCreated = ConvertioAccount(account);
				system.debug('==================================================>'+account.CDH_Party_Number);
				system.debug('==================================================>'+headQuarterNumber);
				system.debug('==================================================>'+globalUltimateNumber);
				system.debug('==================================================>'+domesticUltimateNumber);

				accountToBeCreated.CDH_Party_Name__r = new CDH_Party__c(CDH_Party_Number_Ext__c = account.CDH_Party_Number);
				if(headQuarterNumber != '' && headQuarterNumber !=null)
					accountToBeCreated.Headquarters__r = new CDH_Party__c(CDH_Party_Number_Ext__c = headQuarterNumber);

				if(globalUltimateNumber != '' && globalUltimateNumber !=null)
					accountToBeCreated.Global_Ultimate__r = new CDH_Party__c(CDH_Party_Number_Ext__c = globalUltimateNumber);

				if(domesticUltimateNumber != '' && domesticUltimateNumber !=null)
					accountToBeCreated.Domestic_Ultimate__r = new CDH_Party__c(CDH_Party_Number_Ext__c = domesticUltimateNumber);

				accountToBeCreated.RecordTypeId = rId;
				if(accountToBeCreated.Id == null && accountToBeCreated.RecordTypeId != null && accountToBeCreated.OwnerId == null) {
					accountToBeCreated.OwnerId = getDefaultOwnerId(accountToBeCreated.RecordTypeId);
				}
				accountToBeCreated.JigSaw = null;
				accountToBeCreated.Global_Region__c = partnerRegion;
				if (partnerSubregion != null)
					accountToBeCreated.Subregion__c = partnerSubregion;
				accList.add(accountToBeCreated);
			}
			if(accList.size() > 0)
				insert accList;

		}catch(Exception e){
			System.debug('Error: '+e.getMessage());
			Database.rollback(savepoint);
			throw new Interface_ServiceException('Unable to persist SalesAccount data in Salesforce: ' + e.getmessage());
		}

		system.debug('==========++++++++++++++'+accList+'========================feerererrrrrrr'+accList.size());
		return accList;
	}

//depreciated	/**
//depreciated	 * Returns the comma seperated fields in a String
//depreciated	 * @param SobjectApiName
//depreciated	 * @return comma separated fields
//depreciated	 */
//depreciated	public string objectFields(string SobjectApiName){
//depreciated		String commaSepratedFields = '';
//depreciated		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
//depreciated		Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();

//depreciated		for(String fieldName : fieldMap.keyset()){
//depreciated			if(!fieldName.equalsIgnoreCase('Id')){
//depreciated			  if(commaSepratedFields == null || commaSepratedFields == ''){
//depreciated				commaSepratedFields = fieldName;
//depreciated			  }else{
//depreciated				commaSepratedFields = commaSepratedFields + ', ' + fieldName;
//depreciated			  }
//depreciated			}
//depreciated		}
//depreciated		return commaSepratedFields;
//depreciated	}

//depreciated	/**
//depreciated	 * Returns the comma seperated fields in a String
//depreciated	 * @param SobjectApiName
//depreciated	 * @return comma separated fields
//depreciated	 */
//depreciated	public string accountObjectFields(string SobjectApiName){
//depreciated		String commaSepratedFields = '';
//depreciated		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
//depreciated		Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();

//depreciated		for(String fieldName : fieldMap.keyset()){
//depreciated			if(!fieldName.equalsIgnoreCase('Id') && !fieldName.equalsIgnoreCase('Headquarters__c') && !fieldName.equalsIgnoreCase('Global_Ultimate__c') && !fieldName.equalsIgnoreCase('Domestic_Ultimate__c')){
//depreciated			  if(commaSepratedFields == null || commaSepratedFields == ''){
//depreciated				commaSepratedFields = fieldName;
//depreciated			  }else{
//depreciated				commaSepratedFields = commaSepratedFields + ', ' + fieldName;
//depreciated			  }
//depreciated			}
//depreciated		}
//depreciated		return commaSepratedFields;
//depreciated	}

	/**
	 * Class to allow sorting of classification codes.
	 */
	public class ClassificationCodeWrapper implements Comparable {

		/** The classification represented by this object */
		public IntegrationObjects.Classification merchItem;

		// Constructor

		/**
		 * Constroctor
		 * 
		 * @param merchItem
		 */
		public ClassificationCodeWrapper(IntegrationObjects.Classification merchItem) {
			this.merchItem = merchItem;
		}

		/**
		 * Compare merchandise items based on the merchandise price.
		 * @param compareTo
		 * @return 0 if equal to compareTo, -1 if less than compareTo, 1 if greater than compareTo
		 */	
		public Integer compareTo(Object compareTo) {
			// Cast argument to MerchandiseWrapper
			ClassificationCodeWrapper compareToMerch = (ClassificationCodeWrapper)compareTo;
			// The return value of 0 indicates that both elements are equal.
			Integer returnValue = 0;
			if (merchItem.EndDate > compareToMerch.merchItem.EndDate) {
				// Set return value to a positive value.
				returnValue = 1;
			} else if (merchItem.EndDate < compareToMerch.merchItem.EndDate) {
				// Set return value to a negative value.
				returnValue = -1;
			}
			return returnValue;
		}
	}

}