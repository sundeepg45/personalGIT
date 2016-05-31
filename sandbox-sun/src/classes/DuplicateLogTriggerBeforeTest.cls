/**
 * This class contains unit tests for validating the behavior of 
 * DuplicateLogTriggerBefore.cls
 *
 * @version 2015-11-10
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-11-10 - A Merged status is not used for duplicate addresses
 * 2015-09-03 - Created
 */
@isTest
public class DuplicateLogTriggerBeforeTest {

	static Integer PRODUCTS_SIZE = 2;

	public static List<EBS_Account__c> ebsAccounts {
		get {
			if(ebsAccounts == null) {
				ebsAccounts = AccountMergeBatchableTest.ebsAccounts.clone();
				// this is just to make the test run faster
				AbstractTrigger.setBooleanSettings('EBSAccount_Before.',false);
				AbstractTrigger.setBooleanSettings('EBSAccount_After.',false);
				insert ebsAccounts;
				Id accountId = null;
				Id masterRecordId = null;
				for(EBS_Account__c ebsAccount : ebsAccounts) {
					if(ebsAccount.Sales_Account__c != accountId) {
						accountId = ebsAccount.Sales_Account__c;
						masterRecordId = ebsAccount.Id;
					}
					else {
						ebsAccount.Status__c = 'Inactive';
						ebsAccount.MasterRecord__c = masterRecordId;
					}
				}
				update ebsAccounts;
				AbstractTrigger.setBooleanSettings('EBSAccount_Before.',true);
				AbstractTrigger.setBooleanSettings('EBSAccount_After.',true);
			}
			return ebsAccounts;
		}
	}

	public static List<Address__c> addresses {
		get {
			if(addresses == null) {
				addresses = AccountMergeBatchableTest.addresses.clone();
				// this is just to make the test run faster
				AbstractTrigger.setBooleanSettings('Address_Before.',false);
				AbstractTrigger.setBooleanSettings('Address_After.',false);
				insert addresses;
				Id accountId = null;
				Id masterRecordId = null;
				for(Address__c address : addresses) {
					if(address.Sales_Account__c != accountId) {
						accountId = address.Sales_Account__c;
						masterRecordId = address.Id;
					}
					else {
						address.Status__c = 'Merged';
						address.IsDuplicate__c = true;
						address.MasterRecord__c = masterRecordId;
					}
				}
				update addresses;
				AbstractTrigger.setBooleanSettings('Address_Before.',true);
				AbstractTrigger.setBooleanSettings('Address_After.',true);
			}
			return addresses;
		}
	}

	public static List<Contact> contacts {
		get {
			if(contacts == null) {
				contacts = AccountMergeBatchableTest.contacts.clone();
				// this is just to make the test run faster
				AbstractTrigger.setBooleanSettings('Contact_Before.',false);
				AbstractTrigger.setBooleanSettings('Contact_After.',false);
				insert contacts;
				Id accountId = null;
				Id masterRecordId = null;
				for(Contact contact : contacts) {
					if(contact.AccountId != accountId) {
						accountId = contact.AccountId;
						masterRecordId = contact.Id;
					}
					else {
						contact.Status__c = 'Inactive';
						contact.MasterRecord__c = masterRecordId;
					}
				}
				update contacts;
				AbstractTrigger.setBooleanSettings('Contact_Before.',true);
				AbstractTrigger.setBooleanSettings('Contact_After.',true);
			}
			return contacts;
		}
	}

	public static List<DuplicateLog__c> duplicateLogs {
		get {
			if(duplicateLogs == null) {
				duplicateLogs = new List<DuplicateLog__c>();
				Integer ebsAccountsSize = ebsAccounts.size();
				Integer addressesSize = addresses.size();
				Integer contactsSize = contacts.size();
				Integer s = ebsAccountsSize;
				if( addressesSize > 0 && (s == 0 || s > addressesSize) ) {
					s = addressesSize;
				}
				if( contactsSize > 0 && (s == 0 || s > contactsSize) ) {
					s = contactsSize;
				}
				for(Integer i = 0;i < s && i < addressesSize;i++) {
					Address__c address = addresses[i];
					if(address.MasterRecord__c != null) {
						AccountMergeBatchable.addToLog(duplicateLogs,address.MasterRecord__c,address.Id,'Address','Account Merge');
					}
				}
				for(Integer i = 0;i < s && i < ebsAccountsSize;i++) {
					EBS_Account__c ebsAccount = ebsAccounts[i];
					if(ebsAccount.MasterRecord__c != null) {
						AccountMergeBatchable.addToLog(duplicateLogs,ebsAccount.MasterRecord__c,ebsAccount.Id,'EBS Account','Account Merge');
					}
				}
				for(Integer i = 0;i < s && i < contactsSize;i++) {
					Contact contact = contacts[i];
					if(contact.MasterRecord__c != null) {
						AccountMergeBatchable.addToLog(duplicateLogs,contact.MasterRecord__c,contact.Id,'Contact','Account Merge');
					}
				}
			}
			return duplicateLogs;
		}
	}

	public static List<Opportunity> opportunities {
		get {
			if(opportunities == null) {
				opportunities = new List<Opportunity>();
				Opportunity opp = TestUtil.getOpportunity('Opportunity Name' ,new Account());
				Integer ebsAccountsSize = ebsAccounts.size();
				Integer addressesSize = addresses.size();
				Integer contactsSize = contacts.size();
				Integer s = ebsAccountsSize;
				if( addressesSize > 0 && (s == 0 || s > addressesSize) ) {
					s = addressesSize;
				}
				if( contactsSize > 0 && (s == 0 || s > contactsSize) ) {
					s = contactsSize;
				}
				for(Integer i = 0;i < s;i++) {
					Opportunity o = opp.clone();
					o.Name = 'Opportunity Name '+i;
					Account a = new Account();
					if(i < contactsSize) {
						a = new Account(Id=contacts[i].AccountId);
						o.Bill_To_Contact__r = o.Entitle_To_Contact__r = o.Ship_To_Contact__r = o.Sold_To_Contact__r = contacts[i];
						o.Bill_To_Contact__c = o.Entitle_To_Contact__c = o.Ship_To_Contact__c = o.Sold_To_Contact__c = contacts[i].Id;
					}
					if(i < addressesSize) {
						a = new Account(Id=addresses[i].Sales_Account__c);
						o.Bill_To_Address__r = o.Entitle_To_Address__r = o.Ship_To_Address__r = o.Sold_To_Address__r = addresses[i];
						o.Bill_To_Address__c = o.Entitle_To_Address__c = o.Ship_To_Address__c = o.Sold_To_Address__c = addresses[i].Id;
					}
					if(i < ebsAccountsSize) {
						a = new Account(Id=ebsAccounts[i].Sales_Account__c);
						o.Bill_To_Account__r = o.Entitle_To_Account__r = o.Ship_To_Account__r = o.Sold_To_Account__r = ebsAccounts[i];
						o.Bill_To_Account__c = o.Entitle_To_Account__c = o.Ship_To_Account__c = o.Sold_To_Account__c = ebsAccounts[i].Id;
					}
					o.Account = a;
					o.AccountId = a.Id;
					o.Bill_To_Sales_Account__r = o.Entitle_To_Sales_Account__r = o.Ship_To_Sales_Account__r = o.Sold_To_Sales_Account__r = a;
					o.Bill_To_Sales_Account__c = o.Entitle_To_Sales_Account__c = o.Ship_To_Sales_Account__c = o.Sold_To_Sales_Account__c = a.Id;
					opportunities.add(o);
				}
			}
			return opportunities;
		}
		set;
	}

	public static Map<Id,Opportunity> opportunityMap {
		get {
			if(opportunityMap == null) {
				opportunityMap = new Map<Id,Opportunity>();
				// this is just to make the test run faster
				AbstractTrigger.setBooleanSettings('Opp_Before.',false);
				AbstractTrigger.setBooleanSettings('Opp_After.',false);
				upsert opportunities;
				AbstractTrigger.setBooleanSettings('Opp_Before.',true);
				AbstractTrigger.setBooleanSettings('Opp_After.',true);
				opportunityMap.putAll(opportunities);
			}
			return opportunityMap;
		}
		set;
	}

	public static List<Order_Management_Profile__c> omProfiles {
		get {
			if(omProfiles == null) {
				omProfiles = new List<Order_Management_Profile__c>();
				for(Opportunity opp : opportunities) {
					Order_Management_Profile__c omProfile = new Order_Management_Profile__c(
						Name = opp.Name,
						Account__r = opp.Account,
						Account__c = opp.AccountId,
						Default__c = true,
						Bill_To_Contact__r = opp.Bill_To_Contact__r,
						Bill_To_Contact__c = opp.Bill_To_Contact__c,
						Entitle_To_Contact__r = opp.Entitle_To_Contact__r,
						Entitle_To_Contact__c = opp.Entitle_To_Contact__c,
						Ship_To_Contact__r = opp.Ship_To_Contact__r,
						Ship_To_Contact__c = opp.Ship_To_Contact__c,
						Sold_To_Contact__r = opp.Sold_To_Contact__r,
						Sold_To_Contact__c = opp.Sold_To_Contact__c,
						Bill_To_Address__r = opp.Bill_To_Address__r,
						Bill_To_Address__c = opp.Bill_To_Address__c,
						Entitle_To_Address__r = opp.Entitle_To_Address__r,
						Entitle_To_Address__c = opp.Entitle_To_Address__c,
						Ship_To_Address__r = opp.Ship_To_Address__r,
						Ship_To_Address__c = opp.Ship_To_Address__c,
						Sold_To_Address__r = opp.Sold_To_Address__r,
						Sold_To_Address__c = opp.Sold_To_Address__c,
						Bill_To_EBS_Account__r = opp.Bill_To_Account__r,
						Bill_To_EBS_Account__c = opp.Bill_To_Account__c,
						Entitle_To_EBS_Account__r = opp.Entitle_To_Account__r,
						Entitle_To_EBS_Account__c = opp.Entitle_To_Account__c,
						Ship_To_EBS_Account__r = opp.Ship_To_Account__r,
						Ship_To_EBS_Account__c = opp.Ship_To_Account__c,
						Sold_To_EBS_Account__r = opp.Sold_To_Account__r,
						Sold_To_EBS_Account__c = opp.Sold_To_Account__c );
					omProfiles.add(omProfile);
				}
			}
			return omProfiles;
		}
		set;
	}

	public static Map<Id,Order_Management_Profile__c> omProfileMap {
		get {
			if(omProfileMap == null) {
				omProfileMap = new Map<Id,Order_Management_Profile__c>();
				upsert omProfiles;
				omProfileMap.putAll(omProfiles);
			}
			return omProfileMap;
		}
		set;
	}

	public static List<Opportunity_Header_Staging__c> oppHeaderStagingList {
		get {
			if(oppHeaderStagingList == null) {
				oppHeaderStagingList = new List<Opportunity_Header_Staging__c>();
				for(Opportunity opp : opportunities) {
					Opportunity_Header_Staging__c oppHeaderStaging = new Opportunity_Header_Staging__c(
						Bill_To_Contact__r = opp.Bill_To_Contact__r,
						Bill_To_Contact__c = opp.Bill_To_Contact__c,
						Entitle_To_Contact__r = opp.Entitle_To_Contact__r,
						Entitle_To_Contact__c = opp.Entitle_To_Contact__c,
						Ship_To_Contact__r = opp.Ship_To_Contact__r,
						Ship_To_Contact__c = opp.Ship_To_Contact__c,
						Sold_To_Contact__r = opp.Sold_To_Contact__r,
						Sold_To_Contact__c = opp.Sold_To_Contact__c,
						Bill_To_Address__r = opp.Bill_To_Address__r,
						Bill_To_Address__c = opp.Bill_To_Address__c,
						Entitle_To_Address__r = opp.Entitle_To_Address__r,
						Entitle_To_Address__c = opp.Entitle_To_Address__c,
						Ship_To_Address__r = opp.Ship_To_Address__r,
						Ship_To_Address__c = opp.Ship_To_Address__c,
						Sold_To_Address__r = opp.Sold_To_Address__r,
						Sold_To_Address__c = opp.Sold_To_Address__c,
						Bill_To_Account__r = opp.Bill_To_Account__r,
						Bill_To_Account__c = opp.Bill_To_Account__c,
						Entitle_To_Account__r = opp.Entitle_To_Account__r,
						Entitle_To_Account__c = opp.Entitle_To_Account__c,
						Ship_To_Account__r = opp.Ship_To_Account__r,
						Ship_To_Account__c = opp.Ship_To_Account__c,
						Sold_To_Account__r = opp.Sold_To_Account__r,
						Sold_To_Account__c = opp.Sold_To_Account__c );
					oppHeaderStagingList.add(oppHeaderStaging);
				}
			}
			return oppHeaderStagingList;
		}
		set;
	}

	public static Map<Id,Opportunity_Header_Staging__c> oppHeaderStagingMap {
		get {
			if(oppHeaderStagingMap == null) {
				oppHeaderStagingMap = new Map<Id,Opportunity_Header_Staging__c>();
				upsert oppHeaderStagingList;
				oppHeaderStagingMap.putAll(oppHeaderStagingList);
			}
			return oppHeaderStagingMap;
		}
		set;
	}

	public static List<Subscription__c> subscriptions {
		get {
			if(subscriptions == null) {
				subscriptions = new List<Subscription__c>();
				for(Opportunity opp : opportunities) {
					Subscription__c subscription = new Subscription__c(
						BillToContact__r = opp.Bill_To_Contact__r,
						BillToContact__c = opp.Bill_To_Contact__c,
						EntitleToContact__r = opp.Entitle_To_Contact__r,
						EntitleToContact__c = opp.Entitle_To_Contact__c,
						ShipToContact__r = opp.Ship_To_Contact__r,
						ShipToContact__c = opp.Ship_To_Contact__c,
						SoldToContact__r = opp.Sold_To_Contact__r,
						SoldToContact__c = opp.Sold_To_Contact__c,
						BillToAddress__r = opp.Bill_To_Address__r,
						BillToAddress__c = opp.Bill_To_Address__c,
						EntitleToAddress__r = opp.Entitle_To_Address__r,
						EntitleToAddress__c = opp.Entitle_To_Address__c,
						ShipToAddress__r = opp.Ship_To_Address__r,
						ShipToAddress__c = opp.Ship_To_Address__c,
						SoldToAddress__r = opp.Sold_To_Address__r,
						SoldToAddress__c = opp.Sold_To_Address__c,
						BillToEBSAccount__r = opp.Bill_To_Account__r,
						BillToEBSAccount__c = opp.Bill_To_Account__c,
						EntitleToEBSAccount__r = opp.Entitle_To_Account__r,
						EntitleToEBSAccount__c = opp.Entitle_To_Account__c,
						ShipToEBSAccount__r = opp.Ship_To_Account__r,
						ShipToEBSAccount__c = opp.Ship_To_Account__c,
						SoldToEBSAccount__r = opp.Sold_To_Account__r,
						SoldToEBSAccount__c = opp.Sold_To_Account__c );
					subscriptions.add(subscription);
				}
			}
			return subscriptions;
		}
		set;
	}

	public static Map<Id,Subscription__c> subscriptionMap {
		get {
			if(subscriptionMap == null) {
				subscriptionMap = new Map<Id,Subscription__c>();
				upsert subscriptions;
				subscriptionMap.putAll(subscriptions);
			}
			return subscriptionMap;
		}
		set;
	}


	static Id pricebookId {
		get {
			if(pricebookId == null) {
				pricebookId = Test.getStandardPricebookId();
			}
			return pricebookId;
		}
		set;
	}

	static List<Product2> products {
		get {
			if(products == null && pricebookId != null) {
				products = new List<Product2>(products);
				for(Integer i=1;i <= PRODUCTS_SIZE;i++) {
					Product2 product = TestUtil.getProduct('Global Price Book');
					product.ProductCode='TEST-'+i;
					product.IsActive=true;
					products.add(product);
				}
			}
			return products;
		}
		set;
	}

	static Map<Id,Product2> productMap {
		get {
			if(productMap == null) {
				productMap = new Map<Id,Product2>();
				upsert products;
				productMap.putAll(products);
			}
			return productMap;
		}
		set;
	}

	static Pricebook2 customPB {
		get {
			if(customPB == null) {
				// Create a custom price book
				customPB = new Pricebook2(Name='Global Price Book', isActive=true);
				insert customPB;	
			}
			return customPB;
		}
		set;
	}

	static List<PricebookEntry> pricebookEntries {
		get {
			if(pricebookEntries == null) {
				pricebookEntries = new List<PricebookEntry>();
				if(! productMap.isEmpty()) {
					for(Id pbId : new List<Id>{pricebookId,customPB.Id}) {
						for(Product2 product : products) {
							PricebookEntry pricebookEntry = TestUtil.getPricebookEntry(pbId ,product);
							pricebookEntry.IsActive=true;
							pricebookEntry.CurrencyIsoCode = opportunities[0].CurrencyIsoCode;
							pricebookEntries.add(pricebookEntry);
						}
					}
				}
			}
			return pricebookEntries;
		}
		set;
	}

	static Map<Id,PricebookEntry> pricebookEntryMap {
		get {
			if(pricebookEntryMap == null) {
				pricebookEntryMap = new Map<Id,PricebookEntry>();
				upsert pricebookEntries;
				pricebookEntryMap.putAll(pricebookEntries);
			}
			return pricebookEntryMap;
		}
	}

	public static List<OpportunityLineItem> opportunityLineItems {
		get {
			if(opportunityLineItems == null) {
				opportunityLineItems = new List<OpportunityLineItem>();
				for(Opportunity opp : opportunities) {
					Id pricebook2Id = null;
					for(PricebookEntry e : pricebookEntries) {
						if(pricebook2Id == null || pricebook2Id == e.Pricebook2Id) {
							pricebook2Id = e.Pricebook2Id;
							OpportunityLineItem lineItem = TestUtil.getOpportunityLineItem(opp,e.Id);
							lineItem.Opportunity = opp;
							lineItem.PricebookEntry = e;
							lineItem.Entitle_To_Sales_Account__r = opp.Entitle_To_Sales_Account__r;
							lineItem.Entitle_To_Sales_Account__c = opp.Entitle_To_Sales_Account__c;
							lineItem.Entitle_To_Account__r = opp.Entitle_To_Account__r;
							lineItem.Entitle_To_Account__c = opp.Entitle_To_Account__c;
							lineItem.Entitle_To_Address__r = opp.Entitle_To_Address__r;
							lineItem.Entitle_To_Address__c = opp.Entitle_To_Address__c;
							lineItem.Entitle_To_Contact__r = opp.Entitle_To_Contact__r;
							lineItem.Entitle_To_Contact__c = opp.Entitle_To_Contact__c;
							opportunityLineItems.add(lineItem);
						}
					}
				}
			}
			return opportunityLineItems;
		}
		set;
	}

	public static Map<Id,OpportunityLineItem> opportunityLineItemMap {
		get {
			if(opportunityLineItemMap == null) {
				opportunityLineItemMap = new Map<Id,OpportunityLineItem>();
				System.assert(! pricebookEntryMap.isEmpty());
				System.assert(! opportunityMap.isEmpty());
				for(OpportunityLineItem lineItem : opportunityLineItems) {
					lineItem.OpportunityId = lineItem.Opportunity.Id;
					lineItem.PricebookEntryId = lineItem.PricebookEntry.Id;
				}
				// this is just to make the test run faster
				AbstractTrigger.setBooleanSettings('Opp_Before.',false);
				AbstractTrigger.setBooleanSettings('Opp_After.',false);
				AbstractTrigger.setBooleanSettings('OppLine_Before.',false);
				AbstractTrigger.setBooleanSettings('OppLine_After.',false);
				upsert opportunityLineItems;
				AbstractTrigger.setBooleanSettings('Opp_Before.',true);
				AbstractTrigger.setBooleanSettings('Opp_After.',true);
				AbstractTrigger.setBooleanSettings('OppLine_Before.',true);
				AbstractTrigger.setBooleanSettings('OppLine_After.',true);
				opportunityMap.putAll(opportunities);
				opportunityLineItemMap.putAll(opportunityLineItems);
			}
			return opportunityLineItemMap;
		}
		set;
	}

	public static List<Opportunity_Line_Staging__c> oppLineStagingList {
		get {
			if(oppLineStagingList == null && ! oppHeaderStagingMap.isEmpty()) {
				oppLineStagingList = new List<Opportunity_Line_Staging__c>();
				Integer i = 0;
				String oppId = null;
				Opportunity_Header_Staging__c oppHeaderStaging = null;
				for(OpportunityLineItem oppLine : opportunityLineItems) {
					if(oppId != oppLine.OpportunityId) {
						oppId = oppLine.OpportunityId;
						oppHeaderStaging = oppHeaderStagingList[i++];
					}
					Opportunity_Line_Staging__c oppLineStaging = new Opportunity_Line_Staging__c(
						Opportunity_Stage_Header_Id__r = oppHeaderStaging,
						Opportunity_Stage_Header_Id__c = oppHeaderStaging.Id,
						Entitle_To_Contact__r = oppLine.Entitle_To_Contact__r,
						Entitle_To_Contact__c = oppLine.Entitle_To_Contact__c,
						Entitle_To_Address__r = oppLine.Entitle_To_Address__r,
						Entitle_To_Address__c = oppLine.Entitle_To_Address__c,
						Entitle_To_Account__r = oppLine.Entitle_To_Account__r,
						Entitle_To_Account__c = oppLine.Entitle_To_Account__c );
					oppLineStagingList.add(oppLineStaging);
				}
			}
			return oppLineStagingList;
		}
		set;
	}

	public static Map<Id,Opportunity_Line_Staging__c> oppLineStagingMap {
		get {
			if(oppLineStagingMap == null) {
				oppLineStagingMap = new Map<Id,Opportunity_Line_Staging__c>();
				upsert oppLineStagingList;
				oppLineStagingMap.putAll(oppLineStagingList);
			}
			return oppLineStagingMap;
		}
		set;
	}

	public static List<SubscriptionLine__c> subscriptionLines {
		get {
			if(subscriptionLines == null && ! subscriptionMap.isEmpty()) {
				subscriptionLines = new List<SubscriptionLine__c>();
				Integer i = 0;
				String oppId = null;
				Subscription__c subscription = null;
				for(OpportunityLineItem oppLine : opportunityLineItems) {
					if(oppId != oppLine.OpportunityId) {
						oppId = oppLine.OpportunityId;
						subscription = subscriptions[i++];
					}
					SubscriptionLine__c subscriptionLine = new SubscriptionLine__c(
						Subscription__r = subscription,
						Subscription__c = subscription.Id,
						ContractLineId__c = oppLine.Id,
						EntitleToContact__r = oppLine.Entitle_To_Contact__r,
						EntitleToContact__c = oppLine.Entitle_To_Contact__c,
						EntitleToAddress__r = oppLine.Entitle_To_Address__r,
						EntitleToAddress__c = oppLine.Entitle_To_Address__c,
						EntitleToEBSAccount__r = oppLine.Entitle_To_Account__r,
						EntitleToEBSAccount__c = oppLine.Entitle_To_Account__c );
					subscriptionLines.add(subscriptionLine);
				}
			}
			return subscriptionLines;
		}
		set;
	}

	public static Map<Id,SubscriptionLine__c> subscriptionLineMap {
		get {
			if(subscriptionLineMap == null) {
				subscriptionLineMap = new Map<Id,SubscriptionLine__c>();
				upsert subscriptionLines;
				subscriptionLineMap.putAll(subscriptionLines);
			}
			return subscriptionLineMap;
		}
		set;
	}

	@isTest
	static void ignoreRecordIdsTest() {
		AbstractTrigger.setBooleanSettings('DupLog_Before.',false);
		AbstractTrigger.setBooleanSettings('DupLog_After.',false);
		insert duplicateLogs;
		System.assertNotEquals(0,duplicateLogs.size());
		List<DuplicateMigrationLog__c> duplicateMigrationLogs = new List<DuplicateMigrationLog__c>();
		final String objectType = 'Opportunity';
		for(DuplicateLog__c dlog : duplicateLogs) {
			Id masterRecordId = (Id)dlog.MasterRecordId__c;
			// we don't really care what the id is for this particular usage
			Id recordId = dlog.Id;
			String key = objectType+':'+masterRecordId+':'+recordId;
			duplicateMigrationLogs.add(new DuplicateMigrationLog__c(
				DuplicateLog__c = dlog.Id,
				ExternalId__c=key,
				FieldName__c='Bill_To_Account__c',
				MasterRecordId__c=masterRecordId,
				ObjectType__c=objectType,
				RecordId__c = recordId,
				Status__c = 'Failure' ));
		}
		insert duplicateMigrationLogs;
		Test.startTest();
		List<DuplicateLog__c> dlogs = [
			select
				FailedMigrations__c,
				SuccessfulMigrations__c,
				Status__c,
				DuplicateRecordId__c,
				MasterRecordId__c,
				ObjectType__c,
				Opportunities_Migrated__c,
				Products_Migrated__c,
				Staging_Headers_Migrated__c,
				Staging_Lines_Migrated__c,
				OM_Profiles_Migrated__c,
				Subscriptions_Migrated__c,
				Subscription_Lines_Migrated__c,
				OppContactRoles_Migrated__c,
				PartnerPrograms_Migrated__c,
				OpportunityPartners_Migrated__c,
				Activities_Migrated__c
			from DuplicateLog__c ];
		System.assertEquals(duplicateLogs.size(),dlogs.size());
		System.assertNotEquals(0,dlogs[0].FailedMigrations__c.intValue(),'Rollup not calculated: '+dlogs[0]);
		DuplicateLogTriggerBefore beforeTrigger = new DuplicateLogTriggerBefore(new Map<Id,DuplicateLog__c>(dlogs),dlogs);
		Set<Id> duplicateLogIdsWithFailures = beforeTrigger.duplicateLogIdsWithFailures;
		System.assertEquals(dlogs.size(),duplicateLogIdsWithFailures.size());
		Set<id> ignoreRecordIds = beforeTrigger.ignoreRecordIds;
		System.assertEquals(dlogs.size(),ignoreRecordIds.size());
		duplicateLogIdsWithFailures.removeAll(new Map<Id,DuplicateLog__c>(dlogs).keySet());
		System.assert(duplicateLogIdsWithFailures.isEmpty(),'Unexpected record ids to ignore: '+duplicateLogIdsWithFailures);
		ignoreRecordIds.removeAll(new Map<Id,DuplicateLog__c>(dlogs).keySet());
		System.assert(ignoreRecordIds.isEmpty(),'Unexpected record ids to ignore: '+ignoreRecordIds);
		Test.stopTest();
	}

	@isTest
	static void toggerMigratedTest1() {
		Test.startTest();
		DuplicateLogTriggerBefore beforeTrigger = new DuplicateLogTriggerBefore(null,duplicateLogs);
		beforeTrigger.toggleMigrated();
		for(DuplicateLog__c dlog : duplicateLogs) {
			System.assert(dlog.Opportunities_Migrated__c,'Opportunities should be marked migrated');
			System.assert(dlog.Products_Migrated__c,'Products should have been marked migrated');
			System.assert(dlog.OM_Profiles_Migrated__c,'Order Management Profiles should have been marked migrated: '+dlog);
			System.assert(dlog.Staging_Headers_Migrated__c,'Opportunity Header Staging records should be marked migrated');
			System.assert(dlog.Staging_Lines_Migrated__c,'Opportunity Line Staging records should be marked migrated');
			System.assert(dlog.Subscriptions_Migrated__c,'Subscriptions should be marked migrated');
			System.assert(dlog.Subscription_Lines_Migrated__c,'Subscription Lines should be marked migrated');
			System.assertEquals('Completed',dlog.Status__c);
		}
		AbstractTrigger.setBooleanSettings('DupLog_Before.',false);
		AbstractTrigger.setBooleanSettings('DupLog_After.',false);
		insert duplicateLogs;
		System.assertNotEquals(0,duplicateLogs.size());
		beforeTrigger = new DuplicateLogTriggerBefore(new Map<Id,DuplicateLog__c>(duplicateLogs),duplicateLogs);
		beforeTrigger.toggleMigrated();
		for(DuplicateLog__c dlog : duplicateLogs) {
			System.assert(dlog.Opportunities_Migrated__c,'Opportunities should be marked migrated');
			System.assert(dlog.Products_Migrated__c,'Products should have been marked migrated');
			System.assert(dlog.OM_Profiles_Migrated__c,'Order Management Profiles should have been marked migrated: '+dlog);
			System.assert(dlog.Staging_Headers_Migrated__c,'Opportunity Header Staging records should be marked migrated');
			System.assert(dlog.Staging_Lines_Migrated__c,'Opportunity Line Staging records should be marked migrated');
			System.assert(dlog.Subscriptions_Migrated__c,'Subscriptions should be marked migrated');
			System.assert(dlog.Subscription_Lines_Migrated__c,'Subscription Lines should be marked migrated');
			System.assertEquals('Completed',dlog.Status__c);
		}
		Test.stopTest();
	}

	@isTest
	static void toggerMigratedTest2() {
		// create the opportunities, and line items
		System.assertNotEquals(0,opportunityLineItemMap.size());
		// create order management profiles
		System.assertNotEquals(0,omProfileMap.size());
		// create opportunity lines and header staging records
		System.assertNotEquals(0,oppLineStagingMap.size());
		// create subscription and subscription lines
		System.assertNotEquals(0,subscriptionLineMap.size());

		Test.startTest();
		DuplicateLogTriggerBefore beforeTrigger = new DuplicateLogTriggerBefore(null,duplicateLogs);
		beforeTrigger.toggleMigrated();
		for(DuplicateLog__c dlog : duplicateLogs) {
			System.assert(! dlog.Opportunities_Migrated__c,'Opportunities should not have been marked migrated: '+dlog);
			System.assert(! dlog.Products_Migrated__c,'Products should not have been marked migrated');
			System.assert(! dlog.OM_Profiles_Migrated__c,'Order Management Profiles should not have been marked migrated: '+dlog);
			System.assert(! dlog.Staging_Headers_Migrated__c,'Opportunity Header Staging records should not have been marked migrated');
			System.assert(! dlog.Staging_Lines_Migrated__c,'Opportunity Line Staging records should not have been marked migrated');
			System.assert(! dlog.Subscriptions_Migrated__c,'Subscriptions should not have been marked migrated');
			System.assert(! dlog.Subscription_Lines_Migrated__c,'Subscription Lines should not have been marked migrated');
			System.assertEquals('Pending',dlog.Status__c);
		}
		AbstractTrigger.setBooleanSettings('DupLog_Before.',false);
		AbstractTrigger.setBooleanSettings('DupLog_After.',false);
		insert duplicateLogs;
		System.assertNotEquals(0,duplicateLogs.size());
		beforeTrigger = new DuplicateLogTriggerBefore(new Map<Id,DuplicateLog__c>(duplicateLogs),duplicateLogs);
		beforeTrigger.toggleMigrated();
		for(DuplicateLog__c dlog : duplicateLogs) {
			System.assert(! dlog.Opportunities_Migrated__c,'Opportunities should not have been marked migrated: '+dlog);
			System.assert(! dlog.Products_Migrated__c,'Products should not have been marked migrated');
			System.assert(! dlog.OM_Profiles_Migrated__c,'Order Management Profiles should not have been marked migrated: '+dlog);
			System.assert(! dlog.Staging_Headers_Migrated__c,'Opportunity Header Staging records should not have been marked migrated');
			System.assert(! dlog.Staging_Lines_Migrated__c,'Opportunity Line Staging records should not have been marked migrated');
			System.assert(! dlog.Subscriptions_Migrated__c,'Subscriptions should not have been marked migrated');
			System.assert(! dlog.Subscription_Lines_Migrated__c,'Subscription Lines should not have been marked migrated');
			System.assertNotEquals('Completed',dlog.Status__c); // we faked the failure test, so this is in progress not Pending
		}
		beforeTrigger.ignoreRecordIds.addAll(opportunityLineItemMap.keySet());
		beforeTrigger.ignoreRecordIds.addAll(opportunityMap.keySet());
		beforeTrigger.ignoreRecordIds.addAll(omProfileMap.keySet());
		beforeTrigger.ignoreRecordIds.addAll(oppHeaderStagingMap.keySet());
		beforeTrigger.ignoreRecordIds.addAll(oppLineStagingMap.keySet());
		beforeTrigger.ignoreRecordIds.addAll(subscriptionMap.keySet());
		beforeTrigger.ignoreRecordIds.addAll(subscriptionLineMap.keySet());
		beforeTrigger.toggleMigrated();
		for(DuplicateLog__c dlog : duplicateLogs) {
			System.assert(dlog.Opportunities_Migrated__c,'Opportunities should be marked migrated');
			System.assert(dlog.Products_Migrated__c,'Products should have been marked migrated');
			System.assert(dlog.OM_Profiles_Migrated__c,'Order Management Profiles should have been marked migrated: '+dlog);
			System.assert(dlog.Staging_Headers_Migrated__c,'Opportunity Header Staging records should be marked migrated');
			System.assert(dlog.Staging_Lines_Migrated__c,'Opportunity Line Staging records should be marked migrated');
			System.assert(dlog.Subscriptions_Migrated__c,'Subscriptions should be marked migrated');
			System.assert(dlog.Subscription_Lines_Migrated__c,'Subscription Lines should be marked migrated');
			System.assertEquals('Completed',dlog.Status__c);
		}
		Test.stopTest();
	}

	@isTest
	static void toggerMigratedTest3() {
		contacts = new List<Contact>();
		addresses = new List<Address__c>();
		// create the opportunities, and line items
		System.assertNotEquals(0,opportunityLineItemMap.size());
		// create order management profiles
		System.assertNotEquals(0,omProfileMap.size());
		// create opportunity lines and header staging records
		System.assertNotEquals(0,oppLineStagingMap.size());
		// create subscription and subscription lines
		System.assertNotEquals(0,subscriptionLineMap.size());

		Test.startTest();
		DuplicateLogTriggerBefore beforeTrigger = new DuplicateLogTriggerBefore(null,duplicateLogs);
		beforeTrigger.toggleMigrated();
		for(DuplicateLog__c dlog : duplicateLogs) {
			System.assert(! dlog.Opportunities_Migrated__c,'Opportunities should not have been marked migrated');
			System.assert(! dlog.Products_Migrated__c,'Products should not have been marked migrated');
			System.assert(! dlog.OM_Profiles_Migrated__c,'Order Management Profiles should not have been marked migrated: '+dlog);
			System.assert(! dlog.Staging_Headers_Migrated__c,'Opportunity Header Staging records should not have been marked migrated');
			System.assert(! dlog.Staging_Lines_Migrated__c,'Opportunity Line Staging records should not have been marked migrated');
			System.assert(! dlog.Subscriptions_Migrated__c,'Subscriptions should not have been marked migrated');
			System.assert(! dlog.Subscription_Lines_Migrated__c,'Subscription Lines should not have been marked migrated');
			System.assertEquals('Pending',dlog.Status__c);
		}
		AbstractTrigger.setBooleanSettings('DupLog_Before.',false);
		AbstractTrigger.setBooleanSettings('DupLog_After.',false);
		insert duplicateLogs;
		System.assertNotEquals(0,duplicateLogs.size());
		beforeTrigger = new DuplicateLogTriggerBefore(new Map<Id,DuplicateLog__c>(duplicateLogs),duplicateLogs);
		beforeTrigger.toggleMigrated();
		for(DuplicateLog__c dlog : duplicateLogs) {
			System.assert(! dlog.Opportunities_Migrated__c,'Opportunities should not have been marked migrated');
			System.assert(! dlog.Products_Migrated__c,'Products should not have been marked migrated');
			System.assert(! dlog.OM_Profiles_Migrated__c,'Order Management Profiles should not have been marked migrated: '+dlog);
			System.assert(! dlog.Staging_Headers_Migrated__c,'Opportunity Header Staging records should not have been marked migrated');
			System.assert(! dlog.Staging_Lines_Migrated__c,'Opportunity Line Staging records should not have been marked migrated');
			System.assert(! dlog.Subscriptions_Migrated__c,'Subscriptions should not have been marked migrated');
			System.assert(! dlog.Subscription_Lines_Migrated__c,'Subscription Lines should not have been marked migrated');
			System.assertNotEquals('Completed',dlog.Status__c); // we faked the failure test, so this is in progress not Pending
		}
		Test.stopTest();
	}

	@isTest
	static void toggerMigratedTest4() {
		contacts = new List<Contact>();
		ebsAccounts = new List<EBS_Account__c>();
		// create the opportunities, and line items
		System.assertNotEquals(0,opportunityLineItemMap.size());
		// create order management profiles
		System.assertNotEquals(0,omProfileMap.size());
		// create opportunity lines and header staging records
		System.assertNotEquals(0,oppLineStagingMap.size());
		// create subscription and subscription lines
		System.assertNotEquals(0,subscriptionLineMap.size());

		Test.startTest();
		DuplicateLogTriggerBefore beforeTrigger = new DuplicateLogTriggerBefore(null,duplicateLogs);
		beforeTrigger.toggleMigrated();
		for(DuplicateLog__c dlog : duplicateLogs) {
			System.assert(! dlog.Opportunities_Migrated__c,'Opportunities should not have been marked migrated');
			System.assert(! dlog.Products_Migrated__c,'Products should not have been marked migrated');
			System.assert(! dlog.OM_Profiles_Migrated__c,'Order Management Profiles should not have been marked migrated: '+dlog);
			System.assert(! dlog.Staging_Headers_Migrated__c,'Opportunity Header Staging records should not have been marked migrated');
			System.assert(! dlog.Staging_Lines_Migrated__c,'Opportunity Line Staging records should not have been marked migrated');
			System.assert(! dlog.Subscriptions_Migrated__c,'Subscriptions should not have been marked migrated');
			System.assert(! dlog.Subscription_Lines_Migrated__c,'Subscription Lines should not have been marked migrated');
			System.assertEquals('Pending',dlog.Status__c);
		}
		AbstractTrigger.setBooleanSettings('DupLog_Before.',false);
		AbstractTrigger.setBooleanSettings('DupLog_After.',false);
		insert duplicateLogs;
		System.assertNotEquals(0,duplicateLogs.size());
		beforeTrigger = new DuplicateLogTriggerBefore(new Map<Id,DuplicateLog__c>(duplicateLogs),duplicateLogs);
		beforeTrigger.toggleMigrated();
		for(DuplicateLog__c dlog : duplicateLogs) {
			System.assert(! dlog.Opportunities_Migrated__c,'Opportunities should not have been marked migrated');
			System.assert(! dlog.Products_Migrated__c,'Products should not have been marked migrated');
			System.assert(! dlog.OM_Profiles_Migrated__c,'Order Management Profiles should not have been marked migrated: '+dlog);
			System.assert(! dlog.Staging_Headers_Migrated__c,'Opportunity Header Staging records should not have been marked migrated');
			System.assert(! dlog.Staging_Lines_Migrated__c,'Opportunity Line Staging records should not have been marked migrated');
			System.assert(! dlog.Subscriptions_Migrated__c,'Subscriptions should not have been marked migrated');
			System.assert(! dlog.Subscription_Lines_Migrated__c,'Subscription Lines should not have been marked migrated');
			System.assertNotEquals('Completed',dlog.Status__c); // we faked the failure test, so this is in progress not Pending
		}
		Test.stopTest();
	}

	@isTest
	static void toggerMigratedTest5() {
		addresses = new List<Address__c>();
		ebsAccounts = new List<EBS_Account__c>();
		// create the opportunities, and line items
		System.assertNotEquals(0,opportunityLineItemMap.size());
		// create order management profiles
		System.assertNotEquals(0,omProfileMap.size());
		// create opportunity lines and header staging records
		System.assertNotEquals(0,oppLineStagingMap.size());
		// create subscription and subscription lines
		System.assertNotEquals(0,subscriptionLineMap.size());

		Test.startTest();
		DuplicateLogTriggerBefore beforeTrigger = new DuplicateLogTriggerBefore(null,duplicateLogs);
		beforeTrigger.toggleMigrated();
		for(DuplicateLog__c dlog : duplicateLogs) {
			System.assert(! dlog.Opportunities_Migrated__c,'Opportunities should not have been marked migrated');
			System.assert(! dlog.Products_Migrated__c,'Products should not have been marked migrated');
			System.assert(! dlog.OM_Profiles_Migrated__c,'Order Management Profiles should not have been marked migrated: '+dlog);
			System.assert(! dlog.Staging_Headers_Migrated__c,'Opportunity Header Staging records should not have been marked migrated');
			System.assert(! dlog.Staging_Lines_Migrated__c,'Opportunity Line Staging records should not have been marked migrated');
			System.assert(! dlog.Subscriptions_Migrated__c,'Subscriptions should not have been marked migrated');
			System.assert(! dlog.Subscription_Lines_Migrated__c,'Subscription Lines should not have been marked migrated');
			System.assertEquals('Pending',dlog.Status__c);
		}
		AbstractTrigger.setBooleanSettings('DupLog_Before.',false);
		AbstractTrigger.setBooleanSettings('DupLog_After.',false);
		insert duplicateLogs;
		System.assertNotEquals(0,duplicateLogs.size());
		beforeTrigger = new DuplicateLogTriggerBefore(new Map<Id,DuplicateLog__c>(duplicateLogs),duplicateLogs);
		beforeTrigger.toggleMigrated();
		for(DuplicateLog__c dlog : duplicateLogs) {
			System.assert(! dlog.Opportunities_Migrated__c,'Opportunities should not have been marked migrated');
			System.assert(! dlog.Products_Migrated__c,'Products should not have been marked migrated');
			System.assert(! dlog.OM_Profiles_Migrated__c,'Order Management Profiles should not have been marked migrated: '+dlog);
			System.assert(! dlog.Staging_Headers_Migrated__c,'Opportunity Header Staging records should not have been marked migrated');
			System.assert(! dlog.Staging_Lines_Migrated__c,'Opportunity Line Staging records should not have been marked migrated');
			System.assert(! dlog.Subscriptions_Migrated__c,'Subscriptions should not have been marked migrated');
			System.assert(! dlog.Subscription_Lines_Migrated__c,'Subscription Lines should not have been marked migrated');
			System.assertNotEquals('Completed',dlog.Status__c); // we faked the failure test, so this is in progress not Pending
		}
		Test.stopTest();
	}

	@isTest
	static void processTriggerTest() {
		// no class specific tests are performed, this is just to test the processTrigger method
		AbstractTrigger.setBooleanSettings('DupLog_Before.',false);
		AbstractTrigger.setBooleanSettings('DupLog_After.',false);
		List<DuplicateLog__c> xduplicateLogs = new List<DuplicateLog__c>();
		// we'll use user id's instead of addresses, because we are only checking the trigger processing logic for exceptions
		List<User> users = [select Id from User where IsActive = true and ProfileId = :UserInfo.getProfileId() limit 2];
		AccountMergeBatchable.addToLog(xduplicateLogs,users[0].Id,users[1].Id,'Address','Account Merge');
		insert xduplicateLogs;
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('DupLog_Before.',true);
		AbstractTrigger.setBooleanSettings('DupLog_After.',true);
		Test.startTest();
		// insert
		DuplicateLogTriggerBefore.processTrigger(null,xduplicateLogs);
		// update
		DuplicateLogTriggerBefore.processTrigger(new Map<Id,DuplicateLog__c>(xduplicateLogs),xduplicateLogs);
		// delete
		DuplicateLogTriggerBefore.processTrigger(new Map<Id,DuplicateLog__c>(xduplicateLogs),null);
		Test.stopTest();
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('DuplicateLog_Before.');
	}

	@isTest
	static void deployTest() {
		List<DuplicateLog__c> xduplicateLogs = new List<DuplicateLog__c>();
		// we'll use user id's instead of addresses, because we are only checking the trigger invocation for exceptions
		List<User> users = [select Id from User where IsActive = true and ProfileId = :UserInfo.getProfileId() limit 2];
		AccountMergeBatchable.addToLog(xduplicateLogs,users[0].Id,users[1].Id,'Address','Account Merge');
		insert xduplicateLogs;
		AbstractTriggerTest.deployTest('DuplicateLog_Before.',xduplicateLogs);
	}
}