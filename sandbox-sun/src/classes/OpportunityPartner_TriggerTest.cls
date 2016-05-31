@IsTest
public class OpportunityPartner_TriggerTest {
   
   private static List<Opportunity> opportunityList = new List<Opportunity>();
   private static LongSetting__c longSetting = new LongSetting__c();
   private static Date_Setting__c dateSetting = new Date_Setting__c();
   private static StringSetting__c stringSetting = new StringSetting__c();
   @isTest
   private static void method_test(){
         
         List <OpportunityPartner__c > deletePartners = new List<OpportunityPartner__c>();
         
         Account account = new Account();
         account.BillingCity = 'Raleigh';
         account.BillingCountry = 'US';
         account.BillingPostalCode = '27606';
         account.BillingState = 'North Carolina';
         account.BillingStreet = '1801 Varsity Drive';
         account.Name = 'Red Hat';
         account.OracleAccountNumber__c = '12345';
         account.ShippingCity = 'Raleigh';
         account.ShippingCountry = 'US';
         account.ShippingPostalCode = '27606';
         account.ShippingState = 'North Carolina';
         account.ShippingStreet = '1801 Varsity Drive';
         account.VATNumber__c = '67890';
         insert account;
         
         Classification__c partnerType = new Classification__c();
         partnerType.Name = 'Partner Type';
         partnerType.ReferenceKey__c = 'PARTNER_TYPE';
         partnerType.IsActive__c = true;
         partnerType.IsInlineEdit__c = true;
         //partnerType.HierarchyKey__c = 'PARTNER_TYPE';     
         insert partnerType;     
         
         Classification__c partnerTier = new Classification__c();
         partnerTier.Name = 'Partner Tier';
         partnerTier.ReferenceKey__c = 'PARTNER_TIER';
         partnerTier.IsActive__c = true;
         partnerTier.IsInlineEdit__c = true;
         insert partnerTier;     
         
         Classification__c distributor = new Classification__c();
         distributor.Name = 'Distributor';
         distributor.Parent__c = partnerType.Id;
         distributor.ReferenceKey__c = 'DISTRIBUTOR';
         distributor.IsActive__c = true;
         distributor.IsInlineEdit__c = false;
         insert distributor;     
         
         Classification__c affiliated = new Classification__c();
         affiliated.Name = 'Affiliated';
         affiliated.Parent__c = partnerTier.Id;
         affiliated.ReferenceKey__c = 'AFFILIATED';
         affiliated.IsActive__c = true;
         affiliated.IsInlineEdit__c = false;
         insert affiliated;
         
         Account financialAccount = new Account();
         financialAccount.BillingCity = 'Raleigh';
         financialAccount.BillingCountry = 'US';
         financialAccount.BillingPostalCode = '27606';
         financialAccount.BillingState = 'North Carolina';
         financialAccount.BillingStreet = '1801 Varsity Drive';
         financialAccount.Name = 'Integra Micro Systems Private Limited';
         financialAccount.OracleAccountNumber__c = '12345';
         financialAccount.ShippingCity = 'Raleigh';
         financialAccount.ShippingCountry = 'US';
         financialAccount.ShippingPostalCode = '27606';
         financialAccount.ShippingState = 'North Carolina';
         financialAccount.ShippingStreet = '1801 Varsity Drive';
         financialAccount.VATNumber__c = '67890';
         financialAccount.Finder_Partner_Tier__c = affiliated.Id;
         financialAccount.Finder_Partner_Type__c = distributor.Id;
         insert financialAccount;
         
         Opportunity opportunity = new Opportunity();                 
         opportunity.AccountId = account.Id;
         opportunity.CloseDate = Date.newInstance(2014, 10, 02);
         opportunity.Country_Of_Order__c = 'US';
         opportunity.CurrencyIsoCode = 'USD';
         opportunity.Name = 'Opportunity';
         opportunity.OpportunityType__c = 'Standard';
         opportunity.PaymentType__c = 'NA Purchase Order';
         opportunity.StageName = 'Test Stage';
         insert opportunity;                 
         
         test.starttest();
         OpportunityPartner__c f = new OpportunityPartner__c();
         f.Opportunity__c = opportunity.Id;
         f.Partner__c = financialAccount.Id;
         f.PartnerTier__c = affiliated.Id;
         f.PartnerType__c = distributor.Id;
         f.RelationshipType__c = 'Financial';
         insert f;              
         deletePartners.add(f);
         
         OpportunityPartner__c i1 = new OpportunityPartner__c();
         i1.Opportunity__c = opportunity.Id;
         i1.Partner__c = financialAccount.Id;
         i1.PartnerTier__c = affiliated.Id;
         i1.PartnerType__c = distributor.Id;
         i1.RelationshipType__c = 'Influencing';
         insert i1;              
         deletePartners.add(i1);
         
         OpportunityPartner__c i2 = new OpportunityPartner__c();
         i2.Opportunity__c = opportunity.Id;
         i2.Partner__c = financialAccount.Id;
         i2.PartnerTier__c = affiliated.Id;
         i2.PartnerType__c = distributor.Id;
         i2.RelationshipType__c = 'Influencing';
         insert i2; 
         deletePartners.add(i2);
         
         OpportunityPartner__c i3 = new OpportunityPartner__c();
         i3.Opportunity__c = opportunity.Id;
         i3.Partner__c = financialAccount.Id;
         i3.PartnerTier__c = affiliated.Id;
         i3.PartnerType__c = distributor.Id;
         i3.RelationshipType__c = 'Influencing';
         insert i3; 
         deletePartners.add(i3);
         
         OpportunityPartner__c i4 = new OpportunityPartner__c();
         i4.Opportunity__c = opportunity.Id;
         i4.Partner__c = financialAccount.Id;
         i4.PartnerTier__c = affiliated.Id;
         i4.PartnerType__c = distributor.Id;
         i4.RelationshipType__c = 'Influencing';
         insert i4;
         deletePartners.add(i4);
         
         OpportunityPartner__c r1 = new OpportunityPartner__c();
         r1.Opportunity__c = opportunity.Id;
         r1.Partner__c = financialAccount.Id;
         r1.PartnerTier__c = affiliated.Id;
         r1.PartnerType__c = distributor.Id;
         r1.RelationshipType__c = 'Reseller 2';
         insert r1;
         deletePartners.add(r1);
         
         OpportunityPartner__c r2 = new OpportunityPartner__c();
         r2.Opportunity__c = opportunity.Id;
         r2.Partner__c = financialAccount.Id;
         r2.PartnerTier__c = affiliated.Id;
         r2.PartnerType__c = distributor.Id;
         r2.RelationshipType__c = 'Reseller 3';
         insert r2;
         deletePartners.add(r2);
         
         OpportunityPartner__c r3 = new OpportunityPartner__c();
         r3.Opportunity__c = opportunity.Id;
         r3.Partner__c = financialAccount.Id;
         r3.PartnerTier__c = affiliated.Id;
         r3.PartnerType__c = distributor.Id;
         r3.RelationshipType__c = 'Reseller 4';
         insert r3;    
         deletePartners.add(r3);
         
         OpportunityPartner__c r4 = new OpportunityPartner__c();
         r4.Opportunity__c = opportunity.Id;
         r4.Partner__c = financialAccount.Id;
         r4.PartnerTier__c = affiliated.Id;
         r4.PartnerType__c = distributor.Id;
         r4.RelationshipType__c = 'Reseller 5';
         insert r4;
         deletePartners.add(r4);
         
         OpportunityPartner__c r5 = new OpportunityPartner__c();
         r5.Opportunity__c = opportunity.Id;
         r5.Partner__c = financialAccount.Id;
         r5.PartnerTier__c = affiliated.Id;
         r5.PartnerType__c = distributor.Id;
         r5.RelationshipType__c = 'Reseller 6';
         insert r5;
         deletePartners.add(r5);
         
         OpportunityPartner__c r6 = new OpportunityPartner__c();
         r6.Opportunity__c = opportunity.Id;
         r6.Partner__c = financialAccount.Id;
         r6.PartnerTier__c = affiliated.Id;
         r6.PartnerType__c = distributor.Id;
         r6.RelationshipType__c = 'Reseller 7';
         insert r6;         
         deletePartners.add(r6);
         
         opportunityList.add(opportunity);
         
         Opportunity_Partners__c newPartner = [select Id from Opportunity_Partners__c where Opportunity__c = :opportunity.Id];
         
         delete deletepartners;
         
         test.stoptest();
         
   }
   
   
}