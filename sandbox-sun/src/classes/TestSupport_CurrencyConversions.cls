public with sharing class TestSupport_CurrencyConversions {
    public TestSupport_CurrencyConversions() {}
    
    public List<DatedConversionRate> getDatedConversionRateList() {
    	return [
            select ConversionRate
                 , IsoCode
              from DatedConversionRate
             where StartDate <= :Date.Today()
               and NextStartDate > :Date.Today()
        ];
    }

    public List<CurrencyType> getCurrencyTypeList() {
        return [
            select ConversionRate
                 , IsoCode
              from CurrencyType
        ];
    }
}