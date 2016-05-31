/**
 * This is a test class for DatedCurrencyConversion.
 * 
 * @version 2013-04-25
 * @author Bill Riemers <briemers@redhat.com>
 * 2013-04-25 - Created
 */
@IsTest
private class DatedCurrencyConversionTest extends DatedCurrencyConversion {

	public Integer validateConversionRateFake = 0;

	protected override List<ConversionRate> validateConversionRates( Set<String> isoCodes, List<Date> dates ) {
		Map<String, Map<Date, Double>> savedMap = conversionMap; 
		if(validateConversionRateFake-- > 0) {
			conversionMap = new Map<String,Map<Date,Double>>(savedMap);
			for(String isoCode : isoCodes) {
				conversionMap.put(isoCode,new Map<Date,Double>());
			}
		}
		List<ConversionRate> retval = super.validateConversionRates(isoCodes,dates);
		conversionMap = savedMap;
		return retval;
	}

	@IsTest
	public static void conversionRateTest() {
		Date d1 = Date.newInstance(2012,1,1);
		Date d2 = Date.newInstance(2013,1,1);
		Date d3 = System.today();
		Date d4 = d3.addDays(7);
		Set<String> isoCodes = new Set<String>{'USD','EUR','CAD'};
		Set<Date> dates = new Set<Date>{d1,d2,d3,d4};
		Test.startTest();
		DatedCurrencyConversion dcc = new DatedCurrencyConversion();
		Map<String, Map<Date, Double>> conversionMap = dcc.getConversionRateMap(
			isoCodes,
			dates );
		DatedCurrencyConversionTest dcc2 = new DatedCurrencyConversionTest();
		dcc2.validateConversionRateFake = 1;
		Map<String, Map<Date, Double>> conversionMap2 = dcc2.getConversionRateMap(
			isoCodes,
			dates );
		Test.stopTest();
		System.assertNotEquals(0,conversionMap.size());
		Map<Date,Double> eurMap = conversionMap.get('EUR');
		Map<Date,Double> cadMap = conversionMap.get('CAD');
		System.assertNotEquals(null,eurMap);
		System.assertNotEquals(0,eurMap.size());
		System.assertNotEquals(null,cadMap);
		System.assertNotEquals(0,cadMap.size());
		System.assertEquals(null,conversionMap.get('USD'));
		System.assert(eurMap.get(d3) > 0,'Failed to get a EUR conversion rate for today');
		System.assertEquals(eurMap.get(d3),eurMap.get(d4),'Failed to get a EUR conversion rate for next week');
		System.assert(cadMap.get(d3) > 0,'Failed to get a EUR conversion rate for today');
		System.assertEquals(cadMap.get(d3),cadMap.get(d4),'Failed to get a CAD conversion rate for next week');
		// these checks will break if we change the currency tables
		System.assertEquals(7714,Math.roundToLong(10000.00*eurMap.get(d1)));
		System.assertEquals(7558,Math.roundToLong(10000.00*eurMap.get(d2)));
		System.assertEquals(10213,Math.roundToLong(10000.00*cadMap.get(d1)));
		System.assertEquals(9920,Math.roundToLong(10000.00*cadMap.get(d2)));
		System.assertEquals(conversionMap,conversionMap2);
	}

	@IsTest
	public static void noConversionRateTest() {
		Date d1 = Date.newInstance(2012,1,1);
		Test.startTest();
		DatedCurrencyConversionTest dcc2 = new DatedCurrencyConversionTest();
		dcc2.validateConversionRateFake = 2;
		Map<String, Map<Date, Double>> conversionMap2 = dcc2.getConversionRateMap(
			new Set<String>{'EUR'},
			new Set<Date>{d1} );
		Test.stopTest();
	}
}