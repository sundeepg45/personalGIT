/**
 * This class for the submit order process.
 * 
 * @version 2015-11-24
 * @author Bill C. Riemers
 * 2016-01-12 - Updated rules for CLP.  Now using custom settings.
 * 2015-08-26 - don't set touched US72618
 * 2015-08-26 - restored formatting, marked commented code as depreciated
 * 2014-04-09 - change zero dollar order to zero value opportunity
 * 2014-03-19 - Added rules 25 and 25.1 for $0 orders
 * 2013-11-13 - Remove Mexico from the list of excluded countries
 * 2013-08-16 - Added support for Services_Product_Line_6__c.
 * 2013-08-08 - Removed OpportunityTriggerBefore dependancy
 * 2013-07-24 - Added IDR currency.
 * 2013-03-01 - Added 18.6 back again with threshold.
 * 2013-02-21 - Temporarily disable rule 18.6
 * 2013-02-19 - Add support for MXN
 * 2012-12-07 - Added rule 18.5 to check the credit check currency
 * 2012-12-07 - Corrected rule 18.4 to return null when the rule is skipped
 * 2012-11-26 - Added rule 23, Refactored to reduce number of queries
 * 2012-10-03 - Removed updateCredit method
 * 2012-07-10 - Disabled rule 10, as no matching roles exist with SMR.
 * Scott Coleman <scoleman@redhat.com>
 * 2015-11-24 - Updating opportunity type value from "Co-Term" to "CoTerm"
 * 2015-03-22 - Added Colombia to the credit exclusion list
 * 2015-02-07 - Activate rules 19.0, 19.1, 19.2
 * 2015-02-06 - Deactivate rule 23.1
 * 2014-12-01 - Updated rule 5 to address DE7372
 * 2014-02-14 - Added Future Reporting Requirement rule 24.0
 * 2013-04-29 - Modified rule 18.4 to use most recent credit check like 18.5, 18.6
 * 2013-04-08 - Added null check to rule 18.6
 * 2013-01-29 - Added rule 18.6 to check the credit check amount
 * 2012-12-04 - Added rule 23.1 and moved Services SKU list into custom setting
 * 2012-10-19 - Updated rule 18.4 based on demo feedback, retired 18.3
 * 2012-09-15 - Added rule 18.4
 * 2012-09-13 - Retiring rule 10 (US23964)
 * 2012-08-30 - Merging in R12 stories
 * 2012-07-15 - Enabled rule 10 and updated to reference new User field Teamed__c
 * Anshul Kumar <ankumar@redhat.com>
 * 2104-11-04 - US58342 modified rule 5 & 18.4
 * Niti Bansal <nibansal@redhat.com>
 * 2015-01-16 - Modified UpdateOpportunity() Method and updateClosedWon() method
 * Niti Bansal <nibansal@redhat.com>
 * 2015-02-24 - Modified Rules 18, 18.1, 18.4, 18.5, & 18.6 to make credit check compulsory for Channel-Distributor as well
 */
public without sharing class OrderManagementControllerExtension
{
	public static final String MAX_DAYS_OLD_SETTING = 'CreditCheck.MaxDaysOld';
	public static Map<String,Integer> integerValueMap = new Map<String,Integer>{
		MAX_DAYS_OLD_SETTING => getIntegerValue(MAX_DAYS_OLD_SETTING,105) };

	// Opportunity.Service_Contract_Type__c values
	public static final String TIME_AND_MATERIALS_PLV='Time and Materials';
	public static final String FIXED_PRICE_PLV='Fixed Price';
	public static final List<String> SERVICES_CONTRACT_TYPE_VALUES = new List<String> {
		TIME_AND_MATERIALS_PLV, FIXED_PRICE_PLV };

	public static final String CONFIRM_MES = (
		'By claiming commission for this opportunity, I hereby certify that I understand and have '+
		'complied with Red Hat\'s commission requirements and policies, and that the content I submit '+
		'is accurate and complete to the best of my knowledge. I understand and agree that any failure '+
		'to comply with the standard set forth in this certification may result in disciplinary action '+
		'up to and including my dismissal.');
	public static final String ERROR1 = 'Error 1.0: You are not authorized to submit this Order.';

//depreciated	/* commented by nejaiswal@deloittec.com : comment out the below error on ‘Submit opportunity’ as the error is no longer valid as we are replacing the channel load with the interface.
//depreciated	 We need to change the opportunity to ‘Closed/Won’ only.

//depreciated	public static final String ERROR1_1 = 'Error 1.1: This order will be closed booked as part of the NA Channel Load process and cannot be closed using the Submit Order button.';
//depreciated	*/
	public static final String ERROR2 = 'Error 2.0: Please populate the following fields on the Opportunity:';
	public static final String ERROR2_1 = 'Error 2.1: A financial partner is required to submit this opportunity.';
	public static final String ERROR3 = 'Error 3.0: Please enter a PO Number.';
	public static final String ERROR3_1 = 'Error 3.1: Please enter a Billing Address.';
	public static final String ERROR3_2 = 'Error 3.2: Please enter a Shipping Address.';
	public static final String ERROR4 = 'Error 4.0: Please enter a VAT Number on the Account record.';
	public static final String ERROR5 = 'Error 5.0: This Opportunity is not eligible for annual payments.';
	public static final String ERROR5_1 = 'Error 5.1: This Opportunity is not eligible for annual payments.';
	public static final String ERROR6 = 'Error 6.0: Only a Year 1 Payment Amount is valid for this Opportunity.';

	public static final String ERROR7 = 'Error 7.0: Year 1 and Year 2 Payment Amounts are required for this Opportunity.';
	public static final String ERROR8 = 'Error 8.0: The sum of the Payment Amounts is not equal to the Opportunity Amount.';
	public static final String ERROR8_1 = 'Error 8.1: The sum of the Booking Schedule is not equal to the Opportunity Amount.';
	public static final String ERROR9 = 'Error 9.0: Please ensure the Sales Team on the Opportunity is up to date.';
	public static final String ERROR10_1 = 'Error 10.1: Please ensure a Channel Sales Manager has been identified.';
	public static final String ERROR11 = 'Error 11.0: Please add Products to the Opportunity.';
	public static final String ERROR12 = 'Error 12.0: Please enter a Contract Number for all Renewal Products.';
	public static final String ERROR12_1 = 'Error 12.1: Please enter a Contract Number for all Renewal Products.';

//depreciated	/* Commented by nejaiswal@deloitte.com :Reasons for commenting them out is Contact roles might not be used in future as we are using the 4 lookups for contact (Bill-To, Ship-To, Sold-To and Entitle-To).
//depreciated	public static final String ERROR13 = 'Error 13.0: Please designate one of the Contact Roles on the Opportunity as "Shipping Contact".';
//depreciated	public static final String ERROR14 = 'Error 14.0: Please designate one of the Contact Roles on the Opportunity as "Payables Contact".';
//depreciated	public static final String ERROR15 = 'Error 15.0: Please enter a RHN Entitlement Login and Email Address for the Shipping Contact.';
//depreciated	*/


	public static final String ERROR16 = 'Error 16.0: Please attach all required documents.';
	public static final String ERROR17 = 'Error 17.0: Contract Start Date cannot be over 60 days old.';
	public static final String ERROR18 = 'Error 18.0: There is no valid credit approval on this opportunity.	Please submit the opportunity for credit approval.';
	public static final String ERROR18_1 = 'Error 18.1: Please re-submit a Credit Check request.';


	public static final String ERROR19 = 'Error 19.0: Please activate a Quote for the Opportunity.';

	public static final String ERROR19_1 = 'Error 19.1: Please recalculate your quote. The quote Amount and first year booking must match the opportunity.';
	public static final String ERROR19_2 = 'Error 19.2: One or more products require a quote to be attached. Please create an active quote and resubmit.';
	public static final String ERROR20 = 'Error 20.0: Please obtain approval for the Active Quote prior to submitting the Order.';
	public static final String ERROR20_1 = 'Error 20.1: Please confirm the Payment Terms on the Credit Check record match the Active Quote.';
	//public static final String ERROR22 = 'Error 22: Please fill out "Origin Source Opp #" field.';

	//Added by nejaiswal@deloitte.com	error message to display an error when there is no field value.
	//public static final String ERROR26 = 'Error 26.0: Please populate the following fields on the Opportunity:';

	// Added by nejaiswal@deloitte.com : error message Validation rule to ensure that the Employee Number for the owner of the opportunity in the user record is populated when the order was submitted.
	public static final String ERROR27 ='Error 27.0: Employee Number is not present on user profile. Please enter your employee number and re-submit.';

	// Added by nejaiswal@deloitte.com to add validation for the address to check if they have cdh party number.
	public static final String ERROR28 ='Error 28.0: ';
	//public static final String ERROR29 ='Error 29.0: ';
	//public static final String ERROR30 ='Error 30.0: ';
	//public static final String ERROR31 ='Error 31.0: ';
	public static final String ERROR32 =' does not have a CDH Party Number populated. Please contact the Customer Data Team to synchronize the CDH information.';

	// Added by nejaiswal@deloitte.com to add validation for the address to check if they have cdh party number.
	public static final String ERROR33 ='Error 33.0: ';
	//public static final String ERROR34 ='Error 34.0: ';
	//public static final String ERROR35 ='Error 35.0: ';
	//public static final String ERROR36 ='Error 36.0: ';
	public static final String ERROR37 =' does not have a CDH Party Number populated. Please contact the Customer Data Team to synchronize the CDH information.';

	public static final String Error38_1 = 'Error 38.1: Bill-To EBS Account is mandatory. Please populate Bill-To EBS Account before submitting the opportunity for OM review.';
	public static final String Error38_1_NoSubmit = 'WARNING: Bill-To EBS Account is required for credit check';
	public static final String Error38_2 = 'Error 38.2: Bill-To Address is mandatory. Please populate Bill-To Address before submitting the opportunity for OM review.';
	public static final String Error38_2_NoSubmit = 'WARNING: Bill-To Address is required for the successful approval of a credit request';
//depreciated	/*public static final String Error39_1 = 'Error 39.1: Ship-To EBS Account is mandatory. Please populate Ship-To EBS Account before submitting the opportunity for OM review.';
//depreciated	public static final String Error39_2 = 'Error 39.2: Ship-To Address is mandatory. Please populate Ship-To Address before submitting the opportunity for OM review.';
//depreciated	public static final String Error40_1 = 'Error 40.1: Sold-To EBS Account is mandatory. Please populate Sold-To EBS Account before submitting the opportunity for OM review.';
//depreciated	public static final String Error40_2 = 'Error 40.2: Sold-To Address is mandatory. Please populate Sold-To Address before submitting the opportunity for OM review.';
//depreciated	public static final String Error41_1 = 'Error 41.1: Entitle-To EBS Account is mandatory. Please populate Entitle-To EBS Account before submitting the opportunity for OM review.';
//depreciated	public static final String Error41_2 = 'Error 41.2: Entitle-To Address is mandatory. Please populate Entitle-To Address before submitting the opportunity for OM review.';

//depreciated	public static final String Error42_1 = 'Error 42.1: Entitle-To EBS Account is not populated for one or more of the opportunity line items. Please populate Entitle-To EBS Account before submitting the opportunity for OM review.';
//depreciated	public static final String Error42_2 = 'Error 42.2: Entitle-To Address is not populated for one or more of the opportunity line items. Please populate Entitle-To Address before submitting the opportunity for OM review.';
//depreciated	*/

	public static final String ERROR00= 'This order has already been submitted';
	public static final String ERROR99= 'Error 99: An internal error occured. Please report the following information in your trouble ticket: ';
	public static final String MESSAGE_AC_ACTIVE = 'This Account is on a sale hold or is inactive. The order cannot be submitted';
	public static final String SUCCESS_MESSAGE = 'Your order was placed successfully';
	public static final String CORRECT_ERROR_MESSAGE = ('Please correct the items noted above. Once you have confirmed all opportunity detail is complete and accurate, please resubmit.');
	public static final String OPP_ORDER_MESSAGE = ('Please confirm the attached Purchase Order matches the Customer Information in Salesforce.com. Once confirmed, click "OK" button to submit the order.');


		// constants needed for submit order rules.
	public static final String APAC = 'APAC';
	public static final String EMEA = 'EMEA';
	public static final String LATAM = 'LATAM';
	public static final String NA = 'NA';
	public static final String CREDIT_CARD = 'Credit Card';
	public static final String PURCHASE_ORDER = 'Purchase Order';
	public static final String INSIDE_REP_STRING = 'INSIDE REP';
	public static final String OUTSIDE_REP_STRING = 'OUTSIDE REP';
	public static final String CHANNEL_ACCOUNT_MANAGER_STRING = 'CHANNEL ACCOUNT MANAGER';
	public static final String PAYMENT_TERMS = 'Payment Terms';
	public static final String NON_STANDARD = 'Non-Standard';
	public static final String PRICING_DISCOUNT = 'Pricing Discount';
	public static final String PAYABLES_CONTACT_PLV='Payables Contact';
	public static final String SHIPPING_CONTACT_PLV = 'Shipping Contact';
	public static final String MANAGEMENT_SERVICES_PLV='Management Services';
	public static final String PLATFORM_SERVICES_PLV='Platform Services';
	public static final String MIDDLEWARE_SERVICES_PLV='Middleware Services';
	public static final String DIRECT = 'Direct';
	public static final String NA_FED_SLED_RTN = 'NA Fed Sled';
	public static final String NA_SALES_FED_SLED_PN = 'NA Sales - FED SLED';
	public static final String NA_SALES_EDU_DLT_PN ='NA Sales - EDU DLT';

//depreciated	/*Commented this by Neha(nejaiswal@deloitte.com) as the part of the changes in picklist value of payment type.
//depreciated	//public static final String APAC_PURCHASE_ORDER = 'APAC Purchase Order';
//depreciated	//public static final String CHANNEL_FULFILLMENT = 'Channel Fulfillment';*/


	/**
	 * List of countries which require a VAT Number for rule 4.
	 */
	public static final Set<String> VAT_COUNTRIES = new Set<String>{
		'AUSTRIA', 'GB', 'GREAT BRITAIN', 'BELGIUM', 'DENMARK',
		'ESTONIA', 'FINLAND', 'FRANCE', 'GERMANY', 'GREECE',
		'HUNGARY', 'IRELAND', 'ITALY', 'LATVIA', 'LITHUANIA',
		'LUXEMBOURG', 'NETHERLANDS', 'POLAND', 'PORTUGAL',
		'SLOVAKIA', 'SLOVENIA', 'SPAIN', 'SWEDEN', 'UK',
		'UNITED KINGDOM', 'BULGARIA', 'CYPRUS', 'CZECH REPUBLIC',
		'MALTA'};

	/**
	 * List of countries which should by pass credit checks.
	 */
	public static Set<String> EXCLUDED_CREDIT_CHECK_COUNTRIES {
		get {
			if(EXCLUDED_CREDIT_CHECK_COUNTRIES == null) {
				EXCLUDED_CREDIT_CHECK_COUNTRIES = new Set<String>();
				StringSetting__c s = StringSetting__c.getInstance('OM.CreditCheck.ExcludeCountries');
				if(s != null && s.Value__c != null) {
					EXCLUDED_CREDIT_CHECK_COUNTRIES.addAll(s.Value__c.toUpperCase().split('\\s*,\\s*'));
				}
				EXCLUDED_CREDIT_CHECK_COUNTRIES.remove('');
			}
			return EXCLUDED_CREDIT_CHECK_COUNTRIES;
		}
		private set;
	}

	//admin profiles
	public static final String SYS_ADMIN_PN = 'System Administrator';
	public static final String NA_SALES_ADMIN_PN = 'NA Sales Administrator';
	public static final String EMEA_SALES_ADMIN_PN = 'EMEA Sales Admin';
	public static final String SYS_ADMIN_LVL1_PN = 'Systems Administrator - Level 1';
	public static final String GLOBAL_LVL1_PN = 'Global Level 1';
	public static final String GLOBAL_LVL2_PN = 'Global Level 2';
	public static final String GLOBAL_LVL3_PN = 'Global Level 3';

//depreciated	/*Commented this code by Neha(nejaiswal@deloitte.com) as part of the changes in the picklist value of opportunity type.
//depreciated	// Opportunity.opportunityType__c picklist values
//depreciated	public static final String COTERM_PLV = 'Co-Term';
//depreciated	public static final String HOSTING_PLV = 'Hosting';
//depreciated	public static final String HOSTING_INITIAL_PLV = 'Hosting - Initial';
//depreciated	public static final String OM_EXCEPTION_PLV = 'OM Exception';
//depreciated	public static final String REBOOK_PLV = 'REBOOK';
//depreciated	public static final String ROYALTY_PLV = 'Royalty';
//depreciated	public static final String ROYALTY_EMEA_PLV = 'Royalty - EMEA';
//depreciated	public static final String STANDARD_PLV = 'Standard';

//depreciated	//Deleted some of these variables if not present in the picklist variables of opportunity type.
//depreciated	public static final List<String> OPPORTUNITYTYPE_VALUES = new List<String> {
//depreciated		COTERM_PLV, HOSTING_PLV, HOSTING_INITIAL_PLV, OM_EXCEPTION_PLV, REBOOK_PLV,
//depreciated		ROYALTY_PLV, ROYALTY_EMEA_PLV, STANDARD_PLV
//depreciated	};
//depreciated	*/

	// Opportunity.opportunityType__c picklist values
	public static final String COTERM_PLV = 'CoTerm';
	public static final String REBOOK_PLV = 'REBOOK';
	public static final String STANDARD_PLV = 'Standard';
	public static final List<String> OPPORTUNITYTYPE_VALUES = new List<String> {
		COTERM_PLV, REBOOK_PLV,
			STANDARD_PLV
	};

//depreciated	/*
//depreciated	//Commented by Neha(nejaiswal@deloitte.com) as part of the changes made in the picklist value of Opportunity.fulfillmentChannel__c
//depreciated		// Opportunity.fulfillmentChannel__c picklist values
//depreciated	public static final String DIRECT_CARAHSOFT_PLV = 'Direct - Carahsoft';
//depreciated	public static final String DIRECT_DLT_PLV = 'Direct - DLT';
//depreciated	public static final String DIRECT_END_CUSTOMER_PLV = 'Direct - End Customer';
//depreciated	public static final String DIRECT_GTSI_PLV = 'Direct - GTSI';
//depreciated	public static final String DIRECT_OEM_PLV = 'Direct - OEM';
//depreciated	public static final String DIRECT_VARVAD_PLV = 'Direct - VAR/VAD';
//depreciated	public static final String INDIRECT_OEM_PRELOAD_PLV = 'Indirect - OEM Preload';
//depreciated	public static final String INDIRECT_INTERNAL_COMMISSIONS_CREDIT_PLV = 'Indirect - Internal Commissions Credit';
//depreciated	public static final String INDIRECT_VARVAD_PLV = 'Indirect - VAR/VAD';
//depreciated	public static final String INDIRECT_WEBSTORE_PLV = 'Indirect - Webstore';

//depreciated	//Deleted some of the string variables	here if not present as the part of the Opportunity.fulfillmentChannel__c.
//depreciated	public static final List<String> FULFILLMENTCHANNEL_VALUES = new List<String> {
//depreciated		DIRECT_CARAHSOFT_PLV, DIRECT_DLT_PLV, DIRECT_END_CUSTOMER_PLV,
//depreciated		DIRECT_GTSI_PLV, DIRECT_OEM_PLV, DIRECT_VARVAD_PLV,
//depreciated		INDIRECT_OEM_PRELOAD_PLV, INDIRECT_INTERNAL_COMMISSIONS_CREDIT_PLV,
//depreciated		INDIRECT_VARVAD_PLV, INDIRECT_WEBSTORE_PLV
//depreciated	};*/

	// Opportunity.fulfillmentChannel__c picklist values
	public static final String Distributor = 'Distributor';
	public static final String Direct_Reseller = 'Direct Reseller';
	public static final String DIRECT_END_CUSTOMER_PLV = 'Direct End Customer';
	public static final String OEM_PLV = 'OEM';
	public static final String WEBSTORE_PLV = 'Webstore';
	public static final String NAChannel = 'N/A';
	public static final List<String> FULFILLMENTCHANNEL_VALUES = new List<String> {
		Direct_Reseller, DIRECT_END_CUSTOMER_PLV,
		OEM_PLV,Distributor, WEBSTORE_PLV,NA
	};
	/** Rule 18.6 theshold value.	Currently 10% above the opportunity amount. */
	public static final Double THRESHOLD_18_6 = 0.10;

	/** Limit map for rule 5.0 */
	public static final Map<String,Decimal> RULE5_LIMIT_MAP = new Map<String,Decimal>{
		null=>150000
//depreciated		,'AUD'=>187500
//depreciated		,'BRL'=>265957
//depreciated		,'CAD'=>160961
//depreciated		,'CLP'=>106500000
//depreciated		,'CNY'=>1027500
//depreciated		,'EUR'=>100000
//depreciated		,'GBP'=>100000
//depreciated		,'HKD'=>1170000
//depreciated		,'IDR'=>1575000000
//depreciated		,'INR'=>7200000
//depreciated		,'JPY'=>19499999
//depreciated		,'KRW'=>228429411
//depreciated		,'MXN'=>1950000
//depreciated		,// 'MYR'=>103000
//depreciated		,'NZD'=>225000
//depreciated		,// 'PHP'=>13819000
//depreciated		,'SGD'=>231000
//depreciated		,// 'THB'=>951000
//depreciated		,'USD'=>150000*/
	};

//depreciated	/** Limit map for rule 5.1 */
//depreciated	public static final Map<String,Decimal> RULE5_1_LIMIT_MAP = new Map<String,Decimal>{
//depreciated		null=>10000,
//depreciated		'AUD'=>12000,
//depreciated		'BRL'=>19000,
//depreciated		'CAD'=>11000,
//depreciated		'CLP'=>7100000,
//depreciated		'CNY'=>76000,
//depreciated		'EUR'=>10000,
//depreciated		'HKD'=>78000,
//depreciated		'IDR'=>105000000,
//depreciated		'INR'=>404000,
//depreciated		'JPY'=>1223000,
//depreciated		'KRW'=>9546000,
//depreciated		'MXN'=>130000,
//depreciated		'MYR'=>35000,
//depreciated		'NZD'=>13000,
//depreciated		'PHP'=>461000,
//depreciated		'SGD'=>15000,
//depreciated		'THB'=>317000,
//depreciated		'USD'=>10000 };

//depreciated	/** Limit map for rule 8.1 */
//depreciated	public static final Map<String,Decimal> RULE8_1_LIMIT_MAP = new Map<String,Decimal>{
//depreciated		null=>50,
//depreciated		'AUD'=>60,
//depreciated		'BRL'=>97.5,
//depreciated		'CAD'=>52.5,
//depreciated		'CLP'=>30500,
//depreciated		'CNY'=>378,
//depreciated		'EUR'=>36.5,
//depreciated		// 'GBG'=>25, // to do - correct to GBP
//depreciated		'HKD'=>390,
//depreciated		'IDR'=>525000,
//depreciated		'INR'=>200,
//depreciated		'JPY'=>6000,
//depreciated		'KRW'=>47000,
//depreciated		'MXN'=>650,
//depreciated		'MYR'=>174,
//depreciated		'NZD'=>69.5,
//depreciated		'PHP'=>2300,
//depreciated		'SGD'=>76,
//depreciated		'THB'=>1650,
//depreciated		'USD'=>50 };

	// Opportunity.Pay_Now__c and Opportunity.Renewable__c picklist values
	public static final String YES_PLV = 'Yes';
	public static final String NO_PLV = 'No';
	public static final List<String> PAYNOW_VALUES = new List<String> {
		YES_PLV, NO_PLV
	};
	public static final String DEFERRED_PLV = 'Deferred'; // this is not a value of the picklist
	public static final List<String> RENEWABLE_VALUES = PAYNOW_VALUES;

	// Opportunity.StageName picklist values
	public static final String PREPARE_PLV = 'Prepare';
	public static final String CLOSED_WON_PLV = 'Closed Won';
	public static final String CLOSED_BOOKED_PLV = 'Closed Booked';
	public static final List<String> STAGENAME_VALUES = new List<String> {
		PREPARE_PLV, CLOSED_WON_PLV, CLOSED_BOOKED_PLV
	};

	// OpportunityLineItem.NewOrRenewal__c picklist values
	public static final String NEW_PLV='New';
	public static final String RENEWAL_PLV='Renewal';
	public static final String RENEWAL_SKU_CHANGE_PLV='Renewal - SKU Change';
	public static final List<String> NEWORRENEWAL_VALUES = new List<String> {
		NEW_PLV, RENEWAL_PLV, RENEWAL_SKU_CHANGE_PLV
	};

	// ApprovalCustom__c.ApprovalStatus__c picklist values
	public static final String APPROVED_PLV='Approved';
	public static final String SIGNED_PLV='Signed';
	public static final List<String> APPROVALSTATUS_VALUES = new List<String> {
		APPROVED_PLV, SIGNED_PLV
	};

	// Credit__c.Credit_Stage__c picklist values
	//public static final String APPROVED_PLV='Approved';
	public static final String APPROVED_MANUAL_PLV='Approved - Manual';
	public static final List<String> CREDITSTAGE_VALUES = new List<String> {
		APPROVED_PLV, APPROVED_MANUAL_PLV
	};

	// Opportunity.Rush_Order_Reason__c values
	public static final String RUSH_SLA_TIME_PERIOD='SLA time period';
	public static final String RUSH_PRODUCT_EXCEPTION='Product Exception';


	public static final String HIDE_MESSAGES_SETTING = 'OrderManagement.HideMessages';
	/** Map of all the BooleanSetting__c values used. */
	public static final Map<String,Boolean> booleanSettingMap = new Map<String,Boolean> {
		HIDE_MESSAGES_SETTING => getBooleanSettingValue(HIDE_MESSAGES_SETTING) };

	/**
	 * GPS Services SKU's from the Services SKU custom setting.
	 */
	public static Set<String> GPS_SERVICES_SKU_SET {
		get {
			if (GPS_SERVICES_SKU_SET == null) {
				GPS_SERVICES_SKU_SET = new Set<String>();
				Map<String, ServicesSKU__c> servicesSKUs = ServicesSKU__c.getAll();
				for (ServicesSKU__c servicesSKU : servicesSKUs.values()) {
					GPS_SERVICES_SKU_SET.add(servicesSKU.Name);
				}
			}
			return GPS_SERVICES_SKU_SET;
		}
	}

	/**
	 * Query a Boolean value from BooleanSetting__c constants.
	 */
	public static Boolean getBooleanSettingValue(String key) {
		Boolean retval = null;
		BooleanSetting__c bs = BooleanSetting__c.getInstance(key);
		if(bs != null) {
			retval = bs.Value__c;
		}
		return retval;
	}

	/**
	 * Query the current user.
	 */
	public static User currentUser {
		get {
			if(currentUser == null) {
				currentUser = [
					select
						Region__c,
						UserRole.Name,
						Job_Function__c
					from User
					where Id = :UserInfo.getUserId() ];
			}
			return currentUser;
		}
	}

	/**
	 * Normalize long dashes into short dashes.
	 */
	public static String convertLongDash(String value) {
		return (value != null)?value.replaceAll('–','-'):null;
	}

	/**
	 * Normalize currencies with a scale of 2.
	 */
	public static Decimal currencyAmount(Decimal value,Decimal retval) {
		if(value != null) {
			retval = value;
		}
		if(retval != null && retval.scale() != 2) {
			retval = retval.setScale(2,System.RoundingMode.HALF_DOWN);
		}
		return retval;
	}

	public static Integer getIntegerValue(String key,Integer retval) {
		LongSetting__c ls = LongSetting__c.getInstance(key);
		if(ls != null && ls.Value__c != null) {
			retval = ls.Value__c.intValue();
		}
		return retval;
	}

	/**
	 * Normalize currencies with a scale of 2.
	 */
	public static Decimal currencyAmount(Decimal value) {
		if(value != null && value.scale() != 2) {
			value = value.setScale(2,System.RoundingMode.HALF_DOWN);
		}
		return value;
	}

	public Id oppId;
	private Boolean needsUpdate = false;

	public OrderManagementControllerExtension(ApexPages.StandardController stdController) {
		oppId = stdController.getId();
	 //added to accomodate dated currency changes : US58342
		Opportunity oppInst = new Opportunity();
		oppInst = [SELECT CloseDate FROM Opportunity WHERE Id =: oppId];
		list<DatedConversionRate> listConvRates = new list<DatedConversionRate>([
			SELECT ConversionRate, IsoCode, StartDate
			FROM DatedConversionRate
			WHERE StartDate <=: oppInst.CloseDate
				AND NextStartDate >: oppInst.CloseDate]);
		for(DatedConversionRate conRateInst : listConvRates){
				RULE5_LIMIT_MAP.put(conRateInst.IsoCode, conRateInst.ConversionRate * 150000);
		}
		system.debug('---OrderManagementControllerExtension.RULE5_LIMIT_MAP---'+RULE5_LIMIT_MAP);
	}

	/**
	 * Rule 00
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: Standard, Co-Term, Eval
	 * If order already submitted
	 *		OR	if role starts with ‘NA’ and Account is inactive
	 *		OR	if role starts with ‘NA’ and Account is on Credit Hold and Opportunity is on Sale Hold
	 * then display error: Cannot Submit
	 */
	public Boolean func_rule00() {
		Boolean retval = null;
		if(notExempt2()) {
			retval = func_checkToValidate() && func_activeAccount();
		}
		return reportResult(retval,'0',null);
	}

	// first part of rule00
	public Boolean func_checkToValidate() {
		Boolean retval = true;
		if(notExempt2()) {
			retval = (opp.DateOrderSubmitted__c == null);
			if(! retval) {
				ApexPages_Message_ControllerExtension.addErrorMessage(ERROR00);
			}
		}
		return retval;
	}

	// second part of rule00
	public Boolean func_activeAccount() {
		Boolean retval = true;
		if(notExempt2() && isNAUser()) {
			retval = ! ((opp.Account.IsAccountActive__c != true) || (opp.Account.IsOnCreditHold__c == true && opp.IsOnSaleHold__c == true));
			if(! retval) {
				ApexPages_Message_ControllerExtension.addErrorMessage(MESSAGE_AC_ACTIVE);
			}
		}
		return retval;
	}

	/**
	 * Rule 1
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: ALL except Bridge, Buffer, and Customer Satisfaction
	 *
	 * Only Account Owner OR Opportunity Owner
	 * OR a Member of the Sales Team OR Account Team (with read/write permissions)
	 * OR a user with a System Administrator Profile
	 * can submit order and process rules.
	 */
	public Boolean func_rule1() {
		Boolean retval = null;
		if(! isAdmin) {
			Id uid = currentUser.Id;
			Boolean allowed = (uid == opp.Account.OwnerId)
				|| (uid == opp.OwnerId)
				|| isTeamMember
				|| isShareMember
				|| isAccountMember;
			retval = allowed; // && (opp.RecordType.Name != NA_FED_SLED_RTN || (currentUser.Profile.Name != NA_SALES_FED_SLED_PN && currentUser.Profile.Name != NA_SALES_EDU_DLT_PN ));
//	 * Users with a profile of NA Sales - FED SLED or NA Sales - EDU DLT cannot submit
//	 * orders with a record type of NA Fed Sled.
		}
		return reportResult(retval,'1',ERROR1);
	}

//depreciated	/**
//depreciated	 * Rule 1.1
//depreciated	 *
//depreciated	 * Regions: NA
//depreciated	 *
//depreciated	 * Channels: Distributor, Webstore
//depreciated	 *
//depreciated	 * Opportunity Types: ALL except Bridge, Buffer, and Customer Satisfaction
//depreciated	 *
//depreciated	 * The order must not be Distributor and
//depreciated	 * may only have open enrollment products.
//depreciated	 */
//depreciated	/* Commented by nejaiswal@deloitte.com as the values of the picklist of fulfillmentChannel are changed.
//depreciated	public Boolean func_rule1_1() {
//depreciated		Boolean retval = null;
//depreciated		if(((fulfillmentChannel == INDIRECT_VARVAD_PLV) || (fulfillmentChannel == INDIRECT_WEBSTORE_PLV)) && isNAUser()) {
//depreciated			retval = ! ((fulfillmentChannel == INDIRECT_VARVAD_PLV) || hasNonOpenEnrollment);
//depreciated		}
//depreciated		return reportResult(retval,'1.1',ERROR1_1);
//depreciated	}

//depreciated	/* comment out the below error on ‘Submit opportunity’ as the error is no longer valid as we are replacing the channel load with the interface.
//depreciated	 We need to change the opportunity to ‘Closed/Won’ only.
//depreciated	public Boolean func_rule1_1() {
//depreciated		Boolean retval = null;
//depreciated		if(((fulfillmentChannel == Distributor) || (fulfillmentChannel == WEBSTORE_PLV)) && isNAUser()) {
//depreciated			retval = ! ((fulfillmentChannel == Distributor) || hasNonOpenEnrollment);
//depreciated		}
//depreciated		return reportResult(retval,'1.1',ERROR1_1);
//depreciated	}

//depreciated	/

	/**
	 * Rule 2
	 *
	 * Regions: ALL
	 *
	 * Channels: Direct End Customer, Direct	End Customer, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
	 *
	 * If payment method is Credit Card than none of the following fields can be null;
	 *		Billing Address, Shipping Address, Credit Card Type, Credit Card Number,
	 *		Expiration Date, Name on Card
	 */
	public Boolean func_rule2() {
		Boolean retval = null;
		if(notExempt()&&isDirect()) {
			retval = (CREDIT_CARD != opp.PaymentType__c);
			if(! retval) {
				String msgFields = '';
				String sep = '\n\t';

//depreciated				/*
//depreciated				//Commented by pbanik@redhat.com
//depreciated				//check now done on new billing and shipping address lookups done in func_rule26
//depreciated				if(opp.BillingAddress__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.BillingAddress__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.BillingCity__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.BillingCity__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.BillingState__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.BillingState__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.BillingCountry__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.BillingCountry__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.BillingZipPostalCode__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.BillingZipPostalCode__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.ShippingAddress__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.ShippingAddress__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.ShippingCity__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.ShippingCity__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.ShippingState__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.ShippingState__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.ShippingCountry__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.ShippingCountry__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.ShippingZipPostalCode__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.ShippingZipPostalCode__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.CreditCardType__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.CreditCardType__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				*/
				if(opp.Credit_Card_Number__c == null) {
					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Credit_Card_Number__c.Label;
					sep = ',\n\t';
				}
				if(opp.ExpirationDate__c == null) {
					msgFields += sep + Schema.SObjectType.Opportunity.Fields.ExpirationDate__c.Label;
					sep = ',\n\t';
				}
				if(opp.NameOnCard__c == null) {
					msgFields += sep + Schema.SObjectType.Opportunity.Fields.NameOnCard__c.Label;
				}
				retval = (msgFields == '');
				if(! retval) {
					ApexPages_Message_ControllerExtension.addErrorMessage(ERROR2+msgFields);
				}
			}
		}
		return reportResult(retval,'2',null);
	}

	/**
	 * Rule 2.1:
	 *
	 * Regions: ALL
	 *
	 * Channels: OEM, Direct – VAR/VAD, Indirect – OEM Preload, Indirect – VAR/VAD, Direct – Carasoft, Direct – DLT, Direct – GTSI
	 *
	 * Opportunity Types: ALL except Bridge, Buffer, and Customer Satisfaction
	 *
	 * Financial Partner is required
	 */
	public Boolean func_rule2_1() {
		Boolean retval = ! Opportunity_ManagePartners.isFinancialPartnerRequired(opp);
		return reportResult(retval,'2.1',ERROR2_1);
	}

	/**
	 * Rule 3
	 *
	 * Regions ALL
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
	 *
	 * If Payment Type equals PO then PO Number cannot be null
	 */
	public Boolean func_rule3() {
		Boolean retval = null;
		if(notExempt()&&isDirect()) {
			retval = (opp.PONumber__c != null) || ! isPurchaseOrderPaymentType;
		}
		return reportResult(retval,'3',ERROR3);
	}

//depreciated	/**
//depreciated	 * Rule 3.1
//depreciated	 *
//depreciated	 * Regions: EMEA, APAC
//depreciated	 *
//depreciated	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
//depreciated	 *
//depreciated	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
//depreciated	 *
//depreciated	 * If Payment Type equals PO
//depreciated	 *		AND the role of the user submitting the opportunity starts with EMEA OR APAC
//depreciated	 * then Billing Address cannot be blank
//depreciated	 * (zip code is not required if Country of Order equals Hong Kong OR New Zealand)
//depreciated	 */
//depreciated	/*public Boolean func_rule3_1() {
//depreciated		Boolean retval = null;
//depreciated		if(notExempt()&&isDirect()&&(isEMEAUser()||isAPACUser())) {
//depreciated			retval = ! isPurchaseOrderPaymentType;
//depreciated			if(! retval) {
//depreciated				if((opp.BillingAddress__c != null)&&(opp.BillingCity__c != null)&&(opp.BillingCountry__c != null)) {
//depreciated					retval = (opp.BillingZipPostalCode__c != null);
//depreciated					if(! retval) {
//depreciated						String c = opp.BillingCountry__c.toUpperCase();
//depreciated						retval = (c == 'NEW ZEALAND' || c == 'NZ' || c == 'HONG KONG' || c == 'HK');
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		return reportResult(retval,'3.1',ERROR3_1);
//depreciated	}*/

//depreciated	/**
//depreciated	 * Rule 3.2
//depreciated	 *
//depreciated	 * Regions: EMEA, APAC
//depreciated	 *
//depreciated	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
//depreciated	 *
//depreciated	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
//depreciated	 *
//depreciated	 * If Payment Type equals PO
//depreciated	 *		AND the role of the user submitting the opportunity starts with EMEA OR APAC
//depreciated	 * then Shipping Address cannot be blank
//depreciated	 * (zip code is not required if Country of Order equals Hong Kong OR New Zealand)
//depreciated	 */
//depreciated	/*public Boolean func_rule3_2() {
//depreciated		Boolean retval = null;
//depreciated		if(notExempt()&&isDirect()&&(isEMEAUser()||isAPACUser())) {
//depreciated			retval = ! isPurchaseOrderPaymentType;
//depreciated			if(! retval) {
//depreciated				if((opp.ShippingAddress__c != null)&&(opp.ShippingCity__c != null)&&(opp.ShippingCountry__c != null)) {
//depreciated					retval = (opp.ShippingZipPostalCode__c != null);
//depreciated					if(! retval) {
//depreciated						String c = opp.ShippingCountry__c.toUpperCase();
//depreciated						retval = (c == 'NEW ZEALAND' || c == 'NZ' || c == 'HONG KONG' || c == 'HK');
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		return reportResult(retval,'3.2',ERROR3_2);
//depreciated	}*/

	/**
	 * Rule 4
	 *
	 * Regions: ALL
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
	 *
	 * If Account Billing country is one of the following
	 * then VAT Number field cannot be blank:
	 *		Austria, Belgium, Denmark, Estonia, Finland, France,
	 *		Germany, Greece, Hungary, Ireland, Italy, Latvia,
	 *		Lithuania, Luxembourg, Netherlands, Poland, Portugal,
	 *		Slovakia, Slovenia, Spain, Sweden, UK, United Kingdom,
	 *		Bulgaria, Cyprus, Czech Republic, Malta
	 */
	public Boolean func_rule4() {
		Boolean retval = null;
		if(notExempt()&&isDirect()) {
			retval = (opp.Account.VATNumber__c != null)
				|| (opp.Account.BillingCountry == null)
				|| ! VAT_COUNTRIES.contains(opp.Account.BillingCountry.toUpperCase());
		}
		return reportResult(retval,'4',ERROR4);
	}

	/**
	 * Rule 5
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
	 *
	 * Opportunities where Pay Now is "No" cannot use annual payments where amount is less
	 * than $150,000 (or equivalent converted value in respective currency).
	 */
	public Boolean func_rule5() {
		Boolean retval = null;

		if(notExempt()) {
			retval = (opp.Pay_Now__c == 'Yes')
					|| ((currencyAmount(opp.Year2PaymentAmount__c,0.00) <= 0)
					&& (currencyAmount(opp.Year3PaymentAmount__c,0.00) <= 0)
					&& (currencyAmount(opp.Year4PaymentAmount__c,0.00) <= 0)
					&& (currencyAmount(opp.Year5PaymentAmount__c,0.00) <= 0)
					&& (currencyAmount(opp.Year6PaymentAmount__c,0.00) <= 0) );

			if(! retval) {
				Decimal limitAmount = currencyAmount(RULE5_LIMIT_MAP.get(opp.CurrencyIsoCode),RULE5_LIMIT_MAP.get(null));
				retval = (currencyAmount(opp.Amount,0.00) >= limitAmount);
			}
		}
		return reportResult(retval,'5',ERROR5);
	}

	/**
	 * Rule 5.1
	 *
	 * Regions: NA, LATAM, APAC
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
	 *
	 * Opportunities which are in a closed won state cannot use Annual Payments
	 * when the amount is less than the following (in respective applicable currency):
	 *		10,000 USD
	 *		12,000 AUD
	 *		19,000 BRL
	 *		11,000 CAD
	 *		7,100,000 CLP
	 *		76,000 CNY
	 *		10,000 EUR
	 *		78,000 HKD
	 *		404,000 INR
	 *		1,223,000 JPY
	 *		35,000 MYR
	 *		130,000 MXN
	 *		13,000 NZD
	 *		15,000 SGD
	 *		317,000 THB
	 *		461,000 PHP
	 *		9,546,000 KRW
	 */
	public Boolean func_rule5_1() {
		Boolean retval = null;
		if(notExempt()&&isDirect()&&(isNAUser()||isAPACUser()||isLATAMUser())) {
			retval = (opp.StageName != CLOSED_WON_PLV)
				|| (( currencyAmount(opp.Year2PaymentAmount__c,0.00) <= 0)
					&& ( currencyAmount(opp.Year3PaymentAmount__c,0.00) <= 0)
					&& ( currencyAmount(opp.Year4PaymentAmount__c,0.00) <= 0)
					&& ( currencyAmount(opp.Year5PaymentAmount__c,0.00) <= 0)
					&& ( currencyAmount(opp.Year6PaymentAmount__c,0.00) <= 0));
			if(! retval) {
				OrderManagementLimits__c omLimits = OrderManagementLimits__c.getInstance(opp.CurrencyIsoCode);
				if(omLimits == null || omLimits.Rule_5_1_Limit__c == null) {
					omLimits = OrderManagementLimits__c.getInstance('USD');
				}
				Decimal limitAmount = 10000.00;
				if(omLimits != null && omLimits.Rule_5_1_Limit__c != null) {
					limitAmount = currencyAmount(omLimits.Rule_5_1_Limit__c);
				}
				retval = (currencyAmount(opp.Amount,0.00) >= limitAmount);
			}
		}
		return reportResult(retval,'5.1',ERROR5_1);
	}

	/**
	 * Rule 6
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: Standard, Co-Term, Eval
	 *
	 * If Pay Now equals Yes then the 1st Year Payment should not be null OR zero.
	 * All other Payment fields should be null or less than or equal to zero.
	 */
	public Boolean func_rule6() {
		Boolean retval = null;
		if(notExempt1()) {
			retval = (opp.Pay_Now__c != YES_PLV)
				|| ((currencyAmount(opp.Year1PaymentAmount__c,0.00) != 0.00)
					&& (currencyAmount(opp.Year2PaymentAmount__c,0.00) <= 0)
					&& (currencyAmount(opp.Year3PaymentAmount__c,0.00) <= 0)
					&& (currencyAmount(opp.Year4PaymentAmount__c,0.00) <= 0)
					&& (currencyAmount(opp.Year5PaymentAmount__c,0.00) <= 0)
					&& (currencyAmount(opp.Year6PaymentAmount__c,0.00) <= 0));
		}
		return reportResult(retval,'6',ERROR6);
	}


	/**
	 * Rule 7
	 *
	 * Regions: ALL
	 *
	 * Channels: Distributor, Direct_Reseller, Direct - End Customer,
	 *					 Direct - OEM, Direct - VAR/VAD
	 *
	 * Opportunity Types: Standard, Co-Term, Eval
	 *
	 * If Pay Now equals No, at least 1st Year Payment
	 * and 2nd Year Payment should contain a value
	 */
	public Boolean func_rule7() {
		Boolean retval = null;
		if(notExempt1() && isFulfillmentChannelDirect()) {
			retval = (opp.Pay_Now__c != NO_PLV)
				|| ((currencyAmount(opp.Year1PaymentAmount__c,0.00) != 0)
					&& (currencyAmount(opp.Year2PaymentAmount__c,0.00) != 0) );
		}
		return reportResult(retval,'7',ERROR7);
	}

	/**
	 * Rule 8
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: Standard, Co-Term, Eval
	 *
	 * The Sum of Annual Payments must equals the Amount
	 */
	public Boolean func_rule8() {
		Boolean retval = null;
		if(notExempt2()) {
			Decimal totalPayment = currencyAmount(currencyAmount(opp.Year1PaymentAmount__c,0.00)
				+ currencyAmount(opp.Year2PaymentAmount__c,0.00)
				+ currencyAmount(opp.Year3PaymentAmount__c,0.00)
				+ currencyAmount(opp.Year4PaymentAmount__c,0.00)
				+ currencyAmount(opp.Year5PaymentAmount__c,0.00)
				+ currencyAmount(opp.Year6PaymentAmount__c,0.00));
			Decimal amount = currencyAmount(opp.Amount,0.00);
			retval = (totalPayment == amount);
		}
		return reportResult(retval,'8',ERROR8);
	}

	/**
	 * Rule 8.1
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: Standard, Co-Term, Eval
	 *
	 * The Sum of the Booking Schedule must equal the Amount within the following margin of error:
	 *		60.00 AUD
	 *		97.50 BRL
	 *		52.50 CAD
	 *		30,500.00 CLP
	 *		378.00 CNY
	 *		36.50 EUR
	 *		25.00 GBG // to do - correct to GBP
	 *		390.00 HKD
	 *		200.00 INR
	 *		6,000.00 JPY
	 *		47,000.00 KRW
	 *		650.00 MXN
	 *		174.00 MYR
	 *		69.50 NZD
	 *		2,300.00 PHP
	 *		76.00 SGD
	 *		1,650.00 THB
	 *		50.00 USD
	 */
	public Boolean func_rule8_1() {
		Boolean retval = null;
		if(notExempt2()) {
			Decimal bookedAmount = currencyAmount(currencyAmount(opp.Year1Amount__c,0.00)
				+ currencyAmount(opp.Year2Amount__c,0.00)
				+ currencyAmount(opp.Year3Amount__c,0.00)
				+ currencyAmount(opp.Year4Amount__c,0.00)
				+ currencyAmount(opp.Year5Amount__c,0.00)
				+ currencyAmount(opp.Year6Amount__c,0.00));
			Decimal amount = currencyAmount(opp.Amount,0.00);
			OrderManagementLimits__c omLimits = OrderManagementLimits__c.getInstance(opp.CurrencyIsoCode);
			if(omLimits == null || omLimits.Rule_8_1_Limit__c == null) {
				omLimits = OrderManagementLimits__c.getInstance('USD');
			}
			Decimal limitAmount = 50.00;
			if(omLimits != null && omLimits.Rule_8_1_Limit__c != null) {
				limitAmount = currencyAmount(omLimits.Rule_8_1_Limit__c);
			}
			System.debug('bookedAmount='+bookedAmount+',limitAmount='+limitAmount+',amount='+amount);
			retval = (bookedAmount-limitAmount < amount) && (bookedAmount+limitAmount > amount);
		}
		return reportResult(retval,'8.1',ERROR8_1);
	}

	/**
	 * Rule 9
	 *
	 * Regions: NA
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: Standard, Co-Term, Eval
	 *
	 * Only one Inside Sales Team member should be present.
	 */
	public Boolean func_rule9() {
		Boolean retval = null;
		if(notExempt2()&&isNAUser()) {
			retval = (insideRepCount() == 1);
		}
		return reportResult(retval,'9',ERROR9);
	}


	/**
	 * Rule 10.1
	 *
	 * Regions: EMEA
	 *
	 * Channels: Direct – VAR/VAD
	 *
	 * Opportunity Types: Standard, Co-Term, Eval
	 *
	 * At least one Sales Team Member should be present on the opportunity
	 * with the role of Channel Sales Manager.
	 */
//depreciated	/*Commented by nejaiswal@deloitte.com as the picklist values for fulfillmentChannel are changed.
//depreciated	public Boolean func_rule10_1() {
//depreciated		Boolean retval = null;
//depreciated		if(notExempt2()&&isEMEAUser()&&(fulfillmentChannel == DIRECT_VARVAD_PLV)) {
//depreciated			retval = (channelAccountManagerCount() > 0);
//depreciated		}
//depreciated		return reportResult(retval,'10.1',ERROR10_1);
//depreciated	}*/
	public Boolean func_rule10_1() {
		Boolean retval = null;
		if(notExempt2()&&isEMEAUser()&&(fulfillmentChannel == Direct_Reseller)) {
			retval = (channelAccountManagerCount() > 0);
		}
		return reportResult(retval,'10.1',ERROR10_1);
	}

	/**
	 * Rule 11
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: Standard, Co-Term, Eval
	 *
	 * Opportunity contains at least one product / line item.
	 */
	public Boolean func_rule11() {
		Boolean retval = null;
		if(notExempt2()) {
			retval = hasProducts;
		}
		return reportResult(retval,'11',ERROR11);
	}

	/**
	 * Rule 12
	 *
	 * Regions: NA, EMEA, LATAM
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: Standard, Co-Term, Eval
	 *
	 * If the Opportunity has products associated with it and one of the products is a renewal product, then a contract number is required.
	 */
	public Boolean func_rule12() {
		Boolean retval = null;
		if(notExempt2()&&isDirect()&&(isNAUser()||isEMEAUser()||isLATAMUser())) {
			retval = ! hasRenewalButNoContractNumbers;
		}
		return reportResult(retval,'12',ERROR12);
	}

	/**
	 * Rule 12.1
	 *
	 * Regions: NA, EMEA, LATAM
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: Standard, Co-Term, Eval
	 *
	 * If Opportunity Line item SKU ends in RN,
	 * then Contract Number cannot be Null
	 * and New or Renewal field must contain Renewal
	 */
	public Boolean func_rule12_1() {
		Boolean retval = null;
		if(notExempt2()&&isDirect()&&(isNAUser()||isEMEAUser()||isLATAMUser())) {
			retval = ! hasInvalidRenewals;
		}
		return reportResult(retval,'12.1',ERROR12_1);
	}

//depreciated	/**
//depreciated	 * Rule 13
//depreciated	 *
//depreciated	 * Regions: ALL
//depreciated	 *
//depreciated	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
//depreciated	 *
//depreciated	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
//depreciated	 *
//depreciated	 * At least one Shipping Contact must be present in Contact Roles
//depreciated	 //Reasons for commenting them out is Contact roles might not be used in future as we are using the 4 lookups for contact (Bill-To, Ship-To, Sold-To and Entitle-To).
//depreciated	public Boolean func_rule13() {
//depreciated		Boolean retval = null;
//depreciated		if(notExempt()&&isDirect()) {
//depreciated			retval = (shippingContactCount > 0);
//depreciated		}
//depreciated		return reportResult(retval,'13',ERROR13);
//depreciated	}
//depreciated	*/

//depreciated	/**
//depreciated	 * Rule 14
//depreciated	 *
//depreciated	 * Regions: ALL
//depreciated	 *
//depreciated	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
//depreciated	 *
//depreciated	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
//depreciated	 *
//depreciated	 * At least one Payables Contact must be present in Contact Roles
//depreciated	 //Reasons for commenting them out is Contact roles might not be used in future as we are using the 4 lookups for contact (Bill-To, Ship-To, Sold-To and Entitle-To).

//depreciated	public Boolean func_rule14() {
//depreciated		Boolean retval = null;
//depreciated		if(notExempt()&&isDirect()) {
//depreciated			retval = (payablesContactCount > 0);
//depreciated		}
//depreciated		return reportResult(retval,'14',ERROR14);
//depreciated	}
//depreciated	*/

//depreciated	/**
//depreciated	 * Rule 15
//depreciated	 *
//depreciated	 * Regions: NA, EMEA, LATAM
//depreciated	 *
//depreciated	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
//depreciated	 *
//depreciated	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
//depreciated	 *
//depreciated	 * If Product is Non-Service (as determined by the product family)
//depreciated	 * then Shipping Contact’s (in Contact Roles) RHN Login
//depreciated	 * AND Email Address cannot be Null
//depreciated	 //Reasons for commenting them out is Contact roles might not be used in future as we are using the 4 lookups for contact (Bill-To, Ship-To, Sold-To and Entitle-To).

//depreciated	public Boolean func_rule15() {
//depreciated		Boolean retval = null;
//depreciated		if(notExempt()&&isDirect()&&(isNAUser()||isEMEAUser()||isLATAMUser())) {
//depreciated			retval = ! (hasNonServices && (shippingContactCount == 0 || isShippingContactInvalid));
//depreciated		}
//depreciated		return reportResult(retval,'15',ERROR15);
//depreciated	}
//depreciated	 */

	/**
	 * Rule 16
	 *
	 * Regions: ALL
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
	 *
	 * At least one attachment must be present in the Notes and Attachments section
	 * on the opportunity
	 */
	public Boolean func_rule16() {
		Boolean retval = null;
		if(notExempt()&&isDirect()) {
			retval = hasAttachments;
		}
		return reportResult(retval,'16',ERROR16);
	}

	/**
	 * Rule 17
	 *
	 * Regions: EMEA, LATAM
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
	 *
	 * If any Product Line item field New_or_Renewal is New
	 * then Contract Start Date cannot be more than 60 days ago.
	 */
	public Boolean func_rule17() {
		Boolean retval = null;
		if(notExempt()&&isDirect()&&(isEMEAUser()||isLATAMUser())) {
			retval = (opp.ContractStartDate__c == null || opp.ContractStartDate__c.daysBetween(System.today()) <= 60 || ! hasNewProducts);
		}
		return reportResult(retval,'17',ERROR17);
	}

	/**
	 * Rule 18
	 *
	 * Regions: ALL
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
	 *
	 * Excluded Countries of Order: Colombia
	 *
	 * If the opp amount contains a non-zero value then
	 * both the most recently created credit check record and the
	 * most recent final credit check record (if there is one) must
	 * have been modified within the last 105 days.
	 */
	public Boolean func_rule18() {
		Boolean retval = null;
		if ( notExempt()
			//Modified to make credit check compulsory for Channel Distributor as well
			//&& isDirect()
			&& (isDirect() || fulfillmentChannel == Distributor)
			&& (opp.Country_of_Order__c == null || ! EXCLUDED_CREDIT_CHECK_COUNTRIES.contains(opp.Country_of_Order__c.toUpperCase())))
		{
			retval = (currencyAmount(opp.Amount,0.00) == 0.00);
			if(!retval) {
				retval = (mostRecentCredit != null)&&(getPossiblyFinalCreditLastModifiedDate().date().daysBetween(System.today()) <= integerValueMap.get(MAX_DAYS_OLD_SETTING));
			}
		}
		return reportResult(retval,'18',ERROR18);
	}

	/**
	 * Rule 18.1
	 *
	 * Regions: ALL
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *  -or- FulfillmentChannel: Distributor
	 *
	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
	 *
	 * Excluded Countries of Order: Colombia
	 *
	 * If the opp amount contains a non-zero value then the most recent created final
	 * credit check record (or just most recent credit check record if there is no final record)
	 * check record must be Approved and Payment Terms cannot be null.
	 */
	public Boolean func_rule18_1() {
		Boolean retval = null;
		if ( notExempt()
			//Modified to make credit check compulsory for Channel Distributor as well
			//&& isDirect()
			&& (isDirect() || fulfillmentChannel == Distributor)
			&& (opp.Country_of_Order__c == null || ! EXCLUDED_CREDIT_CHECK_COUNTRIES.contains(opp.Country_of_Order__c.toUpperCase())))
		{
			retval = (currencyAmount(opp.Amount,0.00) == 0.00);
			if(!retval) {
				retval = (possiblyFinalCredit == null)||((possiblyFinalCredit.Credit_Stage__c == APPROVED_MANUAL_PLV || possiblyFinalCredit.Credit_Stage__c == APPROVED_PLV) && possiblyFinalCredit.Payment_Terms__c != null);
			}
		}
		return reportResult(retval,'18.1',ERROR18_1);
	}

	/**
	 * Rule 18.4
	 *
	 * Regions: ALL
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *  -or- FulfillmentChannel: Distributor
	 *
	 * Opportunity Types: ALL except Bridge, Buffer, and Customer Satisfaction
	 *
	 * Excluded Countries of Order: Colombia
	 *
	 * The Billing Account Number on the most recent Credit Check must match either:
	 *	- The Primary Billing Account Number on the End Customer Account for Direct End Customer Opportunites
	 *	- The Primary Billing Account Number on the Financial Partner listed in PRL for OEM,
	 *		Direct – VAR/VAD, and Direct – GTSI Opportunite
	 *
	 * Error message custom label name: OrderManagement_Error18_4
	 */
	public Boolean func_rule18_4() {
		Boolean retval = null;
		//Modified to make credit check compulsory for Channel Distributor as well
		//if (isDirect() && (opp.Country_of_Order__c == null || ! EXCLUDED_CREDIT_CHECK_COUNTRIES.contains(opp.Country_of_Order__c.toUpperCase())) ) {
		if ((isDirect() || fulfillmentChannel == Distributor) && (opp.Country_of_Order__c == null || ! EXCLUDED_CREDIT_CHECK_COUNTRIES.contains(opp.Country_of_Order__c.toUpperCase())) ) {
			retval = (mostRecentCredit == null);
			if (! retval) {
				if (fulfillmentChannel == DIRECT_END_CUSTOMER_PLV ||
						fulfillmentChannel == Direct_Reseller ||
						fulfillmentChannel == OEM_PLV ||
						fulfillmentChannel == Distributor) { //to make credit check compulsory for Channel Distributor as well
					//retval = (mostRecentCredit.BillingAccountNumberUsed__c == opp.Account.PrimaryBillingAccountNumber__c);
					//changed the refrence to relationship Bill_To_Account__r from Account
					if(mostRecentCredit != null){
							if(string.isNotEmpty(mostRecentCredit.Credit_Stage__c)){
									if(!mostRecentCredit.Credit_Stage__c.containsIgnoreCase('Rejected')
									&& opp.stageName != 'Closed Won' && opp.stageName != 'Closed Lost' && opp.stageName != 'Closed Booked')
											retval = (mostRecentCredit.BillingAccountNumberUsed__c == opp.Bill_To_Account__r.Name);
									else
											retval = true;
							}
					}
					system.debug('---'+mostRecentCredit.BillingAccountNumberUsed__c+'---'+opp.Bill_To_Account__r.Name+'--'+retval);
				}
				else {
					retval = (mostRecentCredit.BillingAccountNumberUsed__c == opp.FinancialPartner__r.PrimaryBillingAccountNumber__c);
					system.debug('---in else---');
				}
			}
		}
		return reportResult(retval,'18.4',Label.OrderManagement_Error18_4);
	}

	/**
	 * Rule 18.5
	 *
	 * Regions: ALL
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: ALL except Bridge, Buffer, and Customer Satisfaction
	 *
	 * Excluded Countries of Order: Colombia
	 *
	 * The most recent credit check must have the same currency type as the opportunity.
	 *
	 * Error message custom label name: OrderManagement_Error18_5
	 */
	public Boolean func_rule18_5() {
		Boolean retval = null;
		//Modified to make credit check compulsory for Channel Distributor as well
		//if(isDirect() && (opp.Country_of_Order__c == null || ! EXCLUDED_CREDIT_CHECK_COUNTRIES.contains(opp.Country_of_Order__c.toUpperCase())) ) {
		if((isDirect() || fulfillmentChannel == Distributor) && (opp.Country_of_Order__c == null || ! EXCLUDED_CREDIT_CHECK_COUNTRIES.contains(opp.Country_of_Order__c.toUpperCase())) ) {
			retval = (mostRecentCredit == null)||(mostRecentCredit.CurrencyIsoCode == opp.CurrencyIsoCode);
		}
		return reportResult(retval,'18.5',Label.OrderManagement_Error18_5);
	}

	/**
	 * Rule 18.6
	 *
	 * Regions: ALL
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: ALL except Bridge, Buffer, and Customer Satisfaction
	 *
	 * Excluded Countries of Order: Colombia
	 *
	 * The opportunity amount must not be greater than the opportunity amount captured on the most recent credit check.
	 *
	 * Error message custom label name: OrderManagement_Error18_6
	 */
	public Boolean func_rule18_6() {
		Boolean retval = null;
		Decimal creditOppAmount;
		if(mostRecentCredit == null || mostRecentCredit.Opportunity_Amount__c == null) {
			creditOppAmount = 0;
		}
		else {
			creditOppAmount = mostRecentCredit.Opportunity_Amount__c;
		}
		//Modified to make credit check compulsory for Channel Distributor as well
		//if(isDirect() && (opp.Country_of_Order__c == null || ! EXCLUDED_CREDIT_CHECK_COUNTRIES.contains(opp.Country_of_Order__c.toUpperCase()))) {
		if((isDirect() || fulfillmentChannel == Distributor) && (opp.Country_of_Order__c == null || ! EXCLUDED_CREDIT_CHECK_COUNTRIES.contains(opp.Country_of_Order__c.toUpperCase()))) {
			retval = (mostRecentCredit == null)||(creditOppAmount*(1.0+THRESHOLD_18_6) >= opp.Amount);
		}
		return reportResult(retval,'18.6',Label.OrderManagement_Error18_6);
	}

	/**
	 * Rule 19
	 *
	 * Regions: ALL
	 *
	 * Channels: Direct End Customer, OEM, Direct Reseller
	 *
	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
	 *
	 * A active quote or primary Big Machines quote is required on the Opportunity
	 */
	public Boolean func_rule19() {
		Boolean retval = null;
		if(notExempt()&&isDirect()) {
			retval = (primaryQuote != null)||(activeQuote != null);
		}
		return reportResult(retval,'19',ERROR19);
	}


	/**
	 * Rule 19.1
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: ALL except Bridge, Buffer, and Customer Satisfaction
	 *
	 * The amount on the the active quote and the amount on the opportunity must match.
	 * The active quote must have been calculated after the last time the
	 * close date on the opportunity was modified.
	 */
	public Boolean func_rule19_1() {
		Boolean retval = (primaryQuote == null)&&(activeQuote == null);
		if(! retval) {
			retval = (currencyAmount(opp.Amount,0.00) == quoteAmount)&&!isClosedDateModifiedSinceCalculated;
		}
		return reportResult(retval,'19.1',ERROR19_1);
	}

	/**
	 * Rule 19.2
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: Standard, Co-Term, Eval
	 *
	 * There must be a active Quote or primary Big Machines quote on the Opportunity when one
	 * or more of the products has the quote required flag checked.	As of 2011-09-11
	 * there are no products with this flag checked, so this rule can never fail.
	 */
	public Boolean func_rule19_2() {
		Boolean retval = null;
		if(notExempt2()) {
			retval = (primaryQuote != null)||(activeQuote != null)|| ! isQuoteRequired;
		}
		return reportResult(retval,'19.2',ERROR19_2);
	}

	/**
	 * Rule 20
	 *
	 * Regions: ALL
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
	 *
	 * The most recent ApprovalCustom__c record of type Non-Standard or Pricing Discount must either be
	 * in an approved state if Pricing Discount or be a approved or signed if Non-Standard.
	 */
	public Boolean func_rule20() {
		Boolean retval = null;
		if(notExempt()&&isDirect()) {
			retval = (recentApprovalCustom == null);
			if(! retval) {
				retval = (recentApprovalCustom.ApprovalStatus__c == APPROVED_PLV) || (
					recentApprovalCustom.RecordType != null
					&& NON_STANDARD == recentApprovalCustom.RecordType.Name
					&& (recentApprovalCustom.ApprovalStatus__c == SIGNED_PLV) );
			}
		}
		return reportResult(retval,'20',ERROR20);
	}

	/**
	 * Rule 20.1
	 *
	 * Regions: NA, APAC, LATAM
	 *
	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
	 *
	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
	 *
	 * Excluded Countries of Order: Colombia
	 *
	 * If the Active Quote has a Payment Terms Approval record
	 * AND the Approval record status equals Approved
	 * then the Payment Terms of the most recently created
	 * final credit check (or just the most recently created credit
	 * check if there is no final credit check) must match the Approved Payment Terms
	 * on the Approval record.
	 */
	public Boolean func_rule20_1() {
		Boolean retval = null;
		if ( notExempt()
			&& isDirect()
			&& (isNAUser()||isAPACUser()||isLATAMUser())
			&& (opp.Country_of_Order__c == null || ! EXCLUDED_CREDIT_CHECK_COUNTRIES.contains(opp.Country_of_Order__c.toUpperCase())))
		{
			retval = (possiblyFinalCredit == null)||(paymentTerms == null)||(paymentTerms.PaymentTermsApproved__c == possiblyFinalCredit.Payment_Terms__c);
		}
		return reportResult(retval,'20.1',ERROR20_1);
	}

//depreciated	/**
//depreciated	 * Rule 22
//depreciated	 *
//depreciated	 * Regions: EMEA
//depreciated	 *
//depreciated	 * Channels: Indirect – VAR/VAD
//depreciated	 *
//depreciated	 * Opportunity Types: ALL except Bridge, Buffer, and Customer Satisfaction
//depreciated	 *
//depreciated	 * If user role starts with EMEA and Channel equals Indirect – VAR/VAD
//depreciated	 * then the Channel Load Opportunity Number field is required
//depreciated	 */
//depreciated	/*Commented by nejaiswal@deloitte.com as values of the picklists are changed for fulfillmentChannel
//depreciated	public Boolean func_rule22() {
//depreciated		Boolean retval = null;
//depreciated		if((fulfillmentChannel == INDIRECT_VARVAD_PLV)&&isEMEAUser()) {
//depreciated			retval = (opp.Channel_Load_Opp__c != null);
//depreciated		}
//depreciated		return reportResult(retval,'22',ERROR22);
//depreciated	}*/
//depreciated	/*public Boolean func_rule22() {
//depreciated		Boolean retval = null;
//depreciated		if((fulfillmentChannel == Distributor)&&isEMEAUser()) {
//depreciated			retval = (opp.Channel_Load_Opp__c != null);
//depreciated		}
//depreciated		return reportResult(retval,'22',ERROR22);
//depreciated	}*/

	/**
	 * Rule 23
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: ALL except Bridge, Buffer, and Customer Satisfaction
	 *
	 * If there is a GPS services sku, then require the services contract type to be
	 * set to either TIME_AND_MATERIALS_PLV, or FIXED_PRICE_PLV engagement. For the purpose
	 * of this rule, a services sku is any product code or config sku that starts with
	 * a value found in the Services SKU custom setting.
	 *
	 * Error message custom label name: OrderManagement_Error23_0
	 */
	public Boolean func_rule23() {
		Boolean retval = ! hasGPSServices;
		if(! retval) {
			retval = (opp.Services_Contract_Type__c == TIME_AND_MATERIALS_PLV || opp.Services_Contract_Type__c == FIXED_PRICE_PLV);
		}
		return reportResult(retval,'23',Label.OrderManagement_Error23_0);
	}

//depreciated	/**
//depreciated	 * Rule 23.1 - DEACTIVATED
//depreciated	 *
//depreciated	 * Regions: ALL
//depreciated	 *
//depreciated	 * Channels: ALL
//depreciated	 *
//depreciated	 * Opportunity Types: ALL except Bridge, Buffer, and Customer Satisfaction
//depreciated	 *
//depreciated	 * If there is a GPS services sku, then require at least one services product line to
//depreciated	 * be selected.	For the purpose of this rule, a services sku is any product code or
//depreciated	 * config sku that starts with a value found in the Services SKU custom setting.
//depreciated	 *
//depreciated	 * Error message custom label name: OrderManagement_Error23_1
//depreciated	 */
//depreciated	//public Boolean func_rule23_1() {
//depreciated	//	Boolean retval = ! hasGPSServices;
//depreciated	//	if(! retval) {
//depreciated	//		retval = (opp.Services_Product_Line_1__c != null || opp.Services_Product_Line_2__c != null || opp.Services_Product_Line_3__c != null || opp.Services_Product_Line_4__c != null || opp.Services_Product_Line_5__c != null || opp.Services_Product_Line_6__c != null);
//depreciated	//	}
//depreciated	//	return reportResult(retval,'23.1',Label.OrderManagement_Error23_1);
//depreciated	//}

	/**
	 * Rule 24
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: ALL except Bridge, Buffer, and Customer Satisfaction
	 *
	 * A value must be supplied for the Future Reporting Requirement field.
	 *
	 * Error message custom label name: OrderManagement_Error24_0
	 */
	public Boolean func_rule24() {
		Boolean retval = (opp.Future_Reporting_Requirement__c != null);
		return reportResult(retval,'24',Label.OrderManagement_Error24_0);
	}

	/**
	 * Rule 25
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: Bridge, Buffer, and Customer Satisfaction
	 *
	 * Only finance can submit a Zero Value Opportunity.
	 *
	 * Error message custom label name: OrderManagement_Error25_0
	 */
	public Boolean func_rule25() {
		Boolean retval = (currentUser.Job_Function__c == 'Finance');
		return reportResult(retval,'25',Label.OrderManagement_Error25_0);
	}

	/**
	 * Rule 25.1
	 *
	 * Regions: ALL
	 *
	 * Channels: ALL
	 *
	 * Opportunity Types: Bridge, Buffer, & Customer Satisfaction
	 *
	 * Only approved Zero Value Opportunities can be submitted to order management.
	 *
	 * Error message custom label name: OrderManagement_Error25_1
	 */
	public Boolean func_rule25_1() {
		Boolean retval = (opp.ApprovalStatus__c == APPROVED_PLV);
		return reportResult(retval,'25',Label.OrderManagement_Error25_1);
	}

//depreciated	 //This rule is added to perforn the validations on the following fields if it has a null value, if yes then an error message will get displayed.
//depreciated		 /**
//depreciated	 * Rule 26
//depreciated	 *
//depreciated	 * Regions: ALL
//depreciated	 *
//depreciated	 * Channels: Direct End Customer, OEM, Direct – VAR/VAD, Direct – GTSI
//depreciated	 *
//depreciated	 * Opportunity Types: Standard, Co-Term, Eval, Runtime
//depreciated	 *
//depreciated	 * If any of the following field is null.
//depreciated	 */
//depreciated	/*public Boolean func_rule26() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Bill_To_Account__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Bill_To_Account__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.Ship_To_Account__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Ship_To_Account__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.Sold_To_Account__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Sold_To_Account__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.Entitle_To_Account__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Account__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.Ship_To_Address__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Ship_To_Address__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.Bill_To_Address__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Bill_To_Address__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.Ship_To_Address__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Ship_To_Address__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				if(opp.Entitle_To_Address__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Address__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				/*
//depreciated				added null field validation for Operating_Unit__c , as it should not be none.
//depreciated				*/
//depreciated				/*if(opp.Operating_Unit__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Operating_Unit__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}

//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(ERROR26+msgFields);
//depreciated				}


//depreciated		return reportResult(retval,'26',null);
//depreciated	}*/


	public Boolean func_rule38_1(boolean isSubmitOpp) {
		Boolean retval = null;
				String msgFields = '';
				String sep = '\n\t';
				if(opp.Bill_To_Account__c == null) {
					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Bill_To_Account__c.Label;
					sep = ',\n\t';
				}
				retval = (msgFields == '');
				if(! retval) {
					if(isSubmitOpp)
							ApexPages_Message_ControllerExtension.addErrorMessage(Error38_1);
					else
							ApexPages_Message_ControllerExtension.addInfoMessage(Error38_1_NoSubmit);
				}


		return reportResult(retval,'38.1',null);
	}

		//Commented as the part of the user story US63466
		public Boolean func_rule38_2(boolean isSubmitOpp) {
		Boolean retval = null;
				String msgFields = '';
				String sep = '\n\t';
				if(opp.Bill_To_Address__c == null) {
					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Bill_To_Address__c.Label;
					sep = ',\n\t';
				}
				retval = (msgFields == '');
				if(! retval) {
					if(isSubmitOpp)
							ApexPages_Message_ControllerExtension.addErrorMessage(Error38_2);
					else
							ApexPages_Message_ControllerExtension.addInfoMessage(Error38_2_NoSubmit);
				}


		return reportResult(retval,'38.2',null);
	}

//depreciated	/*public Boolean func_rule39_1() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Ship_To_Account__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Ship_To_Account__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(Error39_1);
//depreciated				}


//depreciated		return reportResult(retval,'39.1',null);

//depreciated	}

//depreciated	public Boolean func_rule39_2() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Ship_To_Address__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Ship_To_Address__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(Error39_2);
//depreciated				}


//depreciated		return reportResult(retval,'39.2',null);

//depreciated	}

//depreciated	public Boolean func_rule40_1() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Sold_To_Account__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Sold_To_Account__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(Error40_1);
//depreciated				}


//depreciated		return reportResult(retval,'40.1',null);

//depreciated	}

//depreciated		public Boolean func_rule40_2() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Sold_To_Address__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Sold_To_Address__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(Error40_2);
//depreciated				}


//depreciated		return reportResult(retval,'40.2',null);

//depreciated		}

//depreciated		public Boolean func_rule41_1() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Entitle_To_Account__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Account__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(Error41_1);
//depreciated				}


//depreciated		return reportResult(retval,'41.1',null);

//depreciated		}

//depreciated		public Boolean func_rule41_2() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Entitle_To_Address__c == null) {
//depreciated					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Address__c.Label;
//depreciated					sep = ',\n\t';
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(Error41_2);
//depreciated				}


//depreciated		return reportResult(retval,'41.2',null);

//depreciated		}

//depreciated		public Boolean func_rule42_1() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.OpportunityLineItems.size() > 0){
//depreciated						for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {
//depreciated								if(lineItem.Entitle_To_Account__c == null){
//depreciated										msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Account__c.Label;
//depreciated										sep = ',\n\t';
//depreciated										break;
//depreciated								}
//depreciated						}
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(Error42_1);
//depreciated				}

//depreciated		return reportResult(retval,'42.1',null);
//depreciated	}

//depreciated		public Boolean func_rule42_2() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.OpportunityLineItems.size() > 0){
//depreciated						for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {
//depreciated								if(lineItem.Entitle_To_Address__c == null){
//depreciated										msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Address__c.Label;
//depreciated										sep = ',\n\t';
//depreciated										break;
//depreciated								}
//depreciated						}
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(Error42_2);
//depreciated				}

//depreciated		return reportResult(retval,'42.2',null);
//depreciated		}*/


// Rule 27 is added as Validation rule to ensure that the Employee Number for the owner of the opportunity in the user record is populated was not checked when the order was submitted.

	public Boolean func_rule27() {
		Boolean retval = true;
				string employeeNumber = [Select id,EmployeeNumber from User where id = : opp.ownerId].EmployeeNumber;
				if(employeeNumber == null) {
				retval = true;
				ApexPages_Message_ControllerExtension.addErrorMessage(ERROR27);
			}
		return reportResult(retval,'27',null);
	}


	public Boolean func_rule28() {
		Boolean retval = null;
				String msgFields = '';
				String sep = '\n\t';
				if(opp.Bill_To_Address__c != null) {
						if(opp.Bill_To_Address__r.CDH_Party_Site_Number__c == null)
						{
								msgFields += sep + Schema.SObjectType.Opportunity.Fields.Bill_To_Address__c.Label;
								sep = ',\n\t';
						}
				}
				retval = (msgFields == '');
				if(! retval) {
					ApexPages_Message_ControllerExtension.addErrorMessage(ERROR28+msgFields+ERROR32);
				}


		return reportResult(retval,'28',null);
	}

//depreciated	//Commented as the part of user story US63466
//depreciated	/*public Boolean func_rule29() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Entitle_To_Address__c != null) {
//depreciated						if(opp.Entitle_To_Address__r.CDH_Party_Site_Number__c == null)
//depreciated						{
//depreciated								msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Address__c.Label;
//depreciated								sep = ',\n\t';
//depreciated						}
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(ERROR29+msgFields+ERROR32);
//depreciated				}


//depreciated		return reportResult(retval,'29',null);
//depreciated	}

//depreciated	public Boolean func_rule30() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Ship_To_Address__c != null) {
//depreciated						if(opp.Ship_To_Address__r.CDH_Party_Site_Number__c == null)
//depreciated						{
//depreciated								msgFields += sep + Schema.SObjectType.Opportunity.Fields.Ship_To_Address__c.Label;
//depreciated								sep = ',\n\t';
//depreciated						}
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(ERROR30+msgFields+ERROR32);
//depreciated				}


//depreciated		return reportResult(retval,'30',null);
//depreciated	}

//depreciated	public Boolean func_rule31() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Sold_To_Address__c != null) {
//depreciated						if(opp.Sold_To_Address__r.CDH_Party_Site_Number__c == null)
//depreciated						{
//depreciated								msgFields += sep + Schema.SObjectType.Opportunity.Fields.Sold_To_Address__c.Label;
//depreciated								sep = ',\n\t';
//depreciated						}
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(ERROR31+msgFields+ERROR32);
//depreciated				}


//depreciated		return reportResult(retval,'31',null);
//depreciated	}*/

	 public Boolean func_rule33() {
		Boolean retval = null;
				String msgFields = '';
				String sep = '\n\t';
				if(opp.Bill_To_Contact__c != null) {
						if(opp.Bill_To_Contact__r.CDH_Party__c == null)
						{
								msgFields += sep + Schema.SObjectType.Opportunity.Fields.Bill_To_Contact__c.Label;
								sep = ',\n\t';
						}
				}
				retval = (msgFields == '');
				if(! retval) {
					ApexPages_Message_ControllerExtension.addErrorMessage(ERROR33+msgFields+ERROR37);
				}


		return reportResult(retval,'33',null);
	}

//depreciated	 /*public Boolean func_rule34() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Entitle_To_Contact__c != null) {
//depreciated						if(opp.Entitle_To_Contact__r.CDH_Party__c == null)
//depreciated						{
//depreciated								msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Contact__c.Label;
//depreciated								sep = ',\n\t';
//depreciated						}
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(ERROR34+msgFields+ERROR37);
//depreciated				}


//depreciated		return reportResult(retval,'34',null);
//depreciated	}

//depreciated	public Boolean func_rule35() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Ship_To_Contact__c != null) {
//depreciated						if(opp.Ship_To_Contact__r.CDH_Party__c == null)
//depreciated						{
//depreciated								msgFields += sep + Schema.SObjectType.Opportunity.Fields.Ship_To_Contact__c.Label;
//depreciated								sep = ',\n\t';
//depreciated						}
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(ERROR35+msgFields+ERROR37);
//depreciated				}


//depreciated		return reportResult(retval,'35',null);
//depreciated	}

//depreciated	public Boolean func_rule36() {
//depreciated		Boolean retval = null;
//depreciated				String msgFields = '';
//depreciated				String sep = '\n\t';
//depreciated				if(opp.Sold_To_Contact__c != null) {
//depreciated						if(opp.Sold_To_Contact__r.CDH_Party__c == null)
//depreciated						{
//depreciated								msgFields += sep + Schema.SObjectType.Opportunity.Fields.Sold_To_Contact__c.Label;
//depreciated								sep = ',\n\t';
//depreciated						}
//depreciated				}
//depreciated				retval = (msgFields == '');
//depreciated				if(! retval) {
//depreciated					ApexPages_Message_ControllerExtension.addErrorMessage(ERROR36+msgFields+ERROR37);
//depreciated				}


//depreciated		return reportResult(retval,'36',null);
//depreciated	}*/

	/**
	 * The opportunity being submitted.
	 */
	public Opportunity opp {
		get {
			if(opp == null && oppId != null) {
				opp = [
					select
						AccountId,
						Account.PrimaryBillingAccountNumber__c,
						Account.BillingCountry,
						Account.IsAccountActive__c,
						Account.IsOnCreditHold__c,
						Account.Name,
						Account.OwnerId,
						Account.VATNumber__c,
						ApprovalStatus__c,
						Amount,
						Bill_To_Sales_Account__r.Name,
						Bill_To_Sales_Account__r.PrimaryBillingAccountNumber__c,
						Bill_To_Sales_Account__c,
						Bill_To_Account__r.Name,
						Bill_To_Account__c,
						Bill_To_Address__r.Name,
						Bill_To_Address__r.CDH_Party_Site_Number__c,
						Bill_To_Address__c,
						Bill_To_Contact__c,
						Bill_To_Contact__r.Name,
						Bill_To_Contact__r.CDH_Party__c,
						BillingAccountNumber__c,
						BillingAddress__c,
						BillingCity__c,
						BillingCountry__c,
						BillingState__c,
						BillingZipPostalCode__c,
						Channel_Load_Opp__c,
						CloseDate,
						ContractStartDate__c,
						Country_of_Order__c,
						CreatedDate,
						CreditCardType__c,
						Credit_Card_Number__c,
						CurrencyIsoCode,
						DateOrderBooked__c,
						DateOrderSubmitted__c,
						ExpirationDate__c,
						Entitle_To_Sales_Account__c,
						Entitle_To_Sales_Account__r.Name,
						Entitle_To_Account__c,
						Entitle_To_Account__r.Name,
						Entitle_To_Address__c,
						Entitle_To_Address__r.Name,
						Entitle_To_Address__r.CDH_Party_Site_Number__c,
						Entitle_To_Contact__c,
						Entitle_To_Contact__r.Name,
						Entitle_To_Contact__r.CDH_Party__c,
						FinancialPartnerName__c,
						FinancialPartner__r.PrimaryBillingAccountNumber__c,
						Future_Reporting_Requirement__c,
						FulfillmentChannel__c,
						HasOpportunityLineItem,
						IsClosed,
						IsOnSaleHold__c,
						OpportunityType__c,
						Owner.UserRole.Name,
						NameOnCard__c,
						Operating_Unit__c,
						Order_Type__c,
						Pay_Now__c,
						PaymentType__c,
						PO_Confirmed_By__c,
						PONumber__c,
						RecordType.Name,
						Region2__c,
						Renewable__c,
						Royalty_Type__c,
						Rush_Order__c,
						Rush_Order_Reason__c,
						Rush_Order_Set_By_System__c,
						Services_Contract_Type__c,
						Services_Product_Line_1__c,
						Services_Product_Line_2__c,
						Services_Product_Line_3__c,
						Services_Product_Line_4__c,
						Services_Product_Line_5__c,
						Services_Product_Line_6__c,
						StageName,
						Ship_To_Sales_Account__c,
						Ship_To_Sales_Account__r.Name,
						Ship_To_Account__c,
						Ship_To_Account__r.Name,
						Ship_To_Address__c,
						Ship_To_Address__r.Name,
						Ship_To_Address__r.CDH_Party_Site_Number__c,
						Ship_To_Contact__c,
						Ship_To_Contact__r.CDH_Party__c,
						Ship_To_Contact__r.Name,
						Sold_To_Sales_Account__c,
						Sold_To_Sales_Account__r.Name,

						Sold_To_Account__c,
						Sold_To_Account__r.Name,
						Sold_To_Address__c,
						Sold_To_Address__r.Name,
						Sold_To_Address__r.CDH_Party_Site_Number__c,
						Sold_To_Contact__c,
						Sold_To_Contact__r.Name,
						Sold_To_Contact__r.CDH_Party__c,
						ShippingAddress__c,
						ShippingCity__c,
						ShippingCountry__c,
						ShippingState__c,
						ShippingZipPostalCode__c,
						SubmitConfirmDate__c,
						SubmitConfirmUser__c,
						Year1Amount__c,
						Year2Amount__c,
						Year3Amount__c,
						Year4Amount__c,
						Year5Amount__c,
						Year6Amount__c,
						Year1PaymentAmount__c,
						Year2PaymentAmount__c,
						Year3PaymentAmount__c,
						Year4PaymentAmount__c,
						Year5PaymentAmount__c,
						Year6PaymentAmount__c,
						(	select
								Contract_Numbers__c,
								Configured_SKU__c,
								NewOrRenewal__c,
								PricebookEntry.ProductCode,
								PricebookEntry.Product2.Description,
								PricebookEntry.Product2.Family,
								PricebookEntry.Product2.Name,
								PricebookEntry.Product2.QuoteRequired__c,
								Entitle_To_Address__c,
								Entitle_To_Account__c
							from OpportunityLineItems )
					from Opportunity
					where Id = :oppId ];
			}
			return opp;
		}
		set;
	}

	private Boolean needActiveQuote = true;

	/**
	 * The Quote__c object marked as Active.	To be non-null either this object
	 * was created more recently than the primaryQuote, or the primaryQuote
	 * value is null.
	 */
	public Quote__c activeQuote {
		get {
			if(needActiveQuote) {
				needActiveQuote = false;
				DateTime createdDate = opp.CreatedDate;
				if(primaryQuote != null) {
					createdDate = (DateTime)primaryQuote.get('CreatedDate');
				}
				for(Quote__c q : [
					select
							Amount__c,
							CreatedDate,
							IsActive__c,
							LastCalculatedDate__c,
							Year1BookingAmount__c
						from Quote__c
						where IsActive__c=true
							and OpportunityId__c = :oppId
							and CreatedDate >= :createdDate
						limit 1 ] )
				{
					activeQuote = q;
				}
				needActiveQuote = false;
			}
			return activeQuote;
		}
		set {
			needActiveQuote = false;
			activeQuote = value;
			quoteAmount = null;
			isClosedDateModifiedSinceCalculated = null;
		}
	}

	public Boolean needPrimaryQuote = true;

	// There currently is a bug in setting the is primary flag, so we use a bit of
	// sorting to find one that should be primary.
	/**
	 * The BigMachines__Quote__c object marked as primary.	Currently this
	 * object is not available on sandboxes.	As such we use a dynamic query so
	 * this code can still be devoloped on sandboxes.
	 */
	public SObject primaryQuote {
		get {
			if(needPrimaryQuote) {
				if(Schema.getGlobalDescribe().containsKey('BigMachines__Quote__c')) {
					for(SObject bmq : Database.Query(
						'select'
						+ '	 BigMachines__Amount__c,'
						+ '	 BigMachines__Is_Primary__c,'
						+ '	 CreatedDate,'
						+ '	 LastModifiedDate'
						+ ' from BigMachines__Quote__c'
						+ ' where BigMachines__Opportunity__c = :oppId'
						+ '	 and BigMachines__Is_Primary__c = true'
						+ ' order by CreatedDate desc limit 1'))
					{
						primaryQuote = bmq;
					}
				}
				needPrimaryQuote = false;
			}
			return primaryQuote;
		}
		set {
			needPrimaryQuote = false;
			primaryQuote = value;
			quoteAmount = null;
			isClosedDateModifiedSinceCalculated = null;
		}
	}

	public Decimal quoteAmount {
		get {
			if(quoteAmount == null) {
				if(activeQuote != null) {
					quoteAmount = currencyAmount(activeQuote.Amount__c,0.00);
				}
				else if(primaryQuote != null) {
					quoteAmount = currencyAmount((Decimal)primaryQuote.get('BigMachines__Amount__c'),0.00);
				}
			}
			return currencyAmount(quoteAmount);
		}
		set {
			quoteAmount = currencyAmount(value);
		}
	}

	public Boolean isTeamMember {
		get {
			if(isTeamMember == null) {
				isTeamMember = ( [
					Select COUNT()
					from OpportunityTeamMember
					where OpportunityId = :oppId and
						UserId = :currentUser.Id and
						(OpportunityAccessLevel like '%Write%' or
						((not	OpportunityAccessLevel like '%Read%') and
						(not OpportunityAccessLevel like '%None%')))
					limit 1 ] > 0 );
			}
			return isTeamMember;
		}
		set;
	}

	public Boolean isShareMember {
		get {
			if(isShareMember == null) {
				isShareMember = ([
					select COUNT()
					from OpportunityShare
					where OpportunityId = :oppId and
						UserOrGroupId = :currentUser.Id and
						(OpportunityAccessLevel like '%Write%' or
						((not OpportunityAccessLevel like '%Read%') and
						(not OpportunityAccessLevel like '%None%')))
					limit 1] > 0 );
			}
			return isShareMember;
		}
		set;
	}

	public Boolean isAccountMember {
		get {
			if(isAccountMember == null) {
				isAccountMember = ([
					select COUNT()
					from AccountTeamMember
					where AccountId = :opp.AccountId and
						UserId = :currentUser.Id and
						(AccountAccessLevel like '%Write%' or
							((not AccountAccessLevel like '%Read%') and
							(not AccountAccessLevel like '%None%')))
					limit 1 ] > 0 );
			}
			return isAccountMember;
		}
		set;
	}

	public static Boolean isAdmin {
		get {
			if(isAdmin == null) {
				isAdmin = (AdminByPass__c.getInstance().IsAdmin__c == true);
			}
			return isAdmin;
		}
		set;
	}

	public static Boolean isEMEAUser() {
		return (currentUser.Region__c == EMEA);
	}

	public static Boolean isLATAMUser() {
		return (currentUser.Region__c == LATAM);
	}

	public static Boolean isAPACUser() {
		return (currentUser.Region__c == APAC);
	}

	public static Boolean isNAUser() {
		return (currentUser.Region__c == NA);
	}

//depreciated	/*
//depreciated	public Double conversionRate {
//depreciated		get {
//depreciated			if(conversionRate == null) {
//depreciated				conversionRate = 1;
//depreciated				List<DatedConversionRate> datedConversionRate = [
//depreciated					select
//depreciated						ConversionRate
//depreciated					from DatedConversionRate
//depreciated					where IsoCode = :opp.CurrencyIsoCode and
//depreciated						StartDate <= :opp.CloseDate
//depreciated					order by StartDate desc
//depreciated					limit 1 ];
//depreciated				if(datedConversionRate.isEmpty()) {
//depreciated					List<CurrencyType> currencyTypeList = [
//depreciated						select
//depreciated							ConversionRate,
//depreciated							IsoCode
//depreciated						from CurrencyType
//depreciated						where IsoCode = :opp.CurrencyIsoCode
//depreciated							and IsActive = true limit 1 ];
//depreciated					for(CurrencyType ct : currencyTypeList ) {
//depreciated						conversionRate = ct.ConversionRate;
//depreciated					}
//depreciated				}
//depreciated				else {
//depreciated					for(DatedConversionRate dcr : datedConversionRate) {
//depreciated						conversionRate = dcr.ConversionRate;
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			return conversionRate;
//depreciated		}
//depreciated		set;
//depreciated	}
//depreciated	*/

	public Map<String,Integer> repCountMap {
		get {
			if(repCountMap == null) {
				repCountMap = new Map<String,Integer>{
					INSIDE_REP_STRING=>0,
					OUTSIDE_REP_STRING=>0,
					CHANNEL_ACCOUNT_MANAGER_STRING=>0 };
				for(AggregateResult ar : [
					select TeamMemberRole, count(Id) roleCount
					from OpportunityTeamMember
					where OpportunityId = :oppId
						and TeamMemberRole in :repCountMap.keySet()
					group by TeamMemberRole ] )
				{
					String teamMemberRole = (String)ar.get('TeamMemberRole');
					Integer roleCount = (Integer)ar.get('roleCount');
					repCountMap.put(teamMemberRole.toUpperCase(),roleCount);
					System.debug('teamMemberRole='+teamMemberRole+',count='+roleCount);
				}
			}
			return repCountMap;
		}
		set;
	}

	public Integer insideRepCount() {
		return repCountMap.get(INSIDE_REP_STRING);
	}

	public Integer outsideRepCount() {
		return repCountMap.get(OUTSIDE_REP_STRING);
	}

	public Integer channelAccountManagerCount() {
		return repCountMap.get(CHANNEL_ACCOUNT_MANAGER_STRING);
	}

	public Boolean hasNonOpenEnrollment {


		get {

			if(hasNonOpenEnrollment == null) {
				hasNonOpenEnrollment = false;

				for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {

					if(lineItem.PricebookEntry == null
						|| lineItem.PricebookEntry.Product2 == null
						|| (! (''+lineItem.PricebookEntry.Product2.Name).containsIgnoreCase('OPEN ENROLLMENT')) &&
							(! (''+lineItem.PricebookEntry.Product2.Description).containsIgnoreCase('OPEN ENROLLMENT')) )
					{
						hasNonOpenEnrollment = true;
						break;
					}
				}
			}
			return hasNonOpenEnrollment;
		}
		set;
	}

	public Boolean hasRenewalButNoContractNumbers {
		get {
			if(hasRenewalButNoContractNumbers == null) {
				hasRenewalButNoContractNumbers = false;
				for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {
					if((lineItem.Contract_Numbers__c == null || lineItem.Contract_Numbers__c == '') &&
						(lineItem.NewOrRenewal__c == RENEWAL_PLV || lineItem.NewOrRenewal__c == RENEWAL_SKU_CHANGE_PLV) )
					{
						hasRenewalButNoContractNumbers = true;
						break;
					}
				}
			}
			return hasRenewalButNoContractNumbers;
		}
		set;
	}

	public Boolean hasInvalidRenewals {
		get {
			if(hasInvalidRenewals == null) {
				hasInvalidRenewals = false;
				for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {
					// check if this is has sku for a renewal
					if( (''+lineItem.Configured_SKU__c).endsWithIgnoreCase('RN') ||
						(lineItem.PricebookEntry != null && (''+lineItem.PricebookEntry.ProductCode).endsWithIgnoreCase('RN')) )
					{
						// check if either contract numbers are missing or the NewOrRenewal__c flag is set incorrectly
						if( lineItem.Contract_Numbers__c == null ||
							lineItem.Contract_Numbers__c == '' ||
							(lineItem.NewOrRenewal__c != RENEWAL_PLV && lineItem.NewOrRenewal__c != RENEWAL_SKU_CHANGE_PLV) )
						{
							hasInvalidRenewals = true;
							break;
						}
					}
				}
			}
			return hasInvalidRenewals;
		}
		set;
	}

	public Boolean hasNonServices {
		get {
			if(hasNonServices == null) {
				hasNonServices = false;
				for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {
					if(lineItem.PricebookEntry == null ||
						lineItem.PricebookEntry.Product2 == null ||
							(lineItem.PricebookEntry.Product2.Family != MANAGEMENT_SERVICES_PLV &&
								lineItem.PricebookEntry.Product2.Family != PLATFORM_SERVICES_PLV &&
								lineItem.PricebookEntry.Product2.Family != MIDDLEWARE_SERVICES_PLV ) )
					{
						hasNonServices = true;
						break;
					}
				}
			}
			return hasNonServices;
		}
		set;
	}

	public Boolean hasGPSServices {
		get {
			if(hasGPSServices == null) {
				hasGPSServices = false;
				for(String s : GPS_SERVICES_SKU_SET) {
					if(! hasGPSServices) {
						for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {
							if((''+lineItem.Configured_SKU__c).startsWithIgnoreCase(s) ||
								(lineItem.PricebookEntry != null &&
									lineItem.PricebookEntry.Product2 != null &&
									(''+lineItem.PricebookEntry.ProductCode).startsWithIgnoreCase(s) ) )
							{
								hasGPSServices = true;
								break;
							}

						}
					}
				}
			}
			return hasGPSServices;
		}
		set;
	}

	public Boolean hasNewProducts {
		get {
			if(hasNewProducts == null) {
				hasNewProducts = false;
				for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {
					if(lineItem.NewOrRenewal__c == NEW_PLV) {
						hasNewProducts = true;
						break;
					}
				}
			}
			return hasNewProducts;
		}
		set;
	}

	public Boolean hasProducts {
		get {
			return (hasProducts == true)||((hasProducts == null)&&opp.HasOpportunityLineItem);
		}
		set;
	}

	public Boolean isQuoteRequired {
		get {
			if(isQuoteRequired == null) {
				isQuoteRequired = false;
				for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {
					if(lineItem.PricebookEntry != null && lineItem.PricebookEntry.Product2 != null && lineItem.PriceBookEntry.Product2.QuoteRequired__c == true) {
						isQuoteRequired = true;
						break;
					}
				}
			}
			return isQuoteRequired;
		}
		set;
	}

	public Boolean isPurchaseOrderPaymentType {
		get {
			return (opp.PaymentType__c != null)&&(opp.PaymentType__c.indexOf(PURCHASE_ORDER) != -1);
		}
	}

	public Integer payablesContactCount {
		get {
			if(payablesContactCount == null) {
				payablesContactCount = [
					select COUNT()
					from OpportunityContactRole
					where OpportunityId = :oppId and Role = :PAYABLES_CONTACT_PLV ];
			}
			return payablesContactCount;
		}
		set;
	}

	public Integer shippingContactCount {
		get {
			if(shippingContactCount == null) {
				shippingContactCount = [
					select COUNT()
					from OpportunityContactRole
					where OpportunityId = :oppId and Role = :SHIPPING_CONTACT_PLV ];
			}
			return shippingContactCount;
		}
		set;
	}

	public Boolean isShippingContactInvalid {
		get {
			if(isShippingContactInvalid == null) {
				isShippingContactInvalid = ( [
					select COUNT()
					from OpportunityContactRole
					where OpportunityId = :oppId
						and Role = :SHIPPING_CONTACT_PLV
						and ((not Contact.Email like '%_@_%.%_%') or (not Contact.LoginName__c like '%_%'))
					limit 1 ] > 0 );
			}
			return isShippingContactInvalid;
		}
		set;
	}

	public Boolean hasAttachments {
		get {
			if(hasAttachments == null) {
				hasAttachments = ([select COUNT() from Attachment where ParentId = :oppId limit 1] > 0);
			}
			return hasAttachments;
		}
		set;
	}

	public Boolean isClosedDateModifiedSinceCalculated {
		get {
			if(isClosedDateModifiedSinceCalculated == null) {
				DateTime lastCalculatedDate = null;
				if(activeQuote != null) {
					lastCalculatedDate = activeQuote.LastCalculatedDate__c;
				}
				else if(primaryQuote != null) {
					lastCalculatedDate = (DateTime)primaryQuote.get('LastModifiedDate');
				}
				isClosedDateModifiedSinceCalculated = (lastCalculatedDate == null) || ( [
					select COUNT()
					from OpportunityHistory
					where OpportunityId = :oppId
						and CloseDate != :opp.CloseDate
						and SystemModstamp > :lastCalculatedDate
					limit 1 ] > 0 );
			}
			return isClosedDateModifiedSinceCalculated;
		}
		set;
	}

	private Boolean needPossiblyFinalCredit = true;

	/**
	 * The most recent final credit, if there is one.	Otherwise just the most
	 * recent credit.
	 */
	public Credit__c possiblyFinalCredit {
		get {
			if(needPossiblyFinalCredit) {
				for(Credit__c c : [
					select
						BillingAccountNumberUsed__c,
						Credit_Stage__c,
						LastModifiedDate,
						IsFinal__c,
						Opportunity_Amount__c,
						Payment_Terms__c
					from Credit__c
					where Opportunity__c = :oppId
					order by IsFinal__c desc nulls last, CreatedDate desc
					limit 1 ] )
				{
					possiblyFinalCredit = c;
				}
				needPossiblyFinalCredit = false;
			}
			return possiblyFinalCredit;
		}
		set {
			needPossiblyFinalCredit = false;
			possiblyFinalCredit = value;
		}
	}

	private Boolean needMostRecentCredit = true;

	/**
	 * The most recent final credit modified in the last 105 days, if there is one.	Otherwise just the most
	 * recent credit modified in the last 105 days.
	 */
	public Credit__c mostRecentCredit {
		get {
			if(needMostRecentCredit) {
				mostRecentCredit = possiblyFinalCredit;
				if(mostRecentCredit != null) {
					DateTime oldest = DateTime.newInstance(System.today().addDays(-integerValueMap.get(MAX_DAYS_OLD_SETTING)),Time.newInstance(0,0,0,0));
					if(mostRecentCredit.IsFinal__c == true) {
						for(Credit__c c : [
							select
								BillingAccountNumberUsed__c,
								Credit_Stage__c,
								LastModifiedDate,
								IsFinal__c,
								Opportunity_Amount__c,
								Payment_Terms__c
							from Credit__c
							where Opportunity__c = :oppId
								and LastModifiedDate >= :oldest
							order by CreatedDate desc
							limit 1 ] )
						{
							mostRecentCredit = c;
						}
					}
					if(mostRecentCredit.LastModifiedDate < oldest) {
						mostRecentCredit = null;
					}
				}
				needMostRecentCredit = false;
			}
			return mostRecentCredit;
		}
		set {
			needMostRecentCredit = false;
			mostRecentCredit = value;
		}
	}

	/**
	 * This value may be set in test classes.
	 */
	public transient DateTime possiblyFinalCreditLastModifiedDateTest = null;

	/**
	 * Returns the value possiblyFinalCredit.LastModifiedDate
	 */
	private DateTime getPossiblyFinalCreditLastModifiedDate() {
		DateTime retval = possiblyFinalCreditLastModifiedDateTest;
		if(retval == null && possiblyFinalCredit != null) {
			retval = possiblyFinalCredit.LastModifiedDate;
		}
		return retval;
	}

	public Boolean needRecentApprovalCustom = true;

	/**
	 * Obtain the most recent ApprovalCustom__c object with a NON_STANDARD or PRICING_DISCOUNT
	 * Record Type for the active quote.
	 */
	public ApprovalCustom__c recentApprovalCustom {
		get {
			if(needRecentApprovalCustom) {
				if(activeQuote != null) {
					for(ApprovalCustom__c ac : [
						select RecordType.Name, ApprovalStatus__c
						from ApprovalCustom__c
						where Quote__c = :activeQuote.Id
							and RecordType.Name in (:NON_STANDARD,:PRICING_DISCOUNT)
						order by CreatedDate DESC
						limit 1 ] )
					{
						recentApprovalCustom = ac;
					}
				}
				needRecentApprovalCustom = false;
			}
			return recentApprovalCustom;
		}
		set {
			needRecentApprovalCustom = false;
			recentApprovalCustom = value;
		}
	}

	private Boolean needPaymentTerms = true;

	/**
	 * Obtain the payment terms for the most recent approved payment tems
	 * ApprovalCustom__c record for the active quote.
	 */
	public ApprovalCustom__c paymentTerms {
		get {
			if(needPaymentTerms) {
				if(activeQuote != null) {
					for(ApprovalCustom__c ac : [
						select
							ApprovalStatus__c,
							PaymentTermsApproved__c,
							RecordTypeId
						from ApprovalCustom__c
						where Quote__c = :activeQuote.Id
							and RecordType.Name = :PAYMENT_TERMS
							and ApprovalStatus__c=:APPROVED_PLV
						order by CreatedDate desc
						limit 1 ] )
					{
						paymentTerms = ac;
					}
				}
				needPaymentTerms = false;
			}
			return paymentTerms;
		}
		set {
			needPaymentTerms = false;
			paymentTerms = value;
		}
	}

	/**
	 * Set true of the is not a purchase order payment or the purchase order has
	 * been confirmed.
	 */
	public Boolean poConfirmFlag {
		get {
			return (poConfirmFlag == true) || !isPurchaseOrderPaymentType;
		}
		set {
			poConfirmFlag = value;
			opp.SubmitConfirmDate__c = System.today();
			opp.SubmitConfirmUser__c = Userinfo.getUserId();
			needsUpdate = true;
		}
	}

//depreciated		/**
//depreciated		 *Commented by nejaiswal@deloitte.com as the picklist values are changed for fulfillment channels.
//depreciated	 * Test if the fulfillment channel is one of the standard Direct channels of
//depreciated	 * Direct End Customer, Direct GTSI, Direct OEM, or Direct VAR/VAD.
//depreciated	 *
//depreciated	 * @returns true if one of the standard direct fulfillment channels.
//depreciated	 */
//depreciated	/*
//depreciated	public Boolean isDirect() {
//depreciated		return (fulfillmentChannel == DIRECT_END_CUSTOMER_PLV) ||
//depreciated			(fulfillmentChannel == DIRECT_GTSI_PLV) ||
//depreciated			(fulfillmentChannel == DIRECT_OEM_PLV) ||
//depreciated			(fulfillmentChannel == DIRECT_VARVAD_PLV);
//depreciated	}*/

	/**
	 * Test if the fulfillment channel is one of the standard Direct channels of
	 * Direct End Customer, Direct Reseller, OEM.
	 *
	 * @returns true if one of the standard direct fulfillment channels.
	 */
	public Boolean isDirect() {
		return (fulfillmentChannel == DIRECT_END_CUSTOMER_PLV) ||
						(fulfillmentChannel == OEM_PLV) ||
				 (fulfillmentChannel == Direct_Reseller);
	}

	/**
	 * Test if this is a direct fulfillment channel.
	 *
	 * @returns True if the FulfillmentChannel name begins with DIRECT
	 */
	public Boolean isFulfillmentChannelDirect() {
		return (fulfillmentChannel != null)&&(fulfillmentChannel.indexOf(DIRECT) == 0);
	}

	public String opportunityType {
		get {
			if(opportunityType == null) {
				opportunityType = convertLongDash(opp.OpportunityType__c);
			}
			return opportunityType;
		}
		set;
	}

	public String fulfillmentChannel {
		get {
			if(fulfillmentChannel == null) {
				fulfillmentChannel = convertLongDash(opp.FulfillmentChannel__c);
			}
			return fulfillmentChannel;
		}
		set;
	}

//depreciated		/**
//depreciated		 //commented by nejaiswal@deloitte.com as picklist values for opportunityType are changed.
//depreciated	 * Returns false if OpportunityType__c in (Royalty, Royalty - EMEA, REBOOK, Hosting, Hosting - Initial, OM Exception)
//depreciated	 * @returns true if OpportunityType__c in (Standard, Co-Term, Eval, Runtime)
//depreciated	 */
//depreciated	/*
//depreciated	public Boolean notExempt() {
//depreciated		return notExempt1()
//depreciated			&& (opportunityType != OM_EXCEPTION_PLV)
//depreciated			&& (opportunityType != HOSTING_PLV)
//depreciated			&& (opportunityType != ROYALTY_PLV)
//depreciated			&& (opportunityType != ROYALTY_EMEA_PLV);
//depreciated	}*/

	/**
	 * Returns false if OpportunityType__c in (	REBOOK)
	 * @returns true if OpportunityType__c in (Standard, Co-Term, Eval, Runtime)
	 */
	public Boolean notExempt() {
		return notExempt1();
	}


//depreciated	/**
//depreciated	 //commented by nejaiswal@deloitte.com as the picklist values for OpportunityType__c are changed.
//depreciated	 * Returns false if OpportunityType__c in (REBOOK, Hosting - Initial)
//depreciated	 * @returns true if OpportunityType__c in (Standard, Co-Term, Eval, Runtime, Royalty, Royalty - EMEA, Hosting, OM Exception)
//depreciated	 */
//depreciated	/*
//depreciated	public Boolean notExempt1() {
//depreciated		return notExempt2() && (opportunityType != HOSTING_INITIAL_PLV);
//depreciated	}*/

	/**
	 * Returns false if OpportunityType__c in (REBOOK)
	 * @returns true if OpportunityType__c in (Standard, Co-Term, Eval)
	 */
	public Boolean notExempt1() {
		return notExempt2();
	}

//depreciated		/**
//depreciated		 //commented by nejaiswal@deloitte.com as the picklist values for OpportunityType__c are changed.
//depreciated	 * Returns false if OpportunityType__c == REBOOK,
//depreciated	 * @returns true if OpportunityType__c in (Standard, Co-Term, Eval, Runtime, Royalty, Royalty - EMEA, Hosting, Hosting - Initial, OM Exception)
//depreciated	 */
//depreciated	/*
//depreciated	public Boolean notExempt2() {
//depreciated		return (opportunityType != REBOOK_PLV);
//depreciated	}
//depreciated	*/

	/**
	 * Returns false if OpportunityType__c == REBOOK,
	 * @returns true if OpportunityType__c in (Standard, Co-Term, Eval )
	 */
	public Boolean notExempt2() {

		return (opportunityType != REBOOK_PLV);
	}

	private Boolean mayShowResubmitMessage = false;

	/**
	 * Returns true if the resubmit message maybe shown.
	 */
	public Boolean getShowResubmitMessage() {
		return mayShowResubmitMessage && ApexPages.hasMessages(ApexPages.Severity.ERROR);
	}

	public Boolean hasMessages {
		get {
			return ApexPages.hasMessages();
		}
	}

	/**
	 * Returns true if the order should be marked "rush" due to a contract start date before the SLA expires for order processing.
	 */
	private Boolean rushOrderDueToSLA() {
		return opp.ContractStartDate__c != null && datetime.now().addHours(48) > opp.ContractStartDate__c;
	}

	/**
	 * Returns true if the order should be marked "rush" due to a product exception.
	 */
	private Boolean rushOrderDueToProductException() {
		Boolean retval = false;
		Map<String, RushOrderSKU__c> exceptionSKUs = RushOrderSKU__c.getAll();
		if (exceptionSKUs.size() > 0) {
			for (OpportunityLineItem oppProduct : opp.OpportunityLineItems) {
				if(oppProduct.PricebookEntry != null) {
					String SKU = oppProduct.PricebookEntry.ProductCode;
					if (exceptionSKUs.keySet().contains(SKU)) {
						retval = true;
						break;
					}
				}
			}
		}
		return retval;
	}

	public void updateRushOrder() {
		if (opp.Rush_Order__c != true) {
			String rushReason;
			if (rushOrderDueToSLA()) {
				rushReason = RUSH_SLA_TIME_PERIOD;
			}
			else if (rushOrderDueToProductException()) {
				rushReason = RUSH_PRODUCT_EXCEPTION;
			}
			if (rushReason != null) {
				opp.Rush_Order__c = true;
				opp.Rush_Order_Set_By_System__c = true;
				opp.Rush_Order_Reason__c = rushReason;
				needsUpdate = true;
			}
		}
	}

	private void updateClosedWon() {
		//opp.StageName = CLOSED_WON_PLV;//Commented by Niti as this is redundant and reassigned in updateOpportunity method
		needsUpdate = true;
	}

	private void updateClosedBooked() {
		poConfirmFlag=false;
		opp.DateOrderBooked__c = System.now();
		needsUpdate = true;
	}

	private void updateOpportunity() {
		needsUpdate = false;
		opp.DateOrderSubmitted__c = System.Now();
		opp.PO_Confirmed_By__c = poConfirmFlag?(user.FirstName + ' ' + user.LastName):null;
		opp.DateOrderBooked__c = system.Now();

		//This logic is added to set some of the field values when opportunity is closed won.Also it will create a record in Order track custom object.

//depreciated	US72618
//depreciated		//touched will be set as true.
//depreciated		opp.Touched__c = true;

		//this checkbox will be checked for OM team review.
		opp.Pending_OM_Review__c = true;

		//creating a record entry for opportunity succeessfully updates:
		Order_Tracking__c opportunityRecordEntryInOrderTracking = new Order_Tracking__c();

		//this will be the reference to the opportunity that is submitted for OM review.
		opportunityRecordEntryInOrderTracking.Opportunity__c = opp.id;

		//Submitted by is the name of the Sales rep who submitted the opportunity as an order
		opportunityRecordEntryInOrderTracking.Submitted_By__c = UserInfo.getUserId();

		//This will be defaulted to ‘Submitted for OM Review’ in this step
		opportunityRecordEntryInOrderTracking.Order_Status__c = 'Submitted for OM Review';

		//The Date when the Sales rep submits the opportunity as an order
		opportunityRecordEntryInOrderTracking.Submitted_Date__c = System.Now();

		//The current stage of the opportunity when the sales rep submits the opportunity as an order. This would be one of the open stages on an opportunity
		opportunityRecordEntryInOrderTracking.Opportunity_Stage__c = 'Closed Won' ;

		//inserting a record in order tracking object.
		insert opportunityRecordEntryInOrderTracking;

		//changing the stage of the opportunity as closed -won in this step.
		//opp.StageName = 'Closed Won' ;
		opp.CloseDate = system.today();
		opp.Order_Status__c = 'Submitted for OM Review';
		//selecting a recordtype on the submit of an opportunity and making read-only fields for sales rep.
		//opp.RecordTypeId = [select Id from RecordType where Name = 'Submit Opportunity By Sales Rep' and SobjectType = 'Opportunity' And DeveloperName = 'Submit_Opportunity_By_Sales_Rep' limit 1].id;
		//updating opportunity here.

		update opp;

		//For Defect DE7541
		//Changes made by Niti so that stage is changed to 'Closed Won'(eventually locking opp) after	after-triggers on opportunity execute.Hence, Opportunity can be submitted without any Exceptions.
		opp.StageName = 'Closed Won' ;
		update opp;


		List<Database.Error> errors = new List<Database.Error>();
		if(opp.Renewable__c == YES_PLV) {
			opp.Renewable__c = DEFERRED_PLV;
			errors.addAll(Database.update(opp,false).getErrors());
			opp.Renewable__c = YES_PLV;
		}
		errors.addAll(Database.update(opp,false).getErrors());
		for(Database.Error e : errors) {
			ApexPages_Message_ControllerExtension.addErrorMessage('Failed to update opportunity: '+e.getMessage());
		}
	}

	public static void addInfoMessage(String infoMessage) {
		if(infoMessage != null && getBooleanSettingValue(HIDE_MESSAGES_SETTING) == false) {
			ApexPages_Message_ControllerExtension.addInfoMessage(infoMessage);
		}
	}

	/**
	 * Controls if an message number will be shown as part of the error.
	 */
	public static Boolean reportErrorNumber {
		get {
			return (reportErrorNumber != false);
		}
		set;
	}

	public static Boolean reportResult(Boolean retval,String ruleName,String errorMessage) {
		if(retval == null) {
			retval = true;
			addInfoMessage('Rule '+ruleName+' - skipped');
		}
		else if(retval) {
			addInfoMessage('Rule '+ruleName+' - passed');
		}
		else if(errorMessage != null) {
			if(errorMessage != '' && ! reportErrorNumber) {
				errorMessage = errorMessage.substring(errorMessage.indexof(':')+1).trim();
			}
			ApexPages_Message_ControllerExtension.addErrorMessage(errorMessage);
		}
		return retval;
	}


	public static Id zeroValueOpportunityRecordTypeId {
		get {
			return RecordTypeLookup.getRecordTypeId('Zero Value Opportunity','Opportunity');
		}
	}


//depreciated	 /**Commented by nejaiswal@deloitte.com as the changes in the picklist values of opportunityType , payment Type and fullfillmentchannel.
//depreciated	 * Called to submit the order to order management.

//depreciated	public PageReference updateSubmitOrder() {
//depreciated		String paymentType = convertLongDash(opp.PaymentType__c);
//depreciated		String accountName = convertLongDash(opp.Account.Name);
//depreciated		Id accountId = opp.AccountId;


//depreciated		updateRushOrder();
//depreciated		if(opp.RecordTypeId != null && opp.RecordTypeId == zeroValueOpportunityRecordTypeId) {
//depreciated			updateClosedWon();
//depreciated			system.debug('test 1 logic comes here-->'+opp.RecordTypeId);
//depreciated		}
//depreciated		else if((fulfillmentChannel == DIRECT_OEM_PLV)
//depreciated			&& (opportunityType == ROYALTY_PLV)
//depreciated			&& paymentType == APAC_PURCHASE_ORDER
//depreciated			&& (accountName == 'Hitachi,Ltd.,' || accountId == '001300000094XMJ' // Hitachi
//depreciated				|| accountName == 'NEC Corporation' || accountId == '001300000094XOB' // NEC
//depreciated				|| accountName == 'Fujitsu Limited' || accountId == '001300000094XWT' // Fujitsu
//depreciated		)) {
//depreciated			updateClosedWon();
//depreciated			system.debug('test 2 logic comes here-->'+opportunityType);
//depreciated		}
//depreciated		else if((opportunityType == HOSTING_INITIAL_PLV)
//depreciated			|| (opportunityType == REBOOK_PLV)
//depreciated			|| (opportunityType == ROYALTY_EMEA_PLV) )
//depreciated		{
//depreciated			updateClosedWon();
//depreciated			system.debug('test 3 logic comes here-->'+opportunityType);
//depreciated		}
//depreciated		else if((opportunityType == OM_EXCEPTION_PLV)
//depreciated			|| (opportunityType == HOSTING_PLV)
//depreciated			|| (opportunityType == ROYALTY_PLV) )
//depreciated		{
//depreciated			updateClosedBooked();
//depreciated			system.debug('test 4 logic comes here-->'+opportunityType);
//depreciated		}
//depreciated		else if(paymentType == CHANNEL_FULFILLMENT) {
//depreciated			updateClosedBooked();
//depreciated			system.debug('test 5 logic comes here-->'+paymentType);
//depreciated		}
//depreciated		else if((fulfillmentChannel == DIRECT_DLT_PLV)
//depreciated			|| (fulfillmentChannel == DIRECT_CARAHSOFT_PLV)
//depreciated			|| (fulfillmentChannel == INDIRECT_VARVAD_PLV)
//depreciated			|| (fulfillmentChannel == INDIRECT_WEBSTORE_PLV)
//depreciated			|| (fulfillmentChannel == INDIRECT_INTERNAL_COMMISSIONS_CREDIT_PLV)
//depreciated			|| (fulfillmentChannel == INDIRECT_OEM_PRELOAD_PLV) )
//depreciated		{
//depreciated			updateClosedBooked();
//depreciated		}
//depreciated		else {
//depreciated			System.assertEquals(true,isDirect());
//depreciated			updateClosedWon();
//depreciated			system.debug('test 6 logic comes here-->');
//depreciated		}
//depreciated		if(needsUpdate) {
//depreciated			updateOpportunity();
//depreciated			system.debug('test 7 logic comes here-->'+needsUpdate);
//depreciated		}

//depreciated		PageReference retval = null;
//depreciated		if(! ApexPages.hasMessages(ApexPages.Severity.ERROR)) {
//depreciated			retval = System.Page.OrderManagementSuccess;
//depreciated			retval.setRedirect(false);
//depreciated			retval.getParameters().put('id',oppId);
//depreciated			for(Opportunity o : [select Name, StageName from Opportunity where Id = :oppId]) {
//depreciated				ApexPages_Message_ControllerExtension.addInfoMessage('Opportunity "'+o.Name+'" is now '+o.StageName+'.');
//depreciated			}
//depreciated		}
//depreciated		return retval;
//depreciated	}
//depreciated	 */

	/**
	 * Called to submit the order to order management.
	 */
	public PageReference updateSubmitOrder() {
		String paymentType = convertLongDash(opp.PaymentType__c);
		String accountName = convertLongDash(opp.Account.Name);
		Id accountId = opp.AccountId;


		updateRushOrder();
		if(opp.RecordTypeId != null && opp.RecordTypeId == zeroValueOpportunityRecordTypeId) {
			updateClosedWon();
		}

		else if((fulfillmentChannel == OEM_PLV)
			&& paymentType == PURCHASE_ORDER
			&& (accountName == 'Hitachi,Ltd.,' || accountId == '001300000094XMJ' // Hitachi
				|| accountName == 'NEC Corporation' || accountId == '001300000094XOB' // NEC
				|| accountName == 'Fujitsu Limited' || accountId == '001300000094XWT' // Fujitsu
		)) {
			updateClosedWon();
		}
		else if((opportunityType == REBOOK_PLV))

		{
			updateClosedWon();
		}

		else if(paymentType == PURCHASE_ORDER) {
			updateClosedBooked();
		}

		else if((fulfillmentChannel == Distributor)
			|| (fulfillmentChannel == WEBSTORE_PLV)
			|| (fulfillmentChannel == NAChannel) )
		{
			updateClosedBooked();
		}
		else {
			//System.assertEquals(true,isDirect());
			updateClosedWon();
		}
		system.debug('==============================>'+opp.StageName);
		//system.debug('==============================>test'+[select id,name,StageName from opportunity where id=:opp.id].StageName);
		if(needsUpdate) {
			updateOpportunity();
		}
		//system.debug('==============================>'+[select id,name,StageName from opportunity where id=:opp.id].StageName);

		PageReference retval = null;
		if(! ApexPages.hasMessages(ApexPages.Severity.ERROR)) {
			retval = System.Page.OrderManagementSuccess;
			retval.setRedirect(false);
			retval.getParameters().put('id',oppId);
			for(Opportunity o : [select Name, StageName from Opportunity where Id = :oppId]) {
				ApexPages_Message_ControllerExtension.addInfoMessage('Opportunity "'+o.Name+'" is now '+o.StageName+'.');
			}
		}
		return retval;
	}

	/**
	 * Run all the submit order rules.
	 */
	public PageReference validateOrder() {
		if(opp.RecordTypeId != null && opp.RecordTypeId == zeroValueOpportunityRecordTypeId) {
			mayShowResubmitMessage = func_rule25();
			func_rule25_1();
		}
		else {
			mayShowResubmitMessage = false;
			if(func_rule00()) {
//depreciated				//if(func_rule1() && func_rule1_1()) {
				if(func_rule1()) {
					mayShowResubmitMessage = true;
					func_rule2();
					func_rule2_1();
					func_rule3();
//depreciated					//func_rule3_1();
//depreciated					//func_rule3_2();
					func_rule4();
					func_rule5();
					func_rule5_1();

					func_rule7();
					func_rule8();
					func_rule8_1();
					func_rule9();
					func_rule10_1();
					func_rule11();
					func_rule12();
					func_rule12_1();
//depreciated					/* Commented Reasons for commenting them out. Contact roles might not be used in future as we are using the 4 lookups for contact (Bill-To, Ship-To, Sold-To and Entitle-To).
//depreciated					func_rule13();
//depreciated					func_rule14();
//depreciated					func_rule15();

//depreciated					func_rule6();
//depreciated					*/
					func_rule16();
					func_rule17();
					func_rule18();
					func_rule18_1();
					func_rule18_4();
					func_rule18_5();
					func_rule18_6();
					func_rule19();
					func_rule19_1();
					func_rule19_2();
					func_rule20();
					func_rule20_1();
//depreciated					//func_rule22();
					func_rule23();
//depreciated					//func_rule23_1();
					func_rule24();

//depreciated					//added this function to check the field values for 7 look-ups values.
//depreciated					//func_rule26();
					//added this function to check if the employee number of the user i.e. opportunity owner is not blank.
					func_rule27();
					func_rule28();
//depreciated					/*func_rule29();
//depreciated					func_rule30();
//depreciated					func_rule31();*/

					func_rule33();
//depreciated					/*func_rule34();
//depreciated					func_rule35();
//depreciated					func_rule36();*/

					func_rule38_1(TRUE);
					func_rule38_2(TRUE);
//depreciated					/*func_rule39_1();
//depreciated					func_rule39_2();
//depreciated					func_rule40_1();
//depreciated					func_rule40_2();
//depreciated					func_rule41_1();
//depreciated					func_rule41_2();
//depreciated					func_rule42_1();
//depreciated					func_rule42_2();*/
				}
			}
		}
		return null;
	}

	private without sharing class runAsAdmin {
		Database.SaveResult updateSObject(SObject o) {
			return Database.update(o,false);
		}
	}
}