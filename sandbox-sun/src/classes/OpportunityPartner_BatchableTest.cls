@IsTest
public class OpportunityPartner_BatchableTest {
   
   private static List<Opportunity> opportunityList = new List<Opportunity>();
   private static LongSetting__c longSetting = new LongSetting__c();
   private static Date_Setting__c dateSetting = new Date_Setting__c();
   private static StringSetting__c stringSetting = new StringSetting__c();
   
   private static void nonSetUpData(){
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
         opportunityList.add(opportunity);       

         List<OpportunityPartner__c> partnerList = new List<OpportunityPartner__c>();
         OpportunityPartner__c f = new OpportunityPartner__c();
         f.Opportunity__c = opportunity.Id;
         f.Partner__c = financialAccount.Id;
         f.PartnerTier__c = affiliated.Id;
         f.PartnerType__c = distributor.Id;
         f.RelationshipType__c = 'Financial';
         partnerList.add(f);
         
         OpportunityPartner__c i1 = new OpportunityPartner__c();
         i1.Opportunity__c = opportunity.Id;
         i1.Partner__c = financialAccount.Id;
         i1.PartnerTier__c = affiliated.Id;
         i1.PartnerType__c = distributor.Id;
         i1.RelationshipType__c = 'Influencing';
         partnerList.add(i1);           
         
         OpportunityPartner__c i2 = new OpportunityPartner__c();
         i2.Opportunity__c = opportunity.Id;
         i2.Partner__c = financialAccount.Id;
         i2.PartnerTier__c = affiliated.Id;
         i2.PartnerType__c = distributor.Id;
         i2.RelationshipType__c = 'Influencing';
         partnerList.add(i2);
         
         OpportunityPartner__c i3 = new OpportunityPartner__c();
         i3.Opportunity__c = opportunity.Id;
         i3.Partner__c = financialAccount.Id;
         i3.PartnerTier__c = affiliated.Id;
         i3.PartnerType__c = distributor.Id;
         i3.RelationshipType__c = 'Influencing';
         partnerList.add(i3);
         
         OpportunityPartner__c i4 = new OpportunityPartner__c();
         i4.Opportunity__c = opportunity.Id;
         i4.Partner__c = financialAccount.Id;
         i4.PartnerTier__c = affiliated.Id;
         i4.PartnerType__c = distributor.Id;
         i4.RelationshipType__c = 'Influencing';
         partnerList.add(i4);
         
         OpportunityPartner__c r1 = new OpportunityPartner__c();
         r1.Opportunity__c = opportunity.Id;
         r1.Partner__c = financialAccount.Id;
         r1.PartnerTier__c = affiliated.Id;
         r1.PartnerType__c = distributor.Id;
         r1.RelationshipType__c = 'Reseller 2';
         partnerList.add(r1);
         
         OpportunityPartner__c r2 = new OpportunityPartner__c();
         r2.Opportunity__c = opportunity.Id;
         r2.Partner__c = financialAccount.Id;
         r2.PartnerTier__c = affiliated.Id;
         r2.PartnerType__c = distributor.Id;
         r2.RelationshipType__c = 'Reseller 3';
         partnerList.add(r2);
         
         OpportunityPartner__c r3 = new OpportunityPartner__c();
         r3.Opportunity__c = opportunity.Id;
         r3.Partner__c = financialAccount.Id;
         r3.PartnerTier__c = affiliated.Id;
         r3.PartnerType__c = distributor.Id;
         r3.RelationshipType__c = 'Reseller 4';
         partnerList.add(r3);    
         
         OpportunityPartner__c r4 = new OpportunityPartner__c();
         r4.Opportunity__c = opportunity.Id;
         r4.Partner__c = financialAccount.Id;
         r4.PartnerTier__c = affiliated.Id;
         r4.PartnerType__c = distributor.Id;
         r4.RelationshipType__c = 'Reseller 5';
         partnerList.add(r4);
         
         OpportunityPartner__c r5 = new OpportunityPartner__c();
         r5.Opportunity__c = opportunity.Id;
         r5.Partner__c = financialAccount.Id;
         r5.PartnerTier__c = affiliated.Id;
         r5.PartnerType__c = distributor.Id;
         r5.RelationshipType__c = 'Reseller 6';
         partnerList.add(r5);
         
         OpportunityPartner__c r6 = new OpportunityPartner__c();
         r6.Opportunity__c = opportunity.Id;
         r6.Partner__c = financialAccount.Id;
         r6.PartnerTier__c = affiliated.Id;
         r6.PartnerType__c = distributor.Id;
         r6.RelationshipType__c = 'Reseller 7';
         partnerList.add(r6);

         insert partnerList;
   }
   
   private static void setupData(){
     Profile profile =[Select Id from Profile where Name = 'Administrator - Level 1'];
     
     User sysAdmin = new User();
     sysAdmin.FirstName = 'Test1';
     sysAdmin.Username = 'sagamehta123@deloitte.com';
     sysAdmin.Email = 'sagamehta@deloitte.com';
     sysAdmin.LastName = 'Test';
     sysAdmin.Alias = 'Test123';
     sysAdmin.ProfileID = profile.Id;    
     sysAdmin.TimeZoneSidKey = 'America/Los_Angeles';
     sysAdmin.EmailEncodingKey='UTF-8';  
     sysAdmin.LocaleSidKey = 'en_US';
     sysAdmin.LanguageLocaleKey = 'en_US';
     insert sysAdmin;
          
     System.runAs(sysAdmin){
         longSetting.Name = 'Opportunity_Batch_Limit';
         longSetting.Value__c = 10;
         insert longSetting;
         //get Closedate value
         
         dateSetting.Name = 'Opportunity_Batch_Close_Date';
         dateSetting.Value__c = date.newInstance(2014, 09, 01);
         insert dateSetting;
         
         //get Last Mofified Date value     
         stringSetting.Name = 'Opportunity_Batch_LastModified_Date';
         stringSetting.Value__c = 'LAST_N_DAYS:14';
         insert stringSetting;
     }                           
   } 
      
  @isTest
  static void executeBatch() {
    setupData();            
    
    Profile profile =[Select Id from Profile where Name = 'System Administrator'];     
    User sysAdmin = new User();
    sysAdmin.FirstName = 'Test2';
    sysAdmin.Username = 'sagamehta456@deloitte.com';
    sysAdmin.Email = 'sagamehta@deloitte.com';
    sysAdmin.LastName = 'Test123';
    sysAdmin.Alias = 'Test2';
    sysAdmin.ProfileID = profile.Id;    
    sysAdmin.TimeZoneSidKey = 'America/Los_Angeles';
    sysAdmin.EmailEncodingKey='UTF-8';  
    sysAdmin.LocaleSidKey = 'en_US';
    sysAdmin.LanguageLocaleKey = 'en_US';
    insert sysAdmin;
          
    System.runAs(sysAdmin){
        nonSetUpData();        
        OpportunityPartner_Batchable batchable = new OpportunityPartner_Batchable();    
        Test.startTest();
        Database.executeBatch(batchable);
        Test.stopTest();
    }

    Integer recordCount = [SELECT count() FROM Opportunity_Partners__c WHERE Opportunity__c = :opportunityList[0].Id];
    System.assertEquals(1, recordCount);
    Opportunity testOpp = [SELECT Id, Opportunity_Partners__c FROM Opportunity WHERE Id = :opportunityList[0].Id];
    System.assertNotEquals(null, testOpp.Opportunity_Partners__c); 
  }    
  
}