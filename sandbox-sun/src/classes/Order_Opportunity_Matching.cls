/**
 * This class defines the logic for  opportunity matching while the come from external system 
 * 
 * @version 2016-04-04
 * @author Vipul Jain <vipujain@DELOITTE.com>
 * @since 2014-09-10 - Added Opportunity Update Logic.
 * @since 2014-03-10 - initial version
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2016-04-04 - Comment out In1 to resolve DE10221
 * @since 2016-02-16 - Sort products with active products last
 * @since 2016-02-03 - Optimizing queries to reduce query timeout errors
 * @since 2016-01-22 - Updated opprtunityPartnerItemProcess per US81192 to filter partners
 * @since 2016-01-22 - New maps added operatingUnitMap, partnersByCDHPartyNameByRecordTypeMap
 * @since 2016-01-22 - New methods getPartnersByOperatingUnitAndPartnerStaging, second version of errorRecordCreation
 * @since 2016-01-22 - Error In27, change to In37.  Partner related matching errors changed to labels.
 * @since 2016-01-22 - Map of partners and Non-Encustomer Accounts replaced with nonEcoAccountByCDHPartyName only for non-endcustomer accounts
 * @since 2015-12-11 - set the override embedded allowed flag
 * @since 2015-11-04 - do not assign opportunity owner id based on 'INVOICED' records.
 * @since 2015-09-23 - filter influencing partners
 * @since 2015-08-26 - No longer set the touched flag
 * @since 2015-06-03 - Reformatted code (spacing and such) to too improve readability.
 * @since 2015-06-03 - Added errorRecordCreationWithDetails method to capture exception and other critical errors with more details
 * @since 2015-06-03 - Refactored code to try and catch errors per record, when possible.
 * @since 2015-06-03 - Moved most methods and fields into a private inner class to make certain only entry points which catch exceptions are used and fields are retained across multiple processOrders calls.
 * @author Scott Coleman <scoleman@redhat.com>
 * @since 2015-08-11 - Resolved DE8897 by eliminating line errors D24, I26, and In23
 * @since 2015-07-27 - Now addresses are created with Identifying Address = false to resolve DE8882
 * @since 2015-07-14 - US70316 Included field Origin__c in the query for staging headers
 * 
 * @todo This class needs to be updated to be bulk safe.  An error doing an update or insert from one stage record will
 * force us to add an error to all staging records being processed.  As such a list size greater than 1 should
 * be avoided when possible.
 */
public class Order_Opportunity_Matching {
	// static variable for Ready For Reprocessing status
	private static final String READY_FOR_REPROCESSING = 'Ready For Reprocessing';
	private static final String NOT_PROCESSED = 'Not Processed';
	private static final String PENDING_BOOKED_ORDER_PROCESS = 'Pending Booked Order Process';
	private static final Set<String> nonEntitleToAccountRecordTypeNames =  new Set<String>{'APAC Account','Default','EMEA Account','DLT','LATAM Account','Master Account Layout','NA Account','Strategic'};

	// map to hold the error code for each match type.
	private static final Map<String,Integer> matchTypeAndErrorCodeMap = new Map<String,Integer>{'Bill'=>0,'Ship'=>1,'Sold'=>2,'Entitle'=>3};

	private static Id bookedInProcess {
		get {
			if (bookedInProcess == null) {
				bookedInProcess = RecordTypeLookup.getRecordTypeId('Booked opp process','Opportunity');
			}
			return bookedInProcess;
		}
	}

	private static Set<Id> getRecordTypeIds(Set<String> recordTypeNames,Map<String,Schema.RecordTypeInfo> recordTypeInfoMap) {
		Set<Id> recordTypeIds = new Set<Id>();
		if(recordTypeNames != null && ! recordTypeNames.isEmpty()) {
			for(String recordTypeName : recordTypeNames) {
				Schema.RecordTypeInfo recordTypeInfo = recordTypeInfoMap.get(recordTypeName);
				if(recordTypeInfo != null) {
					recordTypeIds.add(recordTypeInfo.getRecordTypeId());
				}
			}
		}
		return recordTypeIds;
	}

	private static Set<Id> getAccountRecordTypeIds(Set<String> recordTypeNames) {
		return getRecordTypeIds(recordTypeNames,Schema.SObjectType.Account.getRecordTypeInfosByName());
	}

	private static Set<Id> getOpportunityRecordTypeIds(Set<String> recordTypeNames) {
		return getRecordTypeIds(recordTypeNames,Schema.SObjectType.Opportunity.getRecordTypeInfosByName());
	}

	// map to hold global region for each country ISO code.
	private static Map<String,String> countryCodeAndGlobalRegionMap {
		get {
			if(countryCodeAndGlobalRegionMap == null) {
				countryCodeAndGlobalRegionMap = new Map<String,String>();
				for(Country__c country :[
					Select Id,
						Name ,
						Iso3166Alpha2__c,
						Global_Region__c 
					from Country__c ] ) 
				{		
					countryCodeAndGlobalRegionMap.put(country.Iso3166Alpha2__c,country.Global_Region__c);
				}
			}
			return countryCodeAndGlobalRegionMap;
		}
	}

	// Integration user to be assigned to Opportunity Order Tracking records when the data flow happens from EBS
	private static Id integrationUserId {
		get {
			if (integrationUserId == null) {
				integrationUserId = UserInfo.getUserId();
				if(UserInfo.getUserName() != 'Integration Admin') {
					for(User u : [SELECT Id FROM User WHERE Name = 'Integration Admin' AND IsActive=true Limit 1] ) {
						integrationUserId = u.Id;
					}
				}
			}
			return integrationUserId;
		}
	}

	private static Id globalPriceBookId { get {
		if(globalPriceBookId == null) {
			globalPricebookId = [
				SELECT Id 
				FROM Pricebook2 
				WHERE Name = 'Global Price Book' limit 1].Id;
		}
		return globalPriceBookId;
	}}

	/**
	 * Method to check if CDH instance already exists in Set of CDH parties which are yet to be inserted.
	 * @param Opportunity staging record to process
	 * @return true if CDH_Party_Number_Ext__c is equal to CDHPartyNumber for any of the members of he set
	 */
	@TestVisible
	private static Boolean checkCDHinSet(Set<CDH_Party__c> setCDHParty,String CDHPartyNumber)
	{
		//Added by Niti to check if the chd instance already exists in cDHPartyToInsertSet with same CDH_Party_Number_Ext__c
		for( CDH_Party__c cdhPartyObj : setCDHParty)
		{
			if (cdhPartyObj.CDH_Party_Number_Ext__c == CDHPartyNumber) {
				return false;
			}
		}
		return true;
	}

	private static void clearMultiMatch(Opportunity_Line_Staging__c line) {
		if(line.Entitle_To_Sales_Account__c == null) {
			line.Entitle_To_Sales_Account__r = null;
		}
		if(line.Entitle_To_Account__c == null) {
			line.Entitle_To_Account__r = null;
		}
		if(line.Entitle_To_Address__c == null) {
			line.Entitle_To_Address__r = null;
		}
		if(line.Entitle_To_Contact__c == null) {
			line.Entitle_To_Contact__r = null;
		}
	}

	@TestVisible
	private static Map<String,OperatingUnit__c> getOperatingUnitMap(final List<Opportunity_Header_Staging__c> oppHeaderStagingList ) {
		Map<String,OperatingUnit__c> operatingUnitMap = new Map<String,OperatingUnit__c>();
		Set<String> operatingUnits = new Set<String>();
		for(Opportunity_Header_Staging__c headerStaging : oppHeaderStagingList) {
			if(headerStaging.Operating_Unit__c != null) {
				operatingUnits.add(headerStaging.Operating_Unit__c.toUpperCase());
			}
		}
		if(! operatingUnits.isEmpty()) {
			System.debug('operatingUnits='+operatingUnits);
			for(OperatingUnit__c ou : [
				select Id,
					AccountRecordType__c,
					BusinessUnitId__c,
					Name,
					PartnerRecordType__c,
					Region__c
				from OperatingUnit__c
				where Name in :operatingUnits ] )
			{
				operatingUnitMap.put(ou.Name.toUpperCase(),ou);
			}
		}
		return operatingUnitMap;
	}

	@TestVisible
	private static Map<String,Map<String,List<Account>>> getPartnersByCDHPartyNameByRecordTypeMap(List<Opportunity_Partner_Staging__c> oppPartnerStagingList, Map<String,OperatingUnit__c> operatingUnitMap) {
		Map<String,Map<String,List<Account>>> partnersByCDHPartyNameByRecordTypeMap = new Map<String,Map<String,List<Account>>>();
		Set<String> cdhPartyNames = new Set<String>();
		Set<String> oracleClassificationCodes = new Set<String>();
		for(Opportunity_Partner_Staging__c partnerStaging : oppPartnerStagingList ) {
			if(partnerStaging.CDH_Party_Number__c != null) {
				cdhPartyNames.add(partnerStaging.CDH_Party_Number__c);
			}
			if(partnerStaging.Oracle_Classification_Code__c != null) {
				oracleClassificationCodes.add(partnerStaging.Oracle_Classification_Code__c);
			}
		}
		if(! cdhPartyNames.isEmpty()) {
			Set<String> recordTypeNames = new Set<String>();
			for(OperatingUnit__c ou : operatingUnitMap.values()) {
				if(ou.PartnerRecordType__c != null) {
					recordTypeNames.add(ou.PartnerRecordType__c);
				}
			}
			if(! recordTypeNames.isEmpty()) {
				System.debug('recordTypeNames='+recordTypeNames);
				System.debug('cdhPartyNames='+cdhPartyNames);
				for(Account partner : [
					select Id,
						Account_External_Id__c,
						CDH_Party_Name__c,
						CDH_Party_Name__r.Name,
						CDH_Party_Number__c,
						RecordTypeId,
						RecordType.DeveloperName,
						RecordType.Name,
						Name,
						(	select Id, Partner__c 
							from PartnerStatuses__r
							where ActivationStatus__c = 'Active'
								and PartnerType__r.Hierarchy__c like 'Partner Type%' 
							limit 1 ),
						(	select Id, Oracle_Classification_Code__c
							from Partner_Programs__r
							where Oracle_Classification_Code__c in :oracleClassificationCodes
								and Active__c = true )
					from Account
					where CDH_Party_Name__c in (select Id from CDH_Party__c where Name in :cdhPartyNames)
						AND RecordTypeId in :getAccountRecordTypeIds(recordTypeNames) ] )
				{
					if(partner.RecordType != null && partner.CDH_Party_Name__r != null) {
						String recordTypeName = partner.RecordType.Name.toUpperCase();
						Map<String,List<Account>> partnersByCDHPartyName = partnersByCDHPartyNameByRecordTypeMap.get(recordTypeName);
						if(partnersByCDHPartyName == null) {
							partnersByCDHPartyName = new Map<String,List<Account>>();
							partnersByCDHPartyNameByRecordTypeMap.put(recordTypeName,partnersByCDHPartyName);
						}
						String cdhPartyName = partner.CDH_Party_Name__r.Name;
						List<Account> partners = partnersByCDHPartyName.get(cdhPartyName);
						if(partners == null) {
							partners = new List<Account>();
							partnersByCDHPartyName.put(cdhPartyName,partners);
						}
						partners.add(partner);
					}
				}
			}
		}
		return partnersByCDHPartyNameByRecordTypeMap;
	}

	/*
	 * Method used to query the order details
	 * @param ids set of the opportunity staging record Id.
	 */
	public static List<Opportunity_Header_Staging__c> queryOrders(final Set<Id> ids){
		return [
			select Id,
				Name,
				Amount__c,
				Bill_To_Account_Number__c,
				Bill_To_Account__c,
				Bill_To_Account__r.Sales_Account__c,
				Bill_To_Account__r.Sales_Account__r.Account_External_Id__c,
				Bill_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
				Bill_To_Address_CDH_Party_Site_Number__c,
				Bill_To_Address_Line_1__c,
				Bill_To_Address_Line_2__c,
				Bill_To_Address_Line_3__c,
				Bill_To_Address_Line_4__c,
				Bill_To_Address__c,
				Bill_To_Address__r.Sales_Account__c,
				Bill_To_Address__r.Sales_Account__r.Account_External_Id__c,
				Bill_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
				Bill_To_CDH_Party_Number__c,
				Bill_To_CDH_Party_Number_Account__c,
				Bill_To_City__c,
				Bill_To_Contact_Email__c,
				Bill_To_Contact_First_Name__c,
				Bill_To_Contact_Last_Name__c,
				Bill_To_Contact_Phone__c,
				Bill_To_Contact__c,
				Bill_To_Contact__r.AccountId,
				Bill_To_Contact__r.Account.Account_External_Id__c,
				Bill_To_Contact__r.Account.CDH_Party_Name__r.Name,
				Bill_To_Country__c,
				Bill_To_County__c,
				Bill_To_Party_Name__c,
				Bill_To_Party_Number__c,
				Bill_To_Party_Type__c,
				Bill_To_Province__c,
				Bill_To_Sales_Account__c,
				Bill_To_Sales_Account__r.Account_External_Id__c,
				Bill_To_Sales_Account__r.CDH_Party_Name__r.Name,
				Bill_To_State__c,
				Bill_To_Zip_Postal_Code__c,
				Channel__c,
				CurrencyIsoCode,
				//Date_Ordered__c,
				Date_Booked__c,//Changes for US68220
				Employee_Number__c,
				Entitle_To_Account_Number__c,
				Entitle_To_Account__c,
				Entitle_To_Account__r.Sales_Account__c,
				Entitle_To_Account__r.Sales_Account__r.Account_External_Id__c,
				Entitle_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
				Entitle_To_Address_CDH_Party_Site_Number__c,
				Entitle_To_Address_Line_1__c,
				Entitle_To_Address_Line_2__c,
				Entitle_To_Address_Line_3__c,
				Entitle_To_Address_Line_4__c,
				Entitle_To_Address__c,
				Entitle_To_Address__r.Sales_Account__c,
				Entitle_To_Address__r.Sales_Account__r.Account_External_Id__c,
				Entitle_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
				Entitle_To_CDH_Party_Number__c,
				Entitle_To_CDH_Party_Number_Account__c,
				Entitle_To_City__c,
				Entitle_To_Contact_Email__c,
				Entitle_To_Contact_First_Name__c,
				Entitle_To_Contact_Last_Name__c,
				Entitle_To_Contact_Phone__c,
				Entitle_To_Contact__c,
				Entitle_To_Contact__r.AccountId,
				Entitle_To_Contact__r.Account.Account_External_Id__c,
				Entitle_To_Contact__r.Account.CDH_Party_Name__r.Name,
				Entitle_To_Country__c,
				Entitle_To_County__c,
				Entitle_To_Party_Name__c,
				Entitle_To_Party_Number__c,
				Entitle_To_Party_Type__c,
				Entitle_To_Province__c,
				Entitle_To_Sales_Account__c,
				Entitle_To_Sales_Account__r.Account_External_Id__c,
				Entitle_To_Sales_Account__r.CDH_Party_Name__r.Name,
				Entitle_To_State__c,
				Entitle_To_Zip_Postal_Code__c,
				LastModifiedDate,
				Operating_Unit__c,
				Opportunity_ID__c,
				Opportunity_Name__c,
				Opportunity_Number__c,
				Opportunity_Owner__c,
				Oracle_Order_ID__c,
				Oracle_Order_Number__c,
				Order_Last_Update_Date__c,
				Order_Source__c,
				Order_Status__c,
				Order_Type__c,
				Origin__c,
				OwnerId,
				Payment_Type__c,
				PO_Number__c,
				Resller_PO__c,
				Status__c,
				Sales_Account__c,
				Sales_Account__r.Account_External_Id__c,
				Sales_Account__r.CDH_Party_Name__r.Name,
				Ship_To_Account_Number__c,
				Ship_To_Account__c,
				Ship_To_Account__r.Sales_Account__c,
				Ship_To_Account__r.Sales_Account__r.Account_External_Id__c,
				Ship_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
				Ship_To_Address_CDH_Party_Site_Number__c,
				Ship_To_Address_Line_1__c,
				Ship_To_Address_Line_2__c,
				Ship_To_Address_Line_3__c,
				Ship_To_Address_Line_4__c,
				Ship_To_Address__c,
				Ship_To_Address__r.Sales_Account__c,
				Ship_To_Address__r.Sales_Account__r.Account_External_Id__c,
				Ship_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
				Ship_To_CDH_Party_Number__c,
				Ship_To_CDH_Party_Number_Account__c,
				Ship_To_City__c,
				Ship_To_Contact_Email__c,
				Ship_To_Contact_First_Name__c,
				Ship_To_Contact_Last_Name__c,
				Ship_To_Contact_Phone__c,
				Ship_To_Contact__c,
				Ship_To_Contact__r.AccountId,
				Ship_To_Contact__r.Account.Account_External_Id__c,
				Ship_To_Contact__r.Account.CDH_Party_Name__r.Name,
				Ship_To_Country__c,
				Ship_To_County__c,
				Ship_To_Party_Name__c,
				Ship_To_Party_Number__c,
				Ship_To_Party_Type__c,
				Ship_To_Province__c,
				Ship_To_Sales_Account__c,
				Ship_To_Sales_Account__r.Account_External_Id__c,
				Ship_To_Sales_Account__r.CDH_Party_Name__r.Name,
				Ship_To_State__c,
				Ship_To_Zip_Postal_Code__c,
				Sold_To_Account_Number__c,
				Sold_To_Account__c,
				Sold_To_Account__r.Sales_Account__c,
				Sold_To_Account__r.Sales_Account__r.Account_External_Id__c,
				Sold_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
				Sold_To_Address_CDH_Party_Site_Number__c,
				Sold_To_Address_Line_1__c,
				Sold_To_Address_Line_2__c,
				Sold_To_Address_Line_3__c,
				Sold_To_Address_Line_4__c,
				Sold_To_Address__c,
				Sold_To_Address__r.Sales_Account__c,
				Sold_To_Address__r.Sales_Account__r.Account_External_Id__c,
				Sold_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
				Sold_To_CDH_Party_Number__c,
				Sold_To_CDH_Party_Number_Account__c,
				Sold_To_City__c,
				Sold_To_Contact_Email__c,
				Sold_To_Contact_First_Name__c,
				Sold_To_Contact_Last_Name__c,
				Sold_To_Contact_Phone__c,
				Sold_To_Contact__c,
				Sold_To_Contact__r.AccountId,
				Sold_To_Contact__r.Account.Account_External_Id__c,
				Sold_To_Contact__r.Account.CDH_Party_Name__r.Name,
				Sold_To_Country__c,
				Sold_To_County__c,
				Sold_To_Party_Name__c,
				Sold_To_Party_Number__c,
				Sold_To_Party_Type__c,
				Sold_To_Province__c,
				Sold_To_Sales_Account__c,
				Sold_To_Sales_Account__r.Id,
				Sold_To_Sales_Account__r.Account_External_Id__c,
				Sold_To_Sales_Account__r.CDH_Party_Name__r.Name,
				Sold_To_State__c,
				Sold_To_Zip_Postal_Code__c,
				Non_Entitled_Endco__c,
				Non_Entitled_Endco_CDH_Party_Number__c,
				Non_Entitled_Endco_Party_Name__c,
				(SELECT Id,
					Name,
					ActualEndDate__c,
					ActualStartDate__c,
					Adjusted_Price__c,
					Base_Price__c,
					Contract_Numbers__c,
					CurrencyIsoCode,
					Entitle_To_Account_Number__c,
					Entitle_To_Account__c,
					Entitle_To_Account__r.Sales_Account__c,
					Entitle_To_Account__r.Sales_Account__r.Account_External_Id__c,
					Entitle_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
					Entitle_To_Address_Line_1__c,
					Entitle_To_Address_Line_2__c,
					Entitle_To_Address_Line_3__c,
					Entitle_To_Address_Line_4__c,
					Entitle_To_Address__c,
					Entitle_To_Address__r.Sales_Account__c,
					Entitle_To_Address__r.Sales_Account__r.Account_External_Id__c,
					Entitle_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
					Entitle_To_CDH_Party_Number_Account__c,
					Entitle_To_CDH_Party_Number__c,
					Entitle_To_CDH_Party_Site_Number__c,
					Entitle_To_City__c,
					Entitle_To_Contact_Email__c,
					Entitle_To_Contact_First_Name__c,
					Entitle_To_Contact_Last_Name__c,
					Entitle_To_Contact_Phone__c,
					Entitle_To_Contact__c,
					Entitle_To_Contact__r.AccountId,
					Entitle_To_Contact__r.Account.Account_External_Id__c,
					Entitle_To_Contact__r.Account.CDH_Party_Name__r.Name,
					Entitle_To_Country__c,
					Entitle_To_County__c,
					Entitle_To_Party_Name__c,
					Entitle_To_Party_Number__c,
					Entitle_To_Party_Type__c,
					Entitle_To_Province__c,
					Entitle_to_Sales_Account__c,
					Entitle_To_Sales_Account__r.Account_External_Id__c,
					Entitle_To_Sales_Account__r.CDH_Party_Name__r.Name,
					Entitle_To_State__c,
					Entitle_To_Zip_Postal_Code__c,
					Install_Base_Number__c,
					Opportunity_ID__c,
					Opportunity_Number__c,
					Opportunity_Product_ID__c,
					Opportunity_Stage_Header_ID__c,
					Opportunity_Stage_Header_ID__r.Opportunity_Number__c,
					Opportunity_Stage_Header_ID__r.Opportunity_ID__c,
					Opportunity_Stage_Header_ID__r.Order_Source__c,
					Opportunity_Stage_Header_ID__r.CurrencyIsoCode,
					Oracle_Order_Header_Id__c,
					Product_Code_Oracle__c,
					Product_Code__c,
					Quantity__c,
					Return_Reason_Code__c,
					SystemModstamp,
					Total_Price__c,
					UnitPrice__c,
					Unit_of_Measure__c 
				FROM Opportunities_Line_Staging__r),
				(SELECT Id,
					Name,
					CDH_Party_Number__c,
					EBS_Account_Number__c,
					Opportunity_Stage_Header_ID__c,
					Oracle_Order_Header_Id__c,
					PartnerTier__c,
					Partner_Contact_CDH_Party_Number__c,
					Partner_Contact_Email__c,
					Partner_Contact_First_Name__c,
					Partner_Contact_Last_Name__c,
					Partner_Contact_Phone__c,
					Partner_Contact__c,
					Partner_Contact__r.AccountId,
					Partner_Contact__r.Account.Account_External_Id__c,
					Partner_Contact__r.Account.CDH_Party_Name__r.Name,
					Partner_Sales_Account__c,
					Partner_Sales_Account__r.Account_External_Id__c,
					Partner_Sales_Account__r.CDH_Party_Name__r.Name,
					Partner_Sub_Type__c,
					Partner_Type__c,
					RelationshipType__c,
					Oracle_Classification_Code__c,
					Escape_Partner_Check__c
				FROM Opportunities_Partner_Staging__r)
			from Opportunity_Header_Staging__c
			where id in:ids
		];
	}

	/**
	 * Method to process single Opportunity Staging records.
	 * @param singleStagingRecord Opportunity staging record to process
	 * @return List of exceptional error occured.
	 */
	public List<String> processOrders (Opportunity_Header_Staging__c singleStagingRecord) {
		return processOrders(new List<Opportunity_Header_Staging__c> {singleStagingRecord});
	}

	/**
	 * Method to process List of Opportunity Staging records.
	 * @param listOfStagingRecords List of Opportunity staging record to process
	 * @return List of exceptional error occured.
	 */
	public List<String> processOrders (List<Opportunity_Header_Staging__c> listOfStagingRecords){
		new ProcessOrdersInstance().processOrders(listofStagingRecords);
		return new List<String>();
	}

	public static Account createAccount(Opportunity_Header_Staging__c headerStaging,String partyType) {
		return createAccount2(headerStaging,partyType);
	}

	public static Account createAccount(Opportunity_Line_Staging__c lineStaging) {
		return createAccount2(lineStaging,'Entitle');
	}

	private static Account createAccount2(SObject staging,String partyType) {
		// create sales account record.
		String name = (String)staging.get(partyType+'_To_Party_Name__c');
		if(name == null || name == '') {
			name = String.valueOf(staging.get(partyType+'_To_Party_Number__c'));
		}
		String cdhPartyNumberAccount = String.valueOf(staging.get(partyType+'_To_CDH_Party_Number_Account__c'));
		Id recordTypeId = null;
		// this was a bug, we use recordTypeId before assigning it...
		//String accountExternalId = name+recordTypeId+cdhPartyNumberAccount;
		String country = (String)staging.get(partyType+'_To_Country__c');
		String superRegion = null;
		if(country != null) {
			superRegion = countryCodeAndGlobalRegionMap.get(country);
		}
		String recordTypeName = 'Default';
		if( superRegion != null) {
			recordTypeName = superRegion+' Account';
		}
		recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
		return new Account(
			Account_External_Id__c = name+recordTypeId+cdhPartyNumberAccount,
			CDH_Party_Name__r = new CDH_Party__c(CDH_Party_Number_Ext__c = cdhPartyNumberAccount ),
			Name = name,
			RecordTypeId = recordTypeId );
	}

	public static Address__c createAddress(Opportunity_Header_Staging__c headerStaging, String partyType,Account salesAccount) {
		return createAddress2(headerStaging,partyType,(String)headerStaging.get(partyType+'_To_Address_CDH_Party_Site_Number__c'),salesAccount);
	}

	public static Address__c createAddress(Opportunity_Line_Staging__c lineStaging,Account salesAccount) {
		return createAddress2(lineStaging,'Entitle',lineStaging.Entitle_To_CDH_Party_Site_Number__c,salesAccount);
	}
	
	private static Address__c createAddress2(SObject staging,String partyType,String cdhPartySiteNumber,Account salesAccount) {
		String state = (String)staging.get(partyType+'_To_Province__c');
		if(state == null) {
			state = (String)staging.get(partyType+'_To_State__c');
		}
		String addressExternalId = salesAccount.Id+cdhPartySiteNumber;
		if(salesAccount.Id == null) {
			addressExternalId = salesAccount.Account_External_Id__c+cdhPartySiteNumber;
		}
		return new Address__c(
			Address_External_Id__c = addressExternalId,
			Address_Line1__c = (String)staging.get(partyType+'_To_Address_Line_1__c'),
			Address_Line2__c = (String)staging.get(partyType+'_To_Address_Line_2__c'),
			Address_Line3__c = (String)staging.get(partyType+'_To_Address_Line_3__c'),
			Address_Line4__c= (String)staging.get(partyType+'_To_Address_Line_4__c'),
			City__c = (String)staging.get(partyType+'_To_City__c'),
			State__c = state,
			County__c = (String)staging.get(partyType+'_To_County__c'),
			Zip_Postal_Code__c = (String)staging.get(partyType+'_To_Zip_Postal_Code__c'),
			Country__c = (String)staging.get(partyType+'_To_Country__c'),
			CDH_Party_Site_Number__c = cdhPartySiteNumber,
			Status__c='ACTIVE',
			Sales_Account__c = salesAccount.Id,
			Sales_Account__r = salesAccount,
			Identifying_Address__c = false);
	}

	public static CDH_Party__c createCDHPersonParty(Opportunity_Header_Staging__c headerStaging,String partyType,String cdhPartyType) {
		return createCDHPersonParty2(headerStaging,partyType,cdhPartyType);
	}

	public static CDH_Party__c createCDHPersonParty(Opportunity_Line_Staging__c lineStaging,String cdhPartyType) {
		return createCDHPersonParty2(lineStaging,'Entitle',cdhPartyType);
	}

	public static CDH_Party__c createCDHPersonParty(Opportunity_Partner_Staging__c partnerStaging, String cdhPartyType) {
		if(cdhPartyType == null) {
			cdhPartyType = 'PERSON';
		}
		return new CDH_Party__c(
			Name = partnerStaging.Partner_Contact_CDH_Party_Number__c,
			CDH_Party_Type__c = cdhPartyType,
			CDH_Party_Name__c = partnerStaging.Partner_Contact_First_Name__c+partnerStaging.Partner_Contact_Last_Name__c,
			CDH_Party_Number_Ext__c = partnerStaging.Partner_Contact_CDH_Party_Number__c);
	}

	private static CDH_Party__c createCDHPersonParty2(SObject staging,String partyType,String cdhPartyType) {
		if(cdhPartyType == null) {
			cdhPartyType = String.valueof(staging.get(partyType+'_To_Party_Type__c'));
		}
		if(cdhPartyType == null || cdhPartyType == '') {
			cdhPartyType = 'PERSON';
		}
		String contactCDHPartyNumber = String.valueOf(staging.get(partyType+'_To_CDH_Party_Number__c'));
		return new CDH_Party__c(
			Name = contactCDHPartyNumber,
			CDH_Party_Type__c = cdhPartyType,
			CDH_Party_Name__c = String.valueof(staging.get(partyType+'_To_Contact_First_Name__c')),
			CDH_Party_Number_Ext__c = contactCDHPartyNumber);
	}

	public static CDH_Party__c createCDHAccountParty(Opportunity_Header_Staging__c headerStaging,String partyType) {
		return createCDHAccountParty2(headerStaging,partyType);
	}

	public static CDH_Party__c createCDHAccountParty(Opportunity_Line_Staging__c lineStaging) {
		return createCDHAccountParty2(lineStaging,'Entitle');
	}

	private static CDH_Party__c createCDHAccountParty2(SObject staging,String partyType) {
		String accountCDHPartyNumber = String.valueof(staging.get(partyType+'_To_CDH_Party_Number_Account__c'));
		return new CDH_Party__c(
			Name = accountCDHPartyNumber,
			CDH_Party_Type__c = String.valueof(staging.get(partyType+'_To_Party_Type__c')),
			CDH_Party_Name__c = String.valueof(staging.get(partyType+'_To_Party_Name__c')),
			CDH_Party_Number_Ext__c = accountCDHPartyNumber );
	}

	public static Contact createContact( Opportunity_Header_Staging__c headerStaging, String partyType, Account salesAccount ) {
		return createContact2(headerStaging,partyType,salesAccount);
	}

	public static Contact createContact( Opportunity_Line_Staging__c lineStaging, Account salesAccount ) {
		return createContact2(lineStaging,'Entitle',salesAccount);
	}

	private static Contact createContact2( SObject staging, String partyType, Account salesAccount ) {
		String firstName = (String)staging.get(partyType+'_To_Contact_First_Name__c');
		if(firstName != null && firstName.length() > 40) {
			firstName = firstName.substring(0,40);
		}
		String lastName = (String)staging.get(partyType+'_To_Contact_Last_Name__c');
		if(lastName == null || lastName == '') {
			lastName = (String)staging.get(partyType+'_To_Contact_Email__c');
		}
		if(lastName != null && lastName.length() > 40) {
			lastName = lastName.substring(0,40);
		}
		String contactCDHPartyNumber = String.valueOf(staging.get(partyType+'_To_CDH_Party_Number__c'));
		String contactExternalId = contactCDHPartyNumber+salesAccount.Id;
		if(salesAccount.Id == null) {
			contactExternalId = contactCDHPartyNumber+salesAccount.Account_External_Id__c;
		}
		return new Contact(
			AccountId = salesAccount.Id,
			Account = salesAccount,
			CDH_Party__r = new CDH_Party__c(CDH_Party_Number_Ext__c =  contactCDHPartyNumber),
			Contact_External_Id__c = contactExternalId,
			Email = (String)staging.get(partyType+'_To_Contact_Email__c'),
			FirstName = firstName,
			LastName = lastName,
			Phone = (String)staging.get(partyType+'_To_Contact_Phone__c') );
	}

	public static Contact createContact(Opportunity_Partner_Staging__c partnerStaging,Account partnerAccount) {
		String firstName = partnerStaging.Partner_Contact_First_Name__c;
		if(firstName != null && firstName.length() > 40) {
			firstName = firstName.substring(0,40);
		}
		String lastName = partnerStaging.Partner_Contact_Last_Name__c;
		if(lastName == null || lastName == '') {
			lastName = partnerStaging.Partner_Contact_Email__c;
		}
		if(lastName != null && lastName.length() > 40) {
			lastName = lastName.substring(0,40);
		}
		String contactExternalId = partnerStaging.Partner_Contact_CDH_Party_Number__c+partnerAccount.Id;
		if(partnerAccount.Id == null) {
			contactExternalId = partnerStaging.Partner_Contact_CDH_Party_Number__c+partnerAccount.Account_External_Id__c;
		}
		return new Contact(
			Account = partnerAccount,
			AccountId = partnerAccount.Id,
			CDH_Party__r = new CDH_Party__c(CDH_Party_Number_Ext__c = partnerStaging.Partner_Contact_CDH_Party_Number__c),
			Contact_External_Id__c = contactExternalId,
			FirstName = firstName,
			LastName = lastName,
			Phone = partnerstaging.Partner_Contact_Phone__c,
			Email = partnerstaging.Partner_Contact_Email__c);
	}

	public static EBS_Account__c createEBSAccount(Opportunity_Header_Staging__c headerStaging, String partyType, Account salesAccount) {
		return createEBSAccount2(headerStaging,partyType,salesAccount);
	}

	public static EBS_Account__c createEBSAccount(Opportunity_Line_Staging__c lineStaging, Account salesAccount) {
		return createEBSAccount2(lineStaging,'Entitle',salesAccount);
	}

	private static EBS_Account__c createEBSAccount2(SObject staging, String partyType, Account salesAccount) {
		String name = (String)staging.get(partyType+'_To_Party_Name__c');
		String ebsAccountExternalId = name+salesAccount.Id;
		if(salesAccount.Id == null) {
			ebsAccountExternalId = name+salesAccount.Account_External_Id__c;
		}
		return new EBS_Account__c(
			EBS_Account_External_Id__c = ebsAccountExternalId,
			EBS_Party_Name__c  = name,
			EBS_Party_Number__c = String.valueOf(staging.get(partyType+'_To_Party_Number__c')),
			Name = String.valueOf(staging.get(partyType+'_To_Account_Number__c')),
			Sales_Account__c = salesAccount.Id,
			Sales_Account__r = salesAccount );
	}

	public static List<Contact> getUpsertContacts(Map<String,Contact> contactMap,Map<String,Account> accountMap) {
		Map<String,Contact> contactMap2 = new Map<String,Contact>();
		for(Contact c : new Set<Contact>(contactMap.values())) {
			if(c.Account != null) {
				Account a = c.Account;
				if(a.Id == null) {
					a = accountMap.get(c.Account.Account_External_Id__c);
				}
				if(a != null && a.Id != null) {
					c.Account = a;
					c.AccountId = a.Id;
					if(c.CDH_Party__r != null) {
						String extId = a.Id+c.CDH_Party__r.CDH_Party_Number_Ext__c;
						if(extId != c.Contact_External_Id__c) {
							contactMap2.put(extId,c);
							contactMap.put(extId,c);
						}
						c.Contact_External_Id__c = extId;
					}
				}
			}
		}
		for(Contact c : contactMap.values()) {
			if(contactMap2.containsKey(c.Contact_External_Id__c)) {
				contactMap2.put(c.Contact_External_Id__c,c);
			}
		}
		return contactMap2.values();
	}

	public static List<Address__c> getUpsertAddresses(Map<String,Address__c> addressMap,Map<String,Account> accountMap) {
		Map<String,Address__c> addressMap2 = new Map<String,Address__c>();
		for(Address__c addr : new Set<Address__c>(addressMap.values())) {
			if(addr.Sales_Account__c == null && addr.Sales_Account__r != null) {
				Account a= addr.Sales_Account__r;
				if(a.Id == null) {
					a = accountMap.get(addr.Sales_Account__r.Account_External_Id__c);
				}
				if(a != null && a.Id != null) {
					addr.Sales_Account__r = a;
					addr.Sales_Account__c = a.Id;
					String extId = a.Id+addr.CDH_Party_Site_Number__c;
					if(extId != addr.Address_External_Id__c) {
						addressMap2.put(extId,addr);
						addressMap.put(extId,addr);
					}
					addr.Address_External_Id__c = extId;
				}
			}
		}
		for(Address__c addr : addressMap.values()) {
			if(! addressMap2.containsKey(addr.Address_External_Id__c)) {
				addressMap2.put(addr.Address_External_Id__c,addr);
			}
		}
		return addressMap2.values();
	}

	public static List<EBS_Account__c> getUpsertEBSAccounts(Map<String,EBS_Account__c> ebsAccountMap,Map<String,Account> accountMap) {
		Map<String,EBS_Account__c> ebsAccountMap2 = new Map<String,EBS_Account__c>();
		for(EBS_Account__c e : new Set<EBS_Account__c>(eBSAccountMap.values())) {
			Account a = e.Sales_Account__r;
			if(a != null) {
				if(a.Id == null) {
					a = accountMap.get(a.Account_External_Id__c);
				}
				if(a != null && a.Id != null) {
					e.Sales_Account__r = a;
					e.Sales_Account__c = a.Id;
					String extId = e.Name+account.Id;
					if(extId != e.EBS_Account_External_Id__c) {
						ebsAccountMap2.put(extId,e);
						ebsAccountMap.put(extId,e);
					}
					e.EBS_Account_External_Id__c =  extId;
				}
			}
		}
		for(EBS_Account__c e : eBSAccountMap.values()) {
			if(! ebsAccountMap2.containsKey(e.EBS_Account_External_Id__c)) {
				ebsAccountMap2.put(e.EBS_Account_External_Id__c,e);
			}
		}
		return ebsAccountMap2.values();
	}

	private class Order_Opportunity_Matching_Exception extends Exception {}

	private class ProcessOrdersInstance {
		// List to hold the Direct Opportunities records to be updated.
		List<Opportunity> listOfDirectOpportunityToBeUpdated = new List<Opportunity>();
		// Map of staging records that need to be account matched.
		Map<Id,Opportunity_Header_Staging__c> stagingRecordsToMatch = new Map<Id,Opportunity_Header_Staging__c>();
		// List to hold the opportunity staging records to be updated.
		List<Opportunity_Header_Staging__c> listOfStagingRecordToBeUpdated = new List<Opportunity_Header_Staging__c>();
//depreciated		//list to hold the Opportunity Line staging records to be updated.
//depreciated		List<Opportunity_Line_Staging__c> opportunityLineStagingRecordList = new List<Opportunity_Line_Staging__c>();
//depreciated		//list to hold the Opportunity partner staging records to be updated.
//depreciated		List<Opportunity_Partner_Staging__c> opportunityPartnerStagingRecordList = new List<Opportunity_Partner_Staging__c>();
		// Map to hold the opportunity details .
		Map<Id,Opportunity> opportunityDetailsMap = new Map<Id,Opportunity>();
		// map to hold the opportunity Product information.
		Map<Id,OpportunityLineItem> opportunityProductMap = new Map<Id,OpportunityLineItem>();
		//set of excluded opportunity record type from validation.
		//this set will be prepared based on the tolerance level table.
		Set<Id> excludedRecordTypeIds = new Set<Id>();
		//set of excluded opportunity Stage from validation.
		//this set will be prepared based on the tolerance level table.
		Set<String> ExcludedOpportunityStageSet = new Set<String>();
		// variable to hold the amount tolerance value 
		Decimal amountTolerance;
//depreciated		// map to hold the List of EBS Account record for EBS Account Number.
//depreciated		Map<String,List<EBS_Account__c>> eBSAccountNumberAndListOfEBSAccountMap = new Map<String,List<EBS_Account__c>>();
//depreciated		// map to hold the list of address record for CDH Party site Number.
//depreciated		Map<String, List<Address__c>> cDHPartySiteNumberAndListOfAddressMap = new Map<String, List<Address__c>>();
		// map to hold the List of contact for CDH Person Party Number.
		Map<String, List<Contact>> cDHPartyNumberAndListOfContactMap = new Map<String, List<Contact>>();
		// map to hold the List of Account for  CDH Party Number.
		Map<String,List<Account>> nonEcoAccountByCDHPartyName = new Map<String,List<Account>>();
		//Set of Account record to be inserted.
		Map<String,Account> accountToUpsertMap = new Map<String,Account>();
		// Set of contact record to be insrted.
		Map<String,Contact> contactToUpsertMap = new Map<String,Contact>();
		// map of contact Map of CDH number and externalid
		Map<string,string> contactToInsertMap = new Map<string,string>();
		// Set of EBS Account record to be insrted.
		Map<String,EBS_Account__c> eBSAccountToUpsertMap = new Map<String,EBS_Account__c>();
		// Set of CDH Party records to be insrted.
		Set<CDH_Party__c> cDHPartyToInsertSet = new Set<CDH_Party__c>();
		// Set of Address records to be inserted.
		Map<String,Address__c> addressToUpsertMap = new Map<String,Address__c>();


		// List to store Order Tracking Records to be created during status change
		List<Order_Tracking__c> opportunityOrderTrackingRecList= new List<Order_Tracking__c>();

		// set to hold the opportunity staging record Id.
		Set<Id> stagingRecordIdSet = new Set<Id>();
//depreciated		// set to hold the EBS accout record Ids from Lookup.
//depreciated		Set<Id> ebsAccountIdSet = new Set<Id>();
//depreciated		// set to hold the address record Ids from Lookup.
//depreciated		Set<Id> addressIdSet = new Set<Id>();
		// list to hold the error record to be inserted.
		List<Match_and_Validation_Error__c> errorList = new List<Match_and_Validation_Error__c>();
		// List of Opportunity Partner records that need to be deleted
		List<OpportunityPartner__c> OppPartnerLstToDelete= new List<OpportunityPartner__c>();
		// List of Opportunity Partner records that needs tobe ccreated
		List<OpportunityPartner__c> OppPartnerLstToCreate= new List<OpportunityPartner__c>();
		// List of Opportunity Line Item records that need to be deleted
		List<OpportunitylineItem> OppLineItemLstToDelete= new List<OpportunitylineItem>();
		// List of Opportunity Line Item records that needs tobe ccreated
		List<OpportunitylineItem> OppLineItemLstToUpsert= new List<OpportunitylineItem>();
		// map of Product and product code,will be used to identify the list of Product based on code
		//Map<string,id> productCodeIdmap= new Map<string,id>();
		Map<String,Map<String,PricebookEntry>> productCodeIdByCurrencyMap= new Map<String,Map<String,PricebookEntry>>();//Changes made for US67181 to hold PricebookEntry object instance in value of map and not just ID
		// map of classification object reference key and unique id
		// Commented because of PRL redesign :US59513 map<string,id> classifiyRecMap = new map<string,id>();
		// map of Partner Oracle Classification Code reference key and Object
		Map<string,id> partnerOrcClsCodeTierMap = new Map<string,id>();
		Map<string,id> partnerOrcClsCodeTypeMap = new Map<string,id>();
		//US60577 :set of Id to define if related records are to be set to 'Ready for Re-processing' from 'Pending Booked Order Process'
		Set<id> oHSRestStatusSet= new Set<id>();

		// map of Opportunity Number and Opportunity details.
		Map<String,Opportunity> mapofOpportunityNumberAndOpportunityDetails = new Map<String,Opportunity>();
		//map of entitle to Account and set of of abs account number.
		Map<Id,Set<string>> mapofEntitleAccountandSetOfEBSNumber = new map<Id,Set<string>>();
		// list of orderheaders with system exceptions
		Map<Id,Opportunity_Header_Staging__c> oppHeaderWithSystemErrorMap = new Map<Id,Opportunity_Header_Staging__c>();

		list<System_exception_Handler__c> listSystemErrorHandler = new list<System_exception_Handler__c>();

		set<String> productCodeRelatedSet= new set<String>();
		set<String> classificationRelatedSet= new set<String>();
		List<Opportunity_Partner_Staging__c> partnersToUpdate = new List<Opportunity_Partner_Staging__c>();

		/**
		 * Method to process List of Opportunity Staging records.
		 * @param listOfStagingRecords List of Opportunity staging record to process
		 * @return List of exceptional error occured.
		 */
		private void processOrders(List<Opportunity_Header_Staging__c> listOfStagingRecords){
			operatingUnitMap = null;
			Boolean overrideEmbeddedAllowed = OpportunityTriggerBefore2.embedded.OverrideAllowed__c;
			try {
				// don't allow messages from the bus to override the embedded flag
				OpportunityTriggerBefore2.embedded.OverrideAllowed__c = false;
				Savepoint savepoint = Database.setSavepoint();
				try {
					Map<Id,Opportunity_Header_Staging__c> directOpportunityStagingRecordMap = new Map<Id,Opportunity_Header_Staging__c>();
					Map<Id,Opportunity_Header_Staging__c> indirectOppBookedStagingRecordMap = new Map<Id,Opportunity_Header_Staging__c>();
					Map<Id,Opportunity_Header_Staging__c> indirectOppNonBookedStagingRecordMap = new Map<Id,Opportunity_Header_Staging__c>();
					set<String> partnerOrcClasificationcodeSet= new set<String>();

					Set<String> excludedRecordTypeNames = new Set<String>();
					// Query on tolerance level table to get the matching configuration.
					for(Opportunity_Match_Configuration__c opportunityMatchConfig :[
						Select Id,
							Name ,
							Operator__c,
							Value__c 
						from Opportunity_Match_Configuration__c
						where Operator__c!=Null and
						Value__c!= Null ] )
					{
						if(opportunityMatchConfig.Name == 'RecordType__c' && opportunityMatchConfig.Operator__c == 'NOT EQUAL TO'){
							excludedRecordTypeNames.add(opportunityMatchConfig.Value__c);
						}
						else if(opportunityMatchConfig.Name == 'StageName' && opportunityMatchConfig.Operator__c == 'NOT EQUAL TO'){
							ExcludedOpportunityStageSet.add(opportunityMatchConfig.Value__c);
						}
						else if(opportunityMatchConfig.Name == 'Amount' && opportunityMatchConfig.Operator__c == 'RANGE'){
							amountTolerance = decimal.valueof(opportunityMatchConfig.Value__c);
						}
					}
					excludedRecordTypeIds.addAll(getOpportunityRecordTypeIds(excludedRecordTypeNames));
//depreciated					Set<String> eBSAccountNumberSet = new Set<String>();
					Set<String> cDHPartyNumberSet = new Set<String>();
//depreciated					Set<String> cDHPartySiteNumberSet = new Set<String>();
					Set<String> cdhAccountNumberSet = new Set<String>();
					Set<String> nonEcoAccountSet = new Set<String>();
					//Iterating on List of Opportunity staging records.
					//Prepare the set of EBS Account number for Bill to , Ship To , Sold To, Entitle To from order Data.
					//Prepare the set of CDH Party Number for Bill to , Ship To , Sold To, Entitle To from order Data.
					//Prepare the set of CDH Party Site number for Bill to , Ship To , Sold To, Entitle To from order Data.
					//Prepare the set of EBS Account number for Entitle To from order Line Data.
					//Prepare the set of CDH Party Number for Entitle To from order Line Data.
					//Prepare the set of CDH Party Site Number for Entitle To from order Line Data.
					//Prepare the set of CDH Account Number from order Partner Data.
					//Prepare the set of CDH Person Party Number for Entitle To from order Line Data.

					for(Opportunity_Header_Staging__c opportunityStaging : listOfStagingRecords){
						stagingRecordIdSet.add(opportunityStaging.Id);
//depreciated						eBSAccountNumberSet.add(opportunityStaging.Bill_To_Account_Number__c);
//depreciated						eBSAccountNumberSet.add(opportunityStaging.Ship_To_Account_Number__c);
//depreciated						eBSAccountNumberSet.add(opportunityStaging.Sold_To_Account_Number__c);
//depreciated						eBSAccountNumberSet.add(opportunityStaging.Entitle_To_Account_Number__c);
//depreciated						cDHPartyNumberSet.add(opportunityStaging.Bill_To_CDH_Party_Number__c);
//depreciated						cDHPartyNumberSet.add(opportunityStaging.Ship_To_CDH_Party_Number__c);
//depreciated						cDHPartyNumberSet.add(opportunityStaging.Sold_To_CDH_Party_Number__c);
//depreciated						cDHPartyNumberSet.add(opportunityStaging.Entitle_To_CDH_Party_Number__c);
//depreciated						cDHPartySiteNumberSet.add(opportunityStaging.Bill_To_Address_CDH_Party_Site_Number__c);
//depreciated						cDHPartySiteNumberSet.add(opportunityStaging.Ship_To_Address_CDH_Party_Site_Number__c);
//depreciated						cDHPartySiteNumberSet.add(opportunityStaging.Sold_To_Address_CDH_Party_Site_Number__c);
//depreciated						cDHPartySiteNumberSet.add(opportunityStaging.Entitle_To_Address_CDH_Party_Site_Number__c);
//depreciated						if(opportunityStaging.Bill_To_Account__c !=null){
//depreciated							ebsAccountIdSet.add(opportunityStaging.Bill_To_Account__c);
//depreciated						}
//depreciated						if(opportunityStaging.Ship_To_Account__c !=null){
//depreciated							ebsAccountIdSet.add(opportunityStaging.Ship_To_Account__c);
//depreciated						}
//depreciated						if(opportunityStaging.Sold_To_Account__c!= null){
//depreciated							ebsAccountIdSet.add(opportunityStaging.Sold_To_Account__c);
//depreciated						}
//depreciated						if(opportunityStaging.Entitle_To_Account__c !=null){
//depreciated							ebsAccountIdSet.add(opportunityStaging.Entitle_To_Account__c);
//depreciated						}
//depreciated						// Create Set of Address Records
//depreciated						if(opportunityStaging.Bill_To_Address__c !=null){
//depreciated							addressIdSet.add(opportunityStaging.Bill_To_Address__c);
//depreciated						}
//depreciated						if(opportunityStaging.Ship_To_Address__c !=null){
//depreciated							addressIdSet.add(opportunityStaging.Ship_To_Address__c);
//depreciated						}
//depreciated						if(opportunityStaging.Sold_To_Address__c!= null){
//depreciated							addressIdSet.add(opportunityStaging.Sold_To_Address__c);
//depreciated						}
//depreciated						if(opportunityStaging.Entitle_To_Address__c !=null){
//depreciated							addressIdSet.add(opportunityStaging.Entitle_To_Address__c);
//depreciated						}

						if(opportunityStaging.Non_Entitled_Endco_CDH_Party_Number__c !=null){
							nonEcoAccountSet.add(opportunityStaging.Non_Entitled_Endco_CDH_Party_Number__c);
						}
						for(Opportunity_Line_Staging__c oppLineStaging :opportunityStaging.Opportunities_Line_Staging__r){
//depreciated							if(oppLineStaging.Entitle_To_Account__c !=null){
//depreciated								ebsAccountIdSet.add(oppLineStaging.Entitle_To_Account__c);
//depreciated							}
//depreciated							if(oppLineStaging.Entitle_To_Address__c !=null){
//depreciated								addressIdSet.add(oppLineStaging.Entitle_To_Address__c);
//depreciated							}
							if(oppLineStaging.Product_Code_Oracle__c !=null && oppLineStaging.Product_Code_Oracle__c !=''){
								productCodeRelatedSet.add(oppLineStaging.Product_Code_Oracle__c);
								productCodeIdByCurrencyMap.put(oppLineStaging.CurrencyIsoCode,new Map<String,PricebookEntry>());
							}
//depreciated							eBSAccountNumberSet.add(oppLineStaging.Entitle_To_Account_Number__c);
//depreciated							cDHPartyNumberSet.add(oppLineStaging.Entitle_To_CDH_Party_Number__c);
//depreciated							cDHPartySiteNumberSet.add(oppLineStaging.Entitle_To_CDH_Party_Site_Number__c);

						}
						for(Opportunity_Partner_Staging__c partnerStaging :opportunityStaging.Opportunities_Partner_Staging__r){
							if(partnerStaging.CDH_Party_Number__c != null) {
								cdhAccountNumberSet.add(partnerStaging.CDH_Party_Number__c);
							}
							if(partnerStaging.Partner_Contact_CDH_Party_Number__c != null) {
								cDHPartyNumberSet.add(partnerStaging.Partner_Contact_CDH_Party_Number__c);
							}
							if(partnerStaging.Oracle_Classification_Code__c !=null){
								partnerOrcClasificationcodeSet.add(partnerStaging.Oracle_Classification_Code__c);
							}
							if(partnerStaging.Partner_Type__c !=null && partnerStaging.Partner_Type__c !=''){
								classificationRelatedSet.add(partnerStaging.Partner_Type__c);
							}
							if(partnerStaging.PartnerTier__c !=null && partnerStaging.PartnerTier__c !=''){
								classificationRelatedSet.add(partnerStaging.PartnerTier__c);
							}
						}

					}
					if(! stagingRecordIdSet.isEmpty()) {
						System.debug('stagingRecordIdSet='+stagingRecordIdSet);
						database.delete([select Id from Potential_Matched_Opportunities__c where Opportunity_Header_Staging__c in :stagingRecordIdSet],false);
					}

					//Query Account records based on CDH Account number.
					//Prepare map of CDH Account Number and List of account record.
					if(! (nonEcoAccountSet.isEmpty()||nonEntitleToAccountRecordTypeNames.isEmpty())) {
						System.debug('nonEcoAccountSet='+nonEcoAccountSet);
						System.debug('nonEntitleToAccountRecordTypeNames='+nonEntitleToAccountRecordTypeNames);
						for(Account account : [
							Select Id,
								Account_External_Id__c,
								CDH_Party_Name__c,
								CDH_Party_Name__r.Name,
								CDH_Party_Number__c,
								RecordTypeId,
								RecordType.DeveloperName,
								Name 
							from Account
							where CDH_Party_Name__c in (select Id from CDH_Party__c where Name in :nonEcoAccountSet) 
								AND RecordTypeId in :getAccountRecordTypeIds(nonEntitleToAccountRecordTypeNames) ] )
						{
							List<Account> accountList = nonEcoAccountByCDHPartyName.get(account.CDH_Party_Name__r.Name);
							if(accountList == null){
								accountList = new List<Account>();
								nonEcoAccountByCDHPartyName.put(account.CDH_Party_Name__r.Name,accountList);
							}
							accountList.add(account);
						}
					}
//depreciated					//Query Address records based on CDH Party Site number.
//depreciated					//Prepare map of CDH Party Site number and List of address record.
//depreciated					for(Address__c address : [select CDH_Party_Site_Number__c,Sales_Account__c ,Sales_Account__r.Name,Sales_Account__r.RecordTypeId,Sales_Account__r.CDH_Party_Number__c,Sales_Account__r.CDH_Party_Name__r.Name from Address__c where (CDH_Party_Site_Number__c in:cDHPartySiteNumberSet and CDH_Party_Site_Number__c!= Null) OR ID IN:addressIdSet]){
//depreciated						List<Address__c> addressList = new List<Address__c>();
//depreciated						if(cDHPartySiteNumberAndListOfAddressMap.get(address.CDH_Party_Site_Number__c) != Null){
//depreciated							addressList.addall(cDHPartySiteNumberAndListOfAddressMap.get(address.CDH_Party_Site_Number__c));
//depreciated						}
//depreciated						addressList.add(address);
//depreciated						if(addressIdSet.Contains(address.id)){
//depreciated							cDHPartySiteNumberAndListOfAddressMap.put(address.id,new List<Address__c>{address});
//depreciated						}
//depreciated						if(cDHPartySiteNumberSet.contains(address.CDH_Party_Site_Number__c)){
//depreciated							cDHPartySiteNumberAndListOfAddressMap.put(address.CDH_Party_Site_Number__c,addressList);
//depreciated						}
//depreciated
//depreciated					}

					// Wrap PriceBookentry and related product code to be pupulated when data is recived from EBS and Product field need to be updated.
					//Changes made for US67181 to query Product2.IsActive also and populate map with PricebookEntry oject instance
					//for(PricebookEntry prodRelated:[Select id,Product2Id,CurrencyIsoCode, Product2.ProductCode from PricebookEntry where PriceBook2.Name='Global Price Book' AND Product2.ProductCode IN: productCodeRelatedSet and IsActive=True]){
					//   productCodeIdmap.put(prodRelated.Product2.ProductCode+prodRelated.CurrencyIsoCode,prodRelated.id);
					//}
					if(! (productCodeRelatedSet.isEmpty()||productCodeIdByCurrencyMap.isEmpty())) {
						System.debug('productCodeRelatedSet='+productCodeRelatedSet);
						System.debug('productCodeIdByCurrencyMap.keySet()='+productCodeIdByCurrencyMap.keySet());
						for(PricebookEntry prodRelated:[
							select Id,
								Product2Id,
								CurrencyIsoCode,
								Product2.ProductCode,
								Product2.IsActive,
								IsActive
							from PricebookEntry
							where PriceBook2Id = :globalPriceBookId
								AND CurrencyIsoCode in :productCodeIdByCurrencyMap.keySet()
								AND Product2Id in (select Id from Product2 where ProductCode IN: productCodeRelatedSet)
							order by Product2.IsActive, IsActive ] )
						{
							productCodeIdByCurrencyMap.get(prodRelated.CurrencyIsoCode).put(prodRelated.Product2.ProductCode,prodRelated);
						}
					}

					//Query Contact records based on CDH Person Party number.
					//Prepare map of CDH Person Party number and List of contact record.
					if(! cDHPartyNumberSet.isEmpty()) {
						System.debug('cDHPartyNumberSet='+cDHPartyNumberSet);
						for(Contact contact : [
							select Id,
								CDH_Party_Number__c, 
								AccountId,
								Account.Account_External_Id__c,
								Account.CDH_Party_Name__r.Name
							from Contact
							where CDH_Party__c in (
								select Id
								from CDH_Party__c
								where CDH_Party_Number_Ext__c in :cDHPartyNumberSet ) ] )
						{
							List<Contact> contactList = new List<Contact>();
							if(cDHPartyNumberAndListOfContactMap.get(contact.CDH_Party_Number__c) != Null){
								contactList.addall(cDHPartyNumberAndListOfContactMap.get(contact.CDH_Party_Number__c));
							}
							contactList.add(contact);
							cDHPartyNumberAndListOfContactMap.put(contact.CDH_Party_Number__c,contactList);
						}
					}
					//Query Contact records based on EBS Account number.
					//Prepare map of EBS Account number and List of EBSAccount records.

//depreciated					for(EBS_Account__c ebsAccount : [select Name,Sales_Account__c,Sales_Account__r.Name,Sales_Account__r.CDH_Party_Name__r.Name,Sales_Account__r.RecordTypeId from EBS_Account__c where Name in:eBSAccountNumberSet OR ID IN:ebsAccountIdSet]){
//depreciated						List<EBS_Account__c> ebsAccountList = new List<EBS_Account__c>();
//depreciated						if(eBSAccountNumberAndListOfEBSAccountMap.get(ebsAccount.Name) != Null){
//depreciated							ebsAccountList.addall(eBSAccountNumberAndListOfEBSAccountMap.get(ebsAccount.Name));
//depreciated						}
//depreciated						ebsAccountList.add(ebsAccount);
//depreciated						if(ebsAccountIdSet.contains(ebsAccount.id)){
//depreciated							eBSAccountNumberAndListOfEBSAccountMap.put(ebsAccount.id,new list<EBS_Account__c>{ebsAccount});
//depreciated						}
//depreciated						if(eBSAccountNumberSet.contains(ebsAccount.Name)){
//depreciated							eBSAccountNumberAndListOfEBSAccountMap.put(ebsAccount.Name,ebsAccountList);
//depreciated						}
//depreciated					}

					// Query on Partner program tier based on Values from partner object 
					//Prepare a map of Oracle classofication code and related Partner tier record for further processing 
					if(! partnerOrcClasificationcodeSet.isEmpty()) {
						System.debug('partnerOrcClasificationcodeSet='+partnerOrcClasificationcodeSet);
						for(Partner_Program_Tier__c pPTier:[
							SELECT Id,
								Oracle_Classification_Code__c,
								Legacy_Partner_Tier__c,
								Partner_Program_Definition__r.Legacy_Partner_Type__c,
								Is_Active__c
							FROM Partner_Program_Tier__c
							WHERE Oracle_Classification_Code__c IN:partnerOrcClasificationcodeSet
								AND Is_Active__c = True ] )
						{
							partnerOrcClsCodeTierMap.put(pPTier.Oracle_Classification_Code__c,pPTier.Legacy_Partner_Tier__c);	 
							partnerOrcClsCodeTypeMap.put(pPTier.Oracle_Classification_Code__c,pPTier.Partner_Program_Definition__r.Legacy_Partner_Type__c);								 
						}
					}


					//checking which staging records are related to direct opportunities.

					for(Opportunity_Header_Staging__c directOpportunitystaging : listOfStagingRecords){
						try{
							//get List of all the records with status ready for reprocess and Order status as Booked to reset the status of child records:US60577
							if( directOpportunitystaging.Order_Status__c =='BOOKED' && directOpportunitystaging.Status__c==READY_FOR_REPROCESSING){
								oHSRestStatusSet.add(directOpportunitystaging.id);
							}
							if((directOpportunitystaging.Opportunity_ID__c != Null && directOpportunitystaging.Opportunity_ID__c!='') ||
								(directOpportunitystaging.Opportunity_Number__c != Null && directOpportunitystaging.Opportunity_Number__c!=''))
							{
								directOpportunityStagingRecordMap.put(directOpportunitystaging.Id,directOpportunitystaging);
							}
							else if(directOpportunitystaging.Order_Status__c =='BOOKED') {
								indirectOppBookedStagingRecordMap.put(directOpportunitystaging.Id,directOpportunitystaging);
							}
							else if(directOpportunitystaging.Order_Status__c =='INVOICED' ||
								directOpportunitystaging.Order_Status__c =='CLOSED' ||
								directOpportunitystaging.Order_Status__c =='CANCELLED')
							{
								indirectOppNonBookedStagingRecordMap.put(directOpportunitystaging.Id,directOpportunitystaging);
							}
						}catch(Exception ex) {
							errorRecordCreationWithDetails(ex,directOpportunitystaging);
						}
					}

					//Invoke the method to process the opportunity staging record (for direct opportunity)
					if(!directOpportunityStagingRecordMap.isempty()){
						processDirectOpportunitiesPrematch(directOpportunityStagingRecordMap.values());
					}

					//Invoke the method to process the Indirect opportunity staging records with Booked Status
					if(!indirectOppBookedStagingRecordMap.isempty()){
						processIndirectBookedOpportunitiesPrematch(indirectOppBookedStagingRecordMap.values());
					}

					// all the party account matching is now done in Account_Matching_Orders
					if(! stagingRecordsToMatch.isEmpty()) {
						List<Opportunity_Line_Staging__c> lineStagingRecords = new List<Opportunity_Line_Staging__c>();
						for(Opportunity_Header_Staging__c header : stagingRecordsToMatch.values()) {
							if(header.Opportunities_Line_Staging__r != null) {
								lineStagingRecords.addAll(header.Opportunities_Line_Staging__r);
							}
						}

						Account_Matching_Orders accountMatching = new Account_Matching_Orders(stagingRecordsToMatch.values(),lineStagingRecords);
						accountMatching.assignRefOppId(); // opportunity mappings
						accountMatching.match(); // does the basic matching
						accountMatching.filter(); // filters out duplicates and partners
						// report errors 
						accountMatching.errorsAndWarningsReporting();
						accountMatching.assignFrom(); // assign values to the staging records

						for(Match_and_Validation_Error__c e : accountMatching.getErrorAndWarnList() ) {
							if(e.Opportunity_Staging_Header__r != null) {
								oppHeaderWithSystemErrorMap.put(e.Opportunity_Staging_Header__c,e.Opportunity_Staging_Header__r);
							}
							errorList.add(e);
						}
					}

					//Invoke the method to process the Indirect opportunity staging records with Booked Status
					if(!indirectOppNonBookedStagingRecordMap.isempty()){
						processIndirectNonBookedOpportunities(indirectOppNonBookedStagingRecordMap.values());
					}

					//Invoke the method to process the opportunity staging record (for direct opportunity)
					if(!directOpportunityStagingRecordMap.isempty()){
						processDirectOpportunitiesPostmatch(directOpportunityStagingRecordMap.values());
					}

					//Invoke the method to process the Indirect opportunity staging records with Booked Status
					if(!indirectOppBookedStagingRecordMap.isempty()){
						processIndirectBookedOpportunitiesPostmatch(indirectOppBookedStagingRecordMap.values());
					}
					savepoint = null;
				}
				finally {
					if(savepoint != null) {
						Database.rollback(savepoint);
					}
				}
			}
			catch(Exception ex2) {
				for(Opportunity_Header_Staging__c directOpportunitystaging : listOfStagingRecords) {
					if(! oppHeaderWithSystemErrorMap.containsKey(directOpportunitystaging.Id)) {
						oppHeaderWithSystemErrorMap.put(directOpportunitystaging.Id,directOpportunitystaging);
						errorRecordCreationWithDetails(ex2,directOpportunitystaging);
					}
					directOpportunitystaging.Status__c = 'Error';
				}
			}

			try {
				system.debug('=================Reached here==============================>');
				// we ignore errors because it is best to process what we can and continue
				if(! stagingRecordIdSet.isEmpty()) {
					System.debug('stagingRecordIdSet='+stagingRecordIdSet);
					database.delete([
						select Id 
						from Match_and_Validation_Error__c
						where Opportunity_Staging_Header__c in :stagingRecordIdSet], false);
				}
			}
			finally {
				OpportunityTriggerBefore2.embedded.OverrideAllowed__c = overrideEmbeddedAllowed;
				try {
					//update the system exceptions 
					if(!oppHeaderWithSystemErrorMap.isempty()) {
						try {
							database.update(oppHeaderWithSystemErrorMap.values(),true);
						}
						catch(Exception ex) {
							List<Opportunity_Header_Staging__c> updateList = new List<Opportunity_Header_Staging__c>();
							for(Id headerId : oppHeaderWithSystemErrorMap.keySet()) {
								updateList.add(new Opportunity_Header_Staging__c(Id=headerId,Status__c='Error'));
							}
							// we ignore errors because it is best to process what we can and continue
							database.update(updateList,false);
						}
					}
				}
				finally {
					try {
						if(! listSystemErrorHandler.isEmpty()) {
							// we ignore errors because it is best to process what we can and continue
							database.insert(listSystemErrorHandler,false);
						}
					}
					finally {
						system.debug('=================Reached here==============================>'+errorList);
						if(!errorList.isempty()) {
							// we ignore errors because it is best to process what we can and continue
							database.insert(errorList,false);
						}
					}
				}
			}
		}

		private Map<String,OperatingUnit__c> operatingUnitMap {
			get {
				if(operatingUnitMap == null) {
					operatingUnitMap = getOperatingUnitMap(stagingRecordsToMatch.values());
				}
				return operatingUnitMap;
			}
			set {
				operatingUnitMap = value;
				if(value == null) {
					partnersByCDHPartyNameByRecordTypeMap = null;
				}
			}
		}

		private Map<String,Map<String,List<Account>>> partnersByCDHPartyNameByRecordTypeMap {
			get {
				if(partnersByCDHPartyNameByRecordTypeMap == null) {
					partnersByCDHPartyNameByRecordTypeMap = getPartnersByCDHPartyNameByRecordTypeMap(getPartners(stagingRecordsToMatch.values()),operatingUnitMap);
				}
				return partnersByCDHPartyNameByRecordTypeMap;
			}
			set;
		}

		List<Account> getPartnersByOperatingUnitAndPartnerStaging(String operatingUnit,Opportunity_Partner_Staging__c partnerStaging) {
			List<Account> retval = new List<Account>();
			if(operatingUnit != null && partnerStaging != null && partnerStaging.Oracle_Classification_Code__c != null) {
				System.debug('Looking for Oracle_Classification_Code__c='+partnerStaging.Oracle_Classification_Code__c);
				OperatingUnit__c ou = operatingUnitMap.get(operatingUnit.toUpperCase());
				if(ou != null && ou.PartnerRecordType__c != null) {
					System.debug('Looking for ou.PartnerRecordType__c='+ou.PartnerRecordType__c);
					Map<String,List<Account>> partnersByCDHPartyName = partnersByCDHPartyNameByRecordTypeMap.get(ou.PartnerRecordType__c.toUpperCase());
					if(partnersByCDHPartyName != null) {
						System.debug('Looking for partnerStaging.CDH_Party_Number__c='+partnerStaging.CDH_Party_Number__c);
						List<Account> partners = partnersByCDHPartyName.get(partnerStaging.CDH_Party_Number__c);
						if(partners != null && ! partners.isEmpty()) {
							// only accept partners with the correct program membership
							for(Account partner : partners) {
								if(partner.Partner_Programs__r != null) {
									for(Partner_Program__c pp : partner.Partner_Programs__r) {
										if(pp.Oracle_Classification_Code__c == partnerStaging.Oracle_Classification_Code__c) {
											System.debug('Found for Oracle_Classification_Code__c='+partnerStaging.Oracle_Classification_Code__c);
											retval.add(partner);
											break;
										}
									}
								}
							}
							// The following was not called out explicitly in the acceptance criteria.
							// However, we really should limit ourselves to records with an active partner status
							// as this is still how PRL works.
							if(retval.size() > 1) {
								partners = new List<Account>();
								for(Account partner : retval) {
									if(partner.PartnerStatuses__r != null && ! partner.PartnerStatuses__r.isEmpty()) {
										// use the reduced list of partners
										retval = partners;
										retval.add(partner);
									}
								}
							}
						}
					}
				}
			}
			return retval;
		}

		private Map<Id,Id> accountOwnerMap = new Map<Id,Id>();

		private Map<Id,Id> getAccountOwnerMap(List<Opportunity_Header_Staging__c> headerStagingList) {
			Set<Id> accountIds = new Set<Id>();
			for(Opportunity_Header_Staging__c headerStaging : headerStagingList) {
				if(headerStaging.Opportunity_Owner__c == null && headerStaging.Sales_Account__c != null) {
					accountIds.add(headerStaging.Sales_Account__c);
				}
			}
			accountIds.removeAll(accountOwnerMap.keySet());
			if(! accountIds.isEmpty()) {
				for(Id accountId : accountIds) {
					accountOwnerMap.put(accountId,null);
				}
				System.debug('accountIds='+accountIds);
				for(Account acc : [
					select
						Id,
						OwnerId
					from Account
					where Id in : accountIds ] )
				{
					accountOwnerMap.put(acc.Id,acc.OwnerId);
				}
			}
			return accountOwnerMap;
		}

		/**
		 * Method to process Indirect Direct Opportunities with No order number With status Other than Booked.
		 * @param listofstagingrecords List of Opportunity staging records.
		 */
		private void processIndirectNonBookedOpportunities(List<Opportunity_Header_Staging__c> listofstagingrecord){
			try {
				Savepoint savepoint = Database.setSavepoint();
				try {
					Set<string> orderOrderNumberSet= new Set<string>();
					List<opportunity> oppListToupdate = new List<opportunity>();
					List<Opportunity_Header_Staging__c> oppHeaderListToupdate = new List<Opportunity_Header_Staging__c>();
					List<Order_Tracking__c> opportunityOrderTrackingIndRecList= new List<Order_Tracking__c>();
					for(Opportunity_Header_Staging__c oppHeaderStag:listofstagingrecord){
						if(oppHeaderStag.Oracle_Order_Number__c !=null){
							orderOrderNumberSet.add(oppHeaderStag.Oracle_Order_Number__c);
						}
					}
					Map<string,List<Opportunity>> oracleOdNumberOppMap= new Map<string,List<Opportunity>>();
					if(! orderOrderNumberSet.isEmpty()) {
						System.debug('orderOrderNumberSet='+orderOrderNumberSet);
						for(Opportunity opp:[
							select Id,
								OracleOrderNumber__c,
								StageName,
								Order_Status__c,
								LastModifiedDate,
								OwnerId
							from Opportunity 
							where OracleOrderNumber__c IN:orderOrderNumberSet] )
						{
							List<Opportunity> relOppList= oracleOdNumberOppMap.get(Opp.OracleOrderNumber__c);
							if(relOppList == null) {
								relOppList= new List<Opportunity>(); 
								oracleOdNumberOppMap.put(opp.OracleOrderNumber__c,relOppList);
							}
							relOppList.add(opp);
						}
					}
					Map<Id,Id> xaccountOwnerMap = getAccountOwnerMap(listofstagingrecord);
					for(Opportunity_Header_Staging__c oppHeaderStag:listofstagingrecord){
						try {
							if(oppHeaderStag.Oracle_Order_Number__c !=null && oracleOdNumberOppMap.size()!=0 &&
								oracleOdNumberOppMap.get(oppHeaderStag.Oracle_Order_Number__c) !=null){
								List<opportunity> oppsToUpdate=oracleOdNumberOppMap.get(oppHeaderStag.Oracle_Order_Number__c);
								if(oppsToUpdate.size()==1){
									Id ownerId = oppHeaderStag.Opportunity_Owner__c;
									if(ownerId == null && oppHeaderStag.Sales_Account__c != null) {
										ownerId = xaccountOwnerMap.get(oppHeaderStag.Sales_Account__c);
									}
									Opportunity opp = oppsToUpdate[0];
									if(ownerId != null && oppHeaderStag.Order_Status__c != 'INVOICED' && oppHeaderStag.Order_Status__c != 'Cancelled') {
										//Changed as per User Story US63533 by Sagar Mehta
										opp.OwnerID = ownerId;
									}
									opp.Order_Status__c=oppHeaderStag.Order_Status__c;
									oppListToupdate.add(opp);
									oppHeaderStag.Status__c='Processed';
									oppHeaderListToupdate.add(oppHeaderStag);
									Order_Tracking__c orderTrackObj= new Order_Tracking__c();
									orderTrackObj.Opportunity__c=opp.id;
									orderTrackObj.Opportunity_Owner__c=opp.OwnerId;
									orderTrackObj.Opportunity_Stage__c=opp.StageName;
									orderTrackObj.Oracle_Order_Number__c=opp.OracleOrderNumber__c;
									orderTrackObj.Order_Status__c=opp.Order_Status__c;
									orderTrackObj.Submitted_By__c=integrationUserId;
									orderTrackObj.Submitted_Date__c=oppHeaderStag.LastModifiedDate;
									opportunityOrderTrackingIndRecList.add(orderTrackObj);
								}
								else {
									//oppHeaderStag.Error_Message__c = 'Error Code: In28 Error Message: None or More than one Opportunity with given Order Number found. Please specify an opportunity number that links to the order record or choose to create a new opportunity';
									oppHeaderStag.Status__c = 'Error';
									oppHeaderListToupdate.add(oppHeaderStag);
									errorRecordCreation(oppHeaderStag.Id,'In28','None or More than one Opportunity with given Order Number found. Please specify an opportunity number that links to the order record or choose to create a new opportunity','Not Applicable'); 
								}
							}
							else if(oppHeaderStag.Oracle_Order_Number__c !=null && oracleOdNumberOppMap.size()!=0 &&
								oracleOdNumberOppMap.get(oppHeaderStag.Oracle_Order_Number__c) ==null)
							{
								//oppHeaderStag.Error_Message__c = 'Error Code: In28 Error Message: None or More than one Opportunity with given Order Number found. Please specify an opportunity number that links to the order record or choose to create a new opportunity';
								oppHeaderStag.Status__c = 'Error';
								oppHeaderListToupdate.add(oppHeaderStag);
								errorRecordCreation(oppHeaderStag.Id,'In28','None or More than one Opportunity with given Order Number found. Please specify an opportunity number that links to the order record or choose to create a new opportunity','Not Applicable'); 

							}
						}
						catch(Exception ex) {
							errorRecordCreationWithDetails(ex,oppHeaderStag);
						}
					}
					if(!oppListToupdate.isempty()){
						database.Update(oppListToupdate);
					}
					if(!oppHeaderListToupdate.isempty()){
						database.Update(oppHeaderListToupdate);
					}
					if(!opportunityOrderTrackingIndRecList.isempty()){
						database.Insert(opportunityOrderTrackingIndRecList);
					}
					savepoint = null;
				}
				finally {
					if(savepoint != null) {
						Database.rollback(savepoint);
					}
				}
			}
			catch(Exception ex2) {
				for(Opportunity_Header_Staging__c headerStaging : listofstagingrecord) {
					if(! oppHeaderWithSystemErrorMap.containsKey(headerStaging.Id)) {
						oppHeaderWithSystemErrorMap.put(headerStaging.Id,headerStaging);
					}
					errorRecordCreationWithDetails(ex2,headerStaging);
					headerStaging.Status__c = 'Error';
				}
			}
		}

		List<Potential_Matched_Opportunities__c> potentialMatchOpportunityList= new List<Potential_Matched_Opportunities__c>();
		List<Opportunity_Header_Staging__c> oppListErrorUpdate= new List<Opportunity_Header_Staging__c>();

		/**
		 * Method to process Indirect Direct Opportunities with No order number WIth Booked Status.
		 * @param listofstagingrecords
		 */
		private void processIndirectBookedOpportunitiesPrematch(List<Opportunity_Header_Staging__c> listofstagingrecord){
			try {
				// query list of "Initially Eligible" opportunities:  opportunities that don't currently have an order already assigned 
				//AND are not in the Closed Booked Stage AND are Type <> ICC
				//AND entitle to is associated with one of the correct EBS_Account__c records.
				List<Opportunity> relIndirectOppList = new List<Opportunity>();
				Map<Id,EBS_Account__c> ebsAccountMap = new Map<Id,EBS_Account__c>();
				Set<String> entitleToAccountNumbers = new Set<String>();
				for(Opportunity_Header_Staging__c oppStagRec: listofstagingrecord) {
					if(oppStagRec.Entitle_To_Account_Number__c != null) {
						entitleToAccountNumbers.add(oppStagRec.Entitle_To_Account_Number__c);
					}
				}
				if(! entitleToAccountNumbers.isEmpty()) {
					System.debug('entitleToAccountNumbers='+entitleToAccountNumbers);
					ebsAccountMap.putAll([
						select Id,
							Name,
							Sales_Account__c 
						from EBS_Account__c
						where Name in :entitleToAccountNumbers ]);
					if(! ebsAccountMap.isEmpty()) {
						String limitOnOpp= '2000';
						final Indirect_Matching_Static_Data__c limitIMSD = Indirect_Matching_Static_Data__c.getInstance('Limit');
						if(limitIMSD != null && limitIMSD.Value__c != null) {
							limitOnOpp = limitIMSD.Value__c;
						}
						String sortByValue = 'LastModifiedDate';
						final Indirect_Matching_Static_Data__c sortByIMSD = Indirect_Matching_Static_Data__c.getInstance('SortBy');
						if(sortByIMSD != null && sortByIMSD.Value__c != null) {
							sortByValue = sortByIMSD.Value__c;
						}
						final Set<Id> ebsAccountIds = ebsAccountMap.keySet();
						final Set<Id> salesAccountIds = new Set<Id>();
						for(EBS_Account__c ebsAccount : ebsAccountMap.values()) {
							if(ebsAccount.Sales_Account__c != null) {
								salesAccountIds.add(ebsAccount.Sales_Account__c);
							}
						}
						String filter = '';
						String sep = '';
						if(!ebsAccountIds.isEmpty()) {
							filter = 'Entitle_To_Account__c in :ebsAccountIds';
							sep = ' OR ';
							System.debug('ebsAccountIds='+ebsAccountIds);
						}
						if(!salesAccountIds.isEmpty()) {
							filter += sep + 'Entitle_To_Sales_Account__c in :salesAccountIds';
							System.debug('salesAccountIds='+salesAccountIds);
						}
						relIndirectOppList = new List<Opportunity>();
						if(filter != '') {
							System.debug('excludedRecordTypeIds='+excludedRecordTypeIds);
							relIndirectOppList = Database.query(
								'SELECT Id,'
								+	'Name,'
								+	'Entitle_To_Sales_Account__c,'
								+	'Entitle_To_Account__r.Name,'
								+	'Amount '
								+'FROM Opportunity '
								+'WHERE OracleOrderID__c = null '
								+	'AND StageName != \'Closed Booked\' '
								+	'AND RecordTypeId NOT IN :excludedRecordTypeIds '
								+	'AND ( '+filter+' ) '
								+'ORDER BY '+sortBYValue+' DESC '
								+'LIMIT '+limitOnOpp );
						}
					}
				}

				//If the records retrieved after executing the query is less than than zero
//DE10221				if(relIndirectOppList.isEmpty()){
//DE10221					for(Opportunity_Header_Staging__c stagingrecord:listofstagingrecord){
//DE10221						// stagingrecord.Error_Message__c = 'Error Code: In1 Error Message: No eligible opportunities found. Please specify an opportunity number that links to the order record or choose to create a new opportunity';
//DE10221						stagingrecord.Status__c = 'Error';
//DE10221						oppListErrorUpdate.add(stagingrecord);
//DE10221						errorRecordCreation(stagingrecord.Id,'In1','No eligible opportunities found. Please specify an opportunity number that links to the order record or choose to create a new opportunity','Not Applicable'); 
//DE10221					}
//DE10221					listofstagingrecord.clear();
//DE10221				}
//DE10221				else {
					Map<id,set<String>> salesAccountIDEBSIDMap= new Map<id,set<String>>();
					// Get the List of EBS records Related to Sales Account
					if(! ebsAccountMap.isEmpty()) {
						Set<id> salesAccountIds= new Set<id>();
						for(Opportunity opp:relIndirectOppList){
							if(opp.Entitle_To_Sales_Account__c !=null){
								salesAccountIds.add(opp.Entitle_To_Sales_Account__c);
							}
						}
						if(! salesAccountIds.isEmpty()){
							for(EBS_Account__c eBSAcc: ebsAccountMap.values() ) {
								if(salesAccountIds.contains(eBSAcc.Sales_Account__c)) {
									Set<String> names=salesAccountIDEBSIDMap.get(eBSAcc.Sales_Account__c);
									if(names == null) {
										names = new Set<String>();
										salesAccountIDEBSIDMap.put(eBSAcc.Sales_Account__c,names);
									}
									names.add(eBSAcc.Name);
								}
							}
						}
					}
					//If the records retrieved after executing the query is not zero
					for(Opportunity_Header_Staging__c oppStagRec: listofstagingrecord){
						try {
							boolean errorI2Invalid=False;
							boolean errorI3Invalid=False;
							boolean ValidateIndirectOpportunity=False;
							for(opportunity oppInd: relIndirectOppList){
								//**First Set of filters :
								//1.Query all the opportunity ID’s where Entitle-To Account Number on the order record matches the Entitle-To Account Number on the opportunity.
								//2.Query all the opportunity ID’s where the Entitle-To Account Number on the order record matches the Entitle-To Account number associated with the Entitle-To Sales Account on the opportunity.

								if( (oppStagRec.Entitle_To_Account_Number__c !=null 
										&& oppStagRec.Entitle_To_Account_Number__c == oppInd.Entitle_To_Account__r.Name )
									|| ( salesAccountIDEBSIDMap !=null 
										&& salesAccountIDEBSIDMap.containsKey(oppInd.Entitle_To_Sales_Account__c) 
										&& salesAccountIDEBSIDMap.get(oppInd.Entitle_To_Sales_Account__c).contains(oppStagRec.Entitle_To_Account_Number__c) ) )
								{
									errorI2Invalid=true;
									//** second set of filter :Query the opportunity ID’s where the Order Amount (Order Total) is in the range of +/- 15 % of the Opportunity Amount.  
									// if(oppStagRec.Amount__c==null){
									//	 oppStagRec.Amount__c=0;
									// }
									if(oppInd.Amount == null){
										oppInd.Amount=0;
									}
									if(amountTolerance==null){
										amountTolerance=0;
									}
									if(oppStagRec.Amount__c <=(oppInd.Amount +((oppInd.Amount/100)*amountTolerance)) && oppStagRec.Amount__c >=(oppInd.Amount -((oppInd.Amount/100)*amountTolerance)) ){
										errorI3Invalid=true;
										Potential_Matched_Opportunities__c potentialMatch= new Potential_Matched_Opportunities__c();
										potentialMatch.name=oppInd.Name;
										potentialMatch.Opportunity__c=oppInd.id;
										potentialMatch.Opportunity_Header_Staging__c=oppStagRec.id;
										potentialMatchOpportunityList.add(potentialMatch);
									}
								}
							}
							//for indirect without Opportunity number scenarios check the not entitled endco 
							if(oppStagRec.Non_Entitled_Endco__c ==null &&
								oppStagRec.Non_Entitled_Endco_CDH_Party_Number__c !=null &&
								nonEcoAccountByCDHPartyName !=null &&
								nonEcoAccountByCDHPartyName.get(oppStagRec.Non_Entitled_Endco_CDH_Party_Number__c) !=null &&
								nonEcoAccountByCDHPartyName.get(oppStagRec.Non_Entitled_Endco_CDH_Party_Number__c).size() ==1)
							{
								oppStagRec.Non_Entitled_Endco__c=nonEcoAccountByCDHPartyName.get(oppStagRec.Non_Entitled_Endco_CDH_Party_Number__c)[0].id;
							}
							else if(oppStagRec.Non_Entitled_Endco_CDH_Party_Number__c !=null){
								errorRecordCreation(oppStagRec.Id , 'In29','Non Entitled Endco match failed. Please review and select the correct the Non Entitled Endco from the lookup field.','Non_Entitled_Endco_CDH_Party_Number__c'); 
							}
							if(!errorI2Invalid) {
								errorRecordCreation(oppStagRec.Id,'In2','No opportunities found for the Order Entitle To customer','Not Applicable');
								//oppStagRec.Error_Message__c = 'Error Code: In2 Error Message: No opportunities found for the Order Entitle To customer';
								oppStagRec.Status__c = 'Error';
								ValidateIndirectOpportunity=true;
							}else if(!errorI3Invalid) {
								errorRecordCreation(oppStagRec.Id,'In3','No opportunities of similar value have been found','Not Applicable'); 
								//oppStagRec.Error_Message__c = 'Error Code: In3 Error Message: No opportunities of similar value have been found';
								oppStagRec.Status__c = 'Error';
								ValidateIndirectOpportunity=true;

							}else{
								List<String> e = System.Label.C360_IN37.split(':\\s*',2);
								e.add(e[0]);
								errorRecordCreation(oppStagRec.Id,e[0],e[1],'Not Applicable');
								//oppStagRec.Error_Message__c = 'Error Code: In27 Error Message: Potential matching opportunities found. Please review the opportunities and select one of the opportunities for re-processing or choose to create a new opportunity. ';
								oppStagRec.Status__c = 'Error';
								// oppListErrorUpdate.add(oppStagRec);
							}
							System.debug('stagingRecordsToMatch.put('+oppStagRec.Id+','+oppStagRec+')');
							stagingRecordsToMatch.put(oppStagRec.Id,oppStagRec);
						}
						catch(Exception ex) {
							errorRecordCreationWithDetails(ex,oppStagRec);
						}
					}
//DE10221				} 
			}
			catch(Exception ex2) {
				for(Opportunity_Header_Staging__c headerStaging : listofstagingrecord) {
					if(! oppHeaderWithSystemErrorMap.containsKey(headerStaging.Id)) {
						oppHeaderWithSystemErrorMap.put(headerStaging.Id,headerStaging);
						headerStaging.Status__c = 'Error';
						errorRecordCreationWithDetails(ex2,headerStaging);
					}
				}
				listofstagingrecord.clear();
			}
		}

		private List<Opportunity_Line_Staging__c> getLines(List<Opportunity_Header_Staging__c> headers) {
			List<Opportunity_Line_Staging__c> lines = new List<Opportunity_Line_Staging__c>();
			for(Opportunity_Header_Staging__c header : headers) {
				Opportunity_Header_Staging__c staging = stagingRecordsToMatch.get(header.Id);
				if(staging != null && staging.Opportunities_Line_Staging__r != null) {
					lines.addAll(staging.Opportunities_Line_Staging__r);
				}
			}
			return lines;
		}

		private List<Opportunity_Partner_Staging__c> getPartners(List<Opportunity_Header_Staging__c> headers) {
			List<Opportunity_Partner_Staging__c> partners = new List<Opportunity_Partner_Staging__c>();
			for(Opportunity_Header_Staging__c header : headers) {
				Opportunity_Header_Staging__c staging = stagingRecordsToMatch.get(header.Id);
				if(staging != null && staging.Opportunities_Partner_Staging__r != null) {
					partners.addAll(staging.Opportunities_Partner_Staging__r);
				}
			}
			return partners;
		}

		private List<Database.SaveResult> updateLines(List<Opportunity_Line_Staging__c> lines,Boolean requireAll) {
			for(Opportunity_Line_Staging__c line : lines) {
				Account a = line.Entitle_To_Sales_Account__r;
				if(a != null) {
					if(a.Id == null) {
						a = accountToUpsertMap.get(a.Account_External_Id__c);
					}
					if(a != null && a.Id == null) {
						line.Entitle_To_Sales_Account__r = a;
						line.Entitle_To_Sales_Account__c = a.Id;
					}
				}
				Address__c  addr = line.Entitle_To_Address__r;
				if(addr != null) {
					if(addr.Id == null) {
						addr = addressToUpsertMap.get(addr.Address_External_Id__c);
					}
					if(addr != null && addr.Id == null) {
						line.Entitle_To_Address__r = addr;
						line.Entitle_To_Address__c = addr.Id;
					}
				}
				EBS_Account__c  e = line.Entitle_To_Account__r;
				if(e != null) {
					if(e.Id == null) {
						e = ebsAccountToUpsertMap.get(e.EBS_Account_External_Id__c);
					}
					if(e != null && e.Id == null) {
						line.Entitle_To_Account__r = e;
						line.Entitle_To_Account__c = e.Id;
					}
				}
				Contact c = line.Entitle_To_Contact__r;
				if(c != null) {
					if(c.Id == null) {
						c = contactToUpsertMap.get(c.Contact_External_Id__c);
					}
					if(c != null && c.Id == null) {
						line.Entitle_To_Contact__r = c;
						line.Entitle_To_Contact__c = c.Id;
					}
				}
			}
			System.debug('Updating lines: '+lines);
			return database.update(lines,requireAll);
		}

		private List<Database.SaveResult> updateHeaders(List<Opportunity_Header_Staging__c> headers,Boolean requireAll) {
			for(Opportunity_Header_Staging__c header : headers) {
				if(stagingRecordsToMatch.containsKey(header.Id)) {
					Account a = header.Bill_To_Sales_Account__r;
					if(a != null) {
						if(a.Id == null) {
							a = accountToUpsertMap.get(a.Account_External_Id__c);
						}
						if(a != null && a.Id != null) {
							header.Bill_To_Sales_Account__r = a;
							header.Bill_To_Sales_Account__c = a.Id;
						}
					}
					a = header.Entitle_To_Sales_Account__r;
					if(a != null) {
						if(a.Id == null) {
							a = accountToUpsertMap.get(a.Account_External_Id__c);
						}
						if(a != null && a.Id != null) {
							header.Entitle_To_Sales_Account__r = a;
							header.Entitle_To_Sales_Account__c = a.Id;
						}
					}
					a = header.Ship_To_Sales_Account__r;
					if(a != null) {
						if(a.Id == null) {
							a = accountToUpsertMap.get(a.Account_External_Id__c);
						}
						if(a != null && a.Id != null) {
							header.Ship_To_Sales_Account__r = a;
							header.Ship_To_Sales_Account__c = a.Id;
						}
					}
					a = header.Sold_To_Sales_Account__r;
					if(a != null) {
						if(a.Id == null) {
							a = accountToUpsertMap.get(a.Account_External_Id__c);
						}
						if(a != null && a.Id != null) {
							header.Sold_To_Sales_Account__r = a;
							header.Sold_To_Sales_Account__c = a.Id;
						}
					}
					Address__c addr = header.Bill_To_Address__r;
					if(addr != null) {
						if(addr.Id == null) {
							addr = addressToUpsertMap.get(addr.Address_External_Id__c);
						}
						if(addr != null && addr.Id != null) {
							header.Bill_To_Address__r = addr;
							header.Bill_To_Address__c = addr.Id;
						}
					}
					addr = header.Entitle_To_Address__r;
					if(addr != null) {
						if(addr.Id == null) {
							addr = addressToUpsertMap.get(addr.Address_External_Id__c);
						}
						if(addr != null && addr.Id != null) {
							header.Entitle_To_Address__r = addr;
							header.Entitle_To_Address__c = addr.Id;
						}
					}
					addr = header.Ship_To_Address__r;
					if(addr != null) {
						if(addr.Id == null) {
							addr = addressToUpsertMap.get(addr.Address_External_Id__c);
						}
						if(addr != null && addr.Id != null) {
							header.Ship_To_Address__r = addr;
							header.Ship_To_Address__c = addr.Id;
						}
					}
					addr = header.Sold_To_Address__r;
					if(addr != null) {
						if(addr.Id == null) {
							addr = addressToUpsertMap.get(addr.Address_External_Id__c);
						}
						if(addr != null && addr.Id != null) {
							header.Sold_To_Address__r = addr;
							header.Sold_To_Address__c = addr.Id;
						}
					}
					EBS_Account__c e = header.Bill_To_Account__r;
					if(e != null) {
						if(e.Id == null) {
							e = ebsAccountToUpsertMap.get(e.EBS_Account_External_Id__c);
						}
						if(e != null && e.Id != null) {
							header.Bill_To_Account__r = e;
							header.Bill_To_Account__c = e.Id;
						}
					}
					e = header.Entitle_To_Account__r;
					if(e != null) {
						if(e.Id == null) {
							e = ebsAccountToUpsertMap.get(e.EBS_Account_External_Id__c);
						}
						if(e != null && e.Id != null) {
							header.Entitle_To_Account__r = e;
							header.Entitle_To_Account__c = e.Id;
						}
					}
					e = header.Ship_To_Account__r;
					if(e != null) {
						if(e.Id == null) {
							e = ebsAccountToUpsertMap.get(e.EBS_Account_External_Id__c);
						}
						if(e != null && e.Id != null) {
							header.Ship_To_Account__r = e;
							header.Ship_To_Account__c = e.Id;
						}
					}
					e = header.Sold_To_Account__r;
					if(e != null) {
						if(e.Id == null) {
							e = ebsAccountToUpsertMap.get(e.EBS_Account_External_Id__c);
						}
						if(e != null && e.Id != null) {
							header.Sold_To_Account__r = e;
							header.Sold_To_Account__c = e.Id;
						}
					}
					Contact c = header.Bill_To_Contact__r;
					if(c != null) {
						if(c.Id == null) {
							c = contactToUpsertMap.get(c.Contact_External_Id__c);
						}
						if(c != null && c.Id != null) {
							header.Bill_To_Contact__r = c;
							header.Bill_To_Contact__c = c.Id;
						}
					}
					c = header.Entitle_To_Contact__r;
					if(c != null) {
						if(c.Id == null) {
							c = contactToUpsertMap.get(c.Contact_External_Id__c);
						}
						if(c != null && c.Id != null) {
							header.Entitle_To_Contact__r = c;
							header.Entitle_To_Contact__c = c.Id;
						}
					}
					c = header.Ship_To_Contact__r;
					if(c != null) {
						if(c.Id == null) {
							c = contactToUpsertMap.get(c.Contact_External_Id__c);
						}
						if(c != null && c.Id != null) {
							header.Ship_To_Contact__r = c;
							header.Ship_To_Contact__c = c.Id;
						}
					}
					c = header.Sold_To_Contact__r;
					if(c != null) {
						if(c.Id == null) {
							c = contactToUpsertMap.get(c.Contact_External_Id__c);
						}
						if(c != null && c.Id != null) {
							header.Sold_To_Contact__r = c;
							header.Sold_To_Contact__c = c.Id;
						}
					}
				}
			}
			System.debug('Updating headers: '+headers);
//			for(Opportunity_Header_Staging__c header : headers) {
//				System.debug(header.Id+'.Bill_To_Account__c='+header.Bill_To_Account__c);
//				System.debug(header.Id+'.Bill_To_Account__r='+header.Bill_To_Account__r);
//				System.debug(header.Id+'.Entitle_To_Account__c='+header.Entitle_To_Account__c);
//				System.debug(header.Id+'.Entitle_To_Account__r='+header.Entitle_To_Account__r);
//				System.debug(header.Id+'.Ship_To_Account__c='+header.Ship_To_Account__c);
//				System.debug(header.Id+'.Ship_To_Account__r='+header.Ship_To_Account__r);
//				System.debug(header.Id+'.Sold_To_Account__c='+header.Sold_To_Account__c);
//				System.debug(header.Id+'.Sold_To_Account__r='+header.Sold_To_Account__r);
//			}
			return database.update(headers,requireAll);
		}

		private List<Database.SaveResult> updatePartners(Boolean requireAll) {
			for(Opportunity_Partner_Staging__c partner : partnersToUpdate) {
				Contact c = partner.Partner_Contact__r;
				if(c != null) {
					if(c.Id == null) {
						c = contactToUpsertMap.get(c.Contact_External_Id__c);
					}
					if(c != null && c.Id != null) {
						partner.Partner_Contact__r = c;
						partner.Partner_Contact__c = c.Id;
					}
				}
			}
			System.debug('Updating partners: '+partnersToUpdate);
			return database.update(partnersToUpdate,requireAll);
		}

		/**
		 * Method to process Indirect Direct Opportunities with No order number WIth Booked Status.
		 * @param listofstagingrecords
		 */
		private void processIndirectBookedOpportunitiesPostmatch(List<Opportunity_Header_Staging__c> listofstagingrecord){
			try {
				Savepoint savepoint = Database.setSavepoint();
				try {
					//If the records retrieved after executing the query is not zero
					for(Opportunity_Header_Staging__c oppStagRec: listofstagingrecord){
						if(! stagingRecordsToMatch.containsKey(oppStagRec.Id)) {
							for(Opportunity_Line_Staging__c line : oppStagRec.Opportunities_Line_Staging__r) {
								clearMultiMatch(line);
							}
							continue;
						}
						oppStagRec=indirectOppValidation(oppStagRec,'Bill','4');
						oppStagRec=indirectOppValidation(oppStagRec,'Ship','8');
						oppStagRec=indirectOppValidation(oppStagRec,'Sold','12');
						oppStagRec=indirectOppValidation(oppStagRec,'Entitle','16');
						// Logic for the Opportunity Line Item validation.
						if(! oppStagRec.Opportunities_Line_Staging__r.isEmpty()){
							oppStagRec=opportunitystagingLineItemProcess(oppStagRec.Opportunities_Line_Staging__r,oppStagRec,'In');
						}
						if(oppStagRec != null) {
							// Logic for the Opportunity Partner validation.
							List<Opportunity_Partner_Staging__c> partnersToProcess = oppStagRec.Opportunities_Partner_Staging__r;
							if(! partnersToProcess.isEmpty()){
								oppStagRec=opprtunityPartnerItemProcess(oppStagRec.Opportunities_Partner_Staging__r,oppStagRec,'In',null);
							}
							if(oppStagRec != null) {
								oppListErrorUpdate.add(oppStagRec);
							}
						}
					}
					if(!oppListErrorUpdate.isempty()) {
						if(!cDHPartyToInsertSet.isempty()){
							// upsert based on the external Id.
							database.upsert(new List<CDH_Party__c>(cDHPartyToInsertSet),CDH_Party__c.field.CDH_Party_Number_Ext__c,true);
							//insert(new List<CDH_Party__c>(cDHPartyToInsertSet));
							cDHPartyToInsertSet.clear();
						}
						System.debug('Upserting accounts: '+accountToUpsertMap.keySet());
						database.upsert(accountToUpsertMap.values(),Account.field.Account_External_Id__c ,true);
						List<Contact> contactsToUpsert = getUpsertContacts(contactToUpsertMap,accountToUpsertMap);
						System.debug('Upserting contacts: '+contactsToUpsert);
						database.upsert(contactsToUpsert, Contact.Field.Contact_External_Id__c,true);
						List<Address__c> addressesToUpsert = getUpsertAddresses(addressToUpsertMap,accountToUpsertMap);
						System.debug('Upserting addresses: '+addressesToUpsert);
						database.upsert(addressesToUpsert,Address__c.field.Address_External_Id__c,true);
						List<EBS_Account__c> ebsAccountsToUpsert = getUpsertEBSAccounts(ebsAccountToUpsertMap,accountToUpsertMap);
						System.debug('Upserting ebsAccounts: '+ebsAccountsToUpsert);
						database.upsert(ebsAccountsToUpsert,EBS_Account__c.field.EBS_Account_External_Id__c,true);
						updateLines(getLines(oppListErrorUpdate),true);
						updatePartners(true);
						updateHeaders(oppListErrorUpdate,true);
					}
					savepoint = null;
				}
				finally {
					accountToUpsertMap.clear();
					addressToUpsertMap.clear();
					contactToUpsertMap.clear();
					ebsAccountToUpsertMap.clear();
					partnersToUpdate.clear();
					if(savepoint != null) {
						Database.rollback(savepoint);
					}
					if(!potentialMatchOpportunityList.isempty()){
						database.insert(potentialMatchOpportunityList);
					}
				}
			}
			catch(Exception ex2) {
				for(Opportunity_Header_Staging__c headerStaging : listofstagingrecord) {
					if(! oppHeaderWithSystemErrorMap.containsKey(headerStaging.Id)) {
						oppHeaderWithSystemErrorMap.put(headerStaging.Id,headerStaging);
					}
					errorRecordCreationWithDetails(ex2,headerStaging);
					headerStaging.Status__c = 'Error';
				}
			}
		}

		private Account addAccountToUpsert(Account account) {
			Account retval = accountToUpsertMap.get(account.Account_External_Id__c);
			if(retval == null) {
				retval = account;
				accountToUpsertMap.put(account.Account_External_Id__c,retval);
			}
			return retval;
		}

		private EBS_Account__c addEBSAccountToUpsert(EBS_Account__c ebsAccount) {
			EBS_Account__c retval = ebsAccountToUpsertMap.get(ebsAccount.EBS_Account_External_Id__c);
			if(retval == null) {
				retval = ebsAccount;
				ebsAccountToUpsertMap.put(retval.EBS_Account_External_Id__c,retval);
				if(retval.Sales_Account__r != null && retval.Sales_Account__r.Account_External_Id__c != null) {
					String externalId2 = retval.Name+retval.Sales_Account__r.Account_External_Id__c;
					if(retval.EBS_Account_External_Id__c != externalId2) {
						ebsAccountToUpsertMap.put(externalId2,retval);
					}
				}
			}
			return retval;
		}

		private Address__c addAddressToUpsert(Address__c address) {
			Address__c retval = addressToUpsertMap.get(address.Address_External_Id__c);
			if(retval == null) {
				retval = address;
				addressToUpsertMap.put(address.Address_External_Id__c,retval);
				if(retval.Sales_Account__r != null && retval.Sales_Account__r.Account_External_Id__c != null) {
					String externalId2 = retval.Sales_Account__r.Account_External_Id__c+retval.CDH_Party_Site_Number__c;
					if(retval.Address_External_Id__c != externalId2) {
						addressToUpsertMap.put(externalId2,retval);
					}
				}
			}
			return retval;
		}

		private Contact addContactToUpsert(Contact contact) {
			Contact retval = contactToUpsertMap.get(contact.Contact_External_Id__c);
			if(retval == null) {
				retval = contact;
				contactToUpsertMap.put(retval.Contact_External_Id__c,retval);
				if(retval.CDH_Party__r != null && retval.Account != null && retval.Account.Account_External_Id__c != null) {
					String externalId2 = retval.CDH_Party__r.CDH_Party_Number_Ext__c+retval.Account.Account_External_Id__c;
					if(retval.Contact_External_Id__c != externalId2) {
						contactToUpsertMap.put(externalId2,retval);
					}
				}
			}
			return retval;
		}

		/**
		 * Method to process List of Opportunity Staging records and update Error's in case of invalid data.
		 * @param stagingrecord Opportunity staging record to process
		 * @return the staging record
		 */
		private Opportunity_Header_Staging__c  indirectOppValidation(Opportunity_Header_Staging__c stagingrecord,String Type,String errorStartNum){
			boolean conditionsValid=true;
			id salesAccID;
			//Incase New Records are created this list will be update with the error list
//depreciated			List<Match_and_Validation_Error__c> errorListNew = new List<Match_and_Validation_Error__c>();
//depreciated			errorListNew.addAll(errorList);
			string accountPrevId=String.valueof(stagingrecord.get(Type+'_To_Account__c'));
			system.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@2+'+stagingrecord.get(Type+'_To_Account__c'));
			// match query the EBS account records based on the Bill_To_Account_Number__c of staging record.
			Id stagingEBSAccountId = (Id)stagingrecord.get(Type+'_To_Account__c');
			EBS_Account__c stagingEBSAccount = (EBS_Account__c)stagingrecord.getsobject(Type+'_To_Account__r');
			if(stagingEBSAccountId == null) {
				stagingrecord.putsobject(Type+'_To_Account__r',null);
			}
			else if(stagingEBSAccount != null){
				salesAccID=stagingEBSAccount.Sales_Account__c;
			}
//depreciated			else if(
//depreciated				stagingrecord.get(Type+'_To_Account_Number__c') !=Null &&
//depreciated				(eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof(stagingrecord.get(Type+'_To_Account_Number__c')))== Null ||
//depreciated				eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof(stagingrecord.get(Type+'_To_Account_Number__c'))).size()>1)){
//depreciated					conditionsValid=false;
//depreciated					errorRecordCreation(stagingrecord.Id,'In'+errorStartNum,Type+'-To Account number match failed. Please review and select the correct '+Type+'-To Account Number from the lookup field.',Type+'_To_Account_Number__c');
//depreciated			}else if(
//depreciated				stagingrecord.get(Type+'_To_Account_Number__c') !=Null &&
//depreciated				eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof(stagingrecord.get(Type+'_To_Account_Number__c')))!= Null &&
//depreciated				eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof(stagingrecord.get(Type+'_To_Account_Number__c'))).size()==1){
//depreciated						// if matched then populate the Bill to Account lookup
//depreciated						stagingrecord.put(Type+'_To_Account__c',eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof(stagingrecord.get(Type+'_To_Account_Number__c')))[0].id);
//depreciated						salesAccID=eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof(stagingrecord.get(Type+'_To_Account_Number__c')))[0].Sales_Account__c;
//depreciated			}
			// match query the address records based on the Bill_To_Address_CDH_Party_Site_Number__c of staging record.
			Id stagingAddressId = (Id)stagingrecord.get(Type+'_To_Address__c');
			Address__c stagingAddress = (Address__c)stagingrecord.getsobject(Type+'_To_Address__r');
			if(stagingAddressId == null) {
				stagingrecord.putsobject(Type+'_To_Address__r',null);
			}
			else if(salesAccID != null && stagingAddress != null && stagingAddress.Sales_Account__c != null && salesAccID != stagingAddress.Sales_Account__c) {
				salesAccID = null;
			}
//depreciated			if(stagingAddress == Null &&
//depreciated				stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c') != Null &&
//depreciated				(cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c')))== Null || 
//depreciated				cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c'))).size() >1)){
//depreciated					conditionsValid=false;
//depreciated					errorRecordCreation(stagingrecord.Id,'In'+String.Valueof(Integer.Valueof(errorStartNum)+1),Type+'-To Address match failed. Please review and select the correct '+Type+'-To Address from the lookup field.',Type+'_To_Address_CDH_Party_Site_Number__c');
//depreciated			}else if(stagingAddress == Null &&
//depreciated				stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c') != Null &&
//depreciated				cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c')))!= Null && 
//depreciated				cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c'))).size() ==1){
//depreciated					// if matched then populate the Bill to Address lookup
//depreciated					stagingrecord.put(Type+'_To_Address__c',cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c')))[0].id);

//depreciated					if(salesAccID !=null && 
//depreciated					cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c')))[0].Sales_Account__c !=null && 
//depreciated					salesAccID != cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c')))[0].Sales_Account__c){
//depreciated						salesAccID=null;
//depreciated					}
//depreciated			}

//depreciated			Contact stagingContact = stagingrecord.getsobject(Type+'_To_Contact__r');
//depreciated			// match query the contact records based on the Bill_To_CDH_Party_Number__c of staging record.
//depreciated			if(stagingContact == Null &&
//depreciated				stagingrecord.get(Type+'_To_CDH_Party_Number__c') != Null &&
//depreciated				(cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c')))== Null || 
//depreciated				cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c'))).size()>1)){
//depreciated					conditionsValid=false;
//depreciated					errorRecordCreation(stagingrecord.Id,'In'+String.Valueof(Integer.Valueof(errorStartNum)+2),Type+'-To Contact match failed. Please review and select the correct '+Type+'-To Contact from the lookup field',Type+'_To_CDH_Party_Number__c');
//depreciated			}else if(stagingContact == Null &&
//depreciated				stagingrecord.get(Type+'_To_CDH_Party_Number__c') != Null &&
//depreciated				cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c')))!= Null && 
//depreciated				cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c'))).size()==1){
//depreciated					// if matched then populate the CDH Party lookup
//depreciated					stagingrecord.put(Type+'_To_Contact__c',cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c')))[0].id);
//depreciated					 
//depreciated					if(salesAccID !=null && 
//depreciated					cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c')))[0].AccountId !=null &&
//depreciated					salesAccID != cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c')))[0].AccountId){
//depreciated						salesAccID=null;
//depreciated					}
//depreciated			}
			Id stagingContactId = (Id)stagingrecord.get(Type+'_To_Contact__c');
			Contact stagingContact = (Contact)stagingrecord.getsobject(Type+'_To_Contact__r');
			if(stagingContactId == null) {
				stagingrecord.putsobject(Type+'_To_Contact__r',null);
			}
			else if(salesAccID != null && stagingContact != Null && stagingContact.AccountId != null && salesAccID != stagingContact.AccountId) {
				salesAccID = null;
			}

			String contactCDHPartyNumber = String.valueOf(stagingrecord.get(Type+'_To_CDH_Party_Number__c'));
			// create contact record in case single record found for ebs account and address associated with same sales account.
			if(stagingContactId == null
				&& stagingContact == null
				&& contactCDHPartyNumber != null
				&& stagingAddressId != null
				&& stagingAddress != null
				&& stagingEBSAccountId  != null 
				&& stagingEBSAccount != null
				&& salesAccID !=null )
			{
				//Clear the Old error list to remove error added due to improper CDH details
//depreciated				errorList.clear();
//depreciated				errorList.addAll(errorListNew);

				// first create CDH Party record.
				CDH_Party__c cdhParty = createCDHPersonParty(stagingrecord,Type,'PERSON');

				//Changed by Niti : Add CDH party instance into the set only if it does not exist already.
				if(checkCDHinSet(cDHPartyToInsertSet ,contactCDHPartyNumber ))
				{
					cDHPartyToInsertSet.add(cdhParty );
				}

				// create contact record.
				Contact contact = addContactToUpsert(createContact( stagingrecord, Type, new Account(Id=salesAccId) ));
				stagingrecord.putsobject(Type+'_To_Contact__r' , contact );
			} 



			// Match the sales account information received from Bill-To Account, Bill-To Address and Bill-To Contact 
			if(salesAccID !=null){
				stagingrecord.put(Type+'_To_Sales_Account__c',salesAccID);
			}
//depreciated			else if((stagingrecord.get(Type+'_To_CDH_Party_Number__c') != Null && stagingrecord.get(Type+'_To_Contact__c')==null)|| 
//depreciated				(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c') != Null && stagingrecord.get(Type+'_To_Address__c')==null )||
//depreciated				(stagingrecord.get(Type+'_To_Account_Number__c') !=Null && stagingrecord.get(Type+'_To_Account__c') == Null))
//depreciated			{
//depreciated				 errorRecordCreation(stagingrecord.Id,'In'+String.Valueof(Integer.Valueof(errorStartNum)+3),Type+'-To Account,'+Type+'-To Address and '+Type+'-To Contact is not associated with the same Sales Account .Please review and correct the '+ Type+'-To information.' ,Type+'_To_Sales_Account__c');
//depreciated			}
			// in case no information is recived Bill-To Account, Bill-To Address and Bill-To Contact then create new records and assign the same.
			String oracleAccountNumber = String.valueOf(stagingrecord.get(Type+'_To_Account_Number__c'));
			String cdhPartySiteNumber = String.valueOf(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c'));
			if( // stagingrecord.Status__c != 'ERROR' &&
				stagingEBSAccountId == Null &&
				stagingAddressId == Null &&
				stagingContactId == Null &&
				oracleAccountNumber != Null &&
				cdhPartySiteNumber != Null &&
				contactCDHPartyNumber != null && 
				stagingEBSAccount == null && // eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof(stagingrecord.get(Type+'_To_Account_Number__c')))==Null &&
				stagingAddress == null && // cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c')))== Null &&
				stagingContact == null && // cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c')))== Null && 
				stagingrecord.get(Type+'_To_Party_Type__c')=='PERSON')
			{
				String accountCDHPartyNumber = String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number_Account__c'));
				//Clear the Old error list to remove error added due to improper CDH details
//depreciated				errorList.clear();
//depreciated				errorList.addAll(errorListNew);

				// create CDH Party record for salesaccount.
				CDH_Party__c cdhParty = createCDHAccountParty(stagingrecord,Type);

				//Changed by Niti : Add CDH party instance into the set only if it does not exist already.
				if(checkCDHinSet(cDHPartyToInsertSet , accountCDHPartyNumber ))
				{
					cDHPartyToInsertSet.add(cdhParty);
				}

				// create sales account record.
				Account account = addAccountToUpsert(createAccount(stagingRecord,Type));

				// create EBS Account.
				EBS_Account__c ebsAccount = addEBSAccountToUpsert(createEBSAccount(stagingrecord,Type,account));

				// create address record.
				Address__c address = addAddressToUpsert(createAddress(stagingrecord,Type,account));

				// create cdh party records.

				CDH_Party__c cdhPersonParty = createCDHPersonParty( stagingrecord, Type, null);

				//Changed by Niti : Add CDH party instance into the set only if it does not exist already.
				if(checkCDHinSet(cDHPartyToInsertSet ,contactCDHPartyNumber ))
				{
					cDHPartyToInsertSet.add(cdhPersonParty);
				}

				//create contact record.
				Contact contact = addContactToUpsert(createContact( stagingrecord, Type, account ));

				// associate these created records to staging record.
				stagingrecord.putsobject(Type+'_To_Contact__r' , contact );
				stagingrecord.putsobject(Type+'_To_Sales_Account__r', account );
				stagingrecord.putsobject(Type+'_To_Address__r', address );
				stagingrecord.putsobject(Type+'_To_Account__r', ebsAccount );

			}
			return stagingrecord;
		}



		/**
		 * Method to process Direct Opportunities.
		 * @param listofstagingrecord
		 */
		private void processDirectOpportunitiesPrematch(List<Opportunity_Header_Staging__c> listofstagingrecord)
		{
			try {
				// prepare the set of opportunities id.
				Set<Id> directOpportunitiesIdSet = new Set<Id>();
				// set of the Opportunity number in staging record.
				Set<String> indirectOpportunityNumberSet = new Set<String>();
				for(Opportunity_Header_Staging__c directOpportunitystaging: listofstagingrecord) {
					if(directOpportunitystaging.Opportunity_ID__c!=Null){
						directOpportunitiesIdSet.add(directOpportunitystaging.Opportunity_ID__c);
					}
					if(directOpportunitystaging.Opportunity_Number__c!=Null){
						indirectOpportunityNumberSet.add(directOpportunitystaging.Opportunity_Number__c);
					}

				}

				//Query all the opportunities and retrieve the result in one map.
				opportunityDetailsMap = new Map<Id,Opportunity>();
	
				if( ! (directOpportunitiesIdSet.isEmpty()&&indirectOpportunityNumberSet.isEmpty())) {
					System.debug('directOpportunitiesIdSet='+directOpportunitiesIdSet);
					System.debug('indirectOpportunityNumberSet='+indirectOpportunityNumberSet);
					opportunityDetailsMap.putAll([
						select Id,
							Name,
							StageName,
							OracleOrderID__c,
							OracleOrderNumber__c,
							RecordTypeId,
							Recordtype.Name,
							Amount,
							CurrencyIsoCode,
							Bill_To_Account__c,
							Bill_To_Account__r.Name,
							Bill_To_Account__r.Sales_Account__c,
							Bill_To_Account__r.Sales_Account__r.Account_External_Id__c,
							Bill_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Bill_To_Address__c,
							Bill_To_Address__r.Sales_Account__c,
							Bill_To_Address__r.Sales_Account__r.Account_External_Id__c,
							Bill_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Bill_To_Address__r.CDH_Party_Site_Number__c,
							Bill_To_Address__r.CDH_Party__c,
							Bill_To_Address__r.CDH_Party__r.Name,
							Bill_To_Contact__c,
							Bill_To_Contact__r.AccountId,
							Bill_To_Contact__r.Account.Account_External_Id__c,
							Bill_To_Contact__r.Account.CDH_Party_Name__r.Name,
							Bill_To_Contact__r.CDH_Party_Number__c,
							Bill_To_Sales_Account__c,
							Bill_To_Sales_Account__r.Account_External_Id__c,
							Bill_To_Sales_Account__r.CDH_Party_Name__r.Name,
							Entitle_To_Account__c,
							Entitle_To_Account__r.Name,
							Entitle_To_Account__r.Sales_Account__c,
							Entitle_To_Account__r.Sales_Account__r.Account_External_Id__c,
							Entitle_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Entitle_To_Address__c,
							Entitle_To_Address__r.Sales_Account__c,
							Entitle_To_Address__r.Sales_Account__r.Account_External_Id__c,
							Entitle_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Entitle_To_Address__r.CDH_Party_Site_Number__c,
							Entitle_To_Address__r.CDH_Party__c,
							Entitle_To_Address__r.CDH_Party__r.Name,
							Entitle_To_Contact__c,
							Entitle_To_Contact__r.AccountId,
							Entitle_To_Contact__r.Account.Account_External_Id__c,
							Entitle_To_Contact__r.Account.CDH_Party_Name__r.Name,
							Entitle_To_Contact__r.CDH_Party_Number__c,
							Entitle_To_Sales_Account__c,
							Entitle_To_Sales_Account__r.Account_External_Id__c,
							Entitle_To_Sales_Account__r.CDH_Party_Name__r.Name,
							Non_Entitled_Endco__r.CDH_Party_Name__r.Name,
							OpportunityNumber__c,
							OwnerId,
							Order_Status__c,
							Ship_To_Account__c,
							Ship_To_Account__r.Name,
							Ship_To_Account__r.Sales_Account__c,
							Ship_To_Account__r.Sales_Account__r.Account_External_Id__c,
							Ship_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Ship_To_Address__c,
							Ship_To_Address__r.Sales_Account__c,
							Ship_To_Address__r.Sales_Account__r.Account_External_Id__c,
							Ship_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Ship_To_Address__r.CDH_Party__c,
							Ship_To_Address__r.CDH_Party__r.Name,
							Ship_To_Address__r.CDH_Party_Site_Number__c,
							Ship_To_Contact__c,
							Ship_To_Contact__r.AccountId,
							Ship_To_Contact__r.Account.Account_External_Id__c,
							Ship_To_Contact__r.Account.CDH_Party_Name__r.Name,
							Ship_To_Contact__r.CDH_Party_Number__c,
							Ship_To_Sales_Account__c,
							Ship_To_Sales_Account__r.Account_External_Id__c,
							Ship_To_Sales_Account__r.CDH_Party_Name__r.Name,
							Sold_To_Account__c,
							Sold_To_Account__r.Name,
							Sold_To_Account__r.Sales_Account__c,
							Sold_To_Account__r.Sales_Account__r.Account_External_Id__c,
							Sold_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Sold_To_Address__c,
							Sold_To_Address__r.Sales_Account__c,
							Sold_To_Address__r.Sales_Account__r.Account_External_Id__c,
							Sold_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Sold_To_Address__r.CDH_Party__c,
							Sold_To_Address__r.CDH_Party_Site_Number__c,
							Sold_To_Address__r.CDH_Party__r.Name,
							Sold_To_Contact__c,
							Sold_To_Contact__r.AccountId,
							Sold_To_Contact__r.Account.Account_External_Id__c,
							Sold_To_Contact__r.Account.CDH_Party_Name__r.Name,
							Sold_To_Contact__r.CDH_Party_Number__c,
							Sold_To_Sales_Account__c,
							Sold_To_Sales_Account__r.Account_External_Id__c,
							Sold_To_Sales_Account__r.CDH_Party_Name__r.Name,
							( select id,
									Name,
									Partner__c,
									Partner__r.Account_External_Id__c,
									Partner__r.CDH_Party_Name__c,
									Partner__r.CDH_Party_Name__r.Name,
									RelationshipType__c 
								from OpportunityPartners2__r),
							( select id,
									Name,
									OpportunityId,
									Contract_Numbers__c,
									Install_Base_Number__c,
									ActualStartDate__c,
									ActualEndDate__c,
									Quantity,
									UnitPrice,
									Base_Price__c,
									Return_Reason_Code__c,
									PricebookEntryId,
									Entitle_To_Account__c,
									Entitle_To_Account__r.Name,
									Entitle_To_Account__r.Sales_Account__c,
									Entitle_To_Account__r.Sales_Account__r.Account_External_Id__c,
									Entitle_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
									Entitle_To_Address__c,
									Entitle_To_Address__r.CDH_Party__r.Name,
									Entitle_To_Address__r.CDH_Party_Site_Number__c,
									Entitle_To_Address__r.Sales_Account__c,
									Entitle_To_Address__r.Sales_Account__r.Account_External_Id__c,
									Entitle_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
									Entitle_To_Contact__c,
									Entitle_To_Contact__r.CDH_Party_Number__c,
									Entitle_To_Contact__r.AccountId,
									Entitle_To_Contact__r.Account.Account_External_Id__c,
									Entitle_To_Contact__r.Account.CDH_Party_Name__r.Name,
									Entitle_To_Sales_Account__c,
									Entitle_To_Sales_Account__r.Account_External_Id__c,
									Entitle_To_Sales_Account__r.CDH_Party_Name__r.Name
								from OpportunityLineItems)
						from Opportunity
						where Id in:directOpportunitiesIdSet or OpportunityNumber__c in : indirectOpportunityNumberSet]);
				}

				// querying all opportunity Line Item records.
				opportunityProductMap = new Map<Id,OpportunityLineItem>();
				set<Id> entitleToAccountId = new Set<Id>();
				for(opportunity  opp:opportunityDetailsMap.Values()){
					mapofOpportunityNumberAndOpportunityDetails.put(opp.OpportunityNumber__c,opp);
					if(opp.Entitle_To_Sales_Account__c!=Null){
						entitleToAccountId.add(opp.Entitle_To_Sales_Account__c);
					}
					for(OpportunityLineItem oppLI:opp.OpportunityLineItems){
						opportunityProductMap.put(oppLI.id,oppLI);
					}
				}
				if(! entitleToAccountId.isEmpty()) {
					System.debug('entitleToAccountId='+entitleToAccountId);
					for(Account account : [
						select Id, ( select Name from EBS_Account__r)
						from Account
						where Id in :entitleToAccountId ] )
					{
						Set<String> tempset = new Set<String>();
						for(EBS_Account__c ebsaccount :account.EBS_Account__r){
							tempset.add(ebsaccount.Name);
						}
						if(!tempset.isempty()){
							mapofEntitleAccountandSetOfEBSNumber.put(account.Id,tempset);
						}
					}
				}

				// wrap Classification record and related Name
				// for(Classification__c classifiyRec:[SELECT id,ReferenceKey__c,Name FROM Classification__c where ReferenceKey__c IN: classificationRelatedSet]){
				//	classifiyRecMap.put(classifiyRec.Name,classifiyRec.id); 
				// }


				//iterating on all opportunity staging records.
				for(Opportunity_Header_Staging__c directOpportunitystaging: listofstagingrecord){
					try {
						directOpportunitystaging.Error_Message__c = '';
						//indicate error if opportunity Id on Staging record does not match with any existing opportunity record`s Id.
						if(directOpportunitystaging.Order_Source__c == 'SFDC_Sales' &&
							!opportunityDetailsMap.containsKey(directOpportunitystaging.Opportunity_ID__c))
						{
							directOpportunitystaging.Status__c = 'Error';
							errorRecordCreation(directOpportunitystaging.Id , 'D0','The opportunity Id does not match with any opportunity','Opportunity_ID__c');
							//directOpportunitystaging.Error_Message__c = 'Error Code: D0 Error Message: The opportunity Id does not match with any opportunity';
							listOfStagingRecordToBeUpdated.add(directOpportunitystaging);
						}
						else if(directOpportunitystaging.Order_Source__c != 'SFDC_Sales' &&
							! mapofOpportunityNumberAndOpportunityDetails.containskey(directOpportunitystaging.Opportunity_Number__c))
						{
							directOpportunitystaging.Status__c = 'Error';
							errorRecordCreation(directOpportunitystaging.Id , 'I1','The opportunity number provided is not valid. Please verify the opportunity Number','Opportunity_Number__c');
							//directOpportunitystaging.Error_Message__c = 'Error Code: I1 Error Message: The opportunity number provided is not valid. Please verify the opportunity Number';
							listOfStagingRecordToBeUpdated.add(directOpportunitystaging);
						}
						// else start processing based on the status of the order on opportunity staging record.
						else{
						//for Direct scenarios check the not entitled endco 
							if(directOpportunitystaging.Non_Entitled_Endco__c ==null &&
								directOpportunitystaging.Opportunity_ID__c !=null && 
								directOpportunitystaging.Non_Entitled_Endco_CDH_Party_Number__c !=null && 
								directOpportunitystaging.Non_Entitled_Endco_CDH_Party_Number__c !=opportunityDetailsMap.get(directOpportunitystaging.Opportunity_ID__c).Non_Entitled_Endco__r.CDH_Party_Name__r.Name)
							{
								if(nonEcoAccountByCDHPartyName !=null &&
									nonEcoAccountByCDHPartyName.get(directOpportunitystaging.Non_Entitled_Endco_CDH_Party_Number__c) !=null &&
									nonEcoAccountByCDHPartyName.get(directOpportunitystaging.Non_Entitled_Endco_CDH_Party_Number__c).size() ==1)
								{
									directOpportunitystaging.Non_Entitled_Endco__c=nonEcoAccountByCDHPartyName.get(directOpportunitystaging.Non_Entitled_Endco_CDH_Party_Number__c)[0].id;
								}else if(directOpportunitystaging.Non_Entitled_Endco_CDH_Party_Number__c !=null){
									errorRecordCreation(directOpportunitystaging.Id , 'D29','Non Entitled Endco match failed. Please review and select the correct the Non Entitled Endco from the lookup field.','Non_Entitled_Endco_CDH_Party_Number__c'); 
								}
							}
							//for indirect scenaros check the not entitled endco
							if(directOpportunitystaging.Non_Entitled_Endco__c==null &&
								directOpportunitystaging.Opportunity_ID__c ==null &&
								directOpportunitystaging.Opportunity_Number__c !=null && 
								directOpportunitystaging.Non_Entitled_Endco_CDH_Party_Number__c !=null && 
								directOpportunitystaging.Non_Entitled_Endco_CDH_Party_Number__c !=mapofOpportunityNumberAndOpportunityDetails.get(directOpportunitystaging.Opportunity_Number__c).Non_Entitled_Endco__r.CDH_Party_Name__r.Name)
							{
								if(nonEcoAccountByCDHPartyName !=null &&
									nonEcoAccountByCDHPartyName.get(directOpportunitystaging.Non_Entitled_Endco_CDH_Party_Number__c) !=null &&
									nonEcoAccountByCDHPartyName.get(directOpportunitystaging.Non_Entitled_Endco_CDH_Party_Number__c).size() ==1)
								{
									directOpportunitystaging.Non_Entitled_Endco__c=nonEcoAccountByCDHPartyName.get(directOpportunitystaging.Non_Entitled_Endco_CDH_Party_Number__c)[0].id;
								}
								else if(directOpportunitystaging.Non_Entitled_Endco_CDH_Party_Number__c !=null){
									errorRecordCreation(directOpportunitystaging.Id , 'I30','Non Entitled Endco match failed. Please review and select the correct the Non Entitled Endco from the lookup field','Non_Entitled_Endco_CDH_Party_Number__c'); 
								}
							}
							//Below logic will execute when staging record will be created through interface and then matching logic will be executed.
							if(directOpportunitystaging.Status__c == NOT_PROCESSED || directOpportunitystaging.Status__c == READY_FOR_REPROCESSING){

								if(directOpportunitystaging.Order_Status__c =='BOOKED'){
									System.debug('stagingRecordsToMatch.put('+directOpportunitystaging.Id+','+directOpportunitystaging+')');
									stagingRecordsToMatch.put(directOpportunitystaging.Id,directOpportunitystaging);
								}
							}
						}
					}
					catch(Exception ex) {
						errorRecordCreationWithDetails(ex,directOpportunitystaging);
					}
				}
			}
			catch(Exception ex2) {
				for(Opportunity_Header_Staging__c headerStaging : listofstagingrecord) {
					if(! oppHeaderWithSystemErrorMap.containsKey(headerStaging.Id)) {
						oppHeaderWithSystemErrorMap.put(headerStaging.Id,headerStaging);
						headerStaging.Status__c = 'Error';
						errorRecordCreationWithDetails(ex2,headerStaging);
					}
				}
				listofstagingrecord.clear();
			}
		}

		/**
		 * Method to process Direct Opportunities.
		 * @param listofstagingrecord
		 */
		private void processDirectOpportunitiesPostmatch(List<Opportunity_Header_Staging__c> listofstagingrecord)
		{
			try {
				Savepoint savepoint = Database.setSavepoint();
				try {
					//iterating on all opportunity staging records.
					for(Opportunity_Header_Staging__c directOpportunitystaging: listofstagingrecord){
						try {
							directOpportunitystaging.Error_Message__c = '';
							//indicate error if opportunity Id on Staging record does not match with any existing opportunity record`s Id.
							//Below logic will execute when staging record will be created through interface and then matching logic will be executed.
							if(stagingRecordsToMatch.containsKey(directOpportunitystaging.Id)) {
								directBookedOpportunityValidation(directOpportunitystaging);
							}
							else if(directOpportunitystaging.Status__c == NOT_PROCESSED || directOpportunitystaging.Status__c == READY_FOR_REPROCESSING ){
								if(directOpportunitystaging.Order_Status__c =='CLOSED'){
									//Order Processing for Status Not Processed and Order Status CLOSED
									directClosedOpportunityValidation(directOpportunitystaging);
								}
								else if(directOpportunitystaging.Order_Status__c =='CANCELLED'){
									//Order Processing for Status Not Processed and Order Status CANCELLED
									directCancelledOpportunityValidation(directOpportunitystaging);
								}
								else if(directOpportunitystaging.Order_Status__c =='INVOICED'){
									//Order Processing for Status Not Processed and Order Status INVOICED
									directInvoicedOpportunityValidation(directOpportunitystaging);
								}
								else if(directOpportunitystaging.Order_Status__c =='ENTERED' && 
									directOpportunitystaging.Order_Source__c == 'SFDC_Sales' &&
									directOpportunitystaging.Opportunity_ID__c!=Null)
								{
									//Order Processing for Status Not Processed and Order Status ENTERED
									directEnteredOpportunityValidation(directOpportunitystaging);
								}
							}
						}
						catch(Exception ex) {
							errorRecordCreationWithDetails(ex,directOpportunitystaging);
						}
					}
					// Insert CDH Party Records.
					// if(listOfSystemExceptionalErrors.isempty()){

					if(!cDHPartyToInsertSet.isempty()){
						// upsert based on the external Id.
						database.upsert(new List<CDH_Party__c>(cDHPartyToInsertSet),CDH_Party__c.field.CDH_Party_Number_Ext__c,false);
						//insert(new List<CDH_Party__c>(cDHPartyToInsertSet));
						cDHPartyToInsertSet.clear();
					}
					database.upsert(accountToUpsertMap.values(),Account.field.Account_External_Id__c ,true);
					database.upsert(getUpsertContacts(contactToUpsertMap,accountToUpsertMap), Contact.Field.Contact_External_Id__c,true);
					database.upsert(getUpsertAddresses(addressToUpsertMap,accountToUpsertMap),Address__c.field.Address_External_Id__c,true);
					database.upsert(getUpsertEBSAccounts(ebsAccountToUpsertMap,accountToUpsertMap),EBS_Account__c.field.EBS_Account_External_Id__c,true);

					// Delete the List of Opportunity Products that do not Match the Opportunity Header related data
					if(!OppLineItemLstToDelete.isempty()) {
						database.delete(OppLineItemLstToDelete);
					}

					// invoke the method to update the opportunity records.
					if(!listOfDirectOpportunityToBeUpdated.isempty() && errorList.isempty()) {
						database.update(listOfDirectOpportunityToBeUpdated); 
					} 

					// invoke the method to update the opportunity staging records.
					if(!listOfStagingRecordToBeUpdated.isempty()) {
						updateLines(getLines(listOfStagingRecordToBeUpdated),true);
						updatePartners(true);
						//call the Method to update the related pending OHS
						listOfStagingRecordToBeUpdated.addAll(oSHRelatedHeaderStatusProcess(listOfStagingRecordToBeUpdated));
						updateStagingRecordForDirectOpportunity(listOfStagingRecordToBeUpdated); 
					}
					if(errorList.isempty()){
						// Insert the Order Tracking Records 
						if(!opportunityOrderTrackingRecList.isempty()){
							database.insert(opportunityOrderTrackingRecList,false);
						}
						// Delete the list of Opportunity Partners related
						if(!OppPartnerLstToDelete.isempty()) {
							database.delete(OppPartnerLstToDelete);
						}
						// Insert the list of new Opportunity Partners
						if(!OppPartnerLstToCreate.isempty()) {
							database.insert(OppPartnerLstToCreate);
						}

						// Insert the new and Update the Old Opportunity Related Line items
						if(!OppLineItemLstToUpsert.isempty()) {
							database.upsert(OppLineItemLstToUpsert);
						}
					}
					savepoint = null;
				}
				finally {
					accountToUpsertMap.clear();
					addressToUpsertMap.clear();
					contactToUpsertMap.clear();
					ebsAccountToUpsertMap.clear();
					partnersToUpdate.clear();
					if(savepoint != null) {
						Database.rollback(savepoint);
					}
				}
			}
			catch(Exception ex2) {
				for(Opportunity_Header_Staging__c headerStaging : listofstagingrecord) {
					if(! oppHeaderWithSystemErrorMap.containsKey(headerStaging.Id)) {
						oppHeaderWithSystemErrorMap.put(headerStaging.Id,headerStaging);
					}
					errorRecordCreationWithDetails(ex2,headerStaging);
					headerStaging.Status__c = 'Error';
				}
			}
		}

		/**
		 * method to process Invoiced status orders
		 * @param stagingrecord
		 */
		private void  directInvoicedOpportunityValidation(Opportunity_Header_Staging__c stagingrecord)
		{
			// Update the status and error message on staging record.
			stagingrecord.Status__c = 'Processed';
			stagingrecord.Error_Message__c = '';
			listOfStagingRecordToBeUpdated.add(stagingrecord);
			directOpportunityUpdate(stagingrecord); 
		}


		/** 
		 * method to process Cancelled status orders.
		 * @param stagingrecord
		 */
		private void  directCancelledOpportunityValidation(Opportunity_Header_Staging__c stagingrecord)
		{
			// Update the status and error message on staging record.
			stagingrecord.Status__c = 'Processed';
			stagingrecord.Error_Message__c = '';
			listOfStagingRecordToBeUpdated.add(stagingrecord);
			directOpportunityUpdate(stagingrecord);
		}

		/** 
		 * method to process Closed status orders.
		 * @param stagingRecord
		 */
		private void  directClosedOpportunityValidation(Opportunity_Header_Staging__c stagingrecord)
		{
			stagingrecord.Status__c = 'Processed';
			stagingrecord.Error_Message__c = '';
			listOfStagingRecordToBeUpdated.add(stagingrecord);
			directOpportunityUpdate(stagingrecord);
		}

		/** 
		 * method to process ENTERED status orders.
		 * @param stagingrecord
		 */
		private void  directEnteredOpportunityValidation(Opportunity_Header_Staging__c stagingrecord)
		{
			stagingrecord.Error_Message__c = '';
			// validation to check if opportunity is already  associated with some order.
			if(opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c).OracleOrderNumber__c != Null && stagingrecord.Status__c == NOT_PROCESSED){
				errorRecordCreation(stagingrecord.Id , 'D1','The opportunity listed is currently tied to an existing Order Number.Please review and provide the correct Opportunity Number for this current order','Not Applicable');
				//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D1 Error Message: The opportunity listed is currently tied to an existing Order Number.Please review and provide the correct Opportunity Number for this current order'+'\n';
			}
			// validation to check if opportunity record type is excluded from matching 
			if(excludedRecordTypeIds.contains(opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c).RecordTypeId) && stagingrecord.Status__c == NOT_PROCESSED){
				errorRecordCreation(stagingrecord.Id , 'D2','Opportunity Number relates to an Opportunity type that cannot be associated directly with an Order.Please review the Opportunity Number and update the order record with the correct value.','Not Applicable');
				// stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D2 Error Message: Opportunity Number relates to an Opportunity type that cannot be associated directly with an Order.Please review the Opportunity Number and update the order record with the correct value.'+'\n';
			}
			// validation to check if opportunity Stage is excluded from matching 
			if(ExcludedOpportunityStageSet.contains(opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c).StageName) && (stagingrecord.Status__c == NOT_PROCESSED || stagingrecord.Status__c == READY_FOR_REPROCESSING)){
				errorRecordCreation(stagingrecord.Id , 'D3','This opportunity is in the Closed Booked stage.  No Closed Booked opportunities should exist without an order number already associated.  Please review the Opportunity Number and update the order record with the correct value','Not Applicable');
				//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D3 Error Message: This opportunity is in the Closed Booked stage.  No Closed Booked opportunities should exist without an order number already associated.  Please review the Opportunity Number and update the order record with the correct value'+'\n';
			}

			// update the status on staging records.
			stagingrecord.Status__c = (errorList.isempty()) ? 'Processed' : 'Error';

			// add the staging record in one list.
			listOfStagingRecordToBeUpdated.add(stagingrecord);

			// if no validation occurs then update the opportunity information as well.
			if(errorList.isempty()){

				directOpportunityUpdate(stagingrecord); 
			}
		}

		/**
		 * method to process Booked status orders.
		 * @param stagingrecord Opportunity staging record having order status "BOOKED".
		 */
		private void  directBookedOpportunityValidation(Opportunity_Header_Staging__c stagingrecord) {
			stagingrecord.Error_Message__c = '';
			//set the upper boundary of amount
			//set the lower boundary of amount.
			//log the error if order amount is not in tolerance amount.
			Opportunity matchedOpportunityrecord = new Opportunity();
			if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=Null) {
				matchedOpportunityrecord = opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c);
			}
			else if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c!=Null)
			{
				matchedOpportunityrecord = mapofOpportunityNumberAndOpportunityDetails.get(stagingrecord.Opportunity_Number__c);
				if((matchedOpportunityrecord.OracleOrderNumber__c != Null || 
					matchedOpportunityrecord.OracleOrderID__c!=Null) && 
					stagingrecord.Status__c == NOT_PROCESSED)
				{
					string errorRecInfo;
					if(matchedOpportunityrecord.OracleOrderNumber__c !=null){
						errorRecInfo='(Order Number#'+matchedOpportunityrecord.OracleOrderNumber__c+').';
					}else{
						errorRecInfo='(Order id #'+matchedOpportunityrecord.OracleOrderID__c+').';
					}		   
					errorRecordCreation(stagingrecord.Id , ' I2','The opportunity listed is currently tied to an existing Order Number.  Please review and provide the correct Opportunity Number for this current order'+errorRecInfo,'Not Applicable');
					//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I2 Error Message: The opportunity listed is currently tied to an existing Order Number.  Please review and provide the correct Opportunity Number for this current order.'+'\n';

				}
				if(excludedRecordTypeIds.contains(matchedOpportunityrecord.RecordTypeId) && stagingrecord.Status__c == NOT_PROCESSED ){
					errorRecordCreation(stagingrecord.Id , 'I3','Opportunity Number relates to an Opportunity type that cannot be associated directly with an Order.  Please review the Opportunity Number and update the order record with the correct ','Not Applicable');
					//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I3 Error Message: Opportunity Number relates to an Opportunity type that cannot be associated directly with an Order.  Please review the Opportunity Number and update the order record with the correct value.'+'\n';

				}

				if(ExcludedOpportunityStageSet.contains(matchedOpportunityrecord.StageName) && (stagingrecord.Status__c == NOT_PROCESSED || stagingrecord.Status__c == READY_FOR_REPROCESSING)){
					errorRecordCreation(stagingrecord.Id , 'I4','This opportunity is in the Closed Booked stage.  No Closed Booked opportunities should exist without an order number already associated.  Please review the Opportunity Number and update the order record with the correct value','Not Applicable');
					//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I4 Error Message: This opportunity is in the Closed Booked stage.  No Closed Booked opportunities should exist without an order number already associated.  Please review the Opportunity Number and update the order record with the correct value'+'\n';
				} 
				if(stagingrecord.Status__c == NOT_PROCESSED &&
				stagingrecord.Entitle_To_Account_Number__c!=Null &&
				matchedOpportunityrecord.Entitle_To_Sales_Account__c!=Null &&
				mapofEntitleAccountandSetOfEBSNumber.get(matchedOpportunityrecord.Entitle_To_Sales_Account__c)!=Null &&
				!((mapofEntitleAccountandSetOfEBSNumber.get(matchedOpportunityrecord.Entitle_To_Sales_Account__c)).contains(stagingrecord.Entitle_To_Account_Number__c))){

					errorRecordCreation(stagingrecord.Id , 'I5',' Entitle To customer on the Order does not match the Entitle To customer on the provided Opportunity.  Please review the Opportunity Number and update the order record with the correct value','Entitle_To_Account_Number__c');
					//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I5 Error Message: Entitle To customer on the Order does not match the Entitle To customer on the provided Opportunity.  Please review the Opportunity Number and update the order record with the correct value'+'\n';

				}
			}
			if(matchedOpportunityrecord.Amount!= Null &&
				matchedOpportunityrecord.Amount >0 && stagingrecord.Status__c == NOT_PROCESSED)
			{
				Decimal tolerancePercentage = (amountTolerance)/100;
				Decimal upperBoundary = ((matchedOpportunityrecord.Amount)) + ((matchedOpportunityrecord.Amount))*tolerancePercentage;
				Decimal lowerBoundary = ((matchedOpportunityrecord.Amount)) - ((matchedOpportunityrecord.Amount))*tolerancePercentage;
				String errorcode = stagingrecord.Order_Source__c == 'SFDC_Sales' ? 'D4':'I6';
				if(!(stagingrecord.Amount__c <= upperBoundary && stagingrecord.Amount__c >= lowerBoundary) && stagingrecord.Order_Source__c == 'SFDC_Sales'){
					errorRecordCreation(stagingrecord.Id ,'D4','The total value of the order is greater/less than'+amountTolerance+'% different than the total value of the Opportunity. Please review the Order and Opportunity to ensure they should be related.','Amount__c');
					//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D4 Error Message: The total value of the order is greater/less than'+amountTolerance+'% different than the total value of the Opportunity. Please review the Order and Opportunity to ensure they should be related.'+'\n';
				}
				if(!(stagingrecord.Amount__c <= upperBoundary && stagingrecord.Amount__c >= lowerBoundary) && stagingrecord.Order_Source__c != 'SFDC_Sales'){
					errorRecordCreation(stagingrecord.Id ,'I6','The total value of the order is greater/less than'+amountTolerance+'% different than the total value of the Opportunity. Please review the Order and Opportunity to ensure they should be related.','Amount__c');
					//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I6 Error Message: The total value of the order is greater/less than'+amountTolerance+'% different than the total value of the Opportunity. Please review the Order and Opportunity to ensure they should be related.'+'\n';
				}

			}
			//invoke method to validate Bill To Information
			stagingrecord = validateHeaderInformation('Bill',stagingrecord); 

			//invoke method to validate Ship To Information
			stagingrecord = validateHeaderInformation('Ship',stagingrecord);

			//invoke method to validate Sold To Information
			stagingrecord = validateHeaderInformation('Sold',stagingrecord);

			//invoke method to validate Entitle To Information
			stagingrecord = validateHeaderInformation('Entitle',stagingrecord);

			System.debug('Opportunity Line item processing Starts here=============================================>'+stagingrecord.Opportunities_Line_Staging__r.size());
			// Logic for the Opportunity Line Item validation.
			if(! stagingrecord.Opportunities_Line_Staging__r.isEmpty() ){
				stagingrecord=opportunitystagingLineItemProcess(stagingrecord.Opportunities_Line_Staging__r,stagingrecord,'I');
			}
			if(stagingrecord != null) {
				// Logic for the Opportunity Partner validation.
				Map<string,string> cdhTransitionTypemap  = new map<string,string>();
				if(matchedOpportunityrecord!=null && matchedOpportunityrecord.OpportunityPartners2__r.size()!=null){
					for(OpportunityPartner__c oP:matchedOpportunityrecord.OpportunityPartners2__r){
						if(oP.RelationshipType__c=='Financial' || oP.RelationshipType__c=='FINANCIAL'){
							cdhTransitionTypemap.put(oP.Partner__r.CDH_Party_Name__r.Name,oP.RelationshipType__c);
						}
					}
				}
				if(! stagingrecord.Opportunities_Partner_Staging__r.isEmpty()){
					stagingrecord=opprtunityPartnerItemProcess(stagingrecord.Opportunities_Partner_Staging__r,stagingrecord,'I',cdhTransitionTypemap);
				}
				else if(cdhTransitionTypemap.size()>0 && stagingrecord.Opportunity_ID__c !=null && stagingrecord.Opportunity_ID__c !='' && stagingrecord.Status__c == NOT_PROCESSED){
					//In case a financial record exists in Opportunity map and list of Opp header staging is empty then log a error
					List<String> e = System.Label.C360_D28.split(':\\s*',2);
					e.add(e[0]);
					errorRecordCreation(stagingrecord.Id,e[0],e[1],'Not Applicable'); 
				}

				if(stagingrecord != null) {
					// add the staging record in one list.
					stagingrecord.Status__c = (errorList.isempty()) ? 'Processed' : 'Error';
					listOfStagingRecordToBeUpdated.add(stagingrecord);

					// if no validation occurs then update the opportunity information as well.
					if(errorList.isempty()){
						directOpportunityUpdate(stagingrecord);
					}
				}
			}
		}

		private Opportunity_Header_Staging__c validateHeaderInformation(String Type , Opportunity_Header_Staging__c stagingrecord)
		{
			// Bill to Information and validation:
			string accPreviousValue=string.valueof(stagingrecord.get(Type+'_To_Account__c'));
			//Incase New Records are created this list will be update with the error list
//depreciated			List<Match_and_Validation_Error__c> errorListNew = new List<Match_and_Validation_Error__c>();
//depreciated			errorListNew.addAll(errorList);
			Opportunity opportunityrecord = new Opportunity();
			if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c != Null){
				opportunityrecord = opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c);
			}
			else if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c != Null){
				opportunityrecord = mapofOpportunityNumberAndOpportunityDetails.get(stagingrecord.Opportunity_Number__c);
			}
			Id stagingEBSAccountId = (Id)stagingrecord.get(Type+'_To_Account__c');
			EBS_Account__c stagingEBSAccount = (EBS_Account__c)stagingrecord.getsobject(Type+'_To_Account__r');
			if(stagingEBSAccountId == null) {
				stagingrecord.putsobject(Type+'_To_Account__r',null);
			}
			Id stagingAddressId = (Id)stagingrecord.get(Type+'_To_Address__c');
			Address__c stagingAddress = (Address__c)stagingrecord.getsobject(Type+'_To_Address__r');
			if(stagingAddressId == null) {
				stagingrecord.putsobject(Type+'_To_Address__r',null);
			}
			Id stagingContactId = (Id)stagingrecord.get(Type+'_To_Contact__c');
			Contact stagingContact = (Contact)stagingrecord.getsobject(Type+'_To_Contact__r');
			if(stagingContactId == null) {
				stagingrecord.putsobject(Type+'_To_Contact__r',null);
			}
			Id salesAccountOfAccount = null;
			Id salesAccountOfAddress = null;
			Id salesAccountOfContact = null;
			if(stagingEBSAccountId != null && stagingEBSAccount != null) {
				salesAccountOfAccount = stagingEBSAccount.Sales_Account__c;
			}
			if(stagingAddressId != null && stagingAddress != null) {
				salesAccountOfAddress = stagingAddress.Sales_Account__c;
			}
			if(stagingContactId != null && stagingContact != null) {
				salesAccountOfContact = stagingContact.AccountId;
			}
//depreciated			EBS_Account__c oppEBSAccount = null;
//depreciated			Address__c oppAddress = null;
//depreciated			Contact oppContact = null;
//depreciated			if(opportunityrecord != null) {
//depreciated				oppEBSAccount = (EBS_Account__c)opportunityrecord.get(Type+'_To_Account__r');
//deprecaited				oppAddress = (Address__c)opportunityrecord.get(Type+'_To_Address__r');
//deprecaited				oppContact = (Contact)opportunityrecord.get(Type+'_To_Contact__r');
//depreciated			}
//depreciated			// check if Bill to account number on staging record matched with Bill to account number on opportunity.
//depreciated			if( oppEBSAccount != Null
//depreciated				&& stagingrecord.get(Type+'_To_Account__c')== null
//depreciated				&& oppEBSAccount.Name == stagingrecord.get(Type+'_To_Account_Number__c') )
//depreciated			{

//depreciated				// if matched then populate the Bill to Account lookup with the value of Bill to Account in opportunity record.
//depreciated				stagingrecord.put(Type+'_To_Account__c',e.Id);
//depreciated				salesAccountOfAccount = oppEBSAccount.Sales_Account__c;
//depreciated			}
//depreciated			// if does not match query the ebs account based on the bill to account number in staging record.
//depreciated			// to do : remove this query and create the map at initial stage.
//depreciated			else{
//depreciated			System.debug('==================================================================Direct And Indirect With Opp Number Logic ===============>'+stagingrecord.get(Type+'_To_Account__c'));
//depreciated				if(stagingrecord.get(Type+'_To_Account__c')== Null &&
//depreciated				stagingrecord.get(Type+'_To_Account_Number__c')!=Null &&
//depreciated				eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof((stagingrecord.get(Type+'_To_Account_Number__c'))))!=Null &&
//depreciated				eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof((stagingrecord.get(Type+'_To_Account_Number__c')))).size() ==1){

//depreciated					stagingrecord.put(Type+'_To_Account__c', eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof((stagingrecord.get(Type+'_To_Account_Number__c'))))[0].id);
//depreciated					salesAccountOfAccount = eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof((stagingrecord.get(Type+'_To_Account_Number__c'))))[0].Sales_Account__c;
//depreciated				}
//depreciated				if(stagingrecord.get(Type+'_To_Account__c')== Null &&
//depreciated				stagingrecord.get(Type+'_To_Account_Number__c')!=Null &&
//depreciated				(eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof(stagingrecord.get(Type+'_To_Account_Number__c')))==Null || 
//depreciated				eBSAccountNumberAndListOfEBSAccountMap.get(String.valueof(stagingrecord.get(Type+'_To_Account_Number__c'))).size()>1)){

//depreciated					if(stagingrecord.Order_Source__c == 'SFDC_Sales'){

//depreciated						errorRecordCreation(stagingrecord.Id , 'D'+String.valueof(5+4*matchTypeAndErrorCodeMap.get(Type)),Type+'-To Account number match failed. Please review and select the correct '+Type+'-To Account Number from the lookup field.',Type+'_To_Account_Number__c');
//depreciated						//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D'+String.valueof(5+4*matchTypeAndErrorCodeMap.get(Type))+' Error Message: '+Type+'-To Account number match failed. Please review and select the correct '+Type+'-To Account Number from the lookup field.'+'\n';
//depreciated					}
//depreciated					else if(stagingrecord.Order_Source__c != 'SFDC_Sales'){

//depreciated						errorRecordCreation(stagingrecord.Id , 'I'+String.valueof(7+4*matchTypeAndErrorCodeMap.get(Type)),Type+'-To Account number match failed. Please review and select the correct '+Type+'-To Account Number from the lookup field.',Type+'_To_Account_Number__c');
//depreciated						//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I'+String.valueof(7+4*matchTypeAndErrorCodeMap.get(Type))+' Error Message: '+Type+'-To Account number match failed. Please review and select the correct '+Type+'-To Account Number from the lookup field.'+'\n';
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			// Compare Bill To CDH Party Site Number logic

//depreciated			if( oppAddress != Null 
//depreciated				&& stagingrecord.get(Type+'_To_Address__c')== Null &&
//depreciated				&& oppAddress.CDH_Party_Site_Number__c != Null
//depreciated				&& oppAddress.CDH_Party_Site_Number__c == stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c'))
//depreciated			{
//depreciated				// if matched populate the Bill to address lookup with the value of Bill To Address on Opportunity.
//depreciated				stagingrecord.put(Type+'_To_Address__c', opportunityrecord.get(Type+'_To_Address__c'));
//depreciated				salesAccountOfAddress = oppAddress.Sales_Account__c;
//depreciated			}
//depreciated			else {
//depreciated				// if does not match query the address records based on the Bill_To_Address_CDH_Party_Site_Number__c of staging record.
//depreciated				if(stagingrecord.get(Type+'_To_Address__c')==Null &&
//depreciated					stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c')!= Null &&
//depreciated					cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c')))!= Null && 
//depreciated					cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c'))).size()==1)
//depreciated				{
//depreciated					stagingrecord.put(Type+'_To_Address__c', (cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c')))[0].Id));
//depreciated					salesAccountOfAddress = (cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c')))[0].Sales_Account__c);
//depreciated				}
//depreciated				if(stagingrecord.get(Type+'_To_Address__c')==Null &&
//depreciated					stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c')!=Null &&
//depreciated					(cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c'))) == Null || 
//depreciated					cDHPartySiteNumberAndListOfAddressMap.get(String.valueof(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c'))).size()>1))
//depreciated				{
//depreciated					if(stagingrecord.Order_Source__c == 'SFDC_Sales'){
//depreciated						errorRecordCreation(stagingrecord.Id , 'D'+String.valueof(6+4*matchTypeAndErrorCodeMap.get(Type)),Type+'-To Address match failed.Please review and select the correct '+Type+'-To Address from the lookup field.',Type+'_To_Address_CDH_Party_Site_Number__c');
//depreciated						//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D'+String.valueof(6+4*matchTypeAndErrorCodeMap.get(Type))+' Error Message: '+Type+'-To Address match failed.Please review and select the correct '+Type+'-To Address from the lookup field.'+'\n';
//depreciated					}
//depreciated					else if(stagingrecord.Order_Source__c != 'SFDC_Sales'){
//depreciated						errorRecordCreation(stagingrecord.Id , 'I'+String.valueof(8+4*matchTypeAndErrorCodeMap.get(Type)),Type+'-To Address match failed.Please review and select the correct '+Type+'-To Address from the lookup field.',Type+'_To_Address_CDH_Party_Site_Number__c');
//depreciated						//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I'+String.valueof(8+4*matchTypeAndErrorCodeMap.get(Type))+' Error Message: '+Type+'-To Address match failed.Please review and select the correct '+Type+'-To Address from the lookup field.'+'\n';
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			if(stagingrecord.get(Type+'_To_Contact__c')==Null &&
//depreciated				stagingrecord.get(Type+'_To_CDH_Party_Number__c')!=Null &&
//depreciated				(cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c')))== Null || 
//depreciated				cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c'))).size()>1))
//depreciated			{
//depreciated				if(stagingrecord.Order_Source__c == 'SFDC_Sales'){
//depreciated					errorRecordCreation(stagingrecord.Id , 'D'+String.valueof(7+4*matchTypeAndErrorCodeMap.get(Type)),Type+'-To Contact match failed.Please review and select the correct '+Type+'-To Contact from the lookup field.',Type+'_To_CDH_Party_Number__c');
//depreciated					//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D'+String.valueof(7+4*matchTypeAndErrorCodeMap.get(Type))+' Error Message: '+Type+'-To Contact match failed.Please review and select the correct '+Type+'-To Contact from the lookup field.'+'\n';
//depreciated				}
//depreciated				else if(stagingrecord.Order_Source__c != 'SFDC_Sales'){
//depreciated					errorRecordCreation(stagingrecord.Id , 'I'+String.valueof(9+4*matchTypeAndErrorCodeMap.get(Type)),Type+'-To Contact match failed.Please review and select the correct '+Type+'-To Contact from the lookup field.',Type+'_To_CDH_Party_Number__c');
//depreciated					//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I'+String.valueof(9+4*matchTypeAndErrorCodeMap.get(Type))+' Error Message: '+Type+'-To Contact match failed.Please review and select the correct '+Type+'-To Contact from the lookup field.'+'\n';
//depreciated				}
//depreciated			}
//depreciated			// Compare Bill To CDH Person Party Number logic
//depreciated			if(stagingrecord.get(Type+'_To_Contact__c')==Null &&
//depreciated				opportunityrecord.get(Type+'_To_Contact__c') != Null &&
//depreciated				(opportunityrecord.getsobject(Type+'_To_Contact__r')).get('CDH_Party_Number__c')!= Null &&
//depreciated				(opportunityrecord.getsobject(Type+'_To_Contact__r')).get('CDH_Party_Number__c') == stagingrecord.get(Type+'_To_CDH_Party_Number__c'))
//depreciated			{
//depreciated				// if match found update Bill to CDH Person Part lookup with the value of Bill To Contact on Opportunity.
//depreciated				stagingrecord.put(Type+'_To_Contact__c',opportunityrecord.get(Type+'_To_Contact__c'));
//depreciated				salesAccoutofContact = String.valueof((opportunityrecord.getsobject(Type+'_To_Contact__r')).get('AccountId'));
//depreciated			}
//depreciated			else {
//depreciated				// query contact records
//depreciated				if(stagingrecord.get(Type+'_To_Contact__c')==Null &&
//depreciated					stagingrecord.get(Type+'_To_CDH_Party_Number__c')!= Null &&
//depreciated					(cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c')))!= Null &&
//depreciated					cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c'))).size()==1))
//depreciated				{
//depreciated					stagingrecord.put(Type+'_To_Contact__c', cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c')))[0].Id);
//depreciated					salesAccoutofContact = cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c')))[0].AccountId;
//depreciated				}
//			if(stagingContact == null) {

				// create contact record in case single record found for ebs account and address associated with same sales account.

				String contactCDHPartyNumber = String.valueOf(stagingrecord.get(Type+'_To_CDH_Party_Number__c'));
				if( contactCDHPartyNumber != Null
					&& stagingContact == Null // && cDHPartyNumberAndListOfContactMap.get(String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number__c')))== Null
					&& stagingAddressId != Null
					&& stagingAddress != null
					&& stagingEBSAccountId  != Null 
					&& stagingEBSAccount != null
					&& stagingAddress.Sales_Account__c == stagingEBSAccount.Sales_Account__c )
				{
					//Clear the Old error list to remove error added due to improper CDH details
//depreciated					errorList.clear();
//depreciated					errorList.addAll(errorListNew);

					// first create CDH Party record.
					CDH_Party__c cdhParty = createCDHPersonParty(stagingrecord,Type,'PERSON');

					//Changed by Niti : Add CDH party instance into the set only if it does not exist already.
					if(checkCDHinSet(cDHPartyToInsertSet ,contactCDHPartyNumber ))
					{
						cDHPartyToInsertSet.add(cdhParty );
					}

					// create contact record.
					Contact contact = addContactToUpsert(createContact( stagingrecord, Type, new Account(Id=stagingEBSAccount.Sales_Account__c) ));
					stagingrecord.putsobject(Type+'_To_Contact__r' , contact );
				}
//			}

			// if bill to address , bill to ebs account and bill to contact are not related to same sales account show the error message.

			boolean isValidSalesAccHeader=true;
			if(( salesAccountOfAccount != null &&  salesAccountOfAddress !=null &&(salesAccountOfAccount != salesAccountOfAddress)) ||
				( salesAccountOfAccount != null &&  salesAccountofContact !=null &&(salesAccountOfAccount != salesAccountofContact)) ||
				( salesAccountOfAddress != null &&  salesAccountofContact !=null &&(salesAccountOfAddress != salesAccountofContact)))
			{
				isValidSalesAccHeader=false;
			}
			if(isValidSalesAccHeader) {
				if(salesAccountOfAccount !=null){
					stagingrecord.put(Type+'_To_Sales_Account__c',salesAccountOfAccount);
				}else if(salesAccountofContact !=null){
					stagingrecord.put(Type+'_To_Sales_Account__c',salesAccountofContact);
				}else if(salesAccountOfAddress !=null){
					stagingrecord.put(Type+'_To_Sales_Account__c',salesAccountOfAddress);
				}
			}
//depreciated			else {
//depreciated				if(stagingrecord.Order_Source__c == 'SFDC_Sales') {
//depreciated					errorRecordCreation(stagingrecord.Id , 'D'+String.valueof(8+4*matchTypeAndErrorCodeMap.get(Type)),Type+'-To Account,'+Type+'-To Address and '+Type+'-To Contact is not associated with the same Sales Account .Please review and correct the '+Type+'-To information.',Type+'_To_Sales_Account__c');
//depreciated					//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D'+String.valueof(8+4*matchTypeAndErrorCodeMap.get(Type))+' Error Message: '+Type+'-To Account, '+Type+'-To Address and '+Type+'-To Contact is not associated with the same Sales Account .Please review and correct the '+Type+'-To information.'+'\n';
//depreciated				}
//depreciated				else if(stagingrecord.Order_Source__c != 'SFDC_Sales') {
//depreciated					errorRecordCreation(stagingrecord.Id , 'I'+String.valueof(10+4*matchTypeAndErrorCodeMap.get(Type)),Type+'-To Account,'+Type+'-To Address and '+Type+'-To Contact is not associated with the same Sales Account .Please review and correct the '+Type+'-To information.',Type+'_To_Sales_Account__c');
//depreciated					//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I'+String.valueof(10+4*matchTypeAndErrorCodeMap.get(Type))+' Error Message: '+Type+'-To Account, '+Type+'-To Address and '+Type+'-To Contact is not associated with the same Sales Account .Please review and correct the '+Type+'-To information.'+'\n';
//depreciated				}
//depreciated			}

			String oracleAccountNumber = String.valueOf(stagingrecord.get(Type+'_To_Account_Number__c'));
			String cdhPartySiteNumber = String.valueOf(stagingrecord.get(Type+'_To_Address_CDH_Party_Site_Number__c'));
			if(stagingEBSAccountId == Null &&
				stagingAddressId ==  Null &&
				stagingContactId == Null &&
				oracleAccountNumber != Null &&
				cdhPartySiteNumber!= Null &&
				contactCDHPartyNumber != Null &&
				stagingEBSAccount == Null &&
				stagingAddress == Null &&
				stagingContact == Null && 
				stagingrecord.get(Type+'_To_Party_Type__c')=='PERSON')
			{
				String accountCDHPartyNumber = String.valueof(stagingrecord.get(Type+'_To_CDH_Party_Number_Account__c'));
				//Clear the Old error list to remove error added due to improper CDH details
//depreciated				errorList.clear();
//depreciated				errorList.addAll(errorListNew);
				// create CDH Party record for salesaccount.
				CDH_Party__c cdhParty = createCDHAccountParty(stagingrecord,Type);

				//Changed by Niti : Add CDH party instance into the set only if it does not exist already.
				if(checkCDHinSet(cDHPartyToInsertSet ,accountCDHPartyNumber ))
				{
					 cDHPartyToInsertSet.add(cdhParty);
				}

				// create sales account record.
				Account account = addAccountToUpsert(createAccount(stagingrecord,Type));

				// create EBS Account.
				EBS_Account__c ebsAccount = addEBSAccountToUpsert(createEBSAccount(stagingrecord,Type,account));

				// create address record.
				Address__c address = addAddressToUpsert(createAddress(stagingrecord,Type,account));

				// create cdh party records.
				CDH_Party__c cdhPersonParty = createCDHPersonParty(stagingrecord,Type, null);

				//Changed by Niti : Add CDH party instance into the set only if it does not exist already.
				if(checkCDHinSet(cDHPartyToInsertSet ,contactCDHPartyNumber ))
				{
					cDHPartyToInsertSet.add(cdhPersonParty);
				}

				//create contact record.
				Contact contact = addContactToUpsert(createContact( stagingrecord, Type, account ));

				// associate these created records to staging record.
				stagingrecord.putsobject(Type+'_To_Contact__r' , contact );
				stagingrecord.putsobject(Type+'_To_Sales_Account__r', account );
				stagingrecord.putsobject(Type+'_To_Address__r', address );
				stagingrecord.putsobject(Type+'_To_Account__r', ebsAccount );
			}
			return stagingrecord;
		}

		//Method to update the status and error message on opportunity staging records.
		private void updateStagingRecordForDirectOpportunity(List<Opportunity_Header_Staging__c> listofStagingRecords)
		{
			map<id,Opportunity_Header_Staging__c> oppHeaderMap= new map<id,Opportunity_Header_Staging__c>();
			for(Opportunity_Header_Staging__c oppHeader:listofStagingRecords){
				oppHeaderMap.put(oppHeader.id,oppHeader);
			}
			// perform the update operations
			system.debug('==================================================================>'+listofStagingRecords);

			Database.SaveResult[] stagingRecordErrorUpdateResultList = updateHeaders(listofStagingRecords,false);

			// logic to store the system errors (if comes) during the updates of opportunity staging records.
			for(Database.SaveResult updateresult : stagingRecordErrorUpdateResultList ){
				String errormessage = null;
				if(!updateresult.isSuccess()) {
					system.debug('=================================================>'+updateresult);
					opportunity_header_staging__c oppHeadertoUpdate= oppHeaderMap.get(updateresult.getid());
					system.debug('=================================================>'+oppHeadertoUpdate);
					for(Database.Error errors : updateresult.getErrors()){
						errormessage = errormessage!=null? 'Error Occured while updating error on Staging Record :'+updateresult.getid()+' Error Description : '+errors .getMessage(): errormessage+'\n'+'Error Occured while updating error on Staging Record :'+updateresult.getid()+' Error Description : '+errors.getMessage();
					}
					errorRecordCreationWithDetails(errormessage,oppHeadertoUpdate,null);
				}
			}

		}

		/**
		 * Method to classify different type of opportunity staging and process the related opportunity with related data.
		 */
		private void directOpportunityUpdate(Opportunity_Header_Staging__c stagingrecord){

			//Changed as per User Story US63533 for defaulting opportunity owner by Sagar Mehta
			Id ownerId = stagingrecord.Opportunity_Owner__c;
			if(ownerId == null && stagingrecord.Sales_Account__c != null){
				ownerId = getAccountOwnerMap(new List<Opportunity_Header_Staging__c>{stagingrecord}).get(stagingrecord.Id);
			}
			Opportunity opp = new Opportunity();
			if(ownerId != null) {
				opp = new Opportunity(OwnerId=ownerId);
			}
			if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=Null) {
				opp=opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c);
			}
			else if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c!=Null){
				opp=mapofOpportunityNumberAndOpportunityDetails.get(stagingrecord.Opportunity_Number__c);
			}
			if(ownerId != null && stagingrecord.Order_Status__c != 'INVOICED' && stagingrecord.Order_Status__c != 'Cancelled') {
				//Changed as per User Story US63533 by Sagar Mehta
				opp.OwnerID = ownerId;
			}

			if(stagingrecord.Order_Status__c=='Closed'){
				if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=Null){
					//Opportunity opp=opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c);
					opportunityStatusClosed(opp);
				}
				else if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c!=Null){
					//Opportunity opp=mapofOpportunityNumberAndOpportunityDetails.get(stagingrecord.Opportunity_Number__c);
					opportunityStatusClosed(opp);
				}
			}
			else if(stagingrecord.Order_Status__c=='Invoiced'){
				if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=Null){
					//Opportunity opp=opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c);
					opportunityStatusInvoiced(Opp);
				}
				else if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c!=Null){
					//Opportunity opp=mapofOpportunityNumberAndOpportunityDetails.get(stagingrecord.Opportunity_Number__c);
					opportunityStatusInvoiced(opp);
				}

			}
			else if(stagingrecord.Order_Status__c=='Cancelled'){
				if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=Null) {
					//Opportunity opp=opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c);
					opportunityStatusCancelled(Opp);
				}
				else if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c!=Null){
					//Opportunity opp=mapofOpportunityNumberAndOpportunityDetails.get(stagingrecord.Opportunity_Number__c);
					opportunityStatusCancelled(opp);
				}
			}
			else if(stagingrecord.Order_Status__c=='Entered'){
				if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=Null) {
					//Opportunity opp=opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c);
					opportunityStatusEntered(opp,stagingrecord);
				}
			}
			else if(stagingrecord.Order_Status__c=='BOOKED'){
				boolean currencyChange=false;
				if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=Null) {

					if(opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c).CurrencyIsoCode != stagingrecord.CurrencyIsoCode){
						currencyChange=true;
					}
					//opportunityStatusBooked(opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c),stagingrecord);
					//opportunityProductMatching(opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c),stagingrecord,currencyChange);
					//opportunityPartnerCreation(opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c),stagingrecord);
					opportunityStatusBooked(opp,stagingrecord);
					opportunityProductMatching(opp,stagingrecord,currencyChange);
					opportunityPartnerCreation(opp,stagingrecord);
				}
				else if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c!=Null){
					if(mapofOpportunityNumberAndOpportunityDetails.get(stagingrecord.Opportunity_Number__c).CurrencyIsoCode != stagingrecord.CurrencyIsoCode){
						currencyChange=true;
					}
					//opportunityStatusBooked(mapofOpportunityNumberAndOpportunityDetails.get(stagingrecord.Opportunity_Number__c),stagingrecord);
					//opportunityProductMatching(mapofOpportunityNumberAndOpportunityDetails.get(stagingrecord.Opportunity_Number__c),stagingrecord,currencyChange);
					//opportunityPartnerCreation(mapofOpportunityNumberAndOpportunityDetails.get(stagingrecord.Opportunity_Number__c),stagingrecord);
					opportunityStatusBooked(opp,stagingrecord);
					opportunityProductMatching(opp,stagingrecord,currencyChange);
					opportunityPartnerCreation(opp,stagingrecord);
				}
			}
			// send details to order Tracking record creation process.
			opportunityOrderTracking(stagingrecord);

		}

		/**
		 * Update Opportunity_Matching logic to update the matching opportunity where order Status is "Closed"
		 */
		private void opportunityStatusClosed(Opportunity oppToprocess){

			oppToprocess.Order_Status__c='Closed';
			listOfDirectOpportunityToBeUpdated.add(oppToprocess);
		}

		/**
		 * Update Opportunity_Matching logic to update the matching opportunity where order Status is "Invoiced"
		 */
		private void opportunityStatusInvoiced(Opportunity oppToprocess){

			oppToprocess.Order_Status__c='Invoiced';
			listOfDirectOpportunityToBeUpdated.add(oppToprocess);
		}
		
		/**
		 * Update Opportunity_Matching logic to update the matching opportunity where order Status is "Cancelled"
		 */
		private void opportunityStatusCancelled(Opportunity oppToprocess){

			oppToprocess.Order_Status__c='Cancelled';
			listOfDirectOpportunityToBeUpdated.add(oppToprocess);
		}

		/**
		 * Update Opportunity_Matching logic to update the matching opportunity where order Status is "Entered", UPdate the Field Order ID and Opportunity ID
		 */
		private void opportunityStatusEntered(Opportunity oppToprocess,Opportunity_Header_Staging__c stagingrecord){

			oppToprocess.Order_Status__c='Entered';
			//oppToprocess.StageName='Closed Booked';
			oppToprocess.OracleOrderID__c=stagingrecord.Oracle_Order_ID__c;
			oppToprocess.OracleOrderNumber__c=stagingrecord.Oracle_Order_Number__c;
			listOfDirectOpportunityToBeUpdated.add(oppToprocess);
		}

		/**
		 * Update Opportunity_Matching logic to update the matching opportunity where order Status is "Booked"
		 */
		private void opportunityStatusBooked(Opportunity oppToprocess,Opportunity_Header_Staging__c OppHeaderStaging){
			system.debug('Booked Opportunity update process called=================================================>'+OppHeaderStaging.Non_Entitled_Endco__c);
			//system.debug('===date ordered==============================================>'+OppHeaderStaging.Date_Ordered__c);
			system.debug('===date booked==============================================>'+OppHeaderStaging.Date_Booked__c);
			//if(OppHeaderStaging.Date_Ordered__c !=null){
			if(OppHeaderStaging.Date_Booked__c !=null){//Changes for US68220
				//oppToprocess.CloseDate=OppHeaderStaging.Date_Ordered__c;
				oppToprocess.CloseDate=OppHeaderStaging.Date_Booked__c;//Changes for US68220
			}
			if(OppHeaderStaging.Order_Type__c !=null && OppHeaderStaging.Order_Type__c.contains('MULTI SHIP/ENTITLE')){
				oppToprocess.Pay_Now__c='No';
			}
			else{
				oppToprocess.Pay_Now__c='Yes';
			}
			oppToprocess.StageName='Closed Booked';
			oppToprocess.RecordTypeID=bookedInProcess;
			oppToprocess.Order_Status__c='BOOKED';
			oppToprocess.PONumber__c=OppHeaderStaging.PO_Number__c;
			oppToprocess.Reseller_PO__c=OppHeaderStaging.Resller_PO__c;
			oppToprocess.Operating_Unit__c=OppHeaderStaging.Operating_Unit__c;
			oppToprocess.Order_Type__c=OppHeaderStaging.Order_Type__c;
			if(OppHeaderStaging.Payment_Type__c ==Null || OppHeaderStaging.Payment_Type__c=='' || OppHeaderStaging.Payment_Type__c=='Check' || OppHeaderStaging.Payment_Type__c=='Cash'){
				oppToprocess.PaymentType__c='Purchase Order';
			}else if(OppHeaderStaging.Payment_Type__c =='Credit Card'){
				oppToprocess.PaymentType__c='Credit Card';
			}
			if(OppHeaderStaging.Order_Source__c!='SFDC_Sales' && OppHeaderStaging.Opportunity_Number__c!=Null){
				oppToprocess.OracleOrderID__c = OppHeaderStaging.Oracle_Order_ID__c;
				oppToprocess.OracleOrderNumber__c = OppHeaderStaging.Oracle_Order_Number__c;
//depreciated US72618 - Don't set touched
//depreciated				oppToprocess.Touched__c = True;
				oppToprocess.FulfillmentChannel__c = OppHeaderStaging.Channel__c;
			}
			oppToprocess.Bill_To_Sales_Account__c= OppHeaderStaging.Bill_To_Sales_Account__c;
			oppToprocess.Bill_To_Account__c=OppHeaderStaging.Bill_To_Account__c;
			oppToprocess.Bill_To_Address__c=OppHeaderStaging.Bill_To_Address__c;
			oppToprocess.Bill_To_Contact__c=OppHeaderStaging.Bill_To_Contact__c;

			oppToprocess.Ship_To_Sales_Account__c=OppHeaderStaging.Ship_To_Sales_Account__c;
			oppToprocess.Ship_To_Account__c=OppHeaderStaging.ship_To_Account__c;
			oppToprocess.Ship_To_Address__c=OppHeaderStaging.Ship_To_Address__c;
			oppToprocess.Ship_To_Contact__c=OppHeaderStaging.Ship_To_Contact__c;

			oppToprocess.Sold_To_Sales_Account__c=OppHeaderStaging.Sold_To_Sales_Account__c;
			oppToprocess.Sold_To_Account__c=OppHeaderStaging.sold_To_Account__c;
			oppToprocess.Sold_To_Address__c=OppHeaderStaging.Sold_To_Address__c;
			oppToprocess.Sold_To_Contact__c=OppHeaderStaging.sold_To_Contact__c;

			oppToprocess.Entitle_To_Sales_Account__c=OppHeaderStaging.Entitle_To_Sales_Account__c;
			oppToprocess.Entitle_To_Account__c=OppHeaderStaging.Entitle_To_Account__c;
			oppToprocess.Entitle_To_Address__c=OppHeaderStaging.Entitle_To_Address__c;
			oppToprocess.Entitle_To_Contact__c=OppHeaderStaging.Entitle_To_Contact__c;
			system.debug('=================================Caling Opp currency change code================================>'+OppHeaderStaging.CurrencyIsoCode);
			oppToprocess.CurrencyIsoCode = OppHeaderStaging.CurrencyIsoCode;
			oppToprocess.Non_Entitled_Endco__c= OppHeaderStaging.Non_Entitled_Endco__c;
			listOfDirectOpportunityToBeUpdated.add(oppToprocess);
		}

		/** 
		 * verify the Product under Opportunity and Opportunity Header staging
		 */
		private void opportunityProductMatching(Opportunity oppToprocess,Opportunity_Header_Staging__c OppHeaderStaging,boolean currencyChange){
			set<id> oppLineUniqueID= new set<id>();
			map<string,Opportunity_Line_Staging__c> oppLineStageUniqueMap=  new map<string,Opportunity_Line_Staging__c>();
			for(Opportunity_Line_Staging__c oppLineStage:OppHeaderStaging.Opportunities_Line_Staging__r){
				oppLineStageUniqueMap.put(oppLineStage.Opportunity_Product_ID__c,oppLineStage);
			}
			system.debug('=====================================================================>'+oppLineStageUniqueMap);
			for(OpportunityLineItem OppLineItem:oppToprocess.OpportunityLineItems){
				System.debug('Libe item Processing========================================================>'+OppLineItem.id);
				oppLineUniqueID.add(OppLineItem.id);
				if(oppLineStageUniqueMap.keyset().contains(OppLineItem.id) && !currencyChange){
				//Passing the Opportunity product and Related Line item for cloning
					Opportunity_Line_Staging__c oppLineStaging= oppLineStageUniqueMap.get(OppLineItem.id);
					opportunityProductUpsert(oppLineStaging,oppLineItem,OppHeaderStaging);
				}else{
					OppLineItemLstToDelete.add(oppLineItem);
				}
			}
			for(Opportunity_Line_Staging__c oppLineStage:OppHeaderStaging.Opportunities_Line_Staging__r){
				if(!oppLineUniqueID.contains(oppLineStage.Opportunity_Product_ID__c)){
					//Create Product in case the product exist in the Opportunity Line item Staging and not in Opportunity Line item
					OpportunitylineItem oppLineItem= new OpportunitylineItem();
					opportunityProductUpsert(oppLineStage,oppLineItem,OppHeaderStaging); 
				}
			}
		}

		/**
		 * create/update new products for the Opportunity
		 */
		private void opportunityProductUpsert(Opportunity_Line_Staging__c oppLineStaging,OpportunitylineItem oppLineItem,Opportunity_header_staging__c OppHeaderStaging){
			if(oppLineItem.OpportunityId ==null){
				oppLineItem.OpportunityId = oppLineStaging.Opportunity_Stage_Header_ID__r.Order_Source__c!='SFDC_Sales' ? mapofOpportunityNumberAndOpportunityDetails.get(oppLineStaging.Opportunity_Stage_Header_ID__r.Opportunity_Number__c).Id:oppLineStaging.Opportunity_Stage_Header_ID__r.Opportunity_ID__c;
			}
			if(oppLineStaging.ActualStartDate__c !=null && oppLineStaging.ActualEndDate__c !=null){
				oppLineItem.ScheduleLocked__c =true;
			}
			else{
				oppLineItem.ScheduleLocked__c =false;
			}
			oppLineItem.Contract_Numbers__c=oppLineStaging.Contract_Numbers__c;
			oppLineItem.Install_Base_Number__c=oppLineStaging.Install_Base_Number__c;
			oppLineItem.ActualStartDate__c=oppLineStaging.ActualStartDate__c;
			oppLineItem.ActualEndDate__c=oppLineStaging.ActualEndDate__c;
			oppLineItem.Quantity=oppLineStaging.Quantity__c;
			oppLineItem.UnitPrice=oppLineStaging.UnitPrice__c;
			oppLineItem.Base_Price__c=oppLineStaging.Base_Price__c;
			oppLineItem.Return_Reason_Code__c= oppLineStaging.Return_Reason_Code__c;
			//System.debug('%%%%%%%%2 = '+productCodeIdmap);
			if(oppLineItem.PricebookEntryId ==null) {
				Map<String,PricebookEntry> productCodeIdMap = productCodeIdByCurrencyMap.get(oppLineStaging.Opportunity_Stage_Header_ID__r.CurrencyIsoCode);
				if(productCodeIdMap != null) {
					PricebookEntry pricebookEntry = productCodeIdMap.get(oppLineStaging.Product_Code_Oracle__c);
					if( pricebookEntry != null && pricebookEntry.IsActive == true&& pricebookEntry.Product2.IsActive == true) {
						oppLineItem.PricebookEntryId=productCodeIdmap.get(oppLineStaging.Product_Code_Oracle__c).Id;
					}
				}
			}

			oppLineItem.Entitle_To_Account__c=oppLineStaging.Entitle_To_Account__c;
			oppLineItem.Entitle_To_Address__c=oppLineStaging.Entitle_To_Address__c;
			oppLineItem.Entitle_To_Contact__c=oppLineStaging.Entitle_To_Contact__c;
			oppLineItem.Entitle_To_Sales_Account__c=oppLineStaging.Entitle_to_Sales_Account__c;

			OppLineItemLstToUpsert.add(OppLineItem);

		}

		/**
		 * update the List of Partners related to current Opportunity
		 */
		private void opportunityPartnerCreation(Opportunity oppToprocess,Opportunity_Header_Staging__c OppHeaderStaging){
			// Add the List of current Opportunity Partners to be deleted. 
			Boolean hasInfluencing = false;
			if(oppToprocess.OpportunityPartners2__r != null) {
				for(OpportunityPartner__c oppPartner : oppToprocess.OpportunityPartners2__r) {
					Boolean isInfluencing = (oppPartner.RelationshipType__c == 'Influencing');
					if(! isInfluencing) {
						OppPartnerLstToDelete.add( oppPartner );
					}
					hasInfluencing = hasInfluencing || isInfluencing;
				}
			}
			//Create New set of Opportunity Partners to be create
			if(! OppHeaderStaging.Opportunities_Partner_Staging__r.isEmpty()){
				Id oppId = OppHeaderStaging.Opportunity_ID__c;
				if(oppId == null) {
					Opportunity opp = mapofOpportunityNumberAndOpportunityDetails.get(OppHeaderStaging.Opportunity_Number__c);
					if(opp != null) {
						oppId = opp.Id;
					}
				}
				// create a new list of opportunity partners.
				if(oppId != null) {
					opportunityPartnerCreate(OppHeaderStaging.Opportunities_Partner_Staging__r,oppId,hasInfluencing,OppHeaderStaging.Operating_Unit__c);
				}
			}

		}

		/**
		 * create a Opportunity Partner List based on information provied
		 */
		private void opportunityPartnerCreate(List<Opportunity_Partner_Staging__c> OppPartnerStagLst,Id oppID,Boolean hasInfluencing,String operatingUnit){
			for(Opportunity_Partner_Staging__c oppPartnerStage: OppPartnerStagLst){
				if((! hasInfluencing) || oppPartnerStage.RelationshipType__c != 'Influencing') {
					Id partnerId = oppPartnerStage.Partner_Sales_Account__c;
					if( partnerId == null) {
						List<Account> partners = getPartnersByOperatingUnitAndPartnerStaging(operatingUnit,oppPartnerStage);
						if(partners != null) {
							for(Account a : partners) {
								partnerId = a.id;
								break;
							}
						}
					}
					if(partnerId != null) {
						OpportunityPartner__c oppPartner= new OpportunityPartner__c(
							Escape_Partner_Check__c=oppPartnerStage.Escape_Partner_Check__c,
							Opportunity__c = oppID,
							Partner__c = partnerId,
							Partner_Contact__c=oppPartnerStage.Partner_Contact__c,
							RelationshipType__c = oppPartnerStage.RelationshipType__c );
						if(oppPartnerStage.Oracle_Classification_Code__c != null) {
							if( partnerOrcClsCodeTierMap != null
								&& partnerOrcClsCodeTierMap.containsKey(oppPartnerStage.Oracle_Classification_Code__c))
							{
								oppPartner.PartnerTier__c=partnerOrcClsCodeTierMap.get(oppPartnerStage.Oracle_Classification_Code__c);
							}
							if( partnerOrcClsCodeTypeMap != null
								&& partnerOrcClsCodeTypeMap.containsKey(oppPartnerStage.Oracle_Classification_Code__c))
							{
								oppPartner.PartnerType__c=partnerOrcClsCodeTypeMap.get(oppPartnerStage.Oracle_Classification_Code__c);
							}
						}
						OppPartnerLstToCreate.add(oppPartner);
					}
				}
			}
		} 

		/**
		 * create a Order Tracking record for the related Opportunity is case the data flow is from EBS system.
		 */
		private void opportunityOrderTracking(Opportunity_Header_Staging__c stagingrecord){
			Opportunity oppRelated = new Opportunity();
			if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=Null){
				oppRelated = opportunityDetailsMap.get(stagingrecord.Opportunity_ID__c);
			}
			else if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c!=Null){
				oppRelated = mapofOpportunityNumberAndOpportunityDetails.get(stagingrecord.Opportunity_Number__c);
			}
			Order_Tracking__c orderTrackObj= new Order_Tracking__c();
			orderTrackObj.Opportunity__c=oppRelated.id;
			orderTrackObj.Opportunity_Owner__c=oppRelated.OwnerId;
			orderTrackObj.Opportunity_Stage__c=oppRelated.StageName;
			orderTrackObj.Oracle_Order_Number__c=oppRelated.OracleOrderNumber__c;
			orderTrackObj.Order_Status__c=oppRelated.Order_Status__c;
			orderTrackObj.Submitted_By__c=integrationUserId;
			orderTrackObj.Submitted_Date__c=stagingrecord.LastModifiedDate;
			opportunityOrderTrackingRecList.add(orderTrackObj);

		}  

		private void errorRecordCreation(Opportunity_Partner_Staging__c partnerstaging,String errorMessage, String fieldName){
			if(errorMessage != null) {
				List<String> e = errorMessage
					.replaceAll('\\{partnerstaging.Partner_Contact_CDH_Party_Number__c\\}',''+partnerstaging.Partner_Contact_CDH_Party_Number__c)
					.replaceAll('\\{partnerstaging.CDH_Party_Number__c\\}',''+partnerstaging.CDH_Party_Number__c)
					.replaceAll('\\{partnerstaging.Name\\}',''+partnerstaging.Name)
					.split(':\\s*',2);
				e.add(e[0]);
				errorRecordCreation(partnerstaging.Opportunity_Stage_Header_ID__c,e[0],e[1],fieldName,partnerstaging.Id);
			}
		}

		/**
		 * method : create the record in error table (header level errors)
		 */
		private void errorRecordCreation(Id opportunityStagingId , String errorCode , String errorDescription , String fieldName){
			errorList.add(new Match_and_Validation_Error__c(
								Error_Code__c = errorCode,
								Error_Description__c = errorDescription,
								Error_Type__c = 'Header',
								Opportunity_Staging_Header__c = opportunityStagingId,
								Related_Field_API_Name__c = fieldName));


		}

		/**
		 * method : create the record in error table (Line level errors)
		 */
		private void errorRecordCreation(Id opportunityStagingId ,Id opportunityProductStagingId,  String errorCode , String errorDescription , String fieldName){
			errorList.add(new Match_and_Validation_Error__c(
								Error_Code__c = errorCode,
								Error_Description__c = errorDescription,
								Error_Type__c = 'Line',
								Opportunity_Staging_Header__c = OpportunityStagingId,
								Opportunity_Product_Staging__c = opportunityProductStagingId,
								Related_Field_API_Name__c = fieldName));


		}

		/**
		 * method : create the record in error table (Partner level errors)
		 */
		private void errorRecordCreation(Id opportunityStagingId ,String errorCode , String errorDescription , String fieldName, Id opportunityPartnerStagingId){
			errorList.add(new Match_and_Validation_Error__c(
								Error_Code__c = errorCode,
								Error_Description__c = errorDescription,
								Error_Type__c = 'Partner',
								Opportunity_Staging_Header__c = OpportunityStagingId,
								Opportunity_Partner_Staging__c = opportunityPartnerStagingId,
								Related_Field_API_Name__c = fieldName));
		}

		/**
		 * Method to process List of Opportunity line items records and validate.
		 * @param lstOpplineStagingItems Opportunity line item staging record to process
		 */
		private Opportunity_Header_Staging__c  opportunitystagingLineItemProcess(list<Opportunity_Line_Staging__c> lstOpplineStagingItems,Opportunity_Header_Staging__c stagingrecord,String errorCode){
			Opportunity_Header_Staging__c retval = stagingrecord;
			for(Opportunity_Line_Staging__c lineStaging :lstOpplineStagingItems) {
				try {
					String accPreviousID = lineStaging.Entitle_To_Account__c;
					if(lineStaging.Opportunity_Product_ID__c!= Null && opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c) == Null && errorCode !='In'){
						//TODO:Call error Class
						errorRecordCreation(stagingrecord.Id,'D00','Opportunity Product Id is not correct on Opportunity Line Staging record.Reference SKU:'+lineStaging.Name+'\n','Not Applicable'); 
						//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D00 Error Message : Opportunity Product Id is not correct on Opportunity Line Staging record.Reference SKU:'+lineStaging.Name+'\n';
					}
					//Incase New Records are created this list will be update with the error list
//depreciated					List<Match_and_Validation_Error__c> errorListNew = new List<Match_and_Validation_Error__c>();
//depreciated					errorListNew.addAll(errorList);
					Id lineStagingEBSAccountId = lineStaging.Entitle_To_Account__c;
					EBS_Account__c lineStagingEBSAccount = (EBS_Account__c)lineStaging.Entitle_To_Account__r;

					Id lineStagingAddressId = lineStaging.Entitle_To_Address__c;
					Address__c lineStagingAddress = (Address__c)lineStaging.Entitle_To_Address__r;

					Id lineStagingContactId = lineStaging.Entitle_To_Contact__c;
					Contact lineStagingContact = (Contact)lineStaging.Entitle_To_Contact__r;

					clearMultiMatch(lineStaging);

					Id lineStagingSalesAccountOfEbsASccount = null;
					Id lineStagingSalesAccountOfAddress = null;
					Id lineStagingSalesAccountOfContact = null;
					if(lineStagingEBSAccountId != null && lineStagingEBSAccount != null) {
						lineStagingSalesAccountOfEbsASccount = lineStagingEBSAccount.Sales_Account__c;
					}
					if(lineStagingAddressId != null && lineStagingAddress != null) {
						lineStagingSalesAccountOfAddress = lineStagingAddress.Sales_Account__c;
					}
					if(lineStagingContactId != null && lineStagingContact != null) {
						lineStagingSalesAccountOfContact = lineStagingContact.AccountId;
					}
//depreciated					// check for entitle to account information
//depreciated					if(lineStaging.Entitle_To_Account__c == Null &&
//depreciated						lineStaging.Opportunity_Product_ID__c!= Null && 
//depreciated						opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c) != Null &&
//depreciated						opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Account__c!=Null &&
//depreciated						lineStaging.Entitle_To_Account_Number__c == opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Account__r.Name)
//depreciated					{
//depreciated						lineStaging.Entitle_To_Account__c = opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Account__c;
//depreciated						lineStagingSalesAccountOfEbsASccount = opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Account__r.Sales_Account__c;
//depreciated					}
//depreciated					else {
//depreciated						if(lineStaging.Entitle_To_Account__c == Null &&
//depreciated							eBSAccountNumberAndListOfEBSAccountMap.get(lineStaging.Entitle_To_Account_Number__c)!= Null &&  
//depreciated							eBSAccountNumberAndListOfEBSAccountMap.get(lineStaging.Entitle_To_Account_Number__c).size()==1)
//depreciated						{
//depreciated							lineStaging.Entitle_To_Account__c = eBSAccountNumberAndListOfEBSAccountMap.get(lineStaging.Entitle_To_Account_Number__c)[0].Id;
//depreciated							lineStagingSalesAccountOfEbsASccount = eBSAccountNumberAndListOfEBSAccountMap.get(lineStaging.Entitle_To_Account_Number__c)[0].Sales_Account__c;
//depreciated						}
//depreciated						if(lineStaging.Entitle_To_Account__c == Null &&
//depreciated							lineStaging.Entitle_To_Account_Number__c !=Null &&
//depreciated							(eBSAccountNumberAndListOfEBSAccountMap.get(lineStaging.Entitle_To_Account_Number__c)== Null ||
//depreciated							eBSAccountNumberAndListOfEBSAccountMap.get(lineStaging.Entitle_To_Account_Number__c).size()>1))
//depreciated						{
//depreciated							if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=Null){
//depreciated								errorRecordCreation(stagingrecord.Id,lineStaging.Id,'D21','Entitle-To Account number match failed. Please review and select the correct Entitle-To Account Number from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n','Entitle_To_Account_Number__c');
//depreciated								//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D21 Error Message: Entitle-To Account number match failed. Please review and select the correct Entitle-To Account Number from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n';
//depreciated							}
//depreciated							else if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c!=Null){
//depreciated								errorRecordCreation(stagingrecord.Id,lineStaging.Id,'I23','Entitle-To Account number match failed. Please review and select the correct Entitle-To Account Number from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n','Entitle_To_Account_Number__c');
//depreciated								//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I23 Error Message: Entitle-To Account number match failed. Please review and select the correct Entitle-To Account Number from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n';
//depreciated							}
//depreciated							else if(errorCode=='In') {
//depreciated								errorRecordCreation(stagingrecord.Id,lineStaging.Id,'In20','Entitle-To Account number match failed. Please review and select the correct Entitle-To Account Number from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n','Entitle_To_Account_Number__c');
//depreciated							}
//depreciated						}
//depreciated
//depreciated					}

					PricebookEntry pricebookEntry = null;
					System.debug('%%%%%%%%6 = '+lineStaging.Product_Code_Oracle__c);
					if(lineStaging.Product_Code_Oracle__c != null) {
						Map<String,PricebookEntry> productCodeIdMap = productCodeIdByCurrencyMap.get(lineStaging.Opportunity_Stage_Header_ID__r.CurrencyIsoCode);
						System.debug('%%%%%%%%2 = '+productCodeIdMap);
						if(productCodeIdMap != null) {
							pricebookEntry = productCodeIdMap.get(lineStaging.Product_Code_Oracle__c);
						}
					}
					if( pricebookEntry != null && pricebookEntry.Product2.IsActive != true) {
						//Changes made for US67181 to show user an error letting them know that their line item is inactive.
						System.debug('%%%%5');
						if(stagingrecord.Opportunity_id__c !=null){
							errorRecordCreation(stagingrecord.Id, lineStaging.id,'D29','The product (Reference SKU # '+lineStaging.Product_Code_Oracle__c+', Line # '+lineStaging.Name+')  is inactive in SFDC. Please contact the product data team for assistance','Not Applicable'); 
						}
						else if(stagingrecord.Opportunity_number__c !=null){
							errorRecordCreation(stagingrecord.Id, lineStaging.id,'I30','The product (Reference SKU # '+lineStaging.Product_Code_Oracle__c+', Line # '+lineStaging.Name+')  is inactive in SFDC. Please contact the product data team for assistance','Not Applicable'); 
						}else{
							errorRecordCreation(stagingrecord.Id, lineStaging.id,'In29','The product (Reference SKU # '+lineStaging.Product_Code_Oracle__c+', Line # '+lineStaging.Name+')  is inactive in SFDC. Please contact the product data team for assistance','Not Applicable'); 
						}
						stagingrecord.Status__c = 'Error';				   
					}
					else if(pricebookEntry == null || pricebookEntry.IsActive != true){
						errorRecordCreationWithDetails('Price Book entry not found for :'+lineStaging.Product_Code_Oracle__c+' in Global Price Book',stagingrecord,lineStaging,null);
					}

//depreciated					// check for entitle to Address Information.
//depreciated					if(lineStaging.Entitle_To_Address__c == Null &&
//depreciated						lineStaging.Opportunity_Product_ID__c!= Null &&
//depreciated						opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c) != Null &&
//depreciated						opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Address__c!=Null &&
//depreciated						opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Address__r.CDH_Party_Site_Number__c!=Null &&
//depreciated						opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Address__r.CDH_Party_Site_Number__c == lineStaging.Entitle_To_CDH_Party_Site_Number__c)
//depreciated					{
//depreciated						lineStaging.Entitle_To_Address__c = opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Address__c;
//depreciated						lineStagingSalesAccountOfAddress = opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Address__r.Sales_Account__c;
//depreciated					}
//depreciated					else{
//depreciated
//depreciated						if(lineStaging.Entitle_To_Address__c == Null &&
//depreciated						cDHPartySiteNumberAndListOfAddressMap.get(lineStaging.Entitle_To_CDH_Party_Site_Number__c)!= Null &&
//depreciated						cDHPartySiteNumberAndListOfAddressMap.get(lineStaging.Entitle_To_CDH_Party_Site_Number__c).size()==1){
//depreciated							lineStaging.Entitle_To_Address__c = cDHPartySiteNumberAndListOfAddressMap.get(lineStaging.Entitle_To_CDH_Party_Site_Number__c)[0].id;
//depreciated							lineStagingSalesAccountOfAddress = cDHPartySiteNumberAndListOfAddressMap.get(lineStaging.Entitle_To_CDH_Party_Site_Number__c)[0].Sales_Account__c;
//depreciated						}
//depreciated						system.debug('Matching logic test================================================================>'+lineStaging.Entitle_To_CDH_Party_Site_Number__c);
//depreciated						system.debug('Matching logic test================================================================>'+cDHPartySiteNumberAndListOfAddressMap.get(lineStaging.Entitle_To_CDH_Party_Site_Number__c));
//depreciated						if(lineStaging.Entitle_To_Address__c == Null &&
//depreciated							lineStaging.Entitle_To_CDH_Party_Site_Number__c!=Null &&
//depreciated							(cDHPartySiteNumberAndListOfAddressMap.get(lineStaging.Entitle_To_CDH_Party_Site_Number__c)== Null ||
//depreciated							cDHPartySiteNumberAndListOfAddressMap.get(lineStaging.Entitle_To_CDH_Party_Site_Number__c).size()>1))
//depreciated						{
//depreciated							if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=Null){
//depreciated								errorRecordCreation(stagingrecord.Id,lineStaging.Id,'D22','Entitle-To Address match failed. Please review and select the correct Entitle-To Address from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n','Entitle_To_CDH_Party_Site_Number__c');
//depreciated								//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D22 Error Message: Entitle-To Address match failed. Please review and select the correct Entitle-To Address from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n';
//depreciated							}
//depreciated							else if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c!=Null){
//depreciated								errorRecordCreation(stagingrecord.Id,lineStaging.Id,'I24','Entitle-To Address match failed. Please review and select the correct Entitle-To Address from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n','Entitle_To_CDH_Party_Site_Number__c');
//depreciated								//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I24 Error Message: Entitle-To Address match failed. Please review and select the correct Entitle-To Address from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n';
//depreciated							}else if(errorCode=='In'){
//depreciated								errorRecordCreation(stagingrecord.Id,lineStaging.Id,'In21','Entitle-To Address match failed. Please review and select the correct Entitle-To Address from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n','Entitle_To_CDH_Party_Site_Number__c');
//depreciated							}
//depreciated
//depreciated						}
//depreciated
//depreciated					}
//depreciated
//depreciated					// check for entitle contact information
//depreciated					if(lineStaging.Entitle_To_Contact__c == Null &&
//depreciated						lineStaging.Opportunity_Product_ID__c!= Null &&
//depreciated						opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c) != Null &&
//depreciated						opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Contact__c!=Null &&
//depreciated						opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Contact__r.CDH_Party_Number__c!=Null &&
//depreciated						opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Contact__r.CDH_Party_Number__c == lineStaging.Entitle_To_CDH_Party_Number__c)
//depreciated					{
//depreciated						lineStaging.Entitle_To_Contact__c = opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Contact__c;
//depreciated						lineStagingSalesAccountOfContact = opportunityProductMap.get(lineStaging.Opportunity_Product_ID__c).Entitle_To_Contact__r.AccountId;
//depreciated					}
//depreciated					else{
//depreciated						if(lineStaging.Entitle_To_Contact__c == Null &&
//depreciated							cDHPartyNumberAndListOfContactMap.get(lineStaging.Entitle_To_CDH_Party_Number__c)!=Null &&
//depreciated							cDHPartyNumberAndListOfContactMap.get(lineStaging.Entitle_To_CDH_Party_Number__c).size()==1)
//depreciated						{
//depreciated							lineStaging.Entitle_To_Contact__c  = cDHPartyNumberAndListOfContactMap.get(lineStaging.Entitle_To_CDH_Party_Number__c)[0].Id;
//depreciated							lineStagingSalesAccountOfContact =  cDHPartyNumberAndListOfContactMap.get(lineStaging.Entitle_To_CDH_Party_Number__c)[0].AccountId;
//depreciated						}else if(contactToInsertMap.get(lineStaging.Entitle_To_CDH_Party_Number__c) !=null){
//depreciated
//depreciated						String contactExternalId = contactToInsertMap.get(lineStaging.Entitle_To_CDH_Party_Number__c);
//depreciated						if(lineStagingContactId == null && contactExternalId !=null){
//depreciated							lineStaging.putsobject('Entitle_To_Contact__r' , new contact(Contact_External_Id__c = contactExternalId) );
//depreciated						}
//depreciated						if(lineStagingContactId == Null &&
//depreciated							lineStaging.Entitle_To_CDH_Party_Number__c!=Null &&
//depreciated							lineStagingContact ==null )
//depreciated						{
//depreciated							if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=Null){
//depreciated								errorRecordCreation(stagingrecord.Id,lineStaging.Id,'D23','Entitle-To Contact match failed. Please review and select the correct Entitle-To Contact from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n','Entitle_To_CDH_Party_Number__c');
//depreciated								//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D23 Error Message: Entitle-To Contact match failed. Please review and select the correct Entitle-To Contact from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n';
//depreciated							}
//depreciated							if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c!=Null){
//depreciated								errorRecordCreation(stagingrecord.Id,lineStaging.Id,'I25','Entitle-To Contact match failed. Please review and select the correct Entitle-To Contact from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n','Entitle_To_CDH_Party_Number__c');
//depreciated								//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I25 Error Message: Entitle-To Contact match failed. Please review and select the correct Entitle-To Contact from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n';
//depreciated							}else if(errorCode=='In'){
//depreciated								errorRecordCreation(stagingrecord.Id,lineStaging.Id,'In22','Entitle-To Contact match failed. Please review and select the correct Entitle-To Contact from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n','Entitle_To_CDH_Party_Number__c');
//depreciated							}
//depreciated						}
						Contact contact = createContact( lineStaging, new Account(Id=lineStagingSalesAccountOfAddress) );
						if(contactToUpsertMap.containsKey(contact.Contact_External_Id__c)) {
							contact = contactToUpsertMap.get(contact.Contact_External_Id__c);
							lineStaging.putsobject('Entitle_To_Contact__r' , contact );
						}
						if( lineStagingContactId == null &&
							lineStaging.Entitle_To_CDH_Party_Number__c != null && 
							lineStagingContact == null && // cDHPartyNumberAndListOfContactMap.get(lineStaging.Entitle_To_CDH_Party_Number__c)==Null &&
							lineStagingSalesAccountOfEbsASccount!= Null &&
							lineStagingSalesAccountOfAddress != Null &&
							lineStagingSalesAccountOfAddress == lineStagingSalesAccountOfEbsASccount)
						{
							//Clear the Old error list to remove error added due to improper CDH details
//depreciated							errorList.clear();
//depreciated							errorList.addAll(errorListNew);
							system.debug('finalcheck ===============================>'+lineStaging.Entitle_To_CDH_Party_Number__c);
							// create CDH Person Party record.
							CDH_Party__c cdhPersonParty = createCDHPersonParty(lineStaging,'PERSON');

							//Changed by Niti : Add CDH party instance into the set only if it does not exist already.
							if(checkCDHinSet(cDHPartyToInsertSet ,lineStaging.Entitle_To_CDH_Party_Number__c ))
							{
								cDHPartyToInsertSet.add(cdhPersonParty);
							}

							//create contact record.
							contact = addContactToUpsert(contact);
							lineStaging.Entitle_To_Contact__r = contact;
						}
//depreciated					}

					boolean isValidSalesAcc=true;
					if(( lineStagingSalesAccountOfAddress != null &&  lineStagingSalesAccountOfEbsASccount !=null &&(lineStagingSalesAccountOfAddress != lineStagingSalesAccountOfEbsASccount)) ||
						( lineStagingSalesAccountOfAddress != null &&  lineStagingSalesAccountOfContact !=null &&(lineStagingSalesAccountOfAddress != lineStagingSalesAccountOfContact)) ||
						( lineStagingSalesAccountOfEbsASccount != null &&  lineStagingSalesAccountOfContact !=null &&(lineStagingSalesAccountOfEbsASccount != lineStagingSalesAccountOfContact)))
					{
						isValidSalesAcc=false;
					}
					List<Match_and_Validation_Error__c> errorListNew = errorList.clone();
					if(isValidSalesAcc){
						if(lineStagingSalesAccountOfAddress !=null){
							lineStaging.Entitle_To_Sales_Account__c =lineStagingSalesAccountOfAddress;
						}
						else if(lineStagingSalesAccountOfEbsASccount !=null) {
							lineStaging.Entitle_To_Sales_Account__c =lineStagingSalesAccountOfEbsASccount;
						}
						else if(lineStagingSalesAccountOfContact !=null) {
							lineStaging.Entitle_To_Sales_Account__c = lineStagingSalesAccountOfContact;
						}
					}
					// DE8897
					//else if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=Null) {
					//	errorRecordCreation(stagingrecord.Id,lineStaging.Id,'D24','Entitle-To Account, Entitle-To Address, and Entitle-To Contact is not associated with the same Sales Account .Please review and correct the Entitle-To information (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n','Entitle_To_Sales_Account__c');
					//	//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: D24 Error Message: Entitle-To Account, Entitle-To Address, and Entitle-To Contact is not associated with the same Sales Account .Please review and correct the Entitle-To information (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n';
					//}
					//else if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c!=Null) {
					//	errorRecordCreation(stagingrecord.Id,lineStaging.Id,'I26','Entitle-To Account, Entitle-To Address, and Entitle-To Contact is not associated with the same Sales Account .Please review and correct the Entitle-To information (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n','Entitle_To_Sales_Account__c');
					//	//stagingrecord.Error_Message__c = stagingrecord.Error_Message__c+'Error Code: I26 Error Message: Entitle-To Account, Entitle-To Address, and Entitle-To Contact is not associated with the same Sales Account .Please review and correct the Entitle-To information (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n';
					//}
					//else if(errorCode=='In') {
					//	errorRecordCreation(stagingrecord.Id,lineStaging.Id,'In23','Entitle-To Contact match failed. Please review and select the correct Entitle-To Contact from the lookup field (Reference SKU:'+lineStaging.Product_Code_Oracle__c+',Line#:'+lineStaging.Name+'\n','Entitle_To_CDH_Party_Number__c');
					//}

					// create sales account , CDH Party , ebs account , address , contact record.
					if( lineStaging.Entitle_To_Contact__c == Null &&
						lineStaging.Entitle_To_Account__c == Null &&
						lineStaging.Entitle_To_Address__c == Null &&
						lineStaging.Entitle_To_Account_Number__c != null &&
						lineStaging.Entitle_To_CDH_Party_Number_Account__c !=null &&
						lineStaging.Entitle_To_CDH_Party_Site_Number__c !=null &&
						lineStaging.Entitle_To_CDH_Party_Number__c !=null &&
						lineStagingEBSAccount == null && // eBSAccountNumberAndListOfEBSAccountMap.get(lineStaging.Entitle_To_CDH_Party_Number_Account__c)== Null &&
						lineStagingAddress == null && // cDHPartySiteNumberAndListOfAddressMap.get(lineStaging.Entitle_To_CDH_Party_Site_Number__c)== Null &&
						lineStagingContact == null && // cDHPartyNumberAndListOfContactMap.get(lineStaging.Entitle_To_CDH_Party_Number__c)==Null &&
						lineStaging.Entitle_To_Party_Type__c =='PERSON')
					{
						//Clear the Old error list to remove error added due to improper CDH details
						errorList.clear();
						errorList.addAll(errorListNew);
						// create CDH Party record.
						// create CDH Party record for salesaccount.
						CDH_Party__c cdhParty = createCDHAccountParty(lineStaging);

						//Changed by Niti : Add CDH party instance into the set only if it does not exist already.
						if(checkCDHinSet(cDHPartyToInsertSet ,lineStaging.Entitle_To_CDH_Party_Number_Account__c ))
						{
							cDHPartyToInsertSet.add(cdhParty);
						}


						// create sales account record.
						Account account = addAccountToUpsert(createAccount(lineStaging));

						// create EBS Account.
						EBS_Account__c ebsAccount = addEBSAccountToUpsert(createEBSAccount(lineStaging,account));

						// create address record.
						Address__c address = addAddressToUpsert(createAddress(lineStaging,account));

						// create cdh party records.
						CDH_Party__c cdhPersonParty = createCDHPersonParty(lineStaging,null);

						//Changed by Niti : Add CDH party instance into the set only if it does not exist already.
						if(checkCDHinSet(cDHPartyToInsertSet ,lineStaging.Entitle_To_CDH_Party_Number__c ))
						{
							cDHPartyToInsertSet.add(cdhPersonParty);
						}

						//create contact record.
						contactToUpsertMap.put(contact.Contact_External_Id__c,contact);
						lineStaging.Entitle_To_Contact__r = contact;
						// associate these created records to staging record.
						lineStaging.Entitle_To_Sales_Account__r = account;
						lineStaging.Entitle_To_Address__r = address;

						lineStaging.Entitle_To_Account__r = ebsAccount;
					}
//depreciated					opportunityLineStagingRecordList.add(lineStaging);
				}
				catch(Exception ex) {
					errorRecordCreationWithDetails(ex,stagingrecord,lineStaging);
					retval = null;
				}
			}
			return retval;
		}

		/**
		 * Method to process List of Opportunity partner records and validate.
		 * @param  partnerstagingRecList Opportunity partner staging record to process
		 */
		private Opportunity_Header_Staging__c  opprtunityPartnerItemProcess(List<Opportunity_Partner_Staging__c> partnerstagingRecList,Opportunity_Header_Staging__c stagingrecord,String errorCodePrefix,map<string,string> cdhTrasitionMap){
			Opportunity_Header_Staging__c retval = stagingrecord;
			List<string> finRecLst= new List<string>();
			Boolean finRecMisMatch=false;
			if(stagingrecord.Order_Source__c == 'SFDC_Sales' && stagingrecord.Opportunity_ID__c!=null){
				errorCodePrefix='D';
			}
			else if(stagingrecord.Order_Source__c != 'SFDC_Sales' && stagingrecord.Opportunity_Number__c!=null){
				errorCodePrefix='I';
			}
			else if(errorCodePrefix != 'In') {
				errorCodePrefix = null;
			}
			for(Opportunity_Partner_Staging__c partnerstaging : partnerstagingRecList){
				// Check if the Current Record set contains Transaction Role = 'Financial' or  'FINANCIAL' for Direct Orders
				if( stagingrecord.Order_Source__c == 'SFDC_Sales'
					&& stagingrecord.Opportunity_ID__c != null 
					&& partnerstaging.RelationshipType__c == 'Financial' )
				{
					finRecLst.add(partnerstaging.CDH_Party_Number__c);
					if(stagingrecord.Status__c == NOT_PROCESSED && cdhTrasitionMap.get(partnerstaging.CDH_Party_Number__c) ==null){
						//Log an error because no related record with the given Partner found with the status Financial
						finRecMisMatch=true;
						errorRecordCreation(partnerstaging,System.Label.C360_D28,'Not Applicable');
					}
				}
				Account cdhPartyNumberAccount = null;
				//Incase New Records are created this list will be update with the error list
				List<Match_and_Validation_Error__c> errorListNew = errorList.clone();
				Id partnerSalesAccountId = partnerstaging.Partner_Sales_Account__c;
				// check for account match
				if(partnerSalesAccountId == null && partnerstaging.CDH_Party_Number__c != null) {
					String directError = System.Label.C360_D25;
					List<Account> partnerAccounts = getPartnersByOperatingUnitAndPartnerStaging(stagingrecord.Operating_Unit__c,partnerstaging);
					Integer partnerAccountsSize = 0;
					if(partnerAccounts != null) {
						partnerAccountsSize = partnerAccounts.size();
					}
					if(partnerAccountsSize == 1) {
						cdhPartyNumberAccount = partnerAccounts[0];
						partnerSalesAccountId = partnerstaging.Partner_Sales_Account__c = cdhPartyNumberAccount.Id;
						directError = System.Label.C360_D36;
					}
					if(errorCodePrefix != null) {
						errorRecordCreation(
							partnerstaging,
							errorCodePrefix+directError.substring(1).replaceAll('\\{partnerAccounts.size\\}',''+partnerAccountsSize),
							'CDH_Party_Number__c');
					}
				}
				Id partnerContactAccountId = null;
				if(partnerstaging.Partner_Contact__c == null) {
					// check for contact match
					List<Contact> contacts = cDHPartyNumberAndListOfContactMap.get(partnerstaging.Partner_Contact_CDH_Party_Number__c);
					if( contacts != null && contacts.size() == 1 )
					{
						partnerstaging.Partner_Contact__c =  contacts[0].Id;
						partnerContactAccountId  = contacts[0].AccountId;
					}
					else if( partnerstaging.Partner_Contact_CDH_Party_Number__c != null
						&& contactToInsertMap.get(partnerstaging.Partner_Contact_CDH_Party_Number__c) == null
						&& errorCodePrefix != null )
					{
						errorRecordCreation(partnerstaging,errorCodePrefix+System.Label.C360_D26.substring(1),'Partner_Contact_CDH_Party_Number__c');
					}
				}
				Contact contact = null;
				if(cdhPartyNumberAccount != null) {
					contact = contactToUpsertMap.get(partnerstaging.Partner_Contact_CDH_Party_Number__c+cdhPartyNumberAccount.Id);
				}
				else if(partnerstaging.Partner_Sales_Account__c != null) {
					contact = contactToUpsertMap.get(partnerstaging.Partner_Contact_CDH_Party_Number__c+partnerstaging.Partner_Sales_Account__c);
				}
				if( partnerstaging.Partner_Contact__c == null
					&& partnerstaging.Partner_Contact_CDH_Party_Number__c != null 
					&& contact == null
					&& cdhPartyNumberAccount != null
					&& cDHPartyNumberAndListOfContactMap.get(partnerstaging.Partner_Contact_CDH_Party_Number__c) == null )
				{
					//Clear the Old error list to remove error added due to improper CDH details
					errorList.clear();
					errorList.addAll(errorListNew);
					// create the contact record.
					CDH_Party__c cdhPersonParty = createCDHPersonParty(partnerstaging,'PERSON');

					//Changed by Niti : Add CDH party instance into the set only if it does not exist already.
					if(checkCDHinSet(cDHPartyToInsertSet ,partnerstaging.Partner_Contact_CDH_Party_Number__c ))
					{
						cDHPartyToInsertSet.add(cdhPersonParty);
					}
					//create contact record.
					contact = addContactToUpsert(createContact( partnerStaging, cdhPartyNumberAccount ));
					partnerContactAccountId = contact.AccountId;
					partnerstaging.Partner_Contact__r = contact;
				}
				if(contact != null){
					partnerstaging.Partner_Contact__r = contact;
				}
				if(partnerSalesAccountId != partnerContactAccountId
					&& partnerSalesAccountId != null 
					&& partnerContactAccountId != null
					&& errorCodePrefix != null )
				{
					errorRecordCreation(partnerstaging,errorCodePrefix+System.Label.C360_D27.substring(1),'Partner_Contact_CDH_Party_Number__c');
				}
//depreciated					opportunityPartnerStagingRecordList.add(partnerstaging);
			}
			if(retval != null) {
				//comparision in case financial rec size match fails
				if(retval != null && finRecLst !=null && cdhTrasitionMap !=null && finRecLst.size()!=cdhTrasitionMap.size() && !finRecMisMatch && stagingrecord.Opportunity_ID__c !=null && stagingrecord.Opportunity_ID__c !='' && stagingrecord.Status__c == NOT_PROCESSED){
					List<String> e = System.Label.C360_D28.split(':\\s*',2);
					e.add(e[0]);
					errorRecordCreation(stagingrecord.Id,e[0],e[1],'Not Applicable'); 
				}
				partnersToUpdate.addAll(partnerstagingRecList);
			}
			return retval;
		}

		/**
		 * Method to process List of Opportunity staging records and status status to ready for reprocessing.
		 * @param  oHSlist Opportunity header staging record  list to process
		 */
		private list<Opportunity_header_staging__c> oSHRelatedHeaderStatusProcess(list<Opportunity_header_staging__c> oHSlist){
			set<string> oHSOONToProcess= new set<string>();
			map<string,String> oracleOrderNumberOppNumberMap= new map<string,String>();
			list<Opportunity_header_staging__c> oHSRelatedlist= new list<Opportunity_header_staging__c>();
			for(Opportunity_header_staging__c oHS: oHSlist){
				if(oHSRestStatusSet !=null && oHSRestStatusSet.contains(oHS.id) && oHS.Status__c !='Error' && oHS.Oracle_Order_Number__c != null) {
					oHSOONToProcess.add(oHS.Oracle_Order_Number__c);
					oracleOrderNumberOppNumberMap.put(oHS.Oracle_Order_Number__c,oHS.Opportunity_number__c);
				}
			}
			if( ! oHSOONToProcess.isEmpty() ) {
				System.debug('oHSOONToProcess='+oHSOONToProcess);
				for(Opportunity_header_staging__c oHS: [
					select id,
						Name,
						Status__c,
						Oracle_Order_Number__c,
						Opportunity_number__c
					from Opportunity_header_staging__c
					where Oracle_Order_Number__c IN:oHSOONToProcess
						and Status__c=: PENDING_BOOKED_ORDER_PROCESS ] )
				{
					oHS.Opportunity_number__c=oracleOrderNumberOppNumberMap.get(oHS.Oracle_Order_Number__c);
					oHS.Status__c=READY_FOR_REPROCESSING;
					oHSRelatedlist.add(oHS);
				}
			}
			return oHSRelatedlist;
		}

		private System_Exception_Handler__c errorRecordCreationWithDetails(Exception ex,Opportunity_Header_Staging__c headerStaging) {
			return errorRecordCreationWithDetails('An error occured while processing a Staging record: '+ex.getMessage(),headerStaging,ex.getStackTraceString());
		}

		private System_Exception_Handler__c errorRecordCreationWithDetails(Exception ex,Opportunity_Header_Staging__c headerStaging,Opportunity_Line_Staging__c lineStaging) {
			return errorRecordCreationWithDetails('An error occured while processing a Staging record: '+ex.getMessage(),headerStaging,lineStaging, ex.getStackTraceString());
		}

		private System_Exception_Handler__c errorRecordCreationWithDetails(Exception ex,Opportunity_Header_Staging__c headerStaging,Opportunity_Partner_Staging__c partnerStaging) {
			return errorRecordCreationWithDetails('An error occured while processing a Staging record: '+ex.getMessage(),headerStaging,partnerStaging, ex.getStackTraceString());
		}

		private System_Exception_Handler__c errorRecordCreationWithDetails(String errorInfo,Opportunity_Header_Staging__c headerStaging,String stackTrace) {
			headerStaging.Status__c = 'Error';
			oppHeaderWithSystemErrorMap.put(headerStaging.Id,headerStaging);
			if(headerStaging.Opportunity_id__c !=null){
				errorRecordCreation(headerStaging.Id,'D99','This order cannot be processed due to a system exception. Please contact IT for support with the order number','Not Applicable'); 
			}
			else if(headerStaging.Opportunity_number__c !=null){
				errorRecordCreation(headerStaging.Id,'I99','This order cannot be processed due to a system exception. Please contact IT for support with the order number','Not Applicable'); 
			}
			else {
				errorRecordCreation(headerStaging.Id,'In99','This order cannot be processed due to a system exception. Please contact IT for support with the order number','Not Applicable'); 
			}
			System_Exception_Handler__c retval = logErrorDetails(errorInfo,headerStaging.Id,'Opportunity Header Staging',stackTrace);
			retval.OpportunityHeaderStaging__c = headerStaging.Id;
			return retval;
		}

		private System_Exception_Handler__c errorRecordCreationWithDetails(String errorInfo,Opportunity_Header_Staging__c headerStaging,Opportunity_Line_Staging__c lineStaging,String stackTrace) {
			System_Exception_Handler__c retval = errorRecordCreationWithDetails(errorInfo,headerStaging,stackTrace);
			retval.Object_Name__c = 'Opportunity Line Staging';
			retval.Salesforce_ID__c = retval.OpportunityLineStaging__c = lineStaging.Id;
			return retval;
		}

		private System_Exception_Handler__c errorRecordCreationWithDetails(String errorInfo,Opportunity_Header_Staging__c headerStaging,Opportunity_Partner_Staging__c partnerStaging,String stackTrace) {
			System_Exception_Handler__c retval = errorRecordCreationWithDetails(errorInfo,headerStaging,stackTrace);
			retval.Object_Name__c = 'Opportunity Partner Staging';
			retval.Salesforce_ID__c = retval.OpportunityPartnerStaging__c = partnerStaging.Id;
			return retval;
		}

		private System_Exception_Handler__c logErrorDetails(string errorInfo,Id recordId,String objName,String stackTrace){
			if(stackTrace == null) {
				try {
					throw new Order_Opportunity_Matching_Exception(errorInfo);
				}
				catch(Exception ex) {
					stackTrace = ex.getStackTraceString();
				}
			}
			System_Exception_Handler__c handler = new System_Exception_Handler__c(
				ClassName__c = 'Order_Opportunity_Matching',
				Error_Details__c=errorInfo+'\n'+stackTrace,
				Object_Name__c=objName,
				Salesforce_ID__c=recordId);
			listSystemErrorHandler.add(handler);
			return handler;
		}
	}
}