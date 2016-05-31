/**
 * Controller class to manage products and lookup pricing.
 *
 * @version 2015-11-17
 *
 * @author Bryan Bosely <bbosely@redhat.com>
 * Bill Riemers <briemers@redhat.com>
 * 2015-11-17 - Only change unit price when updated by more than a penny.
 * 2015-10-29 - New methods allow warnings prior to deactivating a quote
 * 2015-10-05 - Updated to allow unit price to be updated for forecasting.
 * 2015-10-05 - Stability improvements (tech dept)
 * 2015-08-26 - Exclude inactive ebs accounts and contacts
 * 2014-04-02 - Added field for deactivating configured skus and updated opp lock for $0 orders
 * 2012-07-12 - Added methods to determine number formatting
 * 2012-07-11 - Some refactoring and adding of comments.
 * 2012-07-09 - Added override reason.
 * Scott Coleman <scoleman@redhat.com>
 * 2013-07-15 - Implemented Opp Lock
 * 2015-08-07 - Applied fix for defect when deleting products related to pagination and probability > 0 (US72156)
 * Pankaj Banik <pbanik@redhat.com>
 * 2014-07-21  - Removed error for Price overide reason
 * Chandan Prusty <cprusty@redhat.com>
 * 2014-10-27  - Added logic for displaying Line Item details in tabs. Introduced logic to display discount codes and discount value.
 * 2015-04-22 - Change to apply a filter to exclude Partner record types while querying Entitle To Sales Account
 * 2015-05-15 - Changes as per US66981 implementation of Pagination
 * Sagar Mehta <smehta@redhat.com>
 */
public class Opportunity_ProductPricingController{
	/** A string containing the no override reason value. */
	public static final String NO_OVERRIDE_REASON = 'No Override Reason';

	/** Approved picklist value */
	public static final String APPROVED_PLV = 'Approved';

	/** Finance picklist value */
	public static final String FINANCE_PLV = 'Finance';

	/** Use configured SKU's setting */
	public static final String USE_CONFIGURED_SKUS_SETTING = 'Use Configured SKUs';

//depreciated	/** A copy of the opportunity being managed. */
//depreciated	private Opportunity origOpportunity = null;
	private String origPriceOverrideReason = null;
	private String origQuoteNumber = null;

//depreciated	/** Boolean value for setting number of related Big Machine Quotes */
//depreciated	public Boolean bigMachineQuotes = false;

	/**Added on 24-Nov-2014 for ICC recordtype check */
	public Boolean isICCOpportunityRecord {
		get { return (opportunity.RecordType.DeveloperName == 'ICC'); }
	}

	public Boolean isForecastAllowed {
		get { 
			return opportunity.Deal_Registration__c != true 
				&& opportunity.Deal_Registration_Fed_Sled__c != true
				&& opportunity.OpportunityType__c != OrderManagementControllerExtension.REBOOK_PLV
				&& ( opportunity.FulfillmentChannel__c == OrderManagementControllerExtension.Direct_Reseller
					|| opportunity.FulfillmentChannel__c == OrderManagementControllerExtension.DIRECT_END_CUSTOMER_PLV
					|| opportunity.FulfillmentChannel__c == OrderManagementControllerExtension.Distributor
					|| opportunity.FulfillmentChannel__c == OrderManagementControllerExtension.OEM_PLV);
		}
	}

	/** Integer storing current displayed page of line items */
	public Integer lineNo {
		get {
			if(lineNo != 0) {
				if( lineNo == null || lineNo < 0 || pageNo <= 1) {
					lineNo = 0;
				}
				else if(lineNo >= pageNo - 1 ) {
					lineNo = pageNo - 1;
				}
			}
			return lineNo;
		}
		set;
	}

	/** Integer Storing total no of pages of line items */
	public Integer pageNo {
		get;
		set;
	}

	private List < List < PricingLineItem >> displayListLines = null;
	
	private void setDisplayListLines(List < List < PricingLineItem >> value ) {
		displayListLines = value;
		pageNo = 0;
		lineNo = 0;
		if(value != null) {
			pageNo = value.size();
		}
	}

	/** Map of list of lineitems for pagination */
	public List < List < PricingLineItem >> getDisplayListLines() { //US66981
		List < List < PricingLineItem >> retval = displayListLines;
		if(retval == null) {
			retval = new List< List< PricingLineItem> >();
			try {
				Integer rowsPerPage = 200;
				ManageProductsPageSetting__c setting = ManageProductsPageSetting__c.getInstance('RowsPerPage');
				if(setting != null) {
					rowsPerPage = Integer.valueOf(setting.RowsPerPage__c);
				}
				Integer i = rowsPerPage;
				List< PricingLineItem > displayLines = null;
				for(OpportunityLineItem oppLineItem : opportunity.OpportunityLineItems) {
					if( ++i >= rowsPerPage) {
						i = 0;
						displayLines = new List< PricingLineItem >();
						retval.add(displayLines);
					}
					displayLines.add(new PricingLineItem(oppLineItem));
				}
			}
			finally {
				setDisplayListLines( retval );
			}
		}
		return retval;
	}

	/** List to display the list of lineitems of the current selected page */
	public List < PricingLineItem > getLineItems() {
		List< PricingLineItem> lineItems = new List<PricingLineItem>();
		try {
			final List< List< PricingLineItem> > pricingLineItems = getDisplayListLines();
			if(! pricingLineItems.isEmpty()) {
				lineItems = pricingLineItems[ lineNo ];
			}
			System.debug('LineItems: '+lineItems);
		}
		catch(Exception ex) {
			ApexPages.addMessages(ex);
		}
		return lineItems;
	}//US66981

	/** Flag to enable/disable Next button */
	public Boolean getDisableNext() {
		return (lineNo >= pageNo - 1);
	}//US66981

	/** Flag to enable/disable Previous button */
	public Boolean getDisablePrevious() {
		return (pageNo <= 0 || lineNo <= 0);
	}//US66981

	/** Flag to enable/disable First button */
	public Boolean getDisableFirst() {
		return (lineNo == 0);
	}

	/** Flag to enable/disable Last button */
	public boolean getDisableLast() {
		return (lineNo == pageNo - 1);
	}

	/**
	 * constructor
	 */
	public Opportunity_ProductPricingController() {
		if (isOppLocked) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.Opp_Lock_Message));
		}
	}

	public Boolean getIsPartnerUser() {
		User me = [select Contact.AccountId from User where Id = : Userinfo.getUserId()];
		return me.Contact != null && me.Contact.AccountId != null;
	}

	/**
	 * Determine the decimal character in the current local.
	 *
	 * @return decimal character
	 */
	public String getDecimal() {
		return 1.11.format().replaceAll('1', '');
	}

	/**
	 * Determine the thousands separator character in the current local.
	 *
	 * @return thousand separator character
	 */
	public String getThousandsSep() {
		return 111111111.11.format()
			.replaceAll('1', '')
			.replaceAll('[' + getDecimal() + ']', '')
			.subString(0, 1);
	}

	private Opportunity assignOpportunityValues(Opportunity opp) {
		origPriceOverrideReason = null;
		origQuoteNumber = null;
		setDisplayListLines(null);
		lineItem = null;
		if(opp != null) {
			origPriceOverrideReason = opp.PriceOverrideReason__c;
			origQuoteNumber = opp.QuoteNumber__c;
			System.debug('origQuoteNumber='+origQuoteNumber);
			if(opp.QuoteNumber__c != null
				&& (opp.Quotes__r == null || opp.Quotes__r.isEmpty())
				&& (opp.BigMachines__BigMachines_Quotes__r == null || opp.BigMachines__BigMachines_Quotes__r.isEmpty()))
			{
				opp.QuoteNumber__c = null;
				System.debug('opp.QuoteNumber__c='+opp.QuoteNumber__c);
			}
//depreciated				//Code to set boolean based on number of bigmachine quotes
//depreciated				if (opportunity.BigMachines__BigMachines_Quotes__r.size() > 0) {
//depreciated					bigMachineQuotes = true;
//depreciated				}
			// code to deal with applications that only set the opportunity level value
			if (origPriceOverrideReason != null && origPriceOverrideReason != NO_OVERRIDE_REASON) {
				for (OpportunityLineItem xlineItem: opp.OpportunityLineItems) {
					if (xlineItem.PriceOverrideReason__c == null && xlineItem.Base_Price__c != null && xlineItem.UnitPrice != null) {
						if (xlineItem.Base_Price__c > xlineItem.UnitPrice) {
							xlineItem.PriceOverrideReason__c = origPriceOverrideReason;
						}
					}
				}
			}
		}
		return opp;
	}

	/**
	 * the opportunity being managed
	 */
	public Opportunity opportunity {
		get {
			if (opportunity == null) {
				// get the opportunity details
				opportunity = assignOpportunityValues( [
					select
						CurrencyIsoCode,
						IsLockedForSales__c,
						Name,
						Deal_Registration__c,
						Deal_Registration_Fed_Sled__c,
						FulfillmentChannel__c,
						Probability,
						Pricebook2Id,
						PriceOverrideReason__c,
						OpportunityType__c,
						QuoteNumber__c,
						RecordType.DeveloperName,
						StageName,
						Entitle_To_Account__c,
						Entitle_To_Account__r.Name,
						Entitle_To_Address__r.Address_Line1__c,
						Entitle_To_Address__r.Address_Line2__c,
						Entitle_To_Address__r.City__c,
						Entitle_To_Address__r.State__c,
						Entitle_To_Address__r.Province__c,
						Entitle_To_Address__r.Country__c,
						Entitle_To_Address__r.Zip_Postal_Code__c,
						Entitle_To_Address__r.County__c,
						Entitle_To_Address__c,
						Entitle_To_Address__r.Name,
						Entitle_To_Contact__c,
						Entitle_To_Contact__r.Name,
						Entitle_To_Contact__r.LoginName__c,
						Entitle_To_Sales_Account__c,
						Entitle_To_Sales_Account__r.Name,
						(	select
								Base_Price__c,
								Configured_SKU__c,
								Contract_Numbers__c,
								CurrencyIsoCode,
								Description,
								NewOrRenewal__c,
								Opportunity.Name,
								Opportunity.CurrencyIsoCode,
								PricebookEntryId,
								PricebookEntry.Name,
								PricebookEntry.Product2.Description,
								PricebookEntry.Pricebook2Id,
								PricebookEntry.ProductCode,
								PricebookEntry.UnitPrice,
								PriceOverrideReason__c,
								Quantity,
								UnitPrice,
								TotalPrice,
								Adjusted_Price__c,
								Discretionary_Discount_Amount__c,
								One_time_Discount_Amount__c,
								Price_After_Discretionary_Discount__c,
								Price_After_One_Time_Discount__c,
								Entitle_To_Account__c,
								Entitle_To_Account__r.Name,
								Entitle_To_Address__c,
								Entitle_To_Address__r.Address_Line1__c,
								Entitle_To_Address__r.Address_Line2__c,
								Entitle_To_Address__r.City__c,
								Entitle_To_Address__r.State__c,
								Entitle_To_Address__r.Province__c,
								Entitle_To_Address__r.Country__c,
								Entitle_To_Address__r.Zip_Postal_Code__c,
								Entitle_To_Address__r.County__c,
								Entitle_To_Contact__c,
								Entitle_To_Contact__r.Name,
								Entitle_To_Contact__r.LoginName__c,
								Entitle_To_Sales_Account__c,
								Entitle_To_Sales_Account__r.Name,
								ActualEndDate__c,
								ActualStartDate__c,
								Oracle_Price_Adjustments__c
							from OpportunityLineItems 
							order by CreatedDate),
					(	select Id from Quotes__r where IsActive__c != false),
					(	select id from BigMachines__BigMachines_Quotes__r where BigMachines__Is_Primary__c != false)
				from Opportunity
				where Id = : opportunityId ] );
			}
			return opportunity;
		}
		private set {
			opportunity = assignOpportunityValues( value );
		}
	}

	/**
	 * The new lineItem being created.
	 */
	public OpportunityLineItem lineItem {
		get {
			if (lineItem == null) {
				lineItem = new OpportunityLineItem(OpportunityId = opportunityId);
			}
			return lineItem;
		}
		private set;
	}

	/**
	 * get the opportunity.Id
	 */
	public Id opportunityId {
		get {
			if (opportunityId == null) {
				// grab the opportunity id from the parameters
				opportunityId = ApexPages.currentPage().getParameters().get('id');
				System.debug('Opportunity_ProductPricingController: opportunity id: ' + opportunityId);
				opportunity = null;
			}
			return opportunityId;
		}
		private set;
	}

	/** Used to query the current user. */
	public static User currentUser {
		get {
			if (currentUser == null) {
				currentUser = [
					select Job_Function__c
					from User
					where Id = : UserInfo.getUserId()
				];
			}
			return currentUser;
		}
		set;
	}

	public Boolean useConfiguredSKUs {
		get {
			if (useConfiguredSKUs == null) {
				BooleanSetting__c setting = BooleanSetting__c.getInstance(USE_CONFIGURED_SKUS_SETTING);
				useConfiguredSKUs = (setting != null) && (setting.Value__c == true) && (0 != [
					SELECT count()
					FROM Product2
					WHERE IsActive = true and
					Configurable__c = true LIMIT 1
				]);
			}
			return useConfiguredSKUs;
		}
		set;
	}

	public Boolean isOppLocked {
		get {
			Boolean oppLocked = false;
			AdminByPass__c bypass = AdminByPass__c.getInstance();
			if (bypass != null) {
				oppLocked = opportunity.IsLockedForSales__c && !bypass.IsOppAdmin__c && (bypass.IsSalesUser__c || (opportunity.StageName == APPROVED_PLV && currentUser.Job_Function__c != FINANCE_PLV));
			}
			return oppLocked;
		}
	}

	public Pricebook2 globalPricebook {
		get {
			if (globalPricebook == null) {
				// query SFDC for the global pricebook id
				globalPricebook = [
					select Id from Pricebook2
					where Name = 'Global Price Book'
					limit 1
				];
			}
			return globalPricebook;
		}
		private set;
	}

	public List < SelectOption > getPriceOverrideReasonOptions() {
		List < Schema.PicklistEntry > entries = OpportunityLineItem.PriceOverrideReason__c.getDescribe().getPicklistValues();
		List < SelectOption > options = new List < SelectOption > {
			new SelectOption('', '--None--', true)
		};
		for (Schema.PickListEntry entry: entries) {
			if (entry.getValue() != NO_OVERRIDE_REASON) {
				options.add(new SelectOption(entry.getValue(), entry.getLabel()));
			}
		}
		return options;
	}

	/**
	 * get an options list for new or renewal
	 */
	public List < SelectOption > getNewOrRenewalOptions() {
		List < Schema.PicklistEntry > entries = OpportunityLineItem.NewOrRenewal__c.getDescribe().getPicklistValues();
		List < SelectOption > options = new List < SelectOption > ();
		for (Schema.PicklistEntry entry: entries) {
			options.add(new SelectOption(entry.getValue(), entry.getLabel()));
		}
		return options;
	}

	public String getRegion() {
		User me = [select ContactId from User where Id = : UserInfo.getUserId()];
		if (me.ContactId != null) {
			me = [select Contact.Account.Global_Region__c from User where Id = : UserInfo.getUserId()];
			return me.Contact.Account.Global_Region__c;
		}
		return '';
	}

	static void setOverrideReason(Opportunity opportunity, OpportunityLineItem lineItem) {
		if (lineItem.base_price__c != null) {
			if (lineItem.base_price__c <= lineItem.UnitPrice) {
				lineItem.PriceOverrideReason__c = NO_OVERRIDE_REASON;
			} else if (lineItem.PriceOverrideReason__c == null || lineItem.PriceOverrideReason__c == null || lineItem.PriceOverrideReason__c == NO_OVERRIDE_REASON) {
				lineItem.PriceOverrideReason__c = opportunity.PriceOverrideReason__c;
				if (opportunity.PriceOverrideReason__c == NO_OVERRIDE_REASON) {
					lineItem.PriceOverrideReason__c = null;
				}
			}
			if (opportunity.PriceOverrideReason__c == null || (lineItem.PriceOverrideReason__c != NO_OVERRIDE_REASON && opportunity.PriceOverrideReason__c == NO_OVERRIDE_REASON)) {
				opportunity.PriceOverrideReason__c = lineItem.PriceOverrideReason__c;
			}
		} else {
			lineItem.PriceOverrideReason__c = null;
		}
	}

	public static void updateOverrideReasons(Opportunity opportunity, List < PricingLineItem > lineItems) {
		Boolean needsOverrideReason = true;
		System.debug('1. opportunity.PriceOverrideReason__c=' + opportunity.PriceOverrideReason__c);
		// find out if we can still use the current reason
		if (opportunity.PriceOverrideReason__c != null && opportunity.PriceOverrideReason__c != NO_OVERRIDE_REASON) {
			for (PricingLineItem pricingLineItem: lineItems) {
				if (!pricingLineItem.isBeingRemoved) {
					needsOverrideReason = needsOverrideReason && (opportunity.PriceOverrideReason__c != pricingLineItem.opportunityLineItem.PriceOverrideReason__c);
				}
			}
		}
		// find out what no reason we can use
		if (needsOverrideReason) {
			opportunity.PriceOverrideReason__c = null;
			for (PricingLineItem pricingLineItem: lineItems) {
				if (!pricingLineItem.isBeingRemoved) {
					setOverrideReason(opportunity, pricinglineItem.opportunityLineItem);
				}
			}
			System.debug('2. opportunity.PriceOverrideReason__c=' + opportunity.PriceOverrideReason__c);
		}
		if (opportunity.PriceOverrideReason__c != null) {
			// assign the new reason to any line item that needs one
			for (PricingLineItem pricingLineItem: lineItems) {
				if (!pricingLineItem.isBeingRemoved) {
					setOverrideReason(opportunity, pricinglineItem.opportunityLineItem);
				}
			}
		}
		System.debug('3. opportunity.PriceOverrideReason__c=' + opportunity.PriceOverrideReason__c);
	}

	/**
	 * add an opportunity line item
	 */
	public PageReference addProduct() {

		final Id pricebookEntryId = lineItem.PricebookEntryId;
		if (pricebookEntryId == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
				'Please use the product lookup dialog to select a product code'));
		} else {
			Savepoint sp = null;
			try {
				// set the product description
				PricebookEntry priceBookEntry = [
					select
					Product2.Description
					from PricebookEntry
					where Id = : pricebookEntryId limit 1
				];
				lineItem.Description = priceBookEntry.Product2.Description;
				lineItem.Entitle_To_Account__c = opportunity.Entitle_To_Account__c;
				lineItem.Entitle_To_Address__c = opportunity.Entitle_To_Address__c;
				lineItem.Entitle_To_Contact__c = opportunity.Entitle_To_Contact__c;
				lineItem.Entitle_To_Sales_Account__c = opportunity.Entitle_To_Sales_Account__c;
				lineItem.Base_Price__c = 0;
				lineItem.Adjusted_Price__c = 0;
				sp = Database.setSavepoint();
				insert lineItem;
				deactivateQuotes();
				sp = null;
			} catch (Exception e) {
				ApexPages.addMessages(e);
			} finally {
				// refresh the pricing line items, lineItem, and opportunity
				opportunity = null;
				if (sp != null) {
					Database.rollback(sp);
				}
			}
		}
		return null;
	}

	public Boolean getNeedsDeactivateQuotesConfirmation() {
		return (origQuoteNumber != null 
			|| (opportunity.Quotes__r != null && ! opportunity.Quotes__r.isEmpty())
			|| (opportunity.BigMachines__BigMachines_Quotes__r != null && !opportunity.BigMachines__BigMachines_Quotes__r.isEmpty()));
	}

	/**
	 * add a configured product
	 */
	public PageReference addConfiguredProduct() {
		String configuredSku = lineItem.Configured_SKU__c;
		if (configuredSku == '' || configuredSKU == null) {
			ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a configured sku.');
			ApexPages.addMessage(msg);

			return null;
		}
		Savepoint sp = null;
		try {
			// look up the base sku for the configured sku and attributes from the pricing service
			Opportunity_PricingService ops = new Opportunity_PricingService();
			Opportunity_PricingService.ProductResult results = ops.getProductInfo(configuredSku);
			System.Debug('Pricing Service Results: ' + results);

			if (results.statusCode == 'ERROR') {
				ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to find the sku ' + configuredSku + ', please try again');
				ApexPages.addMessage(msg);

				return null;
			}

			String baseSku = results.baseSKU;
			String attributes = results.attributes;
			String description = results.description;

			// look up the pricebook entry id for the base sku
			PricebookEntry priceBookEntry = [
				select Id from PricebookEntry
				where Product2.Configurable__c = true
				and CurrencyIsoCode = : opportunity.CurrencyIsoCode
				and pricebook2Id = : globalPricebook.Id
				and productCode = : basesku
				limit 1
			];

			// add the new opportunity line item to the opportunity
			lineItem.PricebookEntryId = priceBookEntry.Id;
			// response is somtimes too long - next line commented out to
			//   resolve production issue on 10 July 2012
			// lineItem.Pricing_Attributes__c = attributes;
			lineItem.Description = description;
			sp = Database.setSavepoint();
			insert lineItem;
			deactivateQuotes();
			sp = null;

		} catch (Exception e) {
			ApexPages.addMessages(e);
		} finally {
			// refresh the pricing line items, lineItem, and opportunity
			opportunity = null;
			if (sp != null) {
				Database.rollback(sp);
			}
		}
		return null;
	}


	/**
	 * cancel
	 */
	public PageReference cancel() {
		PageReference page = new PageReference('/' + opportunityId);
		page.setRedirect(true);

		return page;
	}

	public static Set<String> deactivateQuotesOnChangeFieldPaths {
		get {
			if(deactivateQuotesOnChangeFieldPaths == null) {
				deactivateQuotesOnChangeFieldPaths = new Set<String>();
				for(String fieldPath : OpportunityLineItemTriggerAfter2.deactivateQuotesOnChangeMap.keySet()) {
					deactivateQuotesOnChangeFieldPaths.add(fieldPath.toLowerCase());
				}
			}
			return deactivateQuotesOnChangeFieldPaths;
		}
		set;
	}

	/**
	 * Check if there are fields updated by the pricing call that may deactivate a quote.
	 * 
	 * @return true if the quote will probably be deactivated on save after get pricing is called
	 */
	public Boolean getPricingWillDeactivateQuotes() {
		Boolean retval = deactivateQuotesOnChangeFieldPaths.contains('adjusted_price__c')
			|| deactivateQuotesOnChangeFieldPaths.contains('base_price__c')
			|| deactivateQuotesOnChangeFieldPaths.contains('oracle_price_adjustments__c')
			|| deactivateQuotesOnChangeFieldPaths.contains('priceoverridereason__c');
		if(! retval) {
			for (List<PricingLineItem> pricingLineItems : getDisplayListLines()) {
				if (pricingLineItems != null) {
					for (PricingLineItem pricingLineItem: pricingLineItems) {
						if (pricingLineItem.opportunityLineItem.Discretionary_Discount_Amount__c == 0 && pricingLineItem.opportunityLineItem.One_time_Discount_Amount__c == 0) {
							retval = deactivateQuotesOnChangeFieldPaths.contains('unitprice');
							if(retval) {
								break;
							}
						}
					}
				}
			}
		}
		return retval;
	}

	/**
	 * Check if there are fields updated by the copy entite to call that will deactivate a quote.
	 * 
	 * @return true if the quote will be deactivated on save after copy entitle to is called
	 */
	public Boolean getCopyEntitleToWillDeactivateQuotes() {
		Boolean retval = false;
		for (List<PricingLineItem> pricingLineItems : getDisplayListLines()) {
			if (pricingLineItems != null) {
				for (PricingLineItem lineItemInst: pricingLineItems) {
					if (String.isBlank(lineItemInst.entitleAccountName)
						&& String.isBlank(lineItemInst.entitleSalesAccountName)
						&& String.isBlank(lineItemInst.entitleAddressName)
						&& String.isBlank(lineItemInst.entitleContactName) )
					{
						retval = (entitleToAccountWillDeactivateQuotes && lineItemInst.opportunityLineItem.Entitle_To_Account__c != opportunity.Entitle_To_Account__c)
							|| (entitleToSalesAccountWillDeactivateQuotes && lineItemInst.opportunityLineItem.Entitle_To_Sales_Account__c != opportunity.Entitle_To_Sales_Account__c)
							|| (entitleToAddressWillDeactivateQuotes && lineItemInst.opportunityLineItem.Entitle_To_Contact__c != opportunity.Entitle_To_Contact__c)
							|| (entitleToContactWillDeactivateQuotes && lineItemInst.opportunityLineItem.Entitle_To_Address__c != opportunity.Entitle_To_Address__c);
						if(retval) {
							break;
						}
					}
				}
			}
		}
		return retval;
	}

	/**
	 * Check if there are fields updated by the clear entite to call that will deactivate a quote.
	 * 
	 * @return true if the quote will be deactivated on save after clear entitle to is called
	 */
	public Boolean getClearEntitleToWillDeactivateQuotes() {
		Boolean retval = false;
		for (List<PricingLineItem> pricingLineItems : getDisplayListLines()) {
			if (pricingLineItems != null) {
				for (PricingLineItem lineItemInst: pricingLineItems) {
					retval = (entitleToAccountWillDeactivateQuotes && lineItemInst.opportunityLineItem.Entitle_To_Account__c != null)
						|| (entitleToSalesAccountWillDeactivateQuotes && lineItemInst.opportunityLineItem.Entitle_To_Sales_Account__c != null)
						|| (entitleToContactWillDeactivateQuotes && lineItemInst.opportunityLineItem.Entitle_To_Contact__c != null)
						|| (entitleToAddressWillDeactivateQuotes && lineItemInst.opportunityLineItem.Entitle_To_Address__c != null);
					if(retval) {
						break;
					}
				}
			}
		}
		return retval;
	}

	/**
	 * True if modifying a sales price will deactivate quotes on save.
	 */
	public Boolean unitPriceWillDeactivateQuotes { get {
		return deactivateQuotesOnChangeFieldPaths.contains('unitprice');
	}}

	/**
	 * True if modifying the new or renewal flag will deactivate quotes on save.
	 */
	public Boolean newOrRenewalWillDeactivateQuotes { get {
		return deactivateQuotesOnChangeFieldPaths.contains('neworrenewal__c');
	}}

	/**
	 * True if modifying the contract numbers will deactivate quotes on save.
	 */
	public Boolean contractNumbersWillDeactivateQuotes { get {
		return deactivateQuotesOnChangeFieldPaths.contains('contract_numbers__c');
	}}

	/**
	 * True if modifying an entitle-to account will deactivate quotes on save.
	 */
	public Boolean entitleToAccountWillDeactivateQuotes { get {
		return deactivateQuotesOnChangeFieldPaths.contains('entitle_to_account__c');
	}}

	/**
	 * True if modifying an entitle-to sales account will deactivate quotes on save.
	 */
	public Boolean entitleToSalesAccountWillDeactivateQuotes { get {
		return deactivateQuotesOnChangeFieldPaths.contains('entitle_to_sales_account__c');
	}}

	/**
	 * True if modifying an entitle-to address will deactivate quotes on save.
	 */
	public Boolean entitleToAddressWillDeactivateQuotes { get {
		return deactivateQuotesOnChangeFieldPaths.contains('entitle_to_address__c');
	}}

	/**
	 * True if modifying an entitle-to contact will deactivate quotes on save.
	 */
	public Boolean entitleToContactWillDeactivateQuotes { get {
		return deactivateQuotesOnChangeFieldPaths.contains('entitle_to_contact__c');
	}}


	/**
	 * Call the pricing web service
	 */
	public PageReference pricing() {
		try {
			// call the pricing web service
			Opportunity_PricingService ops = new Opportunity_PricingService();
			Map < String, Opportunity_PricingService.Result > results = ops.getOpportunityPricing(opportunityId);
			System.Debug('Pricing Service Results: ' + results);

			Boolean firstError = true;
			for (List<PricingLineItem> pricingLineItems : getDisplayListLines()) {
				if (pricingLineItems != null) {
					for (PricingLineItem pricingLineItem: pricingLineItems) {
						// update the line item status code, and the unit price for pricing line items
						Opportunity_PricingService.Result result = results.get(pricingLineItem.opportunityLineItem.Id);
//depreciated						pricingLineItem.isUpdated = true;
						pricingLineItem.lineItemStatus = result.lineItemStatusCode;
						pricingLineItem.lineItemStatusMsg = result.lineItemStatusMsg;
						//pricingLineItem.listPrice = Decimal.valueOf(util.formatCurrency(result.unitPrice));
						if (String.isNotBlank(result.unitPriceNew)) {
							pricingLineitem.opportunityLineItem.Adjusted_Price__c = Decimal.valueof(result.unitPriceNew);
						}
						if (String.isNotBlank(result.unitListPrice)) {
							pricingLineitem.opportunityLineItem.base_price__c = Decimal.valueof(result.unitListPrice);
						}
						if (pricingLineItem.opportunityLineItem.Discretionary_Discount_Amount__c == 0 && pricingLineItem.opportunityLineItem.One_time_Discount_Amount__c == 0 && String.isNotBlank(result.unitPriceNew)) {
							pricingLineitem.opportunityLineItem2.unitPrice = pricingLineitem.opportunityLineItem.unitPrice = Decimal.valueof(result.unitPriceNew);
						}
						system.debug('++++++++++++++' + pricingLineitem.opportunityLineItem.unitPrice + '///////////' + result.unitPrice);
						if (result.discount != null && !result.discount.isEmpty()) {
							pricingLineitem.codeDiscountAmountList.clear();
							pricingLineitem.opportunityLineItem.Oracle_Price_Adjustments__c = null;
							//loop throug the price list from the result
							for (Opportunity_PricingService.Discount priceListRecord: result.discount) {
								pricingLineitem.codeDiscountAmountList.add(priceListRecord.code + '-' + priceListRecord.description + ':' + priceListRecord.value);
								// add incoming price list to Oracle_Price_Adjustments__c field as comma seperated values.
								if (String.isBlank(pricingLineitem.opportunityLineItem.Oracle_Price_Adjustments__c)) {
									pricingLineitem.opportunityLineItem.Oracle_Price_Adjustments__c = priceListRecord.code + ' - ' + priceListRecord.description + ':' + priceListRecord.value;
								} else {
									pricingLineitem.opportunityLineItem.Oracle_Price_Adjustments__c = pricingLineitem.opportunityLineItem.Oracle_Price_Adjustments__c + ',' + priceListRecord.code + ' - ' + priceListRecord.description + ':' + priceListRecord.value;
								}
							}
						}
						if (pricingLineItem.opportunityLineItem.base_price__c != null) {
							// determine if the price returned from the pricing service matches
							// what the rep has in SFDC
							if (pricingLineItem.opportunityLineItem.UnitPrice != pricingLineItem.opportunityLineItem.base_price__c) {
								pricingLineItem.isListPriceUnequal = true;
							}
							if (pricingLineItem.opportunityLineItem.UnitPrice == null || pricingLineItem.opportunityLineItem.UnitPrice >= pricingLineItem.opportunityLineItem.base_price__c) {
								pricingLineItem.opportunityLineItem.PriceOverrideReason__c = NO_OVERRIDE_REASON;
							}
						}

						// add failure messages to the page
						if (pricingLineItem.lineItemStatus == 'FAILURE') {
							// add header message if this is our first failure
							if (firstError) {
								firstError = false;
								ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,
									'The pricing call did not successfully complete due to the following error(s). ' +
									'Please submit a Momentum ticket and be sure to include the error message so that this issue can be quickly resolved.'));
							}
							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
								pricingLineItem.lineItemStatusMsg));
						}
					}
				}
			}
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,
				'The pricing call could not be processed at this time. Please wait and try again.' + e +
				' If the problem persists, please submit a Momentum ticket and be sure ' +
				'to include the above error message so that this issue can be quickly resolved.'));
		}
		return null;
	}

	/**
	 * Deactivate all quotes.
	 */
	public void deactivateQuotes() {
		for (Quote__c quote: opportunity.Quotes__r) {
			quote.IsActive__c = false;
		}
		update opportunity.Quotes__r;
		for (BigMachines__Quote__c bmQuote : opportunity.BigMachines__BigMachines_Quotes__r) {
			bmQuote.BigMachines__Is_Primary__c = false;
		}
		update opportunity.BigMachines__BigMachines_Quotes__r;
		if (origQuoteNumber != null || opportunity.PriceOverrideReason__c != origPriceOverrideReason) {
			origQuoteNumber = opportunity.QuoteNumber__c = null;
			update opportunity;
		}
	}

	private List<PricingLineItem> getPricingLineItems() {
		List<PricingLineItem> retval = new List<PricingLineItem>();
		for(List<PricingLineItem> pricingLineItems : getDisplayListLines()) {
			if(pricingLineItems != null) {
				for(PricingLineItem pricingLineItem : pricingLineItems) {
					// this will update the unit price from opportunityLineItem2
					pricingLineItem.unitPriceUpdated();
				}
				retval.addAll(pricingLineItems);
			}
		}
		return retval;
	}

	/**
	 * save
	 */
	public PageReference save() {
		PageReference page = null;
		Savepoint sp = null;
		try {
			List<PricingLineItem> pricingLineItems = getPricingLineItems();
			updateOverrideReasons(opportunity,pricingLineItems);
			List < OpportunityLineItem > opportunityLineItems = opportunity.OpportunityLineItems;
			if (! opportunityLineItems.isEmpty()) {
				sp = Database.setSavepoint();
				update opportunityLineItems;
				System.debug('opportunityLineItems' + opportunityLineItems);
				if(unitPriceWillDeactivateQuotes && (origQuoteNumber != null || opportunity.PriceOverrideReason__c != origPriceOverrideReason)) {
					for(PricingLineItem pricingLineItem : pricingLineItems) {
						if(pricingLineItem.unitPriceUpdated()) {
							deactivateQuotes();
							break;
						}
					}
				}
			}
			opportunity = null;
			if(opportunity.QuoteNumber__c == null) {
				if(origQuoteNumber != null) {
					update opportunity;
				}
			}
			sp = null;
			page = new PageReference('/' + opportunityId);
			page.setRedirect(true);
		} catch (Exception e) {
			ApexPages.addMessages(e);
		} finally {
			if (sp != null) {
				opportunity = null;
				Database.rollback(sp);
			}
		}
		return page;
	}


	/**
	 * Remove selected products
	 */
	public PageReference remove() {
		Savepoint sp = null;
		try {
			// retrieve the OpportunityLineItems from the PricingLineItems and delete them
			List < OpportunityLineItem > opportunityLineItems = new List < OpportunityLineItem > ();
			for(List<PricingLineItem> pricingLineItems : getDisplayListLines()) {
				if(pricingLineItems != null) {
					for (PricingLineItem pricingLineItem : pricingLineItems) {
						if (pricingLineItem.isBeingRemoved || pricingLineItem.isBeingRemovedSecTab || pricingLineItem.isBeingRemovedTrdTab) {
							opportunityLineItems.add(pricinglineItem.opportunityLineItem);
						}
					}
				}
			}
			System.Debug('Items being removed' + opportunityLineItems.size());

			if (!opportunityLineItems.isEmpty()) {
				sp = Database.setSavepoint();
				delete opportunityLineItems;
				deactivateQuotes();
				// I do not understand why we are calling the updateOverrideReason method.
				String priceOverrideReason = opportunity.PriceOverrideReason__c;
				opportunity = null;
				opportunity.PriceOverrideReason__c = priceOverrideReason;
				List < PricingLineItem > lineItems = getLineItems();
				updateOverrideReasons(opportunity, lineItems);

				// Check if we are now in an invalid state
				if (Util.adminByPass(true) || !(lineItems == null || lineItems.isEmpty()) || opportunity.Probability == 0 || origQuoteNumber != null) {
					// no need to rollback
					sp = null;
				}
				if (sp != null) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,
						'When opportunity probability is greater than zero you must have at least one line item.'));
				}
			}
		} catch (System.DMLException e) {
			ApexPages.addMessages(e);
		} finally {
			if (sp != null) {
				Database.rollback(sp);
				opportunity = null;
			}
		}
		return null;
	}

	/**
	 * Method to copy Entitle-to info from Opportunity (US63517)
	 */
	public void copyEntitleToInfo() {
		//US66981
		//Added logic to incorporate Map of lists logic and to read data and update the map of lists
		for (List<PricingLineItem> pricingLineItems : getDisplayListLines()) {
			if (pricingLineItems != null) {
				for (PricingLineItem lineItemInst: pricingLineItems) {
					if (String.isBlank(lineItemInst.entitleAccountName)
						&& String.isBlank(lineItemInst.entitleSalesAccountName)
						&& String.isBlank(lineItemInst.entitleAddressName)
						&& String.isBlank(lineItemInst.entitleContactName) )
					{
						lineItemInst.opportunityLineItem.Entitle_To_Account__r = opportunity.Entitle_To_Account__r;
						lineItemInst.opportunityLineItem.Entitle_To_Account__c = opportunity.Entitle_To_Account__c;
						lineItemInst.opportunityLineItem.Entitle_To_Sales_Account__r = opportunity.Entitle_To_Sales_Account__r;
						lineItemInst.opportunityLineItem.Entitle_To_Sales_Account__c = opportunity.Entitle_To_Sales_Account__c;
						lineItemInst.opportunityLineItem.Entitle_To_Contact__r = opportunity.Entitle_To_Contact__r;
						lineItemInst.opportunityLineItem.Entitle_To_Contact__c = opportunity.Entitle_To_Contact__c;
						lineItemInst.opportunityLineItem.Entitle_To_Address__r = opportunity.Entitle_To_Address__r;
						lineItemInst.opportunityLineItem.Entitle_To_Address__c = opportunity.Entitle_To_Address__c;
						lineItemInst.entitleAccountName = null;
						lineItemInst.entitleSalesAccountName = null;
						lineItemInst.entitleContactName = null;
						lineItemInst.entitleAddressName = null;
						lineItemInst.rhnEntitlementLogin = null;
					}
				}
			}
		}
	}

	/**
	 * Method to clear Entitle-to info on the line items (US67343)
	 */
	public void clearEntitleToInfo() {
		for (List<PricingLineItem> pricingLineItems : getDisplayListLines()) {
			if (pricingLineItems != null) {
				for (PricingLineItem lineItemInst: pricingLineItems) {
					lineItemInst.opportunityLineItem.Entitle_To_Account__r = null;
					lineItemInst.opportunityLineItem.Entitle_To_Account__c = null;
					lineItemInst.opportunityLineItem.Entitle_To_Sales_Account__r = null;
					lineItemInst.opportunityLineItem.Entitle_To_Sales_Account__c = null;
					lineItemInst.opportunityLineItem.Entitle_To_Contact__r = null;
					lineItemInst.opportunityLineItem.Entitle_To_Contact__c = null;
					lineItemInst.opportunityLineItem.Entitle_To_Address__r = null;
					lineItemInst.opportunityLineItem.Entitle_To_Address__c = null;
					lineItemInst.entitleAccountName = null;
					lineItemInst.entitleSalesAccountName = null;
					lineItemInst.entitleContactName = null;
					lineItemInst.entitleAddressName = null;
					lineItemInst.rhnEntitlementLogin = null;
				}
			}
		}
	}

	public static String blankValue(String value,String defaultValue) {
		if(String.isBlank(value)) {
			value = defaultValue;
		}
		return value;
	}

	public static String concatValue(String value1,String sep,String value2) {
		String retval = '';
		if(String.isNotBlank(value1)) {
			retval = value1;
			if(String.isNotBlank(value2)) {
				retval += sep + value2;
			}
		}
		else if(String.isNotBlank(value2)) {
			retval = value2;
		}
		return retval;
	}

	/**
	 * creating a new object to add an attribute to the opportunity line item
	 */
	public class PricingLineItem {
		public OpportunityLineItem opportunityLineItem {
			get {
				if(opportunityLineItem != null
					&& opportunityLineItem2 != null 
					&& (opportunityLineItem2.UnitPrice == null
						|| opportunityLineItem.UnitPrice == null 
						|| opportunityLineItem2.UnitPrice != opportunityLineItem.UnitPrice.divide(1,2,System.RoundingMode.HALF_EVEN)) )
				{
					opportunityLineItem.UnitPrice = opportunityLineItem2.UnitPrice;
				}
				return opportunityLineItem;
			}
			private set;
		}
		OpportunityLineItem opportunityLineItem2 = null;
		public OpportunityLineItem getOpportunityLineItem2() {
			if(opportunityLineItem2 == null && opportunityLineItem != null) {
				Decimal unitPrice = opportunityLineItem.UnitPrice;
				if(unitPrice != null) {
					unitPrice = unitPrice.divide(1,2,System.RoundingMode.HALF_EVEN);
				}
				opportunityLineItem2 = new OpportunityLineItem(UnitPrice=unitPrice);
			}
			return opportunityLineItem2;
		}
		public Decimal unitPrice {
			get;
			private set;
		}
		public String entitleAccountName {
			get {
				if(entitleAccountName == null) {
					entitleAccountName = '';
					if(opportunityLineItem.Entitle_To_Account__r != null) {
						entitleAccountName = blankValue(opportunityLineItem.Entitle_To_Account__r.Name,'');
					}
				}
				return entitleAccountName;
			}
			set;
		}
		public String entitleSalesAccountName {
			get {
				if(entitleSalesAccountName == null) {
					entitleSalesAccountName = '';
					if(opportunityLineItem.Entitle_To_Sales_Account__r != null) {
						entitleSalesAccountName = blankValue(opportunityLineItem.Entitle_To_Sales_Account__r.Name,'');
					}
				}
				return entitleSalesAccountName;
			}
			set;
		}
		public string entitleAddressName {
			get {
				if(entitleAddressName == null) {
					entitleAddressName = '';
					Address__c a = opportunityLineItem.Entitle_To_Address__r;
					if(a != null) {
						entitleAddressName = blankValue(a.Address_Line1__c,'');
						// entitleAddressName = concatValue(entitleAddressName,', ',a.Address_Line2__c);
						entitleAddressName = concatValue(entitleAddressName,', ',a.City__c);
						entitleAddressName = concatValue(entitleAddressName,', ',a.County__c);
						entitleAddressName = concatValue(entitleAddressName,', ',a.State__c);
						entitleAddressName = concatValue(entitleAddressName,', ',a.Province__c);
						entitleAddressName = concatValue(entitleAddressName,', ',a.Country__c);
						entitleAddressName = concatValue(entitleAddressName,', ',a.Zip_Postal_Code__c);
					}
				}
				return entitleAddressName;
			}
			set;
		}
		public string entitleContactName {
			get {
				if(entitleContactName == null) {
					entitleContactName = '';
					if(opportunityLineItem.Entitle_To_Contact__r != null) {
						entitleContactName = blankValue(opportunityLineItem.Entitle_To_Contact__r.Name, '');
					}
				}
				return entitleContactName;
			}
			set;
		}
		public List < string > codeDiscountAmountList {
			get {
				if(codeDiscountAmountList == null) {
					codeDiscountAmountList = new List<String>();
					if(String.isNotBlank(opportunityLineItem.Oracle_Price_Adjustments__c)) {
						codeDiscountAmountList.addAll(opportunityLineItem.Oracle_Price_Adjustments__c.split(','));
						System.debug('LIST_VAL' + codeDiscountAmountList.size());
					}
				}
				return codeDiscountAmountList;
			}
			set;
		}
		public String rhnEntitlementLogin {
			get {
				if(rhnEntitlementLogin == null) {
					rhnEntitlementLogin = '';
					if(opportunityLineItem.Entitle_To_Contact__r != null) {
						rhnEntitlementLogin = blankValue(opportunityLineItem.Entitle_To_Contact__r.LoginName__c, '');
					}
				}
				return rhnEntitlementLogin;
			}
			set;
		}

		public PricingLineItem(OpportunityLineItem lineItem) {
			codeDiscountAmountList = new List < String > ();
			opportunityLineItem = lineItem;
			getOpportunityLineItem2();
			unitPrice = lineItem.unitPrice;
			System.debug('Opportunity Line Item is -----' + lineItem);
		}

		public String lineItemStatus {
			get;
			set;
		}
		public String lineItemStatusMsg {
			get;
			set;
		}
		//public Decimal listPrice { get; set; }
		public Boolean isBeingRemoved {
			get { return (isBeingRemoved == true); }
			set;
		}
		public Boolean isBeingRemovedSecTab {
			get { return (isBeingRemovedSecTab == true); }
			set;
		}
		public Boolean isBeingRemovedTrdTab {
			get { return (isBeingRemovedTrdTab == true); }
			set;
		}
		public Boolean isListPriceUnequal {
			get;
			set;
		}
		public Boolean isOverrideReasonRequired {
			get {
				return opportunityLineItem.Base_Price__c != null;
			}
			set;
		}
		public String priceOverrideReason {
			get {
				priceOverrideReason = opportunityLineItem.PriceOverrideReason__c;
				if (priceOverrideReason == null || priceOverrideReason == NO_OVERRIDE_REASON) {
					priceOverrideReason = '';
				}
				return priceOverrideReason;
			}
			set {
				opportunityLineItem.PriceOverrideReason__c = priceOverrideReason = value;
				if (value == '') {
					opportunityLineItem.PriceOverrideReason__c = null;
				}
			}
		}
		Boolean unitPriceUpdated() {
			return (unitPrice != opportunityLineItem.UnitPrice);
		}
	}

	public static String orderDetailsJSON {
		get;
		set;
	} // JSON string property

	// Remote method to get all salesaccounts
	@RemoteAction
	public static string salesAccountSearch(string AccName) {
		String AccountToBeSearched = AccName;
		List < OrderDetailsWrapper > OrderDetailsWrapperList = new List < OrderDetailsWrapper > ();
		for (Account a: [
			select
				EBS_Account_Numbers__c,
				RecordType.Name,
				RecordType.DeveloperName,
				Id,
				Name,
				BillingStreet,
				BillingCity,
				AccountClassification__c,
				BillingState,
				BillingCountry,
				BillingPostalCode,
				CDH_Party_Name__c,
				CDH_Party_Name__r.name,
				Owner.Name,
				phone,
				fax
			from Account where Name like: '%' + AccountToBeSearched + '%'
			limit 999 ] )
		{
			if (a.Id != null && !a.RecordType.DeveloperName.contains('Partner')) {
				OrderDetailsWrapper odw = new OrderDetailsWrapper();
				odw.RecId = string.valueOf(a.Id);
				odw.RecName = a.Name;
				odw.Phone = a.Phone != null ? a.phone : '';
				odw.Fax = a.Fax != null ? a.Fax : '';
				odw.RecordType = a.RecordType.Name; //added as per US63409
				odw.EbsAcc = a.EBS_Account_Numbers__c != null ? a.EBS_Account_Numbers__c : ''; //added as per US64739
				odw.Classification = a.AccountClassification__c != null ? a.AccountClassification__c : '';
				odw.AccBillingAddress = a.BillingStreet != null ? a.BillingStreet : '';
				odw.AccBillingAddress += a.BillingCity != null ? ', ' + a.BillingCity : '';
				odw.AccBillingAddress += a.BillingState != null ? ', ' + a.BillingState : '';
				odw.AccBillingAddress += a.BillingCountry != null ? ', ' + a.BillingCountry : '';
				odw.AccBillingAddress += a.BillingPostalCode != null ? a.BillingPostalCode : '';
				odw.PartyNumber = a.CDH_Party_Name__c != null ? a.CDH_Party_Name__r.Name : '';
				odw.OwnerName = a.Owner.Name;
				OrderDetailsWrapperList.add(odw);
			}
		}
		// return the JSON message
		OrderDetailsJSON = JSON.serialize(OrderDetailsWrapperList);
		return OrderDetailsJSON;
	}

		// Remote method to get EBS Accounts for the selected SalesAccount
	@RemoteAction
	public static string EBSAccountSearch(string accID) {
		List < OrderDetailsWrapper > OrderDetailsWrapperList = new List < OrderDetailsWrapper > ();
		for (EBS_Account__c e: [
			select Id,
				Name,
				EBS_Party_Number__c,
				EBS_Account_Description__c,
				EBS_Party_Name__c,
				Primary_EBS_Account__c
			from EBS_Account__c
			where Sales_Account__c = : accID and Status__c != 'Inactive'
			order by Primary_EBS_Account__c])
		{
			if (e.id != null) {
				OrderDetailsWrapper odw = new OrderDetailsWrapper();
				odw.RecId = String.valueOf(e.Id);
				odw.RecName = e.Name;
				odw.Description = e.EBS_Account_Description__c != null ? e.EBS_Account_Description__c : '';
				odw.PartyNumber = e.EBS_Party_Number__c != null ? e.EBS_Party_Number__c : '';
				odw.PartyName = e.EBS_Party_Name__c != null ? e.EBS_Party_Name__c : '';
				odw.BillTo = e.Primary_EBS_Account__c == true ? 'checked' : 'false';
				/*if(odw.BillTo == 'checked'){
					OrderDetailsWrapperListChecked.add(odw) ;
				}
				else if(odw.BillTo == 'false'){
					OrderDetailsWrapperListUnChecked.add(odw) ;
				}*/
				OrderDetailsWrapperList.add(odw);
			}
		}
		// return the JSON string
		OrderDetailsJSON = JSON.serialize(OrderDetailsWrapperList);
		return OrderDetailsJSON;
	}

		// Remote method to get Address for the selected salesaccount
	@RemoteAction
	public static string AddressSearch(string accID) {
		List < OrderDetailsWrapper > OrderDetailsWrapperList = new List < OrderDetailsWrapper > ();
		for (Address__c e: [
			select Id,
				Name,
				Address_Line1__c,
				Address_Line2__c,
				CDH_Party_Site_Number__c,
				Bill_To_Address__c,
				Entitle_To_Address__c,
				Sold_To_Address__c,
				Ship_To_Address__c,
				Province__c,
				Zip_Postal_Code__c,
				Country__c,
				State__c,
				City__c
			from Address__c
			where Sales_Account__c = : accID and Status__c = 'Active' ] )
		{
			if (e.id != null) {
				OrderDetailsWrapper odw = new OrderDetailsWrapper();
				odw.RecId = string.valueOf(e.Id);
				odw.RecName = e.Address_Line1__c != null ? e.Address_Line1__c : '';
				odw.RecName += e.City__c != null ? ', ' + e.City__c : '';
				odw.RecName += e.State__c != null ? ', ' + e.State__c : '';
				odw.RecName += e.Province__c != null ? ', ' + e.Province__c : '';
				odw.RecName += e.Zip_Postal_Code__c != null ? ' ' + e.Zip_Postal_Code__c : '';
				odw.AddressOne = e.Address_Line1__c != null ? e.Address_Line1__c : '';
				odw.AddressTwo = e.Address_Line2__c != null ? e.Address_Line2__c : '';
				odw.partySiteNumber = e.CDH_Party_Site_Number__c != null ? e.CDH_Party_Site_Number__c : '';
				odw.AddressNumber = e.Name != null ? e.Name : '';
				odw.City = e.City__c != null ? e.City__c : '';
				odw.State = e.State__c != null ? e.State__c : '';
				odw.Province = e.Province__c != null ? e.Province__c : '';
				odw.Country = e.Country__c != null ? e.Country__c : '';
				odw.zipPostal = e.Zip_Postal_Code__c != null ? e.Zip_Postal_Code__c : '';
				odw.BillTo = e.Bill_To_Address__c == true ? 'checked' : 'false';
				odw.ShipTo = e.Ship_To_Address__c == true ? 'checked' : 'false';
				odw.EntitleTo = e.Entitle_To_Address__c == true ? 'checked' : 'false';
				odw.SoldTo = e.Sold_To_Address__c == true ? 'checked' : 'false';
				OrderDetailsWrapperList.add(odw);
			}
		}
		// return JSON String
		OrderDetailsJSON = JSON.serialize(OrderDetailsWrapperList);
		return OrderDetailsJSON;
	}

	// Remote method to get Contacts for the selected salesaccount
	@RemoteAction
	public static string ContactSearch(string accID) {
		List < OrderDetailsWrapper > OrderDetailsWrapperList = new List < OrderDetailsWrapper > ();
		for (Contact e: [
			select Id,
				Name,
				FirstName,
				LastName,
				Email,
				Department,
				Phone,
				CDH_Party__r.Name,
				LoginName__c
			from Contact
			where AccountId = : accID and Status__c != 'Inactive' ] )
		{
			if (e.id != null) {
				OrderDetailsWrapper odw = new OrderDetailsWrapper();
				odw.RecId = string.valueOf(e.Id);
				odw.firstName = e.firstName != null ? e.firstName : '';
				odw.lastName = e.lastName;
				odw.RecName = e.Name;
				odw.Email = e.email != null ? e.Email : '';
				odw.contactPhone = e.Phone != null ? e.Phone : '';
				odw.Department = e.Department != null ? e.Department : '';
				odw.contactPartyNumber = e.CDH_Party__r.Name != null ? e.CDH_Party__r.Name : '';
				odw.rhnEntitlementLogin = e.LoginName__c;
				OrderDetailsWrapperList.add(odw);
			}
		}
		// return JSON String
		OrderDetailsJSON = JSON.serialize(OrderDetailsWrapperList);
		return OrderDetailsJSON;
	}

	// Wrapper class for getting details in the visualforce page.
	public with sharing class OrderDetailsWrapper {
		public String RecId {
			get;
			set;
		}
		public String RecName {
			get;
			set;
		}
		public String PartyNumber {
			get;
			set;
		}
		public String OwnerName {
			get;
			set;
		}
		public String Country {
			get;
			set;
		}
		public String RecordType {
			get;
			set;
		} //added as per US63409
		public string EbsAcc {
			get;
			set;
		}
		public String State {
			get;
			set;
		}
		public String City {
			get;
			set;
		}
		public String lastName {
			get;
			set;
		}
		public String firstName {
			get;
			set;
		}
		public String Email {
			get;
			set;
		}
		public String Phone {
			get;
			set;
		}
		public String Fax {
			get;
			set;
		}
		public String AccBillingAddress {
			get;
			set;
		}
		public String PartyName {
			get;
			set;
		}
		public String AddressOne {
			get;
			set;
		}
		public String Province {
			get;
			set;
		}
		public String BillTo {
			get;
			set;
		}
		public String ShipTo {
			get;
			set;
		}
		public String EntitleTo {
			get;
			set;
		}
		public String SoldTo {
			get;
			set;
		}
		public String zipPostal {
			get;
			set;
		}
		public String Classification {
			get;
			set;
		}
		public String Description {
			get;
			set;
		}
		public String Department {
			get;
			set;
		}
		public String contactPhone {
			get;
			set;
		}
		public String contactPartyNumber {
			get;
			set;
		}
		public String AddressTwo {
			get;
			set;
		}
		public String partySiteNumber {
			get;
			set;
		}
		public String AddressNumber {
			get;
			set;
		}
		public String rhnEntitlementLogin {
			get { return rhnEntitlementLogin != null? rhnEntitlementLogin : ''; }
			set;
		}
	}


	/*
	* returns the next page of records 
	*/
	public PageReference Next() {
		lineNo++;
		return null;
	}

	/*
	* returns the previous page of records
	*/
	public PageReference Previous() {
		lineNo = lineNo--;
		return null;
	}

	/*
	* returns the first page of records
	*/
	public PageReference first() {
		lineNo = 0;
		return null;
	}

	/*
	* returns the last page of records
	*/
	public PageReference last() {
		lineNo = pageNo - 1;
		return null;
	}
	//End of Changes
}