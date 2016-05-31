/**
* Class Name:CurrencyConverterTest
* Description:Test Class created for CurrencyConverter business Class.
* Modificaton History:
* Modified By :Abhijeet Anand
* Reason for Modification:Enhanced code coverage and added assert statements.
*/
@IsTest
private class CurrencyConverterTest 
{
    public static Decimal getDatedConversionRate(String isoCode) 
    {
        return [
            select ConversionRate
              from DatedConversionRate
             where IsoCode = :isoCode
          order by NextStartDate desc
             limit 1
        ].ConversionRate;
    }
    
    public static Decimal getCurrencyType(String isoCode) 
    {
        return [
            select ConversionRate
              from CurrencyType
             where IsoCode = :isoCode
             limit 1
        ].ConversionRate;
    }
    
    public static void testConversion(String sourceCurrency, String targetCurrency, Boolean roundingEnabled, Boolean legacyConversion) 
    {
        Decimal sourceCurrencyRate = 0.0;
        Decimal targetCurrencyRate = 0.0;
        Decimal dec = 1000;
        
        if (legacyConversion) 
        {
            sourceCurrencyRate = getCurrencyType(sourceCurrency);
            targetCurrencyRate = getCurrencyType(targetCurrency);
        } 
        else 
        {
            sourceCurrencyRate = getDatedConversionRate(sourceCurrency);
            targetCurrencyRate = getDatedConversionRate(targetCurrency);
        }
        
        
        CurrencyConverter converter = new CurrencyConverter();
        converter.setSourceAmount(1000.00);
        converter.setSourceCurrency(sourceCurrency);
        converter.setTargetCurrency(targetCurrency);
        converter.setRoundingEnabled(roundingEnabled); 
        converter.setLegacyConversion(legacyConversion);
        
        CurrencyConverter cnvrtr = new CurrencyConverter(1000.00,sourceCurrency,targetCurrency);

        Decimal conversionRate = targetCurrencyRate.divide(sourceCurrencyRate, CurrencyConverter.PRECISION);
        Decimal expectedAmount = conversionRate * 1000.00;
        Decimal receivedAmount = converter.getTargetAmount();
    
        // Is rounding enabled?
        if (roundingEnabled)
            expectedAmount = Decimal.valueOf((expectedAmount * 100).round()).divide(100, 2);
        

        System.assertEquals(expectedAmount, receivedAmount);
        
        //
        // Validate conversion in reverse.
        //
    }
    
    /**
      * Dated conversion rate
      */
    public static void testDatedConversionRate(String sourceCurrency, String targetCurrency) {
        testConversion(sourceCurrency, targetCurrency, false, false);
    }

    public static void testDatedConversionRate(String sourceCurrency, String targetCurrency, Boolean roundingEnabled) {
        testConversion(sourceCurrency, targetCurrency, roundingEnabled, false);
    }
    
    public static testmethod void testDatedConversionRate_USD_USD() {
        test.startTest();
        testDatedConversionRate('USD', 'USD');
        test.stopTest();
    }

    public static testmethod void testDatedConversionRate_USD_JPY() {
        test.startTest();
        testDatedConversionRate('USD', 'JPY');
        test.stopTest();
    }

    public static testmethod void testDatedConversionRate_JPY_USD() {
        test.startTest();
        testDatedConversionRate('JPY', 'USD');
        test.stopTest();
    }

    public static testmethod void testDatedConversionRate_USD_EUR() {
        test.startTest();
        testDatedConversionRate('USD', 'EUR');
        test.stopTest();
    }

    public static testmethod void testDatedConversionRate_EUR_USD() {
        test.startTest();
        testDatedConversionRate('EUR', 'USD');
        test.stopTest();
    }
    
    public static testmethod void testDatedConversionRate_EUR_JPY() {
        test.startTest();
        testDatedConversionRate('EUR', 'JPY');
        test.stopTest();
    }

    public static testmethod void testDatedConversionRate_JPY_EUR() {
        test.startTest();
        testDatedConversionRate('JPY', 'EUR');
        test.stopTest();
    }
    
    public static testmethod void testDatedConversionRate_GBP_KRW() {
        test.startTest();
        testDatedConversionRate('GBP', 'KRW');
        test.stopTest();
    }
    
    public static testmethod void testDatedConversionRate_GBP_KRW_WithRoundingEnabled() {
        test.startTest();
        testDatedConversionRate('GBP', 'KRW', true);
        test.stopTest();
    }
    
    public static testmethod void testDatedConversionRate_KRW_GBP() {
        test.startTest();
        testDatedConversionRate('KRW', 'GBP');
        test.stopTest();
    }
    
    public static testmethod void testDatedConversionRate_KRW_GBP_WithRoundingEnabled() {
        test.startTest();
        testDatedConversionRate('KRW', 'GBP', true);
        test.stopTest();
    }
    
    /**
      * CurrencyType tests
      */

    public static void testCurrencyType(String sourceCurrency, String targetCurrency) {
        testConversion(sourceCurrency, targetCurrency, false, true);
    }
    
    public static void testCurrencyType(String sourceCurrency, String targetCurrency, Boolean roundingEnabled) {
        testConversion(sourceCurrency, targetCurrency, roundingEnabled, true);
    }
    
    public static testmethod void testCurrencyType_USD_USD() {
        test.startTest();
        testCurrencyType('USD', 'USD');
        test.stopTest();
    }

    public static testmethod void testCurrencyType_USD_JPY() {
        test.startTest();
        testCurrencyType('USD', 'JPY');
        test.stopTest();
    }

    public static testmethod void testCurrencyType_JPY_USD() {
        test.startTest();
        testCurrencyType('JPY', 'USD');
        test.stopTest();
    }

    public static testmethod void testCurrencyType_USD_EUR() {
        test.startTest();
        testCurrencyType('USD', 'EUR');
        test.stopTest();
    }

    public static testmethod void testCurrencyType_EUR_USD() {
        test.startTest();
        testCurrencyType('EUR', 'USD');
        test.stopTest();
    }
    
    public static testmethod void testCurrencyType_EUR_JPY() {
        test.startTest();
        testCurrencyType('EUR', 'JPY');
        test.stopTest();
    }
    
    public static testmethod void testCurrencyType_JPY_EUR() {
        test.startTest();
        testCurrencyType('JPY', 'EUR');
        test.stopTest();
    }
    
    public static testmethod void testCurrencyType_GBP_KRW() {
        test.startTest();
        testCurrencyType('GBP', 'KRW');
        test.stopTest();
    }
    
    public static testmethod void testCurrencyType_GBP_KRW_WithRoundingEnabled() {
        test.startTest();
        testCurrencyType('GBP', 'KRW', true);
        test.stopTest();
    }
    
    public static testmethod void testCurrencyType_KRW_GBP() {
        test.startTest();
        testCurrencyType('KRW', 'GBP');
        test.stopTest();
    }
    
    public static testmethod void testCurrencyType_KRW_GBP_WithRoundingEnabled() {
        test.startTest();
        testCurrencyType('KRW', 'GBP', true);
        test.stopTest();
    }
    
}