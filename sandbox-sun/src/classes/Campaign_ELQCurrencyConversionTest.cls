/**
 * Depreciated
 * Test class for Opportunity_ELQConvertedAmount.cls
 *
 * @author  Bryan Bosely <bbosely@redhat.com>
 * @date    08/02/11
 */
 
@isTest
private class Campaign_ELQCurrencyConversionTest { /*

	static CurrencyType ct;
    
    static 
    {
    	//
    	// get the conversion rate
    	//
    	
        ct = [SELECT IsoCode
        	   , ConversionRate 
        	FROM CurrencyType
           WHERE IsoCode = 'INR'
	    ];
    }
	
	static Campaign createCampaign( Decimal actualCost, Decimal budgetedCost, String currencyIsoCode )
	{
		//
        // create a campaign
        //
        
		Campaign campaign = new Campaign();
        campaign.Type='Email Link';
        campaign.mkt_cl_cmp_ad_name__c ='Acn';
        campaign.mkt_cl_parent_campaign_name__c='Parent1';
        campaign.mkt_cl_cmp_media_name__c='Star';
        campaign.Type='Banner Ad';
        campaign.mkt_cl_cmp_is_internal__c=true;
        campaign.mkt_cl_cmp_audience__c='VP';
        campaign.mkt_cl_cmp_director__c='Emma Battle';
        campaign.mkt_cl_cmp_category__c = 'GLS';
        campaign.mkt_cl_cmp_vertical__c = 'Manufacturing';
        campaign.Campaign_Partner__c = 'OEM';
        campaign.mkt_cl_cmp_geo__c='NA';
        campaign.mkt_cl_cmp_cta__c='Renew';
        campaign.mkt_cl_cmp_product_group__c= 'Multiple';
        campaign.Origin__c= 'Sales';
        campaign.Media_Source__c='CNET';
        campaign.Landing_Page_URL__c= 'http://Sf.com';
        campaign.Notes_for_Sales__c = 'Text';
        campaign.Description = 'Text';
        campaign.Status = 'Plannned';
        campaign.Name = 'Name';
        campaign.ActualCost = actualCost;
        campaign.BudgetedCost = budgetedCost;
        campaign.CurrencyIsoCode = currencyIsoCode;
        insert campaign;
	    	    
	    //
	    // retrieve the calculated amounts
	    //
	    
	    Campaign updatedCampaign = [SELECT Id
	    		, ActualCost
	    		, BudgetedCost
	    		, CurrencyIsoCode
	    		, ELQ_USD_ActualCost__c
	    		, ELQ_USD_BudgetedCost__c
	    	 FROM Campaign
	    	WHERE Id = :campaign.Id
	    ];
	    
	    return updatedCampaign;
	}
	
	
    static testMethod void testConversionRate() 
    {
	 	Campaign campaign = createCampaign( 1000.00, 500.00, 'INR' );   
	    system.assertEquals( campaign.ELQ_USD_ActualCost__c , ( campaign.ActualCost / ct.conversionRate ));
	   	system.assertEquals( campaign.ELQ_USD_BudgetedCost__c , ( campaign.BudgetedCost / ct.conversionRate ));
    }
    
    
    
    static testMethod void testConversionRateUSCurrencyCode() 
    {   
	    Campaign campaign = createCampaign( 1000.00, 500.00, 'USD' );  
	    system.assertEquals( campaign.ELQ_USD_ActualCost__c , campaign.ActualCost );
	   	system.assertEquals( campaign.ELQ_USD_BudgetedCost__c , campaign.BudgetedCost );
    }
    
    
    static testMethod void testConversionRateAmountZero() 
    {   
	    Campaign campaign = createCampaign( 0.0, 0.0, 'INR' );  
	    system.assertEquals( campaign.ELQ_USD_ActualCost__c , 0.0 );
	   	system.assertEquals( campaign.ELQ_USD_BudgetedCost__c , 0.0 );
    }
*/
}