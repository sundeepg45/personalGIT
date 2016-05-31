/**
 * Opportunity_Subscription.cls
 *
 * @version 2016-01-28
 * @author Bill Riemers <briemers@redhat.com>
 * 2016-01-28 - US74944 - assign reseller fields for LATAM
 * 2015-04-28 - Added conversion of operating unit for WEB STANDARD - US.
 * 2015-03-30 - using the ignore errors filter
 * 2015-03-26 - Correcting the copying of opportunity contact roles to happen on the new opportunity...
 * 2015-03-24 - Readded financial partner errors.  Added operating unit errors.  Removed deferredErrors.
 * 2015-03-19 - Readded the no lines error reason
 * 2015-03-17 - Correct handling of contract start and end dates
 * 2015-03-16 - Added logic for DNR, NFR, and Already Renewed
 * 2015-03-16 - Added more exception handling.
 * 2015-03-14 - New and improved rollback logic, corrected the external id values
 * 2015-03-03 - Revised forecast category, stage name, and probability assignments
 * 2015-02-24 - Added primaryReseller and revised code to set reseller fields on update instead of insert
 * 2015-02-05 - Added a new createContacts method
 * 2015-02-03 - Revised getAccount() to return OriginalOpportunity.Account or EntitleToEBSAccount__r.Sales_Account__r rather than null
 * 2015-01-28 - Made more bulk friendly by moving campaign member and contact role inserts into the parent class
 * 2015-01-28 - Disabled account creation, unless a special costom setting is set
 * 2015-01-28 - Depreciated code for creating contacts
 * 2015-01-22 - Combined financial partner and reseller creation, and refactored to make opportunity operations bulk fieldly
 * 2015-01-15 - Revised fulfillment channel mapping
 * 2015-01-14 - Refactored with OppCreator subclass to make more bulk friendly
 * 2014-12-22 - Depend on trigger to create contacts when in a READY Status
 * 2014-12-22 - Revised LATAM to add shipping contact role
 * 2014-12-22 - Commented out account creation - legacy
 * 2014-12-10 - Revised AssignTo logic to consider AssignToId__c as well.
 * 2014-12-10 - Added support for Bill-To, Entitle-To, Ship-To, and Sold-To fields
 * 2014-11-24 - Correct test failures
 * 2014-11-21 - Re-enabled campaign & coterm processing
 * 2014-11-19 - Corrected APAC forcast category
//+ * 2014-10-06 - Updated so LATAM loads both shipping and sold to contacts
 * 2014-10-06 - New owner logic supercedes old JAPAN rule
 * 2014-10-06 - Corrected 3 year contracts since days between is one day less that total term length
 * 2014-10-06 - Updated so AssignTo__r is also the owner for newly created opportunity and contacts
 * 2014-10-06 - Update EMEA to set the date back one month in an update, so the autoclosure will be based on the original close date.
 * 2014-10-06 - Changed Forecast Category for EMEA, LATAM, and NA
 * 2014-10-06 - Moved EMEA close date to start of the month if in the first month of a quarter.
 * 2014-10-06 - Corrected EMEA channel mapping. Use inactive bill-to records.
 * 2013-10-01 - Rewrite of Opportunity_Renewal to use subscription objects
 * 2013-10-14 - Update for the assignAccount trigger
 * Scott Coleman <scoleman@redhat.com>
 * 2015-11-24 - Updating opportunity type value from "Co-Term" to "CoTerm"
 * 2014-01-07 - Update to use previously mapped subscription contacts on opportunity
 * 2014-01-09 - Update to use previously mapped subscription reseller partner on opportunity
 * 2014-01-10 - Update to use previously mapped subscription source opportunity
 * 2014-01-13 - Introduced additional contructor to facilitate testing
 */
public without sharing class Opportunity_Subscription {
	/** 
	 * BooleanSetting__c key to enable the creation of legal entity accounts.  This option is
	 * not bulk friendly, and only remains to help with debugging on a non-full data sandbox.
	 */
	public static final String CREATE_ACCOUNT_SETTING = 'Opp_Sub.createAccount';
	/** StringSetting__c key for ignored some errors. */
	public static final String WEB_STANDARD_US_ORDER_TYPE = 'WEB STANDARD - US';
	public static final String RH_US_OPERATING_UNIT_NAME = 'RH US Operating Unit';
	public static final String IGNORE_FAILURE_KEY = 'C360.Renewal.Ignore';
	public static final String SALESFORCE_MSG_NAMESPACE = 'http://salesforce.redhat.com/renewals';
	public static final String SUCCESS_STATUS = 'SUCCESS';
	public static final String READY_STATUS = 'READY';
	public static final String ERROR_STATUS = 'ERROR';
	public static final String STATUS_CO_TERMED = 'COTERMED';
//	public static final String STATUS_DUPLICATE = 'DUPLICATE';
	public static final String SHIPPING_CONTACT_ROLE = 'Shipping Contact';
	public static final String SELLING_CONTACT_ROLE = 'Technical Buyer';
	public static final String RESELLER_TYPE = 'Reseller';
	public static final String INACTIVE_SKU_REASON = 'Inactive SKU';
	public static final String INVALID_PARTNER_REASON = 'Invalid Partner';
	public static final String INVALID_SKU_REASON = 'Invalid SKU';
	public static final String INTERNAL_ERROR_REASON = 'Internal Error';
	public static final String INVALID_FINANCIAL_PARTNER_REASON = 'Invalid Financial Partner';
	public static final String INVALID_OPERATING_UNIT_REASON = 'Invalid Operating Unit';
	public static final String INVALID_OWNER_REASON = 'Invalid Owner';
	public static final String INVALID_LINE_REASON = 'Invalid Line';
	public static final String MISSING_ACCOUNT_REASON = 'Missing Account';
	public static final String NO_LINES_REASON = 'No Lines';
	public static final String CLOUD_PROVIDER_FC = 'Cloud Provider';
	public static final String DIRECT_END_CUSTOMER_FC = 'Direct End Customer';
	public static final String DIRECT_RESELLER_FC = 'Direct Reseller';
	public static final String DISTRIBUTOR_FC = 'Distributor';
	public static final String OEM_FC = 'OEM';
	public static final String OEM_ROYALTIES_FC = '<OEM ROYALTIES>';
	public static final String WEBSTORE_FC = 'Webstore';
	public static final String DEFAULT_FC = DIRECT_END_CUSTOMER_FC;

	public static Map<String,String> FC_MAP {
		get {
			if(FC_MAP == null) {
				FC_MAP = new Map<String,String> {
					'directendcustomer' => DIRECT_END_CUSTOMER_FC,
					'distributor' => DISTRIBUTOR_FC,
					'directcarasoftnaonly' => DISTRIBUTOR_FC,
					'directcarasoft' => DISTRIBUTOR_FC, // old SFDC value, but also possible typo
					'directcarahsoftnaonly' => DISTRIBUTOR_FC, // possible typo
					'directcarahsoft' => DISTRIBUTOR_FC, //  old SFDC value, but also possible typo
//reject					'directimmixgroup' => DISTRIBUTOR_FC, // old SFDC values
//reject					'indirectvarvad' => DISTRIBUTOR_FC, // old SFDC values
					'reseller' => DIRECT_RESELLER_FC,
					'directdltnaonly' => DIRECT_RESELLER_FC,
					'directdlt' => DIRECT_RESELLER_FC, //  old SFDC value, but also possible typo
//reject					'directgtsi' => DIRECT_RESELLER_FC, // old SFDC value
					'directreseller' => DIRECT_RESELLER_FC,
//reject					'directvarvad' => DIRECT_RESELLER_FC, // old SFDC value
					'webstore' => WEBSTORE_FC,
//reject					'directvarvad' => WEBSTORE_FC, // old SFDC value
//reject					'indirectwebstore' => WEBSTORE_FC, // old SFDC value
					'oem' => OEM_FC,
					'oempo' => OEM_FC,
//reject					'directoem' => OEM_FC, // old SFDC value
//reject					'indirectoempreload' => OEM_FC, // old SFDC value
					'oemroyalties' => OEM_ROYALTIES_FC, // special value
					'direct' => DIRECT_END_CUSTOMER_FC,
					'cloudprovider' => CLOUD_PROVIDER_FC,
					'emailcenter' => DEFAULT_FC,
					'trainingreseller' => DEFAULT_FC };
			}
			return FC_MAP;
		}
	}

	@TestVisible
	private static Map<String,String> FORECAST_CATEGORY_MAP {
		get {
			if(FORECAST_CATEGORY_MAP == null) {
				FORECAST_CATEGORY_MAP = new Map<String,String>{
					'APAC' => 'Pipeline',
					'EMEA' => 'Commit',
					'JAPAN' => 'Pipeline',
					'LATAM' => 'Best Case',
					'NA' => 'Commit'
				};
			}
			return FORECAST_CATEGORY_MAP;
		}
	}

	@TestVisible
	private static Map<String,String> STAGE_MAP {
		get {
			if(STAGE_MAP == null) {
				STAGE_MAP = new Map<String,String>{
					'APAC' => 'Engage',
					'EMEA' => 'Negotiate',
					'JAPAN' => 'Engage',
					'LATAM' => 'Propose',
					'NA' => 'Negotiate'
				};
			}
			return STAGE_MAP;
		}
	}

	@TestVisible
	private static Map<String,Double> PROBABILITY_MAP {
		get {
			if(PROBABILITY_MAP == null) {
				PROBABILITY_MAP = new Map<String,Double>{
//					'APAC' => default,
					'EMEA' => 75.0,
//					'JAPAN' => default,
					'LATAM' => 60.0 //,
//					'NA' => default
				};
			}
			return PROBABILITY_MAP;
		}
	}

	Map<String,Account> accountMap = new Map<String,Account>();
//depreciated	private Map<Id,Map<String,Contact>> contactMap = new Map<Id,Map<String,Contact>>();

	// Map of OppCreator objects based on subscription id
	@TestVisible
	final Map<Id,OppCreator> oppCreatorMap = new Map<Id,OppCreator>();

	static Date nillValue(Date value,Date defaultValue) {
		if(value == null) {
			value = defaultValue;
		}
		return value;
	}

	/** All valid Opportunity.Opportunity_Unit__c values converted to lower case. */
	public static Set<String> operatingUnitValues {
		get {
			if(operatingUnitValues == null) {
				operatingUnitValues = new Set<String>();
				for(Schema.PicklistEntry ple : Opportunity.Operating_Unit__c.getDescribe().getPicklistValues()) {
					operatingUnitValues.add((''+ple.getValue()).toLowerCase());
				}
			}
			return operatingUnitValues;
		}
	}

	/** All valid Opportunity.Order_Type__c values converted to lower case. */
	public static Set<String> orderTypeValues {
		get {
			if(orderTypeValues == null) {
				orderTypeValues = new Set<String>();
				for(Schema.PicklistEntry ple : Opportunity.Order_Type__c.getDescribe().getPicklistValues()) {
					orderTypeValues.add((''+ple.getValue()).toLowerCase());
				}
			}
			return orderTypeValues;
		}
	}

	/**
	 * Return if the first value is non-zero and non-null, return that value.
	 * Otherwise if the second value is not null return that value, otherwise return 0.00.
	 * 
	 * @param retval value to return if not null or 0.
	 * @param defaultValue value to return if the first value is 0.
	 * @return a non-null value as specified
	 */
	public static Decimal selectPrice(Decimal retval,Decimal defaultValue) {
		if(retval == null || retval == 0) {
			retval = defaultValue;
			if(retval == null) {
				retval = 0.00;
			}
		}
		return retval;
	}

	/**
	 * Creates a new renewal opportunity
	 */
	public static Map<Id,List<Database.Error>> createRenewalOpportunities(Set<Id> subscriptionIds,Boolean needUpdate) {
		Map<Id,List<Database.Error>> retval = new Map<Id,List<Database.Error>>();
		if(needUpdate) {
			List<Subscription__c> updateList = new List<Subscription__c>();
			for(Id subscriptionId : subscriptionIds) {
				updateList.add(new Subscription__c(Id=subscriptionId));
			}
			appendUpdateErrors(retval,Database.update(updateList,false));
			subscriptionIds.removeAll(retval.keySet());
		}
		if(! subscriptionIds.isEmpty()) {
			Opportunity_Subscription oppSub = new Opportunity_Subscription(subscriptionIds);
			oppSub.createRenewalOpportunities( retval );
		}
		return retval;
	}

	void createRenewalOpportunities( Map<Id,List<Database.Error>> retval ) {
		List<Opportunity> opportunities = new List<Opportunity>();
		List<OppCreator> oppCreators = new List<OppCreator>();
		for(OppCreator oppCreator : oppCreatorMap.values()) {
			if(oppCreator.subscription.Opportunity__c != null) {
				opportunities.add(new Opportunity(Id=oppCreator.subscription.Opportunity__c));
				oppCreators.add(oppCreator);
			}
		}
		if(! opportunities.isEmpty()) {
			for(Database.DeleteResult dr : Database.delete(opportunities,false)) {
				Opportunity opp = opportunities.remove(0);
				OppCreator oppCreator = oppCreators.remove(0);
				oppCreator.setOpportunity(null);
				if(! dr.isSuccess()) {
					oppCreator.addError(
						INTERNAL_ERROR_REASON,
						'Failed to delete Opportunity '+opp.Id+' : '+dr.getErrors(),
						true );
				}
			}
		}
		SavePoint sp = null;
		try {
			sp = Database.setSavePoint();
			oppCreators = insertOpportunities();
			createContacts(oppCreators);
			insertOpportunityPartners(oppCreators);
			insertCampaignMembers(insertOpportunityContactRoles(oppCreators));
			upsertExpiringProducts(oppCreators);
			insertOpportunityLineItems(oppCreators);
			updateOpportunities(oppCreators); // this clears the oppCreators list
			for(OppCreator oppCreator : oppCreatorMap.values()) {
				if(oppCreator.prepareErrors()) {
					if(oppCreator.subscription.Opportunity__c != null) {
						opportunities.add(new Opportunity(Id=oppCreator.subscription.Opportunity__c));
					}
				}
			}
			Map<Id,Subscription__c> subscriptionMap = new Map<Id,Subscription__c>();
			List<SubscriptionError__c> errors = new List<SubscriptionError__c>();
			Map<Id,SubscriptionLine__c> updateLineMap = new Map<Id,SubscriptionLine__c>();
			Map<Id,SubscriptionPartner__c> updatePartnerMap = new Map<Id,SubscriptionPartner__c>();
			Map<Id,SubscriptionPartnerRelationship__c> updatePartnerRelationshipMap = new Map<Id,SubscriptionPartnerRelationship__c>();
			for(OppCreator oppCreator : oppCreatorMap.values()) {
				errors.addAll(oppCreator.errorList);
				subscriptionMap.put(oppCreator.subscription.Id,oppCreator.subscription);
				updateLineMap.putAll(oppCreator.updateLines);
				updatePartnerMap.putAll(oppCreator.updatePartners);
				updatePartnerRelationshipMap.putAll(oppCreator.updatePartnerRelationships);
			}
			appendUpdateErrors(retval,Database.update(subscriptionMap.values(),false));
			for(Database.UpsertResult ur : Database.upsert(errors,false) ) {
				SubscriptionError__c se = errors.remove(0);
				if (! ur.isSuccess()) {
					System.debug(LoggingLevel.ERROR,'Failed to upsert error: ' + se+'\n'+ur.getErrors() );
				}
			}
			appendUpdateErrors(retval,Database.update(updateLineMap.values(),false));
			appendUpdateErrors(retval,Database.update(updatePartnerMap.values(),false));
			appendUpdateErrors(retval,Database.update(updatePartnerRelationshipMap.values(),false));
			Database.delete(opportunities,false);
			sp = null;
		}
		finally {
			if(sp != null) {
				Database.rollback(sp);
			}
		}
	}

	static void appendUpdateErrors(Map<Id,List<Database.Error>> errorMap,List<Database.SaveResult> saveResults) {
		for(Database.SaveResult ur : saveResults) {
			if(! ur.isSuccess()) {
				errorMap.put(ur.getId(),ur.getErrors());
			}
		}
	}

	// mapping of Partner Status objects based on the opportunity Billing Account Number
	public Map<String,PartnerStatus__c> financialPartnerMap {
		get {
			if(financialPartnerMap == null) {
				financialPartnerMap = new Map<String,PartnerStatus__c>();
				Set<String> billingAccountNumbers = new Set<String>();
				for(OppCreator oppCreator : oppCreatorMap.values()) {
					if(oppCreator.subscription != null
						&& oppCreator.subscription.Opportunity__r != null
						&& oppCreator.subscription.Opportunity__r.BillingAccountNumber__c != null )
					{
						billingAccountNumbers.add(oppCreator.subscription.Opportunity__r.BillingAccountNumber__c);
					}
				}
				if(! billingAccountNumbers.isEmpty()) {
					Map<Id,Set<String>> accountIdMap = new Map<Id,Set<String>>();
					for(EBS_Account__c ebsAccount : [
						select
							Name,
							Sales_Account__c
						from EBS_Account__c
						where Name in :billingAccountNumbers
							and Status__c != 'Inactive' ] )
					{
						Set<String> values = accountIdMap.get( ebsAccount.Sales_Account__c );
						if(values == null ) {
							values = new Set<String>();
							accountIdMap.put( ebsAccount.Sales_Account__c, values );
						}
						values.add( ebsAccount.Name );
					}
					List<PartnerStatus__c> partnerStatusList = [
						select
							Partner__c,
							Partner__r.Name,
							PartnerTier__c,
							PartnerType__c,
							PartnerType__r.Hierarchy__c,
							Partner__r.OracleAccountNumber__c,
							Partner__r.PrimaryBillingAccountNumber__c
						from PartnerStatus__c
						where ActivationStatus__c = 'Active'
							and ( Partner__c in :accountIdMap.keySet()
								or Partner__r.OracleAccountNumber__c in :billingAccountNumbers
								or Partner__r.PrimaryBillingAccountNumber__c in :billingAccountNumbers)];
					for(PartnerStatus__c partnerStatus : partnerStatusList ) {
						if(partnerStatus.Partner__r != null && partnerStatus.Partner__r.PrimaryBillingAccountNumber__c != null) {
							financialPartnerMap.put(partnerStatus.Partner__r.PrimaryBillingAccountNumber__c,partnerStatus);
						}
					}
					for(PartnerStatus__c partnerStatus : partnerStatusList ) {
						if(partnerStatus.Partner__r != null && partnerStatus.Partner__r.OracleAccountNumber__c != null) {
							financialPartnerMap.put(partnerStatus.Partner__r.OracleAccountNumber__c,partnerStatus);
						}
					}
					for(PartnerStatus__c partnerStatus : partnerStatusList ) {
						Set<String> accountNumbers = accountIdMap.get(partnerStatus.Partner__c);
						if ( accountNumbers != null ) {
							for(String accountNumber : accountNumbers ) {
								financialPartnerMap.put(accountNumber,partnerStatus);
							}
						}
					}
					financialPartnerMap.keySet().retainAll(billingAccountNumbers);
				}
			}
			return financialPartnerMap;
		}
		set;
	}

	public void createContacts(List<OppCreator> oppCreators) {
		List<Subscription__c> subscriptionList = new List<Subscription__c>();
		List<SubscriptionLine__c> subscriptionLineList = new List<SubscriptionLine__c>();
		for(OppCreator oppCreator : oppCreators) {
			subscriptionList.add(oppCreator.subscription);
			subscriptionLineList.addAll(oppCreator.getSubscriptionLines());
		}
		SubscriptionTriggerBefore beforeTrigger = new SubscriptionTriggerBefore(null,subscriptionList);
		beforeTrigger.readyList = subscriptionList;
		beforeTrigger.contactInsertSizeLimit = subscriptionLineList.size()+subscriptionList.size()*6;
		beforeTrigger.createContacts(subscriptionLineList);
	}

	/**
	 * create the opportunity contact role
	 * @param opportunityContactRoleMap
	 * @param opportunityId
	 * @param contactId
	 * @param role
	 * @param isPrimary
	 * @return newly created opportunity contact role or null
	 */
	@TestVisible
	OpportunityContactRole createOpportunityContactRole(
		Map<String,OpportunityContactRole> opportunityContactRoleMap,
		Id contactId,
		Id opportunityId,
		String role,
		Boolean isPrimary)
	{
		OpportunityContactRole retval = null;
		if (contactId != null && opportunityId != null) {
			retval = new OpportunityContactRole(
				OpportunityId = opportunityId,
				ContactId = contactId,
				Role = role,
				IsPrimary = isPrimary);
			String key = OpportunityId+':'+contactId+':'+role;
			if(isPrimary || ! opportunityContactRoleMap.containsKey(key)) {
				opportunityContactRoleMap.put(key, retval );
			}
		}
		return retval;
	}

	/**
	 * create the opportunity contact role and campaign member
	 * @param campaignMemberMap to add campaign to
	 * @param campaignId
	 * @param contactId
	 * @return newly created opportunity contact role or null
	 */
	@TestVisible
	CampaignMember createCampaignMember(
		Map<String,CampaignMember> campaignMemberMap,
		Id campaignId,
		Id contactId )
	{
		CampaignMember retval = null;
		// ignore the results
		if(contactId != null && campaignId != null) {
			retval = new CampaignMember(
				ContactId = contactId,
				CampaignId = campaignId,
				Status = 'Responded');
			String key = contactId+':'+campaignId;
			campaignMemberMap.put(key,retval);
		}
		return retval;
	}	

	// return a map based on opportunity id of source contact roles
	@TestVisible
	Map<Id,List<OpportunityContactRole>> sourceOpportunityContactRolesMap {
		get {
			if(sourceOpportunityContactRolesMap == null) {
				sourceOpportunityContactRolesMap = new Map<Id,List<OpportunityContactRole>>();
				Set<Id> sourceOpportunityIds = new Set<Id>();
				for(OppCreator oppCreator : oppCreatorMap.values()) {
					sourceOpportunityIds.add(oppCreator.subscription.OriginalOpportunity__c);
				}
				for(Id key : sourceOpportunityIds) {
					List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
					sourceOpportunityContactRolesMap.put(key,ocrList);
				}
				sourceOpportunityIds.remove(null);
				if(! sourceOpportunityIds.isEmpty()) {
					for(OpportunityContactRole ocr : [
						select 
							ContactId,
							IsPrimary,
							OpportunityId, 
							Role
						from OpportunityContactRole
						where OpportunityId in :sourceOpportunityIds
							and (Role = 'Payables Contact' or Role = :SHIPPING_CONTACT_ROLE) ] )
					{
						List<OpportunityContactRole> ocrList = sourceOpportunityContactRolesMap.get(ocr.OpportunityId);
						if(ocrList == null) {
							ocrList = new List<OpportunityContactRole>();
							sourceOpportunityContactRolesMap.put(ocr.OpportunityId,ocrList);
						}
						ocrList.add(ocr);
					}
				}
			}
			return sourceOpportunityContactRolesMap;
		}
		set;
	}

	// bulk insert of all the contact roles
	@TestVisible
	List<CampaignMember> insertOpportunityContactRoles(List<OppCreator> oppCreatorList) {
		Map<String,OpportunityContactRole> opportunityContactRoleMap = new Map<String,OpportunityContactRole>();
		Map<String,CampaignMember> campaignMemberMap = new Map<String,CampaignMember>();
		Map<Id,OppCreator> oppCreatorMap2 = new Map<Id,OppCreator>();
		for(OppCreator oppCreator : oppCreatorList) {
			Id oppId = oppCreator.getOpportunityId();
			if(oppId != null) {
				oppCreatorMap2.put(oppId,oppCreator);
				oppCreator.copyOpportunityContactRoles(opportunityContactRoleMap,campaignMemberMap);
				oppCreator.addShippingContact(opportunityContactRoleMap,campaignMemberMap);
				oppCreator.addSellingContact(opportunityContactRoleMap,campaignMemberMap);
			}
		}
		List<OpportunityContactRole> opportunityContactRoles = opportunityContactRoleMap.values();

		if(! opportunityContactRoles.isEmpty()) {
			for (Database.SaveResult saveResult : Database.insert(opportunityContactRoles,false)) 
			{
				OpportunityContactRole opportunityContactRole = opportunityContactRoles.remove(0);
				// log and otherwise ignore errors
				if (! saveResult.isSuccess()) {
					OppCreator oppCreator = oppCreatorMap2.get(opportunityContactRole.OpportunityId);
					oppCreator.addError(
						INTERNAL_ERROR_REASON, 
						system.Label.C360_R33 + ': ' + saveResult.getErrors(),
						false );
				}
			}
		}
		return new List<CampaignMember>(campaignMemberMap.values());
	}

	// bulk insert of the campaign members
	@TestVisible
	void insertCampaignMembers(List<CampaignMember> campaignMembers) {
		if(! campaignMembers.isEmpty()) {
			for (Database.SaveResult saveResult : Database.insert(campaignMembers,false)) 
			{
				CampaignMember campaignMember = campaignMembers.remove(0);
				// log and otherwise ignore errors
				if (! saveResult.isSuccess()) {
					System.debug(LoggingLevel.ERROR,'Failed to create Campaign Member:\n\t' + campaignMember+'\n'+saveResult.getErrors() );
				}
			}
		}
	}

	// Map of pricebook entries by currency iso code
	Map<String,Map<String, PricebookEntry>> pricebookEntryMapByCurrencyIsoCode {
		get {
			if(pricebookEntryMapByCurrencyIsoCode == null) {
				pricebookEntryMapByCurrencyIsoCode = new Map<String,Map<String, PricebookEntry>>();
				Set<String> productCodes = new Set<String>();
				Set<String> currencyIsoCodes = new Set<String>();
				for(OppCreator oppCreator : oppCreatorMap.values()) {
					productCodes.addAll(oppCreator.getProductCodes());
					currencyIsoCodes.add(oppCreator.subscription.CurrencyIsoCode);
				}
				for(String currencyIsoCode : currencyIsoCodes) {
					pricebookEntryMapByCurrencyIsoCode.put((''+currencyIsoCode).toUpperCase(),new Map<String,PricebookEntry>());
				}
				if(! productCodes.isEmpty()) {
					// query the pricebook entry by productCode
					// populate the pricebook entry map with the results
					for ( PricebookEntry pbe : [
						SELECT
							UnitPrice,
							CurrencyIsoCode,
							IsActive,
							Product2.Description,
							Product2.Id,
							Product2.ProductCode,
							Product2.IsActive,
							Pricebook2.Name
						FROM PricebookEntry
						WHERE Product2.ProductCode IN :productCodes
							AND CurrencyIsoCode = :currencyIsoCodes
							AND Pricebook2.Name = 'Global Price Book' ] )
					{
						Map<String,PricebookEntry> pricebookEntryMap = pricebookEntryMapByCurrencyIsoCode.get(pbe.CurrencyIsoCode.toUpperCase());
						if((pbe.IsActive == true && pbe.Product2.IsActive == true)|| ! pricebookEntryMap.containsKey(pbe.Product2.ProductCode)) {
							pricebookEntryMap.put ( pbe.Product2.ProductCode, pbe );
						}
					}
				}
			}
			return pricebookEntryMapByCurrencyIsoCode;
		}
		set;
	}

	/**
	 * Truncate a string to the specified length.
	 */
	public static String truncate(String value, Integer len) {
		if(value != null && value.length() > len) {
			value = value.substring(0,len);
		}
		return value;
	}

	static Id getSalesAccountId(EBS_Account__c e, Address__c a, Contact c) {
		Id retval = null;
		if(e != null && e.Sales_Account__c != null) {
			retval = e.Sales_Account__c;
		}
		else if(a != null && a.Sales_Account__c != null) {
			retval = a.Sales_Account__c;
		}
		else if(c != null && c.AccountId != null) {
			retval = c.AccountId;
		}
		return retval;
	}

	// Constructor, based on querying a set of subscription ids.
	@TestVisible
	Opportunity_Subscription(Set<Id> subscriptionIds) {
		for(Subscription__c subscription : [
			select
				Account__c,
				Account__r.Owner.IsActive,
				Account__r.Owner.Name,
				Account__r.Owner.Email,
				Account__r.Owner.UserRole.Name,
				Account__r.Name,
				AssignTo__c,
				AssignTo__r.IsActive,
				AssignTo__r.Name,
				AssignTo__r.Email,
				AssignTo__r.UserRole.Name,
				AssignToId__c,
				BillToAccountNumber__c,
				BillToAddress__c,
				BillToAddress__r.Sales_Account__c,
				BillToAddress1__c,
				BillToAddress2__c,
				BillToCDHPartyNumber__c,
				BillToCDHPartySiteNumber__c,
				BillToCity__c,
				BillToContCDHPartyNumber__c,
				BillToContactEmail__c,
				BillToContact__c,
				BillToContact__r.CDH_Party_Number__c,
				BillToContact__r.AccountId,
				BillToContact__r.Account.RecordType.Name,
				BillToContact__r.Email,
				BillToCountry__c,
				BillToEBSAccount__c,
				BillToEBSAccount__r.Sales_Account__c,
				BillToPartyName__c,
				BillToPostalCode__c,
				BillToSfAddressId__c,
				BillToSfContactId__c,
				BillToSfEBSAccountId__c,
				BillToState__c,
				BusinessUnitId__c,
				BusinessUnitName__c,
				Campaign__c,
				ContractAmount__c,
				ContractEndDate__c,
				ContractNumber__c,
				ContractStartDate__c,
				CountryOfOrder__c,
				CurrencyIsoCode,
				EntitleToAddress__c,
				EntitleToAddress__r.Sales_Account__c,
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
				EntitleToEBSAccount__r.Sales_Account__c,
				EntitleToEBSAccount__r.Sales_Account__r.Owner.IsActive,
				EntitleToEBSAccount__r.Sales_Account__r.Owner.Name,
				EntitleToEBSAccount__r.Sales_Account__r.Owner.Email,
				EntitleToEBSAccount__r.Sales_Account__r.Owner.UserRole.Name,
				EntitleToEBSAccount__r.Sales_Account__r.Name,
				EntitleToSfAddressId__c,
				EntitleToSfContactId__c,
				EntitleToSfEBSAccountId__c,
				ErrorMessage__c,
				LeadSourceDetail__c,
				Opportunity__c,
				OpportunityNumber__c,
				OrderId__c,
				OrderNumber__c,
				OrderSourceName__c,
				OrderTypeName__c,
				OriginalOpportunity__c,
				OriginalOpportunity__r.AccountId,
				OriginalOpportunity__r.Account.Owner.IsActive,
				OriginalOpportunity__r.Account.Owner.Name,
				OriginalOpportunity__r.Account.Owner.Email,
				OriginalOpportunity__r.Account.Owner.UserRole.Name,
				OriginalOpportunity__r.Account.Name,
				OriginalOpportunity__r.Country_Of_Order__c,
				OriginalOpportunity__r.ContractStartDate__c,
				OriginalOpportunity__r.ContractEndDate__c,
				OriginalOpportunity__r.Owner.IsActive,
				OriginalOpportunity__r.Touched__c,
				PurchaseOrderNumber__c,
				Region__c,
				SalesChannelCode__c,
				SellingContact__c,
				ShippingContact__c,
				ShipToAddress__c,
				ShipToAddress__r.Sales_Account__c,
				ShipToAddress1__c,
				ShipToAddress2__c,
				ShipToAccountNumber__c,
				ShipToCDHPartyNumber__c,
				ShipToCDHPartySiteNumber__c,
				ShipToCity__c,
				ShipToContact__c,
				ShipToContact__r.CDH_Party_Number__c,
				ShipToContact__r.AccountId,
				ShipToContact__r.Account.RecordType.Name,
				ShipToContact__r.Email,
				ShipToContactEmail__c,
				ShipToContactFirstName__c,
				ShipToContactLastName__c,
				ShipToContactName__c,
				ShipToContactPhone__c,
				ShipToContCDHPartyNumber__c,
				ShipToCountry__c,
				ShipToPostalCode__c,
				ShipToState__c,
				ShipToEBSAccount__c,
				ShipToEBSAccount__r.Sales_Account__c,
				ShipToSfAddressId__c,
				ShipToSfContactId__c,
				ShipToSfEBSAccountId__c,
				SoldToAccountNumber__c,
				SoldToAddress__c,
				SoldToAddress__r.Sales_Account__c,
				SoldToCDHPartyNumber__c,
				SoldToCDHPartySiteNumber__c,
				SoldToContact__c,
				SoldToContact__r.CDH_Party_Number__c,
				SoldToContact__r.AccountId,
				SoldToContact__r.Account.RecordType.Name,
				SoldToContact__r.Email,
				SoldToContactEmail__c,
				SoldToContactFirstName__c,
				SoldToContactLastName__c,
				SoldToContactName__c,
				SoldToContactPhone__c,
				SoldToContCDHPartyNumber__c,
				SoldToCountry__c,
				SoldToEBSAccount__c,
				SoldToEBSAccount__r.Sales_Account__c,
				SoldToEBSAccount__r.Sales_Account__r.Owner.IsActive,
				SoldToEBSAccount__r.Sales_Account__r.Owner.Name,
				SoldToEBSAccount__r.Sales_Account__r.Owner.Email,
				SoldToEBSAccount__r.Sales_Account__r.Owner.UserRole.Name,
				SoldToEBSAccount__r.Sales_Account__r.Name,
				SoldToPartyName__c,
				SoldToSfAddressId__c,
				SoldToSfContactId__c,
				SoldToSfEBSAccountId__c,
				SSI_InScope__c,
				Status__c,
				SuperRegion__c,
				(	select
						AlreadyRenewed__c,
						CurrencyIsoCode,
						ConfiguredItem__c,
						ContractId__c,
						ContractLineId__c,
						ErrorMessage__c,
						ExpiringProduct__c,
						EntitleToAddress__c,
						EntitleToAddress__r.Sales_Account__c,
						EntitleToAccountNumber__c,
						EntitleToCDHPartyNumber__c,
						EntitleToCDHPartySiteNumber__c,
						EntitleToContCDHPartyNumber__c,
						EntitleToContactEmail__c,
						EntitleToContact__c,
						EntitleToContact__r.CDH_Party_Number__c,
						EntitleToContact__r.AccountId,
						EntitleToContact__r.Account.RecordType.Name,
						EntitleToContact__r.Email,
						EntitleToCountry__c,
						EntitleToEBSAccount__c,
						EntitleToEBSAccount__r.Sales_Account__c,
						EntitleToSfAddressId__c,
						EntitleToSfContactId__c,
						EntitleToSfEBSAccountId__c,
						FulfilledItemDescription__c,
						InstanceNumber__c,
						NetUnitSellingPrice__c,
						OpportunityLineItemId__c,
						OrderedItem__c,
						OrderedQuantity__c,
						OrderLineId__c,
						OriginalSubscription__c,
						OriginalSubscription__r.ContractStartDate__c,
						OriginalSubscription__r.ContractEndDate__c,
						OriginalSubscription__r.ContractId__c,
						OriginalSubscription__r.ContractNumber__c,
						OriginalSubscription__r.OpportunityNumber__c,
						OriginalSubscription__r.OrderId__c,
						OriginalSubscription__r.OrderNumber__c,
						OriginalSubscription__r.OriginalOpportunity__c,
						OriginalSubscription__r.PurchaseOrderNumber__c,
						OrigOpportunityLineId__c,
						RenewalItem__c,
						ServiceEndDate__c,
						ServiceStartDate__c,
						Status__c,
						Subscription__c,
						SubstituteItem__c,
						TotalPrice__c,
						UnitSellingPrice__c
					from SubscriptionLines__r 
					where DnrFlag__c = false and NfrFlag__c = false ),
				(	select
						ErrorMessage__c,
						OpportunityPartner__c,
						Status__c,
						SubscriptionPartner__r.Account__c,
						SubscriptionPartner__r.Account__r.Name,
						SubscriptionPartner__r.AccountNumber__c,
						SubscriptionPartner__r.ContactEmail__c,
						SubscriptionPartner__r.ContactFirstName__c,
						SubscriptionPartner__r.ContactLastName__c,
						SubscriptionPartner__r.ContactName__c,
						SubscriptionPartner__r.ContactPhone__c,
						SubscriptionPartner__r.PartnerStatus__c,
						SubscriptionPartner__r.PartnerStatus__r.ActivationStatus__c,
						SubscriptionPartner__r.PartnerStatus__r.Partner__c,
						SubscriptionPartner__r.PartnerStatus__r.Partner__r.Name,
						SubscriptionPartner__r.PartnerStatus__r.PartnerType__c,
						SubscriptionPartner__r.PartnerStatus__r.PartnerTier__c,
						SubscriptionPartner__r.PartyName__c,
						SubscriptionPartner__r.PartyNumber__c,
						SubscriptionPartner__r.PurchaseOrderNumber__c,
						SubscriptionPartner__r.TransactionRole__c
					from Subscription_Partner_Relationships__r ),
				(	select
						Id,
						Reason__c,
						Details__c,
						Subscription__c,
						SubscriptionLine__c,
						SubscriptionPartnerRelationship__c
					from Subscription_Errors__r )
			from Subscription__c
			where Id in :subscriptionIds
			FOR UPDATE ])
		{
			new OppCreator(this,subscription);
		}
	}

	// Map of OppCreator's that need opportunties inserted, based on subscription id
	Map<Id,OppCreator> needOpportunityInsertMap {
		get {
			if(needOpportunityInsertMap == null) {
				needOpportunityInsertMap = new Map<Id,OppCreator>();
				for(OppCreator oppCreator : oppCreatorMap.values()) {
					oppCreator.getOpportunity();
				}
			}
			return needOpportunityInsertMap;
		}
		set;
	}

	// Insert all the opportunites as based on the needOpportunityInsertMap and return
	// a list of OppCreators where the insert was successful.
	@TestVisible
	List<OppCreator> insertOpportunities() {
		List<OppCreator> retval = new List<OppCreator>();
		List<OppCreator> oppCreatorList = needOpportunityInsertMap.values();
		if(! oppCreatorList.isEmpty()) {
			List<Opportunity> oppList = new List<Opportunity>();
			while (! oppCreatorList.isEmpty()) {
				OppCreator oppCreator = oppCreatorList.remove(0);
				try {
					Opportunity opp = oppCreator.getOpportunity();
					if(opp != null) {
						oppList.add(oppCreator.getOpportunity());
						retval.add(oppCreator);
					}
				}
				catch(Exception ex) {
					oppCreator.addError(ex);
				}
			}
			if(! oppList.isEmpty()) {
				for(Database.SaveResult sr : Database.insert(oppList,false)) {
					OppCreator oppCreator = retval.remove(0);
					Opportunity opp = oppList.remove(0);
					if(sr.isSuccess()) {
						oppCreator.setOpportunity(opp);
						oppCreator.subscription.Status__c = SUCCESS_STATUS;
						retval.add(oppCreator);
					}
					else {
						oppCreator.addError(
							INTERNAL_ERROR_REASON,
							'Opportunity Creation Failed: ' + sr.getErrors(),
							true );
					}
				}
			}
		}
		return retval;
	}

	@TestVisible
	void updateOpportunities(List<OppCreator> oppCreators) {
		if(! oppCreators.isEmpty()) {
			List<OppCreator> oppCreatorList = new List<OppCreator>();
			List<Opportunity> oppList = new List<Opportunity>();
			while(! oppCreators.isEmpty()) {
				OppCreator oppCreator = oppCreators.remove(0);
				try {
					Opportunity opp = oppCreator.updateOpportunity();
					if(opp != null) {
						oppList.add(opp);
						oppCreatorList.add(oppCreator);
					}
				}
				catch(Exception ex) {
					oppCreator.addError(ex);
				}
			}
			for(Database.SaveResult sr : Database.update(oppList,false)) {
				OppCreator oppCreator = oppCreatorList.remove(0);
				Opportunity opp = oppList.remove(0);
				if(! sr.isSuccess()) {
					oppCreator.addError(
						INTERNAL_ERROR_REASON,
						'Opportunity Update Failed: ' + sr.getErrors(),
						true );
				}
			}
		}
	}

	/**
	 * create expiring products
	 */
	@TestVisible
	void upsertExpiringProducts(List<OppCreator> oppCreators) {
		if(! oppCreators.isEmpty()) {
			List<OppCreator> oppCreatorList = new List<OppCreator>();
			List<Expiring_Product__c> expiringProducts = new List<Expiring_Product__c>();
			while(! oppCreators.isEmpty()) {
				OppCreator oppCreator = oppCreators.remove(0);
				try {
					expiringProducts.addAll(oppCreator.expiringProducts);
					oppCreatorList.add(oppCreator);
				}
				catch(Exception ex) {
					oppCreator.addError(ex);
				}
			}
			List<Database.UpsertResult> upsertResults = Database.upsert(expiringProducts,Expiring_Product__c.Fields.ExternalId__c,false);
			for(OppCreator oppCreator : oppCreatorList) {
				try {
					// save the salesforce record
					// and log the results of the salesforce save
					List<SubscriptionLine> renewalLines =  new List<SubscriptionLine>(oppCreator.lineList);
					while(! oppCreator.expiringProducts.isEmpty()) {
						Expiring_Product__c expiringProduct = oppCreator.expiringProducts.remove(0);
						Database.UpsertResult upsertResult = upsertResults.remove(0);
						SubscriptionLine renewalLine = renewalLines.remove(0);
						if (upsertResult.isSuccess()) {
							system.debug(LoggingLevel.INFO, 'Created Expiring Product: ' + upsertResult.getId());
							renewalLine.subLine.ExpiringProduct__r = expiringProduct;
							renewalLine.subLine.ExpiringProduct__c = upsertResult.getId();
							renewalLine.subLine.ErrorMessage__c = null;
							renewalLine.subLine.Status__c = SUCCESS_STATUS;
						}
						else {
							oppCreator.addError(
								INVALID_LINE_REASON,
								system.Label.C360_R34+': '+upsertResult.getErrors(),
								renewalLine.subLine);
						}
					}
					oppCreators.add(oppCreator);
				}
				catch(Exception ex) {
					oppCreator.addError(ex);
				}
			}
		}
	}

	/**
	 * create opportunity line items
	 */
	@TestVisible
	void insertOpportunityLineItems(List<OppCreator> oppCreators) {
		if(! oppCreators.isEmpty()) {
			List<OppCreator> oppCreatorList = new List<OppCreator>();
			List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
			while(! oppCreators.isEmpty()) {
				OppCreator oppCreator = oppCreators.remove(0);
				try {
					opportunityLineItems.addAll(oppCreator.opportunityLineItems);
					oppCreatorList.add(oppCreator);
				}
				catch(Exception ex) {
					oppCreator.addError(ex);
				}
			}
			List<Database.SaveResult> saveResults = Database.insert(opportunityLineItems,false);
			for(OppCreator oppCreator : oppCreatorList) {
				try {
					// save the salesforce record
					// and log the results of the salesforce save
					List<SubscriptionLine> renewalLines = new List<SubscriptionLine>(oppCreator.lineList);
					if(! oppCreator.opportunityLineItems.isEmpty()) {
						do {
							OpportunityLineItem lineItem = oppCreator.opportunityLineItems.remove(0);
							Database.SaveResult saveResult = saveResults.remove(0);
							SubscriptionLine renewalLine = renewalLines.remove(0);
							if (saveResult.isSuccess()) {
								system.debug(LoggingLevel.INFO, 'Created Opportunity Line Item: ' + saveResult.getId());
								renewalLine.subLine.OpportunityLineItemId__c = saveResult.getId();
//									renewalLine.salesforceOpportunityId = subscription.Opportunity__c;
								renewalLine.subLine.ErrorMessage__c = null;
								renewalLine.subLine.Status__c = SUCCESS_STATUS;
							}
							else {
								oppCreator.addError(
									INTERNAL_ERROR_REASON,
									'Failed to create Opportunity Line Item: ' + saveResult.getErrors(),
									renewalLine.subLine);
							}
						} while(! oppCreator.opportunityLineItems.isEmpty());
					} else if (! oppCreator.hasErrors ) {
						oppCreator.addError(
							NO_LINES_REASON,
							system.Label.C360_R37,
							true );
					}
					oppCreators.add(oppCreator);
				}
				catch(Exception ex) {
					oppCreator.addError(ex);
				}
			}
		}
	}

	/**
	 * create OpportunityPartners
	 */
	@TestVisible
	void insertOpportunityPartners(List<OppCreator> oppCreators) {
		if(! oppCreators.isEmpty()) {
			List<OppCreator> oppCreatorList = new List<OppCreator>();
			List<SubscriptionPartnerRelationship__c> partners = new List<SubscriptionPartnerRelationship__c>();
			while(! oppCreators.isEmpty()) {
				OppCreator oppCreator = oppCreators.remove(0);
				try {
					partners.addAll(oppCreator.partnersWithOpportunityPartners);
					oppCreatorList.add(oppCreator);
				}
				catch(Exception ex) {
					oppCreator.addError(ex);
				}
			}
			if(partners.isEmpty()) {
				oppCreators.addAll(oppCreatorList);
			}
			else {
				List<OpportunityPartner__c> opportunityPartners = new List<OpportunityPartner__c>();
				for(SubscriptionPartnerRelationship__c partner : partners) {
					if(partner.OpportunityPartner__r != null) {
						opportunityPartners.add(partner.OpportunityPartner__r);
					}
				}
				List<Database.SaveResult> saveResults = Database.insert(opportunityPartners,false);
				for(OppCreator oppCreator : oppCreatorList) {
					try {
						for(SubscriptionPartnerRelationship__c partner : oppCreator.partnersWithOpportunityPartners) {
							Database.SaveResult saveResult = saveResults.remove(0);
							if(saveResult.isSuccess()) {
								system.debug( LoggingLevel.INFO, 'Created Opportunity Partner: ' + saveResult.getId() );
								partner.OpportunityPartner__c = saveResult.getId();
								partner.ErrorMessage__c = null;
								partner.Status__c = SUCCESS_STATUS;
							}
							else if(partner.Id != null) {
								oppCreator.addWarning(INTERNAL_ERROR_REASON,'Failed to create Opportunity Partner: '+saveResult.getErrors(),partner);
							}
							else {
								oppCreator.addWarning(INVALID_FINANCIAL_PARTNER_REASON,'Failed to add the financial partner specified by the Bill To Account Number: '+saveResult.getErrors(),null,null);
							}
						}
						SubscriptionPartner__c sp = oppCreator.primaryReseller;
						SubscriptionPartnerRelationship__c spr = oppCreator.financialPartner;
						oppCreator.partnersWithOpportunityPartners.clear();
						oppCreators.add(oppCreator);
					}
					catch(Exception ex) {
						oppCreator.addError(ex);
					}
				}
			}
		}
	}

//		We are now using a trigger to do this preparation in bulk.
//
//	Boolean prepared = false;
//
//	@TestVisible
//	void prepare() {
//		if(! prepared) {
//			prepared = true;
//			List<Subscription__c> subscriptions = new List<Subscription__c>();
//			List<SubscriptionLine__c> updateLines = new List<SubscriptionLine__c>();
//			List<SubscriptionError__c> notReadyErrors = new List<SubscriptionError__c>();
//			for(Id subscriptionId : oppCreatorMap.keySet()) {
//				OppCreator oppCreator = oppCreatorMap.get(subscriptionId);
//				if(oppCreator.subscription.Status__c != READY_STATUS) {
//					subscriptions.add(oppCreator.subscription);
//					updateLines.addAll(oppCreator.updateLines);
//					notReadyErrors.addAll(oppCreator.errorList);
//					oppCreator.errorList.clear();
//				}
//			}
//			if(! subscriptions.isEmpty()) {
//				Database.delete(notReadyErrors,false);
//				Account_Matching_Renewals accountMatching = new Account_Matching_Renewals(subscriptions,updateLines);
//				accountMatching.match();
//				accountMatching.filter();
//				// accountMatching.assignRefOppId();
//				accountMatching.assignFrom();
//				accountMatching.errorsAndWarningsReporting();
//				String value = '';
//				StringSetting__c s = StringSetting__c.getInstance(IGNORE_FAILURE_KEY);
//				if(s != null) {
//					value = s.Value__c;
//				}
//				for(SubscriptionError__c e : accountMatching.getErrorAndWarnList(Pattern.compile(('^'+value+'$').toLowerCase()))) {
//					oppCreatorMap.get(e.Subscription__c).errorList.add(e);
//				}
//			}
//		}
//	}

	/**
	 * class that models a renewal line
	 *
	 */
	public class SubscriptionLine {
		// the following are needed at the line level due to coterm operations
		public final String contractNumber;
		public final String opportunityNumber;
		public final String orderNumber;
		public final String poNumber;
		public final String sourceOpportunityId;
		public final String configuredItemDescription = null; // no such member of SubscriptionLine__c
		public Id salesforcePricebookEntryId = null; // no such member of SubscriptionLine__c
		public String salesforceProduct2Id = null; // no such member of SubscriptionLine__c

		public final SubscriptionLine__c subLine;

		public SubscriptionLine(Subscription__c subscription,SubscriptionLine__c subLine) {
			this.subLine = subLine;
			String contractNumber = subscription.ContractNumber__c;
			String opportunityNumber = subscription.OpportunityNumber__c;
			String orderNumber = subscription.OrderNumber__c;
			String poNumber = subscription.PurchaseOrderNumber__c;
			String sourceOpportunityId = subscription.OriginalOpportunity__c;
			if(subLine.OriginalSubscription__r != null) {
				contractNumber = subLine.OriginalSubscription__r.ContractNumber__c;
				opportunityNumber = subLine.OriginalSubscription__r.OpportunityNumber__c;
				orderNumber = subLine.OriginalSubscription__r.OrderNumber__c;
				poNumber = subLine.OriginalSubscription__r.PurchaseOrderNumber__c;
				sourceOpportunityId = subLine.OriginalSubscription__r.OriginalOpportunity__c;
			}
			this.contractNumber = contractNumber;
			this.opportunityNumber = opportunityNumber;
			this.orderNumber = orderNumber;
			this.poNumber = poNumber;
			this.sourceOpportunityId = sourceOpportunityId;
		}
	}

	public class SubscriptionException extends Exception {}

	public class OppCreator {
		private final String accountRecordType;
		private final String accountRecordTypeId;
//coterm	public Long mergeToSubscriptionId;
		private String opportunityRecordType { set; } // no such field for Subscription__c
		private final String opportunityRecordTypeId; // no such fieldor Subscription__c
//legacy	private final String shipToContactUserName = null; // no such field for Subscription__c
//legacy	private String shipToContactErrorMessage = null; // technically we are dropping this on the floor
//legacy	private String shipToContactRecordStatus = null;

		@TestVisible
		final List<SubscriptionLine> lineList = new List<SubscriptionLine>();
		@TestVisible
		final List<SubscriptionPartnerRelationship__c> partnerList = new List<SubscriptionPartnerRelationship__c>();
		@TestVisible
		final Map<Id,Subscription__c> mergedSubscriptionMap = new Map<Id,Subscription__c>();
		@TestVisible
		final List<SubscriptionLine__c> updateLines = new List<SubscriptionLine__c>();
		final List<SubscriptionPartner__c> updatePartners = new List<SubscriptionPartner__c>();
		@TestVisible
		final List<SubscriptionPartnerRelationship__c> updatePartnerRelationships = new List<SubscriptionPartnerRelationship__c>();

		@TestVisible
		final Opportunity_Subscription oppSub;
		@TestVisible
		Subscription__c subscription;

		private Account createdAccount = null;
//depreciated		private Map<String,Contact> createdContactMap = new Map<String,Contact>();
		private Boolean isReadyStatus = false;

		@TestVisible
		OppCreator(Opportunity_Subscription oppSub,Subscription__c subscription,List<SubscriptionLine__c> subLines,List<SubscriptionPartnerRelationship__c> partnerList) {
			this.oppSub = oppSub;
			this.subscription = subscription;
			this.oppSub.oppCreatorMap.put(subscription.Id,this);
			this.subscription.Opportunity__r = null;
			for(SubscriptionLine__c subLine : subLines) {
				subLine.Status__c = READY_STATUS;
				subLine.ErrorMessage__c = null;
				updateLines.add(subLine);
				lineList.add(new SubscriptionLine(subscription,subLine));
				mergedSubscriptionMap.put(subLine.OriginalSubscription__c,subLine.OriginalSubscription__r);
			}
			mergedSubscriptionMap.remove(null);
			mergedSubscriptionMap.remove(subscription.Id);
			if(partnerList != null) {
				this.partnerList.addAll(partnerList);
				for(SubscriptionPartnerRelationship__c spr : partnerList) {
					spr.Status__c = READY_STATUS;
					spr.ErrorMessage__c = null;
					if(spr.Id != null) {
						updatePartnerRelationships.add(spr);
					}
					spr.Status__c = READY_STATUS;
					spr.ErrorMessage__c = null;
					if(spr.SubscriptionPartner__r.Id != null) {
						updatePartners.add(spr.SubscriptionPartner__r);
					}
				}
			}
			if(subscription.SuperRegion__c != null) {
				String r = subscription.SuperRegion__c;
				if(r == 'JAPAN') {
					r = 'APAC';
				}
				this.accountRecordType = r + ' Account';
				this.accountRecordTypeId = RecordTypeLookup.getRecordTypeId(accountRecordType,'Account');
			}
			this.opportunityRecordTypeId = RecordTypeLookup.getRecordTypeId('Renewal','Opportunity');
		}

		@TestVisible
		OppCreator(Opportunity_Subscription oppSub,Subscription__c subscription) {
			this( oppSub,
				subscription,
				subscription.SubscriptionLines__r,
				subscription.Subscription_Partner_Relationships__r);
		}

		/**
		 * retrieves (or creates) an account
		 *
		 * @return Account object
		 */
		@TestVisible
		Account getAccount() {
			// account logic change February 28, 2011:
			// 1st use the account id from matching/manual process on validation file
			// 2nd use the sold to account number (done with trigger)
			// 3rd create a new account
			if (subscription.Account__c == null || subscription.Account__r == null || subscription.Account__c != subscription.Account__r.Id ) {
				subscription.Account__c = null;
				if(subscription.Account__r == null || subscription.Account__r.Id == null) {
					if(subscription.SoldToEBSAccount__r != null && subscription.SoldToEBSAccount__r.Sales_Account__r != null) {
						subscription.Account__r = subscription.SoldToEBSAccount__r.Sales_Account__r;
					}
					if(subscription.EntitleToEBSAccount__r != null && subscription.EntitleToEBSAccount__r.Sales_Account__r != null) {
						subscription.Account__r = subscription.EntitleToEBSAccount__r.Sales_Account__r;
					}
					if(subscription.OriginalOpportunity__r != null && subscription.OriginalOpportunity__r.Account != null) {
						subscription.Account__r = subscription.OriginalOpportunity__r.Account;
					}
					if(subscription.Account__r == null || subscription.Account__r.Id == null) {
						subscription.Account__r = oppSub.accountMap.get(subscription.SoldToAccountNumber__c);
						if(subscription.Account__r == null && AbstractTrigger.isActive(CREATE_ACCOUNT_SETTING,false)) {
							Account account = convertToAccount();
							Database.SaveResult saveResult = Database.insert(account,false);
							if(saveResult.isSuccess()) {
								Id accountId = saveResult.getId();
								system.debug(Logginglevel.INFO, 'Created Account: ' + saveResult.getId());
								createdAccount = subscription.Account__r = [
									select
										Owner.IsActive,
										Owner.Name,
										Owner.Email,
										Owner.UserRole.Name,
										Name,
										OracleAccountNumber__c
									from Account
									where  Id = :accountId ];
							}
							else {
								throw addError(
									MISSING_ACCOUNT_REASON,
									'Account Creation Failed: ' + saveResult.getErrors(),
									true );
								// no need to proceed
							}
						}
					}
				}
				if(subscription.Account__r == null || subscription.Account__r.Id == null) {
					throw addError(
						MISSING_ACCOUNT_REASON,
						system.Label.C360_R31,
						true );
				}
				subscription.Account__c = subscription.Account__r.Id;
				system.debug(Logginglevel.INFO, 'Account Id: ' + subscription.Account__c);
			}
			return subscription.Account__r;
		}

		@TestVisible
		List<SubscriptionError__c> errorList {
			get {
				if(errorList == null) {
					errorList = new List<SubscriptionError__c>();
					if(subscription.Subscription_Errors__r != null) {
						errorList.addAll(subscription.Subscription_Errors__r);
					}
				}
				return errorList;
			}
			set;
		}

		Boolean hasErrors = false;

		SubscriptionException addError(Exception ex) {
			if(! (ex instanceof SubscriptionException)) {
				String message = ex.getMessage() + ':\n' + ex.getStackTraceString();
				
				system.debug(Logginglevel.ERROR, 'Exception: ' + message );
				subscription.Status__c = ERROR_STATUS;
				ex = addError(
					INTERNAL_ERROR_REASON,
					message,
					true );
			}
			return (SubscriptionException)ex;
		}

		@TestVisible
		SubscriptionException addError(String reason,String details,Boolean always) {
			subscription.Status__c = ERROR_STATUS;
			if(subscription.ErrorMessage__c == null || subscription.ErrorMessage__c == '') {
				subscription.ErrorMessage__c = truncate(reason+':\n'+details,4096);
			}
			return addError(truncate(reason+':\n'+details,4096),reason,details,always,null,null);
		}

		@TestVisible
		SubscriptionException addError(Exception ex,SubscriptionLine__c subLine) {
			String message = ex.getMessage() + ':\n' + ex.getStackTraceString();
			system.debug(Logginglevel.ERROR, 'Exception: ' + message );
			return addError(INTERNAL_ERROR_REASON,message,subLine);
		}

		@TestVisible
		SubscriptionException addError(String reason,String details,SubscriptionLine__c subLine) {
			subLine.Status__c = ERROR_STATUS;
			subLine.ErrorMessage__c = truncate(reason+':\n'+details,4096);
			return addError(truncate(reason+':\n'+details,4096),reason,details,true,subLine.Id,null);
		}

		@TestVisible
		void addWarning(String reason,String details,SubscriptionLine__c subLine) {
			addError(null,reason,details,true,subLine.Id,null);
		}

		@TestVisible
		void addWarning(String reason,String details,SubscriptionPartnerRelationship__c subPartRel) {
			Id subPartRelId = null;
			if(subPartRel != null) {
				subPartRel.Status__c = ERROR_STATUS;
				subPartRel.ErrorMessage__c = truncate(reason+':\n'+details,4096);
				subPartRelId = subPartRel.Id;
			}
			addError(null,reason,details,true,null,subPartRelId);
		}

		@TestVisible
		void addWarning(String reason,String details,Id subLineId,Id subPartRelId) {
			addError(null,reason,details,true,subLineId,subPartRelId);
		}

		@TestVisible
		SubscriptionException addError(String errorMessage,String reason,String details,Boolean always,Id subLineId,Id subPartRelId) {
			System.debug('Error: '+reason+' => '+details);
			if(always || ! hasErrors) {
				if(errorMessage != null) {
					hasErrors = hasErrors || ! SubscriptionTriggerBefore.ignoreErrorReasonPattern.matcher(errorMessage).matches();
					subscription.ErrorMessage__c = errorMessage;
				}
				errorList.add(new SubscriptionError__c(
					Reason__c = reason,
					Details__c = truncate(details,4096),
					Subscription__c = subscription.Id,
					SubscriptionLine__c = subLineId,
					SubscriptionPartnerRelationship__c = subPartRelId) );
			}
			return new SubscriptionException(details);
		}

		@TestVisible
		User getAssignTo() {
			User retval = subscription.AssignTo__r;
			if(retval == null) {
				if(subscription.AssignToId__c != null) {
					throw addError(
						INVALID_OWNER_REASON,
						system.Label.C360_R32,
						true );
				}
				retval = subscription.Account__r.Owner;
			}
			if(retval != null && retval.IsActive == false) {
				throw addError(
					INVALID_OWNER_REASON,
					system.Label.C360_R32,
					true );
			}
			return retval;
		}

		@TestVisible
		Opportunity getOpportunity() {
			if(subscription.Opportunity__r == null) {
				subscription.Opportunity__c = null;
				system.debug(LoggingLevel.INFO, 'Starting opportunity process');
				try {
					hasErrors = (subscription.Status__c == ERROR_STATUS);
					if(! hasErrors ){
						subscription.Status__c = READY_STATUS;
						subscription.ErrorMessage__c = null;
	
						if (subscription.OriginalOpportunity__r != null) {
							system.debug(Logginglevel.INFO, 'Source Opportunity Found: ' + subscription.OriginalOpportunity__c);
						}
						else {
							system.debug(Logginglevel.INFO, 'Source Opportunity Not Found: ' + subscription.OpportunityNumber__c);
						}

						// build the renewal opportunity
						setOpportunity( convertToOpportunity(getAccount(), subscription.OriginalOpportunity__r) );
					}
					else if(errorList.isEmpty()) {
						String message = subscription.ErrorMessage__c;
						if(message == null) {
							message = 'UNKNOWN'; // this shouldn't happen
						}
						String reason = INTERNAL_ERROR_REASON;
						if(message == system.Label.C360_R38) {
							reason = NO_LINES_REASON;
						}
						// if we have seen errors with the accounts or lack of
						// subscription lines add an error to the queue.
						addError(
							reason,
							message,
							true);
					}
				}
				catch(Exception ex) {
					addError(ex);
				}
			}
			return subscription.Opportunity__r;
		}

		@TestVisible
		void setOpportunity(Opportunity value) {
			Id oppId = (value != null)?value.Id:null;
			if(oppId == null) {
				oppSub.needOpportunityInsertMap.put(subscription.Id,this);
			}
			else {
				oppSub.needOpportunityInsertMap.remove(subscription.Id);
			}
			subscription.Opportunity__r = value;
			subscription.Opportunity__c = oppId;
		}

		@TestVisible
		Id getOpportunityId() {
			return subscription.Opportunity__c;
		}

		/**
		 * Copy the contract roles from the source opportunity onto the new opportunity
		 */
		@TestVisible
		void copyOpportunityContactRoles(Map<String,OpportunityContactRole> opportunityContactRoleMap,Map<String,CampaignMember> campaignMemberMap) {
			if (subscription.OriginalOpportunity__r != null) {
				if ('EMEA' == subscription.SuperRegion__c || 'JAPAN' == subscription.SuperRegion__c ) {
					List<OpportunityContactRole> sourceOpportunityContactRoles = oppSub.sourceOpportunityContactRolesMap.get(subscription.OriginalOpportunity__c);
					if (sourceOpportunityContactRoles != null && ! sourceOpportunityContactRoles.isEmpty()) {
						for (OpportunityContactRole contactRole : sourceOpportunityContactRoles) {
							oppSub.createOpportunityContactRole(opportunityContactRoleMap,contactRole.ContactId,getOpportunityId(),contactRole.Role,contactRole.IsPrimary);
							oppSub.createCampaignMember(campaignMemberMap,getOpportunity().CampaignId,contactRole.contactId);
						}
					}
				}
			}
		}

		Opportunity updateOpportunity() {
			Opportunity retval = null;
			Opportunity opportunity = getOpportunity();
			String reseller = null;
			String naReseller = null;
			String resellerPO = null;
			Id resellerId = null;
			// in the new model, ordering is pretty much random.  So we use transaction role
			// value
			if(primaryReseller != null) {
				resellerId = primaryReseller.Account__c;
				reseller = primaryReseller.PartyName__c;
				if(reseller == null && primaryReseller.Account__r != null) {
					reseller = primaryReseller.Account__r.Name;
				}
				naReseller = reseller;
				resellerPO = primaryReseller.PurchaseOrderNumber__c;
			}
			System.debug('opportunity='+opportunity);
			System.debug('subscription.Opportunity__c='+subscription.Opportunity__c);
			System.debug('hasErrors='+hasErrors);
			if(opportunity != null && opportunity.Id != null && ! hasErrors) {
				try {
					if(opportunity.BillingAccountNumber__c != null) {
						if(financialPartner != null && financialPartner.Status__c == SUCCESS_STATUS) {
							if(financialPartner.OpportunityPartner__r != null && financialPartner.OpportunityPartner__r.Partner__r != null) {
								opportunity.Primary_Partner__c = financialPartner.OpportunityPartner__r.Partner__r.Name;
								opportunity.FinancialPartner__c = financialPartner.OpportunityPartner__r.Partner__c;
							}
						}
						else if( opportunity.Primary_Partner__c != null && Opportunity_ManagePartners.FINANCIAL_PARTNER_CHANNELS.contains(opportunity.FulfillmentChannel__c)) {
							addError(
								INVALID_FINANCIAL_PARTNER_REASON,
								system.label.C360_R40+' '+opportunity.BillingAccountNumber__c,
								true );
						}
					}
					// this section handles the region specific requirements
					// for creating opportunity contact roles
					if ('EMEA' == subscription.SuperRegion__c) {
							// US50409 RH-00323838 - Closed date now updated to EMEA logic.
						Date serviceEndDateMin = opportunity.CloseDate;
						// Rally user story US13625 - Corrected 2013-02-15
						Date closeDate = serviceEndDateMin.addMonths( -1 );
						// Rally user story US13625 - Corrected 2013-02-15
						if(Math.mod(serviceEndDateMin.month(),3) == 0) {
							closeDate = serviceEndDateMin.toStartOfMonth(); // RH-00251160: US36179
						}
						opportunity.CloseDate = closeDate;
					}
//depreciated-US74944					else if ('LATAM' == subscription.SuperRegion__c) {
//depreciated-US74944						resellerId = null;
//depreciated-US74944						reseller = null;
//depreciated-US74944					}

					// update the year 1 payment amount field
					opportunity.Year1PaymentAmount__c = opportunity.amount;
					// update the opportunity with the source opportunity id
					if (subscription.OriginalOpportunity__r != null) {
						opportunity.Source_Opportunity__c = subscription.OriginalOpportunity__c;
					}

					String forecastCategoryName = FORECAST_CATEGORY_MAP.get(subscription.SuperRegion__c);
					if(forecastCategoryName != null) {
						opportunity.ForecastCategoryName = forecastCategoryName;
					}
					String stageName = STAGE_MAP.get(subscription.SuperRegion__c);
					if(stageName != null) {
						opportunity.StageName = stageName;
					}
					Double probability = PROBABILITY_MAP.get(subscription.SuperRegion__c);
					if(probability != null) {
						opportunity.Probability = probability;
					}

					// update reseller information
					opportunity.NA_Reseller__c = naReseller;
					opportunity.Reseller__c = reseller;
					opportunity.Reseller_PO__c = resellerPO;
					opportunity.ResellerPartner__c = resellerId;

					// assign description
					opportunity.Description = getDescription();

					// call the function to create opportunity partners
					retval = opportunity;
				}
				catch(Exception ex) {
					addError(ex);
				}
			}
			return retval;
		}

		/**
		 * calculate the amount of the opportunity
		 * recalculate the original contract amount based on the
		 * lines left after the co-term lines were removed
		 * Salesforce case no: RH-00033729
		 * @return calculated amount
		 */
		@TestVisible
		Double calculateAmount()
		{
			Decimal amount = 0.00;
			for (SubscriptionLine renewalLine : this.lineList) {
				if(renewalLine.subLine.TotalPrice__c != null) {
					amount += renewalLine.subLine.TotalPrice__c;
				}
			}
			return amount.doubleValue();
		}

		/**
		 * Create or query an account.  This method is only used for debugging.
		 *
		 * @return Account account object created or queried
		 */
		@TestVisible
		Account convertToAccount() {
			Account account = new Account(
				Name = truncate(subscription.SoldToPartyName__c,120),
				ShippingStreet = truncate(subscription.ShipToAddress1__c + (subscription.ShipToAddress2__c != null ? '\n'+subscription.ShipToAddress2__c : ''),255),
				ShippingCity = truncate(subscription.ShipToCity__c,40),
				ShippingState = truncate(subscription.ShipToState__c,20),
				ShippingPostalCode = truncate(subscription.ShipToPostalCode__c,20),
				ShippingCountry = truncate(subscription.ShipToCountry__c,40),
				// we are deliberately setting the billing addres the same as the shipping address
				BillingStreet = truncate(subscription.ShipToAddress1__c + (subscription.ShipToAddress2__c != null ? '\n'+subscription.ShipToAddress2__c : ''),255),
				BillingCity = truncate(subscription.ShipToCity__c,40),
				BillingState = truncate(subscription.ShipToState__c,20),
				BillingPostalCode = truncate(subscription.ShipToPostalCode__c,20),
				BillingCountry = truncate(subscription.ShipToCountry__c,40),
				OracleAccountNumber__c = truncate(subscription.SoldToAccountNumber__c,20),
				RecordTypeId = this.accountRecordTypeId);
			if ( subscription.AssignTo__r != null && subscription.AssignTo__r.IsActive == true ) {
				account.OwnerId = subscription.AssignTo__r.Id;
				account.Owner = subscription.AssignTo__r;
			}
			if(account.Name == null || account.Name == '') {
				throw addError(
					MISSING_ACCOUNT_REASON,
					'No Sold To Party Name is available to create a new account.',
					true);
			}
			return account;
		}

		/**
		 * convertToOpportunity
		 *
		 * @param account
		 * @param opportunity
		 * @return new opportunity sobject
		 */
		@TestVisible
		Opportunity convertToOpportunity(Account account, Opportunity sourceOpportunity) {
			// Create opportunity object and add default values for all regions
			// values can be overridden in region based logic statement
			system.debug( '-- CampaignId: ' + subscription.Campaign__c );
			// set the close date to the max end date of the lines
			// changed April 26, 2011
			Date closeDate = null;
			Date closeDateMin = null;
			for (SubscriptionLine line : this.lineList) {
				if (closeDate == null || (closeDate < line.subLine.ServiceEndDate__c)) {
					closeDate = line.subLine.ServiceEndDate__c;
				}
				if (closeDateMin == null || (closeDateMin > line.subLine.ServiceEndDate__c)) {
					closeDateMin = line.subLine.ServiceEndDate__c;
				}
			}

			String countryOfOrder = subscription.CountryOfOrder__c;
			// populate the country of order from the source opportunity if the source
			// opportunity exists else use the country of order from the contract object
			if (sourceOpportunity != null) {
				countryOfOrder = sourceOpportunity.country_of_Order__c;
			}

			String opportunityType = 'Standard';
			// set the opportunity type = Co-Term if the opportunity is
			// created from more than one expiring contract
			if (! this.mergedSubscriptionMap.isEmpty()) {
				opportunityType = 'CoTerm';
			}

			String billingAccountNumber = null;
			String primaryPartner = null;
			// if bill to account number and sold to account number are different
			// then add the billing account number to the opportunity object along
			// with the Bill To Party Name in the primary partner field (DISTRIBUTOR)
			if (subscription.BillToAccountNumber__c != subscription.SoldToAccountNumber__c) {
				billingAccountNumber = subscription.BillToAccountNumber__c;
				primaryPartner = subscription.BillToPartyName__c;
			}

			// Begin process of region specific logic
			String billingCity = truncate(subscription.BillToCity__c,40);
			String billingState = truncate(subscription.BillToState__c,20);
			Date contractStartDate = subscription.ContractEndDate__c; // the new contract starts where the old ends
			if(subscription.OriginalOpportunity__r != null) {
				contractStartDate = nillValue(contractStartDate,subscription.OriginalOpportunity__r.ContractEndDate__c);
			}
			String opportunityName = null;
			User currentOwner = getAssignTo();
			String paymentType = null;
			String poNumber = subscription.PurchaseOrderNumber__c;
			String shippingCity = truncate(subscription.ShipToCity__c,40);
			String shippingState = truncate(subscription.ShipToState__c,20);
			// set the contract start date on the opportunity
			// to the contract end date
			if ('EMEA' == subscription.SuperRegion__c) {
				poNumber = null;
				paymentType = 'EMEA Purchase Order';
				opportunityName = account.Name + ' - Renewal - Service Contract #' + subscription.ContractNumber__c;


				// if there are merged contracts then make the one with
				// the earliest end date be the start date
				for (Subscription__c mergedContract : this.mergedSubscriptionMap.values()) {
					if (mergedContract.ContractEndDate__c != null && (contractStartDate == null || mergedContract.ContractEndDate__c < contractStartDate)) {
						contractStartDate = mergedContract.ContractEndDate__c;
					}
					opportunityName += ', ' + mergedContract.ContractNumber__c;
				}

				// US50409 RH-00323838 - Initially calculate close date based on minimum service end date
				for (SubscriptionLine line : this.lineList) {
					if (closeDate > line.subLine.ServiceEndDate__c) {
						closeDate = line.subLine.ServiceEndDate__c;
					}
				}

				// US38437 RH-00251160 - Move close dates before the 
				// start of the current quarter to the start of the current 
				// quarter
				Date startOfQuarter = Date.today().toStartOfMonth();
				startOfQuarter = startOfQuarter.addMonths(-Math.mod(startOfQuarter.month(),3));
				if(closeDate < startOfQuarter) {
					closeDate = startOfQuarter;
				}
			}
			else if ('LATAM' == subscription.SuperRegion__c) {
				opportunityName = 'Renewal - ' + account.name + ' - (' + subscription.ContractNumber__c + ')';
			}
			else if ('NA' == subscription.SuperRegion__c) {
				opportunityName = 'Renewal - ' + account.name + ' - (' + subscription.ContractNumber__c + ')';
			}
			else if('JAPAN' == subscription.SuperRegion__c) {
				// change for Japan to add as a region February 28, 2011
				opportunityName = 'Renewal ' + account.Name + ' Service Contract #' + subscription.ContractNumber__c;

				// US49552 : use AssignTo__r even when not creating an account
				if ( subscription.AssignTo__r == null && subscription.AssignTo__r.IsActive != true ) {
					// change for Japan February 28, 2011
					// for region is JAPAN and the sourceOpportunity is not null
					// override the account.owner.id with the sourceOpportunity.owner.id
					if (sourceOpportunity != null && sourceOpportunity.Owner.IsActive) {
						currentOwner = sourceOpportunity.Owner;
					}
				}
			}
			else if ('APAC' == subscription.SuperRegion__c) {
				opportunityName = 'Renewal ' + account.Name + ' Service Contract #' + subscription.ContractNumber__c;
			}
			// set the contract end date on the opportunity
			// to the contract end date plus one year
			Date contractEndDate = null;
			if(contractStartDate != null) {
				contractEndDate = contractStartDate.addYears(1);
				// add one to the end date and use as the next contract start date
				contractStartDate = contractStartDate.addDays(1);
			}

			if(closeDate == null) {
				closeDate = System.today();
			}

			if( currentOwner == null || currentOwner.IsActive != true) {
				throw addError(
					INVALID_OWNER_REASON,
					system.Label.C360_R32,
					true );
			}
			Opportunity opportunity = new Opportunity(
				AccountId = account.Id,
				Amount = 0.00,
				Bill_To_Address__c = subscription.BillToAddress__c,
				Bill_To_Contact__c = subscription.BillToContact__c,
				Bill_To_Account__c = subscription.BillToEBSAccount__c,
				Bill_To_Sales_Account__c = getSalesAccountId(
					subscription.BillToEBSAccount__r,
					subscription.BillToAddress__r,
					subscription.BillToContact__r),
				BillingAccountNumber__c = billingAccountNumber,
				BillingAddress__c = truncate(subscription.BillToAddress1__c + (subscription.BillToAddress2__c != null ? subscription.BillToAddress2__c : ''),255),
				BillingCity__c = billingCity,
				BillingState__c = billingState,
				BillingCountry__c = truncate(subscription.BillToCountry__c,40),
				BillingZipPostalCode__c = truncate(subscription.BillToPostalCode__c,20),
				CampaignId = subscription.Campaign__c,
				CloseDate = closeDate,
				ContractNumber__c = subscription.ContractNumber__c,
				ContractStartDate__c = contractStartDate,
				ContractEndDate__c = contractEndDate,
				Country_of_Order__c = countryOfOrder,
				CrossRegionalCreditCheck__c = 'None',
				CurrencyIsoCode = subscription.CurrencyIsoCode,
				Entitle_To_Address__c = subscription.EntitleToAddress__c,
				Entitle_To_Contact__c = subscription.EntitleToContact__c,
				Entitle_To_Account__c = subscription.EntitleToEBSAccount__c,
				Entitle_To_Sales_Account__c = getSalesAccountId(
					subscription.EntitleToEBSAccount__r,
					subscription.EntitleToAddress__r,
					subscription.EntitleToContact__r),
				LeadSourceDetail__c = subscription.LeadSourceDetail__c,
				Name =  truncate(opportunityName,120),
				OpportunityType__c = opportunityType,
				OwnerId = currentOwner.Id,
				Pay_Now__c = 'Yes',
				PaymentType__c = paymentType,
				PONumber__c = poNumber,
				Primary_Partner__c = primaryPartner,
				RecordTypeId = this.opportunityRecordTypeId,
				Renewal_Opportunity__c = true,
				Renewable__c = 'No',
				ShippingAddress__c = truncate(subscription.ShipToAddress1__c + (subscription.ShipToAddress2__c != null ? subscription.ShipToAddress2__c : ''),255),
				ShippingCity__c = shippingCity,
				ShippingState__c = shippingState,
				ShippingCountry__c = truncate(subscription.ShipToCountry__c,40),
				ShippingZipPostalCode__c = truncate(subscription.ShipToPostalCode__c,20),
				Ship_To_Address__c = subscription.ShipToAddress__c,
				Ship_To_Contact__c = subscription.ShipToContact__c,
				Ship_To_Account__c = subscription.ShipToEBSAccount__c,
				Ship_To_Sales_Account__c = getSalesAccountId(
					subscription.ShipToEBSAccount__r,
					subscription.ShipToAddress__r,
					subscription.ShipToContact__r),
				Sold_To_Address__c = subscription.SoldToAddress__c,
				Sold_To_Contact__c = subscription.SoldToContact__c,
				Sold_To_Account__c = subscription.SoldToEBSAccount__c,
				Sold_To_Sales_Account__c = getSalesAccountId(
					subscription.SoldToEBSAccount__r,
					subscription.SoldToAddress__r,
					subscription.SoldToContact__r),
				SSI_In_Scope__c = subscription.SSI_InScope__c,
				StageName = 'Prepare',
				Touched__c = (sourceOpportunity != null && sourceOpportunity.Touched__c == true));

			// calculate the amount of the opportunity
			// recalculate the original contract amount based on the
			// lines left after the co-term lines were removed
			// Salesforce case no: RH-00033729
			for (SubscriptionLine renewalLine : this.lineList) {
				if(renewalLine.subLine.TotalPrice__c != null) {
					opportunity.amount += renewalLine.subLine.TotalPrice__c;
				}
			}

			// removed by jherson Feburary 10, 2012
			// rally task US14406: RH-00124768: Stop Checking Deal Reg Renewals Flag
			//   if ( sourceOpportunity != null )
			//	   opportunity.deal_registration__c = sourceOpportunity.deal_registration__c;
			// set the fulfillment channel based on business rules
			opportunity.FulfillmentChannel__c = getFulfillmentChannel();
			if(Opportunity_ManagePartners.NO_FINANCIAL_PARTNER_CHANNELS.contains( opportunity.FulfillmentChannel__c )) {
				opportunity.BillingAccountNumber__c = null;
				opportunity.Primary_Partner__c = null;
			}
			String businessUnitName = subscription.BusinessUnitName__c;
			if(subscription.OrderTypeName__c ==  WEB_STANDARD_US_ORDER_TYPE && operatingUnitValues.contains(RH_US_OPERATING_UNIT_NAME.toLowerCase())) {
				businessUnitName = RH_US_OPERATING_UNIT_NAME;
			}
			if( businessUnitName != null || subscription.BusinessUnitId__c != null) {
				if( businessUnitName != null && operatingUnitValues.contains(businessUnitName.toLowerCase()) ) {
					opportunity.Operating_Unit__c = businessUnitName;
					if( orderTypeValues.contains((''+subscription.OrderTypeName__c).toLowerCase()) ) {
						opportunity.Order_Type__c = subscription.OrderTypeName__c;
					}
				}
				else {
					throw addError(
						INVALID_OPERATING_UNIT_REASON,
						system.Label.C360_R39 + businessUnitName,
						true );
				}
			}
			return opportunity;
		}

//depreciated		/**
//depreciated		 * create Campaign Members
//depreciated		 */
//depreciated		@TestVisible
//depreciated		void createCampaignMembers() {
//depreciated			if(subscription.Campaign__c != null) {
//depreciated				List<CampaignMember> campaignMembers = new List<CampaignMember>();
//depreciated				campaignMembers.add( new CampaignMember(
//depreciated					CampaignId = subscription.Campaign__c,
//depreciated					ContactId = subscription.ShippingContact__c) );
//depreciated				for (Database.SaveResult saveResult : Database.insert(campaignMembers,false)) {
//depreciated					// log the results, but otherwise ignore them
//depreciated					if (saveResult.isSuccess()) {
//depreciated						system.debug(LoggingLevel.INFO, 'Created Campaign Member: ' + saveResult.getId());
//depreciated					}
//depreciated					else {
//depreciated						system.debug(LoggingLevel.ERROR, 'Failed to create Campaign Member: ' + saveResult.getErrors());
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}

//legacy		/**
//legacy		 * create Contact
//legacy		 * @param contract
//legacy		 * @param contactIdMap map of contact id by email address to update
//legacy		 */
//legacy		protected void createContact(
//legacy			Id accountId,
//legacy			Id accountOwnerId,
//legacy			Map<String,Id> contactIdMap)
//legacy		{
//legacy			Contact contact = new Contact(
//legacy				AccountId = accountId,
//legacy				OwnerId = accountOwnerId,
//legacy				FirstName = subscription.ShipToContactFirstName__c,
//legacy				LastName = subscription.ShipToContactLastName__c,
//legacy				Email = (subscription.ShipToContactEmail__c != null ? subscription.ShipToContactEmail__c : ''),
//legacy				Phone = (subscription.ShipToContactPhone__c != null ? subscription.ShipToContactPhone__c : ''),
//legacy				LoginName__c = shipToContactUserName);

//legacy			Database.SaveResult saveResult = Database.insert(contact,false);
//legacy			if (saveResult.isSuccess()) {
//legacy				system.debug(LoggingLevel.INFO, 'Created Contact: ' + contact.Id);
//legacy				subscription.ShippingContact__c = contact.Id;
//legacy				shipToContactRecordStatus = SUCCESS_STATUS;
//legacy				contactIdMap.put(contact.Email.toLowerCase(),contact.Id);
//legacy			}
//legacy			else {
//legacy				system.debug(LoggingLevel.ERROR, 'Failed to create Contact: ' + saveResult.getErrors()[0].getMessage());
//legacy				shipToContactErrorMessage = ''+saveResult.getErrors();
//legacy				shipToContactRecordStatus = ERROR_STATUS;
//legacy			}
//legacy		}

		Set<String> getProductCodes() {
			Set<String> productCodes = new Set<String>();
			for ( SubscriptionLine renewalLine : this.lineList ) {
				productCodes.add( getProductCode(renewalLine) );
				productCodes.add( renewalLine.subLine.OrderedItem__c );
			}
			return productCodes;
		}

		@TestVisible
		Map<String, PricebookEntry> pricebookEntryMap {
			get {
				if(pricebookEntryMap == null) {
					pricebookEntryMap = oppSub.pricebookEntryMapByCurrencyIsoCode.get((''+subscription.CurrencyIsoCode).toUpperCase());
				}
				System.assertNotEquals(null,pricebookEntryMap,'failed to retrieve pricebookEntryMap for: '+subscription.CurrencyIsoCode);
				return pricebookEntryMap;
			}
			set;
		}

		/**
		 * create expiring products
		 */
		@TestVisible
		List<Expiring_Product__c> expiringProducts {
			get {
				if(expiringProducts == null) {
					expiringProducts = new List<Expiring_Product__c>();
					if(getOpportunityId() != null) {
						for (SubscriptionLine renewalLine : this.lineList) {
							try {
								if (renewalLine.salesforceProduct2Id == null || renewalLine.salesforceProduct2Id == '') {
									String productCode = renewalLine.subLine.OrderedItem__c;
									PricebookEntry pricebookEntry = pricebookEntryMap.get( productCode );
									if ( pricebookEntry != null ) {
										renewalLine.salesforceProduct2Id = pricebookEntry.product2.id;
									}
									else {
										renewalLine.salesforceProduct2Id = null;
									}
								}

								String externalId = renewalLine.subLine.ContractLineId__c;
								if(renewalLine.subLine.ContractId__c != null && renewalLine.subLine.InstanceNumber__c != null) {
									externalId = Integer.valueOf(renewalLine.subLine.ContractId__c)+'-'+renewalLine.subLine.InstanceNumber__c;
								}
								Expiring_Product__c expiringProduct = new Expiring_Product__c(
									Expiring_Product_End_Date__c = renewalLine.subLine.ServiceEndDate__c,
									Expiring_Contract_Number__c = renewalLine.contractNumber,
									Expiring_Contract_PO_Number__c = renewalLine.poNumber,
									Expiring_Product_Start_Date__c = renewalLine.subLine.ServiceStartDate__c,
									Expiring_Oracle_Order_Number__c = renewalLine.orderNumber,
									ExternalId__c = externalId,
									CurrencyIsoCode = subscription.CurrencyIsoCode,
									Co_Term__c = (renewalLine.subLine.AlreadyRenewed__c == true),
									Already_Renewed__c = (renewalLine.subLine.AlreadyRenewed__c == true),
									Opportunity__c = subscription.Opportunity__c,
									Product_Code__c = renewalLine.subLine.OrderedItem__c,
									Quantity__c = renewalLine.subLine.OrderedQuantity__c,
									Sales_Price__c = renewalLine.subLine.UnitSellingPrice__c,
									Name = truncate(renewalLine.subLine.FulfilledItemDescription__c,80),
									Mapped_Description__c = renewalLine.subLine.FulfilledItemDescription__c,
									Product__c = renewalLine.salesforceProduct2Id,
									Renewal_Opportunity__c = renewalLine.sourceOpportunityId);

//coterm						// check to see if the expring product has been co-termed
//coterm						// if so then set the indicator flags
//coterm						if ('Y' == renewalLine.cotermFlag) {
//coterm							expiringProduct.Already_Renewed__c = expiringProduct.co_Term__c = true;
//coterm						}

								// add the SKU mapping for the Co-Term wizard
								if (renewalLine.subLine.ConfiguredItem__c != null && renewalLine.subLine.ConfiguredItem__c != '') {
									expiringProduct.Mapped_SKU__c = truncate(renewalLine.subLine.ConfiguredItem__c, 4);
									expiringProduct.Mapped_Description__c = renewalLine.configuredItemDescription;
									expiringProduct.Configured_Renewal_SKU__c = renewalLine.subLine.RenewalItem__c;
								}
								else if (renewalLine.subLine.RenewalItem__c != null) {
									expiringProduct.Mapped_SKU__c = renewalLine.subLine.RenewalItem__c;
								}
								else if (renewalLine.subLine.SubstituteItem__c != null) {
									expiringProduct.Mapped_SKU__c = renewalLine.subLine.SubstituteItem__c;
								}
								else {
									expiringProduct.Mapped_SKU__c = renewalLine.subLine.OrderedItem__c;
								}
								expiringProducts.add(expiringProduct);
							}
							catch(Exception ex) {
								addError( ex, renewalLine.subLine );
							}
						}
					}
				}
				return expiringProducts;
			}
			set;
		}

		String getProductCode(SubscriptionLine renewalLine) {
			String productCode = null;
			if (renewalLine.subLine.ConfiguredItem__c != null && renewalLine.subLine.ConfiguredItem__c != '') {
				// we always truncate configured items
				productCode = truncate( renewalLine.subLine.ConfiguredItem__c, 4);
			}
			else if (renewalLine.subLine.RenewalItem__c != null && renewalLine.subLine.RenewalItem__c != '') {
				productCode = renewalLine.subLine.RenewalItem__c;
			}
			else if (renewalLine.subLine.SubstituteItem__c != null && renewalLine.subLine.SubstituteItem__c != '') {
				productCode = renewalLine.subLine.SubstituteItem__c;
			}
			else {
				productCode = renewalLine.subLine.OrderedItem__c;
			}
			return productCode;
		}

		List<SubscriptionLine__c> getSubscriptionLines() {
			List<SubscriptionLine__c> retval = new List<SubscriptionLine__c>();
			for(SubscriptionLine renewalLine : this.lineList) {
				retval.add(renewalLine.subLine);
			}
			return retval;
		}

		/**
		 * create opportunity line items
		 * @return list of update ContractLines
		 */
		@TestVisible
		List<OpportunityLineItem> opportunityLineItems {
			get {
				if(opportunityLineItems == null) {
					opportunityLineItems = new List<OpportunityLineItem>();

					if(getOpportunityId() != null) {
						Date contractStartDate = subscription.ContractStartDate__c;
						if(subscription.OriginalOpportunity__r != null) {
							contractStartDate = nillValue(contractStartDate,subscription.OriginalOpportunity__r.ContractStartDate__c);
						}
						// get the product codes from the renewal lines
						List<SubscriptionLine> lineList2 = new List<SubscriptionLine>();
						List<SubscriptionLine> lineList3 = new List<SubscriptionLine>();
						for(SubscriptionLine renewalLine : lineList) {
							OpportunityLineItem opportunityLineItem = null;
							try {
								if( renewalLine.subLine.AlreadyRenewed__c != true ) {
									String productCode = getProductCode( renewalLine );
									// try the untruncated value first
									PricebookEntry pricebookEntry = pricebookEntryMap.get( productCode );
									if ( pricebookEntry == null ) {
										addError(
											INVALID_SKU_REASON,
											system.label.C360_R36 + ': ' + productCode,
											renewalLine.subLine );
									}
									else if( pricebookEntry.IsActive != true || pricebookEntry.Product2.IsActive != true) {
										addError(
											INACTIVE_SKU_REASON,
											system.label.C360_R35 + ': ' + productCode,
											renewalLine.subLine );
									}
									else {
										system.debug( '-- pricebookEntry: ' + pricebookEntry );

										// set the pricebook entry id and the product description
										String pricebookEntryId = pricebookEntry.Id;
										String productDescription = pricebookEntry.product2.description;
	
										// populate configured sku description if present
										if ( renewalLine.configuredItemDescription != null && renewalLine.configuredItemDescription != '' ) {
											productDescription = renewalLine.configuredItemDescription;
										}

										Date startDate = renewalLine.subLine.ServiceEndDate__c.addDays(1);

										// set the default line start date to the expiring
										// contract end date plus one day
										system.debug ( ' -- renewal line service end date: ' + renewalLine.subLine.ServiceEndDate__c );

										// set the default line end date to the contract end date
										// plus one year or 3 years rally story US10441
										Date endDate = renewalLine.subLine.ServiceEndDate__c.addYears(1);
										// 2014-07-24 - Corrected since days between is one day less that total term 
										if ( contractStartDate != null && contractStartDate.daysBetween( subscription.ContractEndDate__c ) >= 1094 ) {
											endDate = endDate.addYears(2);
										}

										// build the opportunity line item object
										opportunityLineItem = new OpportunityLineItem(
											ActualEndDate__c = endDate,
											ActualStartDate__c = startDate,
											PricebookEntryId = pricebookEntryId,
											OpportunityId = subscription.Opportunity__c,
											NewOrRenewal__c = 'Renewal',
											Quantity = renewalLine.subLine.OrderedQuantity__c,
											ScheduleLocked__c = true,
											Contract_Numbers__c = renewalLine.contractNumber,
											Configured_SKU__c = ( renewalLine.subLine.ConfiguredItem__c != null ? renewalLine.subLine.RenewalItem__c : null ),
											UnitPrice = selectPrice(renewalLine.subLine.NetUnitSellingPrice__c,renewalLine.subLine.UnitSellingPrice__c),
											Description = productDescription,
											Entitle_To_Address__c = renewalLine.subLine.EntitleToAddress__c,
											Entitle_To_Contact__c = renewalLine.subLine.EntitleToContact__c,
											Entitle_To_Account__c = renewalLine.subLine.EntitleToEBSAccount__c,
											Entitle_To_Sales_Account__c = getSalesAccountId(
												renewalLine.subLine.EntitleToEBSAccount__r,
												renewalLine.subLine.EntitleToAddress__r,
												renewalLine.subLine.EntitleToContact__r));

										// set the default line start date to the expiring
										// contract end date plus one day
										system.debug ( ' -- renewal line service end date: ' + renewalLine.subLine.ServiceEndDate__c );
									}
								}
							}
							catch(Exception ex) {
								addError( ex, renewalLine.subLine );
							}
							finally {
								if(opportunityLineItem != null) {
									opportunityLineItems.add(opportunityLineItem);
									lineList2.add(renewalLine);
								}
								else {
									lineList3.add(renewalLine);
								}
							}
						}
						lineList.clear();
						lineList.addAll(lineList2);
						lineList.addAll(lineList3);
					}
				}
				return opportunityLineItems;
			}
			set;
		}

		/**
		 * create OpportunityPartners return the respect SubscriptionPartnerRelationship list.
		 *
		 * Currently only resellers are loaded via this call.
		 */
		@TestVisible
		List<SubscriptionPartnerRelationship__c> partnersWithOpportunityPartners {
			get {
				if(partnersWithOpportunityPartners == null) {
					partnersWithOpportunityPartners = new List<SubscriptionPartnerRelationship__c>();
					if(getOpportunityId() != null) {
						Opportunity opp = getOpportunity();
						List<String> transactionRoles = new List<String>();
						List<SubscriptionPartnerRelationship__c> partnerList2 = new List<SubscriptionPartnerRelationship__c>();
						for ( SubscriptionPartnerRelationship__c partner : this.partnerList ) {
							partner.OpportunityPartner__r = null;
							partner.OpportunityPartner__c = null;
							String tr = partner.SubscriptionPartner__r.TransactionRole__c;
							if(tr == null) {
								partnerList2.add(partner);
								transactionRoles.add(null);
							}
							else if(tr != null) {
								tr = tr.toLowerCase().trim().replaceAll(' ','');
								if(tr.startsWith('reseller')) {
									partnerList2.add(partner);
									transactionRoles.add('Reseller '+tr.substring(8));
								}
							}
						}

						List<String> resellerTypes = new List<String>{
							'Reseller 2',
							'Reseller 3',
							'Reseller 4',
							'Reseller 5',
							'Reseller 6',
							'Reseller 7',
							'Reseller 8',
							'Reseller 9',
							'Reseller 10' };
						Map<Id,SubscriptionPartnerRelationship__c> partnerMap = new Map<Id,SubscriptionPartnerRelationship__c>();
						for (SubscriptionPartnerRelationship__c partner : partnerList2 ) {
							String resellerType = transactionRoles.remove(0);
							// filter out partners that we couldn't find when mapping resellers to subscriptions
							if ( partner.SubscriptionPartner__r.PartnerStatus__c == null
									|| partner.SubscriptionPartner__r.PartnerStatus__r.ActivationStatus__c != 'Active') {
								addWarning(INVALID_PARTNER_REASON,'Unable to locate a matching active partner status',partner);
							}
							else {
								String rt = null;
								if(resellerType != null) {
									for(Integer i=resellerTypes.size(); i-- > 0;) 
									{
										if(resellerType == resellerTypes[i]) {
											rt = resellerType;
											resellerTypes.remove(i);
											break;
										}
									}
								}
								partner.OpportunityPartner__r = new OpportunityPartner__c(
									Opportunity__c = getOpportunityId(),
									Partner__r = partner.SubscriptionPartner__r.PartnerStatus__r.Partner__r,
									Partner__c = partner.SubscriptionPartner__r.PartnerStatus__r.Partner__c,
									PartnerType__c = partner.SubscriptionPartner__r.PartnerStatus__r.PartnerType__c,
									PartnerTier__c = partner.SubscriptionPartner__r.PartnerStatus__r.PartnerTier__c,
									RelationshipType__c = rt );
								partnerMap.put(partner.Id,partner);
							}
						}
						System.debug('BillingAccountNumber__c='+opp.BillingAccountNumber__c);
						if( opp.BillingAccountNumber__c != null) {
							System.debug('Primary_Partner__c='+opp.Primary_Partner__c);
							PartnerStatus__c ps = oppSub.financialPartnerMap.get(opp.BillingAccountNumber__c);
							if(ps != null) {
								SubscriptionPartnerRelationship__c partner = new SubscriptionPartnerRelationship__c(
									OpportunityPartner__r = new OpportunityPartner__c(
										Opportunity__c = getOpportunityId(),
										Partner__r = ps.Partner__r,
										Partner__c = ps.Partner__c,
										PartnerType__c = ps.PartnerType__c,
										PartnerTier__c = ps.PartnerTier__c,
										RelationshipType__c = Opportunity_ManagePartners.FINANCIAL) );
								partnerMap.put(null,partner);
								System.debug('Attempting to add Financial Partner: '+partner);
							}
						}
						for(SubscriptionPartnerRelationship__c partner : partnerMap.values()) {
							OpportunityPartner__c op = partner.OpportunityPartner__r;
							if(op.RelationshipType__c == null) {
								if(! resellerTypes.isEmpty()) {
									op.RelationshipType__c = resellerTypes.remove(0);
								}
								else {
									partner.OpportunityPartner__r = null;
									if(partner.Id != null) {
										addWarning(INTERNAL_ERROR_REASON,'Too many partners.',partner);
									}
								}
							}
							if(partner.OpportunityPartner__r != null) {
								partnersWithOpportunityPartners.add(partner);
							}
						}
					}
				}
				return partnersWithOpportunityPartners;
			}
			set;
		}

		/**
		 * Find the reseller 2 value.
		 */
		@TestVisible
		SubscriptionPartner__c primaryReseller {
			get {
				if(primaryReseller == null) {
					Integer resellerNumber = 12;
					for(SubscriptionPartnerRelationship__c spr : partnersWithOpportunityPartners) {
						System.debug('OpportunityPartner__r='+spr.OpportunityPartner__r);
						if(spr.OpportunityPartner__r != null && spr.OpportunityPartner__r.RelationshipType__c != null) {
							try {
								String transactionRole = spr.OpportunityPartner__r.RelationshipType__c.toLowerCase().trim().replaceAll(' ','');
								System.debug('transactionRole='+transactionRole);
								if(transactionRole.startsWith('reseller')) {
									Integer no = Integer.valueOf(transactionRole.substring(8));
									if(no < resellerNumber) {
										primaryReseller = spr.SubscriptionPartner__r;
										resellerNumber = no;
									}
								}
							}
							catch(Exception ex) {}
						}
					}
					System.debug('primaryReseller='+primaryReseller);
				}
				return primaryReseller;
			}
			set;
		}

		/**
		 * Find the financial partner.
		 */
		@TestVisible
		SubscriptionPartnerRelationship__c financialPartner {
			get {
				if(financialPartner == null) {
					for(SubscriptionPartnerRelationship__c spr : partnersWithOpportunityPartners) {
						if(spr.OpportunityPartner__r != null && spr.OpportunityPartner__r.RelationshipType__c ==  Opportunity_ManagePartners.FINANCIAL) {
							financialPartner = spr;
						}
					}
				}
				return financialPartner;
			}
			set;
		}

		/**
		 * create a ship to contact role
		 */
		@TestVisible
		void addShippingContact(Map<String,OpportunityContactRole> opportunityContactRoleMap,Map<String,CampaignMember> campaignMemberMap) {
			if('JAPAN' != subscription.SuperRegion__c) {
				oppSub.createOpportunityContactRole(opportunityContactRoleMap,subscription.ShippingContact__c,getOpportunityId(),SHIPPING_CONTACT_ROLE,true);
				oppSub.createCampaignMember(campaignMemberMap,subscription.Campaign__c,subscription.ShippingContact__c);
			}
		}

		/**
		 * create a sold to contact role
		 */
		@TestVisible
		void addSellingContact(Map<String,OpportunityContactRole> opportunityContactRoleMap,Map<String,CampaignMember> campaignMemberMap) {
			if('JAPAN' != subscription.SuperRegion__c && 'EMEA' != subscription.SuperRegion__c) {
				oppSub.createOpportunityContactRole(opportunityContactRoleMap,subscription.SellingContact__c,getOpportunityId(),SELLING_CONTACT_ROLE,false);
				oppSub.createCampaignMember(campaignMemberMap,subscription.Campaign__c,subscription.SellingContact__c);
			}
		}

		/**
		 * get renewal description
		 * @return the description string
		 */
		@TestVisible
		String getDescription() {
			String description = '';
			//
			// add dealer contact details to the description
			//
			if (primaryReseller != null) {
				description += 'Partner Contact: ' + (primaryReseller.ContactName__c != null ? primaryReseller.ContactName__c : '') + '\n';
				description += 'Partner Email: ' + (primaryReseller.ContactEmail__c != null ? primaryReseller.ContactEmail__c : '') + '\n';
				description += 'Partner Phone: ' + (primaryReseller.ContactPhone__c != null ? primaryReseller.ContactPhone__c : '') + '\n\n';
			}

			//
			// add oracle order number and contract number to the description
			//
			if (subscription.OrderId__c != null) {
				description += 'Order Number: ' + subscription.OrderNumber__c + '\n';
				description += 'Contract Number: ' + subscription.ContractNumber__c + '\n';
			}

			//
			// for EMEA add extra information to the description
			// including the merged contracts
			//
			if ('EMEA' == subscription.SuperRegion__c) {
				if (subscription.PurchaseOrderNumber__c != null) {
					description += 'PO Number: ' + subscription.PurchaseOrderNumber__c + '\n';
				}

				if (subscription.OpportunityNumber__c != null) {
					description += 'Opportunity Number: ' + subscription.OpportunityNumber__c  + '\n';
				}

				if (! this.mergedSubscriptionMap.isEmpty()) {
					for (Subscription__c mergedContract : this.mergedSubscriptionMap.values()) {
						description += '\n';
						if (mergedContract.OrderId__c != null) {
							description += 'Order Number: ' + mergedContract.OrderNumber__c + '\n';
							description += 'Contract Number: ' + mergedContract.ContractNumber__c + '\n';
						}

						if (mergedContract.PurchaseOrderNumber__c != null) {
							description += 'PO Number: ' + mergedContract.PurchaseOrderNumber__c + '\n';
						}
						if (mergedContract.OpportunityNumber__c != null) {
							description += 'Opportunity Number: ' + mergedContract.OpportunityNumber__c  + '\n';
						}
					}
				}
			}
			return description;
		}

		/**
		 * get the value which should be used as the FulfillmentChannel
		 * @return the opportunity fulfillment channel
		 */
		@TestVisible
		String getFulfillmentChannel()
		{
			String fulfillmentChannel = subscription.SalesChannelCode__c;
			if(fulfillmentChannel != null) {
				fulfillmentChannel = FC_MAP.get(fulfillmentChannel.toLowerCase().replaceAll('[^a-z0-9]',''));
			}
			if(fulfillmentChannel == OEM_ROYALTIES_FC) {
				fulfillmentChannel = OEM_FC;
				if(subscription.BillToAccountNumber__c == subscription.ShipToAccountNumber__c) {
					fulfillmentChannel = DIRECT_END_CUSTOMER_FC;
				}
			}
			else if(fulfillmentChannel == null) {
				fulfillmentChannel = DEFAULT_FC;
			}
			return fulfillmentChannel;
		}

		/**
		 * Prepares the update list with errors as needed.
		 * 
		 * @return hasErrors
		 */
		public Boolean prepareErrors()
		{
			if(hasErrors || subscription.Opportunity__c == null) {
				subscription.Status__c = ERROR_STATUS;
				for(Integer i = updateLines.size();i-- > 0;) {
					SubscriptionLine__c lineItem = updateLines.remove(i);
					String status = READY_STATUS;
					if(lineItem.Status__c == ERROR_STATUS) {
						status = ERROR_STATUS;
					}
					updateLines.add( new SubscriptionLine__c(
						Id=lineItem.Id,
						Status__c = status,
						ErrorMessage__c = lineItem.ErrorMessage__c) );
				}
				for(Integer i = updatePartnerRelationships.size();i-- > 0;) {
					SubscriptionPartnerRelationship__c partnerRelationship = updatePartnerRelationships.remove(i);
					String status = READY_STATUS;
					if(partnerRelationship.Status__c == ERROR_STATUS) {
						status = ERROR_STATUS;
					}
					updatePartnerRelationships.add( new SubscriptionPartnerRelationship__c(
						Id=partnerRelationship.Id,
						Status__c = status,
						ErrorMessage__c = partnerRelationship.ErrorMessage__c) );
				}
			}
			if (createdAccount != null) {
				if(createdAccount.OracleAccountNumber__c != null) {
					oppSub.accountMap.put(createdAccount.OracleAccountNumber__c,createdAccount);
				}
				subscription.Account__c = createdAccount.Id;
			}
			return (hasErrors || subscription.Opportunity__c == null);
		}
	}
}