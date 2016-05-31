/**
* Class Name: UtilTest
* Description: Test Class created for Util Class
* Modificaton History:
* Modified By: Scott Coleman <scoleman@redhat.com>
* Modified data: 04/27/2012
* Reason for Modification: Added test methods for bypass methods.
* Modified By :Nitesh Dokania
* Modified date :09/21/2011
* Reason for Modification: Separated test class from business class and created a new test class and incraese the test coverage.Also added assert statements.
*/

@isTest
private class UtilTest
{
	public static final String SANDBOXES_DEFAULT = 'dev';
	// Feel free to add more explicity mappings, such as training boxes.
	public static final Map<String,String> SANDBOXES = new Map<String,String>{
		'com'=>'prod',
		'stage'=>'stage',
		'qa'=>'qa','fte1'=>'qa','fte2'=>'qa'};
	public static String ENVIRONMENT {
		get {
			if(ENVIRONMENT == null)
			{
				String username = currentUser.UserName;
				if(! username.contains('@redhat.com')) {
					User u = [select UserName from User where UserName like 'intadmin@redhat.com%' limit 1];
					username = u.UserName;
				}
				ENVIRONMENT = SANDBOXES_DEFAULT;
				Integer i = username.lastIndexOf('.');
				if(i > 0) {
					final String s = SANDBOXES.get(username.substring(i+1));
					if(s != null) {
						ENVIRONMENT = s;
					}
				}
			}
			return ENVIRONMENT;
		}
		private set;
	}
	
	public static User currentUser {
		get {
			if(currentUser == null) {
				// This will have everything we need except the name field.  For that a query is required.
				currentUser = new User(Id=UserInfo.getUserId(),UserName=UserInfo.getUserName(),UserRoleId=UserInfo.getUserRoleId(),ProfileId=UserInfo.getProfileId());
			}
			return currentUser;
		}
		set;
	}

	static testMethod void testEnvironment() {
		
		Account ACCOUNT;
		Account PARTNER_ACCOUNT;
		Opportunity OPPORTUNITY;
		Opportunity oppty;
		Opportunity opptyJBoss;
		OpportunityLineItem LINE_ITEM;
		OpportunityLineItem opptyLineItem;
		OpportunityLineItem opptyLineItemJBoss;
		
		ACCOUNT = new Account();
		ACCOUNT.BillingCity = 'Raleigh';
		ACCOUNT.BillingCountry = 'US';
		ACCOUNT.BillingPostalCode = '27606';
		ACCOUNT.BillingState = 'North Carolina';
		ACCOUNT.BillingStreet = '1801 Varsity Drive';
		ACCOUNT.Name = 'Red Hat';
		ACCOUNT.OracleAccountNumber__c = '12345';
		ACCOUNT.ShippingCity = 'Raleigh';
		ACCOUNT.ShippingCountry = 'US';
		ACCOUNT.ShippingPostalCode = '27606';
		ACCOUNT.ShippingState = 'North Carolina';
		ACCOUNT.ShippingStreet = '1801 Varsity Drive';
		ACCOUNT.VATNumber__c = '67890';
		insert ACCOUNT;
		
		// create a partner account
		PARTNER_ACCOUNT = new Account();
		PARTNER_ACCOUNT.BillingCity = 'Raleigh';
		PARTNER_ACCOUNT.BillingCountry = 'US';
		PARTNER_ACCOUNT.BillingPostalCode = '27606';
		PARTNER_ACCOUNT.BillingState = 'North Carolina';
		PARTNER_ACCOUNT.BillingStreet = '1801 Varsity Drive';
		PARTNER_ACCOUNT.Name = 'Red Hat Partner';
		PARTNER_ACCOUNT.OracleAccountNumber__c = '12345';
		PARTNER_ACCOUNT.ShippingCity = 'Raleigh';
		PARTNER_ACCOUNT.ShippingCountry = 'US';
		PARTNER_ACCOUNT.ShippingPostalCode = '27606';
		PARTNER_ACCOUNT.ShippingState = 'North Carolina';
		PARTNER_ACCOUNT.ShippingStreet = '1801 Varsity Drive';
		PARTNER_ACCOUNT.VATNumber__c = '67890';
		insert PARTNER_ACCOUNT;
		
		// get the id of the standard price book
		Pricebook2 priceBook= [SELECT Id FROM PriceBook2 WHERE isStandard = true];
		String priceBookId = priceBook.Id;
		
		// create a product
		Product2 product = new Product2();
		product.Description = 'Warning: Pregnant women, the elderly, and children should avoid prolonged exposure to Happy Fun Ball.';
		product.IsActive = true;
		product.Name = 'Happy';
		product.ProductCode = 'HFB007';
		product.Family = 'GPS';
		insert product;
		
		// create a pricebook entry for the standard pricebook
		PricebookEntry priceBookEntry = new PricebookEntry();
		priceBookEntry.CurrencyIsoCode = 'USD';
		priceBookEntry.isActive = true;
		priceBookEntry.Pricebook2Id = priceBookId;
		priceBookEntry.Product2Id = product.Id;
		priceBookEntry.UnitPrice = 2000.00;
		insert priceBookEntry;
		String priceBookEntryId = priceBookEntry.Id;
		
		// create an opportunity
		OPPORTUNITY = new Opportunity();
		OPPORTUNITY.AccountId = account.Id;
		OPPORTUNITY.CloseDate = Date.newInstance(2009, 11, 10);
		OPPORTUNITY.Country_Of_Order__c = 'US';
		OPPORTUNITY.CurrencyIsoCode = 'USD';
		OPPORTUNITY.Name = 'Opportunity';
		OPPORTUNITY.OpportunityType__c = 'Standard';
		OPPORTUNITY.PaymentType__c = 'NA Purchase Order';
		OPPORTUNITY.StageName = 'Test Stage';
		insert OPPORTUNITY;
		
		// create an opportunity line item
		LINE_ITEM = new OpportunityLineItem();
		LINE_ITEM.OpportunityId = OPPORTUNITY.Id;
		LINE_ITEM.ActualStartDate__c = Date.newInstance(2009, 11, 11);
		LINE_ITEM.ActualEndDate__c = Date.newInstance(2010, 11, 10);
		LINE_ITEM.ActualTerm__c = 2000;
		LINE_ITEM.PricebookEntryId = priceBookEntryId;
		LINE_ITEM.Quantity = 2;
		LINE_ITEM.UnitPrice = 2000.00;
		LINE_ITEM.ScheduleLocked__c = true;
		LINE_ITEM.Pricing_Attributes__c = 'TestArea=tstArea,NiteshTest=nitTest,Rhtest=test';
		insert LINE_ITEM;
		
		Map<String,User> userMap = new Map<String,User> {
			'prod' => new User(alias = 'admintes', email='noreply@redhat.com',
			emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
			localesidkey='en_US', profileid = currentUser.ProfileId,
			timezonesidkey='America/Los_Angeles', username='testingnoreply1@redhat.com',
			userroleid = null),
			'stage' => new User(alias = 'admintes', email='noreply@redhat.com',
			emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
			localesidkey='en_US', profileid = currentUser.ProfileId,
			timezonesidkey='America/Los_Angeles', username='testingnoreply2@redhat.com.stage',
			userroleid = null),
			'qa' => new User(alias = 'admintes', email='noreply@redhat.com',
			emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
			localesidkey='en_US', profileid = currentUser.ProfileId,
			timezonesidkey='America/Los_Angeles', username='testingnoreply3@redhat.com.qa',
			userroleid = null),
			'dev' => new User(alias = 'admintes', email='noreply@redhat.com',
			emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
			localesidkey='en_US', profileid = currentUser.ProfileId,
			timezonesidkey='America/Los_Angeles', username='testingnoreply4@redhat.com.anything',
			userroleid = null),
			null => new User(alias = 'admintes', email='noreply@redhat.com',
			emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
			localesidkey='en_US', profileid = currentUser.ProfileId,
			timezonesidkey='America/Los_Angeles', username='testingnoreply5@google.com',
			userroleid = null) };
		
		test.startTest();
		
		for(String key : userMap.keySet()) {
			Util.ENVIRONMENT = null;
			Util.currentUser = userMap.get(key);
			if(key == null) {
				System.assertNotEquals(null,Util.ENVIRONMENT);
			}
			else {
				System.assertEquals(key,Util.ENVIRONMENT);
				System.assertEquals((key == 'prod'),Util.isProd());
				System.assertEquals((key == 'stage'),Util.isStage());
				System.assertEquals((key == 'qa'),Util.isQA());
				System.assertEquals((key == 'dev'),Util.isDev());
			}
		}
			  
		util.getProducts(OPPORTUNITY.id);
		util.getProducts(OPPORTUNITY.id);
		System.assertEquals(false,util.hasGPSGLSProducts(OPPORTUNITY.id));
		
		oppty = new Opportunity();
		oppty.AccountId = account.Id;
		oppty.CloseDate = Date.newInstance(2009, 11, 10);
		oppty.Country_Of_Order__c = 'US';
		oppty.CurrencyIsoCode = 'USD';
		oppty.Name = 'Opportunity';
		oppty.OpportunityType__c = 'Standard';
		oppty.PaymentType__c = 'NA Purchase Order';
		oppty.StageName = 'Test Stage';
		insert oppty;
		
		product.Name = 'GPS';
		update product;
		
		opptyLineItem = new OpportunityLineItem();
		opptyLineItem.OpportunityId = oppty.Id;
		opptyLineItem.ActualStartDate__c = Date.newInstance(2009, 11, 11);
		opptyLineItem.ActualEndDate__c = Date.newInstance(2010, 11, 10);
		opptyLineItem.ActualTerm__c = 2000;
		opptyLineItem.PricebookEntryId = priceBookEntryId;
		opptyLineItem.Quantity = 2;
		opptyLineItem.UnitPrice = 2000.00;
		opptyLineItem.ScheduleLocked__c = true;
		opptyLineItem.Pricing_Attributes__c = 'TestArea=tstArea,NiteshTest=nitTest,Rhtest=test';
		insert opptyLineItem;
		
		util.getProducts(oppty.id);
		System.assertEquals(true,util.hasGPSGLSProducts(oppty.id));
		System.assertEquals(false,util.hasJbossProducts(OPPORTUNITY.id));
		
		opptyJBoss = new Opportunity();
		opptyJBoss.AccountId = account.Id;
		opptyJBoss.CloseDate = Date.newInstance(2009, 11, 10);
		opptyJBoss.Country_Of_Order__c = 'US';
		opptyJBoss.CurrencyIsoCode = 'USD';
		opptyJBoss.Name = 'Opportunity';
		opptyJBoss.OpportunityType__c = 'Standard';
		opptyJBoss.PaymentType__c = 'NA Purchase Order';
		opptyJBoss.StageName = 'Test Stage';
		insert opptyJBoss;
		
		product.Name = 'JBoss';
		update product;
		
		opptyLineItemJBoss = new OpportunityLineItem();
		opptyLineItemJBoss.OpportunityId = opptyJBoss.Id;
		opptyLineItemJBoss.ActualStartDate__c = Date.newInstance(2009, 11, 11);
		opptyLineItemJBoss.ActualEndDate__c = Date.newInstance(2010, 11, 10);
		opptyLineItemJBoss.ActualTerm__c = 2000;
		opptyLineItemJBoss.PricebookEntryId = priceBookEntryId;
		opptyLineItemJBoss.Quantity = 2;
		opptyLineItemJBoss.UnitPrice = 2000.00;
		opptyLineItemJBoss.ScheduleLocked__c = true;
		opptyLineItemJBoss.Pricing_Attributes__c = 'TestArea=tstArea,NiteshTest=nitTest,Rhtest=test';
		insert opptyLineItemJBoss;
		
		util.getProducts(opptyJBoss.id);
		System.assertEquals(true,util.hasJbossProducts(opptyJBoss.id));
		util.getOpportunityData(OPPORTUNITY.id);	  
		util.getOpportunityData(OPPORTUNITY.id);
		util.getUser(UserInfo.getUserId());
		util.getUser(UserInfo.getUserId());
		util.getSalesTeam(OPPORTUNITY.id);
		util.getSalesTeam(OPPORTUNITY.id);
		util.getAccountTeam(ACCOUNT.Id);
		util.getAccountTeam(ACCOUNT.Id);
		System.assertEquals('testname',util.nullCheck('testname'));
		System.assertEquals(1200,util.getConvertedAmount('AUD',1000));
		System.assertEquals(1000,util.getConvertedAmount('USD',1000));
		System.assertEquals(120000,util.getConvertedAmount('JPY',1000));
		System.assertEquals(40000,util.getConvertedAmount('INR',1000));
		System.assertEquals(1950,util.getConvertedAmount('BRL',1000));
		System.assertEquals(7560,util.getConvertedAmount('CNY',1000));
		System.assertEquals(1050,util.getConvertedAmount('CAD',1000));
		System.assertEquals(730,util.getConvertedAmount('EUR',1000));
		System.assertEquals(500,util.getConvertedAmount('GBP',1000));
		System.assertEquals(7800,util.getConvertedAmount('HKD',1000));
		System.assertEquals(940000,util.getConvertedAmount('KRW',1000));
		System.assertEquals(3480,util.getConvertedAmount('MYR',1000));
		System.assertEquals(46000,util.getConvertedAmount('PHP',1000));
		System.assertEquals(1520,util.getConvertedAmount('SGD',1000));
		System.assertEquals(33000,util.getConvertedAmount('THB',1000));
		System.assertEquals(1320,util.getConvertedAmount('NZD',1000));
		System.assertEquals(1000,util.getConvertedAmount('ABC',1000));
		System.assertEquals('NITESH',util.getUpperCaseValue('nitesh'));
		System.assertEquals('',util.getUpperCaseValue(null));
		util.setTesting(true);
		util.isNill('test');
		util.leapDays(Date.newInstance(2012,2,29), Date.newInstance(2020,2,28));
		
		test.stopTest();
	}

	static testMethod void testByPasses() {
		Util.setTesting(true);
		System.assertEquals(''+true,''+Util.adminByPass(true));
		System.assertEquals(''+true,''+Util.adminByPassForOpportunity(true));
		System.assertEquals(''+true,''+Util.channelLoadByPass(true));
		System.assertEquals(''+false,''+Util.adminByPass(false));
		System.assertEquals(''+false,''+Util.adminByPassForOpportunity(false));
		System.assertEquals(''+false,''+Util.channelLoadByPass(false));
		Util.setTesting(false);
		AdminByPass__c bypass = AdminByPass__c.getInstance(UserInfo.getUserId());
		System.assertEquals(''+(bypass.IsAdmin__c == true),''+Util.adminByPass());
		System.assertEquals(''+(bypass.IsOppAdmin__c == true),''+Util.adminByPassForOpportunity());
		System.assertEquals(''+(bypass.IsChannelLoad__c == true),''+Util.channelLoadByPass());
		bypass.IsAdmin__c = (bypass.IsAdmin__c != true);
		bypass.IsOppAdmin__c = (bypass.IsOppAdmin__c != true);
		bypass.IsChannelLoad__c = (bypass.IsChannelLoad__c != true);
		upsert bypass;
		System.assertEquals(''+(bypass.IsAdmin__c == true),''+Util.adminByPass());
		System.assertEquals(''+(bypass.IsOppAdmin__c == true),''+Util.adminByPassForOpportunity());
		System.assertEquals(''+(bypass.IsChannelLoad__c == true),''+Util.channelLoadByPass());
	}
}