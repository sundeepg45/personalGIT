@isTest

public class Product_CreateUpdate_Test{
    
    public static testMethod void testProduct_CreateUpdate(){
        
        Profile standard = [SELECT Id FROM Profile WHERE Name LIKE '%Direct Sales User%' LIMIT 1]; 
        Profile admin = [SELECT Id FROM Profile WHERE Name='Administrator - Level 1'];

        User standardUser = new User(Alias = 'standt', Email='stcTestStandardUser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = standard.Id, 
          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestStandardUser@testorg.com');
        insert standardUser;
        
        User adminUser = new User(Alias = 'admint', Email='stcTestAdminUser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = admin.Id, 
          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestAdminUser@testorg.com');
        insert adminUser;
        
        
        system.runAs(adminUser){
            
            Pricebook2 pb = new Pricebook2(Name='Global Price Book');
            insert pb;
            
          //create Product2 record  
            Product2 prod = new Product2(
                                            Name='testProduct',
                                            ProductCode = 'TC',
                                            IsActive = TRUE,
                                            Primary_BU__c = 10,
                                            Secondary_BU__c = 10,
                                            Tertiary__c = 10,
                                            Quaternary_BU__c = 10,
                                            Quinary_BU__c = 10);
            insert prod;
            
            
            PriceBookEntry pbe = new PriceBookEntry(
                                                        IsActive = TRUE,
                                                        Pricebook2Id = Test.getStandardPricebookId(),
                                                        Product2Id = prod.Id,
                                                        UnitPrice = 100,
                                                        UseStandardPrice = FALSE);
                                                        
            insert pbe;
            
            pbe = new PriceBookEntry(
                                                        IsActive = TRUE,
                                                        Pricebook2Id = pb.Id,
                                                        Product2Id = prod.Id,
                                                        UnitPrice = 100,
                                                        UseStandardPrice = TRUE);
                                                        
            insert pbe;
            
          //create IntegrationObjects.Product instance (to test Create scenario)  
            list<IntegrationObjects.Product> listParsedProduct = new list<IntegrationObjects.Product>();
            IntegrationObjects.Product productInst = new IntegrationObjects.Product();
            productInst.ProductCategory = 'test';
            productInst.ProductLine = 'test';
            productInst.Name = 'test';
            productInst.Description = 'test';
            productInst.ProductCode = 'test12';
            productInst.UnitOfMeasure = 'test';
            productInst.Term = '1 day';
            productInst.IsActive = TRUE;
            productInst.PrimaryBusinessUnit = 'test';
            productInst.PrimaryBusinessUnitSplit = '12';
            productInst.SecondaryBusinessUnit = 'test';
            productInst.SecondaryBusinessUnitSplit = '12';
            productInst.TertiaryBusinessUnit = 'test';
            productInst.TertiaryBusinessUnitSplit = '12';
            productInst.QuaternaryBusinessUnit = 'test';
            productInst.QuaternaryBusinessUnitSplit = '12';
            productInst.QuinaryBusinessUnit = 'test';
            productInst.QuinaryBusinessUnitSplit = '12';
            productInst.SpecialPricingValue = 'test';
            listParsedProduct.add(productInst);
          
          //create IntegrationObjects.Product instance (to test Update scenario)    
            productInst = new IntegrationObjects.Product();
            productInst.ProductCategory = 'test';
            productInst.ProductLine = 'test';
            productInst.Name = 'test';
            productInst.Description = 'test';
            productInst.ProductCode = 'TC';
            productInst.UnitOfMeasure = 'test';
            productInst.Term = '1 year';
            productInst.IsActive = TRUE;
            productInst.PrimaryBusinessUnit = 'test';
            productInst.PrimaryBusinessUnitSplit = '12';
            productInst.SecondaryBusinessUnit = 'test';
            productInst.SecondaryBusinessUnitSplit = '12';
            productInst.TertiaryBusinessUnit = 'test';
            productInst.TertiaryBusinessUnitSplit = '12';
            productInst.QuaternaryBusinessUnit = 'test';
            productInst.QuaternaryBusinessUnitSplit = '12';
            productInst.QuinaryBusinessUnit = 'test';
            productInst.QuinaryBusinessUnitSplit = '12';
            productInst.SpecialPricingValue = 'test';
            listParsedProduct.add(productInst);
          //negative scenario for Term 
            productInst = new IntegrationObjects.Product();
            productInst.ProductCategory = 'test';
            productInst.ProductLine = 'test';
            productInst.Name = 'test';
            productInst.Description = 'test';
            productInst.ProductCode = 'TC123';
            productInst.UnitOfMeasure = 'test';
            productInst.Term = '1 y2ear';
            productInst.IsActive = TRUE;
            productInst.PrimaryBusinessUnit = 'test';
            productInst.PrimaryBusinessUnitSplit = '12';
            productInst.SecondaryBusinessUnit = 'test';
            productInst.SecondaryBusinessUnitSplit = '12';
            productInst.TertiaryBusinessUnit = 'test';
            productInst.TertiaryBusinessUnitSplit = '12';
            productInst.QuaternaryBusinessUnit = 'test';
            productInst.QuaternaryBusinessUnitSplit = '12';
            productInst.QuinaryBusinessUnit = 'test';
            productInst.QuinaryBusinessUnitSplit = '12';
            productInst.SpecialPricingValue = 'test';
            listParsedProduct.add(productInst);
          //negative scenario for Term   
            productInst = new IntegrationObjects.Product();
            productInst.ProductCategory = 'test';
            productInst.ProductLine = 'test';
            productInst.Name = 'test';
            productInst.Description = 'test';
            productInst.ProductCode = 'TC12';
            productInst.UnitOfMeasure = 'test';
            productInst.Term = '13e year';
            productInst.IsActive = TRUE;
            productInst.PrimaryBusinessUnit = 'test';
            productInst.PrimaryBusinessUnitSplit = '12';
            productInst.SecondaryBusinessUnit = 'test';
            productInst.SecondaryBusinessUnitSplit = '12';
            productInst.TertiaryBusinessUnit = 'test';
            productInst.TertiaryBusinessUnitSplit = '12';
            productInst.QuaternaryBusinessUnit = 'test';
            productInst.QuaternaryBusinessUnitSplit = '12';
            productInst.QuinaryBusinessUnit = 'test';
            productInst.QuinaryBusinessUnitSplit = '12';
            productInst.SpecialPricingValue = 'test';
            listParsedProduct.add(productInst);
          //negative scenario for Term   
            productInst = new IntegrationObjects.Product();
            productInst.ProductCategory = 'test';
            productInst.ProductLine = 'test';
            productInst.Name = 'test';
            productInst.Description = 'test';
            productInst.ProductCode = 'TC321';
            productInst.UnitOfMeasure = 'test';
            productInst.Term = '1year';
            productInst.IsActive = TRUE;
            productInst.PrimaryBusinessUnit = 'test';
            productInst.PrimaryBusinessUnitSplit = '12';
            productInst.SecondaryBusinessUnit = 'test';
            productInst.SecondaryBusinessUnitSplit = '12';
            productInst.TertiaryBusinessUnit = 'test';
            productInst.TertiaryBusinessUnitSplit = '12';
            productInst.QuaternaryBusinessUnit = 'test';
            productInst.QuaternaryBusinessUnitSplit = '12';
            productInst.QuinaryBusinessUnit = 'test';
            productInst.QuinaryBusinessUnitSplit = '12';
            productInst.SpecialPricingValue = 'test';
            listParsedProduct.add(productInst);
            
            Product_CreateUpdate p = new Product_CreateUpdate();
            p.createUpdateProducts(listParsedProduct);
            
            system.assertEquals([SELECT Id FROM Product2 WHERE ProductCode = 'test12'].size(), 1);
            
        }
    
    }
}