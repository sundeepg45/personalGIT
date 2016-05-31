/**
 * This class view opportunity order staging records and also allows us to
 * to test kick off the matching process.
 *
 * @version 2015-06-29
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-06-29 - Update to support address, contact, and ebs account creation
 * 2014-10-02 - Corrected test method failures
 */
public with sharing class Order_Opportunity_ControllerExtension {
	/** 
	 * The cgi-bin argument for status value.  To make this easy to
	 * extend we are using the variable name.
	 */
	public static final String STATUS_PARAM = 'status__c';

	/** current record being viewed */
	public Opportunity_Header_Staging__c currentRecord { get; set; }

	private transient Opportunity_Header_Staging__c queriedRecord = null;

	/**
	 * Standard controller extension constructor.
	 * @param controller the standard controller
	 */
	public Order_Opportunity_ControllerExtension(ApexPages.StandardController controller) {
		currentRecord = (Opportunity_Header_Staging__c)controller.getRecord();
		String status = ApexPages.currentPage().getParameters().get(STATUS_PARAM);
		if(status == null || status == '') {
			status = getQueriedRecord().Status__c;
		}
		currentRecord.Status__c = status;
		for(Match_and_Validation_Error__c e : apexErrorList) {
			String message = 'Error: ';
			if(e.Related_Field_API_Name__c != null) {
				message = 'Error on Field '+e.Related_Field_API_Name__c+': ';
			}
			if(e.Opportunity_Product_Staging__c != null) {
				message = 'Line '+e.Opportunity_Product_Staging__c +' '+message;
			}
			ApexPages_Message_ControllerExtension.addErrorMessage(message+e.Error_Description__c);
		}
	}

	private List<Match_and_Validation_Error__c> apexErrorList {
		get {
			if(apexErrorList == null) {
				apexErrorList = [
					select Id, 
						Error_Description__c,
						Error_Type__c,
						Opportunity_Staging_Header__c,
						Opportunity_Product_Staging__c,
						Related_Field_API_Name__c
					from Match_and_Validation_Error__c
					where Opportunity_Staging_Header__c = :currentRecord.Id
						and Error_Code__c = 'APEX'
					order by Error_Type__c,
						Related_Field_API_Name__c,
						Opportunity_Product_Staging__c,
						CreatedDate, Id ];
			}
			return apexErrorList;
		}
		set;
	}

	public PageReference deleteApexErrorList() {
		Database.delete(apexErrorList,false);
		return null;
	}

	public PageReference matchingNotProcessed() {
		currentRecord.Status__c = 'Not Processed';
		return matching();
	}

	public PageReference matchingReadyForReprocessing() {
		currentRecord.Status__c = 'Ready For Reprocessing';
		return matching();
	}

	/**
	 * Method to call the Opportunity_Order_Matching__c service.
	 * @return null
	 */
	public PageReference matching() {
		if(currentRecord.Status__c == 'Not Processed' || currentRecord.Status__c == 'Ready For Reprocessing') {
			Order_Opportunity_Matching matchingInstance = new Order_Opportunity_Matching();
			try {
				if(currentRecord.Status__c == 'Not Processed') {
					if(getQueriedRecord().Opportunities_Line_Staging__r != null) {
						for(Opportunity_Line_Staging__c line : queriedRecord.Opportunities_Line_Staging__r) {
							line.Entitle_To_Sales_Account__c = null;
							line.Entitle_To_Account__c = null;
							line.Entitle_To_Address__c = null;
							line.Entitle_To_Contact__c = null;
						}
						update queriedRecord.Opportunities_Line_Staging__r;
					}
					currentRecord.Bill_To_Sales_Account__c = null;
					currentRecord.Bill_To_Account__c = null;
					currentRecord.Bill_To_Address__c = null;
					currentRecord.Bill_To_Contact__c = null;
					currentRecord.Entitle_To_Sales_Account__c = null;
					currentRecord.Entitle_To_Account__c = null;
					currentRecord.Entitle_To_Address__c = null;
					currentRecord.Entitle_To_Contact__c = null;
					currentRecord.Ship_To_Sales_Account__c = null;
					currentRecord.Ship_To_Account__c = null;
					currentRecord.Ship_To_Address__c = null;
					currentRecord.Ship_To_Contact__c = null;
					currentRecord.Sold_To_Sales_Account__c = null;
					currentRecord.Sold_To_Account__c = null;
					currentRecord.Sold_To_Address__c = null;
					currentRecord.Sold_To_Contact__c = null;
				}
				// we shouldn't need to worry if the processOrders method queries this record
				// or uses the exact object we pass in
				update currentRecord;
				queriedRecord = null;
				for(String message : matchingInstance.processOrders(getQueriedRecord()) ) {
					ApexPages_Message_ControllerExtension.addErrorMessage(message);
				}
			}
			catch(Exception ex) {
				ApexPages.addMessages(ex);
			}
		}
		return null;
	}

	@TestVisible
	Opportunity_Header_Staging__c getQueriedRecord() {
		if(queriedRecord == null) {
			queriedRecord = Order_Opportunity_Matching.queryOrders(new Set<Id>{currentRecord.Id})[0];
			isAutoCreateAllowed = null;
		}
		return queriedRecord;
	}

	@TestVisible
	private Boolean isBillToEBSAccountCreateAllowed() {
		Opportunity_Header_Staging__c staging = getQueriedRecord();
		return staging.Bill_To_Sales_Account__c != null
			&& staging.Bill_To_Account__c == null
			&& staging.Bill_To_Account_Number__c != null
			&& staging.Bill_To_Account__r == null ;
	}

	@TestVisible
	private Boolean isEntitleToEBSAccountCreateAllowed() {
		Opportunity_Header_Staging__c staging = getQueriedRecord();
		return staging.Entitle_To_Sales_Account__c != null
			&& staging.Entitle_To_Account__c == null
			&& staging.Entitle_To_Account_Number__c != null
			&& staging.Entitle_To_Account__r == null;
	}

	@TestVisible
	private Boolean isShipToEBSAccountCreateAllowed() {
		Opportunity_Header_Staging__c staging = getQueriedRecord();
		return staging.Ship_To_Sales_Account__c != null
			&& staging.Ship_To_Account__c == null
			&& staging.Ship_To_Account_Number__c != null
			&& staging.Ship_To_Account__r == null;
	}

	@TestVisible
	private Boolean isSoldToEBSAccountCreateAllowed() {
		Opportunity_Header_Staging__c staging = getQueriedRecord();
		return staging.Sold_To_Sales_Account__c != null 
			&& staging.Sold_To_Account__c == null 
			&& staging.Sold_To_Account_Number__c != null
			&& staging.Sold_To_Account__r == null; 
	}


	@TestVisible
	private static Boolean isEntitleToEBSAccountCreateAllowed(Opportunity_Line_Staging__c staging) {
		return staging.Entitle_To_Sales_Account__c != null
			&& staging.Entitle_To_Account__c == null
			&& staging.Entitle_To_Account_Number__c != null
			&& staging.Entitle_To_Account__r == null;
	}

	@TestVisible
	private Boolean isBillToAddressCreateAllowed() {
		Opportunity_Header_Staging__c staging = getQueriedRecord();
		return staging.Bill_To_Sales_Account__c != null 
			&& staging.Bill_To_Address__c == null
			&& staging.Bill_To_Address_CDH_Party_Site_Number__c != null
			&& staging.Bill_To_Address__r == null;
	}

	@TestVisible
	private Boolean isEntitleToAddressCreateAllowed() {
		Opportunity_Header_Staging__c staging = getQueriedRecord();
		return staging.Entitle_To_Sales_Account__c != null 
			&& staging.Entitle_To_Address__c == null
			&& staging.Entitle_To_Address_CDH_Party_Site_Number__c != null
			&& staging.Entitle_To_Address__r == null;
	}

	@TestVisible
	private Boolean isShipToAddressCreateAllowed() {
		Opportunity_Header_Staging__c staging = getQueriedRecord();
		return staging.Ship_To_Sales_Account__c != null 
			&& staging.Ship_To_Address__c == null
			&& staging.Ship_To_Address_CDH_Party_Site_Number__c != null
			&& staging.Ship_To_Address__r == null;
	}

	@TestVisible
	private Boolean isSoldToAddressCreateAllowed() {
		Opportunity_Header_Staging__c staging = getQueriedRecord();
		return staging.Sold_To_Sales_Account__c != null 
			&& staging.Sold_To_Address__c == null
			&& staging.Sold_To_Address_CDH_Party_Site_Number__c != null
			&& staging.Sold_To_Address__r == null;
	}

	@TestVisible
	private static Boolean isEntitleToAddressCreateAllowed(Opportunity_Line_Staging__c staging) {
		return staging.Entitle_To_Sales_Account__c != null 
			&& staging.Entitle_To_Address__c == null 
			&& staging.Entitle_To_CDH_Party_Site_Number__c != null
			&& staging.Entitle_To_Address__r == null;
	}

	@TestVisible
	private Boolean isBillToContactCreateAllowed() {
		Opportunity_Header_Staging__c staging = getQueriedRecord();
		return staging.Bill_To_Sales_Account__c != null 
			&& staging.Bill_To_Contact__c == null
			&& staging.Bill_To_CDH_Party_Number__c != null
			&& staging.Bill_To_Contact__r == null; 
	}

	@TestVisible
	private Boolean isEntitleToContactCreateAllowed() {
		Opportunity_Header_Staging__c staging = getQueriedRecord();
		return staging.Entitle_To_Sales_Account__c != null 
			&& staging.Entitle_To_Contact__c == null
			&& staging.Entitle_To_CDH_Party_Number__c != null
			&& staging.Entitle_To_Contact__r == null; 
	}

	@TestVisible
	private Boolean isShipToContactCreateAllowed() {
		Opportunity_Header_Staging__c staging = getQueriedRecord();
		return staging.Ship_To_Sales_Account__c != null 
			&& staging.Ship_To_Contact__c == null
			&& staging.Ship_To_CDH_Party_Number__c != null
			&& staging.Ship_To_Contact__r == null; 
	}

	@TestVisible
	private Boolean isSoldToContactCreateAllowed() {
		Opportunity_Header_Staging__c staging = getQueriedRecord();
		return staging.Sold_To_Sales_Account__c != null 
			&& staging.Sold_To_Contact__c == null
			&& staging.Sold_To_CDH_Party_Number__c != null
			&& staging.Sold_To_Contact__r == null; 
	}

	@TestVisible
	private static Boolean isEntitleToContactCreateAllowed(Opportunity_Line_Staging__c staging) {
		return staging.Entitle_To_Sales_Account__c != null 
			&& staging.Entitle_To_Contact__c == null
			&& staging.Entitle_To_CDH_Party_Number__c != null
			&& staging.Entitle_To_Contact__r == null; 
	}

	private Boolean useProactiveMatching() {
		return (getQueriedRecord().Order_Status__c == 'BOOKED' && getQueriedRecord().Origin__c != 'Order Loader');
	}

	/**
	 * true if and only if at least one record can be auto created
	 */
	public Boolean isAutoCreateAllowed {
		get {
			Opportunity_Header_Staging__c header = getQueriedRecord();
			if(isAutoCreateAllowed == null) {
				isAutoCreateAllowed = false;
				if (header.Status__c == 'Error' && useProactiveMatching() ) {
					isAutoCreateAllowed = isBillToEBSAccountCreateAllowed()
						|| isBillToAddressCreateAllowed()
						|| isBillToContactCreateAllowed()
						|| isEntitleToEBSAccountCreateAllowed()
						|| isEntitleToAddressCreateAllowed()
						|| isEntitleToContactCreateAllowed()
						|| isShipToEBSAccountCreateAllowed()
						|| isShipToAddressCreateAllowed()
						|| isShipToContactCreateAllowed()
						|| isSoldToEBSAccountCreateAllowed()
						|| isSoldToAddressCreateAllowed()
						|| isSoldToContactCreateAllowed();
					if(! (isAutoCreateAllowed || header.Opportunities_Line_Staging__r == null)) {
						for(Opportunity_Line_Staging__c line : header.Opportunities_Line_Staging__r) {
							isAutoCreateAllowed = isEntitleToEBSAccountCreateAllowed(line)
								|| isEntitleToAddressCreateAllowed(line)
								|| isEntitleToContactCreateAllowed(line);
							if(isAutoCreateAllowed) {
								break;
							}
						}
					}
				}
			}
			return isAutoCreateAllowed;
		}
		set;
	}

	private static void addValue(Map<String,Set<String>> valuesMap,String key,String value) {
		if(valuesMap != null && value != null) {
			Set<String> s = valuesMap.get(key);
			if(s == null) {
				s = new Set<String>();
				valuesMap.put(key,s);
			}
			s.add(value);
		}
	}

	private static void addEBSAccount(
		Map<String,EBS_Account__c> ebsAccountMap,
		Map<String,Set<String>> fieldMap,
		Map<String,String> accountCDHPartyNumberMap,
		EBS_Account__c ebsAccount,
		String accountCDHPartyNumber,
		String fieldNAme ) 
	{
		ebsAccountMap.put(ebsAccount.EBS_Account_External_Id__c,ebsAccount);
		accountCDHPartyNumberMap.put(ebsAccount.EBS_Account_External_Id__c,accountCDHPartyNumber);
		addValue(fieldMap,ebsAccount.EBS_Account_External_Id__c,fieldName);
	}

	private static void addAddress(Map<String,Address__c> addressMap, Map<String,Set<String>> fieldMap,Address__c address,String fieldName) {
		addressMap.put(address.Address_External_Id__c,address);
		addValue(fieldMap,address.Address_External_Id__c,fieldName);
	}

	private static void addCDHParty(Map<String,CDH_Party__c> cdhPartyMap, Map<String,Set<String>> fieldMap,CDH_Party__c cdhParty,String fieldName) {
		cdhPartyMap.put(cdhParty.CDH_Party_Number_Ext__c,cdhParty);
		addValue(fieldMap,cdhParty.CDH_Party_Number_Ext__c,fieldName);
	}

	private static void addContact(Map<String,Contact> contactMap, Map<String,Set<String>> fieldMap,Contact contact,String fieldName) {
		contactMap.put(contact.Contact_External_Id__c,contact);
		addValue(fieldMap,contact.Contact_External_Id__c,fieldName);
	}

	private static String getCDHPartyName(Account a) {
		String retval = null;
		if(a != null && a.CDH_Party_Name__r != null) {
			retval = a.CDH_Party_Name__r.Name;
		}
		return retval;
	}

	private static Match_and_Validation_Error__c createError(String errorCode,String errorDescription,Id oppStagingId,Id oppLineStagingId,String fieldName) {
		String errorType = 'Line';
		if(oppLineStagingId == null) {
			errorType = 'Header';
		}
		if(errorCode == 'APEX') {
			String message = 'Error: ';
			if(fieldName != null) {
				message = 'Error on Field '+fieldName+': ';
			}
			if(oppLineStagingId != null) {
				message = 'Line '+oppLineStagingId+' '+message;
			}
			ApexPages_Message_ControllerExtension.addErrorMessage(message+errorDescription);
		}
		return new Match_and_Validation_Error__c(
			Error_Code__c = errorCode,
			Error_Description__c = errorDescription,
			Error_Type__c = errorType,
			Opportunity_Staging_Header__c = oppStagingId,
			Opportunity_Product_Staging__c = oppLineStagingId,
			Related_Field_API_Name__c = fieldName);
	}

	static void addApexErrors(
		List<Match_and_Validation_Error__c> errorList,
		Set<String> fieldNames, Set<String> lineIds,
		Id headerId,
		String message,
		String lineFieldName)
	{
		if(fieldNames != null) {
			for(String fieldName : fieldNames) {
				errorList.add(createError('APEX',message,headerId,null,fieldName));
			}
		}
		if(lineIds != null) {
			for(String lineId : lineIds) {
				errorList.add(createError('APEX',message,headerId,(Id)lineId,lineFieldName));
			}
		}
	}

	@future
	private static void queueSalesAccountMessages(Set<Id> accountIds) {
		new PartnerProgram_Trigger_Handler().invokeOutboundService(accountIds,true,false);
	}

	public PageReference autocreate() {
		if(! isAutoCreateAllowed) {
			ApexPages_Message_ControllerExtension.addErrorMessage('No records can be auto-created.');
		}
		else {
			List<Match_and_Validation_Error__c> errorList = new List<Match_and_Validation_Error__c>();
			// first we create a map of everything we can create
			Map<String,EBS_Account__c> ebsAccountMap = new Map<String,EBS_Account__c>();
			Map<String,Address__c> addressMap = new Map<String,Address__c>();
			Map<String,Contact> contactMap = new Map<String,Contact>();
			Map<String,CDH_Party__c> cdhPartyMap = new Map<String,CDH_Party__c>();
			Map<String,Set<String>> ebsAccountFieldMap = new Map<String,Set<String>>();
			Map<String,Set<String>> addressFieldMap = new Map<String,Set<String>>();
			Map<String,Set<String>> cdhPartyFieldMap = new Map<String,Set<String>>();
			Map<String,Set<String>> contactFieldMap = new Map<String,Set<String>>();
			Map<String,Set<String>> ebsAccountLineMap = new Map<String,Set<String>>();
			Map<String,Set<String>> addressLineMap = new Map<String,Set<String>>();
			Map<String,Set<String>> cdhPartyLineMap = new Map<String,Set<String>>();
			Map<String,Set<String>> contactLineMap = new Map<String,Set<String>>();
			Map<String,String> accountCDHPartyNumberMap = new Map<String,String>();
			Opportunity_Header_Staging__c header = getQueriedRecord();
			if(isBillToEBSAccountCreateAllowed()) {
				addEBSAccount(
					ebsAccountMap,
					ebsAccountFieldMap,
					accountCDHPartyNumberMap,
					Order_Opportunity_Matching.createEBSAccount(
						header,
						'Bill',
						header.Bill_To_Sales_Account__r ),
					header.Bill_To_CDH_Party_Number_Account__c,
					'Bill_To_Account__c' );
			}
			if(isEntitleToEBSAccountCreateAllowed()) {
				addEBSAccount(
					ebsAccountMap,
					ebsAccountFieldMap,
					accountCDHPartyNumberMap,
					Order_Opportunity_Matching.createEBSAccount(
						header,
						'Entitle',
						header.Entitle_To_Sales_Account__r ),
					header.Entitle_To_CDH_Party_Number_Account__c,
					'Entitle_To_Account__c' );
			}
			if(isShipToEBSAccountCreateAllowed()) {
				addEBSAccount(
					ebsAccountMap,
					ebsAccountFieldMap,
					accountCDHPartyNumberMap,
					Order_Opportunity_Matching.createEBSAccount(
						header,
						'Ship',
						header.Ship_To_Sales_Account__r ),
					header.Ship_To_CDH_Party_Number_Account__c,
					'Ship_To_Account__c' );
			}
			if(isSoldToEBSAccountCreateAllowed()) {
				addEBSAccount(
					ebsAccountMap,
					ebsAccountFieldMap,
					accountCDHPartyNumberMap,
					Order_Opportunity_Matching.createEBSAccount(
						header,
						'Sold',
						header.Sold_To_Sales_Account__r ),
					header.Sold_To_CDH_Party_Number_Account__c,
					'Sold_To_Account__c' );
			}
			if(isBillToAddressCreateAllowed()) {
				addAddress(
					addressMap,
					addressFieldMap,
					Order_Opportunity_Matching.createAddress(
						header,
						'Bill',
						header.Bill_To_Sales_Account__r ),
					'Bill_To_Address__c');
			}
			if(isEntitleToAddressCreateAllowed()) {
				addAddress(
					addressMap,
					addressFieldMap,
					Order_Opportunity_Matching.createAddress(
						header,
						'Entitle',
						header.Entitle_To_Sales_Account__r ),
					'Entitle_To_Address__c');
			}
			if(isShipToAddressCreateAllowed()) {
				addAddress(
					addressMap,
					addressFieldMap,
					Order_Opportunity_Matching.createAddress(
						header,
						'Ship',
						header.Ship_To_Sales_Account__r ),
					'Ship_To_Address__c');
			}
			if(isSoldToAddressCreateAllowed()) {
				addAddress(
					addressMap,
					addressFieldMap,
					Order_Opportunity_Matching.createAddress(
						header,
						'Sold',
						header.Sold_To_Sales_Account__r ),
					'Sold_To_Address__c');
			}
			if(isBillToContactCreateAllowed()) {
				addCDHParty(
					cdhPartyMap,
					cdhPartyFieldMap,
					Order_Opportunity_Matching.createCDHPersonParty(
						header,
						'Bill',
						null),
					'Bill_To_Contact__c');
				addContact(
					contactMap,
					contactFieldMap,
					Order_Opportunity_Matching.createContact(
						header,
						'Bill',
						header.Bill_To_Sales_Account__r ),
					'Bill_To_Contact__c');
			}
			if(isEntitleToContactCreateAllowed()) {
				addCDHParty(
					cdhPartyMap,
					cdhPartyFieldMap,
					Order_Opportunity_Matching.createCDHPersonParty(
						header,
						'Entitle',
						null),
					'Entitle_To_Contact__c');
				addContact(
					contactMap,
					contactFieldMap,
					Order_Opportunity_Matching.createContact(
						header,
						'Entitle',
						header.Entitle_To_Sales_Account__r ),
					'Entitle_To_Contact__c');
			}
			if(isShipToContactCreateAllowed()) {
				addCDHParty(
					cdhPartyMap,
					cdhPartyFieldMap,
					Order_Opportunity_Matching.createCDHPersonParty(
						header,
						'Ship',
						null),
					'Ship_To_Contact__c');
				addContact(
					contactMap,
					contactFieldMap,
					Order_Opportunity_Matching.createContact(
						header,
						'Ship',
						header.Ship_To_Sales_Account__r ),
					'Ship_To_Contact__c');
			}
			if(isSoldToContactCreateAllowed()) {
				addCDHParty(
					cdhPartyMap,
					cdhPartyFieldMap,
					Order_Opportunity_Matching.createCDHPersonParty(
						header,
						'Sold',
						null),
					'Sold_To_Contact__c');
				addContact(
					contactMap,
					contactFieldMap,
					Order_Opportunity_Matching.createContact(
						header,
						'Sold',
						header.Sold_To_Sales_Account__r ),
					'Sold_To_Contact__c');
			}
			Map<Id,Opportunity_Line_Staging__c> oppLineStagingMap = new Map<Id,Opportunity_Line_Staging__c>();
			if( header.Opportunities_Line_Staging__r != null) {
				oppLineStagingMap.putAll(header.Opportunities_Line_Staging__r);
				for(Opportunity_Line_Staging__c line : header.Opportunities_Line_Staging__r) {
					if(isEntitleToEBSAccountCreateAllowed(line)) {
						addEBSAccount(
							ebsAccountMap,
							ebsAccountLineMap,
							accountCDHPartyNumberMap,
							Order_Opportunity_Matching.createEBSAccount(
								line,
								line.Entitle_To_Sales_Account__r ),
							line.Entitle_To_CDH_Party_Number_Account__c,
							line.Id );
					}
					if(isEntitleToAddressCreateAllowed(line)) {
						addAddress(
							addressMap,
							addressLineMap,
							Order_Opportunity_Matching.createAddress(
								line,
								line.Entitle_To_Sales_Account__r),
							line.Id);
					}
					if(isEntitleToContactCreateAllowed(line)) {
						addCDHParty(
							cdhPartyMap,
							cdhPartyLineMap,
							Order_Opportunity_Matching.createCDHPersonParty(line,null),
							line.Id);
						addContact(
							contactMap,
							contactLineMap,
							Order_Opportunity_Matching.createContact(
								line,
								line.Entitle_To_Sales_Account__r ),
							line.Id);
					}
				}
			}
			Set<Id> updatedAccountIds = new Set<Id>();
			if(!ebsAccountMap.isEmpty()) {
				// prepare to look for existing records
				Set<Id> salesAccountIds = new Set<Id>();
				Set<String> accountNumbers = new Set<String>();
				for(EBS_Account__c ebsAccount : ebsAccountMap.values()) {
					salesAccountIds.add(ebsAccount.Sales_Account__c);
					accountNumbers.add(ebsAccount.Name);
				}
				Map<String,EBS_Account__c> ebsAccountMap2 = new Map<String,EBS_Account__c>();
				for(EBS_Account__c ebsAccount : [
					select
						EBS_Account_External_Id__c,
						Name,
						Sales_Account__c,
						Sales_Account__r.Account_External_Id__c,
						Sales_Account__r.CDH_Party_Name__r.Name
					from EBS_Account__c
					where Name in :accountNumbers and Sales_Account__c in : salesAccountIds ])
				{
					ebsAccountMap2.put(ebsAccount.Sales_Account__c+ebsAccount.Name,ebsAccount);
				}
				// prepare a list of new ebs accounts to insert
				List<EBS_Account__c> ebsAccounts = new List<EBS_Account__c>();
				for(String key : ebsAccountMap.keySet()) {
					EBS_Account__c ebsAccount = ebsAccountMap.get(key);
					EBS_Account__c ebsAccount2 = ebsAccountMap2.get(ebsAccount.Sales_Account__c+ebsAccount.Name);
					if(ebsAccount2 != null) {
						ebsAccountMap.put(key,ebsAccount2);
					}
					else {
						String accountCDHPartyNumber = accountCDHPartyNumberMap.get(key);
						if(accountCDHPartyNumber == null || accountCDHPartyNumber == '' || accountCDHPartyNumber == getCDHPartyName(ebsAccount.Sales_Account__r)) {
							ebsAccounts.add(ebsAccount);
						}
						else {
							addApexErrors(
								errorList,
								ebsAccountFieldMap.get(ebsAccount.EBS_Account_External_Id__c),
								ebsAccountLineMap.get(ebsAccount.EBS_Account_External_Id__c),
								header.Id,
								'The selected Sales Account is not associated with the CDH Party',
								'Entitle_To_Account__c');
						}
					}
				}
				// insert the new ebs accounts
				for(Database.SaveResult sr : Database.insert(ebsAccounts,false)) {
					EBS_Account__c ebsAccount = ebsAccounts.remove(0);
					if(! sr.isSuccess() ) {
						addApexErrors(
							errorList,
							ebsAccountFieldMap.get(ebsAccount.EBS_Account_External_Id__c),
							ebsAccountLineMap.get(ebsAccount.EBS_Account_External_Id__c),
							header.Id,
							'Creation of EBS Account failed: '+sr.getErrors(),
							'Entitle_To_Account__c');
					}
					else {
						updatedAccountIds.add(ebsAccount.Sales_Account__c);
					}
				}
				// finally assign successfull mappings
				for(String key : ebsAccountMap.keySet()) {
					EBS_Account__c ebsAccount = ebsAccountMap.get(key);
					if(ebsAccount.Id != null) {
						Set<String> fieldNames = ebsAccountFieldMap.get(key);
						if(fieldNames != null) {
							for(String field : fieldNames) {
								header.put(field,ebsAccount.Id);
							}
						}
						Set<String> lineIds = ebsAccountLineMap.get(key);
						if(lineIds != null) {
							for(String lineId : lineIds) {
								Opportunity_Line_Staging__c lineStaging = oppLineStagingMap.get((Id)lineId);
								if(lineStaging != null) {
									lineStaging.Entitle_To_Account__c = ebsAccount.Id;
								}
							}
						}
					}
				}
			}
			if(! addressMap.isEmpty()) {
				// prepare to look for existing records
				Set<Id> salesAccountIds = new Set<Id>();
				Set<String> cdhPartySiteNumbers = new Set<String>();
				for(Address__c address : addressMap.values()) {
					salesAccountIds.add(address.Sales_Account__c);
					cdhPartySiteNumbers.add(address.CDH_Party_Site_Number__c);
				}
				Map<String,Address__c> addressMap2 = new Map<String,Address__c>();
				for(Address__c address : [
					select
						Address_External_Id__c,
						CDH_Party_Site_Number__c,
						Sales_Account__c,
						Sales_Account__r.Account_External_Id__c,
						Sales_Account__r.CDH_Party_Name__r.Name
					from Address__c
					where CDH_Party_Site_Number__c in :cdhPartySiteNumbers and Sales_Account__c in : salesAccountIds ])
				{
					addressMap2.put(address.Sales_Account__c+address.CDH_Party_Site_Number__c,address);
				}
				// prepare a list of new ebs accounts to insert
				List<Address__c> addresses = new List<Address__c>();
				for(String key : addressMap.keySet()) {
					Address__c address = addressMap.get(key);
					Address__c address2 = addressMap2.get(address.Sales_Account__c+address.CDH_Party_Site_Number__c);
					if(address2 != null) {
						addressMap.put(key,address2);
					}
					else {
						addresses.add(address);
					}
				}
				// insert the new ebs accounts
				for(Database.SaveResult sr : Database.insert(addresses,false)) {
					Address__c address = addresses.remove(0);
					if(! sr.isSuccess() ) {
						addApexErrors(
							errorList,
							addressFieldMap.get(address.Address_External_Id__c),
							addressLineMap.get(address.Address_External_Id__c),
							header.Id,
							'Creation of Address failed: '+sr.getErrors(),
							'Entitle_To_Address__c');
					}
				}
				// finally assign successfull mappings
				for(String key : addressMap.keySet()) {
					Address__c address = addressMap.get(key);
					if(address.Id != null) {
						Set<String> fieldNames = addressFieldMap.get(key);
						if(fieldNames != null) {
							for(String field : fieldNames) {
								header.put(field,address.Id);
							}
						}
						Set<String> lineIds = addressLineMap.get(key);
						if(lineIds != null) {
							for(String lineId : lineIds) {
								Opportunity_Line_Staging__c lineStaging = oppLineStagingMap.get((Id)lineId);
								if(lineStaging != null) {
									lineStaging.Entitle_To_Address__c = address.Id;
								}
							}
						}
					}
				}
			}
			if(! cdhPartyMap.isEmpty()) {
				// prepare to look for existing records
				Set<String> cdhPartyNumbers = new Set<String>();
				for(CDH_Party__c cdhParty : cdhPartyMap.values()) {
					cdhPartyNumbers.add(cdhParty.Name);
				}
				Map<String,CDH_Party__c> cdhPartyMap2 = new Map<String,CDH_Party__c>();
				for(CDH_Party__c cdhParty : [
					select
						CDH_Party_Number_Ext__c,
						Id,
						Name
					from CDH_Party__c
					where Name in :cdhPartyNumbers ])
				{
					cdhPartyMap2.put(cdhParty.Name,cdhParty);
				}
				// prepare a list of new ebs accounts to insert
				List<CDH_Party__c> cdhParties = new List<CDH_Party__c>();
				for(String key : cdhPartyMap.keySet()) {
					CDH_Party__c cdhParty = cdhPartyMap.get(key);
					CDH_Party__c cdhParty2 = cdhPartyMap2.get(cdhParty.Name);
					if(cdhParty2 != null) {
						cdhPartyMap.put(key,cdhParty2);
					}
					else {
						cdhParties.add(cdhParty);
					}
				}
				// insert the new ebs accounts
				for(Database.UpsertResult ur : Database.upsert(cdhParties,CDH_Party__c.field.CDH_Party_Number_Ext__c,false)) {
					CDH_Party__c cdhParty = cdhParties.remove(0);
					if(! ur.isSuccess() ) {
						errorList.add(createError('APEX','Creation/Update of CDH Party failed: '+ur.getErrors(),header.Id,null,null));
					}
				}
				// finally assign successfull mappings
				for(String key : new Set<String>(contactMap.keySet()) ) {
					Contact contact = contactMap.get(key);
					if(contact != null) {
						String cdhPartyKey = contact.CDH_Party__r.CDH_Party_Number_Ext__c;
						CDH_Party__c cdhParty = cdhPartyMap.get(contact.CDH_Party__r.CDH_Party_Number_Ext__c);
						if(cdhParty.Id != null) {
							contact.CDH_Party__r = null;
							contact.CDH_Party__c = cdhParty.Id;
						}
						else {
							contactMap.remove(key);
						}
					}
				}
			}
			if(! contactMap.isEmpty()) {
				// prepare to look for existing records
				Set<Id> salesAccountIds = new Set<Id>();
				Set<Id> cdhPartyIds = new Set<Id>();
				for(Contact contact : contactMap.values()) {
					salesAccountIds.add(contact.AccountId);
					cdhPartyIds.add(contact.CDH_Party__c);
				}
				Map<String,Contact> contactMap2 = new Map<String,Contact>();
				for(Contact contact : [
					select
						Account.Account_External_Id__c,
						Account.CDH_Party_Name__r.Name,
						AccountId,
						CDH_Party__c,
						CDH_Party__r.CDH_Party_Number_Ext__c,
						Contact_External_Id__c
					from Contact
					where AccountId in : salesAccountIds and CDH_Party__c in :cdhPartyIds ])
				{
					contactMap2.put(String.valueOf(contact.AccountId)+String.valueOf(contact.CDH_Party__c),contact);
				}
				// prepare a list of new ebs accounts to insert
				List<Contact> contacts = new List<Contact>();
				for(String key : contactMap.keySet()) {
					Contact contact = contactMap.get(key);
					Contact contact2 = contactMap2.get(String.valueOf(contact.AccountId)+String.valueOf(contact.CDH_Party__c));
					if(contact2 != null) {
						contactMap.put(key,contact2);
					}
					else {
						contacts.add(contact);
					}
				}
				// insert the new ebs accounts
				for(Database.SaveResult sr : Database.insert(contacts,false)) {
					Contact contact = contacts.remove(0);
					if(! sr.isSuccess() ) {
						addApexErrors(
							errorList,
							contactFieldMap.get(contact.Contact_External_Id__c),
							contactLineMap.get(contact.Contact_External_Id__c),
							header.Id,
							'Creation of Contact failed: '+sr.getErrors(),
							'Entitle_To_Contact__c');
					}
				}
				// finally assign successfull mappings
				for(String key : contactMap.keySet()) {
					Contact contact = contactMap.get(key);
					if(contact.Id != null) {
						Set<String> fieldNames = contactFieldMap.get(key);
						if(fieldNames != null) {
							for(String field : fieldNames) {
								header.put(field,contact.Id);
							}
						}
						Set<String> lineIds = contactLineMap.get(key);
						if(lineIds != null) {
							for(String lineId : lineIds) {
								Opportunity_Line_Staging__c lineStaging = oppLineStagingMap.get((Id)lineId);
								if(lineStaging != null) {
									lineStaging.Entitle_To_Contact__c = contact.Id;
								}
							}
						}
					}
				}
			}
			if(! updatedAccountIds.isEmpty()) {
				queueSalesAccountMessages(updatedAccountIds);
			}
			if( header.Opportunities_Line_Staging__r != null) {
				List<Opportunity_Line_Staging__c> lines = header.Opportunities_Line_Staging__r.clone();
				for(Database.SaveResult sr : Database.update(header.Opportunities_Line_Staging__r,false) ) {
					Opportunity_Line_Staging__c line = lines.remove(0);
					if(! sr.isSuccess()) {
						errorList.add(createError('APEX','Failed to Update Line: '+sr.getErrors(),header.Id,line.Id,null));
					}
				}
			}
			Database.SaveResult sr2 = Database.update(header,false);
			if(! sr2.isSuccess()) {
				errorList.add(createError('APEX','Failed to Update Header: '+sr2.getErrors(),header.Id,null,null));
			}
			Database.insert(errorList,false);
			queriedRecord = null;
		}
		return null;
	}
}