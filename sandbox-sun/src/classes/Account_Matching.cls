/**
 * This class templates account matching for customer c360 
 * opportunity fields including Bill-To, Ship-To, Sold-To,
 * Entitle-To, Line Item Entitle-To.
 * 
 * @version 2015-09-23
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-09-23 - revised cdh party number logic to reference sales account when needed
 * 2015-08-24 - Filter addresses and contacts by status
 * 2015-06-18 - created more generic versions of the getCDHPartyIds and getSalesAccountIds methods
 * 2015-06-16 - changed the setRefOpp and setRefOppLine methods to virtual so orders can override these methods
 * 2015-05-19 - Updated to support mapping contacts to different accounts linked to the same CDH Party
 * 2015-04-20 - Revised filter to do all the steps necessary to select the sales account over the partner account
 * 2015-04-15 - Aggressively filter partners and attempt to replace with sales accounts
 * 2015-03-18 - Added a filterEBSByRecordTypeName to filter out partners from matches
 * 2015-02-24 - Added filterAccountIds method
 * 2015-02-12 - Revised for more specific query
 * 2015-01-06 - update account matching logic
 * 2014-12-04 - Corrections based on debugging
 * 2014-11-26 - Created
 */
public abstract with sharing class Account_Matching {
	@TestVisible
	private static Integer MIN_FILTER_SIZE = 2;

	/** Name of a custom setting to specify an e-mail suffix for contacts. */
	public static final String CONTACT_EMAIL_SUFFIX_SETTING = 'Contact.Email.Suffix';

	/** Specifies an e-mail suffix being used by contacts on a sandbox */
	public static String CONTACT_EMAIL_SUFFIX {
		get {
			if(CONTACT_EMAIL_SUFFIX == null) {
				String retval = null;
				StringSetting__c s = StringSetting__c.getInstance(CONTACT_EMAIL_SUFFIX_SETTING);
				if(s != null) {
					CONTACT_EMAIL_SUFFIX = s.Value__c;
				}
				if(CONTACT_EMAIL_SUFFIX == null) {
					CONTACT_EMAIL_SUFFIX = '';
				}
			}
			return CONTACT_EMAIL_SUFFIX;
		}
		set;
	}

	/** The type of accounts one can map. */
	public enum AccountToType { BILL_TO, SHIP_TO, SOLD_TO, ENTITLE_TO, LINE_ENTITLE_TO }

	/** The type of accounts matchings.  Useful for determining ordering */
	public enum AccountMatchType { EBS_MATCH, ADDRESS_MATCH, CONTACT_MATCH }

	/** The type of accounts matchings.  Useful for determining ordering */
	public enum AccountMatchEmptyMode { LEFT_MODE, UNION_MODE, INTERSECT_MODE }

	public static final List<AccountMatchType> EBS_ADDRESS_CONTACT_ORDERING = new List<AccountMatchType>{ AccountMatchType.EBS_MATCH, AccountMatchType.ADDRESS_MATCH, AccountMatchType.CONTACT_MATCH };

	public static final List<AccountMatchType> EBS_ADDRESS_ORDERING = new List<AccountMatchType>{ AccountMatchType.EBS_MATCH, AccountMatchType.ADDRESS_MATCH };

	/** Attempt to remap partner accounts to sales accounts. */
	protected final Boolean preferSalesAccounts;

	/** Map of errors related to best ebs account matching. */
	public final Map<AccountToType,String> ebsAccountErrorMap;

	/** Map of errors related to best address matching. */
	public final Map<AccountToType,String> addressErrorMap;

	/** Map of errors related to best contact matching. */
	public final Map<AccountToType,String> contactErrorMap;

	/** Map of errors related to sales account matching. */
	public final Map<AccountToType,String> salesErrorMap;

	/** Map of errors related to unique ebs account matching. */
	public final Map<AccountToType,String> ebsAccountErrorMap2;

	/** Map of errors related to unique address account matching. */
	public final Map<AccountToType,String> addressErrorMap2;

	/** Map of errors related to unique contact account matching. */
	public final Map<AccountToType,String> contactErrorMap2;

	/** Map of errors when a partner is matched as a sales account. */
	public final Map<AccountToType,String> partnerErrorMap;

	/** List of parties to map */
	protected List<PartyData> partyList;

	/** Allow a contact to be on any account with the same CDH Party Id. */
	protected Boolean allowContactOnDifferentAccount {
		get {
			return (allowContactOnDifferentAccount == true);
		}
		set;
	}


	/**
	 * Protected constructor to take the list of parties and preferences for mapping.
	 * 
	 * @param preferSalesAccounts assign true if partner accounts should be replaced with sales accounts
	 * @param partyList list of all parties to be mapped
	 * @param ebsAccountErrorMap map of errors related to best ebs account matching
	 * @param addressErrorMap map of errors related to best address matching
	 * @param contactErrorMap map of errors related to best address matching
	 * @param salesErrorMap map of errors related to sales account matching
	 * @param ebsAccountErrorMap2 map of errors related to unique ebs account matching
	 * @param addressErrorMap2 map of errors related to unique address matching
	 * @param contactErrorMap2 map of errors related to unique address matching
	 * @param partnerErrorMap map of errors when partner is matched as a sales account
	 */
	protected Account_Matching(
		Boolean preferSalesAccounts,
		List<PartyData> partyList,
		Map<AccountToType,String> ebsAccountErrorMap,
		Map<AccountToType,String> addressErrorMap,
		Map<AccountToType,String> contactErrorMap,
		Map<AccountToType,String> salesErrorMap,
		Map<AccountToType,String> ebsAccountErrorMap2,
		Map<AccountToType,String> addressErrorMap2,
		Map<AccountToType,String> contactErrorMap2,
		Map<AccountToType,String> partnerErrorMap)
	{
		this.preferSalesAccounts = preferSalesAccounts;
		this.partyList = partyList;
		this.ebsAccountErrorMap = ebsAccountErrorMap;
		this.addressErrorMap = addressErrorMap;
		this.contactErrorMap = contactErrorMap;
		this.salesErrorMap = salesErrorMap;
		this.ebsAccountErrorMap2 = ebsAccountErrorMap2;
		this.addressErrorMap2 = addressErrorMap2;
		this.contactErrorMap2 = contactErrorMap2;
		this.partnerErrorMap = partnerErrorMap;
		for(PartyData party : partyList) {
			party.accountMatching = this;
		}
	}

	/**
	 * Method to check if an account is a partner.
	 * @param value account to check
	 * @return true if the referenced account is a partner account.
	 */
	public static Boolean isPartner(Account value) {
		return (value != null && value.RecordType != null && value.RecordType.Name != null && value.RecordType.Name.containsIgnoreCase('PARTNER'));
	}

	/**
	 * Method to check if an ebs account has a partner as a sales account.
	 * @param value ebs account to check
	 * @return true if the referenced sales account is a partner account.
	 */
	public static Boolean isPartner(EBS_Account__c e) {
		return (e != null && isPartner(e.Sales_Account__r));
	}

	/**
	 * Method to check if an address has a partner as a sales account.
	 * @param value address to check
	 * @return true if the referenced sales account is a partner account.
	 */
	public static Boolean isPartner(Address__c a) {
		return (a != null && isPartner(a.Sales_Account__r));
	}

	/**
	 * Method to check if a contact is associated to a sales account.
	 * @param value contact to check
	 * @return true if the contact account is a partner account.
	 */
	public static Boolean isPartner(Contact c) {
		return (c != null && isPartner(c.Account));
	}

	/**
	 * Method to get record type name
	 * @param value account to check
	 * @return the value of of the sales account record type name
	 */
	public static String getAccountRecordTypeName(Account value) {
		String recordTypeName = null;
		if (value != null && value.RecordType != null) {
			recordTypeName = value.RecordType.Name;
		}
		return recordTypeName;
	}

	/**
	 * Method to check if an ebs account has a partner as a sales account.
	 * @param value ebs account to check
	 * @return the value of of the sales account record type name
	 */
	public static String getAccountRecordTypeName(EBS_Account__c e) {
		String recordTypeName = null;
		if(e != null) {
			recordTypeName = getAccountRecordTypeName(e.Sales_Account__r);
		}
		return recordTypeName;
	}

	/**
	 * Method to check if an address has a partner as a sales account.
	 * @param value address to check
	 * @return the value of of the sales account record type name
	 */
	public static String getAccountRecordTypeName(Address__c a) {
		String recordTypeName = null;
		if(a != null) {
			recordTypeName = getAccountRecordTypeName(a.Sales_Account__r);
		}
		return recordTypeName;
	}

	/**
	 * Method to check if a contact is associated to a sales account.
	 * @param value contact to check
	 * @return the value of of the sales account record type name
	 */
	public static String getAccountRecordTypeName(Contact c) {
		String recordTypeName = null;
		if(c != null) {
			recordTypeName = getAccountRecordTypeName(c.Account);
		}
		return recordTypeName;
	}

	/** 
	 * Find the CDH Party Name__c for an account.  If null, return the defaultValue.
	 */
	public static Id getCDHPartyIdFromAccount(Account a,Id defaultValue) {
		if(a != null && a.CDH_Party_Name__c != null) {
			defaultValue = a.CDH_Party_Name__c;
		}
		return defaultValue;
	}

	/**
	 * Populates each of the ebsAccountMapMap, addressMapMap, and contactMapMap on each of the PartyData
	 * instances in the mapping list.  This implements SFDC BR[1-5].PART A for
	 * renewals matching.
	 */
	public void match() {
		for(PartyData m : partyList) {
			m.matchEBSAccount(preferSalesAccounts,ebsAccountMap,ebsAccountsKeyMap);
			m.refAddress = addressMap.get( m.refAddressId );
			m.setAddress( m.refAddress );
			if( m.refAddress == null || (preferSalesAccounts && isPartner(m.refAddress))) {
				for(String cdhPartySiteNumber : m.cdhPartySiteNumbers ) {
					m.addAddresses( addressesKeyMap.get(cdhPartySiteNumberKey(cdhPartySiteNumber)) );
				}
			}
			m.refContact = contactMap.get( m.refContactId );
			m.setContact( m.refContact );
			if( m.refContact == null || (preferSalesAccounts && isPartner(m.refContact))) {
				for(String contactCDHPartyNumber : m.contactCDHPartyNumbers ) {
					m.addContacts( contactsKeyMap.get(cdhPartyNumberKey(contactCDHPartyNumber)) );
				}
			}
		}
	}

	/**
	 * Filter each of the ebsAccountMapMap, addressMapMap, and contactMapMaps based on account numbers,
	 * record types, names, sales account id, cdh party numbers, and status.  Additional filtering may be done 
	 * by overloading this method.
	 */
	public virtual void filter() {
		for(PartyData m : partyList) {
			if(! ebsAccountMap.isEmpty()) {
				System.debug('ebsAccountFiltering '+m.ebsAccountMapMap.size()+', '+MIN_FILTER_SIZE);
				m.refEBSAccount = ebsAccountMap.get( m.refEBSAccountId );
				if( m.refEBSAccount != null && ! (preferSalesAccounts && isPartner(m.refEBSAccount))) {
					m.useRefEBSAccount();
				}
				else {
					// filter all EBS Accounts marked as duplicates
					m.filterEBSByStatus(m.refEBSAccount == null,true);
					m.filterEBSByAccountNumbers();
					m.filterEBSAccounts(preferSalesAccounts);
				}
			}
			if(! addressMap.isEmpty()) {
				m.refAddress = addressMap.get( m.refAddressId );
				if( m.refAddress != null && ! (preferSalesAccounts && isPartner(m.refAddress))) {
					m.useRefAddress();
				}
				else if(! m.addressMapMap.isEmpty()) {
					// filter all Addresses marked as duplicates
					m.filterAddressByStatus(m.refAddress == null,true);
					m.filterAddresses(preferSalesAccounts);
				}
			}
			if(! contactMap.isEmpty()) {
				m.refContact = contactMap.get( m.refContactId );
				if( m.refContact != null && ! (preferSalesAccounts && isPartner(m.refContact))) {
					m.useRefContact();
				}
				else if(! m.contactMapMap.isEmpty()) {
					// filter all Contacts marked as duplicates
					m.filterContactByStatus(m.refContact == null,true);
					m.filterContacts(preferSalesAccounts);
				}
			}
		}
	}

	private static Boolean addErrorMessage(List<String> messages,String message) {
		if(message != null && messages != null) {
			messages.add(message);
		}
		return (message != null);
	}

	public virtual Boolean ebsAccountErrorReporting(PartyData m,List<String> messages,List<String> messages2) {
		Boolean retval = false;
		if(ebsAccountErrorMap != null) {
			if(m.getBestEBSAccount() == null) {
				retval = addErrorMessage(messages,ebsAccountErrorMap.get(m.toType));
			}
			else if (ebsAccountErrorMap2 != null && m.getEBSAccount() == null) {
				retval = addErrorMessage(messages2,ebsAccountErrorMap2.get(m.toType));
			}
		}
		return retval;
	}

	public virtual Boolean addressErrorReporting(PartyData m,List<String> messages,List<String> messages2) {
		Boolean retval = false;
		if(addressErrorMap != null) {
			if(m.getBestAddress(false) == null) {
				retval = addErrorMessage(messages,addressErrorMap.get(m.toType));
			}
			else if (addressErrorMap2 != null && m.getAddress() == null) {
				retval = addErrorMessage(messages2,addressErrorMap2.get(m.toType));
			}
		}
		return retval;
	}

	public virtual Boolean contactErrorReporting(PartyData m,List<String> messages,List<String> messages2) {
		Boolean retval = false;
		if(contactErrorMap != null) {
			if(m.getBestContact(false) == null) {
				retval = addErrorMessage(messages,contactErrorMap.get(m.toType));
			}
			else if (contactErrorMap2 != null && m.getContact() == null) {
				retval = addErrorMessage(messages2,contactErrorMap2.get(m.toType));
			}
		}
		return retval;
	}

	/** 
	 * We consider this a sales error if there is not at least one sales account common for all three objects
	 */
	public virtual Boolean salesErrorReporting(PartyData m,List<String> messages,List<String> messages2) {
		return salesErrorReporting(m,messages,messages2,(m.getBestEBSAccount() == null),(m.getBestAddress(false) == null),(m.getBestContact(false) == null));
	}

	/** 
	 * We consider this a sales error if there is not at least one sales account common for all three objects
	 */
	public Boolean salesErrorReporting(PartyData m,List<String> messages,List<String> messages2,Boolean ebsAccountError,Boolean addressError,Boolean contactError) {
		Boolean salesError = false;
		Set<Id> ids = null;
		if(! ebsAccountError) {
			ids = m.ebsAccountMapMap.keySet().clone();
			if(! addressError) {
				ids.retainAll(m.addressMapMap.keySet());
				salesError = ids.isEmpty();
				if(salesError) {
					String message = salesErrorMap.get(m.toType);
					if(message != null) {
						messages.add(message);
					}
				}
			}
		}
		else if(! addressError) {
			ids = m.addressMapMap.keySet().clone();
		}
		if(! (ids == null || ids.isEmpty() || contactError)) {
			Set<Id> ids2 = ids.clone();
			ids2.retainAll(m.contactMapMap.keySet());
			if(ids2.isEmpty()) {
				Boolean allowContact = false;
				if(allowContactOnDifferentAccount) {
					for(Id accountId : ids) {
						if(! allowContact) {
							Id cdhPartyId = getCDHPartyIdFromAccount(accountMap.get(accountId),null);
							if(cdhPartyId != null) {
								for(Map<Id,Contact> cm : m.contactMapMap.values()) {
									for(Contact c : cm.values()) {
										allowContact = (getCDHPartyIdFromAccount(c.Account,null) == cdhPartyId);
										break;
									}
									if( allowContact ) {
										break;
									}
								}
							}
						}
					}
				}
				if(salesErrorMap != null && ! allowContact ) {
					String message = salesErrorMap.get(m.toType);
					if(message != null) {
						messages2.add(message);
					}
				}
			}
		}
		return salesError;
	}

	public Boolean partnerErrorReporting(PartyData m,List<String> messages) {
		Boolean retval = false;
		EBS_Account__c ebsAccount = m.getBestEBSAccount();
		if( partnerErrorMap != null && preferSalesAccounts && isPartner(ebsAccount)) {
			retval = addErrorMessage(messages,partnerErrorMap.get(m.toType));
		}
		return retval;
	}

	/**
	 * Error reporting  This implements SFDC BR[1-5].PART C for renewals matching.
	 */
	public void errorReporting() {
		for(PartyData m : partyList) {
			m.errorMessages.clear();
			ebsAccountErrorReporting(m,m.errorMessages,m.errorMessages);
			addressErrorReporting(m,m.errorMessages,m.errorMessages);
			contactErrorReporting(m,m.errorMessages,m.errorMessages);
			salesErrorReporting(m,m.errorMessages,m.errorMessages);
			partnerErrorReporting(m,m.errorMessages);
		}
	}


	/**
	 * Find the most recent contacts with a matching e-mail address for PartyData
	 * with exactly one sales account id and without exactly one contact.
	 */
	@TestVisible
	protected void findContactsByEmail() {
		Set<Id> accountIds = new Set<Id>();
		Set<Id> cdhPartyIds = new Set<Id>();
		Set<String> emails = new Set<String>();
		for(PartyData m : partyList) {
			if(m.email != null && m.getBestContact(false) == null) {
				Set<Id> ids = m.getSalesAccountIds();
				if(ids.size() == 1) {
					accountIds.addAll(ids);
					emails.add(m.email);
					emails.add(m.email+CONTACT_EMAIL_SUFFIX);
					if(allowContactOnDifferentAccount) {
						cdhPartyIds.addAll(m.getCDHPartyIds());
					}
				}
			}
		}
		if(! accountIds.isEmpty()) {
			Map<Id,Map<Id,Contact>> xcontactMapMap = new Map<Id,Map<Id,Contact>>();
			for(Contact c : [
				select
					CDH_Party_Number__c,
					AccountId,
					Account.CDH_Party_Name__c,
					Account.CDH_Party_Name__r.Name,
					Account.RecordType.Name,
					Email,
					LastModifiedDate
				from Contact
				where Email in :emails
					and (AccountId in :accountIds 
						or Account.CDH_Party_Name__c in :cdhPartyIds) ] )
			{
				Id key = c.AccountId;
				if(allowContactOnDifferentAccount) {
					key = getCDHPartyIdFromAccount(c.Account,c.AccountId);
				}
				Map<Id,Contact> xcm = xcontactMapMap.get(key);
				if(xcm == null) {
					xcm = new Map<Id,Contact>();
					xcontactMapMap.put(key,xcm);
				}
				xcm.put(c.Id,c);
			}
			for(PartyData m : partyList) {
				if(m.email != null && m.getBestContact(false) == null) {
					Id accountId = null;
					Id cdhPartyId = null;
					List<Contact> contacts = new List<Contact>();
					Iterator<Id> i = m.getSalesAccountIds().iterator();
					if(i.hasNext()) {
						accountId = i.next();
						if(i.hasNext()) {
							accountId = null;
						}
					}
					if(allowContactOnDifferentAccount) {
						i= m.getCDHPartyIds().iterator();
						if(i.hasNext()) {
							cdhPartyId = i.next();
							if(i.hasNext()) {
								cdhPartyId = null;
							}
						}
					}
					if(accountId != null || cdhPartyId != null) {
						for(Map<Id,Contact> cm : xcontactMapMap.values()) {
							for(Contact c : cm.values()) {
								if(c.AccountId == accountId || getCDHPartyIdFromAccount(c.Account,c.AccountId) == cdhPartyId) {
									contacts.addAll(cm.values());
								}
								break;
							}
						}
					}
					if(! contacts.isEmpty()) {
						String email2 = m.email+CONTACT_EMAIL_SUFFIX;
						Contact c = null;
						for(Contact c2 : contacts) {
							if ( (c2.Email == m.email || c2.Email == email2)
								&& (c == null
									|| (c2.AccountId == accountId 
										&& (c.AccountId != accountId 
											|| c2.LastModifiedDate > c.LastModifiedDate ) )
									|| (c2.AccountId != accountId 
										&& c.AccountId != accountId 
										&& c2.LastModifiedDate > c.LastModifiedDate) ) )
							{
								c = c2;
							}
						}
						if(c != null) {
							m.setContact(c);
						}
					}
				}
			}
		}
	}

	/**
	 * Loops overthe respective opportunities and returns the line item map.
	 */
	public Map<Id,OpportunityLineItem> oppLineMap {
		get {
			if(oppLineMap == null) {
				oppLineMap = new Map<Id,OpportunityLineItem>();
				for(Opportunity opp : oppMap.values()) {
					oppLineMap.putAll( opp.OpportunityLineItems );
				}
			}
			return oppLineMap;
		}
		set;
	}

	/**
	 * Queries the respective opportunities and returns the map.  Calls assignFromRefOpp.
	 */
	protected Map<Id,Opportunity> oppMap {
		get {
			if(oppMap == null) {
				oppMap = new Map<Id,Opportunity>();
				Set<Id> refOppIds = new Set<Id>();
				Set<Id> refOppLineIds = new Set<Id>();
				for(PartyData m : partyList) {
					Opportunity refOpp = m.getRefOpp();
					OpportunityLineItem refOppLine = m.getRefOppLine();
					if(refOpp != null) {
						oppMap.put(refOpp.Id,refOpp);
					}
					if(refOppLine != null) {
						oppLineMap.put(refOppLine.Id,refOppLine);
					}
					else if(m.refOpp != null || m.refOppId != null)
					{
						if( m.refOppLineId != null) {
							refOppLineIds.add(m.refOppLineId);
							if(refOpp != null) {
								refOppIds.add(refOpp.Id);
							}
							else {
								refOppIds.add(m.refOppId);
							}
						}
						else if( m.refOpp == null && m.refOppId != null 
							&& m.toType != AccountToType.LINE_ENTITLE_TO )
						{
							refOppIds.add(m.refOppId);
						}
					}
				}
				if(! refOppIds.isEmpty()) {
					oppMap.putAll( [
						select
							Bill_To_Account__c,
							Bill_To_Account__r.Name,
							Bill_To_Account__r.CDH_Party_Number__c,
							Bill_To_Account__r.MasterRecord__c,
							Bill_To_Account__r.Sales_Account__c,
							Bill_To_Account__r.Sales_Account__r.CDH_Party_Name__c,
							Bill_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Bill_To_Account__r.Sales_Account__r.RecordType.Name,
							Bill_To_Account__r.Status__c,
							Bill_To_Address__c,
							Bill_To_Address__r.CDH_Party_Site_Number__c,
							Bill_To_Address__r.Country__c,
							Bill_To_Address__r.IsDuplicate__c,
							Bill_To_Address__r.MasterRecord__c,
							Bill_To_Address__r.Sales_Account__c,
							Bill_To_Address__r.Sales_Account__r.CDH_Party_Name__c,
							Bill_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Bill_To_Address__r.Sales_Account__r.RecordType.Name,
							Bill_To_Address__r.Status__c,
							Bill_To_Contact__c,
							Bill_To_Contact__r.CDH_Party_Number__c,
							Bill_To_Contact__r.AccountId,
							Bill_To_Contact__r.Account.CDH_Party_Name__c,
							Bill_To_Contact__r.Account.CDH_Party_Name__r.Name,
							Bill_To_Contact__r.Account.RecordType.Name,
							Bill_To_Contact__r.LastModifiedDate,
							Bill_To_Contact__r.Email,
							Bill_To_Contact__r.MasterRecord__c,
							Bill_To_Contact__r.Status__c,
							Bill_To_Sales_Account__c,
							Bill_To_Sales_Account__r.CDH_Party_Name__c,
							Bill_To_Sales_Account__r.CDH_Party_Name__r.Name,
							Bill_To_Sales_Account__r.RecordType.Name,
							Entitle_To_Account__c,
							Entitle_To_Account__r.Name,
							Entitle_To_Account__r.CDH_Party_Number__c,
							Entitle_To_Account__r.MasterRecord__c,
							Entitle_To_Account__r.Sales_Account__c,
							Entitle_To_Account__r.Sales_Account__r.CDH_Party_Name__c,
							Entitle_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Entitle_To_Account__r.Sales_Account__r.RecordType.Name,
							Entitle_To_Account__r.Status__c,
							Entitle_To_Address__c,
							Entitle_To_Address__r.CDH_Party_Site_Number__c,
							Entitle_To_Address__r.Country__c,
							Entitle_To_Address__r.IsDuplicate__c,
							Entitle_To_Address__r.MasterRecord__c,
							Entitle_To_Address__r.Sales_Account__c,
							Entitle_To_Address__r.Sales_Account__r.CDH_Party_Name__c,
							Entitle_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Entitle_To_Address__r.Sales_Account__r.RecordType.Name,
							Entitle_To_Address__r.Status__c,
							Entitle_To_Contact__c,
							Entitle_To_Contact__r.CDH_Party_Number__c,
							Entitle_To_Contact__r.AccountId,
							Entitle_To_Contact__r.Account.CDH_Party_Name__c,
							Entitle_To_Contact__r.Account.CDH_Party_Name__r.Name,
							Entitle_To_Contact__r.Account.RecordType.Name,
							Entitle_To_Contact__r.Email,
							Entitle_To_Contact__r.LastModifiedDate,
							Entitle_To_Contact__r.MasterRecord__c,
							Entitle_To_Contact__r.Status__c,
							Entitle_To_Sales_Account__c,
							Entitle_To_Sales_Account__r.CDH_Party_Name__c,
							Entitle_To_Sales_Account__r.CDH_Party_Name__r.Name,
							Entitle_To_Sales_Account__r.RecordType.Name,
							Ship_To_Account__c,
							Ship_To_Account__r.Name,
							Ship_To_Account__r.CDH_Party_Number__c,
							Ship_To_Account__r.MasterRecord__c,
							Ship_To_Account__r.Sales_Account__c,
							Ship_To_Account__r.Sales_Account__r.CDH_Party_Name__c,
							Ship_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Ship_To_Account__r.Sales_Account__r.RecordType.Name,
							Ship_To_Account__r.Status__c,
							Ship_To_Address__c,
							Ship_To_Address__r.CDH_Party_Site_Number__c,
							Ship_To_Address__r.Country__c,
							Ship_To_Address__r.IsDuplicate__c,
							Ship_To_Address__r.MasterRecord__c,
							Ship_To_Address__r.Sales_Account__c,
							Ship_To_Address__r.Sales_Account__r.CDH_Party_Name__c,
							Ship_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Ship_To_Address__r.Sales_Account__r.RecordType.Name,
							Ship_To_Address__r.Status__c,
							Ship_To_Contact__c,
							Ship_To_Contact__r.CDH_Party_Number__c,
							Ship_To_Contact__r.AccountId,
							Ship_To_Contact__r.Account.CDH_Party_Name__c,
							Ship_To_Contact__r.Account.CDH_Party_Name__r.Name,
							Ship_To_Contact__r.Account.RecordType.Name,
							Ship_To_Contact__r.Email,
							Ship_To_Contact__r.LastModifiedDate,
							Ship_To_Contact__r.MasterRecord__c,
							Ship_To_Contact__r.Status__c,
							Ship_To_Sales_Account__c,
							Ship_To_Sales_Account__r.CDH_Party_Name__c,
							Ship_To_Sales_Account__r.CDH_Party_Name__r.Name,
							Ship_To_Sales_Account__r.RecordType.Name,
							Sold_To_Account__c,
							Sold_To_Account__r.Name,
							Sold_To_Account__r.CDH_Party_Number__c,
							Sold_To_Account__r.MasterRecord__c,
							Sold_To_Account__r.Sales_Account__c,
							Sold_To_Account__r.Sales_Account__r.CDH_Party_Name__c,
							Sold_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Sold_To_Account__r.Sales_Account__r.RecordType.Name,
							Sold_To_Account__r.Status__c,
							Sold_To_Address__c,
							Sold_To_Address__r.CDH_Party_Site_Number__c,
							Sold_To_Address__r.Country__c,
							Sold_To_Address__r.IsDuplicate__c,
							Sold_To_Address__r.MasterRecord__c,
							Sold_To_Address__r.Sales_Account__c,
							Sold_To_Address__r.Sales_Account__r.CDH_Party_Name__c,
							Sold_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
							Sold_To_Address__r.Sales_Account__r.RecordType.Name,
							Sold_To_Address__r.Status__c,
							Sold_To_Contact__c,
							Sold_To_Contact__r.CDH_Party_Number__c,
							Sold_To_Contact__r.AccountId,
							Sold_To_Contact__r.Account.CDH_Party_Name__c,
							Sold_To_Contact__r.Account.CDH_Party_Name__r.Name,
							Sold_To_Contact__r.Account.RecordType.Name,
							Sold_To_Contact__r.Email,
							Sold_To_Contact__r.LastModifiedDate,
							Sold_To_Contact__r.MasterRecord__c,
							Sold_To_Contact__r.Status__c,
							Sold_To_Sales_Account__c,
							Sold_To_Sales_Account__r.CDH_Party_Name__c,
							Sold_To_Sales_Account__r.CDH_Party_Name__r.Name,
							Sold_To_Sales_Account__r.RecordType.Name,
							OpportunityNumber__c,
							OracleOrderNumber__c,
							PONumber__c,
							(	select
									Entitle_To_Account__c,
									Entitle_To_Account__r.Name,
									Entitle_To_Account__r.CDH_Party_Number__c,
									Entitle_To_Account__r.MasterRecord__c,
									Entitle_To_Account__r.Sales_Account__c,
									Entitle_To_Account__r.Sales_Account__r.CDH_Party_Name__c,
									Entitle_To_Account__r.Sales_Account__r.CDH_Party_Name__r.Name,
									Entitle_To_Account__r.Sales_Account__r.RecordType.Name,
									Entitle_To_Account__r.Status__c,
									Entitle_To_Address__c,
									Entitle_To_Address__r.CDH_Party_Site_Number__c,
									Entitle_To_Address__r.Country__c,
									Entitle_To_Address__r.IsDuplicate__c,
									Entitle_To_Address__r.MasterRecord__c,
									Entitle_To_Address__r.Sales_Account__c,
									Entitle_To_Address__r.Sales_Account__r.CDH_Party_Name__c,
									Entitle_To_Address__r.Sales_Account__r.CDH_Party_Name__r.Name,
									Entitle_To_Address__r.Sales_Account__r.RecordType.Name,
									Entitle_To_Address__r.Status__c,
									Entitle_To_Contact__c,
									Entitle_To_Contact__r.CDH_Party_Number__c,
									Entitle_To_Contact__r.AccountId,
									Entitle_To_Contact__r.Account.CDH_Party_Name__c,
									Entitle_To_Contact__r.Account.CDH_Party_Name__r.Name,
									Entitle_To_Contact__r.Account.RecordType.Name,
									Entitle_To_Contact__r.Email,
									Entitle_To_Contact__r.LastModifiedDate,
									Entitle_To_Contact__r.MasterRecord__c,
									Entitle_To_Contact__r.Status__c,
									Entitle_To_Sales_Account__c,
									Entitle_To_Sales_Account__r.CDH_Party_Name__c,
									Entitle_To_Sales_Account__r.CDH_Party_Name__r.Name,
									Entitle_To_Sales_Account__r.RecordType.Name
								from OpportunityLineItems
								where Id in :refOppLineIds )
						from Opportunity
						where Id in :refOppIds ] );
					for(PartyData m : partyList) {
						if(m.getRefOpp() == null && m.refOppId != null) {
							m.setRefOpp(oppMap.get(m.refOppId));
						}
						if(m.getRefOppLine() == null && m.refOppLineId != null) {
							m.setRefOppLine(oppLineMap.get(m.refOppLineId));
						}
					}
				}
			}
			return oppMap;
		}
		set;
	}

	private static Map<Id,Account> putAll(Map<Id,Account> accountMap,List<Account> accounts) {
		if(accountMap == null) {
			accountMap = new Map<Id,Account>();
		}
		for(Account a : accounts) {
			if(a != null) {
				accountMap.put(a.Id,a);
			}
		}
		return accountMap;
	}

	/**
	 * Find all the accounts referenced in the various maps and populate them
	 * into a single map.
	 * 
	 * @return map of accounts based on account id
	 */
	@TestVisible
	protected Map<Id,Account> accountMap {
		get {
			if(accountMap == null) {
				List<Account> accounts = new List<Account>();
				for(Opportunity opp : oppMap.values()) {
					accounts.add(opp.Bill_To_Sales_Account__r);
					accounts.add(opp.Entitle_To_Sales_Account__r);
					accounts.add(opp.Ship_To_Sales_Account__r);
					accounts.add(opp.Sold_To_Sales_Account__r);
					for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {
						accounts.add(lineItem.Entitle_To_Sales_Account__r);
					}
				}
				for(EBS_Account__c a : ebsAccountMap.values()) {
					accounts.add(a.Sales_Account__r);
				}
				for(Address__c a : addressMap.values()) {
					accounts.add(a.Sales_Account__r);
				}
				for(Contact c : contactMap.values()) {
					accounts.add(c.Account);
				}
				accountMap = putAll(accountMap,accounts);
			}
			return accountMap;
		}
		set;
	}

	/**
	 * Map all the accounts based on id or cdh party name keys.
	 */
	protected Map<String,List<Account>> accountsKeyMap {
		get {
			if(accountsKeyMap == null) {
				accountsKeyMap = new Map<String,List<Account>>();
				ebsAccountsKeyMap.isEmpty();
				addressesKeyMap.isEmpty();
				contactsKeyMap.isEmpty();
				Set<String> cdhPartyNumbers = new Set<String>();
				for(PartyData m : partyList) {
					if(String.isNotBlank(m.cdhPartyNumber)) {
						cdhPartyNumbers.add(m.cdhPartyNumber);
					}
				}
				if(! cdhPartyNumbers.isEmpty()) {
					putAll(accountMap, [
						select Id,
							CDH_Party_Name__c,
							CDH_Party_Name__r.Name,
							RecordType.Name
						from Account
						where CDH_Party_Name__c in ( select Id from CDH_Party__c where Name in :cdhPartyNumbers )
							and Id not in :accountMap.keySet() ] );
				}
				for(Account a : accountMap.values()) {
					Set<String> keys = new Set<String>{idKey(a.Id)};
					if(a.CDH_Party_Name__r != null) {
						keys.add(cdhPartyNumberKey(a.CDH_Party_Name__r.Name));
					}
					for(String key : keys) {
						List<Account> accounts = accountsKeyMap.get(key);
						if(accounts == null) {
							accounts = new List<Account>();
							accountsKeyMap.put(key,accounts);
						}
						accounts.add(a);
					}
				}
			}
			return accountsKeyMap;
		}
		set;
	}

	private static Map<Id,EBS_Account__c> putAll(Map<Id,Account> accountMap,Map<Id,EBS_Account__c> ebsAccountMap,List<EBS_Account__c> ebsAccounts) {
		if(ebsAccountMap == null) {
			ebsAccountMap = new Map<Id,EBS_Account__c>();
		}
		for(EBS_Account__c ebsAccount : ebsAccounts) {
			if(ebsAccount != null) {
				ebsAccountMap.put(ebsAccount.Id,ebsAccount);
				// in many cases CDH_Party_Number__c is not set when it should be...
				// so we set the value here
				if(ebsAccount.CDH_Party_Number__c == null 
					&& ebsAccount.Sales_Account__r != null
					&& ebsAccount.Sales_Account__r.CDH_Party_Name__r != null )
				{
					ebsAccount.CDH_Party_Number__c = ebsAccount.Sales_Account__r.CDH_Party_Name__r.Name;
				}
				if(accountMap != null) {
					accountMap.put(ebsAccount.Sales_Account__c,ebsAccount.Sales_Account__r);
				}
			}
		}
		return ebsAccountMap;
	}

	/**
	 * Query the respective EBS Account objects.
	 * 
	 * @return map of EBS Accounts based on Id
	 */
	protected Map<Id,EBS_Account__c> ebsAccountMap {
		get {
			if(ebsAccountMap == null) {
				List<EBS_Account__c> ebsAccounts = new List<EBS_Account__c>();
				for(Opportunity opp : oppMap.values()) {
					ebsAccounts.add(opp.Bill_To_Account__r);
					ebsAccounts.add(opp.Entitle_To_Account__r);
					ebsAccounts.add(opp.Ship_To_Account__r);
					ebsAccounts.add(opp.Sold_To_Account__r);
					for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {
						ebsAccounts.add(lineItem.Entitle_To_Account__r);
					}
				}
				ebsAccountMap = putAll(null,ebsAccountmap,ebsAccounts);
				Set<Id> ebsAccountIds = new Set<Id>();
				for(PartyData m : partyList) {
					if(m.refEBSAccountId != null) {
						ebsAccountIds.add(m.refEBSAccountId);
					}
				}
				ebsAccountIds.removeAll(ebsAccountMap.keySet());
				if(! ebsAccountIds.isEmpty()) {
					putAll(null,ebsAccountMap,[
						select
							Name,
							CDH_Party_Number__c,
							Sales_Account__c,
							Sales_Account__r.CDH_Party_Name__c,
							Sales_Account__r.CDH_Party_Name__r.Name,
							Sales_Account__r.RecordType.Name,
							MasterRecord__c,
							Status__c
						from EBS_Account__c
						where Id in :ebsAccountIds ] );
				}
			}
			return ebsAccountMap;
		}
		set;
	}

	public static String accountNumberKey(String oracleAccountNumber) {
		String retval = null;
		oracleAccountNumber = trimValue(oracleAccountNumber);
		if(oracleAccountNumber != null) {
			retval = 'A#:'+oracleAccountNumber;
		}
		return retval;
	}

	public static String idKey(Id salesAccountId) {
		String retval = null;
		if(salesAccountId != null) {
			retval = 'ID:'+salesAccountId;
		}
		return retval;
	}

	public static String cdhPartyNumberKey(String cdhPartyNumber) {
		String retval = null;
		cdhPartyNumber = trimValue(cdhPartyNumber);
		if(cdhPartyNumber != null) {
			retval = 'P#:'+cdhPartyNumber;
		}
		return retval;
	}

	public static String cdhPartySiteNumberKey(String cdhPartySiteNumber) {
		String retval = null;
		cdhPartySiteNumber = trimValue(cdhPartySiteNumber);
		if(cdhPartySiteNumber != null) {
			retval = 'S#:'+cdhPartySiteNumber;
		}
		return retval;
	}

	/**
	 * Query the respective EBS Account objects using CDH party number.
	 * 
	 * @return map of a list of EBS Accounts based on CDH Party Number
	 */
	protected Map<String,List<EBS_Account__c>> ebsAccountsKeyMap {
		get {
			if(ebsAccountsKeyMap == null) {
				Set<Id> salesAccountIds = new Set<Id>();
				Set<String> oracleAccountNumbers = new Set<String>();
				Set<String> cdhPartyNumbers = new Set<String>();
				for(PartyData m : partyList) {
					m.refEBSAccount = ebsAccountMap.get( m.refEBSAccountId );
					if( m.refEBSAccount == null || (preferSalesAccounts && isPartner(m.refEBSAccount))) {
						if(m.refSalesAccountId != null) {
							salesAccountIds.add(m.refSalesAccountId);
						}
					}
				}
				ebsAccountsKeyMap = new Map<String,List<EBS_Account__c>>();
				Set<Id> hasSalesAccountIds = new Set<Id>();
				if(! salesAccountIds.isEmpty()) {
					// add all query results directly into the ebsAccountMap
					putAll(accountMap,ebsAccountMap,[
						select
							Name,
							CDH_Party_Number__c,
							MasterRecord__c,
							Sales_Account__c,
							Sales_Account__r.CDH_Party_Name__c,
							Sales_Account__r.CDH_Party_Name__r.Name,
							Sales_Account__r.RecordType.Name,
							Status__c
						from EBS_Account__c
						where Sales_Account__c in :salesAccountIds
							and (not Id in :ebsAccountMap.keySet()) ]);
					for(EBS_Account__c ebsAccount : ebsAccountMap.values()) {
						hasSalesAccountIds.add(ebsAccount.Sales_Account__c);
					}
				}
				for(PartyData m : partyList) {
					m.refEBSAccount = ebsAccountMap.get( m.refEBSAccountId );
					if(m.refSalesAccount != null) {
						salesAccountIds.add(m.refSalesAccount.Id);
					}
					if( m.refEBSAccount == null || (preferSalesAccounts && isPartner(m.refEBSAccount))) {
						oracleAccountNumbers.addAll( m.oracleAccountNumbers );
						cdhPartyNumbers.addAll( m.cdhPartyNumbers );
					}
				}
				if(! oracleAccountNumbers.isEmpty()) {
					// add all query results directly into the ebsAccountMap
					putAll(accountMap,ebsAccountMap,[
						select
							Name,
							CDH_Party_Number__c,
							MasterRecord__c,
							Sales_Account__c,
							Sales_Account__r.CDH_Party_Name__c,
							Sales_Account__r.CDH_Party_Name__r.Name,
							Sales_Account__r.RecordType.Name,
							Status__c
						from EBS_Account__c
						where Name in :oracleAccountNumbers
							and (not Id in :ebsAccountMap.keySet()) ]);
				}
				if(! cdhPartyNumbers.isEmpty()) {
					Set<Id> accountIds = new Set<Id>();
					for(Account a : accountMap.values()) {
						if(a.CDH_Party_Name__r != null && cdhPartyNumbers.contains(a.CDH_Party_Name__r.Name)) {
							accountIds.add(a.Id);
						}
					}
					// add all query results directly into the ebsAccountMap
					putAll(accountMap,ebsAccountMap,[
						select
							Name,
							CDH_Party_Number__c,
							MasterRecord__c,
							Sales_Account__c,
							Sales_Account__r.CDH_Party_Name__c,
							Sales_Account__r.CDH_Party_Name__r.Name,
							Sales_Account__r.RecordType.Name,
							Status__c
						from EBS_Account__c
						where ( CDH_Party_Number__c in :cdhPartyNumbers
								or (CDH_Party_Number__c = null and Sales_Account__c in :accountIds) )
							and (not Id in :ebsAccountMap.keySet()) ]);
				}
				// loop over all the EBS Accounts in the map, not just the ones
				// we just added.
				Set<String> keys = new Set<String>();
				for(EBS_Account__c a : ebsAccountMap.values()) {
					String oracleAccountNumber = a.Name;
					if(oracleAccountNumbers.contains(oracleAccountNumber)){
						keys.add(accountNumberKey(oracleAccountNumber));
					}
					Id salesAccountId = a.Sales_Account__c;
					if( salesAccountIds.contains(salesAccountId) ) {
						keys.add(idKey(salesAccountId));
					}
					String cdhPartyNumber = a.CDH_Party_Number__c;
					if(cdhPartyNumber != null && cdhPartyNumbers.contains(cdhPartyNumber)) {
						keys.add(cdhPartyNumberKey(cdhPartyNumber));
					}
					for(String key : keys) {
						if(key != null) {
							List<EBS_Account__c> ebsAccounts = ebsAccountsKeyMap.get(key);
							if(ebsAccounts == null) {
								ebsAccounts = new List<EBS_Account__c>();
								ebsAccountsKeyMap.put(key,ebsAccounts);
							}
							ebsAccounts.add(a);
						}
					}
					keys.clear();
				}
			}
			return ebsAccountsKeyMap;
		}
		set;
	}

	private static Map<Id,Address__c> putAll(Map<Id,Account> accountMap,Map<Id,Address__c> addressMap,List<Address__c> addresses) {
		if(addressMap == null) {
			addressMap = new Map<Id,Address__c>();
		}
		for(Address__c address : addresses) {
			if(address != null) {
				addressMap.put(address.Id,address);
				if(accountMap != null) {
					accountMap.put(address.Sales_Account__c,address.Sales_Account__r);
				}
			}
		}
		return addressMap;
	}

	/**
	 * Query the respective Address objects based on Id.
	 * 
	 * @return a map of Address objects based on Id.
	 */
	protected Map<Id,Address__c> addressMap {
		get {
			if(addressMap == null) {
				List<Address__c> addresses = new List<Address__c>();
				for(Opportunity opp : oppMap.values()) {
					addresses.add(opp.Bill_To_Address__r);
					addresses.add(opp.Entitle_To_Address__r);
					addresses.add(opp.Ship_To_Address__r);
					addresses.add(opp.Sold_To_Address__r);
					for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {
						if(lineItem.Entitle_To_Address__r != null) {
							addresses.add(lineItem.Entitle_To_Address__r);
						}
					}
				}
				addressMap = putAll(null,addressMap,addresses);
				Set<Id> addressIds = new Set<Id>();
				for(PartyData m : partyList) {
					if(m.refAddressId != null) {
						addressIds.add(m.refAddressId);
					}
				}
				addressIds.removeAll(addressMap.keySet());
				if(! addressIds.isEmpty()) {
					putAll(null,addressMap,[
						select
							CDH_Party_Site_Number__c,
							Country__c,
							IsDuplicate__c,
							MasterRecord__c,
							Sales_Account__c,
							Sales_Account__r.CDH_Party_Name__c,
							Sales_Account__r.CDH_Party_Name__r.Name,
							Sales_Account__r.RecordType.Name,
							Status__c
						from Address__c
						where Id in :addressIds ] );
				}
			}
			return addressMap;
		}
		set;
	}

	/**
	 * Query the respective Address objects based on CDH Party Site Number.
	 * 
	 * @return a map of lists of addresses based CDH Site Party Number.
	 */
	protected Map<String,List<Address__c>> addressesKeyMap {
		get {
			if(addressesKeyMap == null) {
				addressesKeyMap = new Map<String,List<Address__c>>();
				Set<String> cdhPartySiteNumbers = new Set<String>();
				for(PartyData m : partyList) {
					m.refAddress = addressMap.get( m.refAddressId );
					if( m.refAddress == null || (preferSalesAccounts && isPartner(m.refAddress))) {
						cdhPartySiteNumbers.addAll(m.cdhPartySiteNumbers);
					}
				}
				if(! cdhPartySiteNumbers.isEmpty()) {
					// put query result directly in the address Map
					putAll(accountMap,addressMap,[
						select
							CDH_Party_Site_Number__c,
							Country__c,
							IsDuplicate__c,
							MasterRecord__c,
							Sales_Account__c,
							Sales_Account__r.CDH_Party_Name__c,
							Sales_Account__r.CDH_Party_Name__r.Name,
							Sales_Account__r.RecordType.Name,
							Status__c
						from Address__c
						where CDH_Party_Site_Number__c in :cdhPartySiteNumbers
							and (not Id in :addressMap.keySet()) ] );
				}
				// loop over all the results, not just the ones we just added
				for(Address__c a : addressMap.values()) {
					String cdhPartySiteNumber = a.CDH_Party_Site_Number__c;
					if(cdhPartySiteNumber != null && cdhPartySiteNumbers.contains(cdhPartySiteNumber)) {
						String key = cdhPartySiteNumberKey(cdhPartySiteNumber);
						if(key != null) {
							List<Address__c> addresses = addressesKeyMap.get(key);
							if(addresses == null) {
								addresses = new List<Address__c>();
								addressesKeyMap.put(key,addresses);
							}
							addresses.add(a);
						}
					}
				}
			}
			return addressesKeyMap;
		}
		set;
	}

	private static Map<Id,Contact> putAll(Map<Id,Account> accountMap,Map<Id,Contact> contactMap,List<Contact> contacts) {
		if(contactMap == null) {
			contactMap = new Map<Id,Contact>();
		}
		for(Contact contact : contacts) {
			if(contact != null) {
				contactMap.put(contact.Id,contact);
				if(accountMap != null && contact.Account != null) {
					accountMap.put(contact.AccountId,contact.Account);
				}
			}
		}
		return contactMap;
	}

	/**
	 * Query the respective Contact objects based on Id.
	 * 
	 * @return a map of Contacts based on Id.
	 */
	protected Map<Id,Contact> contactMap {
		get {
			if(contactMap == null) {
				List<Contact> contacts = new List<Contact>();
				// all all the contacts referenced by the reference opportunity
				for(Opportunity opp : oppMap.values()) {
					contacts.add(opp.Bill_To_Contact__r);
					contacts.add(opp.Entitle_To_Contact__r);
					contacts.add(opp.Ship_To_Contact__r);
					contacts.add(opp.Sold_To_Contact__r);
					for(OpportunityLineItem lineItem : opp.OpportunityLineItems) {
						contacts.add(lineItem.Entitle_To_Contact__r);
					}
				}
				contactMap = putAll(null,contactMap,contacts);
				// find the set of contact ids to query
				Set<Id> contactIds = new Set<Id>();
				for(PartyData m : partyList) {
					if(m.refContactId != null) {
						contactIds.add( m.refContactId );
					}
				}
				// exclude the contact ids we just added to the map
				contactIds.removeAll(contactMap.keySet());
				if(! contactIds.isEmpty()) {
					putAll(null,contactMap,[
						select
							CDH_Party_Number__c,
							AccountId,
							Account.CDH_Party_Name__c,
							Account.CDH_Party_Name__r.Name,
							Account.RecordType.Name,
							Email,
							LastModifiedDate,
							MasterRecord__c,
							Status__c
						from Contact
						where Id in :contactIds ] );
				}
			}
			return contactMap;
		}
		set;
	}

	@TestVisible
	private Set<String> getContactCDHPartyNumbers() {
		Set<String> contactCDHPartyNumbers = new Set<String>();
		for(PartyData m : partyList) {
			m.refContact = contactMap.get(m.refContactId);
			if( m.refContact == null || (preferSalesAccounts && isPartner(m.refContact))) {
				contactCDHPartyNumbers.addAll( m.contactCDHPartyNumbers );
			}
		}
		return contactCDHPartyNumbers;
	}

	/**
	 * Query the respective Contact objects based on Contact CDH Party Numbers.
	 * 
	 * @return a map of lists of Contacts based the Contact CDH Site Party Number.
	 */
	@TestVisible
	protected Map<String,List<Contact>> contactsKeyMap {
		get {
			if(contactsKeyMap == null) {
				Set<String> contactCDHPartyNumbers = getContactCDHPartyNumbers();
				contactsKeyMap = new Map<String,List<Contact>>();
				if(! contactCDHPartyNumbers.isEmpty() ) {
					// add all the contacts directly to the contactMap
					putAll(accountMap,contactMap,[
						select
							CDH_Party_Number__c,
							AccountId,
							Account.CDH_Party_Name__c,
							Account.CDH_Party_Name__r.Name,
							Account.RecordType.Name,
							Email,
							LastModifiedDate,
							MasterRecord__c,
							Status__c
						from Contact
						where CDH_Party__c in (
							select Id
							from CDH_Party__c
							where CDH_Party_Number_Ext__c in :contactCDHPartyNumbers) ] );
				}
				// loop over all the contacts, not just the ones we just added
				for(Contact c : contactMap.values()) {
					if(c.CDH_Party_Number__c != null && contactCDHPartyNumbers.contains(c.CDH_Party_Number__c)) {
						String key = cdhPartyNumberKey(c.CDH_Party_Number__c);
						if(key != null) {
							List<Contact> contacts = contactsKeyMap.get(key);
							if(contacts == null) {
								contacts = new List<Contact>();
								contactsKeyMap.put(key,contacts);
							}
							contacts.add(c);
						}
					}
				}
			}
			return contactsKeyMap;
		}
		set;
	}

	private static String trimValue(String value) {
		return (value == null || value.trim() == '')?null:value.trim();
	}

	/**
	 * Class representing matching data.
	 */
	public virtual class PartyData {
		protected Opportunity refOpp = null;
		protected OpportunityLineItem refOppLine = null;
		public final AccountToType toType;
		public Id refOppId;
		public Id refOppLineId;
		public String oracleAccountNumber {
			get;
			set { oracleAccountNumber = trimValue(value); }
		}
		public String cdhPartyNumber {
			get;
			set { cdhPartyNumber = trimValue(value); }
		}
		public String cdhPartySiteNumber {
			get;
			set { cdhPartySiteNumber = trimValue(value); }
		}
		public String contactCDHPartyNumber {
			get;
			set { contactCDHPartyNumber = trimValue(value); }
		}
		public String superRegion {
			get;
			set { superRegion = trimValue(value); }
		}
		public String country {
			get;
			set { country = trimValue(value); }
		}
		public String email {
			get;
			set { email = trimValue(value); }
		}
		public Id refSalesAccountId = null;
		public Id refEBSAccountId = null;
		public Id refAddressId = null;
		public Id refContactId = null;
		public Map<Id,Map<Id,EBS_Account__c>> ebsAccountMapMap = new Map<Id,Map<Id,EBS_Account__c>>();
		public Map<Id,Map<Id,Address__c>> addressMapMap = new Map<Id,Map<Id,Address__c>>();
		public Map<Id,Map<Id,Contact>> contactMapMap = new Map<Id,Map<Id,Contact>>();
		public List<String> errorMessages = new List<String>();
		public List<String> warnMessages = new List<String>();
		protected Account_Matching accountMatching {
			get;
			private set;
		}

		/** 
		 * Standard Contructor.
		 * 
		 * @param toType enum matching type
		 * @param refOppId the Id of the reference Opportunity
		 * @param refOppLineId the Id of the reference Opportunity Line Item
		 * @param oracleAccountNumber the oracle account number
		 * @param cdhPartyNumber the CDH Party Number
		 * @param cdhPartySiteNumber the CDH Party Site Number
		 * @param contactCDHPartyNumber the Contact CDH Party Number
		 * @param superRegion to filter accounts with
		 * @param country to filter addresses with
		 * @param email to filter contacts with
		 */
		public PartyData(
			AccountToType toType,
			Id refOppId,
			Id refOppLineId,
			String oracleAccountNumber,
			String cdhPartyNumber,
			String cdhPartySiteNumber,
			String contactCDHPartyNumber,
			String superRegion,
			String country,
			String email )
		{
			this.toType = toType;
			this.refOppId = refOppId;
			this.refOppLineId = refOppLineId;
			this.oracleAccountNumber = oracleAccountNumber;
			this.cdhPartyNumber = cdhPartyNumber;
			this.cdhPartySiteNumber = cdhPartySiteNumber;
			this.contactCDHPartyNumber = contactCDHPartyNumber;
			this.superRegion = superRegion;
			this.country = country;
			this.email = email;
		}

		protected virtual void matchEBSAccount(Boolean xpreferSalesAccounts,Map<Id,EBS_Account__c> xebsAccountMap,Map<String,List<EBS_Account__c>> xebsAccountsKeyMap) {
			refEBSAccount = xebsAccountMap.get( refEBSAccountId );
			setEBSAccount( refEBSAccount );
			if( refEBSAccount == null || (xpreferSalesAccounts && isPartner(refEBSAccount))) {
				addEBSAccounts( xebsAccountsKeyMap.get( idKey(refSalesAccountId) ) );
				for(String oracleAccountNumber : oracleAccountNumbers) {
					addEBSAccounts( xebsAccountsKeyMap.get( accountNumberKey(oracleAccountNumber) ) );
					System.debug('oracleAccountNumber: '+oracleAccountNumber);
				}
			}
		}

		/**
		 * Get the reference Opportunity.
		 * @return refOpp
		 */
		public Opportunity getRefOpp() {
			return refOpp;
		}

		/**
		 * Assigns the reference opportunity.  Also assigns the
		 * refSalesAccount, refEBSAccount, refAddress, and 
		 * refContact values.
		 * @param refOpp
		 */
		public virtual void setRefOpp(Opportunity refOpp) {
			this.refOpp = refOpp;
			if(refOpp != null  && toType != AccountToType.LINE_ENTITLE_TO) {
				if(toType == AccountToType.BILL_TO) {
					refSalesAccount = refOpp.Bill_To_Sales_Account__r;
					refEBSAccount = refOpp.Bill_To_Account__r;
					refAddress = refOpp.Bill_To_Address__r;
					refContact = refOpp.Bill_To_Contact__r;
				}
				else if(toType == AccountToType.ENTITLE_TO) {
					refSalesAccount = refOpp.Entitle_To_Sales_Account__r;
					refEBSAccount = refOpp.Entitle_To_Account__r;
					refAddress = refOpp.Entitle_To_Address__r;
					refContact = refOpp.Entitle_To_Contact__r;
				}
				else if(toType == AccountToType.SHIP_TO) {
					refSalesAccount = refOpp.Ship_To_Sales_Account__r;
					refEBSAccount = refOpp.Ship_To_Account__r;
					refAddress = refOpp.Ship_To_Address__r;
					refContact = refOpp.Ship_To_Contact__r;
				}
				else if(toType == AccountToType.SOLD_TO) {
					refSalesAccount = refOpp.Sold_To_Sales_Account__r;
					refEBSAccount = refOpp.Sold_To_Account__r;
					refAddress = refOpp.Sold_To_Address__r;
					refContact = refOpp.Sold_To_Contact__r;
				}
			}
		}

		/**
		 * Get the reference Opportunity Line Item.
		 * @return refOppLine
		 */
		public OpportunityLineItem getRefOppLine() {
			return refOppLine;
		}

		/**
		 * Assigns the reference opportunity line.  Also assigns the
		 * refSalesAccount, refEBSAccount, refAddress, and 
		 * refContact values.
		 * @param refOppLine
		 */
		public virtual void setRefOppLine(OpportunityLineItem refOppLine) {
			this.refOppLine = refOppLine;
			if(refOppLine != null && toType == AccountToType.LINE_ENTITLE_TO) {
				refSalesAccount = refOppLine.Entitle_To_Sales_Account__r;
				refEBSAccount = refOppLine.Entitle_To_Account__r;
				refAddress = refOppLine.Entitle_To_Address__r;
				refContact = refOppLine.Entitle_To_Contact__r;
			}
		}

		public Account refSalesAccount {
			get;
			set {
				if(value != null) {
					refSalesAccount = value;
				}
			}
		}

		public EBS_Account__c refEBSAccount {
			get;
			set {
				if(value != null ) {
					refEBSAccount = value;
					refSalesAccount = value.Sales_Account__r;
					oracleAccountNumbers.add( value.Name );
					if(value.CDH_Party_Number__c != null) {
						cdhPartyNumbers.add( value.CDH_Party_Number__c );
					}
				}
			}
		}

		public void useRefEBSAccount() {
			if(refEBSAccount != null) {
				ebsAccountMapMap.clear();
				ebsAccountMapMap.put(refEBSAccount.Sales_Account__c,new Map<Id,EBS_Account__c>{refEBSAccount.Id=>refEBSAccount});
			}
		}

		public Address__c refAddress {
			get;
			set {
				if(value != null) {
					refAddress = value;
					if(value.CDH_Party_Site_Number__c != null) {
						cdhPartySiteNumbers.add( value.CDH_Party_Site_Number__c );
					}
				}
			}
		}

		public void useRefAddress() {
			if(refAddress != null) {
				addressMapMap.clear();
				addressMapMap.put(refAddress.Sales_Account__c,new Map<Id,Address__c>{refAddress.Id=>refAddress});
			}
		}

		public Contact refContact {
			get;
			set {
				if(value != null) {
					refContact = value;
					if(value.CDH_Party_Number__c != null) {
						contactCDHPartyNumbers.add( value.CDH_Party_Number__c );
					}
				}
			}
		}

		public void useRefContact() {
			if(refContact != null) {
				contactMapMap.clear();
				contactMapMap.put(refContact.AccountId,new Map<Id,Contact>{refContact.Id=>refContact});
			}
		}

		public Set<String> oracleAccountNumbers {
			get {
				if(oracleAccountNumbers == null) {
					oracleAccountNumbers = new Set<String>();
					if(oracleAccountNumber != null) {
						oracleAccountNumbers.add( oracleAccountNumber );
					}
				}
				return oracleAccountNumbers;
			}
			set;
		}

		public Set<String> cdhPartyNumbers {
			get {
				if(cdhPartyNumbers == null) {
					cdhPartyNumbers = new Set<String>();
					if(cdhPartyNumber != null) {
						cdhPartyNumbers.add( cdhPartyNumber );
					}
				}
				return cdhPartyNumbers;
			}
			set;
		}

		public Set<String> cdhPartySiteNumbers {
			get {
				if(cdhPartySiteNumbers == null) {
					cdhPartySiteNumbers = new Set<String>();
					if(cdhPartySiteNumber != null) {
						cdhPartySiteNumbers.add( cdhPartySiteNumber );
					}
				}
				return cdhPartySiteNumbers;
			}
			set;
		}

		public Set<String> contactCDHPartyNumbers {
			get {
				if(contactCDHPartyNumbers == null) {
					contactCDHPartyNumbers = new Set<String>();
					if(contactCDHPartyNumber != null) {
						contactCDHPartyNumbers.add( contactCDHPartyNumber );
					}
				}
				return contactCDHPartyNumbers;
			}
			set;
		}

		/**
		 * Get best EBS Account.
		 * 
		 * @return best EBS Account or null
		 */
		public EBS_Account__c getBestEBSAccount() {
			Id accountId = getSalesAccountId(ebsAccountMapMap.keySet(),true);
			EBS_Account__c retval = null;
			if(accountId != null) {
				retval = ebsAccountMapMap.get(accountId).values()[0];
			}
			return retval;
		}

		/**
		 * Get the unique EBS Account.
		 * 
		 * @return unique EBS Account or null
		 */
		public EBS_Account__c getEBSAccount() {
			EBS_Account__c retval = null;
			if(ebsAccountMapMap.size() == 1) {
				Map<Id,EBS_Account__c> ebsAccounts = ebsAccountMapMap.values()[0];
				if(ebsAccounts.size() == 1) {
					retval = ebsAccounts.values()[0];
				}
			}
			return retval;
		}

		/**
		 * Set the unique EBS Account.  Use null to clear the map.
		 * 
		 * @param ebsAccount the unique EBS Account
		 */
		public void setEBSAccount(EBS_Account__c ebsAccount) {
			ebsAccountMapMap.clear();
			addEBSAccount(ebsAccount);
		}

		/**
		 * Add another EBS Account.
		 * 
		 * @param ebsAccount the EBS Account to add
		 */
		public void addEBSAccount(EBS_Account__c ebsAccount) {
			if(ebsAccount != null) {
				Map<Id,EBS_Account__c> em = ebsAccountMapMap.get(ebsAccount.Sales_Account__c);
				if(em == null) {
					em = new Map<Id,EBS_Account__c>();
					ebsAccountMapMap.put(ebsAccount.Sales_Account__c,em);
				}
				em.put(ebsAccount.Id,ebsAccount);
			}
		}

		/**
		 * Add all EBS Accounts.
		 * 
		 * @param ebsAccounts the list of EBS Accounts to add
		 */
		public void addEBSAccounts(List<EBS_Account__c> ebsAccounts) {
			if(ebsAccounts != null) {
				for(EBS_Account__c e : ebsAccounts) {
					addEBSAccount(e);
					System.debug('addEBSAccount='+e);
				}
			}
		}


		/**
		 * Get the best Address.
		 * 
		 * @param requireEBSMap true if the return id must be a key for the ebsAccountMapMap.
		 * @return best Address or null
		 */
		public Address__c getBestAddress(Boolean requireEBSMap) {
			Set<Id> accountIds = new Set<Id>(addressMapMap.keySet());
			if(requireEBSMap) {
				accountIds.retainAll(ebsAccountMapMap.keySet());
			}
			Id accountId = getSalesAccountId(accountIds,false);
			Address__c retval = null;
			if(accountId != null) {
				Map<Id,Address__c> addresses = addressMapMap.get(accountId);
				if(addresses != null && ! addresses.isEmpty()) {
					retval = addresses.values()[0];
				}
			}
			return retval;
		}

		/**
		 * Get the unique Address.
		 * @return unique Address or null
		 */
		public Address__c getAddress() {
			Address__c retval = null;
			if(addressMapMap.size() == 1) {
				Map<Id,Address__c> am = addressMapMap.values().get(0);
				if(am.size() == 1) {
					retval = am.values()[0];
				}
			}
			return retval;
		}

		/**
		 * Set the unique Address.  Use null to clear the map.
		 * 
		 * @param address the unique Address
		 */
		public void setAddress(Address__c address) {
			addressMapMap.clear();
			addAddress(address);
		}

		/**
		 * Add another Address.
		 * 
		 * @param address the Address to add
		 */
		public void addAddress(Address__c address) {
			if(address != null) {
				Map<Id,Address__c> am = addressMapMap.get(address.Sales_Account__c);
				if(am == null) {
					am = new Map<Id,Address__c>();
					addressMapMap.put(address.Sales_Account__c,am);
				}
				am.put(address.Id,address);
			}
		}

		/**
		 * Add all Addresses.
		 * 
		 * @param addresses the list of Addresses to add
		 */
		public void addAddresses(List<Address__c> addresses) {
			if(addresses != null) {
				for(Address__c a : addresses) {
					addAddress(a);
				}
			}
		}

		/**
		 * Get the best Contact.
		 * 
		 * @param requireEBSMap true if the return id must be a key (or cdh party id) for the ebsAccountMapMap.
		 * @return best Contact or null
		 */
		public Contact getBestContact(Boolean requireEBSMap) {
			Contact retval = null;
			if(! contactMapMap.isEmpty()) {
				Set<Id> accountIds = new Set<Id>(contactMapMap.keySet());
				if(requireEBSMap) {
					accountIds.retainAll(ebsAccountMapMap.keySet());
				}
				Id accountId = getSalesAccountId(accountIds,false);
				if(accountId != null) {
					Map<Id,Contact> contacts = contactMapMap.get(accountId);
					if(contacts != null && ! contacts.isEmpty()) {
						retval = contacts.values()[0];
					}
				}
				if(retval == null && accountMatching.allowContactOnDifferentAccount) {
					Set<Id> cdhPartyIds = getContactCDHPartyIds();
					if(requireEBSMap) {
						cdhPartyIds.retainAll(getEBSAccountCDHPartyIds());
					}
					Id cdhPartyId = getCDHPartyId(cdhPartyIds,false);
					if(cdhPartyId != null) {
						for(Map<Id,Contact> cm : contactMapMap.values()) {
							for(Contact c : cm.values()) {
								if( getCDHPartyIdFromAccount(c.Account,c.AccountId) == cdhPartyId) {
									retval = c;
								}
								break;
							}
							if(retval != null) {
								break;
							}
						}
					}
				}
			}
			return retval;
		}

		/**
		 * Get the unique Contact.
		 * @return unique Contact or null
		 */
		public Contact getContact() {
			Contact retval = null;
			if(contactMapMap.size() == 1) {
				Map<Id,Contact> cm = contactMapMap.values()[0];
				if(cm != null && cm.size() == 1) {
					retval = cm.values()[0];
				}
			}
			return retval;
		}

		/**
		 * Set the unique Contact.  Use null to clear the map.
		 * 
		 * @param contact the unique Contact
		 */
		public void setContact(Contact contact) {
			contactMapMap.clear();
			addContact(contact);
		}

		/**
		 * Add another Contact.
		 * 
		 * @param contact the Contact to add
		 */
		public void addContact(Contact contact) {
			if(contact != null) {
				Map<Id,Contact> cm = contactMapMap.get(contact.AccountId);
				if(cm == null) {
					cm = new Map<Id,Contact>();
					contactMapMap.put(contact.AccountId,cm);
				}
				cm.put(contact.Id,contact);
			}
		}

		/**
		 * Add all Contacts.
		 * 
		 * @param contacts the list of Contacts to add
		 */
		public void addContacts(List<Contact> contacts) {
			if(contacts != null) {
				for(Contact c : contacts) {
					addContact(c);
				}
			}
		}

		/**
		 * Retain only the specified cdh party ids.
		 *
		 * @param accountIds retained ids
		 */
		public void retainCDHPartyIds(Set<Id> cdhPartyIds) {
			Set<Id> accountIds = new Set<Id>();
			for(Map<Id,EBS_Account__c> em : ebsAccountMapMap.values()) {
				for(EBS_Account__c ebsAccount : em.values()) {
					if(cdhPartyIds.contains(getCDHPartyIdFromAccount(ebsAccount.Sales_Account__r,ebsAccount.Sales_Account__c))) {
						accountIds.add(ebsAccount.Sales_Account__c);
					}
					break;
				}
			}
			for(Map<Id,Address__c> am : addressMapMap.values()) {
				for(Address__c address : am.values()) {
					if(cdhPartyIds.contains(getCDHPartyIdFromAccount(address.Sales_Account__r,address.Sales_Account__c))) {
						accountIds.add(address.Sales_Account__c);
					}
					break;
				}
			}
			for(Map<Id,Contact> cm : contactMapMap.values()) {
				for(Contact contact : cm.values()) {
					if(cdhPartyIds.contains(getCDHPartyIdFromAccount(contact.Account,contact.AccountId))) {
						accountIds.add(contact.AccountId);
					}
				}
			}
			System.debug('ebsAccountMapMap.size()='+ebsAccountMapMap.size());
			ebsAccountMapMap.keySet().retainAll(accountIds);
			System.debug('ebsAccountMapMap.size()='+ebsAccountMapMap.size());
			System.debug('addressMapMap.size()='+addressMapMap.size());
			addressMapMap.keySet().retainAll(accountIds);
			System.debug('addressMapMap.size()='+addressMapMap.size());
			System.debug('contactMapMap.size()='+contactMapMap.size());
			contactMapMap.keySet().retainAll(accountIds);
			System.debug('contactMapMap.size()='+contactMapMap.size());
		}

		/**
		 * Retain only the specified account Ids.
		 *
		 * @param accountIds retained ids
		 * @param applyToContacts even if it removes all contacts
		 */
		public void retainAccountIds(Set<Id> accountIds) {
			if(! contactMapMap.isEmpty()) {
				Boolean needsContactOnDifferentAccount = false;
				if(accountMatching.allowContactOnDifferentAccount) {
					Set<Id> s = accountIds.clone();
					s.retainAll(contactMapMap.keySet());
					needsContactOnDifferentAccount = s.isEmpty();
				}
				if(needsContactOnDifferentAccount) {
					Map<Id,Id> m = getCDHPartyIdByAccountId().clone();
					m.keySet().retainAll(accountIds);
					retainCDHPartyIds(new Set<Id>(m.values()));
				}
				else {
					contactMapMap.keySet().retainAll(accountIds);
				}
			}
			ebsAccountMapMap.keySet().retainAll(accountIds);
			addressMapMap.keySet().retainAll(accountIds);
		}

		/**
		 * Retain only the specified cdh party ids, and if possible only the specified account
		 * 
		 * @param cdhPartyIds retained ids
		 * @param cdhPartyId only account id to retain if contained in accountIds
		 * @return the number of remaining account ids
		 */
		public Integer filterCDHPartyIds(Set<Id> cdhPartyIds, Id cdhPartyId) {
			if(! cdhPartyIds.isEmpty()) {
				if(cdhPartyId != null && cdhPartyIds.contains(cdhPartyId)) {
					cdhPartyIds = new Set<Id>{ cdhPartyId };
				}
				retainCDHPartyIds(cdhPartyIds);
			}
			cdhPartyIds = getEBSAccountCDHPartyIds().clone();
			cdhPartyIds.addAll(getAddressCDHPartyIds());
			cdhPartyIds.addAll(getContactCDHPartyIds());
			return cdhPartyIds.size();
		}

		/**
		 * Retain only the specified account ids, and if possible only the specified account
		 * 
		 * @param accountIds retained ids
		 * @param accountId only account id to retain if contained in accountIds
		 * @return the number of remaining account ids
		 */
		public Integer filterAccountIds(Set<Id> accountIds, Id accountId) {
			if(! accountIds.isEmpty()) {
				if(accountId != null && accountIds.contains(accountId)) {
					accountIds = new Set<Id>{ accountId };
				}
				retainAccountIds(accountIds);
			}
			accountIds = ebsAccountMapMap.keySet().clone();
			accountIds.addAll(addressMapMap.keySet());
			accountIds.addAll(contactMapMap.keySet());
			Integer s=accountIds.size();
			System.debug('accountIds.size()='+s);
			return s;
		}

		/**
		 * Find the best sales account ids.  We do this by filtering, prefering ebsAccountMapMap
		 * sales acconut ids over addressMapMap sales account ids over contactMapMap sales account ids.
		 * 
		 * @param requiredIds set of ids to union results with
		 * @param usecontactMapMap true if the contactMapMap sales account ids should be used as well.
		 * @return the best sales account ids
		 */
		public Set<Id> getSalesAccountIds(Set<Id> requiredIds, Boolean usecontactMapMap) {
			List<AccountMatchType> matchType = EBS_ADDRESS_ORDERING;
			if(usecontactMapMap) {
				matchType = EBS_ADDRESS_CONTACT_ORDERING;
			}
			return getSalesAccountIds(requiredIds,matchType,AccountMatchEmptyMode.LEFT_MODE);
		}

		/**
		 * Find the best sales account ids.  We do this by filtering, prefering ebsAccountMapMap
		 * sales account ids over addressMapMap sales acconut ids over contactMapMap sales account ids.  There are two modes
		 * of operation.  We step through the key sets in the required order.  The first non-empty set is set as
		 * the return set.  Then with each consecutive set we look at the intersection of that set with return 
		 * set.  If the intesection is not an empty set or we are in INTERSECT_MODE, we replace the return set with 
		 * the intersection and continue processing.  Otherwise, we just keep the current return set and continue.
		 * 
		 * Unfortunately, the LEFT_MODE, processing is order dependant, so that is why the processing order 
		 * must be specified.  Essentially in left mode we are allowing a return set that only includes 
		 * the earlier items on the list, if the intersections are empty.
		 * 
		 * @param requiredIds set of ids to union results with
		 * @param ordering list to determine processing order
		 * @param emptyMode determines action when the intersection between two sets is empty
		 * @return the best sales account ids
		 */
		public Set<Id> getSalesAccountIds(Set<Id> requiredIds,List<AccountMatchType> ordering, AccountMatchEmptyMode emptyMode) {
			Set<Id> salesAccountIds = new Set<Id>();
			if(requiredIds == null || ! requiredIds.isEmpty()) {
				for(AccountMatchType o : ordering) {
					Set<Id> s = null;
					if(o == AccountMatchType.EBS_MATCH) {
						s = ebsAccountMapMap.keySet().clone();
					}
					else if(o == AccountMatchType.ADDRESS_MATCH) {
						s = addressMapMap.keySet().clone();
					}
					else if(o == AccountMatchType.CONTACT_MATCH) {
						s = contactMapMap.keySet().clone();
					}
					if(s != null) {
						if(requiredIds != null) {
							s.retainAll(requiredIds);
						}
						if(emptyMode == AccountMatchEmptyMode.INTERSECT_MODE || ! s.isEmpty()) {
							requiredIds = salesAccountIds = s;
						}
					}
				}
			}
			return salesAccountIds;
		}

		/**
		 * Find one of the best sales account ids.
		 * 
		 * @param requiredIds set of ids to union results with
		 * @param usecontactMapMap true if the contactMapMap keys should be used as well.
		 * @return one ofthe best account ids
		 */
		public Id getSalesAccountId(Set<Id> requiredIds, Boolean usecontactMapMap) {
			Id retval = null;
			Iterator<Id> i = getSalesAccountIds(requiredIds,usecontactMapMap).iterator();
			if(i.hasNext()) {
				retval = i.next();
			}
			return retval;
		}

		/**
		 * Find account ids in both ebsAccountMapMap and addressMapMap.  If one of these
		 * maps is empty, return the non-empty set.
		 * 
		 * @return a set of account ids in both key maps
		 */
		public Set<Id> getSalesAccountIds() {
			return getSalesAccountIds(null,false);
		}

		private Map<Id,Id> getEBSAccountCDHPartyIdByAccountId() {
			Map<Id,Id> m = new Map<Id,Id>();
			for(Map<Id,EBS_Account__c> em : ebsAccountMapMap.values() ) {
				for(EBS_Account__c e : em.values()) {
					m.put(e.Sales_Account__c,getCDHPartyIdFromAccount(e.Sales_Account__r,e.Sales_Account__c));
					break;
				}
			}
			return m;
		}

		public Set<Id> getEBSAccountCDHPartyIds() {
			return new Set<Id>(getEBSAccountCDHPartyIdByAccountId().values());
		}

		private Map<Id,Id> getAddressCDHPartyIdByAccountId() {
			Map<Id,Id> m = new Map<Id,Id>();
			for(Map<Id,Address__c> am : addressMapMap.values() ) {
				for(Address__c a : am.values()) {
					m.put(a.Sales_Account__c,getCDHPartyIdFromAccount(a.Sales_Account__r,a.Sales_Account__c));
					break;
				}
			}
			return m;
		}

		public Set<Id> getAddressCDHPartyIds() {
			return new Set<Id>(getAddressCDHPartyIdByAccountId().values());
		}

		private Map<Id,Id> getContactCDHPartyIdByAccountId() {
			Map<Id,Id> m = new Map<Id,Id>();
			for(Map<Id,Contact> cm : contactMapMap.values() ) {
				for(Contact c : cm.values()) {
					m.put(c.AccountId,getCDHPartyIdFromAccount(c.Account,c.AccountId));
					break;
				}
			}
			return m;
		}

		public Set<Id> getContactCDHPartyIds() {
			return new Set<Id>(getContactCDHPartyIdByAccountId().values());
		}

		private Map<Id,Id> getCDHPartyIdByAccountId() {
			Map<Id,Id> m = getEBSAccountCDHPartyIdByAccountId().clone();
			m.putAll(getAddressCDHPartyIdByAccountId());
			m.putAll(getContactCDHPartyIdByAccountId());
			return m;
		}

		/**
		 * Find the best sales account CDH Party Ids.  We do this by filtering, prefering ebsAccountMapMap
		 * cdh party ids over addressMapMap cdh party ids over contactMapMap cdh party ids.
		 * 
		 * @param requiredIds set of ids to union results with
		 * @param usecontactMapMap true if the contactMapMap cdh party ids should be used as well.
		 * @return the best cdh party ids
		 */
		public Set<Id> getCDHPartyIds(Set<Id> requiredIds, Boolean usecontactMapMap) {
			List<AccountMatchType> matchType = EBS_ADDRESS_ORDERING;
			if(usecontactMapMap) {
				matchType = EBS_ADDRESS_CONTACT_ORDERING;
			}
			return getCDHPartyIds(requiredIds,matchType,AccountMatchEmptyMode.LEFT_MODE);
		}

		/**
		 * Find the best sales account CDH Party Ids.  We do this by filtering, prefering ebsAccountMapMap
		 * cdh party ids over addressMapMap cdh party ids over contactMapMap cdh party ids.  There are two modes
		 * of operation.  We step through the key sets in the required order.  The first non-empty set is set as
		 * the return set.  Then with each consecutive set we look at the intersection of that set with return 
		 * set.  If the intesection is not an empty set or we are in INTERSECT_MODE, we replace the return set with 
		 * the intersection and continue processing.  Otherwise, we just keep the current return set and continue.
		 * 
		 * Unfortunately, the LEFT_MODE, processing is order dependant, so that is why the processing order 
		 * must be specified.  Essentially in left mode we are allowing a return set that only includes 
		 * the earlier items on the list, if the intersections are empty.
		 * 
		 * @param requiredIds set of ids to union results with
		 * @param ordering list to determine processing order
		 * @param emptyMode determines action when the intersection between two sets is empty
		 * @return the best cdh party ids
		 */
		public Set<Id> getCDHPartyIds(Set<Id> requiredIds,List<AccountMatchType> ordering, AccountMatchEmptyMode emptyMode) {
			Set<Id> cdhPartyIds = new Set<Id>();
			if(requiredIds == null || ! requiredIds.isEmpty()) {
				for(AccountMatchType o : ordering) {
					Set<Id> s = null;
					if(o == AccountMatchType.EBS_MATCH) {
						if(! ebsAccountMapMap.isEmpty()) {
							s = getEBSAccountCDHPartyIds().clone();
						}
					}
					else if(o == AccountMatchType.ADDRESS_MATCH) {
						if(! addressMapMap.isEmpty()) {
							s = getAddressCDHPartyIds().clone();
						}
					}
					else if(o == AccountMatchType.CONTACT_MATCH) {
						if(! contactMapMap.isEmpty()) {
							s = getContactCDHPartyIds().clone();
						}
					}
					if(s != null) {
						if(requiredIds != null) {
							s.retainAll(requiredIds);
						}
						if(emptyMode == AccountMatchEmptyMode.INTERSECT_MODE || ! s.isEmpty()) {
							requiredIds = cdhPartyIds = s;
						}
					}
				}
			}
			return cdhPartyIds;
		}

		/**
		 * Find one of the best cdh party id.
		 * 
		 * @param requiredIds set of ids to union results with
		 * @param usecontactMapMap true if the contactMapMap keys should be used as well.
		 * @return one ofthe best account ids
		 */
		public Id getCDHPartyId(Set<Id> requiredIds,Boolean usecontactMapMap) {
			Id retval = null;
			Iterator<Id> i = getCDHPartyIds(requiredIds,usecontactMapMap).iterator();
			if(i.hasNext()) {
				retval = i.next();
			}
			return retval;
		}

		/**
		 * Find cdh party ids in both ebsAccountMapMap and addressMapMap.  If one of these
		 * maps is empty, return the non-empty set.
		 * 
		 * @return a set of account ids in both key maps
		 */
		public Set<Id> getCDHPartyIds() {
			return getCDHPartyIds(null,false);
		}


		/**
		 * Retrieve the first error or the first warning message.
		 *
		 * @return first message or a null value
		 */
		public String getFirstMessage() {
			String retval = null;
			if(! errorMessages.isEmpty()) {
				retval = errorMessages.get(0);
			}
			else if(! warnMessages.isEmpty()) {
				retval = warnMessages.get(0);
			}
			return retval;
		}

		/**
		 * Merge all error and warning messages.
		 * 
		 * @return all error and warning messages in a single string.
		 */
		public String getAllMessages() {
			String retval = '';
			String sep = '';
			for(String message : errorMessages) {
				retval += sep + message;
				sep = '\n';
			}
			for(String message : warnMessages) {
				retval += sep+message;
				sep = '  \n';
			}
			if(retval == '') {
				retval = null;
			}
			return retval;
		}

		/**
		 * Merge all error messages.
		 * 
		 * @return all error messages in a single string.
		 */
		public String getErrorMessages() {
			String retval = '';
			String sep = '';
			for(String message : errorMessages) {
				retval += sep + message;
				sep = '\n';
			}
			if(retval == '') {
				retval = null;
			}
			return retval;
		}

		protected virtual void filterEBSAccounts(Boolean xpreferSalesAccounts) {
			if(ebsAccountMapMap.size() >= MIN_FILTER_SIZE) {
				if(xpreferSalesAccounts) {
					filterEBSByRecordTypeName();
				}
				filterEBSByName();
				filterEBSBySalesAccountId();
				filterEBSByCDHPartyNumber();
				filterEBSByStatus();
			}
		}

		protected virtual void filterAddresses(Boolean xpreferSalesAccounts) {
			if(addressMapMap.size() >= MIN_FILTER_SIZE) {
				filterAddressByEBSAccounts();
				if(xpreferSalesAccounts) {
					filterAddressByRecordTypeName();
				}
				filterAddressBySalesAccountId();
				filterAddressByCDHPartySiteNumber();
				filterAddressByStatus(false,false);
			}
			filterEBSByAddresses();
		}

		protected virtual void filterContacts(Boolean xpreferSalesAccounts) {
			if(contactMapMap.size() >= MIN_FILTER_SIZE) {
				filterContactByEBSAccounts();
				filterContactByAddresses();
				if(xpreferSalesAccounts) {
					filterContactByRecordTypeName();
				}
				filterContactBySalesAccountId();
				filterContactByContactCDHPartyNumber();
				filterContactByStatus(false,false);
			}
			filterEBSByContacts();
			filterAddressByEBSAccounts();
			filterAddressByContacts();
		}

		/**
		 * Remove any EBS Account which does not have a matching oracle account number
		 * even if there are no matches.
		 */
		public void filterEBSByAccountNumbers() {
			System.debug('filterEBSByAccountNumbers '+oracleAccountNumbers);
			if(! oracleAccountNumbers.isEmpty()) {
				Map<Id,EBS_Account__c> xebsAccountMap = new Map<Id,EBS_Account__c>();
				for(Map<Id,EBS_Account__c> em : ebsAccountMapMap.values()) {
					for(EBS_Account__c xebsAccount : em.values()) {
						if(oracleAccountNumbers.contains(xebsAccount.Name)) {
							xebsAccountMap.put(xebsAccount.Id,xebsAccount);
						}
					}
				}
				setEBSAccount(null);
				addEBSAccounts(xebsAccountMap.values());
			}
		}

		/**
		 * Remove any EBS Account which does not have the same name as the refEBSAccount
		 * if there is at least one match.
		 */
		public void filterEBSByName() {
			if(refEBSAccount != null) {
				Map<Id,EBS_Account__c> xebsAccountMap = new Map<Id,EBS_Account__c>();
				for(Map<Id,EBS_Account__c> em : ebsAccountMapMap.values()) {
					for(EBS_Account__c xebsAccount : em.values()) {
						if(refEBSAccount.Name == xebsAccount.Name) {
							xebsAccountMap.put(xebsAccount.Id,xebsAccount);
						}
					}
				}
				if(! xebsAccountMap.isEmpty()) {
					setEBSAccount(null);
					addEBSAccounts(xebsAccountMap.values());
				}
			}
		}


		/**
		 * Remove any EBS Account, Address, and Contact which does not have a matching sales 
		 * account id if and only if there is at least one EBS Account with a matching sales 
		 * account id or cdh party id for contacts when allowContactOnDifferentAccount is true.
		 */
		public void filterEBSBySalesAccountId() {
			if(refSalesAccountId != null) {
				Map<Id,EBS_Account__c> em = ebsAccountMapMap.get(refSalesAccountId);
				if(em != null) {
					for(EBS_Account__c ebsAccount : em.values()) {
						Boolean allowContactOnDifferentAccount = accountMatching.allowContactOnDifferentAccount;
						retainAccountIds(new Set<Id>{refSalesAccountId});
						if(allowContactOnDifferentAccount) {
							retainCDHPartyIds(new Set<Id>{getCDHPartyIdFromAccount(ebsAccount.Sales_Account__r,refSalesAccountId)});
						}
						break;
					}
				}
			}
		}

		/**
		 * Remove any EBS Account which does not have a matching cdh party number if and only
		 * if there is at least one EBS Account with a matching cdh party number.
		 */
		public void filterEBSByCDHPartyNumber() {
			String xcdhPartyNumber = cdhPartyNumber;
			if(refEBSAccount != null && refEBSAccount.CDH_Party_Number__c != null) {
				xcdhPartyNumber = refEBSAccount.CDH_Party_Number__c;
			}
			if(xcdhPartyNumber != null) {
				Map<Id,EBS_Account__c> xebsAccountMap1 = new Map<Id,EBS_Account__c>();
				Map<Id,EBS_Account__c> xebsAccountMap2 = new Map<Id,EBS_Account__c>();
				Map<Id,EBS_Account__c> xebsAccountMap = xebsAccountMap1;
				for(Map<Id,EBS_Account__c> em : ebsAccountMapMap.values()) {
					for(EBS_Account__c xebsAccount : em.values()) {
						if(xcdhPartyNumber == xebsAccount.CDH_Party_Number__c) {
							xebsAccountMap = xebsAccountMap2;
							xebsAccountMap.put(xebsAccount.Id,xebsAccount);
						}
						else if(cdhPartyNumbers.contains(xebsAccount.CDH_Party_Number__c)) {
							xebsAccountMap1.put(xebsAccount.Id,xebsAccount);
						}
					}
				}
				if(!xebsAccountMap.isEmpty()) {
					setEBSAccount(null);
					addEBSAccounts(xebsAccountMap.values());
				}
			}
		}

		/**
		 * Remove any EBS Account which has a status of Inactive if and only
		 * if there is at least one EBS Account without a status.
		 */
		public void filterEBSByStatus() {
			filterEBSByStatus(false,false);
		}

		/**
		 * Remove any EBS Account which has a status of Inactive if and only
		 * if there is at least one EBS Account without a status of Inactive
		 * or the mustBeActive flag is true.
		 * 
		 * @param mustBeActive
		 * @param keepNonDuplicates
		 */
		public void filterEBSByStatus(Boolean mustBeActive,Boolean keepNonDuplicates) {
			Map<Id,EBS_Account__c> xebsAccountMap = new Map<Id,EBS_Account__c>();
			for(Map<Id,EBS_Account__c> em : ebsAccountMapMap.values()) {
				for(EBS_Account__c xebsAccount : em.values()) {
					if(xebsAccount.Status__c != 'Inactive'
						|| (keepNonDuplicates && xebsAccount.MasterRecord__c == null) )
					{
						xebsAccountMap.put(xebsAccount.Id,xebsAccount);
					}
				}
			}
			if(mustBeActive|| !xebsAccountMap.isEmpty()) {
				setEBSAccount(null);
				addEBSAccounts(xebsAccountMap.values());
			}
		}

		/**
		 * Remove any EBS Account which is a partner if an only if there is at least
		 * one EBS Account which is not a partner.
		 */
		public void filterEBSByRecordTypeName() {
			filterEBSByRecordTypeName(true,'SALES');
		}

		/**
		 * Remove any EBS Account which does not match the specified sales account record type name.  A special
		 * value of SALES removes all partner accounts.
		 * 
		 * @param doNotRemoveAll - if false remove partner accounts even if that removes everything
		 * @param accountRecordTypeName value to match
		 */
		public void filterEBSByRecordTypeName(Boolean doNotRemoveAll,String recordTypeName) {
			Map<Id,EBS_Account__c> xebsAccountMap = new Map<Id,EBS_Account__c>();
			for(Map<Id,EBS_Account__c> em : ebsAccountMapMap.values()) {
				for(EBS_Account__c xebsAccount : em.values()) {
					if(xebsAccount.Sales_Account__r != null 
						&& ( ( recordTypeName == 'SALES' && ! isPartner(xebsAccount) ) 
							|| recordTypeName == getAccountRecordTypeName(xebsAccount) ) )
					{
						xebsAccountMap.put(xebsAccount.Id,xebsAccount);
					}
				}
			}
			if(! (doNotRemoveAll && xebsAccountMap.isEmpty()) ) {
				setEBSAccount(null);
				addEBSAccounts(xebsAccountMap.values());
			}
		}

		/**
		 * Remove any Address which does not have a matching sales account in the EBS matches
		 * provided there is at least one match...
		 */
		public void filterAddressByEBSAccounts() {
			if( addressMapMap.size() >= MIN_FILTER_SIZE && ! ebsAccountMapMap.isEmpty()) {
				Set<Id> accountIds = addressMapMap.keySet().clone();
				accountIds.retainAll(ebsAccountMapMap.keySet());
				if(! accountIds.isEmpty()) {
					addressMapMap.keySet().retainAll(accountIds);
				}
			}
		}


		/**
		 * Remove any Address which is a partner if an only if there is at least
		 * one Address which is not a partner.
		 */
		public void filterAddressByRecordTypeName() {
			filterAddressByRecordTypeName( true,'SALES' );
		}

		/**
		 * Remove any Address which does not match the specified sales account record type name.  A special
		 * value of SALES removes all partner accounts.
		 * 
		 * @param doNotRemoveAll - if false remove partner accounts even if that removes everything
		 * @param accountRecordTypeName value to match
		 */
		public void filterAddressByRecordTypeName(Boolean doNotRemoveAll,String recordTypeName) {
			Map<Id,Address__c> xaddressMap = new Map<Id,Address__c>();
			for(Map<Id,Address__c> am : addressMapMap.values()) {
				for(Address__c xaddress : am.values()) {
					if(xaddress.Sales_Account__r != null 
						&& ( ( recordTypeName == 'SALES' && ! isPartner(xaddress) ) 
							|| recordTypeName == getAccountRecordTypeName(xaddress) ) )
					{
						xaddressMap.put(xaddress.Id,xaddress);
					}
				}
			}
			if(! ( doNotRemoveAll && xaddressMap.isEmpty() ) ) {
				setAddress(null);
				addAddresses(xaddressMap.values());
			}
		}

		/**
		 * Remove any Address which has a status of Inactive if and only
		 * if there is at least one Address without a status of Inactive
		 * or the mustBeActive flag is true.
		 * 
		 * @param mustBeActive
		 * @param keepNonDuplicates
		 */
		public void filterAddressByStatus(Boolean mustBeActive,Boolean keepNonDuplicates) {
			Map<Id,Address__c> xaddressMap = new Map<Id,Address__c>();
			for(Map<Id,Address__c> am : addressMapMap.values()) {
				for(Address__c xaddress : am.values()) {
					if((xaddress.Status__c != 'Inactive' && xaddress.Status__c != 'Merged')
						|| (keepNonDuplicates && xaddress.MasterRecord__c == null && xaddress.IsDuplicate__c != true) )
					{
						xaddressMap.put(xaddress.Id,xaddress);
					}
				}
			}
			if( mustBeActive || ! xaddressMap.isEmpty() ) {
				setAddress(null);
				addAddresses(xaddressMap.values());
			}
		}

		/**
		 * Remove any Address which does not have a matching sales account id if and only
		 * if there is at least one Address with a matching sales account id.
		 */
		public void filterAddressBySalesAccountId() {
			if(refSalesAccountId != null && addressMapMap.containsKey(refSalesAccountId)) {
				addressMapMap.keySet().retainAll(new Set<Id>{refSalesAccountId});
			}
		}

		/**
		 * Remove any Address which does not have a matching cdh party site number if and only
		 * if there is at least one Address with a matching cdh party site number.
		 */
		public void filterAddressByCDHPartySiteNumber() {
			String xcdhPartySiteNumber = cdhPartySiteNumber;
			if(refAddress != null && refAddress.CDH_Party_Site_Number__c != null) {
				xcdhPartySiteNumber = refAddress.CDH_Party_Site_Number__c;
			}
			if(xcdhPartySiteNumber != null) {
				Map<Id,Address__c> xaddressMap1 = new Map<Id,Address__c>();
				Map<Id,Address__c> xaddressMap2 = new Map<Id,Address__c>();
				Map<Id,Address__c> xaddressMap = xaddressMap1;
				for(Map<Id,Address__c> am : addressMapMap.values()) {
					for(Address__c xaddress : am.values()) {
						if(xcdhPartySiteNumber == xaddress.CDH_Party_Site_Number__c) {
							xaddressMap = xaddressMap2;
							xaddressMap.put(xaddress.Id,xaddress);
						}
						else if(cdhPartySiteNumbers.contains(xaddress.CDH_Party_Site_Number__c)) {
							xaddressMap1.put(xaddress.Id,xaddress);
						}
					}
				}
				if(!xaddressMap.isEmpty()) {
					setAddress(null);
					addAddresses(xaddressMap.values());
				}
			}
		}

		/**
		 * Remove any EBS Account which does not have a matching sales account in the Addres matches
		 * provided there is at least one match...
		 */
		public void filterEBSByAddresses() {
			if(ebsAccountMapMap.size() >= MIN_FILTER_SIZE && ! addressMapMap.isEmpty()) {
				Set<Id> accountIds = addressMapMap.keySet().clone();
				accountIds.retainAll(ebsAccountMapMap.keySet());
				if(! accountIds.isEmpty()) {
					ebsAccountMapMap.keySet().retainAll(accountIds);
				}
			}
		}

		/**
		 * Remove any Contact which does not have a matching sales account in the EBS matches
		 * provided there is at least one match...
		 */
		public void filterContactByEBSAccounts() {
			if( contactMapMap.size() >= MIN_FILTER_SIZE && ! ebsAccountMapMap.isEmpty()) {
				Set<Id> accountIds = contactMapMap.keySet().clone();
				accountIds.retainAll(ebsAccountMapMap.keySet());
				if(accountIds.isEmpty()) {
					Set<Id> cdhPartyIds = getEBSAccountCDHPartyIds();
					for(Map<Id,Contact> cm : contactMapMap.values()) {
						for(Contact c : cm.values()) {
							if(cdhPartyIds.contains(getCDHPartyIdFromAccount(c.Account,c.AccountId))) {
								accountIds.add(c.AccountId);
							}
						}
					}
				}
				if(! accountIds.isEmpty()) {
					contactMapMap.keySet().retainAll(accountIds);
				}
			}
		}

		/**
		 * Remove any Contact which does not have a matching sales account in the EBS matches
		 * provided there is at least one match...
		 */
		public void filterContactByAddresses() {
			if( contactMapMap.size() >= MIN_FILTER_SIZE && ! addressMapMap.isEmpty()) {
				Set<Id> accountIds = contactMapMap.keySet().clone();
				accountIds.retainAll(addressMapMap.keySet());
				if(accountMatching.allowContactOnDifferentAccount && accountIds.isEmpty()) {
					Set<Id> cdhPartyIds = getAddressCDHPartyIds();
					for(Map<Id,Contact> cm : contactMapMap.values()) {
						for(Contact c : cm.values()) {
							if(cdhPartyIds.contains(getCDHPartyIdFromAccount(c.Account,c.AccountId))) {
								accountIds.add(c.AccountId);
							}
						}
					}
				}
				if(! accountIds.isEmpty()) {
					contactMapMap.keySet().retainAll(accountIds);
				}
			}
		}

		/**
		 * Remove any Contact which is a partner if an only if there is at least
		 * one Contact which is not a partner.
		 */
		public void filterContactByRecordTypeName() {
			filterContactByRecordTypeName( true, 'SALES' );
		}

		/**
		 * Remove any Contact which does not match the specified sales account record type name.  A special
		 * value of SALES removes all partner accounts.
		 * 
		 * @param doNotRemoveAll - if false remove partner accounts even if that removes everything
		 * @param accountRecordTypeName value to match
		 */
		public void filterContactByRecordTypeName( Boolean doNotRemoveAll, String recordTypeName ) {
			Map<Id,Contact> xcontactMap = new Map<Id,Contact>();
			for(Map<Id,Contact> cm : contactMapMap.values()) {
				for(Contact xcontact : cm.values()) {
					if(xcontact.Account != null 
						&& ( ( recordTypeName == 'SALES' && ! isPartner(xcontact) ) 
							|| recordTypeName == getAccountRecordTypeName(xcontact) ) )
					{
						xcontactMap.put(xcontact.Id,xcontact);
					}
				}
			}
			if(! (doNotRemoveAll && xcontactMap.isEmpty()) ) {
				setContact(null);
				addContacts(xcontactMap.values());
			}
		}

		/**
		 * Remove any Contact which has a status of Inactive if and only
		 * if there is at least one Address without a status of Inactive
		 * or the mustBeActive flag is true.
		 * 
		 * @param mustBeActive
		 * @param keepNonDuplicates
		 */
		public void filterContactByStatus(Boolean mustBeActive,Boolean keepNonDuplicates) {
			Map<Id,Contact> xcontactMap = new Map<Id,Contact>();
			for(Map<Id,Contact> cm : contactMapMap.values()) {
				for(Contact xcontact : cm.values()) {
					if(xcontact.Status__c != 'Inactive'
						|| (keepNonDuplicates && xcontact.MasterRecord__c == null) )
					{
						xcontactMap.put(xcontact.Id,xcontact);
					}
				}
			}
			if( mustBeActive || ! xcontactMap.isEmpty() ) {
				setContact(null);
				addContacts(xcontactMap.values());
			}
		}


		/**
		 * Remove any Contact which does not have a matching sales account id if and only
		 * if there is at least one contact with a matching sales account id.
		 * Remove any Contact which does not have a matching cdh party id if and only
		 * if there is at least one contact with a matching cdh party id.
		 */
		public void filterContactBySalesAccountId() {
			if(refSalesAccountId != null) {
				if(contactMapMap.containsKey(refSalesAccountId)) {
					contactMapMap.keySet().retainAll(new Set<Id>{refSalesAccountId});
				}
				else if(accountMatching.allowContactOnDifferentAccount) {
					Id cdhPartyId = getCDHPartyIdFromAccount(refSalesAccount,null);
					if(cdhPartyId == null) {
						cdhPartyId = getCDHPartyIdByAccountId().get(refSalesAccountId);
					}
					if(cdhPartyId != null) {
						Set<Id> accountIds = new Set<Id>();
						for(Map<Id,Contact> cm : contactMapMap.values()) {
							for(Contact c : cm.values()) {
								if(cdhPartyId == getCDHPartyIdFromAccount(c.Account,null)) {
									accountIds.add( c.AccountId );
								}
								break;
							}
						}
						if(! accountIds.isEmpty()) {
							contactMapMap.keySet().retainAll( accountIds );
						}
					}
				}
			}
		}

		/**
		 * Remove any Contact which does not have a matching cdh party number if and only
		 * if there is at least one Contact with a matching cdh party number.
		 */
		public void filterContactByContactCDHPartyNumber() {
			String xcontactCDHPartyNumber = contactCDHPartyNumber;
			if(refContact != null && refContact.CDH_Party_Number__c != null) {
				xcontactCDHPartyNumber = refContact.CDH_Party_Number__c;
			}
			if(xcontactCDHPartyNumber != null) {
				Map<Id,Contact> xcontactMap1 = new Map<Id,Contact>();
				Map<Id,Contact> xcontactMap2 = new Map<Id,Contact>();
				Map<Id,Contact> xcontactMap = xcontactMap1;
				for(Map<Id,Contact> cm : contactMapMap.values()) {
					for(Contact xcontact : cm.values()) {
						if(xcontactCDHPartyNumber == xcontact.CDH_Party_Number__c) {
							xcontactMap = xcontactMap2;
							xcontactMap.put(xcontact.Id,xcontact);
						}
						else if(contactCDHPartyNumbers.contains(xcontact.CDH_Party_Number__c)) {
							xcontactMap1.put(xcontact.Id,xcontact);
						}
					}
				}
				if(!xcontactMap.isEmpty()) {
					setContact(null);
					addContacts(xcontactMap.values());
				}
			}
		}

		/**
		 * Remove any EBS Account which does not have a matching sales account in the Contact matches
		 * provided there is at least one match...
		 */
		public void filterEBSByContacts() {
			if( ebsAccountMapMap.size() >= MIN_FILTER_SIZE && ! contactMapMap.isEmpty()) {
				Set<Id> accountIds = contactMapMap.keySet().clone();
				accountIds.retainAll(ebsAccountMapMap.keySet());
				if(accountMatching.allowContactOnDifferentAccount && accountIds.isEmpty()) {
					Set<Id> cdhPartyIds = getContactCDHPartyIds();
					for(Map<Id,EBS_Account__c> em : ebsAccountMapMap.values()) {
						for(EBS_Account__c e : em.values()) {
							if(cdhPartyIds.contains(getCDHPartyIdFromAccount(e.Sales_Account__r,e.Sales_Account__c))) {
								accountIds.add(e.Sales_Account__c);
							}
						}
					}
				}
				if(! accountIds.isEmpty()) {
					ebsAccountMapMap.keySet().retainAll(accountIds);
				}
			}
		}

		/**
		 * Remove any Address which does not have a matching sales account in the Contact matches
		 * provided there is at least one match...
		 */
		public void filterAddressByContacts() {
			if( addressMapMap.size() >= MIN_FILTER_SIZE && ! contactMapMap.isEmpty()) {
				Set<Id> accountIds = addressMapMap.keySet().clone();
				accountIds.retainAll(addressMapMap.keySet());
				if(accountMatching.allowContactOnDifferentAccount && accountIds.isEmpty()) {
					Set<Id> cdhPartyIds = getContactCDHPartyIds();
					for(Map<Id,Address__c> am : addressMapMap.values()) {
						for(Address__c a : am.values()) {
							if(cdhPartyIds.contains(getCDHPartyIdFromAccount(a.Sales_Account__r,a.Sales_Account__c))) {
								accountIds.add(a.Sales_Account__c);
							}
						}
					}
				}
				if(! accountIds.isEmpty()) {
					addressMapMap.keySet().retainAll(accountIds);
				}
			}
		}

		/**
		 * Called to filter the set of sales account id by super region
		 */
		public void filterBySuperRegion(Map<Id,Account> accountMap) {
			if(superRegion != null) {
				if(ebsAccountMapMap.size() >= MIN_FILTER_SIZE) {
					ebsAccountMapMap.keySet().retainAll(filterAccountIdsBySuperRegion(accountMap,ebsAccountMapMap.keySet()));
				}
				if(addressMapMap.size() >= MIN_FILTER_SIZE) {
					addressMapMap.keySet().retainAll(filterAccountIdsBySuperRegion(accountMap,addressMapMap.keySet()));
				}
				if(contactMapMap.size() >= MIN_FILTER_SIZE) {
					contactMapMap.keySet().retainAll(filterAccountIdsBySuperRegion(accountMap,contactMapMap.keySet()));
				}
			}
		}

		/**
		 * Called to filter a set of account ids to those matching the super region.
		 * If the results are empty, return the original set.
		 */
		public Set<Id> filterAccountIdsBySuperRegion(Map<Id,Account> accountMap,Set<Id> accountIds) {
			Set<Id> matchingIds = new Set<Id>();
			if(superRegion != null) {
				String xsuperRegion = superRegion;
				if(xsuperRegion == 'JAPAN') {
					xsuperRegion = 'APAC';
				}
				for(Id accountId : accountIds) {
					Account a = accountMap.get(accountId);
					if(a != null && a.RecordType != null && a.RecordType.Name != null) {
						String recordTypeName = a.RecordType.Name;
						if(a.RecordType.Name.containsIgnoreCase(xsuperRegion)
							|| (xsuperRegion == 'NA' && recordTypeName == 'Fed/Sled'))
						{
							matchingIds.add(a.Id);
						}
					}
				}
			}
			if(matchingIds.isEmpty()) {
				matchingIds.addAll(accountIds);
			}
			return matchingIds;
		}

		/**
		 * Called to filter the set of addresses by country.
		 */
		public void filterByCountry() {
			if(country != null && addressMapMap.size() >= MIN_FILTER_SIZE) {
				Map<Id,Map<Id,Address__c>> xaddressMapMap = new Map<Id,Map<Id,Address__c>>();
				for(Id accountId : addressMapMap.keySet()) {
					for(Address__c a : addressMapMap.get(accountId).values()) {
						if(country == a.Country__c) {
							Map<Id,Address__c> am = xaddressMapMap.get(accountId);
							if(am == null) {
								am = new Map<Id,Address__c>();
								xaddressMapMap.put(accountId,am);
							}
							am.put(a.Id,a);
						}
					}
				}
				if(! xaddressMapMap.isEmpty()) {
					addressMapMap = xaddressMapMap;
					retainAccountIds(xaddressMapMap.keySet());
				}
			}
		}

		/**
		 * Called to filter all but the most recent contact per sales account id
		 * with a matching e-mail address.  Provided of course there is at least
		 * one contact with a matching e-mail address.
		 */
		public void filterByEmail() {
			if(email != null && contactMapMap.size() >= MIN_FILTER_SIZE) {
				String email2 = email+CONTACT_EMAIL_SUFFIX;
				Map<Id,Contact> xcontactMap = new Map<Id,Contact>();
				Set<Id> cdhPartyIds = null;
				if( accountMatching.allowContactOnDifferentAccount ) {
					cdhPartyIds = new Set<Id>();
				}
				for(Id accountId : contactMapMap.keySet()) {
					Contact c = null;
					for(Contact c2 : contactMapMap.get(accountId).values()) {
						if(c2.Email == email || c2.Email == email2) {
							if(c == null || c.LastModifiedDate < c2.LastModifiedDate) {
								c = c2;
							}
						}
					}
					if(c != null) {
						if( cdhPartyIds != null ) {
							cdhPartyIds.add( getCDHPartyIdFromAccount(c.Account,accountId) );
						}
						xcontactMap.put( accountId ,c );
					}
				}
				if(! xcontactMap.isEmpty()) {
					contactMapMap.clear();
					for(Contact c : xcontactMap.values()) {
						contactMapMap.put(c.AccountId,new Map<Id,Contact>{c.Id=>c});
					}
					if( cdhPartyIds != null ) {
						retainCDHPartyIds( cdhPartyIds );
					}
					else {
						retainAccountIds(xcontactMap.keySet());
					}
				}
			}
		}
	}
}