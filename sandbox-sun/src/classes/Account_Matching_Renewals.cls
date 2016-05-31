/**
 * This class implements account matching for customer c360 renewals
 * opportunity fields including Bill-To, Ship-To, Sold-To,
 * Entitle-To, Line Item Entitle-To.
 *
 * @version 2015-05-21
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-05-21 - Updated to support contacts on different accounts
 * 2015-04-15 - Aggressively filter partners and attempt to replace with sales accounts
 * 2015-03-30 - The ignore errors pattern is now case insensitive
 * 2015-03-24 - Added a label and error code for NO LINES
 * 2015-03-18 - Updated the bill to matching to filter out partners, instead of non-partners
 * 2015-02-24 - Added filtering for legal entity account id
 * 2015-02-12 - Revised logic to support assigning refSalesAccountId values
 * 2014-12-10 - Added code for processing subscription and subscription lines
 * 2014-12-04 - Added support for opportunity line item id
 * 2014-12-01 - Created
 */
public with sharing class Account_Matching_Renewals extends Account_Matching {
	public static final String ALLOW_CONTACT_ON_DIFFERENT_ACCOUNT_SETTING = 'Renewals.ContactDiffAcc';
	public static final String ERROR_STATUS = 'ERROR';
	public static final String WARNING_REASON = 'WARNING';
	public static final String MATCHING_FAILURE_REASON = 'Matching Failure';
	public static final String INTERNAL_ERROR_REASON = 'Internal Error';
	public static final String NO_LINES_REASON = 'No Lines';

	public static final Map<AccountToType,String> EBS_ACCOUNT_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>System.Label.C360_R01,
		AccountToType.SHIP_TO=>System.Label.C360_R05,
		AccountToType.SOLD_TO=>System.Label.C360_R09,
		AccountToType.ENTITLE_TO=>System.Label.C360_R13,
		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_R17 };
	public static final Map<AccountToType,String> ADDRESS_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>System.Label.C360_R02,
		AccountToType.SHIP_TO=>System.Label.C360_R06,
		AccountToType.SOLD_TO=>System.Label.C360_R10,
		AccountToType.ENTITLE_TO=>System.Label.C360_R14,
		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_R18 };
	public static final Map<AccountToType,String> CONTACT_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>System.Label.C360_R03,
		AccountToType.SHIP_TO=>System.Label.C360_R07,
		AccountToType.SOLD_TO=>System.Label.C360_R11,
		AccountToType.ENTITLE_TO=>System.Label.C360_R15,
		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_R19 };
	public static final Map<AccountToType,String> SALES_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>System.Label.C360_R04,
		AccountToType.SHIP_TO=>System.Label.C360_R08,
		AccountToType.SOLD_TO=>System.Label.C360_R12,
		AccountToType.ENTITLE_TO=>System.Label.C360_R16,
		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_R20 };
	public static final Map<AccountToType,String> EBS_ACCOUNT_ERROR_MAP2 = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>System.Label.C360_R21,
		AccountToType.SHIP_TO=>System.Label.C360_R22,
		AccountToType.SOLD_TO=>System.Label.C360_R23,
		AccountToType.ENTITLE_TO=>System.Label.C360_R24,
		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_R25 };
	public static final Map<AccountToType,String> ADDRESS_ERROR_MAP2 = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>System.Label.C360_R26,
		AccountToType.SHIP_TO=>System.Label.C360_R27,
		AccountToType.SOLD_TO=>System.Label.C360_R28,
		AccountToType.ENTITLE_TO=>System.Label.C360_R29,
		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_R30 };
	public static final Map<AccountToType,String> PARTNER_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>System.Label.C360_R41,
		AccountToType.SHIP_TO=>System.Label.C360_R42,
		AccountToType.SOLD_TO=>System.Label.C360_R43,
		AccountToType.ENTITLE_TO=>System.Label.C360_R44,
		AccountToType.LINE_ENTITLE_TO=>System.Label.C360_R45 };

	public final List<RenewalParty> renewalParties;

	private static Boolean getAllowContactOnDifferentAccountSetting() {
		BooleanSetting__c b = BooleanSetting__c.getInstance(ALLOW_CONTACT_ON_DIFFERENT_ACCOUNT_SETTING);
		return (b == null || b.Value__c != false);
	}

	/**
	 * Construct from a list of renewal parties.
	 * 
	 * @param renewalParties list of RenewalParty
	 */
	public Account_Matching_Renewals(
		List<RenewalParty> renewalParties)	
	{
		super(true,
			renewalParties,
			EBS_ACCOUNT_ERROR_MAP,
			ADDRESS_ERROR_MAP,
			CONTACT_ERROR_MAP,
			SALES_ERROR_MAP,
			EBS_ACCOUNT_ERROR_MAP2,
			ADDRESS_ERROR_MAP2,
			null,
			PARTNER_ERROR_MAP );
		this.renewalParties = renewalParties;
		this.allowContactOnDifferentAccount = getAllowContactOnDifferentAccountSetting();
	}

	/**
	 * Construct from a list of subscription and subscription lines.
	 * If the subscriptionLines list is null, the list will be queried.
	 * 
	 * @param subscriptions list of subscriptions
	 * @param subscriptionLines list of subscription lines for the subscriptions, maybe null
	 */
	public Account_Matching_Renewals(
		List<Subscription__c> subscriptions,
		List<SubscriptionLine__c> subscriptionLines)
	{
		super(true,
			getRenewalParty(subscriptions,subscriptionLines),
			EBS_ACCOUNT_ERROR_MAP,
			ADDRESS_ERROR_MAP,
			CONTACT_ERROR_MAP,
			SALES_ERROR_MAP,
			EBS_ACCOUNT_ERROR_MAP2,
			ADDRESS_ERROR_MAP2,
			null,
			PARTNER_ERROR_MAP );
		this.renewalParties = (List<RenewalParty>)partyList;
		this.allowContactOnDifferentAccount = getAllowContactOnDifferentAccountSetting();
	}

	/**
	 * Filter each of the ebsAccountMapMap, addressMapMap, and contactMapMap on 
	 * each of the PartyData instances in the mapping list.  This implements 
	 * SFDC BR[1-5].PART B for renewals matching.
	 */
	public override void filter() {
		super.filter();
		for(RenewalParty m : renewalParties) {
			if(m.filterAccountIds(m.getSalesAccountIds(),m.refSalesAccountId) > 1) {
				m.filterBySuperRegion(accountMap);
				if(m.filterAccountIds(m.getSalesAccountIds(),null) > 1) {
					if(allowContactOnDifferentAccount) {
						m.filterCDHPartyIds(m.getContactCDHPartyIds(),null);
					}
					else {
						m.filterAccountIds(m.contactMapMap.keySet(),null);
					}
				}
			}
			m.filterByCountry();
			m.filterByEmail();
			m.filterAccountIds(m.getSalesAccountIds(),m.getLegalEntityId());
		}
		findContactsByEmail();
	}

	/**
	 * Error reporting  This implements SFDC BR[1-5].PART C for renewals matching,
	 * except contact failures become warnings instead of errors.  SHIP_TO and LINE_ENTITLE_TO 
	 * messages also become warnings.  Provided the sourceObject is defined,
	 * if ENTITLE_TO is provided, SOLD_TO becomes warnings, and visa versa.
	 */
	public void errorsAndWarningsReporting() {
		Set<Object> hasEntitleToOrSoldTo = new Set<Object>();
		for(RenewalParty m : renewalParties) {
			m.errorMessages.clear();
			m.warnMessages.clear();
			ebsAccountErrorReporting(m,m.errorMessages,m.warnMessages);
			addressErrorReporting(m,m.warnMessages,m.warnMessages);
			contactErrorReporting(m,m.warnMessages,null);
			salesErrorReporting(m,m.warnMessages,m.warnMessages);
			partnerErrorReporting(m,m.warnMessages);
			if( (m.toType == AccountToType.ENTITLE_TO || m.toType == AccountToType.SOLD_TO)
				&& m.sourceObject != null
				&& m.errorMessages.isEmpty())
			{
				hasEntitleToOrSoldTo.add(m.sourceObject);
			}
		}
		// convert errors to warnings
		for(RenewalParty m : renewalParties) {
			if(m.toType == AccountToType.SHIP_TO || m.toType == AccountToType.LINE_ENTITLE_TO 
				|| ((m.toType == AccountToType.ENTITLE_TO || m.toType == AccountToType.SOLD_TO)
					 && hasEntitleToOrSoldTo.contains(m.sourceObject)) )
			{
				m.warnMessages.addAll(m.errorMessages);
				m.errorMessages.clear();
			}
		}
	}

	/**
	 * Use the old assignment logic to maximumize the chances
	 * of assigning refOppId values.
	 */
	public void assignRefOppId() {
		for(RenewalParty m : renewalParties) {
			if(! potentialOppMap.containsKey(m.refOppId)) {
				m.refOppId = oppIdByOpportunityNumber.get(m.opportunityNumber);
				if(m.refOppId == null && m.oracleOrderNumber != null) {
					Set<Id> oppIds = oppIdsByOracleOrderNumber.get(m.oracleOrderNumber);
					if(oppIds != null && ! oppIds.isEmpty()) {
						m.refOppId = oppIds.iterator().next();
					}
				}
				if(m.refOppId == null && m.poNumber != null) {
					Set<Id> oppIds = oppIdsByPONumber.get(m.poNumber);
					if(oppIds != null && ! oppIds.isEmpty()) {
						m.refOppId = oppIds.iterator().next();
					}
				}
			}
		}
	}

	/**
	 * Use new assignment logic to maximumize the chances of 
	 * assigning the correct refOppId values.
	 */
	public void preAssignRefOppId() {
		for(RenewalParty m : renewalParties) {
			if(! potentialOppMap.containsKey(m.refOppId)) {
				m.refOppId = null;
				if(m.oracleOrderNumber != null) {
					if(m.opportunityNumber != null) {
						Id oppId = oppIdByOpportunityNumber.get(m.opportunityNumber);
						if(oppId != null && potentialOppMap.get(oppId).OracleOrderNumber__c == m.oracleOrderNumber) {
							m.refOppId = oppId;
						}
					}
					if(m.refOppId == null) {
						Id accountId = null;
						Set<Id> oppIds = oppIdsByOracleOrderNumber.get(m.oracleOrderNumber);
						if(oppIds != null) {
							for(Id oppId : oppIds) {
								Opportunity opp = potentialOppMap.get(oppId);
								if( accountId != opp.AccountId && accountId != null) {
									m.refOppId = null;
									break;
								}
								accountId = opp.AccountId;
								m.refOppId = oppId;
							}
						}
					}
				}
			}
		}
	}

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

	@TestVisible
	private Map<String,Set<Id>> oppIdsByOracleOrderNumber {
		get {
			if(oppIdsByOracleOrderNumber == null) {
				oppIdsByOracleOrderNumber = new Map<String,Set<Id>>();
				for(Opportunity opp : potentialOppMap.values()) {
					if(opp.OracleOrderNumber__c != null) {
						Set<Id> oppIds = oppIdsByOracleOrderNumber.get(opp.OracleOrderNumber__c);
						if(oppIds == null) {
							oppIds = new Set<Id>();
							oppIdsByOracleOrderNumber.put(opp.OracleOrderNumber__c,oppIds);
						}
						oppIds.add(opp.Id);
					}
				}
			}
			return oppIdsByOracleOrderNumber;
		}
		set;
	}

	@TestVisible
	private Map<String,Set<Id>> oppIdsByPONumber {
		get {
			if(oppIdsByPONumber == null) {
				oppIdsByPONumber = new Map<String,Set<Id>>();
				for(Opportunity opp : potentialOppMap.values()) {
					if(opp.OracleOrderNumber__c != null) {
						Set<Id> oppIds = oppIdsByPONumber.get(opp.PONumber__c);
						if(oppIds == null) {
							oppIds = new Set<Id>();
							oppIdsByPONumber.put(opp.PONumber__c,oppIds);
						}
						oppIds.add(opp.Id);
					}
				}
			}
			return oppIdsByPONumber;
		}
		set;
	}

	@TestVisible
	private Map<Id,Opportunity> potentialOppMap {
		get {
			if(potentialOppMap == null) {
				potentialOppMap = new Map<Id,Opportunity>();
				Set<Id> oppIds = new Set<Id>();
				for(RenewalParty m : renewalParties) {
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
							PONumber__c
						from Opportunity
						where Id in :oppIds ] ) );
				}
				Set<String> opportunityNumbers = new Set<String>();
				Set<String> oracleOrderNumbers = new Set<String>();
				Set<String> poNumbers = new Set<String>();
				for(RenewalParty m : renewalParties) {
					if(m.getRefOpp() == null && ! potentialOppMap.containsKey(m.refOppId)) {
						if(m.opportunityNumber != null) {
							opportunityNumbers.add(m.opportunityNumber);
						}
						if(m.oracleOrderNumber != null) {
							oracleOrderNumbers.add(m.oracleOrderNumber);
						}
						if(m.poNumber != null) {
							poNumbers.add(m.poNumber);
						}
					}
				}
				if(! (opportunityNumbers.isEmpty() && oracleOrderNumbers.isEmpty() && poNumbers.isEmpty())) {
					potentialOppMap.putAll( new Map<Id,Opportunity>( [
						select
							AccountId,
							OpportunityNumber__c,
							OracleOrderNumber__c,
							PONumber__c
						from Opportunity
						where OpportunityNumber__c in :opportunityNumbers
							or OracleOrderNumber__c in :oracleOrderNumbers
							or PONumber__c in :poNumbers ] ) );
				}
			}
			return potentialOppMap;
		}
		set;
	}

	/**
	 * Useful method to get a list of RenewalParty from a list of subscriptions and a list of subscription lines.
	 * If the subscriptionLines list is null, the list will be queried.
	 * 
	 * @param subscriptions list of subscriptions
	 * @param subscriptionLines list of subscription lines for the subscriptions, maybe null
	 */
	public static List<RenewalParty> getRenewalParty(
		List<Subscription__c> subscriptions,
		List<SubscriptionLine__c> subscriptionLines)
	{
		List<RenewalParty> retval = new List<RenewalParty>();
		Map<Id,Subscription__c> subscriptionMap = new Map<Id,Subscription__c>();
		for(Subscription__c sub : subscriptions) {
			addSubscription(retval,sub);
			subscriptionMap.put(sub.Id,sub);
		}
		if(subscriptionLines == null) {
			subscriptionLines = [
				select
					EntitleToAddress__c,
					EntitleToAccountNumber__c,
					EntitleToCDHPartyNumber__c,
					EntitleToCDHPartySiteNumber__c,
					EntitleToContCDHPartyNumber__c,
					EntitleToCountry__c,
					EntitleToContactEmail__c,
					EntitleToContact__c,
					EntitleToContact__r.CDH_Party_Number__c,
					EntitleToContact__r.AccountId,
					EntitleToContact__r.Account.RecordType.Name,
					EntitleToContact__r.Email,
					EntitleToEBSAccount__c,
					EntitleToSalesAccount__c,
					EntitleToSfAccountId__c,
					EntitleToSfAddressId__c,
					EntitleToSfContactId__c,
					EntitleToSfEBSAccountId__c,
					OrigOpportunityLineId__c,
					Subscription__c,
					Subscription__r.Account__c
				from SubscriptionLine__c
				where Subscription__c in :subscriptionMap.keySet() ];
		}
		for(SubscriptionLine__c subLine : subscriptionLines) {
			addSubscriptionLine(retval,subLine,subscriptionMap.get(subLine.Subscription__c));
		}
		return retval;
	}

	/**
	 * Called to update the subscription and subscription lines reference
	 * by the RenewalParty with the results from the matching and filtering.
	 */
	public void assignFrom() {
		assignFrom(renewalParties);
	}

	/**
	 * Return the list of SubscriptionError__c objects and update the 
	 * respective subscription statuses to ERROR_STATUS when appropriate.
	 * This method will only work if the renewals data was initialized 
	 * from subscriptions and subscription lines.
	 * 
	 * @return a list of SubscriptionError__c object which may be inserted
	 */
	public List<SubscriptionError__c> getErrorAndWarnList() {
		return getErrorAndWarnList(null);
	}


	/**
	 * Return the list of SubscriptionError__c objects and update the 
	 * respective subscription statuses to ERROR_STATUS when appropriate.
	 * This method will only work if the renewals data was initialized 
	 * from subscriptions and subscription lines.
	 * 
	 * @ignoreErrorsPattern pattern of errors which should not set an ERROR_STATUS
	 * @return a list of SubscriptionError__c object which may be inserted
	 */
	public List<SubscriptionError__c> getErrorAndWarnList(Pattern ignoreErrorsPattern) {
		return getErrorAndWarnList(ignoreErrorsPattern,renewalParties);
	}

	/**
	 * Retrieve the list of subscription lines that have been updated.
	 * Use an update call to commit the updates.
	 * 
	 * @retval updated list of subscription lines
	 */
	public List<SubscriptionLine__c> getUpdatedSubscriptionLines() {
		return getUpdatedSubscriptionLines(renewalParties);
	}

	private static void addSubscriptionLine(List<RenewalParty> renewalPartyList,SubscriptionLine__c subLine,Subscription__c sub) {
		renewalPartyList.add(getLineEntitleToRenewalParty(subLine,sub));
	}

	private static void addSubscription(List<RenewalParty> renewalPartyList,Subscription__c sub) {
		renewalPartyList.add(getBillToRenewalParty(sub));
		renewalPartyList.add(getEntitleToRenewalParty(sub));
		renewalPartyList.add(getShipToRenewalParty(sub));
		renewalPartyList.add(getSoldToRenewalParty(sub));
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

	private static RenewalParty getBillToRenewalParty(Subscription__c sub) {
		System.assertNotEquals(null,sub,'Missing subscription');
		RenewalParty retval = 
			new RenewalParty(
				AccountToType.BILL_TO,
				sub.OriginalOpportunity__c,
				null, // refOppLineId
				sub.BillToAccountNumber__c,
				sub.BillToCDHPartyNumber__c,
				sub.BillToCDHPartySiteNumber__c,
				sub.BillToContCDHPartyNumber__c,
				sub.SuperRegion__c,
				sub.BillToCountry__c,
				sub.BillToContactEmail__c,
				sub.OpportunityNumber__c,
				sub.OrderNumber__c,
				sub.PurchaseOrderNumber__c,
				sub );
		retval.refEBSAccountId = refIdValue(sub.BillToEBSAccount__c,sub.BillToSfEBSAccountId__c);
		retval.refAddressId = refIdValue(sub.BillToAddress__c,sub.BillToSfAddressId__c);
		retval.refContactId = refIdValue(sub.BillToContact__c,sub.BillToSfContactId__c);
		if(retval.refEBSAccountId == null && retval.refAddressId == null && retval.refContactId == null) {
			retval.refSalesAccountId = refIdValue(sub.BillToSalesAccount__c,sub.BillToSfAccountId__c);
		}
		return retval;
	}

	private static RenewalParty getEntitleToRenewalParty(Subscription__c sub) {
		System.assertNotEquals(null,sub,'Missing subscription');
		RenewalParty retval = 
			new RenewalParty(
				AccountToType.ENTITLE_TO,
				sub.OriginalOpportunity__c,
				null, // refOppLineId
				sub.EntitleToAccountNumber__c,
				sub.EntitleToCDHPartyNumber__c,
				sub.EntitleToCDHPartySiteNumber__c,
				sub.EntitleToContCDHPartyNumber__c,
				sub.SuperRegion__c,
				sub.EntitleToCountry__c,
				sub.EntitleToContactEmail__c,
				sub.OpportunityNumber__c,
				sub.OrderNumber__c,
				sub.PurchaseOrderNumber__c,
				sub );
		retval.refEBSAccountId = refIdValue(sub.EntitleToEBSAccount__c,sub.EntitleToSfEBSAccountId__c);
		retval.refAddressId = refIdValue(sub.EntitleToAddress__c,sub.EntitleToSfAddressId__c);
		retval.refContactId = refIdValue(sub.EntitleToContact__c,sub.EntitleToSfContactId__c);
		if(retval.refEBSAccountId == null && retval.refAddressId == null && retval.refContactId == null) {
			retval.refSalesAccountId = refIdValue(sub.EntitleToSalesAccount__c,sub.EntitleToSfAccountId__c);
		}
		return retval;
	}

	private static RenewalParty getShipToRenewalParty(Subscription__c sub) {
		System.assertNotEquals(null,sub,'Missing subscription');
		RenewalParty retval = 
			new RenewalParty(
				AccountToType.SHIP_TO,
				sub.OriginalOpportunity__c,
				null, // refOppLineId
				sub.ShipToAccountNumber__c,
				sub.ShipToCDHPartyNumber__c,
				sub.ShipToCDHPartySiteNumber__c,
				sub.ShipToContCDHPartyNumber__c,
				sub.SuperRegion__c,
				sub.ShipToCountry__c,
				sub.ShipToContactEmail__c,
				sub.OpportunityNumber__c,
				sub.OrderNumber__c,
				sub.PurchaseOrderNumber__c,
				sub );
		retval.refEBSAccountId = refIdValue(sub.ShipToEBSAccount__c,sub.ShipToSfEBSAccountId__c);
		retval.refAddressId = refIdValue(sub.ShipToAddress__c,sub.ShipToSfAddressId__c);
		retval.refContactId = refIdValue(sub.ShipToContact__c,sub.ShipToSfContactId__c);
		if(retval.refEBSAccountId == null && retval.refAddressId == null && retval.refContactId == null) {
			retval.refSalesAccountId = refIdValue(sub.ShipToSalesAccount__c,sub.ShipToSfAccountId__c);
		}
		return retval;
	}

	private static RenewalParty getSoldToRenewalParty(Subscription__c sub) {
		System.assertNotEquals(null,sub,'Missing subscription');
		RenewalParty retval = 
			new RenewalParty(
				AccountToType.SOLD_TO,
				sub.OriginalOpportunity__c,
				null, // refOppLineId
				sub.SoldToAccountNumber__c,
				sub.SoldToCDHPartyNumber__c,
				sub.SoldToCDHPartySiteNumber__c,
				sub.SoldToContCDHPartyNumber__c,
				sub.SuperRegion__c,
				sub.SoldToCountry__c,
				sub.SoldToContactEmail__c,
				sub.OpportunityNumber__c,
				sub.OrderNumber__c,
				sub.PurchaseOrderNumber__c,
				sub );
		retval.refEBSAccountId = refIdValue(sub.SoldToEBSAccount__c,sub.SoldToSfEBSAccountId__c);
		retval.refAddressId = refIdValue(sub.SoldToAddress__c,sub.SoldToSfAddressId__c);
		retval.refContactId = refIdValue(sub.SoldToContact__c,sub.SoldToSfContactId__c);
		if(retval.refEBSAccountId == null && retval.refAddressId == null && retval.refContactId == null) {
			retval.refSalesAccountId = refIdValue(sub.SoldToSalesAccount__c,sub.SoldToSfAccountId__c);
		}
		return retval;
	}

	private static RenewalParty getLineEntitleToRenewalParty(SubscriptionLine__c subLine,Subscription__c sub) {
		System.assertNotEquals(null,sub,'Missing subscription');
		System.assertNotEquals(null,subLine,'Missing subscription line');
		Id origOppLineId = null;
		try {
			origOppLineId = subLine.OrigOpportunityLineId__c;
		}
		catch(Exception ex) {}
		RenewalParty retval = 
			new RenewalParty(
				AccountToType.LINE_ENTITLE_TO,
				sub.OriginalOpportunity__c,
				origOppLineId,
				subLine.EntitleToAccountNumber__c,
				subLine.EntitleToCDHPartyNumber__c,
				subLine.EntitleToCDHPartySiteNumber__c,
				subLine.EntitleToContCDHPartyNumber__c,
				sub.SuperRegion__c,
				subLine.EntitleToCountry__c,
				subLine.EntitleToContactEmail__c,
				sub.OpportunityNumber__c,
				sub.OrderNumber__c,
				sub.PurchaseOrderNumber__c,
				subLine );
		retval.refEBSAccountId = refIdValue(subLine.EntitleToEBSAccount__c,subLine.EntitleToSfEBSAccountId__c);
		retval.refAddressId = refIdValue(subLine.EntitleToAddress__c,subLine.EntitleToSfAddressId__c);
		retval.refContactId = refIdValue(subLine.EntitleToContact__c,subLine.EntitleToSfContactId__c);
		if(retval.refEBSAccountId == null && retval.refAddressId == null && retval.refContactId == null) {
			retval.refSalesAccountId = refIdValue(subLine.EntitleToSalesAccount__c,subLine.EntitleToSfAccountId__c);
		}
		return retval;
	}

	private static void assignFrom(List<RenewalParty> renewalPartyList) {
		for(RenewalParty renewalParty : renewalPartyList) {
			assignFrom(renewalParty);
		}
	}

	private static void assignFrom(RenewalParty renewalParty) {
		if(renewalParty.toType == AccountToType.BILL_TO) {
			assignFromBillTo(renewalParty);
		}
		else if(renewalParty.toType == AccountToType.ENTITLE_TO) {
			assignFromEntitleTo(renewalParty);
		}
		else if(renewalParty.toType == AccountToType.SHIP_TO) {
			assignFromShipTo(renewalParty);
		}
		else if(renewalParty.toType == AccountToType.SOLD_TO) {
			assignFromSoldTo(renewalParty);
		}
		else {
			System.assertEquals(AccountToType.LINE_ENTITLE_TO,renewalParty.toType);
			assignFromLineEntitleTo(renewalParty);
		}
	}

	private static void assignFromBillTo(RenewalParty renewalParty) {
		assignFromBillTo((Subscription__c)renewalParty.sourceObject,renewalParty);
	}

	private static void assignFromBillTo(Subscription__c sub,RenewalParty renewalParty) {
		System.assertEquals(AccountToType.BILL_TO,renewalParty.toType);
		Contact contact = renewalParty.getBestContact(true);
		if(contact == null && sub.BillToContact__r != null) {
			contact = sub.BillToContact__r;
			renewalParty.setContact(contact);
		}
		Id contactId = null;
		if(contact != null) {
			contactId = contact.Id;
		}
		if(contactId != sub.BillToContact__c) {
			sub.BillToContact__r = contact;
			sub.BillToContact__c = contactId;
			renewalParty.updated = true;
		}
		Id salesAccountId = null;
		Id addressId = null;
		Address__c address = renewalParty.getBestAddress(true);
		if(address != null) {
			addressId = address.Id;
			salesAccountId = address.Sales_Account__c;
		}
		if(addressId != sub.BillToAddress__c) {
			sub.BillToAddress__r = address;
			sub.BillToAddress__c = addressId;
			renewalParty.updated = true;
		}
		Id ebsAccountId = null;
		EBS_Account__c ebsAccount = renewalParty.getBestEBSAccount();
		if(ebsAccount != null) {
			ebsAccountId = ebsAccount.Id;
			salesAccountId = ebsAccount.Sales_Account__c;
		}
		if(ebsAccountId != sub.BillToEBSAccount__c) {
			sub.BillToEBSAccount__r = ebsAccount;
			sub.BillToEBSAccount__c = ebsAccountId;
			renewalParty.updated = true;
		}
		if(salesAccountId != sub.BillToSalesAccount__c) {
			sub.BillToSalesAccount__c = salesAccountId;
		}
	}

	private static void assignFromEntitleTo(RenewalParty renewalParty) {
		assignFromEntitleTo((Subscription__c)renewalParty.sourceObject,renewalParty);
	}

	private static void assignFromEntitleTo(Subscription__c sub,RenewalParty renewalParty) {
		System.assertEquals(AccountToType.ENTITLE_TO,renewalParty.toType);
		Contact contact = renewalParty.getBestContact(true);
		if(contact == null && sub.EntitleToContact__r != null) {
			contact = sub.EntitleToContact__r;
			renewalParty.setContact(contact);
		}
		Id contactId = null;
		if(contact != null) {
			contactId = contact.Id;
		}
		if(contactId != sub.EntitleToContact__c) {
			sub.EntitleToContact__r = contact;
			sub.EntitleToContact__c = contactId;
			renewalParty.updated = true;
		}
		Id salesAccountId = null;
		Id addressId = null;
		Address__c address = renewalParty.getBestAddress(true);
		if(address != null) {
			addressId = address.Id;
			salesAccountId = address.Sales_Account__c;
		}
		if(addressId != sub.EntitleToAddress__c) {
			sub.EntitleToAddress__r = address;
			sub.EntitleToAddress__c = addressId;
			renewalParty.updated = true;
		}
		Id ebsAccountId = null;
		EBS_Account__c ebsAccount = renewalParty.getBestEBSAccount();
		if(ebsAccount != null) {
			ebsAccountId = ebsAccount.Id;
			salesAccountId = ebsAccount.Sales_Account__c;
		}
		if(ebsAccountId != sub.EntitleToEBSAccount__c) {
			sub.EntitleToEBSAccount__r = ebsAccount;
			sub.EntitleToEBSAccount__c = ebsAccountId;
			renewalParty.updated = true;
		}
		if(salesAccountId != sub.EntitleToSalesAccount__c) {
			sub.EntitleToSalesAccount__c = salesAccountId;
		}
	}

	private static void assignFromShipTo(RenewalParty renewalParty) {
		assignFromShipTo((Subscription__c)renewalParty.sourceObject,renewalParty);
	}

	private static void assignFromShipTo(Subscription__c sub,RenewalParty renewalParty) {
		System.assertEquals(AccountToType.SHIP_TO,renewalParty.toType);
		Contact contact = renewalParty.getBestContact(true);
		if(contact == null && sub.ShipToContact__r != null) {
			contact = sub.ShipToContact__r;
			renewalParty.setContact(contact);
		}
		Id contactId = null;
		if(contact != null) {
			contactId = contact.Id;
		}
		if(contactId != sub.ShipToContact__c) {
			sub.ShipToContact__r = contact;
			sub.ShipToContact__c = contactId;
			renewalParty.updated = true;
		}
		Id salesAccountId = null;
		Id addressId = null;
		Address__c address = renewalParty.getBestAddress(true);
		if(address != null) {
			addressId = address.Id;
			salesAccountId = address.Sales_Account__c;
		}
		if(addressId != sub.ShipToAddress__c) {
			sub.ShipToAddress__r = address;
			sub.ShipToAddress__c = addressId;
			renewalParty.updated = true;
		}
		Id ebsAccountId = null;
		EBS_Account__c ebsAccount = renewalParty.getBestEBSAccount();
		if(ebsAccount != null) {
			ebsAccountId = ebsAccount.Id;
			salesAccountId = ebsAccount.Sales_Account__c;
		}
		if(ebsAccountId != sub.ShipToEBSAccount__c) {
			sub.ShipToEBSAccount__r = ebsAccount;
			sub.ShipToEBSAccount__c = ebsAccountId;
			renewalParty.updated = true;
		}
		if(salesAccountId != sub.ShipToSalesAccount__c) {
			sub.ShipToSalesAccount__c = salesAccountId;
		}
	}

	private static void assignFromSoldTo(RenewalParty renewalParty) {
		assignFromSoldTo((Subscription__c)renewalParty.sourceObject,renewalParty);
	}

	private static void assignFromSoldTo(Subscription__c sub,RenewalParty renewalParty) {
		System.assertEquals(AccountToType.SOLD_TO,renewalParty.toType);
		Contact contact = renewalParty.getBestContact(true);
		if(contact == null && sub.SoldToContact__r != null) {
			contact = sub.SoldToContact__r;
			renewalParty.setContact(contact);
		}
		Id contactId = null;
		if(contact != null) {
			contactId = contact.Id;
		}
		if(contactId != sub.SoldToContact__c) {
			sub.SoldToContact__r = contact;
			sub.SoldToContact__c = contactId;
			renewalParty.updated = true;
		}
		Id salesAccountId = null;
		Id addressId = null;
		Address__c address = renewalParty.getBestAddress(true);
		if(address != null) {
			addressId = address.Id;
			salesAccountId = address.Sales_Account__c;
		}
		if(addressId != sub.SoldToAddress__c) {
			sub.SoldToAddress__r = address;
			sub.SoldToAddress__c = addressId;
			renewalParty.updated = true;
		}
		Id ebsAccountId = null;
		EBS_Account__c ebsAccount = renewalParty.getBestEBSAccount();
		if(ebsAccount != null) {
			ebsAccountId = ebsAccount.Id;
			salesAccountId = ebsAccount.Sales_Account__c;
		}
		if(ebsAccountId != sub.SoldToEBSAccount__c) {
			sub.SoldToEBSAccount__r = ebsAccount;
			sub.SoldToEBSAccount__c = ebsAccountId;
			renewalParty.updated = true;
		}
		if(salesAccountId != sub.SoldToSalesAccount__c) {
			sub.SoldToSalesAccount__c = salesAccountId;
		}
	}

	private static void assignFromLineEntitleTo(RenewalParty renewalParty) {
		assignFromLineEntitleTo((SubscriptionLine__c)renewalParty.sourceObject,renewalParty);
	}

	private static void assignFromLineEntitleTo(SubscriptionLine__c subLine,RenewalParty renewalParty) {
		System.assertEquals(AccountToType.LINE_ENTITLE_TO,renewalParty.toType);
		Contact contact = renewalParty.getBestContact(true);
		if(contact == null && subLine.EntitleToContact__r != null) {
			contact = subLine.EntitleToContact__r;
			renewalParty.setContact(contact);
		}
		Id contactId = null;
		if(contact != null) {
			contactId = contact.Id;
		}
		if(contactId != subLine.EntitleToContact__c) {
			subLine.EntitleToContact__r = contact;
			subLine.EntitleToContact__c = contactId;
			renewalParty.updated = true;
		}
		Id salesAccountId = null;
		Id addressId = null;
		Address__c address = renewalParty.getBestAddress(true);
		if(address != null) {
			addressId = address.Id;
			salesAccountId = address.Sales_Account__c;
		}
		if(addressId != subLine.EntitleToAddress__c) {
			subLine.EntitleToAddress__r = address;
			subLine.EntitleToAddress__c = addressId;
			renewalParty.updated = true;
		}
		Id ebsAccountId = null;
		EBS_Account__c ebsAccount = renewalParty.getBestEBSAccount();
		if(ebsAccount != null) {
			ebsAccountId = ebsAccount.Id;
			salesAccountId = ebsAccount.Sales_Account__c;
		}
		if(ebsAccountId != subLine.EntitleToEBSAccount__c) {
			subLine.EntitleToEBSAccount__r = ebsAccount;
			subLine.EntitleToEBSAccount__c = ebsAccountId;
			renewalParty.updated = true;
		}
		if(salesAccountId != subLine.EntitleToSalesAccount__c) {
			subLine.EntitleToSalesAccount__c = salesAccountId;
		}
	}

	private static SubscriptionError__c createSubscriptionError(
		Pattern ignoreErrorsPattern,
		RenewalParty renewalParty,
		Id subId,
		Id subLineId,
		String reason,
		String message,
		Boolean warning,
		Boolean always )
	{
		String details = reason+' :\n'+message;
		warning = warning || (ignoreErrorsPattern != null && ignoreErrorsPattern.matcher(reason+':'+message).matches());
		SubscriptionError__c retval = new SubscriptionError__c(
			Reason__c = reason,
			Details__c = details,
			Subscription__c = subId,
			SubscriptionLine__c = subLineId );
		if(renewalParty.sourceObject instanceof Subscription__c 
			&& (! warning) )
		{
			Subscription__c sub = (Subscription__c)renewalParty.sourceObject;
			if (always || sub.Status__c != ERROR_STATUS) {
				sub.Status__c = ERROR_STATUS;
				sub.ErrorMessage__c = details;
				renewalParty.updated = true;
			}
		}
		return retval;
	}

	private static List<SubscriptionError__c> getErrorAndWarnList(Pattern ignoreErrorsPattern,List<RenewalParty> renewalPartyList) {
		List<SubscriptionError__c> retval = new List<SubscriptionError__c>();
		Map<Id,Id> lineIdMap = new Map<Id,Id>();
		Map<Id,RenewalParty> renewalPartyMap = new Map<Id,RenewalParty>();
		for(RenewalParty renewalParty : renewalPartyList) {
			Subscription__c sub = null;
			String errorReason;
			Id subId;
			Id subLineId = null;
			Boolean warning = false;
			if(renewalParty.sourceObject instanceof Subscription__c) {
				sub = (Subscription__c)renewalParty.sourceObject;
				subId = sub.Id;
				errorReason = MATCHING_FAILURE_REASON;
				renewalPartyMap.put(subId,renewalParty);
			}
			else {
				SubscriptionLine__c subLine = (SubscriptionLine__c)renewalParty.sourceObject;
				subId = subLine.Subscription__c;
				subLineId = subLine.Id;
				lineIdMap.put(subId,subLineId);
				errorReason = WARNING_REASON;
				warning = true;
			}
			if(subLineId != null || ! lineIdMap.containsKey(subId)) {
				lineIdMap.put(subId,subLineId);
			}
			for(String message : renewalParty.errorMessages) {
				retval.add( createSubscriptionError(
					ignoreErrorsPattern,
					renewalParty,
					subId,
					subLineId,
					errorReason,
					message,
					warning,
					false ) );
			}
			for(String message : renewalParty.warnMessages) {
				retval.add( createSubscriptionError(
					ignoreErrorsPattern,
					renewalParty,
					subId,
					subLineId,
					WARNING_REASON,
					message,
					true,
					false ) );
			}
		}
		for(Id subId : lineIdMap.keySet()) {
			if(lineIdMap.get(subId) == null) {
				retval.add( createSubscriptionError(
					ignoreErrorsPattern,
					renewalPartyMap.get(subId),
					subId,
					null,
					NO_LINES_REASON,
					system.Label.C360_R38,
					false,
					true ) );
			}
		}
		return retval;
	}

	private static List<SubscriptionLine__c> getUpdatedSubscriptionLines(List<RenewalParty> renewalPartyList) {
		Set<Id> ids = new Set<Id>();
		List<SubscriptionLine__c> retval = new List<SubscriptionLine__c>();
		for(Account_Matching_Renewals.RenewalParty renewalParty : renewalPartyList) {
			if(renewalParty.updated && renewalParty.sourceObject instanceof SubscriptionLine__c) {
				SubscriptionLine__c subLine = (SubscriptionLine__c)renewalParty.sourceObject;
				if(! ids.contains(subLine.Id)) {
					ids.add(subLine.Id);
					retval.add(subLine);
				}
			}
		}
		return retval;
	}

	/**
	 * Class representing matching data.
	 */
	public virtual class RenewalParty extends Account_Matching.PartyData {
		/** Opportunity Number */
		public String opportunityNumber;
		/** Oracle Order Number */
		public String oracleOrderNumber;
		/** Purchase order number */
		public String poNumber;
		/** It is a nice idea to keep a reference to the original object */
		public Object sourceObject;
		/** Keep track if the assignFrom methods update the source object */
		public Boolean updated = false;

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
		 * @param poNumber to lookup the refOppId
		 * @param sourceObject value to indentify the party set
		 */
		public RenewalParty(
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
			String poNumber,
			Object sourceObject )
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
			this.poNumber = poNumber;
			this.sourceObject = sourceObject;
		}

		public Id getLegalEntityId() {
			Id retval = null;
			if(sourceObject != null) {
				Subscription__c sub = null;
				if(sourceObject instanceof Subscription__c) {
					sub = (Subscription__c)sourceObject;
				}
				else if(sourceObject instanceof SubscriptionLine__c) {
					sub = ((SubscriptionLine__c)sourceObject).Subscription__r;
				}
				if(sub != null) {
					retval = sub.Account__c;
				}
			}
			return retval;
		}

		/** For renewals we'll take non-account number matches as close enough when needed. */
		protected override void matchEBSAccount(Boolean xpreferSalesAccounts,Map<Id,EBS_Account__c> xebsAccountMap,Map<String,List<EBS_Account__c>> xebsAccountsKeyMap) {
			refEBSAccount = xebsAccountMap.get( refEBSAccountId );
			setEBSAccount( refEBSAccount );
			if( refEBSAccount == null || (xpreferSalesAccounts && isPartner(refEBSAccount))) {
				addEBSAccounts( xebsAccountsKeyMap.get( idKey(refSalesAccountId) ) );
				for(String oracleAccountNumber : oracleAccountNumbers) {
					addEBSAccounts( xebsAccountsKeyMap.get( accountNumberKey(oracleAccountNumber) ) );
					System.debug('oracleAccountNumber: '+oracleAccountNumber);
				}
				for(String cdhPartyNumber : cdhPartyNumbers) {
					addEBSAccounts( xebsAccountsKeyMap.get( cdhPartyNumberKey(cdhPartyNumber) ) );
				}
			}
		}
	}
}