/**
 * Quoting.cls
 *
 * @author  Bryan Bosely <bbosely@redhat.com>
 * @date    01/11/11
 * @Modified By : Scott Coleman
 * @Modified date : 01/29/2013
 * @Reason for Modification: Populating Credit__c.Opportunity_Amount__c 
 */

public class Quoting {
    
    private static final String SALESFORCE_MSG_NAMESPACE = 'http://salesforce.redhat.com/quoting';
    
    
    /**
     * synchronizes opportunity data with the data on a quote
     *
     * @param Id quoteId
     **/
     
    public void syncQuoteWithOpp(Id quoteId) {
            
        //
        // obtain the quote
        //
        
        Quote__c quote = getQuote( quoteId );
     
        //
        // obtain the opportunity
        //
        
        Opportunity opportunity = getOpportunity( quote.opportunityId__c, quoteId );
              
        //
        // update the opportunity with quote data
        // 
        
        opportunity.Amount = quote.Amount__c;
        opportunity.ContractEndDate__c = quote.EndDate__c;
        opportunity.ContractStartDate__c = quote.StartDate__c;
        opportunity.CurrencyIsoCode = quote.CurrencyIsoCode;
        opportunity.Pay_Now__c = quote.PayNow__c;
        opportunity.Pricebook2Id = quote.PricebookId__c;
        opportunity.QuoteNumber__c = quote.Number__c;
        opportunity.TermOfOpportunity__c = quote.Term__c.toPlainString();
        opportunity.Year1PaymentAmount__c = quote.Year1PaymentAmount__c;
        opportunity.Year2PaymentAmount__c = quote.Year2PaymentAmount__c;
        opportunity.Year3PaymentAmount__c = quote.Year3PaymentAmount__c;
        opportunity.Year4PaymentAmount__c = quote.Year4PaymentAmount__c;
        opportunity.Year5PaymentAmount__c = quote.Year5PaymentAmount__c;
        opportunity.Year6PaymentAmount__c = quote.Year6PaymentAmount__c;
        update opportunity;
        
        
        //
        // obtain the opportunity products (line items) to delete
        //
        
        OpportunityLineItem[] oppProdToDelete = [SELECT Id
                , OpportunityId 
             FROM OpportunityLineItem
            WHERE OpportunityId = :opportunity.Id
        ];
        
        delete oppProdToDelete;    
        
        
        //
        // obtain the new opportunity products from the quote
        //
        
        List<OpportunityLineItem> oppProdToCreate = new List<OpportunityLineItem>();
        QuoteLineItem__c[] quoteProds = [SELECT Id
                , Configured_SKU__c
                , ContractNumbers__c
                , EndDate__c
                , Name
                , NewOrRenewal__c
                , opportunityId__c
                , PricebookEntryId__c
                , Pricing_Attributes__c
                , ProductDescription__c
                , Quantity__c
                , StartDate__c
                , Term__c
                , TotalPrice__c
                , UnitPrice__c
                , YearlySalesPrice__c                                   
             FROM QuoteLineItem__c 
            WHERE QuoteId__c = :quoteId
        ];
        
        
        if (quoteProds.size() > 0) {

            for (QuoteLineItem__c qProd : quoteProds) {
                oppProdToCreate.add(new OpportunityLineItem(PriceBookEntryId = qProd.PricebookEntryId__c, 
                    Quantity = qProd.Quantity__c, 
                    UnitPrice = qProd.UnitPrice__c, 
                    NewOrRenewal__c = qProd.NewOrRenewal__c,
                    ActualStartDate__c = qProd.StartDate__c,
                    ActualEndDate__c = qProd.EndDate__c,
                    ActualTerm__c = qProd.Term__c,
                    Configured_SKU__c = qProd.Configured_SKU__c,
                    Contract_Numbers__c = qProd.ContractNumbers__c,
                    YearlySalesPrice__c = qProd.YearlySalesPrice__c, 
                    Pricing_Attributes__c = qProd.Pricing_Attributes__c,
                    Description = qProd.ProductDescription__c,
                    Line_Item_Source__c = 'application/vnd.redhat.sforce.quotingservices',
                    ScheduleLocked__c = true,
                    OpportunityId = qProd.opportunityId__c));
            }
            
            insert oppProdToCreate;
        }
        
        //
        // obtain the ApprovalCustom record from the quote
        //
        
        List<ApprovalCustom__c> approvals = [SELECT Id,
                BillingAccountNameApprovedOn__c, 
                BillingAccountNumberApprovedOn__c, 
                Opportunity__c,
                PaymentTermsApproved__c
           FROM ApprovalCustom__c
          WHERE ApprovalStatus__c = 'Approved'
            AND ApprovalCustom__c.RecordType.Name = 'Payment Terms'
            AND Quote__c = :quote.Id
            LIMIT 1
        ];
        
        
        if (approvals.size() > 0) {
 
            //
            // create a new credit object
            //
            
            RecordType recordType = [SELECT Id
                FROM RecordType 
               WHERE NAME = 'Approval Created'
            ];

            ApprovalCustom__c approval = approvals[0];
       
            Credit__c credit = new Credit__c();
            credit.BillingAccountNameUsed__c = approval.BillingAccountNameApprovedOn__c;
            credit.BillingAccountNumberUsed__c = approval.BillingAccountNumberApprovedOn__c;
            credit.Comments__c = 'Approval Reason: Payment Term Approval Request Granted';
            credit.Credit_Stage__c = 'Approved';
            credit.opportunity__c = approval.opportunity__c;
            credit.Opportunity_Amount__c = quote.Amount__c;
            credit.Payment_Terms__c = approval.PaymentTermsApproved__c;
            credit.RecordTypeId = recordType.id;
            insert credit;
        }
    }
    
    
    /**
     * calculate the quote line item schedules for a quote
     *
     * @param   Id quoteId
     **/
     
    public void calculate( Id quoteId ) {
        
        Quote__c quote = getQuote( quoteId );
        Opportunity opportunity = getOpportunity( quote.OpportunityId__c, quoteId );
        
        System.debug( 'Quote Id: ' + quote.Id );
        System.debug( 'Opportunity Id: ' + opportunity.Id );

        //
        // clear any existing schedules
        //
        
        delete quote.quotePaymentSchedule__r;
        delete quote.quoteLineItemSchedule__r;
        
        //
        // clear out the payment amounts
        //
        
        quote.year1PaymentAmount__c = 0.00;
        quote.year2PaymentAmount__c = 0.00;
        quote.year3PaymentAmount__c = 0.00;
        quote.year4PaymentAmount__c = 0.00;
        quote.year5PaymentAmount__c = 0.00;
        quote.year6PaymentAmount__c = 0.00;

        //
        // populate a SalesQuote object so that we can calculate the quote line item schedules
        //
        
        SalesQuote salesQuote = new SalesQuote( quote, opportunity );

        //
        // calculate the quote line items schedules for the quote
        //
        
        calculateQuoteLineItemSchedule( salesQuote );
        
        //
        // extract the quote line items ( QuoteLineItem__c ) from the sales quote and update them
        // extract the quote line item schedules ( QuoteLineItemSchedule__c ) from the sales quote line item and persist them 
        //
        
        List<QuoteLineItem__c> quoteLineItems = new List<QuoteLineItem__c>();
        List<QuoteLineItemSchedule__c> quoteLineItemSchedules = new List<QuoteLineItemSchedule__c>();
        
        for (SalesQuoteLineItem sqli : salesQuote.quoteLineItems)
        {
            quoteLineItems.add( sqli.quoteLineItem );
            
            for ( SalesQuoteLineItemSchedule sqlis : sqli.salesQuoteLineItemSchedules )
                quoteLineItemSchedules.add( sqlis.quoteLineItemSchedule );
        }        
        
        update quoteLineItems;
        insert quoteLineItemSchedules;

        //
        // update the quote ( Quote__c ) within the sales quote
        //

        salesQuote.quote.isCalculated__c = true;
        update salesQuote.quote;


        if ( (salesQuote.fulfillmentChannel == 'Direct - DLT') || (salesQuote.fulfillmentChannel == 'Direct - Carahsoft') ) 
        {
            salesQuote.quote.isActive__c = true;
            update salesQuote.quote;
            
            syncQuoteWithOpp ( salesQuote.quoteId );
        }
    }
    
    
    /**
     * calculate the quote line item schedules for a quote.
     * this method only calculates the quote line item schedules 
     * and does not persist them to SFDC
     *
     * @param   String xmlDocument
     * @return  String
     **/
     
    public String calculateXml(String xmlDocument)
    {
        
        //
        // generate the quote class hierarchy from the XML
        //
        
        SalesQuoteMessage message = new SalesQuoteMessage();
        message.unmarshal( xmlDocument, SALESFORCE_MSG_NAMESPACE );
        
        //
        // calculate the quote line items schedules for the quote
        //
        
        calculateQuoteLineItemSchedule( message.quote );
        
        //
        // generate the response message
        //
        
        return message.marshal();   
    }
    
    
    /**
     *
     * @param Quote__c quote
     * @return List<Date>
     */
         
    private List<Date> getInvoiceEndDates(Quote__c quote) {

        //
        // Build an array list with the invoice end dates Rules:
        //

        Date quoteStartDate = quote.startDate__c;
        Date quoteEndDate = quote.endDate__c;
        Date yearEndDate = quote.endDate__c;

        system.debug( 'Quote Start Date: ' + quoteStartDate );
        system.debug( 'Quote End Date: ' + quoteEndDate );
        system.debug( 'Quote Year End Date: ' + yearEndDate );

        List<Date> invoiceEndDates = new List<Date>();
        while ( ( quoteStartDate < yearEndDate ) || ( quoteStartDate == yearEndDate )) 
        {
            yearEndDate = yearEndDate.addYears( -1 );
            System.debug( 'Quote Year End Date: ' + yearEndDate );
        }
        yearEndDate = yearEndDate.addYears( 1 );


        if ( 'Co-Term'.equals( quote.type__c ) || 'Non Standard'.equals( quote.type__c ) ) 
        {
            if ( getDifference( quoteStartDate, yearEndDate ) < ( 365 + Util.leapDays( quoteStartDate, yearEndDate ))) 
            {
                yearEndDate = yearEndDate.addYears( 1 );
            }
        }
        
        invoiceEndDates.add( yearEndDate );

        while ( yearEndDate < quoteEndDate ) 
        {
            yearEndDate = yearEndDate.addYears( 1 );
            invoiceEndDates.add( yearEndDate );
        }

        return invoiceEndDates;
    }

    
    /**
     * method for retrieving a quote from SaleForce.com
     *
     * @param   Id quoteId
     * @return  Quote__c
     **/
    
    private Quote__c getQuote( Id quoteId )
    {
        Quote__c quote;
        try {   
            quote = [SELECT Name
                    , Amount__c
                    , CurrencyIsoCode
                    , EndDate__c
                    , Number__c
                    , OpportunityId__c
                    , PayNow__c
                    , PricebookId__c
                    , StartDate__c
                    , Term__c
                    , Type__c
                    , Year1PaymentAmount__c
                    , Year2PaymentAmount__c
                    , Year3PaymentAmount__c
                    , Year4PaymentAmount__c
                    , Year5PaymentAmount__c
                    , Year6PaymentAmount__c
                    , (SELECT Id
                            , Configured_SKU__c
                            , ContractNumbers__c
                            , EndDate__c
                            , Name
                            , NewOrRenewal__c
                            , PricebookEntryId__c
                            , Pricing_Attributes__c
                            , ProductDescription__c
                            , ProductFamily__c
                            , Quantity__c
                            , StartDate__c
                            , Term__c
                            , UnitPrice__c
                            , YearlySalesPrice__c
                         FROM QuoteLineItem__r)
                    , (SELECT Id
                            , Name
                         FROM QuoteLineItemSchedule__r)
                    , (SELECT Id
                            , Name
                         FROM QuotePaymentSchedule__r)
                 FROM Quote__c 
                WHERE Id = :quoteId
            ];
        }
        catch ( System.QueryException sqe ) {
            throw new QuoteException( 'Quote id: ' + quoteId + ' not found' );
        }
        
        return quote;
    }
    
    
    /**
     * method for retrieving an opportunity from SalesForce.com
     *
     * @param   Id opportunityId
     * @param   Id quoteId
     * @return  Opportunity
     **/
     
    private Opportunity getOpportunity( Id opportunityId, Id quoteId )
    {
        Opportunity opportunity;
        
        try {
            opportunity = [SELECT Id
                    , CloseDate
                    , FulfillmentChannel__c
                    , Name
                    , Pricebook2Id
                    , StageName
                    , (SELECT Id
                         FROM OpportunityLineItems)
                 FROM Opportunity 
                WHERE Id = :opportunityId
            ];
        }
        catch ( System.QueryException sqe ) {
            throw new QuoteException( 'Opportunity not found for quote id: ' + quoteId );
        }
        
        return opportunity;
    }
    
    
    /**
     * method for formatting currency values
     *
     * @param String currencyIsoCode
     * @param Decimal price
     * @return Decimal
     **/
    
    private Decimal formatPrice(String currencyIsoCode, Decimal price) 
    {
        if ('JPY'.equals(currencyIsoCode) || 'KRW'.equals(currencyIsoCode)) 
        {
            price = price.divide( 1, 0, System.RoundingMode.HALF_EVEN );
        } 
        else 
        {
            price = price.divide( 1, 2, System.RoundingMode.HALF_EVEN );
        }
        return price;
    }
    
    
    /**
     * method for calculating the number of days between two days
     *
     * @param Date startDate
     * @param Date endDate
     * @return Integer
     **/
    
    private Integer getDifference(Date startDate, Date endDate) {
        
        //
        // adding one day because the daysBetween method is not inclusive
        //
        
        return ( startDate.daysBetween( endDate ) + 1 );
    }
    
    
    /**
     * calculate the quote line item schedule
     *
     * @param Quote quote
     **/
     
    private void calculateQuoteLineItemSchedule( Quoting.SalesQuote salesQuote ) 
    {   
        system.debug( 'Quote Id: ' + salesQuote.quote.Id );
        system.debug( 'Quote Type: ' + salesQuote.quote.type__c );
        system.debug( 'Opportunity Fulfillment Channel: ' + salesQuote.fulfillmentChannel );
        
        //
        // get the quote__c object from the decorated class SalesQuote
        //
        
        Quote__c quote = salesQuote.quote;  
        quote.year1PaymentAmount__c = 0.00;
        quote.year2PaymentAmount__c = 0.00;
        quote.year3PaymentAmount__c = 0.00;
        quote.year4PaymentAmount__c = 0.00;
        quote.year5PaymentAmount__c = 0.00;
        quote.year6PaymentAmount__c = 0.00;
        quote.lastCalculatedDate__c = System.now();
        
        List<Date> invoiceEndDates = getInvoiceEndDates( salesQuote.quote );
        Decimal pricePerDay = 0.00;
        
        //
        // interate through the quote lines items and calculate the quote line items schedules
        //
        
        for (SalesQuoteLineItem salesQuoteLineItem : salesQuote.QuoteLineItems)
        {       
            //
            // get the quoteLineItem__c object from the decorated class SalesQuoteLineItem
            //
            
            QuoteLineItem__c quoteLineItem = salesQuoteLineItem.quoteLineItem;
            
            Decimal prorateYearUnitPrice = 0.00;
            Decimal prorateYearTotalPrice = 0.00;
            Decimal prorateUnitPrice = 0.00;
            Decimal prorateTotalPrice = 0.00;
            Decimal totalPrice = 0.00;
            Decimal standardTotal = 0.00;
            Decimal totalPriceForTerm = 0.00;
            Boolean standardLineItem = false;
                
            Date lineStartDate = quoteLineItem.startDate__c;
            Date lineEndDate = quoteLineItem.endDate__c;
            Integer term = getDifference( lineStartDate, lineEndDate );
            Decimal standardYears = Decimal.valueOf( term ).divide( 365.00, 2, System.RoundingMode.HALF_EVEN );
                
            if ( quoteLineItem.yearlySalesPrice__c != 0 && quoteLineItem.quantity__c != 0 ) 
            {
                totalPrice = ( quoteLineItem.yearlySalesPrice__c * quoteLineItem.quantity__c );
            }
       
       
            system.debug ( '-- lineStartDate: ' + lineStartDate );
            system.debug ( '-- lineEndDate: ' + lineEndDate );
            system.debug ( '-- term: ' + term );
            system.debug ( '-- standardYears: ' + standardYears );
            system.debug ( '-- totalPrice: ' + totalPrice );
            
                      
            //
            // Calculate the price per day based on the Quote type Rules: if the quote is a non-standard then do not set a price per
            // day but use the price as is
            //
    
            //
            // determine if the opportunity is for the public sector
            //
                
            if ( (salesQuote.fulfillmentChannel == 'Direct - DLT') || (salesQuote.fulfillmentChannel == 'Direct - Carahsoft') ) 
            {
                if ('Co-Term'.equals( quote.type__c )) 
                {
                    pricePerDay = quoteLineItem.unitPrice__c.divide( term, 10, System.RoundingMode.HALF_UP );
                } 
                else if ('Standard'.equals( quote.type__c )) 
                {
                    pricePerDay = quoteLineItem.yearlySalesPrice__c.divide( term, 10, System.RoundingMode.HALF_UP );
                } 
                else if ('Non Standard'.equals( quote.type__c )) 
                {
                    pricePerDay = quoteLineItem.unitPrice__c.divide( term, 10, System.RoundingMode.HALF_UP );
                }
            } 
            else 
            {
                if ('Co-Term'.equals( quote.type__c )) 
                {
                    pricePerDay = quoteLineItem.yearlySalesPrice__c.divide( 365, 10, System.RoundingMode.HALF_UP );
                } 
                else if ('Standard'.equals( quote.type__c )) 
                {
                    pricePerDay = quoteLineItem.yearlySalesPrice__c.divide( term - Util.leapDays( lineStartDate, lineEndDate ), 10, System.RoundingMode.HALF_UP );
                } 
                else if ('Non Standard'.equals(quote.type__c )) 
                {
                    pricePerDay = quoteLineItem.yearlySalesPrice__c.divide( 365, 10, System.RoundingMode.HALF_UP );
                    
                    //
                    // calculate pricePerDay for services products
                    //
                    
                    if (quoteLineItem.productFamily__c.equalsIgnoreCase('GLS') || quoteLineItem.productFamily__c.equalsIgnoreCase('GPS')) 
                    {
                        pricePerDay = quoteLineItem.yearlySalesPrice__c.divide( term - Util.leapDays( lineStartDate, lineEndDate ), 10, System.RoundingMode.HALF_UP );
                    }
                }
            }
                
            system.debug( 'QuoteType: ' + quote.type__c );
                
            //
            // determine if the opportunity is for the public sector
            //
                
            if ( (salesQuote.fulfillmentChannel == 'Direct - DLT') || (salesQuote.fulfillmentChannel == 'Direct - Carahsoft') ) 
            {
                totalPriceForTerm = ( pricePerDay * term );    
            } 
            else 
            {
                Integer termMinusLeapYearCount = term - Util.leapDays(  quoteLineItem.startDate__c, quoteLineItem.endDate__c );
                totalPriceForTerm = ( pricePerDay * termMinusLeapYearCount );
            }
                
            Integer daysInYear = 0;
            prorateYearUnitPrice = 0.00;
            prorateYearTotalPrice = 0.00;
            prorateUnitPrice = 0.00;
            prorateTotalPrice = 0.00;
                
            //
            // Calculate the invoice schedule Rules:
            //
    
            Date invoiceYearStartDate = lineStartDate;
            if ( 'Yes'.equals( quote.payNow__c )) 
            {
                    
                Integer actualDays = 0;
    
                if ( (salesQuote.fulfillmentChannel == 'Direct - DLT') || (salesQuote.fulfillmentChannel == 'Direct - Carahsoft') ) 
                {
                    actualDays = getDifference( lineStartDate, lineEndDate );
                } 
                else 
                {
                    actualDays = getDifference( lineStartDate, lineEndDate ) - Util.leapDays( lineStartDate, lineEndDate );
                }
    
                if (quoteLineItem.productFamily__c.equalsIgnoreCase('GLS') || quoteLineItem.productFamily__c.equalsIgnoreCase('GPS')) 
                {
                    prorateUnitPrice = formatPrice( quote.currencyIsoCode, quoteLineItem.yearlySalesPrice__c );
                } 
                else 
                {
                    prorateUnitPrice = formatPrice( quote.currencyIsoCode, ( pricePerDay * actualDays ) );
                }
                    
                prorateTotalPrice = formatPrice( quote.currencyIsoCode, ( prorateUnitPrice * quoteLineItem.quantity__c ) );
                                        
                
                //
                // create a new saleQuoteLineItemSchedule and add it to the quote
                //
                
                SalesQuoteLineItemSchedule salesQuoteLineItemSchedule = new SalesQuoteLineItemSchedule();
                salesQuoteLineItem.salesQuoteLineItemSchedules.add( salesQuoteLineItemSchedule );
                
                //
                // get the quoteLineItemSchedule__c object from the decorated class SalesQuoteLineItemSchedule
                //
                
                QuoteLineItemSchedule__c quoteLineItemSchedule = salesQuoteLineItemSchedule.quoteLineItemSchedule;
                quoteLineItemSchedule.type__c = 'Invoice';
                quoteLineItemSchedule.startDate__c = quoteLineItem.startDate__c;
                quoteLineItemSchedule.quoteId__c = quote.Id;
                quoteLineItemSchedule.quoteLineItemId__c = quoteLineItem.Id;
                quoteLineItemSchedule.endDate__c = quoteLineItem.endDate__c;
                quoteLineItemSchedule.year__c = 1;
                quoteLineItemSchedule.pricePerDay__c = pricePerDay;
                quoteLineItemSchedule.prorateTotalPrice__c = prorateTotalPrice;
                quoteLineItemSchedule.prorateUnitPrice__c = prorateUnitPrice;
                quoteLineItemSchedule.prorateYearTotalPrice__c = prorateTotalPrice;
                quoteLineItemSchedule.prorateYearUnitPrice__c = prorateUnitPrice;
                
                quote.year1PaymentAmount__c = ( quote.year1PaymentAmount__c + prorateTotalPrice );
            } 
            else 
            {
                //
                // For services products put the total amount in the year 1 bucket for both invoice and booking schedules
                //
    
                if ('Co-Term'.equals( quote.type__c ) && (quoteLineItem.productFamily__c.equalsIgnoreCase('GLS') || quoteLineItem.productFamily__c.equalsIgnoreCase('GPS'))) 
                {
                    prorateYearUnitPrice = formatPrice( quote.currencyIsoCode, quoteLineItem.yearlySalesPrice__c );
                    prorateYearTotalPrice = ( prorateYearUnitPrice * quoteLineItem.quantity__c );
                    prorateUnitPrice = prorateYearUnitPrice;
                    prorateTotalPrice = prorateYearTotalPrice;
                                                    
                    //
                    // create a new saleQuoteLineItemSchedule and add it to the quote
                    //
                
                    SalesQuoteLineItemSchedule salesQuoteLineItemSchedule = new SalesQuoteLineItemSchedule();
                    salesQuoteLineItem.salesQuoteLineItemSchedules.add( salesQuoteLineItemSchedule );
                    
                    //
                    // get the quoteLineItemSchedule__c object from the decorated class SalesQuoteLineItemSchedule
                    //
                    
                    QuoteLineItemSchedule__c quoteLineItemSchedule = salesQuoteLineItemSchedule.quoteLineItemSchedule;
                    quoteLineItemSchedule.type__c = 'Invoice';
                    quoteLineItemSchedule.pricePerDay__c = pricePerDay;
                    quoteLineItemSchedule.prorateTotalPrice__c = prorateTotalPrice;
                    quoteLineItemSchedule.prorateUnitPrice__c = prorateUnitPrice;
                    quoteLineItemSchedule.prorateYearTotalPrice__c = prorateYearTotalPrice;
                    quoteLineItemSchedule.prorateYearUnitPrice__c = prorateYearUnitPrice;
                    quoteLineItemSchedule.quoteId__c = quote.Id;
                    quoteLineItemSchedule.quoteLineItemId__c = quoteLineItem.Id;
                    quoteLineItemSchedule.startDate__c = lineStartDate;
                    quoteLineItemSchedule.endDate__c = lineEndDate;
                    quoteLineItemSchedule.year__c  = 1;

                    quote.year1PaymentAmount__c = ( quote.year1PaymentAmount__c + prorateYearTotalPrice );
                }
                else 
                {
                    //
                    // For non-services products put the amount into the bucket that the start date and end date falls between for
                    // the invoice schedule
                    //
                    
                    system.debug ( '--Invoice End Dates: ' + invoiceEndDates );
    
                    for (Integer k = 0; k < invoiceEndDates.size(); k++) 
                    {
                        Date invoiceYearEndDate = (Date) invoiceEndDates.get( k );
                        daysInYear = 0;
    
                        if ( lineStartDate < invoiceYearEndDate ) 
                        {
                            if ( 'Non Standard'.equals( quote.type__c ) )
                            {
                                if ( lineEndDate > invoiceYearStartDate ) 
                                {
                                    if ( lineEndDate < invoiceYearEndDate ) 
                                    {
                                        daysInYear = getDifference( invoiceYearStartDate, lineEndDate );
                                        if ( ( salesQuote.fulfillmentChannel != 'Direct - DLT' ) && ( salesQuote.fulfillmentChannel != 'Direct - Carahsoft' ) ) 
                                        {
                                            daysInYear = daysInYear - Util.leapDays( invoiceYearStartDate, lineEndDate );
                                        }
                                    } 
                                    else 
                                    {
                                        daysInYear = getDifference( invoiceYearStartDate, invoiceYearEndDate );
                                        if ( ( salesQuote.fulfillmentChannel != 'Direct - DLT' ) && ( salesQuote.fulfillmentChannel != 'Direct - Carahsoft' ) )
                                        {
                                            daysInYear = daysInYear - Util.leapDays( invoiceYearStartDate, invoiceYearEndDate );
                                        }
                                    }
                                }
                            } 
                            else 
                            {
                                if ( lineEndDate < invoiceYearEndDate ) 
                                {
                                    daysInYear = getDifference( invoiceYearStartDate, lineEndDate );
                                    if ( ( salesQuote.fulfillmentChannel != 'Direct - DLT' ) && ( salesQuote.fulfillmentChannel != 'Direct - Carahsoft' ) )
                                    {
                                        daysInYear = daysInYear - Util.leapDays( invoiceYearStartDate, lineEndDate );
                                    }
                                } 
                                else 
                                {
                                    daysInYear = getDifference( invoiceYearStartDate, invoiceYearEndDate );
                      
                                    if ( ( salesQuote.fulfillmentChannel != 'Direct - DLT' ) && ( salesQuote.fulfillmentChannel != 'Direct - Carahsoft' ) )
                                    {
                                        daysInYear = daysInYear - Util.leapDays( invoiceYearStartDate, invoiceYearEndDate );
                                    }
                                }
                            }
                            
                            if (daysInYear > 0) 
                            {       
                                prorateYearUnitPrice = formatPrice( quote.currencyIsoCode, ( pricePerDay * daysInYear ) );
                                prorateYearUnitPrice = prorateYearUnitPrice.divide( 1, 2, System.RoundingMode.HALF_EVEN );
                                prorateYearTotalPrice = ( prorateYearUnitPrice * quoteLineItem.quantity__c );
                                prorateYearTotalPrice = prorateYearTotalPrice.divide( 1, 2, System.RoundingMode.HALF_EVEN );
                                
                                    
                                if ( ( k + 1 ) < standardYears && 'Standard'.equals( quote.type__c ) )
                                {
                                    prorateUnitPrice = ( prorateUnitPrice + prorateYearUnitPrice );
                                    prorateTotalPrice = ( prorateTotalPrice + prorateYearTotalPrice );
    
                                } 
                                else if ( ( k + 1 ) < invoiceEndDates.size() && ('Non Standard'.equals( quote.type__c ) || 'Co-Term'.equals( quote.type__c ) ) )
                                {
                                    prorateUnitPrice = ( prorateUnitPrice + prorateYearUnitPrice );
                                    prorateTotalPrice = ( prorateTotalPrice + prorateYearTotalPrice );
                                }
    
                                if ( 'Standard'.equals( quote.type__c ) || standardLineItem ) 
                                {
                                    if ( ( k + 1 ) == standardYears ) 
                                    {
                                        prorateYearUnitPrice = ( quoteLineItem.YearlySalesPrice__c - standardTotal );
                                        prorateYearTotalPrice = ( prorateYearUnitPrice * quoteLineItem.quantity__c );
                                        prorateUnitPrice = ( prorateUnitPrice + prorateYearUnitPrice );
                                        prorateTotalPrice = ( prorateTotalPrice + prorateYearTotalPrice );
                                    } 
                                    else 
                                    {
                                        standardTotal = ( standardTotal + prorateYearUnitPrice );
                                    }
                                }
    
                                if ( 'Non Standard'.equals( quote.type__c ) || 'Co-Term'.equals( quote.type__c ) ) 
                                {
                                    if ( ( k + 1 ) == invoiceEndDates.size() ) 
                                    {
                                        prorateYearUnitPrice = ( totalPriceForTerm - standardTotal );
                                        prorateYearUnitPrice = prorateYearUnitPrice.divide( 1, 2, System.RoundingMode.HALF_EVEN );
                                        prorateYearTotalPrice = ( prorateYearUnitPrice * quoteLineItem.quantity__c );
                                        prorateYearTotalPrice = prorateYearTotalPrice.divide( 1, 2, System.RoundingMode.HALF_EVEN );
                                        prorateUnitPrice = ( prorateUnitPrice + prorateYearUnitPrice );
                                        prorateTotalPrice = ( prorateTotalPrice + prorateYearTotalPrice );
                                        
                                        //
                                        // process services products
                                        //
                                        
                                        if (('Non Standard'.equals( quote.type__c )) && (quoteLineItem.productFamily__c.equalsIgnoreCase('GLS') || quoteLineItem.productFamily__c.equalsIgnoreCase('GPS')))
                                        {
                                            prorateYearUnitPrice = ( quoteLineItem.YearlySalesPrice__c - standardTotal );
                                            prorateYearUnitPrice = prorateYearUnitPrice.divide( 1, 2, System.RoundingMode.HALF_EVEN );
                                        }
                                    }
                                    else 
                                    {
                                        standardTotal = ( standardTotal + prorateYearUnitPrice );
                                    }
                                }
    
                                
                                //
                                // get the quoteLineItemSchedule__c object from the decorated class SalesQuoteLineItemSchedule
                                //
                                
                                system.debug('----------------------------------------------');
                                system.debug(' Quote Line Item Schedule: ' + (k + 1) );
                                system.debug('----------------------------------------------');
                                system.debug('-- Price Per Day: ' + pricePerDay);
                                system.debug('-- Prorate Total Price: ' + prorateTotalPrice);
                                system.debug('-- Prorate Unit Price: ' + prorateUnitPrice);
                                system.debug('-- Prorate Year Total Price: ' + prorateYearTotalPrice);
                                system.debug('-- Prorate Year Unit Price: ' + prorateYearUnitPrice);
                                system.debug('-- Line Start Date: ' + lineStartDate);
                                system.debug('-- Line End Date: ' + lineEndDate);
                                system.debug('-- Invoice Year Start Date: ' + invoiceYearStartDate);
                                system.debug('-- Invoice Year End Date: ' + invoiceYearEndDate);
                                system.debug( '--Days in Year ' + daysInYear );
                                
                                
                                //
                                // create a new saleQuoteLineItemSchedule and add it to the quote
                                //
                
                                SalesQuoteLineItemSchedule salesQuoteLineItemSchedule = new SalesQuoteLineItemSchedule();
                                salesQuoteLineItem.salesQuoteLineItemSchedules.add( salesQuoteLineItemSchedule );
                
                                //
                                // get the quoteLineItemSchedule__c object from the decorated class SalesQuoteLineItemSchedule
                                //
                                
                                QuoteLineItemSchedule__c quoteLineItemSchedule = salesQuoteLineItemSchedule.quoteLineItemSchedule;
                                quoteLineItemSchedule.type__c = 'Invoice';
                                quoteLineItemSchedule.pricePerDay__c = pricePerDay;
                                quoteLineItemSchedule.prorateTotalPrice__c = prorateTotalPrice;
                                quoteLineItemSchedule.prorateUnitPrice__c = prorateUnitPrice;
                                quoteLineItemSchedule.prorateYearTotalPrice__c = prorateYearTotalPrice;
                                quoteLineItemSchedule.prorateYearUnitPrice__c = prorateYearUnitPrice;
                                quoteLineItemSchedule.quoteId__c = quote.Id;
                                quoteLineItemSchedule.quoteLineItemId__c = quoteLineItem.Id;
                                
                                    
                                if ( lineStartDate > invoiceYearStartDate ) 
                                {
                                    quoteLineItemSchedule.startDate__c = lineStartDate;
                                } 
                                else 
                                {
                                    quoteLineItemSchedule.startDate__c = invoiceYearStartDate;
                                }
                                
                                if ( invoiceYearEndDate > lineEndDate ) 
                                {
                                    quoteLineItemSchedule.endDate__c = lineEndDate;
                                } 
                                else 
                                {
                                    quoteLineItemSchedule.endDate__c = invoiceYearEndDate;
                                }
                                    
                                quoteLineItemSchedule.year__c = ( k + 1 );
    
                                if ( k == 0 ) 
                                {
                                    quote.year1PaymentAmount__c = ( quote.year1PaymentAmount__c + prorateYearTotalPrice );
                                } 
                                else if ( k == 1 ) 
                                {
                                    quote.year2PaymentAmount__c = ( quote.year2PaymentAmount__c + prorateYearTotalPrice );
                                } 
                                else if ( k == 2 ) 
                                {
                                    quote.year3PaymentAmount__c = ( quote.year3PaymentAmount__c + prorateYearTotalPrice );
                                } 
                                else if ( k == 3 ) 
                                {
                                    quote.year4PaymentAmount__c = ( quote.year4PaymentAmount__c + prorateYearTotalPrice );
                                } 
                                else if ( k == 4 ) 
                                {
                                    quote.year5PaymentAmount__c = ( quote.year5PaymentAmount__c + prorateYearTotalPrice );
                                } 
                                else if ( k == 5 ) 
                                {
                                    quote.year6PaymentAmount__c = ( quote.year6PaymentAmount__c + prorateYearTotalPrice );
                                }
                            }
                                
                            invoiceYearStartDate = invoiceYearEndDate;
                            invoiceYearStartDate = invoiceYearStartDate.addDays( 1 );
                        }
                    }
                }
            }
    
            if ( (salesQuote.fulfillmentChannel == 'Direct - DLT') || (salesQuote.fulfillmentChannel == 'Direct - Carahsoft') ) 
            {
                quoteLineItem.totalPrice__c = prorateTotalPrice;
            } 
            else 
            {
                if ( 'Standard'.equals( quote.type__c ) ) 
                {
                    quoteLineItem.UnitPrice__c = quoteLineItem.YearlySalesPrice__c;
                    quoteLineItem.totalPrice__c = totalPrice;
                } 
                else 
                {
                    quoteLineItem.unitPrice__c = prorateUnitPrice;
                    quoteLineItem.totalPrice__c = prorateTotalPrice;
                }
            }
        }
    }
    
    
    //
    // The following inner classes model an XML document as an object hierarchy for a Quote
    //
    
    /**
     * class to model the sales quote message
     **/
     
    public class SalesQuoteMessage
    {
        public SalesQuoteHeader header                                      { get; set; }
        public SalesQuote quote                                             { get; set; }
        
        
        /**
         * constructor
         **/
         
        public SalesQuoteMessage()
        {
            this.header = new SalesQuoteHeader();
            this.quote = new SalesQuote();
        }
        
        
        /**
         * Populates quote class hierarchy from XML
         *
         * @param String        xmlDocument
         * @param String        namespace
         **/
         
        public void unmarshal( String xmlDocument, String namespace )
        {
            DOM.Document document = new DOM.Document();
            document.load(xmlDocument);
            
            for(DOM.XmlNode node : document.getRootElement().getChildElements()) 
            {
                if (node.getName() == 'Header') 
                {
                    this.header.unmarshal( node, namespace );   
                }
            
                if (node.getName() == 'Payload') 
                {
                    DOM.XMLNode quoteNode = node.getChildElement( 'Quote', SALESFORCE_MSG_NAMESPACE );
                    this.quote.unmarshal( quoteNode, namespace );
                }
            }       
        }
        
        
        /**
         * method for marshalling the sales quote class hierarchy back to XML
         *
         * @return String
         **/
         
        public String marshal()
        {
            DOM.Document response = new DOM.Document();
            DOM.xmlNode salesForceMessage = response.createRootElement( 'SalesForceMessage', SALESFORCE_MSG_NAMESPACE, '' );
    
            //
            // generate header node
            //
        
            this.header.marshal( salesForceMessage );
            
            //
            // generate payload node
            //
            
            DOM.xmlNode payload = salesForceMessage.addChildElement( 'Payload', SALESFORCE_MSG_NAMESPACE, '' );
            
            //
            // generate quote node
            //
            
            this.quote.marshal( payload );
 
            
            return response.toXmlString();
        }       
    }
   
   
    /**
     * class to model the sales quote header
     **/
     
    public class SalesQuoteHeader 
    {
        public String instanceId                                            { get; set; }
        public String operation                                             { get; set; }
        public String opportunityType                                       { get; set; }
        public String timestamp                                             { get; set; }
        
        
        /**
         * Populates quote header from XML
         *
         * @param DOM.Xmlnode   node
         * @param String        namespace
         **/
         
        public void unmarshal( DOM.Xmlnode node, String namespace )
        {   
            //
            // Determine if the nodes we are looking for exist within the xml
            //
            
            DOM.Xmlnode instanceId                  = node.getChildElement( 'InstanceId', namespace );
            DOM.Xmlnode operation                   = node.getChildElement( 'Operation', namespace );
            DOM.Xmlnode opportunityType             = node.getChildElement( 'Type', namespace );
            DOM.Xmlnode timestamp                   = node.getChildElement( 'TimeStamp', namespace );

            //
            // Populate quote header with values from the xml node
            // NOTE: A ternary statement is being used to check for null values.
            //       In situations where a value needs to be cast a nested ternary statement is used
            //
                
            this.instanceId                         = ( instanceId != null ) ? instanceId.getText() : null;
            this.operation                          = ( operation != null ) ? operation.getText() : null;
            this.opportunityType                    = ( opportunityType != null ) ? opportunityType.getText() : null;
            this.timestamp                          = ( timestamp != null ) ? timestamp.getText() : null;   
        }
        
        
        /**
         * method for marshalling an object to XML
         *
         * @param DOM.Xmlnode   node 
         **/
         
        public void marshal( DOM.Xmlnode node )
        {
            DOM.xmlNode header = node.addChildElement( 'Header', SALESFORCE_MSG_NAMESPACE, '' );
            header.addChildElement( 'Operation', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.operation );
            header.addChildElement( 'Type', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.opportunityType );
            header.addChildElement( 'InstanceId', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.instanceId );
            header.addChildElement( 'TimeStamp', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.timestamp );
            header.addChildElement( 'ResponseTimeStamp', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( system.now().format('yyyy-MM-dd\'T\'HH:mm:ss') );
        }       
    }
    
    
    /**
     * class to model a sales quote
     **/
    
    public class SalesQuote 
    {
        public Date closeDate                                               { get; set; }
        public String fulfillmentChannel                                    { get; set; }
        public Quote__c quote                                               { get; set; }
        public String quoteId                                               { get; set; }
        public String quoteNumber                                           { get; set; }
        public String stageName                                             { get; set; }
        
        public List<SalesQuoteLineItem> quoteLineItems                      { get; set; }
        
        
        /**
         * constructor
         **/
         
        public SalesQuote()
        {
            this.quote                              = new Quote__c();
            this.quoteLineItems                     = new List<SalesQuoteLineItem>();
        }
        
        /**
         * constructor
         *
         * @param Quote__c quote
         * @param Opportunity opportunity
         **/
        
        public SalesQuote(Quote__c quote, Opportunity opportunity)
        {
            //
            // call the default constructor
            //
            
            this();
            
            this.closeDate = opportunity.closeDate;
            this.fulfillmentChannel = opportunity.fulfillmentChannel__c;
            this.stageName = opportunity.stageName;
            this.quote = quote;
            this.quoteId = quote.Id;
            
            //
            // initialize the sales quote line items
            //
            
            for (QuoteLineItem__c quoteLineItem : quote.quoteLineItem__r)
            {
                SalesQuoteLineItem salesQuoteLineItem = new SalesQuoteLineItem( quoteLineItem );
                this.quoteLineItems.add( salesQuoteLineItem );
            }
        }
        
        
        /**
         * Populates sales quote from XML
         *
         * @param DOM.Xmlnode   node
         * @param String        namespace
         **/
         
        public void unmarshal( DOM.Xmlnode node, String namespace ) 
        {   
            //
            // Determine if the nodes we are looking for exist within the xml
            //
            
            DOM.Xmlnode amount                      = node.getChildElement( 'Amount', namespace );
            DOM.Xmlnode closeDate                   = node.getChildElement( 'CloseDate', namespace );
            DOM.Xmlnode currencyIsoCode             = node.getChildElement( 'CurrencyIsoCode', namespace );
            DOM.Xmlnode endDate                     = node.getChildElement( 'EndDate', namespace );
            DOM.Xmlnode fulfillmentChannel          = node.getChildElement( 'FulfillmentChannel', namespace );
            DOM.Xmlnode lastCalculatedDate          = node.getChildElement( 'LastCalculatedDate', namespace );
            DOM.Xmlnode name                        = node.getChildElement( 'Name', namespace );
            DOM.Xmlnode opportunityId               = node.getChildElement( 'OpportunityId', namespace );
            DOM.Xmlnode payNow                      = node.getChildElement( 'PayNow', namespace );
            DOM.Xmlnode pricebookId                 = node.getChildElement( 'PricebookId', namespace );
            DOM.Xmlnode quoteId                     = node.getChildElement( 'Id', namespace );
            DOM.Xmlnode quoteNumber                 = node.getChildElement( 'Number', namespace );
            DOM.Xmlnode quoteType                   = node.getChildElement( 'Type', namespace );
            DOM.Xmlnode stageName                   = node.getChildElement( 'StageName', namespace );
            DOM.Xmlnode startDate                   = node.getChildElement( 'StartDate', namespace );
            DOM.Xmlnode term                        = node.getChildElement( 'Term', namespace );
            DOM.Xmlnode year1PaymentAmount          = node.getChildElement( 'Year1PaymentAmount', namespace );
            DOM.Xmlnode year2PaymentAmount          = node.getChildElement( 'Year2PaymentAmount', namespace );
            DOM.Xmlnode year3PaymentAmount          = node.getChildElement( 'Year3PaymentAmount', namespace );
            DOM.Xmlnode year4PaymentAmount          = node.getChildElement( 'Year4PaymentAmount', namespace );
            DOM.Xmlnode year5PaymentAmount          = node.getChildElement( 'Year5PaymentAmount', namespace );
            DOM.Xmlnode year6PaymentAmount          = node.getChildElement( 'Year6PaymentAmount', namespace );

            
            //
            // Populate quote with values from the xml node
            // NOTE: A ternary statement is being used to check for null values.
            //       In situations where a value needs to be cast a nested ternary statement is used
            //
            
            this.closeDate                          = ( closeDate != null ) ? (( closeDate.getText() != '' ) ? parseDate( closeDate.getText() ) : null) : null;
            this.fulfillmentChannel                 = ( fulfillmentChannel != null ) ? fulfillmentChannel.getText() : null;
            this.quoteId                            = ( quoteId != null ) ? quoteId.getText() : null;
            this.quoteNumber                        = ( quoteNumber != null ) ? quoteNumber.getText() : null;
            this.stageName                          = ( stageName != null ) ? stageName.getText() : null;
            
            this.quote.amount__c                    = ( amount != null ) ? (( amount.getText() != '' ) ? Double.valueOf( amount.getText() ) : 0.0) : null;
            this.quote.currencyIsoCode              = ( currencyIsoCode != null ) ? currencyIsoCode.getText() : null;
            this.quote.endDate__c                   = ( endDate != null ) ? (( endDate.getText() != '' ) ? parseDate( endDate.getText() ) : null) : null;
            this.quote.lastCalculatedDate__c        = ( lastCalculatedDate != null ) ? (( lastCalculatedDate.getText() != '' ) ? parseDate( lastCalculatedDate.getText() ) : null) : null;
            this.quote.name                         = ( name != null ) ? name.getText() : null;
            this.quote.opportunityId__c             = ( opportunityId != null ) ? opportunityId.getText() : null;
            this.quote.payNow__c                    = ( payNow != null ) ? payNow.getText() : null;
            this.quote.pricebookId__c               = ( pricebookId != null ) ? pricebookId.getText() : null;
            this.quote.type__c                      = ( quoteType != null ) ? quoteType.getText() : null;
            this.quote.startDate__c                 = ( startDate != null ) ? (( startDate.getText() != '' ) ? parseDate( startDate.getText() ) : null) : null;
            this.quote.term__c                      = ( term != null ) ? (( term.getText() != '' ) ? Double.valueOf( term.getText() ) : 0.0) : null;
            this.quote.year1PaymentAmount__c        = ( year1PaymentAmount != null ) ? (( year1PaymentAmount.getText() != '' ) ? Double.valueOf( year1PaymentAmount.getText() ) : 0.0) : null;
            this.quote.year2PaymentAmount__c        = ( year2PaymentAmount != null ) ? (( year2PaymentAmount.getText() != '' ) ? Double.valueOf( year2PaymentAmount.getText() ) : 0.0) : null;
            this.quote.year3PaymentAmount__c        = ( year3PaymentAmount != null ) ? (( year3PaymentAmount.getText() != '' ) ? Double.valueOf( year3PaymentAmount.getText() ) : 0.0) : null;
            this.quote.year4PaymentAmount__c        = ( year4PaymentAmount != null ) ? (( year4PaymentAmount.getText() != '' ) ? Double.valueOf( year4PaymentAmount.getText() ) : 0.0) : null;
            this.quote.year5PaymentAmount__c        = ( year5PaymentAmount != null ) ? (( year5PaymentAmount.getText() != '' ) ? Double.valueOf( year5PaymentAmount.getText() ) : 0.0) : null;
            this.quote.year6PaymentAmount__c        = ( year6PaymentAmount != null ) ? (( year6PaymentAmount.getText() != '' ) ? Double.valueOf( year6PaymentAmount.getText() ) : 0.0) : null;  
            
            
            //
            // loop through the child nodes of the argument node to populate quote line items
            //
                
            for ( DOM.XmlNode n : node.getChildElements() ) 
            {
                if ( n.getName() == 'QuoteLineItem' )
                {
                    SalesQuoteLineItem quoteLineItem = new SalesQuoteLineItem();
                    quoteLineItem.unmarshal( n, namespace );
                    this.quoteLineItems.add( quoteLineItem );
                }
            }
        }
        
        
        /**
         * method for marshalling an object to XML
         *
         * @param DOM.Xmlnode   node
         **/
         
        public void marshal( DOM.Xmlnode node )
        {   
            
            //
            // generate quote node
            //
            
            DOM.xmlNode quote = node.addChildElement( 'Quote', SALESFORCE_MSG_NAMESPACE, '' );
            quote.addChildElement( 'Id', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteId );
            quote.addChildElement( 'Name', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.name );
            quote.addChildElement( 'Amount', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.amount__c.toPlainString() );
            quote.addChildElement( 'CurrencyIsoCode', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.currencyIsoCode );
            quote.addChildElement( 'StartDate', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( date2XsDate( this.quote.startDate__c ) );
            quote.addChildElement( 'EndDate', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( date2XsDate( this.quote.endDate__c ) );
            quote.addChildElement( 'Number', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteNumber );
            quote.addChildElement( 'OpportunityId', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.opportunityId__c );
            quote.addChildElement( 'PayNow', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.payNow__c );
            quote.addChildElement( 'CloseDate', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( date2XsDate( this.closeDate ) );
            quote.addChildElement( 'FulfillmentChannel', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.fulfillmentChannel );
            quote.addChildElement( 'StageName', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.stageName );
            quote.addChildElement( 'PricebookId', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.pricebookId__c );
            quote.addChildElement( 'Term', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.term__c.format().replace(',','') );
            quote.addChildElement( 'Type', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.type__c );
            quote.addChildElement( 'Year1PaymentAmount', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.year1PaymentAmount__c.toPlainString() );
            quote.addChildElement( 'Year2PaymentAmount', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.year2PaymentAmount__c.toPlainString() );
            quote.addChildElement( 'Year3PaymentAmount', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.year3PaymentAmount__c.toPlainString() );    
            quote.addChildElement( 'Year4PaymentAmount', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.year4PaymentAmount__c.toPlainString() );
            quote.addChildElement( 'Year5PaymentAmount', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.year5PaymentAmount__c.toPlainString() );
            quote.addChildElement( 'Year6PaymentAmount', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.year6PaymentAmount__c.toPlainString() );
            quote.addChildElement( 'LastCalculatedDate', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quote.lastCalculatedDate__c.format('yyyy-MM-dd\'T\'HH:mm:ss') );              
            
            
            //
            // generate quote line item nodes
            //
            
            for (SalesQuoteLineItem quoteLineItem : this.quoteLineItems)
            {
                quoteLineItem.marshal( quote );
            }
        }
        
        
        /**
         * method for converting a string to a date 
         *
         * @return Date
         **/
         
        private Date parseDate (String dt) 
        {
            String[] x      = dt.split('-');
            Integer year    = Integer.valueOf( x[0] );
            Integer month   = Integer.valueOf( x[1] );
            Integer day     = Integer.valueOf( x[2] );
        
            return Date.newInstance(year, month, day);
        }
        
        
        /**
         * method for converting a SFDC Date to xs:date format
         *
         * @return String
         **/
         
        private String date2XsDate (Date dt)
        {
            String year     = String.valueOf( dt.year() );
            String month    = ( String.valueOf( dt.month() ).length() == 1 ) ? '0' + String.valueOf( dt.month() ) : String.valueOf( dt.month() );
            String day      = ( String.valueOf( dt.day() ).length() == 1 ) ? '0' + String.valueOf( dt.day() ) : String.valueOf( dt.day() );
            
            return year + '-' + month + '-' + day;
        }
    }
    
    
    /**
     * class to model the quote line item
     **/
     
    public class SalesQuoteLineItem
    {
        public String id                                                    { get; set; }
        public QuoteLineItem__c quoteLineItem                               { get; set; }
        public List<SalesQuoteLineItemSchedule> salesQuoteLineItemSchedules { get; set; }


        /**
         * constructor
         **/
         
        public SalesQuoteLineItem()
        {
            this.quoteLineItem                          = new QuoteLineItem__c();
            this.salesQuoteLineItemSchedules            = new List<SalesQuoteLineItemSchedule>();
        }
        
        
        /**
         * constructor
         *
         * @param QuoteLineItem__c quoteLineItem
         **/
         
        public SalesQuoteLineItem( QuoteLineItem__c quoteLineItem )
        {
            //
            // call the default constructor
            //
            
            this();
            
            this.id = quoteLineItem.Id;
            this.quoteLineItem = quoteLineItem;
        } 
        
        
        /**
         * Populates quote line item from XML
         *
         * @param DOM.Xmlnode   node
         * @param String        namespace
         **/
         
        public void unmarshal( DOM.Xmlnode node, String namespace )
        {   
            //
            // Determine if the nodes we are looking for exist within the xml
            //
            
            DOM.Xmlnode configuredSku               = node.getChildElement( 'ConfiguredSKU', namespace );
            DOM.Xmlnode contractNumbers             = node.getChildElement( 'ContractNumbers', namespace );
            DOM.Xmlnode endDate                     = node.getChildElement( 'EndDate', namespace );
            DOM.Xmlnode id                          = node.getChildElement( 'Id', namespace );
            DOM.Xmlnode name                        = node.getChildElement( 'Name', namespace );
            DOM.Xmlnode newOrRenewal                = node.getChildElement( 'NewOrRenewal', namespace );
            DOM.Xmlnode pricebookEntryId            = node.getChildElement( 'PricebookEntryId', namespace );
            DOM.Xmlnode pricingAttributes           = node.getChildElement( 'PricingAttributes', namespace );
            DOM.Xmlnode productDescription          = node.getChildElement( 'ProductDescription', namespace );
            DOM.Xmlnode productFamily               = node.getChildElement( 'ProductFamily', namespace );
            DOM.Xmlnode quantity                    = node.getChildElement( 'Quantity', namespace );
            DOM.Xmlnode startDate                   = node.getChildElement( 'StartDate', namespace );
            DOM.Xmlnode term                        = node.getChildElement( 'Term', namespace );
            DOM.Xmlnode totalPrice                  = node.getChildElement( 'TotalPrice', namespace );
            DOM.Xmlnode unitPrice                   = node.getChildElement( 'UnitPrice', namespace );
            DOM.Xmlnode yearlySalesPrice            = node.getChildElement( 'YearlySalesPrice', namespace );


            //
            // Populate quote line item with values from the xml node
            // NOTE: A ternary statement is being used to check for null values.
            //       In situations where a value needs to be cast a nested ternary statement is used
            //
                
            this.id                                     = ( id != null ) ? id.getText() : null;
                
            this.quoteLineItem.configured_sku__c        = ( configuredSku != null ) ? configuredSku.getText() : null;
            this.quoteLineItem.contractNumbers__c       = ( contractNumbers != null ) ? contractNumbers.getText() : null;
            this.quoteLineItem.endDate__c               = ( endDate != null ) ? (( endDate.getText() != '' ) ? parseDate( endDate.getText() ) : null) : null;
            this.quoteLineItem.name                     = ( name != null ) ? name.getText() : null;
            this.quoteLineItem.newOrRenewal__c          = ( newOrRenewal != null ) ? newOrRenewal.getText() : null;
            this.quoteLineItem.pricebookEntryId__c      = ( pricebookEntryId != null ) ? pricebookEntryId.getText() : null;
            this.quoteLineItem.pricing_attributes__c    = ( pricingAttributes != null ) ? pricingAttributes.getText() : null;
            this.quoteLineItem.productDescription__c    = ( productDescription != null ) ? productDescription.getText() : null;
            this.quoteLineItem.productFamily__c         = ( productFamily != null ) ? productFamily.getText() : null;
            this.quoteLineItem.quantity__c              = ( quantity != null ) ? (( quantity.getText() != '' ) ? Double.valueOf( quantity.getText() ) : 0.0) : null;
            this.quoteLineitem.startDate__c             = ( startDate != null ) ? (( startDate.getText() != '' ) ? parseDate( startDate.getText() ) : null) : null;
            this.quoteLineItem.term__c                  = ( term != null ) ? (( term.getText() != '' ) ? Double.valueOf( term.getText() ) : 0.0) : null;
            this.quoteLineItem.totalPrice__c            = ( totalPrice != null ) ? (( totalPrice.getText() != '' ) ? Double.valueOf( totalPrice.getText() ) : 0.0) : null;
            this.quoteLineItem.unitPrice__c             = ( unitPrice != null ) ? (( unitPrice.getText() != '' ) ? Double.valueOf( unitPrice.getText() ) : 0.0) : null;
            this.quoteLineItem.yearlySalesPrice__c      = ( yearlySalesPrice != null ) ? (( yearlySalesPrice.getText() != '' ) ? Double.valueOf( yearlySalesPrice.getText() ) : 0.0) : null;
        }
        
        
        /**
         * method for marshalling an object to XML
         *
         * @param DOM.Xmlnode   node 
         **/
         
        public void marshal( DOM.Xmlnode node )
        {
            
            //
            // generate quote line item node
            //
            
            DOM.xmlNode quoteLineItem = node.addChildElement( 'QuoteLineItem', SALESFORCE_MSG_NAMESPACE, '' );
            quoteLineItem.addChildElement( 'Id', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.id );
            quoteLineItem.addChildElement( 'Name', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.name );
            quoteLineItem.addChildElement( 'NewOrRenewal', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.newOrRenewal__c );
            quoteLineItem.addChildElement( 'ConfiguredSKU', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.configured_sku__c );
            quoteLineItem.addChildElement( 'ContractNumbers', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.contractNumbers__c );
            quoteLineItem.addChildElement( 'StartDate', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( date2XsDate( this.quoteLineItem.startDate__c ) );
            quoteLineItem.addChildElement( 'EndDate', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( date2XsDate( this.quoteLineItem.endDate__c ) );
            quoteLineItem.addChildElement( 'Term', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.term__c.format().replace(',','') );
            quoteLineItem.addChildElement( 'PricebookEntryId', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.pricebookEntryId__c );
            quoteLineItem.addChildElement( 'PricingAttributes', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.pricing_attributes__c );
            quoteLineItem.addChildElement( 'ProductDescription', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.productDescription__c );
            quoteLineItem.addChildElement( 'ProductFamily', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.productFamily__c );
            quoteLineItem.addChildElement( 'YearlySalesPrice', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.yearlySalesPrice__c.toPlainString() );  
            quoteLineItem.addChildElement( 'Quantity', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.quantity__c.toPlainString() );
            quoteLineItem.addChildElement( 'UnitPrice', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.unitPrice__c.toPlainString() );
            quoteLineItem.addChildElement( 'TotalPrice', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( this.quoteLineItem.totalPrice__c.toPlainString() );
            
            //
            // generate quote line item schedule nodes
            //
            
            system.debug('-- SalesQuoteLineItemSchedules: ' + this.salesQuoteLineItemSchedules.size());
            
            for ( salesQuoteLineItemSchedule  salesQuoteLineItemSchedule : this.salesQuoteLineItemSchedules )
            {
                salesQuoteLineItemSchedule.marshal( quoteLineItem );
            }
        } 
        
        
        /**
         * method for converting a string to a date 
         *
         * @return Date
         **/
         
        private Date parseDate (String dt) 
        {
            String[] x      = dt.split('-');
            Integer year    = Integer.valueOf( x[0] );
            Integer month   = Integer.valueOf( x[1] );
            Integer day     = Integer.valueOf( x[2] );
        
            return Date.newInstance(year, month, day);
        }
        
        
        /**
         * method for converting a SFDC Date to xs:date format
         *
         * @return String
         **/
         
        private String date2XsDate (Date dt)
        {
            String year     = String.valueOf( dt.year() );
            String month    = ( String.valueOf( dt.month() ).length() == 1 ) ? '0' + String.valueOf( dt.month() ) : String.valueOf( dt.month() );
            String day      = ( String.valueOf( dt.day() ).length() == 1 ) ? '0' + String.valueOf( dt.day() ) : String.valueOf( dt.day() );
            
            return year + '-' + month + '-' + day;
        }       
    }
    
    
    /**
     * class to model the quote line item schedule
     **/
     
    public class SalesQuoteLineItemSchedule
    {
        public QuoteLineItemSchedule__c quoteLineItemSchedule               { get; set; }


        /**
         * constructor
         **/
         
        public SalesQuoteLineItemSchedule()
        {
            this.quoteLineItemSchedule = new QuoteLineItemSchedule__c();
        }


        /**
         * method for marshalling an object to XML
         *
         * @param DOM.Xmlnode   node 
         **/
         
        public void marshal( DOM.Xmlnode node )
        {
            
            //
            // generate quote line item schedule node
            //
            
            string endDate                      = ( this.quoteLineItemSchedule.endDate__c != null) ? date2XsDate( this.quoteLineItemSchedule.endDate__c ) : '';
            string pricePerDay                  = ( this.quoteLineItemSchedule.pricePerDay__c != null) ? this.quoteLineItemSchedule.pricePerDay__c.toPlainString() : '';
            string prorateTotalPrice            = ( this.quoteLineItemSchedule.prorateTotalPrice__c != null) ? this.quoteLineItemSchedule.prorateTotalPrice__c.toPlainString() : ''; 
            string prorateUnitPrice             = ( this.quoteLineItemSchedule.prorateUnitPrice__c != null) ? this.quoteLineItemSchedule.prorateUnitPrice__c.toPlainString() : ''; 
            string prorateYearTotalPrice        = ( this.quoteLineItemSchedule.prorateYearTotalPrice__c != null) ? this.quoteLineItemSchedule.prorateYearTotalPrice__c.toPlainString() : ''; 
            string prorateYearUnitPrice         = ( this.quoteLineItemSchedule.prorateYearUnitPrice__c != null) ? this.quoteLineItemSchedule.prorateYearUnitPrice__c.toPlainString() : ''; 
            string startDate                    = ( this.quoteLineItemSchedule.startDate__c != null) ? date2XsDate( this.quoteLineItemSchedule.startDate__c ) : '';
            string year                         = ( this.quoteLineItemSchedule.year__c != null) ? this.quoteLineItemSchedule.year__c.format() : ''; 
            
            DOM.xmlNode quoteLineItemSchedule = node.addChildElement( 'QuoteLineItemSchedule', SALESFORCE_MSG_NAMESPACE, '' );
            quoteLineItemSchedule.addChildElement( 'PricePerDay', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( pricePerDay );
            quoteLineItemSchedule.addChildElement( 'ProrateTotalPrice', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( prorateTotalPrice );
            quoteLineItemSchedule.addChildElement( 'ProrateUnitPrice', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( prorateUnitPrice );
            quoteLineItemSchedule.addChildElement( 'ProrateYearTotalPrice', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( prorateYearTotalPrice );
            quoteLineItemSchedule.addChildElement( 'ProrateYearUnitPrice', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( ProrateYearUnitPrice );
            quoteLineItemSchedule.addChildElement( 'StartDate', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( startDate );
            quoteLineItemSchedule.addChildElement( 'EndDate', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( endDate );
            quoteLineItemSchedule.addChildElement( 'Year', SALESFORCE_MSG_NAMESPACE, '' ).addTextNode( year );
        }
        
        
        /**
         * method for converting a SFDC Date to xs:date format
         *
         * @return String
         **/
         
        private String date2XsDate (Date dt)
        {
            String year     = String.valueOf( dt.year() );
            String month    = ( String.valueOf( dt.month() ).length() == 1 ) ? '0' + String.valueOf( dt.month() ) : String.valueOf( dt.month() );
            String day      = ( String.valueOf( dt.day() ).length() == 1 ) ? '0' + String.valueOf( dt.day() ) : String.valueOf( dt.day() );
            
            return year + '-' + month + '-' + day;
        }       
    }
    
    
    public class QuoteException extends Exception {}
}