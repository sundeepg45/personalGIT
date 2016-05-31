/**
 * ApprovalCustom_ControllerExtension
 *
 * @version 2013-01-29
 * @author Unknown
 * 2011-12-05 Created
 * Scott Coleman <scoleman@redhat.com>
 * 2012-10-02 - Added proxy approver property
 * 2013-01-29 - Now populating Opportunity_Amount__c on generated Credit__c records
 */
public with sharing class ApprovalCustom_ControllerExtension {
	public static final String CURRENCY_ISO_CODE_FIELD = 'CurrencyIsoCode';
	public static final String PRODUCT_CODE_FIELD = 'ProductCode';
	public static final String BM_QUOTE_OBJECT = 'BigMachines__Quote__c';
	public static final String BM_QUOTE_FIELD = 'BigMachines_Quote__c';
	public static final String BM_ACCOUNT_REF = 'BigMachines__Account__r';
	public static final String BM_OPPORTUNITY_REF = 'BigMachines__Opportunity__r';
	public static final String BM_DESCRIPTION_FIELD = 'BigMachines__Description__c';
	public static final String BM_NAME_FIELD = 'Name';
	public static final String BM_PAY_NOW_FIELD = 'BigMachines_Pay_Now__c';
	public static final String BM_CURRENCY_FIELD = 'CurrencyIsoCode';
	public static final String BM_TOTAL_AMOUNT_FIELD = 'BigMachines__Total_Amount__c';
	public static final String BM_OWNER_ID = 'OwnerId';
	public static final String BM_QUOTE_PRODUCT_FIELD = 'BigMachines__BigMachines_Quote_Products__r';
	public static final String BM_QP_PRODUCT_REF = 'BigMachines__Product__r';
	public static final String BM_QP_CONFIGURED_SKU_FIELD = 'BigMachines_Configured_sku__c';
	public static final String BM_QP_DESCRIPTION_FIELD = 'BigMachines__Description__c';
	public static final String BM_QP_QUANTITY_FIELD = 'BigMachines__Quantity__c';
	public static final String BM_QP_SALES_PRICE_FIELD = 'BigMachines__Sales_Price__c';
	public static final String BM_QP_TOTAL_PRICE_FIELD = 'BigMachines__Total_Price__c';

	private Id approvalCustomId;
	private ApprovalCustom__c approvalCustom;
	private Account quoteAccount = null;
	private String quoteDescription = null;
	public Quote__c quote = null;
	private List<QuoteLineItem__c> quoteLineItems = new List<QuoteLineItem__c>();

	private static final String bmQuery = 
		'select'
		+'	'+BM_ACCOUNT_REF+'.Name'
		+	','+BM_OPPORTUNITY_REF+'.Country_of_Order__c'
		+	','+BM_OPPORTUNITY_REF+'.Name'
		+	','+BM_OPPORTUNITY_REF+'.Account.Name'
		+	','+BM_DESCRIPTION_FIELD
		+	','+BM_NAME_FIELD
		+	','+BM_PAY_NOW_FIELD
		+	','+BM_CURRENCY_FIELD
		+	','+BM_TOTAL_AMOUNT_FIELD
		+	','+BM_OWNER_ID
		+	', (	select '+CURRENCY_ISO_CODE_FIELD
		+				','+BM_QP_PRODUCT_REF+'.'+PRODUCT_CODE_FIELD
		+				','+BM_QP_CONFIGURED_SKU_FIELD
		+				','+BM_QP_DESCRIPTION_FIELD
		+				','+BM_QP_QUANTITY_FIELD
		+				','+BM_QP_SALES_PRICE_FIELD
		+				','+BM_QP_TOTAL_PRICE_FIELD
		+	'		from '+BM_QUOTE_PRODUCT_FIELD+' )'
		+' from '+BM_QUOTE_OBJECT
		+' where Id in (select '+BM_QUOTE_FIELD+' from ApprovalCustom__c where Id = :approvalCustomId )'
		+' limit 1';

	public ApprovalCustom_ControllerExtension(ApexPages.StandardController stdController) {
		approvalCustomId = stdController.getId();
		approvalCustom = (ApprovalCustom__c)stdController.getRecord();
	}

	public ApprovalCustom__c getApprovalCustom() {
		return approvalCustom;
	}

	public Boolean getIsBmQuote() {
		return (getQuote().Number__c == null);
	}

	public Account getQuoteAccount() {
		getQuote();
		return quoteAccount;
	}

	public String getQuoteDescription() {
		getQuote();
		return quoteDescription;
	}
	
	public Boolean getIsProxyApprover() {
		ProxyApprover__c proxySetting = ProxyApprover__c.getInstance();
		return (proxySetting.IsProxyApprover__c == true 
					&& approvalCustom.assignApprovalTo__c != UserInfo.getUserId()
					&& approvalCustom.RecordType.Name == 'Pricing Discount');
	}

	public List<QuoteLineItem__c> getQuoteLineItems() {
		getQuote();
		return quoteLineItems;
	}

	public Id quoteId {
		get {
			if(quote == null) {
				getQuote();
			}
			return quoteId;
		}
		set;
	}

	public Quote__c getQuote() {
		if(quote == null) {
			quoteAccount = null;
			quoteDescription = null;
			for(Quote__c q : [
				select
					OpportunityId__r.Account.Name
					, OpportunityId__r.Country_of_Order__c
					, OpportunityId__r.Name
					, Name
					, Number__c
					, PayNow__c
					, CurrencyIsoCode
					, Amount__c
					, QuoteOwnerId__r.Name
					, (	select CurrencyIsoCode
							, ProductCode__c
							, Configured_SKU__c
							, ProductDescription__c
							, Quantity__c
							, UnitPrice__c
							, TotalPrice__c
						from QuoteLineItem__r )
				from Quote__c
				where Id in (select Quote__c from ApprovalCustom__c where Id= :approvalCustomId)
				limit 1 ] )
			{
				quoteId = q.Id;
				quote = q;
				if(quote.OpportunityId__r != null) {
					quoteAccount = quote.OpportunityId__r.Account;
				}
				if(quote.QuoteLineItem__r != null) {
					quoteLineItems.addAll(quote.QuoteLineItem__r);
				}
			}
			if(quote == null) {
				quote = new Quote__c();
				try {
					System.debug(bmQuery);
					for(SObject bmQuote : Database.Query(bmQuery)) {
						quoteId = bmQuote.Id;
						quote.OpportunityId__r = (Opportunity)bmQuote.getSObject(BM_OPPORTUNITY_REF);
						quote.Name = (String)bmQuote.get(BM_NAME_FIELD);
						quote.PayNow__c = 'No';
						if((Boolean)bmQuote.get(BM_PAY_NOW_FIELD) == true) {
							quote.PayNow__c = 'Yes';
						}
						quote.CurrencyIsoCode = (String)bmQuote.get(BM_CURRENCY_FIELD);
						quote.Amount__c = (Decimal)bmQuote.get(BM_TOTAL_AMOUNT_FIELD);
						for(User u : [select Name from User where Id = :(Id)bmQuote.get(BM_OWNER_ID)]) {
							quote.QuoteOwnerId__r = u;
						}
						quoteAccount = (Account)bmQuote.getSObject(BM_ACCOUNT_REF);
						quoteDescription = (String)bmQuote.get(BM_DESCRIPTION_FIELD);
						List<SObject> products = (List<SObject>)bmQuote.getSObjects(BM_QUOTE_PRODUCT_FIELD);
						if(products != null) {
							for(SObject product : products) {
								String productCode = null;
								SObject prod = product.getSObject(BM_QP_PRODUCT_REF);
								if(prod != null) {
									productCode = (String)prod.get(PRODUCT_CODE_FIELD);
								}
								quoteLineItems.add(new QuoteLineItem__c(
									CurrencyIsoCode = (String)product.get(CURRENCY_ISO_CODE_FIELD),
									ProductCode__c = productCode,
									Configured_SKU__c = (String)product.get(BM_QP_CONFIGURED_SKU_FIELD),
									ProductDescription__c = (String)product.get(BM_QP_DESCRIPTION_FIELD),
									Quantity__c = (Decimal)product.get(BM_QP_QUANTITY_FIELD),
									UnitPrice__c = (Decimal)product.get(BM_QP_SALES_PRICE_FIELD),
									TotalPrice__c = (Decimal)product.get(BM_QP_TOTAL_PRICE_FIELD)));
							}
						}
					}
				}
				catch(Exception e) {}
			}
		}
		return quote;
	}

	public List<SelectOption> assignApprovalToOptions {
		get {
			if(assignApprovalToOptions == null) {
				Boolean hasCurrentValue = false;
				assignApprovalToOptions = new List<SelectOption>();
				Id currentUserId = UserInfo.getUserId();
				for(User u : [
					select FirstName, LastName 
					from User
					where (Id = :currentUserId or AprvrPaymentTerms__c = true) and IsActive = true 
					order by LastName, FirstName ] )
				{
					hasCurrentValue = hasCurrentValue || (u.Id == approvalCustom.AssignApprovalTo__c);
					assignApprovalToOptions.add(new SelectOption(u.Id, u.LastName+', '+u.FirstName));
				}
				if(! hasCurrentValue) {
					approvalCustom.assignApprovalTo__c = currentUserId;
				} 
			}
			return assignApprovalToOptions;
		}
		set;
	}

	public PageReference save() {
		PageReference retval = null;
		if(approvalCustom.RecordType.Name == 'Payment Terms') {
			Id approvedBy = approvalCustom.ApprovedBy__c;
			SavePoint sp = Database.setSavepoint();
			try {
				Credit__c c = null;
				if(approvalCustom.ApprovalStatus__c == 'Approved') {
					if(approvalCustom.ApprovedBy__c == null) {
						approvalCustom.ApprovedBy__c = UserInfo.getUserId();
						Quote__c q = getQuote();
						if(q.Id == null) { // only create a credit check for big machines
							// don't create a credit check for excluded countries
							if(q.OpportunityId__r.Country_of_Order__c == null || ! OrderManagementControllerExtension.EXCLUDED_CREDIT_CHECK_COUNTRIES.contains(q.OpportunityId__r.Country_of_Order__c.toUpperCase()) )
							{
								c = new Credit__c(
									Account__c = q.OpportunityId__r.Account.Id,
									BillingAccountNameUsed__c = approvalCustom.BillingAccountNameApprovedOn__c,
									BillingAccountNumberUsed__c = approvalCustom.BillingAccountNumberApprovedOn__c,
									Comments__c = 'Approval Reason: Payment Team Approval Request Granted',
									Credit_Stage__c = 'Approved',
									Opportunity__c = q.OpportunityId__r.Id,
									Opportunity_Amount__c = q.Amount__c,
									Payment_Terms__c = approvalCustom.PaymentTermsApproved__c,
									RecordTypeId = [
										select Id
										from RecordType
										where Name ='Approval Created' and SObjectType = 'Credit__c' and IsActive = true
										limit 1].Id,
									Quote__c = q.Id );
								c.put(BM_QUOTE_FIELD,quoteId);
							}
						}
					}
				}
				else {
					approvalCustom.ApprovedBy__c = null;
				}
				update approvalCustom;
				if(c != null) {
					insert c;
				}
				retval = new PageReference('/'+quote.OpportunityId__r.Id);
				retval.setRedirect(true);
			}
			catch(Exception e) {
				ApexPages.addMessages(e);
				approvalCustom.ApprovedBy__c = approvedBy;
				Database.rollback(sp);
			}
		}
		return retval;
	}
}