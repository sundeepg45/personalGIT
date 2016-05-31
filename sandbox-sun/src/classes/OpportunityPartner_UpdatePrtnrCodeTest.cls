@isTest

public class OpportunityPartner_UpdatePrtnrCodeTest{
    
    public static final String SUPER_REGION = 'EMEA';

    public static RecordType preferredRecordType {
        get {
            if(preferredRecordType == null) {
                preferredRecordType = [
                  select Id,name
                  from RecordType
                  where name like :(SUPER_REGION+' %')
                    and SObjectType = 'Opportunity'
                    and IsActive = true
                  limit 1 ];
            }
            return preferredRecordType;
        }
    }

    public static Account account {
        get {
          if(account == null) {
            RecordType recordType = [
              select Id,name
              from RecordType
              where name = 'Strategic'
                and SObjectType = 'Account'
                and IsActive = true
              limit 1 ];
            account = new Account(
              CurrencyIsoCode='USD',
              name='Test Account',
              RecordTypeId=recordType.Id,
              AccountClassification__c=recordType.name );
            insert account;
            account.RecordType = recordType;
          }
          return account;
        }
    }

    public static Opportunity opp {
        get {
          if(opp == null) {
            opp = new Opportunity(
              Name='Opportunity Test',
              CurrencyIsoCode=account.CurrencyIsoCode,
              CloseDate=System.today(),
              ContractStartDate__c = System.today().addDays(1),
              StageName='Unqualified',
              OwnerId=UserInfo.getUserId(),
              AccountId=account.Id,Country_of_Order__c='India',FulfillmentChannel__c='Direct - OEM',
              RecordTypeId = preferredRecordType.Id,
              PrimaryBusinessUnit__c=null,
              POC_Status__c=null);
          }
          return opp;
        }
    }
    
    public static testMethod void testOpportunityPartner_UpdatePrtnrCode(){
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
        
        Credit__c CC = new Credit__c();
        Credit__c CC1 = new Credit__c();
        
        EBS_Account__c ebsAcc = new EBS_Account__c();
        
        system.runAs(adminUser){
          //create opportunity
            insert opp;
            
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
            pptInst.Oracle_Classification_Code__c = '22342';
            pptInst.Partner_Program_Definition__c = ppdInst.Id;
            pptInst.Tier__c = 'test';
            pptInst.Order__c = 987;
            
            insert pptInst;
            
            OpportunityPartner__c oppPrtnrInst = new OpportunityPartner__c();
            oppPrtnrInst.Opportunity__c = opp.Id;
            oppPrtnrInst.PartnerType__c = clssInst3.Id;
            oppPrtnrInst.PartnerTier__c = clssInst1.Id;
            oppPrtnrInst.Partner__c = account.Id;
            
            insert oppPrtnrInst;
            
            system.assert([SELECT Oracle_Classification_Code__c FROM OpportunityPartner__c WHERE Id =: oppPrtnrInst.Id LIMIT 1].Oracle_Classification_Code__c != NULL);
        }
    }
    
}