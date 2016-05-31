/**
 * Test class for Opportunity_ELQConvertedAmountTest.cls
 *
 * @author  Bryan Bosely <bbosely@redhat.com>
 * @date	04/28/10
 */

@isTest
private class Opportunity_ELQConvertedAmountTest
{
	static Account ACCOUNT {
		get {
			if(ACCOUNT == null) {
				// create an account
				ACCOUNT = new Account(
					BillingCity = 'Raleigh',
					BillingCountry = 'US',
					BillingPostalCode = '27606',
					BillingState = 'North Carolina',
					BillingStreet = '1801 Varsity Drive',
					Name = 'Red Hat',
					OracleAccountNumber__c = '12345',
					ShippingCity = 'Raleigh',
					ShippingCountry = 'US',
					ShippingPostalCode = '27606',
					ShippingState = 'North Carolina',
					ShippingStreet = '1801 Varsity Drive',
					VATNumber__c = '67890');
				insert ACCOUNT;
			}
			return ACCOUNT;
		}
	}

	static Opportunity queryOpportunity(Opportunity opp) {
		if(opp.Id == null) {
			insert opp;
		}
		return [
			SELECT ELQ_USD_AMT__C
			FROM Opportunity
			WHERE Id = :opp.Id ];
	}

	static Opportunity createOpportunity(Date closeDate,String currencyIsoCode) {
		return new Opportunity(
			AccountId = ACCOUNT.Id,
			Amount = 50000,
			CloseDate = closeDate,
			Country_Of_Order__c = 'US',
			CurrencyIsoCode = currencyIsoCode,
			Name = 'Opportunity',
			OpportunityType__c = 'Standard',
			PaymentType__c = 'NA Purchase Order',
			StageName = 'Unqualified');
	}

	static testMethod void testConversionRate()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		// get the conversion rate
		DatedConversionRate dcr = [
			SELECT
				ConversionRate,
				StartDate
			FROM DatedConversionRate
			WHERE IsoCode = 'INR'
				AND StartDate = 2010-05-01 ];

		Opportunity opportunity = createOpportunity(Date.newInstance(2010, 05, 01),'INR');
		system.assertEquals( ( opportunity.amount / dcr.conversionRate ), queryOpportunity(opportunity).ELQ_USD_AMT__c);
	}

	static testMethod void testConversionRateFutureDate()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		//
		// get the conversion rate for the max start date
		//
		DatedConversionRate dcr = [
			SELECT
				ConversionRate,
				StartDate
			FROM DatedConversionRate
			WHERE IsoCode = 'INR'
			Order By StartDate Desc LIMIT 1 ];

		Opportunity opportunity = createOpportunity(Date.today().addDays(15),'INR');
		system.assertEquals( ( opportunity.amount / dcr.conversionRate ), queryOpportunity(opportunity).ELQ_USD_AMT__c);
	}


	static testMethod void testConversionRateUSCurrencyCode()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Opportunity opportunity = createOpportunity(Date.newInstance(2010, 05, 01),'USD');
		system.assertEquals( opportunity.amount, queryOpportunity(opportunity).ELQ_USD_AMT__c);
	}


	static testMethod void testConversionRateAmountZero()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		Opportunity opportunity = createOpportunity(Date.newInstance(2010, 05, 01),'JPY');
		opportunity.Amount = 0.0;
		system.assertEquals( 0.0, queryOpportunity(opportunity).ELQ_USD_AMT__c);
	}


	static testMethod void testBulkConversion()
	{
		DeactivateAllTestUtil.setDeactivateAll(false);

		// create bulk opportunties
		List<Opportunity> opportunities = new List<Opportunity>{
			createOpportunity(Date.newInstance(2000, 05, 01),'INR'),
			createOpportunity(Date.newInstance(2000, 05, 01),'USD'),
			createOpportunity(Date.newInstance(2000, 05, 01),'INR'),
			createOpportunity(Date.newInstance(2000, 05, 01),'USD'),
			createOpportunity(Date.newInstance(2000, 05, 01),'INR') };
		insert opportunities;

		// obtain the opps and check that the ELQ_USD_AMT__c amount is populated
		List<Opportunity> insertedOpportunities = [
			SELECT ELQ_USD_AMT__c
			FROM Opportunity
			WHERE Id IN :opportunities ];
		for ( Opportunity opportunity : [
			SELECT ELQ_USD_AMT__c
			FROM Opportunity
			WHERE Id IN :opportunities ])
		{
			system.assert( opportunity.ELQ_USD_AMT__c > 0.0, opportunity.ELQ_USD_AMT__c+' should be greater than 0' );
		}
	}
}