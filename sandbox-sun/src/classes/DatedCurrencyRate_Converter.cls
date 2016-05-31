/**
* Class Name: DatedCurrencyRate_Converter
* Author: Accenture
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date : 4/28/2011
* Reason for Modification: Separated test class from business class.
*/

public with sharing class DatedCurrencyRate_Converter {
    private Decimal sourceAmount = 0;
    private String sourceCurrency = 'USD';
    private String targetCurrency = 'USD';
    private Boolean legacyConversion = false;
    private Map<String, Double> conversionMap;
    
    private static List<DatedConversionRate> datedConversionRateList = [
        select ConversionRate
             , IsoCode
          from DatedConversionRate
         where StartDate <= :Date.Today()
           and NextStartDate > :Date.Today()
    ];
    
    private static List<CurrencyType> currencyTypeList = [
        select ConversionRate
             , IsoCode
          from CurrencyType
    ];
    
    public DatedCurrencyRate_Converter() {}
    
    public DatedCurrencyRate_Converter(Decimal sourceAmount, String sourceCurrency, String targetCurrency) {
        setSourceAmount(sourceAmount);
        setSourceCurrency(sourceCurrency);
        setTargetCurrency(targetCurrency);
    }

    public void setLegacyConversion(Boolean legacyConversion) {
        if (this.legacyConversion != legacyConversion) {
            this.legacyConversion = legacyConversion;
            this.conversionMap = null; // clear existing mapping if any
        }
    }
    
    public void setSourceAmount(Decimal sourceAmount) {
        if (sourceAmount != null)
           this.sourceAmount = sourceAmount;
    }
    
    public void setSourceCurrency(String sourceCurrency) {
        if (sourceCurrency != null)
            this.sourceCurrency = sourceCurrency;
    }
    
    public void setTargetCurrency(String targetCurrency) {
        if (targetCurrency != null)
            this.targetCurrency = targetCurrency;
    }
     
    public Decimal getTargetAmount() {
        return legacyConversion ? getTargetAmountByCurrencyType() : getTargetAmountByDatedConversionRate();
    }
    
    public Decimal getTargetAmountByDatedConversionRate() {
        if (conversionMap == null) {
            conversionMap = new Map<String, Double>();
            
            for (DatedConversionRate rate : datedConversionRateList)
                conversionMap.put(rate.IsoCode, rate.ConversionRate);
        }
        
        return sourceAmount * (conversionMap.get(targetCurrency) / conversionMap.get(sourceCurrency));
    }
    
    public Decimal getTargetAmountByCurrencyType() {
        if (conversionMap == null) {
            conversionMap = new Map<String, Double>();
            
            for (CurrencyType rate : currencyTypeList)
                conversionMap.put(rate.IsoCode, rate.ConversionRate);
        }
        
        return sourceAmount * (conversionMap.get(targetCurrency) / conversionMap.get(sourceCurrency));
    }
}