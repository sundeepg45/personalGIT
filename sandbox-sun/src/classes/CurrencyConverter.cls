public with sharing class CurrencyConverter {
	public static final Integer PRECISION = 10;
	
    private Decimal sourceAmount = 0;
    private String sourceCurrency = 'USD';
    private String targetCurrency = 'USD';
    private Boolean legacyConversion = false;
    private Boolean roundingEnabled = false;
    private Map<String, Decimal> datedConversionRateMap;
    private Map<String, Decimal> currencyTypeMap;
    
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
    
    public CurrencyConverter() {}
    
    public CurrencyConverter(Decimal sourceAmount, String sourceCurrency, String targetCurrency) {
        setSourceAmount(sourceAmount);
        setSourceCurrency(sourceCurrency);
        setTargetCurrency(targetCurrency);
    }

    public void setLegacyConversion(Boolean legacyConversion) {
        this.legacyConversion = legacyConversion;
    }
    
    public void setRoundingEnabled(Boolean roundingEnabled) {
        this.roundingEnabled = roundingEnabled;
    }
    
    public void setSourceAmount(Decimal sourceAmount) {
        this.sourceAmount = sourceAmount;
    }
    
    public void setSourceCurrency(String sourceCurrency) {
        this.sourceCurrency = sourceCurrency;
    }
    
    public void setTargetCurrency(String targetCurrency) {
        this.targetCurrency = targetCurrency;
    }
     
    public Decimal getTargetAmount() {
    	Decimal targetAmount = 0.00;
    	
    	if (sourceCurrency == targetCurrency)
    	    targetAmount = sourceAmount; 
    	else if (legacyConversion)
    	    targetAmount = getTargetAmountByCurrencyType();
    	else 
    	    targetAmount = getTargetAmountByDatedConversionRate();
    	    
    	if (roundingEnabled)
    	    targetAmount = Decimal.valueOf((targetAmount * 100).round()).divide(100, 2);
    	
    	return targetAmount;
    }
    
    public Decimal getTargetAmountByDatedConversionRate() {
        if (datedConversionRateMap == null) {
            datedConversionRateMap = new Map<String, Decimal>();
            
            for(DatedConversionRate rate : datedConversionRateList)
                datedConversionRateMap.put(rate.IsoCode, rate.ConversionRate);
        }
        
        return sourceAmount * datedConversionRateMap.get(targetCurrency).divide(datedConversionRateMap.get(sourceCurrency), PRECISION);
    }
    
    public Decimal getTargetAmountByCurrencyType() {
        if (currencyTypeMap == null) {
            currencyTypeMap = new Map<String, Decimal>();
            
            for(CurrencyType rate : currencyTypeList)
                currencyTypeMap.put(rate.IsoCode, rate.ConversionRate);
        }
        
        return sourceAmount * currencyTypeMap.get(targetCurrency).divide(currencyTypeMap.get(sourceCurrency), PRECISION);
    }
    
}