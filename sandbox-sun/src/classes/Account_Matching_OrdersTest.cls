/**
 * This is the test class for Account_Matching_Orders.
 *
 * @version 2015-09-25
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-09-25 - minor test updates
 * 2015-07-06 - created
 */
@isTest
private class Account_Matching_OrdersTest {
	static List<Opportunity> opportunities {
		get {
			if(opportunities == null) {
				opportunities = Account_MatchingTest.opportunities;
				Integer i=0;
				for(Opportunity o : opportunities) {
					// This actually won't work, because as soon as we commit
					// the opportunity, the Oracle Order Number will be cleared...
					// to fix it requires an update and changing to closed booked.
					// However, the test already takes too long to run, so we are
					// punting on this detail.
					o.OracleOrderNumber__c = ''+(-1-i);
					o.PONumber__c = ''+(-101-i);
					i++;
				}
			}
			return opportunities;
		}
		set;
	}

	static Map<Id,Opportunity> opportunityMap {
		get {
			if(opportunityMap == null) {
				opportunityMap = Account_MatchingTest.opportunityMap;
			}
			return opportunityMap;
		}
		set;
	}

	static Map<Id,String> opportunityNumberMap {
		get {
			if(opportunityNumberMap == null) {
				opportunityNumberMap = new Map<Id,String>();
				for(Opportunity o : [
					select
						OpportunityNumber__c
					from Opportunity
					where Id in :opportunityMap.keySet() ] )
				{
					opportunityNumberMap.put(o.Id,o.OpportunityNumber__c);
				}
			}
			return opportunityNumberMap;
		}
		set;
	}

	static List<Opportunity_Header_Staging__c> oppHeaderStagingList {
		get {
			if(oppHeaderStagingList == null) {
				Opportunity_Header_Staging__c oppHeaderStaging = Order_Opportunity_ControllerExtnTest.oppHeaderStaging;
				oppHeaderStaging.Status__c='Not Processed';
				oppHeaderStaging.Opportunity_Number__c = null;
				oppHeaderStagingList = new List<Opportunity_Header_Staging__c>{
					oppHeaderStaging,
					oppHeaderStaging.clone(),
					oppHeaderStaging.clone(),
					oppHeaderStaging.clone(),
					oppHeaderStaging.clone() };
				oppHeaderStaging.Status__c = 'ERROR';
				Map<Id,String> oppNumMap = opportunityNumberMap;
				Id oppId = opportunities[0].Id;
				String oppNumber = oppNumMap.get(oppId);
				oppHeaderStagingList[0].Opportunity_Number__c = oppNumber;
				oppHeaderStagingList[1].Opportunity_Number__c = oppNumber;
				oppHeaderStagingList[2].Opportunity_Number__c = oppNumber;
				oppHeaderStagingList[0].Opportunity_Id__c = oppId;
				oppHeaderStagingList[2].Opportunity_Id__c = oppId;
				oppHeaderStagingList[3].Opportunity_Id__c = oppId;
			}
			return oppHeaderStagingList;
		}
		set;
	}

	static Map<Id,Opportunity_Header_Staging__c> oppHeaderStagingMap {
		get {
			if(oppHeaderStagingMap == null) {
				List<Account> salesAccounts = Order_Opportunity_ControllerExtnTest.salesAccounts;
				oppHeaderStagingList[0].Bill_To_Sales_Account__c = salesAccounts[0].Id;
				oppHeaderStagingList[0].Entitle_To_Sales_Account__c = salesAccounts[1].Id;
				oppHeaderStagingList[0].Ship_To_Sales_Account__c = salesAccounts[2].Id;
				oppHeaderStagingList[0].Sold_To_Sales_Account__c = salesAccounts[3].Id;
				for(Opportunity_Header_Staging__c ohs : oppHeaderStagingList) {
					if(ohs.Id == null) {
						upsert oppHeaderStagingList;
						break;
					}
				}
				oppHeaderStagingMap = new Map<Id,Opportunity_Header_Staging__c>(oppHeaderStagingList);
			}
			return oppHeaderStagingMap;
		}
		set;
	}

	static List<Opportunity_Line_Staging__c> oppLineStagingList {
		get {
			if(oppLineStagingList == null) {
				oppLineStagingList = new List<Opportunity_Line_Staging__c>();
				List<Account> salesAccounts = Order_Opportunity_ControllerExtnTest.salesAccounts;
				Integer salesAccountsSize = salesAccounts.size();
				Integer j=4;
				for(Opportunity_Line_Staging__c ols : Order_Opportunity_ControllerExtnTest.oppLineStagingList) {
					ols.Entitle_To_Sales_Account__r = salesAccounts[j];
					ols.Entitle_To_Sales_Account__c = salesAccounts[j].Id;
					if(++j == salesAccountsSize) {
						j=4;
					}
				}
				for(Id ohsId : oppHeaderStagingMap.keySet()) {
					for(Opportunity_Line_Staging__c ols : Order_Opportunity_ControllerExtnTest.oppLineStagingList.deepclone(true)) {
						if(ohsId != oppHeaderStagingList[0].Id) {
							ols.Entitle_To_Sales_Account__r = null;
							ols.Entitle_To_Sales_Account__c = null;
						}
						ols.Opportunity_Stage_Header_ID__c = ohsId;
						oppLineStagingList.add(ols);
					}
				}
			}
			return oppLineStagingList;
		}
		set;
	}


	static Map<Id,Opportunity_Line_Staging__c> oppLineStagingMap {
		get {
			if(oppLineStagingMap == null) {
				for(Opportunity_Line_Staging__c ols : oppLineStagingList) {
					if(ols.Id == null) {
						upsert oppLineStagingList;
						break;
					}
				}
				oppLineStagingMap = new Map<Id,Opportunity_Line_Staging__c>(oppLineStagingList);
			}
			return oppLineStagingMap;
		}
		set;
	}

	static User intadmin {
		get {
			if(intadmin == null) {
				intadmin = [select Id, ProfileId from User where Alias = 'intadmin' and IsActive = true limit 1];
			}
			return intadmin;
		}
	}

	@IsTest
	static void fullTest() {
		oppLineStagingMap.size();
		Id recordId = oppHeaderStagingList[0].Id;
		System.assertNotEquals(null,recordId);
		System.assertNotEquals(null,oppHeaderStagingList[0].Opportunity_Number__c);
		System.assertNotEquals(null,oppHeaderStagingList[0].Opportunity_Id__c);
		PageReference r = new PageReference('/apex/WhoCares');
		r.getParameters().put('id',recordId);
		Test.setCurrentPage(r);
		ApexPages.StandardController sc = new ApexPages.StandardController(oppHeaderStagingList[0]);
		Order_Opportunity_ControllerExtension controller = new Order_Opportunity_ControllerExtension(sc);
		// this creates all the relevant party objects
		System.assert(controller.isAutoCreateAllowed,'Auto-create should be allowed');
		controller.autocreate();
		// lets just make sure the creation succeeded before preceeding with our test
		List<Account> salesAccounts = Order_Opportunity_ControllerExtnTest.salesAccounts;
		Integer salesAccountsSize = salesAccounts.size();
		Map<Id,Opportunity_Header_Staging__c> ohsMap = new Map<Id,Opportunity_Header_Staging__c>(Order_Opportunity_Matching.queryOrders(oppHeaderStagingMap.keySet()));
		Opportunity_Header_Staging__c ohs0 = ohsMap.get(recordId);
		System.assertEquals(salesAccounts[0].Id,ohs0.Bill_To_Sales_Account__c);
		System.assertEquals(salesAccounts[1].Id,ohs0.Entitle_To_Sales_Account__c);
		System.assertEquals(salesAccounts[2].Id,ohs0.Ship_To_Sales_Account__c);
		System.assertEquals(salesAccounts[3].Id,ohs0.Sold_To_Sales_Account__c);
		System.assertNotEquals(null,ohs0.Bill_To_Account__c);
		System.assertNotEquals(null,ohs0.Entitle_To_Account__c);
		System.assertNotEquals(null,ohs0.Ship_To_Account__c);
		System.assertNotEquals(null,ohs0.Sold_To_Account__c);
		System.assertNotEquals(null,ohs0.Bill_To_Address__c);
		System.assertNotEquals(null,ohs0.Entitle_To_Address__c);
		System.assertNotEquals(null,ohs0.Ship_To_Address__c);
		System.assertNotEquals(null,ohs0.Sold_To_Address__c);
		System.assertNotEquals(null,ohs0.Bill_To_Contact__c);
		System.assertNotEquals(null,ohs0.Entitle_To_Contact__c);
		System.assertNotEquals(null,ohs0.Ship_To_Contact__c);
		System.assertNotEquals(null,ohs0.Sold_To_Contact__c);
		Integer j=4;
		for(Opportunity_Line_Staging__c ols : ohs0.Opportunities_Line_Staging__r) {
			System.assertEquals(salesAccounts[j].Id,ols.Entitle_To_Sales_Account__c);
			System.assertNotEquals(null,ols.Entitle_To_Account__c);
			System.assertNotEquals(null,ols.Entitle_To_Address__c);
			System.assertNotEquals(null,ols.Entitle_To_Contact__c);
			if(++j == salesAccountsSize) {
				j=4;
			}
		}
		// so far the following is just mostly coverage test
		List<Opportunity_Line_Staging__c> olsList = new List<Opportunity_Line_Staging__c>();
		for(Opportunity_Header_Staging__c ohs : ohsMap.values()) {
			olsList.addAll(ohs.Opportunities_Line_Staging__r);
		}
		System.runAs(intadmin) {
			// If we made it this far, then creation has succeeded
			Test.startTest();
			Account_Matching_Orders accountMatching = new Account_Matching_Orders(ohsMap.values(),olsList);
			accountMatching.assignRefOppId(); // opportunity mappings
			for(Account_Matching_Orders.OrderParty orderParty : accountMatching.orderParties) {
				if(orderParty.opportunityNumber != null) {
					System.assertNotEquals(null,orderParty.refOppId,'Expected refOppId for # '+orderParty.opportunityNumber+' map '+accountMatching.potentialOppMap);
				}
			}
			accountMatching.match(); // does the basic matching
			for(Account_Matching_Orders.OrderParty orderParty : accountMatching.orderParties) {
				System.assertNotEquals(null,orderParty.getBestEBSAccount());
				System.assertNotEquals(null,orderParty.getBestAddress(true));
				System.assertNotEquals(null,orderParty.getBestContact(true));
			}
			accountMatching.filter(); // filters out duplicates and partners
			for(Account_Matching_Orders.OrderParty orderParty : accountMatching.orderParties) {
				System.assertNotEquals(null,orderParty.getEBSAccount());
				System.assertNotEquals(null,orderParty.getAddress());
				System.assertNotEquals(null,orderParty.getContact());
			}
			// report errors 
			accountMatching.errorsAndWarningsReporting();
			for(Account_Matching_Orders.OrderParty orderParty : accountMatching.orderParties) {
				System.assertEquals(0,orderParty.errorMessages.size());
			}
			accountMatching.assignFrom(); // assign values to the staging records
			for(Account_Matching_Orders.OrderParty orderParty : accountMatching.orderParties) {
				System.assert(orderParty.useProactiveMatching(),'Proactive matching should be used');
				if(orderParty.header.Id != recordId) {
					Integer errorCount = 0;
					if (orderParty.toType == Account_Matching.AccountToType.LINE_ENTITLE_TO)
					{
						if(orderParty.stagingLine.Entitle_To_Sales_Account__c != null) {
							errorCount = 1;
						}
						System.assertEquals(errorCount,orderParty.errorMessages.size(),'Error count not as expected: '+orderParty.toType+' '+orderParty.stagingLine);
					}
					else { 
						if ( (orderParty.toType == Account_Matching.AccountToType.BILL_TO && orderParty.header.Bill_To_Sales_Account__c != null)
							|| (orderParty.toType == Account_Matching.AccountToType.ENTITLE_TO  && orderParty.header.Entitle_To_Sales_Account__c != null)
							|| (orderParty.toType == Account_Matching.AccountToType.SHIP_TO  && orderParty.header.Ship_To_Sales_Account__c != null)
							|| (orderParty.toType == Account_Matching.AccountToType.SOLD_TO  && orderParty.header.Sold_To_Sales_Account__c != null) )
						{
							errorCount = 1;
						}
						System.assertEquals(errorCount,orderParty.errorMessages.size(),'Error count not as expected: '+orderParty.toType+' '+orderParty.header);
					}
				}
				else {
					System.assertEquals(0,orderParty.errorMessages.size());
				}
			}
			List<Match_and_Validation_Error__c> errorList = accountMatching.getErrorAndWarnList();
			System.assertEquals(20,errorList.size());
			for(Match_and_Validation_Error__c e : errorList) {
				System.assertNotEquals(null,e.Error_Code__c);
				System.assertNotEquals(null,e.Error_Description__c);
				System.assertNotEquals(null,e.Error_Type__c);
				System.assertNotEquals(null,e.Opportunity_Staging_Header__r);
				System.assertNotEquals(null,e.Opportunity_Staging_Header__c);
				System.assertNotEquals(null,e.Related_Field_API_Name__c);
			}
			Test.stopTest();
		}

		// lets at least make sure everything was assigned correctly
		for(Opportunity_Header_Staging__c ohs : ohsMap.values()) {
			System.assertEquals(ohs0.Bill_To_Account__c,ohs.Bill_To_Account__c,'Expected Bill_To_Account__c for '+ohs);
			System.assertEquals(ohs0.Entitle_To_Account__c,ohs.Entitle_To_Account__c,'Expected Entitle_To_Account__c for '+ohs);
			System.assertEquals(ohs0.Ship_To_Account__c,ohs.Ship_To_Account__c,'Expected Ship_To_Account__c for '+ohs);
			System.assertEquals(ohs0.Sold_To_Account__c,ohs.Sold_To_Account__c,'Expected Sold_To_Account__c for '+ohs);
			System.assertEquals(ohs0.Bill_To_Address__c,ohs.Bill_To_Address__c,'Expected Bill_To_Address__c for '+ohs);
			System.assertEquals(ohs0.Entitle_To_Address__c,ohs.Entitle_To_Address__c,'Expected Entitle_To_Address__c for '+ohs);
			System.assertEquals(ohs0.Ship_To_Address__c,ohs.Ship_To_Address__c,'Expected Ship_To_Address__c for '+ohs);
			System.assertEquals(ohs0.Sold_To_Address__c,ohs.Sold_To_Address__c,'Expected Sold_To_Address__c for '+ohs);
			System.assertEquals(ohs0.Bill_To_Contact__c,ohs.Bill_To_Contact__c,'Expected Bill_To_Contact__c for '+ohs);
			System.assertEquals(ohs0.Entitle_To_Contact__c,ohs.Entitle_To_Contact__c,'Expected Entitle_To_Contact__c for '+ohs);
			System.assertEquals(ohs0.Ship_To_Contact__c,ohs.Ship_To_Contact__c,'Expected Ship_To_Contact__c for '+ohs);
			System.assertEquals(ohs0.Sold_To_Contact__c,ohs.Sold_To_Contact__c,'Expected Sold_To_Contact__c for '+ohs);
			System.assertEquals(salesAccounts[0].Id,ohs.Bill_To_Sales_Account__c);
			System.assertEquals(salesAccounts[1].Id,ohs.Entitle_To_Sales_Account__c);
			System.assertEquals(salesAccounts[2].Id,ohs.Ship_To_Sales_Account__c);
			System.assertEquals(salesAccounts[3].Id,ohs.Sold_To_Sales_Account__c);
			Integer i=0;
			for(Opportunity_Line_Staging__c ols : ohs.Opportunities_Line_Staging__r) {
				Opportunity_Line_Staging__c ols0 = ohs0.Opportunities_Line_Staging__r[i++];
				System.assertEquals(ols0.Entitle_To_Sales_Account__c,ols.Entitle_To_Sales_Account__c,'Expected '+ols0.Entitle_To_Sales_Account__r+' not '+ols.Entitle_To_Sales_Account__r+' for '+ols);
				System.assertEquals(ols0.Entitle_To_Account__c,ols.Entitle_To_Account__c,'Expected '+ols0.Entitle_To_Account__r+' not '+ols.Entitle_To_Account__r+' for '+ols);
				System.assertEquals(ols0.Entitle_To_Address__c,ols.Entitle_To_Address__c,'Expected '+ols0.Entitle_To_Address__r+' not '+ols.Entitle_To_Address__r+' for '+ols);
				System.assertEquals(ols0.Entitle_To_Contact__c,ols.Entitle_To_Contact__c,'Expected '+ols0.Entitle_To_Contact__r+' not '+ols.Entitle_To_Contact__r+' for '+ols);
			}
		}
	}
}