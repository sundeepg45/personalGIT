/*
 * Class to recalculate the amounts on the budget, in case sometime the budgets amounts are not
 * in sync[Triggers go bad or record is manually updated]
 * 
 * @version 2015-05-08
 * @author unknown
 * Bill C Riemers <briemers@redhat.com>
 * 2015-05-08 - Refactored test method into a separate class from Recalculate Budget
*/
global class RecalculateBudget {

    /*
    * Called from the recalculate button on the budget object.
    * recalculates the fund request and the fund claim amounts
    */  
    @TestVisible
    static String budgetCurrency='';

    WebService static void calculate(String budgetId) {
        
          SFDC_Budget__c objbudget = [Select Id, Approved_Requests__c,Approved_Claims__c,Requests_Submitted__c,
                Requests_Awaiting_Approval__c,Claims_Submitted__c,Claims_Awaiting_Approval__c, Unclaimed_Requests2__c, Last_Refresh_Date__c,CurrencyIsoCode 
                    From SFDC_Budget__c Where Id = :budgetId];

            
        budgetCurrency = objbudget.CurrencyIsoCode;

        Decimal fundRequestAmount = getFundRequestAmount(budgetId);
        Decimal fundClaimAmount = getFundClaimAmount(budgetId);
        Decimal fundRequestAmount1 = getFundRequestSubmittedAmount(budgetId);
        Decimal fundAwaitingAmount = getFundRequestAwaitingApp(budgetId);
        Decimal fundClaimSubAmt=getFundClaimSubmiited(budgetId);
        Decimal fundClaimAwtAmt=getFundClaimAwaitingApp(budgetId);
        Decimal fundReqUnclaimedAmt =getfundReqUnclaimedAmt(budgetId); 
                        
      
            System.debug('budgetCurrency -- '+budgetCurrency);

            objbudget.Approved_Requests__c=fundRequestAmount;
            objbudget.Approved_Claims__c=fundClaimAmount;
            objbudget.Requests_Submitted__c=fundRequestAmount1;
            objbudget.Requests_Awaiting_Approval__c=fundAwaitingAmount;
            objbudget.Claims_Submitted__c=fundClaimSubAmt;
            objbudget.Claims_Awaiting_Approval__c=fundClaimAwtAmt;
            objbudget.Last_Refresh_Date__c=System.now();
            objbudget.Unclaimed_Requests2__c= (fundRequestAmount - fundReqUnclaimedAmt);
           // objbudget.Active__c=true;

        try {
            update objbudget;
        System.Debug('budget updated'+objbudget);
        } catch (DmlException e) {
            System.debug('Update Failed: ' + e);
            throw e; //the javascript should get it
        }       
        
    }
    
    @TestVisible
     private static Decimal getConvertedCurrencyValue(Decimal Value,String currentCurrency,String targetCurrency)
        {
            
            Decimal convertedAmt;
            if(currentCurrency!=targetCurrency){
                Decimal targetCurrencyRate =1; 
                Decimal currentCurrencyRate =1;
                List <CurrencyType> currencyConversions=[Select Id,ConversionRate, IsoCode from CurrencyType where IsoCode=:currentCurrency OR IsoCode=:targetCurrency];   
                for(CurrencyType ct  :currencyConversions){
                    if(ct.IsoCode==currentCurrency){
                        currentCurrencyRate=ct.ConversionRate;
                    }else{
                        targetCurrencyRate=ct.ConversionRate;
                    }
                }
                // curent --->USD ---> Target
                convertedAmt = (Value/currentCurrencyRate)*targetCurrencyRate;
                System.Debug('convertedAmt'+convertedAmt);          
            }else{
                convertedAmt=Value;
            }


            return convertedAmt;
        }

    /*
    * recalculates and returns the fund request amount
    */  
    @TestVisible
    private static Decimal getFundRequestAmount(String budgetId) {
        //get all approved fund requests for the budget
        List<SFDC_MDF__c> fundRequests = [Select Id, Estimated_Red_Hat_Funding_Requested__c, CurrencyIsoCode From SFDC_MDF__c 
            Where Budget__c = :budgetId And Approval_Status__c = 'Approved'];

        //recalculate amount
        Decimal fundRequestAmount = 0;
        for (SFDC_MDF__c fundRequest : fundRequests) 
        {
            Decimal amount = fundRequest.Estimated_Red_Hat_Funding_Requested__c ;
            String RequestCurrency=fundRequest.CurrencyIsoCode ;

            if(amount!=null)
            {
                Decimal convertedamount=getConvertedCurrencyValue(amount,RequestCurrency,budgetCurrency);
                if (convertedamount != null) fundRequestAmount += convertedamount;
            }

        }
        System.Debug('fundRequestAmount'+fundRequestAmount);
        return fundRequestAmount;

    }
    
     /*
    * recalculates and returns the Requests Submitted amount.
    */  
    @TestVisible
    private static Decimal getFundRequestSubmittedAmount(String budgetId) {
        //get all approved fund requests for the budget
        List<SFDC_MDF__c> fundRequests_1 = [Select Id, Estimated_Red_Hat_Funding_Requested__c,CurrencyIsoCode From SFDC_MDF__c 
            Where Budget__c = :budgetId And Approval_Status__c IN ('Pending First Approval','Approved','Pending Final Approval')];

        //recalculate amount
        Decimal fundRequestAmount1 = 0;
        for (SFDC_MDF__c fundRequest : fundRequests_1) 
            {
                Decimal Submitamount = fundRequest.Estimated_Red_Hat_Funding_Requested__c;
                String RequestCurrency=fundRequest.CurrencyIsoCode ;

                if (Submitamount != null)
                {
                    Decimal convertedamount=getConvertedCurrencyValue(Submitamount,RequestCurrency,budgetCurrency);
                    if (convertedamount != null) fundRequestAmount1 += convertedamount;
                 //  System.Debug('in side if fundRequestAmount1'+fundRequestAmount1);      

                }
                // System.Debug('out side if fundRequestAmount1'+fundRequestAmount1);     
          }
         //System.Debug('finally fundRequestAmount1'+fundRequestAmount1);
        return fundRequestAmount1;
        
    }
    
     
    /*
    * recalculates and returns the Requests Awaiting Approval amount
    */  
    @TestVisible
    private static Decimal getFundRequestAwaitingApp(String budgetId) {
        //get all approved fund requests for the budget
        List<SFDC_MDF__c> fundRequests2 = [Select Id, Estimated_Red_Hat_Funding_Requested__c,CurrencyIsoCode From SFDC_MDF__c 
            Where Budget__c = :budgetId And Approval_Status__c IN ('Pending First Approval','Pending Final Approval')];

        //recalculate amount
        Decimal fundAwaitingAmount = 0;
        for (SFDC_MDF__c fundRequest : fundRequests2) {
            Decimal awaitingAmount = fundRequest.Estimated_Red_Hat_Funding_Requested__c;
            String RequestCurrency=fundRequest.CurrencyIsoCode ;

            if (awaitingAmount != null) 
            {   
                Decimal convertedamount=getConvertedCurrencyValue(awaitingAmount,RequestCurrency,budgetCurrency);  
                if (convertedamount != null)fundAwaitingAmount += convertedamount;
            }
        }
         System.Debug('fundAwaitingAmount'+fundAwaitingAmount);
        return fundAwaitingAmount;
    }


    /*
    * recalculates and returns the fund claim amount
    */  
    @TestVisible
    private static Decimal getFundClaimAmount(String budgetId) {
        //get all approved FundClaims for this budget
        List<SFDC_MDF_Claim__c> fundClaims = [Select Id, Requested_Amount__c,CurrencyIsoCode From SFDC_MDF_Claim__c 
            Where Budget__c = :budgetId And Approval_Status__c = 'Approved'];

        //recalculate amount
        Decimal fundClaimAmount = 0;
        for (SFDC_MDF_Claim__c fundClaim : fundClaims) {
            Decimal amount = fundClaim.Requested_Amount__c;
            String RequestCurrency=fundClaim.CurrencyIsoCode ;

            if (amount != null) 
            {   
                Decimal convertedamount=getConvertedCurrencyValue(amount,RequestCurrency,budgetCurrency);  
                if (convertedamount != null)fundClaimAmount += convertedamount;
            }
        }
         System.Debug('fundClaimAmount'+fundClaimAmount);
        return fundClaimAmount;
    }
    

    /*
    * recalculates and returns the Claims Submitted.
    */  
    @TestVisible
    private static Decimal getFundClaimSubmiited(String budgetId) {
        //get all approved FundClaims for this budget
        List<SFDC_MDF_Claim__c> fundSubClaims = [Select Id, Requested_Amount__c,CurrencyIsoCode From SFDC_MDF_Claim__c 
            Where Budget__c = :budgetId And Approval_Status__c IN ('Pending First Approval','Approved','Pending Second Approval','Pending Final Approval')];
            
        //recalculate amount
        Decimal fundClaimSubAmt = 0;
        for (SFDC_MDF_Claim__c fundClaim1 : fundSubClaims) {
            Decimal Subamount = fundClaim1.Requested_Amount__c;
            String RequestCurrency=fundClaim1.CurrencyIsoCode ;

            if (Subamount != null)
            {       
                Decimal convertedamount=getConvertedCurrencyValue(Subamount,RequestCurrency,budgetCurrency);   
                if (convertedamount != null)fundClaimSubAmt += convertedamount;
            }
        }
         System.Debug('fundClaimSubAmt'+fundClaimSubAmt);
        return fundClaimSubAmt;
    }
    
   /*
    * recalculates and returns the Claims Awaiting Approval.
    */  
    @TestVisible
    private static Decimal getFundClaimAwaitingApp(String budgetId) {
        //get all approved FundClaims for this budget
        List<SFDC_MDF_Claim__c> fundAwtClaims = [Select Id, Requested_Amount__c,CurrencyIsoCode From SFDC_MDF_Claim__c 
            Where Budget__c = :budgetId And Approval_Status__c IN ('Pending First Approval','Pending Second Approval','Pending Final Approval')];

        //recalculate amount
        Decimal fundClaimAwtAmt = 0;
        for (SFDC_MDF_Claim__c fundClaim2 : fundAwtClaims) {
            Decimal awtAmount = fundClaim2.Requested_Amount__c;
            String RequestCurrency=fundClaim2.CurrencyIsoCode ;

            if (awtAmount != null)
            {   
                Decimal convertedamount=getConvertedCurrencyValue(awtAmount,RequestCurrency,budgetCurrency);   
                if (convertedamount != null)fundClaimAwtAmt += convertedamount;
            }
        }
         System.Debug('fundClaimAwtAmt'+fundClaimAwtAmt);
        return fundClaimAwtAmt;
    }
    
   /*
    * recalculates and returns the Unclaimed Fund Request Amount.
    */
    @TestVisible
    private static Decimal getfundReqUnclaimedAmt(String budgetId) {
        //get all approved FundClaims for this budget
        List<SFDC_MDF_Claim__c> fundAwtClaims = [Select Fund_Request__c From SFDC_MDF_Claim__c 
            Where Budget__c = :budgetId And Approval_Status__c =: 'Approved'];
        
        set<ID> fcIds = new set<ID>();    
        for(SFDC_MDF_Claim__c fClaim :  fundAwtClaims){
            fcIds.add(fClaim.Fund_Request__c);
            
            
        }  
        
        //get all Fund Requests with approved Fund Claims for this budget 
        
        List<SFDC_MDF__c> fundReqsWithApprovedClaims = [Select Id, Estimated_Red_Hat_Funding_Requested__c, CurrencyIsoCode from SFDC_MDF__c where Id IN: fcIds];    
        
        
        
        
        //recalculate amount
        Decimal fundReqUnclaim = 0;
        for (SFDC_MDF__c fr : fundReqsWithApprovedClaims) {
            Decimal unclaimAmt = fr.Estimated_Red_Hat_Funding_Requested__c;
            String RequestCurrency=fr.CurrencyIsoCode ;

            if (unclaimAmt != null)
            {   
                Decimal convertedamount=getConvertedCurrencyValue(unclaimAmt,RequestCurrency,budgetCurrency);   
                if (convertedamount != null)fundReqUnclaim += convertedamount;
            }
        }
         System.Debug('fundReqUnclaim'+fundReqUnclaim);
        return fundReqUnclaim;
    }
}