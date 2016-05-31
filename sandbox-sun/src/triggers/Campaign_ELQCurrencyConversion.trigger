/**
 * Campaign_ELQCurrencyConversion
 *
 * This trigger converts the 
 * to allow for reporting in the Eloqua campaign module
 *
 * @author Bryan Bosely <bbosely@redhat.com>
 */

trigger Campaign_ELQCurrencyConversion on Campaign (before insert, before update) 
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    //
    // create the currency conversion map
    //
    
    List<CurrencyType> currencyTypeList = [ SELECT IsoCode, ConversionRate FROM CurrencyType ];
    Map<String, Double> conversionRateMap = new Map<String, Double>();

    for ( CurrencyType ct : currencyTypeList )
    {
        conversionRateMap.put( ct.IsoCode, ct.ConversionRate ); 
    }
    
    //
    // calculate the actual cost, and budgeted cost in USD for Eloqua 
    //
    
    for (Campaign campaign : Trigger.new) 
    {   
        //
        // do not attempt to calculate a currency conversion for records 
        // that do not contain a value for actualCost, budgetedCost
        //
        
        system.debug ( '-- actual cost: ' + campaign.ActualCost );
        system.debug ( '-- budgeted cost: ' + campaign.BudgetedCost );
        
        if ( campaign.ActualCost == null || campaign.ActualCost == 0 || campaign.BudgetedCost == null || campaign.BudgetedCost == 0 )
        {
            campaign.ELQ_USD_ActualCost__c = 0.0;
            campaign.ELQ_USD_BudgetedCost__c = 0.0;
            
            continue;
        }
        
        //
        // campaigns using USD as a currency do not need to be converted
        // populate the fields ??? with the actual cost and the budgeted cost 
        //
        
        if ( campaign.currencyIsoCode == 'USD' )
        {
            campaign.ELQ_USD_ActualCost__c = campaign.ActualCost;
            campaign.ELQ_USD_BudgetedCost__c = campaign.BudgetedCost;
            continue;
        }
            
        //
        // campaigns using currencies other than USD need the actualCost, budgetedCost converted
        //
        
        Double conversionRate = conversionRateMap.get( campaign.CurrencyIsoCode );
    
        system.debug ( '-- campaign conversion rate: ' + conversionRate );
        system.debug ( '-- campaign iso code: ' + campaign.CurrencyIsoCode );
        
        //
        // calculate the currency conversion
        //
        
        try 
        {
            campaign.ELQ_USD_ActualCost__c = ( campaign.ActualCost / conversionRate );
            campaign.ELQ_USD_BudgetedCost__c = ( campaign.BudgetedCost / conversionRate );
        }
        catch ( system.MathException sme )
        {
            campaign.ELQ_USD_ActualCost__c = 0.0;
            campaign.ELQ_USD_BudgetedCost__c = 0.0;
            campaign.addError( 'Unable to locate a conversion rate for campaign: [ ' + campaign.id + ', ' + campaign.CurrencyIsoCode + ']' );
        }
    }
}