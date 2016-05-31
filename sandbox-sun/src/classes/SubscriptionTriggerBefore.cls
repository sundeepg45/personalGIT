/**
 * This class replaces all before insert and before update Subscription__c triggers.  The
 * processTrigger method is invoked by the Subscription_Before trigger and in turn invokes
 * all the processTrigger methods of the subclasses.  This gives us a way to control 
 * the order in which the code logic is invoked, as well as allowing other class features 
 * such as shared data, constant values, and complete test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class or it's subclasses
 * as that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2016-03-30
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2016-03-30 - Can no longer assign __r and __c values.
 * @since 2016-02-09 - Update to use a hash when inserting and searching for contacts
 * @since 2015-04-21 - Combined syncAccountFields() and assignSalesAccounts() and cleanup the sync methods so upserts work as expected
 * @since 2015-04-20 - Corrected the assignSalesAccount method to query accounts before assignment.
 * @since 2015-04-06 - Assign values to the readyIds set
 * @since 2015-03-31 - Updated ignore error matching pattern to be case insensative
 * @since 2015-03-16 - Support already renewed, dnr and nfr flags.
 * @since 2015-02-24 - Added subscription__r.Account__c to the line item query
 * @since 2015-02-19 - Updated composite key logic
 * @since 2015-02-05 - Add READY_FOR_SSI_STATUS to the ready list for NA and LATAM
 * @since 2015-02-04 - Added size limit to create contacts method
 * @since 2015-01-27 - Commenting out assign batch, since we aren't using this feature and the tests are failing
 * @since 2015-01-09 - Added contact creation to the matching method
 * @since 2014-12-22 - Added updateFromSubscriptionLines and createContacts methods
 * @since 2014-12-22 - Updated mapContacts to use entitle to for sold to when account numbers match
 * @since 2014-12-12 - Added syncOriginalOpportunityFields method
 * @since 2014-12-12 - Revised composite key logic to treat null as nill.
 * @since 2014-12-09 - Added new matching logic and removed old matching logic
 * @since 2014-11-25 - Do not override super region based on country of order
 * @since 2014-11-24 - Added trigger to validate campaign id's
 * @since 2014-11-20 - Corrections to comments
 * @since 2013-09-11 - Created
 * @since 2013-01-07 - Added assign account method to assign an account once channel load is completed.
 * @author Scott Coleman <scoleman@redhat.com>
 * @since 2014-01-13 - Added method that touches related Subscription Partner records to invoke mapping triggers
 * @since 2014-01-10 - Added mapping of source opportunity
 * @since 2014-01-07 - Added mapping of contacts
 */
public without sharing class SubscriptionTriggerBefore  extends AbstractTrigger {
	/** StringSetting__c key for ignored some errors. */
	public static final String IGNORE_FAILURE_KEY = 'C360.Renewal.Ignore';
//depreciated	/** BooleanSetting__c key to enable the assignBatch trigger method. */
//depreciated	public static final String ASSIGN_BATCH_SETTING = 'Sub_Before.assignBatch';
	/** BooleanSetting__c key to enable the assignCompositeKey trigger method. */
	public static final String ASSIGN_COMPOSITE_KEY_SETTING = 'Sub_Before.assignCompositeKey';
	/** BooleanSetting__c key to enable the assignRegion trigger method. */
	public static final String ASSIGN_REGION_SETTING = 'Sub_Before.assignRegion';
	/** BooleanSetting__c key to enable the aggregateSubscriptionLines trigger method. */
	public static final String AGGREGATE_SUBSCRIPTION_LINES_SETTING = 'Sub_Before.agrSubLines';
	/** BooleanSetting__c key to enable the updateStatuses trigger method. */
	public static final String UPDATE_STATUS_SETTING = 'Sub_Before.updateStatus';
	/** BooleanSetting__c key to enable the updateFromSubscriptionLines trigger method. */
	public static final String UPDATE_SUBSCRIPTION_LINES_SETTING = 'Sub_Before.updateSubLines';
	/** BooleanSetting__c key to enable the clearErrors trigger method. */
	public static final String CLEAR_ERRORS_SETTING = 'Sub_Before.clearErrors';
	/** BooleanSetting__c key to enable the updateStatuses trigger method. */
	public static final String SSI_OPT_IN_SETTING = 'Sub_Before.ssiOptIn';
	/** BooleanSetting__c key to enable the syncAssignToFields trigger method. */
	public static final String SYNC_ASSIGN_TO_SETTING = 'Sub_Before.syncAssignTo';
	/** BooleanSetting__c key to enable the syncAccountFields trigger method. */
	public static final String SYNC_ACCOUNT_SETTING = 'Sub_Before.syncAccount';
	/** BooleanSetting__c key to enable the syncCampaignFields trigger method. */
	public static final String SYNC_CAMPAIGN_SETTING = 'Sub_Before.syncCampaign';
	/** BooleanSetting__c key to enable the syncOriginalOpportunityFields trigger method. */
	public static final String SYNC_ORIGINAL_OPPORTUNITY_SETTING = 'Sub_Before.syncOrigOpp';
	/** BooleanSetting__c key to enable the mapContacts trigger method. */
	public static final String MAP_CONTACTS_SETTING = 'Sub_Before.mapContacts';
	/** BooleanSetting__c key to enable the mapping of reseller partners */
	public static final String MAP_RESELLER_PARTNER_SETTING = 'Sub_Before.mapResellerPartner';  
	/** BooleanSetting__c key to enable the matchAccounts trigger method. */
	public static final String MATCH_ACCOUNTS_SETTING = 'SubLine_Before.matchAccounts';

	public static final Double CONTRACT_AMOUNT_LIMIT = 15000.00;
	public static final String SUCCESS_STATUS = 'SUCCESS';
	public static final String READY_STATUS = 'READY';
	public static final String READY_FOR_SSI_STATUS = 'READY for SSI';
	public static final String HOLD_FOR_DECISION_STATUS = 'HOLD for Decision';
	public static final String ERROR_STATUS = 'ERROR';
	public static final String DO_NOT_LOAD_STATUS = 'DO NOT LOAD';
	public static final Integer CONTACT_INSERT_QUERY_RESERVE = 10;
	public static final Integer CONTACT_INSERT_DML_RESERVE = 10;

	public static List<SubscriptionLine__c> updatedLines = null;
	public static List<SubscriptionError__c> errorList = null;

	private final Map<Id,Subscription__c> oldMap = new Map<Id,Subscription__c>();
	private final List<Subscription__c> newList = new List<Subscription__c>();

	public static Pattern ignoreErrorReasonPattern {
		get {
			if(ignoreErrorReasonPattern == null) {
				String value = '';
				StringSetting__c s = StringSetting__c.getInstance(IGNORE_FAILURE_KEY);
				if(s != null) {
					value = s.Value__c;
				}
				ignoreErrorReasonPattern = Pattern.compile('^(?i)'+value+'$');
			}
			return ignoreErrorReasonPattern;
		}
		set;
	}


	/**
	 * Standard constructor.
	 * 
	 * @param xoldMap
	 * @param xnewList
	 */
	public SubscriptionTriggerBefore(Map<Id,Subscription__c> xoldMap,List<Subscription__c> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
		updatedLines = null;
		errorList = null;
	}

	public Integer contactInsertSizeLimit {
		get {
			Integer remaining = Limits.getLimitDMLStatements() - Limits.getDMLStatements() - CONTACT_INSERT_DML_RESERVE;
			Integer remainingQueries = Limits.getLimitQueries() - Limits.getQueries() - CONTACT_INSERT_QUERY_RESERVE;
			if(remainingQueries < remaining) {
				remaining = remainingQueries;
			}
			return remaining;
		}
		set;
	}

	public List<Subscription__c> readyList {
		get {
			if(readyList == null) {
				readyList = new List<Subscription__c>();
				for(Subscription__c sub : newList) {
					if(sub.Status__c == READY_STATUS
						|| (sub.Status__c == READY_FOR_SSI_STATUS 
							&& (sub.SuperRegion__c == 'NA' || sub.SuperRegion__c == 'LATAM') ) )
					{
						readyList.add(sub);
					}
				}
			}
			return readyList;
		}
		set;
	}

	/**
	 * Call to clear the error message.
	 */
	public void clearErrorsWhenReady() {
		for(Subscription__c sub : readyList) {
			sub.ErrorMessage__c = null;
		}
		SubscriptionTriggerAfter.readyIds.clear();
		if(isUpdate) {
			SubscriptionTriggerAfter.readyIds.addAll(new Map<Id,Subscription__c>(readyList).keySet());
		}
	}

	/**
	 * Assign all the account values, and insert respective subscription error objects.
	 * If there is at least one error for a subscription (not warning), then change 
	 * the subscription status to ERROR_STATUS.
	 */
	public void matchAccounts() {
		updatedLines = null;
		errorList = null;
		if(! readyList.isEmpty()) {
			List<SubscriptionLine__c> subLines = new List<SubscriptionLine__c>();
			Boolean afterTriggerIsActive = AbstractTrigger.isActive(SubscriptionTriggerAfter.MATCH_ACCOUNTS_SETTING,true);
			if(afterTriggerIsActive) {
				// set to null, so we query the list of subscription lines
				subLines = null;
			}
			Account_Matching_Renewals accountMatching = new Account_Matching_Renewals(readyList,subLines);

			accountMatching.match();
			accountMatching.filter();
			accountMatching.assignFrom();
			createContacts( subLines );
			accountMatching.assignFrom();

			if(afterTriggerIsActive) {
				accountMatching.errorsAndWarningsReporting();
				errorList = accountMatching.getErrorAndWarnList(ignoreErrorReasonPattern);
				updatedLines = accountMatching.getUpdatedSubscriptionLines();
			}
		}
	}

	/**
	 * Called to synchronize the AssignToId__c and AssignTo__c fields.
	 */
	public void syncAssignToFields() {
		Set<Id> assignToIds = new Set<Id>();
		for(Subscription__c sub : newList) {
			Id assignToId = idValue(sub.AssignToId__c);
			Subscription__c oldSub = oldMap.get(sub.Id);
			if(oldSub == null) {
				oldSub = new Subscription__c();
			}
			if(oldSub.AssignTo__c != sub.AssignTo__c) {
				sub.AssignToId__c = sub.AssignTo__c;
			}
			else if(assignToId != sub.AssignTo__c) {
				assignToIds.add(assignToId);
			}
		}
		if(! assignToIds.isEmpty()) {
			assignToIds.remove(null);
			if(! assignToIds.isEmpty()) {
				assignToIds = new Map<Id,User>([
					select Id
					from User
					where Id in :assignToIds and IsActive = true ]).keySet();
			}
			for(Subscription__c sub : newList) {
				Id assignToId = idValue(sub.AssignToId__c);
				if(assignToId != sub.AssignTo__c) {
					if(! assignToIds.contains(assignToId)) {
						assignToId = null;
					}
					sub.AssignToId__c = sub.AssignTo__c = assignToId;
				}
			}
		}
	}

	/**
	 * Called to synchronize the *AccountId__c and *Account__c fields.
	 */
	public void syncAccountFields() {
		Set<Id> accountIds = new Set<Id>();
		for(Subscription__c sub : newList) {
			Id accountId = idValue(sub.AccountId__c);
			Id billToSfAccountId = idValue(sub.BillToSfAccountId__c);
			Id shipToSfAccountId = idValue(sub.ShipToSfAccountId__c);
			Id soldToSfAccountId = idValue(sub.SoldToSfAccountId__c);
			Id entitleToSfAccountId = idValue(sub.EntitleToSfAccountId__c);
			Subscription__c oldSub = oldMap.get(sub.Id);
			if(oldSub == null) {
				oldSub = new Subscription__c();
			}
			if(oldSub.Account__c != sub.Account__c) {
				sub.AccountId__c = sub.Account__c;
			}
			else if(accountId != sub.Account__c) {
				accountIds.add(accountId);
			}
			if(oldSub.BillToSalesAccount__c != sub.BillToSalesAccount__c) {
				sub.BillToSfAccountId__c = sub.BillToSalesAccount__c;
			}
			else if(billToSfAccountId != sub.BillToSalesAccount__c) {
				accountIds.add(billToSfAccountId);
			}
			if(oldSub.ShipToSalesAccount__c != sub.ShipToSalesAccount__c) {
				sub.ShipToSfAccountId__c = sub.ShipToSalesAccount__c;
			}
			else if(shipToSfAccountId != sub.ShipToSalesAccount__c) {
				accountIds.add(shipToSfAccountId);
			}
			if(oldSub.SoldToSalesAccount__c != sub.SoldToSalesAccount__c) {
				sub.SoldToSfAccountId__c = sub.SoldToSalesAccount__c;
			}
			else if(soldToSfAccountId != sub.SoldToSalesAccount__c) {
				accountIds.add(soldToSfAccountId);
			}
			if(oldSub.EntitleToSalesAccount__c != sub.EntitleToSalesAccount__c) {
				sub.EntitleToSfAccountId__c = sub.EntitleToSalesAccount__c;
			}
			else if(entitleToSfAccountId != sub.EntitleToSalesAccount__c) {
				accountIds.add(entitleToSfAccountId);
			}
		}
		if(! accountIds.isEmpty()) {
			accountIds.remove(null);
			if(! accountIds.isEmpty()) {
				accountIds = new Map<Id,Account>([
					select Id
					from Account
					where Id in :accountIds ]).keySet();
			}
			for(Subscription__c sub : newList) {
				Id accountId = idValue(sub.AccountId__c);
				Id billToSfAccountId = idValue(sub.BillToSfAccountId__c);
				Id shipToSfAccountId = idValue(sub.ShipToSfAccountId__c);
				Id soldToSfAccountId = idValue(sub.ShipToSfAccountId__c);
				Id entitleToSfAccountId = idValue(sub.EntitleToSfAccountId__c);
				if(accountId != sub.Account__c) {
					if(! accountIds.contains(accountId)) {
						accountId = null;
					}
					sub.AccountId__c = sub.Account__c = accountId;
				}
				if(billToSfAccountId != sub.BillToSalesAccount__c) {
					if(! accountIds.contains(billToSfAccountId)) {
						billToSfAccountId = null;
					}
					sub.BillToSfAccountId__c = sub.BillToSalesAccount__c = billToSfAccountId;
				}
				if(shipToSfAccountId != sub.ShipToSalesAccount__c) {
					if(! accountIds.contains(shipToSfAccountId)) {
						shipToSfAccountId = null;
					}
					sub.ShipToSfAccountId__c = sub.ShipToSalesAccount__c = shipToSfAccountId;
				}
				if(soldToSfAccountId != sub.SoldToSalesAccount__c) {
					if(! accountIds.contains(soldToSfAccountId)) {
						soldToSfAccountId = null;
					}
					sub.SoldToSfAccountId__c = sub.SoldToSalesAccount__c = soldToSfAccountId;
				}
				if(entitleToSfAccountId != sub.EntitleToSalesAccount__c) {
					if(! accountIds.contains(entitleToSfAccountId)) {
						entitleToSfAccountId = null;
					}
					sub.EntitleToSfAccountId__c = sub.EntitleToSalesAccount__c = entitleToSfAccountId;
				}
			}
		}
	}

	/**
	 * Called to synchronize the CampaignId__c and Campaign__c fields.
	 */
	public void syncCampaignFields() {
		Set<Id> campaignIds = new Set<Id>();
		for(Subscription__c sub : newList) {
			Id campaignId = idValue(sub.CampaignId__c);
			Subscription__c oldSub = oldMap.get(sub.Id);
			if(oldSub == null) {
				oldSub = new Subscription__c();
			}
			if(oldSub.Campaign__c != sub.Campaign__c) {
				sub.CampaignId__c = sub.Campaign__c;
			}
			else if(campaignId != sub.Campaign__c) {
				campaignIds.add(campaignId);
			}
		}
		if(! campaignIds.isEmpty()) {
			campaignIds.remove(null);
			if(! campaignIds.isEmpty()) {
				campaignIds = new Map<Id,Campaign>([
					select Id
					from Campaign
					where Id in :campaignIds]).keySet();
			}
			for(Subscription__c sub : newList) {
				Id campaignId = idValue(sub.CampaignId__c);
				if(campaignId != sub.Campaign__c) {
					String x = null;
					if(! campaignIds.contains(campaignId)) {
						campaignId = null;
					}
					sub.CampaignId__c = sub.Campaign__c = campaignId;
				}
			}
		}
	}

	/**
	 * Called to synchronize the OriginalOpportunityId__c and OriginalOpportunity__c fields.
	 */
	public void syncOriginalOpportunityFields() {
		Set<Id> oppIds = new Set<Id>();
		for(Subscription__c sub : newList) {
			Id originalOpportunityId = idValue(sub.OriginalOpportunityId__c);
			Subscription__c oldSub = oldMap.get(sub.Id);
			if(oldSub == null) {
				oldSub = new Subscription__c();
			}
			if(oldSub.OriginalOpportunity__c != sub.OriginalOpportunity__c) {
				sub.OriginalOpportunityId__c = sub.OriginalOpportunity__c;
			}
			else if(originalOpportunityId != sub.OriginalOpportunity__c) {
				oppIds.add(originalOpportunityId);
			}
		}
		if(! oppIds.isEmpty()) {
			oppIds.remove(null);
			if(! oppIds.isEmpty()) {
				oppIds = new Map<Id,Opportunity>([
					select Id
					from Opportunity
					where Id in :oppIds]).keySet();
			}
			for(Subscription__c sub : newList) {
				Id originalOpportunityId = idValue(sub.OriginalOpportunityId__c);
				if(originalOpportunityId != sub.OriginalOpportunity__c) {
					if(! oppIds.contains(originalOpportunityId)) {
						originalOpportunityId = null;
					}
					sub.OriginalOpportunityId__c = sub.OriginalOpportunity__c = originalOpportunityId;
				}
			}
		}
	}

//depreciated	/**
//depreciated	 * Assign the batch.  If there are multiple batches running in 
//depreciated	 * parallel, there will be locking errors.  Those will be ignored
//depreciated	 * here and handled in future methods.
//depreciated	 */
//depreciated	public void assignBatch() {
//depreciated		Map<String,Id> batchIdMap = new Map<String,Id>();
//depreciated		Set<String> batchIds = new Set<String>();
//depreciated		for(Subscription__c sub : newList) {
//depreciated			if(sub.BatchId__c != null) {
//depreciated				if(sub.Batch__c != null) {
//depreciated					batchIdMap.put(sub.BatchId__c.toLowerCase(),sub.Batch__c);
//depreciated				}
//depreciated				else {
//depreciated					batchIds.add(sub.BatchId__c.toLowerCase());
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		batchIds.removeAll(batchIdMap.keySet());
//depreciated		if(! batchIds.isEmpty()) {
//depreciated			for(SubscriptionBatch__c batch : [
//depreciated				select BatchId__c
//depreciated				from SubscriptionBatch__c
//depreciated				where BatchId__c in :batchIds ] )
//depreciated			{
//depreciated				batchIdMap.put(batch.BatchId__c.toLowerCase(),batch.Id);
//depreciated			}
//depreciated			batchIds.removeAll(batchIdMap.keySet());
//depreciated			if(! batchIds.isEmpty()) {
//depreciated				List<SubscriptionBatch__c> subscriptionBatches = new List<SubscriptionBatch__c>();
//depreciated				for(String batchId : batchIds) {
//depreciated					subscriptionBatches.add(new SubscriptionBatch__c(
//depreciated						BatchId__c = batchId ));
//depreciated				}
//depreciated				for(Database.UpsertResult ur : Database.upsert(subscriptionBatches,SubscriptionBatch__c.Fields.BatchId__c,false)) {
//depreciated					SubscriptionBatch__c batch = subscriptionBatches.remove(0);
//depreciated					if(ur.isSuccess()) {
//depreciated						batchIdMap.put(batch.BatchId__c,batch.Id);
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		if(! batchIdMap.isEmpty()) {
//depreciated			for( Subscription__c sub : newList ) {
//depreciated				if(sub.BatchId__c != null) {
//depreciated					Id id = batchIdMap.get(sub.BatchId__c.toLowerCase());
//depreciated					if(id != null && id != sub.Batch__c) {
//depreciated						sub.Batch__c = id;
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}

	/**
	 * assign the composite key
	 */
	public void assignCompositeKey() {
		for(Subscription__c sub : newList) {
			String compositeKey = null;
			if(sub.OrderId__c != null || sub.ContractId__c != null) {
				String orderId = '';
				if(sub.OrderId__c != null) {
					orderId = String.valueOf(sub.OrderId__c.longValue());
				}
				String contractId = '';
				if(sub.ContractId__c != null) {
					contractId = String.valueOf(sub.ContractId__c.longValue());
				}
				String fiscalYear = '????';
				if(sub.FiscalYear__c != null) {
					fiscalYear = String.valueOf(sub.FiscalYear__c.longValue());
				}
				String fiscalQuarter = '?';
				if(sub.FiscalQuarter__c != null) {
					fiscalQuarter = String.valueOf(sub.FiscalQuarter__c.longValue());
				}
				compositeKey = orderId+':'+contractId+'FY'+fiscalYear+'Q'+fiscalQuarter;
			}
			if(compositeKey != sub.CompositeKey__c) {
				sub.CompositeKey__c = compositeKey;
			}
		}
	}

	/**
	 * assign the region
	 */
	public void assignRegion() {
		Set<String> countries = new Set<String>();
		for(Subscription__c sub : newList) {
			if(sub.CountryOfOrder__c != null) {
				Subscription__c oldSub = oldMap.get(sub.Id);
				String oldCountryOfOrder = null;
				if(oldSub != null) {
					oldCountryOfOrder = oldSub.CountryOfOrder__c;
				}
				if(oldCountryOfOrder != sub.CountryOfOrder__c) {
					countries.add(sub.CountryOfOrder__c);
				}
			}
		}
		if(! countries.isEmpty()) {
			Map<String,Region__c> regionMap = new Map<String,Region__c>();
			for( Region__c region : [
				select
					Country__c,
					Region__c,
					Sub_Region__c,
					Super_Region__c
				from Region__c
				where Country__c in :countries ])
			{
				regionMap.put(region.Country__c.toUpperCase(),region);
			}
			for(Subscription__c sub : newList) {
				if(sub.CountryOfOrder__c != null) {
					Region__c region = regionMap.get(sub.CountryOfOrder__c.toUpperCase());
					if(region != null) {
						if(sub.SuperRegion__c == null) {
							sub.SuperRegion__c = region.Super_Region__c;
						}
						sub.Region__c = region.Region__c;
					}
				}
			}
		}
	}

	private static Id idValue(String value) {
		Id retval = null;
		try {
			retval = value;
		}
		catch(Exception ex) {}
		return retval;
	}

	public static Map<String,CurrencyType> currencyTypeMap {
		get {
			if(currencyTypeMap == null) {
				currencyTypeMap = new Map<String,CurrencyType>();
				for(CurrencyType ct : [
					select ConversionRate, IsoCode, DecimalPlaces
					from CurrencyType
					where IsActive = true ])
				{
					currencyTypeMap.put(ct.IsoCode,ct);
				}
			}
			return currencyTypeMap;
		}
		private set;
	}

	public void aggregateSubscriptionLines() {
		Map<String,Subscription__c> subMap = new Map<String,Subscription__c>();
		for(Subscription__c sub : newList) {
			subMap.put(sub.CompositeKey__c,sub);
		}
		for(AggregateResult ar : [
			select
				SubscriptionCompositeKey__c,
				SUM(RenewalTotalPrice__c) sum
			from SubscriptionLine__c
			where AlreadyRenewed__c != true 
				and DnrFlag__c != true
				and NfrFlag__c != true
				and SubscriptionCompositeKey__c = :subMap.keySet()
			group by SubscriptionCompositeKey__c ] )
		{
			Decimal expiringProductsAmount = (Decimal)ar.get('sum');
			if(expiringProductsAmount != null) {
				Subscription__c sub = subMap.remove((String)ar.get('SubscriptionCompositeKey__c'));
				if(sub != null) {
					// A aggregate SUM of a currency value is always convert to the corporate currency.
					// So we need to convert the currency back to the correct currency type.
					Integer scale = expiringProductsAmount.scale();
					CurrencyType ct = currencyTypeMap.get(sub.CurrencyIsoCode);
					Double conversionRate = 1.0;
					if(ct != null) {
						conversionRate = ct.ConversionRate;
						scale = ct.DecimalPlaces;
					}
					expiringProductsAmount = (expiringProductsAmount*conversionRate).setScale(scale);
					if(expiringProductsAmount != sub.ExpiringProductsAmount__c) {
						sub.ExpiringProductsAmount__c = expiringProductsAmount;
						System.debug(ar);
					}
				}
			}
		}
		for(Subscription__c sub : subMap.values()) {
			if(sub.ExpiringProductsAmount__c != 0) {
				sub.ExpiringProductsAmount__c = 0;
			}
		}
	}

	public void updateStatuses() {
		for(Subscription__c sub : newList) {
			if( null == sub.Status__c
				|| SubscriptionBatchTriggerAfter.HOLD_FOR_DECISION_STATUS == sub.Status__c
				|| SubscriptionBatchTriggerAfter.WAIT_FOR_CHANNEL_LOAD_STATUS == sub.Status__c ) 
			{
				String status = SubscriptionBatchTriggerAfter.HOLD_FOR_DECISION_STATUS;
				if(true != sub.IsChannelLoadComplete__c) {
					status = SubscriptionBatchTriggerAfter.WAIT_FOR_CHANNEL_LOAD_STATUS;
				}
				if(status != sub.Status__c) {
					sub.Status__c = status;
				}
			}
		}
	}

	public void ssiOptIn() {
		for(Subscription__c sub : newList) {
			if( isInsert
				|| null == sub.Status__c
				|| SubscriptionBatchTriggerAfter.HOLD_FOR_DECISION_STATUS == sub.Status__c
				|| SubscriptionBatchTriggerAfter.WAIT_FOR_CHANNEL_LOAD_STATUS == sub.Status__c )
			{
				if(sub.SSI_InScope__c != false) {
					sub.SSI_InScope__c = false;
				}
				if(sub.CurrencyIsoCode != null && sub.ContractAmount__c != null) {
					Double conversionRate = 1.0;
					CurrencyType ct = currencyTypeMap.get(sub.CurrencyIsoCode);
					if(ct != null) {
						conversionRate = ct.ConversionRate;
					}
					Boolean ssiOptIn = (sub.ContractAmount__c <= CONTRACT_AMOUNT_LIMIT * conversionRate);
					if(ssiOptIn != sub.SSI_OptIn__c) {
						sub.SSI_OptIn__c = ssiOptIn;
					}
				}
			}
		}
	}

	/**
	 * method to allow us to perform a look up for contact
	 * data instead of querying for each contact. supports
	 * batches that include subscriptions across multiple
	 * accounts.
	 *
	 * @param account ids
	 * @param email addresses
	 * @return map of contact ids by account id and email address
	 */
	private Map<Id, Map<String, Id>> getContactIdMap(Set<Id> accountIds, Set<String> emails) {
		emails.remove(null);

		Map<Id, Map<String, Id>> contactIdMap = new Map<Id, Map<String, Id>>();
		if(! emails.isEmpty()) {
			// query the contacts by email address and account
			// populate the contact map with the results
			for ( Contact contact : [
				SELECT
					AccountId,
					Email
				FROM Contact
				WHERE AccountId IN :accountIds
					AND Email IN :emails ] )
				{
					if(!contactIdMap.containsKey(contact.AccountId)) {
						contactIdMap.put(contact.AccountId,new Map<String, Id>());
					}
					contactIdMap.get(contact.AccountId).put(contact.Email.toLowerCase(), contact.Id);
				}
			}
		return contactIdMap;
	}

	/**
	 * trigger method that maps existing contacts to the subscription
	 */
	public void mapContacts() {
		// build sets needed to get contact map for lookups
		Set<Id> accountIds = new Set<Id>();
		Set<String> emails = new Set<String>();
		List<Subscription__c> subscriptions = new List<Subscription__c>();
		for(Subscription__c sub : newList) {
			Subscription__c oldSub = null;
			if(isUpdate) {
				oldSub = oldMap.get(sub.Id);
			}
			if( sub.Status__c != SubscriptionBatchTriggerAfter.WAIT_FOR_CHANNEL_LOAD_STATUS
				&& sub.Status__c != SUCCESS_STATUS
				&& sub.Status__c != DO_NOT_LOAD_STATUS
				&& (sub.Status__c != ERROR_STATUS || oldSub == null || sub.Status__c == oldSub.Status__c ) )
			{
				if(oldSub == null || sub.Account__c != oldSub.Account__c || sub.Account__c == null ) {
					sub.ShippingContact__c = null;
					sub.SellingContact__c = null;
				}
				if(sub.Account__c != null && (sub.SellingContact__c == null || sub.ShippingContact__c == null)) {
					subscriptions.add(sub);
					accountIds.add(sub.Account__c);
					if(sub.ShippingContact__c == null && sub.ShipToContactEmail__c != null) {
						emails.add(sub.ShipToContactEmail__c);
					}
					if(sub.SellingContact__c == null) {
						if(sub.SoldToContactEmail__c != null) {
							emails.add(sub.SoldToContactEmail__c);
						}
						else if(sub.EntitleToContactEmail__c != null && sub.SoldToAccountNumber__c == sub.EntitleToAccountNumber__c)
						{
							emails.add(sub.EntitleToContactEmail__c);
						}
					}
				}
			}
		}
		if(! emails.isEmpty()) {
			// get contact map
			Map<Id, Map<String, Id>> contactIdMap = getContactIdMap(accountIds, emails);

			// look up contacts for each subscription by account and email
			for(Subscription__c sub : subscriptions) {
				Map<String,Id> contactIdMap2 = contactIdMap.get(sub.Account__c);
				if(contactIdMap2 != null) {
					// set the shipping contact on the sub
					if(sub.ShippingContact__c == null && sub.ShipToContactEmail__c != null) {
						sub.ShippingContact__c = contactIdMap2.get(sub.ShipToContactEmail__c.toLowerCase());
					}
					// set the sold to contact on the sub
					if(sub.SellingContact__c == null) {
						if(sub.SoldToContactEmail__c != null)
						{
							sub.SellingContact__c = contactIdMap2.get(sub.SoldToContactEmail__c.toLowerCase());
						}
						else if(sub.EntitleToContactEmail__c != null && sub.SoldToAccountNumber__c == sub.EntitleToAccountNumber__c)
						{
							sub.SellingContact__c = contactIdMap2.get(sub.EntitleToContactEmail__c.toLowerCase());
						}
					}
				}
			}
		}
	}

	/**
	 * do we need to touch related partners to invoke mapping trigger?
	 */
	private Boolean mapResellerPartner(Subscription__c oldSub, Subscription__c newSub) {
		return(newSub != null 
			&& newSub.Status__c != SubscriptionBatchTriggerAfter.WAIT_FOR_CHANNEL_LOAD_STATUS
			&& newSub.Status__c != SUCCESS_STATUS
			&& newSub.Status__c != DO_NOT_LOAD_STATUS
			&& (oldSub == null || newSub.Status__c == oldSub.Status__c || newSub.Status__c != ERROR_STATUS));
	}

	/**
	 * trigger method touches related subscription partner records to invoke the mapping triggers there
	 */
	public void mapResellerPartner() {
		// build sets
		Set<Id> subIds = new Set<Id>();
		for(Subscription__c sub : newList) {
			Subscription__c oldSub = null;
			if(isUpdate) {
			oldSub = oldMap.get(sub.Id);
			}
			if(mapResellerPartner(oldSub, sub)) {
			subIds.add(sub.Id);
			}
		}

		// get subscription partners
		Set<Id> subPartnerIds = new Set<Id>();
		for(SubscriptionPartnerRelationship__c subPartnerRel : [
			select
			Id,
			SubscriptionPartner__c
			from SubscriptionPartnerRelationship__c
			where Subscription__c IN :subIds])
		{
			subPartnerIds.add(subPartnerRel.SubscriptionPartner__c);
		}

		// touch subscription partner records
		List<SubscriptionPartner__c> subPartners = new List<SubscriptionPartner__c>();
		for(Id subPartnerId : subPartnerIds) {
			subPartners.add(new SubscriptionPartner__c(Id = subPartnerId));
		}
		if(!subPartners.isEmpty()) {
			Database.update(subPartners,false);
		}
	}

	/**
	 * Copy Entitle To data from the relevant SubscriptionLine__c records, and find
	 * the subscription lines that need to be updated to link the subscription.
	 */
	public void updateFromSubscriptionLines() {
		Map<String,Subscription__c> keyMap = new Map<String,Subscription__c>();
		Map<Id,Subscription__c> newMap = new Map<Id,Subscription__c>();
		if(isUpdate) {
			newMap.putAll( newList );
		}
		for( Subscription__c sub : newList ) {
			if(sub.CompositeKey__c != null && sub.Status__c != READY_STATUS) {
				keyMap.put(sub.CompositeKey__c,sub);
			}
		}
		if(! keyMap.isEmpty()) {
			List<SubscriptionLine__c> queriedList = [
				select
					AlreadyRenewed__c,
					CurrencyIsoCode,
					DnrFlag__c,
					EntitleToAddress1__c,
					EntitleToAddress2__c,
					EntitleToAccountNumber__c,
					EntitleToCDHPartyNumber__c,
					EntitleToCDHPartySiteNumber__c,
					EntitleToCity__c,
					EntitleToContactEmail__c,
					EntitleToContactFirstName__c,
					EntitleToContactLastName__c,
					EntitleToContactName__c,
					EntitleToContactPhone__c,
					EntitleToContCDHPartyNumber__c,
					EntitleToCountry__c,
					EntitleToPartyNumber__c,
					EntitleToPartyName__c,
					EntitleToPostalCode__c,
					EntitleToState__c,
					NfrFlag__c,
					OwnerId,
					OriginalCompositeKey__c,
					OriginalSubscription__c,
					Subscription__c,
					Subscription__r.Account__c,
					SubscriptionCompositeKey__c
				from SubscriptionLine__c
				where Subscription__c in : newMap.keySet()
					or OriginalSubscription__c in : newMap.keySet()
					or ( OriginalSubscription__c = null
						and OriginalCompositeKey__c in :keyMap.keySet() )
					or ( Subscription__c = null
						and SubscriptionCompositeKey__c in :keyMap.keySet() ) ];
			for(SubscriptionLine__c subLine : queriedList ) {
				if(subLine.AlreadyRenewed__c != true && subLine.DnrFlag__c != true && subLine.NfrFlag__c != true) {
					Subscription__c sub = newMap.get(subLine.OriginalSubscription__c);
					if(subLine.OriginalSubscription__c == null) {
						sub = keyMap.get(subLine.OriginalCompositeKey__c);
					}
					if ( sub != null
						&& sub.EntitleToAddress1__c == null
						&& sub.EntitleToAddress2__c == null
						&& sub.EntitleToCDHPartyNumber__c == subLine.EntitleToCDHPartyNumber__c
						&& sub.EntitleToCDHPartySiteNumber__c == subLine.EntitleToCDHPartySiteNumber__c
						&& sub.EntitleToCity__c == null
						&& sub.EntitleToContactEmail__c == null
						&& sub.EntitleToContactFirstName__c == null
						&& sub.EntitleToContactLastName__c == null
						&& sub.EntitleToContactName__c == null
						&& sub.EntitleToContactPhone__c == null
						&& sub.EntitleToContCDHPartyNumber__c == subLine.EntitleToContCDHPartyNumber__c
						&& sub.EntitleToCountry__c == null
						&& sub.EntitleToPostalCode__c == null
						&& sub.EntitleToState__c == null )
					{
						if(sub.EntitleToAccountNumber__c == null) {
							sub.EntitleToAccountNumber__c = subLine.EntitleToAccountNumber__c;
						}
						if(sub.EntitleToPartyNumber__c == null) {
							sub.EntitleToPartyNumber__c = subLine.EntitleToPartyNumber__c;
						}
						if(sub.EntitleToPartyName__c == null) {
							sub.EntitleToPartyName__c = subLine.EntitleToPartyName__c;
						}
						sub.EntitleToAddress1__c = subLine.EntitleToAddress1__c;
						sub.EntitleToAddress2__c = subLine.EntitleToAddress2__c;
						sub.EntitleToCity__c = subLine.EntitleToCity__c;
						sub.EntitleToContactEmail__c = subLine.EntitleToContactEmail__c;
						sub.EntitleToContactFirstName__c = subLine.EntitleToContactFirstName__c;
						sub.EntitleToContactLastName__c = subLine.EntitleToContactLastName__c;
						sub.EntitleToContactName__c = subLine.EntitleToContactName__c;
						sub.EntitleToContactPhone__c = subLine.EntitleToContactPhone__c;
						sub.EntitleToCountry__c = subLine.EntitleToCountry__c;
						sub.EntitleToPostalCode__c = subLine.EntitleToPostalCode__c;
						sub.EntitleToState__c = subLine.EntitleToState__c;
					}
				}
			}
			SubscriptionTriggerAfter.queriedSubscriptionLines = queriedList;
		}
	}

	private String getContactKey(
		Id accountId,
		String firstName,
		String lastName,
		String name,
		String email,
		String phone)
	{
		//  if(firstName == null) {
		//  firstName = '';
		//  }
		//  if(lastName == null || lastName == '') {
		//  lastName = name;
		//  }
		//  String key = (accountId+':'+firstName+':'+lastName+':'+email+':'+phone).toLowerCase();
		return (accountId+':'+email).toLowerCase();
	}

	private static String blankValue(String value,String defaultValue) {
		if(value == '' || value == null) {
			value = defaultValue;
		}
		return value;
	}

	private static String emailValue(String value,String defaultValue) {
		String retval = defaultValue;
		if(value != null && value != '') {
			final String CONTACT_EMAIL_SUFFIX = blankValue(Account_Matching.CONTACT_EMAIL_SUFFIX,null);
			if(CONTACT_EMAIL_SUFFIX != null && ! value.endsWithIgnoreCase(CONTACT_EMAIL_SUFFIX)) {
				value += CONTACT_EMAIL_SUFFIX;
			}
			retval = value;
		}
		return retval;
	}

	private static String emailValue2(String value,String defaultValue) {
		String retval = defaultValue;
		if(value != null && value != '') {
			final String CONTACT_EMAIL_SUFFIX = blankValue(Account_Matching.CONTACT_EMAIL_SUFFIX,null);
			if(CONTACT_EMAIL_SUFFIX != null && value.endsWithIgnoreCase(CONTACT_EMAIL_SUFFIX)) {
				value.substring(0,value.length()-CONTACT_EMAIL_SUFFIX.length());
			}
			retval = value;
		}
		return retval;
	}

	private static Contact createContact(Id accountId,String firstName, String lastName, String name, String email, String phone) {
		Contact c = new Contact(
			AccountId = accountId,
			FirstName = blankValue(firstName,''),
			LastName = blankValue(lastName,blankValue(name,'')),
			Email = emailValue(email,null),
			Phone = blankValue(phone,null));
		c.Hash__c = ContactTriggerBefore.hash(c);
		return c;
	}

	private static Contact getContact(Map<String,Contact> contactHashMap,Id accountId,String firstName, String lastName, String name, String email, String phone) {
		return contactHashMap.get(createContact(accountId,firstName,lastName,name,email,phone).Hash__c);
	}

	private static List<Contact> getContacts(Map<String,Contact> contactHashMap,Set<Id> accountIds,String firstName, String lastName, String name, String email, String phone) {
		List<Contact> contacts = new List<Contact>();
		for(Id accountId : accountIds) {
			Contact c = getContact(contactHashMap,accountId,firstName,lastName,name,email,phone);
			if(c != null) {
				contacts.add(c);
			}
		}
		return contacts;
	}

	
	private static void addContact(Map<String,Contact> contactHashMap,Set<Id> accountIds,String firstName, String lastName, String name, String email, String phone) {
		for(Id accountId : accountIds) {
			if(accountId != null && contactHashMap != null) {
				Contact c = createContact( accountId, firstName, lastName, name, email, phone);
//				contactMap.put(getContactKey(c.AccountId,c.FirstName,c.LastName,null,c.Email,c.Phone),c);
				contactHashMap.put(c.Hash__c,c);
				break;
			}
		}
	}

	/**
	 * Called to create contacts before processing a subscription.
	 */
	public void createContacts(List<SubscriptionLine__c> subLines) {
		Boolean isTesting = Test.isRunningTest();
		Map<String,Contact> contactHashMap = new Map<String,Contact>();
		if(subLines != null) {
			for( SubscriptionLine__c subLine : subLines ) {
				if( subLine.AlreadyRenewed__c != true 
					&& subLine.DnrFlag__c != true
					&& subLine.NfrFlag__c != true
					&& subLine.EntitleToContact__c == null
					&& (isTesting || subLine.EntitleToEBSAccount__c != null)
					&& subLine.EntitleToSalesAccount__c != null
					&& subLine.EntitleToContactEmail__c != null )
				{
					addContact(contactHashMap,
						new Set<Id> { subLine.EntitleToSalesAccount__c },
						subLine.EntitleToContactFirstName__c,
						subLine.EntitleToContactLastName__c,
						subLine.EntitleToContactName__c,
						subLine.EntitleToContactEmail__c,
						subLine.EntitleToContactPhone__c );
				}
			}
		}
		for( Subscription__c sub : readyList ) {
			System.debug('Status__c = '+sub.Status__c);
			if( sub.BillToContact__c == null
				&& (isTesting || sub.BillToEBSAccount__c != null)
				&& sub.BillToSalesAccount__c != null
				&& sub.BillToContactEmail__c != null )
			{
				addContact(contactHashMap,
					new Set<Id>{ sub.BillToSalesAccount__c },
					sub.BillToContactFirstName__c,
					sub.BillToContactLastName__c,
					sub.BillToContactName__c,
					sub.BillToContactEmail__c,
					sub.BillToContactPhone__c );
			}
			if( sub.ShipToContact__c == null
				&& (isTesting || sub.ShipToEBSAccount__c != null)
				&& sub.ShipToSalesAccount__c != null
				&& sub.ShipToContactEmail__c != null )
			{
				addContact(contactHashMap,
					new Set<Id>{ sub.ShipToSalesAccount__c },
					sub.ShipToContactFirstName__c,
					sub.ShipToContactLastName__c,
					sub.ShipToContactName__c,
					sub.ShipToContactEmail__c,
					sub.ShipToContactPhone__c );
			}
			if( sub.SoldToContact__c == null
				&& (isTesting || sub.SoldToEBSAccount__c != null)
				&& sub.SoldToSalesAccount__c != null
				&& sub.SoldToContactEmail__c != null )
			{
				addContact(contactHashMap,
					new Set<Id>{ sub.SoldToSalesAccount__c },
					sub.SoldToContactFirstName__c,
					sub.SoldToContactLastName__c,
					sub.SoldToContactName__c,
					sub.SoldToContactEmail__c,
					sub.SoldToContactPhone__c );
			}
			if( sub.EntitleToContact__c == null
				&& (isTesting || sub.EntitleToEBSAccount__c != null)
				&& sub.EntitleToSalesAccount__c != null
				&& sub.EntitleToContactEmail__c != null ) 
			{
				addContact(contactHashMap,
					new Set<Id>{ sub.EntitleToSalesAccount__c },
					sub.EntitleToContactFirstName__c,
					sub.EntitleToContactLastName__c,
					sub.EntitleToContactName__c,
					sub.EntitleToContactEmail__c,
					sub.EntitleToContactPhone__c );
			}
			if( sub.SuperRegion__c != null
				&& sub.SuperRegion__c != 'JAPAN' )
			{
				if(sub.ShippingContact__c == null && sub.ShipToContactEmail__c != null) {
					addContact(contactHashMap,
						new Set<Id>{ sub.ShipToSalesAccount__c, sub.Account__c },
						sub.ShipToContactFirstName__c,
						sub.ShipToContactLastName__c,
						sub.ShipToContactName__c,
						sub.ShipToContactEmail__c,
						sub.ShipToContactPhone__c);
				}
				if(sub.SellingContact__c == null && sub.SuperRegion__c != 'EMEA') {
					if(sub.SoldToContactEmail__c != null) {
						addContact(contactHashMap,
							new Set<Id>{ sub.SoldToSalesAccount__c, sub.Account__c },
							sub.SoldToContactFirstName__c,
							sub.SoldToContactLastName__c,
							sub.SoldToContactName__c,
							sub.SoldToContactEmail__c,
							sub.SoldToContactPhone__c);
					}
					else if(sub.EntitleToContactEmail__c != null && (sub.SoldToAccountNumber__c == null || sub.EntitleToAccountNumber__c == sub.SoldToAccountNumber__c)) {
						addContact(contactHashMap,
							new Set<Id>{ sub.EntitleToSalesAccount__c, sub.Account__c },
							sub.EntitleToContactFirstName__c,
							sub.EntitleToContactLastName__c,
							sub.EntitleToContactName__c,
							sub.EntitleToContactEmail__c,
							sub.EntitleToContactPhone__c);
					}
				}
			}
		}
		// check if we need to find or add any contacts
		if(! contactHashMap.isEmpty()) {
			// we will filter our initial query by account id and email adddress
			Set<Id> accountIds = new Set<Id>();
			Set<String> emailAddresses = new Set<String>();
			for(Contact c : contactHashMap.values()) {
				accountIds.add(c.AccountId);
				emailAddresses.add(emailValue(c.Email,null));
				emailAddresses.add(emailValue2(c.Email,null));
			}
			Map<Id,Account> accountMap = new Map<Id,Account>([
				select Id,
					CDH_Party_Name__c,
					(	select Id,
							AccountId,
							FirstName,
							LastName,
							Email,
							Phone,
							Hash__c
						from Contacts
						where Email in :emailAddresses )
				from Account
				where Id in :accountIds]);
			// Clone the contactHashMap to keep track the the contacts we don't find
			Map<String,Contact> neededContactByHash = contactHashMap.clone();
			// Make a has based on cdh party id, so we can find contacts under related accounts
			Map<String,Contact> contactByCDHPartyHash = new Map<String,Contact>();
			// loop over our results and update the maps
			for(Account a : accountMap.values()) {
				for(Contact c : a.Contacts) {
					c.Email = emailValue(c.Email,null);
					c.Hash__c = ContactTriggerBefore.hash(c);
					contactHashMap.put(c.Hash__c,c);
					contactByCDHPartyHash.put(blankValue(a.CDH_Party_Name__c,'')+c.Hash__c.substring(18),c);
					neededContactByHash.remove(c.Hash__c);
				}
			}
			// do we still have contacts to find?
			if(! neededContactByHash.isEmpty()) {
				emailAddresses.clear();
				// lets prepare a map of contacts by cdhparty id
				Map<Id,List<Contact>> contactsByCDHPartyId = new Map<Id,List<Contact>>();
				// search for contacts using the cdh party id instead of account id
				for(Contact c : neededContactByHash.values().clone()) {
					Account a = accountMap.get(c.AccountId);
					Contact c2 = null;
					if(a != null) {
						c2 = contactByCDHPartyHash.get(blankValue(a.CDH_Party_Name__c,'')+c.Hash__c.substring(18));
					}
					if(a != null && a.CDH_Party_Name__c != null && c2 == null) {
						// no match, so prepare the data we'll need for the next query
						if(c.Email != null) {
							emailAddresses.add(emailValue(c.Email,null));
							emailAddresses.add(emailValue2(c.Email,null));
						}
						List<Contact> contacts = contactsByCDHPartyId.get(a.CDH_Party_Name__c);
						if(contacts == null) {
							contacts = new List<Contact>();
							contactsByCDHPartyId.put(a.CDH_Party_Name__c,contacts);
						}
						contacts.add(c);
					}
					else {
						// we have a match, lets store it
						neededContactByHash.remove(c.Hash__c);
						if(c2 != null) {
							// Store the contact under the hash value we need, even
							// though this not the hash code we have.   Basically it is
							// close enough, as everything is correct except the actual account.
							contactHashMap.put(c.Hash__c,c2);
						}
					}
				}
				// do we need to query additional accounts?
				if(! contactsByCDHPartyId.isEmpty()) {
					// query related accounts and store the contacts in our map
					for(Account a : [
						select Id,
							CDH_Party_Name__c,
							(	select Id,
									AccountId,
									FirstName,
									LastName,
									Email,
									Phone,
									Hash__c
								from Contacts
								where Email in :emailAddresses )
						from Account
						where Id not in :accountMap.keySet()
							and CDH_Party_Name__c in :contactsByCDHPartyId.keySet() ] )
					{
						for(Contact c : a.contacts) {
							c.Email = emailValue(c.Email,null);
							c.Hash__c = ContactTriggerBefore.hash(c);
							contactByCDHPartyHash.put(blankValue(a.CDH_Party_Name__c,'')+c.Hash__c.substring(18),c);
						}
					}
					// scan to see if we found any of the contacts we needed
					for(Id cdhPartyId : contactsByCDHPartyId.keySet()) {
						for(Contact c : contactsByCDHPartyId.get(cdhPartyId)) {
							Contact c2 = contactByCDHPartyHash.get(blankValue(cdhPartyId,'')+c.Hash__c.substring(18));
							if(c2 != null) {
								// Store the contact under the hash value we need, even
								// though this not the hash code we have.   Basically it is
								// close enough, as everything is correct except the actual account.
								contactHashMap.put(c2.Hash__c,c);
								neededContactByHash.remove(c2.Hash__c);
							}
						}
					}
				}
				// do we still have contacts to find
				if(! neededContactByHash.isEmpty()) {
					// we insert contacts by a key which currently consists of account id and e-mail address.
					// we do not search by contacts this way, under the assumption that multiple contacts could have 
					// the same key, but it is unlikely we'll happen to need to insert multiple contacts that have the
					// same key...  This is basically a compromise between the way it should be done if the way the
					// data was perfect and recognizing phone numbers and names will be mistyped on some of the lines
					// of the validation files.
					Map<String,Contact> missingContactByKey = new Map<String,Contact>();
					for(Contact c : neededContactByHash.values()) {
						String key = getContactKey(
							c.AccountId,
							c.FirstName,
							c.LastName,
							null,
							c.Email,
							c.Phone);
						missingContactByKey.put(key,c);
					}
					// We still have contacts we cannot find.  Time to create them.
					List<Contact> contactList = missingContactByKey.values().clone();
					for(Integer i=contactList.size(),j=contactInsertSizeLimit;i > j;) {
						contactList.remove(--i);
					}
					// an upsert works better for race conditions
					Database.upsert(contactList,Contact.fields.Hash__c,false);
					// scan again to store the contacts we just inserted
					for(Contact c : neededContactByHash.values()) {
						String key = getContactKey(
							c.AccountId,
							c.FirstName,
							c.LastName,
							null,
							c.Email,
							c.Phone);
						Contact c2 = missingContactByKey.get(key);
						if(c2 != null && c2.Id != null) {
							// Store the contact under the hash value we need, even
							// though this not the hash code we have.  None of the fields match
							// except the account and e-mail address, but that is considered to be
							// close enough...
							contactHashMap.put(c.Hash__c,c2);
							neededContactByHash.remove(c2.Hash__c);
						}
					}
					System.debug(missingContactByKey);
				}
			}
			if(subLines != null) {
				for( SubscriptionLine__c subLine : subLines ) {
					if( subLine.AlreadyRenewed__c != true 
						&& subLine.DnrFlag__c != true
						&& subLine.NfrFlag__c != true
						&& subLine.EntitleToContact__c == null
						&& (isTesting || subLine.EntitleToEBSAccount__c != null)
						&& subLine.EntitleToSalesAccount__c != null
						&& subLine.EntitleToContactEmail__c != null )
					{
						Contact c = getContact(
							contactHashMap,
							subLine.EntitleToSalesAccount__c,
							subLine.EntitleToContactFirstName__c,
							subLine.EntitleToContactLastName__c,
							subLine.EntitleToContactName__c,
							subLine.EntitleToContactEmail__c,
							subLine.EntitleToContactPhone__c);
						if(c != null && c.Id != null) {
							//subLine.EntitleToContact__r = c;
							subLine.EntitleToContact__c = c.Id;
						}
					}
				}
			}
			for( Subscription__c sub : readyList ) {
				System.debug('sub.Id='+sub.Id);
				if( sub.BillToContact__c == null
					&& (isTesting || sub.BillToEBSAccount__c != null)
					&& sub.BillToSalesAccount__c != null
					&& sub.BillToContactEmail__c != null )
				{
					Contact c = getContact(
						contactHashMap,
						sub.BillToSalesAccount__c,
						sub.BillToContactFirstName__c,
						sub.BillToContactLastName__c,
						sub.BillToContactName__c,
						sub.BillToContactEmail__c,
						sub.BillToContactPhone__c);
					if(c != null && c.Id != null) {
						//sub.BillToContact__r = c;
						sub.BillToContact__c = c.Id; 
					}
				}
				if( sub.ShipToContact__c == null
					&& (isTesting || sub.ShipToEBSAccount__c != null)
					&& sub.ShipToSalesAccount__c != null
					&& sub.ShipToContactEmail__c != null)
				{
					Contact c = getContact(
						contactHashMap,
						sub.ShipToSalesAccount__c,
						sub.ShipToContactFirstName__c,
						sub.ShipToContactLastName__c,
						sub.ShipToContactName__c,
						sub.ShipToContactEmail__c,
						sub.ShipToContactPhone__c);
					if(c != null && c.Id != null) {
						//sub.ShipToContact__r = c;
						sub.ShipToContact__c = c.Id;
					}
				}
				if( sub.SoldToContact__c == null
					&& (isTesting || sub.SoldToEBSAccount__c != null)
					&& sub.SoldToSalesAccount__c != null
					&& sub.SoldToContactEmail__c != null )
				{
					Contact c = getContact(
						contactHashMap,
						sub.SoldToSalesAccount__c,
						sub.SoldToContactFirstName__c,
						sub.SoldToContactLastName__c,
						sub.SoldToContactName__c,
						sub.SoldToContactEmail__c,
						sub.SoldToContactPhone__c);
					if(c != null && c.Id != null) {
						//sub.SoldToContact__r = c;
						sub.SoldToContact__c = c.Id;
					}
				}
				if( sub.EntitleToContact__c == null
					&& (isTesting || sub.EntitleToEBSAccount__c != null)
					&& sub.EntitleToSalesAccount__c != null
					&& sub.EntitleToContactEmail__c != null )
				{
					Contact c = getContact(
						contactHashMap,
						sub.EntitleToSalesAccount__c,
						sub.EntitleToContactFirstName__c,
						sub.EntitleToContactLastName__c,
						sub.EntitleToContactName__c,
						sub.EntitleToContactEmail__c,
						sub.EntitleToContactPhone__c);
					if(c != null && c.Id != null) {
						//sub.EntitleToContact__r = c;
						sub.EntitleToContact__c = c.Id;
					}
				}
				if(sub.ShippingContact__c == null) {
					for(Contact c : getContacts(
						contactHashMap,
						new Set<Id>{ sub.ShipToSalesAccount__c, sub.Account__c },
						sub.ShipToContactFirstName__c,
						sub.ShipToContactLastName__c,
						sub.ShipToContactName__c,
						sub.ShipToContactEmail__c,
						sub.ShipToContactPhone__c) )
					{
						// sub.ShippingContact__r = c;
						sub.ShippingContact__c = c.Id;
						break;
					}
				}
				if(sub.SellingContact__c == null) {
					List<Contact> contacts = null;
					if(sub.SoldToContactEmail__c != null)
					{
						contacts = getContacts(
							contactHashMap,
							new Set<Id>{ sub.SoldToSalesAccount__c, sub.Account__c },
							sub.SoldToContactFirstName__c,
							sub.SoldToContactLastName__c,
							sub.SoldToContactName__c,
							sub.SoldToContactEmail__c,
							sub.SoldToContactPhone__c);
					}
					else if( sub.EntitleToContactEmail__c != null
						&& ( sub.SoldToAccountNumber__c == null
							|| sub.SoldToAccountNumber__c == sub.EntitleToAccountNumber__c ) )
					{
						contacts = getContacts(
							contactHashMap,
							new Set<Id>{ sub.EntitleToSalesAccount__c, sub.Account__c },
							sub.EntitleToContactFirstName__c,
							sub.EntitleToContactLastName__c,
							sub.EntitleToContactName__c,
							sub.EntitleToContactEmail__c,
							sub.EntitleToContactPhone__c);
					}
					if(contacts != null) {
						for(Contact c : contacts) {
							System.debug('Selling hash='+c.Hash__c);
							// sub.SellingContact__r = c;
							sub.SellingContact__c = c.Id;
							break;
						}
					}
				}
			}
		}
	}

	/**
	 * This method is called from the Subscription_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Subscription__c objects as in Trigger.oldMap.
	 * @param xnewList the list of new Subscription__c objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,Subscription__c> xoldMap,List<Subscription__c> xnewList) {
		SubscriptionTriggerAfter.readyIds.clear();
		final SubscriptionTriggerBefore beforeTrigger = new SubscriptionTriggerBefore(xoldMap,xnewList);
		SubscriptionTriggerAfter.queriedSubscriptionLines = null;
		if(AbstractTrigger.isActive(CLEAR_ERRORS_SETTING,true)) {
			beforeTrigger.clearErrorsWhenReady();
		}
//depreciated		if(AbstractTrigger.isActive(ASSIGN_BATCH_SETTING,true)) {
//depreciated			beforeTrigger.assignBatch();
//depreciated		}
		if(AbstractTrigger.isActive(ASSIGN_COMPOSITE_KEY_SETTING,true)) {
			beforeTrigger.assignCompositeKey();
		}
		if(AbstractTrigger.isActive(ASSIGN_REGION_SETTING,true)) {
			beforeTrigger.assignRegion();
		}
		if(AbstractTrigger.isActive(SYNC_ACCOUNT_SETTING,true)) {
			beforeTrigger.syncAccountFields();
		}
		if(AbstractTrigger.isActive(AGGREGATE_SUBSCRIPTION_LINES_SETTING,true)) {
			beforeTrigger.aggregateSubscriptionLines();
		}
		if(AbstractTrigger.isActive(UPDATE_STATUS_SETTING,true)) {
			beforeTrigger.updateStatuses();
		}
		if(AbstractTrigger.isActive(UPDATE_SUBSCRIPTION_LINES_SETTING,true)) {
			beforeTrigger.updateFromSubscriptionLines();
		}
		if(AbstractTrigger.isActive(SYNC_ASSIGN_TO_SETTING,true)) {
			beforeTrigger.syncAssignToFields();
		}
		if(AbstractTrigger.isActive(SYNC_CAMPAIGN_SETTING,true)) {
			beforeTrigger.syncCampaignFields();
		}
		if(AbstractTrigger.isActive(SYNC_ORIGINAL_OPPORTUNITY_SETTING,true)) {
			beforeTrigger.syncOriginalOpportunityFields();
		}
		if(AbstractTrigger.isActive(SSI_OPT_IN_SETTING,true)) {
			beforeTrigger.ssiOptIn();
		}
		if(AbstractTrigger.isActive(MAP_CONTACTS_SETTING,true)) {
			beforeTrigger.mapContacts();
		}
		if(AbstractTrigger.isActive(MAP_RESELLER_PARTNER_SETTING,true)) {
			beforeTrigger.mapResellerPartner();
		}
		if(AbstractTrigger.isActive(MATCH_ACCOUNTS_SETTING,true)) {
			beforeTrigger.matchAccounts();
		}
		AbstractTrigger.processTriggerComplete();
	}
}