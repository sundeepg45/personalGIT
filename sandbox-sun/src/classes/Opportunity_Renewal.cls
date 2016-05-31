/**
 * Renewal loading service
 *
 * @version 2015-01-27
 * @author  John Herson  <jherson@redhat.com>, Bryan Bosely <bbosely@rehat.com>
 * 2011-01-13 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2015-01-27 - Depreciated
 * 2013-10-31 - Moved EMEA close date to start of the month if in the first month of a quarter.
 * 2013-10-30 - Corrected EMEA channel mapping. Use inactive bill-to records.
 * 2013-09-30 - Updated fulfillment channel logic
 * 2013-09-17 - Move EMEA close dates before the start of the quarter to the start of the quarter
 * 2013-02-15 - Corrected EMEA close date
 * 2013-02-14 - Added external id to expired products.
 *            - Added status return for successful product lines
 *            - Corrected the error of inserting duplicate Contact Id's
 * 2012-09-04 - Depreciated Expiring_Products_Total_Amount__c and Total_Price__c assignment.
 * 2012-08-21 - Update to change forecast category
 * 2012-05-31 - Added a isTestMode and isSuccess properties
 * 2012-03-27 - Removed LATAM owner map table
 * 2012-03-17 - Refactored including removing the bogus 200 limit on inserts.  See:
 *	 http://boards.developerforce.com/t5/Apex-Code-Development/quot-For-loop-list-batch-size-quot-limit-of-200-what-is-it/td-p/217239
 */
public class Opportunity_Renewal {
//depreciated	public static final String SALESFORCE_MSG_NAMESPACE = 'http://salesforce.redhat.com/renewals';
//depreciated	public static final String STATUS_SUCCESS = 'SUCCESS';
//depreciated	public static final String STATUS_ERROR = 'ERROR';
//depreciated	public static final String STATUS_NO_LINES = 'NO_LINES';
//depreciated	public static final String STATUS_CO_TERMED = 'COTERMED';
//depreciated	public static final String STATUS_DUPLICATE = 'DUPLICATE';

//depreciated	/**
//depreciated	 * Creates a new renewal opportunity
//depreciated	 *
//depreciated	 * @param   xmlDocument
//depreciated	 * @return  a response message
//depreciated	 */
//depreciated	public String createRenewalOpportunity(String xmlDocument) {
//depreciated		// generate the renewal class hierarchy from the XML
//depreciated		Opportunity_RenewalMessage message = new Opportunity_RenewalMessage();
//depreciated		message.unmarshal( xmlDocument, SALESFORCE_MSG_NAMESPACE );

//depreciated		// create the renewal opportunity
//depreciated		message.subscription.process(this);

//depreciated		// generate the response message
//depreciated		return message.marshal();
//depreciated	}

//depreciated	static Map<String,BillToAccount__c> billToAccountMap = new Map<String,BillToAccount__c>{null=>null,''=>null};

//depreciated	static Map<String,BillToAccount__c> getBillToAccountMap(Set<String> accountNumbers) {
//depreciated		accountNumbers = accountNumbers.clone();
//depreciated		accountNumbers.removeAll(billToAccountMap.keySet());
//depreciated		if(!accountNumbers.isEmpty()) {
//depreciated			for(String accountNumber : accountNumbers) {
//depreciated				billToAccountMap.put(accountNumber,null);
//depreciated			}
//depreciated			for(BillToAccount__c bta : [
//depreciated				select
//depreciated					Bill_To_Account_Number__c,
//depreciated					Region__c,
//depreciated					Channel__c
//depreciated				from BillToAccount__c
//depreciated				where Bill_To_Account_Number__c in :accountNumbers
//depreciated					and Channel__c != null ])
//depreciated			{
//depreciated				billToAccountMap.put(bta.Bill_To_Account_Number__c,bta);
//depreciated			}
//depreciated		}
//depreciated		return billToAccountMap;
//depreciated	}

//depreciated	static BillToAccount__c getBillToAccount(String accountNumber) {
//depreciated		return getBillToAccountMap(new Set<String>{accountNumber}).get(accountNumber);
//depreciated	}

//depreciated	/**
//depreciated	 * Setting to enable test mode.  In test mode we always rollback
//depreciated	 * any object created.
//depreciated	 */
//depreciated	public Boolean isTestMode {
//depreciated		get {
//depreciated			return (isTestMode == true);
//depreciated		}
//depreciated		set;
//depreciated	}

//depreciated	/**
//depreciated	 * Setting to indicate success.
//depreciated	 */
//depreciated	public Boolean isSuccess {
//depreciated		get {
//depreciated			return (isSuccess == true);
//depreciated		}
//depreciated		set;
//depreciated	}

//depreciated	/**
//depreciated	 * create or query a contact
//depreciated	 * @param accountId
//depreciated	 * @param opportunityId
//depreciated	 * @param ownerId
//depreciated	 * @param role
//depreciated	 * @param name
//depreciated	 * @param email
//depreciated	 * @param phone
//depreciated	 * @param contactIdMap map of contact Id by email address
//depreciated	 */
//depreciated	public static void createOrQueryContact(
//depreciated		Id accountId,
//depreciated		Id opportunityId,
//depreciated		Id ownerId,
//depreciated		Id campaignId,
//depreciated		String role,
//depreciated		String name,
//depreciated		String email,
//depreciated		String phone,
//depreciated		Boolean isPrimary,
//depreciated		Map<String,Id> contactIdMap)
//depreciated	{
//depreciated		if(email != null && email != '') {
//depreciated			Id contactId = contactIdMap.get(email.toLowerCase());
//depreciated			if (contactId == null) {
//depreciated				contactId = Database.insert(new Contact(
//depreciated					AccountId = accountId,
//depreciated					OwnerId = ownerId,
//depreciated					LastName = name,
//depreciated					Email = email,
//depreciated					Phone = phone), false).getId();
//depreciated			}
//depreciated			if (contactId != null) {
//depreciated				contactIdMap.put(email.toLowerCase(),contactId);
//depreciated				// ignore the results
//depreciated				Database.insert( new OpportunityContactRole(
//depreciated					OpportunityId = opportunityId,
//depreciated					ContactId = contactId,
//depreciated					Role = role,
//depreciated					IsPrimary = isPrimary), false);

//depreciated				// ignore the results
//depreciated				Database.insert(new CampaignMember(
//depreciated					ContactId = contactId,
//depreciated					CampaignId = campaignId,
//depreciated					Status = 'Responded'), false);
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * create Source Opportunity Contact Roles
//depreciated	 * @param sourceOpportunity
//depreciated	 * @param opportunityId
//depreciated	 */
//depreciated	public static void createSourceOpportunityContactRoles(Opportunity sourceOpportunity, Opportunity opportunity) {
//depreciated		List<OpportunityContactRole> contactRoles = sourceOpportunity.opportunityContactRoles;
//depreciated		if (contactRoles != null && ! contactRoles.isEmpty()) {
//depreciated			List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole>();
//depreciated			List<CampaignMember> campaignMembers = new List<CampaignMember>();

//depreciated			for (OpportunityContactRole contactRole : contactRoles) {
//depreciated				OpportunityContactRole opportunityContactRole = (OpportunityContactRole) contactRole.clone(false, true);
//depreciated				opportunityContactRole.OpportunityId = opportunity.Id;
//depreciated				opportunityContactRoles.add(opportunityContactRole);

//depreciated				campaignMembers.add(new CampaignMember(
//depreciated					ContactId = opportunityContactRole.ContactId,
//depreciated					CampaignId = opportunity.CampaignId,
//depreciated					Status = 'Responded'));
//depreciated			}

//depreciated			for (Database.SaveResult saveResult : Database.insert(opportunityContactRoles,false)) {
//depreciated				// log and otherwise ignore errors
//depreciated				if (! saveResult.isSuccess()) {
//depreciated					system.debug(LoggingLevel.ERROR, 'Failed to create Source Opportunity Contact Role: ' + saveResult.getErrors());
//depreciated				}
//depreciated			}

//depreciated			try {
//depreciated				for (Database.SaveResult saveResult : Database.insert(campaignMembers,false)) {
//depreciated					// log and otherwise ignore errors
//depreciated					if (! saveResult.isSuccess()) {
//depreciated						system.debug(LoggingLevel.ERROR, 'Failed to create Source Opportunity Campaign Member: ' + saveResult.getErrors());
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			catch ( Exception e ) {
//depreciated				// this should really never happen
//depreciated				system.debug(LoggingLevel.ERROR, 'Failed to create Source Opportunity Campaign Member: ' + e.getMessage()+':\n'+e.getStackTraceString() );
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * retrieves an account
//depreciated	 *
//depreciated	 * @param whereClause
//depreciated	 * @return Account object
//depreciated	 */
//depreciated	public static Account getAccount(String whereClause) {
//depreciated		Account account = null;
//depreciated		for(SObject o : Database.query(
//depreciated			'SELECT ' +
//depreciated				'Id, ' +
//depreciated				'Name, ' +
//depreciated				'OracleAccountID__c, ' +
//depreciated				'OracleAccountNumber__c, ' +
//depreciated				'Owner.Id, ' +
//depreciated				'Owner.Name,' +
//depreciated				'Owner.Email, ' +
//depreciated				'Owner.UserRole.Name ' +
//depreciated			'FROM Account ' +
//depreciated			'WHERE ' + whereClause))
//depreciated		{
//depreciated			account = (Account)o;
//depreciated		}
//depreciated		return account;
//depreciated	}


//depreciated	/**
//depreciated	 * retrieves an account by the account number
//depreciated	 *
//depreciated	 * @param accountNumber
//depreciated	 * @return Account object
//depreciated	 */
//depreciated	public static Account getAccountByAccountNumber(String accountNumber) {
//depreciated		return getAccount('OracleAccountNumber__c = \'' + accountNumber + '\'');
//depreciated	}


//depreciated	/**
//depreciated	 * retrieve an account by the account id
//depreciated	 *
//depreciated	 * @param accountId
//depreciated	 * @return Account object
//depreciated	 */
//depreciated	public static Account getAccountById(Id accountId) {
//depreciated		return getAccount('Id = \'' + accountId + '\'');
//depreciated	}
//depreciated	/**
//depreciated	 * find the user Id with the specified e-mail address
//depreciated	 * @param email address to lookup
//depreciated	 * @param retval default return value
//depreciated	 * @return Id of user found
//depreciated	 */
//depreciated	public static Id getOwnerId(String email, Id retval) {
//depreciated		if(email != null) {
//depreciated			for(User u : [select Id from User where Email = :email order by IsActive, CreatedDate limit 1]) {
//depreciated				retval = u.Id;
//depreciated			}
//depreciated		}
//depreciated		return retval;
//depreciated	}

//depreciated	private static final Map<String,Set<String>> productCodesByCurrencyIsoCode = new Map<String,Set<String>>();
//depreciated	private static final Map<String,Map<String, PricebookEntry>> pricebookEntryMapByCurrencyIsoCode = new Map<String,Map<String, PricebookEntry>>();

//depreciated	/**
//depreciated	 * method to allow us to perform a look up for pricebook entry
//depreciated	 * data instead of querying for each entry
//depreciated	 *
//depreciated	 * @param productCodeList an ordered list of pricebook codes
//depreciated	 * @param currencyIsoCode
//depreciated	 * @return map of pricebook entries by product code
//depreciated	 */
//depreciated	private static Map<String, PricebookEntry> getPricebookEntryMap( List<String> productCodeList, String currencyIsoCode ) {
//depreciated		Map<String, PricebookEntry> pricebookEntryMap = pricebookEntryMapByCurrencyIsoCode.get(currencyIsoCode);
//depreciated		Set<String> previousProductCodes = productCodesByCurrencyIsoCode.get(currencyIsoCode);
//depreciated		if(pricebookEntryMap == null) {
//depreciated			pricebookEntryMap = new Map<String,PricebookEntry>();
//depreciated			pricebookEntryMapByCurrencyIsoCode.put(currencyIsoCode,pricebookEntryMap);
//depreciated			previousProductCodes = new Set<String>();
//depreciated			productCodesByCurrencyIsoCode.put(currencyIsoCode,previousProductCodes);
//depreciated		}
//depreciated		final Set<String> productCodes = new Set<String>(productCodeList);
//depreciated		productCodes.removeAll(previousProductCodes);
//depreciated		previousProductCodes.addAll(productCodes);

//depreciated		system.debug('-- Product Codes: ' + productCodes);
//depreciated		if(! productCodes.isEmpty()) {
//depreciated			// query the pricebook entry by productCode
//depreciated			// populate the pricebook entry map with the results
//depreciated			for ( PricebookEntry pbe : [
//depreciated				SELECT
//depreciated					UnitPrice,
//depreciated					CurrencyIsoCode,
//depreciated					Product2.Description,
//depreciated					Product2.Id,
//depreciated					Product2.ProductCode,
//depreciated					Pricebook2.Name
//depreciated				FROM PricebookEntry
//depreciated				WHERE Product2.ProductCode IN :productCodes
//depreciated					AND PricebookEntry.CurrencyIsoCode = :currencyIsoCode
//depreciated					AND IsActive = true
//depreciated					AND Product2.IsActive = true
//depreciated					AND Pricebook2.Name = 'Global Price Book' ] )
//depreciated			{
//depreciated				pricebookEntryMap.put ( pbe.Product2.ProductCode, pbe );
//depreciated			}
//depreciated		}
//depreciated		return pricebookEntryMap;
//depreciated	}

//depreciated	private static List<Opportunity> getSourceOpportunities(Set<String> opportunityNumbers, Set<String> orderNumbers, Set<String> poNumbers) {
//		// Find a the set of most recent creation dates to limit
//		// the number of records returned in the next query
//		Set<DateTime> createdDates = new Set<DateTime>();
//		for(AggregateResult ar : [
//			select max(CreatedDate) maxCreatedDate
//			from Opportunity
//			where OpportunityNumber__c in :opportunityNumbers
//				or OracleOrderNumber__c in :orderNumbers
//				or PONumber__c in :poNumbers
//			group by OpportunityNumber__c, OracleOrderNumber__c, PONumber__c ] )
//		{
//			createdDates.add((DateTime)ar.get('maxCreatedDate'));
//		}
//depreciated		return [
//depreciated			select
//depreciated				OpportunityNumber__c,
//depreciated				OracleOrderNumber__c,
//depreciated				PONumber__c,
//depreciated				Account.Id,
//depreciated				Account.Name,
//depreciated				Account.Owner.Id,
//depreciated				Account.Owner.Name,
//depreciated				Account.Owner.UserRole.Name,
//depreciated				CloseDate,
//depreciated				Country_of_Order__c,
//depreciated				Deal_Registration__c,
//depreciated				Owner.Id,
//depreciated				Owner.IsActive,
//depreciated				Touched__c,
//depreciated				(	select 
//depreciated						ContactId, Role
//depreciated					from OpportunityContactRoles
//depreciated					where (Role = 'Payables Contact' Or Role = 'Shipping Contact'))
//depreciated			from Opportunity 
//depreciated			where // CreatedDate in :createdDates and
//depreciated				(OpportunityNumber__c in :opportunityNumbers
//depreciated					or OracleOrderNumber__c in :orderNumbers
//depreciated					or PONumber__c in :poNumbers ) ];
//depreciated	}

//depreciated	/**
//depreciated	 * this method is responsible for retrieving the source opportunity
//depreciated	 *
//depreciated	 * @param opportunityNumber
//depreciated	 * @param orderNumber
//depreciated	 * @param poNumber
//depreciated	 * @return the source Opportunity
//depreciated	 */
//depreciated	private static Opportunity getSourceOpportunity(List<Opportunity> sourceOpportunities,String opportunityNumber, String orderNumber, String poNumber) {
//depreciated		for(Opportunity opp : sourceOpportunities) {
//depreciated			if (opportunityNumber != null && opportunityNumber != '')
//depreciated			{
//depreciated				if(opp.OpportunityNumber__c == opportunityNumber) {
//depreciated					return opp;
//depreciated				}
//depreciated			}
//depreciated			else if (orderNumber != null && orderNumber != '')
//depreciated			{
//depreciated				if(orderNumber == opp.OracleOrderNumber__c) {
//depreciated					return opp;
//depreciated				}
//depreciated			}
//depreciated			else if (poNumber != null && poNumber != '')
//depreciated			{
//depreciated				if(poNumber == opp.PONumber__c) {
//depreciated					return opp;
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		return null;
//depreciated	}

//depreciated	/**
//depreciated	 * method for retrieving a double from a node
//depreciated	 *
//depreciated	 * @param parent node to get child element from
//depreciated	 * @param element name of child element
//depreciated	 * @param namespace name of namespace to use
//depreciated	 * @return parsed double
//depreciated	 */
//depreciated	public static Double parseDouble(Dom.XmlNode parent, String element, String namespace) {
//depreciated		final DOM.Xmlnode node = parent.getChildElement(element,namespace);
//depreciated		Double retval = null;
//depreciated		if(node != null) {
//depreciated			retval = 0;
//depreciated			final String s = node.getText();
//depreciated			if(s != null && s != '') {
//depreciated				retval = Double.valueOf(s);
//depreciated			}
//depreciated		}
//depreciated		return retval;
//depreciated	}

//depreciated	/**
//depreciated	 * method for retrieving a long from a node
//depreciated	 *
//depreciated	 * @param parent node to get child element from
//depreciated	 * @param element name of child element
//depreciated	 * @param namespace name of namespace to use
//depreciated	 * @return parsed long
//depreciated	 */
//depreciated	public static Long parseLong(Dom.XmlNode parent, String element, String namespace) {
//depreciated		final DOM.Xmlnode node = parent.getChildElement(element,namespace);
//depreciated		Long retval = null;
//depreciated		if(node != null) {
//depreciated			retval = 0;
//depreciated			final String s = node.getText();
//depreciated			if(s != null && s != '') {
//depreciated				retval = Long.valueOf(s);
//depreciated			}
//depreciated		}
//depreciated		return retval;
//depreciated	}

//depreciated	/**
//depreciated	 * method for retrieving a integer from a node
//depreciated	 *
//depreciated	 * @param parent node to get child element from
//depreciated	 * @param element name of child element
//depreciated	 * @param namespace name of namespace to use
//depreciated	 * @return parsed integer
//depreciated	 */
//depreciated	public static Integer parseInteger(Dom.XmlNode parent, String element, String namespace) {
//depreciated		final DOM.Xmlnode node = parent.getChildElement(element,namespace);
//depreciated		Integer retval = null;
//depreciated		if(node != null) {
//depreciated			retval = 0;
//depreciated			final String s = node.getText();
//depreciated			if(s != null && s != '') {
//depreciated				retval = Integer.valueOf(s);
//depreciated			}
//depreciated		}
//depreciated		return retval;
//depreciated	}

//depreciated	/**
//depreciated	 * method for retrieving the text from a node
//depreciated	 *
//depreciated	 * @param parent node to get child element from
//depreciated	 * @param element name of child element
//depreciated	 * @param namespace name of namespace to use
//depreciated	 * @return parsed text
//depreciated	 */
//depreciated	public static String parseText(Dom.XmlNode parent, String element, String namespace) {
//depreciated		final DOM.Xmlnode node = parent.getChildElement(element,namespace);
//depreciated		String retval = null;
//depreciated		if(node != null) {
//depreciated			final String s = node.getText();
//depreciated			if(s != null && s != '') {
//depreciated				retval = s;
//depreciated			}
//depreciated		}
//depreciated		return retval;
//depreciated	}

//depreciated	/**
//depreciated	 * method for converting a string to a date
//depreciated	 *
//depreciated	 * @param parent node to get child element from
//depreciated	 * @param element name of child element
//depreciated	 * @param namespace name of namespace to use
//depreciated	 * @return the parsed Date
//depreciated	 */
//depreciated	public static Date parseDate(Dom.XmlNode parent, String element, String namespace) {
//depreciated		final DOM.Xmlnode node = parent.getChildElement(element,namespace);
//depreciated		Date retval = null;
//depreciated		if(node != null) {
//depreciated			final String dt = node.getText();
//depreciated			if(dt != null && dt != '') {
//depreciated				final String[] x = dt.split('-');
//depreciated				final Integer year = Integer.valueOf( x[0] );
//depreciated				final Integer month = Integer.valueOf( x[1] );
//depreciated				final Integer day = Integer.valueOf( x[2] );
//depreciated				retval = Date.newInstance(year, month, day);
//depreciated			}
//depreciated		}
//depreciated		return retval;
//depreciated	}

//depreciated	/**
//depreciated	 * Adds a child text node from the given value.
//depreciated	 *
//depreciated	 * @param parent node to add child to
//depreciated	 * @param element name of child element to add
//depreciated	 * @param namespace name of namespace to use
//depreciated	 * @param value which should be converted to the text to add
//depreciated	 */
//depreciated	public static void addChildText(Dom.XmlNode parent, String element, String namespace, Object value) {
//depreciated		String textValue = '';
//depreciated		if(value != null) {
//depreciated			final String s = String.valueOf(value);
//depreciated			if(s != null) {
//depreciated				textValue = s;
//depreciated			}
//depreciated		}
//depreciated		parent.addChildElement(element, namespace,'').addTextNode( textValue );
//depreciated	}

//depreciated	/**
//depreciated	 * Truncate a string to the specified length.
//depreciated	 */
//depreciated	public static String truncate(String value, Integer len) {
//depreciated		if(value != null && value.length() > len) {
//depreciated			value = value.substring(0,len);
//depreciated		}
//depreciated		return value;
//depreciated	}

//depreciated	/**
//depreciated	 * class to model the renewal message
//depreciated	 */
//depreciated	public class Opportunity_RenewalMessage
//depreciated	{
//depreciated		public Header header;
//depreciated		public Subscription subscription;


//depreciated		/**
//depreciated		 * constructor
//depreciated		 */
//depreciated		public Opportunity_RenewalMessage() {
//depreciated			header = new Header();
//depreciated			subscription = new Subscription();
//depreciated		}


//depreciated		/**
//depreciated		 * Populates opportunity renewal class hierarchy from XML
//depreciated		 *
//depreciated		 * @param xmlDocument
//depreciated		 * @param namespace
//depreciated		 */
//depreciated		public void unmarshal( String xmlDocument, String namespace ) {
//depreciated			DOM.Document document = new DOM.Document();
//depreciated			document.load(xmlDocument);

//depreciated			for(DOM.XmlNode node : document.getRootElement().getChildElements())
//depreciated			{
//depreciated				String nodeName = node.getName();
//depreciated				if (nodeName == 'Header')
//depreciated				{
//depreciated					header.unmarshal( node, namespace );
//depreciated				}
//depreciated				else if (nodeName == 'Payload')
//depreciated				{
//depreciated					DOM.XMLNode subscriptionNode = node.getChildElement( 'Subscription', SALESFORCE_MSG_NAMESPACE );
//depreciated					subscription.unmarshal( subscriptionNode, namespace );
//depreciated				}
//depreciated			}
//depreciated		}

//depreciated		/**
//depreciated		 * method for marshalling the renewal class hierarchy back to XML
//depreciated		 *
//depreciated		 * @return the marshalled string
//depreciated		 */
//depreciated		public String marshal() {
//depreciated			DOM.Document response = new DOM.Document();
//depreciated			DOM.xmlNode salesForceMessage = response.createRootElement( 'SalesforceMessage', '', '' );

//depreciated			// generate header node
//depreciated			header.marshal( salesForceMessage, '' );

//depreciated			// generate payload node
//depreciated			DOM.xmlNode payload = salesForceMessage.addChildElement( 'Payload', '', '' );

//depreciated			// generate subscription node
//depreciated			subscription.marshal( payload, '' );

//depreciated			return response.toXmlString();
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * class to model the renewal header
//depreciated	 */
//depreciated	public class Header {
//depreciated		public String instanceId;
//depreciated		public String operation;
//depreciated		public String opportunityType;
//depreciated		public String timestamp;

//depreciated		/**
//depreciated		 * Populates opportunity renewal header from XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 * @param namespace
//depreciated		 */
//depreciated		public void unmarshal( DOM.Xmlnode node, String namespace ) {
//depreciated			// Populate with values from the xml node children
//depreciated			instanceId = parseText(node,'InstanceId', namespace);
//depreciated			operation = parseText(node,'Operation', namespace);
//depreciated			opportunityType = parseText(node,'Type', namespace);
//depreciated			timestamp = parseText(node,'Timestamp', namespace);
//depreciated		}


//depreciated		/**
//depreciated		 * method for marshalling an object to XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 */
//depreciated		public void marshal( DOM.Xmlnode node, String namespace ) {
//depreciated			DOM.xmlNode header = node.addChildElement( 'Header', namespace, '' );
//depreciated			header.addChildElement( 'Operation', namespace, '' ).addTextNode( operation );
//depreciated			header.addChildElement( 'Type', namespace, '' ).addTextNode( opportunityType );
//depreciated			header.addChildElement( 'InstanceId', namespace, '' ).addTextNode( instanceId );
//depreciated			header.addChildElement( 'Timestamp', namespace, '' ).addTextNode( timestamp );
//depreciated			header.addChildElement( 'ResponseTimeStamp', namespace, '' ).addTextNode( system.now().format('yyyy-MM-dd\'T\'HH:mm:ss') );
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * class to model a renewal
//depreciated	 */
//depreciated	public class Subscription {
//depreciated		public String accountRecordType;
//depreciated		public String accountRecordTypeId;
//depreciated		public Long businessUnitId;
//depreciated		public String businessUnitName;
//depreciated		public String campaignName;
//depreciated		public Double contractAmount;
//depreciated		public Date contractEndDate;
//depreciated		public Double contractId;
//depreciated		public String contractNumber;
//depreciated		public Date contractStartDate;
//depreciated		public String contractStatusCode;
//depreciated		public String countryOfOrder;
//depreciated		public String currencyIsoCode;
//depreciated		public String errorMessage;
//		public Double expiringProductsAmount;
//depreciated		public Integer fiscalQuarter;
//depreciated		public Integer fiscalYear;
//depreciated		public String id;
//depreciated		public String leadSourceDetail;
//depreciated		public Long mergeToSubscriptionId;
//depreciated		public String opportunityNumber;
//depreciated		public String opportunityRecordType;
//depreciated		public String opportunityRecordTypeId;
//depreciated		public Long orderId;
//depreciated		public String orderNumber;
//depreciated		public Long orderSourceId;
//depreciated		public String orderSourceName;
//depreciated		public Long orderTypeId;
//depreciated		public String orderTypeName;
//depreciated		public String poNumber;
//depreciated		public String recordStatus;
//depreciated		public String region;
//depreciated		public String salesChannelCode;
//depreciated		public String salesforceAccountId;
//depreciated		public String salesforceAccountOwnerId;
//depreciated		public String salesforceCampaignId;
//depreciated		public String salesforceOpportunityId;
//depreciated		public String salesRepOnAccount;
//depreciated		public String salesRepOnOrder;
//depreciated		public String salesRepRoleOnAccount;

//depreciated		public SubscriptionParty billToParty;
//depreciated		public SubscriptionParty shipToParty;
//depreciated		public SubscriptionParty soldToParty;

//depreciated		public List<SubscriptionLine> lineList;
//depreciated		public List<SubscriptionPartner> partnerList;
//depreciated		public List<SubscriptionUser> userList;
//depreciated		public List<MergedSubscription> mergedSubscriptionList;


//depreciated		/**
//depreciated		 * Populates opportunity renewal header from XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 * @param namespace
//depreciated		 */
//depreciated		public void unmarshal( DOM.Xmlnode node, String namespace ) {
//depreciated			// Populate with values from the xml node children
//depreciated			accountRecordType = parseText(node,'AccountRecordType', namespace);
//depreciated			accountRecordTypeId = parseText(node,'AccountRecordTypeId', namespace);
//depreciated			businessUnitId = parseLong(node,'BusinessUnitId', namespace);
//depreciated			businessUnitName = parseText(node,'BusinessUnitName', namespace);
//depreciated			campaignName = parseText(node,'CampaignName', namespace);
//depreciated			contractAmount = parseDouble(node,'ContractAmount', namespace);
//depreciated			contractEndDate = parseDate(node,'ContractEndDate', namespace);
//depreciated			contractId = parseDouble(node,'ContractId', namespace);
//depreciated			contractNumber = parseText(node,'ContractNumber', namespace);
//depreciated			contractStartDate = parseDate(node,'ContractStartDate', namespace);
//depreciated			contractStatusCode = parseText(node,'ContractStatusCode', namespace);
//depreciated			countryOfOrder = parseText(node,'CountryOfOrder', namespace);
//depreciated			currencyIsoCode = parseText(node,'CurrencyIsoCode', namespace);
//depreciated			errorMessage = '';
//			expiringProductsAmount = parseDouble(node,'ExpiringProductsAmount', namespace );
//depreciated			fiscalQuarter = parseInteger(node,'FiscalQuarter', namespace);
//depreciated			fiscalYear = parseInteger(node,'FiscalYear', namespace);
//depreciated			id = parseText(node,'Id', namespace);
//depreciated			leadSourceDetail = parseText(node,'LeadSourceDetail', namespace);
//depreciated			mergeToSubscriptionId = parseLong(node,'MergeToSubscriptionId', namespace);
//depreciated			opportunityNumber = parseText(node,'OpportunityNumber', namespace);
//depreciated			opportunityRecordType = parseText(node,'OpportunityRecordType', namespace);
//depreciated			opportunityRecordTypeId = parseText(node,'OpportunityRecordTypeId', namespace);
//depreciated			orderId = parseLong(node,'OrderId', namespace);
//depreciated			orderNumber = parseText(node,'OrderNumber', namespace);
//depreciated			orderSourceId = parseLong(node,'OrderSourceId', namespace);
//depreciated			orderSourceName = parseText(node,'OrderSourceName', namespace);
//depreciated			orderTypeId = parseLong(node,'OrderTypeId', namespace);
//depreciated			orderTypeName = parseText(node,'OrderTypeName', namespace);
//depreciated			poNumber = parseText(node,'PoNumber', namespace);
//depreciated			recordStatus = parseText(node,'RecordStatus', namespace);
//depreciated			region = parseText(node,'Region', namespace);
//depreciated			salesChannelCode = parseText(node,'SalesChannelCode', namespace);
//depreciated			salesforceAccountId = parseText(node,'SalesforceAccountId', namespace);
//depreciated			salesforceAccountOwnerId = parseText(node,'SalesforceAccountOwnerId', namespace);
//depreciated			salesforceCampaignId = parseText(node,'SalesforceCampaignId', namespace);
//depreciated			salesforceOpportunityId = parseText(node,'SalesforceOpportunityId', namespace);
//depreciated			salesRepOnAccount = parseText(node,'SalesRepOnAccount', namespace);
//depreciated			salesRepOnOrder = parseText(node,'SalesRepOnOrder', namespace);
//depreciated			salesRepRoleOnAccount = parseText(node,'SalesRepRoleOnAccount', namespace);

//depreciated			lineList = new List<SubscriptionLine>();
//depreciated			partnerList = new List<SubscriptionPartner>();
//depreciated			userList = new List<SubscriptionUser>();
//depreciated			mergedSubscriptionList = new List<MergedSubscription>();

//depreciated			//
//depreciated			// loop through the child nodes of the argument node to populate
//depreciated			// billTo, shipTo, soldTo, lines, partners, users, and merged subscriptions
//depreciated			//

//depreciated			for ( DOM.XmlNode n : node.getChildElements() ) {
//depreciated				String nodeName = n.getName();
//depreciated				if ( nodeName == 'BillToParty' ) {
//depreciated					billToParty = new SubscriptionParty();
//depreciated					billToParty.unmarshal( n, namespace );
//depreciated				}
//depreciated				else if ( nodeName == 'ShipToParty' ) {
//depreciated					shipToParty = new SubscriptionParty();
//depreciated					shipToParty.unmarshal( n, namespace );
//depreciated				}
//depreciated				else if ( nodeName == 'SoldToParty' ) {
//depreciated					soldToParty = new SubscriptionParty();
//depreciated					soldToParty.unmarshal( n, namespace );
//depreciated				}
//depreciated				else if ( nodeName == 'Line' ) {
//depreciated					SubscriptionLine line = new SubscriptionLine();
//depreciated					line.unmarshal( n, namespace );
//depreciated					lineList.add( line );
//depreciated				}
//depreciated				else if ( nodeName == 'Partner' ) {
//depreciated					SubscriptionPartner partner = new SubscriptionPartner();
//depreciated					partner.unmarshal( n, namespace );
//depreciated					partnerList.add( partner );
//depreciated				}
//depreciated				else if ( nodeName == 'User' ) {
//depreciated					SubscriptionUser user = new SubscriptionUser();
//depreciated					user.unmarshal( n, namespace );
//depreciated					userList.add( user );
//depreciated				}
//depreciated				else if ( nodeName == 'MergedSubscription' ) {
//depreciated					MergedSubscription mergedSubscription = new MergedSubscription();
//depreciated					mergedSubscription.unmarshal( n, namespace );
//depreciated					mergedSubscriptionList.add( mergedSubscription );
//depreciated				}
//depreciated			}
//depreciated		}

//depreciated		/**
//depreciated		 * method for marshalling an object to XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 */
//depreciated		public void marshal( DOM.Xmlnode node, String namespace ) {
//depreciated			// generate subscription node
//depreciated			DOM.xmlNode subscription = node.addChildElement( 'Subscription', namespace, '' );
//depreciated			addChildText( subscription, 'Id', namespace, id );
//depreciated			addChildText( subscription, 'SalesRepOnAccount', namespace, salesRepOnAccount );
//depreciated			addChildText( subscription, 'SalesRepRoleOnAccount', namespace, salesRepRoleOnAccount );
//depreciated			addChildText( subscription, 'SalesforceAccountId', namespace, salesforceAccountId );
//depreciated			addChildText( subscription, 'SalesforceOpportunityId', namespace, salesforceOpportunityId );
//depreciated			addChildText( subscription, 'SalesforceAccountOwnerId', namespace, salesforceAccountOwnerId );
//depreciated			addChildText( subscription, 'RecordStatus', namespace, recordStatus );
//depreciated			addChildText( subscription, 'ErrorMessage', namespace, errorMessage );

//depreciated			// generate line nodes
//depreciated			for (SubscriptionLine line : lineList) {
//depreciated				line.marshal( subscription, namespace );
//depreciated			}

//depreciated			// generate partner nodes
//depreciated			for (SubscriptionPartner partner : partnerList) {
//depreciated				partner.marshal( subscription, namespace );
//depreciated			}

//depreciated			// generate user nodes
//depreciated			for (SubscriptionUser user : userList) {
//depreciated				user.marshal( subscription, namespace );
//depreciated			}
//depreciated		}

//depreciated		/**
//depreciated		 * this method is responsible for the creation of the renewal
//depreciated		 * and encapsulates all of the geo specific business rules
//depreciated		 */
//depreciated		public void process(Opportunity_Renewal oppRenewal) {
//depreciated			oppRenewal.isSuccess = false;
//depreciated			SavePoint sp = null;
//depreciated			Account account = null;
//depreciated			Opportunity opportunity = null;
//depreciated			Opportunity sourceOpportunity = null;

//depreciated			system.debug(LoggingLevel.INFO, 'Starting opportunity process');

//depreciated			try {
//depreciated				// check to make sure the subscription has lines before
//depreciated				// processing and exit if not
//depreciated				if (this.lineList.isEmpty()) {
//depreciated					system.debug(LoggingLevel.INFO, 'Subscription does not have line items');
//depreciated					this.recordStatus = STATUS_NO_LINES;
//depreciated					return;
//depreciated				}

//depreciated				// do not process any contracts that do not have lines
//depreciated				// this filter was added for contracts that have had all
//depreciated				// of their lines co-termed. Salesforce case no: RH-00033729
//depreciated				if (getCoTermLineCount() == this.lineList.size()) {
//depreciated					system.debug(Logginglevel.INFO, 'All line items have been co-termed');
//depreciated					this.recordStatus = STATUS_CO_TERMED;
//depreciated					return;
//depreciated				}

//depreciated				Set<String> opportunityNumbers = new Set<String>();
//depreciated				Set<String> orderNumbers = new Set<String>();
//depreciated				Set<String> poNumbers = new Set<String>();
//depreciated				if (this.opportunityNumber != null && this.opportunityNumber != '')
//depreciated				{
//depreciated					opportunityNumbers.add(this.opportunityNumber);
//depreciated				}
//depreciated				else if (this.orderNumber != null && this.orderNumber != '')
//depreciated				{
//depreciated					orderNumbers.add(this.orderNumber);
//depreciated				}
//depreciated				else if (this.poNumber != null && this.poNumber != '')
//depreciated				{
//depreciated					poNumbers.add(this.poNumber);
//depreciated				}
//depreciated				for (SubscriptionLine renewalLine : this.lineList) {
//depreciated					if (renewalLine.opportunityNumber != null && renewalLine.opportunityNumber != '')
//depreciated					{
//depreciated						opportunityNumbers.add(renewalLine.opportunityNumber);
//depreciated					}
//depreciated					else if (renewalLine.orderNumber != null && renewalLine.orderNumber != '')
//depreciated					{
//depreciated						orderNumbers.add(renewalLine.orderNumber);
//depreciated					}
//depreciated					else if (renewalLine.poNumber != null && renewalLine.poNumber != '')
//depreciated					{
//depreciated						poNumbers.add(renewalLine.poNumber);
//depreciated					}
//depreciated				}
//depreciated				List<Opportunity> sourceOpportunities = getSourceOpportunities(opportunityNumbers,orderNumbers,poNumbers);

//depreciated				// get the source opportunity based on the original
//depreciated				// opportunity number from the order, order number or the po number
//depreciated				sourceOpportunity = getSourceOpportunity(
//depreciated					sourceOpportunities,
//depreciated					this.opportunityNumber,
//depreciated					this.orderNumber,
//depreciated					this.poNumber);

//depreciated				if (sourceOpportunity != null) {
//depreciated					system.debug(Logginglevel.INFO, 'Source Opportunity Found: ' + sourceOpportunity.Id);
//depreciated				}
//depreciated				else {
//depreciated					system.debug(Logginglevel.INFO, 'Source Opportunity Not Found: ' + this.opportunityNumber);
//depreciated				}

//depreciated				// account logic change February 28, 2011:
//depreciated				// 1st use the account id from matching/manual process on validation file
//depreciated				// 2nd use the sold to account number
//depreciated				// 3rd create a new account
//depreciated				if (this.salesforceAccountId != null) {
//depreciated					account = getAccountById(this.salesforceAccountId);
//depreciated				}
//depreciated				if (account == null) {
//depreciated					account = getAccountByAccountNumber(this.soldToParty.accountNumber);
//depreciated				}
//depreciated				sp = Database.setSavePoint();
//depreciated				if (account == null) {
//depreciated					Database.SaveResult saveResult = Database.insert(convertToAccount(),false);
//depreciated					if(saveResult.isSuccess()) {
//depreciated						system.debug(Logginglevel.INFO, 'Created Account: ' + saveResult.getId());
//depreciated						account = getAccountById( saveResult.getId() );
//depreciated					}
//depreciated					else {
//depreciated						system.debug(Logginglevel.Error, 'Account Creation Failed: ' + saveResult.getErrors());
//depreciated						this.recordStatus = STATUS_ERROR;
//depreciated						this.errorMessage = 'Account Creation Failed: ' + saveResult.getErrors();
//depreciated						// no need to proceed
//depreciated						return;
//depreciated					}
//depreciated				}

//depreciated				system.debug(Logginglevel.INFO, 'Account Id: ' + account.id);

//depreciated				addAccountDataToSubscription(account);

//depreciated				// build the renewal opportunity
//depreciated				opportunity = convertToOpportunity(account, sourceOpportunity);

//depreciated				// create the renewal opportunity
//depreciated				Database.SaveResult saveResult2 = Database.insert(opportunity,false);
//depreciated				if(! saveResult2.isSuccess()) {
//depreciated					system.debug(Logginglevel.Error, 'Opportunity Creation Failed: ' + saveResult2.getErrors());
//depreciated					this.recordStatus = STATUS_ERROR;
//depreciated					this.errorMessage = 'Opportunity Creation Failed: ' + saveResult2.getErrors();
//depreciated					return;
//depreciated				}
//depreciated				system.debug(Logginglevel.INFO, 'Created Opportunity: ' + opportunity.Id);
//depreciated				this.salesforceOpportunityId = opportunity.Id;
//depreciated				this.recordStatus = STATUS_SUCCESS;

//depreciated				// call the function to create the exipring products
//depreciated				createExpiringProducts(sourceOpportunities);

//depreciated				// call the function to create the opportunity line items
//depreciated				createOpportunityLineItems();

//depreciated				// call the method to create opportunity partners
//depreciated				createOpportunityPartners();

//depreciated				// this section handles the region specific requirements
//depreciated				// for creating opportunity contact roles
//depreciated				if ('EMEA'.equals(this.region)) {
//depreciated					// if region EMEA then add source opportunity contacts only to the renewal opportunity
//depreciated					// if no contacts exit on the source opportunity or the source opportunity does not exsit then
//depreciated					// the opportunity will have no contacts
//depreciated					if (sourceOpportunity != null) {
//depreciated						createSourceOpportunityContactRoles(sourceOpportunity, opportunity);
//depreciated					}

//depreciated					// populate a map with the contact data so that we can
//depreciated					// perform a look up instead of querying for each contact
//depreciated					Map<String, Id> contactIdMap = getContactIdMap( null, account.Id, new Set<String>{
//depreciated						this.shipToParty.contact.email} );
//depreciated					createShipToContact(contactIdMap);
//depreciated				}
//depreciated				else if ('LATAM' == this.region) {
//depreciated					// for LATAM renewals create only the ship to contact from
//depreciated					// the original order
//depreciated					// populate a map with the contact data so that we can
//depreciated					// perform a look up instead of querying for each contact
//depreciated					Set<String> emails = new Set<String>{};
//depreciated					Map<String, Id> contactIdMap = getContactIdMap( null, account.Id, new Set<String>{
//depreciated							this.soldToParty.contact.email} );
//depreciated					createSoldToContact(contactIdMap);
//depreciated				}
//depreciated				else if ('APAC' == this.region) {
//depreciated					// populate a map with the contact data so that we can
//depreciated					// perform a look up instead of querying for each contact
//depreciated					Map<String, Id> contactIdMap = getContactIdMap( null, account.Id, new Set<String>{
//depreciated						this.soldToParty.contact.email,
//depreciated						this.shipToParty.contact.email} );

//depreciated					// for the APAC renewals create the ship to, sold to
//depreciated					// create the ship to contract from the order
//depreciated					createShipToContact(contactIdMap);

//depreciated					// create the sold to contact from the order
//depreciated					createSoldToContact(contactIdMap);
//depreciated				}
//depreciated				else if ('JAPAN' == this.region) {
//depreciated					// added February 28th, 2011 for Japan roll out
//depreciated					// if region JAPAN then add source opportunity contacts only to the renewal opportunity
//depreciated					// if no contacts exit on the source opportunity or the source opportunity does not exsit then
//depreciated					// the opportunity will have no contacts
//depreciated					if (sourceOpportunity != null) {
//depreciated						createSourceOpportunityContactRoles(sourceOpportunity, opportunity);
//depreciated					}
//depreciated				}
//depreciated				else if ('NA' == this.region) {
//depreciated					// populate a map with the contact data so that we can
//depreciated					// perform a look up instead of querying for each contact
//depreciated					Map<String, Id> contactIdMap = getContactIdMap( this.userList, account.Id, new Set<String>{
//depreciated						this.soldToParty.contact.email} );

//depreciated					// create the sold to contact from the order
//depreciated					createSoldToContact(contactIdMap);

//depreciated					for (SubscriptionUser renewalUser : this.userList) {
//depreciated						Id contactId = null;
//depreciated						if(renewalUser.email != null) {
//depreciated							contactId = contactIdMap.get( renewalUser.email.toLowerCase() );
//depreciated						}
//depreciated						if (contactId != null) {
//depreciated							renewalUser.salesforceContactId = contactId;
//depreciated							renewalUser.recordStatus = STATUS_DUPLICATE;
//depreciated						}
//depreciated						else {
//depreciated							createContact(this.salesforceAccountId, this.salesforceAccountOwnerId, renewalUser, contactIdMap);
//depreciated						}
//depreciated					}

//depreciated					// create OpportunityContactRoles
//depreciated					createOpportunityContactRoles();

//depreciated					// create CampaignMembers
//depreciated					createCampaignMembers();

//depreciated					// change forecast category
//depreciated					opportunity.ForecastCategoryName='Best Case';
//depreciated				}

//depreciated				// update the year 1 payment amount field
//depreciated				opportunity.Year1PaymentAmount__c = opportunity.amount;

//depreciated				// update the opportunity with the source opportunity id
//depreciated				if (sourceOpportunity != null) {
//depreciated					opportunity.Source_Opportunity__c = sourceOpportunity.id;
//depreciated				}

//depreciated				// update the stage based on the region logic
//depreciated				opportunity.StageName = getStageName( account, opportunity );

//depreciated				// call opportunity update
//depreciated				Database.SaveResult saveResult = Database.update(opportunity, false);
//depreciated				if (saveResult.isSuccess()) {
//depreciated					system.debug(Logginglevel.INFO, 'Updated Opportunity: ' + saveResult.getId());
//depreciated				}
//depreciated				else {
//depreciated					throw new SubscriptionException( ''+saveResult.getErrors() );
//depreciated				}
//depreciated				if(!oppRenewal.isTestMode) {
//depreciated					sp = null;
//depreciated				}
//depreciated				oppRenewal.isSuccess = true;
//depreciated			}
//depreciated			catch (Exception e) {
//depreciated				system.debug(Logginglevel.INFO, 'Exception' + e + ':\n'+e.getStackTraceString());
//depreciated				this.salesforceOpportunityId = null;
//depreciated				this.recordStatus = STATUS_ERROR;
//depreciated				this.errorMessage = e.getMessage()+':\n'+e.getStackTraceString();
//depreciated			}
//depreciated			finally {
//depreciated				if(sp != null) {
//depreciated					System.debug('Rollback entire process due to error');
//depreciated					Database.rollback(sp);
//depreciated				}
//depreciated			}
//depreciated		}

//depreciated		/**
//depreciated		 * addAccountDataToSubscription
//depreciated		 * populate the contract record with
//depreciated		 * the values from the created or updated account
//depreciated		 *
//depreciated		 * @param   Account account
//depreciated		 */
//depreciated		private void addAccountDataToSubscription(Account account) {
//depreciated			this.salesforceAccountId = account.id;
//depreciated			this.salesforceAccountOwnerId = account.owner.id;
//depreciated			this.salesRepOnAccount = account.owner.name;

//depreciated			if (account.owner.userRole != null) {
//depreciated				this.salesrepRoleOnAccount = account.owner.userRole.name;
//depreciated			}
//depreciated		}

//depreciated		/**
//depreciated		 * calculate the amount of the opportunity
//depreciated		 * recalculate the original contract amount based on the
//depreciated		 * lines left after the co-term lines were removed
//depreciated		 * Salesforce case no: RH-00033729
//depreciated		 * @return calculated amount
//depreciated		 */
//depreciated		private Double calculateAmount()
//depreciated		{
//depreciated			Decimal amount = 0.00;
//depreciated			for (SubscriptionLine renewalLine : this.lineList) {
//depreciated				if (! ('Y' == renewalLine.cotermFlag)) {
//depreciated					amount += renewalLine.totalPrice;
//depreciated				}
//depreciated			}
//depreciated			return amount.doubleValue();
//depreciated		}

//depreciated		/**
//depreciated		 * create or query an account
//depreciated		 *
//depreciated		 * @return Account account object created or queried
//depreciated		 */
//depreciated		private Account convertToAccount() {
//depreciated			Account account = getAccountByAccountNumber(this.soldToParty.accountNumber);
//depreciated			if (account == null) {
//depreciated				account = new Account(
//depreciated					Name = this.soldToParty.partyName,
//depreciated					ShippingStreet = this.shipToParty.address.address1 + (this.shipToParty.address.address2 != null ? this.shipToParty.address.address2 : ''),
//depreciated					ShippingCity = this.shipToParty.address.city,
//depreciated					ShippingState = this.shipToParty.address.state,
//depreciated					ShippingPostalCode = this.shipToParty.address.postalCode,
//depreciated					ShippingCountry = this.shipToParty.address.country,
//depreciated					BillingStreet = this.shipToParty.address.address1 + (this.billToParty.address.address2 != null ? this.billToParty.address.address2 : ''),
//depreciated					BillingCity = this.shipToParty.address.city,
//depreciated					BillingState = this.shipToParty.address.state,
//depreciated					BillingPostalCode = this.shipToParty.address.postalCode,
//depreciated					BillingCountry = this.shipToParty.address.country,
//depreciated					OracleAccountNumber__c = this.soldToParty.accountNumber,
//depreciated					RecordTypeId = this.accountRecordTypeId);

//depreciated				if ( this.salesforceAccountOwnerId != null && this.salesforceAccountOwnerId != '') {
//depreciated					account.OwnerId = this.salesforceAccountOwnerId;
//depreciated				}
//depreciated			}
//depreciated			return account;
//depreciated		}

//depreciated		/**
//depreciated		 * convertToOpportunity
//depreciated		 *
//depreciated		 * @param account
//depreciated		 * @param opportunity
//depreciated		 * @return new opportunity sobject
//depreciated		 */
//depreciated		private Opportunity convertToOpportunity(Account account, Opportunity sourceOpportunity) {
//depreciated			// Create opportunity object and add default values for all regions
//depreciated			// values can be overridden in region based logic statement
//depreciated			system.debug( '-- CampaignId: ' + this.salesforceCampaignId );

//depreciated			// set the close date to the max end date of the lines
//depreciated			// changed April 26, 2011
//depreciated			Date closeDate = null;
//depreciated			Date closeDateMin = null;
//depreciated			for (SubscriptionLine line : this.lineList) {
//depreciated				// calculate the close date to the line end date plus one year
//depreciated				// added June 14, 2011
//depreciated				if (closeDate == null || (closeDate < line.serviceEndDate)) {
//depreciated					closeDate = line.serviceEndDate;
//depreciated				}
//depreciated				if (closeDateMin == null || (closeDateMin > line.serviceEndDate)) {
//depreciated					closeDateMin = line.serviceEndDate;
//depreciated				}
//depreciated			}

//depreciated			String countryOfOrder = this.countryOfOrder;
//depreciated			// populate the country of order from the source opportunity if the source
//depreciated			// opportunity exists else use the country of order from the contract object
//depreciated			if (sourceOpportunity != null) {
//depreciated				countryOfOrder = sourceOpportunity.country_of_Order__c;
//depreciated			}

//depreciated			String opportunityType = 'Standard';
//depreciated			// set the opportunity type = Co-Term if the opportunity is
//depreciated			// created from more than one expiring contract
//depreciated			if (! this.mergedSubscriptionList.isEmpty()) {
//depreciated				opportunityType = 'Co-Term';
//depreciated			}

//depreciated			String billingAccountNumber = null;
//depreciated			String primaryPartner = null;
//depreciated			// if bill to account number and sold to account number are different
//depreciated			// then add the billing account number to the opportunity object along
//depreciated			// with the Bill To Party Name in the primary partner field (DISTRIBUTOR)
//depreciated			if (! (this.billToParty.accountNumber == this.soldToParty.accountNumber)) {
//depreciated				billingAccountNumber = this.billToParty.accountNumber;
//depreciated				primaryPartner = this.billToParty.partyName;
//depreciated			}

//depreciated			String reseller = null;
//depreciated			String naReseller = null;
//depreciated			String resellerPO = null;
//depreciated			// Set the reseller fields on the opportunity to the 1st reseller in additional parties
//depreciated			// also add the reseller PO number
//depreciated			for(SubscriptionPartner partner : partnerList) {
//depreciated				reseller = partner.partyName;
//depreciated				naReseller = partner.partyName;
//depreciated				resellerPO = partner.poNumber;
//depreciated				break;
//depreciated			}

//depreciated			// Begin process of region specific logic
//depreciated			String billingCity = this.billToParty.address.city;
//depreciated			String billingState = this.billToParty.address.state;
//depreciated			Date contractStartDate = this.contractStartDate;
//depreciated			Date contractEndDate = this.contractEndDate;
//depreciated			String opportunityName = null;
//depreciated			Id ownerId = account.owner.id;
//depreciated			String paymentType = null;
//depreciated			String poNumber = this.poNumber;
//depreciated			String shippingCity = this.shipToParty.address.city;
//depreciated			String shippingState = this.shipToParty.address.state;
//depreciated			if ('EMEA' == this.region) {
//depreciated				poNumber = null;
//depreciated				paymentType = 'EMEA Purchase Order';
//depreciated				opportunityName = account.Name + ' - Renewal - Service Contract #' + this.contractNumber;

//depreciated				// set the contract start date on the opportunity
//depreciated				// to the contract end date
//depreciated				contractStartDate = this.contractEndDate;

//depreciated				// if there are merged contracts then make the one with
//depreciated				// the earliest end date be the start date
//depreciated				for (MergedSubscription mergedContract : this.mergedSubscriptionList) {
//depreciated					if (mergedContract.contractEndDate < contractStartDate) {
//depreciated						contractStartDate = mergedContract.contractEndDate;
//depreciated					}
//depreciated					opportunityName += ', ' + mergedContract.contractNumber;
//depreciated				}

//depreciated				// Rally user story US13625 - Corrected 2013-02-15
//depreciated				if(Math.mod(closeDateMin.month(),3) == 0) {
//depreciated					closeDate = closeDateMin.toStartOfMonth(); // RH-00251160: US36179
//depreciated				}
//depreciated				else {
//depreciated					// Rally user story US13625 - Corrected 2013-02-15
//depreciated					closeDate = closeDateMin.addMonths( -1 );
//depreciated				}

//depreciated				// US38437 RH-00251160 - Move close dates before the 
//depreciated				// start of the current quarter to the start of the current 
//depreciated				// quarter
//depreciated				Date startOfQuarter = Date.today().toStartOfMonth();
//depreciated				startOfQuarter = startOfQuarter.addMonths(-Math.mod(startOfQuarter.month(),3));
//depreciated				if(closeDate < startOfQuarter) {
//depreciated					closeDate = startOfQuarter;
//depreciated				}

//depreciated				// set the contract end date on the opportunity
//depreciated				// to the contract end date plus one year
//depreciated				contractEndDate = contractStartDate.addYears(1);

//depreciated				// add one to the end date and use as the next contract start date
//depreciated				contractStartDate = contractStartDate.addDays(1);
//depreciated			}
//depreciated			else if ('APAC' == this.region) {
//depreciated				opportunityName = 'Renewal ' + account.Name + ' Service Contract #' + this.contractNumber;
//depreciated			}
//depreciated			else if ('JAPAN' == this.region) {
//depreciated				// change for Japan to add as a region February 28, 2011
//depreciated				opportunityName = 'Renewal ' + account.Name + ' Service Contract #' + this.contractNumber;

//depreciated				// change for Japan February 28, 2011
//depreciated				// for region is JAPAN and the sourceOpportunity is not null
//depreciated				// override the account.owner.id with the sourceOpportunity.owner.id
//depreciated				if (sourceOpportunity != null && sourceOpportunity.Owner.IsActive) {
//depreciated					ownerId = sourceOpportunity.Owner.Id;
//depreciated				}

//depreciated				// Rally Story US10167
//depreciated				// Map bill to and ship to city to the state field for Japan
//depreciated				shippingCity = null;
//depreciated				shippingState = this.shipToParty.address.city;

//depreciated				billingCity = null;
//depreciated				billingState = this.billToParty.address.city;
//depreciated			}
//depreciated			else if ('LATAM' == this.region) {
//depreciated				opportunityName = 'Renewal - ' + account.name + ' - (' + this.contractNumber + ')';
//depreciated				reseller = null;
//depreciated			}
//depreciated			else if ('NA' == this.region) {
//depreciated				opportunityName = 'Renewal - ' + account.name + ' - (' + this.contractNumber + ')';
//depreciated			}

//depreciated			if(closeDate == null) {
//depreciated				closeDate = System.today();
//depreciated			}

//depreciated			Opportunity opportunity = new Opportunity(
//depreciated				AccountId = account.Id,
//depreciated				Amount = calculateAmount(),
//depreciated				BillingAccountNumber__c = billingAccountNumber,
//depreciated				BillingAddress__c = this.billToParty.address.address1 + (this.billToParty.address.address2 != null ? this.billToParty.address.address2 : ''),
//depreciated				BillingCity__c = billingCity,
//depreciated				BillingState__c = billingState,
//depreciated				BillingCountry__c = this.billToParty.address.country,
//depreciated				BillingZipPostalCode__c = this.billToParty.address.postalCode,
//depreciated				CampaignId = this.salesforceCampaignId,
//depreciated				CloseDate = closeDate,
//depreciated				ContractNumber__c = this.contractNumber,
//depreciated				ContractStartDate__c = contractStartDate,
//depreciated				ContractEndDate__c = contractEndDate,
//depreciated				Country_of_Order__c = countryOfOrder,
//depreciated				CrossRegionalCreditCheck__c = 'None',
//depreciated				CurrencyIsoCode = this.currencyIsoCode,
//depreciated				Description = getDescription(),
//depreciated				LeadSourceDetail__c = this.leadSourceDetail,
//depreciated				NA_Reseller__c = naReseller,
//depreciated				Name =  truncate(opportunityName,120),
//depreciated				OpportunityType__c = opportunityType,
//depreciated				OwnerId = ownerId,
//depreciated				Pay_Now__c = 'Yes',
//depreciated				PaymentType__c = paymentType,
//depreciated				PONumber__c = poNumber,
//depreciated				Primary_Partner__c = primaryPartner,
//depreciated				RecordTypeId = this.opportunityRecordTypeId,
//depreciated				Renewal_Opportunity__c = true,
//depreciated				Renewable__c = 'No',
//depreciated				Reseller__c = reseller,
//depreciated				Reseller_PO__c = resellerPO,
//depreciated				ShippingAddress__c = this.shipToParty.address.address1 + (this.shipToParty.address.address2 != null ? this.shipToParty.address.address2 : ''),
//depreciated				ShippingCity__c = shippingCity,
//depreciated				ShippingState__c = shippingState,
//depreciated				ShippingCountry__c = this.shipToParty.address.country,
//depreciated				ShippingZipPostalCode__c = this.shipToParty.address.postalCode,
//depreciated				StageName = 'Prepare',
//depreciated				Touched__c = (sourceOpportunity != null && sourceOpportunity.Touched__c == true));

//depreciated			// removed by jherson Feburary 10, 2012
//depreciated			// rally task US14406: RH-00124768: Stop Checking Deal Reg Renewals Flag
//depreciated			//   if ( sourceOpportunity != null )
//depreciated			//	   opportunity.deal_registration__c = sourceOpportunity.deal_registration__c;

//depreciated			// set the fulfillment channel based on business rules
//depreciated			opportunity.FulfillmentChannel__c = getFulfillmentChannel( opportunity );
//depreciated			if(Opportunity_ManagePartners.NO_FINANCIAL_PARTNER_CHANNELS.contains( opportunity.FulfillmentChannel__c )) {
//depreciated				opportunity.BillingAccountNumber__c = null;
//depreciated				opportunity.Primary_Partner__c = null;
//depreciated			}
//depreciated			return opportunity;
//depreciated		}

//depreciated		/**
//depreciated		 * create Campaign Members
//depreciated		 * @param campaignId
//depreciated		 * @param contractUsers
//depreciated		 */
//depreciated		private void createCampaignMembers() {
//depreciated			List<CampaignMember> campaignMembers = new List<CampaignMember>();
//depreciated			for (SubscriptionUser renewalUser : this.userList) {
//depreciated				campaignMembers.add( new CampaignMember(
//depreciated					CampaignId = this.salesforceCampaignId,
//depreciated					ContactId = renewalUser.salesforceContactId) );
//depreciated			}

//depreciated			for (Database.SaveResult saveResult : Database.insert(campaignMembers,false)) {
//depreciated				// log the results, but otherwise ignore them
//depreciated				if (saveResult.isSuccess()) {
//depreciated					system.debug(LoggingLevel.INFO, 'Created Campaign Member: ' + saveResult.getId());
//depreciated				}
//depreciated				else {
//depreciated					system.debug(LoggingLevel.ERROR, 'Failed to create Campaign Member: ' + saveResult.getErrors());
//depreciated				}
//depreciated			}
//depreciated		}

//depreciated		/**
//depreciated		 * create Contact
//depreciated		 * @param contract
//depreciated		 * @param contractUsers
//depreciated		 * @param contactIdMap map of contact id by email address to update
//depreciated		 */
//depreciated		private void createContact(
//depreciated			Id accountId,
//depreciated			Id accountOwnerId,
//depreciated			SubscriptionUser renewalUser,
//depreciated			Map<String,Id> contactIdMap)
//depreciated		{
//depreciated			Contact contact = new Contact(
//depreciated				AccountId = accountId,
//depreciated				OwnerId = accountOwnerId,
//depreciated				FirstName = renewalUser.firstName,
//depreciated				LastName = renewalUser.lastName,
//depreciated				Email = (renewalUser.email != null ? renewalUser.email : ''),
//depreciated				Phone = (renewalUser.phone != null ? renewalUser.phone : ''),
//depreciated				LoginName__c = renewalUser.userName);

//depreciated			Database.SaveResult saveResult = Database.insert(contact,false);
//depreciated			if (saveResult.isSuccess()) {
//depreciated				system.debug(LoggingLevel.INFO, 'Created Contact: ' + contact.Id);
//depreciated				renewalUser.salesforceContactId = contact.Id;
//depreciated				renewalUser.recordStatus = STATUS_SUCCESS;
//depreciated				contactIdMap.put(contact.Email.toLowerCase(),contact.Id);
//depreciated			}
//depreciated			else {
//depreciated				system.debug(LoggingLevel.ERROR, 'Failed to create Contact: ' + saveResult.getErrors()[0].getMessage());
//depreciated				renewalUser.errorMessage = ''+saveResult.getErrors();
//depreciated				renewalUser.recordStatus = STATUS_ERROR;
//depreciated			}
//depreciated		}

//depreciated		/**
//depreciated		 * create expiring products
//depreciated		 */
//depreciated		private void createExpiringProducts(List<Opportunity> sourceOpportunities) {
//depreciated			// add the ordered item to a collection for bulk quering
//depreciated			List<String> productCodes = new List<String>();
//depreciated			for ( SubscriptionLine renewalLine : this.lineList ) {
//depreciated				if (renewalLine.salesforceProduct2Id == null || renewalLine.salesforceProduct2Id == '') {
//depreciated					productCodes.add( renewalLine.orderedItem );
//depreciated				}
//depreciated			}

//depreciated			// get the pricebook entry map
//depreciated			Map<String, PricebookEntry> pricebookEntryMap = getPricebookEntryMap( productCodes, this.currencyIsoCode );

//depreciated			List<Expiring_Product__c> expiringProducts = new List<Expiring_Product__c>();
//depreciated			for (SubscriptionLine renewalLine : this.lineList) {
//depreciated				if (renewalLine.salesforceProduct2Id == null || renewalLine.salesforceProduct2Id == '') {
//depreciated					PricebookEntry pricebookEntry = pricebookEntryMap.get( productCodes.remove(0) );
//depreciated					if ( pricebookEntry != null ) {
//depreciated						renewalLine.salesforceProduct2Id = pricebookEntry.product2.id;
//depreciated					}
//depreciated					else {
//depreciated						renewalLine.salesforceProduct2Id = null;
//depreciated					}
//depreciated				}

//depreciated				Expiring_Product__c expiringProduct = new Expiring_Product__c(
//depreciated					Expiring_Product_End_Date__c = renewalLine.serviceEndDate,
//depreciated					Expiring_Contract_Number__c = renewalLine.contractNumber,
//depreciated					Expiring_Contract_PO_Number__c = renewalLine.poNumber,
//depreciated					Expiring_Product_Start_Date__c = renewalLine.serviceStartDate,
//depreciated					Expiring_Oracle_Order_Number__c = renewalLine.orderNumber,
//depreciated					ExternalId__c = renewalLine.externalId,
//depreciated					CurrencyIsoCode = this.currencyIsoCode,
//depreciated					Co_Term__c = false,
//depreciated					Already_Renewed__c = false,
//depreciated					Opportunity__c = this.salesforceOpportunityId,
//depreciated					Product_Code__c = renewalLine.orderedItem,
//depreciated					Quantity__c = Double.valueOf( renewalLine.orderedQuantity ),
//depreciated					Sales_Price__c = renewalLine.unitSellingPrice,
//depreciated					//Total_Price__c = renewalLine.totalPrice,
//depreciated					Name = truncate(renewalLine.fulfilledItemDescription,80),
//depreciated					Mapped_Description__c = renewalLine.fulfilledItemDescription,
//depreciated					Product__c = renewalLine.salesforceProduct2Id);

//depreciated				// look up the source opportunity for each line in the subscription
//depreciated				// using opportunity number, order number or po number
//depreciated				Opportunity sourceOpportunity = getSourceOpportunity(
//depreciated					sourceOpportunities,
//depreciated					renewalLine.opportunityNumber,
//depreciated					renewalLine.orderNumber,
//depreciated					renewalLine.poNumber);

//depreciated				if (sourceOpportunity != null) {
//depreciated					expiringProduct.Renewal_Opportunity__c = sourceOpportunity.id;
//depreciated				}

//depreciated				// check to see if the expring product has been co-termed
//depreciated				// if so then set the indicator flags
//depreciated				if ('Y' == renewalLine.cotermFlag) {
//depreciated					expiringProduct.Already_Renewed__c = expiringProduct.co_Term__c = true;
//depreciated				}

//depreciated				// add the SKU mapping for the Co-Term wizard
//depreciated				if (renewalLine.configuredItem != null && renewalLine.configuredItem != '') {
//depreciated					expiringProduct.Mapped_SKU__c = truncate(renewalLine.configuredItem, 4);
//depreciated					expiringProduct.Mapped_Description__c = renewalLine.configuredItemDescription;
//depreciated					expiringProduct.Configured_Renewal_SKU__c = renewalLine.renewalItem;
//depreciated				}
//depreciated				else if (renewalLine.renewalItem != null) {
//depreciated					expiringProduct.Mapped_SKU__c = renewalLine.renewalItem;
//depreciated				}
//depreciated				else if (renewalLine.substituteItem != null) {
//depreciated					expiringProduct.Mapped_SKU__c = renewalLine.substituteItem;
//depreciated				}
//depreciated				else {
//depreciated					expiringProduct.Mapped_SKU__c = renewalLine.orderedItem;
//depreciated				}
//depreciated				expiringProducts.add(expiringProduct);
//depreciated			}

//depreciated			// save the salesforce record
//depreciated			// and log the results of the salesforce save
//depreciated			List<SubscriptionLine> renewalLines =  new List<SubscriptionLine>(this.lineList);
//depreciated			SubscriptionException e = null;
//depreciated			for (Database.UpsertResult upsertResult : Database.upsert(expiringProducts,Expiring_Product__c.Fields.ExternalId__c,false)) {
//depreciated				SubscriptionLine renewalLine = renewalLines.remove(0);
//depreciated				if (upsertResult.isSuccess()) {
//depreciated					system.debug(LoggingLevel.INFO, 'Created Expiring Product: ' + upsertResult.getId());
//depreciated					renewalLine.salesforceExpiringProductId = upsertResult.getId();
//depreciated					renewalLine.recordStatus = STATUS_SUCCESS;
//depreciated				}
//depreciated				else {
//depreciated					system.debug(LoggingLevel.ERROR, 'Failed to create Expiring Proudct: ' + upsertResult.getErrors());
//depreciated					renewalLine.errorMessage = ''+upsertResult.getErrors();
//depreciated					renewalLine.recordStatus = STATUS_ERROR;
//depreciated					e = new SubscriptionException('Failed to create Expiring Proudct: ' + upsertResult.getErrors());
//depreciated				}
//depreciated			}
//depreciated			// it seems pretty pointless to record errors and then throw the exception...
//depreciated			if(e != null) {
//depreciated				throw e;
//depreciated			}
//depreciated		}

//depreciated		private String getOpportunityContactRoleKey(OpportunityContactRole role) {
//depreciated			return role.OpportunityId+'\n'+role.ContactId+'\n'+role.Role;
//depreciated		}

//depreciated		/**
//depreciated		 * create contact roles for opportunities
//depreciated		 * @param opportunityId
//depreciated		 * @param contractUsers
//depreciated		 * @return update List of ContractUsers
//depreciated		 */
//depreciated		private void createOpportunityContactRoles() {
//depreciated			Set<String> avoidDuplicates = new Set<String>();
//depreciated			Map<String,List<SubscriptionUser>> subscriptionUsersMap = new Map<String,List<SubscriptionUser>>();

//depreciated			List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole>();

//depreciated			for (SubscriptionUser renewalUser : this.userList) {
//depreciated				OpportunityContactRole role = new OpportunityContactRole(
//depreciated					OpportunityId = this.salesforceOpportunityId,
//depreciated					ContactId = renewalUser.salesforceContactId,
//depreciated					Role = 'Shipping Contact');
//depreciated				String key = getOpportunityContactRoleKey(role);
//depreciated				List<SubscriptionUser> subscriptionUsers = subscriptionUsersMap.get(key);
//depreciated				if(subscriptionUsers == null) {
//depreciated					opportunityContactRoles.add( role );
//depreciated					subscriptionUsers = new List<SubscriptionUser>();
//depreciated					subscriptionUsersMap.put(key,subscriptionUsers);
//depreciated				}
//depreciated				subscriptionUsers.add(renewalUser);
//depreciated			}
//depreciated			if ( ! opportunityContactRoles.isEmpty()) {
//depreciated				List<SubscriptionUser> renewalUsers = new List<SubscriptionUser>(this.userList);
//depreciated				for (Database.SaveResult saveResult : Database.insert(opportunityContactRoles,false)) {
//depreciated					OpportunityContactRole role = opportunityContactRoles.remove(0);
//depreciated					String key = getOpportunityContactRoleKey(role);
//depreciated					if (saveResult.isSuccess()) {
//depreciated						system.debug(LoggingLevel.INFO, 'Created Opportunity Contact Role: ' + saveResult.getId());
//depreciated						String status = STATUS_SUCCESS;
//depreciated						for(SubscriptionUser renewalUser : subscriptionUsersMap.get(key)) {
//depreciated							renewalUser.salesforceContactRoleId = saveResult.getId();
//depreciated							renewalUser.recordStatus = status;
//depreciated							status = STATUS_DUPLICATE;
//depreciated						}
//depreciated					}
//depreciated					else {
//depreciated						system.debug(LoggingLevel.ERROR, 'Failed to create Opportunity Contact Role: ' + saveResult.getErrors());
//depreciated						for(SubscriptionUser renewalUser : subscriptionUsersMap.get(key)) {
//depreciated							if ( renewalUser.recordStatus != STATUS_ERROR ) {
//depreciated								renewalUser.errorMessage = ''+saveResult.getErrors();
//depreciated								renewalUser.recordStatus = STATUS_ERROR;
//depreciated							}
//depreciated						}
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}


//depreciated		/**
//depreciated		 * create opportunity line items
//depreciated		 * @return list of update ContractLines
//depreciated		 */
//depreciated		private void createOpportunityLineItems() {
//depreciated			// get the product codes from the renewal lines
//depreciated			List<String> productCodes = new List<String>();
//depreciated			for ( SubscriptionLine renewalLine : this.linelist ) {
//depreciated				if (renewalLine.salesforcePricebookEntryId == null || renewalLine.salesforcePricebookEntryId == '') {
//depreciated					if (renewalLine.configuredItem != null && renewalLine.configuredItem != '') {
//depreciated						productCodes.add( truncate(renewalLine.configuredItem, 4) );
//depreciated					}
//depreciated					else if (renewalLine.renewalItem != null && renewalLine.renewalItem != '') {
//depreciated						productCodes.add( renewalLine.renewalItem );
//depreciated					}
//depreciated					else if (renewalLine.substituteItem != null && renewalLine.substituteItem != '') {
//depreciated						productCodes.add( renewalLine.substituteItem );
//depreciated					}
//depreciated					else {
//depreciated						productCodes.add( renewalLine.orderedItem );
//depreciated					}
//depreciated				}
//depreciated			}

//depreciated			// get the pricebook entry map
//depreciated			Map<String, PricebookEntry> pricebookEntryMap = getPricebookEntryMap( productCodes, this.currencyIsoCode );

//depreciated			List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
//depreciated			for (SubscriptionLine renewalLine : this.lineList) {
//depreciated				// if the pricebook entry is null then lookup in Salesforce
//depreciated				PricebookEntry pricebookEntry = null;

//depreciated				if (renewalLine.salesforcePricebookEntryId == null || renewalLine.salesforcePricebookEntryId == '') {
//depreciated					String productCode = productCodes.remove(0);
//depreciated					pricebookEntry = pricebookEntryMap.get( productCode );
//depreciated					if ( pricebookEntry == null ) {
//depreciated						system.debug(LoggingLevel.ERROR, 'Global Pricebook query failed for Product : ' + productCode);
//depreciated						renewalLine.errorMessage = 'Global Pricebook query failed for Product : ' + productCode;
//depreciated						renewalLine.recordStatus = STATUS_ERROR;
//depreciated					}
//depreciated				}

//depreciated				system.debug( '-- pricebookEntry: ' + pricebookEntry );

//depreciated				// set the pricebook entry id and the product description
//depreciated				String pricebookEntryId = null;
//depreciated				String productDescription = null;
//depreciated				if ( renewalLine.salesforcePricebookEntryId != null && renewalLine.salesforcePricebookEntryId != '' ) {
//depreciated					pricebookEntryId = renewalLine.salesforcePricebookEntryId;
//depreciated					productDescription = renewalLine.fulfilledItemDescription;
//depreciated				}
//depreciated				else if ( pricebookEntry != null ) {
//depreciated					pricebookEntryId = pricebookEntry.Id;
//depreciated					productDescription = pricebookEntry.product2.description;
//depreciated				}
//depreciated				renewalLine.salesforcePricebookEntryId = pricebookEntryId;
//depreciated				// populate configured sku description if present
//depreciated				if ( renewalLine.configuredItemDescription != null && renewalLine.configuredItemDescription != '' ) {
//depreciated					productDescription = renewalLine.configuredItemDescription;
//depreciated				}

//depreciated				//
//depreciated				// 8/12/11
//depreciated				// HACK ALERT!!!
//depreciated				// This is the quickest way to allow us to still tie the saveResult to the original collection
//depreciated				//
//depreciated				// if the line has been co-termed then clear out the pricebookEntryId to cause the line to fail upon creation
//depreciated				// since it cannot be renewed
//depreciated				//
//depreciated				if ('Y' == renewalLine.cotermFlag) {
//depreciated					pricebookEntryId = null;
//depreciated					renewalLine.recordStatus = STATUS_CO_TERMED;
//depreciated				}

//depreciated				system.debug('-- pricebook entry id: ' + pricebookEntryId);

//depreciated				Date startDate = renewalLine.serviceEndDate.addDays(1);

//depreciated				// set the default line start date to the expiring
//depreciated				// contract end date plus one day
//depreciated				system.debug ( ' -- renewal line service end date: ' + renewalLine.serviceEndDate );

//depreciated				// set the default line end date to the contract end date
//depreciated				// plus one year or 3 years rally story US10441
//depreciated				Date endDate = renewalLine.serviceEndDate.addYears(1);
//depreciated				if ( this.contractStartDate.daysBetween( this.ContractEndDate ) >= 1095 ) {
//depreciated					endDate = endDate.addYears(2);
//depreciated				}

//depreciated				// build the opportunity line item object
//depreciated				OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
//depreciated					ActualEndDate__c = endDate,
//depreciated					ActualStartDate__c = startDate,
//depreciated					PricebookEntryId = pricebookEntryId,
//depreciated					OpportunityId = this.salesforceOpportunityId,
//depreciated					NewOrRenewal__c = 'Renewal',
//depreciated					Quantity = Double.valueOf( renewalLine.orderedQuantity ),
//depreciated					ScheduleLocked__c = true,
//depreciated					Contract_Numbers__c = renewalLine.contractNumber,
//depreciated					Configured_SKU__c = ( renewalLine.configuredItem != null ? renewalLine.renewalItem : null ),
//depreciated					UnitPrice = renewalLine.unitSellingPrice,
//depreciated					Description = productDescription);


//depreciated				// set the default line start date to the expiring
//depreciated				// contract end date plus one day
//depreciated				system.debug ( ' -- renewal line service end date: ' + renewalLine.serviceEndDate );

//depreciated				opportunityLineItems.add(opportunityLineItem);
//depreciated			}

//depreciated			// save the salesforce record
//depreciated			// and log the results of the salesforce save
//depreciated			SubscriptionException e = null;
//depreciated			List<SubscriptionLine> renewalLines = new List<SubscriptionLine>(this.lineList);
//depreciated			for (Database.SaveResult saveResult : Database.insert(opportunityLineItems,false)) {
//depreciated				SubscriptionLine renewalLine = renewalLines.remove(0);
//depreciated				if (saveResult.isSuccess()) {
//depreciated					system.debug(LoggingLevel.INFO, 'Created Opportunity Line Item: ' + saveResult.getId());
//depreciated					renewalLine.salesforceOpportunityLineId = saveResult.getId();
//depreciated					renewalLine.salesforceOpportunityId = this.salesforceOpportunityId;
//depreciated					renewalLine.recordStatus = STATUS_SUCCESS;
//depreciated				}
//depreciated				else {
//depreciated					system.debug(LoggingLevel.ERROR, 'Failed to create Opportunity Line Item: ' + saveResult.getErrors()[0].getMessage());

//depreciated					// we do not want to overwrite any previous errors on the line item
//depreciated					if ( renewalLine.recordStatus != STATUS_ERROR && renewalLine.recordStatus != STATUS_CO_TERMED) {
//depreciated						renewalLine.errorMessage = ''+saveResult.getErrors();
//depreciated						renewalLine.recordStatus = STATUS_ERROR;
//depreciated					}

//depreciated					// ignore any failures for cotermed line items
//depreciated					if ( renewalLine.cotermFlag != 'Y' ) {
//depreciated						e = new SubscriptionException('Failed to create Opportunity Line Item: ' + saveResult.getErrors()[0].getMessage());
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			if(e != null) {
//depreciated				throw e;
//depreciated			}
//depreciated		}

//depreciated		/**
//depreciated		 * create OpportunityPartners
//depreciated		 */
//depreciated		private void createOpportunityPartners() {
//depreciated			// create a collection of oracle party numbers
//depreciated			Set<String> oraclePartyNumbers = new Set<String>();
//depreciated			for ( SubscriptionPartner partner : this.partnerList ) {
//depreciated				if ( partner.partyNumber != null && partner.partyNumber != '' ) {
//depreciated					oraclePartyNumbers.add( partner.partyNumber );
//depreciated				}
//depreciated			}

//depreciated			if ( oraclePartyNumbers.isEmpty() ) {
//depreciated				return;
//depreciated			}

//depreciated			system.debug( 'Oracle Party Numbers: ' + oraclePartyNumbers );

//depreciated			// query partner status for all of the reseller partners
//depreciated			// we currently aren't concerned with other partner types
//depreciated			// generate a map of oracle numbers to partner status
//depreciated			Map<String, PartnerStatus__c> partnerStatusMap = new Map<String, PartnerStatus__c>();
//depreciated			for (PartnerStatus__c ps : [
//depreciated				SELECT
//depreciated					Partner__c,
//depreciated					Partner__r.Name,
//depreciated					Partner__r.OraclePartyNumber__c,
//depreciated					PartnerType__r.Hierarchy__c,
//depreciated					PartnerType__c,
//depreciated					PartnerType__r.Name,
//depreciated					PartnerTier__c,
//depreciated					PartnerTier__r.Name
//depreciated				FROM PartnerStatus__c
//depreciated				WHERE ActivationStatus__c = 'Active'
//depreciated					AND PartnerType__r.Hierarchy__c like 'Partner Type%'
//depreciated					AND PartnerType__r.Name = 'Reseller'
//depreciated					AND Partner__r.OraclePartyNumber__c IN :oraclePartyNumbers ] )
//depreciated			{
//depreciated				partnerStatusMap.put( ps.Partner__r.OraclePartyNumber__c, ps );
//depreciated			}

//depreciated			system.debug( 'Partner Status Map: ' + partnerStatusMap );

//depreciated			List<OpportunityPartner__c> opportunityPartners = new List<OpportunityPartner__c>();
//depreciated			List<SubscriptionPartner> partners = new List<SubscriptionPartner>();
//depreciated			for (SubscriptionPartner partner : this.partnerList) {
//depreciated				PartnerStatus__c partnerStatus = partnerStatusMap.get( partner.partyNumber );

//depreciated				// filter out partners that we can't find in the partnerStatusMap
//depreciated				if ( partnerStatus == null ) {
//depreciated					system.debug( LoggingLevel.INFO, 'Unable to locate partner' );
//depreciated					partner.errorMessage = 'Failed to create Opportunity Partner: Unable to locate partner';
//depreciated					partner.recordStatus = STATUS_ERROR;
//depreciated				}
//depreciated				else {
//depreciated					opportunityPartners.add( new OpportunityPartner__c(
//depreciated						Opportunity__c = this.salesforceOpportunityId,
//depreciated						Partner__c = partnerStatus.Partner__c,
//depreciated						PartnerType__c = partnerStatus.PartnerType__c,
//depreciated						PartnerTier__c = partnerStatus.PartnerTier__c,
//depreciated						RelationshipType__c = 'Reseller ' + ( opportunityPartners.size() + 2 ) ) );
//depreciated					partners.add(partner);
//depreciated				}
//depreciated			}
//depreciated			for(Database.SaveResult saveResult : Database.insert(opportunityPartners,false)) {
//depreciated				OpportunityPartner__c oppPartner = opportunityPartners.remove(0);
//depreciated				SubscriptionPartner partner = partners.remove(0);
//depreciated				if(saveResult.isSuccess()) {
//depreciated					system.debug( LoggingLevel.INFO, 'Created Opportunity Partner: ' + oppPartner.id );
//depreciated					partner.salesforceOpportunityPartnerId = oppPartner.Id;
//depreciated					partner.salesforceAccountId = this.salesforceAccountId;
//depreciated					partner.recordStatus = STATUS_SUCCESS;
//depreciated				}
//depreciated				else {
//depreciated					system.debug( LoggingLevel.ERROR, 'Failed to create Opportunity Partner: ' + saveResult.getErrors() );
//depreciated					partner.errorMessage = ''+saveResult.getErrors();
//depreciated					partner.recordStatus = STATUS_ERROR;
//depreciated				}
//depreciated			}
//depreciated		}

//depreciated		/**
//depreciated		 * create a ship to contact
//depreciated		 * @param contactIdMap mapping of email address to contact Id
//depreciated		 */
//depreciated		private void createShipToContact(Map<String,Id> contactIdMap) {
//depreciated			createOrQueryContact(this.salesforceAccountId,
//depreciated				this.salesforceOpportunityId,
//depreciated				this.salesforceAccountOwnerId,
//depreciated				this.salesforceCampaignId,
//depreciated				'Shipping Contact',
//depreciated				this.shipToParty.contact.name,
//depreciated				this.shipToParty.contact.email,
//depreciated				this.shipToParty.contact.phone,
//depreciated				true,
//depreciated				contactIdMap);
//depreciated		}


//depreciated		/**
//depreciated		 * create a sold to contact
//depreciated		 * @param contactIdMap mapping of email address to contact Id
//depreciated		 */
//depreciated		private void createSoldToContact(Map<String,Id> contactIdMap) {
//depreciated			createOrQueryContact(this.salesforceAccountId,
//depreciated				this.salesforceOpportunityId,
//depreciated				this.salesforceAccountOwnerId,
//depreciated				this.salesforceCampaignId,
//depreciated				'Technical Buyer',
//depreciated				this.soldToParty.contact.name,
//depreciated				this.soldToParty.contact.email,
//depreciated				this.soldToParty.contact.phone,
//depreciated				false,
//depreciated				contactIdMap);
//depreciated		}

//depreciated		/**
//depreciated		 * method to allow us to perform a look up for contact
//depreciated		 * data instead of querying for each contact
//depreciated		 *
//depreciated		 * @param users
//depreciated		 * @param account id
//depreciated		 * @return map of contact ids by email address
//depreciated		 */
//depreciated		private Map<String, Id> getContactIdMap(List<SubscriptionUser> users, Id accountId, Set<String> emails) {
//depreciated			emails.remove(null);
//depreciated			if(users != null) {
//depreciated				// get the email address from the renewal users
//depreciated				for ( SubscriptionUser renewalUser : users ) {
//depreciated					if(renewalUser.Email != null && renewalUser.Email != '') {
//depreciated						emails.add ( renewalUser.Email );
//depreciated					}
//depreciated				}
//depreciated			}

//depreciated			Map<String, Id> contactIdMap = new Map<String, Id>();
//depreciated			if(! emails.isEmpty()) {
//depreciated				// query the contacts by email address
//depreciated				// populate the contact map with the results
//depreciated				for ( Contact contact : [
//depreciated					SELECT
//depreciated						Email
//depreciated					FROM Contact
//depreciated					WHERE AccountId = :accountId
//depreciated						AND Email IN :emails ] )
//depreciated				{
//depreciated					contactIdMap.put ( contact.Email.toLowerCase(), contact.Id );
//depreciated				}
//depreciated			}
//depreciated			return contactIdMap;
//depreciated		}

//depreciated		/**
//depreciated		 * retrieves the number of line items that are co-termed
//depreciated		 *
//depreciated		 * @return number of coterm line items
//depreciated		 */
//depreciated		private Integer getCoTermLineCount() {
//depreciated			Integer count = 0;
//depreciated			for (SubscriptionLine line : this.lineList) {
//depreciated				if (line.CotermFlag == 'Y') {
//depreciated					count++;
//depreciated				}
//depreciated			}
//depreciated			return count;
//depreciated		}

//depreciated		/**
//depreciated		 * get renewal description
//depreciated		 * @return the description string
//depreciated		 */
//depreciated		private String getDescription() {
//depreciated			String description = '';

//depreciated			//
//depreciated			// add dealer contact details to the description
//depreciated			//
//depreciated			if (! this.partnerList.isEmpty()) {
//depreciated				description += 'Partner Contact: ' + (this.partnerList[0].contact.name != null ? this.partnerList[0].contact.name : '') + '\n';
//depreciated				description += 'Partner Email: ' + (this.partnerList[0].contact.email != null ? this.partnerList[0].contact.email : '') + '\n';
//depreciated				description += 'Partner Phone: ' + (this.partnerList[0].contact.phone != null ? this.partnerList[0].contact.phone : '') + '\n\n';
//depreciated			}

//depreciated			//
//depreciated			// add oracle order number and contract number to the description
//depreciated			//
//depreciated			if (this.orderId != null) {
//depreciated				description += 'Order Number: ' + this.orderNumber + '\n';
//depreciated				description += 'Contract Number: ' + this.contractNumber + '\n';
//depreciated			}

//depreciated			//
//depreciated			// for EMEA add extra information to the description
//depreciated			// including the merged contracts
//depreciated			//
//depreciated			if ('EMEA' == this.region) {
//depreciated				if (this.poNumber != null) {
//depreciated					description += 'PO Number: ' + this.poNumber + '\n';
//depreciated				}

//depreciated				if (this.opportunityNumber != null) {
//depreciated					description += 'Opportunity Number: ' + this.opportunityNumber  + '\n';
//depreciated				}

//depreciated				if (! this.mergedSubscriptionList.isEmpty()) {
//depreciated					for (MergedSubscription mergedContract : this.mergedSubscriptionList) {
//depreciated						description += '\n';
//depreciated						if (mergedContract.orderId != null) {
//depreciated							description += 'Order Number: ' + mergedContract.orderNumber + '\n';
//depreciated							description += 'Contract Number: ' + mergedContract.contractNumber + '\n';
//depreciated						}

//depreciated						if (mergedContract.poNumber != null) {
//depreciated							description += 'PO Number: ' + mergedContract.poNumber + '\n';
//depreciated						}

//depreciated						if (mergedContract.opportunityNumber != null) {
//depreciated							description += 'Opportunity Number: ' + mergedContract.opportunityNumber  + '\n';
//depreciated						}
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			return description;
//depreciated		}


//depreciated		/**
//depreciated		 * get the value which should be used as the FulfillmentChannel
//depreciated		 * @param opportunity
//depreciated		 * @return the opportunity fulfillment channel
//depreciated		 */
//depreciated		private String getFulfillmentChannel(Opportunity opportunity)
//depreciated		{
//depreciated			String fulfillmentChannel = 'Direct - VAR/VAD';
//depreciated			// new logic from US38832
//depreciated			if ( this.region == 'NA' && 'Web' == this.orderSourceName) {
//depreciated				fulfillmentChannel = 'Indirect – Webstore';
//depreciated			}
//depreciated			else {
//depreciated				BillToAccount__c bta = getBillToAccount(this.billToParty.accountNumber);
//depreciated				if(bta != null) {
//depreciated					fulfillmentChannel = bta.Channel__c;
//depreciated				}
//depreciated				else if('EMEA' == this.region) {
//depreciated					fulfillmentChannel = 'Direct - End Customer';
//depreciated				}
//depreciated				else if(('APAC' == this.region || 'JAPAN' == this.region) && (
//depreciated					(''+this.salesChannelCode).toUpperCase().indexof('OEM') >= 0 ||
//depreciated					(''+this.salesChannelCode).toLowerCase().indexof('original equipment manufacturer') >= 0) )
//depreciated				{
//depreciated					fulfillmentChannel = 'Direct – OEM';
//depreciated				}
//depreciated				else if ('Distributor' != this.salesChannelCode) {
//depreciated					fulfillmentChannel = 'Direct - End Customer';
//depreciated				}
//depreciated				else if('NA' == this.region) {
//depreciated					fulfillmentChannel = 'Indirect - VAR/VAD';
//depreciated				}
//depreciated			}
//			// if the financial partner is DLT or Carasoft then set the channel
//			// to their channel per ticket RH-00031976 else
//			// if we have a value in the dealer name field from poetic
//			// then set the channel to Indirect - VAR/VAD
//			// else check for order source and if web set
//			// the channel to Indirect - Webstore
//			// else default to Direct - End Customer
//			if (opportunity.primary_Partner__c != null && opportunity.primary_Partner__c.toUpperCase().contains('DLT SOLUTIONS')) {
//				fulfillmentChannel = 'Direct - DLT';
//			}
//			else if (opportunity.primary_Partner__c != null && opportunity.primary_Partner__c.toUpperCase().contains('CARAHSOFT')) {
//				fulfillmentChannel = 'Direct - Carahsoft';
//			}
//			else  if ( 'Distributor' == this.salesChannelCode ) {
//				if ( 'APAC' ==  this.region || 'EMEA' == this.region || 'JAPAN' == this.region) {
//					fulfillmentChannel = 'Direct - VAR/VAD';
//				}
//				else if ( 'LATAM' == this.region || 'NA' == this.region ) {
//					fulfillmentChannel = 'Indirect - VAR/VAD';
//				}
//			}
//			else if ( 'Web' == this.orderSourceName ) {
//				fulfillmentChannel = 'Indirect – Webstore';
//			}
//			else {
//				fulfillmentChannel = 'Direct - End Customer';
//			}
//depreciated			return fulfillmentChannel;
//depreciated		}

//depreciated		/**
//depreciated		 * find the stage name we should use based on business rules
//depreciated		 * @param account to use
//depreciated		 * @param opportunity to use
//depreciated		 * @return stage name based on business rules
//depreciated		 */
//depreciated		private String getStageName(Account account, Opportunity opportunity) {
//depreciated			String stageName = 'Prepare';
//depreciated			if ('APAC' == this.region || 'JAPAN' == this.region) {
//depreciated				stageName = 'Engage';
//depreciated			}
//depreciated			else if ('EMEA' == this.region) {
//depreciated				// added for EMEA per Hillary December 17, 2010
//depreciated				// updated per rally story US13625
//depreciated				stageName = 'Propose';
//depreciated			}
//depreciated			else if ('NA' == this.region) {
//depreciated				String roleName = account.owner.userRole.name.toUpperCase();
//depreciated				if ((this.contractAmount == null || this.contractAmount < 5000.0)
//depreciated					&& ! (roleName.endsWith(' FED') || roleName.contains(' FED ')) )
//depreciated				{
//depreciated					stageName = 'Engage';
//depreciated				}
//depreciated				else if ('Indirect - VAR/VAD' == opportunity.fulfillmentChannel__c) {
//depreciated					// case no RH-00033890 - all indirect opportunities should be set to qualified
//depreciated					stageName = 'Engage';
//depreciated				}
//depreciated			}
//depreciated			else if ('LATAM' == this.region) {
//depreciated				if (this.contractAmount == null || this.contractAmount < 2000.0) {
//depreciated					stageName = 'Engage';
//depreciated				}
//depreciated			}
//depreciated			return stageName;
//depreciated		}
//depreciated	}


//depreciated	/**
//depreciated	 * class that models a renewal line
//depreciated	 **/

//depreciated	public class SubscriptionLine {
//depreciated		public String configuredItem;
//depreciated		public String configuredItemDescription;
//depreciated		public Double contractLineId;
//depreciated		public String contractNumber;
//depreciated		public String cotermFlag;
//depreciated		public String description;
//depreciated		public String errorMessage;
//depreciated		public String externalId;
//depreciated		public Integer fiscalQuarter;
//depreciated		public Integer fiscalYear;
//depreciated		public String fulfilledItem;
//depreciated		public String fulfilledItemDescription;
//depreciated		public Long id;
//depreciated		public Long mergeToSubscriptionId;
//depreciated		public String nfrFlag;
//depreciated		public String opportunityNumber;
//depreciated		public String orderedItem;
//depreciated		public Integer orderedQuantity;
//depreciated		public Long orderLineId;
//depreciated		public String orderLineNumber;
//depreciated		public String orderNumber;
//depreciated		public String poNumber;
//depreciated		public String pricingAttributes;
//depreciated		public String productLine;
//depreciated		public String recordStatus;
//depreciated		public String renewalItem;
//depreciated		public Double revenueAmount;
//depreciated		public String salesforceExpiringProductId;
//depreciated		public String salesforceOpportunityId;
//depreciated		public String salesforceOpportunityLineId;
//depreciated		public String salesforcePricebookEntryId;
//depreciated		public String salesforceProduct2Id;
//depreciated		public Date serviceStartDate;
//depreciated		public Date serviceEndDate;
//depreciated		public Long subscriptionId;
//depreciated		public String substituteItem;
//depreciated		public Double totalPrice;
//depreciated		public Double unitSellingPrice;


//depreciated		/**
//depreciated		 * Populates opportunity renewal line from XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 * @param namespace
//depreciated		 */
//depreciated		public void unmarshal( DOM.Xmlnode node, String namespace ) {
//depreciated			// Populate with values from the xml node children
//depreciated			configuredItem = parseText(node,'ConfiguredItem', namespace);
//depreciated			configuredItemDescription = parseText(node,'ConfiguredItemDescription', namespace);
//depreciated			contractLineId = parseDouble(node,'ContractLineId', namespace);
//depreciated			contractNumber = parseText(node,'ContractNumber', namespace);
//depreciated			cotermFlag = parseText(node,'CotermFlag', namespace);
//depreciated			description = parseText(node,'Description', namespace);
//depreciated			errorMessage = '';
//depreciated			externalId = parseText(node,'ExternalId',namespace);
//depreciated			fiscalQuarter = parseInteger(node,'FiscalQuarter', namespace);
//depreciated			fiscalYear = parseInteger(node,'FiscalYear',namespace);
//depreciated			fulfilledItem = parseText(node,'FulfilledItem', namespace);
//depreciated			fulfilledItemDescription = parseText(node,'FulfilledItemDescription', namespace);
//depreciated			Id = parseLong(node,'Id', namespace);
//depreciated			mergeToSubscriptionId = parseLong(node,'MergeToSubscriptionId', namespace);
//depreciated			nfrFlag = parseText(node,'NfrFlag', namespace);
//depreciated			opportunityNumber = parseText(node,'OpportunityNumber', namespace);
//depreciated			orderedItem = parseText(node,'OrderedItem', namespace);
//depreciated			orderedQuantity = parseInteger(node,'OrderedQuantity', namespace);
//depreciated			orderLineId = parseLong(node,'OrderLineId', namespace);
//depreciated			orderLineNumber = parseText(node,'OrderLineNumber', namespace);
//depreciated			orderNumber = parseText(node,'OrderNumber', namespace);
//depreciated			poNumber = parseText(node,'PoNumber', namespace);
//depreciated			pricingAttributes = parseText(node,'PricingAttributes', namespace);
//depreciated			productLine = parseText(node,'ProductLine', namespace);
//depreciated			// removed unused variable assignment 2012-03-19
//depreciated			//DOM.Xmlnode recordDate = node.getChildElement( 'RecordDate', namespace );
//depreciated			// added missing assignment 2012-03-19
//depreciated			recordStatus = parseText(node,'RecordStatus', namespace);
//depreciated			renewalItem = parseText(node,'RenewalItem', namespace);
//depreciated			revenueAmount = parseDouble(node,'RevenueAmount', namespace);
//depreciated			salesforceExpiringProductId = parseText(node,'SalesforceExpiringProductId', namespace);
//depreciated			salesforceOpportunityId = parseText(node,'SalesforceOpportunityId', namespace);
//depreciated			salesforceOpportunityLineId = parseText(node,'SalesforceOpportunityLineId', namespace);
//depreciated			salesforcePricebookEntryId = parseText(node,'SalesforcePricebookEntryId', namespace);
//depreciated			salesforceProduct2Id = parseText(node,'SalesforceProduct2Id', namespace);
//depreciated			serviceEndDate = parseDate(node,'ServiceEndDate', namespace);
//depreciated			serviceStartDate = parseDate(node,'ServiceStartDate', namespace);
//depreciated			subscriptionId = parseLong(node,'SubscriptionId', namespace);
//depreciated			substituteItem = parseText(node,'SubstituteItem', namespace);
//depreciated			totalPrice = parseDouble(node,'TotalPrice', namespace);
//depreciated			unitSellingPrice = parseDouble(node,'UnitSellingPrice', namespace);
//depreciated		}

//depreciated		/**
//depreciated		 * method for marshalling an object to XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 */
//depreciated		public void marshal( DOM.XmlNode node, String namespace ) {
//depreciated			// generate line node
//depreciated			DOM.xmlNode line = node.addChildElement( 'Line', namespace, '' );
//depreciated			addChildText(line, 'Id', namespace, id );
//depreciated			addChildText(line, 'ExternalId',namespace,externalId);
//depreciated			addChildText(line, 'SalesforceExpiringProductId', namespace, salesforceExpiringProductId );
//depreciated			addChildText(line, 'SalesforceOpportunityLineId', namespace, salesforceOpportunityLineId );
//depreciated			addChildText(line, 'SalesforcePricebookEntryId', namespace, salesforcePricebookEntryId );
//depreciated			addChildText(line, 'SalesforceProduct2Id', namespace, salesforceProduct2Id );
//depreciated			addChildText(line, 'RecordStatus', namespace, recordStatus );
//depreciated			addChildText(line, 'ErrorMessage', namespace, errorMessage );
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * class that models a renewal partner
//depreciated	 */
//depreciated	public class SubscriptionPartner extends SubscriptionParty {
//depreciated		public Long apId;
//depreciated		public String errorMessage;
//depreciated		public Long id;
//depreciated		public String partnerType;
//depreciated		public String poNumber;
//depreciated		public String recordStatus;
//depreciated		public String salesforceOpportunityPartnerId;
//depreciated		public Long subscriptionId;


//depreciated		/**
//depreciated		 * Populates opportunity renewal partner from XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 * @param namespace
//depreciated		 */
//depreciated		public override void unmarshal( DOM.Xmlnode node, String namespace ) {
//depreciated			super.unmarshal (node, namespace );

//depreciated			//
//depreciated			// loop through the child nodes of the argument node to populate
//depreciated			// Partner
//depreciated			//

//depreciated			for ( DOM.XmlNode n : node.getChildElements() ) {
//depreciated				if ( n.getName() == 'PartnerParty' ) {
//depreciated					super.unmarshal ( n, namespace );
//depreciated				}
//depreciated			}

//depreciated			// Populate with values from the xml node children
//depreciated			apId = parseLong(node,'ApId', namespace);
//depreciated			id = parseLong(node,'Id', namespace);
//depreciated			partnerType = parseText(node,'PartnerType', namespace);
//depreciated			poNumber = parseText(node,'PoNumber', namespace);
//depreciated			recordStatus = parseText(node,'RecordStatus', namespace);
//depreciated			salesforceOpportunityPartnerId = parseText(node,'SalesForceOpportunityPartnerId', namespace);
//depreciated			subscriptionId = parseLong(node,'SubscriptionId', namespace );
//depreciated		}


//depreciated		/**
//depreciated		 * method for marshalling an object to XML
//depreciated		 *
//depreciated		 * @return DOM.Document
//depreciated		 */
//depreciated		public override void marshal( DOM.XmlNode node, String namespace ) {
//depreciated			// generate partner node
//depreciated			DOM.xmlNode line = node.addChildElement( 'Partner', namespace, '' );
//depreciated			super.marshal ( line, namespace );

//depreciated			addChildText(line, 'Id', namespace,id );
//depreciated			addChildText(line, 'SalesforceOpportunityPartnerId', namespace, salesforceOpportunityPartnerId );
//depreciated			addChildText(line, 'RecordStatus', namespace, recordStatus );
//depreciated			addChildText(line, 'ErrorMessage', namespace, errorMessage );
//depreciated		}
//depreciated	}


//depreciated	/**
//depreciated	 * class that models a renewal party
//depreciated	 */
//depreciated	public virtual class SubscriptionParty {
//depreciated		public Long accountId;
//depreciated		public String accountNumber;
//depreciated		public Long partyId;
//depreciated		public String partyName;
//depreciated		public String partyNumber;
//depreciated		public String salesforceAccountId;
//		Removed unused variables 2012-03-19
//		public String salesforceContactId;
//		public String salesforceContactRoleId;
//depreciated		public SubscriptionAddress address;
//depreciated		public SubscriptionContact contact;


//depreciated		/**
//depreciated		 * Populates opportunity renewal partner from XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 * @param namespace
//depreciated		 */
//depreciated		public virtual void unmarshal( DOM.Xmlnode node, String namespace ) {
//depreciated			// Populate with values from the xml node children
//depreciated			accountId = parseLong(node,'AccountId', namespace);
//depreciated			accountNumber = parseText(node,'AccountNumber', namespace);
//depreciated			partyId = parseLong(node,'PartyId', namespace);
//depreciated			partyName = parseText(node,'PartyName', namespace);
//depreciated			partyNumber = parseText(node,'PartyNumber', namespace);
//depreciated			salesforceAccountId =  parseText(node,'SalesforceAccountId', namespace);
//depreciated			// removed unused assignments 2012-03-19
//depreciated			//DOM.Xmlnode salesforceContactId = node.getChildElement( 'SalesforceContactId', namespace );
//depreciated			//DOM.Xmlnode SalesforceContactRoleId = node.getChildElement( 'SalesforceContactRoleId', namespace );


//depreciated			//
//depreciated			// loop through the child nodes of the argument node to populate
//depreciated			// address and contact
//depreciated			//

//depreciated			for ( DOM.XmlNode n : node.getChildElements() ) {
//depreciated				String nodeName = n.getName();
//depreciated				if ( nodeName == 'Address' ) {
//depreciated					address = new SubscriptionAddress();
//depreciated					address.unmarshal( n, namespace );
//depreciated				}
//depreciated				else if ( nodeName == 'Contact' ) {
//depreciated					contact = new SubscriptionContact();
//depreciated					contact.unmarshal( n, namespace );
//depreciated				}
//depreciated			}
//depreciated		}


//depreciated		/**
//depreciated		 * method for marshalling an object to XML
//depreciated		 */
//depreciated		public virtual void marshal( DOM.XmlNode node, String namespace ) {
//depreciated			// generate contact node
//depreciated			DOM.xmlNode contactNode = node.addChildElement( 'Contact', namespace, '' );
//depreciated			contact.marshal( contactNode, namespace );

//depreciated			addChildText(node,'SalesforceAccountId', namespace, salesforceAccountId );
//depreciated		}
//depreciated	}


//depreciated	/**
//depreciated	 * class that models a renewal address
//depreciated	 */
//depreciated	public class SubscriptionAddress {
//depreciated		public String address1;
//depreciated		public String address2;
//depreciated		public String city;
//depreciated		public String country;
//depreciated		public Long locationId;
//depreciated		public String postalCode;
//depreciated		public String state;


//depreciated		/**
//depreciated		 * Populates opportunity renewal address from XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 * @param namespace
//depreciated		 */
//depreciated		public void unmarshal( DOM.Xmlnode node, String namespace )
//depreciated		{
//depreciated			// Populate with values from the xml node children
//depreciated			address1 = parseText(node,'Address1', namespace);
//depreciated			address2 = parseText(node,'Address2', namespace);
//depreciated			city = parseText(node,'City', namespace);
//depreciated			country = parseText(node,'Country', namespace);
//depreciated			locationId = parseLong(node,'LocationId', namespace);
//depreciated			postalCode = parseText(node,'PostalCode', namespace);
//depreciated			state = parseText(node,'State', namespace);
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * class that models a renewal contact
//depreciated	 */
//depreciated	public class SubscriptionContact {
//depreciated		public Long contactId;
//depreciated		public String email;
//depreciated		public String firstName;
//depreciated		public String lastName;
//depreciated		public String name;
//depreciated		public String phone;
//depreciated		public String salesforceContactId;
//depreciated		public String salesforceContactRoleId;

//depreciated		/**
//depreciated		 * Populates opportunity renewal contact from XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 * @param namespace
//depreciated		 */
//depreciated		public void unmarshal( DOM.Xmlnode node, String namespace ) {
//depreciated			// Populate with values from the xml node children
//depreciated			contactId = parseLong(node,'ContactId', namespace);
//depreciated			email = parseText(node,'Email', namespace);
//depreciated			firstName = parseText(node,'FirstName', namespace);
//depreciated			lastName = parseText(node,'LastName', namespace);
//depreciated			name = parseText(node, 'Name', namespace);
//depreciated			phone = parseText(node, 'Phone', namespace);
//depreciated			salesforceContactId = parseText(node,'SalesforceContactId', namespace);
//depreciated			salesforceContactRoleId = parseText(node,'SalesforceContactRoleId', namespace);
//depreciated		}

//depreciated		/**
//depreciated		 * method for marshalling an object to XML
//depreciated		 */
//depreciated		public virtual void  marshal( DOM.XmlNode node, String namespace ) {
//depreciated			addChildText(node,'SalesforceContactId', namespace, salesforceContactId );
//depreciated			addChildText(node, 'SalesforceContactRoleId', namespace, salesforceContactRoleId );
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * class that models a renewal user
//depreciated	 */
//depreciated	public class SubscriptionUser {
//depreciated		public String email;
//depreciated		public String errorMessage;
//depreciated		public String firstName;
//depreciated		public Long id;
//depreciated		public String lastName;
//depreciated		public String name;
//depreciated		public String phone;
//depreciated		public String recordStatus;
//depreciated		public String salesforceContactId;
//depreciated		public String salesforceContactRoleId;
//depreciated		public Long subscriptionId;
//depreciated		public Long userId;
//depreciated		public String userName;
//depreciated		public String userType;

//depreciated		/**
//depreciated		 * Populates opportunity renewal user from XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 * @param namespace
//depreciated		 */
//depreciated		public void unmarshal( DOM.Xmlnode node, String namespace ) {
//depreciated			// Populate with values from the xml node children
//depreciated			email = parseText(node,'Email', namespace);
//depreciated			errorMessage = '';
//depreciated			firstName = parseText(node,'FirstName', namespace);
//depreciated			id = parseLong(node,'Id', namespace);
//depreciated			lastName = parseText(node,'LastName', namespace);
//depreciated			name = parseText(node,'Name', namespace);
//depreciated			phone = parseText(node,'Phone', namespace);
//depreciated			recordStatus = parseText(node,'RecordStatus', namespace);
//depreciated			salesforceContactId = parseText(node,'SalesforceContactId', namespace);
//depreciated			salesforceContactRoleId = parseText(node,'SalesforceContactRoleId', namespace);
//depreciated			subscriptionId = parseLong(node,'SubscriptionId', namespace);
//depreciated			userId = parseLong(node,'UserId', namespace);
//depreciated			userName = parseText(node,'UserName', namespace);
//depreciated			userType = parseText(node,'UserType', namespace);
//depreciated		}

//depreciated		/**
//depreciated		 * method for marshalling an object to XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 */
//depreciated		public void marshal( DOM.XmlNode node, String namespace ) {
//depreciated			// generate user node
//depreciated			DOM.xmlNode user = node.addChildElement( 'User', namespace, '' );
//depreciated			addChildText(user, 'Id', namespace, id);
//depreciated			addChildText(user, 'SalesforceContactId', namespace, salesforceContactId );
//depreciated			addChildText(user, 'SalesforceContactRoleId', namespace, salesforceContactRoleId );
//depreciated			addChildText(user, 'RecordStatus', namespace, recordStatus );
//depreciated			addChildText(user, 'ErrorMessage', namespace, errorMessage );
//depreciated		}
//depreciated	}


//depreciated	/**
//depreciated	 * class that models a renewal merged subscription
//depreciated	 */
//depreciated	public class MergedSubscription {
//depreciated		public Double contractAmount;
//depreciated		public Date contractEndDate;
//depreciated		public Long contractId;
//depreciated		public String contractNumber;
//depreciated		public Date contractStartDate;
//		public Double expiringProductsAmount;
//depreciated		public Long id;
//depreciated		public Long mergeToSubscriptionId;
//depreciated		public String opportunityNumber;
//depreciated		public Long orderId;
//depreciated		public String orderNumber;
//depreciated		public String poNumber;

//depreciated		/**
//depreciated		 * Populates opportunity renewal merged subscription from XML
//depreciated		 *
//depreciated		 * @param node
//depreciated		 * @param namespace
//depreciated		 */
//depreciated		public void unmarshal( DOM.Xmlnode node, String namespace ) {
//depreciated			// Populate with values from the xml node children
//depreciated			contractAmount = parseDouble(node,'ContractAmount', namespace);
//depreciated			contractEndDate = parseDate(node,'ContractEndDate', namespace);
//depreciated			contractId = parseLong(node,'ContractId', namespace);
//depreciated			contractNumber = parseText(node,'ContractNumber', namespace);
//depreciated			contractStartDate = parseDate(node,'ContractStartDate', namespace);
//			expiringProductsAmount = parseDouble(node,'ExpiringProductsAmount', namespace);
//depreciated			id = parseLong(node,'Id', namespace);
//depreciated			mergeToSubscriptionId = parseLong(node,'MergeToSubscriptionId', namespace);
//depreciated			opportunityNumber = parseText(node,'OpportunityNumber', namespace);
//depreciated			orderId = parseLong(node,'OrderId', namespace);
//depreciated			orderNumber = parseText(node,'OrderNumber', namespace);
//depreciated			poNumber = parseText(node,'PoNumber', namespace);
//depreciated		}
//depreciated	}

//depreciated	public class SubscriptionException extends Exception {}
}