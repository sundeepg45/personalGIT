/**
 * Opportunity_ELQConvertedAmount
 *
 * This trigger converts the opportunity amount to USD and populates the field ELQ_USD_AMT__c
 * to allow for reporting in the Eloqua campaign module
 *
 * @author Bryan Bosely <bbosely@redhat.com>
 */

trigger Opportunity_ELQConvertedAmount on Opportunity (before insert, before update) 
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    DatedCurrencyConversion dcc = new DatedCurrencyConversion();
    Set<String> currencyIsoCodes = new Set<String>();
    Set<Date> closeDates = new Set<Date>();
    
    //
    // obtain the currency iso codes and close dates from the trigger.new collection
    //
    
    for (Opportunity opp : Trigger.new)  {
        if(opp.CurrencyIsoCode != 'USD' && opp.Amount != null && opp.Amount != 0.0) {
            currencyIsoCodes.add( opp.currencyIsoCode );
            closeDates.add( opp.CloseDate );
        }
    }
    
    //
    // get the currency conversion map
    //
    
    Map<String, Map<Date, Double>> conversionMap = null;
    
    try
    {
        conversionMap = dcc.getConversionRateMap( currencyIsoCodes, closeDates);
    }
    catch ( Exception e )
    {
        system.debug( 'Unable to create conversion map: iso codes: ' + currencyIsoCodes + ' closeDates: ' + closeDates );
        
        //
        // shoot the dev team an email
        //
        
        String subjectText = 'Opportunity ELQ Converted Amount Trigger has experienced an exception';
        String bodyText = 'Unable to create conversion map - User: ' + UserInfo.getName() + ' : ' + UserInfo.getUserId() 
                        + ', iso codes: ' + currencyIsoCodes 
                        + ', closeDates: ' + closeDates 
                        + '\n' + e.getMessage();
                        
        dcc.notifyDevTeam( subjectText, bodyText );
    }
    
    //
    // calculate the converted amount for Eloqua 
    //
    
    for (Opportunity opp : Trigger.new) 
    {
        try
        {
            //
            // do not attempt to calculate a currency conversion for records 
            // that do not contain a value for amount
            //
            
            system.debug ( '-- opportunity amount: ' + opp.Amount );
            
            if ( opp.Amount == null || opp.Amount == 0 )
            {
                opp.ELQ_USD_AMT__c = 0.0;
                continue;
            }
            
            //
            // opportunities using USD as a currency do not need to be converted
            // populate the field ELQ_USD_AMT__c with the opportunity amount 
            //
            
            if ( opp.currencyIsoCode == 'USD' )
            {
                opp.ELQ_USD_AMT__c = opp.Amount;
                continue;
            }
                
            //
            // opportunities using currencies other than USD need to their amounts converted
            //
                
            Map<Date, Double> conversionRateMap = conversionMap.get( opp.CurrencyIsoCode );
            Double conversionRate = 0.0;
            
            //
            // when the close date of an opportunity is in the future
            // use the max date conversion rate
            //
            
            if ( opp.closeDate >= dcc.maxStartDateMap.get( opp.CurrencyIsoCode ) )
            {
                system.debug ( '-- opportunity close date after max date' );
                conversionRate = conversionRateMap.get( dcc.maxStartDateMap.get( opp.CurrencyIsoCode ) );  
            }
            else if ( opp.closeDate <= dcc.minStartDate )
            {
                system.debug ( '-- opportunity close date before min date' );
                conversionRate = conversionRateMap.get( dcc.minStartDate );
            }
            else
            {
                conversionRate = conversionRateMap.get( opp.CloseDate );
            } 
        
            system.debug ( '-- opportunity conversion rate: ' + conversionRate );
            system.debug ( '-- opportunity iso code: ' + opp.CurrencyIsoCode );
            system.debug ( '-- opportunity close date: ' + opp.closeDate );
            
            //
            // calculate the currency conversion
            //
            
            opp.ELQ_USD_AMT__c = ( opp.Amount / conversionRate );
        }
        catch ( system.MathException sme )
        {
            opp.ELQ_USD_AMT__c = 0.0;
            opp.addError( 'Unable to locate a conversion rate for opportunity: [ ' + opp.id + ', ' + opp.CurrencyIsoCode + ', ' + opp.closeDate + ']' );
        }
        catch ( Exception e)
        {
            opp.ELQ_USD_AMT__c = 0.0;
            system.debug( '' );
                
            //
            // shoot the dev team an email
            //
            
            String subjectText = 'Opportunity ELQ Converted Amount Trigger has experienced an exception';
            String bodyText = 'Unable to create conversion map - User: ' + UserInfo.getName() + ' : ' + UserInfo.getUserId() 
                        + ', iso codes: ' + currencyIsoCodes 
                        + ', closeDates: ' + closeDates 
                        + '\n' + e.getMessage();
                        
            dcc.notifyDevTeam( subjectText, bodyText );
        }
    }
}