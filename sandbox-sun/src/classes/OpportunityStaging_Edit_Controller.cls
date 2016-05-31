/**
 * Controller for editing staging records.
 * 
 * @version 2016-03-01
 * @author Sagar Mehta <smehta@redhat.com>
 * @since 2014 - Used for implementing custom visualforce page logic for Opportunity Header Stage.
 * @since 2014 - User Story US55531: [SFDC & EBS] [SFDC] Order Opp Staging Table GUI: Header and Tab structure (No lines & No Partners)
 * @since 2014 - Task TA148344: Create Visual Force Page(s) and asscoiated controller(s)
 * @since 2014 - User Story US54874: [SFDC & EBS] [SFDC] Order Opp Staging Table GUI: Partner & Lines
 * @since 2014 - Task TA153207: Update the controller and Visual force page to view and Update Partner Information
 * @since 2014 - Task TA153208: Update the controller and Visual force page to view and Update the opportunity line information
 * @since 2014 - User Story US66203 : Country of order field can be set on the staging table
 * @since 2014 - User Story: US65054 - Need ability set opportunity type for Master Claim opportunities
 * @since 2014-10-08 - User Story: US67158 - Opportunity Name/Number Change in the staging table not saved
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2016-03-01 - Fixed formatting errors
 * @since 2016-02-09 - Corrected opportunity number query criteria
 * @since 2016-01-19 - Change assignment of staging referenced
 * @since 2015-08-28 - US72618 commented out touched__c assignment, fixed formatting
 */
public with sharing class OpportunityStaging_Edit_Controller{
	private Profile profile;

	public String oldMatchingId;
	public String oldMatchingValue;
	public String oldOpportunityNumber;

	public String opptyHeaderStagingId{get;set;}

	public String status{get;set;}
	public String selectedTab{get;set;}
	public String fieldNameSet{get;set;}
	public String selectedTabName{get;set;}
	public String lineFieldNameSet{get;set;}
	public String partnerFieldNameSet{get;set;}
	public String selOpportunityValue{get;set;}
	public String selOpportunityValueID{get;set;}

	public boolean matchErrorFlag{get;set;}
	public boolean oppPotentialMatch{get;set;}
	public boolean isStatusDisplayed{get;set;}
	public boolean isStatusPickListDisplayed{get;set;}

	public List<SelectOption> statusOptions{get;set;}

	/** used to display the error messages in tabular format */
	public transient List<Match_and_Validation_Error__c> errorList;

	/** current record being viewed */
	public Opportunity_Header_Staging__c headerStaging{get;set;}

	private static final String LINE = 'Line';
	private static final String ERROR = 'Error';
	private static final String HEADER = 'Header';
	private static final String PARTNER = 'Partner';
	private static final String READY_FOR_REPROCESSING = 'Ready For Reprocessing';
	private static final String PENDING_BOOKED_ORDER_PROCESS= 'Pending Booked Order Process';

	/**
	 * Constructor of the Controller class - Initializes all the variables.
	 * Populates forecast quarter data into forecast list
	 * @param controller
	 */
	public OpportunityStaging_Edit_Controller(ApexPages.StandardController controller) {
		if (!Test.isRunningTest()) {
			controller.addFields(new List<String>{'Date_Booked__c','Channel__c', 'Order_Status__c'});}

		headerStaging = (Opportunity_Header_Staging__c)controller.getRecord();
		opptyHeaderStagingId = controller.getRecord().Id;
		selectedTabName = 'HeaderDetails';

		matchErrorFlag = true;
		isStatusDisplayed = false;
		isStatusPickListDisplayed = true;
	 
		// get the list of potentialMatches
		//mapPotentialOpp= new map<id,Potential_Matched_Opportunities__c>();
		if([select count() from Potential_Matched_Opportunities__c where Opportunity_Header_Staging__c=:opptyHeaderStagingId]>0){
			oppPotentialMatch=true;
		}else{
			oppPotentialMatch=false;
		}
		// selOpportunityValue = (String)controller.getRecord().get('Opportunity_Name__r');
		for(Opportunity o : [Select id, name, OpportunityNumber__c from Opportunity where id=:(String)controller.getRecord().get('Opportunity_Name__c') Limit 1]){
			selOpportunityValue = o.Name;
			selOpportunityValueID = o.id;
			oldMatchingId = o.id;
			oldMatchingValue = o.Name;
			oldOpportunityNumber = o.OpportunityNumber__c;
		}
		errorList = new List<Match_and_Validation_Error__c>();		 
		statusOptions = new List<SelectOption>();
		/* Retrieve all the editable fields from fieldset.
		 * Used to determine if a field should be readonly or editable on visualforce page.
		 */
		for(Schema.FieldSetMember f : SObjectType.Opportunity_Header_Staging__c.FieldSets.Opportunity_Header_Editable_Field_Set.getFields()) {
			fieldNameSet += '[' + f.getFieldPath() + '], ';
		}

		for(Schema.FieldSetMember f : SObjectType.Opportunity_Line_Staging__c.FieldSets.Oppty_Line_Staging_Editable_Field_Set.getFields()) {
			lineFieldNameSet += f.getFieldPath() + ', ';
		}

		for(Schema.FieldSetMember f : SObjectType.Opportunity_Partner_Staging__c.FieldSets.Oppty_Partner_Staging_Editable_Field_Set.getFields()) {
			partnerFieldNameSet += f.getFieldPath() + ', ';
		}
		status = headerStaging.Status__c;	 
		statusOptions.add(new SelectOption(ERROR, ERROR));
		statusOptions.add(new SelectOption(READY_FOR_REPROCESSING, READY_FOR_REPROCESSING));

		selectedTab = 'headerStagingTab';
		List<Profile> profileList = new List<Profile>();
		profileList = [Select Id, Name from Profile where Id =: UserInfo.getProfileid()];
		if(!profileList.isEmpty())
			profile = profileList.get(0);

		if(headerStaging.Status__c != 'Error' && headerStaging.Order_Status__c == 'BOOKED' && profile != null && profile.Name != Label.Administrator_Level_1 && profile.Name != Label.Administrator_Level_2){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Order_Status_Not_Error));
			isStatusDisplayed = true;
			isStatusPickListDisplayed = false;
		}else if(headerStaging.Order_Status__c != 'BOOKED' && profile != null && profile.Name != Label.Administrator_Level_1 && profile.Name != Label.Administrator_Level_2){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Order_Status_Not_Booked));
			isStatusDisplayed = true;
			isStatusPickListDisplayed = false;
		}				 
	}

	/**
	 * Used to retrieve list of Opportunity Line Staging records related to a Opportunity Stage Header record.
	 */
	public List<Opportunity_Line_Staging__c> relatedOpptyLineStagingList{
		get{
			if(relatedOpptyLineStagingList == null){
				relatedOpptyLineStagingList = new List<Opportunity_Line_Staging__c>();
				String query = buildLineStagingQuery();
				relatedOpptyLineStagingList = (List<Opportunity_Line_Staging__c>)Database.query(query);													 
			}
			if(selectedTab == 'lineStagingTab'){
				Integer lineLimit;
				Integer lineCount = [Select count() from Opportunity_Line_Staging__c where Opportunity_Stage_Header_ID__c =: opptyHeaderStagingId];
				Oppty_Staging_Limit__c limitSetting = Oppty_Staging_Limit__c.getInstance('LineStaging');
				try{
					if(limitSetting.Limit__c != null)
						lineLimit = Integer.valueOf(limitSetting.Limit__c);
					else
						lineLimit = 10;				 
				}catch(Exception e){
					lineLimit = 0;
				} 
				if(lineCount > lineLimit){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, limitSetting.Limit__c + ' ' + Label.Line_Staging_Configurable_Message));				 
				}
			}
			return relatedOpptyLineStagingList;
		}
		set;
	}

	/**
	 * Used to return SOQL query of Opportunity Line Staging related to a Opportunity Stage Header record.
	 * @return query string for opportunity line staging records
	 */
	public String buildLineStagingQuery(){
		String query = 'SELECT ';
		for(Schema.FieldSetMember f : SObjectType.Opportunity_Line_Staging__c.FieldSets.Entitle_To_Account_Information_FieldSet.getFields()) {
			query += f.getFieldPath() + ', ';
		}
		for(Schema.FieldSetMember f : SObjectType.Opportunity_Line_Staging__c.FieldSets.Entitle_To_Address_Information_FieldSet.getFields()) {
			query += f.getFieldPath() + ', ';
		}
		for(Schema.FieldSetMember f : SObjectType.Opportunity_Line_Staging__c.FieldSets.Entitle_To_Contact_Information_Field_Set.getFields()) {
			query += f.getFieldPath() + ', ';
		}
		for(Schema.FieldSetMember f : SObjectType.Opportunity_Line_Staging__c.FieldSets.Oppty_Line_Staging_Information_FieldSet.getFields()) {
			query += f.getFieldPath() + ', ';
		}
		query += 'Id, Name, ActualEndDate__c, ActualStartDate__c, Base_Price__c, Quantity__c, UnitPrice__c, Total_Price__c FROM Opportunity_Line_Staging__c';
		query += ' where Opportunity_Stage_Header_ID__c = \'' +opptyHeaderStagingId+ '\'';
		Oppty_Staging_Limit__c limitSetting = Oppty_Staging_Limit__c.getInstance('LineStaging');
		if(limitSetting.Limit__c != null)
			query += ' LIMIT ' + limitSetting.Limit__c;
		else
			query += ' LIMIT 10';

		system.debug('========================================================================>'+query);
		return query;
	}

	/**
	 * Used to retrieve list of Opportunity Partner Staging records related to a Opportunity Stage Header record.
	 */
	public List<Opportunity_Partner_Staging__c> relatedOpptyPartnerStagingList{
		get{
			if(relatedOpptyPartnerStagingList == null){
				relatedOpptyPartnerStagingList = new List<Opportunity_Partner_Staging__c>();		 
				String query = buildPartnerStagingQuery();
				relatedOpptyPartnerStagingList = (List<Opportunity_Partner_Staging__c>)Database.query(query);
			}
			if(selectedTab == 'partnerStagingTab'){
				Integer lineLimit;
				Integer lineCount = [Select count() from Opportunity_Partner_Staging__c where Opportunity_Stage_Header_ID__c =: opptyHeaderStagingId];
				Oppty_Staging_Limit__c limitSetting = Oppty_Staging_Limit__c.getInstance('PartnerStaging');
				try{
				 if(limitSetting.Limit__c != null)
					lineLimit = Integer.valueOf(limitSetting.Limit__c);
				 else
					lineLimit = 10;
				}catch(Exception e){
				 lineLimit = 0;
				} 
				if(lineCount > lineLimit){
				 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, limitSetting.Limit__c + ' ' + Label.Partner_Staging_Configurable_Message));				 
				}
			} 
			return relatedOpptyPartnerStagingList;
		}
		set;
	}

	/**
	 * Used to return SOQL query of Opportunity Partner Staging related to a Opportunity Stage Header record.
	 * 
	 * @return query string for opportunity partner staging records
	 */
	public String buildPartnerStagingQuery(){
		String query = 'SELECT ';
		for(Schema.FieldSetMember f : SObjectType.Opportunity_Partner_Staging__c.FieldSets.Oppty_Partner_Staging_Info_FieldSet.getFields()) {
			query += f.getFieldPath() + ', ';
		}
		query += 'Id, Name, CDH_Party_Number__c, Partner_Contact_CDH_Party_Number__c FROM Opportunity_Partner_Staging__c';
		query += ' where Opportunity_Stage_Header_ID__c = \'' +opptyHeaderStagingId+ '\'';
		Oppty_Staging_Limit__c limitSetting = Oppty_Staging_Limit__c.getInstance('PartnerStaging');
		if(limitSetting.Limit__c != null)
			query += ' LIMIT ' + limitSetting.Limit__c;
		else
			query += ' LIMIT 10'; 
		return query;
	}

	/**
	 * Used as a accessor method to get the Error Messages from Match_and_Validation_Error_-c object related to Staging Header.
	 * @return related errors logged after matching logic processing if there otherwise blank list.
	 */
	public List<Match_and_Validation_Error__c> getErrorList(){
		String query;
		List<Match_and_Validation_Error__c> errorMsgList = new List<Match_and_Validation_Error__c>();
		try{
			/**
			* Need to select error messages based on the selected tab.
			* selectedTab value changes when user clicks on a new tab.
			*/
			query = 'SELECT Id,';
			query = query + ' Name,';
			query = query + ' Error_Code__c,';
			query = query + ' Error_Type__c,';
			query = query + ' Error_Description__c,';
			query = query + ' Related_Field_API_Name__c,';
			query = query + ' Opportunity_Partner_Staging__c,';
			query = query + ' Opportunity_Product_Staging__c';
			query = query + ' FROM Match_and_Validation_Error__c';
			query = query + ' WHERE Opportunity_Staging_Header__c = \'' + opptyHeaderStagingId + '\'' ;
			if(selectedTab == 'headerStagingTab'){
				query = query + ' AND Error_Type__c =: ' + HEADER;
			}else if(selectedTab == 'lineStagingTab'){
				query = query + ' AND Opportunity_Product_Staging__c != null and Error_Type__c =: ' + LINE;
			}else if(selectedTab == 'partnerStagingTab'){
				query = query + ' AND Opportunity_Partner_Staging__c != null and Error_Type__c =: ' + PARTNER;
			}
			List<Match_and_Validation_Error__c> matchingErrorList = new List<Match_and_Validation_Error__c>();
			matchingErrorList = Database.query(query);
			matchErrorFlag = true;
			if(matchingErrorList != null && matchingErrorList.size() < 50){
				errorMsgList = matchingErrorList;
				matchErrorFlag = true;
			}else if(matchingErrorList != null && matchingErrorList.size() > 50){
				matchErrorFlag = false;
				ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Matching_Validation_Error_Msg));
			}
		}catch(Exception e){
			ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
		}
		return errorMsgList;
	}

	/**
	 * Used to override the save method of StandardController.
	 * @return reference to the opportunity header staging page, or null
	 */
	public PageReference save(){
		try{
			if(headerStaging.Create_New_Opportunity__c && headerStaging.Sales_Account__c== null){
				ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select the Sales Account that will be associated with the opportunity created' ));
				return null;
			}else{
				map<string,string> countryCodeAndGlobalRegionMap = new map<string,string>();
				//Search country based on coutry code
				for(Country__c country :[Select Name ,
								Iso3166Alpha2__c,
								Global_Region__c
								from Country__c ]){
					countryCodeAndGlobalRegionMap.put(country.Iso3166Alpha2__c,country.Global_Region__c);
				}
				// update the related patner staging records to escape the Validation rule
				list<Opportunity_Partner_Staging__c> oPSList= new list<Opportunity_Partner_Staging__c>();
				for(Opportunity_Partner_Staging__c oPS:[select id,name,Escape_Partner_Check__c,Opportunity_Stage_Header_ID__c
										from Opportunity_Partner_Staging__c
										where Opportunity_Stage_Header_ID__c=:headerStaging.id]){
					oPS.Escape_Partner_Check__c=true;
					oPSList.add(oPS);

				}
				if(!oPSList.isempty()){
					database.update(oPSList);
				}
				// Update the value for header staging with the given value
				headerStaging.Status__c = status;
				// In case create new opportunity checked

				if(headerStaging.Create_New_Opportunity__c !=null && headerStaging.Create_New_Opportunity__c && (headerStaging.Opportunity_Number__c ==null || headerStaging.Opportunity_Number__c =='') && headerStaging.status__c==READY_FOR_REPROCESSING){
					// Create new Opportunity in case this value is checked before updating the record
					string oppNameAssignmentValue=[select id,Name from Account where id=:headerStaging.Sales_Account__c limit 1].Name;
					if(headerStaging.Oracle_Order_Number__c !=null){
						oppNameAssignmentValue+='-'+headerStaging.Oracle_Order_Number__c;
					}
					if(headerStaging.Date_Booked__c !=null){
						oppNameAssignmentValue+='-'+headerStaging.Date_Booked__c.year()+'-'+headerStaging.Date_Booked__c.month()+'-'+headerStaging.Date_Booked__c.day();
					}
					Opportunity newRelatedOpportunity= new Opportunity();
					if( oppNameAssignmentValue!= null && oppNameAssignmentValue !=''){
						newRelatedOpportunity.Name=oppNameAssignmentValue;
					}else{
						newRelatedOpportunity.Name= headerStaging.name;
					}
					// Query the Values from Opportunity header that are not added to the page
					Opportunity_Header_Staging__c oppHeadertoUpdate=[select id,name,PO_Number__c,Resller_PO__c,Operating_Unit__c,Payment_Type__c,
										// Oracle_Order_ID__c,Oracle_Order_Number__c,Entitle_To_Country__c,CurrencyIsoCode,Order_Type__c
										//Changes for US63990
										Oracle_Order_ID__c,Oracle_Order_Number__c,Entitle_To_Country__c,CurrencyIsoCode,Order_Type__c,Sold_To_Country__c
										from Opportunity_Header_Staging__c where id=:headerStaging.id];

					newRelatedOpportunity.recordtypeId=[SELECT Name,SobjectType FROM RecordType WHERE Name = 'Booked opp process' AND SobjectType='Opportunity' limit 1].id;
					newRelatedOpportunity.Bill_To_Account__c=headerStaging.Bill_To_Account__c;
					newRelatedOpportunity.Ship_To_Account__c=headerStaging.Ship_To_Account__c;
					newRelatedOpportunity.Sold_To_Account__c=headerStaging.Sold_To_Account__c;
					newRelatedOpportunity.Entitle_To_Account__c=headerStaging.Sold_To_Account__c;
					newRelatedOpportunity.Bill_To_Address__c=headerStaging.Bill_To_Address__c;
					newRelatedOpportunity.Ship_To_Address__c=headerStaging.Ship_To_Address__c;
					newRelatedOpportunity.Sold_To_Address__c=headerStaging.Sold_To_Address__c;
					newRelatedOpportunity.Entitle_To_Address__c=headerStaging.Entitle_To_Address__c;
					newRelatedOpportunity.Bill_To_Sales_Account__c=headerStaging.Bill_To_Sales_Account__c;
					newRelatedOpportunity.Ship_To_Sales_Account__c=headerStaging.Ship_To_Sales_Account__c;
					newRelatedOpportunity.Sold_To_Sales_Account__c=headerStaging.Sold_To_Sales_Account__c;
					newRelatedOpportunity.Entitle_To_Sales_Account__c=headerStaging.Entitle_To_Sales_Account__c;
					newRelatedOpportunity.Bill_To_Contact__c=headerStaging.Bill_To_Contact__c;
					newRelatedOpportunity.Ship_To_Contact__c=headerStaging.Ship_To_Contact__c;
					newRelatedOpportunity.Sold_To_Contact__c=headerStaging.Sold_To_Contact__c;
					newRelatedOpportunity.Entitle_To_Contact__c=headerStaging.Entitle_To_Contact__c;
					newRelatedOpportunity.FulfillmentChannel__c=headerStaging.Channel__c;
					newRelatedOpportunity.Order_Status__c='BOOKED';
					newRelatedOpportunity.PONumber__c =oppHeadertoUpdate.PO_Number__c;
					newRelatedOpportunity.Reseller_PO__c=oppHeadertoUpdate.Resller_PO__c;
					newRelatedOpportunity.Operating_Unit__c=oppHeadertoUpdate.Operating_Unit__c;
					newRelatedOpportunity.Order_Type__c=oppHeadertoUpdate.Order_Type__c;
					newRelatedOpportunity.PaymentType__c=oppHeadertoUpdate.Payment_Type__c;
					newRelatedOpportunity.OracleOrderID__c=oppHeadertoUpdate.Oracle_Order_ID__c;
					newRelatedOpportunity.OracleOrderNumber__c=oppHeadertoUpdate.Oracle_Order_Number__c;
					/* Changes for US63990
					if(countryCodeAndGlobalRegionMap !=null &&
						oppHeadertoUpdate.Entitle_To_Country__c !=null &&
							countryCodeAndGlobalRegionMap.get(oppHeadertoUpdate.Entitle_To_Country__c)!=null){
						newRelatedOpportunity.Country_of_Order__c=countryCodeAndGlobalRegionMap.get(oppHeadertoUpdate.Entitle_To_Country__c);
					}*/

					// Code Changes for User Story: US66203 - Country of order field can be set on the staging table
					if(headerStaging.Country_of_Order__c != null){
						newRelatedOpportunity.Country_of_Order__c = headerStaging.Country_of_Order__c;
					}else{
						//Added for US63990				 
						List<Region__c> regionList = new List<Region__c>();
						if(oppHeadertoUpdate.Sold_To_Country__c != null)
						{
							regionList = [Select Id, Country__c from Region__c where Country_ISO_Code__c =: oppHeadertoUpdate.Sold_To_Country__c];
						}

						if(regionList != null && regionList.size() > 0 && regionList.get(0).Country__c != null){
							newRelatedOpportunity.Country_of_Order__c = regionList.get(0).Country__c;
						}else{
							newRelatedOpportunity.Country_of_Order__c = null;
						}
					}

					// Code Changes for User Story: US65054 - Need ability set opportunity type for Master Claim opportunities
					System.debug('headerStaging.Opportunity_Type__c: '+headerStaging.Opportunity_Type__c);
					if(headerStaging.Opportunity_Type__c != null)
						newRelatedOpportunity.OpportunityType__c = headerStaging.Opportunity_Type__c;
					else
						newRelatedOpportunity.OpportunityType__c = 'Standard';

//depreciated					newRelatedOpportunity.Touched__c=true;
					newRelatedOpportunity.Pay_Now__c='No';
					newRelatedOpportunity.CurrencyIsoCode=oppHeadertoUpdate.CurrencyIsoCode;
					//newRelatedOpportunity.OwnerID = [select id,OwnerID from Account where ID=:headerStaging.Sales_Account__c].OwnerID;

					if(headerStaging.Opportunity_Owner__c != null){
						newRelatedOpportunity.OwnerID = headerStaging.Opportunity_Owner__c;
					}else{
						List<Account> accList = new List<Account>();
						accList = [select Id, OwnerId from Account where Id =: headerStaging.Sales_Account__c];
						if(accList.size() > 0)
							newRelatedOpportunity.OwnerID = accList.get(0).OwnerId;
					}

					// Update the clsed date on Opportunity based on booked date from Staging record
					if(headerStaging.Date_Booked__c !=null){
						newRelatedOpportunity.CloseDate=headerStaging.Date_Booked__c;
					}else{
						newRelatedOpportunity.CloseDate=System.today();
					}

					newRelatedOpportunity.AccountID=headerStaging.Sales_Account__c;
					newRelatedOpportunity.StageName='Closed Booked';
					newRelatedOpportunity.recordtypeID=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Booked Opp Process').getRecordTypeId();

					//Added for US64957 to set flag IsStagingReferred__c to true when currencyIsoCode is ARS
//US79718 					if(headerStaging.CurrencyIsoCode=='ARS')
//US79718 					{
					newRelatedOpportunity.IsStagingReferred__c = true;
//US79718 					}

					insert newRelatedOpportunity;
					// Update the Opportunity staging record with the related values
					headerStaging.Opportunity_Number__c=[select id,name,OpportunityNumber__c from Opportunity where id=:newRelatedOpportunity.id].OpportunityNumber__c;
					headerStaging.Opportunity_Name__c=newRelatedOpportunity.id;
				}else if(headerStaging.Create_New_Opportunity__c !=null && !headerStaging.Create_New_Opportunity__c){
					// Code Changes for User Story: US67158 - Opportunity Name/Number Change in the staging table not saved
					if(headerStaging.Opportunity_Name__c != null && (headerStaging.Opportunity_Number__c != null || headerStaging.Opportunity_Number__c != '')
						&& oldOpportunityNumber != headerStaging.Opportunity_Number__c
						&& oldMatchingId != headerStaging.Opportunity_Name__c){
						List<Opportunity> opptyList = new List<Opportunity>();
						opptyList = [select Id from Opportunity where OpportunityNumber__c =: headerStaging.Opportunity_Number__c];
						if(opptyList.size() > 0){
							headerStaging.Opportunity_Name__c = opptyList.get(0).Id;
						}
					}else if(headerStaging.Opportunity_Name__c != null && (headerStaging.Opportunity_Number__c != null || headerStaging.Opportunity_Number__c != '')
						&& oldOpportunityNumber != headerStaging.Opportunity_Number__c){
						List<Opportunity> opptyList = new List<Opportunity>();
						opptyList = [select Id from Opportunity where OpportunityNumber__c =: headerStaging.Opportunity_Number__c];
						if(opptyList.size() > 0){
							headerStaging.Opportunity_Name__c = opptyList.get(0).Id;
						}
					}else if(headerStaging.Opportunity_Name__c != null &&
						(headerStaging.Opportunity_Number__c != null || headerStaging.Opportunity_Number__c != '') &&
						oldMatchingId != headerStaging.Opportunity_Name__c){
						List<Opportunity> opptyList = new List<Opportunity>();
						opptyList = [select id, OpportunityNumber__c from Opportunity where id =: headerStaging.Opportunity_Name__c];
						if(opptyList.size() > 0){
							headerStaging.Opportunity_Number__c = opptyList.get(0).OpportunityNumber__c;
						}
					}else if(headerStaging.Opportunity_Name__c == null && headerStaging.Opportunity_Number__c != null && headerStaging.Opportunity_Number__c != ''){
						List<Opportunity> opptyList = new List<Opportunity>();
						opptyList = [select Id from Opportunity where OpportunityNumber__c =: headerStaging.Opportunity_Number__c];
						if(opptyList.size() > 0){
							headerStaging.Opportunity_Name__c = opptyList.get(0).Id;
						}
					}else if(headerStaging.Opportunity_Name__c != null && (headerStaging.Opportunity_Number__c == null || headerStaging.Opportunity_Number__c == '')){
						List<Opportunity> opptyList = new List<Opportunity>();
						opptyList = [select id, OpportunityNumber__c from Opportunity where id =: headerStaging.Opportunity_Name__c];
						if(opptyList.size() > 0){
							headerStaging.Opportunity_Number__c = opptyList.get(0).OpportunityNumber__c;
						}
					}

					if(selOpportunityValueId !=null && selOpportunityValueId !='' && oldMatchingId != selOpportunityValueId){
						List<Opportunity> oppList = new List<Opportunity>();
						oppList = [select id, name, OpportunityNumber__c, OwnerId from Opportunity where id =: selOpportunityValueId];
						if(oppList != null && oppList.size() > 0){
							headerStaging.Opportunity_Number__c = oppList.get(0).OpportunityNumber__c;
							headerStaging.Opportunity_Name__c = selOpportunityValueId;
							if(headerStaging.Opportunity_Owner__c != null){
								oppList.get(0).OwnerID = headerStaging.Opportunity_Owner__c;
							}else{
								List<Account> accList = new List<Account>();
								accList = [select Id, OwnerId from Account where Id =: headerStaging.Sales_Account__c];
								if(accList.size() > 0)
									oppList.get(0).OwnerID = accList.get(0).OwnerId;
							}
							update oppList;
						}
					}
				}

				update headerStaging;

				if(relatedOpptyPartnerStagingList != null && relatedOpptyPartnerStagingList.size() > 0)
					update relatedOpptyPartnerStagingList;

				if(relatedOpptyLineStagingList != null && relatedOpptyLineStagingList.size() > 0)
					update relatedOpptyLineStagingList;

			}
		}catch(Exception e){
			if(e.getMessage().contains('This record does not have Status as'))
				ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Order_Status_Not_Error));
			else if(e.getMessage().contains('This record does not have Order Status as'))
				ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Order_Status_Not_Booked));
			else
				ApexPages.addmessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));

			return null;
		}

		return new PageReference('/'+opptyHeaderStagingId);
	}

	/**
	 * Used to switch tabs and call ErrorMessage.
	 */
	public void switchTabs(){
		if(headerStaging.Status__c != 'Error' && headerStaging.Order_Status__c == 'BOOKED' && profile != null && profile.Name != Label.Administrator_Level_1 && profile.Name != Label.Administrator_Level_2)
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Order_Status_Not_Error));
		else if(headerStaging.Order_Status__c != 'BOOKED' && profile != null && profile.Name != Label.Administrator_Level_1 && profile.Name != Label.Administrator_Level_2)
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Order_Status_Not_Booked));

		getErrorList();
	}

	/**
	 * Used to copy Entitle Information from Header Staging to Line Staging.
	 */
	public void copyEntitleToFromHeaderInformation(){
		for(Opportunity_Line_Staging__c lineStaging : relatedOpptyLineStagingList){
			lineStaging.Entitle_To_Sales_Account__c = headerStaging.Entitle_To_Sales_Account__c;
			lineStaging.Entitle_To_Account__c = headerStaging.Entitle_To_Account__c;
			lineStaging.Entitle_To_Address__c = headerStaging.Entitle_To_Address__c;
			lineStaging.Entitle_To_Contact__c = headerStaging.Entitle_To_Contact__c;
		}
	}
}