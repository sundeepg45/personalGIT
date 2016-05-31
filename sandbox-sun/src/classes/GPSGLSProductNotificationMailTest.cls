/**
 * Test Class created for GPSGLSNotificationMailTest business Class.
 *
 * @author Unknown
 *
 * @version 2012-07-10
 *
 * Modified: Bill Riemers <briemers@redhat.com>
 * 2012-07-10 - SMR additional updates
 * 2012-04-25 - Update for Security Model Redesign
 * Modified: Abhijeet Anand
 * 2011-09-26 - Enhanced code coverage and added assert statements.
 */ 
@isTest
private class GPSGLSProductNotificationMailTest
{
	// test method for GPSGLSProductNotificationMail
	@isTest
	static void deployGPSGLSProductNotificationMail()
	{
		Opportunity  tandem_Opportunity;
		List<OpportunityLineItem> products = new List<OpportunityLineItem>();
		Profile profile = [select id from profile where Name like '%Sales%' limit 1];
		User u = new User(
			alias = 'st9318', 
			email='standarduser9318@testorg.com',
			emailencodingkey='UTF-8',
			lastname='Testing',
			languagelocalekey='en_US',
			localesidkey='en_US',
			profileid = profile.Id,
			timezonesidkey='America/Los_Angeles',
			username='standarduser9318@testorg.com');
		insert u;

		System.runAs(u)
		{
			Account acc = new Account(Name='Test Account');
			//acc.OwnerId = u.Id;
			insert acc;
			//changed the opportunity stagename value to Prepare as part of Value Selling enhancement.July 20th release
			Opportunity Opp = new Opportunity();
			Opp.StageName = 'Prepare';
			Opp.PaymentType__c = 'LATAM Purchase Order';
			Opp.Pay_Now__c = 'Yes';
			Opp.OpportunityType__c = 'Standard';
			Opp.Name = 'Test Opp';
			//Opp.Country_of_Order__c = 'Virgin Islands, U.S';
			Opp.CloseDate = System.today();
			Opp.AccountId = acc.Id;
			Opp.Region2__c ='4';
			Opp.CurrencyIsoCode ='USD';
			insert Opp;

			Product2 pdts = new Product2(Name = 'GLS',Family = 'GLS', IsActive = True);
			insert pdts;

			Pricebook2 prcBook2 = [Select p.IsStandard From Pricebook2 p where IsStandard = true limit 1];

			PricebookEntry prcBookEntry = new PricebookEntry(UseStandardPrice = false,Pricebook2Id = prcBook2.Id,UnitPrice = 75.00,Product2Id = pdts.Id, IsActive=True);
			insert prcBookEntry;

			//products.add(opptyLineItem);
			AccountTeamMember accTeamMember = new AccountTeamMember();
			accTeamMember.AccountId = acc.Id;
			accTeamMember.TeamMemberRole = 'Presales Owner';
			accTeamMember.UserId = u.Id;
			insert accTeamMember;

			//OpportunityLineItem oppid=[Select opportunityId,PricebookEntry.Product2.Family from OpportunityLineItem where ( (PricebookEntry.Product2.Family like '%GPS%' or PricebookEntry.Product2.Family like '%GLS%') and PricebookEntry.IsActive=true )and opportunity.Super_Region__c='EMEA' limit 1];
			OpportunityTeamMember oppTeamMember = new OpportunityTeamMember ();
			oppTeamMember.UserId = u.Id;
			oppTeamMember.TeamMemberRole = 'Presales Owner';
			oppTeamMember.OpportunityId = Opp.Id;
			insert oppTeamMember;

			OpportunityLineItem opptyLineItem = new OpportunityLineItem(OpportunityId = Opp.Id,PricebookEntryId = prcBookEntry.Id);
			insert opptyLineItem;
			//delete opptyLineItem;
			System.debug('lineitne****'+opptyLineItem);
			List<Opportunity> tandem_Opportunities = new List<Opportunity>();
			tandem_Opportunity = [Select account.RecordType.Name,account.Name,account.Account_Priority__c, account.AccountClassification__c, account.AccountRating__c, account.EMEA_SE_Required__c, account.OwnerId, OwnerId,CurrencyIsoCode,AccountId, Amount, BillingAddress__c, BillingCity__c, BillingCountry__c, CloseDate, Country_of_Order__c, EMEA_SE_Required__c, ForecastCategory, FulfillmentChannel__c, Id, Opportunity_Priority__c, OpportunityNumber__c, Primary_Partner__c, ProductsOfInterest__c, Region__c, Reseller__c, ShippingAddress__c, ShippingCity__c, ShippingCountry__c, StageName, LastModifiedById,Super_Region__c,name from Opportunity where id=:Opp.Id];
		}
		//tandem_Opportunity = [Select account.RecordType.Name,account.Name,account.Account_Priority__c, account.AccountClassification__c, account.AccountRating__c, account.EMEA_SE_Required__c, account.OwnerId, OwnerId,CurrencyIsoCode,AccountId, Amount, BillingAddress__c, BillingCity__c, BillingCountry__c, CloseDate, Country_of_Order__c, EMEA_SE_Required__c, ForecastCategory, FulfillmentChannel__c, Id, Opportunity_Priority__c, OpportunityNumber__c, Primary_Partner__c, ProductsOfInterest__c, Region__c, Reseller__c, ShippingAddress__c, ShippingCity__c, ShippingCountry__c, StageName, LastModifiedById,Super_Region__c,name from Opportunity where id=:Opp.Id];
		//tandem_Opportunities.add(tandem_Opportunity);

		products=[Select opportunityId,PricebookEntry.Name, PricebookEntry.CurrencyIsoCode, PricebookEntry.Product2.Family, PricebookEntry.Product2.ProductCode, Quantity,CurrencyIsoCode,UnitPrice,TotalPrice from OpportunityLineItem  where OpportunityId=:tandem_Opportunity.id];
		Util.products.put(tandem_Opportunity.id,products);
		test.startTest();
		GPSGLSProductNotificationMail g = new GPSGLSProductNotificationMail();
		g.createMail(tandem_Opportunity,products,'insert');
		System.assert(g.mailSent,'Failed to send mail');
		g = new GPSGLSProductNotificationMail();
		g.createMail(null,products,'insert');
		System.assert(g.mailSent,'Failed to send mail');
		g = new GPSGLSProductNotificationMail();
		g.createMail(tandem_Opportunity,products,'stage update');
		System.assert(g.mailSent,'Failed to send mail');
		g = new GPSGLSProductNotificationMail();
		g.createMail(tandem_Opportunity,products,'update');
		System.assert(g.mailSent,'Failed to send mail');
		g = new GPSGLSProductNotificationMail();
		g.sendMail();
		System.assert(g.mailSent,'Failed to send mail');
		test.stopTest();
	}

	// test method for GPSGLSProductNotification trigger
	@isTest
	static void deployGPSGLSProductNotification()
	{
		test.startTest();
		Opportunity  tandem_Opportunity;
		List<OpportunityLineItem> products = new List<OpportunityLineItem>();
		Profile profile = [select id from profile where name like '%Sales%' limit 1];
		User u = new User(alias = 'st8234', email='standarduse8234@testorg.com',
		emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
		localesidkey='en_US', profileid = profile.Id,
		timezonesidkey='America/Los_Angeles', username='standarduse8234@testorg.com');
		insert u;

		System.runAs(u)
		{
			Account acc = new Account(Name='Test Account');
			//acc.OwnerId = u.Id;
			insert acc;
			//changed the opportunity stagename value to Prepare as part of Value Selling enhancement.July 20th release
			Opportunity Opp = new Opportunity();
			Opp.StageName = 'Prepare';
			Opp.PaymentType__c = 'LATAM Purchase Order';
			Opp.Pay_Now__c = 'Yes';
			Opp.OpportunityType__c = 'Standard';
			Opp.Name = 'Test Opp';
			//Opp.Country_of_Order__c = 'Virgin Islands, U.S';
			Opp.CloseDate = System.today();
			Opp.AccountId = acc.Id;
			Opp.Region2__c ='4';
			Opp.CurrencyIsoCode ='USD';
			insert Opp;

			Product2 pdts = new Product2(Name = 'ABC',Family = 'GLS', IsActive = True);
			insert pdts;

			Product2 prdts = new Product2(Name = 'GPS',Family = 'GLS', IsActive = True);
			insert prdts;

			Pricebook2 prcBook2 = [Select p.IsStandard From Pricebook2 p where IsStandard = true limit 1];

			PricebookEntry prcBookEntry = new PricebookEntry(UseStandardPrice = false,Pricebook2Id = prcBook2.Id,UnitPrice = 75.00,Product2Id = pdts.Id, IsActive=True);
			insert prcBookEntry;

			PricebookEntry priceBookEntry = new PricebookEntry(UseStandardPrice = false,Pricebook2Id = prcBook2.Id,UnitPrice = 75.00,Product2Id = prdts.Id, IsActive=True);
			insert priceBookEntry;
			//products.add(opptyLineItem);
			AccountTeamMember accTeamMember = new AccountTeamMember();
			accTeamMember.AccountId = acc.Id;
			accTeamMember.TeamMemberRole = 'Presales Owner';
			accTeamMember.UserId = u.Id;
			insert accTeamMember;

			//OpportunityLineItem oppid=[Select opportunityId,PricebookEntry.Product2.Family from OpportunityLineItem where ( (PricebookEntry.Product2.Family like '%GPS%' or PricebookEntry.Product2.Family like '%GLS%') and PricebookEntry.IsActive=true )and opportunity.Super_Region__c='EMEA' limit 1];
			OpportunityTeamMember oppTeamMember = new OpportunityTeamMember ();
			oppTeamMember.UserId = u.Id;
			oppTeamMember.TeamMemberRole = 'Presales Owner';
			oppTeamMember.OpportunityId = Opp.Id;
			insert oppTeamMember;

			List<OpportunityLineItem> delList = new List<OpportunityLineItem>();
			OpportunityLineItem opptLineItem = new OpportunityLineItem(OpportunityId = Opp.Id,PricebookEntryId = prcBookEntry.Id);
			insert opptLineItem;
			delList.add(opptLineItem);
			OpportunityLineItem opptyLineItem = new OpportunityLineItem(OpportunityId = Opp.Id,PricebookEntryId = priceBookEntry.Id);
			insert opptyLineItem;
			delList.add(opptyLineItem);
			delete delList;
			System.debug('lineitne****'+opptyLineItem);
			List<Opportunity> tandem_Opportunities = new List<Opportunity>();
			tandem_Opportunity = [Select account.RecordType.Name,account.Name,account.Account_Priority__c, account.AccountClassification__c, account.AccountRating__c, account.EMEA_SE_Required__c, account.OwnerId, OwnerId,CurrencyIsoCode,AccountId, Amount, BillingAddress__c, BillingCity__c, BillingCountry__c, CloseDate, Country_of_Order__c, EMEA_SE_Required__c, ForecastCategory, FulfillmentChannel__c, Id, Opportunity_Priority__c, OpportunityNumber__c, Primary_Partner__c, ProductsOfInterest__c, Region__c, Reseller__c, ShippingAddress__c, ShippingCity__c, ShippingCountry__c, StageName, LastModifiedById,Super_Region__c,name from Opportunity where id=:Opp.Id];
			test.stopTest();
		}
	}

	// test method for GPSGLSNotification trigger
	@isTest
	static void deployGPSGLSNotification()
	{
		test.startTest();
		Opportunity  tandem_Opportunity;
		List<OpportunityLineItem> products = new List<OpportunityLineItem>();
		Profile profile = [select id from profile where Name like '%Sales%' limit 1];
		User u = new User(alias = 'st2746', email='standarduser2746@testorg.com',
		emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
		localesidkey='en_US', profileid = profile.Id,
		timezonesidkey='America/Los_Angeles', username='standarduser2746@testorg.com');
		insert u;

		System.runAs(u)
		{
			Account acc = new Account(Name='Test Account');
			//acc.OwnerId = u.Id;
			insert acc;
			//changed the opportunity stagename value to Prepare as part of Value Selling enhancement.July 20th release

			Product2 prd = new Product2(Name = 'GPS',Family = 'GLS', IsActive = True);
			insert prd;

			Pricebook2 prcBook2 = [Select p.IsStandard From Pricebook2 p where IsStandard = true limit 1];

			PricebookEntry prcBookEntry = new PricebookEntry(UseStandardPrice = false,Pricebook2Id = prcBook2.Id,UnitPrice = 75.00,Product2Id = prd.Id, IsActive=True);
			insert prcBookEntry;

			Opportunity Opp = new Opportunity();
			Opp.StageName = 'Prepare';
			Opp.PaymentType__c = 'LATAM Purchase Order';
			Opp.Pay_Now__c = 'Yes';
			Opp.OpportunityType__c = 'Standard';
			Opp.Name = 'Test Opp';
			Opp.Country_of_Order__c = 'Virgin Islands, U.S';
			Opp.CloseDate = System.today();
			Opp.AccountId = acc.Id;
			Opp.Region2__c ='4';
			Opp.CurrencyIsoCode ='USD';
			insert Opp;

			OpportunityLineItem opptyLineItem = new OpportunityLineItem(OpportunityId = Opp.Id,PricebookEntryId = prcBookEntry.Id);
			insert opptyLineItem;

			Opp.StageName = 'Complete';
			update Opp;

			List<Opportunity> tandem_Opportunities = new List<Opportunity>();
			tandem_Opportunity = [Select account.RecordType.Name,account.Name,account.Account_Priority__c, account.AccountClassification__c, account.AccountRating__c, account.EMEA_SE_Required__c, account.OwnerId, OwnerId,CurrencyIsoCode,AccountId, Amount, BillingAddress__c, BillingCity__c, BillingCountry__c, CloseDate, Country_of_Order__c, EMEA_SE_Required__c, ForecastCategory, FulfillmentChannel__c, Id, Opportunity_Priority__c, OpportunityNumber__c, Primary_Partner__c, ProductsOfInterest__c, Region__c, Reseller__c, ShippingAddress__c, ShippingCity__c, ShippingCountry__c, StageName, LastModifiedById,Super_Region__c,name from Opportunity where id=:Opp.Id];
			test.stopTest();
		}
	}
}