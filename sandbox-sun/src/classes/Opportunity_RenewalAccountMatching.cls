/**
 * This class implements account the renewals rest service account
 * matching logic for the c360 environment.
 * 
 * @version 2015-03-18
 * @author  Bryan Bosely <bbosely@rehat.com>
 * 2011-10-10 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2015-03-18 - Consider Sold To sales account if Entitle To sales account does not give us a valid result
 * 2015-03-11 - Correct account id to use entitle to party
 * 2015-02-24 - Added filtering for legal entity account id
 * 2015-01-06 - update account matching logic
 * 2014-12-04 - Added support for opportunity line item id passed to account matching
 * 2014-12-02 - Updated for C360
 * Scott Coleman <scoleman@redhat.com>
 * 2015-07-16 - Replacing addressesMap with addressMapMap in createAddresses() so class will compile
 */
public with sharing class Opportunity_RenewalAccountMatching 
{
	/** BooleanSetting__c key to enable the createAddresses method. */
	public static final String CREATE_ADDRESSES_SETTING = 'Opp_RAM.createAddresses';
	public static final String SALESFORCE_MSG_NAMESPACE = 'http://salesforce.redhat.com/renewals';
	private static final String STATUS_SUCCESS = 'SUCCESS';
	private static final String STATUS_WARN = 'WARNING';
	private static final String STATUS_ERROR = 'ERROR';

	@TestVisible
	private AccountQuery accountQuery = null;


	/**
	 * query an account
	 *
	 * @param   String xmlDocument
	 * @return  String
	 **/
	 
	public String queryAccount( String xmlDocument ) 
	{
		// generate the account matching class hierarchy from the XML
		//
		MatchingMessage message = new MatchingMessage();
		message.unmarshal( xmlDocument, SALESFORCE_MSG_NAMESPACE );
		accountQuery = message.query;

		// Now create a renewals account matching object
		Account_Matching_Renewals accountMatching = new Account_Matching_Renewals(
			accountQuery.renewalMappings );

		// Do an initial source opportunity mapping as specified in SDFC.BR 6
		accountMatching.preAssignRefOppId();

		// all parties should get the same mapping, so we only need to look at the first one
		Id oppId = null;
		if(! accountQuery.renewalMappings.isEmpty()) {
			oppId =  accountQuery.renewalMappings.get(0).refOppId;
		}

		// Find the account based on the source opportunity.
		//
		Account account = null;
		if(oppId != null) {
			for(Account a : [
				select 
					Name,
					Named_Account__c,
					OwnerId,
					Owner.IsActive,
					Owner.Name,
					Owner.UserRole.Name
				from Account
				where Id in (select AccountId from Opportunity where Id = :oppId)
				limit 1 ] )
			{
				account = a;
			}
		}

		// store the source opportunity id
		if(! accountQuery.renewalMappings.isEmpty()) {
			accountQuery.sourceOpportunityId =  accountQuery.renewalMappings.get(0).refOppId;
		}

		// Now, try harder to assign the source opportunity id
		accountMatching.assignRefOppId();

		// Do the full matching
		accountMatching.match();

		// filter the matches
		accountMatching.filter();

		// try to find the account based on the entitle to party
		if(account == null) {
			for(Id accountId : new List<Id> {
				getSalesAccountId(accountQuery.entitleToParty.renewalParty.getBestEBSAccount()),
				getSalesAccountId(accountQuery.soldToParty.renewalParty.getBestEBSAccount()) } )
			{
				if(accountId != null) {
					for(Account a : [
						select 
							Name,
							Named_Account__c,
							OwnerId,
							Owner.IsActive,
							Owner.Name,
							Owner.UserRole.Name
						from Account
						where Id = :accountId
						limit 1 ] )
					{
						account = a;
						break;
					}
				}
			}
		}

		if(account != null) {
			for(Party party : accountQuery.parties) {
				party.renewalParty.filterAccountIds(party.renewalParty.getSalesAccountIds(),account.Id);
			}
		}

		if(AbstractTrigger.isActive(CREATE_ADDRESSES_SETTING,false)) {
			createAddresses();
		}

		// report errors 
		accountMatching.errorsAndWarningsReporting();

		// set the return status values
		for(Party party : accountQuery.parties) {
			party.ebsAccount = party.renewalParty.getBestEBSAccount();
			String xmessage = party.renewalParty.getErrorMessages();
			String xstatus = STATUS_ERROR;
			if(xmessage == null) {
				xmessage = party.renewalParty.getAllMessages();
				xstatus = STATUS_WARN;
			}
			if(xmessage != null) {
				party.status = xstatus;
				party.message = xmessage;
			}
		}

		if(account != null) {
			sObject owner = account.getSObject( 'Owner' );
			sObject userRole = owner.getSObject( 'UserRole' );
			
			accountQuery.namedAccount = String.valueOf(account.Named_Account__c);
			accountQuery.salesforceAccountId = account.Id;
			accountQuery.salesforceAccountName = account.Name;
			accountQuery.salesforceAccountOwnerId = account.OwnerId;
			if(account.Owner != null) {
				accountQuery.salesRepOnAccount = account.Owner.Name;
				accountQuery.salesRepOnAccountActive = String.valueOf(account.Owner.IsActive);
				if(account.Owner.UserRole != null) {
					accountQuery.salesRepRoleOnAccount = account.Owner.UserRole.Name;
				}
			}
			system.debug( 'Account.Named Account: ' + accountQuery.namedAccount );
			system.debug( 'Account.Id: ' + accountQuery.salesforceAccountId );
			system.debug( 'Account.Name: ' + accountQuery.salesforceAccountName );
			system.debug( 'Account.Owner Id: ' + accountQuery.salesforceAccountOwnerId );
			system.debug( 'Account.Sales Rep On Account: ' + accountQuery.salesRepOnAccount );
			system.debug( 'Account.Sales Rep Role On Account: ' + accountQuery.salesRepRoleOnAccount );  
		}
		else
		{
			// accountQuery.status = STATUS_ERROR;
			accountQuery.errorMessage = 'Unable to locate an account';
		}

		// generate the response message
		String response = message.marshal();
		system.debug( 'Response XML: ' + response );
		
		return response;
	}

	@TestVisible
	// This probably isn't creating a valid address as we aren't assigning
	// CDH_Party__c and we always assign both State__c and Province__c.
	private void createAddresses() {
		Map<String,Address__c> addressMap = new Map<String,Address__c>();
		List<Party> parties = new List<Party>();
		for(Party party : accountQuery.parties) {
			if(party.cdhPartySiteNumber != null && party.country != null) {
				EBS_Account__c ebsAccount = party.renewalParty.getEBSAccount();
				if(ebsAccount != null && party.renewalParty.addressMapMap.isEmpty()) {
					parties.add(party);
					String key = ebsAccount.Sales_Account__c+':'+party.cdhPartySiteNumber+':'+party.country;
					Address__c address = addressMap.get(key);
					if(address == null) {
						address = new Address__c(
							CDH_Party_Site_Number__c = party.cdhPartySiteNumber,
							Address_Line1__c = truncate(party.address1,240),
							Address_Line2__c = truncate(party.address2,240),
							City__c = party.city,
							Country__c = party.country,
							Province__c = party.state,
							State__c = party.state,
							Zip_Postal_Code__c = party.postalCode,
							Status__c = 'Active',
							Sales_Account__r = ebsAccount.Sales_Account__r,
							Sales_Account__c = ebsAccount.Sales_Account__c,
							Bill_To_Address__c = false,
							Entitle_To_Address__c = false,
							Ship_To_Address__c = false,
							Sold_To_Address__c = false );
					}
					address.Bill_To_Address__c = address.Bill_To_Address__c || (party.toType == Account_Matching.AccountToType.BILL_TO);
					address.Entitle_To_Address__c = address.Entitle_To_Address__c || (party.toType == Account_Matching.AccountToType.ENTITLE_TO) || (party.toType == Account_Matching.AccountToType.LINE_ENTITLE_TO);
					address.Ship_To_Address__c = address.Ship_To_Address__c || (party.toType == Account_Matching.AccountToType.SHIP_TO);
					address.Sold_To_Address__c = address.Sold_To_Address__c || (party.toType == Account_Matching.AccountToType.SOLD_TO);
					addressMap.put(key,address);
				}
			}
		}
		if(! addressMap.isEmpty()) {
			Database.insert(addressMap.values(),false);
			for(Party party : parties) {
				EBS_Account__c ebsAccount = party.renewalParty.getEBSAccount();
				String key = ebsAccount.Sales_Account__c+':'+party.cdhPartySiteNumber+':'+party.country;
				Address__c address = addressMap.get(key);
				if(address.Id != null) {
					party.renewalParty.setAddress(address);
				}
			}
		}
	}

	/**
	 * class to model the renewal message
	 */
	@TestVisible
	class MatchingMessage
	{
		Header header;
		AccountQuery query;

		/**
		 * constructor
		 */
		MatchingMessage()
		{
			this.header = new Header();
			this.query = new AccountQuery();
		}

		/**
		 * Populates opportunity renewal class hierarchy from XML
		 *
		 * @param xmlDocument
		 * @param namespace
		 */
		@TestVisible
		void unmarshal( String xmlDocument, String namespace )
		{
			DOM.Document document = new DOM.Document();
			document.load(xmlDocument);

			system.debug( 'Document:' + document );
			system.debug( 'Root Element:' + document.getRootElement() );

			for(DOM.XmlNode node : document.getRootElement().getChildElements()) 
			{
				if (node.getName() == 'Header') 
				{
					this.header.unmarshal( node, namespace );   
				}
				
				if (node.getName() == 'Payload') 
				{
					DOM.XMLNode accountQueryNode = node.getChildElement( 'AccountQuery', namespace );
					System.assertNotEquals(null,accountQueryNode,node);
					system.debug( 'Account Query Node: ' + accountQueryNode );
					this.query.unmarshal( accountQueryNode, namespace );
				}
			}
		}

		/**
		 * method for marshalling the renewal class hierarchy back to XML
		 *
		 * @return String
		 */
		String marshal()
		{
			DOM.Document response = new DOM.Document();
			DOM.xmlNode salesForceMessage = response.createRootElement( 'SalesforceMessage', '', '' );

			// generate header node
			this.header.marshal( salesForceMessage, '' );

			// generate payload node
			DOM.xmlNode payload = salesForceMessage.addChildElement( 'Payload', '', '' );

			// generate account query node
			this.query.marshal( payload, '' );
 
			return response.toXmlString();
		}
	}

	private static String getText(DOM.XmlNode node) {
		String text = null;
		if(node != null) {
			text = node.getText();
			if(text == '') {
				text = null;
			}
		}
		return text;
	}

	private static String getChildNodeText(DOM.XmlNode node, String name, String namespace) {
		return getText( node.getChildElement( name, namespace ) );
	}

	private static void addTextNode( DOM.XmlNode node, String text) {
		if(text == null) {
			text = '';
		}
		node.addTextNode( text );
	}

	private static Id getSObjectId( SObject o ) {
		Id retval = null;
		if(o != null) {
			retval = o.Id;
		}
		return retval;
	}

	private static Id getSalesAccountId( EBS_Account__c o ) {
		Id retval = null;
		if(o != null) {
			retval = o.Sales_Account__c;
		}
		return retval;
	}

	private static String truncate(String value, Integer length) {
		String retval = '';
		if(value != null) {
			retval = value;
			if(retval.length() > length) {
				retval = retval.substring(0,length);
			}
		}
		return retval;
	}

	/**
	 * class to model the renewal header
	 **/
	@TestVisible 
	class Header 
	{
		String instanceId;
		String operation;
		String opportunityType;
		@TestVisible
		String timestamp;

		/**
		 * Populates opportunity renewal header from XML
		 *
		 * @param DOM.Xmlnode   node
		 * @param String		namespace
		 **/
		void unmarshal( DOM.Xmlnode node, String namespace )
		{
			this.instanceId = getChildNodeText( node, 'InstanceId', namespace );
			this.operation = getChildNodeText( node, 'Operation', namespace );
			this.opportunityType = getChildNodeText( node, 'Type', namespace );
			this.timestamp = getChildNodeText( node, 'Timestamp', namespace );
		}

		/**
		 * method for marshalling an object to XML
		 *
		 * @param DOM.Xmlnode   node 
		 **/
		 
		void marshal( DOM.Xmlnode node, String namespace )
		{
			DOM.xmlNode header = node.addChildElement( 'Header', namespace, '' );
			addTextNode( header.addChildElement( 'Operation', namespace, '' ), this.operation );
			addTextNode( header.addChildElement( 'Type', namespace, '' ), this.opportunityType );
			addTextNode( header.addChildElement( 'InstanceId', namespace, '' ), this.instanceId );
			addTextNode( header.addChildElement( 'Timestamp', namespace, '' ), this.timestamp );
			addTextNode( header.addChildElement( 'ResponseTimeStamp', namespace, '' ), system.now().format('yyyy-MM-dd\'T\'HH:mm:ss') );
		}
	}

	/**
	 * class to model an account query
	 */
	@TestVisible
	class AccountQuery 
	{
		@TestVisible
		final List<Party> parties = new List<Party>();
		Party billToParty;
		Party entitleToParty;
		Party shipToParty;
		Party soldToParty;
		String accountNumber;
		String contractNumber;
		String errorMessage;
		String id;
		String namedAccount;
		String opportunityNumber;
		String orderNumber;
		String partyNumber;
		String poNumber; // new
		String sourceOpportunityId; // new
		String region;
		String salesChannelCode;
		String salesforceAccountId;
		String salesforceAccountName;
		String salesforceAccountOwnerId;
		String salesRepOnAccount;
		String salesRepOnAccountActive;
		String salesRepRoleOnAccount;
		String status;

		/**
		 * Populates account query header from XML
		 *
		 * @param node
		 * @param namespace
		 */
		void unmarshal( DOM.Xmlnode node, String namespace )
		{
			// Populate account query with values from the xml node
			// NOTE: A ternary statement is being used to check for null values.
			//	   In situations where a value needs to be cast a nested ternary statement is used
			this.renewalMappings = null;
			this.accountNumber = getChildNodeText( node, 'AccountNumber', namespace );
			this.contractNumber = getChildNodeText( node, 'ContractNumber', namespace );
			this.id = getChildNodeText( node, 'Id', namespace );
			this.opportunityNumber = getChildNodeText( node, 'OpportunityNumber', namespace );
			this.orderNumber = getChildNodeText( node, 'OrderNumber', namespace );
			this.partyNumber = getChildNodeText( node, 'PartyNumber', namespace );
			this.poNumber = getChildNodeText( node, 'PONumber', namespace );
			Id sourceOpportunityId = null;
			try {
				sourceOpportunityId = getChildNodeText( node, 'SourceOpportunityId', namespace );
			} catch(Exception ignored) {}
			this.sourceOpportunityId = sourceOpportunityId;
			this.region = getChildNodeText( node, 'Region', namespace );
			this.salesChannelCode = getChildNodeText( node, 'SalesChannelCode', namespace );
			this.status = STATUS_SUCCESS;
			for ( DOM.XmlNode n : node.getChildElements() ) {
				String nodeName = n.getName();
				Party party = null;
				if ( nodeName == 'BillToParty' ) {
					billToParty = party = new Party(
						this, nodeName, Account_Matching.AccountToType.BILL_TO);
				}
				else if ( nodeName == 'ShipToParty' ) {
					shipToParty = party = new Party(
						this, nodeName, Account_Matching.AccountToType.SHIP_TO);
				}
				else if ( nodeName == 'SoldToParty' ) {
					soldToParty = party = new Party(
						this, nodeName, Account_Matching.AccountToType.SOLD_TO);
				}
				else if ( nodeName == 'EntitleToParty' ) {
					entitleToParty = party = new Party(
						this, nodeName, Account_Matching.AccountToType.ENTITLE_TO);
				}
				else if ( nodeName == 'LineEntitleToParty' ) {
					party = new Party(
						this, nodeName, Account_Matching.AccountToType.LINE_ENTITLE_TO);
				}
				if(party != null) {
					party.unmarshal( n, namespace );
					parties.add( party );
				}
			}
			// this is a hack to work around missing values in the ebs extract
			if(entitleToParty.oracleAccountNumber == null || entitleToParty.email == null && entitleToParty.country == null) {
				if(entitleToParty.cdhPartyNumber != null || entitleToParty.cdhPartySiteNumber != null || entitleToParty.cdhPartySiteNumber != null || entitleToParty.contactCDHPartyNumber != null) {
					for(Party p : parties) {
						if(p.nodeName == 'LineEntitleToParty') {
							if(p.contactCDHPartyNumber == entitleToParty.contactCDHPartyNumber && p.cdhPartyNumber == entitleToParty.cdhPartyNumber && p.cdhPartySiteNumber == entitleToParty.cdhPartySiteNumber) {
								if(entitleToParty.oracleAccountNumber == null) {
									entitleToParty.oracleAccountNumber = p.oracleAccountNumber;
								}
								entitleToParty.address1 = p.address1;
								entitleToParty.address2 = p.address2;
								entitleToParty.city = p.city;
								entitleToParty.postalCode = p.postalCode;
								entitleToParty.country = p.country;
								entitleToParty.email = p.email;
								if(entitleToParty.email != null || entitleToParty.country != null) {
									break;
								}
							}
						}
					}
				}
			}
		}

		List<Account_Matching_Renewals.RenewalParty> renewalMappings {
			get {
				if(renewalMappings == null) {
					renewalMappings = new List<Account_Matching_Renewals.RenewalParty>();
					for(Party p : parties) {
						renewalMappings.add(p.renewalParty);
					}
				}
				return renewalMappings;
			}
			set;
		}

		/**
		 * method for marshalling an object to XML
		 *
		 * @param node 
		 * @param namespace
		 */
		void marshal( DOM.Xmlnode node, String namespace )
		{
			DOM.xmlNode accountQuery = node.addChildElement( 'AccountQuery', namespace, '' );
			addTextNode( accountQuery.addChildElement( 'Id', namespace, '' ), id );
			addTextNode( accountQuery.addChildElement( 'AccountNumber', namespace, '' ), accountNumber );
			addTextNode( accountQuery.addChildElement( 'ContractNumber', namespace, '' ), contractNumber );
			addTextNode( accountQuery.addChildElement( 'OpportunityNumber', namespace, '' ), opportunityNumber );
			addTextNode( accountQuery.addChildElement( 'OrderNumber', namespace, '' ), orderNumber );
			addTextNode( accountQuery.addChildElement( 'PartyNumber', namespace, '' ), partyNumber );
			addTextNode( accountQuery.addChildElement( 'PONumber', namespace, '' ), poNumber );
			addTextNode( accountQuery.addChildElement( 'SourceOpportunityId', namespace, '' ), sourceOpportunityId );
			addTextNode( accountQuery.addChildElement( 'SalesChannelCode', namespace, '' ), salesChannelCode );
			addTextNode( accountQuery.addChildElement( 'SalesforceAccountId', namespace, '' ), salesforceAccountId );
			addTextNode( accountQuery.addChildElement( 'SalesforceAccountName', namespace, '' ), salesforceAccountName );
			addTextNode( accountQuery.addChildElement( 'SalesforceAccountOwnerId', namespace, '' ), salesforceAccountOwnerId );
			addTextNode( accountQuery.addChildElement( 'SalesRepOnAccount', namespace, '' ), salesRepOnAccount );
			addTextNode( accountQuery.addChildElement( 'SalesRepOnAccountActive', namespace, '' ), salesRepOnAccountActive );
			addTextNode( accountQuery.addChildElement( 'SalesRepRoleOnAccount', namespace, '' ), salesRepRoleOnAccount );
			addTextNode( accountQuery.addChildElement( 'NamedAccount', namespace, '' ), namedAccount );
			addTextNode( accountQuery.addChildElement( 'Region', namespace, '' ), region );
			addTextNode( accountQuery.addChildElement( 'Status', namespace, '' ), status );
			addTextNode( accountQuery.addChildElement( 'ErrorMessage', namespace, ''), truncate(errorMessage,398) );
			for(Party party : parties) {
				party.marshal( accountQuery, namespace);
			}
		}
	}

	/**
	 * Class to represent all the party object queries.
	 */
	@TestVisible
	class Party 
	{
		final AccountQuery accountQuery;
		final String nodeName;
		final Account_Matching.AccountToType toType;
		EBS_Account__c ebsAccount;
		String id; // a value that identifies this record
		String sourceOpportunityLineId; // original opportunity line item id
		String oracleAccountNumber; // the oracle account number
		String cdhPartyNumber; // the CDH Party Number
		String cdhPartySiteNumber; // the CDH Party Site Number
		String contactCDHPartyNumber; // the Contact CDH Party Number
		String address1; // to filter addresses with
		String address2; // to filter addresses with
		String city; // to filter addresses with
		String state; // to filter addresses with
		String postalCode; // to filter addresses with
		String country; // to filter addresses with
		String email; //  to filter contacts with
		String status; // status
		String message;

		/**
		 * Constructor.
		 *
		 * @param accountQuery
		 * @param nodeName
		 * @param toType
		 */
		Party(AccountQuery accountQuery, String nodeName,Account_Matching.AccountToType toType) {
			this.accountQuery = accountQuery;
			this.nodeName = nodeName;
			this.toType = toType;
		}

		@TestVisible
		Account_Matching_Renewals.RenewalParty renewalParty {
			get {
				if(renewalParty == null) {
					renewalParty = new Account_Matching_Renewals.RenewalParty(
						toType,
						accountQuery.sourceOpportunityId,
						sourceOpportunityLineId,
						oracleAccountNumber,
						cdhPartyNumber,
						cdhPartySiteNumber,
						contactCDHPartyNumber,
						accountQuery.region,
						country,
						email,
						accountQuery.opportunityNumber,
						accountQuery.orderNumber,
						accountQuery.poNumber,
						accountQuery );
				}
				return renewalParty;
			}
			set;
		}

		/**
		 * Populates the subscription party from XML
		 *
		 * @param node
		 * @param namespace
		 */
		void unmarshal( DOM.Xmlnode node, String namespace )
		{
			// Populate account query with values from the xml node
			// NOTE: A ternary statement is being used to check for null values.
			//	   In situations where a value needs to be cast a nested ternary statement is used
			this.renewalParty = null;
			this.id = getChildNodeText( node, 'Id', namespace);
			Id sourceOpportunityLineId = null;
			try {
				sourceOpportunityLineId = getChildNodeText( node, 'SourceOpportunityLineId', namespace );
			} catch(Exception ignored) {}
			this.sourceOpportunityLineId = sourceOpportunityLineId;
			this.oracleAccountNumber = getChildNodeText( node, 'OracleAccountNumber', namespace);
			this.cdhPartyNumber = getChildNodeText( node, 'CDHPartyNumber', namespace);
			this.cdhPartySiteNumber = getChildNodeText( node, 'CDHPartySiteNumber', namespace);
			this.contactCDHPartyNumber = getChildNodeText( node, 'ContactCDHPartyNumber', namespace);
			this.address1 = getChildNodeText( node, 'Address1', namespace);
			this.address2 = getChildNodeText( node, 'Address2', namespace);
			this.city = getChildNodeText( node, 'City', namespace);
			this.state = getChildNodeText( node, 'State', namespace);
			this.postalCode = getChildNodeText( node, 'PostalCode', namespace);
			this.country = getChildNodeText( node, 'Country', namespace);
			this.email = getChildNodeText( node, 'Email', namespace);
			this.status = STATUS_SUCCESS;
		}

		/**
		 * method for marshalling an object to XML
		 *
		 * @param node 
		 * @param namespacee
		 */
		void marshal( DOM.Xmlnode node, String namespace )
		{
			DOM.xmlNode party = node.addChildElement( nodeName, namespace, '' );
			addTextNode( party.addChildElement( 'Id', namespace, '' ), id );
			addTextNode( party.addChildElement( 'SalesforceSalesAccountId', namespace, '' ), getSalesAccountId( ebsAccount ) );
			addTextNode( party.addChildElement( 'SalesforceEBSAccountId', namespace, '' ), getSObjectId( ebsAccount ) );
			addTextNode( party.addChildElement( 'SalesforceAddressId', namespace, '' ), getSObjectId( renewalParty.getBestAddress(true)) );
			addTextNode( party.addChildElement( 'SalesforceContactId', namespace, '' ), getSObjectId( renewalParty.getBestContact(true)) );
			addTextNode( party.addChildElement( 'SourceOpportunityLineId', namespace, '' ), sourceOpportunityLineId );
			addTextNode( party.addChildElement( 'OracleAccountNumber', namespace, '' ), oracleAccountNumber );
			addTextNode( party.addChildElement( 'CDHPartyNumber', namespace, '' ), cdhPartyNumber );
			addTextNode( party.addChildElement( 'CDHPartySiteNumber', namespace, '' ), cdhPartySiteNumber );
			addTextNode( party.addChildElement( 'ContactCDHPartyNumber', namespace, '' ), contactCDHPartyNumber );
			addTextNode( party.addChildElement( 'Address1', namespace, '' ), address1 );
			addTextNode( party.addChildElement( 'Address2', namespace, '' ), address2 );
			addTextNode( party.addChildElement( 'City', namespace, '' ), city );
			addTextNode( party.addChildElement( 'State', namespace, '' ), state );
			addTextNode( party.addChildElement( 'PostalCode', namespace, '' ), postalCode );
			addTextNode( party.addChildElement( 'Country', namespace, '' ), country );
			addTextNode( party.addChildElement( 'Email', namespace, '' ), email );
			addTextNode( party.addChildElement( 'Status', namespace, '' ), status );
			addTextNode( party.addChildElement( 'Message', namespace, ''), truncate(message,298) );
		}
	}
}