/**
 * Test class for Opportunity_Renewal.cls
 *
 * NOTE: The tests are a bit too high level.  This makes the tests slow to run
 * and means of an error occurs the tests do not really help isolate where the
 * error is.
 *
 * @version 2015-01-27
 * @author  Bryan Bosely <bbosely@redhat.com>
 * 2011-02-11 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2015-01-27 - Depreciated
 * 2013-11-12 - Avoid concat of null to strings as this no longer seems to give consistent results
 * 2013-10-30 - Updated channel used for emea test.
 * 2013-09-30 - Updated EMEA fulfullment channel check and respective account checks.
 * 2013-09-17 - Updated EMEA tests
 * 2013-02-14 - Added external id to expired products.
 *            - Added status return for successful product lines
 *            - Corrected the error of inserting duplicate Contact Id's
 * 2012-09-04 - Depreciated Expiring_Products_Total_Amount__c and Total_Price__c assignment.
 * 2012-05-31 - Expose MESSAGE, and add tests for new properties
 * 2012-03-21 - Add queries to validate create opportunity tests for each region.
 * Scott Coleman <scoleman@redhat.com>
 * 2014-06-19 - Removing redundant assertion of Campaign Name format - checking Campaign Id is enough here.
 */
@isTest
public class Opportunity_RenewalTest
{
//depreciated	static String NAMESPACE = 'http://salesforce.redhat.com/renewals';
//depreciated	static Opportunity_Renewal OPPORTUNITY_RENEWAL = new Opportunity_Renewal();
//depreciated	static Opportunity_Renewal.Opportunity_RenewalMessage ORM = new Opportunity_Renewal.Opportunity_RenewalMessage();

//depreciated	//
//depreciated	// create the opportunity object hierarchy
//depreciated	//

//depreciated	static Campaign CAMPAIGN { get {
//depreciated		if(CAMPAIGN == null) {
//depreciated			// create a campaign
//depreciated			CAMPAIGN = new Campaign(Name = 'Test Campaign');
//depreciated			insert CAMPAIGN;
//depreciated		}
//depreciated		return CAMPAIGN;
//depreciated	}}
//depreciated	static Product2 PRODUCT { get {
//depreciated		if(PRODUCT == null) {
//depreciated			// create a product
//depreciated			PRODUCT = new Product2(
//depreciated				Description = 'Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.',
//depreciated				IsActive = true,
//depreciated				Name = 'Happy Fun Ball',
//depreciated				ProductCode = 'HFB007');
//depreciated			insert PRODUCT;
//depreciated		}
//depreciated		return PRODUCT;
//depreciated	}}
//depreciated	static Pricebook2 GLOBAL_PRICEBOOK { get {
//depreciated		if(GLOBAL_PRICEBOOK == null) {
//depreciated			// get the id of the global price book
//depreciated			GLOBAL_PRICEBOOK = [SELECT Id FROM PriceBook2 WHERE Name = 'Global Price Book'];
//depreciated		}
//depreciated		return GLOBAL_PRICEBOOK;
//depreciated	}}
//depreciated	static PricebookEntry PRICEBOOK_ENTRY { get {
//depreciated		if(PRICEBOOK_ENTRY == null) {
//depreciated			// get the id of the standard price book
//depreciated			Pricebook2 priceBook = [SELECT Id FROM PriceBook2 WHERE isStandard = true];

//depreciated			// create a pricebook entry for the standard pricebook
//depreciated			PricebookEntry priceBookEntry = new PricebookEntry(
//depreciated				CurrencyIsoCode = 'USD',
//depreciated				isActive = true,
//depreciated				Pricebook2Id = priceBook.Id,
//depreciated				Product2Id = PRODUCT.Id,
//depreciated				UnitPrice = 2000.00);

//depreciated			// create a pricebook entry for the global pricebook
//depreciated			PRICEBOOK_ENTRY = new PricebookEntry(
//depreciated				CurrencyIsoCode = priceBookEntry.CurrencyIsoCode,
//depreciated				isActive = true,
//depreciated				Pricebook2Id = GLOBAL_PRICEBOOK.id,
//depreciated				Product2Id = PRODUCT.Id,
//depreciated				UnitPrice = 2000.00);
//depreciated			insert new List<PricebookEntry>{priceBookEntry,PRICEBOOK_ENTRY};
//depreciated		}
//depreciated		return PRICEBOOK_ENTRY;
//depreciated	}}
//depreciated	static User USER { GET {
//depreciated		if(USER == null) {
//depreciated			// create a user
//depreciated			Profile profile = [SELECT Id FROM Profile WHERE NAME = 'System Administrator'];

//depreciated			USER = new User(
//depreciated				FirstName = 'Bryan',
//depreciated				LastName = 'Bosely',
//depreciated				Username = 'bbosely@email.com',
//depreciated				Email = 'bbosely@email.com',
//depreciated				Alias = 'bbosely',
//depreciated				CommunityNickname = 'Bryan',
//depreciated				TimeZoneSidKey = 'America/New_York',
//depreciated				LocaleSidKey = 'en_US',
//depreciated				EmailEncodingKey = 'UTF-8',
//depreciated				ProfileId = profile.Id,
//depreciated				LanguageLocaleKey = 'en_US');

//depreciated			// use a runAs statement to create a new context to avoid mixed DML errors
//depreciated			System.runAs(new User(Id = UserInfo.getUserId())) {					
//depreciated				insert USER;
//depreciated			}
//depreciated		}
//depreciated		return USER;
//depreciated	}}
//depreciated	public static String MESSAGE { GET {
//depreciated		if(MESSAGE == null) {
//depreciated			// create a generic message
//depreciated			MESSAGE = '<?xml version="1.0" encoding="UTF-8"?>' +
//depreciated			'<SalesforceMessage xmlns="http://salesforce.redhat.com/renewals"' +
//depreciated			'		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' +
//depreciated			'		xsi:schemaLocation="http://salesforce.redhat.com/renewals Renewals.xsd ">' +
//depreciated			'	<Header>' +
//depreciated			'		<Operation>Operation</Operation>' +
//depreciated			'		<Type>Type</Type>' +
//depreciated			'		<InstanceId>InstanceId</InstanceId>' +
//depreciated			'		<Timestamp>2011-02-10</Timestamp>' +
//depreciated			'	</Header>' +
//depreciated			'	<Payload>' +
//depreciated			'		<Subscription>' +
//depreciated			'			<Id>0</Id>' +
//depreciated			'			<OrderId>0</OrderId>' +
//depreciated			'			<OrderNumber>OrderNumber</OrderNumber>' +
//depreciated			'			<ContractId>0</ContractId>' +
//depreciated			'			<ContractNumber>ContractNumber</ContractNumber>' +
//depreciated			'			<ContractStatusCode>ContractStatusCode</ContractStatusCode>' +
//depreciated			'			<ContractStartDate>2001-03-01</ContractStartDate>' +
//depreciated			'			<ContractEndDate>2002-03-01</ContractEndDate>' +
//depreciated			'			<CurrencyIsoCode>CurrencyIsoCode</CurrencyIsoCode>' +
//depreciated			'			<ContractAmount>0.0</ContractAmount>' +
//depreciated			'			<OrderSourceId>0</OrderSourceId>' +
//depreciated			'			<OrderSourceName>OrderSourceName</OrderSourceName>' +
//depreciated			'			<SalesRepOnOrder>SalesRepOnOrder</SalesRepOnOrder>' +
//depreciated			'			<OpportunityNumber>OpportunityNumber</OpportunityNumber>' +
//depreciated			'			<PoNumber>PoNumber</PoNumber>' +
//depreciated			'			<OrderTypeId>0</OrderTypeId>' +
//depreciated			'			<OrderTypeName>OrderTypeName</OrderTypeName>' +
//depreciated			'			<CountryOfOrder>CountryOfOrder</CountryOfOrder>' +
//depreciated			'			<SalesChannelCode>SalesChannelCode</SalesChannelCode>' +
//depreciated			'			<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'			<BusinessUnitId>0</BusinessUnitId>' +
//depreciated			'			<BusinessUnitName>BusinessUnitName</BusinessUnitName>' +
//depreciated			'			<Region>Region</Region>' +
//depreciated			'			<AccountRecordType>AccountRecordType</AccountRecordType>' +
//depreciated			'			<AccountRecordTypeId>AccountRecordTypeId</AccountRecordTypeId>' +
//depreciated			'			<OpportunityRecordType>OpportunityRecordType</OpportunityRecordType>' +
//depreciated			'			<OpportunityRecordTypeId>OpportunityRecordTypeId</OpportunityRecordTypeId>' +
//depreciated			'			<SoldToParty>' +
//depreciated			'				<AccountId>0</AccountId>' +
//depreciated			'				<AccountNumber>0</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>Address1</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>City</City>' +
//depreciated			'					<State>State</State>' +
//depreciated			'					<PostalCode>PostalCode</PostalCode>' +
//depreciated			'					<Country>Country</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>Name</Name>' +
//depreciated			'					<FirstName>FirstName</FirstName>' +
//depreciated			'					<LastName>LastName</LastName>' +
//depreciated			'					<Email>Email</Email>' +
//depreciated			'					<Phone>Phone</Phone>' +
//depreciated			'					<SalesforceContactId>SalesforceContactId</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>SalesforceContactRoleId</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>SalesforceAccountId</SalesforceAccountId>' +
//depreciated			'			</SoldToParty>' +
//depreciated			'			<ShipToParty>' +
//depreciated			'				<AccountId>0</AccountId>' +
//depreciated			'				<AccountNumber>0</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'				<LocationId>0</LocationId>' +
//depreciated			'					<Address1>Address1</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>City</City>' +
//depreciated			'					<State>State</State>' +
//depreciated			'					<PostalCode>PostalCode</PostalCode>' +
//depreciated			'					<Country>Country</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>Name</Name>' +
//depreciated			'					<FirstName>FirstName</FirstName>' +
//depreciated			'					<LastName>LastName</LastName>' +
//depreciated			'					<Email>Email</Email>' +
//depreciated			'					<Phone>Phone</Phone>' +
//depreciated			'					<SalesforceContactId>SalesforceContactId</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>SalesforceContactRoleId</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>SalesforceAccountId</SalesforceAccountId>' +
//depreciated			'			</ShipToParty>' +
//depreciated			'			<BillToParty>' +
//depreciated			'				<AccountId>0</AccountId>' +
//depreciated			'				<AccountNumber>0</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>Address1</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>City</City>' +
//depreciated			'					<State>State</State>' +
//depreciated			'					<PostalCode>PostalCode</PostalCode>' +
//depreciated			'					<Country>Country</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>Name</Name>' +
//depreciated			'					<FirstName>FirstName</FirstName>' +
//depreciated			'					<LastName>LastName</LastName>' +
//depreciated			'					<Email>Email</Email>' +
//depreciated			'					<Phone>Phone</Phone>' +
//depreciated			'					<SalesforceContactId>SalesforceContactId</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>SalesforceContactRoleId</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>SalesforceAccountId</SalesforceAccountId>' +
//depreciated			'			</BillToParty>' +
//depreciated			'			<LeadSourceDetail>LeadSourceDetail</LeadSourceDetail>' +
//depreciated			'			<CampaignName>CampaignName</CampaignName>' +
//depreciated			'			<FiscalYear>0</FiscalYear>' +
//depreciated			'			<FiscalQuarter>0</FiscalQuarter>' +
//depreciated			'			<ExpiringProductsAmount>0.0</ExpiringProductsAmount>' +
//depreciated			'			<SalesRepOnAccount>SalesRepOnAccount</SalesRepOnAccount>' +
//depreciated			'			<SalesRepRoleOnAccount>SalesRepRoleOnAccount</SalesRepRoleOnAccount>' +
//depreciated			'			<SalesforceAccountId>SalesforceAccountId</SalesforceAccountId>' +
//depreciated			'			<SalesforceExpiredProductId>SalesforceExpiredProductId</SalesforceExpiredProductId>' +
//depreciated			'			<SalesforceOpportunityId>SalesforceOpportunityId</SalesforceOpportunityId>' +
//depreciated			'			<SalesforceAccountOwnerId>SalesforceAccountOwnerId</SalesforceAccountOwnerId>' +
//depreciated			'			<SalesforceCampaignId>SalesforceCampaignId</SalesforceCampaignId>' +
//depreciated			'			<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'			<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			<Line>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'				<OrderLineId>0</OrderLineId>' +
//depreciated			'				<OrderLineNumber>0</OrderLineNumber>' +
//depreciated			'				<ContractLineId>0</ContractLineId>' +
//depreciated			'				<ContractNumber>0</ContractNumber>' +
//depreciated			'				<ExternalId>0-0</ExternalId>' +
//depreciated			'				<OpportunityNumber>OpportunityNumber</OpportunityNumber>' +
//depreciated			'				<OrderNumber>0</OrderNumber>' +
//depreciated			'				<PoNumber>PoNumber</PoNumber>' +
//depreciated			'				<PricingAttributes>PricingAttributes</PricingAttributes>' +
//depreciated			'				<OrderedItem>OrderedItem</OrderedItem>' +
//depreciated			'				<ProductLine>ProductLine</ProductLine>' +
//depreciated			'				<ConfiguredItem>RH0123456</ConfiguredItem>' +
//depreciated			'				<ConfiguredItemDescription>ConfiguredItemDescription</ConfiguredItemDescription>' +
//depreciated			'				<SubstituteItem>SubstituteItem</SubstituteItem>' +
//depreciated			'				<RenewalItem>RenewalItem</RenewalItem>' +
//depreciated			'				<FulfilledItem>FulfilledItem</FulfilledItem>' +
//depreciated			'				<FulfilledItemDescription>FulfilledItemDescription</FulfilledItemDescription>' +
//depreciated			'				<UnitSellingPrice>0.0</UnitSellingPrice>' +
//depreciated			'				<ServiceStartDate>2001-03-01</ServiceStartDate>' +
//depreciated			'				<ServiceEndDate>2002-03-01</ServiceEndDate>' +
//depreciated			'				<OrderedQuantity>0</OrderedQuantity>' +
//depreciated			'				<TotalPrice>0.0</TotalPrice>' +
//depreciated			'				<CotermFlag>CotermFlag</CotermFlag>' +
//depreciated			'				<NfrFlag>NfrFlag</NfrFlag>' +
//depreciated			'				<RevenueAmount>0.0</RevenueAmount>' +
//depreciated			'				<FiscalYear>0</FiscalYear>' +
//depreciated			'				<FiscalQuarter>0</FiscalQuarter>' +
//depreciated			'				<SalesforceExpiringProductId>SalesforceExpiringProductId</SalesforceExpiringProductId>' +
//depreciated			'				<SalesforceOpportunityId>SalesforceOpportunityId</SalesforceOpportunityId>' +
//depreciated			'				<SalesforceOpportunityLineId>SalesforceOpportunityLineId</SalesforceOpportunityLineId>' +
//depreciated			'				<SalesforcePricebookEntryId>SalesforcePricebookEntryId</SalesforcePricebookEntryId>' +
//depreciated			'				<SalesforceProduct2Id>SalesforceProduct2Id</SalesforceProduct2Id>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</Line>' +
//depreciated			'			<MergedSubscription>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<OrderId>0</OrderId>' +
//depreciated			'				<OrderNumber>OrderNumber</OrderNumber>' +
//depreciated			'				<ContractId>0</ContractId>' +
//depreciated			'				<ContractNumber>ContractNumber</ContractNumber>' +
//depreciated			'				<ContractStartDate>2004-05-01</ContractStartDate>' +
//depreciated			'				<ContractEndDate>2005-05-01</ContractEndDate>' +
//depreciated			'				<ContractAmount>0.0</ContractAmount>' +
//depreciated			'				<ExpiringProductsAmount>0</ExpiringProductsAmount>' +
//depreciated			'				<OpportunityNumber>OpportunityNumber</OpportunityNumber>' +
//depreciated			'				<PoNumber>PoNumber</PoNumber>' +
//depreciated			'				<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'				<ExpiringProductAmount>0.0</ExpiringProductAmount>' +
//depreciated			'			</MergedSubscription>' +
//depreciated			'			<Partner>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>0</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>Address1</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>City</City>' +
//depreciated			'					<State>State</State>' +
//depreciated			'					<PostalCode>PostalCode</PostalCode>' +
//depreciated			'					<Country>Country</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>Name</Name>' +
//depreciated			'					<FirstName>FirstName</FirstName>' +
//depreciated			'					<LastName>LastName</LastName>' +
//depreciated			'					<Email>Email</Email>' +
//depreciated			'					<Phone>Phone</Phone>' +
//depreciated			'					<SalesforceContactId>SalesforceContactId</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>SalesforceContactRoleId</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>SalesforceAccountId</SalesforceAccountId>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<ApId>0</ApId>' +
//depreciated			'				<PartnerType>PartnerType</PartnerType>' +
//depreciated			'				<PoNumber>PoNumber</PoNumber>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</Partner>' +
//depreciated			'			<User>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<UserType>UserType</UserType>' +
//depreciated			'				<UserId>0</UserId>' +
//depreciated			'				<UserName>UserName</UserName>' +
//depreciated			'				<FirstName>FirstName</FirstName>' +
//depreciated			'				<LastName>LastName</LastName>' +
//depreciated			'				<Name>Name</Name>' +
//depreciated			'				<Email>Email</Email>' +
//depreciated			'				<Phone>Phone</Phone>' +
//depreciated			'				<SalesforceContactId>SalesforceContactId</SalesforceContactId>' +
//depreciated			'				<SalesforceContactRoleId>SalesforceContactRoleId</SalesforceContactRoleId>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</User>' +
//depreciated			'		</Subscription>' +
//depreciated			'	</Payload>' +
//depreciated			'</SalesforceMessage>';
//depreciated		}
//depreciated		return MESSAGE;
//depreciated	}}

//depreciated	static Contact createContact(Id accountId) {
//depreciated		Contact regionalContact = new Contact(
//depreciated			AccountId = accountId,
//depreciated			FirstName = 'First',
//depreciated			LastName = 'Last',
//depreciated			Email = 'example@example.org',
//depreciated			Phone = '1-888-555-1212');
//depreciated		insert regionalContact;
//depreciated		regionalContact = [
//depreciated			select
//depreciated				AccountId,
//depreciated				Email,
//depreciated				FirstName,
//depreciated				LastName,
//depreciated				Name,
//depreciated				Phone
//depreciated			from Contact where Id = :regionalContact.Id ];
//depreciated		return regionalContact;
//depreciated	}

//depreciated	static OpportunityLineItem createOpportunityLineItem(Id opportunityId,Integer year) {
//depreciated		OpportunityLineItem regionalLineItem = new OpportunityLineItem(
//depreciated			OpportunityId = opportunityId,
//depreciated			ActualStartDate__c = Date.newInstance(year, 11, 11),
//depreciated			ActualEndDate__c = Date.newInstance(year+1, 11, 10),
//depreciated			ActualTerm__c = 365,
//depreciated			PricebookEntryId = PRICEBOOK_ENTRY.Id,
//depreciated			Quantity = 2,
//depreciated			UnitPrice = 2000.00,
//depreciated			ScheduleLocked__c = true);
//depreciated		insert regionalLineItem;
//depreciated		return regionalLineItem;
//depreciated	}

//depreciated	@isTest
//depreciated	static void testUnmarshal()
//depreciated	{
//depreciated		ORM.unmarshal( MESSAGE, NAMESPACE );
//depreciated		Opportunity_Renewal.Header header = ORM.header;
//depreciated		Opportunity_Renewal.Subscription subscription = ORM.subscription;


//depreciated		//
//depreciated		// validate header
//depreciated		//

//depreciated		system.assertEquals( header.instanceId, 'InstanceId' );
//depreciated		system.assertEquals( header.operation, 'Operation' );
//depreciated		system.assertEquals( header.opportunityType, 'Type' );
//depreciated		system.assertEquals( header.timestamp, '2011-02-10' );


//depreciated		//
//depreciated		// validate subscription
//depreciated		//

//depreciated		system.assertEquals( subscription.accountRecordType, 'AccountRecordType' );
//depreciated		system.assertEquals( subscription.accountRecordTypeId, 'AccountRecordTypeId' );
//depreciated		system.assertEquals( subscription.businessUnitId, 0 );
//depreciated		system.assertEquals( subscription.businessUnitName, 'BusinessUnitName' );
//depreciated		system.assertEquals( subscription.campaignName, 'CampaignName' );
//depreciated		system.assertEquals( subscription.contractAmount, 0 );
//depreciated		system.assertEquals( subscription.contractEndDate, Date.newInstance( 2002, 03, 01 ));
//depreciated		system.assertEquals( subscription.contractId, 0 );
//depreciated		system.assertEquals( subscription.contractNumber, 'ContractNumber' );
//depreciated		system.assertEquals( subscription.contractStartDate, Date.newInstance( 2001, 03, 01 ));
//depreciated		system.assertEquals( subscription.contractStatusCode, 'ContractStatusCode' );
//depreciated		system.assertEquals( subscription.countryOfOrder, 'CountryOfOrder' );
//depreciated		system.assertEquals( subscription.currencyIsoCode, 'CurrencyIsoCode' );
//depreciated		system.assertEquals( subscription.errorMessage, '' );
//depreciated		//system.assertEquals( subscription.expiringProductsAmount, 0 );
//depreciated		system.assertEquals( subscription.fiscalQuarter, 0 );
//depreciated		system.assertEquals( subscription.fiscalYear, 0 );
//depreciated		system.assertEquals( subscription.leadSourceDetail, 'LeadSourceDetail' );
//depreciated		system.assertEquals( subscription.mergeToSubscriptionId, 0 );
//depreciated		system.assertEquals( subscription.opportunityNumber, 'OpportunityNumber' );
//depreciated		system.assertEquals( subscription.opportunityRecordType, 'OpportunityRecordType' );
//depreciated		system.assertEquals( subscription.opportunityRecordTypeId, 'OpportunityRecordTypeId' );
//depreciated		system.assertEquals( subscription.orderId, 0 );
//depreciated		system.assertEquals( subscription.orderNumber, 'OrderNumber' );
//depreciated		system.assertEquals( subscription.orderSourceId, 0 );
//depreciated		system.assertEquals( subscription.orderSourceName, 'OrderSourceName' );
//depreciated		system.assertEquals( subscription.orderTypeId, 0 );
//depreciated		system.assertEquals( subscription.orderTypeName, 'OrderTypeName' );
//depreciated		system.assertEquals( subscription.poNumber, 'PoNumber' );
//depreciated		system.assertEquals( subscription.recordStatus, 'RecordStatus' );
//depreciated		system.assertEquals( subscription.region, 'Region' );
//depreciated		system.assertEquals( subscription.salesChannelCode, 'SalesChannelCode' );
//depreciated		system.assertEquals( subscription.salesforceAccountId, 'SalesforceAccountId' );
//depreciated		system.assertEquals( subscription.salesforceAccountOwnerId, 'SalesforceAccountOwnerId' );
//depreciated		system.assertEquals( subscription.salesforceCampaignId, 'SalesforceCampaignId' );
//depreciated		system.assertEquals( subscription.salesforceOpportunityId, 'SalesforceOpportunityId' );
//depreciated		system.assertEquals( subscription.salesrepOnAccount, 'SalesRepOnAccount' );
//depreciated		system.assertEquals( subscription.salesrepOnOrder, 'SalesRepOnOrder' );
//depreciated		system.assertEquals( subscription.salesrepRoleOnAccount, 'SalesRepRoleOnAccount' );


//depreciated		//
//depreciated		// validate sold to party
//depreciated		//

//depreciated		Opportunity_Renewal.SubscriptionParty soldTo = subscription.soldToParty;
//depreciated		system.assertEquals( soldTo.accountId, 0 );
//depreciated		system.assertEquals( soldTo.accountNumber, '0' );
//depreciated		system.assertEquals( soldTo.partyId, 0 );
//depreciated		system.assertEquals( soldTo.partyName, 'PartyName' );
//depreciated		system.assertEquals( soldTo.partyNumber, '0' );

//depreciated		Opportunity_Renewal.SubscriptionAddress address = soldTo.address;
//depreciated		system.assertEquals( address.address1, 'Address1' );
//depreciated		system.assertEquals( address.address2, 'Address2' );
//depreciated		system.assertEquals( address.city, 'City' );
//depreciated		system.assertEquals( address.country, 'Country' );
//depreciated		system.assertEquals( address.locationId, 0 );
//depreciated		system.assertEquals( address.postalCode, 'PostalCode' );
//depreciated		system.assertEquals( address.state, 'State' );

//depreciated		Opportunity_Renewal.SubscriptionContact contact = soldTo.contact;
//depreciated		system.assertEquals( contact.contactId, 0 );
//depreciated		system.assertEquals( contact.email, 'Email' );
//depreciated		system.assertEquals( contact.firstName, 'FirstName' );
//depreciated		system.assertEquals( contact.lastName, 'LastName' );
//depreciated		system.assertEquals( contact.name, 'Name' );
//depreciated		system.assertEquals( contact.phone, 'Phone' );
//depreciated		system.assertEquals( contact.salesforceContactId, 'SalesforceContactId' );
//depreciated		system.assertEquals( contact.salesforceContactRoleId, 'SalesforceContactRoleId' );


//depreciated		//
//depreciated		// validate ship to party
//depreciated		//

//depreciated		Opportunity_Renewal.SubscriptionParty shipTo = subscription.shipToParty;
//depreciated		system.assertEquals( shipTo.accountId, 0 );
//depreciated		system.assertEquals( shipTo.accountNumber, '0' );
//depreciated		system.assertEquals( shipTo.partyId, 0 );
//depreciated		system.assertEquals( shipTo.partyName, 'PartyName' );
//depreciated		system.assertEquals( shipTo.partyNumber, '0' );

//depreciated		address = shipTo.address;
//depreciated		system.assertEquals( address.address1, 'Address1' );
//depreciated		system.assertEquals( address.address2, 'Address2' );
//depreciated		system.assertEquals( address.city, 'City' );
//depreciated		system.assertEquals( address.country, 'Country' );
//depreciated		system.assertEquals( address.locationId, 0 );
//depreciated		system.assertEquals( address.postalCode, 'PostalCode' );
//depreciated		system.assertEquals( address.state, 'State' );

//depreciated		contact = shipTo.contact;
//depreciated		system.assertEquals( contact.contactId, 0 );
//depreciated		system.assertEquals( contact.email, 'Email' );
//depreciated		system.assertEquals( contact.firstName, 'FirstName' );
//depreciated		system.assertEquals( contact.lastName, 'LastName' );
//depreciated		system.assertEquals( contact.name, 'Name' );
//depreciated		system.assertEquals( contact.phone, 'Phone' );
//depreciated		system.assertEquals( contact.salesforceContactId, 'SalesforceContactId' );
//depreciated		system.assertEquals( contact.salesforceContactRoleId, 'SalesforceContactRoleId' );


//depreciated		//
//depreciated		// validate bill to party
//depreciated		//

//depreciated		Opportunity_Renewal.SubscriptionParty billTo = subscription.billToParty;
//depreciated		system.assertEquals( billTo.accountId, 0 );
//depreciated		system.assertEquals( billTo.accountNumber, '0' );
//depreciated		system.assertEquals( billTo.partyId, 0 );
//depreciated		system.assertEquals( billTo.partyName, 'PartyName' );
//depreciated		system.assertEquals( billTo.partyNumber, '0' );

//depreciated		address = billTo.address;
//depreciated		system.assertEquals( address.address1, 'Address1' );
//depreciated		system.assertEquals( address.address2, 'Address2' );
//depreciated		system.assertEquals( address.city, 'City' );
//depreciated		system.assertEquals( address.country, 'Country' );
//depreciated		system.assertEquals( address.locationId, 0 );
//depreciated		system.assertEquals( address.postalCode, 'PostalCode' );
//depreciated		system.assertEquals( address.state, 'State' );

//depreciated		contact = billTo.contact;
//depreciated		system.assertEquals( contact.contactId, 0 );
//depreciated		system.assertEquals( contact.email, 'Email' );
//depreciated		system.assertEquals( contact.firstName, 'FirstName' );
//depreciated		system.assertEquals( contact.lastName, 'LastName' );
//depreciated		system.assertEquals( contact.name, 'Name' );
//depreciated		system.assertEquals( contact.phone, 'Phone' );
//depreciated		system.assertEquals( contact.salesforceContactId, 'SalesforceContactId' );
//depreciated		system.assertEquals( contact.salesforceContactRoleId, 'SalesforceContactRoleId' );


//depreciated		//
//depreciated		// validate line item
//depreciated		//

//depreciated		Opportunity_Renewal.SubscriptionLine line = subscription.lineList[0];
//depreciated		system.assertEquals( line.configuredItem, 'RH0123456' );
//depreciated		system.assertEquals( line.configuredItemDescription, 'ConfiguredItemDescription' );
//depreciated		system.assertEquals( line.contractLineId, 0 );
//depreciated		system.assertEquals( line.contractNumber, '0' );
//depreciated		system.assertEquals( line.cotermFlag, 'CotermFlag' );
//depreciated		system.assertEquals( line.errorMessage, '' );
//depreciated		system.assertEquals( line.fiscalQuarter, 0 );
//depreciated		system.assertEquals( line.fiscalYear, 0 );
//depreciated		system.assertEquals( line.fulfilledItem, 'FulfilledItem' );
//depreciated		system.assertEquals( line.fulfilledItemDescription, 'FulfilledItemDescription' );
//depreciated		system.assertEquals( line.Id, 0 );
//depreciated		system.assertEquals( line.mergeToSubscriptionId, 0 );
//depreciated		system.assertEquals( line.nfrFlag, 'NfrFlag' );
//depreciated		system.assertEquals( line.opportunityNumber , 'OpportunityNumber' );
//depreciated		system.assertEquals( line.orderedItem, 'OrderedItem' );
//depreciated		system.assertEquals( line.orderedQuantity, 0 );
//depreciated		system.assertEquals( line.orderLineId, 0 );
//depreciated		system.assertEquals( line.orderLineNumber, '0' );
//depreciated		system.assertEquals( line.orderNumber, '0' );
//depreciated		system.assertEquals( line.poNumber, 'PoNumber' );
//depreciated		system.assertEquals( line.pricingAttributes, 'PricingAttributes' );
//depreciated		system.assertEquals( line.productLine, 'ProductLine' );
//depreciated		system.assertEquals( line.renewalItem, 'RenewalItem' );
//depreciated		system.assertEquals( line.revenueAmount, 0 );
//depreciated		system.assertEquals( line.salesforceExpiringProductId, 'SalesforceExpiringProductId' );
//depreciated		system.assertEquals( line.salesforceOpportunityId, 'SalesforceOpportunityId' );
//depreciated		system.assertEquals( line.salesforceOpportunityLineId, 'SalesforceOpportunityLineId' );
//depreciated		system.assertEquals( line.salesforcePricebookEntryId, 'SalesforcePricebookEntryId' );
//depreciated		system.assertEquals( line.salesforceProduct2Id, 'SalesforceProduct2Id' );
//depreciated		system.assertEquals( line.serviceEndDate, Date.newInstance( 2002, 03, 01 ) );
//depreciated		system.assertEquals( line.serviceStartDate, Date.newInstance( 2001, 03, 01 ) );
//depreciated		system.assertEquals( line.subscriptionId, 0 );
//depreciated		system.assertEquals( line.substituteItem, 'SubstituteItem' );
//depreciated		system.assertEquals( line.totalPrice, 0 );
//depreciated		system.assertEquals( line.unitSellingPrice, 0 );


//depreciated		//
//depreciated		// validate merged subscription
//depreciated		//

//depreciated		Opportunity_Renewal.MergedSubscription mergedSubscription = subscription.mergedSubscriptionList[0];
//depreciated		system.assertEquals ( mergedSubscription.contractAmount, 0 );
//depreciated		system.assertEquals ( mergedSubscription.contractEndDate, Date.newInstance( 2005, 05, 01 ));
//depreciated		system.assertEquals ( mergedSubscription.contractId, 0 );
//depreciated		system.assertEquals ( mergedSubscription.contractNumber, 'ContractNumber' );
//depreciated		system.assertEquals ( mergedSubscription.contractStartDate, Date.newInstance( 2004, 05, 01 ));
//depreciated		//system.assertEquals ( mergedSubscription.expiringProductsAmount, 0 );
//depreciated		system.assertEquals ( mergedSubscription.id, 0 );
//depreciated		system.assertEquals ( mergedSubscription.mergeToSubscriptionId, 0 );
//depreciated		system.assertEquals ( mergedSubscription.opportunityNumber, 'OpportunityNumber' );
//depreciated		system.assertEquals ( mergedSubscription.orderId, 0 );
//depreciated		system.assertEquals ( mergedSubscription.orderNumber, 'OrderNumber' );
//depreciated		system.assertEquals ( mergedSubscription.poNumber, 'PoNumber' );


//depreciated		//
//depreciated		// validate partner
//depreciated		//

//depreciated		Opportunity_Renewal.SubscriptionPartner partner = subscription.partnerList[0];
//depreciated		system.assertEquals ( partner.accountId, 0 );
//depreciated		system.assertEquals ( partner.accountNumber, '0' );
//depreciated		system.assertEquals ( partner.apId, 0 );
//depreciated		system.assertEquals ( partner.id, 0 );
//depreciated		system.assertEquals ( partner.partyId, 0 );
//depreciated		system.assertEquals ( partner.partyName, 'PartyName' );
//depreciated		system.assertEquals ( partner.partyNumber, '0' );
//depreciated		system.assertEquals ( partner.partnerType, 'PartnerType' );
//depreciated		system.assertEquals ( partner.poNumber, 'PoNumber' );
//depreciated		system.assertEquals ( partner.recordStatus, 'RecordStatus' );
//depreciated		system.assertEquals ( partner.subscriptionId, 0 );

//depreciated		address = partner.address;
//depreciated		system.assertEquals( address.address1, 'Address1' );
//depreciated		system.assertEquals( address.address2, 'Address2' );
//depreciated		system.assertEquals( address.city, 'City' );
//depreciated		system.assertEquals( address.country, 'Country' );
//depreciated		system.assertEquals( address.locationId, 0 );
//depreciated		system.assertEquals( address.postalCode, 'PostalCode' );
//depreciated		system.assertEquals( address.state, 'State' );

//depreciated		contact = partner.contact;
//depreciated		system.assertEquals( contact.contactId, 0 );
//depreciated		system.assertEquals( contact.email, 'Email' );
//depreciated		system.assertEquals( contact.firstName, 'FirstName' );
//depreciated		system.assertEquals( contact.lastName, 'LastName' );
//depreciated		system.assertEquals( contact.name, 'Name' );
//depreciated		system.assertEquals( contact.phone, 'Phone' );
//depreciated		system.assertEquals( contact.salesforceContactId, 'SalesforceContactId' );
//depreciated		system.assertEquals( contact.salesforceContactRoleId, 'SalesforceContactRoleId' );


//depreciated		//
//depreciated		// validate user
//depreciated		//

//depreciated		Opportunity_Renewal.SubscriptionUser renewalUser = subscription.userList[0];
//depreciated		system.assertEquals( renewalUser.email, 'Email' );
//depreciated		system.assertEquals( renewalUser.firstName, 'FirstName' );
//depreciated		system.assertEquals( renewalUser.id, 0 );
//depreciated		system.assertEquals( renewalUser.lastName, 'LastName' );
//depreciated		system.assertEquals( renewalUser.name, 'Name' );
//depreciated		system.assertEquals( renewalUser.phone, 'Phone' );
//depreciated		system.assertEquals( renewalUser.recordStatus, 'RecordStatus' );
//depreciated		system.assertEquals( renewalUser.salesforceContactId, 'SalesforceContactId' );
//depreciated		system.assertEquals( renewalUser.salesforceContactRoleId, 'SalesforceContactRoleId' );
//depreciated		system.assertEquals( renewalUser.subscriptionId, 0 );
//depreciated		system.assertEquals( renewalUser.userId, 0 );
//depreciated		system.assertEquals( renewalUser.userName, 'UserName' );
//depreciated		system.assertEquals( renewalUser.userType, 'UserType' );
//depreciated	}

//depreciated	@isTest
//depreciated	static void testMarshal()
//depreciated	{
//depreciated		ORM.unmarshal( MESSAGE, NAMESPACE );
//depreciated		String xmlResponse = ORM.marshal();

//depreciated		DOM.Document doc = new DOM.Document();
//depreciated		doc.load(xmlResponse);
//depreciated		DOM.XMLNode salesforceMsg = doc.getRootElement();
//depreciated		DOM.XMLNode header = salesforceMsg.getChildElement( 'Header', null );
//depreciated		DOM.XMLNode payload = salesforceMsg.getChildElement( 'Payload', null );
//depreciated		DOM.XMLNode subscription = payload.getChildElement( 'Subscription', null );
//depreciated		DOM.XMLNode line = subscription.getChildElement( 'Line', null );
//depreciated		DOM.XMLNode partner = subscription.getChildElement( 'Partner', null );
//depreciated		DOM.XMLNode contact = partner.getChildElement( 'Contact', null );
//depreciated		DOM.XMLNode userNode = subscription.getChildElement( 'User', null );

//depreciated		//
//depreciated		// subscription node
//depreciated		//

//depreciated		DOM.XMLNode subscriptionId = subscription.getChildElement( 'Id', null );
//depreciated		DOM.XMLNode salesRepOnAccount = subscription.getChildElement( 'SalesRepOnAccount', null );
//depreciated		DOM.XMLNode salesRepRoleOnAccount = subscription.getChildElement( 'SalesRepRoleOnAccount', null );
//depreciated		DOM.XMLNode salesforceAccountId = subscription.getChildElement( 'SalesforceAccountId', null );
//depreciated		DOM.XMLNode salesforceOpportunityId = subscription.getChildElement( 'SalesforceOpportunityId', null );
//depreciated		DOM.XMLNode salesforceAccountOwnerId = subscription.getChildElement( 'SalesforceAccountOwnerId', null );

//depreciated		//
//depreciated		// line node
//depreciated		//

//depreciated		DOM.XMLNode lineId = line.getChildElement( 'Id', null );
//depreciated		DOM.XMLNode salesforceExpiringProductId = line.getChildElement( 'SalesforceExpiringProductId', null );
//depreciated		DOM.XMLNode salesforceOpportunityLineId = line.getChildElement( 'SalesforceOpportunityLineId', null );
//depreciated		DOM.XMLNode salesforcePricebookEntryId = line.getChildElement( 'SalesforcePricebookEntryId', null );
//depreciated		DOM.XMLNode SalesforceProduct2Id = line.getChildElement( 'SalesforceProduct2Id', null );

//depreciated		//
//depreciated		// partner node
//depreciated		//

//depreciated		DOM.XMLNode partnerId = partner.getChildElement( 'Id', null );
//depreciated		DOM.XMLNode partnerSalesforceAccountId = partner.getChildElement( 'SalesforceAccountId', null );
//depreciated		DOM.XMLNode salesforceContactId = contact.getChildElement( 'SalesforceContactId', null );
//depreciated		DOM.XMLNode salesforceContactRoleId = contact.getChildElement( 'SalesforceContactRoleId', null );

//depreciated		//
//depreciated		// user node
//depreciated		//

//depreciated		DOM.XMLNode userId = userNode.getChildElement( 'Id', null );
//depreciated		DOM.XMLNode userSalesforceContactId = userNode.getChildElement( 'SalesforceContactId', null );
//depreciated		DOM.XMLNode userSalesforceContactRoleId = userNode.getChildElement( 'SalesforceContactRoleId', null );

//depreciated		//
//depreciated		// assertions
//depreciated		//

//depreciated		system.assertEquals( subscriptionId.getText(), '0' );
//depreciated		system.assertEquals( salesRepOnAccount.getText(), 'SalesRepOnAccount' );
//depreciated		system.assertEquals( salesRepRoleOnAccount.getText(), 'SalesRepRoleOnAccount' );
//depreciated		system.assertEquals( salesforceOpportunityId.getText(), 'SalesforceOpportunityId' );
//depreciated		system.assertEquals( salesforceAccountOwnerId.getText(), 'SalesforceAccountOwnerId' );

//depreciated		system.assertEquals( lineId.getText(), '0');
//depreciated		system.assertEquals( salesforceExpiringProductId.getText(), 'SalesforceExpiringProductId' );
//depreciated		system.assertEquals( salesforceOpportunityLineId.getText(), 'SalesforceOpportunityLineId' );
//depreciated		system.assertEquals( salesforcePricebookEntryId.getText(), 'SalesforcePricebookEntryId' );
//depreciated		system.assertEquals( SalesforceProduct2Id.getText(), 'SalesforceProduct2Id' );

//depreciated		system.assertEquals( partnerId.getText(), '0' );
//depreciated		system.assertEquals( partnerSalesforceAccountId.getText(), 'SalesforceAccountId' );
//depreciated		system.assertEquals( salesforceContactId.getText(), 'SalesforceContactId' );
//depreciated		system.assertEquals( salesforceContactRoleId.getText(), 'SalesforceContactRoleId' );

//depreciated		system.assertEquals( userId.getText(), '0' );
//depreciated		system.assertEquals( userSalesforceContactId.getText(), 'SalesforceContactId' );
//depreciated		system.assertEquals( userSalesforceContactRoleId.getText(), 'SalesforceContactRoleId' );
//depreciated	}

//depreciated	static Opportunity queryOpportunity(Id sourceOpportunityId) {
//depreciated		return [
//depreciated			select
//depreciated				AccountId,
//depreciated				Amount,
//depreciated				BillingAccountNumber__c,
//depreciated				BillingAddress__c,
//depreciated				BillingCity__c,
//depreciated				BillingState__c,
//depreciated				BillingCountry__c,
//depreciated				BillingZipPostalCode__c,
//depreciated				CampaignId,
//depreciated				CloseDate,
//depreciated				ContractNumber__c,
//depreciated				ContractStartDate__c,
//depreciated				ContractEndDate__c,
//depreciated				Country_of_Order__c,
//depreciated				CrossRegionalCreditCheck__c,
//depreciated				CurrencyIsoCode,
//depreciated				Description,
//depreciated				Expiring_Products_Total_Amount_RollUp__c,
//depreciated				FulfillmentChannel__c,
//depreciated				LeadSourceDetail__c,
//depreciated				NA_Reseller__c,
//depreciated				Name,
//depreciated				OpportunityType__c,
//depreciated				OwnerId,
//depreciated				Pay_Now__c,
//depreciated				PaymentType__c,
//depreciated				PONumber__c,
//depreciated				Primary_Partner__c,
//depreciated				RecordTypeId,
//depreciated				Renewal_Opportunity__c,
//depreciated				Renewable__c,
//depreciated				Reseller__c,
//depreciated				Reseller_PO__c,
//depreciated				ShippingAddress__c,
//depreciated				ShippingCity__c,
//depreciated				ShippingState__c,
//depreciated				ShippingCountry__c,
//depreciated				ShippingZipPostalCode__c,
//depreciated				Source_Opportunity__c,
//depreciated				StageName,
//depreciated				Touched__c, 
//depreciated				Year1PaymentAmount__c,
//depreciated				(	select
//depreciated						Expiring_Product_End_Date__c,
//depreciated						Expiring_Contract_Number__c,
//depreciated						Expiring_Contract_PO_Number__c,
//depreciated						Expiring_Product_Start_Date__c,
//depreciated						Expiring_Oracle_Order_Number__c,
//depreciated						CurrencyIsoCode,
//depreciated						Co_Term__c,
//depreciated						Already_Renewed__c,
//depreciated						Opportunity__c,
//depreciated						Product_Code__c,
//depreciated						Quantity__c,
//depreciated						Sales_Price__c,
//depreciated						Total_Price_Formula__c,
//depreciated						Name,
//depreciated						Mapped_Description__c,
//depreciated						Product__c
//depreciated					from Expiring_Products__r
//depreciated					order by Product_Code__c, Name, CreatedDate),
//depreciated				(	select
//depreciated						ContactId,
//depreciated						Contact.Email,
//depreciated						Role
//depreciated					From OpportunityContactRoles
//depreciated					order by Role, Contact.Email, CreatedDate),
//depreciated				(	select
//depreciated						ActualEndDate__c,
//depreciated						ActualStartDate__c,
//depreciated						PricebookEntryId,
//depreciated						NewOrRenewal__c,
//depreciated						Quantity,
//depreciated						ScheduleLocked__c,
//depreciated						Contract_Numbers__c,
//depreciated						Configured_SKU__c,
//depreciated						UnitPrice,
//depreciated						Description
//depreciated					from OpportunityLineItems
//depreciated					order by Configured_SKU__c, CreatedDate),
//depreciated				(	select
//depreciated						Partner__c,
//depreciated						PartnerType__c,
//depreciated						PartnerTier__c,
//depreciated						RelationshipType__c
//depreciated					from OpportunityPartners2__r
//depreciated					order by RelationshipType__c, CreatedDate)
//depreciated			from Opportunity 
//depreciated			where Source_Opportunity__c = :sourceOpportunityId ];
//depreciated	}

//depreciated	static List<CampaignMember> queryCampaignMembers(Id sourceOpportunityId) {
//depreciated		return [
//depreciated			select 
//depreciated				CampaignId,
//depreciated				Campaign.Name,
//depreciated				ContactId,
//depreciated				Contact.Email
//depreciated			from CampaignMember
//depreciated			where CampaignId in (
//depreciated				select CampaignId from Opportunity
//depreciated				where Source_Opportunity__c = :sourceOpportunityId )
//depreciated			order by Contact.Email, Campaign.Name, CreatedDate ];
//depreciated	}

//depreciated	static Map<Id,String> getIdMap(Opportunity opp,List<CampaignMember> campaignMembers) {
//depreciated		Map<Id,String> idMap = new Map<Id,String>();
//depreciated		idMap.put(opp.Id,'{!Opportunity.Id}');
//depreciated		System.debug('AccountId='+opp.AccountId);
//depreciated		idMap.put(opp.AccountId,'{!Opportunity.AccountId}');
//depreciated		System.debug('Amount='+opp.Amount);
//depreciated		System.debug('BillingAccountNumber__c='+opp.BillingAccountNumber__c);
//depreciated		System.debug('BillingAddress__c='+opp.BillingAddress__c);
//depreciated		System.debug('BillingCity__c='+opp.BillingCity__c);
//depreciated		System.debug('BillingState__c='+opp.BillingState__c);
//depreciated		System.debug('BillingCountry__c='+opp.BillingCountry__c);
//depreciated		System.debug('BillingZipPostalCode__c='+opp.BillingZipPostalCode__c);
//depreciated		System.debug('CampaignId='+opp.CampaignId);
//depreciated		System.debug('CloseDate='+opp.CloseDate);
//depreciated		System.debug('ContractNumber__c='+opp.ContractNumber__c);
//depreciated		System.debug('ContractStartDate__c='+opp.ContractStartDate__c);
//depreciated		System.debug('ContractEndDate__c='+opp.ContractEndDate__c);
//depreciated		System.debug('Country_of_Order__c='+opp.Country_of_Order__c);
//depreciated		System.debug('CrossRegionalCreditCheck__c='+opp.CrossRegionalCreditCheck__c);
//depreciated		System.debug('CurrencyIsoCode='+opp.CurrencyIsoCode);
//depreciated		System.debug('Description='+opp.Description);
//depreciated		System.debug('Expiring_Products_Total_Amount_RollUp__c='+opp.Expiring_Products_Total_Amount_RollUp__c);
//depreciated		System.debug('FulfillmentChannel__c='+opp.FulfillmentChannel__c);
//depreciated		System.debug('LeadSourceDetail__c='+opp.LeadSourceDetail__c);
//depreciated		System.debug('NA_Reseller__c='+opp.NA_Reseller__c);
//depreciated		System.debug('Name='+opp.Name);
//depreciated		System.debug('OpportunityType__c='+opp.OpportunityType__c);
//depreciated		System.debug('OwnerId='+opp.OwnerId);
//depreciated		idMap.put(opp.OwnerId,'{!Opportunity.OwnerId}');
//depreciated		System.debug('Pay_Now__c='+opp.Pay_Now__c);
//depreciated		System.debug('PaymentType__c='+opp.PaymentType__c);
//depreciated		System.debug('PONumber__c='+opp.PONumber__c);
//depreciated		System.debug('Primary_Partner__c='+opp.Primary_Partner__c);
//depreciated		System.debug('RecordTypeId='+opp.RecordTypeId);
//depreciated		idMap.put(opp.RecordTypeId,'{!Opportunity.RecordTypeId}');
//depreciated		System.debug('Renewal_Opportunity__c='+opp.Renewal_Opportunity__c);
//depreciated		System.debug('Renewable__c='+opp.Renewable__c);
//depreciated		System.debug('Reseller__c='+opp.Reseller__c);
//depreciated		System.debug('Reseller_PO__c='+opp.Reseller_PO__c);
//depreciated		System.debug('ShippingAddress__c='+opp.ShippingAddress__c);
//depreciated		System.debug('ShippingCity__c='+opp.ShippingCity__c);
//depreciated		System.debug('ShippingState__c='+opp.ShippingState__c);
//depreciated		System.debug('ShippingCountry__c='+opp.ShippingCountry__c);
//depreciated		System.debug('ShippingZipPostalCode__c='+opp.ShippingZipPostalCode__c);
//depreciated		System.debug('StageName='+opp.StageName);
//depreciated		System.debug('Touched__c='+opp.Touched__c);
//depreciated		System.debug('Year1PaymentAmount__c='+opp.Year1PaymentAmount__c);
//depreciated		for(Integer i=0;i<opp.Expiring_Products__r.size();i++) {
//depreciated			Expiring_Product__c expiringProduct = opp.Expiring_Products__r[i];
//depreciated			String name = 'Opportunity.Expiring_Products__r['+i+']';
//depreciated			idMap.put(expiringProduct.Id,'{!'+name+'.Id}');
//depreciated			System.debug(name+'.Expiring_Product_End_Date__c='+expiringProduct.Expiring_Product_End_Date__c);
//depreciated			System.debug(name+'.Expiring_Contract_Number__c='+expiringProduct.Expiring_Contract_Number__c);
//depreciated			System.debug(name+'.Expiring_Contract_PO_Number__c='+expiringProduct.Expiring_Contract_PO_Number__c);
//depreciated			System.debug(name+'.Expiring_Product_Start_Date__c='+expiringProduct.Expiring_Product_Start_Date__c);
//depreciated			System.debug(name+'.Expiring_Oracle_Order_Number__c='+expiringProduct.Expiring_Oracle_Order_Number__c);
//depreciated			System.debug(name+'.CurrencyIsoCode='+expiringProduct.CurrencyIsoCode);
//depreciated			System.debug(name+'.Co_Term__c='+expiringProduct.Co_Term__c);
//depreciated			System.debug(name+'.Already_Renewed__c='+expiringProduct.Already_Renewed__c);
//depreciated			System.debug(name+'.Opportunity__c='+expiringProduct.Opportunity__c);
//depreciated			System.debug(name+'.Product_Code__c='+expiringProduct.Product_Code__c);
//depreciated			System.debug(name+'.Quantity__c='+expiringProduct.Quantity__c);
//depreciated			System.debug(name+'.Sales_Price__c='+expiringProduct.Sales_Price__c);
//depreciated			System.debug(name+'.Total_Price_Formula__c='+expiringProduct.Total_Price_Formula__c);
//depreciated			System.debug(name+'.Name='+expiringProduct.Name);
//depreciated			System.debug(name+'.Mapped_Description__c='+expiringProduct.Mapped_Description__c);
//depreciated			System.debug(name+'.Product__c='+expiringProduct.Product__c);
//depreciated		}
//depreciated		for(Integer i=0;i<opp.OpportunityContactRoles.size();i++) {
//depreciated			OpportunityContactRole contactRole = opp.OpportunityContactRoles[i];
//depreciated			String name = 'OpportunityContactRoles['+i+']';
//depreciated			idMap.put(contactRole.Id,'{!'+name+'.Id}');
//depreciated			System.debug(name+'.ContactId='+contactRole.ContactId);
//depreciated			idMap.put(contactRole.ContactId,'{!'+name+'.ContactId}');
//depreciated			System.debug(name+'.Contact.Email='+contactRole.Contact.Email);
//depreciated			System.debug(name+'.Role='+contactRole.Role);
//depreciated		}
//depreciated		for(Integer i=0;i<opp.OpportunityLineItems.size();i++) {
//depreciated			OpportunityLineItem lineItem = opp.OpportunityLineItems[i];
//depreciated			String name = 'OpportunityLineItems['+i+']';
//depreciated			idMap.put(lineItem.Id,'{!'+name+'.Id}');
//depreciated			System.debug(name+'.ActualEndDate__c='+lineItem.ActualEndDate__c);
//depreciated			System.debug(name+'.ActualStartDate__c='+lineItem.ActualStartDate__c);
//depreciated			idMap.put(lineItem.PricebookEntryId,'{!'+name+'.PricebookEntryId}');
//depreciated			System.debug(name+'.PricebookEntryId='+lineItem.PricebookEntryId);
//depreciated			System.debug(name+'.NewOrRenewal__c='+lineItem.NewOrRenewal__c);
//depreciated			System.debug(name+'.Quantity='+lineItem.Quantity);
//depreciated			System.debug(name+'.ScheduleLocked__c='+lineItem.ScheduleLocked__c);
//depreciated			System.debug(name+'.Contract_Numbers__c='+lineItem.Contract_Numbers__c);
//depreciated			System.debug(name+'.Configured_SKU__c='+lineItem.Configured_SKU__c);
//depreciated			System.debug(name+'.UnitPrice='+lineItem.UnitPrice);
//depreciated			System.debug(name+'.Description='+lineItem.Description);
//depreciated		}
//depreciated		for(Integer i=0;i<opp.OpportunityPartners2__r.size();i++) {
//depreciated			OpportunityPartner__c opportunityPartner=opp.OpportunityPartners2__r[i];
//depreciated			String name = 'OpportunityPartners2__r['+i+']';
//depreciated			idMap.put(opportunityPartner.Id,'{!'+name+'.Id}');
//depreciated			System.debug(name+'.Partner__c='+opportunityPartner.Partner__c);
//depreciated			System.debug(name+'.PartnerType__c='+opportunityPartner.PartnerType__c);
//depreciated			System.debug(name+'.PartnerTier__c='+opportunityPartner.PartnerTier__c);
//depreciated			System.debug(name+'.RelationshipType__c='+opportunityPartner.RelationshipType__c);
//depreciated		}
//depreciated		for(Integer i=0;i<campaignMembers.size();i++) {
//depreciated			CampaignMember campaignMember = campaignMembers[i];
//depreciated			String name = 'campaignMembers['+i+']';
//depreciated			idMap.put(campaignMember.Id,'{!'+name+'.Id}');
//depreciated			System.debug(name+'.CampaignId='+campaignMember.CampaignId);
//depreciated			if(!idMap.containsKey(campaignMember.CampaignId)) {
//depreciated				idMap.put(campaignMember.CampaignId,'{!'+name+'.CampaignId}');
//depreciated			}
//depreciated			System.debug(name+'.Campaign.Name='+campaignMember.Campaign.Name);
//depreciated			System.debug(name+'.ContactId='+campaignMember.ContactId);
//depreciated			if(!idMap.containsKey(campaignMember.ContactId)) {
//depreciated				idMap.put(campaignMember.ContactId,'{!'+name+'.ContactId}');
//depreciated			}
//depreciated			System.debug(name+'.Contact.Email='+campaignMember.Contact.Email);
//depreciated		}
//depreciated		idMap.put(CAMPAIGN.Id,'{!Campaign.Id}');
//depreciated		idMap.put(PRODUCT.Id,'{!Product.Id}');
//depreciated		idMap.put(GLOBAL_PRICEBOOK.Id,'{!Pricebook2.Id}');
//depreciated		idMap.put(PRICEBOOK_ENTRY.Id,'{!PricebookEntry.Id}');
//depreciated		idMap.put(USER.Id,'{!User.Id}');
//depreciated		return idMap;
//depreciated	}

//depreciated	static String cleanResponseXML(String responseXML,Map<Id,String> idMap) {
//depreciated		System.debug(responseXML);
//depreciated		for(String key : idMap.keySet()) {
//depreciated			String value = idMap.get(key);
//depreciated			System.debug(key+'=>'+value);
//depreciated			responseXML = responseXML.replace(key,value);
//depreciated		}
//depreciated		return responseXML
//depreciated			.replace((''+Date.today()).substring(0,10),'{!today}')
//depreciated			.replaceAll('>([0a][01][0-9A-Za-z])[0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Z][0-9A-Z][0-9A-Z]<','>$1...............<')
//depreciated			.replaceAll('T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]','T..:..:..')
//depreciated			.replaceAll('<SalesRepOnAccount>[^<]+</SalesRepOnAccount>','<SalesRepOnAccount>...</SalesRepOnAccount>')
//depreciated			.replaceAll('<SalesRepRoleOnAccount>[^<]+</SalesRepRoleOnAccount>','<SalesRepRoleOnAccount>...</SalesRepRoleOnAccount>');
//depreciated	}

//depreciated	@isTest
//depreciated	static void testCreateRenewalOpportunityAPAC()
//depreciated	{

//depreciated		//
//depreciated		// create the object hierarchy for APAC
//depreciated		//

//depreciated		Account regionalAccount = new Account(
//depreciated			BillingCity = 'Tokyo',
//depreciated			BillingCountry = 'JP',
//depreciated			BillingPostalCode = '150-0013',
//depreciated			BillingState = 'Shibuya-ku',
//depreciated			BillingStreet = 'Ebisu Neonato 8F 1-18 Ebisu 4-chome',
//depreciated			Name = 'Red Hat K.K.',
//depreciated			OracleAccountNumber__c = '12345',
//depreciated			RecordTypeId = '012300000000QglAAE',
//depreciated			ShippingCity = 'Tokyo',
//depreciated			ShippingCountry = 'JP',
//depreciated			ShippingPostalCode = '150-0013',
//depreciated			ShippingState = 'Shibuya-ku',
//depreciated			ShippingStreet = 'Ebisu Neonato 8F 1-18 Ebisu 4-chome',
//depreciated			VATNumber__c = '67890');
//depreciated		insert regionalAccount;

//depreciated		Contact regionalContact = createContact(regionalAccount.Id);

//depreciated		Opportunity regionalOpportunity = new Opportunity(
//depreciated			AccountId = regionalAccount.Id,
//depreciated			CloseDate = Date.newInstance(2009, 11, 10),
//depreciated			Country_Of_Order__c = 'JP',
//depreciated			CurrencyIsoCode = 'USD',
//depreciated			Name = 'regionalOpportunity',
//depreciated			OpportunityType__c = 'Standard',
//depreciated			PaymentType__c = 'APAC Purchase Order',
//depreciated			PONumber__c = 'TEST_PO_NUMBER',
//depreciated			Pricebook2Id = GLOBAL_PRICEBOOK.Id,
//depreciated			RecordTypeId = '012300000000TVCAA2',
//depreciated			StageName = 'Prepare',
//depreciated			Touched__c = true);
//depreciated		insert regionalOpportunity;

//depreciated		OpportunityContactRole regionalOCR = new OpportunityContactRole(
//depreciated			Role = 'Shipping Contact',
//depreciated			ContactId = regionalContact.Id,
//depreciated			OpportunityId = regionalOpportunity.Id);
//depreciated		insert regionalOCR;

//depreciated		OpportunityLineItem regionalLineItem = createOpportunityLineItem(regionalOpportunity.Id,2009);

//depreciated		String regionalMessage = '<?xml version="1.0" encoding="UTF-8"?>' +
//depreciated			'<SalesforceMessage xmlns="http://salesforce.redhat.com/renewals"' +
//depreciated			'		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' +
//depreciated			'		xsi:schemaLocation="http://salesforce.redhat.com/renewals Renewals.xsd ">' +
//depreciated			'	<Header>' +
//depreciated			'		<Operation>Operation</Operation>' +
//depreciated			'		<Type>Type</Type>' +
//depreciated			'		<InstanceId>InstanceId</InstanceId>' +
//depreciated			'		<Timestamp>2011-02-10</Timestamp>' +
//depreciated			'	</Header>' +
//depreciated			'	<Payload>' +
//depreciated			'		<Subscription>' +
//depreciated			'			<Id>0</Id>' +
//depreciated			'			<OrderId>0</OrderId>' +
//depreciated			'			<OrderNumber></OrderNumber>' +
//depreciated			'			<ContractId>0</ContractId>' +
//depreciated			'			<ContractNumber>12345</ContractNumber>' +
//depreciated			'			<ContractStatusCode>ContractStatusCode</ContractStatusCode>' +
//depreciated			'			<ContractStartDate>2010-01-01</ContractStartDate>' +
//depreciated			'			<ContractEndDate>2011-01-01</ContractEndDate>' +
//depreciated			'			<CurrencyIsoCode>' + regionalOpportunity.CurrencyIsoCode + '</CurrencyIsoCode>' +
//depreciated			'			<ContractAmount>0.0</ContractAmount>' +
//depreciated			'			<OrderSourceId>0</OrderSourceId>' +
//depreciated			'			<OrderSourceName>OrderSourceName</OrderSourceName>' +
//depreciated			'			<SalesRepOnOrder>SalesRepOnOrder</SalesRepOnOrder>' +
//depreciated			'			<OpportunityNumber></OpportunityNumber>' +
//depreciated			'			<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'			<OrderTypeId>0</OrderTypeId>' +
//depreciated			'			<OrderTypeName>OrderTypeName</OrderTypeName>' +
//depreciated			'			<CountryOfOrder>CountryOfOrder</CountryOfOrder>' +
//depreciated			'			<SalesChannelCode>SalesChannelCode</SalesChannelCode>' +
//depreciated			'			<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'			<BusinessUnitId>0</BusinessUnitId>' +
//depreciated			'			<BusinessUnitName>BusinessUnitName</BusinessUnitName>' +
//depreciated			'			<Region>APAC</Region>' +
//depreciated			'			<AccountRecordType>AccountRecordType</AccountRecordType>' +
//depreciated			'			<AccountRecordTypeId>' + regionalAccount.RecordTypeId + '</AccountRecordTypeId>' +
//depreciated			'			<OpportunityRecordType>OpportunityRecordType</OpportunityRecordType>' +
//depreciated			'			<OpportunityRecordTypeId>' + regionalOpportunity.RecordTypeId + '</OpportunityRecordTypeId>' +
//depreciated			'			<SoldToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.AccountNumber + '</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.BillingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.BillingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.BillingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.BillingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.BillingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.Id + '</SalesforceAccountId>' +
//depreciated			'			</SoldToParty>' +
//depreciated			'			<ShipToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.AccountNumber + '</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.ShippingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.ShippingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.ShippingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.ShippingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.ShippingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			</ShipToParty>' +
//depreciated			'			<BillToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.AccountNumber + '</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.BillingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.BillingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.BillingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.BillingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.BillingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			</BillToParty>' +
//depreciated			'			<LeadSourceDetail>LeadSourceDetail</LeadSourceDetail>' +
//depreciated			'			<CampaignName>CampaignName</CampaignName>' +
//depreciated			'			<FiscalYear>0</FiscalYear>' +
//depreciated			'			<FiscalQuarter>0</FiscalQuarter>' +
//depreciated			'			<ExpiringProductsAmount>0.0</ExpiringProductsAmount>' +
//depreciated			'			<SalesRepOnAccount>SalesRepOnAccount</SalesRepOnAccount>' +
//depreciated			'			<SalesRepRoleOnAccount>SalesRepRoleOnAccount</SalesRepRoleOnAccount>' +
//depreciated			'			<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			<SalesforceExpiredProductId>SalesforceExpiredProductId</SalesforceExpiredProductId>' +
//depreciated			'			<SalesforceOpportunityId>' +  regionalOpportunity.Id + '</SalesforceOpportunityId>' +
//depreciated			'			<SalesforceAccountOwnerId>' + USER.id + '</SalesforceAccountOwnerId>' +
//depreciated			'			<SalesforceCampaignId>' + CAMPAIGN.Id + '</SalesforceCampaignId>' +
//depreciated			'			<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'			<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			<Line>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'				<OrderLineId>0</OrderLineId>' +
//depreciated			'				<OrderLineNumber>0</OrderLineNumber>' +
//depreciated			'				<ContractLineId>0</ContractLineId>' +
//depreciated			'				<ContractNumber>0</ContractNumber>' +
//depreciated			'				<ExternalId>0-0</ExternalId>' +
//depreciated			'				<OpportunityNumber></OpportunityNumber>' +
//depreciated			'				<OrderNumber>0</OrderNumber>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<PricingAttributes>PricingAttributes</PricingAttributes>' +
//depreciated			'				<OrderedItem>' + PRODUCT.ProductCode + '</OrderedItem>' +
//depreciated			'				<ProductLine>ProductLine</ProductLine>' +
//depreciated			'				<ConfiguredItem></ConfiguredItem>' +
//depreciated			'				<ConfiguredItemDescription>ConfiguredItemDescription</ConfiguredItemDescription>' +
//depreciated			'				<SubstituteItem></SubstituteItem>' +
//depreciated			'				<RenewalItem></RenewalItem>' +
//depreciated			'				<FulfilledItem>FulfilledItem</FulfilledItem>' +
//depreciated			'				<FulfilledItemDescription>FulfilledItemDescription</FulfilledItemDescription>' +
//depreciated			'				<UnitSellingPrice>0.0</UnitSellingPrice>' +
//depreciated			'				<ServiceStartDate>2001-03-01</ServiceStartDate>' +
//depreciated			'				<ServiceEndDate>2002-03-01</ServiceEndDate>' +
//depreciated			'				<OrderedQuantity>' + regionalLineItem.Quantity + '</OrderedQuantity>' +
//depreciated			'				<TotalPrice>0.0</TotalPrice>' +
//depreciated			'				<CotermFlag>CotermFlag</CotermFlag>' +
//depreciated			'				<NfrFlag>NfrFlag</NfrFlag>' +
//depreciated			'				<RevenueAmount>0.0</RevenueAmount>' +
//depreciated			'				<FiscalYear>0</FiscalYear>' +
//depreciated			'				<FiscalQuarter>0</FiscalQuarter>' +
//depreciated			'				<SalesforceExpiringProductId>' + PRODUCT.Id + '</SalesforceExpiringProductId>' +
//depreciated			'				<SalesforceOpportunityId>' + regionalOpportunity.Id + '</SalesforceOpportunityId>' +
//depreciated			'				<SalesforceOpportunityLineId>' + regionalLineItem.Id+ '</SalesforceOpportunityLineId>' +
//depreciated			'				<SalesforcePricebookEntryId>' + PRICEBOOK_ENTRY.Id + '</SalesforcePricebookEntryId>' +
//depreciated			'				<SalesforceProduct2Id></SalesforceProduct2Id>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</Line>' +
//depreciated			//'			<MergedSubscription>' +
//depreciated			//'				<Id>0</Id>' +
//depreciated			//'				<OrderId>0</OrderId>' +
//depreciated			//'				<OrderNumber>OrderNumber</OrderNumber>' +
//depreciated			//'				<ContractId>0</ContractId>' +
//depreciated			//'				<ContractNumber>ContractNumber</ContractNumber>' +
//depreciated			//'				<ContractStartDate>2004-05-01</ContractStartDate>' +
//depreciated			//'				<ContractEndDate>2005-05-01</ContractEndDate>' +
//depreciated			//'				<ContractAmount>0.0</ContractAmount>' +
//depreciated			//'				<ExpiringProductsAmount>0</ExpiringProductsAmount>' +
//depreciated			//'				<OpportunityNumber></OpportunityNumber>' +
//depreciated			//'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			//'				<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			//'				<ExpiringProductAmount>0.0</ExpiringProductAmount>' +
//depreciated			//'			</MergedSubscription>' +
//depreciated			'			<Partner>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>0</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>Address1</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>City</City>' +
//depreciated			'					<State>State</State>' +
//depreciated			'					<PostalCode>PostalCode</PostalCode>' +
//depreciated			'					<Country>Country</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.Id + '</SalesforceAccountId>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<ApId>0</ApId>' +
//depreciated			'				<PartnerType>PartnerType</PartnerType>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</Partner>' +
//depreciated			'			<User>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<UserType>UserType</UserType>' +
//depreciated			'				<UserId>0</UserId>' +
//depreciated			'				<UserName></UserName>' +
//depreciated			'				<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'				<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'				<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'				<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'				<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'				<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'				<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</User>' +
//depreciated			'		</Subscription>' +
//depreciated			'	</Payload>' +
//depreciated			'</SalesforceMessage>';

//depreciated		test.startTest();
//depreciated		String responseXML = OPPORTUNITY_RENEWAL.createRenewalOpportunity( regionalMessage );
//depreciated		test.stopTest();

//depreciated		Opportunity opp = queryOpportunity(regionalOpportunity.Id);
//depreciated		List<CampaignMember> campaignMembers = queryCampaignMembers(regionalOpportunity.Id);
//depreciated		Map<Id,String> idMap = getIdMap(opp,campaignMembers);
//depreciated		idMap.put(regionalAccount.Id,'{!regionalAccount.Id}');
//depreciated		idMap.put(regionalContact.Id,'{!regionalContact.Id}');
//depreciated		idMap.put(regionalOpportunity.Id,'{!regionalOpportunity.Id}');
//depreciated		idMap.put(regionalOCR.Id,'{!regionalOCR.Id}');
//depreciated		idMap.put(regionalLineItem.Id,'{!regionalLineItem.Id}');

//depreciated		String expectedXML = '<?xml version="1.0" encoding="UTF-8"?><SalesforceMessage xmlns=""><Header><Operation>Operation</Operation>'
//depreciated			+'<Type>Type</Type>'
//depreciated			+'<InstanceId>InstanceId</InstanceId>'
//depreciated			+'<Timestamp>2011-02-10</Timestamp>'
//depreciated			+'<ResponseTimeStamp>{!today}T..:..:..</ResponseTimeStamp></Header>'
//depreciated			+'<Payload><Subscription><Id>0</Id>'
//depreciated			+'<SalesRepOnAccount>...</SalesRepOnAccount>'
//depreciated			+'<SalesRepRoleOnAccount>...</SalesRepRoleOnAccount>'
//depreciated			+'<SalesforceAccountId>{!regionalAccount.Id}</SalesforceAccountId>'
//depreciated			+'<SalesforceOpportunityId>{!Opportunity.Id}</SalesforceOpportunityId>'
//depreciated			+'<SalesforceAccountOwnerId>{!Opportunity.OwnerId}</SalesforceAccountOwnerId>'
//depreciated			+'<RecordStatus>SUCCESS</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage>'
//depreciated			+'<Line><Id>0</Id>'
//depreciated			+'<ExternalId>0-0</ExternalId>'
//depreciated			+'<SalesforceExpiringProductId>{!Opportunity.Expiring_Products__r[0].Id}</SalesforceExpiringProductId>'
//depreciated			+'<SalesforceOpportunityLineId>{!OpportunityLineItems[0].Id}</SalesforceOpportunityLineId>'
//depreciated			+'<SalesforcePricebookEntryId>{!PricebookEntry.Id}</SalesforcePricebookEntryId>'
//depreciated			+'<SalesforceProduct2Id>{!Product.Id}</SalesforceProduct2Id>'
//depreciated			+'<RecordStatus>SUCCESS</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></Line>'
//depreciated			+'<Partner><Contact><SalesforceContactId>{!regionalContact.Id}</SalesforceContactId>'
//depreciated			+'<SalesforceContactRoleId>{!regionalOCR.Id}</SalesforceContactRoleId></Contact>'
//depreciated			+'<SalesforceAccountId>{!regionalAccount.Id}</SalesforceAccountId>'
//depreciated			+'<Id>0</Id>'
//depreciated			+'<SalesforceOpportunityPartnerId></SalesforceOpportunityPartnerId>'
//depreciated			+'<RecordStatus>ERROR</RecordStatus>'
//depreciated			+'<ErrorMessage>Failed to create Opportunity Partner: Unable to locate partner</ErrorMessage></Partner>'
//depreciated			+'<User><Id>0</Id>'
//depreciated			+'<SalesforceContactId>{!regionalContact.Id}</SalesforceContactId>'
//depreciated			+'<SalesforceContactRoleId>{!regionalOCR.Id}</SalesforceContactRoleId>'
//depreciated			+'<RecordStatus>RecordStatus</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></User></Subscription></Payload></SalesforceMessage>';
//depreciated		responseXML = cleanResponseXML(responseXML,idMap);
//depreciated		System.assert(expectedXML == responseXML,'Unexpected Response: '+responseXML);

//depreciated		System.assertEquals(regionalAccount.Id,opp.AccountId);
//depreciated		System.assertEquals(0.00,opp.Amount);
//depreciated		System.assertEquals(null,opp.BillingAccountNumber__c);
//depreciated		System.assertEquals(regionalAccount.BillingStreet+'Address2',opp.BillingAddress__c);
//depreciated		System.assertEquals(regionalAccount.BillingCity,opp.BillingCity__c);
//depreciated		System.assertEquals(regionalAccount.BillingState,opp.BillingState__c);
//depreciated		System.assertEquals(regionalAccount.BillingCountry,opp.BillingCountry__c);
//depreciated		System.assertEquals(regionalAccount.BillingPostalCode,opp.BillingZipPostalCode__c);
//depreciated		System.assertEquals(CAMPAIGN.Id,opp.CampaignId);
//depreciated		System.assertEquals(Date.newInstance(2002,03,01),opp.CloseDate);
//depreciated		System.assertEquals(regionalAccount.OracleAccountNumber__c,opp.ContractNumber__c);
//depreciated		System.assertEquals(Date.newInstance(2010,01,01),opp.ContractStartDate__c);
//depreciated		System.assertEquals(Date.newInstance(2011,01,01),opp.ContractEndDate__c);
//depreciated		System.assertEquals(regionalOpportunity.Country_Of_Order__c,opp.Country_of_Order__c);
//depreciated		System.assertEquals('None',opp.CrossRegionalCreditCheck__c);
//depreciated		System.assertEquals(regionalOpportunity.CurrencyIsoCode,opp.CurrencyIsoCode);
//depreciated		String orderNumber = null;
//depreciated		System.assertEquals(
//depreciated			'Partner Contact: '+regionalContact.Name
//depreciated			+'\nPartner Email: '+regionalContact.Email
//depreciated			+'\nPartner Phone: '+regionalContact.Phone
//depreciated			+'\n\nOrder Number: '+orderNumber
//depreciated			+'\nContract Number: 12345',opp.Description);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products_Total_Amount_RollUp__c);
//depreciated		System.assertEquals('Direct - End Customer',opp.FulfillmentChannel__c);
//depreciated		System.assertEquals('LeadSourceDetail',opp.LeadSourceDetail__c);
//depreciated		System.assertEquals('PartyName',opp.NA_Reseller__c);
//depreciated		System.assertEquals('Renewal Red Hat K.K. Service Contract #12345',opp.Name);
//depreciated		System.assertEquals('Standard',opp.OpportunityType__c);
//depreciated		System.assertNotEquals(null,opp.OwnerId);
//depreciated		System.assertEquals('Yes',opp.Pay_Now__c);
//depreciated		System.assertEquals(null,opp.PaymentType__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.PONumber__c);
//depreciated		System.assertEquals(null,opp.Primary_Partner__c);
//depreciated		System.assertNotEquals(null,opp.RecordTypeId);
//depreciated		System.assertEquals('true',''+opp.Renewal_Opportunity__c);
//depreciated		System.assertEquals('No',opp.Renewable__c);
//depreciated		System.assertEquals('PartyName',opp.Reseller__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.Reseller_PO__c);
//depreciated		System.assertEquals(regionalAccount.ShippingStreet+'Address2',opp.ShippingAddress__c);
//depreciated		System.assertEquals(regionalAccount.ShippingCity,opp.ShippingCity__c);
//depreciated		System.assertEquals(regionalAccount.ShippingState,opp.ShippingState__c);
//depreciated		System.assertEquals(regionalAccount.ShippingCountry,opp.ShippingCountry__c);
//depreciated		System.assertEquals(regionalAccount.ShippingPostalCode,opp.ShippingZipPostalCode__c);
//depreciated		System.assertEquals('Engage',opp.StageName);
//depreciated		System.assertEquals('true',''+opp.Touched__c);
//depreciated		System.assertEquals(null,opp.Year1PaymentAmount__c);

//depreciated		System.assertEquals(1,opp.Expiring_Products__r.size());
//depreciated		System.assertEquals(Date.newInstance(2002,03,01),opp.Expiring_Products__r[0].Expiring_Product_End_Date__c);
//depreciated		System.assertEquals('0',opp.Expiring_Products__r[0].Expiring_Contract_Number__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.Expiring_Products__r[0].Expiring_Contract_PO_Number__c);
//depreciated		System.assertEquals(Date.newInstance(2001,03,01),opp.Expiring_Products__r[0].Expiring_Product_Start_Date__c);
//depreciated		System.assertEquals('0',opp.Expiring_Products__r[0].Expiring_Oracle_Order_Number__c);
//depreciated		System.assertEquals('USD',opp.Expiring_Products__r[0].CurrencyIsoCode);
//depreciated		System.assertEquals('false',''+opp.Expiring_Products__r[0].Co_Term__c);
//depreciated		System.assertEquals('false',''+opp.Expiring_Products__r[0].Already_Renewed__c);
//depreciated		System.assertEquals('HFB007',opp.Expiring_Products__r[0].Product_Code__c);
//depreciated		System.assertEquals(2,opp.Expiring_Products__r[0].Quantity__c);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products__r[0].Sales_Price__c);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products__r[0].Total_Price_Formula__c);
//depreciated		System.assertEquals('FulfilledItemDescription',opp.Expiring_Products__r[0].Name);
//depreciated		System.assertEquals('FulfilledItemDescription',opp.Expiring_Products__r[0].Mapped_Description__c);
//depreciated		System.assertEquals('01t',(opp.Expiring_Products__r[0].Product__c+'   ').substring(0,3));

//depreciated		System.assertEquals(2,opp.OpportunityContactRoles.size());
//depreciated		System.assertEquals('003',(opp.OpportunityContactRoles[0].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example@example.org',opp.OpportunityContactRoles[0].Contact.Email);
//depreciated		System.assertEquals('Shipping Contact',opp.OpportunityContactRoles[0].Role);
//depreciated		System.assertEquals('003',(opp.OpportunityContactRoles[1].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example@example.org',opp.OpportunityContactRoles[1].Contact.Email);
//depreciated		System.assertEquals('Technical Buyer',opp.OpportunityContactRoles[1].Role);

//depreciated		System.assertEquals(1,opp.OpportunityLineItems.size());
//depreciated		System.assertEquals(Date.newInstance(2003,03,01),opp.OpportunityLineItems[0].ActualEndDate__c);
//depreciated		System.assertEquals(Date.newInstance(2002,03,02),opp.OpportunityLineItems[0].ActualStartDate__c);
//depreciated		System.assertEquals('01u',(opp.OpportunityLineItems[0].PricebookEntryId+'   ').substring(0,3));
//depreciated		System.assertEquals('Renewal',opp.OpportunityLineItems[0].NewOrRenewal__c);
//depreciated		System.assertEquals(2.00,opp.OpportunityLineItems[0].Quantity);
//depreciated		System.assertEquals('true',''+opp.OpportunityLineItems[0].ScheduleLocked__c);
//depreciated		System.assertEquals('0',opp.OpportunityLineItems[0].Contract_Numbers__c);
//depreciated		System.assertEquals(null,opp.OpportunityLineItems[0].Configured_SKU__c);
//depreciated		System.assertEquals(0.00,opp.OpportunityLineItems[0].UnitPrice);
//depreciated		System.assertEquals('ConfiguredItemDescription',opp.OpportunityLineItems[0].Description);

//depreciated		System.assertEquals(0,opp.OpportunityPartners2__r.size());

//depreciated		System.assertEquals(1,campaignMembers.size());
//depreciated		System.assertEquals(CAMPAIGN.Id,campaignMembers[0].CampaignId);
//depreciated		System.assertEquals('003',(campaignMembers[0].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example@example.org',''+campaignMembers[0].Contact.Email);
//depreciated	}

//	static PartnerStatus__c partnerStatus {
//		get {
//			if(partnerStatus == null) {
//				Classification__c pType = new Classification__c(Name='Partner Type');
//				Classification__c pTier = new Classification__c(Name='Partner Tier');
//				for(Classification__c c : [
//					select Name 
//					from Classification__c 
//					where Name in ('Partner Type','Partner Tier') 
//						and Parent__c = null])
//				{
//					if(c.Name == 'Partner Type') {
//						pType = c;
//					}
//					else if(c.Name == 'Partner Tier')
//					{
//						pTier = c;
//					}
//				}
//				if(pType.Id == null || pTier.Id == null) {
//					upsert new List<Classification__c>{pType,pTier};
//				}
//				Classification__c cTier = new Classification__c(Name='Child Tier',Parent__c=pTier.Id);
//				Classification__c cType = new Classification__c(Name='Child Type',Parent__c=pType.Id);
//				insert new List<Classification__c>{cTier,cType};
//				// this is a sad story...
//				List<RedHatObjectReferences__c> rhors = new List<RedHatObjectReferences__c>{
//					new RedHatObjectReferences__c(
//						Name='PARTNER_TYPE.ISV',
//						ObjectId__c=cType.Id),
//					new RedHatObjectReferences__c(
//						Name='PARTNER_TIER.ADVANCED',
//						ObjectId__c=cTier.Id) };
//				upsert rhors;
//				partnerStatus = new PartnerStatus__c(
//					ActivationDate__c = Date.today().addDays(-1),
//					ApprovalStatus__c = 'Approved',
//					ExpirationDate__c = Date.today().addDays(7),
//					Partner__c = reseller.Id,
//					PartnerTier__c = cTier.Id,
//					PartnerType__c = cType.Id);
//				insert partnerStatus;
//				partnerStatus.Partner__r = reseller;
//				partnerStatus.PartnerTier__r = cTier;
//				partnerStatus.PartnerType__r = cType;
//			}
//			return partnerStatus;
//		}
//	}

//depreciated	@isTest
//depreciated	static void testCreateRenewalOpportunityEMEA()
//depreciated	{
//depreciated		//
//depreciated		// create the object hierarchy for EMEA
//depreciated		//

//depreciated		Account regionalAccount = new Account(
//depreciated			BillingCity = 'Raleigh',
//depreciated			BillingCountry = 'US',
//depreciated			BillingPostalCode = '27606',
//depreciated			BillingState = 'North Carolina',
//depreciated			BillingStreet = '1801 Varsity Drive',
//depreciated			Name = 'Red Hat',
//depreciated			OracleAccountNumber__c = '12345',
//depreciated			RecordTypeId = '012300000000NBLAA2',
//depreciated			ShippingCity = 'Raleigh',
//depreciated			ShippingCountry = 'US',
//depreciated			ShippingPostalCode = '27606',
//depreciated			ShippingState = 'North Carolina',
//depreciated			ShippingStreet = '1801 Varsity Drive',
//depreciated			VATNumber__c = '67890');
//depreciated		insert regionalAccount;

//depreciated		Contact regionalContact = createContact(regionalAccount.Id);

//depreciated		Opportunity regionalOpportunity = new Opportunity(
//depreciated			AccountId = regionalAccount.Id,
//depreciated			CloseDate = Date.newInstance(2009, 11, 10),
//depreciated			Country_Of_Order__c = 'US',
//depreciated			CurrencyIsoCode = 'USD',
//depreciated			Name = 'regionalOpportunity',
//depreciated			OpportunityType__c = 'Standard',
//depreciated			PaymentType__c = 'EMEA Purchase Order',
//depreciated			PONumber__c = 'TEST_PO_NUMBER',
//depreciated			Pricebook2Id = GLOBAL_PRICEBOOK.id,
//depreciated			RecordTypeId = '012300000000S4ZAAU',
//depreciated			StageName = 'Test Stage',
//depreciated			Touched__c = true);
//depreciated		insert regionalOpportunity;

//depreciated		OpportunityContactRole regionalOCR = new OpportunityContactRole(
//depreciated			Role = 'Shipping Contact',
//depreciated			ContactId = regionalContact.Id,
//depreciated			OpportunityId = regionalOpportunity.Id);
//depreciated		insert regionalOCR;

//depreciated		OpportunityLineItem regionalLineItem = new OpportunityLineItem();
//depreciated		regionalLineItem.OpportunityId = regionalOpportunity.Id;
//depreciated		regionalLineItem.ActualStartDate__c = Date.newInstance(2009, 11, 11);
//depreciated		regionalLineItem.ActualEndDate__c = Date.newInstance(2010, 11, 10);
//depreciated		regionalLineItem.ActualTerm__c = 365;
//depreciated		regionalLineItem.PricebookEntryId = PRICEBOOK_ENTRY.Id;
//depreciated		regionalLineItem.Quantity = 2;
//depreciated		regionalLineItem.UnitPrice = 2000.00;
//depreciated		regionalLineItem.ScheduleLocked__c = true;
//depreciated		insert regionalLineItem;

//depreciated		String regionalMessage = '<?xml version="1.0" encoding="UTF-8"?>' +
//depreciated			'<SalesforceMessage xmlns="http://salesforce.redhat.com/renewals"' +
//depreciated			'		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' +
//depreciated			'		xsi:schemaLocation="http://salesforce.redhat.com/renewals Renewals.xsd ">' +
//depreciated			'	<Header>' +
//depreciated			'		<Operation>Operation</Operation>' +
//depreciated			'		<Type>Type</Type>' +
//depreciated			'		<InstanceId>InstanceId</InstanceId>' +
//depreciated			'		<Timestamp>2011-02-10</Timestamp>' +
//depreciated			'	</Header>' +
//depreciated			'	<Payload>' +
//depreciated			'		<Subscription>' +
//depreciated			'			<Id>0</Id>' +
//depreciated			'			<OrderId>0</OrderId>' +
//depreciated			'			<OrderNumber></OrderNumber>' +
//depreciated			'			<ContractId>0</ContractId>' +
//depreciated			'			<ContractNumber>12345</ContractNumber>' +
//depreciated			'			<ContractStatusCode>ContractStatusCode</ContractStatusCode>' +
//depreciated			'			<ContractStartDate>2010-01-01</ContractStartDate>' +
//depreciated			'			<ContractEndDate>2011-01-01</ContractEndDate>' +
//depreciated			'			<CurrencyIsoCode>' + regionalOpportunity.CurrencyIsoCode + '</CurrencyIsoCode>' +
//depreciated			'			<ContractAmount>0.0</ContractAmount>' +
//depreciated			'			<OrderSourceId>0</OrderSourceId>' +
//depreciated			'			<OrderSourceName>OrderSourceName</OrderSourceName>' +
//depreciated			'			<SalesRepOnOrder>SalesRepOnOrder</SalesRepOnOrder>' +
//depreciated			'			<OpportunityNumber></OpportunityNumber>' +
//depreciated			'			<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'			<OrderTypeId>0</OrderTypeId>' +
//depreciated			'			<OrderTypeName>OrderTypeName</OrderTypeName>' +
//depreciated			'			<CountryOfOrder>CountryOfOrder</CountryOfOrder>' +
//depreciated			'			<SalesChannelCode>SalesChannelCode</SalesChannelCode>' +
//depreciated			'			<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'			<BusinessUnitId>0</BusinessUnitId>' +
//depreciated			'			<BusinessUnitName>BusinessUnitName</BusinessUnitName>' +
//depreciated			'			<Region>EMEA</Region>' +
//depreciated			'			<AccountRecordType>AccountRecordType</AccountRecordType>' +
//depreciated			'			<AccountRecordTypeId>' + regionalAccount.RecordTypeId + '</AccountRecordTypeId>' +
//depreciated			'			<OpportunityRecordType>OpportunityRecordType</OpportunityRecordType>' +
//depreciated			'			<OpportunityRecordTypeId>' + regionalOpportunity.RecordTypeId + '</OpportunityRecordTypeId>' +
//depreciated			'			<SoldToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.OracleAccountNumber__c + '</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.BillingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.BillingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.BillingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.BillingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.BillingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			//'				<SalesforceAccountId>' + regionalAccount.Id + '</SalesforceAccountId>' +
//depreciated			'			</SoldToParty>' +
//depreciated			'			<ShipToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.AccountNumber + '</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.ShippingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.ShippingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.ShippingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.ShippingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.ShippingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			</ShipToParty>' +
//depreciated			'			<BillToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.OracleAccountNumber__c + '</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.BillingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.BillingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.BillingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.BillingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.BillingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			</BillToParty>' +
//depreciated			'			<LeadSourceDetail>LeadSourceDetail</LeadSourceDetail>' +
//depreciated			'			<CampaignName>CampaignName</CampaignName>' +
//depreciated			'			<FiscalYear>0</FiscalYear>' +
//depreciated			'			<FiscalQuarter>0</FiscalQuarter>' +
//depreciated			'			<ExpiringProductsAmount>0.0</ExpiringProductsAmount>' +
//depreciated			'			<SalesRepOnAccount>SalesRepOnAccount</SalesRepOnAccount>' +
//depreciated			'			<SalesRepRoleOnAccount>SalesRepRoleOnAccount</SalesRepRoleOnAccount>' +
//depreciated			//'			<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			<SalesforceExpiredProductId>SalesforceExpiredProductId</SalesforceExpiredProductId>' +
//depreciated			'			<SalesforceOpportunityId>' +  regionalOpportunity.Id + '</SalesforceOpportunityId>' +
//depreciated			'			<SalesforceAccountOwnerId>' + USER.id + '</SalesforceAccountOwnerId>' +
//depreciated			'			<SalesforceCampaignId>' + CAMPAIGN.Id + '</SalesforceCampaignId>' +
//depreciated			'			<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'			<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			<Line>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'				<OrderLineId>0</OrderLineId>' +
//depreciated			'				<OrderLineNumber>0</OrderLineNumber>' +
//depreciated			'				<ContractLineId>0</ContractLineId>' +
//depreciated			'				<ContractNumber>0</ContractNumber>' +
//depreciated			'				<ExternalId>0-0</ExternalId>' +
//depreciated			'				<OpportunityNumber></OpportunityNumber>' +
//depreciated			'				<OrderNumber>0</OrderNumber>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<PricingAttributes>PricingAttributes</PricingAttributes>' +
//depreciated			'				<OrderedItem>' + PRODUCT.ProductCode + '</OrderedItem>' +
//depreciated			'				<ProductLine>ProductLine</ProductLine>' +
//depreciated			'				<ConfiguredItem>RH0123456</ConfiguredItem>' +
//depreciated			'				<ConfiguredItemDescription>ConfiguredItemDescription</ConfiguredItemDescription>' +
//depreciated			'				<SubstituteItem></SubstituteItem>' +
//depreciated			'				<RenewalItem></RenewalItem>' +
//depreciated			'				<FulfilledItem>FulfilledItem</FulfilledItem>' +
//depreciated			'				<FulfilledItemDescription>FulfilledItemDescription</FulfilledItemDescription>' +
//depreciated			'				<UnitSellingPrice>0.0</UnitSellingPrice>' +
//depreciated			'				<ServiceStartDate>2001-03-01</ServiceStartDate>' +
//depreciated			'				<ServiceEndDate>2002-03-01</ServiceEndDate>' +
//depreciated			'				<OrderedQuantity>' + regionalLineItem.Quantity + '</OrderedQuantity>' +
//depreciated			'				<TotalPrice>0.0</TotalPrice>' +
//depreciated			'				<CotermFlag>CotermFlag</CotermFlag>' +
//depreciated			'				<NfrFlag>NfrFlag</NfrFlag>' +
//depreciated			'				<RevenueAmount>0.0</RevenueAmount>' +
//depreciated			'				<FiscalYear>0</FiscalYear>' +
//depreciated			'				<FiscalQuarter>0</FiscalQuarter>' +
//depreciated			'				<SalesforceExpiringProductId>' + PRODUCT.Id + '</SalesforceExpiringProductId>' +
//depreciated			'				<SalesforceOpportunityId>' + regionalOpportunity.Id + '</SalesforceOpportunityId>' +
//depreciated			'				<SalesforceOpportunityLineId>' + regionalLineItem.Id+ '</SalesforceOpportunityLineId>' +
//depreciated			'				<SalesforcePricebookEntryId>' + PRICEBOOK_ENTRY.Id + '</SalesforcePricebookEntryId>' +
//depreciated			'				<SalesforceProduct2Id>' + PRODUCT.Id + '</SalesforceProduct2Id>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</Line>' +
//depreciated			'			<MergedSubscription>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<OrderId>0</OrderId>' +
//depreciated			'				<OrderNumber>OrderNumber</OrderNumber>' +
//depreciated			'				<ContractId>0</ContractId>' +
//depreciated			'				<ContractNumber>ContractNumber</ContractNumber>' +
//depreciated			'				<ContractStartDate>2001-03-01</ContractStartDate>' +
//depreciated			'				<ContractEndDate>2002-03-01</ContractEndDate>' +
//depreciated			'				<ContractAmount>0.0</ContractAmount>' +
//depreciated			'				<ExpiringProductsAmount>0</ExpiringProductsAmount>' +
//depreciated			'				<OpportunityNumber></OpportunityNumber>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'				<ExpiringProductAmount>0.0</ExpiringProductAmount>' +
//depreciated			'			</MergedSubscription>' +
//depreciated			'			<Partner>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>0</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>Address1</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>City</City>' +
//depreciated			'					<State>State</State>' +
//depreciated			'					<PostalCode>PostalCode</PostalCode>' +
//depreciated			'					<Country>Country</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.Id + '</SalesforceAccountId>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<ApId>0</ApId>' +
//depreciated			'				<PartnerType>PartnerType</PartnerType>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</Partner>' +
//depreciated			'			<User>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<UserType>UserType</UserType>' +
//depreciated			'				<UserId>0</UserId>' +
//depreciated			'				<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'				<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'				<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'				<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'				<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'				<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'				<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</User>' +
//depreciated			'		</Subscription>' +
//depreciated			'	</Payload>' +
//depreciated			'</SalesforceMessage>';
//depreciated		insert new BillToAccount__c(
//depreciated			Bill_To_Account_Number__c=regionalAccount.OracleAccountNumber__c,
//depreciated			Channel_Code__c='Indirect - VAR/VAD',
//depreciated			Region__c='EMEA');
//depreciated		test.startTest();
//depreciated		String responseXML = OPPORTUNITY_RENEWAL.createRenewalOpportunity( regionalMessage );
//depreciated		test.stopTest();

//depreciated		System.debug(responseXML);
//depreciated		Opportunity opp = queryOpportunity(regionalOpportunity.Id);
//depreciated		List<CampaignMember> campaignMembers = queryCampaignMembers(regionalOpportunity.Id);
//depreciated		Map<Id,String> idMap = getIdMap(opp,campaignMembers);
//depreciated		idMap.put(regionalAccount.Id,'{!regionalAccount.Id}');
//depreciated		idMap.put(regionalContact.Id,'{!regionalContact.Id}');
//depreciated		idMap.put(regionalOpportunity.Id,'{!regionalOpportunity.Id}');
//depreciated		idMap.put(regionalOCR.Id,'{!regionalOCR.Id}');
//depreciated		idMap.put(regionalLineItem.Id,'{!regionalLineItem.Id}');

//depreciated		String expectedXML = '<?xml version="1.0" encoding="UTF-8"?><SalesforceMessage xmlns=""><Header><Operation>Operation</Operation>'
//depreciated			+'<Type>Type</Type>'
//depreciated			+'<InstanceId>InstanceId</InstanceId>'
//depreciated			+'<Timestamp>2011-02-10</Timestamp>'
//depreciated			+'<ResponseTimeStamp>{!today}T..:..:..</ResponseTimeStamp></Header>'
//depreciated			+'<Payload><Subscription><Id>0</Id>'
//depreciated			+'<SalesRepOnAccount>...</SalesRepOnAccount>'
//depreciated			+'<SalesRepRoleOnAccount>...</SalesRepRoleOnAccount>'
//depreciated			+'<SalesforceAccountId>{!regionalAccount.Id}</SalesforceAccountId>'
//depreciated			+'<SalesforceOpportunityId>{!Opportunity.Id}</SalesforceOpportunityId>'
//depreciated			+'<SalesforceAccountOwnerId>{!Opportunity.OwnerId}</SalesforceAccountOwnerId>'
//depreciated			+'<RecordStatus>SUCCESS</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage>'
//depreciated			+'<Line><Id>0</Id>'
//depreciated			+'<ExternalId>0-0</ExternalId>'
//depreciated			+'<SalesforceExpiringProductId>{!Opportunity.Expiring_Products__r[0].Id}</SalesforceExpiringProductId>'
//depreciated			+'<SalesforceOpportunityLineId>{!OpportunityLineItems[0].Id}</SalesforceOpportunityLineId>'
//depreciated			+'<SalesforcePricebookEntryId>{!PricebookEntry.Id}</SalesforcePricebookEntryId>'
//depreciated			+'<SalesforceProduct2Id>{!Product.Id}</SalesforceProduct2Id>'
//depreciated			+'<RecordStatus>SUCCESS</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></Line>'
//depreciated			+'<Partner><Contact><SalesforceContactId>{!regionalContact.Id}</SalesforceContactId>'
//depreciated			+'<SalesforceContactRoleId>{!regionalOCR.Id}</SalesforceContactRoleId></Contact>'
//depreciated			+'<SalesforceAccountId>{!regionalAccount.Id}</SalesforceAccountId>'
//depreciated			+'<Id>0</Id>'
//depreciated			+'<SalesforceOpportunityPartnerId></SalesforceOpportunityPartnerId>'
//depreciated			+'<RecordStatus>ERROR</RecordStatus>'
//depreciated			+'<ErrorMessage>Failed to create Opportunity Partner: Unable to locate partner</ErrorMessage></Partner>'
//depreciated			+'<User><Id>0</Id>'
//depreciated			+'<SalesforceContactId>{!regionalContact.Id}</SalesforceContactId>'
//depreciated			+'<SalesforceContactRoleId>{!regionalOCR.Id}</SalesforceContactRoleId>'
//depreciated			+'<RecordStatus>RecordStatus</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></User></Subscription></Payload></SalesforceMessage>';
//depreciated		responseXML = cleanResponseXML(responseXML,idMap);
//depreciated		System.assert(expectedXML == responseXML,'Unexpected Response: '+responseXML+'\nnot '+expectedXML);

//depreciated		System.assertEquals((regionalAccount.Id+'   ').substring(0,3),(opp.AccountId+'   ').substring(0,3));
//depreciated		System.assertEquals(regionalAccount.Id,opp.AccountId);
//depreciated		System.assertEquals(0.00,opp.Amount);
//depreciated		System.assertEquals(null,opp.BillingAccountNumber__c);
//depreciated		System.assertEquals(regionalAccount.BillingStreet+'Address2',opp.BillingAddress__c);
//depreciated		System.assertEquals(regionalAccount.BillingCity,opp.BillingCity__c);
//depreciated		System.assertEquals(regionalAccount.BillingState,opp.BillingState__c);
//depreciated		System.assertEquals(regionalAccount.BillingCountry,opp.BillingCountry__c);
//depreciated		System.assertEquals(regionalAccount.BillingPostalCode,opp.BillingZipPostalCode__c);
//depreciated		System.assertEquals(CAMPAIGN.Id,opp.CampaignId);
//depreciated		System.assertNotEquals(Date.newInstance(2002,02,01),opp.CloseDate);
//depreciated		System.assertEquals(regionalAccount.OracleAccountNumber__c,opp.ContractNumber__c);
//depreciated		System.assertEquals(Date.newInstance(2002,03,02),opp.ContractStartDate__c);
//depreciated		System.assertEquals(Date.newInstance(2003,03,01),opp.ContractEndDate__c);
//depreciated		System.assertEquals(regionalOpportunity.Country_Of_Order__c,opp.Country_of_Order__c);
//depreciated		System.assertEquals('None',opp.CrossRegionalCreditCheck__c);
//depreciated		System.assertEquals(regionalOpportunity.CurrencyIsoCode,opp.CurrencyIsoCode);
//depreciated		String orderNumber = null;
//depreciated		System.assertEquals(
//depreciated			'Partner Contact: '+regionalContact.Name
//depreciated			+'\nPartner Email: '+regionalContact.Email
//depreciated			+'\nPartner Phone: '+regionalContact.Phone
//depreciated			+'\n\nOrder Number: '+orderNumber
//depreciated			+'\nContract Number: 12345\nPO Number: TEST_PO_NUMBER\n\nOrder Number: OrderNumber\nContract Number: ContractNumber\nPO Number: TEST_PO_NUMBER',opp.Description);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products_Total_Amount_RollUp__c);
//depreciated		System.assertEquals('Indirect - VAR/VAD',opp.FulfillmentChannel__c);
//depreciated		System.assertEquals('LeadSourceDetail',opp.LeadSourceDetail__c);
//depreciated		System.assertEquals('PartyName',opp.NA_Reseller__c);
//depreciated		System.assertEquals('Red Hat - Renewal - Service Contract #12345, ContractNumber',opp.Name);
//depreciated		System.assertEquals('Co-Term',opp.OpportunityType__c);
//depreciated		System.assertEquals('005',(opp.OwnerId+'   ').substring(0,3));
//depreciated		System.assertEquals('Yes',opp.Pay_Now__c);
//depreciated		System.assertEquals('EMEA Purchase Order',opp.PaymentType__c);
//depreciated		System.assertEquals(null,opp.PONumber__c);
//depreciated		System.assertEquals(null,opp.Primary_Partner__c);
//depreciated		System.assertEquals('012',(opp.RecordTypeId+'   ').substring(0,3));
//depreciated		System.assertEquals('true',''+opp.Renewal_Opportunity__c);
//depreciated		System.assertEquals('No',opp.Renewable__c);
//depreciated		System.assertEquals('PartyName',opp.Reseller__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.Reseller_PO__c);
//depreciated		System.assertEquals(regionalAccount.ShippingStreet+'Address2',opp.ShippingAddress__c);
//depreciated		System.assertEquals(regionalAccount.ShippingCity,opp.ShippingCity__c);
//depreciated		System.assertEquals(regionalAccount.ShippingState,opp.ShippingState__c);
//depreciated		System.assertEquals(regionalAccount.ShippingCountry,opp.ShippingCountry__c);
//depreciated		System.assertEquals(regionalAccount.ShippingPostalCode,opp.ShippingZipPostalCode__c);
//depreciated		System.assertEquals('Propose',opp.StageName);
//depreciated		System.assertEquals('true',''+opp.Touched__c);
//depreciated		System.assertEquals(null,opp.Year1PaymentAmount__c);

//depreciated		System.assertEquals(1,opp.Expiring_Products__r.size());
//depreciated		System.assertEquals(Date.newInstance(2002,03,01),+opp.Expiring_Products__r[0].Expiring_Product_End_Date__c);
//depreciated		System.assertEquals('0',opp.Expiring_Products__r[0].Expiring_Contract_Number__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.Expiring_Products__r[0].Expiring_Contract_PO_Number__c);
//depreciated		System.assertEquals(Date.newInstance(2001,03,01),+opp.Expiring_Products__r[0].Expiring_Product_Start_Date__c);
//depreciated		System.assertEquals('0',opp.Expiring_Products__r[0].Expiring_Oracle_Order_Number__c);
//depreciated		System.assertEquals('USD',opp.Expiring_Products__r[0].CurrencyIsoCode);
//depreciated		System.assertEquals('false',''+opp.Expiring_Products__r[0].Co_Term__c);
//depreciated		System.assertEquals('false',''+opp.Expiring_Products__r[0].Already_Renewed__c);
//depreciated		System.assertEquals('006',(opp.Expiring_Products__r[0].Opportunity__c+'   ').substring(0,3));
//depreciated		System.assertEquals('HFB007',opp.Expiring_Products__r[0].Product_Code__c);
//depreciated		System.assertEquals(2,opp.Expiring_Products__r[0].Quantity__c);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products__r[0].Sales_Price__c);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products__r[0].Total_Price_Formula__c);
//depreciated		System.assertEquals('FulfilledItemDescription',opp.Expiring_Products__r[0].Name);
//depreciated		System.assertEquals('ConfiguredItemDescription',opp.Expiring_Products__r[0].Mapped_Description__c);
//depreciated		System.assertEquals('01t',(opp.Expiring_Products__r[0].Product__c+'   ').substring(0,3));

//depreciated		// Really we should just have 1.  It is a bug that we have two duplicates...
//depreciated		System.assertEquals(2,opp.OpportunityContactRoles.size());
//depreciated		System.assertEquals('003',(opp.OpportunityContactRoles[0].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example@example.org',opp.OpportunityContactRoles[0].Contact.Email);
//depreciated		System.assertEquals('Shipping Contact',opp.OpportunityContactRoles[0].Role);
//depreciated		System.assertEquals('003',(opp.OpportunityContactRoles[1].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example@example.org',opp.OpportunityContactRoles[1].Contact.Email);
//depreciated		System.assertEquals('Shipping Contact',opp.OpportunityContactRoles[1].Role);

//depreciated		System.assertEquals(1,opp.OpportunityLineItems.size());
//depreciated		System.assertEquals(Date.newInstance(2003,03,01),+opp.OpportunityLineItems[0].ActualEndDate__c);
//depreciated		System.assertEquals(Date.newInstance(2002,03,02),+opp.OpportunityLineItems[0].ActualStartDate__c);
//depreciated		System.assertEquals('01u',(opp.OpportunityLineItems[0].PricebookEntryId+'   ').substring(0,3));
//depreciated		System.assertEquals('Renewal',opp.OpportunityLineItems[0].NewOrRenewal__c);
//depreciated		System.assertEquals(2.00,opp.OpportunityLineItems[0].Quantity);
//depreciated		System.assertEquals('true',''+opp.OpportunityLineItems[0].ScheduleLocked__c);
//depreciated		System.assertEquals('0',opp.OpportunityLineItems[0].Contract_Numbers__c);
//depreciated		System.assertEquals(null,+opp.OpportunityLineItems[0].Configured_SKU__c);
//depreciated		System.assertEquals(0.00,opp.OpportunityLineItems[0].UnitPrice);
//depreciated		System.assertEquals('ConfiguredItemDescription',opp.OpportunityLineItems[0].Description);

//depreciated		System.assertEquals(0,opp.OpportunityPartners2__r.size());

//depreciated		System.assertEquals(1,campaignMembers.size());
//depreciated		System.assertEquals(CAMPAIGN.Id,campaignMembers[0].CampaignId);
//depreciated		System.assertEquals('003',(campaignMembers[0].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example@example.org',''+campaignMembers[0].Contact.Email);
//depreciated	}

//depreciated	@isTest
//depreciated	static void testCreateRenewalOpportunityLATAM()
//depreciated	{
//depreciated		//
//depreciated		// create the object hierarchy for LATAM
//depreciated		//

//depreciated		Account regionalAccount = new Account(
//depreciated			BillingCity = 'Raleigh',
//depreciated			BillingCountry = 'US',
//depreciated			BillingPostalCode = '27606',
//depreciated			BillingState = 'North Carolina',
//depreciated			BillingStreet = '1801 Varsity Drive',
//depreciated			Name = 'Red Hat',
//depreciated			OracleAccountNumber__c = '12345',
//depreciated			OwnerId = [SELECT Id FROM User WHERE email LIKE 'msilva@redhat.com%'].Id,
//depreciated			RecordTypeId = '0126000000053LRAAY',
//depreciated			ShippingCity = 'Raleigh',
//depreciated			ShippingCountry = 'BR',
//depreciated			ShippingPostalCode = '27606',
//depreciated			ShippingState = 'North Carolina',
//depreciated			ShippingStreet = '1801 Varsity Drive',
//depreciated			VATNumber__c = '67890');
//depreciated		insert regionalAccount;

//depreciated		Contact regionalContact = createContact(regionalAccount.Id);

//depreciated		Opportunity regionalOpportunity = new Opportunity(
//depreciated			AccountId = regionalAccount.Id,
//depreciated			CloseDate = Date.newInstance(2009, 11, 10),
//depreciated			Country_Of_Order__c = 'US',
//depreciated			CurrencyIsoCode = 'USD',
//depreciated			Name = 'regionalOpportunity',
//depreciated			OpportunityType__c = 'Standard',
//depreciated			PaymentType__c = 'LATAM Purchase Order',
//depreciated			PONumber__c = 'TEST_PO_NUMBER',
//depreciated			Pricebook2Id = GLOBAL_PRICEBOOK.Id,
//depreciated			RecordTypeId = '012600000004ufHAAQ',
//depreciated			StageName = 'PREPARE',
//depreciated			Touched__c = true);
//depreciated		insert regionalOpportunity;

//depreciated		OpportunityContactRole regionalOCR = new OpportunityContactRole(
//depreciated			Role = 'TEST_ROLE',
//depreciated			ContactId = regionalContact.Id,
//depreciated			OpportunityId = regionalOpportunity.Id);
//depreciated		insert regionalOCR;

//depreciated		OpportunityLineItem regionalLineItem = createOpportunityLineItem(regionalOpportunity.Id,2009);

//depreciated		String regionalMessage = '<?xml version="1.0" encoding="UTF-8"?>' +
//depreciated			'<SalesforceMessage xmlns="http://salesforce.redhat.com/renewals"' +
//depreciated			'		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' +
//depreciated			'		xsi:schemaLocation="http://salesforce.redhat.com/renewals Renewals.xsd ">' +
//depreciated			'	<Header>' +
//depreciated			'		<Operation>Operation</Operation>' +
//depreciated			'		<Type>Type</Type>' +
//depreciated			'		<InstanceId>InstanceId</InstanceId>' +
//depreciated			'		<Timestamp>2011-02-10</Timestamp>' +
//depreciated			'	</Header>' +
//depreciated			'	<Payload>' +
//depreciated			'		<Subscription>' +
//depreciated			'			<Id>0</Id>' +
//depreciated			'			<OrderId>0</OrderId>' +
//depreciated			'			<OrderNumber></OrderNumber>' +
//depreciated			'			<ContractId>0</ContractId>' +
//depreciated			'			<ContractNumber>12345</ContractNumber>' +
//depreciated			'			<ContractStatusCode>ContractStatusCode</ContractStatusCode>' +
//depreciated			'			<ContractStartDate>2010-01-01</ContractStartDate>' +
//depreciated			'			<ContractEndDate>2011-01-01</ContractEndDate>' +
//depreciated			'			<CurrencyIsoCode>' + regionalOpportunity.CurrencyIsoCode + '</CurrencyIsoCode>' +
//depreciated			'			<ContractAmount>0.0</ContractAmount>' +
//depreciated			'			<OrderSourceId>0</OrderSourceId>' +
//depreciated			'			<OrderSourceName>OrderSourceName</OrderSourceName>' +
//depreciated			'			<SalesRepOnOrder>SalesRepOnOrder</SalesRepOnOrder>' +
//depreciated			'			<OpportunityNumber></OpportunityNumber>' +
//depreciated			'			<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'			<OrderTypeId>0</OrderTypeId>' +
//depreciated			'			<OrderTypeName>OrderTypeName</OrderTypeName>' +
//depreciated			'			<CountryOfOrder>CountryOfOrder</CountryOfOrder>' +
//depreciated			'			<SalesChannelCode>SalesChannelCode</SalesChannelCode>' +
//depreciated			'			<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'			<BusinessUnitId>0</BusinessUnitId>' +
//depreciated			'			<BusinessUnitName>BusinessUnitName</BusinessUnitName>' +
//depreciated			'			<Region>LATAM</Region>' +
//depreciated			'			<AccountRecordType>AccountRecordType</AccountRecordType>' +
//depreciated			'			<AccountRecordTypeId>' + regionalAccount.RecordTypeId + '</AccountRecordTypeId>' +
//depreciated			'			<OpportunityRecordType>OpportunityRecordType</OpportunityRecordType>' +
//depreciated			'			<OpportunityRecordTypeId>' + regionalOpportunity.RecordTypeId + '</OpportunityRecordTypeId>' +
//depreciated			'			<SoldToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.AccountNumber + '</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.BillingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.BillingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.BillingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.BillingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.BillingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.Id + '</SalesforceAccountId>' +
//depreciated			'			</SoldToParty>' +
//depreciated			'			<ShipToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.AccountNumber + '</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.ShippingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.ShippingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.ShippingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.ShippingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.ShippingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			</ShipToParty>' +
//depreciated			'			<BillToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.AccountNumber + '</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.BillingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.BillingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.BillingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.BillingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.BillingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			</BillToParty>' +
//depreciated			'			<LeadSourceDetail>LeadSourceDetail</LeadSourceDetail>' +
//depreciated			'			<CampaignName>CampaignName</CampaignName>' +
//depreciated			'			<FiscalYear>0</FiscalYear>' +
//depreciated			'			<FiscalQuarter>0</FiscalQuarter>' +
//depreciated			'			<ExpiringProductsAmount>0.0</ExpiringProductsAmount>' +
//depreciated			'			<SalesRepOnAccount>SalesRepOnAccount</SalesRepOnAccount>' +
//depreciated			'			<SalesRepRoleOnAccount>SalesRepRoleOnAccount</SalesRepRoleOnAccount>' +
//depreciated			'			<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			<SalesforceExpiredProductId>SalesforceExpiredProductId</SalesforceExpiredProductId>' +
//depreciated			'			<SalesforceOpportunityId>' +  regionalOpportunity.Id + '</SalesforceOpportunityId>' +
//depreciated			'			<SalesforceAccountOwnerId>' + USER.id + '</SalesforceAccountOwnerId>' +
//depreciated			'			<SalesforceCampaignId>' + CAMPAIGN.Id + '</SalesforceCampaignId>' +
//depreciated			'			<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'			<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			<Line>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'				<OrderLineId>0</OrderLineId>' +
//depreciated			'				<OrderLineNumber>0</OrderLineNumber>' +
//depreciated			'				<ContractLineId>0</ContractLineId>' +
//depreciated			'				<ContractNumber>0</ContractNumber>' +
//depreciated			'				<ExternalId>0-0</ExternalId>' +
//depreciated			'				<OpportunityNumber></OpportunityNumber>' +
//depreciated			'				<OrderNumber>0</OrderNumber>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<PricingAttributes>PricingAttributes</PricingAttributes>' +
//depreciated			'				<OrderedItem>' + PRODUCT.ProductCode + '</OrderedItem>' +
//depreciated			'				<ProductLine>ProductLine</ProductLine>' +
//depreciated			'				<ConfiguredItem>RH0123456</ConfiguredItem>' +
//depreciated			'				<ConfiguredItemDescription>ConfiguredItemDescription</ConfiguredItemDescription>' +
//depreciated			'				<SubstituteItem></SubstituteItem>' +
//depreciated			'				<RenewalItem></RenewalItem>' +
//depreciated			'				<FulfilledItem>FulfilledItem</FulfilledItem>' +
//depreciated			'				<FulfilledItemDescription>FulfilledItemDescription</FulfilledItemDescription>' +
//depreciated			'				<UnitSellingPrice>0.0</UnitSellingPrice>' +
//depreciated			'				<ServiceStartDate>2001-03-01</ServiceStartDate>' +
//depreciated			'				<ServiceEndDate>2002-03-01</ServiceEndDate>' +
//depreciated			'				<OrderedQuantity>' + regionalLineItem.Quantity + '</OrderedQuantity>' +
//depreciated			'				<TotalPrice>0.0</TotalPrice>' +
//depreciated			'				<CotermFlag>CotermFlag</CotermFlag>' +
//depreciated			'				<NfrFlag>NfrFlag</NfrFlag>' +
//depreciated			'				<RevenueAmount>0.0</RevenueAmount>' +
//depreciated			'				<FiscalYear>0</FiscalYear>' +
//depreciated			'				<FiscalQuarter>0</FiscalQuarter>' +
//depreciated			'				<SalesforceExpiringProductId>' + PRODUCT.Id + '</SalesforceExpiringProductId>' +
//depreciated			'				<SalesforceOpportunityId>' + regionalOpportunity.Id + '</SalesforceOpportunityId>' +
//depreciated			'				<SalesforceOpportunityLineId>' + regionalLineItem.Id+ '</SalesforceOpportunityLineId>' +
//depreciated			'				<SalesforcePricebookEntryId>' + PRICEBOOK_ENTRY.Id + '</SalesforcePricebookEntryId>' +
//depreciated			'				<SalesforceProduct2Id>' + PRODUCT.Id + '</SalesforceProduct2Id>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</Line>' +
//depreciated			'			<MergedSubscription>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<OrderId>0</OrderId>' +
//depreciated			'				<OrderNumber>OrderNumber</OrderNumber>' +
//depreciated			'				<ContractId>0</ContractId>' +
//depreciated			'				<ContractNumber>ContractNumber</ContractNumber>' +
//depreciated			'				<ContractStartDate>2004-05-01</ContractStartDate>' +
//depreciated			'				<ContractEndDate>2005-05-01</ContractEndDate>' +
//depreciated			'				<ContractAmount>0.0</ContractAmount>' +
//depreciated			'				<ExpiringProductsAmount>0</ExpiringProductsAmount>' +
//depreciated			'				<OpportunityNumber></OpportunityNumber>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'				<ExpiringProductAmount>0.0</ExpiringProductAmount>' +
//depreciated			'			</MergedSubscription>' +
//depreciated			'			<Partner>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>0</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>Address1</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>City</City>' +
//depreciated			'					<State>State</State>' +
//depreciated			'					<PostalCode>PostalCode</PostalCode>' +
//depreciated			'					<Country>Country</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.Id + '</SalesforceAccountId>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<ApId>0</ApId>' +
//depreciated			'				<PartnerType>PartnerType</PartnerType>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</Partner>' +
//depreciated			'			<User>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<UserType>UserType</UserType>' +
//depreciated			'				<UserId>0</UserId>' +
//depreciated			'				<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'				<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'				<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'				<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'				<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'				<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'				<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</User>' +
//depreciated			'		</Subscription>' +
//depreciated			'	</Payload>' +
//depreciated			'</SalesforceMessage>';

//depreciated		test.startTest();
//depreciated		String responseXML = OPPORTUNITY_RENEWAL.createRenewalOpportunity( regionalMessage );
//depreciated		test.stopTest();

//depreciated		Opportunity opp = queryOpportunity(regionalOpportunity.Id);
//depreciated		List<CampaignMember> campaignMembers = queryCampaignMembers(regionalOpportunity.Id);
//depreciated		Map<Id,String> idMap = getIdMap(opp,campaignMembers);
//depreciated		idMap.put(regionalAccount.Id,'{!regionalAccount.Id}');
//depreciated		idMap.put(regionalContact.Id,'{!regionalContact.Id}');
//depreciated		idMap.put(regionalOpportunity.Id,'{!regionalOpportunity.Id}');
//depreciated		idMap.put(regionalOCR.Id,'{!regionalOCR.Id}');
//depreciated		idMap.put(regionalLineItem.Id,'{!regionalLineItem.Id}');

//depreciated		String expectedXML = '<?xml version="1.0" encoding="UTF-8"?><SalesforceMessage xmlns=""><Header><Operation>Operation</Operation>'
//depreciated			+'<Type>Type</Type>'
//depreciated			+'<InstanceId>InstanceId</InstanceId>'
//depreciated			+'<Timestamp>2011-02-10</Timestamp>'
//depreciated			+'<ResponseTimeStamp>{!today}T..:..:..</ResponseTimeStamp></Header>'
//depreciated			+'<Payload><Subscription><Id>0</Id>'
//depreciated			+'<SalesRepOnAccount>...</SalesRepOnAccount>'
//depreciated			+'<SalesRepRoleOnAccount>...</SalesRepRoleOnAccount>'
//depreciated			+'<SalesforceAccountId>{!regionalAccount.Id}</SalesforceAccountId>'
//depreciated			+'<SalesforceOpportunityId>{!Opportunity.Id}</SalesforceOpportunityId>'
//depreciated			+'<SalesforceAccountOwnerId>{!Opportunity.OwnerId}</SalesforceAccountOwnerId>'
//depreciated			+'<RecordStatus>SUCCESS</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage>'
//depreciated			+'<Line><Id>0</Id>'
//depreciated			+'<ExternalId>0-0</ExternalId>'
//depreciated			+'<SalesforceExpiringProductId>{!Opportunity.Expiring_Products__r[0].Id}</SalesforceExpiringProductId>'
//depreciated			+'<SalesforceOpportunityLineId>{!OpportunityLineItems[0].Id}</SalesforceOpportunityLineId>'
//depreciated			+'<SalesforcePricebookEntryId>{!PricebookEntry.Id}</SalesforcePricebookEntryId>'
//depreciated			+'<SalesforceProduct2Id>{!Product.Id}</SalesforceProduct2Id>'
//depreciated			+'<RecordStatus>SUCCESS</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></Line>'
//depreciated			+'<Partner><Contact><SalesforceContactId>{!regionalContact.Id}</SalesforceContactId>'
//depreciated			+'<SalesforceContactRoleId>{!regionalOCR.Id}</SalesforceContactRoleId></Contact>'
//depreciated			+'<SalesforceAccountId>{!regionalAccount.Id}</SalesforceAccountId>'
//depreciated			+'<Id>0</Id>'
//depreciated			+'<SalesforceOpportunityPartnerId></SalesforceOpportunityPartnerId>'
//depreciated			+'<RecordStatus>ERROR</RecordStatus>'
//depreciated			+'<ErrorMessage>Failed to create Opportunity Partner: Unable to locate partner</ErrorMessage></Partner>'
//depreciated			+'<User><Id>0</Id>'
//depreciated			+'<SalesforceContactId>{!regionalContact.Id}</SalesforceContactId>'
//depreciated			+'<SalesforceContactRoleId>{!regionalOCR.Id}</SalesforceContactRoleId>'
//depreciated			+'<RecordStatus>RecordStatus</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></User></Subscription></Payload></SalesforceMessage>';
//depreciated		responseXML = cleanResponseXML(responseXML,idMap);
//depreciated		System.assert(expectedXML == responseXML,'Unexpected Response: '+responseXML);

//depreciated		System.assertEquals(regionalAccount.Id,opp.AccountId);
//depreciated		System.assertEquals(0.00,opp.Amount);
//depreciated		System.assertEquals(null,opp.BillingAccountNumber__c);
//depreciated		System.assertEquals(regionalAccount.BillingStreet+'Address2',opp.BillingAddress__c);
//depreciated		System.assertEquals(regionalAccount.BillingCity,opp.BillingCity__c);
//depreciated		System.assertEquals(regionalAccount.BillingState,opp.BillingState__c);
//depreciated		System.assertEquals(regionalAccount.BillingCountry,opp.BillingCountry__c);
//depreciated		System.assertEquals(regionalAccount.BillingPostalCode,opp.BillingZipPostalCode__c);
//depreciated		System.assertEquals(CAMPAIGN.Id,opp.CampaignId);
//depreciated		System.assertEquals(Date.newInstance(2002,03,01),opp.CloseDate);
//depreciated		System.assertEquals(regionalAccount.OracleAccountNumber__c,opp.ContractNumber__c);
//depreciated		System.assertEquals(Date.newInstance(2010,01,01),opp.ContractStartDate__c);
//depreciated		System.assertEquals(Date.newInstance(2011,01,01),opp.ContractEndDate__c);
//depreciated		System.assertEquals(regionalOpportunity.Country_Of_Order__c,opp.Country_of_Order__c);
//depreciated		System.assertEquals('None',opp.CrossRegionalCreditCheck__c);
//depreciated		System.assertEquals(regionalOpportunity.CurrencyIsoCode,opp.CurrencyIsoCode);
//depreciated		String orderNumber = null;
//depreciated		System.assertEquals(
//depreciated			'Partner Contact: '+regionalContact.Name
//depreciated			+'\nPartner Email: '+regionalContact.Email
//depreciated			+'\nPartner Phone: '+regionalContact.Phone
//depreciated			+'\n\nOrder Number: '+orderNumber
//depreciated			+'\nContract Number: 12345',opp.Description);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products_Total_Amount_RollUp__c);
//depreciated		System.assertEquals('Direct - End Customer',opp.FulfillmentChannel__c);
//depreciated		System.assertEquals('LeadSourceDetail',opp.LeadSourceDetail__c);
//depreciated		System.assertEquals('PartyName',opp.NA_Reseller__c);
//depreciated		System.assertEquals('Renewal - Red Hat - (12345)',opp.Name);
//depreciated		System.assertEquals('Co-Term',opp.OpportunityType__c);
//depreciated		System.assertNotEquals(null,opp.OwnerId);
//depreciated		System.assertEquals('Yes',opp.Pay_Now__c);
//depreciated		System.assertEquals(null,opp.PaymentType__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.PONumber__c);
//depreciated		System.assertEquals(null,opp.Primary_Partner__c);
//depreciated		System.assertNotEquals(null,opp.RecordTypeId);
//depreciated		System.assertEquals('true',''+opp.Renewal_Opportunity__c);
//depreciated		System.assertEquals('No',opp.Renewable__c);
//depreciated		System.assertEquals(null,opp.Reseller__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.Reseller_PO__c);
//depreciated		System.assertEquals(regionalAccount.ShippingStreet+'Address2',opp.ShippingAddress__c);
//depreciated		System.assertEquals(regionalAccount.ShippingCity,opp.ShippingCity__c);
//depreciated		System.assertEquals(regionalAccount.ShippingState,opp.ShippingState__c);
//depreciated		System.assertEquals(regionalAccount.ShippingCountry,opp.ShippingCountry__c);
//depreciated		System.assertEquals(regionalAccount.ShippingPostalCode,opp.ShippingZipPostalCode__c);
//depreciated		System.assertEquals('Engage',opp.StageName);
//depreciated		System.assertEquals('true',''+opp.Touched__c);
//depreciated		System.assertEquals(null,opp.Year1PaymentAmount__c);

//depreciated		System.assertEquals(1,opp.Expiring_Products__r.size());
//depreciated		System.assertEquals(Date.newInstance(2002,03,01),+opp.Expiring_Products__r[0].Expiring_Product_End_Date__c);
//depreciated		System.assertEquals('0',opp.Expiring_Products__r[0].Expiring_Contract_Number__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.Expiring_Products__r[0].Expiring_Contract_PO_Number__c);
//depreciated		System.assertEquals(Date.newInstance(2001,03,01),+opp.Expiring_Products__r[0].Expiring_Product_Start_Date__c);
//depreciated		System.assertEquals('0',opp.Expiring_Products__r[0].Expiring_Oracle_Order_Number__c);
//depreciated		System.assertEquals('USD',opp.Expiring_Products__r[0].CurrencyIsoCode);
//depreciated		System.assertEquals('false',''+opp.Expiring_Products__r[0].Co_Term__c);
//depreciated		System.assertEquals('false',''+opp.Expiring_Products__r[0].Already_Renewed__c);
//depreciated		System.assertEquals('006',(opp.Expiring_Products__r[0].Opportunity__c+'   ').substring(0,3));
//depreciated		System.assertEquals('HFB007',opp.Expiring_Products__r[0].Product_Code__c);
//depreciated		System.assertEquals(2,opp.Expiring_Products__r[0].Quantity__c);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products__r[0].Sales_Price__c);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products__r[0].Total_Price_Formula__c);
//depreciated		System.assertEquals('FulfilledItemDescription',opp.Expiring_Products__r[0].Name);
//depreciated		System.assertEquals('ConfiguredItemDescription',opp.Expiring_Products__r[0].Mapped_Description__c);
//depreciated		System.assertEquals('01t',(opp.Expiring_Products__r[0].Product__c+'   ').substring(0,3));

//depreciated		System.assertEquals(1,opp.OpportunityContactRoles.size());
//depreciated		System.assertEquals('003',(opp.OpportunityContactRoles[0].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example@example.org',opp.OpportunityContactRoles[0].Contact.Email);
//depreciated		System.assertEquals('Technical Buyer',opp.OpportunityContactRoles[0].Role);

//depreciated		System.assertEquals(1,opp.OpportunityLineItems.size());
//depreciated		System.assertEquals(Date.newInstance(2003,03,01),+opp.OpportunityLineItems[0].ActualEndDate__c);
//depreciated		System.assertEquals(Date.newInstance(2002,03,02),+opp.OpportunityLineItems[0].ActualStartDate__c);
//depreciated		System.assertEquals('01u',(opp.OpportunityLineItems[0].PricebookEntryId+'   ').substring(0,3));
//depreciated		System.assertEquals('Renewal',opp.OpportunityLineItems[0].NewOrRenewal__c);
//depreciated		System.assertEquals(2.00,opp.OpportunityLineItems[0].Quantity);
//depreciated		System.assertEquals('true',''+opp.OpportunityLineItems[0].ScheduleLocked__c);
//depreciated		System.assertEquals('0',opp.OpportunityLineItems[0].Contract_Numbers__c);
//depreciated		System.assertEquals(null,+opp.OpportunityLineItems[0].Configured_SKU__c);
//depreciated		System.assertEquals(0.00,opp.OpportunityLineItems[0].UnitPrice);
//depreciated		System.assertEquals('ConfiguredItemDescription',opp.OpportunityLineItems[0].Description);

//depreciated		System.assertEquals(0,opp.OpportunityPartners2__r.size());

//depreciated		System.assertEquals(1,campaignMembers.size());
//depreciated		System.assertEquals(CAMPAIGN.Id,campaignMembers[0].CampaignId);
//depreciated		System.assertEquals('003',(campaignMembers[0].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example@example.org',''+campaignMembers[0].Contact.Email);
//depreciated	}


//depreciated	@isTest
//depreciated	static void testCreateRenewalOpportunityJAPAN()
//depreciated	{
//depreciated		//
//depreciated		// create the object hierarchy for JAPAN
//depreciated		//

//depreciated		Account regionalAccount = new Account(
//depreciated			BillingCity = 'Tokyo',
//depreciated			BillingCountry = 'JP',
//depreciated			BillingPostalCode = '150-0013',
//depreciated			BillingState = 'Shibuya-ku',
//depreciated			BillingStreet = 'Ebisu Neonato 8F 1-18 Ebisu 4-chome',
//depreciated			Name = 'Red Hat K.K.',
//depreciated			OracleAccountNumber__c = '12345',
//depreciated			RecordTypeId = '012300000000QglAAE',
//depreciated			ShippingCity = 'Tokyo',
//depreciated			ShippingCountry = 'JP',
//depreciated			ShippingPostalCode = '150-0013',
//depreciated			ShippingState = 'Shibuya-ku',
//depreciated			ShippingStreet = 'Ebisu Neonato 8F 1-18 Ebisu 4-chome',
//depreciated			VATNumber__c = '67890');
//depreciated		insert regionalAccount;

//depreciated		Contact regionalContact = createContact(regionalAccount.Id);

//depreciated		Opportunity regionalOpportunity = new Opportunity(
//depreciated			AccountId = regionalAccount.Id,
//depreciated			CloseDate = Date.newInstance(2009, 11, 10),
//depreciated			Country_Of_Order__c = 'JP',
//depreciated			CurrencyIsoCode = 'USD',
//depreciated			Name = 'regionalOpportunity',
//depreciated			OpportunityType__c = 'Standard',
//depreciated			PaymentType__c = 'JAPAN Purchase Order',
//depreciated			PONumber__c = 'TEST_PO_NUMBER',
//depreciated			Pricebook2Id = GLOBAL_PRICEBOOK.id,
//depreciated			RecordTypeId = '012300000000TVCAA2',
//depreciated			StageName = 'Prepare',
//depreciated			Touched__c = true);
//depreciated		insert regionalOpportunity;

//depreciated		OpportunityContactRole regionalOCR = new OpportunityContactRole(
//depreciated			Role = 'TEST_ROLE',
//depreciated			ContactId = regionalContact.Id,
//depreciated			OpportunityId = regionalOpportunity.Id);
//depreciated		insert regionalOCR;

//depreciated		OpportunityLineItem regionalLineItem = createOpportunityLineItem(regionalOpportunity.Id,2009);

//depreciated		String regionalMessage = '<?xml version="1.0" encoding="UTF-8"?>' +
//depreciated			'<SalesforceMessage xmlns="http://salesforce.redhat.com/renewals"' +
//depreciated			'		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' +
//depreciated			'		xsi:schemaLocation="http://salesforce.redhat.com/renewals Renewals.xsd ">' +
//depreciated			'	<Header>' +
//depreciated			'		<Operation>Operation</Operation>' +
//depreciated			'		<Type>Type</Type>' +
//depreciated			'		<InstanceId>InstanceId</InstanceId>' +
//depreciated			'		<Timestamp>2011-02-10</Timestamp>' +
//depreciated			'	</Header>' +
//depreciated			'	<Payload>' +
//depreciated			'		<Subscription>' +
//depreciated			'			<Id>0</Id>' +
//depreciated			'			<OrderId>0</OrderId>' +
//depreciated			'			<OrderNumber></OrderNumber>' +
//depreciated			'			<ContractId>0</ContractId>' +
//depreciated			'			<ContractNumber>12345</ContractNumber>' +
//depreciated			'			<ContractStatusCode>ContractStatusCode</ContractStatusCode>' +
//depreciated			'			<ContractStartDate>2010-01-01</ContractStartDate>' +
//depreciated			'			<ContractEndDate>2011-01-01</ContractEndDate>' +
//depreciated			'			<CurrencyIsoCode>' + regionalOpportunity.CurrencyIsoCode + '</CurrencyIsoCode>' +
//depreciated			'			<ContractAmount>0.0</ContractAmount>' +
//depreciated			'			<OrderSourceId>0</OrderSourceId>' +
//depreciated			'			<OrderSourceName>OrderSourceName</OrderSourceName>' +
//depreciated			'			<SalesRepOnOrder>SalesRepOnOrder</SalesRepOnOrder>' +
//depreciated			'			<OpportunityNumber></OpportunityNumber>' +
//depreciated			'			<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'			<OrderTypeId>0</OrderTypeId>' +
//depreciated			'			<OrderTypeName>OrderTypeName</OrderTypeName>' +
//depreciated			'			<CountryOfOrder>CountryOfOrder</CountryOfOrder>' +
//depreciated			'			<SalesChannelCode>SalesChannelCode</SalesChannelCode>' +
//depreciated			'			<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'			<BusinessUnitId>0</BusinessUnitId>' +
//depreciated			'			<BusinessUnitName>BusinessUnitName</BusinessUnitName>' +
//depreciated			'			<Region>JAPAN</Region>' +
//depreciated			'			<AccountRecordType>AccountRecordType</AccountRecordType>' +
//depreciated			'			<AccountRecordTypeId>' + regionalAccount.RecordTypeId + '</AccountRecordTypeId>' +
//depreciated			'			<OpportunityRecordType>OpportunityRecordType</OpportunityRecordType>' +
//depreciated			'			<OpportunityRecordTypeId>' + regionalOpportunity.RecordTypeId + '</OpportunityRecordTypeId>' +
//depreciated			'			<SoldToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.AccountNumber + '</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.BillingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.BillingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.BillingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.BillingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.BillingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.Id + '</SalesforceAccountId>' +
//depreciated			'			</SoldToParty>' +
//depreciated			'			<ShipToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.AccountNumber + '</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.ShippingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.ShippingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.ShippingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.ShippingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.ShippingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			</ShipToParty>' +
//depreciated			'			<BillToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.AccountNumber + '</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.BillingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.BillingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.BillingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.BillingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.BillingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			</BillToParty>' +
//depreciated			'			<LeadSourceDetail>LeadSourceDetail</LeadSourceDetail>' +
//depreciated			'			<CampaignName>CampaignName</CampaignName>' +
//depreciated			'			<FiscalYear>0</FiscalYear>' +
//depreciated			'			<FiscalQuarter>0</FiscalQuarter>' +
//depreciated			'			<ExpiringProductsAmount>0.0</ExpiringProductsAmount>' +
//depreciated			'			<SalesRepOnAccount>SalesRepOnAccount</SalesRepOnAccount>' +
//depreciated			'			<SalesRepRoleOnAccount>SalesRepRoleOnAccount</SalesRepRoleOnAccount>' +
//depreciated			'			<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			<SalesforceExpiredProductId>SalesforceExpiredProductId</SalesforceExpiredProductId>' +
//depreciated			'			<SalesforceOpportunityId>' +  regionalOpportunity.Id + '</SalesforceOpportunityId>' +
//depreciated			'			<SalesforceAccountOwnerId>' + USER.id + '</SalesforceAccountOwnerId>' +
//depreciated			'			<SalesforceCampaignId>' + CAMPAIGN.Id + '</SalesforceCampaignId>' +
//depreciated			'			<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'			<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			<Line>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'				<OrderLineId>0</OrderLineId>' +
//depreciated			'				<OrderLineNumber>0</OrderLineNumber>' +
//depreciated			'				<ContractLineId>0</ContractLineId>' +
//depreciated			'				<ContractNumber>0</ContractNumber>' +
//depreciated			'				<ExternalId>0-0</ExternalId>' +
//depreciated			'				<OpportunityNumber></OpportunityNumber>' +
//depreciated			'				<OrderNumber>0</OrderNumber>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<PricingAttributes>PricingAttributes</PricingAttributes>' +
//depreciated			'				<OrderedItem></OrderedItem>' +
//depreciated			'				<ProductLine>ProductLine</ProductLine>' +
//depreciated			'				<ConfiguredItem>RH0123456</ConfiguredItem>' +
//depreciated			'				<ConfiguredItemDescription>ConfiguredItemDescription</ConfiguredItemDescription>' +
//depreciated			'				<SubstituteItem></SubstituteItem>' +
//depreciated			'				<RenewalItem>' + PRODUCT.ProductCode + '</RenewalItem>' +
//depreciated			'				<FulfilledItem>FulfilledItem</FulfilledItem>' +
//depreciated			'				<FulfilledItemDescription>FulfilledItemDescription</FulfilledItemDescription>' +
//depreciated			'				<UnitSellingPrice>0.0</UnitSellingPrice>' +
//depreciated			'				<ServiceStartDate>2001-03-01</ServiceStartDate>' +
//depreciated			'				<ServiceEndDate>2002-03-01</ServiceEndDate>' +
//depreciated			'				<OrderedQuantity>' + regionalLineItem.Quantity + '</OrderedQuantity>' +
//depreciated			'				<TotalPrice>0.0</TotalPrice>' +
//depreciated			'				<CotermFlag>CotermFlag</CotermFlag>' +
//depreciated			'				<NfrFlag>NfrFlag</NfrFlag>' +
//depreciated			'				<RevenueAmount>0.0</RevenueAmount>' +
//depreciated			'				<FiscalYear>0</FiscalYear>' +
//depreciated			'				<FiscalQuarter>0</FiscalQuarter>' +
//depreciated			'				<SalesforceExpiringProductId>' + PRODUCT.Id + '</SalesforceExpiringProductId>' +
//depreciated			'				<SalesforceOpportunityId>' + regionalOpportunity.Id + '</SalesforceOpportunityId>' +
//depreciated			'				<SalesforceOpportunityLineId>' + regionalLineItem.Id+ '</SalesforceOpportunityLineId>' +
//depreciated			'				<SalesforcePricebookEntryId>' + PRICEBOOK_ENTRY.Id + '</SalesforcePricebookEntryId>' +
//depreciated			'				<SalesforceProduct2Id>' + PRODUCT.Id + '</SalesforceProduct2Id>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</Line>' +
//depreciated			'			<MergedSubscription>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<OrderId>0</OrderId>' +
//depreciated			'				<OrderNumber>OrderNumber</OrderNumber>' +
//depreciated			'				<ContractId>0</ContractId>' +
//depreciated			'				<ContractNumber>ContractNumber</ContractNumber>' +
//depreciated			'				<ContractStartDate>2004-05-01</ContractStartDate>' +
//depreciated			'				<ContractEndDate>2005-05-01</ContractEndDate>' +
//depreciated			'				<ContractAmount>0.0</ContractAmount>' +
//depreciated			'				<ExpiringProductsAmount>0</ExpiringProductsAmount>' +
//depreciated			'				<OpportunityNumber></OpportunityNumber>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'				<ExpiringProductAmount>0.0</ExpiringProductAmount>' +
//depreciated			'			</MergedSubscription>' +
//depreciated			'			<Partner>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>0</AccountNumber>' +
//depreciated			'				<PartyId>0</PartyId>' +
//depreciated			'				<PartyNumber>0</PartyNumber>' +
//depreciated			'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>Address1</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>City</City>' +
//depreciated			'					<State>State</State>' +
//depreciated			'					<PostalCode>PostalCode</PostalCode>' +
//depreciated			'					<Country>Country</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.Id + '</SalesforceAccountId>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<ApId>0</ApId>' +
//depreciated			'				<PartnerType>PartnerType</PartnerType>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</Partner>' +
//depreciated			'			<User>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<UserType>UserType</UserType>' +
//depreciated			'				<UserId>0</UserId>' +
//depreciated			'				<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'				<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'				<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'				<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'				<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'				<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'				<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</User>' +
//depreciated			'		</Subscription>' +
//depreciated			'	</Payload>' +
//depreciated			'</SalesforceMessage>';

//depreciated		test.startTest();
//depreciated		String responseXML = OPPORTUNITY_RENEWAL.createRenewalOpportunity( regionalMessage );
//depreciated		test.stopTest();

//depreciated		Opportunity opp = queryOpportunity(regionalOpportunity.Id);
//depreciated		List<CampaignMember> campaignMembers = queryCampaignMembers(regionalOpportunity.Id);
//depreciated		Map<Id,String> idMap = getIdMap(opp,campaignMembers);
//depreciated		idMap.put(regionalAccount.Id,'{!regionalAccount.Id}');
//depreciated		idMap.put(regionalContact.Id,'{!regionalContact.Id}');
//depreciated		idMap.put(regionalOpportunity.Id,'{!regionalOpportunity.Id}');
//depreciated		idMap.put(regionalOCR.Id,'{!regionalOCR.Id}');
//depreciated		idMap.put(regionalLineItem.Id,'{!regionalLineItem.Id}');

//depreciated		String expectedXML = '<?xml version="1.0" encoding="UTF-8"?><SalesforceMessage xmlns=""><Header><Operation>Operation</Operation>'
//depreciated			+'<Type>Type</Type>'
//depreciated			+'<InstanceId>InstanceId</InstanceId>'
//depreciated			+'<Timestamp>2011-02-10</Timestamp>'
//depreciated			+'<ResponseTimeStamp>{!today}T..:..:..</ResponseTimeStamp></Header>'
//depreciated			+'<Payload><Subscription><Id>0</Id>'
//depreciated			+'<SalesRepOnAccount>...</SalesRepOnAccount>'
//depreciated			+'<SalesRepRoleOnAccount>...</SalesRepRoleOnAccount>'
//depreciated			+'<SalesforceAccountId>{!regionalAccount.Id}</SalesforceAccountId>'
//depreciated			+'<SalesforceOpportunityId>{!Opportunity.Id}</SalesforceOpportunityId>'
//depreciated			+'<SalesforceAccountOwnerId>{!Opportunity.OwnerId}</SalesforceAccountOwnerId>'
//depreciated			+'<RecordStatus>SUCCESS</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage>'
//depreciated			+'<Line><Id>0</Id>'
//depreciated			+'<ExternalId>0-0</ExternalId>'
//depreciated			+'<SalesforceExpiringProductId>{!Opportunity.Expiring_Products__r[0].Id}</SalesforceExpiringProductId>'
//depreciated			+'<SalesforceOpportunityLineId>{!OpportunityLineItems[0].Id}</SalesforceOpportunityLineId>'
//depreciated			+'<SalesforcePricebookEntryId>{!PricebookEntry.Id}</SalesforcePricebookEntryId>'
//depreciated			+'<SalesforceProduct2Id>{!Product.Id}</SalesforceProduct2Id>'
//depreciated			+'<RecordStatus>SUCCESS</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></Line>'
//depreciated			+'<Partner><Contact><SalesforceContactId>{!regionalContact.Id}</SalesforceContactId>'
//depreciated			+'<SalesforceContactRoleId>{!regionalOCR.Id}</SalesforceContactRoleId></Contact>'
//depreciated			+'<SalesforceAccountId>{!regionalAccount.Id}</SalesforceAccountId>'
//depreciated			+'<Id>0</Id>'
//depreciated			+'<SalesforceOpportunityPartnerId></SalesforceOpportunityPartnerId>'
//depreciated			+'<RecordStatus>ERROR</RecordStatus>'
//depreciated			+'<ErrorMessage>Failed to create Opportunity Partner: Unable to locate partner</ErrorMessage></Partner>'
//depreciated			+'<User><Id>0</Id>'
//depreciated			+'<SalesforceContactId>{!regionalContact.Id}</SalesforceContactId>'
//depreciated			+'<SalesforceContactRoleId>{!regionalOCR.Id}</SalesforceContactRoleId>'
//depreciated			+'<RecordStatus>RecordStatus</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></User></Subscription></Payload></SalesforceMessage>';
//depreciated		responseXML = cleanResponseXML(responseXML,idMap);
//depreciated		System.assert(expectedXML == responseXML,'Unexpected Response: '+responseXML);

//depreciated		System.assertEquals(regionalAccount.Id,opp.AccountId);
//depreciated		System.assertEquals(0.00,opp.Amount);
//depreciated		System.assertEquals(null,opp.BillingAccountNumber__c);
//depreciated		System.assertEquals(regionalAccount.BillingStreet+'Address2',opp.BillingAddress__c);
//depreciated		System.assertEquals(null,opp.BillingCity__c);
//depreciated		System.assertEquals(regionalAccount.BillingCity,opp.BillingState__c);
//depreciated		System.assertEquals(regionalAccount.BillingCountry,opp.BillingCountry__c);
//depreciated		System.assertEquals(regionalAccount.BillingPostalCode,opp.BillingZipPostalCode__c);
//depreciated		System.assertEquals(CAMPAIGN.Id,opp.CampaignId);
//depreciated		System.assertEquals(Date.newInstance(2002,03,01),opp.CloseDate);
//depreciated		System.assertEquals(regionalAccount.OracleAccountNumber__c,opp.ContractNumber__c);
//depreciated		System.assertEquals(Date.newInstance(2010,01,01),opp.ContractStartDate__c);
//depreciated		System.assertEquals(Date.newInstance(2011,01,01),opp.ContractEndDate__c);
//depreciated		System.assertEquals(regionalOpportunity.Country_Of_Order__c,opp.Country_of_Order__c);
//depreciated		System.assertEquals('None',opp.CrossRegionalCreditCheck__c);
//depreciated		System.assertEquals(regionalOpportunity.CurrencyIsoCode,opp.CurrencyIsoCode);
//depreciated		String orderNumber = null;
//depreciated		System.assertEquals(
//depreciated			'Partner Contact: '+regionalContact.Name
//depreciated			+'\nPartner Email: '+regionalContact.Email
//depreciated			+'\nPartner Phone: '+regionalContact.Phone
//depreciated			+'\n\nOrder Number: '+orderNumber
//depreciated			+'\nContract Number: 12345',opp.Description);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products_Total_Amount_RollUp__c);
//depreciated		System.assertEquals('Direct - End Customer',opp.FulfillmentChannel__c);
//depreciated		System.assertEquals('LeadSourceDetail',opp.LeadSourceDetail__c);
//depreciated		System.assertEquals('PartyName',opp.NA_Reseller__c);
//depreciated		System.assertEquals('Renewal Red Hat K.K. Service Contract #12345',opp.Name);
//depreciated		System.assertEquals('Co-Term',opp.OpportunityType__c);
//depreciated		System.assertNotEquals(null,opp.OwnerId);
//depreciated		System.assertEquals('Yes',opp.Pay_Now__c);
//depreciated		System.assertEquals(null,opp.PaymentType__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.PONumber__c);
//depreciated		System.assertEquals(null,opp.Primary_Partner__c);
//depreciated		System.assertNotEquals(null,opp.RecordTypeId);
//depreciated		System.assertEquals('true',''+opp.Renewal_Opportunity__c);
//depreciated		System.assertEquals('No',opp.Renewable__c);
//depreciated		System.assertEquals('PartyName',opp.Reseller__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.Reseller_PO__c);
//depreciated		System.assertEquals(regionalAccount.ShippingStreet+'Address2',opp.ShippingAddress__c);
//depreciated		System.assertEquals(null,opp.ShippingCity__c);
//depreciated		System.assertEquals(regionalAccount.ShippingCity,opp.ShippingState__c);
//depreciated		System.assertEquals(regionalAccount.ShippingCountry,opp.ShippingCountry__c);
//depreciated		System.assertEquals(regionalAccount.ShippingPostalCode,opp.ShippingZipPostalCode__c);
//depreciated		System.assertEquals('Engage',opp.StageName);
//depreciated		System.assertEquals('true',''+opp.Touched__c);
//depreciated		System.assertEquals(null,opp.Year1PaymentAmount__c);

//depreciated		System.assertEquals(1,opp.Expiring_Products__r.size());
//depreciated		System.assertEquals(Date.newInstance(2002,03,01),+opp.Expiring_Products__r[0].Expiring_Product_End_Date__c);
//depreciated		System.assertEquals('0',opp.Expiring_Products__r[0].Expiring_Contract_Number__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.Expiring_Products__r[0].Expiring_Contract_PO_Number__c);
//depreciated		System.assertEquals(Date.newInstance(2001,03,01),+opp.Expiring_Products__r[0].Expiring_Product_Start_Date__c);
//depreciated		System.assertEquals('0',opp.Expiring_Products__r[0].Expiring_Oracle_Order_Number__c);
//depreciated		System.assertEquals('USD',opp.Expiring_Products__r[0].CurrencyIsoCode);
//depreciated		System.assertEquals('false',''+opp.Expiring_Products__r[0].Co_Term__c);
//depreciated		System.assertEquals('false',''+opp.Expiring_Products__r[0].Already_Renewed__c);
//depreciated		System.assertEquals('006',(opp.Expiring_Products__r[0].Opportunity__c+'   ').substring(0,3));
//depreciated		// Is this a bug?
//depreciated		System.assertEquals(null,opp.Expiring_Products__r[0].Product_Code__c);
//depreciated		System.assertEquals(2,opp.Expiring_Products__r[0].Quantity__c);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products__r[0].Sales_Price__c);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products__r[0].Total_Price_Formula__c);
//depreciated		System.assertEquals('FulfilledItemDescription',opp.Expiring_Products__r[0].Name);
//depreciated		System.assertEquals('ConfiguredItemDescription',opp.Expiring_Products__r[0].Mapped_Description__c);
//depreciated		System.assertEquals('01t',(opp.Expiring_Products__r[0].Product__c+'   ').substring(0,3));

//depreciated		// Hmmm.
//depreciated		System.assertEquals(0,opp.OpportunityContactRoles.size());

//depreciated		System.assertEquals(1,opp.OpportunityLineItems.size());
//depreciated		System.assertEquals(Date.newInstance(2003,03,01),+opp.OpportunityLineItems[0].ActualEndDate__c);
//depreciated		System.assertEquals(Date.newInstance(2002,03,02),+opp.OpportunityLineItems[0].ActualStartDate__c);
//depreciated		System.assertEquals('01u',(opp.OpportunityLineItems[0].PricebookEntryId+'   ').substring(0,3));
//depreciated		System.assertEquals('Renewal',opp.OpportunityLineItems[0].NewOrRenewal__c);
//depreciated		System.assertEquals(2.00,opp.OpportunityLineItems[0].Quantity);
//depreciated		System.assertEquals('true',''+opp.OpportunityLineItems[0].ScheduleLocked__c);
//depreciated		System.assertEquals('0',opp.OpportunityLineItems[0].Contract_Numbers__c);
//depreciated		System.assertEquals('HFB007',opp.OpportunityLineItems[0].Configured_SKU__c);
//depreciated		System.assertEquals(0.00,opp.OpportunityLineItems[0].UnitPrice);
//depreciated		System.assertEquals('ConfiguredItemDescription',opp.OpportunityLineItems[0].Description);

//depreciated		System.assertEquals(0,opp.OpportunityPartners2__r.size());

//depreciated		System.assertEquals(0,campaignMembers.size());
//depreciated	}

//depreciated	@isTest
//depreciated	static void testCreateRenewalOpportunityNA()
//depreciated	{
//depreciated		//
//depreciated		// create the object hierarchy for NA
//depreciated		//

//depreciated		Account regionalAccount = new Account(
//depreciated			BillingCity = 'Raleigh',
//depreciated			BillingCountry = 'US',
//depreciated			BillingPostalCode = '27606',
//depreciated			BillingState = 'North Carolina',
//depreciated			BillingStreet = '1801 Varsity Drive',
//depreciated			Name = 'Red Hat',
//depreciated			OracleAccountNumber__c = '12345',
//depreciated			RecordTypeId = '012300000000NBGAA2',
//depreciated			ShippingCity = 'Raleigh',
//depreciated			ShippingCountry = 'US',
//depreciated			ShippingPostalCode = '27606',
//depreciated			ShippingState = 'North Carolina',
//depreciated			ShippingStreet = '1801 Varsity Drive',
//depreciated			VATNumber__c = '67890');
//depreciated		insert regionalAccount;

//depreciated		Contact regionalContact = createContact(regionalAccount.Id);

//depreciated		Opportunity regionalOpportunity = new Opportunity(
//depreciated			AccountId = regionalAccount.Id,
//depreciated			CloseDate = Date.newInstance(2009, 11, 10),
//depreciated			Country_Of_Order__c = 'US',
//depreciated			CurrencyIsoCode = 'USD',
//depreciated			FulfillmentChannel__c = 'Indirect - VAR/VAD',
//depreciated			Name = 'regionalOpportunity',
//depreciated			OpportunityType__c = 'Standard',
//depreciated			PaymentType__c = 'NA Purchase Order',
//depreciated			PONumber__c = 'TEST_PO_NUMBER',
//depreciated			Pricebook2Id = GLOBAL_PRICEBOOK.id,
//depreciated			RecordTypeId = '012300000000TVDAA2',
//depreciated			StageName = 'Test Stage',
//depreciated			Touched__c = true);
//depreciated		insert regionalOpportunity;

//depreciated		OpportunityContactRole regionalOCR = new OpportunityContactRole(
//depreciated			Role = 'TEST_ROLE',
//depreciated			ContactId = regionalContact.Id,
//depreciated			OpportunityId = regionalOpportunity.Id);
//depreciated		insert regionalOCR;

//depreciated		OpportunityLineItem regionalLineItem = createOpportunityLineItem(regionalOpportunity.Id,2010);

//depreciated		String regionalMessage = '<?xml version="1.0" encoding="UTF-8"?>' +
//depreciated			'<SalesforceMessage xmlns="http://salesforce.redhat.com/renewals"' +
//depreciated			'		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' +
//depreciated			'		xsi:schemaLocation="http://salesforce.redhat.com/renewals Renewals.xsd ">' +
//depreciated			'	<Header>' +
//depreciated			'		<Operation>Operation</Operation>' +
//depreciated			'		<Type>Type</Type>' +
//depreciated			'		<InstanceId>InstanceId</InstanceId>' +
//depreciated			'		<Timestamp>2011-02-10</Timestamp>' +
//depreciated			'	</Header>' +
//depreciated			'	<Payload>' +
//depreciated			'		<Subscription>' +
//depreciated			'			<Id>0</Id>' +
//depreciated			'			<OrderId>0</OrderId>' +
//depreciated			'			<OrderNumber></OrderNumber>' +
//depreciated			'			<ContractId>0</ContractId>' +
//depreciated			'			<ContractNumber>12345</ContractNumber>' +
//depreciated			'			<ContractStatusCode>ContractStatusCode</ContractStatusCode>' +
//depreciated			'			<ContractStartDate>2010-01-01</ContractStartDate>' +
//depreciated			'			<ContractEndDate>2011-01-01</ContractEndDate>' +
//depreciated			'			<CurrencyIsoCode>' + regionalOpportunity.CurrencyIsoCode + '</CurrencyIsoCode>' +
//depreciated			'			<ContractAmount>0.0</ContractAmount>' +
//depreciated			'			<OrderSourceId>0</OrderSourceId>' +
//depreciated			'			<OrderSourceName>OrderSourceName</OrderSourceName>' +
//depreciated			'			<SalesRepOnOrder>SalesRepOnOrder</SalesRepOnOrder>' +
//depreciated			'			<OpportunityNumber></OpportunityNumber>' +
//depreciated			'			<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'			<OrderTypeId>0</OrderTypeId>' +
//depreciated			'			<OrderTypeName>OrderTypeName</OrderTypeName>' +
//depreciated			'			<CountryOfOrder>CountryOfOrder</CountryOfOrder>' +
//depreciated			'			<SalesChannelCode>SalesChannelCode</SalesChannelCode>' +
//depreciated			'			<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'			<BusinessUnitId>0</BusinessUnitId>' +
//depreciated			'			<BusinessUnitName>BusinessUnitName</BusinessUnitName>' +
//depreciated			'			<Region>NA</Region>' +
//depreciated			'			<AccountRecordType>AccountRecordType</AccountRecordType>' +
//depreciated			'			<AccountRecordTypeId>' + regionalAccount.RecordTypeId + '</AccountRecordTypeId>' +
//depreciated			'			<OpportunityRecordType>OpportunityRecordType</OpportunityRecordType>' +
//depreciated			'			<OpportunityRecordTypeId>' + regionalOpportunity.RecordTypeId + '</OpportunityRecordTypeId>' +
//depreciated			'			<SoldToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.AccountNumber + '</AccountNumber>' +
//depreciated			//'				<PartyId>0</PartyId>' +
//depreciated			//'				<PartyNumber>0</PartyNumber>' +
//depreciated			//'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.BillingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.BillingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.BillingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.BillingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.BillingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.Id + '</SalesforceAccountId>' +
//depreciated			'			</SoldToParty>' +
//depreciated			'			<ShipToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>' + regionalAccount.AccountNumber + '</AccountNumber>' +
//depreciated			//'				<PartyId>0</PartyId>' +
//depreciated			//'				<PartyNumber>0</PartyNumber>' +
//depreciated			//'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.ShippingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.ShippingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.ShippingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.ShippingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.ShippingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			</ShipToParty>' +
//depreciated			'			<BillToParty>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber></AccountNumber>' +
//depreciated			//'				<PartyId>0</PartyId>' +
//depreciated			//'				<PartyNumber>0</PartyNumber>' +
//depreciated			//'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>' + regionalAccount.BillingStreet + '</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>' + regionalAccount.BillingCity + '</City>' +
//depreciated			'					<State>' + regionalAccount.BillingState + '</State>' +
//depreciated			'					<PostalCode>' + regionalAccount.BillingPostalCode + '</PostalCode>' +
//depreciated			'					<Country>' + regionalAccount.BillingCountry + '</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			</BillToParty>' +
//depreciated			'			<LeadSourceDetail>LeadSourceDetail</LeadSourceDetail>' +
//depreciated			'			<CampaignName>CampaignName</CampaignName>' +
//depreciated			'			<FiscalYear>0</FiscalYear>' +
//depreciated			'			<FiscalQuarter>0</FiscalQuarter>' +
//depreciated			'			<ExpiringProductsAmount>0.0</ExpiringProductsAmount>' +
//depreciated			'			<SalesRepOnAccount>SalesRepOnAccount</SalesRepOnAccount>' +
//depreciated			'			<SalesRepRoleOnAccount>SalesRepRoleOnAccount</SalesRepRoleOnAccount>' +
//depreciated			'			<SalesforceAccountId>' + regionalAccount.id + '</SalesforceAccountId>' +
//depreciated			'			<SalesforceExpiredProductId>SalesforceExpiredProductId</SalesforceExpiredProductId>' +
//depreciated			'			<SalesforceOpportunityId>' +  regionalOpportunity.Id + '</SalesforceOpportunityId>' +
//depreciated			'			<SalesforceAccountOwnerId>' + USER.id + '</SalesforceAccountOwnerId>' +
//depreciated			'			<SalesforceCampaignId>' + CAMPAIGN.Id + '</SalesforceCampaignId>' +
//depreciated			'			<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'			<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			<Line>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'				<OrderLineId>0</OrderLineId>' +
//depreciated			'				<OrderLineNumber>0</OrderLineNumber>' +
//depreciated			'				<ContractLineId>0</ContractLineId>' +
//depreciated			'				<ContractNumber>0</ContractNumber>' +
//depreciated			'				<ExternalId>0-0</ExternalId>' +
//depreciated			'				<OpportunityNumber></OpportunityNumber>' +
//depreciated			'				<OrderNumber>0</OrderNumber>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<PricingAttributes>PricingAttributes</PricingAttributes>' +
//depreciated			'				<OrderedItem></OrderedItem>' +
//depreciated			'				<ProductLine>ProductLine</ProductLine>' +
//depreciated			'				<ConfiguredItem>RH0123456</ConfiguredItem>' +
//depreciated			'				<ConfiguredItemDescription>ConfiguredItemDescription</ConfiguredItemDescription>' +
//depreciated			'				<SubstituteItem>' + PRODUCT.ProductCode + '</SubstituteItem>' +
//depreciated			'				<RenewalItem></RenewalItem>' +
//depreciated			'				<FulfilledItem>FulfilledItem</FulfilledItem>' +
//depreciated			'				<FulfilledItemDescription>FulfilledItemDescription</FulfilledItemDescription>' +
//depreciated			'				<UnitSellingPrice>0.0</UnitSellingPrice>' +
//depreciated			'				<ServiceStartDate>2010-11-10</ServiceStartDate>' +
//depreciated			'				<ServiceEndDate>2011-11-10</ServiceEndDate>' +
//depreciated			'				<OrderedQuantity>' + regionalLineItem.Quantity + '</OrderedQuantity>' +
//depreciated			'				<TotalPrice>0.0</TotalPrice>' +
//depreciated			'				<CotermFlag></CotermFlag>' +
//depreciated			'				<NfrFlag>NfrFlag</NfrFlag>' +
//depreciated			'				<RevenueAmount>0.0</RevenueAmount>' +
//depreciated			'				<FiscalYear>0</FiscalYear>' +
//depreciated			'				<FiscalQuarter>0</FiscalQuarter>' +
//depreciated			'				<SalesforceExpiringProductId>' + PRODUCT.Id + '</SalesforceExpiringProductId>' +
//depreciated			'				<SalesforceOpportunityId>' + regionalOpportunity.Id + '</SalesforceOpportunityId>' +
//depreciated			'				<SalesforceOpportunityLineId>' + regionalLineItem.Id+ '</SalesforceOpportunityLineId>' +
//depreciated			'				<SalesforcePricebookEntryId>' + PRICEBOOK_ENTRY.Id + '</SalesforcePricebookEntryId>' +
//depreciated			'				<SalesforceProduct2Id>' + PRODUCT.Id + '</SalesforceProduct2Id>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</Line>' +
//depreciated			'			<MergedSubscription>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<OrderId>0</OrderId>' +
//depreciated			'				<OrderNumber>OrderNumber</OrderNumber>' +
//depreciated			'				<ContractId>0</ContractId>' +
//depreciated			'				<ContractNumber>ContractNumber</ContractNumber>' +
//depreciated			'				<ContractStartDate>2004-05-01</ContractStartDate>' +
//depreciated			'				<ContractEndDate>2005-05-01</ContractEndDate>' +
//depreciated			'				<ContractAmount>0.0</ContractAmount>' +
//depreciated			'				<ExpiringProductsAmount>0</ExpiringProductsAmount>' +
//depreciated			'				<OpportunityNumber></OpportunityNumber>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<MergeToSubscriptionId>0</MergeToSubscriptionId>' +
//depreciated			'				<ExpiringProductAmount>0.0</ExpiringProductAmount>' +
//depreciated			'			</MergedSubscription>' +
//depreciated			'			<Partner>' +
//depreciated			'				<AccountId></AccountId>' +
//depreciated			'				<AccountNumber>0</AccountNumber>' +
//depreciated			//'				<PartyId>0</PartyId>' +
//depreciated			//'				<PartyNumber>0</PartyNumber>' +
//depreciated			//'				<PartyName>PartyName</PartyName>' +
//depreciated			'				<Address>' +
//depreciated			'					<LocationId>0</LocationId>' +
//depreciated			'					<Address1>Address1</Address1>' +
//depreciated			'					<Address2>Address2</Address2>' +
//depreciated			'					<City>City</City>' +
//depreciated			'					<State>State</State>' +
//depreciated			'					<PostalCode>PostalCode</PostalCode>' +
//depreciated			'					<Country>Country</Country>' +
//depreciated			'				</Address>' +
//depreciated			'				<Contact>' +
//depreciated			'					<ContactId>0</ContactId>' +
//depreciated			'					<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'					<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'					<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'					<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'					<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'					<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'					<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				</Contact>' +
//depreciated			'				<SalesforceAccountId>' + regionalAccount.Id + '</SalesforceAccountId>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<ApId>0</ApId>' +
//depreciated			'				<PartnerType>PartnerType</PartnerType>' +
//depreciated			'				<PoNumber>' + regionalOpportunity.PONumber__c + '</PoNumber>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</Partner>' +
//depreciated			'			<User>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<UserType>UserType</UserType>' +
//depreciated			'				<UserId>0</UserId>' +
//depreciated			'				<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'				<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'				<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'				<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'				<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'				<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'				<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</User>' +
//depreciated			'			<User>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<UserType>UserType</UserType>' +
//depreciated			'				<UserId>0</UserId>' +
//depreciated			'				<FirstName>' + regionalContact.FirstName + '</FirstName>' +
//depreciated			'				<LastName>' + regionalContact.LastName + '</LastName>' +
//depreciated			'				<Name>' + regionalContact.Name + '</Name>' +
//depreciated			'				<Email>' + regionalContact.Email + '</Email>' +
//depreciated			'				<Phone>' + regionalContact.Phone + '</Phone>' +
//depreciated			'				<SalesforceContactId>' + regionalContact.Id + '</SalesforceContactId>' +
//depreciated			'				<SalesforceContactRoleId>' + regionalOCR.Id + '</SalesforceContactRoleId>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</User>' +
//depreciated			'			<User>' +
//depreciated			'				<Id>0</Id>' +
//depreciated			'				<SubscriptionId>0</SubscriptionId>' +
//depreciated			'				<UserType>UserType</UserType>' +
//depreciated			'				<UserId>0</UserId>' +
//depreciated			'				<FirstName>FirstName</FirstName>' +
//depreciated			'				<LastName>LastName</LastName>' +
//depreciated			'				<Name>Name</Name>' +
//depreciated			'				<Email>example2@example.com</Email>' +
//depreciated			'				<Phone></Phone>' +
//depreciated			//'				<SalesforceContactId></SalesforceContactId>' +
//depreciated			//'				<SalesforceContactRoleId></SalesforceContactRoleId>' +
//depreciated			'				<RecordStatus>RecordStatus</RecordStatus>' +
//depreciated			'				<ErrorMessage>ErrorMessage</ErrorMessage>' +
//depreciated			'			</User>' +
//depreciated			'		</Subscription>' +
//depreciated			'	</Payload>' +
//depreciated			'</SalesforceMessage>';

//depreciated		test.startTest();
//depreciated		String responseXML = OPPORTUNITY_RENEWAL.createRenewalOpportunity( regionalMessage );
//depreciated		test.stopTest();

//depreciated		Opportunity opp = queryOpportunity(regionalOpportunity.Id);
//depreciated		List<CampaignMember> campaignMembers = queryCampaignMembers(regionalOpportunity.Id);
//depreciated		Map<Id,String> idMap = getIdMap(opp,campaignMembers);
//depreciated		idMap.put(regionalAccount.Id,'{!regionalAccount.Id}');
//depreciated		idMap.put(regionalContact.Id,'{!regionalContact.Id}');
//depreciated		idMap.put(regionalOpportunity.Id,'{!regionalOpportunity.Id}');
//depreciated		idMap.put(regionalOCR.Id,'{!regionalOCR.Id}');
//depreciated		idMap.put(regionalLineItem.Id,'{!regionalLineItem.Id}');

//depreciated		String expectedXML = '<?xml version="1.0" encoding="UTF-8"?><SalesforceMessage xmlns=""><Header><Operation>Operation</Operation>'
//depreciated			+'<Type>Type</Type>'
//depreciated			+'<InstanceId>InstanceId</InstanceId>'
//depreciated			+'<Timestamp>2011-02-10</Timestamp>'
//depreciated			+'<ResponseTimeStamp>{!today}T..:..:..</ResponseTimeStamp></Header>'
//depreciated			+'<Payload><Subscription><Id>0</Id>'
//depreciated			+'<SalesRepOnAccount>...</SalesRepOnAccount>'
//depreciated			+'<SalesRepRoleOnAccount>...</SalesRepRoleOnAccount>'
//depreciated			+'<SalesforceAccountId>{!regionalAccount.Id}</SalesforceAccountId>'
//depreciated			+'<SalesforceOpportunityId>{!Opportunity.Id}</SalesforceOpportunityId>'
//depreciated			+'<SalesforceAccountOwnerId>{!Opportunity.OwnerId}</SalesforceAccountOwnerId>'
//depreciated			+'<RecordStatus>SUCCESS</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage>'
//depreciated			+'<Line><Id>0</Id>'
//depreciated			+'<ExternalId>0-0</ExternalId>'
//depreciated			+'<SalesforceExpiringProductId>{!Opportunity.Expiring_Products__r[0].Id}</SalesforceExpiringProductId>'
//depreciated			+'<SalesforceOpportunityLineId>{!OpportunityLineItems[0].Id}</SalesforceOpportunityLineId>'
//depreciated			+'<SalesforcePricebookEntryId>{!PricebookEntry.Id}</SalesforcePricebookEntryId>'
//depreciated			+'<SalesforceProduct2Id>{!Product.Id}</SalesforceProduct2Id>'
//depreciated			+'<RecordStatus>SUCCESS</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></Line>'
//depreciated			+'<Partner><Contact><SalesforceContactId>{!regionalContact.Id}</SalesforceContactId>'
//depreciated			+'<SalesforceContactRoleId>{!regionalOCR.Id}</SalesforceContactRoleId></Contact>'
//depreciated			+'<SalesforceAccountId>{!regionalAccount.Id}</SalesforceAccountId>'
//depreciated			+'<Id>0</Id>'
//depreciated			+'<SalesforceOpportunityPartnerId></SalesforceOpportunityPartnerId>'
//depreciated			+'<RecordStatus>RecordStatus</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></Partner>'
//depreciated			+'<User><Id>0</Id>'
//depreciated			+'<SalesforceContactId>{!regionalContact.Id}</SalesforceContactId>'
//depreciated			+'<SalesforceContactRoleId>{!OpportunityContactRoles[1].Id}</SalesforceContactRoleId>'
//depreciated			+'<RecordStatus>SUCCESS</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></User>'
//depreciated			+'<User><Id>0</Id>'
//depreciated			+'<SalesforceContactId>{!regionalContact.Id}</SalesforceContactId>'
//depreciated			+'<SalesforceContactRoleId>{!OpportunityContactRoles[1].Id}</SalesforceContactRoleId>'
//depreciated			+'<RecordStatus>DUPLICATE</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></User>'
//depreciated			+'<User><Id>0</Id>'
//depreciated			+'<SalesforceContactId>{!OpportunityContactRoles[0].ContactId}</SalesforceContactId>'
//depreciated			+'<SalesforceContactRoleId>{!OpportunityContactRoles[0].Id}</SalesforceContactRoleId>'
//depreciated			+'<RecordStatus>SUCCESS</RecordStatus>'
//depreciated			+'<ErrorMessage></ErrorMessage></User></Subscription></Payload></SalesforceMessage>';
//depreciated		responseXML = cleanResponseXML(responseXML,idMap);
//depreciated		System.assert(expectedXML == responseXML,'Unexpected Response: '+responseXML);

//depreciated		System.assertEquals(regionalAccount.Id,opp.AccountId);
//depreciated		System.assertEquals(0.00,opp.Amount);
//depreciated		System.assertEquals(null,opp.BillingAccountNumber__c);
//depreciated		System.assertEquals(regionalAccount.BillingStreet+'Address2',opp.BillingAddress__c);
//depreciated		System.assertEquals(regionalAccount.BillingCity,opp.BillingCity__c);
//depreciated		System.assertEquals(regionalAccount.BillingState,opp.BillingState__c);
//depreciated		System.assertEquals(regionalAccount.BillingCountry,opp.BillingCountry__c);
//depreciated		System.assertEquals(regionalAccount.BillingPostalCode,opp.BillingZipPostalCode__c);
//depreciated		System.assertEquals(CAMPAIGN.Id,opp.CampaignId);
//depreciated		System.assertEquals(Date.newInstance(2011,11,10),opp.CloseDate);
//depreciated		System.assertEquals(regionalAccount.OracleAccountNumber__c,opp.ContractNumber__c);
//depreciated		System.assertEquals(Date.newInstance(2010,01,01),opp.ContractStartDate__c);
//depreciated		System.assertEquals(Date.newInstance(2011,01,01),opp.ContractEndDate__c);
//depreciated		System.assertEquals(regionalOpportunity.Country_Of_Order__c,opp.Country_of_Order__c);
//depreciated		System.assertEquals('None',opp.CrossRegionalCreditCheck__c);
//depreciated		System.assertEquals(regionalOpportunity.CurrencyIsoCode,opp.CurrencyIsoCode);
//depreciated		String orderNumber = null;
//depreciated		System.assertEquals(
//depreciated			'Partner Contact: '+regionalContact.Name
//depreciated			+'\nPartner Email: '+regionalContact.Email
//depreciated			+'\nPartner Phone: '+regionalContact.Phone
//depreciated			+'\n\nOrder Number: '+orderNumber
//depreciated			+'\nContract Number: 12345',opp.Description);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products_Total_Amount_RollUp__c);
//depreciated		System.assertEquals('Direct - End Customer',opp.FulfillmentChannel__c);
//depreciated		System.assertEquals('LeadSourceDetail',opp.LeadSourceDetail__c);
//depreciated		System.assertEquals(null,opp.NA_Reseller__c);
//depreciated		System.assertEquals('Renewal - Red Hat - (12345)',opp.Name);
//depreciated		System.assertEquals('Co-Term',opp.OpportunityType__c);
//depreciated		System.assertNotEquals(null,opp.OwnerId);
//depreciated		System.assertEquals('Yes',opp.Pay_Now__c);
//depreciated		System.assertEquals(null,opp.PaymentType__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.PONumber__c);
//depreciated		System.assertEquals(null,opp.Primary_Partner__c);
//depreciated		System.assertNotEquals(null,opp.RecordTypeId);
//depreciated		System.assertEquals('true',''+opp.Renewal_Opportunity__c);
//depreciated		System.assertEquals('No',opp.Renewable__c);
//depreciated		System.assertEquals(null,opp.Reseller__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.Reseller_PO__c);
//depreciated		System.assertEquals(regionalAccount.ShippingStreet+'Address2',opp.ShippingAddress__c);
//depreciated		System.assertEquals(regionalAccount.ShippingCity,opp.ShippingCity__c);
//depreciated		System.assertEquals(regionalAccount.ShippingState,opp.ShippingState__c);
//depreciated		System.assertEquals(regionalAccount.ShippingCountry,opp.ShippingCountry__c);
//depreciated		System.assertEquals(regionalAccount.ShippingPostalCode,opp.ShippingZipPostalCode__c);
//depreciated		System.assertEquals('Engage',opp.StageName);
//depreciated		System.assertEquals('true',''+opp.Touched__c);
//depreciated		System.assertEquals(null,opp.Year1PaymentAmount__c);

//depreciated		System.assertEquals(1,opp.Expiring_Products__r.size());
//depreciated		System.assertEquals(Date.newInstance(2011,11,10),+opp.Expiring_Products__r[0].Expiring_Product_End_Date__c);
//depreciated		System.assertEquals('0',opp.Expiring_Products__r[0].Expiring_Contract_Number__c);
//depreciated		System.assertEquals(regionalOpportunity.PONumber__c,opp.Expiring_Products__r[0].Expiring_Contract_PO_Number__c);
//depreciated		System.assertEquals(Date.newInstance(2010,11,10),+opp.Expiring_Products__r[0].Expiring_Product_Start_Date__c);
//depreciated		System.assertEquals('0',opp.Expiring_Products__r[0].Expiring_Oracle_Order_Number__c);
//depreciated		System.assertEquals('USD',opp.Expiring_Products__r[0].CurrencyIsoCode);
//depreciated		System.assertEquals('false',''+opp.Expiring_Products__r[0].Co_Term__c);
//depreciated		System.assertEquals('false',''+opp.Expiring_Products__r[0].Already_Renewed__c);
//depreciated		System.assertEquals('006',(opp.Expiring_Products__r[0].Opportunity__c+'   ').substring(0,3));
//depreciated		System.assertEquals(null,opp.Expiring_Products__r[0].Product_Code__c);
//depreciated		System.assertEquals(2,opp.Expiring_Products__r[0].Quantity__c);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products__r[0].Sales_Price__c);
//depreciated		System.assertEquals(0.00,opp.Expiring_Products__r[0].Total_Price_Formula__c);
//depreciated		System.assertEquals('FulfilledItemDescription',opp.Expiring_Products__r[0].Name);
//depreciated		System.assertEquals('ConfiguredItemDescription',opp.Expiring_Products__r[0].Mapped_Description__c);
//depreciated		System.assertEquals('01t',(opp.Expiring_Products__r[0].Product__c+'   ').substring(0,3));

//depreciated		System.assertEquals(3,opp.OpportunityContactRoles.size());
//depreciated		System.assertEquals('003',(opp.OpportunityContactRoles[0].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example2@example.com',opp.OpportunityContactRoles[0].Contact.Email);
//depreciated		System.assertEquals('Shipping Contact',opp.OpportunityContactRoles[0].Role);
//depreciated		System.assertEquals('003',(opp.OpportunityContactRoles[1].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example@example.org',opp.OpportunityContactRoles[1].Contact.Email);
//depreciated		System.assertEquals('Shipping Contact',opp.OpportunityContactRoles[1].Role);
//depreciated		System.assertEquals('003',(opp.OpportunityContactRoles[2].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example@example.org',opp.OpportunityContactRoles[2].Contact.Email);
//depreciated		System.assertEquals('Technical Buyer',opp.OpportunityContactRoles[2].Role);

//depreciated		System.assertEquals(1,opp.OpportunityLineItems.size());
//depreciated		System.assertEquals(Date.newInstance(2012,11,10),+opp.OpportunityLineItems[0].ActualEndDate__c);
//depreciated		System.assertEquals(Date.newInstance(2011,11,11),+opp.OpportunityLineItems[0].ActualStartDate__c);
//depreciated		System.assertEquals('01u',(opp.OpportunityLineItems[0].PricebookEntryId+'   ').substring(0,3));
//depreciated		System.assertEquals('Renewal',opp.OpportunityLineItems[0].NewOrRenewal__c);
//depreciated		System.assertEquals(2.00,opp.OpportunityLineItems[0].Quantity);
//depreciated		System.assertEquals('true',''+opp.OpportunityLineItems[0].ScheduleLocked__c);
//depreciated		System.assertEquals('0',opp.OpportunityLineItems[0].Contract_Numbers__c);
//depreciated		System.assertEquals(null,+opp.OpportunityLineItems[0].Configured_SKU__c);
//depreciated		System.assertEquals(0.00,opp.OpportunityLineItems[0].UnitPrice);
//depreciated		System.assertEquals('ConfiguredItemDescription',opp.OpportunityLineItems[0].Description);

//depreciated		System.assertEquals(0,opp.OpportunityPartners2__r.size());

//depreciated		System.assertEquals(2,campaignMembers.size());
//depreciated		System.assertEquals(CAMPAIGN.Id,campaignMembers[0].CampaignId);
//depreciated		System.assertEquals('003',(campaignMembers[0].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example2@example.com',''+campaignMembers[0].Contact.Email);
//depreciated		System.assertEquals(CAMPAIGN.Id,campaignMembers[1].CampaignId);
//depreciated		System.assertEquals('003',(campaignMembers[1].ContactId+'   ').substring(0,3));
//depreciated		System.assertEquals('example@example.org',''+campaignMembers[1].Contact.Email);
//depreciated	}

//depreciated	@isTest
//depreciated	static void testNoSourceOpportunity()
//depreciated	{
//depreciated		test.startTest();
//depreciated		String responseXML = OPPORTUNITY_RENEWAL.createRenewalOpportunity( MESSAGE );
//depreciated		test.stopTest();
//depreciated	}

//depreciated	@isTest
//depreciated	static void isTestModeTest() {
//depreciated		OPPORTUNITY_RENEWAL.isTestMode = null;
//depreciated		System.assertEquals('false',''+OPPORTUNITY_RENEWAL.isTestMode);
//depreciated	}

//depreciated	@isTest
//depreciated	static void isSuccessTest() {
//depreciated		OPPORTUNITY_RENEWAL.isSuccess = true;
//depreciated		System.assertEquals('true',''+OPPORTUNITY_RENEWAL.isSuccess);
//depreciated	}

//depreciated	/**
//depreciated	 * parses the response XML returned from the renewals service
//depreciated	 *
//depreciated	 * @param String responseXML
//depreciated	 *
//depreciated	 */
//depreciated	private static Response parseResponseXML( String responseXML ) {
//depreciated		Response response = new Opportunity_RenewalTest.Response();

//depreciated		DOM.Document doc = new DOM.Document();
//depreciated		doc.load(responseXML);
//depreciated		DOM.XMLNode salesforceMsg = doc.getRootElement();
//depreciated		DOM.XMLNode header = salesforceMsg.getChildElement( 'Header', null );
//depreciated		DOM.XMLNode payload = salesforceMsg.getChildElement( 'Payload', null );
//depreciated		DOM.XMLNode subscription = payload.getChildElement( 'Subscription', null );

//depreciated		// parse subscription node
//depreciated		response.recordStatus = subscription.getChildElement( 'RecordStatus', null ).getText();
//depreciated		response.errorMessage = subscription.getChildElement( 'ErrorMessage', null ).getText();

//depreciated		return response;
//depreciated	}


//depreciated	/**
//depreciated	 * Class to represent XML response more conveniently
//depreciated	 */
//depreciated	class Response {
//depreciated		public String errorMessage { get; set; }
//depreciated		public String recordStatus { get; set; }
//depreciated	}
}