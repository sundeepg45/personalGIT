/**
 * This class contains the logic to create/update products recieved from Product Proxy
 * and make Pricebook entries for newly created Products
 *
 * @version 2014-10-21
 * @author Anshul Kumar <ankumar@redhat.com>
 * 2014-10-21 - Created
 */
public with sharing class Product_CreateUpdate{
    
    /**
     * Start method impl for Database.Batchable interface.
     *
     * @param   listParsedProduct list<IntegrationObjects.Product>
     * @return  list<String> collection of error messages
     *
     */
    public list<string> createUpdateProducts(list<IntegrationObjects.Product> listParsedProduct){
        
        set<string> setProductCode = new set<string>();
        map<string, list<Product2>> mapProductCode_Product = new map<string, list<Product2>>();
        list<String> errDet = new list<String>();
        
       //collect all the ProductCodes to fetch Products stored in SFDC 
        for(IntegrationObjects.Product productInst : listParsedProduct){
        
            setProductCode.add(productInst.ProductCode);
        }
        
        list<PricebookEntry> listPricebookEntry = new list<PricebookEntry>([SELECT Product2.Id 
                                                                            FROM PricebookEntry 
                                                                            WHERE Product2.ProductCode IN: setProductCode 
                                                                            AND Pricebook2.Name = 'Global Price Book'
                                                                            ]);
        
        set<Id> setProductIds = new set<Id>();
        
        for(PricebookEntry pbeInst : listPricebookEntry)
            setProductIds.add(pbeInst.Product2.Id);
        
        list<Product2> listSFDCProduct = new list<Product2>([SELECT Family, Product_Line__c, Name, Description,
                                                            ProductCode, Unit_Of_Measure__c, Term__c, IsActive,
                                                            Primary_Business_Unit__c, Primary_BU__c, Secondary_Business_Unit__c,
                                                            Secondary_BU__c, Tertiary_Business_Unit__c, Tertiary__c,
                                                            Quaternary_Business_Unit__c, Quaternary_BU__c, Quinary_Business_Unit__c,
                                                            Quinary_BU__c, Special_Pricing_Value__c 
                                                            FROM Product2 
                                                            WHERE ProductCode IN: setProductCode
                                                            AND Id IN: setProductIds
                                                            ]);
       //Create a map of ProductCode and Product instance                                                     
        for(Product2 prodInst : listSFDCProduct){
            
            if(!mapProductCode_Product.containsKey(prodInst.ProductCode))
                mapProductCode_Product.put(prodInst.ProductCode, new list<Product2>());
            if(mapProductCode_Product.containsKey(prodInst.ProductCode))
                mapProductCode_Product.get(prodInst.ProductCode).add(prodInst);
        }
        
        listSFDCProduct = new list<Product2>();
        list<Product2> listTempProduct;
        
       //Create or Update products 
        for(IntegrationObjects.Product productInst : listParsedProduct){
            
            listTempProduct = new list<Product2>();
            if(mapProductCode_Product.get(productInst.ProductCode) != NULL)
                listTempProduct.addAll(mapProductCode_Product.get(productInst.ProductCode));
            if(listTempProduct.isEmpty())
                listTempProduct.add(new Product2());
            for(Product2 product : listTempProduct){
              //logic to calculate Term recieved in Year/year/Day/Days/Month  
                if(productInst.Term != null){
                    
                    list<string> termChunks = new list<string>();
                    termChunks.addAll(productInst.Term.trim().split(' ',0));
                    decimal convertedDays = 0;
                    if(termChunks.size() == 2){
                        
                        if(string.isNotEmpty(termChunks[1])){
                            
                            if(!termChunks[1].containsIgnoreCase('year') && !termChunks[1].containsIgnoreCase('day') && !termChunks[1].containsIgnoreCase('month')) {
                                errDet.add('Exception in converting Term: "'+ productInst.Term + '" for ProductCode: "' + productInst.ProductCode +'"');
                                continue;
                            }
                            
                            if(string.isEmpty(termChunks[0]) || !termChunks[0].trim().isNumeric()){
                                errDet.add('Exception in converting Term: "'+ productInst.Term + '" for ProductCode: "' + productInst.ProductCode +'"');
                                continue;
                            }
                            
                            if(termChunks[1].containsIgnoreCase('year'))
                                convertedDays = decimal.valueOf(termChunks[0].trim()) * 365;
                            
                            if(termChunks[1].containsIgnoreCase('day'))
                                convertedDays = decimal.valueOf(termChunks[0].trim());
                            
                            
                            if(termChunks[1].containsIgnoreCase('month'))
                                convertedDays = decimal.valueOf(termChunks[0].trim()) * 30;
                            
                        }
                        product.Term__c             = convertedDays;
                    } else {
                        errDet.add('Exception in converting Term: "'+ productInst.Term + '" for ProductCode: "' + productInst.ProductCode +'"');
                        continue;
                    }
                    
                }
                product.Family                      = productInst.ProductCategory;
                product.Product_Line__c             = productInst.ProductLine;
                product.Name                        = productInst.Name;
                product.Description                 = productInst.Description;
                product.ProductCode                 = productInst.ProductCode;
                
                if(productInst.Attribute != null){
                    if(productInst.Attribute.keyset().contains('SFDC_PRODUCT_UNIT_OF_MEASURE')){
                        product.Unit_Of_Measure__c  = productInst.Attribute.get('SFDC_PRODUCT_UNIT_OF_MEASURE');
                    }
                    
                    if(productInst.Attribute.keyset().contains('PRODUCT_GROUP')){
                        product.Product_Group__c    = productInst.Attribute.get('PRODUCT_GROUP');
                    }
                }
                  
                product.IsActive                    = productInst.IsActive;
                product.Primary_Business_Unit__c    = productInst.PrimaryBusinessUnit;
                
                if(productInst.PrimaryBusinessUnitSplit != null)
                    product.Primary_BU__c           = Decimal.valueOf(productInst.PrimaryBusinessUnitSplit); 
                
                product.Secondary_Business_Unit__c  = productInst.SecondaryBusinessUnit;
                
                if(productInst.SecondaryBusinessUnitSplit != null)
                    product.Secondary_BU__c         = Decimal.valueOf(productInst.SecondaryBusinessUnitSplit);
                    
                product.Tertiary_Business_Unit__c   = productInst.TertiaryBusinessUnit;
                
                if(productInst.TertiaryBusinessUnitSplit != null)
                    product.Tertiary__c             = Decimal.valueOf(productInst.TertiaryBusinessUnitSplit);
                    
                product.Quaternary_Business_Unit__c = productInst.QuaternaryBusinessUnit;
                
                if(productInst.QuaternaryBusinessUnitSplit != null)
                    product.Quaternary_BU__c        = Decimal.valueOf(productInst.QuaternaryBusinessUnitSplit);
                    
                product.Quinary_Business_Unit__c    = productInst.QuinaryBusinessUnit;
                
                if(productInst.QuinaryBusinessUnitSplit != null)
                    product.Quinary_BU__c           = Decimal.valueOf(productInst.QuinaryBusinessUnitSplit);
                    
                product.Special_Pricing_Value__c    = productInst.SpecialPricingValue;
                
                listSFDCProduct.add(product);
            }
            
        }
       //upsert all the recieved products 
        list<Database.UpsertResult> productUpsertRes = Database.Upsert(listSFDCProduct, FALSE);
        
        Id standardPricebookId;
        Id globalPricebookId;
       
       //fetch the Standard Pricebook Id and Global Price Book Id 
        if(!Test.isRunningTest()){
            standardPricebookId = [SELECT Id FROM Pricebook2 WHERE isStandard = TRUE LIMIT 1].Id;
            globalPricebookId = [SELECT Id FROM Pricebook2 WHERE Name = 'Global Price Book' LIMIT 1].Id;
        }else{
            standardPriceBookId = globalPricebookId = Test.getStandardPricebookId();
        }
       
       //fetch all the active Currencies in Org 
        list<CurrencyType> listCurrency = new list<CurrencyType>([SELECT IsoCode
                                                                FROM CurrencyType
                                                                WHERE IsActive = TRUE
                                                                ]);
        
        list<PricebookEntry> listPBEntries = new list<PricebookEntry>();
        PricebookEntry PBInst;
        
       //Create Pricebook entries of the newly created products 
        for(Database.UpsertResult result : productUpsertRes){
            if(result.isCreated()){
                for(CurrencyType currInst : listCurrency){
                    PBInst = new PricebookEntry(
                                                IsActive = TRUE,
                                                Pricebook2Id = standardPricebookId,
                                                Product2Id = result.getId(),
                                                UnitPrice = 0,
                                                UseStandardPrice = FALSE,
                                                CurrencyIsoCode = currInst.IsoCode);
                    listPBEntries.add(PBInst);
                    
                    PBInst = new PricebookEntry(
                                                IsActive = TRUE,
                                                Pricebook2Id = globalPricebookId,
                                                Product2Id = result.getId(),
                                                UnitPrice = 0,
                                                UseStandardPrice = TRUE,
                                                CurrencyIsoCode = currInst.IsoCode);
                    listPBEntries.add(PBInst);
                }
            }
        }
        
       //Insert all the Pricebook entries 
        list<Database.SaveResult> insertPBERes = Database.insert(listPBEntries, FALSE);
        
        
        
       //populate return list of errors 
        for(Database.UpsertResult result : productUpsertRes){
            for(Database.Error err : result.getErrors())
                errDet.add(err.getMessage());
        }
        
        for(Database.SaveResult result : insertPBERes){
            for(Database.Error err : result.getErrors())
                errDet.add(err.getMessage());
        }
        
        return errDet;
    }
    
}