/**
 * This is the test class for StrategicPlan_OppProdControllerExtn.
 *
 * @version 2013-08-08
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-08-08 - Rename OpportunityTriggerBeforeTest to OpportunityTriggerBefore2Test
 * 2013-05-23 - Updated test object references
 * 2013-04-23 - Created
 */
@isTest
private class StrategicPlan_OppProdControllerExtnTest {
	static StrategicPlan_OppProdSummary__c ops {
		get {
			if(ops == null) {
				StrategicPlan__c strategicPlan = StrategicPlanControllerExtnTest.strategicPlan;
				Opportunity opportunity = OpportunityTriggerBefore2Test.opportunity;
				opportunity.AccountId = strategicPlan.Account__c;
				Product2 product = OpportunityTriggerBefore2Test.product;
				ops = new StrategicPlan_OppProdSummary__c(
					Amount__c = 100.0,
					AmountUSD__c = 100.0,
					CurrencyIsoCode = 'USD',
					DateCaptured__c = System.today(),
					Forecast_Category__c = opportunity.ForecastCategoryName,
					Product__c = product.Id,
					Stage__c = opportunity.StageName,
					StrategicPlan__c = StrategicPlanControllerExtnTest.strategicPlanId );
				insert ops;
				ops.Product__r = product;
				ops.StrategicPlan__r = strategicPlan;
			}
			return ops;
		}		
	}

	@isTest(SeeAllData = true) // required so we can create a product
	static void unitTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_OppProdSummaryNew?ids='+ops.StrategicPlan__c));
		TabUIController controller = new TabUIController();
		StrategicPlan_OppProdControllerExtn extension = new StrategicPlan_OppProdControllerExtn(controller);
		System.assertEquals(ops.StrategicPlan__c,extension.getStrategicPlanId());
		extension.frequency = StrategicPlan_OppProdControllerExtn.DAILY;
		extension.forecastCategoryNames.add(ops.Forecast_Category__c);
		extension.stageNames.add(ops.Stage__c);
		List<AggregateResult> results = extension.timeData;
		System.assertEquals(1,results.size());
		System.assertEquals(ops.AmountUSD__c,results[0].get('totalUSD'));
		System.assertEquals(null,extension.refreshTimeData());
		extension.forecastCategoryNames.clear();
		results = extension.timeData;
		System.assertEquals(0,results.size());
		results = extension.currentValues;
		System.assertEquals(1,results.size());
		System.assertEquals(ops.AmountUSD__c,results[0].get('totalUSD'));
	}

	@isTest
	static void accessorTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_OppProdSummaryNew'));
		TabUIController controller = new TabUIController();
		StrategicPlan_OppProdControllerExtn extension = new StrategicPlan_OppProdControllerExtn(controller);
		System.assertNotEquals(null,extension.dateRange);
		System.assertNotEquals(null,extension.dateRange.Start__c);
		System.assertNotEquals(null,extension.dateRange.End__c);
		System.assertNotEquals(0,extension.frequencyOptions.size());
		System.assertNotEquals(null,extension.frequency);
		System.assertNotEquals(0,extension.forecastCategoryNameOptions.size());
		System.assertNotEquals(0,extension.forecastCategoryNames.size());
		System.assertNotEquals(0,extension.productOperatorOptions.size());
		System.assertNotEquals(null,extension.productOperator);
		extension.productCode = '<anything>';
		System.assertEquals('<anything>',extension.productCode);
		System.assertNotEquals(0,extension.productFamilyOptions.size());
		System.assertNotEquals(0,extension.productFamilies.size());
		System.assertNotEquals(0,extension.stageNameOptions.size());
		System.assertNotEquals(0,extension.stageNames.size());
	}
}