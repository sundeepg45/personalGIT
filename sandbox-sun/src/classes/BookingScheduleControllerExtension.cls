public class BookingScheduleControllerExtension {
    private final Opportunity opportunity;    
    private List<OpportunityProduct> opportunityProductList;

    public BookingScheduleControllerExtension(ApexPages.StandardController standardController)
    {
        this.opportunity = (Opportunity) standardController.getRecord();
    }
    
    public List<OpportunityProduct> getOpportunityProductList()
    {       
        opportunityProductList = new List<OpportunityProduct>();
        
        try 
        {              
            for (OpportunityLineItem opportunityLineItem : [select 
                PricebookEntry.Product2.ProductCode,                    
                ActualStartDate__c,                    
                ActualEndDate__c,
                Quantity,
                UnitPrice,
                TotalPrice,
                CurrencyIsoCode,
                Configured_SKU__c,
                Year1Amount__c, 
                Year2Amount__c,
                Year3Amount__c,
                Year4Amount__c,
                Year5Amount__c,
                Year6Amount__c
                from OpportunityLineItem 
                where OpportunityId = :opportunity.Id]) 
            {                                                                              
                OpportunityProduct opportunityProduct = new OpportunityProduct();
                opportunityProduct.StartDate = Date.valueOf(opportunityLineItem.ActualStartDate__c).format();
                opportunityProduct.EndDate = Date.valueOf(opportunityLineItem.ActualEndDate__c).format();
                opportunityProduct.Quantity = String.valueOf(opportunityLineItem.Quantity.longValue());
                opportunityProduct.UnitPrice = formatCurrency(opportunityLineItem.UnitPrice);
                opportunityProduct.TotalPrice = formatCurrency(opportunityLineItem.TotalPrice);
                opportunityProduct.Year1Amount = formatCurrency(opportunityLineItem.Year1Amount__c);                                                     
                opportunityProduct.Year2Amount = formatCurrency(opportunityLineItem.Year2Amount__c);
                opportunityProduct.Year3Amount = formatCurrency(opportunityLineItem.Year3Amount__c);
                opportunityProduct.Year4Amount = formatCurrency(opportunityLineItem.Year4Amount__c);
                opportunityProduct.Year5Amount = formatCurrency(opportunityLineItem.Year5Amount__c);
                opportunityProduct.Year6Amount = formatCurrency(opportunityLineItem.Year6Amount__c);
                
                if (opportunityLineItem.Configured_SKU__c != null)
                    opportunityProduct.ProductCode = opportunityLineItem.Configured_SKU__c;
                else 
                    opportunityProduct.ProductCode = opportunityLineItem.PricebookEntry.Product2.ProductCode;
                
                opportunityProductList.add(opportunityProduct);
            }
        }
        catch(Exception error) 
        {
            System.debug(error.getMessage());
        }                                           

        return opportunityProductList; 
    }  
    
    public String getYear1Amount()
    {
        return formatCurrency(opportunity.Year1Amount__c);
    }
    
    public String getYear2Amount()
    {
        return formatCurrency(opportunity.Year2Amount__c);
    }
    
    public String getYear3Amount()
    {
        return formatCurrency(opportunity.Year3Amount__c);
    }
    
    public String getYear4Amount()
    {
        return formatCurrency(opportunity.Year4Amount__c);
    }
    
    public String getYear5Amount()
    {
        return formatCurrency(opportunity.Year5Amount__c);
    }
    
    public String getYear6Amount()
    {
        return formatCurrency(opportunity.Year6Amount__c);
    }        
    
    public class OpportunityProduct {
        public String productCode {get; set;}
        public String startDate {get; set;}
        public String endDate {get; set;}
        public String quantity {get; set;}
        public String unitPrice {get; set;}
        public String totalPrice {get; set;}
        public String year1Amount {get; set;}
        public String year2Amount {get; set;}
        public String year3Amount {get; set;}
        public String year4Amount {get; set;}
        public String year5Amount {get; set;}
        public String year6Amount {get; set;}
    }
    
    public String formatCurrency(Decimal value) {
        if (value != null) {
            return opportunity.CurrencyIsoCode + ' ' + convert(value).format();
        } else {
            return opportunity.CurrencyIsoCode + ' ' + 0.00.format();
        }
    }
    
    public Double convert(Decimal value)
    {
        return value.setScale(2);
    }    
}