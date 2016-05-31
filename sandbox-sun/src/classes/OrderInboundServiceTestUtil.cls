/*****************************************************************************************
    Name    : OrderInboundServiceTestUtil
    Desc    : This class defines the logic for  creating Data for test class for Order Inbound Service          
                            
Modification Log : 
---------------------------------------------------------------------------
Developer              Date            Description
---------------------------------------------------------------------------
Pankaj Banik        1st AUG 2014          Created
******************************************************************************************/

public class OrderInboundServiceTestUtil
{
    // Create OrderLine IntegrationObject Domain Object
    public IntegrationObjects.OrderLine getOrderLine (Product2 product)
    {
        IntegrationObjects.OrderLine  line = new IntegrationObjects.OrderLine();
        line.listPrice = 66767;  
        line.actualEndDate = System.today();
        line.actualStartDate = System.today();
        line.contractNumbers = 'hgyjgygyu';
        line.installBaseNumber = 'yuysjhjhs';
        line.quantity = 123;
        line.unitOfMeasure = 'hshjh';
        line.salesPrice = 7777;
        line.entitleToAccount = getEbsaccount() ;
        line.entitleToaddress = getAddress() ;
        line.entitleTocontact = getContact();
        line.productCode = product.ProductCode;
        
        return line;
    }
    
    // Create OrderPartner IntegrationObject Domain object
    public IntegrationObjects.OrderPartner getOrderPartner ()
    {
        IntegrationObjects.OrderPartner  partner = new IntegrationObjects.OrderPartner();
        partner.account = getSalesAccount() ; 
        partner.partnerType = 'Financial';
        partner.partnerTier = 'Reseller' ;
        partner.transactionRole = 'Financial' ;
        partner.contact = getContact() ;
        return partner ;
    }
    
        // Create Order IntegrationObject Domain object
    public IntegrationObjects.Order Order(Opportunity opportunity, Product2 product)
    {
            IntegrationObjects.Contact  contact = getContact();
            IntegrationObjects.Address address = getAddress ();
            IntegrationObjects.TransactionalAccount ebsaccount = getEBSAccount () ;
            
            
            IntegrationObjects.Order ioOrder = new IntegrationObjects.Order ();
            ioOrder.orderId = '1223'  ;
            ioOrder.orderNumber =  '1234';
            ioOrder.employeeNumber = '555543' ;
            ioOrder.opportunityNumber = opportunity.OpportunityNumber__c ;
            ioOrder.opportunityId = opportunity.Id;
            ioOrder.purchaseOrderNumber = '8837873' ;
            ioOrder.orderType = 'Standard - AR' ;
            ioOrder.operatingUnit = '89' ;
            ioOrder.paymentType =  '';
            ioOrder.fulfillmentChannel = 'Eval' ;
            ioOrder.currencyIsoCode = 'USD' ;
            //ioOrder.orderSource = orderSource ;
            //ioOrder.orderStatus = orderStatus ;
            ioOrder.orderedDate = System.Today() ;
            ioOrder.lastUpdateDate = System.Today() ;
            ioOrder.Amount =  122211;

            ioOrder.soldToAccount = ebsaccount ;
            ioOrder.billToAccount = ebsaccount ;
            ioOrder.entitleToAccount = ebsaccount ;
            ioOrder.shipToAccount = ebsaccount ;

            ioOrder.billToaddress = address ;
            ioOrder.shipToaddress = address ;
            ioOrder.soldToaddress = address ;
            ioOrder.entitleToaddress = address ;

            ioOrder.billTocontact =  contact;
            ioOrder.shipTocontact =  contact;
            ioOrder.soldTocontact = contact ;
            ioOrder.entitleTocontact = contact ;

            list <IntegrationObjects.OrderLine> lines = new list <IntegrationObjects.OrderLine> () ;
            list <IntegrationObjects.OrderPartner> partners = new list <IntegrationObjects.OrderPartner> ();
            
            IntegrationObjects.OrderLine line = new IntegrationObjects.OrderLine () ;
            line = getOrderLine(product) ;
            lines.add(line);
            lines.add(line);
            lines.add(line);
            lines.add(line);
            
            IntegrationObjects.OrderPartner partner = new IntegrationObjects.OrderPartner () ;
            partner = getOrderPartner () ;
            
            partners.add(partner);
            partners.add(partner);
            partners.add(partner);
            partners.add(partner);

            ioOrder.orderLines = lines;
            ioOrder.orderPartners = partners;
            
            return ioOrder ;
    }
    
    // Create Contact IntegrationObject Domain object
    public IntegrationObjects.Contact getContact ()
    {
        IntegrationObjects.contact contact = new IntegrationObjects.contact () ;
        contact.CDH_Party_Number = '78787878';
        contact.FirstName = 'Pankaj';
        contact.LastName = 'Banik';
        contact.Phone = '888888888';
        contact.Email = 'ebsaccount@jjj.com';
        
        return contact ;
    }
    
    // Create Address  IntegrationObject Domain object
    public IntegrationObjects.Address getAddress()
    {
        IntegrationObjects.address address = new IntegrationObjects.address ( );
        address.CDH_Party_Site_Number = '6767657';
        address.address_Line1 = '111' ;
        address.address_Line2 = '222' ;
        address.address_Line3 = '333' ;
        address.address_Line4 = '4444' ;
        address.City = 'bangalore' ;
        address.State = 'Karnataka';
        address.Country = 'India';
        address.Zip_Postal_Code = '560100';
        
        return address ;
    }
 
    // Create TransactionalAccount IntegrationObject Domain object
    public IntegrationObjects.TransactionalAccount getEBSAccount ()
    {
        IntegrationObjects.TransactionalAccount ebsaccount = new IntegrationObjects.TransactionalAccount();
        ebsaccount.Account_Number = '1234';
        ebsaccount.PartyType = 'ORGANIZATION';
        ebsAccount.EBS_Party_Number = '788778';
        ebsaccount.EBS_Party_Name = 'gvxggs';
        ebsaccount.CDH_Party_Number = 'PARTY123456';
        return ebsaccount;
    }
    
    // Create Account object
    public Account getAccount ()
    {
        string recordtypeid;
        //Create Sales Account
        Account salesAccount = new Account();
        
        //Fetch account record type
        recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
        salesAccount.Name = 'Test Sales Account1';
        salesAccount.CurrencyIsoCode = 'USD';
        salesAccount.RecordTypeId = recordTypeId;
        
        
        return salesAccount ;
    }

    //Create Opportunity object
    public Opportunity getOpportunity (Account account)
    {
        string recordtypeid;
        
        Opportunity opportunity = new Opportunity();
        recordtypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('APAC Sales Opportunity').getRecordTypeId();
        
        // Opportunity 
        opportunity.Name = '1234';
        opportunity.StageName = 'Prepare';
        opportunity.Amount = 12345;
        opportunity.RecordTypeID = recordtypeid;
        opportunity.Type = 'Standard';
        opportunity.CloseDate = System.Today();
        opportunity.PaymentType__c = 'Credit Card';
        opportunity.FulfillmentChannel__c = 'Direct - End Customer';
        opportunity.Country_of_Order__c = 'Australia';
        opportunity.AccountId = account.Id;
        opportunity.CurrencyIsoCode = 'USD';
        opportunity.Pay_Now__c = 'Yes';
        opportunity.ForecastCategoryName = 'Pipeline';
        
       
        
        return Opportunity ;
    }
    
    //Create Sales Account IntegrationObject Domain object
    public IntegrationObjects.SalesAccount getSalesAccount ()
    {
        IntegrationObjects.SalesAccount account = new IntegrationObjects.SalesAccount ();
        account.CDH_Party_Number = '787776';
        
        return account ;
    }
    
}