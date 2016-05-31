/**
 * This class implements account matching for customer c360 order staging
 * opportunity fields including Bill-To, Ship-To, Sold-To,
 * Entitle-To, Line Item Entitle-To.
 * 
 * @version 2015-09-23
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-09-23 - update the selectSalesAccountId method to select unique sales account per DE8790
 * 2015-08-24 - Filter out inactive values
 * 2015-08-05 - Only generate errors 31-35 when the sales account id has not been previously set
 * 2015-08-05 - Corrected null exception error
 * 2015-07-08 - Drop opportunity number requirement for proactive matching
 * 2015-07-06 - correcting reprocessing error of line entitle to fields
 * 2015-06-18 - Additional filtering for booked orders with an opportunity number.
 * 2015-06-12 - Created
 * Scott Coleman <scoleman@redhat.com>
 * 2015-07-14 - US70316 Excluding staging records created by Order Loader from proactive matching
 */
public with sharing class Account_Matching_Orders extends Account_Matching {
	/** 
	 * BooleanSetting__c key to enable an error when successfully proactive matched to a single sales account...
	 */
	public static final String PROACTIVE_SALESACCOUNT_ERROR_SETTING = 'Orders.SalesAccountError';
	public static final String ALLOW_CONTACT_ON_DIFFERENT_ACCOUNT_SETTING = 'Orders.ContactDiffAcc';
	public static final String ERROR_STATUS = 'ERROR';
	public static final String WARNING_REASON = 'WARNING';
	public static final String MATCHING_FAILURE_REASON = 'Matching Failure';
	public static final String INTERNAL_ERROR_REASON = 'Internal Error';
	public static final String NO_LINES_REASON = 'No Lines';
	private static Boolean allowDifferentSalesAccounts = true;

	public static final Map<String,String> FIELDNAME_BY_MESSAGE = new Map<String,String> {
		System.Label.C360_D05 => 'Bill_To_Account_Number__c',
		System.Label.C360_D06 => 'Bill_To_Address_CDH_Party_Site_Number__c',
		System.Label.C360_D07 => 'Bill_To_CDH_Party_Number__c',
		System.Label.C360_D08 => 'Bill_To_Sales_Account__c',
		System.Label.C360_D09 => 'Ship_To_Account_Number__c',
		System.Label.C360_D10 => 'Ship_To_Address_CDH_Party_Site_Number__c',
		System.Label.C360_D11 => 'Ship_To_CDH_Party_Number__c',
		System.Label.C360_D12 => 'Ship_To_Sales_Account__c',
		System.Label.C360_D13 => 'Sold_To_Account_Number__c',
		System.Label.C360_D14 => 'Sold_To_Address_CDH_Party_Site_Number__c',
		System.Label.C360_D15 => 'Sold_To_CDH_Party_Number__c',
		System.Label.C360_D16 => 'Sold_To_Sales_Account__c',
		System.Label.C360_D17 => 'Entitle_To_Account_Number__c',
		System.Label.C360_D18 => 'Entitle_To_Address_CDH_Party_Site_Number__c',
		System.Label.C360_D19 => 'Entitle_To_CDH_Party_Number__c',
		System.Label.C360_D20 => 'Entitle_To_Sales_Account__c',
		System.Label.C360_D21 => 'Entitle_To_Account_Number__c',
		System.Label.C360_D22 => 'Entitle_To_CDH_Party_Site_Number__c',
		System.Label.C360_D23 => 'Entitle_To_CDH_Party_Number__c',
		System.Label.C360_D24 => 'Entitle_To_Sales_Account__c',
		System.Label.C360_D31 => 'Bill_To_Sales_Account__c',
		System.Label.C360_D32 => 'Entitle_To_Sales_Account__c',
		System.Label.C360_D33 => 'Ship_To_Sales_Account__c',
		System.Label.C360_D34 => 'Sold_To_Sales_Account__c',
		System.Label.C360_D35 => 'Entitle_To_Sales_Account__c' };

	public static final Map<AccountToType,String> EBS_ACCOUNT_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>System.Label.C360_D05,
		AccountToType.SHIP_TO=>System.Label.C360_D09,
		AccountToType.SOLD_TO=>System.Label.C360_D13,
		AccountToType.ENTITLE_TO=>System.Label.C360_D17,
		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_D21 };
	public static final Map<AccountToType,String> ADDRESS_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>System.Label.C360_D06,
		AccountToType.SHIP_TO=>System.Label.C360_D10,
		AccountToType.SOLD_TO=>System.Label.C360_D14,
		AccountToType.ENTITLE_TO=>System.Label.C360_D18,
		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_D22 };
	public static final Map<AccountToType,String> CONTACT_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>System.Label.C360_D07,
		AccountToType.SHIP_TO=>System.Label.C360_D11,
		AccountToType.SOLD_TO=>System.Label.C360_D15,
		AccountToType.ENTITLE_TO=>System.Label.C360_D19,
		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_D23 };
	public static final Map<AccountToType,String> SALES_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>System.Label.C360_D08,
		AccountToType.SHIP_TO=>System.Label.C360_D12,
		AccountToType.SOLD_TO=>System.Label.C360_D16,
		AccountToType.ENTITLE_TO=>System.Label.C360_D20,
		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_D24 };
//for-reference	public static final Map<AccountToType,String> EBS_ACCOUNT_ERROR_MAP2 = new Map<AccountToType,String>{
//for-reference		AccountToType.BILL_TO=>System.Label.C360_D05,
//for-reference		AccountToType.SHIP_TO=>System.Label.C360_D09,
//for-reference		AccountToType.SOLD_TO=>System.Label.C360_D13,
//for-reference		AccountToType.ENTITLE_TO=>System.Label.C360_D17,
//for-reference		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_D21 };
//for-reference	public static final Map<AccountToType,String> ADDRESS_ERROR_MAP2 = new Map<AccountToType,String>{
//for-reference		AccountToType.BILL_TO=>System.Label.C360_D06,
//for-reference		AccountToType.SHIP_TO=>System.Label.C360_D10,
//for-reference		AccountToType.SOLD_TO=>System.Label.C360_D14,
//for-reference		AccountToType.ENTITLE_TO=>System.Label.C360_D18,
//for-reference		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_D22 };
//for-reference	public static final Map<AccountToType,String> CONTACT_ERROR_MAP2 = new Map<AccountToType,String>{
//for-reference		AccountToType.BILL_TO=>System.Label.C360_D07,
//for-reference		AccountToType.SHIP_TO=>System.Label.C360_D11,
//for-reference		AccountToType.SOLD_TO=>System.Label.C360_D15,
//for-reference		AccountToType.ENTITLE_TO=>System.Label.C360_D19,
//for-reference		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_D23 };
//for-reference	public static final Map<AccountToType,String> PARTNER_ERROR_MAP = new Map<AccountToType,String>{
//for-reference		AccountToType.BILL_TO=>System.Label.C360_D05,
//for-reference		AccountToType.SHIP_TO=>System.Label.C360_D09,
//for-reference		AccountToType.SOLD_TO=>System.Label.C360_D13,
//for-reference		AccountToType.ENTITLE_TO=>System.Label.C360_D17,
//for-reference		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_D21 };

	public final List<OrderParty> orderParties;

	@TestVisible
	private static Boolean allowContactOnDifferentAccountSetting {
		get {
			if(allowContactOnDifferentAccountSetting == null) {
				BooleanSetting__c b = BooleanSetting__c.getInstance(ALLOW_CONTACT_ON_DIFFERENT_ACCOUNT_SETTING);
				allowContactOnDifferentAccountSetting = (b == null || b.Value__c != false);
			}
			return allowContactOnDifferentAccountSetting;
		}
		set;
	}

	@TestVisible
	private static Boolean proactiveSalesAccountErrorSetting {
		get {
			if(proactiveSalesAccountErrorSetting == null) {
				BooleanSetting__c b = BooleanSetting__c.getInstance(PROACTIVE_SALESACCOUNT_ERROR_SETTING);
				proactiveSalesAccountErrorSetting = (b == null || b.Value__c != false);
			}
			return proactiveSalesAccountErrorSetting;
		}
		set;
	}

	/**
	 * Construct from a list of order parties.
	 * 
	 * @param orderParties list of OrderParty
	 */
	public Account_Matching_Orders(
		List<OrderParty> orderParties)	
	{
		super(true,
			orderParties,
			EBS_ACCOUNT_ERROR_MAP,
			ADDRESS_ERROR_MAP,
			CONTACT_ERROR_MAP,
			SALES_ERROR_MAP,
			EBS_ACCOUNT_ERROR_MAP,
			ADDRESS_ERROR_MAP,
			CONTACT_ERROR_MAP,
			null );
		this.orderParties = orderParties;
		this.allowContactOnDifferentAccount = allowContactOnDifferentAccountSetting;
	}

	/**
	 * Construct from a list of order staging header and order staging lines.
	 * If the orderLineStagings list is null, the list will be queried.
	 * 
	 * @param orderHeaderStagings list of orderHeaderStagings
	 * @param orderLineStagings list of order staging lines for the orderHeaderStagings, maybe null
	 */
	public Account_Matching_Orders(
		List<Opportunity_Header_Staging__c> orderHeaderStagings,
		List<Opportunity_Line_Staging__c> orderLineStagings)
	{
		super(true,
			getOrderParty(orderHeaderStagings,orderLineStagings),
			EBS_ACCOUNT_ERROR_MAP,
			ADDRESS_ERROR_MAP,
			CONTACT_ERROR_MAP,
			SALES_ERROR_MAP,
			EBS_ACCOUNT_ERROR_MAP,
			ADDRESS_ERROR_MAP,
			CONTACT_ERROR_MAP,
			null );
		this.orderParties = (List<OrderParty>)partyList;
		this.allowContactOnDifferentAccount = allowContactOnDifferentAccountSetting;
	}

	Map<String,String> accountRecordTypeNameByOperatingUnit {
		get {
			if(accountRecordTypeNameByOperatingUnit == null) {
				accountRecordTypeNameByOperatingUnit = new Map<String,String>();
				Set<String> operatingUnits = new Set<String>();
				for(OrderParty m : orderParties) {
					if(m.operatingUnit != null) {
						operatingUnits.add(m.operatingUnit.toUpperCase());
					}
				}
				if(! operatingUnits.isEmpty()) {
					for(OperatingUnit__c ou : [
						select
							Name,
							AccountRecordType__c
						from OperatingUnit__c
						where Name in :operatingUnits
							and AccountRecordType__c != null ] )
					{
						accountRecordTypeNameByOperatingUnit.put(ou.Name.toUpperCase(),ou.AccountRecordType__c);
					}
				}
			}
			return accountRecordTypeNameByOperatingUnit;
		}
		set;
	}

	/**
	 * Filter each of the ebsAccountMapMap, addressMapMap, and contactMapMap on 
	 * each of the PartyData instances in the mapping list.  This implements 
	 * SFDC BR[1-5].PART B for Orders matching.
	 */
	public override void filter() {
		super.filter();
		for(OrderParty m : orderParties) {
			// filter out inactive values
			if(m.refEBSAccount == null) {
				m.filterEBSByStatus(false,false);
			}
			if(m.refAddress == null) {
				m.filterAddressByStatus(false,false);
			}
			if(m.refContact == null) {
				m.filterContactByStatus(false,false);
			}
			if(m.useProactiveMatching()) {
				String accountRecordTypeName = null;
				if(m.refSalesAccount == null && m.refEBSAccount == null && m.refAddress == null && m.refContact == null) {
					// find the account record type name to keep
					accountRecordTypeName = accountRecordTypeNameByOperatingUnit.get((''+m.operatingUnit).toUpperCase());
				}
				if(accountRecordTypeName == null) {
					accountRecordTypeName = 'SALES'; // keep all non-partner accounts
				}
				// remove all non matching accounts
				m.filterAddressByRecordTypeName(false,accountRecordTypeName);
				// remove all non matching accounts
				m.filterContactByRecordTypeName(false,accountRecordTypeName);
				// remove all non matching accounts
				m.filterEBSByRecordTypeName(false,accountRecordTypeName);

				// In theory the above rules should be sufficent to make everything unique.
				// However, if the operating unit lookup failed, or duplicate accounts the following will help..
				// Filter accounts based on the intersections.
				Set<Id> ids = m.addressMapMap.keySet().clone();
				ids.retainAll(m.contactMapMap.keySet());
				if(! ids.isEmpty()) {
					m.addressMapMap.keySet().retainAll(ids);
					m.contactMapMap.keySet().retainAll(ids);
					ids.retainAll(m.ebsAccountMapMap.keySet());
					if(! ids.isEmpty()) {
						m.retainAccountIds(ids);
					}
				}
				if( ids.isEmpty() ) {
					// we can't reduce enough to avoid errors, but we can still reduce the set to give the user
					// some correctly matched values
					ids = m.getCDHPartyIds(null,EBS_ADDRESS_CONTACT_ORDERING,AccountMatchEmptyMode.INTERSECT_MODE);
					if(! ids.isEmpty()) {
						m.retainCDHPartyIds(ids);
					}
				}
			}
		}
//for-reference		super.filter();
//for-reference		for(OrderParty m : orderParties) {
//for-reference			if(m.filterAccountIds(m.getSalesAccountIds(),m.refSalesAccountId) > 1) {
//for-reference				m.filterBySuperRegion(accountMap);
//for-reference				if(m.filterAccountIds(m.getSalesAccountIds(),null) > 1) {
//for-reference					if(allowContactOnDifferentAccount) {
//for-reference						m.filterCDHPartyIds(m.getContactCDHPartyIds(),null);
//for-reference					}
//for-reference					else {
//for-reference						m.filterAccountIds(m.contactMapMap.keySet(),null);
//for-reference					}
//for-reference				}
//for-reference			}
//for-reference			m.filterByCountry();
//for-reference			m.filterByEmail();
//for-reference			m.filterAccountIds(m.getSalesAccountIds(),m.getLegalEntityId());
//for-reference		}
//for-reference		findContactsByEmail();
	}

	/**
	 * Error reporting.  This would be where we could define some messages to be warnings.
	 */
	public void errorsAndWarningsReporting() {
		errorReporting();
//for-reference		Set<SObject> hasEntitleToOrSoldTo = new Set<SObject>();
//for-reference		for(OrderParty m : orderParties) {
//for-reference			m.errorMessages.clear();
//for-reference			m.warnMessages.clear();
//for-reference			ebsAccountErrorReporting(m,m.errorMessages,m.warnMessages);
//for-reference			addressErrorReporting(m,m.errorMessages,m.warnMessages);
//for-reference			contactErrorReporting(m,m.errorMessages,m.warnMessage);
//for-reference			salesErrorReporting(m,m.errorMessages,m.warnMessages);
//for-reference			partnerErrorReporting(m,m.warnMessages);
//for-reference			if( (m.toType == AccountToType.ENTITLE_TO || m.toType == AccountToType.SOLD_TO)
//for-reference				&& m.sourceObject != null
//for-reference				&& m.errorMessages.isEmpty())
//for-reference			{
//for-reference				hasEntitleToOrSoldTo.add(m.sourceObject);
//for-reference			}
//for-reference		}
//for-reference		// convert errors to warnings
//for-reference		for(OrderParty m : orderParties) {
//for-reference			if(m.toType == AccountToType.SHIP_TO || m.toType == AccountToType.LINE_ENTITLE_TO 
//for-reference				|| ((m.toType == AccountToType.ENTITLE_TO || m.toType == AccountToType.SOLD_TO)
//for-reference					 && hasEntitleToOrSoldTo.contains(m.sourceObject)) )
//for-reference			{
//for-reference				m.warnMessages.addAll(m.errorMessages);
//for-reference				m.errorMessages.clear();
//for-reference			}
//for-reference		}
	}

	/**
	 * Use the old assignment logic to maximumize the chances
	 * of assigning refOppId values.
	 */
	public void assignRefOppId() {
		for(OrderParty m : orderParties) {
			if(! potentialOppMap.containsKey(m.refOppId)) {
				m.refOppId = oppIdByOpportunityNumber.get(m.opportunityNumber);
//for-reference				if(m.refOppId == null && m.oracleOrderNumber != null) {
//for-reference					Set<Id> oppIds = oppIdsByOracleOrderNumber.get(m.oracleOrderNumber);
//for-reference					if(oppIds != null && ! oppIds.isEmpty()) {
//for-reference						m.refOppId = oppIds.iterator().next();
//for-reference					}
//for-reference				}
//for-reference				if(m.refOppId == null && m.oracleOrderId != null) {
//for-reference					Set<Id> oppIds = oppIdsByOracleOrderId.get(m.oracleOrderId);
//for-reference					if(oppIds != null && ! oppIds.isEmpty()) {
//for-reference						m.refOppId = oppIds.iterator().next();
//for-reference					}
//for-reference				}
			}
		}
	}

//for-reference	/**
//for-reference	 * Use new assignment logic to maximumize the chances of 
//for-reference	 * assigning the correct refOppId values.
//for-reference	 */
//for-reference	public void preAssignRefOppId() {
//for-reference		for(OrderParty m : orderParties) {
//for-reference			if(! potentialOppMap.containsKey(m.refOppId)) {
//for-reference				m.refOppId = null;
//for-reference				if(m.oracleOrderNumber != null) {
//for-reference					if(m.opportunityNumber != null) {
//for-reference						Id oppId = oppIdByOpportunityNumber.get(m.opportunityNumber);
//for-reference						if(oppId != null && potentialOppMap.get(oppId).OracleOrderNumber__c == m.oracleOrderNumber) {
//for-reference							m.refOppId = oppId;
//for-reference						}
//for-reference					}
//for-reference					if(m.refOppId == null) {
//for-reference						Id accountId = null;
//for-reference						Set<Id> oppIds = oppIdsByOracleOrderNumber.get(m.oracleOrderNumber);
//for-reference						if(oppIds != null) {
//for-reference							for(Id oppId : oppIds) {
//for-reference								Opportunity opp = potentialOppMap.get(oppId);
//for-reference								if( accountId != opp.AccountId && accountId != null) {
//for-reference									m.refOppId = null;
//for-reference									break;
//for-reference								}
//for-reference								accountId = opp.AccountId;
//for-reference								m.refOppId = oppId;
//for-reference							}
//for-reference						}
//for-reference					}
//for-reference				}
//for-reference			}
//for-reference		}
//for-reference	}

	@TestVisible
	private Map<String,Id> oppIdByOpportunityNumber {
		get {
			if(oppIdByOpportunityNumber == null) {
				oppIdByOpportunityNumber = new Map<String,Id>();
				for(Opportunity opp : potentialOppMap.values()) {
					if(opp.OpportunityNumber__c != null) {
						oppIdByOpportunityNumber.put(opp.OpportunityNumber__c,opp.Id);
					}
				}
			}
			return oppIdByOpportunityNumber;
		}
		set;
	}

//for-reference	@TestVisible
//for-reference	private Map<String,Set<Id>> oppIdsByOracleOrderNumber {
//for-reference		get {
//for-reference			if(oppIdsByOracleOrderNumber == null) {
//for-reference				oppIdsByOracleOrderNumber = new Map<String,Set<Id>>();
//for-reference				for(Opportunity opp : potentialOppMap.values()) {
//for-reference					if(opp.OracleOrderNumber__c != null) {
//for-reference						Set<Id> oppIds = oppIdsByOracleOrderNumber.get(opp.OracleOrderNumber__c);
//for-reference						if(oppIds == null) {
//for-reference							oppIds = new Set<Id>();
//for-reference							oppIdsByOracleOrderNumber.put(opp.OracleOrderNumber__c,oppIds);
//for-reference						}
//for-reference						oppIds.add(opp.Id);
//for-reference					}
//for-reference				}
//for-reference			}
//for-reference			return oppIdsByOracleOrderNumber;
//for-reference		}
//for-reference		set;
//for-reference	}

//for-reference	@TestVisible
//for-reference	private Map<String,Set<Id>> oppIdsByOracleOrderId {
//for-reference		get {
//for-reference			if(oppIdsByOracleOrderId == null) {
//for-reference				oppIdsByOracleOrderId = new Map<String,Set<Id>>();
//for-reference				for(Opportunity opp : potentialOppMap.values()) {
//for-reference					if(opp.OracleOrderNumber__c != null) {
//for-reference						Set<Id> oppIds = oppIdsByOracleOrderId.get(opp.OracleOrderId__c);
//for-reference						if(oppIds == null) {
//for-reference							oppIds = new Set<Id>();
//for-reference							oppIdsByOracleOrderId.put(opp.OracleOrderId__c,oppIds);
//for-reference						}
//for-reference						oppIds.add(opp.Id);
//for-reference					}
//for-reference				}
//for-reference			}
//for-reference			return oppIdsByOracleOrderId;
//for-reference		}
//for-reference		set;
//for-reference	}

	@TestVisible
	private Map<Id,Opportunity> potentialOppMap {
		get {
			if(potentialOppMap == null) {
				potentialOppMap = new Map<Id,Opportunity>();
				Set<Id> oppIds = new Set<Id>();
				for(OrderParty m : orderParties) {
					if(m.refOppId != null && m.getRefOpp() == null) {
						oppIds.add(m.refOppId);
					}
				}
				if(! oppIds.isEmpty()) {
					potentialOppMap.putAll( new Map<Id,Opportunity>( [
						select
							AccountId,
							OpportunityNumber__c,
							OracleOrderNumber__c,
							OracleOrderId__c
						from Opportunity
						where Id in :oppIds ] ) );
				}
				Set<String> opportunityNumbers = new Set<String>();
//for-reference				Set<String> oracleOrderNumbers = new Set<String>();
//for-reference				Set<String> oracleOrderIds = new Set<String>();
				for(OrderParty m : orderParties) {
					if(m.getRefOpp() == null && ! potentialOppMap.containsKey(m.refOppId)) {
						if(m.opportunityNumber != null) {
							opportunityNumbers.add(m.opportunityNumber);
						}
//for-reference						if(m.oracleOrderNumber != null) {
//for-reference							oracleOrderNumbers.add(m.oracleOrderNumber);
//for-reference						}
//for-reference						if(m.oracleOrderId != null) {
//for-reference							oracleOrderIds.add(m.oracleOrderId);
//for-reference						}
					}
				}
				if(! (opportunityNumbers.isEmpty() /* todo && oracleOrderNumbers.isEmpty() && oracleOrderIds.isEmpty() */)) {
					potentialOppMap.putAll( new Map<Id,Opportunity>( [
						select
							AccountId,
							OpportunityNumber__c,
							OracleOrderNumber__c,
							OracleOrderId__c
						from Opportunity
						where OpportunityNumber__c in :opportunityNumbers
//for-reference							or OracleOrderNumber__c in :oracleOrderNumbers
//for-reference							or OracleOrderId__c in :oracleOrderIds 
							] ) );
				}
			}
			return potentialOppMap;
		}
		set;
	}

	/**
	 * Useful method to get a list of OrderParty from a list of orderHeaderStagings and a list of order staging lines.
	 * If the orderLineStagings list is null, the list will be queried.
	 * 
	 * @param orderHeaderStagings list of orderHeaderStagings
	 * @param orderLineStagings list of order staging lines for the orderHeaderStagings, maybe null
	 */
	public static List<OrderParty> getOrderParty(
		List<Opportunity_Header_Staging__c> orderHeaderStagings,
		List<Opportunity_Line_Staging__c> orderLineStagings)
	{
		List<OrderParty> retval = new List<OrderParty>();
		Map<Id,Opportunity_Header_Staging__c> orderHeaderStagingMap = new Map<Id,Opportunity_Header_Staging__c>();
		for(Opportunity_Header_Staging__c header : orderHeaderStagings) {
			addOrderHeaderStaging(retval,header);
			orderHeaderStagingMap.put(header.Id,header);
		}
		for(Opportunity_Line_Staging__c stagingLine : orderLineStagings) {
			stagingLine.Opportunity_Stage_Header_ID__r = orderHeaderStagingMap.get(stagingLine.Opportunity_Stage_Header_ID__c);
			addOrderLineStaging(retval,stagingLine,stagingLine.Opportunity_Stage_Header_ID__r);
		}
		return retval;
	}

	/**
	 * Called to update the orderHeaderStaging and order staging lines reference
	 * by the OrderParty with the results from the matching and filtering.
	 */
	public void assignFrom() {
		assignFrom(orderParties);
	}

	/**
	 * Return the list of Match_and_Validation_Error__c objects and update the 
	 * respective orderHeaderStaging statuses to ERROR_STATUS when appropriate.
	 * This method will only work if the Orders data was initialized 
	 * from orderHeaderStagings and order staging lines.
	 * 
	 * @return a list of Match_and_Validation_Error__c object which may be inserted
	 */
	public List<Match_and_Validation_Error__c> getErrorAndWarnList() {
		return getErrorAndWarnList(null);
	}


	/**
	 * Return the list of Match_and_Validation_Error__c objects and update the 
	 * respective orderHeaderStaging statuses to ERROR_STATUS when appropriate.
	 * ThisFg method will only work if the Orders data was initialized 
	 * from orderHeaderStagings and order staging lines.
	 * 
	 * @ignoreErrorsPattern pattern of errors which should not set an ERROR_STATUS
	 * @return a list of Match_and_Validation_Error__c object which may be inserted
	 */
	public List<Match_and_Validation_Error__c> getErrorAndWarnList(Pattern ignoreErrorsPattern) {
		return getErrorAndWarnList(ignoreErrorsPattern,orderParties);
	}

	/**
	 * Retrieve the list of order staging lines that have been updated.
	 * Use an update call to commit the updates.
	 * 
	 * @retval updated list of order staging lines
	 */
	public List<Opportunity_Line_Staging__c> getUpdatedOrderLineStagings() {
		return getUpdatedOrderLineStagings(orderParties);
	}

	private static void addOrderLineStaging(List<OrderParty> orderPartyList,Opportunity_Line_Staging__c stagingLine,Opportunity_Header_Staging__c header) {
		orderPartyList.add(new OrderParty(stagingLine,header));
	}

	private static void addOrderHeaderStaging(List<OrderParty> orderPartyList,Opportunity_Header_Staging__c header) {
		orderPartyList.add(getBillToOrderParty(header));
		orderPartyList.add(getEntitleToOrderParty(header));
		orderPartyList.add(getShipToOrderParty(header));
		orderPartyList.add(getSoldToOrderParty(header));
	}

	private static Id refIdValue(Id retval, String defaultValue) {
		if(retval == null) {
			try {
				retval = defaultValue;
			}
			catch(Exception ex) {}
		}
		return retval;
	}

	private static String getErrorIdentifier(Opportunity_Header_Staging__c header) {
		String errorIdentifier = 'In';
		if ((header.Opportunity_ID__c != null && header.Opportunity_ID__c!='') ||
					(header.Opportunity_Number__c != null && header.Opportunity_Number__c!='')) 
		{
			errorIdentifier = 'D';
			if(header.Order_Source__c != 'SFDC_Sales') {
				errorIdentifier = 'I';
			}
		}
		return errorIdentifier;
	}

	private static OrderParty getBillToOrderParty(Opportunity_Header_Staging__c header) {
		System.assertNotEquals(null,header,'Missing orderHeaderStaging');
		OrderParty retval = 
			new OrderParty(
				AccountToType.BILL_TO,
				refIdValue(header.Opportunity_ID__c,null), // we need to make certain we do not use this to override values
				null, // refOppLineId
				header.Bill_To_Account_Number__c,
				header.Bill_To_CDH_Party_Number_Account__c,
				header.Bill_To_Address_CDH_Party_Site_Number__c,
				header.Bill_To_CDH_Party_Number__c,
				null, // header.SuperRegion__c -> unknown
				header.Bill_To_Country__c,
				header.Bill_To_Contact_Email__c,
				header.Opportunity_Number__c, // we need to be certain we do not use this to override values
				header.Oracle_Order_Number__c, // we need to be certain we do not use this to override values
				header.Oracle_Order_ID__c, // we need to be certain we do not use this to override values
				getErrorIdentifier(header),
				header.Bill_To_Party_Type__c,
				header.Operating_Unit__c,
				header.Order_Status__c,
				header.Origin__c,
				header.Order_Source__c,
				header,
				null );
		retval.refEBSAccountId = header.Bill_To_Account__c;
		retval.refAddressId = header.Bill_To_Address__c;
		retval.refContactId = header.Bill_To_Contact__c;
//		if(retval.refEBSAccountId == null && retval.refAddressId == null && retval.refContactId == null) {
		retval.refSalesAccountId = header.Bill_To_Sales_Account__c;
//		}
		return retval;
	}

	private static OrderParty getEntitleToOrderParty(Opportunity_Header_Staging__c header) {
		System.assertNotEquals(null,header,'Missing orderHeaderStaging');
		OrderParty retval = 
			new OrderParty(
				AccountToType.ENTITLE_TO,
				refIdValue(header.Opportunity_ID__c,null), // we need to make certain we do not use this to override values
				null, // refOppLineId
				header.Entitle_To_Account_Number__c,
				header.Entitle_To_CDH_Party_Number_Account__c,
				header.Entitle_To_Address_CDH_Party_Site_Number__c,
				header.Entitle_To_CDH_Party_Number__c,
				null, // header.SuperRegion__c -> unknown
				header.Entitle_To_Country__c,
				header.Entitle_To_Contact_Email__c,
				header.Opportunity_Number__c, // we need to be certain we do not use this to override values
				header.Oracle_Order_Number__c, // we need to be certain we do not use this to override values
				header.Oracle_Order_ID__c, // we need to be certain we do not use this to override values
				getErrorIdentifier(header),
				header.Entitle_To_Party_Type__c,
				header.Operating_Unit__c,
				header.Order_Status__c,
				header.Origin__c,
				header.Order_Source__c,
				header,
				null );
		retval.refEBSAccountId = header.Entitle_To_Account__c;
		retval.refAddressId = header.Entitle_To_Address__c;
		retval.refContactId = header.Entitle_To_Contact__c;
//		if(retval.refEBSAccountId == null && retval.refAddressId == null && retval.refContactId == null) {
		retval.refSalesAccountId = header.Entitle_To_Sales_Account__c;
//		}
		return retval;
	}

	private static OrderParty getShipToOrderParty(Opportunity_Header_Staging__c header) {
		System.assertNotEquals(null,header,'Missing orderHeaderStaging');
		OrderParty retval = 
			new OrderParty(
				AccountToType.SHIP_TO,
				refIdValue(header.Opportunity_ID__c,null), // we need to make certain we do not use this to override values
				null, // refOppLineId
				header.Ship_To_Account_Number__c,
				header.Ship_To_CDH_Party_Number_Account__c,
				header.Ship_To_Address_CDH_Party_Site_Number__c,
				header.Ship_To_CDH_Party_Number__c,
				null, // header.SuperRegion__c -> unknown
				header.Ship_To_Country__c,
				header.Ship_To_Contact_Email__c,
				header.Opportunity_Number__c, // we need to be certain we do not use this to override values
				header.Oracle_Order_Number__c, // we need to be certain we do not use this to override values
				header.Oracle_Order_ID__c, // we need to be certain we do not use this to override values
				getErrorIdentifier(header),
				header.Ship_To_Party_Type__c,
				header.Operating_Unit__c,
				header.Order_Status__c,
				header.Origin__c,
				header.Order_Source__c,
				header,
				null );
		retval.refEBSAccountId = header.Ship_To_Account__c;
		retval.refAddressId = header.Ship_To_Address__c;
		retval.refContactId = header.Ship_To_Contact__c;
//		if(retval.refEBSAccountId == null && retval.refAddressId == null && retval.refContactId == null) {
		retval.refSalesAccountId = header.Ship_To_Sales_Account__c;
//		}
		return retval;
	}

	private static OrderParty getSoldToOrderParty(Opportunity_Header_Staging__c header) {
		System.assertNotEquals(null,header,'Missing orderHeaderStaging');
		OrderParty retval = 
			new OrderParty(
				AccountToType.SOLD_TO,
				refIdValue(header.Opportunity_ID__c,null), // we need to make certain we do not use this to override values
				null, // refOppLineId
				header.Sold_To_Account_Number__c,
				header.Sold_To_CDH_Party_Number_Account__c,
				header.Sold_To_Address_CDH_Party_Site_Number__c,
				header.Sold_To_CDH_Party_Number__c,
				null, // header.SuperRegion__c -> unknown
				header.Sold_To_Country__c,
				header.Sold_To_Contact_Email__c,
				header.Opportunity_Number__c, // we need to be certain we do not use this to override values
				header.Oracle_Order_Number__c, // we need to be certain we do not use this to override values
				header.Oracle_Order_ID__c, // we need to be certain we do not use this to override values
				getErrorIdentifier(header),
				header.Sold_To_Party_Type__c,
				header.Operating_Unit__c,
				header.Order_Status__c,
				header.Origin__c,
				header.Order_Source__c,
				header,
				null );
		retval.refEBSAccountId = header.Sold_To_Account__c;
		retval.refAddressId = header.Sold_To_Address__c;
		retval.refContactId = header.Sold_To_Contact__c;
//		if(retval.refEBSAccountId == null && retval.refAddressId == null && retval.refContactId == null) {
		retval.refSalesAccountId = header.Sold_To_Sales_Account__c;
//		}
		return retval;
	}

	private void assignFrom(List<OrderParty> orderPartyList) {
		for(OrderParty orderParty : orderPartyList) {
			assignFrom(orderParty);
		}
	}

	private void assignFrom(OrderParty orderParty) {
		if(orderParty.toType == AccountToType.BILL_TO) {
			assignFromBillTo(orderParty);
		}
		else if(orderParty.toType == AccountToType.ENTITLE_TO) {
			assignFromEntitleTo(orderParty);
		}
		else if(orderParty.toType == AccountToType.SHIP_TO) {
			assignFromShipTo(orderParty);
		}
		else if(orderParty.toType == AccountToType.SOLD_TO) {
			assignFromSoldTo(orderParty);
		}
		else {
			System.assertEquals(AccountToType.LINE_ENTITLE_TO,orderParty.toType);
			assignFromLineEntitleTo(orderParty);
		}
	}

	private Id selectSalesAccountId(OrderParty orderParty,Id retval) {
		Set<Id> salesAccountIds = new Set<Id>();
		if(retval == null && orderParty.cdhPartyNumber != null && orderParty.useProactiveMatching()) {
			// DE8790 - Find if there is a single non-partner - OU filtered sales account.
			List<Account> accounts = accountsKeyMap.get(cdhPartyNumberKey(orderParty.cdhPartyNumber));
			if(accounts != null) {
				String accountRecordTypeName = accountRecordTypeNameByOperatingUnit.get((''+orderParty.operatingUnit).toUpperCase());
				if(accountRecordTypeName == null) {
					accountRecordTypeName = 'SALES'; // keep all non-partner accounts
				}
				for(Account a : accounts) {
					if(accountRecordTypeName == a.RecordType.Name || (accountRecordTypeName == 'SALES' && ! isPartner(a))) {
						salesAccountIds.add(a.Id);
					}
				}
			}
		}
		if(salesAccountIds.size() == 1) {
			for(Id salesAccountId : salesAccountIds) {
				// DE8790 - use the only sales account that matches the cdh party number
				retval = salesAccountId;
			}
		}
		else {
			Id ebsSalesAccountId = null;
			if(orderParty.ebsAccountMapMap.size() == 1) {
				ebsSalesAccountId = orderParty.ebsAccountMapMap.keySet().iterator().next();
			}
			Id addressSalesAccountId = null;
			if(orderParty.addressMapMap.size() == 1) {
				addressSalesAccountId = orderParty.addressMapMap.keySet().iterator().next();
			}
			Id contactSalesAccountId = null;
			if(orderParty.contactMapMap.size() == 1) {
				contactSalesAccountId = orderParty.contactMapMap.keySet().iterator().next();
			}
			// always accept the sales account if there is one and only one value
			if(ebsSalesAccountId != null && ebsSalesAccountId == addressSalesAccountId && (ebsSalesAccountId == contactSalesAccountId || orderParty.contactMapMap.isEmpty())) {
				retval = ebsSalesAccountId;
			}
			else if ( orderParty.useProactiveMatching() ) {
				// in this scenario we don't care about ebsSalesAccountId ..., because the user can create that if needed
				if(addressSalesAccountId != null && addressSalesAccountId == contactSalesAccountId) {
					retval = addressSalesAccountId;
				}
				else {
					// US69227
					Set<Id> ids = orderParty.addressMapMap.keySet().clone();
					ids.retainAll(orderParty.contactMapMap.keySet());
					if(ids.size() == 1) {
						retval = ids.iterator().next();
					}
					else {
						// US69226
						ids = orderParty.ebsAccountMapMap.keySet().clone();
						ids.addAll(orderParty.addressMapMap.keySet());
						ids.addAll(orderParty.contactMapMap.keySet());
						if(ids.size() == 1) {
							retval = ids.iterator().next();
						}
					}
				}
			}
		}
		return retval;
	}

	private void assignFromBillTo(OrderParty orderParty) {
		assignFromBillTo((Opportunity_Header_Staging__c)orderParty.sourceObject,orderParty);
	}

	private void assignFromBillTo(Opportunity_Header_Staging__c header,OrderParty orderParty) {
		System.assertEquals(AccountToType.BILL_TO,orderParty.toType);
		// Contact contact = orderParty.getBestContact(true); // accept the best remaining result
		Contact contact = orderParty.getContact(); // only accept a unique result
		if(contact == null && header.Bill_To_Contact__r != null) {
			contact = header.Bill_To_Contact__r;
			orderParty.setContact(contact);
		}
		Id contactId = null;
		if(contact != null) {
			contactId = contact.Id;
		}
		else {
			contact = orderParty.getBestContact(true);
		}
		header.Bill_To_Contact__r = contact;
		if(contactId != header.Bill_To_Contact__c) {
			header.Bill_To_Contact__c = contactId;
			orderParty.updated = true;
		}
		Id addressId = null;
		// Address__c address = orderParty.getBestAddress(true); // accept the best remaining result
		Address__c address = orderParty.getAddress(); // only accept a unique result
		if(address != null) {
			addressId = address.Id;
		}
		else {
			address = orderParty.getBestAddress(true);
		}
		header.Bill_To_Address__r = address;
		if(addressId != header.Bill_To_Address__c) {
			header.Bill_To_Address__c = addressId;
			orderParty.updated = true;
		}
		Id ebsAccountId = null;
		// EBS_Account__c ebsAccount = orderParty.getBestEBSAccount(); // accept the best remaining result
		EBS_Account__c ebsAccount = orderParty.getEBSAccount(); // only accept a unique result
		if(ebsAccount != null) {
			ebsAccountId = ebsAccount.Id;
		}
		if(ebsAccountId != header.Bill_To_Account__c) {
			header.Bill_To_Account__r = ebsAccount;
			header.Bill_To_Account__c = ebsAccountId;
			orderParty.updated = true;
		}
		Id salesAccountIdOrig = header.Bill_To_Sales_Account__c;
		Id salesAccountId = selectSalesAccountId(orderParty,salesAccountIdOrig);
		if(salesAccountId != salesAccountIdOrig) {
			header.Bill_To_Sales_Account__c = salesAccountId;
			if(salesAccountIdOrig == null && orderParty.useProactiveMatching() && proactiveSalesAccountErrorSetting) {
				orderParty.errorMessages.add(System.Label.C360_D31);
			}
		}
	}

	private void assignFromEntitleTo(OrderParty orderParty) {
		assignFromEntitleTo((Opportunity_Header_Staging__c)orderParty.sourceObject,orderParty);
	}

	private void assignFromEntitleTo(Opportunity_Header_Staging__c header,OrderParty orderParty) {
		System.assertEquals(AccountToType.ENTITLE_TO,orderParty.toType);
		// Contact contact = orderParty.getBestContact(true); // accept the best remaining result
		Contact contact = orderParty.getContact(); // only accept a unique result
		if(contact == null && header.Entitle_To_Contact__r != null) {
			contact = header.Entitle_To_Contact__r;
			orderParty.setContact(contact);
		}
		Id contactId = null;
		if(contact != null) {
			contactId = contact.Id;
		}
		else {
			contact = orderParty.getBestContact(true);
		}
		header.Entitle_To_Contact__r = contact;
		if(contactId != header.Entitle_To_Contact__c) {
			header.Entitle_To_Contact__c = contactId;
			orderParty.updated = true;
		}
		Id addressId = null;
		// Address__c address = orderParty.getBestAddress(true); // accept the best remaining result
		Address__c address = orderParty.getAddress(); // only accept a unique result
		if(address != null) {
			addressId = address.Id;
		}
		else {
			address = orderParty.getBestAddress(true);
		}
		header.Entitle_To_Address__r = address;
		if(addressId != header.Entitle_To_Address__c) {
			header.Entitle_To_Address__c = addressId;
			orderParty.updated = true;
		}
		Id ebsAccountId = null;
		// EBS_Account__c ebsAccount = orderParty.getBestEBSAccount(); // accept the best remaining result
		EBS_Account__c ebsAccount = orderParty.getEBSAccount(); // only accept a unique result
		if(ebsAccount != null) {
			ebsAccountId = ebsAccount.Id;
		}
		if(ebsAccountId != header.Entitle_To_Account__c) {
			header.Entitle_To_Account__r = ebsAccount;
			header.Entitle_To_Account__c = ebsAccountId;
			orderParty.updated = true;
		}
		Id salesAccountIdOrig = header.Entitle_To_Sales_Account__c;
		Id salesAccountId = selectSalesAccountId(orderParty,salesAccountIdOrig);
		if(salesAccountId != salesAccountIdOrig) {
			header.Entitle_To_Sales_Account__c = salesAccountId;
			if(salesAccountIdOrig == null && orderParty.useProactiveMatching() && proactiveSalesAccountErrorSetting) {
				orderParty.errorMessages.add(System.Label.C360_D32);
			}
		}
	}

	private void assignFromShipTo(OrderParty orderParty) {
		assignFromShipTo((Opportunity_Header_Staging__c)orderParty.sourceObject,orderParty);
	}

	private void assignFromShipTo(Opportunity_Header_Staging__c header,OrderParty orderParty) {
		System.assertEquals(AccountToType.SHIP_TO,orderParty.toType);
		// Contact contact = orderParty.getBestContact(true); // accept the best remaining result
		Contact contact = orderParty.getContact(); // only accept a unique result
		if(contact == null && header.Ship_To_Contact__r != null) {
			contact = header.Ship_To_Contact__r;
			orderParty.setContact(contact);
		}
		Id contactId = null;
		if(contact != null) {
			contactId = contact.Id;
		}
		else {
			contact = orderParty.getBestContact(true);
		}
		header.Ship_To_Contact__r = contact;
		if(contactId != header.Ship_To_Contact__c) {
			header.Ship_To_Contact__c = contactId;
			orderParty.updated = true;
		}
		Id addressId = null;
		// Address__c address = orderParty.getBestAddress(true); // accept the best remaining result
		Address__c address = orderParty.getAddress(); // only accept a unique result
		if(address != null) {
			addressId = address.Id;
		}
		else {
			address = orderParty.getBestAddress(true);
		}
		header.Ship_To_Address__r = address;
		if(addressId != header.Ship_To_Address__c) {
			header.Ship_To_Address__c = addressId;
			orderParty.updated = true;
		}
		Id ebsAccountId = null;
		// EBS_Account__c ebsAccount = orderParty.getBestEBSAccount(); // accept the best remaining result
		EBS_Account__c ebsAccount = orderParty.getEBSAccount(); // only accept a unique result
		if(ebsAccount != null) {
			ebsAccountId = ebsAccount.Id;
		}
		if(ebsAccountId != header.Ship_To_Account__c) {
			header.Ship_To_Account__r = ebsAccount;
			header.Ship_To_Account__c = ebsAccountId;
			orderParty.updated = true;
		}
		Id salesAccountIdOrig = header.Ship_To_Sales_Account__c;
		Id salesAccountId = selectSalesAccountId(orderParty,salesAccountIdOrig);
		if(salesAccountId != salesAccountIdOrig) {
			header.Ship_To_Sales_Account__c = salesAccountId;
			if(salesAccountIdOrig == null && orderParty.useProactiveMatching() && proactiveSalesAccountErrorSetting) {
				orderParty.errorMessages.add(System.Label.C360_D33);
			}
		}
	}

	private void assignFromSoldTo(OrderParty orderParty) {
		assignFromSoldTo((Opportunity_Header_Staging__c)orderParty.sourceObject,orderParty);
	}

	private void assignFromSoldTo(Opportunity_Header_Staging__c header,OrderParty orderParty) {
		System.assertEquals(AccountToType.SOLD_TO,orderParty.toType);
		// Contact contact = orderParty.getBestContact(true); // accept the best remaining result
		Contact contact = orderParty.getContact(); // only accept a unique result
		if(contact == null && header.Sold_To_Contact__r != null) {
			contact = header.Sold_To_Contact__r;
			orderParty.setContact(contact);
		}
		Id contactId = null;
		if(contact != null) {
			contactId = contact.Id;
		}
		else {
			contact = orderParty.getBestContact(true);
		}
		header.Sold_To_Contact__r = contact;
		if(contactId != header.Sold_To_Contact__c) {
			header.Sold_To_Contact__c = contactId;
			orderParty.updated = true;
		}
		Id addressId = null;
		// Address__c address = orderParty.getBestAddress(true); // accept the best remaining result
		Address__c address = orderParty.getAddress(); // only accept a unique result
		if(address != null) {
			addressId = address.Id;
		}
		else {
			address = orderParty.getBestAddress(true);
		}
		header.Sold_To_Address__r = address;
		if(addressId != header.Sold_To_Address__c) {
			header.Sold_To_Address__c = addressId;
			orderParty.updated = true;
		}
		Id ebsAccountId = null;
		// EBS_Account__c ebsAccount = orderParty.getBestEBSAccount(); // accept the best remaining result
		EBS_Account__c ebsAccount = orderParty.getEBSAccount(); // only accept a unique result
		if(ebsAccount != null) {
			ebsAccountId = ebsAccount.Id;
		}
		if(ebsAccountId != header.Sold_To_Account__c) {
			header.Sold_To_Account__r = ebsAccount;
			header.Sold_To_Account__c = ebsAccountId;
			orderParty.updated = true;
		}
		Id salesAccountIdOrig = header.Sold_To_Sales_Account__c;
		Id salesAccountId = selectSalesAccountId(orderParty,salesAccountIdOrig);
		if(salesAccountId != salesAccountIdOrig) {
			header.Sold_To_Sales_Account__c = salesAccountId;
			if(salesAccountIdOrig == null && orderParty.useProactiveMatching() && proactiveSalesAccountErrorSetting) {
				orderParty.errorMessages.add(System.Label.C360_D34);
			}
		}
	}

	private void assignFromLineEntitleTo(OrderParty orderParty) {
		assignFromLineEntitleTo((Opportunity_Line_Staging__c)orderParty.sourceObject,orderParty);
	}

	private void assignFromLineEntitleTo(Opportunity_Line_Staging__c stagingLine,OrderParty orderParty) {
		System.assertEquals(AccountToType.LINE_ENTITLE_TO,orderParty.toType);
		// Contact contact = orderParty.getBestContact(true); // accept the best remaining result
		Contact contact = orderParty.getContact(); // only accept a unique result
		if(contact == null && stagingLine.Entitle_To_Contact__r != null) {
			contact = stagingLine.Entitle_To_Contact__r;
			orderParty.setContact(contact);
		}
		Id contactId = null;
		if(contact != null) {
			contactId = contact.Id;
		}
		else {
			contact = orderParty.getBestContact(true);
		}
		stagingLine.Entitle_To_Contact__r = contact;
		if(contactId != stagingLine.Entitle_To_Contact__c) {
			stagingLine.Entitle_To_Contact__c = contactId;
			orderParty.updated = true;
		}
		Id addressId = null;
		// Address__c address = orderParty.getBestAddress(true); // accept the best remaining result
		Address__c address = orderParty.getAddress(); // only accept a unique result
		if(address != null) {
			addressId = address.Id;
		}
		else {
			address = orderParty.getBestAddress(true);
		}
		stagingLine.Entitle_To_Address__r = address;
		if(addressId != stagingLine.Entitle_To_Address__c) {
			stagingLine.Entitle_To_Address__c = addressId;
			orderParty.updated = true;
		}
		Id ebsAccountId = null;
		// EBS_Account__c ebsAccount = orderParty.getBestEBSAccount(); // accept the best remaining result
		EBS_Account__c ebsAccount = orderParty.getEBSAccount(); // only accept a unique result
		if(ebsAccount != null) {
			ebsAccountId = ebsAccount.Id;
		}
		if(ebsAccountId != stagingLine.Entitle_To_Account__c) {
			stagingLine.Entitle_To_Account__r = ebsAccount;
			stagingLine.Entitle_To_Account__c = ebsAccountId;
			orderParty.updated = true;
		}
		Id salesAccountIdOrig = stagingLine.Entitle_To_Sales_Account__c;
		Id salesAccountId = selectSalesAccountId(orderParty,salesAccountIdOrig);
		if(salesAccountId != salesAccountIdOrig) {
			stagingLine.Entitle_To_Sales_Account__c = salesAccountId;
			if(salesAccountIdOrig == null && orderParty.useProactiveMatching() && proactiveSalesAccountErrorSetting) {
				orderParty.errorMessages.add(System.Label.C360_D35);
			}
		}
	}

	private static Match_and_Validation_Error__c createMatchingAndValidationError(
		Pattern ignoreErrorsPattern,
		OrderParty orderParty,
		Id headerId,
		Id stagingLineId,
		String reason,
		String message,
		Boolean warning,
		Boolean always )
	{
		String fieldName = FIELDNAME_BY_MESSAGE.get(message);
		String errorType = 'Header';
		Opportunity_Header_Staging__c header = orderParty.header;
		Opportunity_Line_Staging__c stagingLine = orderParty.stagingLine;
		if(stagingLine != null) {
			errorType = 'Line';
			message = message.replace('{lineStaging.Product_Code_Oracle__c}',''+stagingLine.Product_Code_Oracle__c)
				.replace('{lineStaging.Name}',''+stagingLine.Name);
		}
		// Indirect message errors start with an 'In' instead of a 'D'.
		if ( orderParty.errorIdentifier != 'D' && message.startsWith('D') ) {
			message = orderParty.errorIdentifier + message.substring(1);
		}
		String errorCode = message.split(':',2)[0];
		System.debug(message);
		warning = warning || (ignoreErrorsPattern != null && ignoreErrorsPattern.matcher(reason+':'+message).matches());
		Match_and_Validation_Error__c retval = new Match_and_Validation_Error__c(
			Error_Code__c = errorCode,
			Error_Description__c = message,
			Error_Type__c = errorType,
			Opportunity_Staging_Header__r = header,
			Opportunity_Staging_Header__c = headerId,
			Opportunity_Product_Staging__r = stagingLine,
			Opportunity_Product_Staging__c = stagingLineId,
			Related_Field_API_Name__c = fieldName );
		if(header != null /* && (! warning) */ )
		{
			if (always || header.Status__c != ERROR_STATUS) {
				header.Status__c = ERROR_STATUS;
//for-reference				header.ErrorMessage__c = details;
				orderParty.updated = true;
			}
		}
		System.debug(header);
		return retval;
	}

	public override Boolean ebsAccountErrorReporting(PartyData m,List<String> messages,List<String> messages2) {
		Boolean retval = false;
		if(m.oracleAccountNumber != null) {
			retval = super.ebsAccountErrorReporting(m,messages,messages2);
		}
		return retval;
	}

	public override Boolean addressErrorReporting(PartyData m,List<String> messages,List<String> messages2) {
		Boolean retval = false;
		if(m.cdhPartySiteNumber != null) {
			retval = super.addressErrorReporting(m,messages,messages2);
		}
		return retval;
	}

	public override Boolean contactErrorReporting(PartyData m,List<String> messages,List<String> messages2) {
		Boolean retval = false;
		if(m.contactCDHPartyNumber != null) {
			retval = super.contactErrorReporting(m,messages,messages2);
		}
		return retval;
	}

	private static List<Match_and_Validation_Error__c> getErrorAndWarnList(Pattern ignoreErrorsPattern,List<OrderParty> orderPartyList) {
		List<Match_and_Validation_Error__c> retval = new List<Match_and_Validation_Error__c>();
//for-reference		Map<Id,Id> lineIdMap = new Map<Id,Id>();
		Map<Id,OrderParty> orderPartyMap = new Map<Id,OrderParty>();
		for(OrderParty orderParty : orderPartyList) {
			String errorReason;
			Id headerId;
			Id stagingLineId = null;
			Boolean warning = false;
			Opportunity_Header_Staging__c header = orderParty.header;
			Opportunity_Line_Staging__c stagingLine = orderParty.stagingLine;
			if(orderParty.contactCDHPartyNumber != null && orderParty.getBestContact(true) == null) {
				EBS_Account__c ebsAccount = orderParty.getEBSAccount();
				Address__c address = orderParty.getAddress();
				if(ebsAccount != null && address != null && ebsAccount.Sales_Account__c == address.Sales_Account__c) {
					continue;
				}
				if(orderParty.partyType == 'PERSON' && orderParty.OracleAccountNumber != null && orderParty.cdhPartySiteNumber != null && orderParty.getBestEBSAccount() == null && orderParty.getBestAddress(true) == null) {
					continue;
				}
			}
			headerId = header.Id;
			errorReason = MATCHING_FAILURE_REASON;
			if(stagingLine == null) {
				orderPartyMap.put(headerId,orderParty);
			}
			else {
				stagingLineId = stagingLine.Id;
//for-reference				lineIdMap.put(headerId,stagingLineId);
				errorReason = MATCHING_FAILURE_REASON;
			}
//for-reference			if(stagingLineId != null || ! lineIdMap.containsKey(headerId)) {
//for-reference				lineIdMap.put(headerId,stagingLineId);
//for-reference			}
			for(String message : orderParty.errorMessages) {
				retval.add( createMatchingAndValidationError(
					ignoreErrorsPattern,
					orderParty,
					headerId,
					stagingLineId,
					errorReason,
					message,
					warning,
					false ) );
			}
			for(String message : orderParty.warnMessages) {
				retval.add( createMatchingAndValidationError(
					ignoreErrorsPattern,
					orderParty,
					headerId,
					stagingLineId,
					WARNING_REASON,
					message,
					true,
					false ) );
			}
		}
//for-reference		for(Id headerId : lineIdMap.keySet()) {
//for-reference			if(lineIdMap.get(headerId) == null) {
//for-reference				retval.add( createMatchingAndValidationError(
//for-reference					ignoreErrorsPattern,
//for-reference					orderPartyMap.get(headerId),
//for-reference					headerId,
//for-reference					null,
//for-reference					NO_LINES_REASON,
//for-reference					system.Label.C360_R38,
//for-reference					false,
//for-reference					true ) );
//for-reference			}
//for-reference		}
		return retval;
	}

	private static List<Opportunity_Line_Staging__c> getUpdatedOrderLineStagings(List<OrderParty> orderPartyList) {
		Set<Id> ids = new Set<Id>();
		List<Opportunity_Line_Staging__c> retval = new List<Opportunity_Line_Staging__c>();
		for(Account_Matching_Orders.OrderParty orderParty : orderPartyList) {
			if(orderParty.updated && orderParty.sourceObject instanceof Opportunity_Line_Staging__c) {
				Opportunity_Line_Staging__c stagingLine = (Opportunity_Line_Staging__c)orderParty.sourceObject;
				if(! ids.contains(stagingLine.Id)) {
					ids.add(stagingLine.Id);
					retval.add(stagingLine);
				}
			}
		}
		return retval;
	}

	/** 
	 * We consider this a sales error if there is not at least one sales account common for all three objects
	 */
	public override Boolean salesErrorReporting(PartyData m,List<String> messages,List<String> messages2) {
		Boolean ebsAccountError = (m.getEBSAccount() == null);
		Boolean addressError = (m.getAddress() == null);
		Boolean contactError = (m.getContact() == null);
		Boolean salesError = false;
		if((! allowDifferentSalesAccounts) || (m.refSalesAccount == null && m.refEBSAccount == null && m.refAddress == null && m.refContact == null)) {
			salesError = salesErrorReporting(m,messages,messages2,ebsAccountError,addressError,contactError);
		}
		else {
			Set<Id> ids = null;
			if(! ebsAccountError) {
				ids = m.getEBSAccountCDHPartyIds().clone();
				if(! addressError) {
					ids.retainAll(m.getAddressCDHPartyIds());
					salesError = ids.isEmpty();
					if(salesError) {
						String message = salesErrorMap.get(m.toType);
						if(message != null) {
							messages.add(message);
						}
					}
				}
			}
			else if(! addressError) {
				ids = m.getAddressCDHPartyIds();
			}
			if(! (ids == null || ids.isEmpty() || contactError)) {
				Set<Id> ids2 = ids.clone();
				ids2.retainAll(m.getContactCDHPartyIds());
				if(ids2.isEmpty()) {
					String message = salesErrorMap.get(m.toType);
					if(message != null) {
						messages2.add(message);
					}
				}
			}
		}
		return salesError;
	}

	/**
	 * Class representing matching data.
	 */
	public virtual class OrderParty extends Account_Matching.PartyData {
		/** Opportunity Number */
		public String opportunityNumber;
		/** Oracle Order Number */
		public String oracleOrderNumber;
		/** Purchase order number */
		public String oracleOrderId;
		/** Keep track of the header. */
		@TestVisible
		Opportunity_Header_Staging__c header = null;
		/** Keep track of the line. */
		@TestVisible
		Opportunity_Line_Staging__c stagingLine = null;
		/** It is a nice idea to keep a reference to the original object */
		public Object sourceObject;
		/** Keep track if the assignFrom methods update the source object */
		public Boolean updated = false;
		/** Keep track if this is direct or indirect */
		public String errorIdentifier;
		/** Keep track of party type */
		public String partyType;
		/** Operating Unit */
		public String operatingUnit;
		/** Order Status */
		public String orderStatus;
		/** Origin of staging record */
		public String orderOrigin;
		/** Order Source */
		public String orderSource;

		/** 
		 * Standard Contructor.
		 * 
		 * @param toType enum matching type
		 * @param refOppId the Id of the reference Opportunity
		 * @param refOppLineId the Id of the reference Opportunity Line Item
		 * @param accountNumber the sales account number
		 * @param cdhPartyNumber the CDH Party Number
		 * @param cdhPartySiteNumber the CDH Party Site Number
		 * @param contactCDHPartyNumber the Contact CDH Party Number
		 * @param superRegion to filter accounts with
		 * @param country to filter addresses with
		 * @param email to filter contacts with
		 * @param opportunityNumber to lookup the refOppId
		 * @param oracleOrderNumber to lookup the refOppId
		 * @param oracleOrderId to lookup the refOppId
		 * @param errorIdentifier prefix for error usually 'D', 'I', or 'In'
		 * @param partyType to use in preparing errors
		 * @param operatingUnit to filter record types with
		 * @param orderStatus to filter record types with
		 * @param header
		 * @param stagingLine
		 */
		public OrderParty(
			AccountToType toType,
			Id refOppId,
			Id refOppLineId,
			String oracleAccountNumber,
			String cdhPartyNumber,
			String cdhPartySiteNumber,
			String contactCDHPartyNumber,
			String superRegion,
			String country,
			String email,
			String opportunityNumber,
			String oracleOrderNumber,
			String oracleOrderId,
			String errorIdentifier,
			String partyType,
			String operatingUnit,
			String orderStatus,
			String orderOrigin,
			String orderSource,
			Opportunity_Header_Staging__c header,
			Opportunity_Line_Staging__c stagingLine)
		{
			super(
				toType,
				refOppId,
				refOppLineId,
				oracleAccountNumber,
				cdhPartyNumber,
				cdhPartySiteNumber,
				contactCDHPartyNumber,
				superRegion,
				country,
				email);
			this.opportunityNumber = opportunityNumber;
			this.oracleOrderNumber = oracleOrderNumber;
			this.oracleOrderId = oracleOrderId;
			this.errorIdentifier = errorIdentifier;
			this.partyType = partyType;
			this.operatingUnit = operatingUnit;
			this.orderStatus = orderStatus;
			this.orderOrigin = orderOrigin;
			this.orderSource = orderSource;
			this.sourceObject = (stagingLine != null)?(SObject)stagingLine:(SObject)header;
			this.header = header;
			this.stagingLine = stagingLine;
		}

		public OrderParty(Opportunity_Line_Staging__c stagingLine,Opportunity_Header_Staging__c header) {
			super(
				AccountToType.LINE_ENTITLE_TO,
				refIdValue(header.Opportunity_ID__c,null),
				refIdValue(stagingLine.Opportunity_Product_ID__c,null),
				stagingLine.Entitle_To_Account_Number__c,
				stagingLine.Entitle_To_CDH_Party_Number_Account__c,
				stagingLine.Entitle_To_CDH_Party_Site_Number__c,
				stagingLine.Entitle_To_CDH_Party_Number__c,
				null, // header.SuperRegion__c -> unknown
				stagingLine.Entitle_To_Country__c,
				stagingLine.Entitle_To_Contact_Email__c);
			this.opportunityNumber = header.Opportunity_Number__c;
			this.oracleOrderNumber = header.Oracle_Order_Number__c;
			this.oracleOrderId = header.Oracle_Order_ID__c;
			this.errorIdentifier = getErrorIdentifier(header);
			this.partyType = stagingLine.Entitle_To_Party_Type__c;
			this.operatingUnit = header.Operating_Unit__c;
			this.orderStatus = header.Order_Status__c;
			this.orderOrigin = header.Origin__c;
			this.orderSource = header.Order_Source__c;
			this.sourceObject = stagingLine;
			this.header = header;
			this.stagingLine = stagingLine;
			this.refEBSAccountId = stagingLine.Entitle_To_Account__c;
			this.refAddressId = stagingLine.Entitle_To_Address__c;
			this.refContactId = stagingLine.Entitle_To_Contact__c;
			this.refSalesAccountId = stagingLine.Entitle_To_Sales_Account__c;
		}

		protected override void filterEBSAccounts(Boolean xpreferSalesAccounts) {
			if(useProactiveMatching()) {
				super.filterEBSAccounts(xpreferSalesAccounts);
			}
		}

		protected override void filterAddresses(Boolean xpreferSalesAccounts) {
			if(useProactiveMatching()) {
				super.filterAddresses(xpreferSalesAccounts);
			}
		}

		protected override void filterContacts(Boolean xpreferSalesAccounts) {
			if(useProactiveMatching()) {
				super.filterContacts(xpreferSalesAccounts);
			}
		}

		/**
		 * Assigns the reference opportunity.  Also assigns the
		 * refSalesAccount, refEBSAccount, refAddress, and 
		 * refContact values.
		 * @param refOpp
		 */
		public override void setRefOpp(Opportunity refOpp) {
			this.refOpp = refOpp;
			if(refOpp != null  && toType != AccountToType.LINE_ENTITLE_TO) {
				if(toType == AccountToType.BILL_TO) {
					// refSalesAccount = refOpp.Bill_To_Sales_Account__r;
					if(refEBSAccount == null && refOpp.Bill_To_Account__r != null && refOpp.Bill_To_Account__r.Name == oracleAccountNumber) {
						refEBSAccount = refOpp.Bill_To_Account__r;
					}
					if(refAddress == null && refOpp.Bill_To_Address__r != null && refOpp.Bill_To_Address__r.CDH_Party_Site_Number__c == cdhPartySiteNumber) {
						refAddress = refOpp.Bill_To_Address__r;
					}
					if(refContact == null && refOpp.Bill_To_Contact__r != null && refOpp.Bill_To_Contact__r.CDH_Party_Number__c == contactCDHPartyNumber) {
						refContact = refOpp.Bill_To_Contact__r;
					}
				}
				else if(toType == AccountToType.ENTITLE_TO) {
					// refSalesAccount = refOpp.Entitle_To_Sales_Account__r;
					if(refEBSAccount == null && refOpp.Entitle_To_Account__r != null && refOpp.Entitle_To_Account__r.Name == oracleAccountNumber) {
						refEBSAccount = refOpp.Entitle_To_Account__r;
					}
					if(refAddress == null && refOpp.Entitle_To_Address__r != null && refOpp.Entitle_To_Address__r.CDH_Party_Site_Number__c == cdhPartySiteNumber) {
						refAddress = refOpp.Entitle_To_Address__r;
					}
					if(refContact == null && refOpp.Entitle_To_Contact__r != null && refOpp.Entitle_To_Contact__r.CDH_Party_Number__c == contactCDHPartyNumber) {
						refContact = refOpp.Entitle_To_Contact__r;
					}
				}
				else if(toType == AccountToType.SHIP_TO) {
					// refSalesAccount = refOpp.Ship_To_Sales_Account__r;
					if(refEBSAccount == null && refOpp.Ship_To_Account__r != null && refOpp.Ship_To_Account__r.Name == oracleAccountNumber) {
						refEBSAccount = refOpp.Ship_To_Account__r;
					}
					if(refAddress == null && refOpp.Ship_To_Address__r != null && refOpp.Ship_To_Address__r.CDH_Party_Site_Number__c == cdhPartySiteNumber) {
						refAddress = refOpp.Ship_To_Address__r;
					}
					if(refContact == null && refOpp.Ship_To_Contact__r != null && refOpp.Ship_To_Contact__r.CDH_Party_Number__c == contactCDHPartyNumber) {
						refContact = refOpp.Ship_To_Contact__r;
					}
				}
				else if(toType == AccountToType.SOLD_TO) {
					// refSalesAccount = refOpp.Sold_To_Sales_Account__r;
					if(refEBSAccount == null && refOpp.Sold_To_Account__r != null && refOpp.Sold_To_Account__r.Name == oracleAccountNumber) {
						refEBSAccount = refOpp.Sold_To_Account__r;
					}
					if(refAddress == null && refOpp.Sold_To_Address__r != null && refOpp.Sold_To_Address__r.CDH_Party_Site_Number__c == cdhPartySiteNumber) {
						refAddress = refOpp.Sold_To_Address__r;
					}
					if(refContact == null && refOpp.Sold_To_Contact__r != null && refOpp.Sold_To_Contact__r.CDH_Party_Number__c == contactCDHPartyNumber) {
						refContact = refOpp.Sold_To_Contact__r;
					}
				}
			}
		}

		/**
		 * Assigns the reference opportunity line.  Also assigns the
		 * refSalesAccount, refEBSAccount, refAddress, and 
		 * refContact values.
		 * @param refOppLine
		 */
		public override void setRefOppLine(OpportunityLineItem refOppLine) {
			this.refOppLine = refOppLine;
			if(refOppLine != null && toType == AccountToType.LINE_ENTITLE_TO) {
				// refSalesAccount = refOppLine.Entitle_To_Sales_Account__r;
				if(refEBSAccount == null && refOppLine.Entitle_To_Account__r != null && refOppLine.Entitle_To_Account__r.Name == oracleAccountNumber) {
					refEBSAccount = refOppLine.Entitle_To_Account__r;
				}
				if(refAddress == null && refOppLine.Entitle_To_Address__r != null && refOppLine.Entitle_To_Address__r.CDH_Party_Site_Number__c == cdhPartySiteNumber) {
					refAddress = refOppLine.Entitle_To_Address__r;
				}
				if(refContact == null && refOppLine.Entitle_To_Contact__r != null && refOppLine.Entitle_To_Contact__r.CDH_Party_Number__c == contactCDHPartyNumber) {
					refContact = refOppLine.Entitle_To_Contact__r;
				}
			}
		}

		public Boolean useProactiveMatching() {
			// The string == and != operators are case insensative, so there is no need to do an upper case conversion
			return (orderStatus == 'BOOKED' && orderOrigin != 'Order Loader' && orderSource != 'SFDC_SALES');
		}

//for-reference		public Id getLegalEntityId() {
//for-reference			Id retval = null;
//for-reference			if(sourceObject != null) {
//for-reference				Opportunity_Header_Staging__c header = null;
//for-reference				if(sourceObject instanceof Opportunity_Header_Staging__c) {
//for-reference					header = (Opportunity_Header_Staging__c)sourceObject;
//for-reference				}
//for-reference				else if(sourceObject instanceof Opportunity_Line_Staging__c) {
//for-reference					header = ((Opportunity_Line_Staging__c)sourceObject).Opportunity_Stage_Header_ID__r;
//for-reference				}
//for-reference				if(header != null) {
//for-reference					retval = header.Sales_Account__c;
//for-reference				}
//for-reference			}
//for-reference			return retval;
//for-reference		}
	}
}