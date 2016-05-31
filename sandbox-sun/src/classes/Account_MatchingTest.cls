/**
 * This is the test class for Account_Matching.
 *
 * @version 2015-05-21
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-05-21 - Updated to test contacts on different accounts
 * 2015-04-20 - Revised test to include a bill to partner being remapped to a bill to sales account
 * 2015-04-15 - Updated for aggressive partner filtering tests
 * 2015-01-27 - Changed Bill-To Account record type to APAC Partner 
 * 2015-01-09 - update account matching tests
 * 2014-12-05 - created
 */
@isTest
public class Account_MatchingTest extends Account_Matching {
	static Integer OPPORTUNITIES_SIZE = 4;
	static Integer EBS_ACCOUNTS_SIZE = 6;
	static Integer ACCOUNTS_SIZE = OPPORTUNITIES_SIZE+EBS_ACCOUNTS_SIZE;
	static Integer ADDRESSES_SIZE = EBS_ACCOUNTS_SIZE;
	static Integer CONTACTS_SIZE = EBS_ACCOUNTS_SIZE;
	static Integer PRODUCTS_SIZE = 1;

	static Map<String,List<CDH_Party__c>> partiesMap {
		get {
			if(partiesMap == null) {
				List<CDH_Party__c> parties0 = new List<CDH_Party__c>();
				for(Integer i=0;i++ < CONTACTS_SIZE;) {
					CDH_Party__c p = new CDH_Party__c(
						Name = 'CONTACT-'+i,
						CDH_Party_Name__c = 'CONTACT-'+i,
						CDH_Party_Number_Ext__c = 'CONTACT-'+i,
						CDH_Party_Type__c = 'PERSON');
					parties0.add(p);
				}
				for(Integer i=0;i++ < ACCOUNTS_SIZE;) {
					CDH_Party__c p = new CDH_Party__c(
						Name = 'ACCOUNT-'+i,
						CDH_Party_Name__c = 'ACCOUNT-'+i,
						CDH_Party_Number_Ext__c = 'ACCOUNT-'+i,
						CDH_Party_Type__c = 'ORGANIZATION');
					parties0.add(p);
				}
				insert parties0;
				partiesMap = new Map<String,List<CDH_Party__c>>();
				for(CDH_Party__c party : [
					select 
						Name,
						CDH_Party_Name__c,
						CDH_Party_Number_Ext__c,
						CDH_Party_Type__c
					from CDH_Party__c
					where Id in :(new Map<Id,CDH_Party__c>(parties0).keySet()) 
					order by CDH_Party_Type__c desc, Name ] )
				{
					String partyType = (''+party.CDH_Party_Type__c).toUpperCase();
					List<CDH_Party__c>  cdhParties = partiesMap.get(partyType);
					if(cdhParties == null) {
						cdhParties = new List<CDH_Party__c>();
						partiesMap.put(partyType,cdhParties);
					}
					cdhParties.add(party);
				}
			}
			return partiesMap;
		}
		set;
	}

	static List<Account> accounts {
		get {
			if(accounts == null) {
				Account a = TestUtil.getAccount('Test Account 01');
				List<CDH_Party__c> organizationParties = partiesMap.get('ORGANIZATION');
				a.CDH_Party_Name__c = organizationParties[0].Id;
				a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
				accounts = new List<Account>{a};
				Account p = a.clone();
				p.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Partner').getRecordTypeId();
				List<Account> partners = new List<Account>{p};
				for(Integer i=2,j=1; i <= ACCOUNTS_SIZE;) {
					String s = (''+(100+i++)).substring(1);
					Account b = a.clone();
					b.Name = 'Test Account '+s;
					b.CDH_Party_Name__c = organizationParties[j++].Id;
					accounts.add(b);
					Account c = p.clone();
					c.Name = 'Test Partner '+s;
					c.CDH_Party_Name__c = b.CDH_Party_Name__c;
					partners.add(c);
				}
				accounts.addAll(partners);
			}
			return accounts;
		}
		set;
	}

	static Map<Id,Account> accountMap {
		get {
			if(accountMap == null) {
				accountMap = new Map<Id,Account>();
				upsert accounts;
				accountMap.putAll(accounts);
			}
			return accountMap;
		}
		set;
	}

	public static List<Opportunity> opportunities {
		get {
			if(opportunities == null) {
				opportunities = new List<Opportunity>();
				Opportunity opp = TestUtil.getOpportunity('Opportunity Name' ,new Account());
				for(Integer i = 0;i < OPPORTUNITIES_SIZE;) {
					Account a = accounts[i++];
					Opportunity o = opp.clone();
					o.Name = 'Opportunity Name '+i;
					o.Account = a;
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
				System.assert(! accountMap.isEmpty());
				for(Opportunity o : opportunities) {
					o.AccountId = o.account.Id;
					if(o.Bill_To_Sales_Account__r != null) {
						o.Bill_To_Sales_Account__c = o.Bill_To_Sales_Account__r.Id;
					}
					if(o.Entitle_To_Sales_Account__r != null) {
						o.Entitle_To_Sales_Account__c = o.Entitle_To_Sales_Account__r.Id;
					}
					if(o.Ship_To_Sales_Account__r != null) {
						o.Ship_To_Sales_Account__c = o.Ship_To_Sales_Account__r.Id;
					}
					if(o.Sold_To_Sales_Account__r != null) {
						o.Sold_To_Sales_Account__c = o.Sold_To_Sales_Account__r.Id;
					}
					if(o.Bill_To_Account__r != null) {
						o.Bill_To_Account__c = o.Bill_To_Account__r.Id;
					}
					if(o.Entitle_To_Account__r != null) {
						o.Entitle_To_Account__c = o.Entitle_To_Account__r.Id;
					}
					if(o.Ship_To_Account__r != null) {
						o.Ship_To_Account__c = o.Ship_To_Account__r.Id;
					}
					if(o.Sold_To_Account__r != null) {
						o.Sold_To_Account__c = o.Sold_To_Account__r.Id;
					}
					if(o.Bill_To_Address__r != null) {
						o.Bill_To_Address__c = o.Bill_To_Address__r.Id;
					}
					if(o.Entitle_To_Address__r != null) {
						o.Entitle_To_Address__c = o.Entitle_To_Address__r.Id;
					}
					if(o.Ship_To_Address__r != null) {
						o.Ship_To_Address__c = o.Ship_To_Address__r.Id;
					}
					if(o.Sold_To_Address__r != null) {
						o.Sold_To_Address__c = o.Sold_To_Address__r.Id;
					}
					if(o.Bill_To_Contact__r != null) {
						o.Bill_To_Contact__c = o.Bill_To_Contact__r.Id;
					}
					if(o.Entitle_To_Contact__r != null) {
						o.Entitle_To_Contact__c = o.Entitle_To_Contact__r.Id;
					}
					if(o.Ship_To_Contact__r != null) {
						o.Ship_To_Contact__c = o.Ship_To_Contact__r.Id;
					}
					if(o.Sold_To_Contact__r != null) {
						o.Sold_To_Contact__c = o.Sold_To_Contact__r.Id;
					}
				}
				upsert opportunities;
				opportunityMap.putAll(opportunities);
			}
			return opportunityMap;
		}
		set;
	}

	public static List<EBS_Account__c> partnerEBSAccounts {
		get {
			if(partnerEBSAccounts == null) {
				List<EBS_Account__c> dummy = ebsAccounts;
			}
			return partnerEBSAccounts;
		}
		set;
	}

	public static List<EBS_Account__c> ebsAccounts {
		get {
			if(ebsAccounts == null) {
				ebsAccounts = new List<EBS_Account__c>();
				partnerEBSAccounts = new List<EBS_Account__c>();
				EBS_Account__c ebsAccount = TestUtil.getEBSAcc('',null,'');
				for(Integer i=0;i < EBS_ACCOUNTS_SIZE-1;) {
					Account a = accounts[i+OPPORTUNITIES_SIZE];
					Account p = accounts[i+OPPORTUNITIES_SIZE+ACCOUNTS_SIZE];
					String s=(''+(100+i++)).substring(1);
					EBS_Account__c e = ebsAccount.clone();
					e.Sales_Account__r = a;
					e.Name = 'EBS '+a.Name+'-'+s;
					e.CDH_Party_Number__c = 'EBS-'+s;
					ebsAccounts.add(e);
					e = e.clone();
					e.Sales_Account__r = p;
					partnerEBSAccounts.add(e);
				}
				ebsAccounts.addAll(partnerEBSAccounts);
			}
			return ebsAccounts;
		}
		set;
	}

	public static Map<Id,EBS_Account__c> ebsAccountMap {
		get {
			if(ebsAccountMap == null) {
				ebsAccountMap = new Map<Id,EBS_Account__c>();
				System.assert(! accountMap.isEmpty());
				for(EBS_Account__c e : ebsAccounts) {
					e.Sales_Account__c = e.Sales_Account__r.Id;
				}
				upsert ebsAccounts;
				ebsAccountMap.putAll(ebsAccounts);
			}
			return ebsAccountMap;
		}
		set;
	}

	public static List<Address__c> addresses {
		get {
			if(addresses == null) {
				addresses = new List<Address__c>();
				Address__c address = TestUtil.getAddress('',null);
				address.Address_Line1__c = 'Test Address Line 1';
				address.Address_Line2__c = 'Test Address Line 2';
				address.Address_Line3__c = 'Test Address Line 3';
				address.Address_Line4__c = 'Test Address Line 4';
				address.City__c = 'Hamilton';
				address.State__c = 'Ontario';
				address.Country__c = 'CA';
				address.Zip_Postal_Code__c = 'L8J 3S8';
				for(Integer i=0;i++ < ADDRESSES_SIZE-1;) {
					Account a = accounts[i+OPPORTUNITIES_SIZE-1];
					Address__c address1 = address.clone();
					address1.Sales_Account__r = a;
					address1.Address_Line1__c = 'ADR '+i+address.Address_Line1__c+' : '+i;
					address1.CDH_Party_Site_Number__c = 'ADR-'+i;
					addresses.add(address1);
				}
				address = addresses[0].clone();
				address.Sales_Account__r = accounts[OPPORTUNITIES_SIZE+ADDRESSES_SIZE-1];
				addresses.add(address);
			}
			return addresses;
		}
		set;
	}

	public static Map<Id,Address__c> addressMap {
		get {
			if(addressMap == null) {
				addressMap = new Map<Id,Address__c>();
				System.assert(! accountMap.isEmpty());
				for(Address__c a : addresses) {
					a.Sales_Account__c = a.Sales_Account__r.Id;
				}
				upsert addresses;
				addressMap.putAll(addresses);
			}
			return addressMap;
		}
		set;
	}

	public static List<Contact> contacts {
		get {
			if(contacts == null) {
				contacts = new List<Contact>();
				List<CDH_Party__c> personParties = partiesMap.get('PERSON');
				Contact contact = TestUtil.getContact('',new Account());
				for(Integer i=0;i < CONTACTS_SIZE - 1;i++) {
					Account p = accounts[i+OPPORTUNITIES_SIZE+ACCOUNTS_SIZE];
					Contact c = contact.clone();
					c.Account = p;
					c.FirstName = 'CONTACT '+p.Name;
					c.CDH_Party__r = personParties[i];
					c.Email = 'test'+i+'@nowhere.com';
					contacts.add(c);
				}
			}
			return contacts;
		}
		set;
	}

	public static Map<Id,Contact> contactMap {
		get {
			if(contactMap == null) {
				contactMap = new Map<Id,Contact>();
				System.assert(! accountMap.isEmpty());
				for(Contact c : contacts) {
					c.AccountId = c.Account.Id;
					c.CDH_Party__c = c.CDH_Party__r.Id;
					System.assertNotEquals(null,c.AccountId);
					System.assertNotEquals(null,c.CDH_Party__c);
				}
				upsert contacts;
				contactMap.putAll(contacts);
			}
			return contactMap;
		}
		set;
	}

	public static Id pricebookId {
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

	public static Pricebook2 customPB {
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
					if(lineItem.Entitle_To_Sales_Account__r != null) {
						lineItem.Entitle_To_Sales_Account__c = lineItem.Entitle_To_Sales_Account__r.Id;
					}
					if(lineItem.Entitle_To_Account__r != null) {
						lineItem.Entitle_To_Account__c = lineItem.Entitle_To_Account__r.Id;
					}
					if(lineItem.Entitle_To_Address__r != null) {
						lineItem.Entitle_To_Address__c = lineItem.Entitle_To_Address__r.Id;
					}
					if(lineItem.Entitle_To_Contact__r != null) {
						lineItem.Entitle_To_Contact__c = lineItem.Entitle_To_Contact__r.Id;
					}
				}
				upsert opportunityLineItems;
				opportunityLineItemMap.putAll(opportunityLineItems);
			}
			return opportunityLineItemMap;
		}
		set;
	}

	static final Map<AccountToType,String> EBS_ACCOUNT_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>'TEST01',
		AccountToType.SHIP_TO=>'TEST05',
		AccountToType.SOLD_TO=>'TEST09',
		AccountToType.ENTITLE_TO=>'TEST13',
		AccountToType.LINE_ENTITLE_TO=>'TEST17' };
	static final Map<AccountToType,String> ADDRESS_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>'TEST02',
		AccountToType.SHIP_TO=>'TEST06',
		AccountToType.SOLD_TO=>'TEST10',
		AccountToType.ENTITLE_TO=>'TEST14',
		AccountToType.LINE_ENTITLE_TO=>'TEST18' };
	static final Map<AccountToType,String> CONTRACT_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>'TEST03',
		AccountToType.SHIP_TO=>'TEST07',
		AccountToType.SOLD_TO=>'TEST11',
		AccountToType.ENTITLE_TO=>'TEST15',
		AccountToType.LINE_ENTITLE_TO=>'TEST19' };
	static final Map<AccountToType,String> SALES_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>'TEST04',
		AccountToType.SHIP_TO=>'TEST08',
		AccountToType.SOLD_TO=>'TEST12',
		AccountToType.ENTITLE_TO=>'TEST16',
		AccountToType.LINE_ENTITLE_TO=>'TEST20' };
	static final Map<AccountToType,String> PARTNER_ERROR_MAP = new Map<AccountToType,String>{
		AccountToType.BILL_TO=>'TEST41',
		AccountToType.SHIP_TO=>'TEST42',
		AccountToType.SOLD_TO=>'TEST43',
		AccountToType.ENTITLE_TO=>'TEST44',
		AccountToType.LINE_ENTITLE_TO=>'TEST45' };

	Account_MatchingTest( List<PartyData> partyList ) {
		super( true,
			partyList,
			EBS_ACCOUNT_ERROR_MAP,
			ADDRESS_ERROR_MAP,
			CONTRACT_ERROR_MAP,
			SALES_ERROR_MAP,
			EBS_ACCOUNT_ERROR_MAP,
			ADDRESS_ERROR_MAP,
			null,
			PARTNER_ERROR_MAP );
		Account_Matching.MIN_FILTER_SIZE = 1;
		System.assert(true,this.allowContactOnDifferentAccount);
		this.allowContactOnDifferentAccount = true;
		System.assert(true,this.allowContactOnDifferentAccount);
	}

	@isTest
	static void singleMatchTests() {
		System.assert(! ebsAccountMap.isEmpty());
		EBS_Account__c billToEBS = ebsAccounts[0];
		EBS_Account__c entitleToEBS = ebsAccounts[1];
		EBS_Account__c shipToEBS = ebsAccounts[2];
		EBS_Account__c soldToEBS = ebsAccounts[3];
		EBS_Account__c billToEBS2 = ebsAccounts[5];
		opportunities[0].Bill_To_Sales_Account__r = billToEBS2.Sales_Account__r;
		opportunities[0].Bill_To_Account__r = billToEBS2;
		opportunities[0].Entitle_To_Sales_Account__r = entitleToEBS.Sales_Account__r;
		opportunities[0].Entitle_To_Account__r = entitleToEBS;
		opportunities[0].Ship_To_Sales_Account__r = shipToEBS.Sales_Account__r;
		opportunities[0].Ship_To_Account__r = shipToEBS;
		opportunities[0].Sold_To_Sales_Account__r = soldToEBS.Sales_Account__r;
		opportunities[0].Sold_To_Account__r = soldToEBS;
		System.assert(! addressMap.isEmpty());
		Address__c billToAddress = addresses[0];
		Address__c entitleToAddress = addresses[1];
		Address__c shipToAddress = addresses[2];
		Address__c soldToAddress = addresses[3];
		Address__c billToAddress2 = addresses[5];
		opportunities[0].Bill_To_Address__r = billToAddress;
		opportunities[0].Entitle_To_Address__r = entitleToAddress;
		opportunities[0].Ship_To_Address__r = shipToAddress;
		opportunities[0].Sold_To_Address__r = soldToAddress;
		System.assert(! contactMap.isEmpty());
		Contact billToContact = contacts[0];
		Contact entitleToContact = contacts[1];
		Contact shipToContact = contacts[2];
		Contact soldToContact = contacts[3];
		opportunities[0].Bill_To_Contact__r = billToContact;
		opportunities[0].Entitle_To_Contact__r = entitleToContact;
		opportunities[0].Ship_To_Contact__r = shipToContact;
		opportunities[0].Sold_To_Contact__r = soldToContact;

		System.assert(! opportunityMap.isEmpty());
		EBS_Account__c lineEntitleToEBS = ebsAccounts[4];
		opportunityLineItems[0].Entitle_To_Sales_Account__r = lineEntitleToEBS.Sales_Account__r;
		opportunityLineItems[0].Entitle_To_Account__r = lineEntitleToEBS;
		Address__c lineEntitleToAddress = addresses[4];
		opportunityLineItems[0].Entitle_To_Address__r = lineEntitleToAddress;
		Contact lineEntitleToContact = contacts[4];
		opportunityLineItems[0].Entitle_To_Contact__r = lineEntitleToContact;
		System.assert(! opportunityLineItemMap.isEmpty());

		List<PartyData> partyDataList = new List<PartyData>{
			// based on CDH numbers, except contacts based on e-mail
			new PartyData( // scenario 0
				AccountToType.BILL_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				billToEBS2.Name,
				billToEBS2.CDH_Party_Number__c, // String cdhPartyNumber,
				billToAddress2.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				'EMEA', // String superRegion,
				'INVALID', // String country,
				billToContact.Email ), // String email )
			new PartyData( // scenario 1
				AccountToType.ENTITLE_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				entitleToEBS.Name,
				entitleToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				entitleToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				'EMEA', // String superRegion,
				'INVALID', // String country,
				entitleToContact.Email ), // String email )
			new PartyData( // scenario 2
				AccountToType.SHIP_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				shipToEBS.Name,
				shipToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				shipToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				'EMEA', // String superRegion,
				'INVALID', // String country,
				shipToContact.Email), // String email )
			new PartyData( // scenario 3
				AccountToType.SOLD_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				soldToEBS.Name,
				soldToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				soldToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				'EMEA', // String superRegion,
				'INVALID', // String country,
				soldToContact.Email), // String email )
			new PartyData( // scenario 4
				AccountToType.LINE_ENTITLE_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				lineEntitleToEBS.Name,
				lineEntitleToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				lineEntitleToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				'EMEA', // String superRegion,
				'INVALID', // String country,
				lineEntitleToContact.Email ), // String email )
			// based on opportunity id
			new PartyData( // scenario 5
				AccountToType.BILL_TO, // AccountToType toType,
				opportunities[0].Id, // Id refOppId,
				null, // Id refOppLineId,
				null,
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				'APAC', // String superRegion,
				addresses[0].Country__c, // String country,
				contacts[0].Email), // String email )
			new PartyData( // scenario 6
				AccountToType.ENTITLE_TO, // AccountToType toType,
				opportunities[0].Id, // Id refOppId,
				null, // Id refOppLineId,
				null,
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				'APAC', // String superRegion,
				addresses[0].Country__c, // String country,
				contacts[0].Email), // String email )
			new PartyData( // scenario 7
				AccountToType.SHIP_TO, // AccountToType toType,
				opportunities[0].Id, // Id refOppId,
				null, // Id refOppLineId,
				null,
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				'APAC', // String superRegion,
				addresses[0].Country__c, // String country,
				contacts[0].Email), // String email )
			new PartyData( // scenario 8
				AccountToType.SOLD_TO, // AccountToType toType,
				opportunities[0].Id, // Id refOppId,
				null, // Id refOppLineId,
				null,
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				'APAC', // String superRegion,
				addresses[0].Country__c, // String country,
				contacts[0].Email), // String email )
			new PartyData( // scenario 9
				AccountToType.LINE_ENTITLE_TO, // AccountToType toType,
				opportunities[0].Id, // Id refOppId,
				opportunityLineItems[0].Id, // Id refOppLineId,
				null,
				null, // String cdhPartyNumber,
				null, // String cdhPartySiteNumber,
				null, // String contactCDHPartyNumber,
				'APAC', // String superRegion,
				addresses[0].Country__c, // String country,
				contacts[0].Email), // String email )
			// based on CDH numbers without an opportunity id
			new PartyData( // scenario 10
				AccountToType.BILL_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				billToEBS2.Name,
				billToEBS2.CDH_Party_Number__c, // String cdhPartyNumber,
				billToAddress2.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				billToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				'EMEA', // String superRegion,
				'INVALID', // String country,
				'INVALID'), // String email )
			new PartyData( // scenario 11
				AccountToType.ENTITLE_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				entitleToEBS.Name,
				entitleToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				entitleToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				entitleToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				'EMEA', // String superRegion,
				'INVALID', // String country,
				'INVALID'), // String email )
			new PartyData( // scenario 12
				AccountToType.SHIP_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				shipToEBS.Name,
				shipToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				shipToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				shipToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				'EMEA', // String superRegion,
				'INVALID', // String country,
				'INVALID'), // String email )
			new PartyData( // scenario 13
				AccountToType.SOLD_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				soldToEBS.Name,
				soldToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				soldToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				soldToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				'EMEA', // String superRegion,
				'INVALID', // String country,
				'INVALID'), // String email )
			new PartyData( // scenario 14
				AccountToType.LINE_ENTITLE_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				lineEntitleToEBS.Name,
				lineEntitleToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				lineEntitleToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				lineEntitleToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				'EMEA', // String superRegion,
				'INVALID', // String country,
				'INVALID'), // String email )
			// based on CDH number with an opportunity id
			new PartyData( // scenario 15
				AccountToType.BILL_TO, // AccountToType toType,
				opportunities[1].Id, // Id refOppId
				null, // Id refOppLineId,
				billToEBS2.Name,
				billToEBS2.CDH_Party_Number__c, // String cdhPartyNumber,
				billToAddress2.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				billToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				'JAPAN', // String superRegion,
				null, // String country,
				null), // String email )
			new PartyData( // scenario 16
				AccountToType.ENTITLE_TO, // AccountToType toType,
				opportunities[1].Id, // Id refOppId
				null, // Id refOppLineId,
				entitleToEBS.Name,
				entitleToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				entitleToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				entitleToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				'JAPAN', // String superRegion,
				null, // String country,
				null), // String email )
			new PartyData( // scenario 17
				AccountToType.SHIP_TO, // AccountToType toType,
				opportunities[1].Id, // Id refOppId
				null, // Id refOppLineId,
				shipToEBS.Name,
				shipToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				shipToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				shipToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				'JAPAN', // String superRegion,
				null, // String country,
				null), // String email )
			new PartyData( // scenario 18
				AccountToType.SOLD_TO, // AccountToType toType,
				opportunities[1].Id, // Id refOppId
				null, // Id refOppLineId,
				soldToEBS.Name,
				soldToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				soldToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				soldToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				'JAPAN', // String superRegion,
				null, // String country,
				null), // String email )
			new PartyData( // scenario 19
				AccountToType.LINE_ENTITLE_TO, // AccountToType toType,
				opportunities[1].Id, // Id refOppId
				opportunityLineItems[products.size()].Id, // Id refOppLineId,
				lineEntitleToEBS.Name,
				lineEntitleToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				lineEntitleToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				lineEntitleToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				'JAPAN', // String superRegion,
				null, // String country,
				null), // String email )
			// based on opportunity id with incorrect CDH numbers 
			new PartyData( // scenario 20
				AccountToType.BILL_TO, // AccountToType toType,
				opportunities[0].Id, // Id refOppId
				null, // Id refOppLineId,
				entitleToEBS.Name,
				entitleToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				entitleToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				entitleToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null), // String email )
			new PartyData( // scenario 21
				AccountToType.ENTITLE_TO, // AccountToType toType,
				opportunities[0].Id, // Id refOppId
				null, // Id refOppLineId,
				shipToEBS.Name,
				shipToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				shipToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				shipToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null), // String email )
			new PartyData( // scenario 22
				AccountToType.SHIP_TO, // AccountToType toType,
				opportunities[0].Id, // Id refOppId
				null, // Id refOppLineId,
				soldToEBS.Name,
				soldToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				soldToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				soldToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null), // String email )
			new PartyData( // scenario 23
				AccountToType.SOLD_TO, // AccountToType toType,
				opportunities[0].Id, // Id refOppId
				null, // Id refOppLineId,
				lineEntitleToEBS.Name,
				lineEntitleToEBS.CDH_Party_Number__c, // String cdhPartyNumber,
				lineEntitleToAddress.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				lineEntitleToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null), // String email )
			new PartyData( // scenario 24
				AccountToType.LINE_ENTITLE_TO, // AccountToType toType,
				opportunities[0].Id, // Id refOppId
				opportunityLineItems[0].Id, // Id refOppLineId,
				billToEBS2.Name,
				billToEBS2.CDH_Party_Number__c, // String cdhPartyNumber,
				billToAddress2.CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				billToContact.CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null) }; // String email )
		Account_Matching accountMatching = new Account_MatchingTest(partyDataList);

		Test.startTest();
		accountMatching.match();

		Set<String> contactCDHPartyNumbers = accountMatching.getContactCDHPartyNumbers();
		System.assert(contactCDHPartyNumbers.contains(billToContact.CDH_Party__r.CDH_Party_Number_Ext__c));
		System.assert(contactCDHPartyNumbers.contains(entitleToContact.CDH_Party__r.CDH_Party_Number_Ext__c));
		System.assert(contactCDHPartyNumbers.contains(shipToContact.CDH_Party__r.CDH_Party_Number_Ext__c));
		System.assert(contactCDHPartyNumbers.contains(soldToContact.CDH_Party__r.CDH_Party_Number_Ext__c));
		System.assert(contactCDHPartyNumbers.contains(lineEntitleToContact.CDH_Party__r.CDH_Party_Number_Ext__c));

		System.assert(accountMatching.contactsKeyMap.containsKey(Account_Matching.cdhPartyNumberKey(billToContact.CDH_Party__r.CDH_Party_Number_Ext__c)));
		System.assert(accountMatching.contactsKeyMap.containsKey(Account_Matching.cdhPartyNumberKey(entitleToContact.CDH_Party__r.CDH_Party_Number_Ext__c)));
		System.assert(accountMatching.contactsKeyMap.containsKey(Account_Matching.cdhPartyNumberKey(shipToContact.CDH_Party__r.CDH_Party_Number_Ext__c)));
		System.assert(accountMatching.contactsKeyMap.containsKey(Account_Matching.cdhPartyNumberKey(soldToContact.CDH_Party__r.CDH_Party_Number_Ext__c)));
		System.assert(accountMatching.contactsKeyMap.containsKey(Account_Matching.cdhPartyNumberKey(lineEntitleToContact.CDH_Party__r.CDH_Party_Number_Ext__c)));

		for(Integer i = 0; i < partyDataList.size();i++) {
			PartyData m = partyDataList.get(i);
			System.assertNotEquals(null,m.getBestEBSAccount(),'A. Failed best EBS scenario '+i);
			System.debug('A. BestEBSAccount['+i+']='+m.getBestEBSAccount());
			System.debug('A. EBSAccount['+i+']='+m.getEBSAccount());
			System.assertNotEquals(null,m.getBestAddress(true),'A. Failed best Address scenario '+i);
			System.debug('A. BestAddress['+i+']='+m.getBestAddress(true));
			System.debug('A. Address['+i+']='+m.getAddress());
			if(i < 5) {
				System.assertEquals(null,m.getBestContact(true),'A. Failed best Contact scenario '+i);
			}
			else {
				System.assertNotEquals(null,m.getBestContact(true),'A. Failed best Contact scenario '+i);
			}
			System.debug('A. BestContact['+i+']='+m.getBestContact(true));
			System.debug('A. Contact['+i+']='+m.getContact());
		}
		accountMatching.filter();

		for(Integer i = 0; i < partyDataList.size();i++) {
			PartyData m = partyDataList.get(i);
			System.assertNotEquals(null,m.getBestEBSAccount(),'B. Failed best EBS scenario '+i);
			System.assertEquals(m.getBestEBSAccount(),m.getEBSAccount(),'B. Failed EBS scenario '+i);
			System.debug('B. BestEBSAccount['+i+']='+m.getBestEBSAccount());
			System.debug('B. EBSAccount['+i+']='+m.getEBSAccount());
			System.assertNotEquals(null,m.getBestAddress(true),'B. Failed best Address scenario '+i);
			System.assertEquals(m.getBestAddress(true),m.getAddress(),'B. Failed Address scenario '+i);
			System.debug('B. BestAddress['+i+']='+m.getBestAddress(true));
			System.debug('B. Address['+i+']='+m.getAddress());
			if(i < 5) {
				System.assertEquals(null,m.getBestContact(true),'B. Failed best Contact scenario '+i);
				System.assertEquals(null,m.getContact(),'B. Failed Contact scenario '+i);
			}
			else {
				System.assertNotEquals(null,m.getBestContact(true),'B. Failed best Contact scenario '+i);
				System.assertEquals(m.getBestContact(true),m.getContact(),'B. Failed Contact scenario '+i);
			}
			System.debug('B. BestContact['+i+']='+m.getBestContact(true));
			System.debug('B. Contact['+i+']='+m.getContact());
			Map<Id,Map<Id,EBS_Account__c>> ebsAccountMapMap = m.ebsAccountMapMap;
			m.ebsAccountMapMap = new Map<Id,Map<Id,EBS_Account__c>>();
			System.debug('B. BestContact['+i+']='+m.getBestContact(true));
			m.ebsAccountMapMap = ebsAccountMapMap;
		}

		// check the results
		Integer j=0;
		for(EBS_Account__c ebsAccount : new List<EBS_Account__c>{
			billToEBS,entitleToEBS,shipToEBS,soldToEBS,lineEntitleToEBS,
			billToEBS,entitleToEBS,shipToEBS,soldToEBS,lineEntitleToEBS,
			billToEBS,entitleToEBS,shipToEBS,soldToEBS,lineEntitleToEBS,
			billToEBS,entitleToEBS,shipToEBS,soldToEBS,lineEntitleToEBS,
			billToEBS,entitleToEBS,shipToEBS,soldToEBS,lineEntitleToEBS })
		{
			EBS_Account__c e = partyDataList[j].getEBSAccount();
			System.assertNotEquals(null,e,'Expected EBS Account for line '+j);
			System.assertEquals(ebsAccount.Id,e.Id,'Line '+j+'\nExpected: '+ebsAccount+'\nActual: '+e);
			j++;
		}
		j=0;
		for(Address__c address : new List<Address__c>{
			billToAddress,entitleToAddress,shipToAddress,soldToAddress,lineEntitleToAddress,
			billToAddress,entitleToAddress,shipToAddress,soldToAddress,lineEntitleToAddress,
			billToAddress,entitleToAddress,shipToAddress,soldToAddress,lineEntitleToAddress,
			billToAddress,entitleToAddress,shipToAddress,soldToAddress,lineEntitleToAddress,
			billToAddress,entitleToAddress,shipToAddress,soldToAddress,lineEntitleToAddress })
		{
			Address__c a = partyDataList[j].getAddress();
			System.assertNotEquals(null,a,'Expected Address for line '+j);
			System.assertEquals(address.Id,a.Id,'Line '+j+'\nExpected: '+address+'\nActual: '+a);
			j++;
		}
		j=5;
		for(Contact contact : new List<Contact>{
			billToContact,entitleToContact,shipToContact,soldToContact,lineEntitleToContact,
			billToContact,entitleToContact,shipToContact,soldToContact,lineEntitleToContact,
			billToContact,entitleToContact,shipToContact,soldToContact,lineEntitleToContact,
			billToContact,entitleToContact,shipToContact,soldToContact,lineEntitleToContact })
		{
			Contact c = partyDataList[j].getContact();
			System.assertNotEquals(null,c,'Expected Contact for line '+j);
			System.assertEquals(contact.Id,c.Id,'Line '+j+'\nExpected: '+contact+'\nActual: '+c);
			j++;
		}

		// might as well perform the rest of the tests
		accountMatching.filter();
		for(Integer i = 0; i < partyDataList.size();i++) {
			PartyData m = partyDataList.get(i);
			System.assertNotEquals(null,m.getEBSAccount(),'Failed EBS scenario '+i);
			System.assertNotEquals(null,m.getAddress(),'Failed Address scenario '+i);
//			System.assertNotEquals(null,m.getContact(),'Failed Contact scenario '+i);
		}

//		System.assertEquals(billToContact.Id,partyDataList[0].getBestContact().Id);
//		System.assertEquals(entitleToContact.Id,partyDataList[1].getBestContact().Id);
//		System.assertEquals(shipToContact.Id,partyDataList[2].getBestContact().Id);
//		System.assertEquals(soldToContact.Id,partyDataList[3].getBestContact().Id);
//		System.assertEquals(lineEntitleToContact.Id,partyDataList[4].getBestContact().Id);

		accountMatching.errorReporting();
		for(Integer i = 0; i < partyDataList.size();i++) {
			PartyData m = partyDataList.get(i);
			System.assertNotEquals(null,m.getEBSAccount(),'Failed EBS scenario '+i);
			System.assertNotEquals(null,m.getAddress(),'Failed Address scenario '+i);
//			System.assertNotEquals(null,m.getContact(),'Failed Contact scenario '+i);
			System.assertNotEquals('',m.getAllMessages());
		}
		// for coverage
		accountMatching.findContactsByEmail();
		Set<Id> cdhPartyIds = new Set<Id>();
		Set<Id> accountIds = new Set<Id>(accountMatching.accountMap.keySet());
		for(Account a : accounts) {
			cdhPartyIds.add(a.CDH_Party_Name__c);
		}
		for(Integer i = 0; i < partyDataList.size();i++) {
			PartyData m = partyDataList.get(i);
			m.retainCDHPartyIds(cdhPartyIds);
			m.filterCDHPartyIds(cdhPartyIds,cdhPartyIds.iterator().next());
			m.retainAccountIds(accountIds);
			m.filterAccountIds(accountIds,accountIds.iterator().next());
			m.filterBySuperRegion(accountMatching.accountMap);
			m.filterByCountry();
		}
		Test.stopTest();
	}

	@isTest
	static void contactEmailSuffixTest() {
		StringSetting__c s = new StringSetting__c(Name=Account_Matching.CONTACT_EMAIL_SUFFIX_SETTING,Value__c='.test');
		upsert s;
		System.assertEquals('.test',Account_Matching.CONTACT_EMAIL_SUFFIX);
	}

	@isTest
	static void errorTests() {
		List<PartyData> partyDataList = new List<PartyData>{
			new PartyData(
				AccountToType.SOLD_TO, // AccountToType toType,
				null, // Id refOppId
				null, // Id refOppLineId,
				ebsAccounts[0].Name,
				ebsAccounts[0].CDH_Party_Number__c, // String cdhPartyNumber,
				addresses[0].CDH_Party_Site_Number__c, // String cdhPartySiteNumber,
				contacts[0].CDH_Party__r.CDH_Party_Number_Ext__c, // String contactCDHPartyNumber,
				null, // String superRegion,
				null, // String country,
				null) }; // String email )
		// we are not going to insert any of this data, so the mapping will fail.
		Account_Matching accountMatching = new Account_MatchingTest(partyDataList);

		Test.startTest();
		accountMatching.match();

		for(Integer i = 0; i < partyDataList.size();i++) {
			PartyData m = partyDataList.get(i);
			System.assertEquals(null,m.getEBSAccount(),'Failed EBS scenario '+i);
			System.assertEquals(null,m.getAddress(),'Failed Address scenario '+i);
			System.assertEquals(null,m.getContact(),'Failed Contact scenario '+i);
		}

		accountMatching.filter();
		for(Integer i = 0; i < partyDataList.size();i++) {
			PartyData m = partyDataList.get(i);
			System.assertEquals(null,m.getEBSAccount(),'Failed EBS scenario '+i);
			System.assertEquals(null,m.getAddress(),'Failed Address scenario '+i);
			System.assertEquals(null,m.getContact(),'Failed Contact scenario '+i);
		}

		accountMatching.errorReporting();
		for(Integer i = 0; i < partyDataList.size();i++) {
			PartyData m = partyDataList.get(i);
			System.assertEquals(null,m.getEBSAccount(),'Failed EBS scenario '+i);
			System.assertEquals(null,m.getAddress(),'Failed Address scenario '+i);
			System.assertEquals(null,m.getContact(),'Failed Contact scenario '+i);
			System.assertEquals('TEST09\nTEST10\nTEST11',m.getAllMessages());
			System.assertEquals('TEST09\nTEST10\nTEST11',m.getErrorMessages());
			System.assertEquals('TEST09',m.getFirstMessage());
			m.warnMessages.add('WARN01');
			System.assertEquals('TEST09\nTEST10\nTEST11\nWARN01',m.getAllMessages());
			System.assertEquals('TEST09\nTEST10\nTEST11',m.getErrorMessages());
			System.assertEquals('TEST09',m.getFirstMessage());
			m.errorMessages.clear();
			System.assertEquals('WARN01',m.getAllMessages());
			System.assertEquals(null,m.getErrorMessages());
			System.assertEquals('WARN01',m.getFirstMessage());
		}
		Test.stopTest();
	}
}