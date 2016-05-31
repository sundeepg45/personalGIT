/*****************************************************************************************
    Name    : Order_Inbound_Service_Test
    Desc    : This class defines the logic for test class for Order_Inbound_Service class        
                            
Modification Log : 
---------------------------------------------------------------------------
Developer              Date            Description
---------------------------------------------------------------------------
Pankaj Banik        12 June 2014          Created
******************************************************************************************/

@isTest
public class Order_Inbound_Service_Test
{
    // Test for Direct Opportunities with Entered Status
    static testMethod void DirectEnteredOpportunities()
    {
        // Calling Utility class for Data creation
        OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
        
        // Creating Product
        Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
        insert product;
        System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
        
        //Creating Sales Account
        Account account = data.getAccount() ;
        insert account ;
        System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
        
        //Creating opportunity
        Opportunity opportunity = data.getOpportunity(account) ;
        insert opportunity ;
        System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
        
        //Creating Order information message
        IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
        
        ioOrder.orderSource = 'SFDC_Sales';
        ioOrder.OrderStatus = 'ENTERED';
        
        Order_Inbound_Service inboundService = new Order_Inbound_Service();
        
        //Start test
        test.StartTest();
        system.debug('--->method called-->'+ioOrder);
        inboundService.OpportunityStagingSync(ioOrder);
        list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
        system.assertNotEquals(oHS.size(),0);
        list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
        system.assertNotEquals(oLS.size(),0);
        list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
        system.assertNotEquals(oPS.size(),0);
        
        list<Opportunity> opportunities = [Select Order_Status__c , OracleOrderNumber__c,OracleOrderID__c from opportunity where id =:opportunity.id];
        System.AssertNotEquals(0,opportunities.size());
        //System.AssertEquals('Entered',opportunities[0].Order_Status__c);
        //System.AssertEquals(ioOrder.orderNumber,opportunities[0].OracleOrderNumber__c);
        //System.AssertEquals(ioOrder.orderId,opportunities[0].OracleOrderID__c);
        test.StopTest();
    } 
    
    // Test for Direct Opportunities with Closed Status
    static testMethod void DirectClosedOpportunities()
    {
        // Calling Utility class for Data creation
        OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
        
        // Creating Product
        Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
        insert product;
        System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
        
        // Creating Sales Account
        Account account = data.getAccount() ;
        insert account ;
        System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
        
        // Creating Opportunity
        Opportunity opportunity = data.getOpportunity(account) ;
        insert opportunity ;
        System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
        
        // Creating Order Information
        IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
        
        ioOrder.orderSource = 'SFDC_Sales';
        ioOrder.OrderStatus = 'CLOSED';
        
        Order_Inbound_Service inboundService = new Order_Inbound_Service();
        
        test.StartTest();
        inboundService.OpportunityStagingSync(ioOrder);
        list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
        system.assertNotEquals(oHS.size(),0);
        list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
        system.assertNotEquals(oLS.size(),0);
        list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
        system.assertNotEquals(oPS.size(),0);
        
        list<Opportunity> opportunities = [Select Order_Status__c , OracleOrderNumber__c,OracleOrderID__c from opportunity where id =:opportunity.id ];
        System.AssertNotEquals(0,opportunities.size());
        //System.AssertEquals('Closed',opportunities[0].Order_Status__c);
        test.StopTest();
    }   
    
    // Test for Direct Opportunities with Invoiced Status
    static testMethod void DirectInvoicedOpportunities()
    {
        // Calling Utility class for Data creation
        OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
        
        // Creating Product
        Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
        insert product;
        System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
        
        // Creating Sales Account
        Account account = data.getAccount() ;
        insert account ;
        System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
        
        // Creating Opportunity
        Opportunity opportunity = data.getOpportunity(account) ;
        insert opportunity ;
        System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
        
        // Creating Order Information
        IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
        
        ioOrder.orderSource = 'SFDC_Sales';
        ioOrder.OrderStatus = 'INVOICED';
        
        Order_Inbound_Service inboundService = new Order_Inbound_Service();
        
        test.StartTest();
        inboundService.OpportunityStagingSync(ioOrder);
        list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
        system.assertNotEquals(oHS.size(),0);
        list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
        system.assertNotEquals(oLS.size(),0);
        list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
        system.assertNotEquals(oPS.size(),0);
        
        list<Opportunity> opportunities = [Select Order_Status__c , OracleOrderNumber__c,OracleOrderID__c from opportunity where id =:opportunity.id ];
        System.AssertNotEquals(0,opportunities.size());
        //System.AssertEquals('Invoiced',opportunities[0].Order_Status__c);
        test.StopTest();
    }
    
    // Test for Direct Opportunities with Cancelled Status
    static testMethod void DirectCancelledOpportunities()
    {
        // Calling Utility class for Data creation    
        OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
        
        // Creating Product
        Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
        insert product;
        System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
        
        // Creating Sales Account
        Account account = data.getAccount() ;
        insert account ;
        System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
        
        // Creating Opportunity
        Opportunity opportunity = data.getOpportunity(account) ;
        insert opportunity ;
        System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
        
        // Creating Order Information
        IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
        
        ioOrder.orderSource = 'SFDC_Sales';
        ioOrder.OrderStatus = 'CANCELLED';
        
        Order_Inbound_Service inboundService = new Order_Inbound_Service();
        
        test.StartTest();
        inboundService.OpportunityStagingSync(ioOrder);
        list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
        system.assertNotEquals(oHS.size(),0);
        list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
        system.assertNotEquals(oLS.size(),0);
        list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
        system.assertNotEquals(oPS.size(),0);
        
        list<Opportunity> opportunities = [Select Order_Status__c , OracleOrderNumber__c,OracleOrderID__c from opportunity where id =:opportunity.id];
        System.AssertNotEquals(0,opportunities.size());
        //System.AssertEquals('Cancelled',opportunities[0].Order_Status__c);
        test.StopTest();
    }
    
    // Test for Direct Opportunities with Booked Status
    static testMethod void DirectBookedOpportunities()
    {
        // Calling Utility class for Data creation
        OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
        
        // Creating Product
        Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
        insert product;
        System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
        
        // Creating Sales Account
        Account account = data.getAccount() ;
        insert account ;
        System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
        
        // Creating Opportunity
        Opportunity opportunity = data.getOpportunity(account) ;
        insert opportunity ;
        System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
        
        // Creating Order Information
        IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
        
        ioOrder.orderSource = 'SFDC_Sales';
        ioOrder.OrderStatus = 'BOOKED';
        
        
        Order_Inbound_Service inboundService = new Order_Inbound_Service();
        
        test.StartTest();
        inboundService.OpportunityStagingSync(ioOrder);
        list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
        system.assertNotEquals(oHS.size(),0);
        list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
        system.assertNotEquals(oLS.size(),0);
        list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
        system.assertNotEquals(oPS.size(),0);
        
        
        test.StopTest();
    }
    
    // Test for Indirect Opportunities with Booked Status
    static testMethod void InDirectBookedOpportunities()
    {
        // Calling Utility class for Data creation
        OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
        
        // Creating Product
        Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
        insert product;
        System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
        
        // Creating Sales Account
        Account account = data.getAccount() ;
        insert account ;
        System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
        
        // Creating opportunity
        Opportunity opportunity = data.getOpportunity(account) ;
        insert opportunity ;
        System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
        
        // Creating Order Information
        IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
        
        ioOrder.orderSource = 'WEB';
        ioOrder.OrderStatus = 'BOOKED';
        
        Order_Inbound_Service inboundService = new Order_Inbound_Service();
        
        test.StartTest();
        inboundService.OpportunityStagingSync(ioOrder);
        list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
        system.assertNotEquals(oHS.size(),0);
        list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
        system.assertNotEquals(oLS.size(),0);
        list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
        system.assertNotEquals(oPS.size(),0);
        test.StopTest();
    }
    
    static testMethod void InDirectOpportunitiesNullOpp()
    {
        try 
        {
            // Calling Utility class for Data creation
            OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
            
            // Creating Product
            Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
            insert product;
            System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
            
            // Creating Sales Account
            Account account = data.getAccount() ;
            insert account ;
            System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
            
            // Creating opportunity
            Opportunity opportunity = data.getOpportunity(account) ;
            insert opportunity ;
            System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
            
            // Creating Order Information
            IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
            
            ioOrder.orderNumber = null ;
            ioOrder.orderId  = null ;
            ioOrder.orderSource = 'WEB';
            ioOrder.OrderStatus = 'ENTERED';
            
            Order_Inbound_Service inboundService = new Order_Inbound_Service();
            
            test.StartTest();
            inboundService.OpportunityStagingSync(ioOrder);
            list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
            system.assertNotEquals(oHS.size(),0);
            list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
            system.assertNotEquals(oLS.size(),0);
            list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
            system.assertNotEquals(oPS.size(),0);
            test.StopTest();
        }
        catch (Exception e)
        {
            system.assertEquals(true, e.getmessage().contains('Opportunity record was not found.'));
        }       
    }
    
    static testMethod void DirectOpportunitiesNullOpp()
    {
        try
        {
            // Calling Utility class for Data creation
            OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
            
            // Creating Product
            Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
            insert product;
            System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
            
            // Creating Sales Account
            Account account = data.getAccount() ;
            insert account ;
            System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
            
            // Creating opportunity
            Opportunity opportunity = data.getOpportunity(account) ;
            insert opportunity ;
            System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
            
            // Creating Order Information
            IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
            
            ioOrder.opportunityId  = null ;
            ioOrder.opportunityNumber  = null ;
            ioOrder.orderSource = 'SFDC_Sales';
            ioOrder.OrderStatus = 'ENTERED';
            
            Order_Inbound_Service inboundService = new Order_Inbound_Service();
            
            test.StartTest();
            inboundService.OpportunityStagingSync(ioOrder);
            list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
            system.assertNotEquals(oHS.size(),0);
            list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
            system.assertNotEquals(oLS.size(),0);
            list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
            system.assertNotEquals(oPS.size(),0);
            test.StopTest();
        }
        catch (Exception e)
        {
            system.assertEquals(true, e.getmessage().contains('Opportunity record was not found.'));
        }       
    }
    
    static testMethod void NullOrderStatus()
    {
        try
        {
            // Calling Utility class for Data creation
            OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
            
            // Creating Product
            Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
            insert product;
            System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
            
            // Creating Sales Account
            Account account = data.getAccount() ;
            insert account ;
            System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
            
            // Creating opportunity
            Opportunity opportunity = data.getOpportunity(account) ;
            insert opportunity ;
            System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
            
            // Creating Order Information
            IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
            
            //ioOrder.opportunityId  = null ;
            //ioOrder.opportunityNumber  = null ;
            ioOrder.orderSource = 'SFDC_Sales';
            ioOrder.OrderStatus = null;
            
            Order_Inbound_Service inboundService = new Order_Inbound_Service();
            
            test.StartTest();
            inboundService.OpportunityStagingSync(ioOrder);
            list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
            system.assertNotEquals(oHS.size(),0);
            list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
            system.assertNotEquals(oLS.size(),0);
            list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
            system.assertNotEquals(oPS.size(),0);
            test.StopTest();
        }
        catch (Exception e)
        {
            system.assertEquals(true, e.getmessage().contains('Order Status cannot be null.'));
        }       
    }
    
    static testMethod void DirectOpportunitiesNullOrderDetail()
    {
        try
        {
            // Calling Utility class for Data creation
            OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
            
            // Creating Product
            Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
            insert product;
            System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
            
            // Creating Sales Account
            Account account = data.getAccount() ;
            insert account ;
            System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
            
            // Creating opportunity
            Opportunity opportunity = data.getOpportunity(account) ;
            insert opportunity ;
            System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
            
            // Creating Order Information
            IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
            
            ioOrder.orderNumber = null ;
            ioOrder.orderId  = null ;
            ioOrder.orderSource = 'SFDC_Sales';
            ioOrder.OrderStatus = 'ENTERED';
            
            Order_Inbound_Service inboundService = new Order_Inbound_Service();
            
            test.StartTest();
            inboundService.OpportunityStagingSync(ioOrder);
            list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
            system.assertNotEquals(oHS.size(),0);
            list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
            system.assertNotEquals(oLS.size(),0);
            list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
            system.assertNotEquals(oPS.size(),0);
            test.StopTest();
        }
        catch (Exception e)
        {
            system.assertEquals(true, e.getmessage().contains('Oracle Order Number or Oracle Order Id cannot be null.'));
        }       
    }
    
    static testMethod void IndirectOpportunitiesNullOrderDetail()
    {
        try
        {
            // Calling Utility class for Data creation
            OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
            
            // Creating Product
            Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
            insert product;
            System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
            
            // Creating Sales Account
            Account account = data.getAccount() ;
            insert account ;
            System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
            
            // Creating opportunity
            Opportunity opportunity = data.getOpportunity(account) ;
            insert opportunity ;
            System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
            
            // Creating Order Information
            IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
            
            ioOrder.orderNumber = null ;
            ioOrder.orderId  = null ;
            ioOrder.orderSource = 'WEB';
            ioOrder.OrderStatus = 'ENTERED';
            
            Order_Inbound_Service inboundService = new Order_Inbound_Service();
            
            test.StartTest();
            inboundService.OpportunityStagingSync(ioOrder);
            list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
            system.assertNotEquals(oHS.size(),0);
            list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
            system.assertNotEquals(oLS.size(),0);
            list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
            system.assertNotEquals(oPS.size(),0);
            test.StopTest();
        }
        catch (Exception e)
        {
            system.assertEquals(true, e.getmessage().contains('Oracle Order Number or Oracle Order Id cannot be null.'));
        }       
    }
    
    static testMethod void IndirectEnteredOpportunities()
    {
        // Calling Utility class for Data creation
        OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
        
        // Creating Product
        Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
        insert product;
        System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
        
        //Creating Sales Account
        Account account = data.getAccount() ;
        insert account ;
        System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
        
        //Creating opportunity
        Opportunity opportunity = data.getOpportunity(account) ;
        insert opportunity ;
        System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
        
        //Creating Order information message
        IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
        
        ioOrder.orderSource = 'WEB';
        ioOrder.OrderStatus = 'ENTERED';
        
        Order_Inbound_Service inboundService = new Order_Inbound_Service();
        
        //Start test
        test.StartTest();
        inboundService.OpportunityStagingSync(ioOrder);
        list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
        system.assertNotEquals(oHS.size(),0);
        list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
        system.assertNotEquals(oLS.size(),0);
        list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
        system.assertNotEquals(oPS.size(),0);
        
        list<Opportunity> opportunities = [Select Order_Status__c , OracleOrderNumber__c,OracleOrderID__c from opportunity where id =:opportunity.id];
        System.AssertNotEquals(0,opportunities.size());
        //System.AssertEquals('Entered',opportunities[0].Order_Status__c);
        //System.AssertEquals(ioOrder.orderNumber,opportunities[0].OracleOrderNumber__c);
        //System.AssertEquals(ioOrder.orderId,opportunities[0].OracleOrderID__c);
        test.StopTest();
    } 
    
    // Test for Indirect Opportunities with Closed Status
    static testMethod void IndirectClosedOpportunities()
    {
        // Calling Utility class for Data creation
        OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
        
        // Creating Product
        Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
        insert product;
        System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
        
        // Creating Sales Account
        Account account = data.getAccount() ;
        insert account ;
        System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
        
        // Creating Opportunity
        Opportunity opportunity = data.getOpportunity(account) ;
        insert opportunity ;
        System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
        
        // Creating Order Information
        IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
        
        ioOrder.orderSource = 'WEB';
        ioOrder.OrderStatus = 'CLOSED';
        
        Order_Inbound_Service inboundService = new Order_Inbound_Service();
        
        test.StartTest();
        inboundService.OpportunityStagingSync(ioOrder);
        list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
        system.assertNotEquals(oHS.size(),0);
        list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
        system.assertNotEquals(oLS.size(),0);
        list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
        system.assertNotEquals(oPS.size(),0);
        
        list<Opportunity> opportunities = [Select Order_Status__c , OracleOrderNumber__c,OracleOrderID__c from opportunity where id =:opportunity.id ];
        System.AssertNotEquals(0,opportunities.size());
        //System.AssertEquals('Closed',opportunities[0].Order_Status__c);
        test.StopTest();
    }   
    
    // Test for Indirect Opportunities with Invoiced Status
    static testMethod void IndirectInvoicedOpportunities()
    {
        // Calling Utility class for Data creation
        OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
        
        // Creating Product
        Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
        insert product;
        System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
        
        // Creating Sales Account
        Account account = data.getAccount() ;
        insert account ;
        System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
        
        // Creating Opportunity
        Opportunity opportunity = data.getOpportunity(account) ;
        insert opportunity ;
        System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
        
        // Creating Order Information
        IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
        
        ioOrder.orderSource = 'WEB';
        ioOrder.OrderStatus = 'INVOICED';
        
        Order_Inbound_Service inboundService = new Order_Inbound_Service();
        
        test.StartTest();
        inboundService.OpportunityStagingSync(ioOrder);
        list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
        system.assertNotEquals(oHS.size(),0);
        list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
        system.assertNotEquals(oLS.size(),0);
        list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
        system.assertNotEquals(oPS.size(),0);
        
        list<Opportunity> opportunities = [Select Order_Status__c , OracleOrderNumber__c,OracleOrderID__c from opportunity where id =:opportunity.id ];
        System.AssertNotEquals(0,opportunities.size());
        //System.AssertEquals('Invoiced',opportunities[0].Order_Status__c);
        test.StopTest();
    }
    
    // Test for Indirect Opportunities with Cancelled Status
    static testMethod void IndirectCancelledOpportunities()
    {
        // Calling Utility class for Data creation    
        OrderInboundServiceTestUtil data = new OrderInboundServiceTestUtil () ;
        
        // Creating Product
        Product2 product = new Product2 (Name = 'PROD', CurrencyIsoCode = 'USD', isActive = true,ProductCode = 'PRODTEST') ;
        insert product;
        System.AssertNotEquals(null,[Select id from Product2 where id = : product.id]);
        
        // Creating Sales Account
        Account account = data.getAccount() ;
        insert account ;
        System.AssertNotEquals(null,[Select id from Account where id = : account.id]);
        
        // Creating Opportunity
        Opportunity opportunity = data.getOpportunity(account) ;
        insert opportunity ;
        System.AssertNotEquals(null,[Select id from Opportunity where id = : opportunity.id]);
        
        // Creating Order Information
        IntegrationObjects.Order  ioOrder = data.Order(opportunity,product);
        
        ioOrder.orderSource = 'WEB';
        ioOrder.OrderStatus = 'CANCELLED';
        
        Order_Inbound_Service inboundService = new Order_Inbound_Service();
        
        test.StartTest();
        inboundService.OpportunityStagingSync(ioOrder);
        list<Opportunity_Header_Staging__c> oHS=[select id,Name from Opportunity_Header_Staging__c];
        system.assertNotEquals(oHS.size(),0);
        list<Opportunity_line_Staging__c> oLS=[select id,Name from Opportunity_Line_Staging__c];
        system.assertNotEquals(oLS.size(),0);
        list<Opportunity_partner_Staging__c> oPS=[select id,Name from Opportunity_partner_Staging__c];
        system.assertNotEquals(oPS.size(),0);
        
        list<Opportunity> opportunities = [Select Order_Status__c , OracleOrderNumber__c,OracleOrderID__c from opportunity where id =:opportunity.id];
        System.AssertNotEquals(0,opportunities.size());
        //System.AssertEquals('Cancelled',opportunities[0].Order_Status__c);
        test.StopTest();
    }
}