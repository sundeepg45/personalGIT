/**
 * Test class for Opportunity_RenewalAccountMatching.cls
 *
 * @version 2015-04-23
 * @author  Bill C Riemers <briemers@redhat.com>
 * 2015-04-23 - Corrected to expect non-partner bill-to result
 * 2015-01-27 - make the message public
 * 2014-12-09 - created to replace old class of the same name with new tests
 * 
 */
 
@isTest
public class Opportunity_RenewalAccountMatchingTest 
{

	static Opportunity opportunity {
		get {
			if(opportunity == null) {
				opportunity = Account_MatchingTest.opportunities[0];
				opportunity.Bill_To_Sales_Account__r = Account_MatchingTest.ebsAccounts[0].Sales_Account__r;
				opportunity.Bill_To_Account__r = Account_MatchingTest.ebsAccounts[0];
				opportunity.Entitle_To_Sales_Account__r = Account_MatchingTest.ebsAccounts[1].Sales_Account__r;
				opportunity.Entitle_To_Account__r = Account_MatchingTest.ebsAccounts[1];
				opportunity.Ship_To_Sales_Account__r = Account_MatchingTest.ebsAccounts[2].Sales_Account__r;
				opportunity.Ship_To_Account__r = Account_MatchingTest.ebsAccounts[2];
				opportunity.Sold_To_Sales_Account__r = Account_MatchingTest.ebsAccounts[3].Sales_Account__r;
				opportunity.Sold_To_Account__r = Account_MatchingTest.ebsAccounts[3];
				System.assert(! Account_MatchingTest.addressMap.isEmpty());
				opportunity.Bill_To_Address__r = Account_MatchingTest.addresses[0];
				opportunity.Entitle_To_Address__r = Account_MatchingTest.addresses[1];
				opportunity.Ship_To_Address__r = Account_MatchingTest.addresses[2];
				opportunity.Sold_To_Address__r = Account_MatchingTest.addresses[3];
				System.assert(! Account_MatchingTest.contactMap.isEmpty());
				opportunity.Bill_To_Contact__r = Account_MatchingTest.contacts[0];
				opportunity.Entitle_To_Contact__r = Account_MatchingTest.contacts[1];
				opportunity.Ship_To_Contact__r = Account_MatchingTest.contacts[2];
				opportunity.Sold_To_Contact__r = Account_MatchingTest.contacts[3];
			}
			return opportunity;
		}
		set;
	}

	static Id getOpportunityId() {
		if(opportunity.Id == null) {
			System.assert(! Account_MatchingTest.opportunityMap.isEmpty());
		}
		return opportunity.Id;
	}

	static Opportunity queriedOpportunity {
		get {
			if(queriedOpportunity == null) {
				queriedOpportunity = [
					select 
						OpportunityNumber__c,
						AccountId,
						Account.AccountNumber,
						Account.Name,
						Account.OwnerId,
						Account.Owner.IsActive,
						Account.Owner.Name,
						Account.Owner.UserRole.Name
					from Opportunity
					where Id = :getOpportunityId() ];
			}
			return queriedOpportunity;
		}
		set;
	}

	static OpportunityLineItem opportunityLineItem {
		get {
			if(opportunityLineItem == null && opportunity != null) {
				System.assertNotEquals(null,getOpportunityId());
				opportunityLineItem = Account_MatchingTest.opportunityLineItems[0];
				opportunityLineItem.Entitle_To_Sales_Account__r = Account_MatchingTest.ebsAccounts[4].Sales_Account__r;
				opportunityLineItem.Entitle_To_Account__r = Account_MatchingTest.ebsAccounts[4];
				opportunityLineItem.Entitle_To_Address__r = Account_MatchingTest.addresses[4];
				opportunityLineItem.Entitle_To_Contact__r = Account_MatchingTest.contacts[4];
				System.assert(! Account_MatchingTest.opportunityLineItemMap.isEmpty());
			}
			return opportunityLineItem;
		}
		set;
	}

	public static String xmlDocument {
		get {
			if(xmlDocument == null) {
				System.assert(! Account_MatchingTest.ebsAccountMap.isEmpty());
				System.assert(! Account_MatchingTest.addressMap.isEmpty());
				System.assert(! Account_MatchingTest.contactMap.isEmpty());
				xmlDocument = '<?xml version="1.0" encoding="UTF-8"?>'
					+ '<SalesforceMessage xmlns="'+Opportunity_RenewalAccountMatching.SALESFORCE_MSG_NAMESPACE+'"\n'
					+ '		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n'
					+ '		xsi:schemaLocation="'+Opportunity_RenewalAccountMatching.SALESFORCE_MSG_NAMESPACE+' Renewals.xsd ">\n'
					+ '<Header>\n'
					+ '<Operation>QUERY</Operation>\n'
					+ '<Type>RENEWAL_ACCOUNT</Type>\n'
					+ '<InstanceId>1001463</InstanceId>\n'
					+ '<Timestamp>2014-12-09 02:17:31</Timestamp>\n'
					+ '</Header>\n'
					+ '<Payload>\n'
					+ '<AccountQuery>\n'
					+ '<Id>845128</Id>\n'
					+ '<AccountNumber>'+queriedOpportunity.Account.AccountNumber+'</AccountNumber>\n'
					+ '<PartyNumber>3126018</PartyNumber>\n'
					+ '<OrderNumber>'+opportunity.OracleOrderNumber__c+'</OrderNumber>\n'
					+ '<ContractNumber>10217392</ContractNumber>\n'
					+ '<SalesChannelCode>DISTRIBUTOR</SalesChannelCode>\n'
					+ '<OpportunityNumber>'+queriedOpportunity.OpportunityNumber__c+'</OpportunityNumber>\n'
					+ '<Region>APAC</Region>\n'
					+ '<NamedAccount>false</NamedAccount>\n'
					+ '<SalesRepOnAccount />\n'
					+ '<SalesRepRoleOnAccount />\n'
					+ '<SalesforceAccountId />\n'
					+ '<SalesforceAccountOwnerId />\n'
					+ '<SourceOpportunityId>'+getOpportunityId()+'</SourceOpportunityId>\n'
					+ '<BillToParty>\n'
					+ '<Id />\n'
					+ '<OracleAccountNumber>'+opportunity.Bill_To_Account__r.Name+'</OracleAccountNumber>\n'
					+ '<CDHPartyNumber>'+opportunity.Bill_To_Account__r.CDH_Party_Number__c+'</CDHPartyNumber>\n'
					+ '<CDHPartySiteNumber>'+opportunity.Bill_To_Address__r.CDH_Party_Site_Number__c+'</CDHPartySiteNumber>\n'
					+ '<ContactCDHPartyNumber/>\n'
					+ '<Email />\n'
					+ '<Address1>'+opportunity.Bill_To_Address__r.Address_Line1__c+'</Address1>\n'
					+ '<Address2>'+opportunity.Bill_To_Address__r.Address_Line2__c+'</Address2>\n'
					+ '<City>'+opportunity.Bill_To_Address__r.City__c+'</City>\n'
					+ '<State>'+opportunity.Bill_To_Address__r.State__c+'</State>\n'
					+ '<PostalCode>'+opportunity.Bill_To_Address__r.Zip_Postal_Code__c+'</PostalCode>\n'
					+ '<Country>'+opportunity.Bill_To_Address__r.Country__c+'</Country>\n'
					+ '</BillToParty>\n'
					+ '<EntitleToParty>\n'
					+ '<Id />\n'
					+ '<OracleAccountNumber>'+opportunity.Entitle_To_Account__r.Name+'</OracleAccountNumber>\n'
					+ '<CDHPartyNumber>'+opportunity.Entitle_To_Account__r.CDH_Party_Number__c+'</CDHPartyNumber>\n'
					+ '<CDHPartySiteNumber>'+opportunity.Entitle_To_Address__r.CDH_Party_Site_Number__c+'</CDHPartySiteNumber>\n'
					+ '<ContactCDHPartyNumber>'+opportunity.Entitle_To_Contact__r.CDH_Party__r.CDH_Party_Number_Ext__c+'</ContactCDHPartyNumber>\n'
					+ '<Email />\n'
					+ '</EntitleToParty>\n'
					+ '<ShipToParty>\n'
					+ '<Id />\n'
					+ '<OracleAccountNumber>'+opportunity.Ship_To_Account__r.Name+'</OracleAccountNumber>\n'
					+ '<CDHPartyNumber>'+opportunity.Ship_To_Account__r.CDH_Party_Number__c+'</CDHPartyNumber>\n'
					+ '<CDHPartySiteNumber>'+opportunity.Ship_To_Address__r.CDH_Party_Site_Number__c+'</CDHPartySiteNumber>\n'
					+ '<ContactCDHPartyNumber />\n'
					+ '<Email />\n'
					+ '<Address1>'+opportunity.Ship_To_Address__r.Address_Line1__c+'</Address1>\n'
					+ '<Address2>'+opportunity.Ship_To_Address__r.Address_Line2__c+'</Address2>\n'
					+ '<City>'+opportunity.Ship_To_Address__r.City__c+'</City>\n'
					+ '<State>'+opportunity.Ship_To_Address__r.State__c+'</State>\n'
					+ '<PostalCode>'+opportunity.Ship_To_Address__r.Zip_Postal_Code__c+'</PostalCode>\n'
					+ '<Country>'+opportunity.Ship_To_Address__r.Country__c+'</Country>\n'
					+ '</ShipToParty>\n'
					+ '<SoldToParty>\n'
					+ '<Id />\n'
					+ '<OracleAccountNumber>'+opportunity.Sold_To_Account__r.Name+'</OracleAccountNumber>\n'
					+ '<CDHPartyNumber>'+opportunity.Sold_To_Account__r.CDH_Party_Number__c+'</CDHPartyNumber>\n'
					+ '<CDHPartySiteNumber>'+opportunity.Sold_To_Address__r.CDH_Party_Site_Number__c+'</CDHPartySiteNumber>\n'
					+ '<ContactCDHPartyNumber>'+opportunity.Sold_To_Contact__r.CDH_Party__r.CDH_Party_Number_Ext__c+'</ContactCDHPartyNumber>\n'
					+ '<Email>'+opportunity.Sold_To_Contact__r.Email+'</Email>\n'
					+ '<Address1>'+opportunity.Sold_To_Address__r.Address_Line1__c+'</Address1>\n'
					+ '<Address2>'+opportunity.Sold_To_Address__r.Address_Line2__c+'</Address2>\n'
					+ '<City>'+opportunity.Sold_To_Address__r.City__c+'</City>\n'
					+ '<State>'+opportunity.Sold_To_Address__r.State__c+'</State>\n'
					+ '<PostalCode>'+opportunity.Sold_To_Address__r.Zip_Postal_Code__c+'</PostalCode>\n'
					+ '<Country>'+opportunity.Sold_To_Address__r.Country__c+'</Country>\n'
					+ '</SoldToParty>\n'
					+ '<LineEntitleToParty>\n'
					+ '<Id>1355299</Id>\n'
					+ '<SourceOpportunityLineId />\n'
					+ '<OracleAccountNumber>'+opportunityLineItem.Entitle_To_Account__r.Name+'</OracleAccountNumber>\n'
					+ '<CDHPartyNumber>'+opportunityLineItem.Entitle_To_Account__r.CDH_Party_Number__c+'</CDHPartyNumber>\n'
					+ '<CDHPartySiteNumber>'+opportunityLineItem.Entitle_To_Address__r.CDH_Party_Site_Number__c+'</CDHPartySiteNumber>\n'
					+ '<ContactCDHPartyNumber>'+opportunityLineItem.Entitle_To_Contact__r.CDH_Party__r.CDH_Party_Number_Ext__c+'</ContactCDHPartyNumber>\n'
					+ '<Email>'+opportunityLineItem.Entitle_To_Contact__r.Email+'</Email>\n'
					+ '<Address1>'+opportunity.Entitle_To_Address__r.Address_Line1__c+'</Address1>\n'
					+ '<Address2>'+opportunity.Entitle_To_Address__r.Address_Line2__c+'</Address2>\n'
					+ '<City>'+opportunity.Entitle_To_Address__r.City__c+'</City>\n'
					+ '<State>'+opportunity.Entitle_To_Address__r.State__c+'</State>\n'
					+ '<PostalCode>'+opportunity.Entitle_To_Address__r.Zip_Postal_Code__c+'</PostalCode>\n'
					+ '<Country>'+opportunityLineItem.Entitle_To_Address__r.Country__c+'</Country>\n'
					+ '</LineEntitleToParty>\n'
					+ '</AccountQuery>\n'
					+ '</Payload>\n'
					+ '</SalesforceMessage>\n';
			}
			return xmlDocument;
		}
		set;
	}

	static String expectedXml {
		get {
			if(expectedXml == null) {
				expectedXml = '<?xml version="1.0" encoding="UTF-8"?>'
				+ '<SalesforceMessage xmlns="">'
				+ '<Header>'
				+ '<Operation>QUERY</Operation>'
				+ '<Type>RENEWAL_ACCOUNT</Type>'
				+ '<InstanceId>1001463</InstanceId>'
				+ '<Timestamp>2014-12-09 02:17:31</Timestamp>'
				+ '<ResponseTimeStamp/>'
				+ '</Header>'
				+ '<Payload>'
				+ '<AccountQuery>'
				+ '<Id>845128</Id>'
				+ '<AccountNumber>'+queriedOpportunity.Account.AccountNumber+'</AccountNumber>'
				+ '<ContractNumber>10217392</ContractNumber>'
				+ '<OpportunityNumber>'+queriedOpportunity.OpportunityNumber__c+'</OpportunityNumber>'
				+ '<OrderNumber>'+opportunity.OracleOrderNumber__c+'</OrderNumber>'
				+ '<PartyNumber>3126018</PartyNumber>'
				+ '<PONumber></PONumber>'
				+ '<SourceOpportunityId>'+getOpportunityId()+'</SourceOpportunityId>'
				+ '<SalesChannelCode>DISTRIBUTOR</SalesChannelCode>'
				+ '<SalesforceAccountId>'+queriedOpportunity.AccountId+'</SalesforceAccountId>'
				+ '<SalesforceAccountName>'+queriedOpportunity.Account.Name+'</SalesforceAccountName>'
				+ '<SalesforceAccountOwnerId>'+queriedOpportunity.Account.OwnerId+'</SalesforceAccountOwnerId>'
				+ '<SalesRepOnAccount>'+queriedOpportunity.Account.Owner.Name+'</SalesRepOnAccount>'
				+ '<SalesRepOnAccountActive>true</SalesRepOnAccountActive>'
				+ '<SalesRepRoleOnAccount>'+queriedOpportunity.Account.Owner.UserRole.Name+'</SalesRepRoleOnAccount>'
				+ '<NamedAccount>false</NamedAccount>'
				+ '<Region>APAC</Region>'
				+ '<Status>SUCCESS</Status>'
				+ '<ErrorMessage></ErrorMessage>'
				+ '<BillToParty>'
				+ '<Id></Id>'
				+ '<SalesforceSalesAccountId>'+opportunity.Bill_To_Account__r.Sales_Account__c+'</SalesforceSalesAccountId>'
				+ '<SalesforceEBSAccountId>'+opportunity.Bill_To_Account__c+'</SalesforceEBSAccountId>'
				+ '<SalesforceAddressId>'+opportunity.Bill_To_Address__c+'</SalesforceAddressId>'
				+ '<SalesforceContactId>'+opportunity.Bill_To_Contact__c+'</SalesforceContactId>'
				+ '<SourceOpportunityLineId>'
				+ '</SourceOpportunityLineId>'
				+ '<OracleAccountNumber>'+opportunity.Bill_To_Account__r.Name+'</OracleAccountNumber>'
				+ '<CDHPartyNumber>'+opportunity.Bill_To_Account__r.CDH_Party_Number__c+'</CDHPartyNumber>'
				+ '<CDHPartySiteNumber>'+opportunity.Bill_To_Address__r.CDH_Party_Site_Number__c+'</CDHPartySiteNumber>'
				+ '<ContactCDHPartyNumber></ContactCDHPartyNumber>'
				+ '<Address1>'+opportunity.Bill_To_Address__r.Address_Line1__c+'</Address1>'
				+ '<Address2>'+opportunity.Bill_To_Address__r.Address_Line2__c+'</Address2>'
				+ '<City>'+opportunity.Bill_To_Address__r.City__c+'</City>'
				+ '<State>'+opportunity.Bill_To_Address__r.State__c+'</State>'
				+ '<PostalCode>'+opportunity.Bill_To_Address__r.Zip_Postal_Code__c+'</PostalCode>'
				+ '<Country>'+opportunity.Bill_To_Address__r.Country__c+'</Country>'
				+ '<Email></Email>'
				+ '<Status>SUCCESS</Status>'
				+ '<Message></Message>'
				+ '</BillToParty>'
				+ '<EntitleToParty>'
				+ '<Id></Id>'
				+ '<SalesforceSalesAccountId>'+opportunity.Entitle_To_Account__r.Sales_Account__c+'</SalesforceSalesAccountId>'
				+ '<SalesforceEBSAccountId>'+opportunity.Entitle_To_Account__c+'</SalesforceEBSAccountId>'
				+ '<SalesforceAddressId>'+opportunity.Entitle_To_Address__c+'</SalesforceAddressId>'
				+ '<SalesforceContactId>'+opportunity.Entitle_To_Contact__c+'</SalesforceContactId>'
				+ '<SourceOpportunityLineId></SourceOpportunityLineId>'
				+ '<OracleAccountNumber>'+opportunity.Entitle_To_Account__r.Name+'</OracleAccountNumber>'
				+ '<CDHPartyNumber>'+opportunity.Entitle_To_Account__r.CDH_Party_Number__c+'</CDHPartyNumber>'
				+ '<CDHPartySiteNumber>'+opportunity.Entitle_To_Address__r.CDH_Party_Site_Number__c+'</CDHPartySiteNumber>'
				+ '<ContactCDHPartyNumber>'+opportunity.Entitle_To_Contact__r.CDH_Party__r.CDH_Party_Number_Ext__c+'</ContactCDHPartyNumber>'
				+ '<Address1></Address1>'
				+ '<Address2></Address2>'
				+ '<City></City>'
				+ '<State></State>'
				+ '<PostalCode></PostalCode>'
				+ '<Country></Country>'
				+ '<Email></Email>'
				+ '<Status>SUCCESS</Status>'
				+ '<Message></Message>'
				+ '</EntitleToParty>'
				+ '<ShipToParty>'
				+ '<Id></Id>'
				+ '<SalesforceSalesAccountId>'+opportunity.Ship_To_Account__r.Sales_Account__c+'</SalesforceSalesAccountId>'
				+ '<SalesforceEBSAccountId>'+opportunity.Ship_To_Account__c+'</SalesforceEBSAccountId>'
				+ '<SalesforceAddressId>'+opportunity.Ship_To_Address__c+'</SalesforceAddressId>'
				+ '<SalesforceContactId>'+opportunity.Ship_To_Contact__c+'</SalesforceContactId>'
				+ '<SourceOpportunityLineId></SourceOpportunityLineId>'
				+ '<OracleAccountNumber>'+opportunity.Ship_To_Account__r.Name+'</OracleAccountNumber>'
				+ '<CDHPartyNumber>'+opportunity.Ship_To_Account__r.CDH_Party_Number__c+'</CDHPartyNumber>'
				+ '<CDHPartySiteNumber>'+opportunity.Ship_To_Address__r.CDH_Party_Site_Number__c+'</CDHPartySiteNumber>'
				+ '<ContactCDHPartyNumber></ContactCDHPartyNumber>'
				+ '<Address1>'+opportunity.Ship_To_Address__r.Address_Line1__c+'</Address1>'
				+ '<Address2>'+opportunity.Ship_To_Address__r.Address_Line2__c+'</Address2>'
				+ '<City>'+opportunity.Ship_To_Address__r.City__c+'</City>'
				+ '<State>'+opportunity.Ship_To_Address__r.State__c+'</State>'
				+ '<PostalCode>'+opportunity.Ship_To_Address__r.Zip_Postal_Code__c+'</PostalCode>'
				+ '<Country>'+opportunity.Ship_To_Address__r.Country__c+'</Country>'
				+ '<Email></Email>'
				+ '<Status>SUCCESS</Status>'
				+ '<Message></Message>'
				+ '</ShipToParty>'
				+ '<SoldToParty>'
				+ '<Id></Id>'
				+ '<SalesforceSalesAccountId>'+opportunity.Sold_To_Account__r.Sales_Account__c+'</SalesforceSalesAccountId>'
				+ '<SalesforceEBSAccountId>'+opportunity.Sold_To_Account__c+'</SalesforceEBSAccountId>'
				+ '<SalesforceAddressId>'+opportunity.Sold_To_Address__c+'</SalesforceAddressId>'
				+ '<SalesforceContactId>'+opportunity.Sold_To_Contact__c+'</SalesforceContactId>'
				+ '<SourceOpportunityLineId></SourceOpportunityLineId>'
				+ '<OracleAccountNumber>'+opportunity.Sold_To_Account__r.Name+'</OracleAccountNumber>'
				+ '<CDHPartyNumber>'+opportunity.Sold_To_Account__r.CDH_Party_Number__c+'</CDHPartyNumber>'
				+ '<CDHPartySiteNumber>'+opportunity.Sold_To_Address__r.CDH_Party_Site_Number__c+'</CDHPartySiteNumber>'
				+ '<ContactCDHPartyNumber>'+opportunity.Sold_To_Contact__r.CDH_Party__r.CDH_Party_Number_Ext__c+'</ContactCDHPartyNumber>'
				+ '<Address1>'+opportunity.Sold_To_Address__r.Address_Line1__c+'</Address1>'
				+ '<Address2>'+opportunity.Sold_To_Address__r.Address_Line2__c+'</Address2>'
				+ '<City>'+opportunity.Sold_To_Address__r.City__c+'</City>'
				+ '<State>'+opportunity.Sold_To_Address__r.State__c+'</State>'
				+ '<PostalCode>'+opportunity.Sold_To_Address__r.Zip_Postal_Code__c+'</PostalCode>'
				+ '<Country>'+opportunity.Sold_To_Address__r.Country__c+'</Country>'
				+ '<Email>'+opportunity.Sold_To_Contact__r.Email+'</Email>'
				+ '<Status>SUCCESS</Status>'
				+ '<Message></Message>'
				+ '</SoldToParty>'
				+ '<LineEntitleToParty>'
				+ '<Id>1355299</Id>'
				+ '<SalesforceSalesAccountId>'+opportunityLineItem.Entitle_To_Account__r.Sales_Account__c+'</SalesforceSalesAccountId>'
				+ '<SalesforceEBSAccountId>'+opportunityLineItem.Entitle_To_Account__c+'</SalesforceEBSAccountId>'
				+ '<SalesforceAddressId>'+opportunityLineItem.Entitle_To_Address__c+'</SalesforceAddressId>'
				+ '<SalesforceContactId>'+opportunityLineItem.Entitle_To_Contact__c+'</SalesforceContactId>'
				+ '<SourceOpportunityLineId></SourceOpportunityLineId>'
				+ '<OracleAccountNumber>'+opportunityLineItem.Entitle_To_Account__r.Name+'</OracleAccountNumber>'
				+ '<CDHPartyNumber>'+opportunityLineItem.Entitle_To_Account__r.CDH_Party_Number__c+'</CDHPartyNumber>'
				+ '<CDHPartySiteNumber>'+opportunityLineItem.Entitle_To_Address__r.CDH_Party_Site_Number__c+'</CDHPartySiteNumber>'
				+ '<ContactCDHPartyNumber>'+opportunityLineItem.Entitle_To_Contact__r.CDH_Party__r.CDH_Party_Number_Ext__c+'</ContactCDHPartyNumber>'
				+ '<Address1>'+opportunity.Entitle_To_Address__r.Address_Line1__c+'</Address1>'
				+ '<Address2>'+opportunity.Entitle_To_Address__r.Address_Line2__c+'</Address2>'
				+ '<City>'+opportunity.Entitle_To_Address__r.City__c+'</City>'
				+ '<State>'+opportunity.Entitle_To_Address__r.State__c+'</State>'
				+ '<PostalCode>'+opportunity.Entitle_To_Address__r.Zip_Postal_Code__c+'</PostalCode>'
				+ '<Country>'+opportunityLineItem.Entitle_To_Address__r.Country__c+'</Country>'
				+ '<Email>'+opportunityLineItem.Entitle_To_Contact__r.Email+'</Email>'
				+ '<Status>SUCCESS</Status>'
				+ '<Message></Message>'
				+ '</LineEntitleToParty>'
				+ '</AccountQuery>'
				+ '</Payload>'
				+ '</SalesforceMessage>';
			}
			return expectedXML;
		}
	}

//	static Opportunity_RenewalAccountMatching.MatchingMessage message{
//		get {
//			if(message == null) {
//				Opportunity_RenewalAccountMatching.MatchingMessage message = new Opportunity_RenewalAccountMatching.MatchingMessage();
//				message.unmarshal( xmlDocument, null );
//			}
//			return message;
//		}
//		set;
//	}

	@isTest
	static void fullTest() {
		Opportunity_RenewalAccountMatching ram = new Opportunity_RenewalAccountMatching();
		Test.startTest();
		String results = ram.queryAccount( xmlDocument ).replaceAll('<ResponseTimeStamp>[^<]*</ResponseTimeStamp>','<ResponseTimeStamp/>');
		List<String> expectedXmlList = expectedXml.split('<',0);
		List<String> resultsXmlList = results.split('<',0);
		for(Integer i = 0 ; i < expectedXmlList.size();i++) {
			System.assertEquals(expectedXmlList[i],resultsXmlList[i],'element: '+i);
		}
		System.assertEquals(expectedXmlList.size(),resultsXmlList.size());
		// the following is strictly for coverage test
		// the createAddress method is only used sandboxes, so stricter testing is not needed
		Map<Id,Address__c> addressMap = new Map<Id,Address__c>();
		for(Opportunity_RenewalAccountMatching.Party party : ram.accountQuery.parties ) {
			Address__c a = party.renewalParty.getAddress();
			if(a != null) {
				addressMap.put(a.Id,a);
				party.renewalParty.setAddress(null);
			}
		}
		delete addressMap.values();
		ram.createAddresses();
		Test.stopTest();
	}
}