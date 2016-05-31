/*****************************************************************************************
    Name    : IntegrationObjectConverter
    Desc    : This class exists solely to convert standard SObjects into their integration
              object counterparts.
    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Tiaan Kruger        07/12/2014         Created
    Vipul Jain          15 JULY 2014       Trade style field was referring to custom field , which needs to be deleted , so updated the class to refer to standard
                                           Tradestyle field
    Neha Jaiswal        09 Oct 2014        Added code for classificatin that will hold the partner program details for an account related to US56528.
    Scott Coleman       07 Nov 2014        Added transformations for order Pay Now and Payment Type
    Scott Coleman       09 Dec 2014        Added order Contract Number
    Scott Coleman       22 Mar 2015        Updated convertSalesAccount correctly populate partner program data
    Bill Riemers        27 Aug 2015        Only if there is a master record send the status from that instead
    Bill Riemers        23 Oct 2015        Keep a map of converted opportunity ids, so we can reference values we don't copy...
******************************************************************************************/
public with sharing class IntegrationObjectConverter {

    //declaring final static variable to hold active & inactive status.
    public final static String activeStatus = 'Active';
    public final static String inactiveStatus = 'Inactive';
     public final static String approveStatus = 'Approved';
      
    public static IntegrationObjects.TransactionalAccount convertTransactionalAccount(EBS_Account__c ebsAccount){
        IntegrationObjects.TransactionalAccount tAccount = new IntegrationObjects.TransactionalAccount();

        tAccount.Account_Number = ebsAccount.Name;
        tAccount.Primary_EBS_Account = ebsAccount.Primary_EBS_Account__c;
        // only use the master records status, if defined
        tAccount.Status = ebsAccount.Status__c;
        if(ebsAccount.MasterRecord__r != null) {
            tAccount.Status = ebsAccount.MasterRecord__r.Status__c;
        }
        tAccount.Account_Type = ebsAccount.Account_Type__c;
        tAccount.Account_Description = ebsAccount.EBS_Account_Description__c;
        tAccount.CDH_Party_Number = ebsAccount.CDH_Party_Number__c;
        tAccount.PartyType = ebsAccount.Account_Type__c;
        tAccount.Name = ebsAccount.Name;
        tAccount.EBS_Party_Number = ebsAccount.EBS_Party_Number__c;
        tAccount.EBS_Party_Name = ebsAccount.EBS_Party_Name__c;
        tAccount.Sales_Account = ebsAccount.Sales_Account__c;
        tAccount.Sales_Channel = ebsAccount.Sales_channel__c;
        tAccount.Classification = ebsAccount.Classification__c;
        tAccount.Credit_hold = ebsAccount.Credit_Hold__c;
        tAccount.Last_Credit_Review_Date = ebsAccount.Last_Credit_Review_Date__c;
        tAccount.Next_Credit_Review_Date = ebsAccount.Next_Credit_Review_Date__c;
        tAccount.Credit_Review_Cycle = ebsAccount.Credit_Review_Cycle__c;

        return tAccount;
    }

    public static IntegrationObjects.SalesAccount convertSalesAccount(Account account) {
        return convertSalesAccount(account, null);
    }

    public static IntegrationObjects.SalesAccount convertSalesAccount(Account account, List<Partner_Program__c> partnerPrograms){
        IntegrationObjects.SalesAccount ioAccount = new IntegrationObjects.SalesAccount();

        ioAccount.IDs = account.Id;
        ioAccount.CDH_Party_Number = account.CDHPartyNumber__c;
        ioAccount.Name = account.Name;
        ioAccount.CDH_Party_Type = account.CDH_Party_Type__c;
        ioAccount.VATNumber = account.VATNumber__c;
        ioAccount.D_U_N_S = account.DunsNumber;
        ioAccount.Status = account.Status__c;
        ioAccount.Sic = account.Sic;
        ioAccount.SicDesc = account.SicDesc;
        ioAccount.All_NAICS_Codes = account.All_NAICS_Codes__c;
        ioAccount.Do_Not_Do_Business_with = account.Do_Not_Do_Business_With__c;
        ioAccount.SEA_Concern = account.SEA_Concern__c;
        ioAccount.Trade_Style = account.Tradestyle;
        ioAccount.YearStarted = account.YearStarted;
        ioAccount.NumberOfEmployees = account.NumberOfEmployees;
        ioAccount.AnnualRevenue = account.AnnualRevenue;
        ioAccount.Website = account.Website;
        ioAccount.Phone = account.Phone;
        ioAccount.Fax = account.Fax;
        ioAccount.Head_Quarters = account.Headquarters_CDH_Party_Number__c;
        ioAccount.Domestic_Ultimate = account.Domestic_Ultimate__c;
        ioAccount.Global_Ultimate = account.Global_Ultimate__c;
        ioAccount.Linkedin_URL = account.Linkedin_URL__c;

        if (account.Addresses__r != null && account.Addresses__r.size() > 0){
            ioAccount.addresses = new List<IntegrationObjects.Address>();
            for (Address__c address : account.Addresses__r){
                ioAccount.addresses.add(convertAddress(address));
            }
        }

        if (partnerPrograms != null && !partnerPrograms.isEmpty()){
            ioAccount.PartnerClassifications= new List<IntegrationObjects.Classification>();
            for (Partner_Program__c partnerProgram: partnerPrograms){
                ioAccount.PartnerClassifications.add(convertClassification(partnerProgram));
                ioAccount.PartnerClassifications.add(convertClassification(new Partner_Program__c(
                    Oracle_Classification_Code__c = partnerProgram.Program__r.Oracle_Classification_Code__c,
                    Status__c = partnerProgram.Status__c)));
            }
        }

        return ioAccount;
    }

    public static IntegrationObjects.Contact convertContact(Contact contact){
        IntegrationObjects.Contact ioContact = new IntegrationObjects.Contact();

        ioContact.IDs = contact.Id;
        ioContact.CDH_Party_Number = contact.CDH_Party_Number__c;
        ioContact.LoginName = contact.LoginName__c;
        ioContact.FirstName = contact.FirstName;
        ioContact.LastName = contact.LastName;
        ioContact.Salutation = contact.Salutation;
        // only use the master records status, if defined
        ioContact.Status = contact.Status__c;
        if(contact.MasterRecord__r != null) {
            ioContact.Status = contact.MasterRecord__r.Status__c;
        }
        ioContact.Email = contact.Email;
        ioContact.Phone = contact.Phone;
        ioContact.MobilePhone = contact.MobilePhone;
        ioContact.Fax = contact.Fax;
        ioContact.SalesAccount_Id = contact.AccountId;

        return ioContact;
    }
    
    public static IntegrationObjects.Classification convertClassification(Partner_Program__c classification){
        IntegrationObjects.Classification ioClassification = new IntegrationObjects.Classification();
        system.debug('codeStatus'+ioClassification.Code + ioClassification.Status);
        ioClassification.Code = classification.Oracle_Classification_Code__c;
        ioClassification.Status= classification.Status__c;
        system.debug('testddfsf'+ioClassification.Code + ioClassification.Status);
        if(ioClassification.Status != activeStatus && ioClassification.Status != approveStatus ){
            ioClassification.Status = inactiveStatus ;
            system.debug('status 1'+ioClassification.Status);
        }
        else{
           ioClassification.Status = activeStatus ; 
            system.debug('status 2'+ioClassification.Status);
        }
       return ioClassification;
    }

    public static IntegrationObjects.Address convertAddress(Address__c address){
        IntegrationObjects.Address ioAddress = new IntegrationObjects.Address();


        ioAddress.IDs = address.Id;
        ioAddress.CDH_Party_Site_Number = address.CDH_Party_Site_Number__c;
        ioAddress.Address_Line1 = address.Address_Line1__c;
        ioAddress.Address_Line2 = address.Address_Line2__c;
        ioAddress.Address_Line3 = address.Address_Line3__c;
        ioAddress.Address_Line4 = address.Address_Line4__c;
        ioAddress.City = address.City__c;
        ioAddress.State = address.State__c;
        ioAddress.Province = address.Province__c;
        ioAddress.Zip_Postal_Code = address.Zip_Postal_Code__c;
        ioAddress.County = address.County__c;
        ioAddress.Country = address.Country__c;
        ioAddress.Bill_To_Address = address.Bill_To_Address__c;
        ioAddress.Sold_To_Address = address.Sold_To_Address__c;
        ioAddress.Ship_To_Address = address.Ship_To_Address__c;
        ioAddress.Entitle_To_Address = address.Entitle_To_Address__c;
        ioAddress.Identifying_Address = address.Identifying_Address__c;
        // only use the master records status, if defined
        ioAddress.Status = address.Status__c;
        if(address.MasterRecord__r != null) {
            ioAddress.Status = address.MasterRecord__r.Status__c;
        }
        return ioAddress;
    }

    public static IntegrationObjects.OrderPartner convertOpportunityPartner(OpportunityPartner__c partner){
        IntegrationObjects.OrderPartner orderPartner = new IntegrationObjects.OrderPartner();

        orderPartner.id = partner.Id;
        orderPartner.partnerType = partner.PartnerTypeName__c;
        orderPartner.partnerTier = partner.PartnerTierName__c;
        orderPartner.classificationCode = partner.Oracle_Classification_Code__c ;
        orderPartner.transactionRole = partner.RelationshipType__c;
        /*
        orderPartner.contact = convertContact(partner.Partner_Contact__r);
        */
        if (partner.Partner__r != null){
            orderPartner.account = convertSalesAccount(partner.Partner__r);
        }

        return orderPartner;
    }

    public static IntegrationObjects.OrderLine convertOrderOpportunityLineItem(OpportunityLineItem line){
        IntegrationObjects.OrderLine orderLine = new IntegrationObjects.OrderLine();

        orderLine.id = line.Id;
        orderLine.productCode  = line.PricebookEntry.Product2.ProductCode;
        orderLine.actualStartDate  = line.ActualStartDate__c;
        orderLine.actualEndDate  = line.ActualEndDate__c;
        if (line.Quantity == null){
            orderLine.quantity = 0 ;
        }
        else{
            orderLine.quantity = line.Quantity;
        }        
        orderLine.unitOfMeasure  = line.PricebookEntry.Product2.Unit_Of_Measure__c;
        if (line.UnitPrice == null){
            orderLine.perUnitProratedPrice = 0 ;
        }
        else{
            orderLine.perUnitProratedPrice = line.UnitPrice;
        }
        if (line.Adjusted_Price__c == null){
            orderLine.salesPrice = 0 ;
        }
        else
        {
            orderLine.salesPrice = line.Adjusted_Price__c;
        }
        orderLine.currencyIsoCode = line.CurrencyIsoCode;
        orderLine.contractNumbers  = line.Contract_Numbers__c;
        orderLine.opportunityId  = line.Opportunity.Id;
        orderLine.opportunityLineId = line.Id;
        if (line.Price_After_Discretionary_Discount__c == null){
            orderLine.discretionaryDiscountedPrice = 0 ;
        }
        else{
            orderLine.discretionaryDiscountedPrice = line.Price_After_Discretionary_Discount__c;
        }
        if (line.YearlySalesPrice__c == null){
            orderLine.oneTimeDiscountedPrice = 0 ;
        }
        else{
            orderLine.oneTimeDiscountedPrice = line.YearlySalesPrice__c;
        }
        orderLine.installBaseNumber = line.Install_Base_Number__c;
        orderLine.priceOverrideReason = line.PriceOverrideReason__c;

        if (line.Entitle_To_Account__r != null){
            orderLine.entitleToAccount = convertTransactionalAccount(line.Entitle_To_Account__r);
        }
        orderLine.priceOverrideReason = line.PriceOverrideReason__c;
        if (line.Entitle_To_Address__r != null){
            orderLine.entitleToAddress = convertAddress(line.Entitle_To_Address__r);
        }
        if (line.Entitle_To_Contact__r != null){
            orderLine.entitleToContact = convertContact(line.Entitle_To_Contact__r);
        }

        return orderLine;
    }

    public static Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();

    public static IntegrationObjects.Order convertOpportunityToOrder(Opportunity header){
        IntegrationObjects.Order ioOrder = new IntegrationObjects.Order();
        oppMap.put(header.Id,header);

        ioOrder.ID = header.Id;
        ioOrder.orderID = header.OracleOrderID__c;
        ioOrder.orderNumber = header.OracleOrderNumber__c;
        ioOrder.employeeNumber = header.Owner.EmployeeNumber;
        ioOrder.opportunityNumber = header.OpportunityNumber__c;
        ioOrder.opportunityID = header.Id;
        ioOrder.purchaseOrderNumber = header.PONumber__c;
        ioOrder.orderType = header.Order_Type__c;
        ioOrder.operatingUnit = header.Operating_Unit__c;
        if(header.Pay_Now__c == 'Yes') {
            ioOrder.payNow = 'Y';
        }
        else if(header.Pay_Now__c == 'No') {
            ioOrder.payNow = 'N';
        }        
        if(header.PaymentType__c == 'Credit Card') {
            ioOrder.paymentType = 'CREDIT_CARD';
        }
        ioOrder.contractNumber = header.ContractNumber__c;
        ioOrder.fulfillmentChannel = header.FulfillmentChannel__c;
        ioOrder.orderSource = header.Deal_Source__c;
        ioOrder.currencyIsoCode = header.CurrencyIsoCode;
        ioOrder.resellerPurchaseOrder = header.Reseller_PO__c;
        ioOrder.creditCardNumber = header.Credit_Card_Number__c;
        ioOrder.expirationDate = header.ExpirationDate__c;
        ioOrder.creditCardType = header.CreditCardType__c;
        ioOrder.nameOnCard = header.NameOnCard__c;
        ioOrder.paymentTerms = header.PaymentTerms__c;
        ioOrder.amount = header.TotalAmount__c;
        ioOrder.shippingInstructions = header.Shipping_Instructions__c;
        ioOrder.vatcode = header.VAT_Code__c;
        ioOrder.rushOrder = header.Rush_Order__c;

        if (header.Non_Entitled_Endco__r != null) {
            ioOrder.nonEntitledEndcoCDHPartyName = header.Non_Entitled_Endco__r.Name;
            if (header.Non_Entitled_Endco__r.CDH_Party_Name__r != null) {
                ioOrder.nonEntitledEndcoCDHPartyNumber = header.Non_Entitled_Endco__r.CDH_Party_Name__r.Name;
            }
        }

        if (header.Sold_To_Account__r != null)
            ioOrder.soldToAccount = convertTransactionalAccount(header.Sold_To_Account__r);
        if (header.Bill_To_Account__r != null)
            ioOrder.billToAccount = convertTransactionalAccount(header.Bill_To_Account__r);
        if (header.Entitle_To_Account__r != null)
            ioOrder.entitleToAccount = convertTransactionalAccount(header.Entitle_To_Account__r);
        if (header.Ship_To_Account__r != null)
            ioOrder.shipToAccount = convertTransactionalAccount(header.Ship_To_Account__r);

        if (header.Sold_To_Address__r != null)
            ioOrder.soldToAddress = convertAddress(header.Sold_To_Address__r);
        if (header.Bill_To_Address__r != null)
            ioOrder.billToAddress = convertAddress(header.Bill_To_Address__r);
        if (header.Entitle_To_Address__r != null)
            ioOrder.entitleToAddress = convertAddress(header.Entitle_To_Address__r);
        if (header.Ship_To_Address__r != null)
            ioOrder.shipToAddress = convertAddress(header.Ship_To_Address__r);

        if (header.Sold_To_Contact__r != null)
            ioOrder.soldToContact = convertContact(header.Sold_To_Contact__r);
        if (header.Bill_To_Contact__r != null)
            ioOrder.billToContact = convertContact(header.Bill_To_Contact__r);
        if (header.Entitle_To_Contact__r != null)
            ioOrder.entitleToContact = convertContact(header.Entitle_To_Contact__r);
        if (header.Ship_To_Contact__r != null)
            ioOrder.shipToContact = convertContact(header.Ship_To_Contact__r);

        if (header.OpportunityLineItems != null && header.OpportunityLineItems.size() > 0){
            ioOrder.orderLines = new List<IntegrationObjects.OrderLine>();
            for (OpportunityLineItem line : header.OpportunityLineItems){
                ioOrder.orderLines.add(convertOrderOpportunityLineItem(line));
            }
        }
        if (header.OpportunityPartners2__r != null && header.OpportunityPartners2__r.size() > 0){
            ioOrder.orderPartners = new List<IntegrationObjects.OrderPartner>();
            for (OpportunityPartner__c partner : header.OpportunityPartners2__r){
                ioOrder.orderPartners.add(convertOpportunityPartner(partner));
            }
        }
        
        System.debug('ioOrder---->'+ioOrder);
        return ioOrder;
    }

}