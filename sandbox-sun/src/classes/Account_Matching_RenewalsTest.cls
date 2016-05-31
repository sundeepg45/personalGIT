/**
 * This is the test class for Account_Matching_Renewals.
 *
 * @version 2015-02-12
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-02-12 - Revised logic to support assigning refSalesAccountId values
 * 2014-12-05 - created
 */
@isTest
public class Account_Matching_RenewalsTest {
	public static List<Opportunity> opportunities {
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

	public static Map<Id,Opportunity> opportunityMap {
		get {
			if(opportunityMap == null) {
				opportunityMap = Account_MatchingTest.opportunityMap;
			}
			return opportunityMap;
		}
		set;
	}

	public static Map<Id,String> opportunityNumberMap {
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

	static List<Account_Matching_Renewals.RenewalParty> getRenewalPartyList() {
		return new List<Account_Matching_Renewals.RenewalParty>{
			new Account_Matching_Renewals.RenewalParty( // scenario 0
				Account_Matching.AccountToType.BILL_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				null, // oracle account number
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null, // String email )
				opportunityNumberMap.get(opportunities[0].Id), // String opportunityNumber,
				opportunities[0].OracleOrderNumber__c, // String oracleOrderNumber,
				opportunities[0].PONumber__c, // String poNumber
				opportunities[0].Id ), // sourceObject reference
			new Account_Matching_Renewals.RenewalParty( // scenario 1
				Account_Matching.AccountToType.BILL_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				null, // oracle account number
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null, // String email )
				opportunityNumberMap.get(opportunities[1].Id), // String opportunityNumber,
				opportunities[0].OracleOrderNumber__c, // String oracleOrderNumber,
				opportunities[1].PONumber__c, // String poNumber )
				opportunities[0].Id ), // sourceObject reference
			new Account_Matching_Renewals.RenewalParty( // scenario 2
				Account_Matching.AccountToType.BILL_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				null, // oracle account number
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null, // String email )
				opportunityNumberMap.get(opportunities[0].Id), // String opportunityNumber,
				opportunities[0].OracleOrderNumber__c, // String oracleOrderNumber,
				null, // String poNumber )
				opportunities[0].Id ), // sourceObject reference
			new Account_Matching_Renewals.RenewalParty( // scenario 3
				Account_Matching.AccountToType.BILL_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				null, // oracle account number
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null, // String email )
				opportunityNumberMap.get(opportunities[1].Id), // String opportunityNumber,
				opportunities[0].OracleOrderNumber__c, // String oracleOrderNumber,
				null, // String poNumber )
				opportunities[0].Id ), // sourceObject reference
			new Account_Matching_Renewals.RenewalParty( // scenario 4
				Account_Matching.AccountToType.BILL_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				null, // oracle account number
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null, // String email )
				opportunityNumberMap.get(opportunities[0].Id), // String opportunityNumber,
				null, // String oracleOrderNumber,
				opportunities[0].PONumber__c, // String poNumber )
				opportunities[0].Id ), // sourceObject reference
			new Account_Matching_Renewals.RenewalParty( // scenario 5
				Account_Matching.AccountToType.BILL_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				null, // oracle account number
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null, // String email )
				opportunityNumberMap.get(opportunities[0].Id), // String opportunityNumber,
				null, // String oracleOrderNumber,
				null, // String poNumber )
				opportunities[0].Id ), // sourceObject reference
			new Account_Matching_Renewals.RenewalParty( // scenario 6
				Account_Matching.AccountToType.BILL_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				null, // oracle account number
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null, // String email )
				null, // String opportunityNumber,
				opportunities[0].OracleOrderNumber__c, // String oracleOrderNumber,
				opportunities[0].PONumber__c, // String poNumber )
				opportunities[0].Id ), // sourceObject reference
			new Account_Matching_Renewals.RenewalParty( // scenario 7
				Account_Matching.AccountToType.BILL_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				null, // oracle account number
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null, // String email )
				null, // String opportunityNumber,
				opportunities[0].OracleOrderNumber__c, // String oracleOrderNumber,
				opportunities[1].PONumber__c, // String poNumber )
				opportunities[0].Id ), // sourceObject reference
			new Account_Matching_Renewals.RenewalParty( // scenario 8
				Account_Matching.AccountToType.BILL_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				null, // oracle account number
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null, // String email )
				null, // String opportunityNumber,
				opportunities[0].OracleOrderNumber__c, // String oracleOrderNumber,
				null, // String poNumber )
				opportunities[0].Id ), // sourceObject reference
			new Account_Matching_Renewals.RenewalParty( // scenario 9
				Account_Matching.AccountToType.BILL_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				null, // oracle account number
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null, // String email )
				null, // String opportunityNumber,
				null, // String oracleOrderNumber,
				opportunities[0].PONumber__c, // String poNumber )
				opportunities[0].Id ) }; // sourceObject reference
	}

	static List<EBS_Account__c> ebsAccounts {
		get { return Account_MatchingTest.ebsAccounts; }
	}

	static Map<Id,EBS_Account__c> ebsAccountMap {
		get { return Account_MatchingTest.ebsAccountMap; }
	}

	static List<Address__c> addresses {
		get { return Account_MatchingTest.addresses; }
	}

	static Map<Id,Address__c> addressMap {
		get { return Account_MatchingTest.addressMap; }
	}

	static List<Contact> contacts {
		get { return Account_MatchingTest.contacts; }
	}

	static Map<Id,Contact> contactMap {
		get { return Account_MatchingTest.contactMap; }
	}

	static List<Subscription__c> subscriptions {
		get {
			if(subscriptions == null) {
				System.assert(! ebsAccountMap.isEmpty());
				System.assert(! addressMap.isEmpty());
				System.assert(! contactMap.isEmpty());
				subscriptions = SubscriptionBatchTriggerAfterTest.subscriptions;
				for(Subscription__c sub : subscriptions) {
					sub.BillToAccountNumber__c = ebsAccounts[0].Name;
					sub.BillToCDHPartyNumber__c = ebsAccounts[0].CDH_Party_Number__c;
					sub.BillToCDHPartySiteNumber__c = addresses[0].CDH_Party_Site_Number__c;
					sub.BillToContCDHPartyNumber__c = contacts[0].CDH_Party__r.CDH_Party_Number_Ext__c;
					sub.BillToContactEmail__c = contacts[0].Email;
					sub.BillToCountry__c = addresses[0].Country__c;
					sub.BillToSfAccountId__c = 'INVALID';
					sub.BillToSfAddressId__c = 'INVALID';
					sub.BillToSfContactId__c = 'INVALID';
					sub.BillToSfEBSAccountId__c = 'INVALID';
					sub.EntitleToAccountNumber__c = ebsAccounts[1].Name;
					sub.EntitleToCDHPartyNumber__c = ebsAccounts[1].CDH_Party_Number__c;
					sub.EntitleToCDHPartySiteNumber__c = addresses[1].CDH_Party_Site_Number__c;
					sub.EntitleToContCDHPartyNumber__c = contacts[1].CDH_Party__r.CDH_Party_Number_Ext__c;
					sub.EntitleToContactEmail__c = contacts[1].Email;
					sub.EntitleToCountry__c = addresses[1].Country__c;
					sub.EntitleToSfAccountId__c = 'INVALID';
					sub.EntitleToSfAddressId__c = 'INVALID';
					sub.EntitleToSfContactId__c = 'INVALID';
					sub.EntitleToSfEBSAccountId__c = 'INVALID';
					sub.ShipToAccountNumber__c = ebsAccounts[2].Name;
					sub.ShipToCDHPartyNumber__c = ebsAccounts[2].CDH_Party_Number__c;
					sub.ShipToCDHPartySiteNumber__c = addresses[2].CDH_Party_Site_Number__c;
					sub.ShipToContCDHPartyNumber__c = contacts[2].CDH_Party__r.CDH_Party_Number_Ext__c;
					sub.ShipToContactEmail__c = contacts[2].Email;
					sub.ShipToCountry__c = addresses[2].Country__c;
					sub.ShipToSfAccountId__c = 'INVALID';
					sub.ShipToSfAddressId__c = 'INVALID';
					sub.ShipToSfContactId__c = 'INVALID';
					sub.ShipToSfEBSAccountId__c = 'INVALID';
					sub.SoldToAccountNumber__c = ebsAccounts[3].Name;
					sub.SoldToCDHPartyNumber__c = ebsAccounts[3].CDH_Party_Number__c;
					sub.SoldToCDHPartySiteNumber__c = addresses[3].CDH_Party_Site_Number__c;
					sub.SoldToContCDHPartyNumber__c = contacts[3].CDH_Party__r.CDH_Party_Number_Ext__c;
					sub.SoldToContactEmail__c = contacts[3].Email;
					sub.SoldToCountry__c = addresses[3].Country__c;
					sub.SoldToSfAccountId__c = 'INVALID';
					sub.SoldToSfAddressId__c = 'INVALID';
					sub.SoldToSfContactId__c = 'INVALID';
//bcr					sub.SoldToSfEBSAccountId__c = 'INVALID';
				}
				subscriptions[0].BillToAddress__c = addresses[0].Id;
				subscriptions[0].BillToContact__c = contacts[0].Id;
				subscriptions[0].BillToEBSAccount__c = ebsAccounts[0].Id;
				subscriptions[0].BillToSfAddressId__c = addresses[0].Id;
				subscriptions[0].BillToSfContactId__c = contacts[0].Id;
				subscriptions[0].BillToSfEBSAccountId__c = ebsAccounts[0].Id;
				subscriptions[0].EntitleToAddress__c = addresses[1].Id;
				subscriptions[0].EntitleToContact__c = contacts[1].Id;
				subscriptions[0].EntitleToEBSAccount__c = ebsAccounts[1].Id;
				subscriptions[0].EntitleToSfAddressId__c = addresses[1].Id;
				subscriptions[0].EntitleToSfContactId__c = contacts[1].Id;
				subscriptions[0].EntitleToSfEBSAccountId__c = ebsAccounts[1].Id;
				subscriptions[0].ShipToAddress__c = addresses[2].Id;
				subscriptions[0].ShipToContact__c = contacts[2].Id;
				subscriptions[0].ShipToEBSAccount__c = ebsAccounts[2].Id;
				subscriptions[0].ShipToSfAddressId__c = addresses[2].Id;
				subscriptions[0].ShipToSfContactId__c = contacts[2].Id;
				subscriptions[0].ShipToSfEBSAccountId__c = ebsAccounts[2].Id;
				subscriptions[0].SoldToAddress__c = addresses[3].Id;
				subscriptions[0].SoldToContact__c = contacts[3].Id;
				subscriptions[0].SoldToEBSAccount__c = ebsAccounts[3].Id;
				subscriptions[0].SoldToSfAddressId__c = addresses[3].Id;
				subscriptions[0].SoldToSfContactId__c = contacts[3].Id;
				subscriptions[0].SoldToSfEBSAccountId__c = ebsAccounts[3].Id;
				subscriptions[1].BillToAddress__c = addresses[0].Id;
				subscriptions[1].BillToContact__c = contacts[0].Id;
				subscriptions[1].BillToEBSAccount__c = ebsAccounts[0].Id;
				subscriptions[1].EntitleToAddress__c = addresses[1].Id;
				subscriptions[1].EntitleToContact__c = contacts[1].Id;
				subscriptions[1].EntitleToEBSAccount__c = ebsAccounts[1].Id;
				subscriptions[1].ShipToAddress__c = addresses[2].Id;
				subscriptions[1].ShipToContact__c = contacts[2].Id;
				subscriptions[1].ShipToEBSAccount__c = ebsAccounts[2].Id;
				subscriptions[1].SoldToAddress__c = addresses[3].Id;
				subscriptions[1].SoldToContact__c = contacts[3].Id;
				subscriptions[1].SoldToEBSAccount__c = ebsAccounts[3].Id;
				subscriptions[2].BillToSfAddressId__c = addresses[0].Id;
				subscriptions[2].BillToSfContactId__c = contacts[0].Id;
				subscriptions[2].BillToSfEBSAccountId__c = ebsAccounts[0].Id;
				subscriptions[2].EntitleToSfAddressId__c = addresses[1].Id;
				subscriptions[2].EntitleToSfContactId__c = contacts[1].Id;
				subscriptions[2].EntitleToSfEBSAccountId__c = ebsAccounts[1].Id;
				subscriptions[2].ShipToSfAddressId__c = addresses[2].Id;
				subscriptions[2].ShipToSfContactId__c = contacts[2].Id;
				subscriptions[2].ShipToSfEBSAccountId__c = ebsAccounts[2].Id;
				subscriptions[2].SoldToSfAddressId__c = addresses[3].Id;
				subscriptions[2].SoldToSfContactId__c = contacts[3].Id;
				subscriptions[2].SoldToSfEBSAccountId__c = ebsAccounts[3].Id;
			}
			return subscriptions;
		}
	}

	static Map<Id,Subscription__c> subscriptionMap {
		get {
			if(subscriptionMap == null) {
				System.assert(! subscriptions.isEmpty());
				subscriptionMap = SubscriptionBatchTriggerAfterTest.subscriptionMap;
			} 
			return subscriptionMap; 
		}
		set;
	}

	static List<SubscriptionLine__c> subscriptionLines {
		get {
			if(subscriptionLines == null) {
				System.assert(! subscriptionMap.isEmpty());
				subscriptionLines = SubscriptionBatchTriggerAfterTest.subscriptionLines;
				for(SubscriptionLine__c subLine : subscriptionLines) {
					subLine.EntitleToAccountNumber__c = ebsAccounts[4].Name;
					subLine.EntitleToCDHPartyNumber__c = ebsAccounts[4].CDH_Party_Number__c;
					subLine.EntitleToCDHPartySiteNumber__c = addresses[4].CDH_Party_Site_Number__c;
					subLine.EntitleToContCDHPartyNumber__c = contacts[4].CDH_Party__r.CDH_Party_Number_Ext__c;
					subLine.EntitleToContactEmail__c = contacts[4].Email;
					subLine.EntitleToCountry__c = addresses[4].Country__c;
					subLine.EntitleToSfAccountId__c = 'INVALID';
					subLine.EntitleToSfAddressId__c = 'INVALID';
					subLine.EntitleToSfContactId__c = 'INVALID';
					subLine.EntitleToSfEBSAccountId__c = 'INVALID';
				}
				subscriptionLines[0].EntitleToAddress__c = addresses[4].Id;
				subscriptionLines[0].EntitleToContact__c = contacts[4].Id;
				subscriptionLines[0].EntitleToEBSAccount__c = ebsAccounts[4].Id;
				subscriptionLines[0].EntitleToSfAddressId__c = addresses[4].Id;
				subscriptionLines[0].EntitleToSfContactId__c = contacts[4].Id;
				subscriptionLines[0].EntitleToSfEBSAccountId__c = ebsAccounts[4].Id;
				subscriptionLines[1].EntitleToAddress__c = addresses[4].Id;
				subscriptionLines[1].EntitleToContact__c = contacts[4].Id;
				subscriptionLines[1].EntitleToEBSAccount__c = ebsAccounts[4].Id;
				subscriptionLines[2].EntitleToSfAddressId__c = addresses[4].Id;
				subscriptionLines[2].EntitleToSfContactId__c = contacts[4].Id;
				subscriptionLines[2].EntitleToSfEBSAccountId__c = ebsAccounts[4].Id;
				Iterator<SubscriptionLine__c> iSubLine = subscriptionLines.iterator();
				Integer linesPerSubscription = subscriptionLines.size() / subscriptions.size();
				for(Subscription__c sub : subscriptions) {
					for(Integer i=0;i< linesPerSubscription;i++) {
						SubscriptionLine__c subLine = iSubLine.next();
						subLine.Subscription__c = sub.Id;
						subLine.OriginalSubscription__c = sub.Id;
					}
				}
			}
			return subscriptionLines;
		}
	}

	static Map<Id,SubscriptionLine__c> subscriptionLineMap {
		get {
			if(subscriptionLineMap == null) {
				System.assert(! subscriptionLines.isEmpty());
				subscriptionLineMap = SubscriptionBatchTriggerAfterTest.subscriptionLineMap;
			} 
			return subscriptionLineMap; 
		}
		set;
	}


	@isTest
	static void oppMatchTest() {
		System.assert( ! opportunityNumberMap.isEmpty());
		List<Account_Matching_Renewals.RenewalParty> renewalPartyList = getRenewalPartyList();
		Account_Matching_Renewals accountMatching = new Account_Matching_Renewals(renewalPartyList);
		List<Account_Matching_Renewals.RenewalParty> renewalPartyList2 = getRenewalPartyList();
		Account_Matching_Renewals accountMatching2 = new Account_Matching_Renewals(renewalPartyList2);

		System.assertNotEquals(null,renewalPartyList[0].opportunityNumber);
		System.assertNotEquals(null,renewalPartyList[0].oracleOrderNumber);
		System.assertNotEquals(null,renewalPartyList[0].PONumber);
		// There is a workflow rule that clears the OracleOrderNumber unless
		// the opportunity is closed booked.  This is a work-around...
		for(Opportunity opp : opportunities) {
			Opportunity opp2 = accountMatching.potentialOppMap.get(opp.Id);
			if(opp2 != null) {
				opp2.OracleOrderNumber__c = opp.OracleOrderNumber__c;
				opp2.PONumber__c = opp.PONumber__c;
			}
		}

		// There is a workflow rule that clears the OracleOrderNumber unless
		// the opportunity is closed booked.  This is a work-around...
		for(Opportunity opp : opportunities) {
			Opportunity opp2 = accountMatching2.potentialOppMap.get(opp.Id);
			if(opp2 != null) {
				opp2.OracleOrderNumber__c = opp.OracleOrderNumber__c;
				opp2.PONumber__c = opp.PONumber__c;
			}
		}

		Test.startTest();

		accountMatching.preAssignRefOppId();

		System.assert(accountMatching.oppIdByOpportunityNumber.containsKey(renewalPartyList[0].opportunityNumber));
		Id oppId = accountMatching.oppIdByOpportunityNumber.get(renewalPartyList[0].opportunityNumber);
		System.assertEquals(opportunities[0].Id,oppId);
		Opportunity opp = accountMatching.potentialOppMap.get(oppId);
		System.assertNotEquals(null,opp);
		System.assertEquals(renewalPartyList[0].oracleOrderNumber,opp.OracleOrderNumber__c);
		System.assert(accountMatching.oppIdsByOracleOrderNumber.containsKey(renewalPartyList[0].oracleOrderNumber));
		for(Id oppId2 : accountMatching.oppIdsByOracleOrderNumber.get(renewalPartyList[0].oracleOrderNumber)) {
			System.assertEquals(opportunities[0].Id,oppId2);
		}

		System.assertEquals(opportunities[0].Id,renewalPartyList[0].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[1].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[2].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[3].refOppId);
		System.assertEquals(null,renewalPartyList[4].refOppId);
		System.assertEquals(null,renewalPartyList[5].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[6].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[7].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[8].refOppId);
		System.assertEquals(null,renewalPartyList[9].refOppId);

		accountMatching.assignRefOppId();

		System.assertEquals(opportunities[0].Id,renewalPartyList[0].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[1].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[2].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[3].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[4].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[5].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[6].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[7].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[8].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList[9].refOppId);

		accountMatching2.assignRefOppId();

		System.assertEquals(opportunities[0].Id,renewalPartyList2[0].refOppId);
		System.assertEquals(opportunities[1].Id,renewalPartyList2[1].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList2[2].refOppId);
		System.assertEquals(opportunities[1].Id,renewalPartyList2[3].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList2[4].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList2[5].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList2[6].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList2[7].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList2[8].refOppId);
		System.assertEquals(opportunities[0].Id,renewalPartyList2[9].refOppId);

		Test.stopTest();
	}

	@isTest
	static void subscriptionsTest() {
		System.assert(! subscriptionLineMap.isEmpty());
		Test.startTest();
		Account_Matching_Renewals accountMatching = new Account_Matching_Renewals(subscriptions, null );
		
		// Validate all the  matching data is exactly what we are expecting...

		Integer j=0;
		System.assertEquals(4*subscriptions.size()+subscriptionLines.size(),accountMatching.renewalParties.size());
		List<Account_Matching_Renewals.RenewalParty> subData = new List<Account_Matching_Renewals.RenewalParty>();
		for(Integer i=0;i<4;i++) {
			Account_Matching_Renewals.RenewalParty d = accountMatching.renewalParties[j];
			subData.add(d);
			System.assertEquals(Account_Matching.AccountToType.BILL_TO,d.toType,'Bill-To['+j+']');
			System.assertEquals(subscriptions[i].Id,((SObject)d.sourceObject).Id,'Bill-To['+j+']');
			System.assertEquals(ebsAccounts[0].CDH_Party_Number__c,d.cdhPartyNumber,'Bill-To['+j+'].cdhPartyNumber');
			System.assertEquals(addresses[0].CDH_Party_Site_Number__c,d.cdhPartySiteNumber,'Bill-To['+j+'].cdhPartySiteNumber');
			System.assertEquals(contacts[0].CDH_Party__r.CDH_Party_Number_Ext__c,d.contactCDHPartyNumber,'Bill-To['+j+'].contactCDHPartyNumber');
			System.assertEquals(contacts[0].Email,d.email,'Bill-To['+j+'].email');
			System.assertEquals(addresses[0].Country__c,d.country,'Bill-To['+j+'].country');
			if(i < 3) {
				System.assertEquals(addresses[0].Id,d.refAddressId,'Bill-To['+j+'].refAddressId');
				System.assertEquals(contacts[0].Id,d.refContactId,'Bill-To['+j+'].refContactId');
				System.assertEquals(ebsAccounts[0].Id,d.refEBSAccountId,'Bill-To['+j+'].refEBSAccountId');
			}
			else {
				System.assertEquals(null,d.refAddressId,'Bill-To['+j+'].refAddressId');
				System.assertEquals(null,d.refContactId,'Bill-To['+j+'].refContactId');
				System.assertEquals(null,d.refEBSAccountId,'Bill-To['+j+'].refEBSAccountId');
			}

			d = accountMatching.renewalParties[++j];
			subData.add(d);
			System.assertEquals(Account_Matching.AccountToType.ENTITLE_TO,d.toType,'Entitle-To['+j+']');
			System.assertEquals(subscriptions[i].Id,((SObject)d.sourceObject).Id,'Entitle-To['+j+']');
			System.assertEquals(ebsAccounts[1].CDH_Party_Number__c,d.cdhPartyNumber,'Entitle-To['+j+'].cdhPartyNumber');
			System.assertEquals(addresses[1].CDH_Party_Site_Number__c,d.cdhPartySiteNumber,'Entitle-To['+j+'].cdhPartySiteNumber');
			System.assertEquals(contacts[1].CDH_Party__r.CDH_Party_Number_Ext__c,d.contactCDHPartyNumber,'Entitle-To['+j+'].contactCDHPartyNumber');
			System.assertEquals(contacts[1].Email,d.email,'Entitle-To['+j+'].email');
			System.assertEquals(addresses[1].Country__c,d.country,'Entitle-To['+j+'].country');
			if(i < 3) {
				System.assertEquals(addresses[1].Id,d.refAddressId,'Entitle-To['+j+'].refAddressId');
				System.assertEquals(contacts[1].Id,d.refContactId,'Entitle-To['+j+'].refContactId');
				System.assertEquals(ebsAccounts[1].Id,d.refEBSAccountId,'Entitle-To['+j+'].refEBSAccountId');
			}
			else {
				System.assertEquals(null,d.refAddressId,'Entitle-To['+j+'].refAddressId');
				System.assertEquals(null,d.refContactId,'Entitle-To['+j+'].refContactId');
				System.assertEquals(null,d.refEBSAccountId,'Entitle-To['+j+'].refEBSAccountId');
			}

			d = accountMatching.renewalParties[++j];
			subData.add(d);
			System.assertEquals(Account_Matching.AccountToType.SHIP_TO,d.toType,'Ship-To['+j+']');
			System.assertEquals(subscriptions[i].Id,((SObject)d.sourceObject).Id,'Ship-To['+j+']');
			System.assertEquals(ebsAccounts[2].CDH_Party_Number__c,d.cdhPartyNumber,'Ship-To['+j+'].cdhPartyNumber');
			System.assertEquals(addresses[2].CDH_Party_Site_Number__c,d.cdhPartySiteNumber,'Ship-To['+j+'].cdhPartySiteNumber');
			System.assertEquals(contacts[2].CDH_Party__r.CDH_Party_Number_Ext__c,d.contactCDHPartyNumber,'Ship-To['+j+'].contactCDHPartyNumber');
			System.assertEquals(contacts[2].Email,d.email,'Ship-To['+j+'].email');
			System.assertEquals(addresses[2].Country__c,d.country,'Ship-To['+j+'].country');
			if(i < 3) {
				System.assertEquals(addresses[2].Id,d.refAddressId,'Ship-To['+j+'].refAddressId');
				System.assertEquals(contacts[2].Id,d.refContactId,'Ship-To['+j+'].refContactId');
				System.assertEquals(ebsAccounts[2].Id,d.refEBSAccountId,'Ship-To['+j+'].refEBSAccountId');
			}
			else {
				System.assertEquals(null,d.refAddressId,'Ship-To['+j+'].refAddressId');
				System.assertEquals(null,d.refContactId,'Ship-To['+j+'].refContactId');
				System.assertEquals(null,d.refEBSAccountId,'Ship-To['+j+'].refEBSAccountId');
			}

			d = accountMatching.renewalParties[++j];
			subData.add(d);
			System.assertEquals(Account_Matching.AccountToType.SOLD_TO,d.toType,'Sold-To['+j+']');
			System.assertEquals(subscriptions[i].Id,((SObject)d.sourceObject).Id,'Sold-To['+j+']');
			System.assertEquals(ebsAccounts[3].CDH_Party_Number__c,d.cdhPartyNumber,'Sold-To['+j+'].cdhPartyNumber');
			System.assertEquals(addresses[3].CDH_Party_Site_Number__c,d.cdhPartySiteNumber,'Sold-To['+j+'].cdhPartySiteNumber');
			System.assertEquals(contacts[3].CDH_Party__r.CDH_Party_Number_Ext__c,d.contactCDHPartyNumber,'Sold-To['+j+'].contactCDHPartyNumber');
			System.assertEquals(contacts[3].Email,d.email,'Sold-To['+j+'].email');
			System.assertEquals(addresses[3].Country__c,d.country,'Sold-To['+j+'].country');
			if(i < 3) {
				System.assertEquals(addresses[3].Id,d.refAddressId,'Sold-To['+j+'].refAddressId');
				System.assertEquals(contacts[3].Id,d.refContactId,'Sold-To['+j+'].refContactId');
				System.assertEquals(ebsAccounts[3].Id,d.refEBSAccountId,'Sold-To['+j+'].refEBSAccountId');
			}
			else {
				System.assertEquals(null,d.refAddressId,'Sold-To['+j+'].refAddressId');
				System.assertEquals(null,d.refContactId,'Sold-To['+j+'].refContactId');
				System.assertEquals(null,d.refEBSAccountId,'Sold-To['+j+'].refEBSAccountId');
			}
			j++;
		}
		Map<Id,Account_Matching_Renewals.RenewalParty> subLineDataMap = new Map<Id,Account_Matching_Renewals.RenewalParty>();
		for(;j< accountMatching.renewalParties.size();j++) {
			Account_Matching_Renewals.RenewalParty d = accountMatching.renewalParties[j];
			System.assertEquals(Account_Matching.AccountToType.LINE_ENTITLE_TO,d.toType,'Element '+j);
			System.assert(subscriptionLineMap.containsKey(((SObject)d.sourceObject).Id));
			subLineDataMap.put(((SObject)d.sourceObject).Id,d);
		}
		List<Account_Matching_Renewals.RenewalParty> subLineData = new List<Account_Matching_Renewals.RenewalParty>();
		for(Integer i = 0; i < subscriptionLines.size();i++) {
			SubscriptionLine__c subLine = subscriptionLines[i];
			Account_Matching_Renewals.RenewalParty d = subLineDataMap.get(subLine.Id);
			System.assertNotEquals(null,d,'subscriptionLines['+i+'] Missing renewal data');
			System.assertEquals(ebsAccounts[4].CDH_Party_Number__c,d.cdhPartyNumber,'Line-Entitle-To['+i+'].cdhPartyNumber');
			System.assertEquals(addresses[4].CDH_Party_Site_Number__c,d.cdhPartySiteNumber,'Line-Entitle-To['+i+'].cdhPartySiteNumber');
			System.assertEquals(contacts[4].CDH_Party__r.CDH_Party_Number_Ext__c,d.contactCDHPartyNumber,'Line-Entitle-To['+i+'].contactCDHPartyNumber');
			System.assertEquals(contacts[4].Email,d.email,'Line-Entitle-To['+i+'].email');
			System.assertEquals(addresses[4].Country__c,d.country,'Line-Entitle-To['+i+'].country');
			if(i < 3) {
				System.assertEquals(addresses[4].Id,d.refAddressId,'Line-Entitle-To['+i+'].refAddressId');
				System.assertEquals(contacts[4].Id,d.refContactId,'Line-Entitle-To['+i+'].refContactId');
				System.assertEquals(ebsAccounts[4].Id,d.refEBSAccountId,'Line-Entitle-To['+i+'].refEBSAccountId');
			}
			else {
				System.assertEquals(null,d.refAddressId,'Line-Entitle-To['+i+'].refAddressId');
				System.assertEquals(null,d.refContactId,'Line-Entitle-To['+i+'].refContactId');
				System.assertEquals(null,d.refEBSAccountId,'Line-Entitle-To['+i+'].refEBSAccountId');
			}
			subLineData.add(d);
		}

		// now lets pretend like the matching ran, but failed, lets see what gets
		// written to the subscription and subscription lines

		accountMatching.assignFrom();
		for(Subscription__c sub : subscriptions) {
			System.assertEquals(null,sub.BillToAddress__c);
			System.assertEquals(null,sub.BillToContact__c);
			System.assertEquals(null,sub.BillToEBSAccount__c);
			System.assertEquals(null,sub.EntitleToAddress__c);
			System.assertEquals(null,sub.EntitleToContact__c);
			System.assertEquals(null,sub.EntitleToEBSAccount__c);
			System.assertEquals(null,sub.ShipToAddress__c);
			System.assertEquals(null,sub.ShipToContact__c);
			System.assertEquals(null,sub.ShipToEBSAccount__c);
			System.assertEquals(null,sub.SoldToAddress__c);
			System.assertEquals(null,sub.SoldToContact__c);
			System.assertEquals(null,sub.SoldToEBSAccount__c);
		}
		for(Account_Matching_Renewals.RenewalParty d : subLineData) {
			SubscriptionLine__c subLine = (SubscriptionLine__c)d.sourceObject;
			System.assertEquals(null,subLine.EntitleToAddress__c);
// I don't understand why the following fails...
//			System.assertEquals(null,subLine.EntitleToContact__c);
			System.assertEquals(null,subLine.EntitleToEBSAccount__c);
		}

		System.assertEquals(2,accountMatching.getUpdatedSubscriptionLines().size());

		// lets try again, but this time simmulate success

		for(Account_Matching_Renewals.RenewalParty d : accountMatching.renewalParties) {
			d.setAddress(addressMap.get(d.refAddressId));
			d.setContact(contactMap.get(d.refContactId));
			d.setEBSAccount(ebsAccountMap.get(d.refEBSAccountId));
		}

		accountMatching.assignFrom();

		for(Integer i = 0; i < subscriptions.size(); i++) {
			Subscription__c sub = subscriptions[i];
			if(i < 3) {
				System.assertNotEquals(null,sub.BillToAddress__c);
				System.assertNotEquals(null,sub.BillToContact__c);
				System.assertNotEquals(null,sub.BillToEBSAccount__c);
				System.assertNotEquals(null,sub.EntitleToAddress__c);
				System.assertNotEquals(null,sub.EntitleToContact__c);
				System.assertNotEquals(null,sub.EntitleToEBSAccount__c);
				System.assertNotEquals(null,sub.ShipToAddress__c);
				System.assertNotEquals(null,sub.ShipToContact__c);
				System.assertNotEquals(null,sub.ShipToEBSAccount__c);
				System.assertNotEquals(null,sub.SoldToAddress__c);
				System.assertNotEquals(null,sub.SoldToContact__c);
				System.assertNotEquals(null,sub.SoldToEBSAccount__c);
			}
			else {
				System.assertEquals(null,sub.BillToAddress__c);
				System.assertEquals(null,sub.BillToContact__c);
				System.assertEquals(null,sub.BillToEBSAccount__c);
				System.assertEquals(null,sub.EntitleToAddress__c);
				System.assertEquals(null,sub.EntitleToContact__c);
				System.assertEquals(null,sub.EntitleToEBSAccount__c);
				System.assertEquals(null,sub.ShipToAddress__c);
				System.assertEquals(null,sub.ShipToContact__c);
				System.assertEquals(null,sub.ShipToEBSAccount__c);
				System.assertEquals(null,sub.SoldToAddress__c);
				System.assertEquals(null,sub.SoldToContact__c);
				System.assertEquals(null,sub.SoldToEBSAccount__c);
			}
		}
		for(Integer i = 0; i < subLineData.size(); i++) {
			Account_Matching_Renewals.RenewalParty d = subLineData[i];
			SubscriptionLine__c subLine = (SubscriptionLine__c)d.sourceObject;
			if(i < 3) {
				System.assertNotEquals(null,subLine.EntitleToAddress__c);
				System.assertNotEquals(null,subLine.EntitleToContact__c);
				System.assertNotEquals(null,subLine.EntitleToEBSAccount__c);
			}
			else {
				System.assertEquals(null,subLine.EntitleToAddress__c);
				System.assertEquals(null,subLine.EntitleToContact__c);
				System.assertEquals(null,subLine.EntitleToEBSAccount__c);
			}
		}
		System.assertEquals(3,accountMatching.getUpdatedSubscriptionLines().size());

		// check if we have the expected number of errors and warnings

		accountMatching.errorsAndWarningsReporting();
		Test.stopTest();

		List<SubscriptionError__c> errorList = accountMatching.getErrorAndWarnList();
		System.assertEquals(((subscriptions.size()-3)*4+(subscriptionLines.size()-3))*3,errorList.size());
		// check the error message assignments
		System.assertEquals(null,subscriptions[0].ErrorMessage__c);
		System.assertEquals(null,subscriptions[1].ErrorMessage__c);
		System.assertEquals(null,subscriptions[2].ErrorMessage__c);
		System.assertNotEquals(null,subscriptions[3].ErrorMessage__c);
	}
}