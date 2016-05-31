/*****************************************************************************************
    Name    : SystemObjectConverter
    Desc    : This class exists solely to convert Integration Objects into their system
              object counterparts.
    Modification Log :
---------------------------------------------------------------------------
    Developer       Date                Description
---------------------------------------------------------------------------
    Vipul Jain      23 JULY 2014        Created
    Pankaj Banik    26 JULY 2014        Modified
    Vipul Jain      06 OCT  2014        Updated : To include missing attributes on Opportunity Staging (Header Level and Line Level)
                                        US56366 (TA148304)
   Vipul Jain       31 OCT 2014         Updated : Update the converter class to remove mapping of contact points (US56664-TA154960 ,TA154961)
   Scott Coleman    07 Nov 2014         Added transformations for order Pay Now and Payment Type
   Scott Coleman    09 Dec 2014         Added order Contract Number
   Niti Bansal      16 JAN 2015         Added KnownAs in Account
   Sagar Mehta      23 Feb 2015         Added line for mapping CDH Party Name field in Oppty Partner Staging Object as per US63564, Line No: 337
******************************************************************************************/

public with sharing class SystemObjectConverter {
    
    public static Account ConvertToioAccount(IntegrationObjects.SalesAccount ioAccount){
    
        Account account = new Account();
        account.Name = ioAccount.Name;
        account.VATNumber__c = ioAccount.VATNumber;
        account.D_U_N_S__c = ioAccount.D_U_N_S;
        account.Status__c = ioAccount.Status;
        account.sic = ioAccount.Sic;
        account.SicDesc= ioAccount.SicDesc;
        account.All_NAICS_Codes__c = ioAccount.All_NAICS_Codes;
        account.Do_Not_Do_Business_With__c = ioAccount.Do_Not_Do_Business_with != Null ? ioAccount.Do_Not_Do_Business_with:account.Do_Not_Do_Business_With__c;
        //account.SEA_Concern__c = ioAccount.SEA_Concern;
        account.SEA_Concern__c = ioAccount.SEA_Concern=='SEAP'?'Yes':'No'; //Changed by Niti 
        account.Tradestyle = ioAccount.Trade_Style;
        account.YearStarted = ioAccount.YearStarted;
        account.NumberOfEmployees = ioAccount.NumberOfEmployees;
        account.AnnualRevenue = ioAccount.AnnualRevenue;
        // comment out the mapping for the contact points
        //Commented as a part of user story US64014 : To suppress the code to copy fields when coming as a CDH outbound - SFDC inbound.
        //account.Website = ioAccount.Website;
        //account.Phone = ioAccount.Phone;
        //account.Fax = ioAccount.Fax;
        account.Known_As__c = ioAccount.KnownAs;
        return account;
    }
    
    public static Contact ConvertToioContact(IntegrationObjects.Contact ioContact){
    
        Contact contact = new Contact();
        contact.LoginName__c  = ioContact .LoginName;
        contact.FirstName  = ioContact .FirstName;
        contact.LastName = ioContact .LastName;
        contact.Salutation = ioContact .Salutation;
        contact.Status__c = ioContact .Status;
        // comment out the mapping for the contact points
        //contact.Email = ioContact .Email;
        //contact.Phone = ioContact .Phone;
        //contact.Fax = ioContact .Fax;
        //contact.MobilePhone = ioContact.MobilePhone;
        return contact;
    }
    
    public static Address__c ConvertToioAddress (IntegrationObjects.Address ioAddress){
    
        Address__c address = new Address__c();
        address.CDH_Party_Site_Number__c = ioAddress.CDH_Party_Site_Number;
        address.Address_Line1__c = ioAddress.Address_Line1;
        address.Address_Line2__c = ioAddress.Address_Line2;
        address.Address_Line3__c = ioAddress.Address_Line3;
        address.Address_Line4__c = ioAddress.Address_Line4;
        address.City__c = ioAddress.city;
        address.State__c = ioAddress.State;
        address.Province__c = ioAddress.Province;
        address.Zip_Postal_Code__c = ioAddress.Zip_Postal_Code;
        address.Country__c = ioAddress.country;
        address.County__c = ioAddress.county;
        address.Bill_To_Address__c = (ioAddress.Bill_To_Address !=Null) ? (ioAddress.Bill_To_Address ) : (address.Bill_To_Address__c);
        address.Sold_To_Address__c = (ioAddress.Sold_To_Address != Null ) ? (ioAddress.Sold_To_Address) : (address.Sold_To_Address__c);
        address.Ship_To_Address__c = (ioAddress.Ship_To_Address != Null) ? (ioAddress.Ship_To_Address) : (address.Ship_To_Address__c) ;
        address.Entitle_To_Address__c = (ioAddress.Entitle_To_Address != Null) ? (ioAddress.Entitle_To_Address) : (address.Entitle_To_Address__c);
        address.Identifying_Address__c = (ioAddress.Identifying_Address != Null ) ? (ioAddress.Identifying_Address) : (address.Identifying_Address__c);
        address.Status__c = ioAddress.Status;
        return address;
    }
    
    public static EBS_Account__c ConvertioTransactionalAccount (IntegrationObjects.TransactionalAccount ioTransactionalAccount){
        
        EBS_Account__c ebsAccount = new EBS_Account__c();
        ebsAccount.Name = ioTransactionalAccount.Account_Number;
        ebsAccount.EBS_Account_Description__c = ioTransactionalAccount.Account_Description ;
        ebsAccount.Account_Type__c = ioTransactionalAccount.Account_Type ;
        ebsAccount.Classification__c = ioTransactionalAccount.Classification;
        ebsAccount.Credit_Review_Cycle__c = ioTransactionalAccount.Credit_Review_Cycle ;               
        ebsAccount.Credit_Hold__c =  ioTransactionalAccount.Credit_hold != null ? ioTransactionalAccount.Credit_hold : False;
        ebsAccount.EBS_Party_Number__c = ioTransactionalAccount.EBS_Party_Number ;
        ebsAccount.EBS_Party_Name__c = ioTransactionalAccount.EBS_Party_Name ;
        ebsAccount.CDH_Party_Number__c = ioTransactionalAccount.Sales_Account ;            
        ebsAccount.Last_Credit_Review_Date__c = ioTransactionalAccount.Last_Credit_Review_Date ;
        ebsAccount.Next_Credit_Review_Date__c = ioTransactionalAccount.Next_Credit_Review_Date;            
        ebsAccount.Primary_EBS_Account__c = ioTransactionalAccount.Primary_EBS_Account != null ? ioTransactionalAccount.Primary_EBS_Account: False ;
        ebsAccount.Sales_channel__c = ioTransactionalAccount.Sales_Channel ;
        ebsAccount.Status__c = ioTransactionalAccount.Status ; 
        return ebsAccount;
    }
    
     public static Opportunity_Header_Staging__c ConvertioOrder (IntegrationObjects.Order ioOrder){
        
        System.debug ('Inside Order converter---->') ;
        Opportunity_Header_Staging__c opportunityStaging = new Opportunity_Header_Staging__c();
        
        opportunityStaging.Oracle_Order_ID__c = ioOrder.orderId ;
        opportunityStaging.Oracle_Order_Number__c = ioOrder.orderNumber ;
        opportunityStaging.Employee_Number__c = ioOrder.employeeNumber ;
        opportunityStaging.Opportunity_Number__c = ioOrder.opportunityNumber ;
        opportunityStaging.Order_Type__c = ioOrder.orderType ;
        opportunityStaging.Operating_Unit__c = ioOrder.operatingUnit ;        
        if (ioOrder.paymentType == '' || ioOrder.paymentType == null || ioOrder.paymentType == 'Check' || ioOrder.paymentType == 'Cash' || ioOrder.paymentType == 'PURCHASE ORDER')
            {opportunityStaging.Payment_Type__c = 'Purchase Order'; }
        else if (ioOrder.paymentType == 'Credit Card')
            {opportunityStaging.Payment_Type__c = 'Credit Card';}        
        opportunityStaging.PO_Number__c = ioOrder.purchaseOrderNumber ;
        if (ioOrder.purchaseOrderNumber != null)
            {opportunityStaging.Payment_Type__c = 'Purchase Order'; }                 
        opportunityStaging.Channel__c = ioOrder.fulfillmentChannel ;
        opportunityStaging.CurrencyIsoCode = ioOrder.currencyIsoCode ;
        opportunityStaging.Order_Source__c= ioOrder.orderSource ;
        opportunityStaging.Order_Status__c = ioOrder.orderStatus ;
        opportunityStaging.Date_Ordered__c = ioOrder.orderedDate ;
        opportunityStaging.Date_Booked__c = ioOrder.bookedDate ;
        opportunityStaging.Order_Last_Update_Date__c = ioOrder.lastUpdateDate ;
        opportunityStaging.Opportunity_ID__c = ioOrder.opportunityId ;
        opportunityStaging.Resller_PO__c = ioOrder.resellerPurchaseOrder ;
        opportunityStaging.Non_Entitled_Endco_CDH_Party_Number__c = ioOrder.nonEntitledEndcoCDHPartyNumber ;
        opportunityStaging.Non_Entitled_Endco_Party_Name__c = ioOrder.nonEntitledEndcoCDHPartyName ;
        //opportunityStaging.Amount__c = ioOrder.amount ;
        
        // Sold to EBS account
        if (ioOrder.soldToAccount != null){
            opportunityStaging.Sold_To_Account_Number__c = ioOrder.soldToAccount.Account_Number ;
            opportunityStaging.Sold_To_Party_Number__c = ioOrder.soldToAccount.EBS_Party_Number ;
            opportunityStaging.Sold_To_Party_Name__c = ioOrder.soldToAccount.Name ;
            opportunityStaging.Sold_To_Party_Type__c = ioOrder.soldToAccount.PartyType ;
            opportunityStaging.Sold_To_CDH_Party_Number_Account__c = ioOrder.soldToAccount.CDH_Party_Number;
        }
        // Bill to EBS account
        if(ioOrder.billToAccount != null){
            opportunityStaging.Bill_To_Account_Number__c = ioOrder.billToAccount.Account_Number ;
            opportunityStaging.Bill_To_Party_Number__c = ioOrder.billToAccount.EBS_Party_Number ;
            opportunityStaging.Bill_To_Party_Name__c = ioOrder.billToAccount.Name ;
            opportunityStaging.Bill_To_Party_Type__c = ioOrder.billToAccount.PartyType ;
            opportunityStaging.Bill_To_CDH_Party_Number_Account__c = ioOrder.billToAccount.CDH_Party_Number;
        }
        // Entitle to EBS account
        if(ioOrder.entitleToAccount != null){
            opportunityStaging.Entitle_To_Account_Number__c = ioOrder.entitleToAccount.Account_Number ;
            opportunityStaging.Entitle_To_Party_Number__c = ioOrder.entitleToAccount.EBS_Party_Number ;
            opportunityStaging.Entitle_To_Party_Name__c = ioOrder.entitleToAccount.Name ;
            opportunityStaging.Entitle_To_Party_Type__c = ioOrder.entitleToAccount.PartyType ;
            opportunityStaging.Entitle_To_CDH_Party_Number_Account__c = ioOrder.entitleToAccount.CDH_Party_Number;
            
        }
        // Ship to EBS account
        if(ioOrder.shipToAccount != null){
            opportunityStaging.Ship_To_Account_Number__c = ioOrder.shipToAccount.Account_Number ;
            opportunityStaging.Ship_To_Party_Number__c = ioOrder.shipToAccount.EBS_Party_Number ;
            opportunityStaging.Ship_To_Party_Name__c = ioOrder.shipToAccount.Name ;
            opportunityStaging.Ship_To_Party_Type__c = ioOrder.shipToAccount.PartyType ;
            opportunityStaging.Ship_To_CDH_Party_Number_Account__c = ioOrder.shipToAccount.CDH_Party_Number;
        }
        
        // Bill to address
        if (ioOrder.billToAddress != null){
            opportunityStaging.Bill_To_Address_CDH_Party_Site_Number__c = ioOrder.billToAddress.CDH_Party_Site_Number ;
            opportunityStaging.Bill_To_Address_Line_1__c = ioOrder.billToAddress.Address_Line1 ;
            opportunityStaging.Bill_To_Address_Line_2__c = ioOrder.billToAddress.Address_Line2 ;
            opportunityStaging.Bill_To_Address_Line_3__c = ioOrder.billToAddress.Address_Line3 ;
            opportunityStaging.Bill_To_Address_Line_4__c = ioOrder.billToAddress.Address_Line4 ;
            opportunityStaging.Bill_To_City__c = ioOrder.billToAddress.City ;
            opportunityStaging.Bill_To_Country__c = ioOrder.billToAddress.Country ;
            opportunityStaging.Bill_To_County__c = ioOrder.billToAddress.County ;
            opportunityStaging.Bill_To_State__c = ioOrder.billToAddress.State ;
            opportunityStaging.Bill_To_Province__c = ioOrder.billToAddress.Province ;
            opportunityStaging.Bill_To_Zip_Postal_Code__c = ioOrder.billToAddress.Zip_Postal_Code ;
        }    
        
        // Bill to Contact
        if (ioOrder.billToContact != null){
            opportunityStaging.Bill_To_CDH_Party_Number__c = ioOrder.billToContact.CDH_Party_Number ;
            opportunityStaging.Bill_To_Contact_First_Name__c = ioOrder.billToContact.FirstName ;
            opportunityStaging.Bill_To_Contact_Last_Name__c = ioOrder.billToContact.LastName ;
            opportunityStaging.Bill_To_Contact_Email__c = ioOrder.billToContact.Email ;
            opportunityStaging.Bill_To_Contact_Phone__c = ioOrder.billToContact.Phone ;
        }    
        
        // Ship to address
        if (ioOrder.shipToAddress != null){
            opportunityStaging.Ship_To_Address_CDH_Party_Site_Number__c = ioOrder.shipToAddress.CDH_Party_Site_Number ;
            opportunityStaging.Ship_To_Address_Line_1__c = ioOrder.shipToAddress.Address_Line1 ;
            opportunityStaging.Ship_To_Address_Line_2__c = ioOrder.shipToAddress.Address_Line2 ;
            opportunityStaging.Ship_To_Address_Line_3__c = ioOrder.shipToAddress.Address_Line3 ;
            opportunityStaging.Ship_To_Address_Line_4__c = ioOrder.shipToAddress.Address_Line4 ;
            opportunityStaging.Ship_To_City__c = ioOrder.shipToAddress.City ;
            opportunityStaging.Ship_To_Country__c = ioOrder.shipToAddress.Country ;
            opportunityStaging.Ship_To_County__c = ioOrder.shipToAddress.County ;
            opportunityStaging.Ship_To_State__c = ioOrder.shipToAddress.State ;
            opportunityStaging.Ship_To_Province__c = ioOrder.shipToAddress.State ;
            opportunityStaging.Ship_To_Zip_Postal_Code__c = ioOrder.shipToAddress.Zip_Postal_Code ;
        }
        
        // Ship to Contact
        if (ioOrder.shipToContact != null){    
            opportunityStaging.Ship_To_CDH_Party_Number__c = ioOrder.shipToContact.CDH_Party_Number ;
            opportunityStaging.Ship_To_Contact_First_Name__c = ioOrder.shipToContact.FirstName ;
            opportunityStaging.Ship_To_Contact_Last_Name__c = ioOrder.shipToContact.LastName ;
            opportunityStaging.Ship_To_Contact_Email__c = ioOrder.shipToContact.Email ;
            opportunityStaging.Ship_To_Contact_Phone__c = ioOrder.shipToContact.Phone ;
        }
        
        //Sold To address
        if (ioOrder.soldToAddress != null){    
            opportunityStaging.Sold_To_Address_CDH_Party_Site_Number__c = ioOrder.soldToAddress.CDH_Party_Site_Number ;
            opportunityStaging.Sold_To_Address_Line_1__c = ioOrder.soldToAddress.Address_Line1 ;
            opportunityStaging.Sold_To_Address_Line_2__c = ioOrder.soldToAddress.Address_Line2 ;
            opportunityStaging.Sold_To_Address_Line_3__c = ioOrder.soldToAddress.Address_Line3 ;
            opportunityStaging.Sold_To_Address_Line_4__c = ioOrder.soldToAddress.Address_Line4 ;
            opportunityStaging.Sold_To_City__c = ioOrder.soldToAddress.City ;
            opportunityStaging.Sold_To_Country__c = ioOrder.soldToAddress.Country ;
            opportunityStaging.Sold_To_County__c = ioOrder.soldToAddress.County ;
            opportunityStaging.Sold_To_State__c = ioOrder.soldToAddress.State ;
            opportunityStaging.Sold_To_Province__c = ioOrder.soldToAddress.State ;
            opportunityStaging.Sold_To_Zip_Postal_Code__c = ioOrder.soldToAddress.Zip_Postal_Code ;
        }
        
        //Sold to contact
        if (ioOrder.soldToContact != null){
            opportunityStaging.Sold_To_CDH_Party_Number__c = ioOrder.soldToContact.CDH_Party_Number ;
            opportunityStaging.Sold_To_Contact_First_Name__c = ioOrder.soldToContact.FirstName ;
            opportunityStaging.Sold_To_Contact_Last_Name__c = ioOrder.soldToContact.LastName ;
            opportunityStaging.Sold_To_Contact_Email__c = ioOrder.soldToContact.Email ;
            opportunityStaging.Sold_To_Contact_Phone__c = ioOrder.soldToContact.Phone ;
        }
        
        //Entitle to address
        if (ioOrder.entitleToAddress != null){
            opportunityStaging.Entitle_To_Address_CDH_Party_Site_Number__c = ioOrder.entitleToAddress.CDH_Party_Site_Number ;
            opportunityStaging.Entitle_To_Address_Line_1__c = ioOrder.entitleToAddress.Address_Line1 ;
            opportunityStaging.Entitle_To_Address_Line_2__c = ioOrder.entitleToAddress.Address_Line2 ;
            opportunityStaging.Entitle_To_Address_Line_3__c = ioOrder.entitleToAddress.Address_Line3 ;
            opportunityStaging.Entitle_To_Address_Line_4__c = ioOrder.entitleToAddress.Address_Line4 ;
            opportunityStaging.Entitle_To_City__c = ioOrder.entitleToAddress.City ;
            opportunityStaging.Entitle_To_Country__c = ioOrder.entitleToAddress.Country ;
            opportunityStaging.Entitle_To_County__c = ioOrder.entitleToAddress.County ;
            opportunityStaging.Entitle_To_State__c = ioOrder.entitleToAddress.State ;
            opportunityStaging.Entitle_To_Province__c = ioOrder.entitleToAddress.State ;
            opportunityStaging.Entitle_To_Zip_Postal_Code__c = ioOrder.entitleToAddress.Zip_Postal_Code ;
        }
        
        //Entitle to Contact
        if (ioOrder.entitleToContact != null) {
            opportunityStaging.Entitle_To_CDH_Party_Number__c = ioOrder.entitleToContact.CDH_Party_Number ;
            opportunityStaging.Entitle_To_Contact_First_Name__c = ioOrder.entitleToContact.FirstName ;
            opportunityStaging.Entitle_To_Contact_Last_Name__c = ioOrder.entitleToContact.LastName ;
            opportunityStaging.Entitle_To_Contact_Email__c = ioOrder.entitleToContact.Email ;
            opportunityStaging.Entitle_To_Contact_Phone__c = ioOrder.entitleToContact.Phone ;
        }
        
        return opportunityStaging;
    }
    
    public static Opportunity_Line_Staging__c ConvertioOrderLine (IntegrationObjects.OrderLine ioOrderLine){
        
        System.debug ('Inside Orderline converter---->') ;
        Opportunity_Line_Staging__c opportunityLineStaging = new Opportunity_Line_Staging__c();
        
        opportunityLineStaging.ActualEndDate__c = ioOrderLine.actualEndDate ;
        opportunityLineStaging.ActualStartDate__c = ioOrderLine.actualStartDate ;
        if (ioOrderLine.listPrice != null)
            opportunityLineStaging.Base_Price__c = ioOrderLine.listPrice ;
        else
            opportunityLineStaging.Base_Price__c = 0 ;
            
        opportunityLineStaging.Contract_Numbers__c = ioOrderLine.contractNumbers  ;
        opportunityLineStaging.Install_Base_Number__c = ioOrderLine.installBaseNumber  ;
        opportunityLineStaging.Opportunity_ID__c = ioOrderLine.opportunityId ;
        opportunityLineStaging.Opportunity_Product_ID__c = ioOrderLine.opportunityLineId ;
        opportunityLineStaging.Product_Code_Oracle__c = ioOrderLine.productCode ;
        if (ioOrderLine.quantity != null)
            opportunityLineStaging.Quantity__c = ioOrderLine.quantity ;
        else 
            opportunityLineStaging.Quantity__c = 0 ;
            
        opportunityLineStaging.Unit_of_Measure__c = ioOrderLine.unitOfMeasure ;
        
        if (ioOrderLine.salesPrice != null)
            opportunityLineStaging.UnitPrice__c = ioOrderLine.salesPrice ;
        else 
            opportunityLineStaging.UnitPrice__c = 0 ;
            
        if (ioOrderLine.entitleToAccount != null){
            opportunityLineStaging.Entitle_To_Account_Number__c = ioOrderLine.entitleToAccount.Account_Number ;
            opportunityLineStaging.Entitle_To_Party_Number__c = ioOrderLine.entitleToAccount.EBS_Party_Number ;
            opportunityLineStaging.Entitle_To_Party_Name__c = ioOrderLine.entitleToAccount.Name ;
            opportunityLineStaging.Entitle_To_Party_Type__c = ioOrderLine.entitleToAccount.PartyType ;
            opportunityLineStaging.Entitle_To_CDH_Party_Number_Account__c = ioOrderLine.entitleToAccount.CDH_Party_Number;
        }
        
        if (ioOrderLine.entitleToAddress != null){
            opportunityLineStaging.Entitle_To_CDH_Party_Site_Number__c = ioOrderLine.entitleToAddress.CDH_Party_Site_Number ;
            opportunityLineStaging.Entitle_To_Address_Line_1__c = ioOrderLine.entitleToAddress.Address_Line1 ;
            opportunityLineStaging.Entitle_To_Address_Line_2__c = ioOrderLine.entitleToAddress.Address_Line2 ;
            opportunityLineStaging.Entitle_To_Address_Line_3__c = ioOrderLine.entitleToAddress.Address_Line3 ;
            opportunityLineStaging.Entitle_To_Address_Line_4__c = ioOrderLine.entitleToAddress.Address_Line4 ;
            opportunityLineStaging.Entitle_To_City__c = ioOrderLine.entitleToAddress.City ;
            opportunityLineStaging.Entitle_To_Country__c = ioOrderLine.entitleToAddress.Country ; 
            opportunityLineStaging.Entitle_To_County__c = ioOrderLine.entitleToAddress.County ;
            opportunityLineStaging.Entitle_To_Province__c = ioOrderLine.entitleToAddress.Province ;
            opportunityLineStaging.Entitle_To_State__c = ioOrderLine.entitleToAddress.State ;
            opportunityLineStaging.Entitle_To_Zip_Postal_Code__c = ioOrderLine.entitleToAddress.Zip_Postal_Code ;
        }
        
        if (ioOrderLine.entitleToContact != null){
            opportunityLineStaging.Entitle_To_CDH_Party_Number__c = ioOrderLine.entitleToContact.CDH_Party_Number ;
            opportunityLineStaging.Entitle_To_Contact_First_Name__c = ioOrderLine.entitleToContact.FirstName ;
            opportunityLineStaging.Entitle_To_Contact_Last_Name__c = ioOrderLine.entitleToContact.LastName ;
            opportunityLineStaging.Entitle_To_Contact_Email__c = ioOrderLine.entitleToContact.Email ;
            opportunityLineStaging.Entitle_To_Contact_Phone__c = ioOrderLine.entitleToContact.Phone ;
        }
        
        return opportunityLineStaging ;
        
    }
    
    public static Opportunity_Partner_Staging__c ConvertioOrderPartner (IntegrationObjects.OrderPartner ioOrderPartner){
        System.debug ('Inside OrderPartbner converter---->') ;
        Opportunity_Partner_Staging__c partnerStaging = new Opportunity_Partner_Staging__c();
        
        if (ioOrderPartner.account != null){
            partnerStaging.CDH_Party_Number__c = ioOrderPartner.account.CDH_Party_Number ;
            partnerStaging.CDH_Party_Name__c = ioOrderPartner.account.Name; 
        }
        partnerStaging.PartnerTier__c = ioOrderPartner.partnerTier ;
        partnerStaging.Partner_Type__c = ioOrderPartner.partnerType ;
        partnerStaging.RelationshipType__c = ioOrderPartner.transactionRole ;
        partnerStaging.Oracle_Classification_Code__c=ioOrderPartner.classificationCode;
        
        if (ioOrderPartner.contact != null) {
            partnerStaging.Partner_Contact_CDH_Party_Number__c = ioOrderPartner.contact.CDH_Party_Number ;
            partnerStaging.Partner_Contact_First_Name__c = ioOrderPartner.contact.FirstName ;
            partnerStaging.Partner_Contact_Last_Name__c = ioOrderPartner.contact.LastName ;
            partnerStaging.Partner_Contact_Email__c = ioOrderPartner.contact.Email ;
            partnerStaging.Partner_Contact_Phone__c = ioOrderPartner.contact.Phone ;
        }
        return partnerStaging ;
    }
    
    /*This method will get invoed by OrderDetailsExtensions.onSubmitOrderBtnClick() that will pass entire opportunity details and returns a wrapper structure of opportunity as a parameter.*/
    public static IntegrationObjects.Order ConvertToOrder (Opportunity orderDetails)
    {
        //OperatingUnitOrgId custom setting is used to get org id based on the operating unit selected.
        //Map<String,orgIdMappedToOperatingUnit__c> OperatingUnitOrgId = orgIdMappedToOperatingUnit__c.getAll();
        
        //initializing integrationObject wrapper structure for opportunity here.
        IntegrationObjects.Order orderObject = new IntegrationObjects.Order() ;
        
        //Assigning opportunity details to the related variables of wrapper structure.
        orderObject.orderId = orderDetails.OracleOrderID__c;    
        orderObject.orderNumber = orderDetails.OracleOrderNumber__c;
        orderObject.employeeNumber = orderDetails.Owner__r.EmployeeNumber;
        orderObject.opportunityNumber = orderDetails.OpportunityNumber__c;
        orderObject.purchaseOrderNumber = orderDetails.PONumber__c;
        orderObject.orderType = orderDetails.Order_Type__c;
        // Entitled to customer information mapping
        orderObject.nonEntitledEndcoCDHPartyName=orderDetails.Non_Entitled_Endco__r.Name;
        orderObject.nonEntitledEndcoCDHPartyNumber=orderDetails.Non_Entitled_Endco__r.CDH_Party_Name__r.Name;
        //Adding operating unit logic
        //orderObject.operatingUnit = OperatingUnitOrgId.get(orderDetails.Operating_Unit__c).ORG_ID__c != null ? OperatingUnitOrgId.get(orderDetails.Operating_Unit__c).ORG_ID__c : '';
        orderObject.operatingUnit = orderDetails.Operating_Unit__c;
        if(orderDetails.Pay_Now__c == 'Yes') {
            orderObject.payNow = 'Y';
        }
        else if(orderDetails.Pay_Now__c == 'No') {
            orderObject.payNow = 'N';
        }
        if(orderDetails.PaymentType__c == 'Credit Card') {
            orderObject.paymentType = 'CREDIT_CARD';
        }
        orderObject.contractNumber = orderDetails.ContractNumber__c;
        orderObject.creditCardNumber = orderDetails.Credit_Card_Number__c;
        orderObject.expirationDate = orderDetails.ExpirationDate__c;
        orderObject.creditCardType = orderDetails.CreditCardType__c;
        orderObject.nameOnCard = orderDetails.NameOnCard__c;
        orderObject.fulfillmentChannel = orderDetails.FulfillmentChannel__c;
        //Adding payment terms logic
        //orderObject.paymentTerms = orderDetails.PaymentTerms__c;
        if(orderDetails.CreditChecks__r != null && orderDetails.CreditChecks__r.size() > 0){
            //We are taking the zeroth element because we are taking the latest record
            orderObject.paymentTerms = orderDetails.CreditChecks__r[0].Payment_Terms__c;
        }
        orderObject.currencyIsoCode = orderDetails.CurrencyIsoCode;
        orderObject.opportunityId = orderDetails.Id;
        //orderObject.amount = orderDetails.Amount;
        orderObject.shippingInstructions = orderDetails.Shipping_Instructions__c;
        orderObject.vatCode = orderDetails.VAT_Code__c;
        orderObject.rushOrder = orderDetails.Rush_Order__c;
        orderObject.id = orderDetails.id;
        orderObject.resellerPurchaseOrder = orderDetails.Reseller_PO__c;
        
        //Bill To Account
        //initializing integrationObject wrapper structure for billToAccount here.
        orderObject.billToAccount = new IntegrationObjects.TransactionalAccount();
        orderObject.billToAccount.Account_Number = orderDetails.Bill_To_Account__c != Null ? orderDetails.Bill_To_Account__r.Name : '' ;
        orderObject.billToAccount.EBS_Party_Number = orderDetails.Bill_To_Account__c != null ? orderDetails.Bill_To_Account__r.EBS_Party_Number__c : null;
        
        //Bill To Address
        //initializing integrationObject wrapper structure for billToAddress here.
        orderObject.billToAddress = new IntegrationObjects.Address();
        orderObject.billToAddress.CDH_Party_Site_Number = orderDetails.Bill_To_Address__c != null ? orderDetails.Bill_To_Address__r.CDH_Party_Site_Number__c : '';
        orderObject.billToAddress.Address_Line1 = orderDetails.Bill_To_Address__c != null ? orderDetails.Bill_To_Address__r.Address_Line1__c : '';
        orderObject.billToAddress.Address_Line2 = orderDetails.Bill_To_Address__c != null ? orderDetails.Bill_To_Address__r.Address_Line2__c : '';
        orderObject.billToAddress.Address_Line3 = orderDetails.Bill_To_Address__c != null ? orderDetails.Bill_To_Address__r.Address_Line3__c : '';
        orderObject.billToAddress.Address_Line4 = orderDetails.Bill_To_Address__c != null ? orderDetails.Bill_To_Address__r.Address_Line4__c : '';  
        orderObject.billToAddress.City = orderDetails.Bill_To_Address__c != null ? orderDetails.Bill_To_Address__r.City__c : '';
        orderObject.billToAddress.State = orderDetails.Bill_To_Address__c != null ? orderDetails.Bill_To_Address__r.State__c : '';
        orderObject.billToAddress.Country = orderDetails.Bill_To_Address__c != null ? orderDetails.Bill_To_Address__r.country__c : '';
        orderObject.billToAddress.County = orderDetails.Bill_To_Address__c != null ? orderDetails.Bill_To_Address__r.County__c : '';
        orderObject.billToAddress.Zip_Postal_Code = orderDetails.Bill_To_Address__c != null ? orderDetails.Bill_To_Address__r.Zip_Postal_Code__c : '';
        orderObject.billToAddress.Province = orderDetails.Bill_To_Address__c != null ? orderDetails.Bill_To_Address__r.Province__c : '';
        
        //Bill To Contact
        //initializing integrationObject wrapper structure for billToContact here.
        orderObject.billToContact = new IntegrationObjects.Contact();
        orderObject.billToContact.CDH_Party_Number = orderDetails.Bill_To_Contact__c != null ? orderDetails.Bill_To_Contact__r.CDH_Party_Number__c : '';
        orderObject.billToContact.FirstName = orderDetails.Bill_To_Contact__c != null ? orderDetails.Bill_To_Contact__r.FirstName : '';
        orderObject.billToContact.LastName = orderDetails.Bill_To_Contact__c != null ? orderDetails.Bill_To_Contact__r.LastName : '';
        orderObject.billToContact.Email = orderDetails.Bill_To_Contact__c != null ? orderDetails.Bill_To_Contact__r.Email : '';
        orderObject.billToContact.Phone = orderDetails.Bill_To_Contact__c != null ? orderDetails.Bill_To_Contact__r.Phone : '';
        orderObject.billToContact.CDH_Party_Number = orderDetails.Bill_To_Contact__c != null ? orderDetails.Bill_To_Contact__r.CDH_Party_Number__c : '';
        
        //Sold To Account
        //initializing integrationObject wrapper structure for soldToAccount here.
        orderObject.soldToAccount = new IntegrationObjects.TransactionalAccount();
        orderObject.soldToAccount.Account_Number = orderDetails.Sold_To_Account__c !=Null ? orderDetails.Sold_To_Account__r.Name :'' ;
        orderObject.soldToAccount.EBS_Party_Number = orderDetails.Sold_To_Account__c != null ? orderDetails.Sold_To_Account__r.EBS_Party_Number__c : null;
      
        //Sold To Address
        //initializing integrationObject wrapper structure for soldToAddress here.
        orderObject.soldToAddress = new IntegrationObjects.Address();
        orderObject.soldToAddress.CDH_Party_Site_Number = orderDetails.Sold_To_Address__c != null ? orderDetails.Sold_To_Address__r.CDH_Party_Site_Number__c : '';
        orderObject.soldToAddress.Address_Line1 = orderDetails.Sold_To_Address__c != null ? orderDetails.Sold_To_Address__r.Address_Line1__c : '';
        orderObject.soldToAddress.Address_Line2 = orderDetails.Sold_To_Address__c != null ? orderDetails.Sold_To_Address__r.Address_Line2__c : '';
        orderObject.soldToAddress.Address_Line3 = orderDetails.Sold_To_Address__c != null ? orderDetails.Sold_To_Address__r.Address_Line3__c : '';
        orderObject.soldToAddress.Address_Line4 = orderDetails.Sold_To_Address__c != null ? orderDetails.Sold_To_Address__r.Address_Line4__c : '';
        orderObject.soldToAddress.City = orderDetails.Sold_To_Address__c != null ? orderDetails.Sold_To_Address__r.City__c : '';
        orderObject.soldToAddress.State = orderDetails.Sold_To_Address__c != null ? orderDetails.Sold_To_Address__r.State__c : '';
        orderObject.soldToAddress.Country = orderDetails.Sold_To_Address__c != null ? orderDetails.Sold_To_Address__r.country__c : '';
        orderObject.soldToAddress.County = orderDetails.Sold_To_Address__c != null ? orderDetails.Sold_To_Address__r.County__c : '';
        orderObject.soldToAddress.Zip_Postal_Code = orderDetails.Sold_To_Address__c != null ? orderDetails.Sold_To_Address__r.Zip_Postal_Code__c : '';
        orderObject.soldToAddress.Province = orderDetails.Sold_To_Address__c != null ? orderDetails.Sold_To_Address__r.Province__c : '';
        
        //Sold To Contact
        //initializing integrationObject wrapper structure for soldToContact here.
        orderObject.soldToContact = new IntegrationObjects.Contact();
        orderObject.soldToContact.CDH_Party_Number = orderDetails.Sold_To_Contact__c != null ? orderDetails.Sold_To_Contact__r.CDH_Party_Number__c : '';
        orderObject.soldToContact.FirstName = orderDetails.Sold_To_Contact__c != null ? orderDetails.Sold_To_Contact__r.FirstName : '';
        orderObject.soldToContact.LastName = orderDetails.Sold_To_Contact__c != null ? orderDetails.Sold_To_Contact__r.LastName : '';
        orderObject.soldToContact.Email = orderDetails.Sold_To_Contact__c != null ? orderDetails.Sold_To_Contact__r.Email : '';
        orderObject.soldToContact.Phone = orderDetails.Sold_To_Contact__c != null ? orderDetails.Sold_To_Contact__r.Phone : '';
        orderObject.soldToContact.CDH_Party_Number = orderDetails.Sold_To_Contact__c != null ? orderDetails.Sold_To_Contact__r.CDH_Party_Number__c : '';
        
        //Ship To Account
        //initializing integrationObject wrapper structure for shipToAccount here.
        orderObject.shipToAccount = new IntegrationObjects.TransactionalAccount();
        orderObject.shipToAccount.Account_Number = orderDetails.Ship_To_Account__c != null ? orderDetails.Ship_To_Account__r.Name : '' ;
        orderObject.shipToAccount.EBS_Party_Number = orderDetails.Ship_To_Account__c != null ? orderDetails.Ship_To_Account__r.EBS_Party_Number__c : null ;
        
        //Ship To Address
        //initializing integrationObject wrapper structure for shipToAddress here.
        orderObject.shipToAddress = new IntegrationObjects.Address();
        orderObject.shipToAddress.CDH_Party_Site_Number = orderDetails.Ship_To_Address__c != null ? orderDetails.Ship_To_Address__r.CDH_Party_Site_Number__c : '';
        orderObject.shipToAddress.Address_Line1 = orderDetails.Ship_To_Address__c != null ? orderDetails.Ship_To_Address__r.Address_Line1__c : '';
        orderObject.shipToAddress.Address_Line2 = orderDetails.Ship_To_Address__c != null ? orderDetails.Ship_To_Address__r.Address_Line2__c : '';
        orderObject.shipToAddress.Address_Line3 = orderDetails.Ship_To_Address__c != null ? orderDetails.Ship_To_Address__r.Address_Line3__c : '';
        orderObject.shipToAddress.Address_Line4 = orderDetails.Ship_To_Address__c != null ? orderDetails.Ship_To_Address__r.Address_Line4__c : '';
        orderObject.shipToAddress.City = orderDetails.Ship_To_Address__c != null ? orderDetails.Ship_To_Address__r.City__c : '';
        orderObject.shipToAddress.State = orderDetails.Ship_To_Address__c != null ? orderDetails.Ship_To_Address__r.State__C : '';
        orderObject.shipToAddress.Country = orderDetails.Ship_To_Address__c != null ? orderDetails.Ship_To_Address__r.country__c : '';
        orderObject.shipToAddress.County = orderDetails.Ship_To_Address__c != null ? orderDetails.Ship_To_Address__r.County__c : '';
        orderObject.shipToAddress.Zip_Postal_Code = orderDetails.Ship_To_Address__c != null ? orderDetails.Ship_To_Address__r.Zip_Postal_Code__c : '';
        orderObject.shipToAddress.Province = orderDetails.Ship_To_Address__c != null ? orderDetails.Ship_To_Address__r.Province__c : '';
        
        //Ship To Contact
        //initializing integrationObject wrapper structure for shipToContact here.
        orderObject.shipToContact = new IntegrationObjects.Contact();
        orderObject.shipToContact.CDH_Party_Number = orderDetails.Ship_To_Contact__c != null ? orderDetails.Ship_To_Contact__r.CDH_Party_Number__c : '';
        orderObject.shipToContact.FirstName = orderDetails.Ship_To_Contact__c != null ? orderDetails.Ship_To_Contact__r.FirstName : '';
        orderObject.shipToContact.LastName = orderDetails.Ship_To_Contact__c != null ? orderDetails.Ship_To_Contact__r.LastName : '';
        orderObject.shipToContact.Email = orderDetails.Ship_To_Contact__c != null ? orderDetails.Ship_To_Contact__r.Email : '';
        orderObject.shipToContact.Phone = orderDetails.Ship_To_Contact__c != null ? orderDetails.Ship_To_Contact__r.Phone : '';
        orderObject.shipToContact.CDH_Party_Number = orderDetails.Ship_To_Contact__c != null ? orderDetails.Ship_To_Contact__r.CDH_Party_Number__c : '';
        
        //Entitle To Account
        //initializing integrationObject wrapper structure for entitleToAccount here.
        orderObject.entitleToAccount = new IntegrationObjects.TransactionalAccount();
        orderObject.entitleToAccount.Account_Number = orderDetails.Entitle_To_Account__c != null ? orderDetails.Entitle_To_Account__r.Name : '' ;
        orderObject.entitleToAccount.EBS_Party_Number = orderDetails.Entitle_To_Account__c!= null ? orderDetails.Entitle_To_Account__r.EBS_Party_Number__c : null ;
        
        //Entitle To Address
        //initializing integrationObject wrapper structure for entitleToAddress here.
        orderObject.entitleToAddress = new IntegrationObjects.Address();
        orderObject.entitleToAddress.CDH_Party_Site_Number = orderDetails.Entitle_To_Address__c != null ? orderDetails.Entitle_To_Address__r.CDH_Party_Site_Number__c : '';
        orderObject.entitleToAddress.Address_Line1 = orderDetails.Entitle_To_Address__c != null ? orderDetails.Entitle_To_Address__r.Address_Line1__c : '';
        orderObject.entitleToAddress.Address_Line2 = orderDetails.Entitle_To_Address__c != null ? orderDetails.Entitle_To_Address__r.Address_Line2__c : '';
        orderObject.entitleToAddress.Address_Line3 = orderDetails.Entitle_To_Address__c != null ? orderDetails.Entitle_To_Address__r.Address_Line3__c : '';
        orderObject.entitleToAddress.Address_Line4 = orderDetails.Entitle_To_Address__c != null ? orderDetails.Entitle_To_Address__r.Address_Line4__c : '';
        orderObject.entitleToAddress.City = orderDetails.Entitle_To_Address__c != null ? orderDetails.Entitle_To_Address__r.City__c : '';
        orderObject.entitleToAddress.State = orderDetails.Entitle_To_Address__c != null ? orderDetails.Entitle_To_Address__r.State__C : '';
        orderObject.entitleToAddress.Country = orderDetails.Entitle_To_Address__c != null ? orderDetails.Entitle_To_Address__r.country__c : '';
        orderObject.entitleToAddress.County = orderDetails.Entitle_To_Address__c != null ? orderDetails.Entitle_To_Address__r.County__c : '';
        orderObject.entitleToAddress.Zip_Postal_Code = orderDetails.Entitle_To_Address__c != null ? orderDetails.Entitle_To_Address__r.Zip_Postal_Code__c : '';
        orderObject.entitleToAddress.Province = orderDetails.Entitle_To_Address__c != null ? orderDetails.Entitle_To_Address__r.Province__c : '';
        
        //Entitle To Contact
        //initializing integrationObject wrapper structure for entitleToContact here.
        orderObject.entitleToContact = new IntegrationObjects.Contact();
        orderObject.entitleToContact.CDH_Party_Number = orderDetails.Entitle_To_Contact__c != null ? orderDetails.Entitle_To_Contact__r.CDH_Party_Number__c : '';
        orderObject.entitleToContact.FirstName = orderDetails.Entitle_To_Contact__c != null ? orderDetails.Entitle_To_Contact__r.FirstName : '';
        orderObject.entitleToContact.LastName = orderDetails.Entitle_To_Contact__c != null ? orderDetails.Entitle_To_Contact__r.LastName : '';
        orderObject.entitleToContact.Email = orderDetails.Entitle_To_Contact__c != null ? orderDetails.Entitle_To_Contact__r.Email : '';
        orderObject.entitleToContact.Phone = orderDetails.Entitle_To_Contact__c != null ? orderDetails.Entitle_To_Contact__r.Phone : '';
        orderObject.entitleToContact.CDH_Party_Number = orderDetails.Entitle_To_Contact__c != null ? orderDetails.Entitle_To_Contact__r.CDH_Party_Number__c : '';
        
        //checking if an opportunity has line items associated with it.
        if(orderDetails.OpportunityLineItems.size()>0)
        {
            //initializing opportunityLineItem wrapper structure as a list.
            List<IntegrationObjects.OrderLine> orderLines = new List<IntegrationObjects.OrderLine> (); 
            
            //iterating through the list of opportunitLineItm and assigning there values to the wrapper stucture of opportunityLineItem.
            for(OpportunityLineItem lineItem : orderDetails.OpportunityLineItems)
            {
                //initializing integrationObject wrapper structure for opportunityLineItem here.
                IntegrationObjects.OrderLine orderLine = new IntegrationObjects.OrderLine () ;
                orderLine.productCode = lineItem.PricebookEntry.Product2.ProductCode;
                orderLine.actualStartDate = lineItem.ActualStartDate__c;
                orderLine.actualEndDate = lineItem.ActualEndDate__c;
                if (lineItem.Quantity == null)
                {
                    orderLine.quantity = 0 ;
                }
                else
                {
                    orderLine.quantity = lineItem.Quantity;
                }
                orderLine.unitOfMeasure = lineItem.PricebookEntry.Product2.Unit_Of_Measure__c;
                if (lineItem.UnitPrice == null){
                    orderLine.perUnitProratedPrice = 0 ;
                }
                else{
                    orderLine.perUnitProratedPrice = lineItem.UnitPrice;
                }
                if (lineItem.Adjusted_Price__c == null)
                {
                    orderLine.salesPrice = 0 ;
                }
                else
                {
                    orderLine.salesPrice = lineItem.Adjusted_Price__c;
                }
                system.debug('test debug here to sales price'+orderLine.salesPrice);
                orderLine.contractNumbers = lineItem.Contract_Numbers__c;
                orderLine.opportunityId = lineItem.OpportunityId;
                orderLine.opportunityLineId = lineItem.id;
                if (lineItem.Price_After_Discretionary_Discount__c == null)
                {
                    orderLine.discretionaryDiscountedPrice = 0 ;
                }
                else
                {
                    orderLine.discretionaryDiscountedPrice = lineItem.Price_After_Discretionary_Discount__c;
                }
                if (lineItem.YearlySalesPrice__c == null)
                {
                    orderLine.oneTimeDiscountedPrice = 0 ;
                }
                else
                {
                    orderLine.oneTimeDiscountedPrice = lineItem.YearlySalesPrice__c;
                }
                orderLine.priceOverrideReason = lineItem.PriceOverrideReason__c;
                system.debug('test price override reasons for sales price'+orderLine.priceOverrideReason);
                orderLine.installBaseNumber = lineItem.Install_Base_Number__c;
                
                //Entitle To Account
                //initializing integrationObject wrapper structure for entitleToAccount here.
                orderLine.entitleToAccount = new IntegrationObjects.TransactionalAccount();
                orderLine.entitleToAccount.Account_Number = lineItem.Entitle_To_Account__c != null ? lineItem.Entitle_To_Account__r.Name : '';
                orderLine.entitleToAccount.EBS_Party_Number = lineItem.Entitle_To_Account__c != null ? lineItem.Entitle_To_Account__r.EBS_Party_Number__c : '';
                
                //Entitle To Address
                //initializing integrationObject wrapper structure for entitleToAddress here.
                orderLine.entitleToAddress = new IntegrationObjects.Address();
                orderLine.entitleToAddress.CDH_Party_Site_Number = lineItem.Entitle_To_Address__c != null ? lineItem.Entitle_To_Address__r.CDH_Party_Site_Number__c : '' ;
                orderLine.entitleToAddress.Address_Line1 = lineItem.Entitle_To_Address__c != null ? lineItem.Entitle_To_Address__r.Address_Line1__c : '' ;
                orderLine.entitleToAddress.Address_Line2 = lineItem.Entitle_To_Address__c != null ? lineItem.Entitle_To_Address__r.Address_Line2__c  : '' ;
                orderLine.entitleToAddress.Address_Line3 = lineItem.Entitle_To_Address__c != null ? lineItem.Entitle_To_Address__r.Address_Line3__c  : '' ;
                orderLine.entitleToAddress.Address_Line4 = lineItem.Entitle_To_Address__c != null ? lineItem.Entitle_To_Address__r.Address_Line4__c : '' ;
                orderLine.entitleToAddress.city = lineItem.Entitle_To_Address__c != null ? lineItem.Entitle_To_Address__r.City__c  : '' ;
                orderLine.entitleToAddress.state= lineItem.Entitle_To_Address__c != null ? lineItem.Entitle_To_Address__r.State__c  : '' ;
                orderLine.entitleToAddress.Province = lineItem.Entitle_To_Address__c != null ? lineItem.Entitle_To_Address__r.Province__c  : '' ;
                orderLine.entitleToAddress.country = lineItem.Entitle_To_Address__c != null ? lineItem.Entitle_To_Address__r.Country__c  : '' ;
                orderLine.entitleToAddress.county = lineItem.Entitle_To_Address__c != null ? lineItem.Entitle_To_Address__r.County__c  : '' ;
                orderLine.entitleToAddress.Zip_Postal_Code = lineItem.Entitle_To_Address__c != null ? lineItem.Entitle_To_Address__r.Zip_Postal_Code__c  : '' ;
                
                //entitle to contact
                //initializing integrationObject wrapper structure for entitleToContact here.
                orderLine.entitleToContact = new IntegrationObjects.Contact();
                orderLine.entitleToContact.CDH_Party_Number = lineItem.Entitle_To_Contact__c != null ? lineItem.Entitle_To_Contact__r.CDH_Party_Number__c : '';
                orderLine.entitleToContact.FirstName = lineItem.Entitle_To_Contact__c != null ? lineItem.Entitle_To_Contact__r.firstName : '';
                orderLine.entitleToContact.LastName = lineItem.Entitle_To_Contact__c != null ? lineItem.Entitle_To_Contact__r.lastName : '';
                orderLine.entitleToContact.Email = lineItem.Entitle_To_Contact__c != null ? lineItem.Entitle_To_Contact__r.Email : '';
                orderLine.entitleToContact.Phone = lineItem.Entitle_To_Contact__c != null ? lineItem.Entitle_To_Contact__r.Phone : '';
                
            
                //adding opportunityLineItem to a list.
                orderLines.add(orderLine);
            }
        //Assigning list<opportunityLineItem> to the opportunity wrapper strucute in integrationObjects.    
        orderObject.orderLines = orderLines;
        } 
        
        //checking the size of partners of opportunity.
        if(orderDetails.OpportunityPartners2__r.size()>0)
        {
            //initializing the list of partners.
            List<IntegrationObjects.OrderPartner> orderPartners = new List<IntegrationObjects.OrderPartner> (); 
            
            //iterating through the list of partner and assigning the values in the wrapper structure of partner.
            for(OpportunityPartner__c Partner : orderDetails.OpportunityPartners2__r)
            {
                //initializing integrationObject wrapper structure for orderPartner here.
                IntegrationObjects.OrderPartner orderPartner = new IntegrationObjects.orderPartner () ;
                orderPartner.partnerType = Partner.PartnerType__c != null ? Partner.PartnerType__r.Name : '';
                orderPartner.partnerTier = Partner.PartnerTierName__c;
                orderPartner.classificationCode = Partner.Oracle_Classification_Code__c;
                system.debug('test debug here to partner tier name populate'+orderPartner.partnerTier);
                orderPartner.transactionRole = Partner.RelationshipType__c;
                
                
                //Account
                //initializing integrationObject wrapper structure for account here.
                orderPartner.account = new IntegrationObjects.SalesAccount();
                //orderPartner.account.Name = Partner.PartnerType__c != null ? Partner.Partner__r.Name : '';
                orderPartner.account.Name = Partner.Partner__r.Name != null ? Partner.Partner__r.Name : '';
                orderPartner.account.CDH_Party_Number = Partner.Partner__r.CDH_Party_Name__c != null ? Partner.Partner__r.CDH_Party_Name__r.Name: '';
                orderPartner.id = Partner.Opportunity__c;
                
                //Contact
                //initializing integrationObject wrapper structure for contact here.
                orderPartner.contact = new IntegrationObjects.Contact();
                orderPartner.contact.FirstName = Partner.Partner_Contact__c != null ? Partner.Partner_Contact__r.firstName : '';
                orderPartner.contact.LastName = Partner.Partner_Contact__c != null ? Partner.Partner_Contact__r.lastName : '';
                orderPartner.contact.Phone = Partner.Partner_Contact__c != null ? Partner.Partner_Contact__r.Phone : '';
                orderPartner.contact.Email = Partner.Partner_Contact__c != null ? Partner.Partner_Contact__r.Email : '';
                orderPartner.contact.CDH_Party_Number = Partner.Partner_Contact__c != null ? Partner.Partner_Contact__r.CDH_Party_Number__c : '';
              
                //adding partner to the list.
                orderPartners.add(orderPartner);
            }
         
        //assigning the list of partners to the associated opportunity wrapper structure in integrationObjects.   
        orderObject.orderPartners = orderPartners;  
        }    
      //returns the opportunity to pass as a parameter to the outboundService class.       
      return orderObject;
    }
}