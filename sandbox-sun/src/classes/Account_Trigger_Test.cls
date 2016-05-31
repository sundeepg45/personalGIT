/*****************************************************************************************
    Name    : Account_Trigger_Test
    Desc    : This is test class for Account_trigger  and Account_Trigger_Handler.
              
                            
    Modification Log : 
---------------------------------------------------------------------------
    Developer        Date               Description
---------------------------------------------------------------------------
    Vipul Jain      23 JULY 2014         Created
    Neha Jaiswal    14 Oct 2014          Updated
    Anshul Kumar    28 APR 2015          Updated
******************************************************************************************/
@isTest
public class Account_Trigger_Test{
        
    public testMethod static void SingleAccountCreation_Update() {
        
        // insert CDH Party record
        CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty ('1231231234');
        insert cdhParty;
        test.starttest();
        // insert account records.
        
        Account account = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account');
        account.BillingCountry = 'IN';
        insert account;
        account.Name = 'HP Account';
        update account;
        // insert address record 
        Address__c address = IntegrationObjectsTestUtil.getSFAddress(account,'123 Entitle St', 'Raleigh', 'NC');
        insert address;
        test.stoptest();  
     }
    
    public static testMethod void testCreateEventOnAccTransfer (){
        
        Profile standard = [SELECT Id FROM Profile WHERE Name LIKE '%Direct Sales User%' LIMIT 1]; 
        Profile admin = [SELECT Id FROM Profile WHERE Name='Administrator - Level 1'];

        User standardUser = new User(Alias = 'standt', Email='stcTestStandardUser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = standard.Id, Job_Function__c = 'System Operations',
          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestStandardUser@testorg.com');
        insert standardUser;
        
        User adminUser = new User(Alias = 'admint', Email='stcTestAdminUser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = admin.Id,  Job_Function__c = 'System Operations',
          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestAdminUser@testorg.com');
        insert adminUser;
        
        System.runAs(adminUser){
            CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty ('1231231234');
            insert cdhParty;
            
            Account account = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account');
            account.BillingCountry = 'IN';
            insert account;
            
            RecordType preferredRecordType = [
                  select Id,name
                  from RecordType
                  where name like :('EMEA %')
                    and SObjectType = 'Opportunity'
                    and IsActive = true
                  limit 1 ];
            
            Opportunity opp = new Opportunity(
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
            
            insert opp;
            
            list<Event__c> lstEvent = [SELECT Opportunity__c FROM Event__c WHERE Opportunity__c =: opp.Id AND Processed__c = FALSE];
            delete lstEvent;
            
            account.OwnerId = standardUser.Id;
            update account;
        }
    }
    
    public testmethod static void DuplicateSalesAccountScenario_Creating_CustomerAccount(){
        
        // insert CDH Party record
        CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty ('1231231234');
        insert cdhParty;
        test.starttest();
        // insert account records.
        
        List<Account> accountList = new List<Account>();
        Account account = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account');
        account.BillingCountry = 'IN';
        accountList.add(account);
        Account accountSecond = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account');
        accountSecond.BillingCountry = 'IN';
        accountList.add(accountSecond);
        try {
            insert accountList;
        }
        catch(exception e){
            system.debug('exception occured-->'+e.getmessage());
        }
        test.stoptest(); 
    }
    
    public testmethod static void BulkAccountCreation_Update () {
    
        // insert CDH Party record
        CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty ('1231231234');
        insert cdhParty;
        test.starttest();
        // insert account records.
        List<Account> accountList = new List<Account>();
        for(integer i=0 ; i<20; i++) {
            accountList.add(IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account'+string.valueof(i)));
        }
        insert accountList;
        
        List<Address__c> addressList = new List<Address__c>();
        for(integer i=0 ;i<20;i++){
            addressList.add(IntegrationObjectsTestUtil.getSFAddress(accountList[i],'123 Entitle St', 'Raleigh', 'NC'));
        }
        insert addressList;
    }
    
    /* Method to test the scenario when partner program gets updated for an account with oracle code in related definition object with status as active and when oracle code is null for related definition object with status is different than 'Active.
    */
   public testMethod static void PartnerProgramCreationOnAccount() {
        
        // insert CDH Party record
        CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty ('123100214434');
        insert cdhParty;
       
        //insert Account record
        Account account = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account with partner program scenario create');
        account.BillingCountry = 'CA';
        insert account;
        
        // insert address record 
        Address__c address = IntegrationObjectsTestUtil.getSFAddress(account,'123 Entitle St', 'Raleigh', 'NC');
        insert address;
        
        //insert partner program definition where oracle code is not null.
        Partner_Program_Definition__c definitionObjWithOracleCode = new Partner_Program_Definition__c();
        definitionObjWithOracleCode.Oracle_Classification_Code__c = 'Test oracle classification code';
        insert definitionObjWithOracleCode;
        
        //insert partner program definition where oracle code is null.
        Partner_Program_Definition__c definitionObjWithoutOracleCode = new Partner_Program_Definition__c();
        insert definitionObjWithoutOracleCode;

        //creating partner program tier with different field values.
        Partner_Program_Tier__c partnerProgramTier = new Partner_Program_Tier__c();
        partnerProgramTier.Oracle_Classification_Code__c =  '12345';
        partnerProgramTier.Partner_Program_Definition__c = definitionObjWithOracleCode.id;
        partnerProgramTier.Tier__c = 'Ready';
        partnerProgramTier.Order__c = 1;
        partnerProgramTier.CDH_Mastered__c = false;
        insert partnerProgramTier;
        
        Partner_Program_Tier__c partnerProgramTierCDH = new Partner_Program_Tier__c();
        partnerProgramTierCDH.Oracle_Classification_Code__c =  '1234578';
        partnerProgramTierCDH.Partner_Program_Definition__c = definitionObjWithoutOracleCode.id;
        partnerProgramTierCDH.Tier__c = 'Advanced';
        partnerProgramTierCDH.Order__c = 1;
        partnerProgramTierCDH.CDH_Mastered__c = false;
        insert partnerProgramTierCDH ;
        
        test.startTest();
            /* insert partner program record when program partner's status is active and it's related definition object has oracle classification code
            value, so outbound service is called and CDH will flow.*/
            Partner_Program__c partnerProgramWithOracleCode = new Partner_Program__c();
            partnerProgramWithOracleCode.Status__c = 'Active';
            partnerProgramWithOracleCode.Account__c = account.id;
            partnerProgramWithOracleCode.Program__c = definitionObjWithOracleCode.id;
            partnerProgramWithOracleCode.Tier__c = 'Ready';
            insert partnerProgramWithOracleCode;
            System.assertEquals('Test oracle classification code' , [Select Program__r.Oracle_Classification_Code__c From Partner_Program__c where Program__c =: definitionObjWithOracleCode.id LIMIT 1].Program__r.Oracle_Classification_Code__c);
          
           /* insert partner program record when program partner's status is active and it's related definition object doesn't has oracle classification code value, so outbound service is not called and no CDH will flow.*/
            Partner_Program__c partnerProgramWithOracleCodeAsActive = new Partner_Program__c();
            partnerProgramWithOracleCodeAsActive.Status__c = 'Active';
            partnerProgramWithOracleCodeAsActive.Account__c = account.id;
            partnerProgramWithOracleCodeAsActive.Program__c = definitionObjWithoutOracleCode.id;
            partnerProgramWithOracleCodeAsActive.Tier__c = 'Advanced';
            insert partnerProgramWithOracleCodeAsActive ;
        
       test.stoptest();
    }
    
    // This method checks when bulk records are created for accounts.
    public testmethod static void BulkPartnerProgramUpdatedOnAccount() {
    
        // insert CDH Party record
        CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty ('1231231234');
        insert cdhParty;
        test.starttest();
        // insert account records.
        List<Account> accountList = new List<Account>();
        for(integer i=0 ; i<20; i++) {
            accountList.add(IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account'+string.valueof(i)));
        }
        insert accountList;
        
        //insert partner program definition where oracle code is not null.
        List<Partner_Program_Definition__c > definitionList = new List<Partner_Program_Definition__c >();
        for(integer i=0 ;i<20;i++){
            Partner_Program_Definition__c definitionObjWithOracleCode = new Partner_Program_Definition__c();
            definitionObjWithOracleCode.Oracle_Classification_Code__c = ('Test oracle classification code'+string.valueof(i));
            definitionList.add(definitionObjWithOracleCode);
         }
        insert definitionList;
        
        //insert partner program definition where oracle code is not null , so CDH will flow
        List<Partner_Program__c> programList = new List<Partner_Program__c>();
        for(integer i=0 ;i<20;i++){
            Partner_Program__c programObjWithOracleCode = new Partner_Program__c();
            programObjWithOracleCode.program__c = definitionList[i].id;
            programObjWithOracleCode.Account__c = accountList[i].id;
            programObjWithOracleCode.Status__c = 'Active';
            programList.add(programObjWithOracleCode);
        }
        insert programList;
        System.assertEquals('Test oracle classification code10' , [Select Program__r.Oracle_Classification_Code__c From Partner_Program__c where id =: programList[10].id LIMIT 1].Program__r.Oracle_Classification_Code__c);
    }
    
    /* Method to test the scenario when partner program gets updated for an account.If partner program status gets changed from active to any other
    status or from any other status to Active, then CDH will be interfaced if related definition object has classification oracle code. */
    public testMethod static void partnerProgramUpdatedOnAccount() {
        
        // insert CDH Party record
        CDH_Party__c cdhParty = IntegrationObjectsTestUtil.getCDHParty ('12312399887634');
        insert cdhParty;
       
        //insert Account record
        Account account = IntegrationObjectsTestUtil.getSFAccount(cdhParty,'Testing of Account with partner program scenario update');
        account.BillingCountry = 'CA';
       
        insert account;
        
        // insert address record 
        Address__c address = IntegrationObjectsTestUtil.getSFAddress(account,'123 Entitle St', 'Raleigh', 'NC');
        insert address;
        
        // custom setting to trigger partner program trigger.
        BooleanSetting__c triggeringPartnerProgram = new BooleanSetting__c();
        triggeringPartnerProgram.Name='PartnerProgram_Trigger';
        insert triggeringPartnerProgram ;
        
        //insert partner program definition where oracle code is not null.
        Partner_Program_Definition__c definitionObjWithOracleCode = new Partner_Program_Definition__c();
        definitionObjWithOracleCode.Oracle_Classification_Code__c = 'Test oracle classification code';
        insert definitionObjWithOracleCode;
        
        //insert partner program definition where oracle code is null.
        Partner_Program_Definition__c definitionObjWithoutOracleCode = new Partner_Program_Definition__c();
        insert definitionObjWithoutOracleCode;
        
        //creating partner program tier with different field values.
        Partner_Program_Tier__c partnerProgramTier = new Partner_Program_Tier__c();
        partnerProgramTier.Oracle_Classification_Code__c =  '12345';
        partnerProgramTier.Partner_Program_Definition__c = definitionObjWithOracleCode.id;
        partnerProgramTier.Tier__c = 'Ready';
        partnerProgramTier.Order__c = 1;
        partnerProgramTier.CDH_Mastered__c = false;
        insert partnerProgramTier;
        
        Partner_Program_Tier__c partnerProgramTierCDH = new Partner_Program_Tier__c();
        partnerProgramTierCDH.Oracle_Classification_Code__c =  '1234578';
        partnerProgramTierCDH.Partner_Program_Definition__c = definitionObjWithoutOracleCode.id;
        partnerProgramTierCDH.Tier__c = 'Advanced';
        partnerProgramTierCDH.Order__c = 1;
        partnerProgramTierCDH.CDH_Mastered__c = false;
        insert partnerProgramTierCDH ;
        
        Partner_Program_Tier__c partnerProgramTierCDHIbsert = new Partner_Program_Tier__c();
        partnerProgramTierCDHIbsert.Oracle_Classification_Code__c =  '11';
        partnerProgramTierCDHIbsert.Partner_Program_Definition__c = definitionObjWithOracleCode.id;
        partnerProgramTierCDHIbsert.Tier__c = 'Affiliated';
        partnerProgramTierCDHIbsert.Order__c = 1;
        partnerProgramTierCDHIbsert.CDH_Mastered__c = false;
        insert partnerProgramTierCDHIbsert;
        
        test.startTest();
            
            // insert partner program record when cdh will flow as status is changing from Active to some other status.
            Partner_Program__c partnerProgramWithOracleCode = new Partner_Program__c();
            partnerProgramWithOracleCode.Status__c = 'Active';
            partnerProgramWithOracleCode.Account__c = account.id;
            partnerProgramWithOracleCode.Program__c = definitionObjWithOracleCode.id;
            partnerProgramWithOracleCode.Tier__c = 'Ready';
            insert partnerProgramWithOracleCode;
            
            partnerProgramWithOracleCode.Status__c = 'Rejected';
            update partnerProgramWithOracleCode;
            
            partnerProgramWithOracleCode.Status__c = 'Active';
            partnerProgramWithOracleCode.Tier__c = 'Advanced';
            partnerProgramWithOracleCode.Program__c = definitionObjWithoutOracleCode.id;
            update partnerProgramWithOracleCode;
            
            partnerProgramWithOracleCode.Program__c = definitionObjWithoutOracleCode.id;
            update partnerProgramWithOracleCode;
            
            // insert partner program record when cdh will flow as status of the program gets change to active.
            Partner_Program__c partnerProgramWithOracleCodeStatus = new Partner_Program__c();
            partnerProgramWithOracleCodeStatus.Status__c = 'Approved';
            partnerProgramWithOracleCodeStatus.Account__c = account.id;
            partnerProgramWithOracleCodeStatus.Program__c = definitionObjWithOracleCode.id;
            partnerProgramWithOracleCodeStatus.tier__c ='Ready';
            insert partnerProgramWithOracleCodeStatus ;
            
            partnerProgramWithOracleCodeStatus.Status__c = 'Rejected';
            update partnerProgramWithOracleCodeStatus;
            
            System.assertEquals('Test oracle classification code' , [Select Program__r.Oracle_Classification_Code__c From Partner_Program__c where Program__c =: definitionObjWithOracleCode.id LIMIT 1].Program__r.Oracle_Classification_Code__c);
        
            Partner_Program__c  deletePartner = [Select id from Partner_Program__c  where id =:partnerProgramWithOracleCodeStatus.id];
            Delete deletePartner ;
        test.stoptest();
    }
      
}