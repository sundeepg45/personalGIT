/**
* Class Name:DatedCurrencyRate_ConverterTest
* Author:Accenture
* Date:4/28/2011
* Description:Test Class created for DatedCurrencyRate_Converter business Class.
* Modificaton History:
* Modified By : Nitesh Dokania
* Modified date :4/28/2011
* Reason for Modification: Separated test class from business class and created a new test class
*/

@isTest
private class DatedCurrencyRate_ConverterTest
{
    public static testmethod void testGenerateCodeCoverage() {
            DatedCurrencyRate_Converter d = new DatedCurrencyRate_Converter();
            Decimal a = new DatedCurrencyRate_Converter(1, 'USD', 'EUR').getTargetAmount();
        }
}