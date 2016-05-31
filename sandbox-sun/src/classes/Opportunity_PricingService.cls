/**
 * @author Bryan Bosely <bbosely@redhat.com>
 * @version 2012-06-26
 * 2010-03-31 - Created
 * Scott Coleman <scoleman@redhat.com>
 * 2012-06-26 - Updated for R12 to include parter account details in pricing service callout
 * Chandan Prusty <cprusty@redhat.com>
 * 2014-09-23 - Updated for changing the pricing XML structure
 */

public class Opportunity_PricingService {
    
    static String PRICING_MESSAGE_NAMESPACE = 'http://esb.redhat.com/Pricing/1';
    
    
    /**
     * initiates the process of making a call to the pricing web service
     *
     * getOpportunityPricing
     * @param opportunityId
     * @return Map<String, Result>
     */
     
    public Map<String, Opportunity_PricingService.Result> getOpportunityPricing(String opportunityId) {
        
        System.debug('Retrieve details for opportunity id:' + opportunityId);
        
        //
        // ensure that the opportunityId argument is not null
        //
        
        if (opportunityId == null)
            throw new PricingServiceException('argument opportunityId is null');        
        
        Opportunity opportunity = getOpportunityDetails(opportunityId);
        
        //
        // ensure the opportunity has line items
        //
        
        if (opportunity.opportunityLineItems.size() == 0)
            throw new PricingServiceException('There are no line items to price for this opportunity');
            
        String requestXML = generateRequestXML(opportunity);
        String responseXML = callPricingService(requestXML);


        Map<String, Opportunity_PricingService.Result> pricingMap = parseResponseXML(responseXML);
        
        //
        // NOTE: 5/27/10 commenting out call to method updateLineItemPricing
        // to allow end users the ability to determine which line items will
        // be updated - bbosely
        //:
        // updateLineItemPricing(pricingMap);
        //  
        
        return PricingMap;
    } 
    
    
    /**
     * TODO: This class will need to be refactored to account for the addition of this call
     * In the interest of time and looming deadlines this one method will encapsulate the getProductInfo call
     *
     * initiates the process of making a call to the pricing web service
     *
     * getProductInfo
     * @param configuredSKU
     * @return ProductResult>
     */
     
    public Opportunity_PricingService.ProductResult getProductInfo(String configuredSKU) {
        
        //
        // REFACTOR - duplicate code
        //
        
        System.debug('generating pricing service request XML: getProductInfo');
        
        DOM.Document requestXML = new DOM.Document();
        DOM.xmlNode requestProposalBuilderMsg = requestXML.createRootElement('ProposalbuilderMessage', '', '');
    
        //
        // generate header node
        //
        
        DOM.xmlNode header = requestProposalBuilderMsg.addChildElement('Header', '', '');
        header.addChildElement('System', '', '').addTextNode('SFDC');
        header.addChildElement('Operation', '', '').addTextNode('Sync');
        header.addChildElement('Type', '', '').addTextNode('Quote');
        header.addChildElement('InstanceId', '', '').addTextNode( 'productinfo_' + system.now().format('yyyy-MM-dd\'T\'HH:mm:ss'));
        header.addChildElement('Timestamp', '', '').addTextNode(system.now().format('yyyy-MM-dd\'T\'HH:mm:ss'));
        
        //
        // generate payload node
        //
        
        DOM.xmlNode requestPayload = requestProposalBuilderMsg.addChildElement('Payload', '', '');
        
        //
        // generate Product node
        //
    
        DOM.XmlNode requestProduct = requestPayload.addChildElement('Product', '', '');
        requestProduct.addChildElement('ConfigSku', '', '').addTextNode(configuredSKU);
        System.Debug('Pricing Service request XML getProductInfo: ' + requestXML.toXmlString());
        
        //
        // call the pricing web service
        //

        String responseXML;

        if (!System.Test.isRunningTest()) {
            WS_PricingServices.PricingFacadePort wps = new WS_PricingServices.PricingFacadePort();
            wps.timeout_x = 60000;
            responseXML = wps.getProductInfo(requestXML.toXmlString());
        }
        else {
            responseXML = Opportunity_PricingServiceTest.PRODUCT_RESPONSE_XML;
        }           
        System.Debug('Pricing Service response XML getProductInfo: ' + responseXML);
        
        //
        // parse response XML
        //
        
        System.debug('parsing pricing service response XML: getProductInfo');
        
        Opportunity_PricingService.ProductResult result = new Opportunity_PricingService.ProductResult();
            
        try {
               
            DOM.Document response = new DOM.Document();
            response.load(responseXML);
            
        
            DOM.XMLNode responseProposalBuilderMsg = response.getRootElement();
            System.Debug(responseProposalBuilderMsg);
            DOM.XMLNode responsePayload = responseProposalBuilderMsg.getChildElement('Payload', PRICING_MESSAGE_NAMESPACE);
            DOM.XMLNode product = responsePayload.getChildElement('Product', PRICING_MESSAGE_NAMESPACE);
            DOM.XMLNode status = product.getChildElement('Status', PRICING_MESSAGE_NAMESPACE);
            String statusCode = status.getChildElement('Code', PRICING_MESSAGE_NAMESPACE).getText().toUpperCase();
 
            //
            // get the product contraints
            //
            
            String attributes = '';
            for (Integer i=0; i<product.getChildElements().size(); i++) {
                Dom.XMLNode child = product.getChildElements()[i];
                
                if (child.getName() != 'ProductConstraint')
                    continue;
                
                String code = '';
                String value = '';
                
                //
                //  ensure the product constraint nodes we're interested in are in the response xml
                //
                    
                for (Dom.XMLNode node : child.getChildElements()) {
                    if (node.getName() == 'Code')
                        code = child.getChildElement('Code', PRICING_MESSAGE_NAMESPACE).getText();
                        
                    if (node.getName() == 'Value')
                        value = child.getChildElement('Value',PRICING_MESSAGE_NAMESPACE).getText();
                }
                
                //
                // add the attribute to the attributes string if the code and value vars have a value
                //
                
                if (code != '' && value != '') {
                    attributes += code + '='; 
                    attributes += (i == (product.getChildElements().size() - 1)) ? value : value + ',';
                }   
            }
            
            //
            // get the details for the configured sku 
            //
            
            if (statusCode == 'SUCCESS') {
                String sku = product.getChildElement('Sku', PRICING_MESSAGE_NAMESPACE).getText();
                String description = product.getChildElement('ConfigSkuDescription', PRICING_MESSAGE_NAMESPACE).getText();
       
                result.baseSKU = sku;       
                result.attributes = attributes;
                result.description = description;
            }
            else {
                String statusMsg = status.getChildElement('Message', PRICING_MESSAGE_NAMESPACE).getText();
                
                result.statusMsg = statusMsg;
            }
            
            result.statusCode = statusCode;
       
            
            return result;
        }
        catch(Exception e) {
            throw new PricingServiceException('Unable to retrieve product info: ' + e.getMessage());
        }
        
    }
    
    /**
     * queries SFDC to obtain the values needed to created the pricing service XML
     *
     * getOpportunityDetails
     * @param opportunityId
     * @return opportunity
     */
     
    public Opportunity getOpportunityDetails(String opportunityId) {
    
        //
        // query SFDC for the opportunity details
        //
        
        System.debug('Query SFDC for opportunity');
            
        Opportunity opportunity = [
            SELECT Account.BillingCity
                 , Account.BillingCountry
                 , Account.BillingPostalCode
                 , Account.BillingState
                 , Account.BillingStreet
                 , Account.Name
                 , Account.OracleAccountNumber__c
                 , Account.ShippingCity
                 , Account.ShippingCountry
                 , Account.ShippingPostalCode
                 , Account.ShippingState
                 , Account.ShippingStreet
                 , Account.VATNumber__c
                 , Country_Of_Order__c
                 , CurrencyIsoCode
                 , Id
                 , OpportunityNumber__c
                 , OpportunityType__c
                 , Owner.Name
                 , Owner.Email
                 , PaymentType__c
                 , Super_Region__c
                 , Pay_Now__c
                 , Operating_Unit__c
                 , Bill_To_Address__r.Address_Line1__c  
                 , Bill_To_Address__r.Address_Line2__c  
                 , Bill_To_Address__r.City__c  
                 , Bill_To_Address__r.County__c  
                 , Bill_To_Address__r.Province__c  
                 , Bill_To_Address__r.State__c  
                 , Bill_To_Address__r.Zip_Postal_Code__c  
                 , Bill_To_Address__r.Country__c
                 , Ship_To_Address__r.Address_Line1__c  
                 , Ship_To_Address__r.Address_Line2__c  
                 , Ship_To_Address__r.City__c  
                 , Ship_To_Address__r.County__c  
                 , Ship_To_Address__r.Province__c  
                 , Ship_To_Address__r.State__c  
                 , Ship_To_Address__r.Zip_Postal_Code__c  
                 , Ship_To_Address__r.Country__c
                 , Sold_To_Address__r.Address_Line1__c  
                 , Sold_To_Address__r.Address_Line2__c  
                 , Sold_To_Address__r.City__c  
                 , Sold_To_Address__r.County__c  
                 , Sold_To_Address__r.Province__c  
                 , Sold_To_Address__r.State__c  
                 , Sold_To_Address__r.Zip_Postal_Code__c  
                 , Sold_To_Address__r.Country__c
                 , Entitle_To_Address__r.Address_Line1__c  
                 , Entitle_To_Address__r.Address_Line2__c  
                 , Entitle_To_Address__r.City__c  
                 , Entitle_To_Address__r.County__c  
                 , Entitle_To_Address__r.Province__c  
                 , Entitle_To_Address__r.State__c  
                 , Entitle_To_Address__r.Zip_Postal_Code__c  
                 , Entitle_To_Address__r.Country__c 
                 , Bill_To_Account__r.Name
                 , Bill_To_Account__r.EBS_Party_Number__c
                 , Ship_To_Account__r.Name
                 , Ship_To_Account__r.EBS_Party_Number__c
                 , Sold_To_Account__r.Name
                 , Sold_To_Account__r.EBS_Party_Number__c
                 , Entitle_To_Account__r.Name
                 , Entitle_To_Account__r.EBS_Party_Number__c
                 , Bill_To_Sales_Account__r.Name
                 , Entitle_To_Sales_Account__r.Name
                 ,Ship_To_Sales_Account__r.Name
                 ,Sold_To_Sales_Account__r.Name
                 , (SELECT Id
                         , ActualEndDate__c
                         , ActualStartDate__c
                         , ActualTerm__c
                         , Configured_SKU__c
                         , Pricing_Attributes__c
                         , PricebookEntry.Name
                         , PricebookEntry.PriceBook2.Name
                         , PricebookEntry.Product2.Description
                         , PricebookEntry.Product2.ProductCode
                         , PriceBookEntry.UnitPrice
                         , Quantity
                         , UnitPrice
                      FROM OpportunityLineItems)
                 , (SELECT Id
                         , Partner__r.BillingCity
                         , Partner__r.BillingCountry
                         , Partner__r.BillingPostalCode
                         , Partner__r.BillingState
                         , Partner__r.BillingStreet
                         , Partner__r.Name
                         , Partner__r.OracleAccountNumber__c
                         , Partner__r.ShippingCity
                         , Partner__r.ShippingCountry
                         , Partner__r.ShippingPostalCode
                         , Partner__r.ShippingState
                         , Partner__r.ShippingStreet
                         , Partner__r.VATNumber__c
                         , PartnerType__r.Name
                         , PartnerTier__r.Name
                         , Oracle_Classification_Code__c
                         , RelationshipType__c
                         , Account_Number_Test__c
                         , Partner_Tier_Test__c
                         , Partner_Type_Test__c
                         , Transaction_Role_Test__c
                      FROM OpportunityPartners2__r)
                 , (SELECT Id
                         , StartDate__c
                      FROM Quotes__r
                     WHERE isActive__c = true)                   
              FROM Opportunity
             WHERE Id = :opportunityId
             LIMIT 1
        ];
        
        return opportunity;
    }
    
    
    /**
     * generates the pricing service request XML
     *
     * generateRequestXML
     * @param opportunityId
     * @return String 
     */
     
    public String generateRequestXML(String opportunityId) {
        Opportunity opportunity = getOpportunityDetails(opportunityId);
        String requestXML = generateRequestXML(opportunity);
        
        return requestXML;
    }
    
    
    /**
     * generates the pricing service request XML
     *
     * generateRequestXML
     * @param opportunity
     * @return String
     */
    
    public String generateRequestXML(Opportunity opportunity){
    System.debug('generating pricing service request XML');
    system.debug('The Opportunity details:::::::::::'+opportunity);
    DOM.Document doc = new DOM.Document();
    DOM.xmlNode proposalBuilderMsg = doc.createRootElement('ProposalbuilderMessage', '', '');
    
    //
    // generate header node
    //
    
    DOM.xmlNode header = proposalBuilderMsg.addChildElement('Header', '', '');
    header.addChildElement('System', '', '').addTextNode('SFDC');
    header.addChildElement('Operation', '', '').addTextNode('Sync');
    header.addChildElement('Type', '', '').addTextNode('Quote');
    header.addChildElement('InstanceId', '', '').addTextNode( isNull (opportunity.Id)  + '_' + system.now().format('yyyy-MM-dd\'T\'HH:mm:ss'));
    header.addChildElement('Timestamp', '', '').addTextNode(system.now().format('yyyy-MM-dd\'T\'HH:mm:ss'));    
    
    //
    // generate payload node
    //
    
    DOM.xmlNode payload = proposalBuilderMsg.addChildElement('Payload', '', '');
    
    //
    // generate Quote node
    //
    
    DOM.XmlNode quote = payload.addChildElement('Quote', '', '');
    
    //
    // generate the quoteHeader node
    //
        
    DOM.XmlNode quoteHeader = quote.addChildElement('QuoteHeader', '', '');
    quoteHeader.addChildElement('QuoteNumber', '', '').addTextNode( isNull(opportunity.Id) );
    quoteHeader.addChildElement('QuoteSource', '', '').addTextNode('ProposalBuilder');      
    quoteHeader.addChildElement('SuperRegion', '', '').addTextNode( isNull(opportunity.Super_Region__c) );  
    quoteHeader.addChildElement('CountryOfOrder', '', '').addTextNode( isNull( isCountryUS(opportunity.Country_Of_Order__c) ) );   
    quoteHeader.addChildElement('CurrencyIso3Code', '', '').addTextNode( isNull(opportunity.CurrencyIsoCode) );
    
    // generate sales rep email node
    DOM.XmlNode salesRepEmail = quoteHeader.addChildElement('SalesRepEmail', '', '');
    salesRepEmail.setAttribute('type', 'WORK');
    salesRepEmail.setAttribute('recipient-type', 'TO');
    salesRepEmail.addChildElement('Name', '', '').addTextNode( isNull(opportunity.Owner.Name) );
    salesRepEmail.addChildElement('EmailAddress', '', '').addTextNode ( isNull(opportunity.Owner.Email) );
        
    quoteHeader.addChildElement('OpportunityType', '', '').addTextNode( isNull(opportunity.OpportunityType__c) );
    quoteHeader.addChildElement('OpportunityNumber', '', '').addTextNode( isNull(opportunity.OpportunityNumber__c) );       
    quoteHeader.addChildElement('PayNow', '', '').addTextNode( (isNull(opportunity.Pay_Now__c))=='Yes'?'True':'False');
    quoteHeader.addChildElement('OperatingUnit', '', '').addTextNode( isNull(opportunity.Operating_Unit__c) );
    
    //
    // generate the quote line item nodes
    //
    
    for (OpportunityLineItem line: opportunity.OpportunityLineItems) {
                
        DOM.XmlNode quoteLineItem = quote.addChildElement( 'QuoteLineItem', '', '' );
        quoteLineItem.addChildElement('LineNumber', '', '').addTextNode(line.Id);
            
        //
        // generate the product node
        //
            
        DOM.XmlNode product = quoteLineItem.addChildElement('Product', '', '');
        product.addChildElement('Sku', '', '').addTextNode( isNull(line.PriceBookEntry.Product2.ProductCode) );
            
        //
        // generate xml nodes for configSku, configSkuDescription if we have a configured sku
        //
                
        if (line.Configured_SKU__c == null || line.Configured_SKU__c == '') {
            product.addChildElement('SkuDescription', '', '').addTextNode( isNull(line.PriceBookEntry.Product2.Description) );
        }
        else {
            product.addChildElement('ConfigSku', '', '').addTextNode( isNull(line.Configured_SKU__c) );
            product.addChildElement('ConfigSkuDescription', '', '').addTextNode( isNull(line.PriceBookEntry.Product2.Description) );
                
            //
            // generate product contraint nodes
            //
                
            if (line.Pricing_Attributes__c != null) {
                List<String> attributes = line.Pricing_Attributes__c.split(',');
                for (String nameValuePair : attributes) {
                List<String> attribute = nameValuePair.split('=');
                  
                DOM.XmlNode constraint = product.addChildElement('ProductConstraint', '', '');
                constraint.addChildElement('Code', '', '').addTextNode( isNull(attribute[0]) );
                constraint.addChildElement('Value', '', '').addTextNode( isNull(attribute[1]) );
                }
              }
            }
            
            Dom.XMLNode Quantity = quoteLineItem.addChildElement('Quantity', '', '');
            Quantity.setAttribute('uom', 'EA');
            Quantity.addTextNode(  isNull((line.Quantity).toPlainString()) );
            
            quoteLineItem.addChildElement('StartDate', '', '').addTextNode( date2XsDate(line.ActualStartDate__c) );
            quoteLineItem.addChildElement('EndDate', '', '').addTextNode( date2XsDate(line.ActualEndDate__c) );
            
            
            if (line.ActualTerm__c != null) {  
              String duration = '1'; 
              
              if (line.ActualTerm__c >= 1095)
                duration = '3';
                
              quoteLineItem.addChildElement('ServiceDuration', '', '').addTextNode( isNull(duration) );
            }
            
            quoteLineItem.addChildElement('ServicePeriod', '', '').addTextNode('YR');  
            quoteLineItem.addChildElement('UnitPrice', '', '').addTextNode( isNull((line.UnitPrice).toPlainString()) );
            quoteLineItem.addChildElement('ListPrice', '', '').addTextNode( isNull((line.PriceBookEntry.UnitPrice).toPlainString()) );
            quoteLineItem.addChildElement('PricingEffectiveDate', '', '').addTextNode('');
        }
        
        //
        // generate the account node
        //
        
        DOM.XmlNode entitleToaccount = quote.addChildElement('Account', '', '');
        entitleToaccount.addChildElement('AccountTransactionRole', '', '').addTextNode('END_CUSTOMER');
        entitleToaccount.addChildElement('PartyName', '', '').addTextNode( isNull(Opportunity.Entitle_To_Sales_Account__r.Name));
        entitleToaccount.addChildElement('AccountNumber', '', '').addTextNode( isNull(Opportunity.Entitle_To_Account__r.Name));
        DOM.XMLNode entitleToAddress = entitleToaccount.addChildElement('Address', '', '');
        entitleToAddress.addChildElement('Address1', '', '').addTextNode( isNull(Opportunity.Entitle_To_Address__r.Address_Line1__c) );
        entitleToAddress.addChildElement('Address2', '', '').addTextNode( isNull(Opportunity.Entitle_To_Address__r.Address_Line2__c) );
        entitleToAddress.addChildElement('City', '', '').addTextNode( isNull(Opportunity.Entitle_To_Address__r.City__c) );
        entitleToAddress.addChildElement('County', '', '').addTextNode( isNull(Opportunity.Entitle_To_Address__r.County__c) );
        entitleToAddress.addChildElement('State', '', '').addTextNode( isNull(Opportunity.Entitle_To_Address__r.State__c) );
        entitleToAddress.addChildElement('Province', '', '').addTextNode( isNull(Opportunity.Entitle_To_Address__r.Province__c) );
        entitleToAddress.addChildElement('PostalCode', '', '').addTextNode( isNull(Opportunity.Entitle_To_Address__r.Zip_Postal_Code__c) );
        entitleToAddress.addChildElement('Country', '', '').addTextNode( isNull(Opportunity.Entitle_To_Address__r.Country__c) );
        
        DOM.XmlNode billToaccount = quote.addChildElement('Account', '', '');
        billToaccount.addChildElement('AccountTransactionRole', '', '').addTextNode('BILL_TO');
        billToaccount.addChildElement('PartyName', '', '').addTextNode( isNull(Opportunity.Bill_To_Sales_Account__r.Name));
        billToaccount.addChildElement('AccountNumber', '', '').addTextNode( isNull(Opportunity.Bill_To_Account__r.Name));
        DOM.XMLNode billToAddress = billToaccount.addChildElement('Address', '', '');
        billToAddress.addChildElement('Address1', '', '').addTextNode( isNull(Opportunity.Bill_To_Address__r.Address_Line1__c) );
        billToAddress.addChildElement('Address2', '', '').addTextNode( isNull(Opportunity.Bill_To_Address__r.Address_Line2__c) );
        billToAddress.addChildElement('City', '', '').addTextNode( isNull(Opportunity.Bill_To_Address__r.City__c) );
        billToAddress.addChildElement('County', '', '').addTextNode( isNull(Opportunity.Bill_To_Address__r.County__c) );
        billToAddress.addChildElement('State', '', '').addTextNode( isNull(Opportunity.Bill_To_Address__r.State__c) );
        billToAddress.addChildElement('Province', '', '').addTextNode( isNull(Opportunity.Bill_To_Address__r.Province__c) );        
        billToAddress.addChildElement('PostalCode', '', '').addTextNode( isNull(Opportunity.Bill_To_Address__r.Zip_Postal_Code__c) );
        billToAddress.addChildElement('Country', '', '').addTextNode( isNull(Opportunity.Bill_To_Address__r.Country__c) );
        
        DOM.XmlNode shipToaccount = quote.addChildElement('Account', '', '');
        shipToaccount.addChildElement('AccountTransactionRole', '', '').addTextNode('SHIP_TO');
        shipToaccount.addChildElement('PartyName', '', '').addTextNode( isNull(Opportunity.Ship_To_Sales_Account__r.Name));
        shipToaccount.addChildElement('AccountNumber', '', '').addTextNode( isNull(Opportunity.Ship_To_Account__r.Name));
        DOM.XMLNode shipToAddress = shipToaccount.addChildElement('Address', '', '');
        shipToAddress.addChildElement('Address1', '', '').addTextNode( isNull(Opportunity.Ship_To_Address__r.Address_Line1__c) );
        shipToAddress.addChildElement('Address2', '', '').addTextNode( isNull(Opportunity.Ship_To_Address__r.Address_Line2__c) );
        shipToAddress.addChildElement('City', '', '').addTextNode( isNull(Opportunity.Ship_To_Address__r.City__c) );
        shipToAddress.addChildElement('County', '', '').addTextNode( isNull(Opportunity.Ship_To_Address__r.County__c) );
        shipToAddress.addChildElement('State', '', '').addTextNode( isNull(Opportunity.Ship_To_Address__r.State__c) );
        shipToAddress.addChildElement('Province', '', '').addTextNode( isNull(Opportunity.Ship_To_Address__r.Province__c) );        
        shipToAddress.addChildElement('PostalCode', '', '').addTextNode( isNull(Opportunity.Ship_To_Address__r.Zip_Postal_Code__c) );
        shipToAddress.addChildElement('Country', '', '').addTextNode( isNull(Opportunity.Ship_To_Address__r.Country__c) );
        
        DOM.XmlNode soldToaccount = quote.addChildElement('Account', '', '');
        soldToaccount.addChildElement('AccountTransactionRole', '', '').addTextNode('SOLD_TO');
        soldToaccount.addChildElement('PartyName', '', '').addTextNode( isNull(Opportunity.Sold_To_Sales_Account__r.Name));
        soldToaccount.addChildElement('AccountNumber', '', '').addTextNode( isNull(Opportunity.Sold_To_Account__r.Name));
        DOM.XMLNode soldToAddress = soldToaccount.addChildElement('Address', '', '');
        soldToAddress.addChildElement('Address1', '', '').addTextNode( isNull(Opportunity.Sold_To_Address__r.Address_Line1__c) );
        soldToAddress.addChildElement('Address2', '', '').addTextNode( isNull(Opportunity.Sold_To_Address__r.Address_Line2__c) );
        soldToAddress.addChildElement('City', '', '').addTextNode( isNull(Opportunity.Sold_To_Address__r.City__c) );
        soldToAddress.addChildElement('County', '', '').addTextNode( isNull(Opportunity.Sold_To_Address__r.County__c) );
        soldToAddress.addChildElement('State', '', '').addTextNode( isNull(Opportunity.Sold_To_Address__r.State__c) );
        soldToAddress.addChildElement('Province', '', '').addTextNode( isNull(Opportunity.Sold_To_Address__r.Province__c) );        
        soldToAddress.addChildElement('PostalCode', '', '').addTextNode( isNull(Opportunity.Sold_To_Address__r.Zip_Postal_Code__c) );
        soldToAddress.addChildElement('Country', '', '').addTextNode( isNull(Opportunity.Sold_To_Address__r.Country__c) );
        
        //
        // generate partner account nodes
        //
        
        for (OpportunityPartner__c partner: opportunity.OpportunityPartners2__r) {
          DOM.XmlNode account = quote.addChildElement('Account', '', '');         
          account.addChildElement('AccountTransactionRole', '', '').addTextNode( isNull(partner.RelationshipType__c) );
          // Commented below two tags and added new tag, as new pricing call changes to include partnercode US59507.
          //account.addChildElement('PartnerType', '', '').addTextNode( isNull(partner.Partner_Type_Test__c) );       
          //account.addChildElement('PartnerTier', '', '').addTextNode( isNull(partner.Partner_Tier_Test__c) );
          account.addChildElement('PartnerCode', '', '').addTextNode(isNull(partner.Oracle_Classification_Code__c));
          account.addChildElement('PartyName', '', '').addTextNode( isNull(partner.Partner__r.Name) );
          account.addChildElement('AccountNumber', '', '').addTextNode( isNull(partner.Account_Number_Test__c) );
          

          DOM.XmlNode billingAddress = account.addChildElement('Address', '', '');
          billingAddress.addChildElement('Address1', '', '').addTextNode( isNull(partner.Partner__r.BillingStreet) );
          billingAddress.addChildElement('City', '', '').addTextNode( isNull(partner.Partner__r.BillingCity) );
          billingAddress.addChildElement('State', '', '').addTextNode( isNull(partner.Partner__r.BillingState) );
          billingAddress.addChildElement('PostalCode', '', '').addTextNode( isNull(partner.Partner__r.BillingPostalCode) );
          billingAddress.addChildElement('Country', '', '').addTextNode( isNull( isCountryUS(partner.Partner__r.BillingCountry) ) );

          /*DOM.XmlNode shippingAddress = account.addChildElement('Address', '', '');
          shippingAddress.addChildElement('Address1', '', '').addTextNode( isNull(partner.Partner__r.ShippingStreet) );
          shippingAddress.addChildElement('City', '', '').addTextNode( isNull(partner.Partner__r.ShippingCity) );
          shippingAddress.addChildElement('State', '', '').addTextNode( isNull(partner.Partner__r.ShippingState) );
          shippingAddress.addChildElement('PostalCode', '', '').addTextNode( isNull(partner.Partner__r.ShippingPostalCode) );
          shippingAddress.addChildElement('Country', '', '').addTextNode( isNull( isCountryUS(partner.Partner__r.ShippingCountry) ) );  */  
        }
        
        System.debug('Pricing Service request XML: ' + doc.toXmlString()); 
        return doc.toXmlString();
    }
    
    
    /**
     * calls the pricing web service
     *
     * callPricingService
     * @param requestXML
     * @param String - Response XML
     */
     
    public String callPricingService(string requestXML) {
        
        WS_PricingServices.PricingFacadePort wps = new WS_PricingServices.PricingFacadePort();
        wps.timeout_x = 60000;
        
        String responseXML;
        if (!System.Test.isRunningTest()) {
            responseXML = wps.calculatePrice(requestXML);
        }
        else {
            responseXML = Opportunity_PricingServiceTest.RESPONSE_XML;
        }
        System.Debug('Pricing Service response XML: ' + responseXML);
        
        return responseXML;
    }
    
    
    /**
     * parses the response returned from the pricing web service
     *
     * parseResponseXML
     * @param opportunityId
     * @return Map<String, Opportunity_PricingService.Result>
     */
     
    public Map<String, Opportunity_PricingService.Result> parseResponseXML(String xmlResponse) {
        System.debug('parsing pricing service response XML');
        
        Map<String, Opportunity_PricingService.Result> pricing = new Map<String, Opportunity_PricingService.Result>();
            
        try {
               
            DOM.Document doc = new DOM.Document();
            doc.load(xmlResponse);
        
            DOM.XMLNode proposalBuilderMsg = doc.getRootElement();
            System.Debug(proposalBuilderMsg);
            DOM.XMLNode payload = proposalBuilderMsg.getChildElement('Payload', PRICING_MESSAGE_NAMESPACE);
            DOM.XMLNode quote = payload.getChildElement('Quote', PRICING_MESSAGE_NAMESPACE);
            DOM.XMLNode quoteHeader = quote.getChildElement('QuoteHeader', PRICING_MESSAGE_NAMESPACE);
            DOM.XMLNode status = quote.getChildElement('Status', PRICING_MESSAGE_NAMESPACE);
        
            String opportunityId = quoteHeader.getChildElement('QuoteNumber', PRICING_MESSAGE_NAMESPACE).getText();
            String code = status.getChildElement('Code', PRICING_MESSAGE_NAMESPACE).getText();
            System.Debug('Status:' + code);
        
            //
            // get the line item pricing
            //
        
            for(Dom.XMLNode child : quote.getChildElements()) {
            
                if (child.getName() != 'QuoteLineItem')
                    continue;
                
                String lineNumber = child.getChildElement('LineNumber', PRICING_MESSAGE_NAMESPACE).getText();
                String lineItemStatus = child.getChildElement('Status', PRICING_MESSAGE_NAMESPACE).getChildElement('Code', PRICING_MESSAGE_NAMESPACE).getText();
                String lineItemMessage = child.getChildElement('Status', PRICING_MESSAGE_NAMESPACE).getChildElement('Message', PRICING_MESSAGE_NAMESPACE).getText();
            
                System.Debug('Line Item Status - Opportunity: ' + opportunityId + ' LineNumber: ' + lineNumber + ' LineItemStatus: ' + lineItemStatus + ' LineItemMessage: ' + lineItemMessage);
                
                
                Opportunity_PricingService.Result result = new Opportunity_PricingService.Result();
                result.opportunityLineItemId = lineNumber;
                result.lineItemStatusCode = lineItemStatus;
                result.lineItemStatusMsg = lineItemMessage;
                                
                if (lineItemStatus == 'SUCCESS') {
                    
                    Discount priceInst = new Discount();
                    result.discount = new list<Discount>();
                    for (Dom.XMLNode node : child.getChildElements()) {
                        if (node.getName() == 'Price'){
                            priceInst = new Discount();
                            String priceCode = node.getChildElement('Code', PRICING_MESSAGE_NAMESPACE).getText();
                            if (priceCode == 'UNIT_PRICE') {    
                                Decimal unitPrice = decimal.valueOf(node.getChildElement('Value', PRICING_MESSAGE_NAMESPACE).getText());
                                result.unitPrice = unitPrice;
                            }  
                            priceInst.code = node.getChildElement('Code', PRICING_MESSAGE_NAMESPACE).getText(); 
                            priceInst.description = node.getChildElement('Description', PRICING_MESSAGE_NAMESPACE).getText();   
                            priceInst.value = node.getChildElement('Value', PRICING_MESSAGE_NAMESPACE).getText();
                            result.discount.add(priceInst);
                        }
                    }
                    result.unitPriceNew = child.getChildElement('UnitPrice', PRICING_MESSAGE_NAMESPACE).getText();
                    result.unitListPrice = child.getChildElement('UnitListPrice', PRICING_MESSAGE_NAMESPACE).getText();
                }
                pricing.put(lineNumber, result); 
            }
        }
        catch(Exception e) {
            throw new PricingServiceException('Unable to retrieve pricing data: ' + e.getMessage());
        }
        
        return pricing;
    }
    
    
    /**
     * updates the SFDC opportunity line items with the MSRP price return
     * from the pricing web service
     *
     * updateLineItemPricing
     * @param Map<String, String>
     */
     
    public void updateLineItemPricing(Map<String, String> pricing) {
        
        //
        // determine if we have any line items to update
        //
        
        if (pricing.isEmpty())
            return;
        
        //
        // query SFDC for the line items
        //
        
        List<OpportunityLineItem> lineItems = [
            SELECT Id
                 , UnitPrice 
              FROM OpportunityLineItem 
             WHERE Id 
                IN :pricing.keySet() 
        ];
        
        //
        // were any line items returned from SFDC?
        //
        
        if (lineItems.isEmpty())
            return;
            
        //
        // update the line items with the new pricing
        // 
        
        for (OpportunityLineItem lineItem : lineItems) {
            lineItem.UnitPrice = decimal.valueOf( pricing.get(lineItem.Id) );   
        }
        
        update lineItems;
    }
    
    
    /**
     * utility method for replacing null values with an empty string
     *
     * isNull
     * @param String
     * @return String
     */
     
    private String isNull(String value) {
        return (value == null) ? '' : value;        
    }
    
    
    /**
     * utility method for replacing US with United States
     * In SFDC the country is US, the pricing service wants United States.
     * SFDC is being updated to fix this issue
     *
     * isCountryUS
     * @param String
     * @return String
     */
     
    private String isCountryUS(String value) {
        if (value == null)
            return '';
            
        return (value.equalsIgnoreCase('US') ? 'United States' : value);
    }
    
    
    /**
     * utility method for converting Apex dates
     * to xs:date
     *
     * @param String
     * @return String
     */
    
    private String date2XsDate(Date d) {
        if (d == null)
            return '';
        
        Time t = Time.newInstance(0, 0, 0, 0);  
        DateTime dt = DateTime.newInstance(d, t);
        
        return dt.format('yyyy-MM-dd\'T\'HH:mm:ss');
    }
    
    
    /**
     * value object for holding the results of 
     * pricing web service call 
     */
     
    public class Result {
        public String opportunityLineItemId { get; set; }
        public String lineItemStatusCode { get; set; }
        public String lineItemStatusMsg { get; set; }
        public Decimal unitPrice { get; set; }
        public String unitPriceNew { get; set; }
        public String unitListPrice { get; set; }
        public list<Discount> discount { get; set; }
    }
    
    public class Discount {
        public String description { get; set; }
        public String code { get; set; }
        public String value { get; set; }
    }
    
    /**
     * TODO: refactor along with getProductInfo method
     * value object for holding the results of
     * getProductInfo call
     */
     
    public class ProductResult {
        public String baseSKU { get; set; }
        public String attributes { get; set; }
        public String description { get; set; }
        public String statusCode { get; set; }
        public String statusMsg { get; set; }
    }
    
    public class PricingServiceException extends Exception{}
}