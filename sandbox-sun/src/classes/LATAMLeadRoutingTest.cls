/**
* Class Name:LATAMLeadRoutingTest
* Description:Test Class created for LATAMLeadRouting business Class.
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :4/26/2011
* Reason for Modification:Separated test class from business class and created a new test class
* Modified By :Abhijeet Anand
* Reason for Modification:Enhanced code coverage and added assert statements.
*/


@isTest
private class LATAMLeadRoutingTest
{
    public static List<LeadAccountRules__c> accrulesList= new List<LeadAccountRules__c>();
    public static List<LeadRules__c> rulesList= new List<LeadRules__c>();
    public static List<Lead> leadList = new List<Lead>();
    public static List<Id> leadlistId = new List<Id>();
    public static List<Lead> leadListnew = new List<Lead>();
    public static List<LeadCountryMap__c> countryList= new List<LeadCountryMap__c>();
    public static Map<String,String> deployCompanyMap = new Map<String,String>();
    public static Map<String,String> deployCountryMap = new Map<String,String>();
    public static Map<String,String> deployStateMap = new Map<String,String>();
    public static Map<String,String> deployemailatMap = new Map<String,String>();
    public static Map<String,String> deployemaildotMap = new Map<String,String>();
    public Map<String,LeadRules__c> newcommRulesMap= new Map<String,LeadRules__c>();
    public static LeadMap deployLeadMap= new LeadMap();

    /* This method is responsible for calling the assignQueue method in the business logic class.
       It passes all the necessary parameters to the method in order to cover maxmimum lines of code.
    */
    public static testmethod void latamLeadRoute()
    {
        DeactivateAllTestUtil.setDeactivateAll(false);

        LeadMap.dbbyPass = false; 
        latamLeadCountryMapping();                   
        latamLeadAccoutRules();
        latamLeadRouting();
        insert countryList;     
        insert  accrulesList;
        insert  rulesList;
        insert leadList;
        
        test.startTest();
        
        Lead newLead = [Select Id, OwnerId from Lead where Company =: 'YX555555'];
        
        System.assertEquals(Util.ldUserId,newLead.OwnerId);
        
        test.stopTest();         
    }
    
    public static testmethod void latamErrorLeadTest()
    {
        DeactivateAllTestUtil.setDeactivateAll(false);

    	LeadCountryMap__c countryMap = new LeadCountryMap__c();
    	countryMap.Country__c = 'UKP';
    	countryMap.Region__c = 'LATAM';
    	countryMap.ISO_Code__c = 'UKP';
    	insert countryMap;
    	
    	Lead latamCountryLead= new Lead();
        populateLead(latamCountryLead);
        latamCountryLead.Company='X';
        latamCountryLead.Country='UKP';
        latamCountryLead.Email='br@abc.test';
        //emeaCountryLead.ISO_Country_Code__c = 'GR';
        insert latamCountryLead;
        
        test.startTest();
		
		Lead newLead = [Select Id, OwnerId from Lead where Id =: latamCountryLead.Id];
        Group grp =[Select Id,Name from Group where Name = 'LATAM Lead Management Queue' AND Type = 'Queue'];
        System.assertEquals(grp.Id,newLead.OwnerId);
		
		test.stopTest();
    }
    
    public static void latamLeadCountryMapping()
    {
        LeadCountryMap__c countryMap = new LeadCountryMap__c();
        countryMap.Country__c = 'ABCD';
        countryMap.Region__c = 'LATAM';
        countryMap.ISO_Code__c = 'ABC';
        countryList.add(countryMap);
        
        LeadCountryMap__c countryMap1 = new LeadCountryMap__c();
        countryMap1.Country__c = 'XY';
        countryMap1.Region__c = 'LATAM';
        countryMap1.ISO_Code__c = 'XY';
        countryList.add(countryMap1); 
        
        LeadCountryMap__c countryMap2 = new LeadCountryMap__c();
        countryMap2.Country__c = 'EFGH';
        countryMap2.Region__c = 'LATAM';
        countryMap2.ISO_Code__c = 'EF';
        countryList.add(countryMap2);
        
        LeadCountryMap__c countryMap3 = new LeadCountryMap__c();
        countryMap3.Country__c = 'YZ';
        countryMap3.Region__c = 'LATAM';
        countryMap3.ISO_Code__c = 'YZ';
        countryList.add(countryMap3);
        
        LeadCountryMap__c countryMap4 = new LeadCountryMap__c();
        countryMap4.Country__c = 'ABD';
        countryMap4.Region__c = 'LATAM';
        countryMap4.ISO_Code__c = 'AB';
        countryList.add(countryMap4); 
        
        LeadCountryMap__c countryMap5 = new LeadCountryMap__c();
        countryMap5.Country__c = 'RSP';
        countryMap5.Region__c = 'LATAM';
        countryMap5.ISO_Code__c = 'RS';
        countryList.add(countryMap5); 
        
        LeadCountryMap__c countryMap6 = new LeadCountryMap__c();
        countryMap6.Country__c = 'UST';
        countryMap6.Region__c = 'LATAM';
        countryMap6.ISO_Code__c = 'CD';
        countryList.add(countryMap6);
        
        LeadCountryMap__c countryMap7 = new LeadCountryMap__c();
        countryMap7.Country__c = 'SS';
        countryMap7.Region__c = 'LATAM';
        countryMap7.ISO_Code__c = 'SS';
        countryList.add(countryMap7); 
        
        LeadCountryMap__c countryMap8 = new LeadCountryMap__c();
        countryMap8.Country__c = 'OP';
        countryMap8.Region__c = 'LATAM';
        countryMap8.ISO_Code__c = 'OP';
        countryList.add(countryMap8); 
        
        LeadCountryMap__c countryMap9 = new LeadCountryMap__c();
        countryMap9.Country__c = 'RT';
        countryMap9.Region__c = 'LATAM';
        countryMap9.ISO_Code__c = 'RT';
        countryList.add(countryMap9);
        
        LeadCountryMap__c countryMap0 = new LeadCountryMap__c();
        countryMap0.Country__c = 'ABCD1';
        countryMap0.Region__c = 'LATAM';
        countryMap0.ISO_Code__c = 'GR';
        countryList.add(countryMap0); 

    }
    
        
    /** The test method is updated as part of LATAM GLR Enhancement. This method contains all the rules needed to 
     ** excute the logic.
     **  New code written for named Account rule to enhance code coverage 
    **/    
    public static void latamLeadAccoutRules()
    {
        Profile profile = new Profile();
        profile = [select id,name from Profile where UserType = 'PowerPartner' and Name = 'LATAM Partner Portal – Strategic License' limit 1];
        
        Account TestAccount=new Account();
        TestAccount.Name='Test';
        TestAccount.Named_Account__c=true;
        TestAccount.isAccountActive__c=true;
        insert TestAccount;
        
        TestAccount.IsPartner = true;
        update TestAccount;
        
        Contact con = new Contact();
        con.LastName = 'Test Contact';
        con.AccountId = TestAccount.Id;
        con.Email = 'test@Rh.com';
        insert con;
        
        User usr = new User(alias = 'st6593', email='standarduser6593@testorg.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profile.Id,
        timezonesidkey='America/Los_Angeles', username='standarduser6593@testorg.com',ContactId=con.Id);
        insert usr;
        
        Account acc = new Account(Name = 'Test Account', Named_Account__c = true);
        insert acc;
        
        Account TestAcc2= new Account();
        TestAcc2.Name='TestAcc2';
        TestAcc2.Named_Account__c=false;
        TestAcc2.isAccountActive__c=true;
        insert TestAcc2;
        
        Account TestAccObj= new Account();
        TestAccObj.Name='TestAccObj';
        TestAccObj.Named_Account__c=false;
        TestAccObj.isAccountActive__c=true;
        insert TestAccObj;
        
        AccountTeamMember accMember = new AccountTeamMember(AccountId = acc.Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'Back-Up');                   
        insert accMember;
        
        AccountTeamMember accMem = new AccountTeamMember(AccountId = TestAcc2.Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'Back-Up');                   
        insert accMem;
        
        AccountTeamMember AccountTeamMemObj = new AccountTeamMember ( UserId=Util.ldUserId, AccountId=TestAcc2.Id, TeamMemberRole='Inside Rep');
        insert AccountTeamMemObj;
        
        AccountTeamMember AccountTeamMemIns = new AccountTeamMember ( UserId=usr.Id, AccountId=TestAcc2.Id, TeamMemberRole='Inside Rep');
        insert AccountTeamMemIns;
        
        LeadAccountRules__c partnerlatamAccountRules= new LeadAccountRules__c();
        partnerlatamAccountRules.Type__c='Partner Account';
        partnerlatamAccountRules.Value__c='IBM';
        partnerlatamAccountRules.Assign_To__c='LATAM Priority 1 Queue';
        partnerlatamAccountRules.SuperRegion__c='LATAM';
        accrulesList.add(partnerlatamAccountRules);
    
        LeadAccountRules__c partnerlatamAccountRules1 = new LeadAccountRules__c();
        partnerlatamAccountRules1.Type__c='Partner Account';
        partnerlatamAccountRules1.Value__c='Accenture';
        partnerlatamAccountRules1.Assign_To__c='LATAM Priority 2 Queue';
        partnerlatamAccountRules1.Assign_To_Partner__c=true;
        partnerlatamAccountRules1.PartnerUser__c=Util.ldUserId;
        accrulesList.add(partnerlatamAccountRules1);
        
        LeadAccountRules__c partnerlatamAccountRules2= new LeadAccountRules__c();
        partnerlatamAccountRules2.Type__c='Partner Account';
        partnerlatamAccountRules2.Value__c='Acc';
        partnerlatamAccountRules2.Assign_To_Account_Team_Role__c='Back-Up';
        partnerlatamAccountRules2.SuperRegion__c='LATAM';
        partnerlatamAccountRules2.Account__c=acc.Id; 
        accrulesList.add(partnerlatamAccountRules2);
        
        LeadAccountRules__c partnerlatamAccRules= new LeadAccountRules__c();
        partnerlatamAccRules.Type__c='Partner Account';
        partnerlatamAccRules.Value__c='Acct';
        partnerlatamAccRules.Assign_To_Account_Team_Role__c='Inside Rep';
        partnerlatamAccRules.SuperRegion__c='LATAM';
        partnerlatamAccRules.Account__c=acc.Id; 
        accrulesList.add(partnerlatamAccRules);
        
        LeadAccountRules__c prtnrlatamAccRules= new LeadAccountRules__c();
        prtnrlatamAccRules.Type__c='Partner Account';
        prtnrlatamAccRules.Value__c='Acctu';
        prtnrlatamAccRules.Assign_To_Account_Team_Role__c='Outside Rep';
        prtnrlatamAccRules.SuperRegion__c='LATAM';
        prtnrlatamAccRules.Account__c=TestAccObj.Id; 
        accrulesList.add(prtnrlatamAccRules);  
        
      
        // Start -- Zip Code rule added as part of LATAM GLR enhancement - Oct. Release '10 
        LeadAccountRules__c namedlatamAccountRules= new LeadAccountRules__c();
        namedlatamAccountRules.Type__c='Named Account';
        namedlatamAccountRules.Value__c='AccentureName';
        namedlatamAccountRules.PartnerUser__c = usr.Id;
        namedlatamAccountRules.SuperRegion__c='LATAM';
        namedlatamAccountRules.Country__c='XY';
        namedlatamAccountRules.Assign_To__c = 'LATAM Delete Queue';
        namedlatamAccountRules.Account__c = acc.Id;
        namedlatamAccountRules.Assign_To_Partner__c = true;
        accrulesList.add(namedlatamAccountRules);
        
        LeadAccountRules__c namedlatamAccRule= new LeadAccountRules__c();
        namedlatamAccRule.Type__c='Named Account';
        namedlatamAccRule.Value__c='AccentureName1';
        namedlatamAccRule.User__c = Util.ldUserId;
        namedlatamAccRule.SuperRegion__c='LATAM';
        namedlatamAccRule.Country__c='XY';
        //namedlatamAccRule.Assign_To__c = 'LATAM Delete Queue';
        namedlatamAccRule.Account__c = acc.Id;
        accrulesList.add(namedlatamAccRule);
        
        LeadAccountRules__c namedlatamAccRules= new LeadAccountRules__c();
        namedlatamAccRules.Type__c='Named Account';
        namedlatamAccRules.Value__c='AccName';
        namedlatamAccRules.Assign_To_Account_Team_Role__c='Back-Up';
        namedlatamAccRules.SuperRegion__c='LATAM';
        namedlatamAccRules.Account__c=acc.Id;
        accrulesList.add(namedlatamAccRules); 
      
    
        LeadAccountRules__c namedlatamAccRules2 = new LeadAccountRules__c();
        namedlatamAccRules2.Type__c='Named Account';
        namedlatamAccRules2.Value__c='Acc2';
        namedlatamAccRules2.Assign_To_Account_Team_Role__c='Account Owner';
        namedlatamAccRules2.SuperRegion__c='LATAM';
        namedlatamAccRules2.Account__c=acc.Id; 
        accrulesList.add(namedlatamAccRules2 );
        
        LeadAccountRules__c namelatamAccRule = new LeadAccountRules__c();
        namelatamAccRule.Type__c='Named Account';
        namelatamAccRule.Value__c='Acc2';
        namelatamAccRule.State__c = 'MAHA';
        namelatamAccRule.Territory_Exception__c = true;
        namelatamAccRule.Assign_To_Account_Team_Role__c='Account Owner';
        namelatamAccRule.SuperRegion__c='LATAM';
        namelatamAccRule.Account__c=acc.Id; 
        accrulesList.add(namelatamAccRule );
        
        // End -- Zip Code rule added as part of LATAM GLR enhancement - Oct. Release '10 
        LeadRules__c emailrule=new LeadRules__c();
        emailrule.Type__c='Email Domain';
        emailrule.Value__c='.testvalue';
        emailrule.User__c=Util.ldUserId;
        emailrule.SuperRegion__c='LATAM';
        emailrule.Country__c='Brazil';
        emailrule.Email_Overide__c=true;
        rulesList.add(emailrule);
        
        LeadRules__c emailDomainRule=new LeadRules__c();
        emailDomainRule.Type__c='Email Domain';
        emailDomainRule.Value__c='GOV.IN';
        emailDomainRule.User__c=Util.ldUserId;
        emailDomainRule.SuperRegion__c='LATAM';
        emailDomainRule.Country__c='Brazil';
        emailDomainRule.Email_Overide__c=false;
        rulesList.add(emailDomainRule);
    
        LeadRules__c countryRule = new LeadRules__c();
        countryRule.Type__c='Country';
        countryRule.Value__c='AB';
        countryRule.Zip_Code__c ='12345';
        countryRule.User__c=Util.ldUserId;
        countryRule.SuperRegion__c='LATAM';
        rulesList.add(countryRule);
        
        LeadRules__c countryZipRule = new LeadRules__c();
        countryZipRule.Type__c='Country';
        countryZipRule.Value__c='RS';
        countryZipRule.Zip_Code__c ='12346';
        countryZipRule.User__c=Util.ldUserId;
        countryZipRule.SuperRegion__c='LATAM';
        rulesList.add(countryZipRule);
        
        LeadRules__c cntryRule = new LeadRules__c();
        cntryRule.Type__c='Country';
        cntryRule.Value__c='RT';
        cntryRule.Zip_Code__c ='12349';
        cntryRule.User__c=Util.ldUserId;
        cntryRule.SuperRegion__c='LATAM';
        rulesList.add(cntryRule);
        
        LeadRules__c cntryErrorRule = new LeadRules__c();
        cntryErrorRule.Type__c='Country';
        cntryErrorRule.Value__c='ABC';
        cntryErrorRule.Zip_Code__c ='1234';
        cntryErrorRule.User__c=Util.ldUserId;
        cntryErrorRule.SuperRegion__c='LATAM';
        rulesList.add(cntryErrorRule);
        
        LeadRules__c countryRule1 = new LeadRules__c();
        countryRule1.Type__c='Country';
        countryRule1.Value__c='CD';
        countryRule1.Starting_Range__c ='12345';
        countryRule1.Ending_Range__c='34567';
        countryRule1.User__c=Util.ldUserId;
        countryRule1.SuperRegion__c='LATAM';
        rulesList.add(countryRule1);
        
        LeadRules__c countryRuleM = new LeadRules__c();
        countryRuleM.Type__c='Country';
        countryRuleM.Value__c='CD';
        countryRuleM.Starting_Range__c ='22222';
        countryRuleM.Ending_Range__c='33333';
        countryRuleM.User__c=Util.ldUserId;
        countryRuleM.SuperRegion__c='LATAM';
        rulesList.add(countryRuleM );
        
        LeadRules__c multipleZipRule = new LeadRules__c();
        multipleZipRule.Type__c='Country';
        multipleZipRule.Value__c='CD';
        multipleZipRule.Starting_Range__c ='22221';
        multipleZipRule.Ending_Range__c='33334';
        multipleZipRule.User__c=Util.ldUserId;
        multipleZipRule.SuperRegion__c='LATAM';
        rulesList.add(multipleZipRule );
        
        LeadRules__c countryRule2 = new LeadRules__c();
        countryRule2.Type__c='Country';
        countryRule2.Value__c='SS';
        countryRule2.Zip_Code__c ='ALL';
        countryRule2.User__c=Util.ldUserId;
        countryRule2.SuperRegion__c='LATAM';
        rulesList.add(countryRule2 );
        
        LeadRules__c countryRule3 = new LeadRules__c();
        countryRule3.Type__c='Country';
        countryRule3.Value__c='ALL';
        countryRule3.Zip_Code__c ='77777';
        countryRule3.User__c=Util.ldUserId;
        countryRule3.SuperRegion__c='LATAM';
        rulesList.add(countryRule3 );
        
        LeadAccountRules__c partnerAccountRules1= new LeadAccountRules__c();
        partnerAccountRules1.Type__c='Partner Account';
        partnerAccountRules1.Value__c='CTS';
        partnerAccountRules1.Assign_To_Partner__c=true;
        partnerAccountRules1.PartnerUser__c= usr.Id;
        partnerAccountRules1.Assign_To__c ='APAC Delete Queue';
        partnerAccountRules1.SuperRegion__c='LATAM';
        accrulesList.add(partnerAccountRules1); 
    
    }

    // This method contains all Leads that will go through Lead routing logic and routes corresponding to rules.
    
    public static void latamLeadRouting()
    {                        
        Lead partnerAccountLatamLead= new Lead();
        populateLead(partnerAccountLatamLead);
        partnerAccountLatamLead.Company='IBM';
        deployCompanyMap.put('one',partnerAccountLatamLead.Company);
        partnerAccountLatamLead.Country='ABCD';
        partnerAccountLatamLead.Email='br1@abc.test';
        deployCountryMap.put('one',partnerAccountLatamLead.Iso_Country_Code__c);
        leadList.add(partnerAccountLatamLead);
        
        Lead partnerAccountLatamLea1= new Lead();
        populateLead(partnerAccountLatamLea1);
        partnerAccountLatamLea1.Company='Accenture';
        //deployCompanyMap.put('one1',partnerAccountLatamLead.Company);
        partnerAccountLatamLea1.Country='ABCD';
        partnerAccountLatamLea1.Email='br2@abc.test';
        partnerAccountLatamLea1.PostalCode ='1234';
        //deployCountryMap.put('one1',partnerAccountLatamLead1.Iso_Country_Code__c);
        leadList.add(partnerAccountLatamLea1);
        
        Lead partnerAccountLatamLead1= new Lead();
        populateLead(partnerAccountLatamLead1);
        partnerAccountLatamLead1.Company='Accenture';
        deployCompanyMap.put('one1',partnerAccountLatamLead.Company);
        partnerAccountLatamLead1.Country='ABCD';
        partnerAccountLatamLead1.Email='br2@abc.test';
        partnerAccountLatamLead1.PostalCode ='12345';
        deployCountryMap.put('one1',partnerAccountLatamLead1.Iso_Country_Code__c);
        leadList.add(partnerAccountLatamLead1);
        
        Lead partnerAccountLatamLead2= new Lead();
        populateLead(partnerAccountLatamLead2);
        partnerAccountLatamLead2.Company='Acc';
        deployCompanyMap.put('one2',partnerAccountLatamLead2.Company);
        partnerAccountLatamLead2.Country='ABCD';
        partnerAccountLatamLead2.Email='br3@abc.test';
        deployCountryMap.put('one2',partnerAccountLatamLead2.Iso_Country_Code__c);
        leadList.add(partnerAccountLatamLead2);
        
        Lead partnerAccLatamLead= new Lead();
        populateLead(partnerAccLatamLead);
        partnerAccLatamLead.Company='Acct';
        deployCompanyMap.put('one22',partnerAccLatamLead.Company);
        partnerAccLatamLead.Country='ABCD';
        partnerAccLatamLead.Email='br3@abc.test';
        deployCountryMap.put('one22',partnerAccLatamLead.Iso_Country_Code__c);
        leadList.add(partnerAccLatamLead);
        
        Lead prtnrAccLatamLead= new Lead();
        populateLead(prtnrAccLatamLead);
        prtnrAccLatamLead.Company='Acctu';
        deployCompanyMap.put('one222',prtnrAccLatamLead.Company);
        prtnrAccLatamLead.Country='ABCD';
        prtnrAccLatamLead.Email='br3@abc.test';
        deployCountryMap.put('one222',prtnrAccLatamLead.Iso_Country_Code__c);
        leadList.add(prtnrAccLatamLead);
        
        Lead partnerAccountLatamLead3= new Lead();
        populateLead(partnerAccountLatamLead3);
        partnerAccountLatamLead3.Company='CTS';
        partnerAccountLatamLead3.Partner_Opt_In__c=true;
        deployCompanyMap.put('one3',partnerAccountLatamLead3.Company);
        partnerAccountLatamLead3.Country='ABCD';
        partnerAccountLatamLead3.Email='br31@abc.test';
        deployCountryMap.put('one3',partnerAccountLatamLead3.Iso_Country_Code__c);
        leadList.add(partnerAccountLatamLead3);
    
                     
        // Start -- Zip Code rule added as part of LATAM GLR enhancement - Oct. Release '10 
        Lead namedAccountLead= new Lead();
        populateLead(namedAccountLead);
        namedAccountLead.Company='AccentureName';
        deployCompanyMap.put('two',namedAccountLead.Company);
        namedAccountLead.Country='XY';
        namedAccountLead.State='XY';
        //namedAccountLead.Iso_Country_Code__c ='XY';
        namedAccountLead.Email='br4@abc.test';
        deployCountryMap.put('two',namedAccountLead.Iso_Country_Code__c);
        leadList.add(namedAccountLead);
        
        Lead namedAccLead= new Lead();
        populateLead(namedAccLead);
        namedAccLead.Company='AccentureName1';
        deployCompanyMap.put('two',namedAccLead.Company);
        namedAccLead.Country='XY';
        namedAccLead.State='XY';
        //namedAccountLead.Iso_Country_Code__c ='XY';
        namedAccLead.Email='br4@abc.test';
        deployCountryMap.put('two',namedAccLead.Iso_Country_Code__c);
        leadList.add(namedAccLead);
 
        Lead namedAcctLatamLead= new Lead();
        populateLead(namedAcctLatamLead);
        namedAcctLatamLead.Company='AccName';
        deployCompanyMap.put('four',namedAcctLatamLead.Company);
        namedAcctLatamLead.Country='EFGH';
        namedAcctLatamLead.State='EF';
        //namedAcctLatamLead.Iso_Country_Code__c ='EF';
        namedAcctLatamLead.Email='br5@abc.test';
        deployCountryMap.put('four',namedAcctLatamLead.Iso_Country_Code__c);
        leadList.add(namedAcctLatamLead);
 
        Lead namedAcctLatamLead2= new Lead();
        populateLead(namedAcctLatamLead2);
        namedAcctLatamLead2.Company='Acc2';
        deployCompanyMap.put('five',namedAcctLatamLead2.Company);
        namedAcctLatamLead2.Country='YZ';
        namedAcctLatamLead2.State='YZ';
        //namedAcctLatamLead2.Iso_Country_Code__c ='YZ';
        namedAcctLatamLead2.Email='br6@abc.test';
        deployCountryMap.put('five',namedAcctLatamLead2.Iso_Country_Code__c);
        leadList.add(namedAcctLatamLead2); 
       
        // End -- Zip Code rule added as part of LATAM GLR enhancement - Oct. Release '10 
        Lead latamCountryLead= new Lead();
        populateLead(latamCountryLead);
        latamCountryLead.Country='ABD';
        latamCountryLead.Company='xyz';
        //latamCountryLead.Iso_Country_Code__c ='AB';
        latamCountryLead.PostalCode ='12345';
        latamCountryLead.Email='br7@abc.test';
        deployCountryMap.put('six',latamCountryLead.Iso_Country_Code__c);
        leadList.add(latamCountryLead);
       
        Lead latamCntryLead= new Lead();
        populateLead(latamCntryLead);
        latamCntryLead.Company='rsa';
        latamCntryLead.Country='RSP';
        latamCntryLead.State='RS';
        //latamCntryLead.Iso_Country_Code__c ='RS';
        latamCntryLead.PostalCode ='12346';
        latamCntryLead.Email='br8@abc.test';
        deployCountryMap.put('seven',latamCntryLead.Iso_Country_Code__c);
        leadList.add(latamCntryLead);
        
        Lead latamCntryLead1= new Lead();
        populateLead(latamCntryLead1);
        latamCntryLead1.Company='CD';
        latamCntryLead1.Country='UST';
        latamCntryLead1.State='CD';
        //latamCntryLead1.Iso_Country_Code__c ='CD';
        latamCntryLead1.PostalCode = '23456';
        latamCntryLead1.Email='br9@abc.test';
        deployCountryMap.put('eight',latamCntryLead1.Iso_Country_Code__c);
        leadList.add(latamCntryLead1);
        
        Lead latamCntryLead2= new Lead();
        populateLead(latamCntryLead2);
        latamCntryLead2.Company='Y2';
        latamCntryLead2.Country='SS';
        latamCntryLead2.State='SS';
        //latamCntryLead2.Iso_Country_Code__c ='SS';
        latamCntryLead2.PostalCode = '88888';
        latamCntryLead2.Email='br9@abc.test';
        deployCountryMap.put('nine',latamCntryLead2.Iso_Country_Code__c);
        leadList.add(latamCntryLead2); 
        
        
        Lead nomatchLead = new Lead();
        populateLead(nomatchLead );
        nomatchLead.Company='QW';
        nomatchLead.Country='OP';
        //nomatchLead.Iso_Country_Code__c='OP';
        nomatchLead.State='abcd';
        nomatchLead.PostalCode='99999'; 
        nomatchLead.Email='222@gmail.com';
        deployCountryMap.put('eight1',nomatchLead.Iso_Country_Code__c);
        leadList.add(nomatchLead );
        
        Lead nomatchLead1 = new Lead();
        populateLead(nomatchLead1 );
        nomatchLead1.Company='RT';
        nomatchLead1.Country='RT';
        //nomatchLead1.Iso_Country_Code__c='RT';
        nomatchLead1.State='bcde';
        nomatchLead1.PostalCode='99#9$'; 
        nomatchLead1.Email='222@gmail.com';
        deployCountryMap.put('eight2',nomatchLead1.Iso_Country_Code__c);
        leadList.add(nomatchLead1);
    
        Lead emailDomainLead= new Lead();
        populateLead(emailDomainLead);
        emailDomainLead.Company='YX555555';
        emailDomainLead.Country='ABCD';
        emailDomainLead.Email='br@gov.in';
        leadList.add(emailDomainLead);
        
        Lead emailLead= new Lead();
        populateLead(emailLead);
        emailLead.Company='Y1';
        emailLead.Country='ABCD1';
        emailLead.Email='br9@gmail.testvalue';
        leadList.add(emailLead);
    
    }


    public static void populateLead(Lead objLead)
    {
        objLead.OwnerId=Util.globalLeadRoutingQueue;
        objLead.LastName ='TestR4DeployLead';
        objLead.Title='R4';
        objLead.LeadSourceDetail__c='APAC World Tour';
        objLead.Status='New';
        //objLead.Company='IBM';
        //objLead.Country='ABCD';
        //objLead.State='AB';
        //objLead.Iso_Country_Code__c ='AB';
        objLead.Products_of_Interest__c='JBoss';
        objLead.Partner_Opt_In__c=true;      
        //ObjLead.Email='Paresh@gmail.testvalue';
        //populateemailMap(ObjLead.Email);
        //ObjLead.PostalCode = '12345';
    }
    
        
    public static void populateemailMap(String email)
    {
        String atemailId;
        String dotemailId;
        String[] dotEmail=null;
        String objemailId=email;
        String[] atEmail=objemailId.split('@',2);
        
        if(atEmail.size() >1)
        {
    
            atemailId = atEmail[1].toUpperCase();
            deployemailatMap.put('GOV.IN','GOV.IN');
            dotEmail = atemailId.split('\\.',-1);
            if(dotEmail.size()>1)
            {
            dotemailId=dotEmail[dotEmail.size()-1].toUpperCase();
            deployemaildotMap.put('.'+dotemailId,'.'+dotemailId);
    
            }
    
       }
    }
}