/**
* Class Name:EMEALeadRoutingTest
* Description:Test Class created for EMEALeadRouting business Class.
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date :4/29/2011
* Reason for Modification: Separated test class from business class and created a new test class.
* Modified date :6/5/2011
* Reason for Modification: Enhanced the test coverage.
*/

@IsTest
private class EMEALeadRoutingTest
{
    public static List<LeadAccountRules__c> accrulesList= new List<LeadAccountRules__c>();
    public static List<LeadRules__c> rulesList= new List<LeadRules__c>();
    public static List<Lead> leadList = new List<Lead>();
    public static List<LeadCountryMap__c> countryList= new List<LeadCountryMap__c>();
    public static Map<String,String> deployCompanyMap = new Map<String,String>();
    public static Map<String,String> deployCountryMap = new Map<String,String>();
    public static Map<String,String> deployStateMap = new Map<String,String>();
    public static Map<String,String> deployemailatMap = new Map<String,String>();
    public static Map<String,String> deployemaildotMap = new Map<String,String>();
    public static LeadMap deployLeadMap= new LeadMap();
    public static String GLOBAL_LEAD_ROUTING_ERROR = 'GLR Error Queue';
    
    
    public static testmethod void emeaLeadTest()
    {
        DeactivateAllTestUtil.setDeactivateAll(false);

        LeadMap.dbbyPass = false;
        emeaLeadCountryMapping();                       
        emeaLeadAccoutRules();
        emeaLeadRouting();
        insert countryList;     
        insert  accrulesList;
        insert  rulesList;
        insert leadList;
        
        deployemailatMap.put('GOV.IN','GOV.IN');
        deployemaildotMap.put('.TESTVALUE','.TESTVALUE');
        //new EMEALeadRouting().assignQueue(leadList,deployCompanyMap,deployCountryMap,deployLeadMap,deployemailatMap,deployemaildotMap);
        
        test.startTest();
        
        Lead newLead = [Select Id, OwnerId from Lead where Company =: 'testAcn'];
        
        System.assertEquals(Util.ldUserId,newLead.OwnerId);
        
        test.stopTest();
    }
    
    public static testmethod void emeaErrorLeadTest()
    {
        DeactivateAllTestUtil.setDeactivateAll(false);

        LeadCountryMap__c countryMap = new LeadCountryMap__c();
        countryMap.Country__c = 'UKP';
        countryMap.Region__c = 'EMEA';
        countryMap.ISO_Code__c = 'UKP';
        insert countryMap;
        
        Lead emeaContryLead= new Lead();
        populateLead(emeaContryLead);
        emeaContryLead.Company='Y';
        emeaContryLead.Country='UKP';
        emeaContryLead.Email='br@abc.testtttttt';
        //emeaCountryLead.ISO_Country_Code__c = 'GR';
        insert emeaContryLead;
        
        test.startTest();
        
        Lead newLead = [Select Id, OwnerId from Lead where Id =: emeaContryLead.Id];
        Group grp =[Select Id,Name from Group where Name = 'GLR Error Queue' AND Type = 'Queue'];
        System.assertEquals(grp.Id,newLead.OwnerId);
        
        test.stopTest();
    }
    
    public static void emeaLeadCountryMapping()
    {
        LeadCountryMap__c contryMap = new LeadCountryMap__c();
        contryMap.Country__c = 'UKS';
        contryMap.Region__c = 'EMEA';
        contryMap.ISO_Code__c = 'UKS';
        countryList.add(contryMap);
        
        LeadCountryMap__c countryMap = new LeadCountryMap__c();
        countryMap.Country__c = 'UKT';
        countryMap.Region__c = 'EMEA';
        countryMap.ISO_Code__c = 'UK';
        countryList.add(countryMap);
        
        LeadCountryMap__c countryMap1 = new LeadCountryMap__c();
        countryMap1.Country__c = 'GRT';
        countryMap1.Region__c = 'EMEA';
        countryMap1.ISO_Code__c = 'GR';
        countryList.add(countryMap1); 
        
        LeadCountryMap__c countryMap2 = new LeadCountryMap__c();
        countryMap2.Country__c = 'SMP';
        countryMap2.Region__c = 'EMEA';
        countryMap2.ISO_Code__c = 'SM';
        countryList.add(countryMap2); 

    }
    
    // Creating rules as per conditions available in business logic class so that leads can route through these rules.
    public static void emeaLeadAccoutRules()
    {
                
        Account TestAcc= new Account();
        TestAcc.Name='Test';
        TestAcc.Named_Account__c=true;
        TestAcc.isAccountActive__c=true;
        insert TestAcc;

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
        
        Profile profile = new Profile();
        profile = [select id,name from Profile where UserType = 'PowerPartner' and Name = 'EMEA Partner Portal – Strategic License' limit 1];
        
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
        
        User usr = new User(alias = 'st3412', email='standarduser3412@testorg.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profile.Id,
        timezonesidkey='America/Los_Angeles', username='standarduser3412@testorg.com',ContactId=con.Id);
        insert usr;
        
        AccountTeamMember AccountTeamMem = new AccountTeamMember ( UserId=UserInfo.getUserId(), AccountId=TestAcc2.Id, TeamMemberRole='Back-Up');
        insert AccountTeamMem;
        
        AccountTeamMember AccountTeamMemObj = new AccountTeamMember ( UserId=Util.ldUserId, AccountId=TestAcc2.Id, TeamMemberRole='Inside Rep');
        insert AccountTeamMemObj;
        
        AccountTeamMember AccountTeamMemIns = new AccountTeamMember ( UserId=usr.Id, AccountId=TestAcc2.Id, TeamMemberRole='Inside Rep');
        insert AccountTeamMemIns;
        
        
        // NamedAccount rules
        LeadAccountRules__c namedemeaAccountRules= new LeadAccountRules__c();
        namedemeaAccountRules.Type__c='Named Account';
        namedemeaAccountRules.Value__c='testAcn';
        namedemeaAccountRules.Account__c=TestAcc.Id;
        namedemeaAccountRules.User__c=Util.ldUserId;
        namedemeaAccountRules.SuperRegion__c='EMEA';
        accrulesList.add(namedemeaAccountRules);
        
        LeadAccountRules__c emeaNamedAccountRules= new LeadAccountRules__c();
        emeaNamedAccountRules.Type__c='Named Account';
        emeaNamedAccountRules.Value__c='testAcn1';
        emeaNamedAccountRules.Account__c=TestAcc.Id;
        emeaNamedAccountRules.User__c=Util.ldUserId;
        emeaNamedAccountRules.SuperRegion__c='EMEA';
        emeaNamedAccountRules.Country__c = 'GR';
        accrulesList.add(emeaNamedAccountRules);

        // PartenrAccount rules    
        LeadAccountRules__c partneremeaAccountRules= new LeadAccountRules__c();
        partneremeaAccountRules.Type__c='Partner Account';
        partneremeaAccountRules.Value__c='testAcc2';
        partneremeaAccountRules.Account__c=TestAcc2.Id;
        partneremeaAccountRules.Assign_To_Account_Team_Role__c  ='Account Owner';
        partneremeaAccountRules.SuperRegion__c='EMEA';
        accrulesList.add(partneremeaAccountRules);

        LeadAccountRules__c partneremeaAccountRule2= new LeadAccountRules__c();
        partneremeaAccountRule2.Type__c='Partner Account';
        partneremeaAccountRule2.Value__c='testAlias';
        partneremeaAccountRule2.Account__c=TestAcc2.Id;
        partneremeaAccountRule2.SuperRegion__c='EMEA';
        partneremeaAccountRule2.Assign_To_Account_Team_Role__c  ='Back-Up';
        accrulesList.add(partneremeaAccountRule2);
        
        LeadAccountRules__c partneremeaAccRule= new LeadAccountRules__c();
        partneremeaAccRule.Type__c='Partner Account';
        partneremeaAccRule.Value__c='testAlia';
        partneremeaAccRule.Account__c=TestAcc2.Id;
        partneremeaAccRule.SuperRegion__c='EMEA';
        partneremeaAccRule.Assign_To_Account_Team_Role__c  ='Inside Rep';
        accrulesList.add(partneremeaAccRule);
        
        LeadAccountRules__c ptnrEmeaAccRule= new LeadAccountRules__c();
        ptnrEmeaAccRule.Type__c='Partner Account';
        ptnrEmeaAccRule.Value__c='testAli';
        ptnrEmeaAccRule.Account__c=TestAcc2.Id;
        ptnrEmeaAccRule.SuperRegion__c='EMEA';
        ptnrEmeaAccRule.Assign_To_Account_Team_Role__c  ='Outside Rep';
        accrulesList.add(ptnrEmeaAccRule);
        
        LeadAccountRules__c emeaPartnerAccRule= new LeadAccountRules__c();
        emeaPartnerAccRule.Type__c='Partner Account';
        emeaPartnerAccRule.Value__c='testAl';
        emeaPartnerAccRule.Account__c=TestAccObj.Id;
        emeaPartnerAccRule.SuperRegion__c='EMEA';
        emeaPartnerAccRule.Assign_To_Account_Team_Role__c  ='Outside Rep';
        accrulesList.add(emeaPartnerAccRule);
        
        // Country rules
        LeadRules__c emeaCountryRuleAll = new LeadRules__c();
        emeaCountryRuleAll.User__c = Util.ldUserId;
        emeaCountryRuleAll.Type__c = 'Country';
        emeaCountryRuleAll.Value__c = 'ALL';
        emeaCountryRuleAll.SuperRegion__c = 'EMEA';
        rulesList.add(emeaCountryRuleAll);
        
        LeadRules__c emeaCountryRule = new LeadRules__c();
        emeaCountryRule.User__c = Util.ldUserId;
        emeaCountryRule.Type__c = 'COUNTRY';
        emeaCountryRule.Value__c = 'GRT';
        emeaCountryRule.SuperRegion__c = 'EMEA';   
        rulesList.add(emeaCountryRule);
        
        // Email rules
        LeadRules__c emailrule=new LeadRules__c();
        emailrule.Type__c='Email Domain';
        emailrule.Value__c='.testvalue';
        emailrule.User__c=Util.ldUserId;
        emailrule.SuperRegion__c='EMEA';
        emailrule.Country__c='UKT';
        emailrule.Email_Overide__c=true;
        rulesList.add(emailrule);
        
        LeadRules__c emeaEmailrule = new LeadRules__c();
        emeaEmailrule.Type__c = 'Email Domain';
        emeaEmailrule.Value__c = 'GOV.IN';
        emeaEmailrule.User__c = Util.ldUserId;
        emeaEmailrule.PartnerUser__c = usr.Id;
        emeaEmailrule.Assign_To_Partner__c = true;
        emeaEmailrule.SuperRegion__c = 'EMEA';
        emeaEmailrule.Country__c = 'US';
        rulesList.add(emeaEmailrule);

    }

    // Creating Leads so that they can route through the rules creayed above.
    public static void emeaLeadRouting()
    {
        // Leads that will route through NamedAccount rules.
        Lead namedAccountemeaLead= new Lead();
        populateLead(namedAccountemeaLead);
        namedAccountemeaLead.Company='testAcn';
        deployCompanyMap.put('one',namedAccountemeaLead.Company);
        namedAccountemeaLead.Country='UKT';
        namedAccountemeaLead.Email = 'test@redhat.com';
        leadList.add(namedAccountemeaLead);
        
        Lead emeaNamedAccountLead= new Lead();
        populateLead(emeaNamedAccountLead);
        emeaNamedAccountLead.Company='testAcn1';
        emeaNamedAccountLead.Country='GRT';
        emeaNamedAccountLead.Email = 'test@redhat.nitcom';
        //emeaNamedAccountLead.Iso_Country_Code__c = 'GR';
        leadList.add(emeaNamedAccountLead);

        Lead partnerAccountemeaLead= new Lead();
        populateLead(partnerAccountemeaLead);
        partnerAccountemeaLead.Company='testAcc2';
        deployCompanyMap.put('Three',partnerAccountemeaLead.Company);
        partnerAccountemeaLead.Country='UKT';
        partnerAccountemeaLead.Email = 'test@redhat.com';
        leadList.add(partnerAccountemeaLead);

        // Leads that will route through PartnerAccount rules.
        Lead partnerAccountemeaLead2= new Lead();
        populateLead(partnerAccountemeaLead2);
        partnerAccountemeaLead2.Company='testAlias';
        deployCompanyMap.put('four',partnerAccountemeaLead2.Company);
        partnerAccountemeaLead2.Country='UKT';
        partnerAccountemeaLead2.Email = 'test@redhat.com';
        leadList.add(partnerAccountemeaLead2);
        
        Lead partnerAccemeaLead= new Lead();
        populateLead(partnerAccemeaLead);
        partnerAccemeaLead.Company='testAlia';
        deployCompanyMap.put('five',partnerAccemeaLead.Company);
        partnerAccemeaLead.Country='UKT';
        partnerAccemeaLead.Email = 'test@redhat.com';
        leadList.add(partnerAccemeaLead);
        
        Lead ptnrAccemeaLead= new Lead();
        populateLead(ptnrAccemeaLead);
        ptnrAccemeaLead.Company='testAli';
        deployCompanyMap.put('six',ptnrAccemeaLead.Company);
        ptnrAccemeaLead.Country='UKT';
        ptnrAccemeaLead.Email = 'test@redhat.com';
        leadList.add(ptnrAccemeaLead);
        
        Lead emeaPtnrAccLead= new Lead();
        populateLead(emeaPtnrAccLead);
        emeaPtnrAccLead.Company='testAl';
        emeaPtnrAccLead.Country='UKT';
        emeaPtnrAccLead.Email = 'test@redhat.nitcom';
        leadList.add(emeaPtnrAccLead);
        
        // Leads that will route through Country rules.
        Lead emeaCountryLead= new Lead();
        populateLead(emeaCountryLead);
        emeaCountryLead.Company='Y';
        emeaCountryLead.Country='GRT';
        emeaCountryLead.Email='br@abc.niteshtest';
        //emeaCountryLead.ISO_Country_Code__c = 'GR';
        deployCountryMap.put('one',emeaCountryLead.Country);
        leadList.add(emeaCountryLead);
        
        Lead emeaContryLead= new Lead();
        populateLead(emeaContryLead);
        emeaContryLead.Company='YT';
        emeaContryLead.Country='UKS';
        emeaContryLead.Email='br@abc.testtttttt';
        //emeaCountryLead.ISO_Country_Code__c = 'GR';
        leadList.add(emeaContryLead);
        
        Lead emeaCountryLead1= new Lead();
        populateLead(emeaCountryLead1);
        emeaCountryLead1.Company='B';
        emeaCountryLead1.Country='SMP';
        //emeaCountryLead1.ISO_Country_Code__c = 'SM';
        emeaCountryLead1.Email='br@abc.niteshtest';
        deployCountryMap.put('two',emeaCountryLead1.Country);
        leadList.add(emeaCountryLead1);
        
        // Leads that will route through Email Domain rules.
        Lead emailDomainLead= new Lead();
        populateLead(emailDomainLead);
        emailDomainLead.Company='Y';
        emailDomainLead.Country='UKT';
        //emailDomainLead.ISO_Country_Code__c = 'UK';
        emailDomainLead.Email='br@gov.in';
        leadList.add(emailDomainLead);
        
        Lead emeaEmailLead= new Lead();
        populateLead(emeaEmailLead);
        emeaEmailLead.Company='Y';
        emeaEmailLead.Country='UKT';
        //emailDomainLead.ISO_Country_Code__c = 'UK';
        emeaEmailLead.Email='br@gmail.testvalue';
        leadList.add(emeaEmailLead);
    }


    public static void populateLead(Lead objLead)
    {
        objLead.OwnerId=Util.globalLeadRoutingQueue;
        objLead.LastName ='TestR4DeployLead';
        objLead.Title='R4';
        objLead.LeadSourceDetail__c='APAC World Tour';
        objLead.Status='New';
        objLead.Products_of_Interest__c='JBoss';
        objLead.Partner_Opt_In__c=true;
        //ObjLead.Email='Paresh@gmail.testvalue';
        //populateemailMap(ObjLead.Email);
        
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