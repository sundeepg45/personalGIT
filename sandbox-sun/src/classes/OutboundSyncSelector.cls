/*****************************************************************************************
    Name    : OutboundSyncSelector
    Desc    : This class selects the data used for outbound sync messages

    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Scott Coleman          11 Sep 2014      Created
    Scott Coleman          09 Dec 2014      Added ContractNumber__c to opp query
    Scott Coleman          22 Mar 2015      Added support for account sync by CDH party number, added getPartnerProgramData()
    Bill C Riemers         27 Aug 2015      Added MasterRecord__r.Status__c to the queries
    Bill C Riemers         11 Sep 2015      Added filter for MasterRecord__r.Id values.
******************************************************************************************/
public without sharing class OutboundSyncSelector {

    public static Account getAccountData(Id accountId) {
        return getAccountData(accountId, null);
    }

    public static Account getAccountData(String cdhPartyNumber) {
        return getAccountData(null, cdhPartyNumber);
    }

    private static Account getAccountData(Id accountId, String cdhPartyNumber) {
        Account account;
        List<Account> accounts = [
            SELECT
                Id,
                CDHPartyNumber__c,
                CDH_Party_Number__c,
                Name,
                CDH_Party_Type__c,
                VATNumber__c,
                DunsNumber,
                Status__c,
                Sic,
                SicDesc,
                All_NAICS_Codes__c,
                Do_Not_Do_Business_With__c,
                SEA_Concern__c,
                Tradestyle,
                YearStarted,
                NumberOfEmployees,
                AnnualRevenue,
                Website,
                Phone,
                Fax,
                Headquarters_CDH_Party_Number__c,
                Domestic_Ultimate__c,
                Global_Ultimate__c,
                Linkedin_URL__c,
                (
                    SELECT
                        Id,
                        CDH_Party_Site_Number__c,
                        Address_Line1__c,
                        Address_Line2__c,
                        Address_Line3__c,
                        Address_Line4__c,
                        City__c,
                        State__c,
                        Province__c,
                        Zip_Postal_Code__c,
                        County__c,
                        Country__c,
                        Bill_To_Address__c,
                        Sold_To_Address__c,
                        Ship_To_Address__c,
                        Entitle_To_Address__c,
                        Identifying_Address__c,
                        MasterRecord__r.Status__c,
                        Status__c
                    FROM Account.Addresses__r
                    WHERE MasterRecord__r.Id = null
                    ORDER BY Status__c asc nulls first,
                        Identifying_Address__c nulls last
                )
            FROM Account
            WHERE (Id = :accountId
                OR (CDHPartyNumber__c = :cdhPartyNumber AND CDHPartyNumber__c != null))
                AND RecordType.Name not in ('NA Partner', 'EMEA Partner', 'APAC Partner', 'LATAM Partner')
            ORDER BY CreatedDate ASC        
            LIMIT 1
        ];

        if(!accounts.isEmpty()) {
            account = accounts[0];
        }

        return account;
    }

    public static List<Partner_Program__c> getPartnerProgramData(String cdhPartyNumber) {
        List<Partner_Program__c> partnerProgramMemberships = new List<Partner_Program__c>();
        partnerProgramMemberships = [
            SELECT
                Name,
                Oracle_Classification_Code__c,
                Program__c,
                Program__r.Oracle_Classification_Code__c,
                Account__r.CDHPartyNumber__c,
                Program__r.Program_Category__c,
                Status__c,
                Tier__c
            FROM Partner_Program__c
            WHERE
                Account__r.CDHPartyNumber__c = :cdhPartyNumber
                and Status__c in ('Active', 'Approved')
            ];

        return partnerProgramMemberships;
    }

    public static Contact getContactData(Id contactId) {
        Contact contact;
        List<Contact> contacts = [
            SELECT
                Id,
                AccountId,
                CDH_Party_Number__c,
                LoginName__c,
                FirstName,
                LastName,
                Salutation,
                MasterRecord__r.Status__c,
                Status__c,
                Email,
                Phone,
                MobilePhone,
                Fax
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];

        if(!contacts.isEmpty()) {
            contact = contacts[0];
        }
        return contact;
    }

    public static Opportunity getOpportunityData(Id opportunityId) {
        return getOpportunityData(opportunityId, null);
    }

    public static Opportunity getOpportunityData(String opportunityNumber) {
        return getOpportunityData(null, opportunityNumber);
    }

    private static Opportunity getOpportunityData(Id opportunityId, String opportunityNumber) {
        Opportunity opportunity;
        List<Opportunity> opportunities = [
            SELECT
                Id,
                Name,
                OracleOrderID__c,
                OracleOrderNumber__c,
                Owner.EmployeeNumber,
                OpportunityNumber__c,
                PONumber__c,
                Order_Type__c,
                Operating_Unit__c,
                PaymentType__c,
                Pay_Now__c,
                ContractNumber__c,
                FulfillmentChannel__c,
                Deal_Source__c,
                CurrencyIsoCode,
                Reseller_PO__c,
                Credit_Card_Number__c,
                ExpirationDate__c,
                CreditCardType__c,
                NameOnCard__c,
                PaymentTerms__c,
                TotalAmount__c,
                Shipping_Instructions__c,
                VAT_Code__c,
                Rush_Order__c,
                Non_Entitled_Endco__r.Name,
                Non_Entitled_Endco__r.CDH_Party_Name__r.Name,
                Sold_To_Account__r.MasterRecord__r.Status__c,
                Sold_To_Account__r.Name,
                Sold_To_Account__r.Primary_EBS_Account__c,
                Sold_To_Account__r.Status__c,
                Sold_To_Account__r.Account_Type__c,
                Sold_To_Account__r.EBS_Account_Description__c,
                Sold_To_Account__r.CDH_Party_Number__c,
                Sold_To_Account__r.EBS_Party_Number__c,
                Sold_To_Account__r.EBS_Party_Name__c,
                Sold_To_Account__r.Sales_Account__c,
                Sold_To_Account__r.Sales_channel__c,
                Sold_To_Account__r.Classification__c,
                Sold_To_Account__r.Credit_Hold__c,
                Sold_To_Account__r.Last_Credit_Review_Date__c,
                Sold_To_Account__r.Next_Credit_Review_Date__c,
                Sold_To_Account__r.Credit_Review_Cycle__c,
                Bill_To_Account__r.MasterRecord__r.Status__c,
                Bill_To_Account__r.Name,
                Bill_To_Account__r.Primary_EBS_Account__c,
                Bill_To_Account__r.Status__c,
                Bill_To_Account__r.Account_Type__c,
                Bill_To_Account__r.EBS_Account_Description__c,
                Bill_To_Account__r.CDH_Party_Number__c,
                Bill_To_Account__r.EBS_Party_Number__c,
                Bill_To_Account__r.EBS_Party_Name__c,
                Bill_To_Account__r.Sales_Account__c,
                Bill_To_Account__r.Sales_channel__c,
                Bill_To_Account__r.Classification__c,
                Bill_To_Account__r.Credit_Hold__c,
                Bill_To_Account__r.Last_Credit_Review_Date__c,
                Bill_To_Account__r.Next_Credit_Review_Date__c,
                Bill_To_Account__r.Credit_Review_Cycle__c,
                Entitle_To_Account__r.MasterRecord__r.Status__c,
                Entitle_To_Account__r.Name,
                Entitle_To_Account__r.Primary_EBS_Account__c,
                Entitle_To_Account__r.Status__c,
                Entitle_To_Account__r.Account_Type__c,
                Entitle_To_Account__r.EBS_Account_Description__c,
                Entitle_To_Account__r.CDH_Party_Number__c,
                Entitle_To_Account__r.EBS_Party_Number__c,
                Entitle_To_Account__r.EBS_Party_Name__c,
                Entitle_To_Account__r.Sales_Account__c,
                Entitle_To_Account__r.Sales_channel__c,
                Entitle_To_Account__r.Classification__c,
                Entitle_To_Account__r.Credit_Hold__c,
                Entitle_To_Account__r.Last_Credit_Review_Date__c,
                Entitle_To_Account__r.Next_Credit_Review_Date__c,
                Entitle_To_Account__r.Credit_Review_Cycle__c,
                Ship_To_Account__r.MasterRecord__r.Status__c,
                Ship_To_Account__r.Name,
                Ship_To_Account__r.Primary_EBS_Account__c,
                Ship_To_Account__r.Status__c,
                Ship_To_Account__r.Account_Type__c,
                Ship_To_Account__r.EBS_Account_Description__c,
                Ship_To_Account__r.CDH_Party_Number__c,
                Ship_To_Account__r.EBS_Party_Number__c,
                Ship_To_Account__r.EBS_Party_Name__c,
                Ship_To_Account__r.Sales_Account__c,
                Ship_To_Account__r.Sales_channel__c,
                Ship_To_Account__r.Classification__c,
                Ship_To_Account__r.Credit_Hold__c,
                Ship_To_Account__r.Last_Credit_Review_Date__c,
                Ship_To_Account__r.Next_Credit_Review_Date__c,
                Ship_To_Account__r.Credit_Review_Cycle__c,
                Sold_To_Address__r.Id,
                Sold_To_Address__r.Sales_Account__r.Name,
                Sold_To_Address__r.CDH_Party_Site_Number__c,
                Sold_To_Address__r.Address_Line1__c,
                Sold_To_Address__r.Address_Line2__c,
                Sold_To_Address__r.Address_Line3__c,
                Sold_To_Address__r.Address_Line4__c,
                Sold_To_Address__r.City__c,
                Sold_To_Address__r.State__c,
                Sold_To_Address__r.Province__c,
                Sold_To_Address__r.Zip_Postal_Code__c,
                Sold_To_Address__r.County__c,
                Sold_To_Address__r.Country__c,
                Sold_To_Address__r.Bill_To_Address__c,
                Sold_To_Address__r.Sold_To_Address__c,
                Sold_To_Address__r.Ship_To_Address__c,
                Sold_To_Address__r.Entitle_To_Address__c,
                Sold_To_Address__r.Identifying_Address__c,
                Sold_To_Address__r.MasterRecord__r.Status__c,
                Sold_To_Address__r.Status__c,
                Bill_To_Address__r.Id,
                Bill_To_Address__r.Sales_Account__r.Name,
                Bill_To_Address__r.CDH_Party_Site_Number__c,
                Bill_To_Address__r.Address_Line1__c,
                Bill_To_Address__r.Address_Line2__c,
                Bill_To_Address__r.Address_Line3__c,
                Bill_To_Address__r.Address_Line4__c,
                Bill_To_Address__r.City__c,
                Bill_To_Address__r.State__c,
                Bill_To_Address__r.Province__c,
                Bill_To_Address__r.Zip_Postal_Code__c,
                Bill_To_Address__r.County__c,
                Bill_To_Address__r.Country__c,
                Bill_To_Address__r.Bill_To_Address__c,
                Bill_To_Address__r.Sold_To_Address__c,
                Bill_To_Address__r.Ship_To_Address__c,
                Bill_To_Address__r.Entitle_To_Address__c,
                Bill_To_Address__r.Identifying_Address__c,
                Bill_To_Address__r.MasterRecord__r.Status__c,
                Bill_To_Address__r.Status__c,
                Entitle_To_Address__r.Id,
                Entitle_To_Address__r.Sales_Account__r.Name,
                Entitle_To_Address__r.CDH_Party_Site_Number__c,
                Entitle_To_Address__r.Address_Line1__c,
                Entitle_To_Address__r.Address_Line2__c,
                Entitle_To_Address__r.Address_Line3__c,
                Entitle_To_Address__r.Address_Line4__c,
                Entitle_To_Address__r.City__c,
                Entitle_To_Address__r.State__c,
                Entitle_To_Address__r.Province__c,
                Entitle_To_Address__r.Zip_Postal_Code__c,
                Entitle_To_Address__r.County__c,
                Entitle_To_Address__r.Country__c,
                Entitle_To_Address__r.Bill_To_Address__c,
                Entitle_To_Address__r.Sold_To_Address__c,
                Entitle_To_Address__r.Ship_To_Address__c,
                Entitle_To_Address__r.Entitle_To_Address__c,
                Entitle_To_Address__r.Identifying_Address__c,
                Entitle_To_Address__r.MasterRecord__r.Status__c,
                Entitle_To_Address__r.Status__c,
                Ship_To_Address__r.Id,
                Ship_To_Address__r.Sales_Account__r.Name,
                Ship_To_Address__r.CDH_Party_Site_Number__c,
                Ship_To_Address__r.Address_Line1__c,
                Ship_To_Address__r.Address_Line2__c,
                Ship_To_Address__r.Address_Line3__c,
                Ship_To_Address__r.Address_Line4__c,
                Ship_To_Address__r.City__c,
                Ship_To_Address__r.State__c,
                Ship_To_Address__r.Province__c,
                Ship_To_Address__r.Zip_Postal_Code__c,
                Ship_To_Address__r.County__c,
                Ship_To_Address__r.Country__c,
                Ship_To_Address__r.Bill_To_Address__c,
                Ship_To_Address__r.Sold_To_Address__c,
                Ship_To_Address__r.Ship_To_Address__c,
                Ship_To_Address__r.Entitle_To_Address__c,
                Ship_To_Address__r.Identifying_Address__c,
                Ship_To_Address__r.MasterRecord__r.Status__c,
                Ship_To_Address__r.Status__c,
                Sold_To_Contact__r.Id,
                Sold_To_Contact__r.AccountId,
                Sold_To_Contact__r.CDH_Party_Number__c,
                Sold_To_Contact__r.LoginName__c,
                Sold_To_Contact__r.FirstName,
                Sold_To_Contact__r.LastName,
                Sold_To_Contact__r.Salutation,
                Sold_To_Contact__r.MasterRecord__r.Status__c,
                Sold_To_Contact__r.Status__c,
                Sold_To_Contact__r.Email,
                Sold_To_Contact__r.Phone,
                Sold_To_Contact__r.MobilePhone,
                Sold_To_Contact__r.Fax,
                Bill_To_Contact__r.Id,
                Bill_To_Contact__r.AccountId,
                Bill_To_Contact__r.CDH_Party_Number__c,
                Bill_To_Contact__r.LoginName__c,
                Bill_To_Contact__r.FirstName,
                Bill_To_Contact__r.LastName,
                Bill_To_Contact__r.Salutation,
                Bill_To_Contact__r.MasterRecord__r.Status__c,
                Bill_To_Contact__r.Status__c,
                Bill_To_Contact__r.Email,
                Bill_To_Contact__r.Phone,
                Bill_To_Contact__r.MobilePhone,
                Bill_To_Contact__r.Fax,
                Entitle_To_Contact__r.Id,
                Entitle_To_Contact__r.AccountId,
                Entitle_To_Contact__r.CDH_Party_Number__c,
                Entitle_To_Contact__r.LoginName__c,
                Entitle_To_Contact__r.FirstName,
                Entitle_To_Contact__r.LastName,
                Entitle_To_Contact__r.Salutation,
                Entitle_To_Contact__r.MasterRecord__r.Status__c,
                Entitle_To_Contact__r.Status__c,
                Entitle_To_Contact__r.Email,
                Entitle_To_Contact__r.Phone,
                Entitle_To_Contact__r.MobilePhone,
                Entitle_To_Contact__r.Fax,
                Ship_To_Contact__r.Id,
                Ship_To_Contact__r.AccountId,
                Ship_To_Contact__r.CDH_Party_Number__c,
                Ship_To_Contact__r.LoginName__c,
                Ship_To_Contact__r.FirstName,
                Ship_To_Contact__r.LastName,
                Ship_To_Contact__r.Salutation,
                Ship_To_Contact__r.MasterRecord__r.Status__c,
                Ship_To_Contact__r.Status__c,
                Ship_To_Contact__r.Email,
                Ship_To_Contact__r.Phone,
                Ship_To_Contact__r.MobilePhone,
                Ship_To_Contact__r.Fax,
                (
                    SELECT
                        Id,
                        PricebookEntry.Product2.ProductCode,
                        PricebookEntry.Product2.Unit_Of_Measure__c,
                        ActualStartDate__c,
                        ActualEndDate__c,
                        Adjusted_Price__c,
                        CurrencyIsoCode,
                        Contract_Numbers__c,
                        Opportunity.Id,
                        Quantity,
                        Install_Base_Number__c,
                        Entitle_To_Account__r.MasterRecord__r.Status__c,
                        Entitle_To_Account__r.Name,
                        Entitle_To_Account__r.Primary_EBS_Account__c,
                        Entitle_To_Account__r.Status__c,
                        Entitle_To_Account__r.Account_Type__c,
                        Entitle_To_Account__r.EBS_Account_Description__c,
                        Entitle_To_Account__r.CDH_Party_Number__c,
                        Entitle_To_Account__r.EBS_Party_Number__c,
                        Entitle_To_Account__r.EBS_Party_Name__c,
                        Entitle_To_Account__r.Sales_Account__c,
                        Entitle_To_Account__r.Sales_channel__c,
                        Entitle_To_Account__r.Classification__c,
                        Entitle_To_Account__r.Credit_Hold__c,
                        Entitle_To_Account__r.Last_Credit_Review_Date__c,
                        Entitle_To_Account__r.Next_Credit_Review_Date__c,
                        Entitle_To_Account__r.Credit_Review_Cycle__c,
                        PriceOverrideReason__c,
                        Entitle_To_Address__r.Id,
                        Entitle_To_Address__r.CDH_Party_Site_Number__c,
                        Entitle_To_Address__r.Address_Line1__c,
                        Entitle_To_Address__r.Address_Line2__c,
                        Entitle_To_Address__r.Address_Line3__c,
                        Entitle_To_Address__r.Address_Line4__c,
                        Entitle_To_Address__r.City__c,
                        Entitle_To_Address__r.State__c,
                        Entitle_To_Address__r.Province__c,
                        Entitle_To_Address__r.Zip_Postal_Code__c,
                        Entitle_To_Address__r.County__c,
                        Entitle_To_Address__r.Country__c,
                        Entitle_To_Address__r.Bill_To_Address__c,
                        Entitle_To_Address__r.Sold_To_Address__c,
                        Entitle_To_Address__r.Ship_To_Address__c,
                        Entitle_To_Address__r.Entitle_To_Address__c,
                        Entitle_To_Address__r.Identifying_Address__c,
                        Entitle_To_Address__r.MasterRecord__r.Status__c,
                        Entitle_To_Address__r.Status__c,
                        Entitle_To_Contact__r.Id,
                        Entitle_To_Contact__r.AccountId,
                        Entitle_To_Contact__r.CDH_Party_Number__c,
                        Entitle_To_Contact__r.LoginName__c,
                        Entitle_To_Contact__r.FirstName,
                        Entitle_To_Contact__r.LastName,
                        Entitle_To_Contact__r.Salutation,
                        Entitle_To_Contact__r.MasterRecord__r.Status__c,
                        Entitle_To_Contact__r.Status__c,
                        Entitle_To_Contact__r.Email,
                        Entitle_To_Contact__r.Phone,
                        Entitle_To_Contact__r.MobilePhone,
                        Entitle_To_Contact__r.Fax,
                        UnitPrice,
                        Base_Price__c,
                        Discretionary_Discount_Amount__c,
                        Price_After_Discretionary_Discount__c,
                        One_Time_Discount__c,
                        Price_After_One_Time_Discount__c,
                        YearlySalesPrice__c
                    FROM
                        OpportunityLineItems
                    ORDER BY
                        CreatedDate
                ),
                (
                    SELECT
                        Id,
                        Oracle_Classification_Code__c,
                        PartnerTypeName__c,
                        PartnerTierName__c,
                        RelationshipType__c,
                        Partner__r.Id,
                        Partner__r.CDHPartyNumber__c,
                        Partner__r.CDH_Party_Number__c,
                        Partner__r.Name,
                        Partner__r.CDH_Party_Type__c,
                        Partner__r.VATNumber__c,
                        Partner__r.DunsNumber,
                        Partner__r.Status__c,
                        Partner__r.Sic,
                        Partner__r.SicDesc,
                        Partner__r.All_NAICS_Codes__c,
                        Partner__r.Do_Not_Do_Business_With__c,
                        Partner__r.SEA_Concern__c,
                        Partner__r.Tradestyle,
                        Partner__r.YearStarted,
                        Partner__r.NumberOfEmployees,
                        Partner__r.AnnualRevenue,
                        Partner__r.Website,
                        Partner__r.Phone,
                        Partner__r.Fax,
                        Partner__r.Headquarters_CDH_Party_Number__c,
                        Partner__r.Domestic_Ultimate__c,
                        Partner__r.Global_Ultimate__c,
                        Partner__r.Linkedin_URL__c
                    FROM
                        OpportunityPartners2__r
                )
            FROM
                Opportunity
            WHERE Id = :opportunityId
            OR (OpportunityNumber__c = :opportunityNumber AND OpportunityNumber__c != null)
            LIMIT 1
        ];

        if(!opportunities.isEmpty()) {
            opportunity = opportunities[0];
        }
        return opportunity;
	}
}