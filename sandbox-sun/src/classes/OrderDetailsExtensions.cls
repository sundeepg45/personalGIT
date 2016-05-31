/**
 * Used to create order details for a opportunity, validate address when creating new one.
 * 
 * @version 2016-02-08
 * 
 * @author Phaniraj.N
 * 2014-05-22 - Created
 * Neha Jaiswal
 * 2015-09-19 - Updated
 * Scott Coleman <scoleman@redhat.com>
 * 2016-02-08 - Setting usage on created addresses per US80784
 * 2015-08-13 - Suppressing publishing of test records per US71693
 * 2014-03-11 - Moving address style and country code to Country__c so config doesn't
 *              break every time country names are updated. US64870
 * Anshul Kumar
 * 2015-01-07 - Updated (US60976)
 * Bill C Riemers <briemers@redhat.com>
 * 2015-08-26 - Exclude inactive ebs accounts and contacts
 * 2015-10-23 - Added Credit_Card_Token__c to Opportunity query
 * 2015-11-13 - Ignore duplicates
 */
public without sharing class OrderDetailsExtensions {

	/******************* Properties ***************/
	public static String orderDetailsJSON {get;set;} // JSON string property
	public static String orderWrapperDetailsJSON {get;set;} // Currently this property is being used.
	public Opportunity opportunityRecord{get;set;} // the opportunity record details.
	public Boolean createNewAddress{get;set;} // flag to create new address
	public Address__c addressRecord{get;set;} // instance of Address Record
	public String nameFile{get;set;}
	public Blob contentFile{get;set;}
	String[] filelines = new String[]{};
	public Boolean addressline1Mandatory{get;set;} // flag to check if Address Line 1 field is mandatory
	public Boolean addressline1Visibility{get;set;} // flag to check if Address Line 1 field is visible
	public Boolean addressline2Mandatory{get;set;} // flag to check if Address Line 2 field is mandatory
	public Boolean addressline2Visibility{get;set;} // flag to check if Address Line 2 field is visible
	public Boolean addressline3Mandatory{get;set;} // flag to check if Address Line 3 field is mandatory
	public Boolean addressline3Visibility{get;set;} // flag to check if Address Line 3 field is visible
	public Boolean addressline4Mandatory{get;set;} // flag to check if Address Line 4 field is mandatory
	public Boolean addressline4Visibility{get;set;} // flag to check if Address Line 4 field is visible
	public Boolean cityVisibility{get;set;} // flag to check if City field is visible
	public Boolean cityMandatory{get;set;} // flag to check if City field is mandatory
	public Boolean countyMandatory{get;set;} // flag to check if County field is mandatory
	public Boolean countyVisibility{get;set;} // flag to check if County field is visible
	public Boolean postalCodeMandatory{get;set;} // flag to check if Postal Code field is mandatory
	public Boolean postalCodeVisibilty{get;set;} // flag to check if Postal Code field is visible
	public Boolean provinceMandatory{get;set;}  // flag to check if Province field is mandatory
	public Boolean provinceVisibility{get;set;} // flag to check if Province field is visible
	public Boolean stateMandatory{get;set;} // flag to check if State field is mandatory
	public Boolean stateVisibility{get;set;} // flag to check if State field is visible
	public Map<String,String> mapAddressCountryget{get;set;} // Map to set Country vs Address styles
	public Map<String,List<State__c>> countryStateMap; // map to set country vs state list
	public List<SelectOption> stateList{get;set;} // State select list
	public List<SelectOption> countyList{get;set;} // County select list
	public List<SelectOption> provinceList{get;set;} // Province Select list
	public String stateTextValue{get;set;} // property to store value state value
	public String countyTextValue{get;set;} // property to store value county value
	public String provinceTextValue{get;set;} // property to store value province value
	public Map<string,RH_AddressCountryMapping__c> mapAddressWrapper{get;set;} // wrapper to set address style details
	//public Map<string,RH_CountryCode_CountryName__c > countryCodeWrapper{get;set;} // wrapper to set country vs country code wrapper
	public Map<string,Country__c> countryCodeWrapper{get;set;} // get the Country__c object into a map
	public Map<string,string> codeCountryWrapper{get;set;} // wrapper to set country code vs country wrapper
	public Boolean createModeFlag{get;set;} // Boolean property to check if address is beinig created
	public String countryName{get;set;} // property to set country name
	public String isValid{get;set;} // boolean flag
	public String addressName{get;set;} // property to set complete address details
	public String addressId{get;set;} // property to set id of new created address
	public String salesAccountId{get;set;} // Sales Account Id
	public String addressErrorMsg{get;set;} // Property to set error message for Address
	public List<SelectOption> CountryList{get;set;}
	public Opportunity existingInstance{get;set;}
	public boolean hideNonRelevent { get; set; }
	public list<selectOption> profiles { get; set; }
	public string selectedProfile { get; set; }
	public string newProfileName { get; set; }
	public String pageParameters0 { get; set; }
	public String pageParameters1 { get; set; }
	public String pageParameters2 { get; set; }
	public String pageParameters3 { get; set; }
	public String pageParameters4 { get; set; }
	public String pageParameters5 { get; set; }
	public String pageParameters6 { get; set; }
	public String pageParameters7 { get; set; }
	public String pageParameters8 { get; set; }
	public String pageParameters9 { get; set; }
	public String pageParameters10 { get; set; }
	public String pageParameters11 { get; set; }
	public String pageParameters12 { get; set; }
	public String pageParameters13 { get; set; }
	public String pageParameters14 { get; set; }
	public String pageParameters15 { get; set; }
	public String pageParameters16 { get; set; }
	public String pageParameters17 { get; set; }
	public String pageParameters18 { get; set; }
	public String pageParameters19 { get; set; }
	public String pageParameters20 { get; set; }
	public String pageParameters21 { get; set; }
	public String pageParameters22 { get; set; }
	public String pageParameters23 { get; set; }
	public String pageParameters24 { get; set; }
	public String pageParameters25 { get; set; }
	public String pageParameters26 { get; set; }
	public String pageParameters27 { get; set; }
	public String pageParameters28 { get; set; }
	public String pageParameters29 { get; set; }
	public String pageParameters30 { get; set; }
	public String pageParameters31 { get; set; }
	public list<Order_Management_Profile__c> lstOMP { get; set; }
	public boolean setAsDefault { get; set; }

	public static map<string,OrderTypeDefault__c> orderTypeDefaultMap = OrderTypeDefault__c.getAll();

	public Map<String, States_ISO_codes__c> stateISOCodes = new Map<String, States_ISO_codes__c>(); // map for US Stats ISO Codes

	public string chkOrderSubmitStatus{get;set;} // set the status for order submission

	 //Added as the part of the user story US63466
	public static final String ERROR29 ='Error 29.0: ';
	public static final String ERROR30 ='Error 30.0: ';
	public static final String ERROR31 ='Error 31.0: ';
	public static final String ERROR32 =' does not have a CDH Party Number populated. Please contact the Customer Data Team to synchronize the CDH information.';

	public static final String ERROR34 ='Error 34.0: ';
	public static final String ERROR35 ='Error 35.0: ';
	public static final String ERROR36 ='Error 36.0: ';
	public static final String ERROR37 =' does not have a CDH Party Number populated. Please contact the Customer Data Team to synchronize the CDH information.';

	//public static final String Error38_2 = 'Error 38.2: Bill-To Address is mandatory. Please populate Bill-To Address before submitting the opportunity for OM review.';
	//public static final String Error38_2_NoSubmit = 'Bill-To Address is mandatory. Please populate Bill-To Address before submitting the opportunity for OM review.';
	public static final String Error39_1 = 'Error 39.1: Ship-To EBS Account is mandatory. Please populate Ship-To EBS Account before submitting the opportunity as an order.';
	public static final String Error39_2 = 'Error 39.2: Ship-To Address is mandatory. Please populate Ship-To Address before submitting the opportunity as an order.';
	public static final String Error40_1 = 'Error 40.1: Sold-To EBS Account is mandatory. Please populate Sold-To EBS Account before submitting the opportunity as an order.';
	public static final String Error40_2 = 'Error 40.2: Sold-To Address is mandatory. Please populate Sold-To Address before submitting the opportunity as an order.';
	public static final String Error41_1 = 'Error 41.1: Entitle-To EBS Account is mandatory. Please populate Entitle-To EBS Account before submitting the opportunity as an order.';
	public static final String Error41_2 = 'Error 41.2: Entitle-To Address is mandatory. Please populate Entitle-To Address before submitting the opportunity as an order.';

	public static final String Error42_1 = 'Error 42.1: Entitle-To EBS Account is not populated for one or more of the opportunity line items. Please populate Entitle-To EBS Account before submitting the opportunity as an order.';
	public static final String Error42_2 = 'Error 42.2: Entitle-To Address is not populated for one or more of the opportunity line items. Please populate Entitle-To Address before submitting the opportunity as an order.';

	public static string Display_Error ;
	public static final String HIDE_MESSAGES_SETTING = 'OrderManagement.HideMessages';
	  /** Map of all the BooleanSetting__c values used. */
	  public static final Map<String,Boolean> booleanSettingMap = new Map<String,Boolean> {
	HIDE_MESSAGES_SETTING => getBooleanSettingValue(HIDE_MESSAGES_SETTING) };

	public static Boolean reportErrorNumber {
	get {
	  return (reportErrorNumber != false);
	}
	set;
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



   /**************** Constructor ********************/
	public OrderDetailsExtensions(ApexPages.StandardController controller) {

		// Get opprotunity details
		OpportunityRecord = [Select
							Id,
							Name,
							CloseDate,
							StageName,
							Type,
							AccountId,
							Desired_Operating_Unit__c,
							FulfillmentChannel__c,
							Operating_Unit__c,
							Credit_Card_Number__c,
							Order_Type__c,
							Bill_To_Sales_Account__r.Name,
							Bill_To_Sales_Account__c,
							Bill_To_Account__r.Name,
							Bill_To_Account__c,
							Bill_To_Address_Details__c,
							Bill_To_Address__c,
							Bill_To_Contact__c,
							Bill_To_Contact__r.Name,
							Ship_To_Sales_Account__c,
							Ship_To_Sales_Account__r.Name,
							Ship_To_Account__c,
							Ship_To_Account__r.Name,
							Ship_To_Address__c,
							Ship_To_Address_Details__c,
							Ship_To_Contact__c,
							Ship_To_Contact__r.Name,
							Entitle_To_Sales_Account__c,
							Entitle_To_Sales_Account__r.Name,
							Entitle_To_Account__c,
							Entitle_To_Account__r.Name,
							Entitle_To_Address__c,
							Entitle_To_Address_Details__c,
							Entitle_To_Contact__c,
							Entitle_To_Contact__r.Name,
							Sold_To_Sales_Account__c,
							Sold_To_Sales_Account__r.Name,
							Sold_To_Account__c,
							Sold_To_Account__r.Name,
							Sold_To_Address__c,
							Sold_To_Address_Details__c,
							Sold_To_Contact__c,
							Sold_To_Contact__r.Name,
							Pending_OM_Review__c,
							OM_review_complete__c,
							Order_Status__c,
							OpportunityType__c,
							Order_Management_Profile__c,
							Set_As_Default_Profile__c,
							Entitle_To_Address__r.CDH_Party_Site_Number__c,
							Ship_To_Address__r.CDH_Party_Site_Number__c,
							Sold_To_Address__r.CDH_Party_Site_Number__c,
							Entitle_To_Contact__r.CDH_Party__c,
							Ship_To_Contact__r.CDH_Party__c,
							Sold_To_Contact__r.CDH_Party__c ,
							(Select id,
								Entitle_To_Address__c,
								Entitle_To_Account__c,
								Contract_Numbers__c,
								Configured_SKU__c,
								NewOrRenewal__c,
								PricebookEntry.ProductCode,
								PricebookEntry.Product2.Description,
								PricebookEntry.Product2.Family,
								PricebookEntry.Product2.Name,
								PricebookEntry.Product2.QuoteRequired__c
								 from opportunityLineItems)
							from Opportunity where Id = :apexpages.currentpage().getParameters().get('Id')];

		/************************US60986**********************/
		createNewAddress = false;
		hideNonRelevent = false;
		lstOMP = new list<Order_Management_Profile__c>();
		lstOmp.add(new Order_Management_Profile__c());

		list<Order_Management_Profile__c> ompInst1 = new list<Order_Management_Profile__c>([SELECT Id, Name FROM
																	Order_Management_Profile__c
																	WHERE Account__c =: OpportunityRecord.AccountId
																	AND Id =: OpportunityRecord.Order_Management_Profile__c LIMIT 1]);
		if(!ompInst1.isEmpty())
			selectedProfile = ompInst1[0].Id;
		lstOMP[0].Default__c = OpportunityRecord.Set_As_Default_Profile__c;
		setAsDefault = OpportunityRecord.Set_As_Default_Profile__c;
		// copying the existing instance to another instance
		existingInstance = new opportunity();
		existingInstance.Entitle_To_Sales_Account__c = OpportunityRecord.Entitle_To_Sales_Account__c;
		existingInstance.Entitle_To_Account__c = OpportunityRecord.Entitle_To_Account__c;
		existingInstance.Entitle_To_Contact__c = OpportunityRecord.Entitle_To_Contact__c;
		existingInstance.Entitle_To_Address__c = OpportunityRecord.Entitle_To_Address__c;

		chkOrderSubmitStatus = 'false';
		if(userinfo.getProfileId() != AccountFields__c.getInstance('Order Entry/Billing User - Profile').fieldId__c)
			chkOrderSubmitStatus = 'differentProfile';
		else if((userinfo.getProfileId() == AccountFields__c.getInstance('Order Entry/Billing User - Profile').fieldId__c) && OpportunityRecord.Pending_OM_Review__c == true)
			chkOrderSubmitStatus = 'true';

		else if((userinfo.getProfileId() == AccountFields__c.getInstance('Order Entry/Billing User - Profile').fieldId__c) && OpportunityRecord.Pending_OM_Review__c == false)
			chkOrderSubmitStatus = 'submittedForReview';

		system.debug(userInfo.getProfileId().left(15)+'=='+AccountFields__c.getInstance('Channel Sales').fieldId__c.left(15));
		if(userInfo.getProfileId().left(15) == AccountFields__c.getInstance('Channel Sales').fieldId__c.left(15) ||
		   userInfo.getProfileId().left(15) == AccountFields__c.getInstance('Direct Sales User').fieldId__c.left(15) ||
		   userInfo.getProfileId().left(15) == AccountFields__c.getInstance('Global Services User').fieldId__c.left(15) ||
		   userInfo.getProfileId().left(15) == AccountFields__c.getInstance('SEAP Compliance User').fieldId__c.left(15) ||
		   userInfo.getProfileId().left(15) == AccountFields__c.getInstance('Vendor User').fieldId__c.left(15))
			hideNonRelevent = true;

		profiles = new list<selectOption>();
		profiles.add(new selectOption('--None--', '--None--'));
		for(Order_Management_Profile__c ompInst : [SELECT Name, Default__c FROM Order_Management_Profile__c WHERE Account__c =: OpportunityRecord.AccountId]){
			profiles.add(new selectOption(ompInst.Id, ompInst.Name));
			//if(ompInst.Default__c)
				//selectedProfile = ompInst.Id;
		}

		if(!hideNonRelevent)
			profiles.add(new selectOption('Create New', 'Create New'));

		pageParameters0 = OpportunityRecord.Bill_To_Sales_Account__r.Name;
		pageParameters1 = OpportunityRecord.Bill_To_Sales_Account__c;
		pageParameters2 = OpportunityRecord.Bill_To_Account__r.Name;
		pageParameters3 = OpportunityRecord.Bill_To_Account__c;
		pageParameters4 = OpportunityRecord.Bill_To_Address_Details__c;
		pageParameters5 = OpportunityRecord.Bill_To_Address__c;
		pageParameters6 = OpportunityRecord.Bill_To_Contact__r.Name;
		pageParameters7 = OpportunityRecord.Bill_To_Contact__c;
		pageParameters8 = OpportunityRecord.Ship_To_Sales_Account__r.Name;
		pageParameters9 = OpportunityRecord.Ship_To_Sales_Account__c;
		pageParameters10 = OpportunityRecord.Ship_To_Account__r.Name;
		pageParameters11 = OpportunityRecord.Ship_To_Account__c;
		pageParameters12 = OpportunityRecord.Ship_To_Address_Details__c;
		pageParameters13 = OpportunityRecord.Ship_To_Address__c;
		pageParameters14 = OpportunityRecord.Ship_To_Contact__r.Name;
		pageParameters15 = OpportunityRecord.Ship_To_Contact__c;
		pageParameters16 = OpportunityRecord.Entitle_To_Sales_Account__r.Name;
		pageParameters17 = OpportunityRecord.Entitle_To_Sales_Account__c;
		pageParameters18 = OpportunityRecord.Entitle_To_Account__r.Name;
		pageParameters19 = OpportunityRecord.Entitle_To_Account__c;
		pageParameters20 = OpportunityRecord.Entitle_To_Address_Details__c;
		pageParameters21 = OpportunityRecord.Entitle_To_Address__c;
		pageParameters22 = OpportunityRecord.Entitle_To_Contact__r.Name;
		pageParameters23 = OpportunityRecord.Entitle_To_Contact__c;
		pageParameters24 = OpportunityRecord.Sold_To_Sales_Account__r.Name;
		pageParameters25 = OpportunityRecord.Sold_To_Sales_Account__c;
		pageParameters26 = OpportunityRecord.Sold_To_Account__r.Name;
		pageParameters27 = OpportunityRecord.Sold_To_Account__c;
		pageParameters28 = OpportunityRecord.Sold_To_Address_Details__c;
		pageParameters29 = OpportunityRecord.Sold_To_Address__c;
		pageParameters30 = OpportunityRecord.Sold_To_Contact__r.Name;
		pageParameters31 = OpportunityRecord.Sold_To_Contact__c;

		/************************US60986**********************/
	}
	/**************** End Constructor ********************/

	/************************US60986**********************/
	/*Name: refreshData
	 *
	 *@param:
	 *@return: void
	**/
	public void refreshData(){
		lstOMP = new list<Order_Management_Profile__c>([
															SELECT
																Name, Account__c,
																Bill_To_Account__c, Bill_To_Account__r.Name,
																Bill_To_Address__c, Bill_To_Address_Details__c,
																Bill_To_Contact__c, Bill_To_Contact__r.Name,
																Bill_To_EBS_Account__c, Bill_To_EBS_Account__r.Name,
																Default__c,
																Entitle_To_Account__c, Entitle_To_Account__r.Name,
																Entitle_To_Address__c, Entitle_To_Address_Details__c,
																Entitle_To_Contact__c, Entitle_To_Contact__r.Name,
																Entitle_To_EBS_Account__c, Entitle_To_EBS_Account__r.Name,
																Operating_Unit__c,
																Order_Type__c,
																Ship_To_Account__c, Ship_To_Account__r.Name,
																Ship_To_Address__c, Ship_To_Address_Details__c,
																Ship_To_Contact__c, Ship_To_Contact__r.Name,
																Ship_To_EBS_Account__c, Ship_To_EBS_Account__r.Name,
																Sold_To_Account__c, Sold_To_Account__r.Name,
																Sold_To_Address__c, Sold_To_Address_Details__c,
																Sold_To_Contact__c, Sold_To_Contact__r.Name,
																Sold_To_EBS_Account__c, Sold_To_EBS_Account__r.Name
															FROM
																Order_Management_Profile__c
															WHERE
																Id =: selectedProfile
															]);

		system.debug('---lstOMP---'+lstOMP[0]);
		setAsDefault = lstOMP[0].Default__c;
		OpportunityRecord.Operating_Unit__c = lstOMP[0].Operating_Unit__c;
		OpportunityRecord.Order_Type__c = lstOMP[0].Order_Type__c;
		pageParameters0 = lstOMP[0].Bill_To_Account__r.Name;
		pageParameters1 = lstOMP[0].Bill_To_Account__c;
		pageParameters2 = lstOMP[0].Bill_To_EBS_Account__r.Name;
		pageParameters3 = lstOMP[0].Bill_To_EBS_Account__c;
		pageParameters4 = lstOMP[0].Bill_To_Address_Details__c;
		pageParameters5 = lstOMP[0].Bill_To_Address__c;
		pageParameters6 = lstOMP[0].Bill_To_Contact__r.Name;
		pageParameters7 = lstOMP[0].Bill_To_Contact__c;
		pageParameters8 = lstOMP[0].Ship_To_Account__r.Name;
		pageParameters9 = lstOMP[0].Ship_To_Account__c;
		pageParameters10 = lstOMP[0].Ship_To_EBS_Account__r.Name;
	   pageParameters11 = lstOMP[0].Ship_To_EBS_Account__c;
		pageParameters12 = lstOMP[0].Ship_To_Address_Details__c;
		pageParameters13 = lstOMP[0].Ship_To_Address__c;
		pageParameters14 = lstOMP[0].Ship_To_Contact__r.Name;
		pageParameters15 = lstOMP[0].Ship_To_Contact__c;
		pageParameters16 = lstOMP[0].Entitle_To_Account__r.Name;
		pageParameters17 = lstOMP[0].Entitle_To_Account__c;
		pageParameters18 = lstOMP[0].Entitle_To_EBS_Account__r.Name;
		pageParameters19 = lstOMP[0].Entitle_To_EBS_Account__c;
		pageParameters20 = lstOMP[0].Entitle_To_Address_Details__c;
		pageParameters21 = lstOMP[0].Entitle_To_Address__c;
		pageParameters22 = lstOMP[0].Entitle_To_Contact__r.Name;
		pageParameters23 = lstOMP[0].Entitle_To_Contact__c;
		pageParameters24 = lstOMP[0].Sold_To_Account__r.Name;
		pageParameters25 = lstOMP[0].Sold_To_Account__c;
		pageParameters26 = lstOMP[0].Sold_To_EBS_Account__r.Name;
		pageParameters27 = lstOMP[0].Sold_To_EBS_Account__c;
		pageParameters28 = lstOMP[0].Sold_To_Address_Details__c;
		pageParameters29 = lstOMP[0].Sold_To_Address__c;
		pageParameters30 = lstOMP[0].Sold_To_Contact__r.Name;
		pageParameters31 = lstOMP[0].Sold_To_Contact__c;
	}
	/************************US60986**********************/

	public pageReference initializeAddressCreation(){

		// Method to initiate address creation functionalty
		// set the flag for reRender
		createNewAddress = true;
		//set the properties values
		countryName = '';
		isValid = 'false';
		addressRecord = new Address__c();

		String addrIdentifier = apexpages.currentpage().getParameters().get('addrIdentifier');
		if(addrIdentifier != null) {
			addressRecord.Bill_To_Address__c = (addrIdentifier == 'bill');
			addressRecord.Entitle_To_Address__c = (addrIdentifier == 'entitle');
			addressRecord.Ship_To_Address__c = (addrIdentifier == 'ship');
			addressRecord.Sold_To_Address__c = (addrIdentifier == 'sold');
		}

		salesaccountId = apexpages.currentpage().getParameters().get('salesaccountId');
		// Flag fields
		// Initialize the flag properties
		addressline1Mandatory = true;
		addressline2Mandatory = false;
		addressline3Mandatory = false;
		addressline4Mandatory = false;
		cityVisibility = false;
		cityMandatory = false;
		addressErrorMsg = '';
		// initiate picklist values
		stateList = new List<SelectOption>();
		countyList = new List<SelectOption>();
		provinceList = new List<SelectOption>();
		// initiate maps
		countryStateMap = new Map<String,List<State__c>>();
		mapAddressWrapper = new Map<string,RH_AddressCountryMapping__c>();
		mapAddressCountryget =new Map<string,string>();
		// set the country vs country code map
		// Commented by Scott Coleman 11-Mar-2015. Country Code now found on Country__c object (Iso3166Alpha2).
		//countryCodeWrapper = new Map<string,RH_CountryCode_CountryName__c >();
		//countryCodeWrapper = RH_CountryCode_CountryName__c.getAll();
		countryCodeWrapper = new Map<string,Country__c>(); // Get all country codes into map
		for(Country__c country : [select Id,Name,Iso3166Alpha2__c,Address_Style__c, (select Id,Name from States__r) from Country__c where Address_Style__c != null]){
			countryCodeWrapper.put(country.Name.toUpperCase(), country);
		}
		stateISOCodes = States_ISO_codes__c.getAll(); // put all values to map.
		// set the country code vs country map
		codeCountryWrapper = new Map<string,string>();
		// Commented by Scott Coleman 11-Mar-2015. Country Code now found on Country__c object (Iso3166Alpha2).
		//for(String countryName : countryCodeWrapper.keySet()){
		//	codeCountryWrapper.put(countryCodeWrapper.get(countryName).RH_TERRITORY_CODE__c,countryName.toUpperCase()) ;
		//}
		for(String country : countryCodeWrapper.keySet()){
			codeCountryWrapper.put(countryCodeWrapper.get(country).Iso3166Alpha2__c,country.toUpperCase());
		}
		// Commented by Scott Coleman 11-Mar-2015. Address Style now found on Country__c object.
		//// get all address details from Excel csv file defined in Documents
		//Document documentRecord = [Select id,Body from Document where name='RH_AddressCountryMapping' limit 1];

		//// Read the document and get all country related details
		//String documentContent = '';
		//if(!Test.isRunningTest())   // reading a blob value is not possible in test class. So adding test data here.
		//	documentContent = documentRecord.body.toString();
		//else
		//	documentContent = 'united states,Address Style 9\nindia,Address Style 10\nchina,Address Style 8\ncanada,Address Style 8\naustralia,Address Style 10';
		//filelines = documentContent.split('\n');
		//List<String> countryFileList = new List<String>();
		//// Get all the countries listed in the CSV File
		//for (Integer fileLine=1; fileLine < filelines.size(); fileLine++) //
		//{
		//	String[] inputvalues = new String[]{};
		//		inputvalues = filelines[fileLine].split(',');
		//	countryFileList.add(inputvalues[0]);
		//	// Generate country vs Address line map
		//	mapAddressCountryget.put(inputvalues[0],inputvalues[1]);
		//}

		// for the country in the above list, get the states defined in the object and set a map for Country vs State list
		//for(Country__c country : [Select Id,Name,(select Id,Name from States__r) from Country__c where Name IN :countryFileList]){
		for(Country__c country : countryCodeWrapper.values()){
			List<State__c> stateList = new List<State__c>();
			for(State__c state : country.States__r){
				stateList.add(state);
			}
			countryStateMap.put(country.Name.toUpperCase(),stateList);
			mapAddressCountryget.put(country.Name.toLowerCase(),country.Address_Style__c);
		}

		// build country list based on countries available in the document.
		countryList = new List<SelectOption>();
		String recCountry = '';
		countryList.add(new SelectOption('','--None--'));
		List<String> countryValues = new List<String>();
		countryValues.addAll(countryStateMap.keySet());
		countryValues.sort();
		for(String country:countryValues)
		{
			countryList.add(new SelectOption(country,country));
		}
		return null;
	}

	// for the selected country, get the state, county, province, zipcode, city visibility and mandatory details.
	public pageReference getAllStates(){
		// set the flags and properties.
		countryName = '';
		mapAddressWrapper=new Map<string,RH_AddressCountryMapping__c>();
		mapAddressWrapper= RH_AddressCountryMapping__c.getAll();
		countryName = Apexpages.currentpage().getParameters().get('countryName');
		String countryNameSelected = countryName;
		countryName = countryName.toLowerCase();
		// based on the country that is passed,. get the visibilty and mandatory details
		countryName = mapAddressCountryget.get(countryName).trim();
		cityMandatory			 =  mapAddressWrapper.get(countryName).RH_city_mandatory__c != null ? mapAddressWrapper.get(countryName).RH_city_mandatory__c : false;
		cityVisibility			=  mapAddressWrapper.get(countryName).RH_city_visibility__c != null ? mapAddressWrapper.get(countryName).RH_city_visibility__c : false;
		postalCodeMandatory	   =  mapAddressWrapper.get(countryName).RH_PostalCode_mandatory__c != null ? mapAddressWrapper.get(countryName).RH_PostalCode_mandatory__c : false;
		postalCodeVisibilty	   =  mapAddressWrapper.get(countryName).RH_PostalCode_visibilty__c != null ? mapAddressWrapper.get(countryName).RH_PostalCode_visibilty__c : false;
		provinceMandatory		 =  mapAddressWrapper.get(countryName).RH_Province_mandatory__c != null ? mapAddressWrapper.get(countryName).RH_Province_mandatory__c : false;
		provinceVisibility		=  mapAddressWrapper.get(countryName).RH_Province_visibility__c != null ? mapAddressWrapper.get(countryName).RH_Province_visibility__c : false;
		stateMandatory			=  mapAddressWrapper.get(countryName).RH_state_mandatory__c != null ? mapAddressWrapper.get(countryName).RH_state_mandatory__c : false;
		stateVisibility		   =  mapAddressWrapper.get(countryName).RH_state_visibility__c != null ? mapAddressWrapper.get(countryName).RH_state_visibility__c : false;
		countyMandatory		   =  mapAddressWrapper.get(countryName).RH_County_mandatory__c != null ? mapAddressWrapper.get(countryName).RH_County_mandatory__c : false ;
		countyVisibility		  =  mapAddressWrapper.get(countryName).RH_County_visibility__c != null ? mapAddressWrapper.get(countryName).RH_County_visibility__c : false ;
		countryName = countryNameSelected.toUpperCase();
		// set the state list if the state field is visible
		if(stateVisibility){
			stateList.clear();
			// if states are defined for the country in the database, create a list of states
			stateList.add(new SelectOption('','--None--'));
			if(countryStateMap.get(countryName) != null){
			   List<String> stateValues = new List<String>();
				for(State__c state :countryStateMap.get(countryName)){
					stateValues.add(state.Name);
				}
				stateValues.sort();
				for(String state:stateValues){
					stateList.add(new SelectOption(state,state));
				}
			}
		}
		//if state is not visible, create states as province list
		else if(provinceVisibility){
			provinceList.clear();
			if(stateList.size() < 2){
				provinceList.add(new SelectOption('','--None--'));
				if(countryStateMap.get(countryName) != null){
					List<String> provinceValues = new List<String>();
					for(State__c state:countryStateMap.get(countryName)){
						provinceValues.add(state.Name);
					}
					provinceValues.sort();
					for(String state:provinceValues){
						provinceList.add(new SelectOption(state,state));
					}
				}
			}
		}
		//if state is not visible, create states as county list
		else if(countyVisibility){
			countyList.clear();
			countyList.add(new SelectOption('','--None--'));
		}
		else{}
		// return null
		return null;
	}

	// Auto correction and setting the list values to text values
	public pageReference setSelectListFieldsToText(){
		string adminType = Apexpages.currentpage().getParameters().get('adminType');
		if(adminType == 'State'){
			stateList.clear();
			stateList.add(new SelectOption('','--None--'));
		}else if(adminType == 'County'){
			countyList.clear();
			countyList.add(new SelectOption('','--None--'));
		}else{
			provinceList.clear();
			provinceList.add(new SelectOption('','--None--'));
		}
		return null;
	}

	// Create address functionality
	public pageReference saveAddressDetails(){
		addressErrorMsg = '';
		// get the country code from the map
		if(countryCodeWrapper.get(countryName) != null){
		//addressRecord.Country__c = countryCodeWrapper.get(countryName).RH_TERRITORY_CODE__c;
		addressRecord.Country__c = countryCodeWrapper.get(countryName).Iso3166Alpha2__c;
		}
		if(stateTextValue != null)
			addressRecord.State__c = stateISOCodes.get(stateTextValue) != null ? stateISOCodes.get(stateTextValue).ISO_Code__c : stateTextValue;
		else
			addressRecord.State__c = '';
		addressRecord.Province__c = provinceTextValue;
		addressRecord.County__c = countyTextValue;
		addressRecord.Status__c = 'Active';
		addressRecord.Sales_Account__c = id.valueOf(salesaccountId);
		// insert address and get the details.
		try{
			upsert addressRecord;
			addressId = addressRecord.Id;
			System.debug('----------------->'+addressId);
			stateTextValue = '';
			provinceTextValue = '';
			countyTextValue = '';
			stateList.clear();
			stateList.add(new SelectOption('','--None--'));
			provinceList.clear();
			provinceList.add(new SelectOption('','--None--'));
			countyList.clear();
			countyList.add(new SelectOption('','--None--'));
			List<Address__c> addressCreated = [Select id, Name,Address_Line1__c,City__c,Country__c,County__c,Province__c,State__c,Zip_Postal_Code__c from Address__c where Id = :addressRecord.Id];
			addressName =  addressCreated[0].Address_Line1__c;
			addressName += addressCreated[0].City__c.length() > 0 ? ', '+addressCreated[0].City__c : '';
			addressName += addressCreated[0].County__c.length() > 0 ? ', '+addressCreated[0].County__c : '';
			addressName += addressCreated[0].State__c.length() > 0 ? ', '+addressCreated[0].State__c : '';
			addressName += addressCreated[0].Province__c.length() > 0 ? ', '+addressCreated[0].Province__c : '';
			addressName += addressCreated[0].Country__c.length() > 0 ? ', '+addressCreated[0].Country__c : '';
			addressName += addressCreated[0].Zip_Postal_Code__c.length() > 0 ? ' '+addressCreated[0].Zip_Postal_Code__c : '';
			addressRecord = new Address__c();
			createNewAddress = false;
		}catch (exception e){
			// set the error msg.
			addressErrorMsg = 'Error occurred in creating address';
		}
		// return fromo method
		return null;
	}

	private static String nillValue(String value,String defaultValue) {
		if(value == null) {
			value = defaultValue;
		}
		return value;
	}

	// Remote method to get all salesaccounts
	@RemoteAction
	public static string salesAccountSearch(string AccName){
		String AccountToBeSearched = AccName;
		List<OrderDetailsWrapper> OrderDetailsWrapperList = new List<OrderDetailsWrapper>();
		//added code for US63837 to restrict account with partner record type on search icon.
		String recordTypeLabel = Label.AccountPartnerRecordType;
		Set<String> recordTypeSet = new Set<String>();
		if(recordTypeLabel.contains(',')){
		   List<String> recordTypeList = recordTypeLabel.split(',');
		   for(String recordType : recordTypeList){
			  recordTypeSet.add(recordType);
		   }
		}
		for(Account a: [
			select
				AccountClassification__c,
				EBS_Account_Numbers__c,
				RecordTypeId,
				RecordType.Name,
				RecordType.DeveloperName,
				Id,
				Name,
				BillingStreet,
				BillingCity,
				BillingState,
				BillingCountry,
				BillingPostalCode,
				OraclePartyNumber__c,
				Owner.Name,
				PartnerPrograms__c,
				phone,
				fax,
				CDHPartyNumber__c
			from Account
			where Name like: '%'+AccountToBeSearched+'%'
				AND RecordType.DeveloperName NOT IN :recordTypeSet
			limit 999 ])
		{
			if(a.Id != null){
				OrderDetailsWrapper odw = new OrderDetailsWrapper();
				odw.RecId = string.valueOf(a.Id);
				odw.RecName = a.Name;
				odw.Phone = nillValue(a.Phone,'');
				odw.Fax = nillValue(a.Fax,'');
				odw.RecordType = nillValue(a.RecordType.Name,'');//added as per US63409
				odw.EbsAcc = nillValue(a.EBS_Account_Numbers__c,'');//added as per US64739
				odw.Classification = nillValue(a.AccountClassification__c,'');
				odw.PartnerPrograms = nillValue(a.PartnerPrograms__c,'');
				odw.AccBillingAddress = nillValue(a.BillingStreet,'');
				odw.AccBillingAddress += a.BillingCity != null ? ', '+a.BillingCity : '';
				odw.AccBillingAddress += a.BillingState != null ? ', '+a.BillingState : '';
				odw.AccBillingAddress += a.BillingCountry != null ? ', '+a.BillingCountry : '';
				odw.AccBillingAddress += a.BillingPostalCode != null ? ' '+a.BillingPostalCode : '';
				odw.PartyNumber = nillValue(a.CDHPartyNumber__c,'');
				odw.OwnerName = nillValue(a.Owner.Name,'');
				OrderDetailsWrapperList.add(odw) ;
			}
		}
		// return the JSON message
		OrderDetailsJSON = JSON.serialize(OrderDetailsWrapperList);
		return OrderDetailsJSON;
	}

	// Remote method to get EBS Accounts for the selected SalesAccount
	@RemoteAction
	public static string EBSAccountSearch(string accID){
		List<OrderDetailsWrapper> OrderDetailsWrapperListChecked = new List<OrderDetailsWrapper>();
		List<OrderDetailsWrapper> OrderDetailsWrapperListUnChecked = new List<OrderDetailsWrapper>();
		//List<OrderDetailsWrapper> OrderDetailsWrapperListfinal = new List<OrderDetailsWrapper>();
		Integer settinsIndexOfList = 0;
		for(EBS_Account__c e :[
			select Id,
				Name,
				EBS_Party_Number__c,
				EBS_Account_Description__c,
				EBS_Party_Name__c,
				Primary_EBS_Account__c
			from EBS_Account__c
			where Sales_Account__c = :accID and Status__c != 'Inactive'
			order by Primary_EBS_Account__c ] )
		{
			if(e.id != null) {
				OrderDetailsWrapper odw = new OrderDetailsWrapper();
				odw.RecId = String.valueOf(e.Id);
				odw.RecName = e.Name;
				odw.Description = e.EBS_Account_Description__c != null ? e.EBS_Account_Description__c : '';
				odw.PartyNumber = e.EBS_Party_Number__c != null ? e.EBS_Party_Number__c : '';
				odw.PartyName = e.EBS_Party_Name__c != null ? e.EBS_Party_Name__c : '';
				odw.BillTo = e.Primary_EBS_Account__c == true ? 'checked' : 'false' ;
				if(odw.BillTo == 'checked'){
					OrderDetailsWrapperListChecked.add(odw) ;
				}
				else if(odw.BillTo == 'false'){
					OrderDetailsWrapperListUnChecked.add(odw) ;
				}
			}
		}

		List<OrderDetailsWrapper> OrderDetailsWrapperListfinal = new OrderDetailsWrapper[OrderDetailsWrapperListChecked.size()+OrderDetailsWrapperListUnChecked.size()];
		if(OrderDetailsWrapperListChecked != null && OrderDetailsWrapperListChecked.size() > 0){
			for(OrderDetailsWrapper objWrapper : OrderDetailsWrapperListChecked){
				//OrderDetailsWrapperListfinal.add(objWrapper);
				OrderDetailsWrapperListfinal.set(settinsIndexOfList,objWrapper);
				settinsIndexOfList = settinsIndexOfList + 1;
			}
		}

		if(OrderDetailsWrapperListUnChecked != null && OrderDetailsWrapperListUnChecked.size() > 0){
			for(OrderDetailsWrapper objWrapper : OrderDetailsWrapperListUnChecked){
				//OrderDetailsWrapperListfinal.add(objWrapper);
				OrderDetailsWrapperListfinal.set(settinsIndexOfList,objWrapper);
				settinsIndexOfList = settinsIndexOfList + 1;
			}
		}
		system.debug('++++++++++'+OrderDetailsWrapperListfinal);
		// return the JSON string
		OrderDetailsJSON = JSON.serialize(OrderDetailsWrapperListfinal);
		return OrderDetailsJSON;
	}

	// Remote method to get Address for the selected salesaccount
	@RemoteAction
	public static string AddressSearch(string accID, string strAddrIdentifier){
		List<OrderDetailsWrapper> OrderDetailsWrapperList = new List<OrderDetailsWrapper>();
		String query = 'SELECT Id, Name, Address_Line1__c,Address_Line2__c,CDH_Party_Site_Number__c, Bill_To_Address__c, Entitle_To_Address__c, Sold_To_Address__c, Ship_To_Address__c, Province__c, Zip_Postal_Code__c, Country__c, State__c, City__c FROM Address__c WHERE Sales_Account__c =: accID and IsDuplicate__c != true and Status__c != \'Inactive\'';
		//string strAddrIdentifier = 'bill';
		if(strAddrIdentifier == 'bill')
			query += ' ORDER BY Bill_To_Address__c ASC, Sold_To_Address__c ASC, Ship_To_Address__c ASC, Entitle_To_Address__c ASC';
		else if(strAddrIdentifier == 'sold')
			query += ' ORDER BY Sold_To_Address__c ASC, Bill_To_Address__c ASC, Ship_To_Address__c ASC, Entitle_To_Address__c ASC';
		else if(strAddrIdentifier == 'ship')
			query += ' ORDER BY Ship_To_Address__c ASC, Bill_To_Address__c ASC, Sold_To_Address__c ASC, Entitle_To_Address__c ASC';
		else if(strAddrIdentifier == 'entitle')
			query += ' ORDER BY Entitle_To_Address__c ASC, Bill_To_Address__c ASC, Sold_To_Address__c ASC, Ship_To_Address__c ASC';

		for(Address__c e : Database.query(query)){//[select Id, Name,Address_Line1__c,Bill_To_Address__c,Entitle_To_Address__c,Sold_To_Address__c ,Ship_To_Address__c  ,Province__c ,Zip_Postal_Code__c , Country__c, State__c , City__c,CDH_Party_Site_Number__c from Address__c where Sales_Account__c = :accID and Status__c = 'Active']){
			if(e.id != null){
				OrderDetailsWrapper odw = new OrderDetailsWrapper();
				  odw.RecId = string.valueOf(e.Id);
				  odw.RecName = e.Address_Line1__c != null ? e.Address_Line1__c : '';
				  odw.RecName += e.City__c != null ? ', '+e.City__c: '';
				  odw.RecName += e.State__c != null ? ', '+e.State__c : '';
				  odw.RecName += e.Province__c != null ? ', '+e.Province__c: '';
				  odw.RecName += e.Zip_Postal_Code__c != null ? ' '+e.Zip_Postal_Code__c: '';
				  odw.AddressOne = e.Address_Line1__c != null ? e.Address_Line1__c : '';
				  odw.AddressTwo = e.Address_Line2__c != null ? e.Address_Line2__c : '';
				  odw.partySiteNumber = e.CDH_Party_Site_Number__c != null ? e.CDH_Party_Site_Number__c : '';
				  odw.AddressNumber = e.Name != null ? e.Name : '';
				  odw.City = e.City__c != null ? e.City__c : '';
				  odw.State = e.State__c != null ? e.State__c : '';
				  odw.Province = e.Province__c != null ? e.Province__c : '';
				  odw.Country = e.Country__c != null ? e.Country__c: '';
				  odw.zipPostal = e.Zip_Postal_Code__c != null ? e.Zip_Postal_Code__c : '';
				  odw.BillTo = e.Bill_To_Address__c == true ? 'checked' : 'false' ;
				  odw.ShipTo = e.Ship_To_Address__c == true ? 'checked' : 'false' ;
				  odw.EntitleTo = e.Entitle_To_Address__c == true ? 'checked' : 'false' ;
				  odw.SoldTo = e.Sold_To_Address__c == true ? 'checked' : 'false' ;
				OrderDetailsWrapperList.add(odw) ;
			}
		}
		// return JSON String
		OrderDetailsJSON = JSON.serialize(OrderDetailsWrapperList);
		return OrderDetailsJSON;
	}

	// Remote method to get Contacts for the selected salesaccount
	@RemoteAction
	public static string ContactSearch(string accID){
	   List<OrderDetailsWrapper> OrderDetailsWrapperList = new List<OrderDetailsWrapper>();
		for(Contact e :[
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
			where AccountId = :accID and Status__c != 'Inactive'] )
		{
			if(e.id != null){
				OrderDetailsWrapper odw = new OrderDetailsWrapper();
				odw.RecId = string.valueOf(e.Id);
				odw.firstName = e.firstName != null ? e.firstName : '';
				odw.lastName = e.lastName != null ? e.lastName : '';
				odw.RecName = e.Name;
				odw.Email = e.email != null ? e.Email : '';
				odw.contactPhone = e.Phone != null ? e.Phone : '';
				odw.Department = e.Department != null ? e.Department : '';
				odw.contactPartyNumber = e.CDH_Party__r.Name != null ? e.CDH_Party__r.Name : '';
				odw.rhnEntitlementLogin = e.LoginName__c != null ? e.LoginName__c : '';
				OrderDetailsWrapperList.add(odw) ;
			}
		}
		// return JSON String
		OrderDetailsJSON = JSON.serialize(OrderDetailsWrapperList);
		return OrderDetailsJSON;
	}

	// Remote method to get EBS Accounts, Address, Contacts for the sales Account selected.
	// Note : This is not yet used in the functionality.
	// Due to static remote functionality I am facing some issues so using this is deprecated. But I will find a way to use this.
	/*
	@RemoteAction
	public static string GetAllDataForAccount(string accID){
		// initialize wrapper class and wrapper properties
		OrderWrapperDetails owd = new OrderWrapperDetails();
		owd.EBSAccList = new List<EBS_Account__c>();
		owd.AddressList = new List<Address__c>();
		owd.ContactList = new List<Contact>();
		List<EBS_Account__c> relatedEBSAccountsList = new List<EBS_Account__c>();
		List<Address__c> relatedAddressList = new List<Address__c>();
		List<Contact> relatedContactList = new List<Contact>();
		for(Account acc : [ Select id,(select Id, Name, EBS_Party_Number__c from EBS_Account__r),(select Id,Name, FirstName,LastName,Email from contacts), (select Id, Name, Country__c, State__c , City__c, CDH_Party_Site_Number__c from Addresses__r) from Account where id=: accID] ){
			for(EBS_Account__c e: acc.EBS_Account__r){
				relatedEBSAccountsList.add(e);
			}
			for(Address__c e: acc.Addresses__r){
				relatedAddressList.add(e);
			}
			for(Contact e: acc.contacts){
				relatedContactList.add(e);
			}
		}
		if(relatedEBSAccountsList.size() > 0)
			owd.EBSAccList.addAll(relatedEBSAccountsList);
		if(relatedAddressList.size() > 0)
			owd.AddressList.addAll(relatedAddressList);
	   if(relatedContactList.size() > 0)
			owd.ContactList.addAll(relatedContactList);

		// return JSON String
		OrderWrapperDetailsJSON = JSON.serialize(owd);
		return OrderWrapperDetailsJSON;
	} */

	@RemoteAction
	public static string getDefaultOrderType(string orderTypeCheckValue){
		string orderType = orderTypeDefaultMap.get(orderTypeCheckValue).Order_Type__c;
		return orderType;
	}


	/************************US60986**********************/
	/*Name: createOMP
	 *
	 *@param:
	 *@return: Boolean
	**/
	private boolean createOMP(){

		system.debug('---newProfileName---'+newProfileName+'---'+selectedProfile);
		Order_Management_Profile__c ompInst;
		if(string.isBlank(newProfileName) && selectedProfile == 'Create New'){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter new Profile Name');
			ApexPages.addMessage(myMsg);
			return FALSE;
		}else if(string.isNotBlank(newProfileName) && selectedProfile == 'Create New'){
			ompInst = new Order_Management_Profile__c();

			lstOMP[0].Default__c = setAsDefault;
			ompInst.Name = newProfileName;
			ompInst.Default__c = lstOMP[0].Default__c;
			ompInst.Operating_Unit__c = OpportunityRecord.Operating_Unit__c;
			ompInst.Order_Type__c = OpportunityRecord.Order_Type__c;
			ompInst.Account__c = OpportunityRecord.AccountId;
			ompInst.Bill_To_Account__c = OpportunityRecord.Bill_To_Sales_Account__c;
			ompInst.Bill_To_EBS_Account__c = OpportunityRecord.Bill_To_Account__c;
			ompInst.Bill_To_Address__c = OpportunityRecord.Bill_To_Address__c;
			ompInst.Bill_To_Contact__c = OpportunityRecord.Bill_To_Contact__c;
			ompInst.Ship_To_Account__c = OpportunityRecord.Ship_To_Sales_Account__c;
			ompInst.Ship_To_EBS_Account__c = OpportunityRecord.Ship_To_Account__c;
			ompInst.Ship_To_Address__c = OpportunityRecord.Ship_To_Address__c;
			ompInst.Ship_To_Contact__c = OpportunityRecord.Ship_To_Contact__c;
			ompInst.Entitle_To_Account__c = OpportunityRecord.Entitle_To_Sales_Account__c;
			ompInst.Entitle_To_EBS_Account__c = OpportunityRecord.Entitle_To_Account__c;
			ompInst.Entitle_To_Address__c = OpportunityRecord.Entitle_To_Address__c;
			ompInst.Entitle_To_Contact__c = OpportunityRecord.Entitle_To_Contact__c;
			ompInst.Sold_To_Account__c = OpportunityRecord.Sold_To_Sales_Account__c;
			ompInst.Sold_To_EBS_Account__c = OpportunityRecord.Sold_To_Account__c;
			ompInst.Sold_To_Address__c = OpportunityRecord.Sold_To_Address__c;
			ompInst.Sold_To_Contact__c = OpportunityRecord.Sold_To_Contact__c;
			OpportunityRecord.Set_As_Default_Profile__c = lstOMP[0].Default__c;
			insert ompInst;
			OpportunityRecord.Order_Management_Profile__c = ompInst.Id;
		}
		if(String.isBlank(newProfileName)){

			OpportunityRecord.Order_Management_Profile__c = selectedProfile;


			for(Order_Management_Profile__c ompinst1 : [SELECT Id, Default__c FROM
																	Order_Management_Profile__c
																	WHERE Account__c =: OpportunityRecord.AccountId
																	AND Id =: selectedProfile])
				OpportunityRecord.Set_As_Default_Profile__c = ompinst1.Default__c;
		}

		return true;
	}
	/************************US60986**********************/
	// update opportunity details
	public pageReference opportunityUpdate(){
		String opportunityDetails = Apexpages.currentpage().getParameters().get('opportunityDetailToUpdate');
		List<String> opprtunityFieldValues = opportunityDetails.split(',');
		//OpportunityRecord.Pending_OM_Review__c = opprtunityFieldValues[0] != 'No value defined here' ? true : false ;
		OpportunityRecord.Operating_Unit__c = opprtunityFieldValues[0] != 'No value defined here' ? opprtunityFieldValues[0] : '' ;
		OpportunityRecord.Order_Type__c = opprtunityFieldValues[1] != 'No value defined here' ? opprtunityFieldValues[1] : '' ;
		OpportunityRecord.Bill_To_Sales_Account__c = opprtunityFieldValues[2] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[2]) : null ;
	   OpportunityRecord.Bill_To_Account__c = opprtunityFieldValues[3] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[3]) : null ;
		OpportunityRecord.Bill_To_Address__c = opprtunityFieldValues[4] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[4]) : null ;
		OpportunityRecord.Bill_To_Contact__c = opprtunityFieldValues[5] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[5]) : null ;
		OpportunityRecord.Ship_To_Sales_Account__c = opprtunityFieldValues[6] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[6]) : null ;
		OpportunityRecord.Ship_To_Account__c = opprtunityFieldValues[7] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[7]) : null ;
		OpportunityRecord.Ship_To_Address__c = opprtunityFieldValues[8] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[8]) : null ;
		OpportunityRecord.Ship_To_Contact__c = opprtunityFieldValues[9] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[9]) : null ;
		OpportunityRecord.Entitle_To_Sales_Account__c = opprtunityFieldValues[10] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[10]) : null ;
		OpportunityRecord.Entitle_To_Account__c = opprtunityFieldValues[11] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[11]) : null ;
		OpportunityRecord.Entitle_To_Address__c = opprtunityFieldValues[12] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[12]) : null ;
		OpportunityRecord.Entitle_To_Contact__c = opprtunityFieldValues[13] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[13]) : null ;
		OpportunityRecord.Sold_To_Sales_Account__c = opprtunityFieldValues[14] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[14]) : null ;
		OpportunityRecord.Sold_To_Account__c = opprtunityFieldValues[15] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[15]) : null ;
		OpportunityRecord.Sold_To_Address__c = opprtunityFieldValues[16] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[16]) : null ;
		OpportunityRecord.Sold_To_Contact__c  = opprtunityFieldValues[17] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[17]) : null ;
		// update opportunity
		/************************US60986**********************/
		if(!createOMP()){
			return NULL;
		}
		/************************US60986**********************/
		try{
			update OpportunityRecord;
			//OpportunityRecord = [select Id, Entitle_To_Sales_Account__c, Entitle_To_Account__c, Entitle_To_Address__c, Entitle_To_Contact__c from Opportunity where id = :apexpages.currentpage().getParameters().get('Id')];
			trackEntitlementAndUpdateOpportunityLineItems();
			pageReference page = new pageReference('/'+OpportunityRecord.id);
			return page;
		}
		//catch any exceptions
		catch (Exception e){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error occured in saving Opportunity !!!');
			ApexPages.addMessage(myMsg);
		}
		return null;
	}

	public void onSubmit(){
	}

	// Method for Submit Order button functionality
	public pageReference onSubmitOrderBtnClick()
	{
		Opportunity orderOutboundDetails;
		String opportunityDetails = Apexpages.currentpage().getParameters().get('opportunityDetailToUpdate');
		List<String> opprtunityFieldValues = opportunityDetails.split(',');
		//OpportunityRecord.Pending_OM_Review__c = opprtunityFieldValues[0] != 'No value defined here' ? true : false ;
		OpportunityRecord.Operating_Unit__c = opprtunityFieldValues[0] != 'No value defined here' ? opprtunityFieldValues[0] : '' ;
		OpportunityRecord.Order_Type__c = opprtunityFieldValues[1] != 'No value defined here' ? opprtunityFieldValues[1] : '' ;
		OpportunityRecord.Bill_To_Sales_Account__c = opprtunityFieldValues[2] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[2]) : null ;
		OpportunityRecord.Bill_To_Account__c = opprtunityFieldValues[3] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[3]) : null ;
		OpportunityRecord.Bill_To_Address__c = opprtunityFieldValues[4] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[4]) : null ;
		OpportunityRecord.Bill_To_Contact__c = opprtunityFieldValues[5] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[5]) : null ;
		OpportunityRecord.Ship_To_Sales_Account__c = opprtunityFieldValues[6] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[6]) : null ;
		OpportunityRecord.Ship_To_Account__c = opprtunityFieldValues[7] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[7]) : null ;
		OpportunityRecord.Ship_To_Address__c = opprtunityFieldValues[8] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[8]) : null ;
		OpportunityRecord.Ship_To_Contact__c = opprtunityFieldValues[9] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[9]) : null ;
		OpportunityRecord.Entitle_To_Sales_Account__c = opprtunityFieldValues[10] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[10]) : null ;
		OpportunityRecord.Entitle_To_Account__c = opprtunityFieldValues[11] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[11]) : null ;
		OpportunityRecord.Entitle_To_Address__c = opprtunityFieldValues[12] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[12]) : null ;
		OpportunityRecord.Entitle_To_Contact__c = opprtunityFieldValues[13] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[13]) : null ;
		OpportunityRecord.Sold_To_Sales_Account__c = opprtunityFieldValues[14] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[14]) : null ;
		OpportunityRecord.Sold_To_Account__c = opprtunityFieldValues[15] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[15]) : null ;
		OpportunityRecord.Sold_To_Address__c = opprtunityFieldValues[16] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[16]) : null ;
		OpportunityRecord.Sold_To_Contact__c  = opprtunityFieldValues[17] != 'No value defined here' ? ID.valueOf(opprtunityFieldValues[17]) : null ;
		OpportunityRecord.OM_review_complete__c = true;
		OpportunityRecord.Pending_OM_Review__c = true;
		OpportunityRecord.Order_Status__c = 'Submitted for Order';

		// update opportunity before submitting for order
		/************************US60986**********************/
		if(!createOMP()){
			return NULL;
		}
		/************************US60986**********************/
		try{
			update OpportunityRecord;
			trackEntitlementAndUpdateOpportunityLineItems();
		}catch (Exception e){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error occured in saving Opportunity !!!');
			ApexPages.addMessage(myMsg);
			return null;
		}

		Boolean errorFlag = validateOpportunityRecord();
		//system.debug('errorFlag *outside********' +errorFlag );
		if (!errorFlag ){
			//Creating Order_Tracking__c record
			Order_Tracking__c orderTrackingRecord = new Order_Tracking__c(); ////++++ check naming convention of variable
			orderTrackingRecord.Opportunity__c = OpportunityRecord.ID;
			orderTrackingRecord.Opportunity_Owner__c = OpportunityRecord.Owner.Id;
			orderTrackingRecord.Order_Status__c = 'Submitted for Order';
			orderTrackingRecord.Submitted_By__c = UserInfo.getUserId();
			orderTrackingRecord.Submitted_Date__c = System.Now();
			orderTrackingRecord.Opportunity_Stage__c = 'Closed Won';

			try{
				insert orderTrackingRecord;
				orderOutboundDetails = [
					select Id,
						OracleOrderID__c,
						OracleOrderNumber__c,
						Owner__r.EmployeeNumber,
						OpportunityNumber__c,
						PONumber__c,
						Order_Type__c,
						Operating_Unit__c,
						Bill_To_Account__r.Name,
						Bill_To_Account__r.EBS_Party_Number__c,
						Bill_To_Address__r.CDH_Party_Site_Number__c,
						Bill_To_Address__r.Address_Line1__c,
						Bill_To_Address__r.Address_Line2__c,
						Bill_To_Address__r.Address_Line3__c,
						Bill_To_Address__r.Address_Line4__c,
						Bill_To_Address__r.City__c,
						Bill_To_Address__r.State__c,
						Bill_To_Address__r.Country__c,
						Bill_To_Address__r.County__c,
						Bill_To_Address__r.Zip_postal_code__c,
						Bill_To_Address__r.Province__c,
						Bill_To_Contact__r.CDH_party_number__c,
						Bill_To_Contact__r.FirstName,
						Bill_To_Contact__r.LastName,
						Bill_To_Contact__r.Email,
						Bill_To_Contact__r.Phone,
						Ship_To_Account__r.Name,
						Non_Entitled_Endco__r.CDH_Party_Name__r.Name,
						Non_Entitled_Endco__r.Name,
						Ship_To_Account__r.EBS_Party_Number__c,
						Ship_To_Address__r.CDH_Party_Site_Number__c,
						Ship_To_Address__r.Address_Line1__c,
						Ship_To_Address__r.Address_Line2__c,
						Ship_To_Address__r.Address_Line3__c,
						Ship_To_Address__r.Address_Line4__c,
						Ship_To_Address__r.City__c,
						Ship_To_Address__r.State__c,
						Ship_To_Address__r.Country__c,
						Ship_To_Address__r.County__c,
						Ship_To_Address__r.Zip_postal_code__c,
						Ship_To_Address__r.Province__c,
						Ship_To_Contact__r.CDH_party_number__c,
						Ship_To_Contact__r.FirstName,
						Ship_To_Contact__r.LastName,
						Ship_To_Contact__r.Email,
						Ship_To_Contact__r.Phone,
						Sold_To_Account__r.Name,
						Sold_To_Account__r.EBS_Party_Number__c,
						Sold_To_Address__r.CDH_Party_Site_Number__c,
						Sold_To_Address__r.Address_Line1__c,
						Sold_To_Address__r.Address_Line2__c,
						Sold_To_Address__r.Address_Line3__c,
						Sold_To_Address__r.Address_Line4__c,
						Sold_To_Address__r.City__c,
						Sold_To_Address__r.State__c,
						Sold_To_Address__r.Country__c,
						Sold_To_Address__r.County__c,
						Sold_To_Address__r.Zip_postal_code__c,
						Sold_To_Address__r.Province__c,
						Sold_To_Contact__r.CDH_party_number__c,
						Sold_To_Contact__r.FirstName,
						Sold_To_Contact__r.LastName,
						Sold_To_Contact__r.Email,
						Sold_To_Contact__r.Phone,
						Entitle_To_Account__r.Name,
						Entitle_To_Account__r.EBS_Party_Number__c,
						Entitle_To_Address__r.CDH_Party_Site_Number__c,
						Entitle_To_Address__r.Address_Line1__c,
						Entitle_To_Address__r.Address_Line2__c,
						Entitle_To_Address__r.Address_Line3__c,
						Entitle_To_Address__r.Address_Line4__c,
						Entitle_To_Address__r.City__c,
						Entitle_To_Address__r.State__c,
						Entitle_To_Address__r.Country__c,
						Entitle_To_Address__r.County__c,
						Entitle_To_Address__r.Zip_postal_code__c,
						Entitle_To_Address__r.Province__c,
						Entitle_To_Contact__r.CDH_party_number__c,
						Entitle_To_Contact__r.FirstName,
						Entitle_To_Contact__r.LastName,
						Entitle_To_Contact__r.Email,
						Entitle_To_Contact__r.Phone,
						PaymentType__c,
						Credit_Card_Number__c,
						Credit_Card_Token__c,
						ExpirationDate__c,
						CreditCardType__c,
						NameOnCard__c,
						Pay_Now__c,
						ContractNumber__c,
						FulfillmentChannel__c,
						PaymentTerms__c,
						CurrencyIsoCode,
						Amount,
						Shipping_Instructions__c,
						VAT_code__c,
						Rush_Order__c,
						Reseller_PO__c,
						(	select Id,
								PricebookEntry.Product2.ProductCode,
								ActualStartDate__c,
								YearlySalesPrice__c,
								ActualEndDate__c,
								Quantity,
								PricebookEntry.Product2.Unit_Of_Measure__c,
								UnitPrice,Adjusted_Price__c,
								Contract_Numbers__c,
								Entitle_To_Account__r.Name,
								Entitle_To_Account__r.EBS_Party_Number__c,
								Entitle_To_Address__r.CDH_Party_Site_Number__c,
								Entitle_To_Address__r.Address_Line1__c,
								Entitle_To_Address__r.Address_Line2__c,
								Entitle_To_Address__r.Address_Line3__c,
								Entitle_To_Address__r.Address_Line4__c,
								Entitle_To_Address__r.City__c,
								Entitle_To_Address__r.State__c,
								Entitle_To_Address__r.Country__c,
								Entitle_To_Address__r.County__c,
								Entitle_To_Address__r.Zip_postal_code__c ,
								Entitle_To_Address__r.Province__c,
								Entitle_To_Contact__r.CDH_party_number__c,
								Entitle_To_Contact__r.FirstName,
								Entitle_To_Contact__r.LastName,
								Entitle_To_Contact__r.Email,
								Entitle_To_Contact__r.Phone,
								Price_After_Discretionary_Discount__c ,
								Price_After_One_Time_Discount__c,
								PriceOverrideReason__c,
								Install_Base_Number__c,
								opportunityId,
								One_time_Discount_Amount__c
							from OpportunityLineItems order by CreatedDate),
						(	select Id,
								Partner__r.CDH_Party_Name__r.CDH_Party_Name__c,
								PartnerType__r.Name,
								Partner__r.CDH_Party_Name__r.Name,
								Partner__r.Name,
								Partner_Contact__r.FirstName,
								Partner_Contact__r.LastName,
								Partner_Contact__r.Phone,
								Partner_Contact__r.Email,
								PartnerTier__c,
								PartnerTierName__c,
								RelationshipType__c,
								Partner_Contact__r.CDH_Party_Number__c,
								Opportunity__c,
								Oracle_Classification_Code__c
							from OpportunityPartners2__r),
						(	select Id,
								Payment_Terms__c
							from CreditChecks__r
							where Credit_Stage__c = 'Approved' OR Credit_Stage__c = 'Approved - Manual'
							order By LastModifiedDate DESC limit 1),
						Do_Not_Publish_To_Bus__c,
						Do_Not_Publish_To_Bus_Account__c
					from Opportunity
					where Id= :OpportunityRecord.ID];

			}catch(Exception e){
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error occured in submitting order!!!');
				ApexPages.addMessage(myMsg);
				return null;
			}

			// US71693
			OutboundService.DoNotPublish = (OutboundService.DoNotPublish || orderOutboundDetails.Do_Not_Publish_To_Bus__c || orderOutboundDetails.Do_Not_Publish_To_Bus_Account__c);

			/* Passing opportunity details in the SystemObjectConverter class to get it's wrapper structure.*/
			IntegrationObjects.order orderObject = SystemObjectConverter.ConvertToOrder(orderOutboundDetails);

			/* Invoking outbound service by passing parameter & event to generate JSON structure in outbound_event object.*/
			OutboundService.queueOrderMessage(orderObject, 'INSERT');

			pageReference page = new pageReference('/'+OpportunityRecord.id);
			return page;
		}
		else
			return null;
	}

	public void trackEntitlementAndUpdateOpportunityLineItems(){
		Boolean trackChange = false;


		if(existingInstance.Entitle_To_Sales_Account__c != OpportunityRecord.Entitle_To_Sales_Account__c){
			trackChange = true;
		}
		if(existingInstance.Entitle_To_Account__c != OpportunityRecord.Entitle_To_Account__c){
			trackChange = true;
		}
		if(existingInstance.Entitle_To_Address__c != OpportunityRecord.Entitle_To_Address__c){
			trackChange = true;
		}
		if(existingInstance.Entitle_To_Contact__c != OpportunityRecord.Entitle_To_Contact__c){
			trackChange = true;
		}
		List<OpportunityLineItem> lineItemList = new List<OpportunityLineItem>();
		if(trackChange){
			for(OpportunityLineItem lineItem : [select id, Entitle_To_Sales_Account__c, Entitle_To_Account__c, Entitle_To_Address__c, Entitle_To_Contact__c from OpportunityLineItem where Opportunity.id = :apexpages.currentpage().getParameters().get('Id') and Entitle_To_Sales_Account__c=null and Entitle_To_Account__c=null and Entitle_To_Address__c=null and Entitle_To_Contact__c=null]){
				lineItem.Entitle_To_Sales_Account__c = OpportunityRecord.Entitle_To_Sales_Account__c != null ? OpportunityRecord.Entitle_To_Sales_Account__c : null;
				lineItem.Entitle_To_Account__c = OpportunityRecord.Entitle_To_Account__c != null ? OpportunityRecord.Entitle_To_Account__c : null;
				lineItem.Entitle_To_Address__c = OpportunityRecord.Entitle_To_Address__c != null ? OpportunityRecord.Entitle_To_Address__c : null;
				lineItem.Entitle_To_Contact__c = OpportunityRecord.Entitle_To_Contact__c != null ? OpportunityRecord.Entitle_To_Contact__c : null;
				lineItemList.add(lineItem);
			}
			if(lineItemList.size() > 0){
				update lineItemList;
			}
		}
	}

	// Wrapper class to build EBS Accounts, Address, Contacts for the selected Accounts
	// Note : This is not yet used in the functionality.
	// Due to static remote functionality I am facing some issues so using this is deprecated. But I will find a way to use this.
	/*
	public with sharing class OrderWrapperDetails{
		public List<EBS_Account__c> EBSAccList{get;set;}
		public List<Address__c> AddressList{get;set;}
		public List<Contact> ContactList{get;set;}
	} */
	// Wrapper class for getting details in the visualforce page.
	public with sharing class OrderDetailsWrapper{
		public String RecId{get;set;}
		public String RecName{get;set;}
		public String PartyNumber{get;set;}
		public String OwnerName{get;set;}
		public String Country{get;set;}
		public string RecordType{get;set;}//added as per US63409
		public string EbsAcc{get;set;}//added as per US64739
		public String State {get;set;}
		public String City{get;set;}
		public String lastName{get;set;}
		public String firstName{get;set;}
		public String Email{get;set;}
		public String Phone{get;set;}
		public String Fax{get;set;}
		public String AccBillingAddress{get;set;}
		public String PartyName{get;set;}
		public String AddressOne {get;set;}
		public String Province {get;set;}
		public String BillTo {get;set;}
		public String ShipTo {get;set;}
		public String EntitleTo {get;set;}
		public String SoldTo {get;set;}
		public String zipPostal {get;set;}
		public String Classification {get;set;}
		public String PartnerPrograms {get;set;}
		public String Description {get;set;}
		public String Department {get;set;}
		public String contactPhone{get;set;}
		public String contactPartyNumber{get;set;}
		public String rhnEntitlementLogin{get;set;}
		public String AddressTwo {get;set;}
		public String partySiteNumber{get;set;}
		public String AddressNumber{get;set;}

	}

	//Added as the part of user story US63466
	public Boolean func_rule29() {
	Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Entitle_To_Address__c != null) {
			if(opportunityRecord.Entitle_To_Address__r.CDH_Party_Site_Number__c == null)
			{
				msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Address__c.Label;
				sep = ',\n\t';
			}
		}
		retval = (msgFields == '');
		if(!retval) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ERROR29+msgFields+ERROR32));
		}
		return reportResult(retval,'29',null);
	}

	//Added as the part of user story US63466
	public Boolean func_rule30() {
	Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Ship_To_Address__c != null) {
		system.debug('test here if new or od CDH_Party_Site_Number__c outside value value'+opportunityRecord.Ship_To_Address__r.CDH_Party_Site_Number__c +'   '+opportunityRecord.Ship_To_Address__c);
			if(opportunityRecord.Ship_To_Address__r.CDH_Party_Site_Number__c == null)
			{
				msgFields += sep + Schema.SObjectType.Opportunity.Fields.Ship_To_Address__c.Label;

				system.debug('test here if new or od CDH_Party_Site_Number__c value'+opportunityRecord.Ship_To_Address__r.CDH_Party_Site_Number__c +'   '+opportunityRecord.Ship_To_Address__c);
				sep = ',\n\t';
			}
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ERROR30+msgFields+ERROR32));
		}
		return reportResult(retval,'30',null);
	}

	//Added as the part of user story US63466
	public Boolean func_rule31() {
	Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Sold_To_Address__c != null) {
			if(opportunityRecord.Sold_To_Address__r.CDH_Party_Site_Number__c == null)
			{
				msgFields += sep + Schema.SObjectType.Opportunity.Fields.Sold_To_Address__c.Label;
				sep = ',\n\t';
			}
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ERROR31+msgFields+ERROR32));
		}
		return reportResult(retval,'31',null);
	}

	public Boolean func_rule34() {
		Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Entitle_To_Contact__c != null) {
			if(opportunityRecord.Entitle_To_Contact__r.CDH_Party__c == null)
			{
				msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Contact__c.Label;
				sep = ',\n\t';
			}
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ERROR34+msgFields+ERROR37));
		}
		return reportResult(retval,'34',null);
	}

	public Boolean func_rule35() {
		Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Ship_To_Contact__c != null) {
			if(opportunityRecord.Ship_To_Contact__r.CDH_Party__c == null)
			{
				msgFields += sep + Schema.SObjectType.Opportunity.Fields.Ship_To_Contact__c.Label;
				sep = ',\n\t';
			}
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ERROR35+msgFields+ERROR37));
		}
		return reportResult(retval,'35',null);
	}

	public Boolean func_rule36() {
		Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Sold_To_Contact__c != null) {
			if(opportunityRecord.Sold_To_Contact__r.CDH_Party__c == null)
			{
				msgFields += sep + Schema.SObjectType.Opportunity.Fields.Sold_To_Contact__c.Label;
				sep = ',\n\t';
			}
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ERROR36+msgFields+ERROR37));
		}
	return reportResult(retval,'36',null);
	}

	/*public Boolean func_rule38_2(boolean isSubmitOpp) {
		Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Bill_To_Address__c == null) {
		  msgFields += sep + Schema.SObjectType.Opportunity.Fields.Bill_To_Address__c.Label;
		  sep = ',\n\t';
		}
		retval = (msgFields == '');
		if(! retval)
		{
			if(isSubmitOpp){
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Error38_2));
			}
			else{
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Error38_2_NoSubmit));
			}
		}
		return reportResult(retval,'38.2',null);
	}*/

	public Boolean func_rule39_1() {
	Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Ship_To_Account__c == null) {
		  msgFields += sep + Schema.SObjectType.Opportunity.Fields.Ship_To_Account__c.Label;
		  sep = ',\n\t';
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Error39_1));
		}


	return reportResult(retval,'39.1',null);

  }

  public Boolean func_rule39_2() {
	Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Ship_To_Address__c == null) {
		  msgFields += sep + Schema.SObjectType.Opportunity.Fields.Ship_To_Address__c.Label;
		  sep = ',\n\t';
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Error39_2));
		}


	return reportResult(retval,'39.2',null);

  }

  public Boolean func_rule40_1() {
	Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Sold_To_Account__c == null) {
		  msgFields += sep + Schema.SObjectType.Opportunity.Fields.Sold_To_Account__c.Label;
		  sep = ',\n\t';
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Error40_1));
		}


	return reportResult(retval,'40.1',null);

  }

	public Boolean func_rule40_2() {
	Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Sold_To_Address__c == null) {
		  msgFields += sep + Schema.SObjectType.Opportunity.Fields.Sold_To_Address__c.Label;
		  sep = ',\n\t';
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Error40_2));
		}


	return reportResult(retval,'40.2',null);

	}

	public Boolean func_rule41_1() {
	Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Entitle_To_Account__c == null) {
		  msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Account__c.Label;
		  sep = ',\n\t';
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Error41_1));
		}


	return reportResult(retval,'41.1',null);

	}

	public Boolean func_rule41_2() {
	Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.Entitle_To_Address__c == null) {
		  msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Address__c.Label;
		  sep = ',\n\t';
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Error41_2));
		}


	return reportResult(retval,'41.2',null);

	}

	public Boolean func_rule42_1() {
	Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.OpportunityLineItems.size() > 0){
			for(OpportunityLineItem lineItem : opportunityRecord.OpportunityLineItems) {
				if(lineItem.Entitle_To_Account__c == null){
					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Account__c.Label;
				  sep = ',\n\t';
					break;
				}
			}
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Error42_1));
		}

	return reportResult(retval,'42.1',null);
}

	public Boolean func_rule42_2() {
	Boolean retval = null;
		String msgFields = '';
		String sep = '\n\t';
		if(opportunityRecord.OpportunityLineItems.size() > 0){
			for(OpportunityLineItem lineItem : opportunityRecord.OpportunityLineItems) {
				if(lineItem.Entitle_To_Address__c == null){
					msgFields += sep + Schema.SObjectType.Opportunity.Fields.Entitle_To_Address__c.Label;
					sep = ',\n\t';
					break;
				}
			}
		}
		retval = (msgFields == '');
		if(! retval) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Error42_2));
		}

	return reportResult(retval,'42.2',null);
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
		}
		return retval;
	}

	public static void addInfoMessage(String infoMessage) {
		if(infoMessage != null && getBooleanSettingValue(HIDE_MESSAGES_SETTING) == false) {
		  ApexPages_Message_ControllerExtension.addInfoMessage(infoMessage);
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
	public Boolean validateOpportunityRecord(){

		// Get updated opportunity details
		OpportunityRecord = [Select
							Id,
							Name,
							CloseDate,
							StageName,
							Type,
							AccountId,
							FulfillmentChannel__c,
							Operating_Unit__c,
							Order_Type__c,
							Bill_To_Sales_Account__r.Name,
							Bill_To_Sales_Account__c,
							Bill_To_Account__r.Name,
							Bill_To_Account__c,
							Bill_To_Address_Details__c,
							Bill_To_Address__c,
							Bill_To_Contact__c,
							Bill_To_Contact__r.Name,
							Ship_To_Sales_Account__c,
							Ship_To_Sales_Account__r.Name,
							Ship_To_Account__c,
							Ship_To_Account__r.Name,
							Ship_To_Address__c,
							Ship_To_Address_Details__c,
							Ship_To_Contact__c,
							Ship_To_Contact__r.Name,
							Entitle_To_Sales_Account__c,
							Entitle_To_Sales_Account__r.Name,
							Entitle_To_Account__c,
							Entitle_To_Account__r.Name,
							Entitle_To_Address__c,
							Entitle_To_Address_Details__c,
							Entitle_To_Contact__c,
							Entitle_To_Contact__r.Name,
							Sold_To_Sales_Account__c,
							Sold_To_Sales_Account__r.Name,
							Sold_To_Account__c,
							Sold_To_Account__r.Name,
							Sold_To_Address__c,
							Sold_To_Address_Details__c,
							Sold_To_Contact__c,
							Sold_To_Contact__r.Name,
							Pending_OM_Review__c,
							OM_review_complete__c,
							Order_Status__c,
							OpportunityType__c,
							Order_Management_Profile__c,
							Owner.id,
							Set_As_Default_Profile__c,
							Entitle_To_Address__r.CDH_Party_Site_Number__c,
							Ship_To_Address__r.CDH_Party_Site_Number__c,
							Sold_To_Address__r.CDH_Party_Site_Number__c,
							Entitle_To_Contact__r.CDH_Party__c,
							Ship_To_Contact__r.CDH_Party__c,
							Sold_To_Contact__r.CDH_Party__c ,
							(Select id,
								Entitle_To_Address__c,
								Entitle_To_Account__c,
								Contract_Numbers__c,
								Configured_SKU__c,
								NewOrRenewal__c,
								PricebookEntry.ProductCode,
								PricebookEntry.Product2.Description,
								PricebookEntry.Product2.Family,
								PricebookEntry.Product2.Name,
								PricebookEntry.Product2.QuoteRequired__c
								 from opportunityLineItems)
							from Opportunity where Id = :OpportunityRecord.Id];

		Boolean func_rule29 =   func_rule29();
		Boolean func_rule30 =   func_rule30();
		Boolean func_rule31 =   func_rule31();
		Boolean func_rule34 =   func_rule34();
		Boolean func_rule35 =   func_rule35();
		Boolean func_rule36 =   func_rule36();
		//Boolean func_rule38_2 = func_rule38_2(true);
		Boolean func_rule39_1 = func_rule39_1();
		Boolean func_rule39_2 = func_rule39_2();
		Boolean func_rule40_1 = func_rule40_1();
		Boolean func_rule40_2 = func_rule40_2();
		Boolean func_rule41_1 = func_rule41_1();
		Boolean func_rule41_2 = func_rule41_2();
		Boolean func_rule42_1 = func_rule42_1();
		Boolean func_rule42_2 = func_rule42_2();

		if(!func_rule29 || !func_rule30 || !func_rule31 || !func_rule34 || !func_rule35 || !func_rule36   || !func_rule39_1
				|| !func_rule39_2 || !func_rule40_1 || !func_rule40_2 || !func_rule41_1 || !func_rule41_2 || !func_rule42_1 || !func_rule42_2)
			{
			  //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'error validation'));
			  return true;
			}
		  else
			  return false;

	}
}