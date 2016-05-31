/**
 * This test class is used to create the test data for various objects
 *
 * @author Vipul Jain <vipujain@DELOITTE.com>
 * @version 2014-10-01
 * 2014-10-01 - initial version
 */

public class TestUtil
{
    /**
    *Method to create CDH Party Data
    */
    public Static CDH_Party__c  getCDHParty (String cdhPartyNumber ,String partyType){
        
        CDH_Party__c cdhParty = new CDH_Party__c();
        cdhParty.Name  = CDHPartyNumber;
        cdhParty.CDH_Party_Name__c = 'CDH Party';
        cdhParty.CDH_Party_Number_Ext__c = CDHPartyNumber;
        cdhParty.CDH_Party_Type__c = partyType;
        return cdhParty;
    }
    /**
    *Method to create Address Data
    */
    public Static Address__c  getAddress (String cdhPartyNumber ,id sAccountID){
        
        Address__c addObj = new Address__c();
        addObj.CDH_Party_Site_Number__c=cdhPartyNumber;
        addObj.Sales_Account__c=sAccountID;
        return addObj;
    }
    
     /**
    *Method to create EBS Account Data
    */
    public Static EBS_Account__c  getEBSAcc (String AccName,id sAccountID,string CDHPartyNm){
        
        EBS_Account__c EBSAcc= new EBS_Account__c();
        EBSAcc.Name=AccName;
        EBSAcc.CDH_Party_Number__c=CDHPartyNm;
        EBSAcc.EBS_Account_External_Id__c=AccName;
        EBSAcc.Sales_Account__c=sAccountID;
        return EBSAcc;
    }
    
    /**
    *Method to create Account data.
    */
    
    public Static Account getAccount(String accountName){
        
        Account account = new Account();
        account.Name = accountName;
        return account;
    }
    
    /**
    *Method to create the contact data
    */
    
    public Static Contact getContact(String contactName , Account account){
        
        Contact contact = new Contact();
        contact.FirstName  = contactName;
        contact.LastName = 'Last Name';
        contact.accountId = account.Id;
        return contact; 
    }
    
    /**
    *Method to create the opportunity data
    */
    
    public Static Opportunity getOpportunity(String opportunityName , Account account){
        
        Opportunity opportunity = new Opportunity();
        opportunity.Name = opportunityName;
        opportunity.StageName = 'Prepare';
       // opportunity.Amount = 12345;
        opportunity.recordtypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('APAC Sales Opportunity').getRecordTypeId();
        opportunity.Type = 'Standard';
        opportunity.CloseDate = System.Today();
        opportunity.PaymentType__c = 'Credit Card';
        opportunity.FulfillmentChannel__c = 'Direct - End Customer';
        opportunity.Country_of_Order__c = 'Australia';
        opportunity.AccountId = account.Id;
        opportunity.CurrencyIsoCode = 'USD';
        opportunity.Pay_Now__c = 'Yes';
        opportunity.ForecastCategoryName = 'Pipeline';
        return opportunity;
    }
    
    public Static OpportunityLineItem getOpportunityLineItem(Opportunity opportunity ,Id pricebookEntryId){
        OpportunityLineItem OpportunityLineItem = new OpportunityLineItem();
        OpportunityLineItem.OpportunityId = opportunity.Id;
        OpportunityLineItem.PricebookEntryId = pricebookEntryId;

        return OpportunityLineItem;
    }
    
    /**
    *Method to create Opportunity Header Staging Data
    */
    
    public Static Opportunity_Header_Staging__c getDirectOpportunityHeaderStagingData(Opportunity opportunity, String status , String OrderStatus){
        
        Opportunity_Header_Staging__c opportunityHeaderStaging = new Opportunity_Header_Staging__c();
        opportunityHeaderStaging.Opportunity_ID__c = opportunity.Id;
        opportunityHeaderStaging.Order_Status__c = OrderStatus;
        opportunityHeaderStaging.Status__c = status;
        return opportunityHeaderStaging;
    }
    
    /**
    *Method to create the opportunity Line Staging records.
    */
    public Static Opportunity_Line_Staging__c getDirectOpportunityLineStagingData(Opportunity_Header_Staging__c opportunityHeaderStaging , OpportunityLineItem lineItem, String partyNumber){
        
        Opportunity_Line_Staging__c opportunityLineStaging = new Opportunity_Line_Staging__c();
        opportunityLineStaging.Opportunity_Product_ID__c =  lineItem.Id;
        opportunityLineStaging.Opportunity_Stage_Header_ID__c = opportunityHeaderStaging.Id;
        opportunityLineStaging.Entitle_To_Account_Number__c = partyNumber;
        opportunityLineStaging.Entitle_To_Address_Line_1__c = 'Line 1';
        opportunityLineStaging.Entitle_To_Address_Line_2__c = 'Line 2';
        opportunityLineStaging.Entitle_To_Address_Line_3__c = 'Line 3';
        opportunityLineStaging.Entitle_To_Address_Line_4__c = 'Line 4';
        opportunityLineStaging.Entitle_To_CDH_Party_Number_Account__c = partyNumber+string.valueof(0);
        opportunityLineStaging.Entitle_To_CDH_Party_Site_Number__c = partyNumber+string.valueof(1);
        opportunityLineStaging.Entitle_To_City__c = 'City';
        opportunityLineStaging.Entitle_To_CDH_Party_Number__c = partyNumber+ string.valueof(2);
        opportunityLineStaging.Entitle_To_Contact_Email__c = 'test@test.com';
        opportunityLineStaging.Entitle_To_Contact_First_Name__c = 'First Name';
        opportunityLineStaging.Entitle_To_Contact_Last_Name__c = 'Last';
        opportunityLineStaging.Entitle_To_Contact_Phone__c = '123456789';
        opportunityLineStaging.Entitle_To_Country__c = 'IN';
        opportunityLineStaging.Entitle_To_County__c = 'County';
        opportunityLineStaging.Entitle_To_Party_Name__c = 'Party Name';
        opportunityLineStaging.Entitle_To_Party_Number__c = partyNumber+string.valueof(3);
        opportunityLineStaging.Entitle_To_Party_Type__c = 'PERSON';
        opportunityLineStaging.Entitle_To_Province__c = 'Province';
        opportunityLineStaging.Entitle_To_State__c = 'State';
        opportunityLineStaging.Entitle_To_Zip_Postal_Code__c = '251ABC';
        return opportunityLineStaging;
        
    }
    
    /*
    *Method to create opportunity Line staging data
    */
    public Static Opportunity_Partner_Staging__c getPartnerStaging(Opportunity_Header_Staging__c opportunityHeaderStaging ,String cdhnumber){
        
        Opportunity_Partner_Staging__c  opportunityPartnerStaging = new Opportunity_Partner_Staging__c();
        opportunityPartnerStaging.CDH_Party_Number__c = cdhnumber;
        opportunityPartnerStaging.EBS_Account_Number__c = cdhnumber+string.valueof(0);
        opportunityPartnerStaging.Opportunity_Stage_Header_ID__c = opportunityHeaderStaging.id;
        opportunityPartnerStaging.Partner_Contact_CDH_Party_Number__c =  cdhnumber+string.valueof(1);
        opportunityPartnerStaging.Partner_Contact_Email__c = 'test@test.com';
        opportunityPartnerStaging.Partner_Contact_First_Name__c = 'First';
        opportunityPartnerStaging.Partner_Contact_Last_Name__c = 'Last';
        opportunityPartnerStaging.Oracle_Classification_Code__c = cdhnumber;
        return opportunityPartnerStaging;
        
    }
    /**
    *Method to create Opportunity Match Configuration data
    */
    public Static Opportunity_Match_Configuration__c getOpportunityMatchConfigurationData(String name , String operator, String value){
    
        Opportunity_Match_Configuration__c OpportunityMatchConfiguration = new Opportunity_Match_Configuration__c();
        OpportunityMatchConfiguration.Name = name;
        OpportunityMatchConfiguration.Operator__c = operator;
        OpportunityMatchConfiguration.Value__c = value;
        return OpportunityMatchConfiguration ;
    }
    
    /**
    *Method to insert the product record
    */
    public Static Product2 getProduct(String prductName){
        Product2 prod = new Product2(Name = prductName, 
            Family = 'Software');
        return prod;
    }
    
    /*
    *Method to insert pricebook entry
    */
    public Static PricebookEntry getPricebookEntry(Id pricebookId , Product2 productdetail){
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId , Product2Id = productdetail.Id,
            UnitPrice = 10000, IsActive = true);
        return standardPrice;
    }
    
    /*
    *Method to insert partner Program Tier
    */
    public Static Partner_Program_Tier__c getPartneraprogramTier(string orcaleOrNumber){

        /*Classification__c c= new Classification__c();
        c.Name='Partner Tier';
        insert c;
        Classification__c c1= new Classification__c();
        c1.Name='Partner Tier';
        c1.Parent__c=c.id;
        insert c1;
        Classification__c c2= new Classification__c();
        c2.Name='Partner Tier';
        c2.Parent__c=c1.id;
        insert c2;
        
        Classification__c cType= new Classification__c();
        cType.Name='Partner Type';
        insert cType;
        
        Classification__c cType1= new Classification__c();
        cType1.Name='Partner Type';
        cType1.Parent__c=cType.id;
        insert cType1;
        
        Classification__c cType2= new Classification__c();
        cType2.Name='Partner Type';
        cType2.Parent__c=cType1.id;
        insert cType2;
        
        Partner_Program_Definition__c ppd= new Partner_Program_Definition__c();
        ppd.Legacy_Partner_Type__c=cType2.id;
        insert ppd;
        
        Partner_Program_Tier__c ppt= new Partner_Program_Tier__c();
        ppt.Oracle_Classification_Code__c=orcaleOrNumber;
        ppt.IS_Active__c=true;
        ppt.Order__c=1;
        //ppt.Legacy_Partner_Tier__c=c2.id; 
        ppt.Legacy_Partner_Tier__c=cType2.id; //changed by Niti
        ppt.Partner_Program_Definition__c=ppd.id;
        return ppt;
        */
         Classification__c clssInst = new Classification__c();
            clssInst.Name = 'Partner Tier';
            clssInst.IsActive__c = TRUE;
            clssInst.IsInlineEdit__c = TRUE;
            
            insert clssInst;
            
            Classification__c clssInst1 = new Classification__c();
            clssInst1.Name = 'Partner Type';
            clssInst1.IsActive__c = TRUE;
            clssInst1.IsInlineEdit__c = TRUE;
            clssInst1.Parent__c = clssInst.Id;
            
            insert clssInst1;
            
            Classification__c clssInst2 = new Classification__c();
            clssInst2.Name = 'Partner Type';
            clssInst2.IsActive__c = TRUE;
            clssInst2.IsInlineEdit__c = TRUE;
            
            insert clssInst2;
            
            Classification__c clssInst3 = new Classification__c();
            clssInst3.Name = 'Partner Type';
            clssInst3.IsActive__c = TRUE;
            clssInst3.IsInlineEdit__c = TRUE;
            clssInst3.Parent__c = clssInst2.Id;
            
            insert clssInst3;
            
            Partner_Program_Definition__c ppdInst = new Partner_Program_Definition__c();
            ppdInst.Partner_Tier__c = 'Test Tier';
            ppdInst.Partner_Type__c = 'Test Type';
            ppdInst.Global_Region__c = 'Test Region';
            ppdInst.Is_Primary_Eligible__c = TRUE;
            ppdInst.Legacy_Partner_Type__c = clssInst3.Id;
            ppdInst.Oracle_Classification_Code__c = '987987';
            ppdInst.Program_Category__c = 'Test Catagory';
            ppdInst.Program_Status__c = 'Active';
            ppdInst.Requires_Approval__c = FALSE;
            
            insert ppdInst;
            
            Partner_Program_Tier__c pptInst = new Partner_Program_Tier__c();
            pptInst.Name = 'Test Tier';
            pptInst.Is_Active__c = TRUE;
            pptInst.Legacy_Partner_Tier__c = clssInst1.Id;
            pptInst.Oracle_Classification_Code__c = orcaleOrNumber;
            pptInst.Partner_Program_Definition__c = ppdInst.Id;
            pptInst.Tier__c = 'test';
            pptInst.Order__c = 987;
            
            //insert pptInst;
            return pptInst;
    }
    /*
    *Method to get the details of opportunity header staging data
    */
    public Static Opportunity_Header_Staging__c  getHeaderStagingData(Id stagingRecordId){
        Opportunity_Header_Staging__c resultStaging = new Opportunity_Header_Staging__c();
                resultStaging = [Select
                Bill_To_Account_Number__c,
                Bill_To_Account__c,
                Bill_To_Address_CDH_Party_Site_Number__c,
                Bill_To_Address_Line_1__c,
                Bill_To_Address_Line_2__c,
                Bill_To_Address_Line_3__c,
                Bill_To_Address_Line_4__c,
                Bill_To_Address__c,
                Bill_To_CDH_Party_Number__c,
                Bill_To_City__c,
                Bill_To_Contact_Email__c,
                Bill_To_Contact_First_Name__c,
                Bill_To_Contact_Last_Name__c,
                Bill_To_Contact_Phone__c,
                Bill_To_Contact__c,
                Bill_To_Country__c,
                Bill_To_County__c,
                Bill_To_Party_Name__c,
                Bill_To_Party_Number__c,
                Bill_To_Party_Type__c,
                Bill_To_Province__c,
                Bill_To_Sales_Account__c,
                Bill_To_State__c,
                Bill_To_Zip_Postal_Code__c,
                Channel__c,
                CurrencyIsoCode,
                Date_Ordered__c,
                Employee_Number__c,
                Entitle_To_Account_Number__c,
                Entitle_To_Account__c,
                Entitle_To_Address_CDH_Party_Site_Number__c,
                Entitle_To_Address_Line_1__c,
                Entitle_To_Address_Line_2__c,
                Entitle_To_Address_Line_3__c,
                Entitle_To_Address_Line_4__c,
                Entitle_To_Address__c,
                Entitle_To_CDH_Party_Number__c,
                Entitle_To_City__c,
                Entitle_To_Contact_Email__c,
                Entitle_To_Contact_First_Name__c,
                Entitle_To_Contact_Last_Name__c,
                Entitle_To_Contact_Phone__c,
                Entitle_To_Contact__c,
                Entitle_To_Country__c,
                Entitle_To_County__c,
                Entitle_To_Party_Name__c,
                Entitle_To_Party_Number__c,
                Entitle_To_Party_Type__c,
                Entitle_To_Province__c,
                Entitle_To_Sales_Account__c,
                Entitle_To_State__c,
                Entitle_To_Zip_Postal_Code__c,
                LastModifiedDate,
                Name,
                Operating_Unit__c,
                Opportunity_ID__c,
                Opportunity_Name__c,
                Opportunity_Number__c,
                Opportunity_Owner__c,
                Oracle_Order_ID__c,
                Oracle_Order_Number__c,
                Order_Last_Update_Date__c,
                Order_Source__c,
                Order_Status__c,
                Order_Type__c,
                OwnerId,
                Payment_Type__c,
                PO_Number__c,
                Resller_PO__c,
                Sales_Account__c,
                Ship_To_Account_Number__c,
                Ship_To_Account__c,
                Ship_To_Address_CDH_Party_Site_Number__c,
                Ship_To_Address_Line_1__c,
                Ship_To_Address_Line_2__c,
                Ship_To_Address_Line_3__c,
                Ship_To_Address_Line_4__c,
                Ship_To_Address__c,
                Ship_To_CDH_Party_Number__c,
                Ship_To_City__c,
                Ship_To_Contact_Email__c,
                Ship_To_Contact_First_Name__c,
                Ship_To_Contact_Last_Name__c,
                Ship_To_Contact_Phone__c,
                Ship_To_Contact__c,
                Ship_To_Country__c,
                Ship_To_County__c,
                Ship_To_Party_Name__c,
                Ship_To_Party_Number__c,
                Ship_To_Party_Type__c,
                Ship_To_Province__c,
                Ship_To_Sales_Account__c,
                Ship_To_State__c,
                Ship_To_Zip_Postal_Code__c,
                Sold_To_Account_Number__c,
                Sold_To_Account__c,
                Sold_To_Address_CDH_Party_Site_Number__c,
                Sold_To_Address_Line_1__c,
                Sold_To_Address_Line_2__c,
                Sold_To_Address_Line_3__c,
                Sold_To_Address_Line_4__c,
                Sold_To_Address__c,
                Sold_To_CDH_Party_Number__c,
                Sold_To_City__c,
                Sold_To_Contact_Email__c,
                Sold_To_Contact_First_Name__c,
                Sold_To_Contact_Last_Name__c,
                Sold_To_Contact_Phone__c,
               Status__c,
                Sold_To_Contact__c,
                Sold_To_Country__c,
                Sold_To_County__c,
                Sold_To_Party_Name__c,
                Sold_To_Party_Number__c,
                Sold_To_Party_Type__c,
                Sold_To_Province__c,
                Sold_To_Sales_Account__c,
                Sold_To_State__c,
                Sold_To_Zip_Postal_Code__c,
                Bill_To_CDH_Party_Number_Account__c,
                ship_To_CDH_Party_Number_Account__c,
                Sold_To_CDH_Party_Number_Account__c,
                Entitle_To_CDH_Party_Number_Account__c,
                Amount__c, 
                Non_Entitled_Endco_CDH_Party_Number__c,
                Non_Entitled_Endco__c,                
                (SELECT ActualEndDate__c,ActualStartDate__c,Adjusted_Price__c,Base_Price__c,Contract_Numbers__c,CurrencyIsoCode,Entitle_To_Account_Number__c,
                Entitle_To_Account__c,Entitle_To_Address_Line_1__c,Entitle_To_Address_Line_2__c,Entitle_To_Address_Line_3__c,Entitle_To_Address_Line_4__c,
                Entitle_To_Address__c,Entitle_To_CDH_Party_Number_Account__c,Entitle_To_CDH_Party_Number__c,Entitle_To_CDH_Party_Site_Number__c,
                Entitle_To_City__c,Entitle_To_Contact_Email__c,Entitle_To_Contact_First_Name__c,Entitle_To_Contact_Last_Name__c,Entitle_To_Contact_Phone__c,
                Entitle_To_Contact__c,Entitle_To_Country__c,Entitle_To_County__c,Entitle_To_Party_Name__c,Entitle_To_Party_Number__c,Entitle_To_Party_Type__c,
                Entitle_To_Province__c,Entitle_to_Sales_Account__c,Entitle_To_State__c,Entitle_To_Zip_Postal_Code__c,Id,Install_Base_Number__c,Name,
                Opportunity_ID__c,Opportunity_Number__c,Opportunity_Product_ID__c,Opportunity_Stage_Header_ID__c,Oracle_Order_Header_Id__c,Product_Code_Oracle__c,
                Product_Code__c,Quantity__c,Return_Reason_Code__c,SystemModstamp,Total_Price__c,UnitPrice__c,Unit_of_Measure__c,Opportunity_Stage_Header_ID__r.Order_Source__c, 
                Opportunity_Stage_Header_ID__r.Opportunity_Number__c,Opportunity_Stage_Header_ID__r.Opportunity_ID__c,Opportunity_Stage_Header_ID__r.CurrencyIsoCode
                FROM Opportunities_Line_Staging__r),
                (SELECT CDH_Party_Number__c,EBS_Account_Number__c,Id,Name,Opportunity_Stage_Header_ID__c,Oracle_Order_Header_Id__c,PartnerTier__c,Partner_Contact_CDH_Party_Number__c,Partner_Contact_Email__c,Partner_Contact_First_Name__c,Partner_Contact_Last_Name__c,Partner_Contact_Phone__c,Partner_Contact__c,Partner_Sales_Account__c,Partner_Sub_Type__c,Partner_Type__c,RelationshipType__c,Oracle_Classification_Code__c FROM Opportunities_Partner_Staging__r)
            from Opportunity_Header_Staging__c
            where id= :stagingRecordId
            ];
        return resultStaging;
    }
}