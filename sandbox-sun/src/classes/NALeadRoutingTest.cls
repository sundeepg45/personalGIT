/**
* Class Name: NALeadRoutingTest
* Description:Test Class created for NALeadRouting business Class.
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date :5/3/2011
* Reason for Modification: Separated test class from business class and created a new test class
*/

@isTest
private class NALeadRoutingTest
{
    //Deployment List//
	public static List<LeadAccountRules__c> accrulesList= new List<LeadAccountRules__c>();
	public static List<LeadRules__c> rulesList= new List<LeadRules__c>();
	public static List<LeadCountryMap__c> countryList= new List<LeadCountryMap__c>();
	public static List<Lead> leadList = new List<Lead>();
	public static List<Lead> naLeadList = new List<Lead>();
	public static List<Lead> newBusinessLeadList = new List<Lead>();
	public static List<Id> naIdList = new List<Id>();
	public static Map<String,String> deployCompanyMap = new Map<String,String>();
	public static Map<String,String> deployCountryMap = new Map<String,String>();
	public static Map<String,String> deployStateMap = new Map<String,String>();
	public static Map<String,String> deployMailMap = new Map<String,String>();
	public static LeadMap deployLeadMap= new LeadMap();
	public static Map<String,String> deployemailatMap = new Map<String,String>();
	public static Map<String,String> deployemaildotMap = new Map<String,String>();

	public static testmethod void leadRoutingNA()
	{
        DeactivateAllTestUtil.setDeactivateAll(false);

    	List<String> accountList= new List<String>();
        accountList.add(Util.ldAccount);               
        LeadMap.dbbyPass = false;
        naLeadCountryMapping();
        naLeadAccoutRules();
        naLeadRouting();
        insert  rulesList;
        insert  accrulesList;
        insert countryList;
        //insert  rulesList; 0016000000IqtyrAAB
        insert leadList;
		
		test.startTest();

        Lead newLead = [Select Id, OwnerId from Lead where Company =: 'Acnt'];
        Id id = UserInfo.getUserId();
        
        System.assertEquals(id,newLead.OwnerId);
        
        test.stopTest();
    }
    
    public static testmethod void errorLeadRoutingNA()
	{
        DeactivateAllTestUtil.setDeactivateAll(false);

		LeadCountryMap__c countryMap = new LeadCountryMap__c();
    	countryMap.Country__c = 'USTS';
    	countryMap.Region__c = 'NA';
    	countryMap.ISO_Code__c = 'UST';
    	Insert countryMap;
    	
    	Lead newRevenueLead = new Lead();
        populateLead(newRevenueLead);
        newRevenueLead.OwnerId = Util.naNewBusinessQueue;
        newRevenueLead.Country='USTS';
        newRevenueLead.State='CA';
        newRevenueLead.Company='xyzzz';
        newRevenueLead.PostalCode='06810';
        newRevenueLead.Products_of_Interest__c='RHEL';        
        newRevenueLead.Email='abc@test.in';
        insert newRevenueLead;
        
        test.startTest();
        
        Lead newLead = [Select Id, OwnerId from Lead where Id =: newRevenueLead.Id];
        Group grp = [Select Id,Name from Group where Name = 'NA Sales Dev' AND Type = 'Queue'];
        
        System.assertEquals(grp.id,newLead.OwnerId);
        
        test.stopTest();
	}

    // Creating different Rules for thorugh which Leads will get routed according to diff condition in business logic class.
    public static void naLeadCountryMapping()
    {
    	LeadCountryMap__c countryMap = new LeadCountryMap__c();
    	countryMap.Country__c = 'USS';
    	countryMap.Region__c = 'NA';
    	countryMap.ISO_Code__c = 'US';
    	countryList.add(countryMap);
    	
    	LeadCountryMap__c countryMap1 = new LeadCountryMap__c();
    	countryMap1.Country__c = 'UST';
    	countryMap1.Region__c = 'NA';
    	countryMap1.ISO_Code__c = 'UST';
    	countryList.add(countryMap1); 
    	
    	LeadCountryMap__c countryMap2 = new LeadCountryMap__c();
    	countryMap2.Country__c = 'CAP';
    	countryMap2.Region__c = 'NA';
    	countryMap2.ISO_Code__c = 'CA';
    	countryList.add(countryMap2); 
    	
    	LeadCountryMap__c countryMap3 = new LeadCountryMap__c();
    	countryMap3.Country__c = 'USN';
    	countryMap3.Region__c = 'NA';
    	countryMap3.ISO_Code__c = 'USA';
    	countryList.add(countryMap3); 
    }
    // Creating different Rules for thorugh which Leads will get routed according to diff condition in business logic class.
    public static void naLeadAccoutRules()
    {
        Account acc = new Account(Name='Test Acc');
        acc.Named_Account__c = true;
        insert acc;
                
        Account TestAcc2= new Account();
        TestAcc2.Name='TestAcc2';
        TestAcc2.Named_Account__c=false;
        TestAcc2.isAccountActive__c=true;
        insert TestAcc2;
        
        Account TestAccObj= new Account();
        TestAccObj.Name='TestAccObj';
        TestAccObj.Named_Account__c=true;
        TestAccObj.isAccountActive__c=true;
        insert TestAccObj;
        
        Profile profile = new Profile();
        profile = [select id,name from Profile where UserType = 'PowerPartner' and Name = 'NA Partner Portal – Strategic License' limit 1];
        
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
        
        User usr = new User(alias = 'st6329', email='standarduser6329@testorg.com',
		emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
		localesidkey='en_US', profileid = profile.Id,
		timezonesidkey='America/Los_Angeles', username='standarduser6329@testorg.com',ContactId=con.Id);
		insert usr;
                
        AccountTeamMember AccountTeamMem = new AccountTeamMember ( UserId=UserInfo.getUserId(), AccountId=TestAcc2.Id, TeamMemberRole='Back-Up');
        insert AccountTeamMem;
        
        AccountTeamMember AccTeamMem = new AccountTeamMember ( UserId=usr.Id, AccountId=TestAcc2.Id, TeamMemberRole='Back-Up');
        insert AccTeamMem; 
        
        // NamedAccount Rules
        LeadAccountRules__c namedNaAccountRules= new LeadAccountRules__c();
        namedNaAccountRules.Type__c='Named Account';
        namedNaAccountRules.Value__c='Acn';
        namedNaAccountRules.Account__c=acc.Id;
        namedNaAccountRules.User__c = Util.ldUserId;
        namedNaAccountRules.SuperRegion__c='NA';
        namedNaAccountRules.Country__c='US';
        namedNaAccountRules.State__c='XX';
        namedNaAccountRules.Territory_Exception__c=true;
        accrulesList.add(namedNaAccountRules);

                
        LeadAccountRules__c namedCounrtyAccountRules= new LeadAccountRules__c();
        namedCounrtyAccountRules.Type__c='Named Account';
        namedCounrtyAccountRules.Value__c='Acnt';
        namedCounrtyAccountRules.Account__c=acc.Id;
        namedCounrtyAccountRules.Assign_To_Account_Team_Role__c  ='Account Owner';
        namedCounrtyAccountRules.SuperRegion__c='NA';
        accrulesList.add(namedCounrtyAccountRules);
        
        LeadAccountRules__c namedCounrtyAccTeamRule= new LeadAccountRules__c();
        namedCounrtyAccTeamRule.Type__c='Named Account';
        namedCounrtyAccTeamRule.Value__c='Accnt';
        namedCounrtyAccTeamRule.Account__c=TestAccObj.Id;
        namedCounrtyAccTeamRule.Assign_To_Account_Team_Role__c  ='Back-Up';
        namedCounrtyAccTeamRule.SuperRegion__c='NA';
        accrulesList.add(namedCounrtyAccTeamRule);

        LeadAccountRules__c namedCounrtyAccRules= new LeadAccountRules__c();
        namedCounrtyAccRules.Type__c='Named Account';
        namedCounrtyAccRules.Value__c='Acn';
        namedCounrtyAccRules.Account__c=acc.Id;
        namedCounrtyAccRules.User__c=Util.ldUserId;
        namedCounrtyAccRules.SuperRegion__c='NA';
        namedCounrtyAccRules.Country__c='US';
        accrulesList.add(namedCounrtyAccRules);
        
        //fed Account
        LeadAccountRules__c fedsalesAccountRules= new LeadAccountRules__c();
        fedsalesAccountRules.Type__c='FED Sales';
        fedsalesAccountRules.Value__c='Accenture Fed Sales';
        fedsalesAccountRules.Account__c=acc.Id;
        fedsalesAccountRules.User__c=Util.ldUserId;
        fedsalesAccountRules.SuperRegion__c='NA';
        fedsalesAccountRules.Country__c='US';
        fedsalesAccountRules.Territory_Exception__c=true;
        accrulesList.add(fedsalesAccountRules);

        LeadAccountRules__c fedcountryAccountRules= new LeadAccountRules__c();
        fedcountryAccountRules.Type__c='FED Sales';
        fedcountryAccountRules.Value__c='Accenture Fed Sales 2';
        fedcountryAccountRules.Account__c=acc.Id;
        fedcountryAccountRules.User__c=Util.ldUserId;
        fedcountryAccountRules.SuperRegion__c='NA';
        fedcountryAccountRules.Territory_Exception__c=true;
        accrulesList.add(fedcountryAccountRules);

        // Sled Account rules
        LeadAccountRules__c sledAccountRules= new LeadAccountRules__c();
        sledAccountRules.Type__c='SLED Sales';
        sledAccountRules.Value__c='Accenture SLED Sales';
        sledAccountRules.Account__c=acc.Id;
        sledAccountRules.Assign_To__c = 'NA Sled Sales Queue';
        sledAccountRules.SuperRegion__c='NA';
        sledAccountRules.Country__c='US';
        sledAccountRules.State__c='NY';
        sledAccountRules.Territory_Exception__c=true;
        accrulesList.add(sledAccountRules);
        
        LeadAccountRules__c sledAccRules= new LeadAccountRules__c();
        sledAccRules.Type__c='SLED Sales';
        sledAccRules.Value__c='Accenture EDU Sales';
        sledAccRules.Account__c=acc.Id;
        sledAccRules.Assign_To__c = 'NA EDU Queue';
        sledAccRules.SuperRegion__c='NA';
        sledAccRules.Country__c='US';
        sledAccRules.State__c='NY';
        sledAccRules.Territory_Exception__c=true;
        accrulesList.add(sledAccRules);

        // Territory Account rules
        LeadAccountRules__c naTerritoryAccountRules= new LeadAccountRules__c();
        naTerritoryAccountRules.Type__c='Territory List';
        naTerritoryAccountRules.Value__c='Accenture Territory';
        naTerritoryAccountRules.Account__c=acc.Id;
        naTerritoryAccountRules.User__c=Util.ldUserId;
        naTerritoryAccountRules.SuperRegion__c='NA';
        naTerritoryAccountRules.Country__c='US';
        naTerritoryAccountRules.State__c='NY';
        naTerritoryAccountRules.Territory_Exception__c=true;
        accrulesList.add(naTerritoryAccountRules);

        // Partner Account rules
        LeadAccountRules__c partnerNaAccountRules= new LeadAccountRules__c();
        partnerNaAccountRules.Type__c='Partner Account';
        partnerNaAccountRules.Value__c='IBM1';
        partnerNaAccountRules.Account__c=TestAcc2.Id;
        partnerNaAccountRules.Assign_To_Account_Team_Role__c  ='Account Owner';
        partnerNaAccountRules.SuperRegion__c='NA';
        accrulesList.add(partnerNaAccountRules);
        
        LeadAccountRules__c partnerNaAccountRule= new LeadAccountRules__c();
        partnerNaAccountRule.Type__c='Partner Account';
        partnerNaAccountRule.Value__c='IBM12';
        partnerNaAccountRule.Account__c=TestAcc2.Id;
        partnerNaAccountRule.Assign_To_Account_Team_Role__c  ='Inside SE';
        partnerNaAccountRule.SuperRegion__c='NA';
        accrulesList.add(partnerNaAccountRule);

        LeadAccountRules__c partnerNaAccountRoleRule= new LeadAccountRules__c();
        partnerNaAccountRoleRule.Type__c='Partner Account';
        partnerNaAccountRoleRule.Value__c='IBM11';
        partnerNaAccountRoleRule.SuperRegion__c='NA';
        partnerNaAccountRoleRule.Account__c = TestAcc2.Id;
        partnerNaAccountRoleRule.Assign_To_Account_Team_Role__c  ='Back-Up';
        accrulesList.add(partnerNaAccountRoleRule);
        
		// Sled State rule
        LeadRules__c sledStaterule=new LeadRules__c();
        sledStaterule.Type__c='SLED State';
        sledStaterule.Value__c='XX';
        //sledStaterule.Assign_To__c = 'NA Sales Dev';
        sledStaterule.User__c=Util.ldUserId;
        sledStaterule.SuperRegion__c='NA';
        rulesList.add(sledStaterule);
        
        // EDU State Rule
        LeadRules__c eduStaterule = new LeadRules__c();
        eduStaterule.Type__c='EDU State';
        eduStaterule.Value__c='NC1';
        //sledStaterule.Assign_To__c = 'NA Sales Dev';
        eduStaterule.User__c=Util.ldUserId;
        eduStaterule.SuperRegion__c='NA';
        rulesList.add(eduStaterule);

        // Email Rules
        LeadRules__c emailrule=new LeadRules__c();
        emailrule.Type__c='Email Domain';
        emailrule.Value__c='.testvalue';
        emailrule.User__c=Util.ldUserId;
        emailrule.SuperRegion__c='NA';
        emailrule.Country__c='US';
        emailrule.Email_Overide__c=true;
        rulesList.add(emailrule);
                
        LeadRules__c atEmailRule=new LeadRules__c();
        atEmailRule.Type__c='Email Domain';
        atEmailRule.Value__c='gov.in';
        atEmailRule.User__c=Util.ldUserId;
        atEmailRule.PartnerUser__c = usr.Id;
        atEmailRule.Assign_To_Partner__c = true;
        atEmailRule.SuperRegion__c='NA';
        atEmailRule.Country__c='US';
        rulesList.add(atEmailRule);

        // Business Rules
        LeadRules__c newBusinessCA=new LeadRules__c();
        newBusinessCA.Type__c='New Business State';
        newBusinessCA.Value__c='CP';
        newBusinessCA.User__c=Util.ldUserId;
        newBusinessCA.SuperRegion__c='NA';
        newBusinessCA.Country__c='US';
        rulesList.add(newBusinessCA);

        LeadRules__c newBusinessRule=new LeadRules__c();
        newBusinessRule.Type__c='New Business North Cal';
        newBusinessRule.Zip_Code__c='06810';
        newBusinessRule.Revenue__c=500;
        newBusinessRule.ETR_Assign_To__c=Util.ldUserId;
        newBusinessRule.SMB_Assign_To__c=Util.ldUserId;
        newBusinessRule.SuperRegion__c='NA';
        rulesList.add(newBusinessRule);
        
        LeadRules__c newBusinessRev=new LeadRules__c();
        newBusinessRev.Type__c='New Business Revenue';
        newBusinessRev.Zip_Code__c='06819';
        newBusinessRev.Revenue__c=500;
        newBusinessRev.Value__c='CA';
        newBusinessRev.ETR_Assign_To__c=Util.ldUserId;
        newBusinessRev.SMB_Assign_To__c=Util.ldUserId;
        newBusinessRev.SuperRegion__c='NA';
        rulesList.add(newBusinessRev);
        
        LeadRules__c newBusinessRevCC=new LeadRules__c();
        newBusinessRevCC.Type__c='New Business Revenue';
        newBusinessRevCC.Zip_Code__c='06819';
        newBusinessRevCC.Revenue__c=500;
        newBusinessRevCC.Value__c='CC';
        newBusinessRevCC.ETR_Assign_To__c=Util.ldUserId;
        newBusinessRevCC.SMB_Assign_To__c=Util.ldUserId;
        newBusinessRevCC.SuperRegion__c='NA';
        rulesList.add(newBusinessRevCC);
                
        // New Commercial Rules
        LeadRules__c newCO =new LeadRules__c();
        newCO.Type__c='NA Commercial';
        newCO.Zip_Code__c='27601';
        newCO.Product_Of_Interest__c='Platform';
        newCO.Value__c='NC';
        newCO.Revenue__c=500;
        newCO.Territory_Assign_to__c=Util.ldUserId;
        newCO.New_Business_Assign_To__c=Util.ldUserId;
        newCO.SuperRegion__c='NA';
        rulesList.add(newCO);

        LeadRules__c newCO1 =new LeadRules__c();
        newCO1.Type__c='NA Commercial';
        newCO1.Zip_Code__c='27602';
        newCO1.Value__c='NC1';
        newCO1.Product_Of_Interest__c='Middleware';
        newCO1.Revenue__c=500;
        newCO1.Territory_Partner_User__c=Util.ldUserId;
        newCO1.New_Business_Partner_User__c=Util.ldUserId;
        newCO1.Assign_To_Partner__c = true;
        newCO1.SuperRegion__c='NA';
        rulesList.add(newCO1);

        LeadRules__c newCO2 =new LeadRules__c();
        newCO2.Type__c='NA Commercial';
        newCO2.Product_Of_Interest__c='Platform';
        newCO2.Value__c='NC3';
        newCO2.Revenue__c=500;
        newCO2.Zip_Code__c='27602';
        newCO2.Territory_Assign_to__c=Util.ldUserId;
        newCO2.New_Business_Assign_To__c=Util.ldUserId;                          
        newCO2.SuperRegion__c='NA';
        rulesList.add(newCO2);

        LeadRules__c newCO3 =new LeadRules__c();
        newCO3.Type__c='NA Commercial';
        newCO3.Value__c='PA1';
        newCO3.Product_Of_Interest__c='Cloud';
        newCO3.Revenue__c=500;
        newCO3.Zip_Code__c='27605';
        newCO3.Territory_Partner_User__c=Util.ldUserId;
        newCO3.New_Business_Partner_User__c=Util.ldUserId;             
        newCO3.Assign_To_Partner__c = true;
        newCO3.SuperRegion__c='NA';
        rulesList.add(newCO3);
                
        LeadRules__c newCO4 =new LeadRules__c();
        newCO4.Type__c='NA Commercial';
        newCO4.Value__c='PA2';
        newCO4.Product_Of_Interest__c='Management';
        newCO4.Revenue__c=100;
        newCO4.Territory_Assign_to__c=Util.ldUserId;
        newCO4.New_Business_Assign_To__c=Util.ldUserId;
        newCO4.SuperRegion__c='NA';
        rulesList.add(newCO4);
                
        LeadRules__c newCO5 =new LeadRules__c();
        newCO5.Type__c='NA Commercial';
        newCO5.Value__c='PA2';
        newCO5.Product_Of_Interest__c='Cloud';
        newCO5.Revenue__c=100;
        newCO5.Territory_Partner_User__c=Util.ldUserId;
        newCO5.New_Business_Partner_User__c=Util.ldUserId;            
        newCO5.Assign_To_Partner__c = true;
        newCO5.SuperRegion__c='NA';
        rulesList.add(newCO5);
                
    }

    /* Creating different Leads corresponding to the rules created above thorugh which Leads will get routed according to diff 
       condition in business logic class.
    */
    public static void naLeadRouting()
    {
        // Leads to route through NamedAccount rules.
        Lead namedAccountNaLead= new Lead();
        populateLead(namedAccountNaLead);
        namedAccountNaLead.Company='Acn';
        namedAccountNaLead.Country='USS';
        namedAccountNaLead.State='XX';       
        namedAccountNaLead.Products_of_Interest__c='GLS';        
        //namedAccountNaLead.Iso_Country_Code__c='US';
        deployCompanyMap.put('one',namedAccountNaLead.Company);
        leadList.add(namedAccountNaLead);
        
        Lead namedAccNaLead= new Lead();
        populateLead(namedAccNaLead);
        namedAccNaLead.Company='Acnt';
        namedAccNaLead.Country='UST';
        namedAccNaLead.State='XX';       
        namedAccNaLead.Products_of_Interest__c='GLS';        
        //namedAccNaLead.Iso_Country_Code__c='US';
        deployCompanyMap.put('one11',namedAccNaLead.Company);
        leadList.add(namedAccNaLead);
        
        Lead namedAccNaTeamLead= new Lead();
        populateLead(namedAccNaTeamLead);
        namedAccNaTeamLead.Company='Accnt';
        namedAccNaTeamLead.Country='UST';
        namedAccNaTeamLead.State='XX';       
        namedAccNaTeamLead.Products_of_Interest__c='GLS';
        leadList.add(namedAccNaTeamLead);
               
        Lead nameCountrydNaLead= new Lead();
        populateLead(nameCountrydNaLead);
        nameCountrydNaLead.Company='Acn';
        nameCountrydNaLead.Country='USS';
        nameCountrydNaLead.Products_of_Interest__c='GLS';
        //nameCountrydNaLead.Iso_Country_Code__c='US';
        deployCompanyMap.put('five',nameCountrydNaLead.Company);
        leadList.add(nameCountrydNaLead);

        // Leads to route through Fed Account rules.
        Lead fedAccountNaLead= new Lead();
        populateLead(fedAccountNaLead);
        fedAccountNaLead.Company='Accenture Fed Sales';
        fedAccountNaLead.Country='USS';
        fedAccountNaLead.Products_of_Interest__c='GLS';
        //fedAccountNaLead.Iso_Country_Code__c='US';
        fedAccountNaLead.State='NY';
        deployCompanyMap.put('two',fedAccountNaLead.Company);
        leadList.add(fedAccountNaLead);


        Lead fedCountryAccountNaLead= new Lead();
        populateLead(fedCountryAccountNaLead);
        fedCountryAccountNaLead.Company='Accenture Fed Sales 2';
        fedCountryAccountNaLead.Country='CAP';
        //fedCountryAccountNaLead.Iso_Country_Code__c='US';
        fedCountryAccountNaLead.State='CA';
        fedCountryAccountNaLead.Products_of_Interest__c='GLS';
        fedCountryAccountNaLead.AnnualRevenue=1000;
        fedCountryAccountNaLead.PostalCode='06810';
        deployCompanyMap.put('six',fedCountryAccountNaLead.Company);
        leadList.add(fedCountryAccountNaLead);


        Lead fedCountryAccountNaLeadz= new Lead();
        populateLead(fedCountryAccountNaLeadz);
        fedCountryAccountNaLeadz.Company='Accenture Fed Sales 2';
        fedCountryAccountNaLeadz.Country='USS';
        //fedCountryAccountNaLeadz.Iso_Country_Code__c='US';
        fedCountryAccountNaLeadz.State='CA';
        fedCountryAccountNaLeadz.Products_of_Interest__c='GLS';
        fedCountryAccountNaLeadz.PostalCode='06810';
        deployCompanyMap.put('sixz',fedCountryAccountNaLeadz.Company);
        leadList.add(fedCountryAccountNaLeadz);

        // Leads to route through SLEDAccount rules.
        Lead sledAccountNaLead= new Lead();
        populateLead(sledAccountNaLead);
        sledAccountNaLead.Company='Accenture SLED Sales';
        sledAccountNaLead.Country='USS';
        //sledAccountNaLead.Iso_Country_Code__c='US';
        sledAccountNaLead.Products_of_Interest__c='GLS';
        sledAccountNaLead.State='NY';
        deployCompanyMap.put('three',sledAccountNaLead.Company);
        leadList.add(sledAccountNaLead);
        
        Lead sledAccNaLead= new Lead();
        populateLead(sledAccNaLead);
        sledAccNaLead.Company='Accenture EDU Sales';
        sledAccNaLead.Country='USS';
        //sledAccountNaLead.Iso_Country_Code__c='US';
        sledAccNaLead.Products_of_Interest__c='GLS';
        sledAccNaLead.State='NY';
        deployCompanyMap.put('three',sledAccNaLead.Company);
        //LeadRules__c records are routing to an inactive user - commenting out this test lead for now (SLC 24 Aug 2012)
        //leadList.add(sledAccNaLead);

		// Leads to route through TerritoryAccount rules.
        Lead territoryAccountNaLead= new Lead();
        populateLead(territoryAccountNaLead);
        territoryAccountNaLead.Company='Accenture Territory';
        territoryAccountNaLead.Country='USS';
        territoryAccountNaLead.Products_of_Interest__c='GLS';
        //territoryAccountNaLead.Iso_Country_Code__c='US';
        territoryAccountNaLead.State='NY';
        deployCompanyMap.put('four',territoryAccountNaLead.Company);
        leadList.add(territoryAccountNaLead);

		// Leads to route through PartnerAccount rules.
        Lead partnerAccountnaLead= new Lead();
        populateLead(partnerAccountnaLead);
        partnerAccountnaLead.Company='IBM1';
        partnerAccountnaLead.Country='USS';
        partnerAccountnaLead.Products_of_Interest__c='GLS';
        partnerAccountnaLead.State='CA';
        partnerAccountnaLead.PostalCode='06810';
        //partnerAccountnaLead.Iso_Country_Code__c='US';
        deployCompanyMap.put('seven',partnerAccountnaLead.Company);
        leadList.add(partnerAccountnaLead);
        
        Lead partnerAccnaLead= new Lead();
        populateLead(partnerAccnaLead);
        partnerAccnaLead.Company='IBM12';
        partnerAccnaLead.Country='USS';
        partnerAccnaLead.Products_of_Interest__c='GLS';
        partnerAccnaLead.State='CA';
        partnerAccnaLead.PostalCode='06810';
        //partnerAccountnaLead.Iso_Country_Code__c='US';
        deployCompanyMap.put('seven',partnerAccnaLead.Company);
        leadList.add(partnerAccnaLead);
                
        Lead partnerAccountLead= new Lead();
        populateLead(partnerAccountLead);
        partnerAccountLead.Company='IBM11';
        partnerAccountLead.Country='USS';
        partnerAccountLead.Products_of_Interest__c='GLS';
        partnerAccountLead.State='CA';
        partnerAccountLead.PostalCode='06810';
        //partnerAccountLead.Iso_Country_Code__c='US';
        deployCompanyMap.put('eight',partnerAccountLead.Company);
        leadList.add(partnerAccountLead);
        
        Lead partnerAccLead= new Lead();
        populateLead(partnerAccLead);
        partnerAccLead.Company='IBM111';
        partnerAccLead.Country='USS';
        partnerAccLead.Products_of_Interest__c='GLS';
        partnerAccLead.State='CA';
        partnerAccLead.PostalCode='06810';
        //partnerAccLead.Iso_Country_Code__c='US';
        deployCompanyMap.put('eight8',partnerAccLead.Company);
        leadList.add(partnerAccLead);

        // Leads to route through Email Domain rules.
        Lead emailDomainLead= new Lead();
        populateLead(emailDomainLead);
        emailDomainLead.Company='Y';
        emailDomainLead.Country='USS';
        //emailDomainLead.Iso_Country_Code__c='US';
        emailDomainLead.Products_of_Interest__c='GLS';
        //emailDomainLead.Email='us@gov.in';
        leadList.add(emailDomainLead);
        
        Lead atEmailLead= new Lead();
        populateLead(atEmailLead);
        atEmailLead.Company='Y';
        atEmailLead.Country='USS';
        //atEmailLead.Iso_Country_Code__c='US';
        atEmailLead.Products_of_Interest__c='GLS';
        atEmailLead.Email='us@gov.in';
        populateemailMap(atEmailLead.Email);
        leadList.add(atEmailLead);
                
        // Leads to route through New Commercial rules.
        Lead newcomm = new Lead();
        populateLead(newcomm);
                           
        newcomm.Country='USS';
        newcomm.State='NC';
        newcomm.Company='xyz';
        newcomm.PostalCode='27601';
        //newcomm.Iso_Country_Code__c='US';
        newcomm.AnnualRevenue = 111;
        newcomm.Products_of_Interest__c='RHEL';
        newcomm.Email='abc@test.in';
        deployStateMap.put('one',newcomm.State);
        leadList.add(newcomm);
        
        Lead newCommercial = new Lead();
        populateLead(newCommercial);
        newCommercial.Country='USN';
        newCommercial.State='CC';
        newCommercial.Company='xyzabc';
        newCommercial.PostalCode='411013';
        //newCommercial.Iso_Country_Code__c='USA';
        newCommercial.AnnualRevenue = 1111;
        newCommercial.Products_of_Interest__c='RHELL';
        newCommercial.Email='abc@test.in';
        deployStateMap.put('one1',newCommercial.State);
        leadList.add(newCommercial);
		
        Lead newCommObj = new Lead();
        populateLead(newCommObj);
        newCommObj.Country='USS';
        newCommObj.State='NC1';
        newCommObj.Company='xyz1';
        //newCommObj.PostalCode='27601';
        //newCommObj.Iso_Country_Code__c='US';
        newCommObj.AnnualRevenue = 999;
        newCommObj.Products_of_Interest__c='GFS';
        newCommObj.Email='abc@test.in';
        deployStateMap.put('two',newCommObj.State);
        leadList.add(newCommObj);
        
        Lead newcomm1 = new Lead();
        populateLead(newcomm1);
        newcomm1.Country='USS';
        newcomm1.State='NC1';
        newcomm1.Company='xyz1';
        newcomm1.PostalCode='27602';
        //newcomm1.Iso_Country_Code__c='US';
        newcomm1.AnnualRevenue = 999;
        newcomm1.Products_of_Interest__c='Portals';
        newcomm1.Email='abc@test.in';
        deployStateMap.put('two',newcomm1.State);
        leadList.add(newcomm1);
        
        Lead newcom1 = new Lead();
        populateLead(newcom1);
        newcom1.OwnerId = Util.naEduQueue;
        newcom1.Country='USS';
        newcom1.State='NC1';
        newcom1.Company='xyz1';
        newcom1.PostalCode='27602';
        //newcomm1.Iso_Country_Code__c='US';
        newcom1.AnnualRevenue = 999;
        newcom1.Products_of_Interest__c='Portals';
        newcom1.Email='abc@test.in';
        deployStateMap.put('two',newcom1.State);
        leadList.add(newcom1);

        Lead newcomm2 = new Lead();
        populateLead(newcomm2);
        newcomm2.OwnerId = Util.naSledSalesQueue;
        newcomm2.Country='USS';
        newcomm2.State='XX';
        newcomm2.Company='xyz2';
        newcomm2.PostalCode='27602';
        //newcomm2.Iso_Country_Code__c='US';
        newcomm2.Products_of_Interest__c='JBoss Operations Network';
        newcomm2.AnnualRevenue = 999;            
        newcomm2.Email='abc@test.in';
        deployStateMap.put('three',newcomm2.State);
        leadList.add(newcomm2);            
                
        Lead newcomm2T = new Lead();
        populateLead(newcomm2T);
        newcomm2T.OwnerId = Util.naNewBusinessQueue;
        newcomm2T.Country='USS';
        newcomm2T.State='CP';
        newcomm2T.Company='xyz2';
        newcomm2T.PostalCode='06810';
        //newcomm2T.Iso_Country_Code__c='US';
        newcomm2T.Products_of_Interest__c='RHEL';
        newcomm2T.AnnualRevenue = 999;             
        newcomm2T.Email='abc@test.in';
        deployStateMap.put('four',newcomm2T.State);
        leadList.add(newcomm2T);
        
        Lead newBusinessLead = new Lead();
        populateLead(newBusinessLead);
        newBusinessLead.OwnerId = Util.naNewBusinessQueue;
        newBusinessLead.Country='USS';
        newBusinessLead.State='CA';
        newBusinessLead.Company='xyzz';
        newBusinessLead.PostalCode='06810';
        //newBusinessLead.Iso_Country_Code__c='US';
        newBusinessLead.Products_of_Interest__c='RHEL';
        newBusinessLead.AnnualRevenue = 9;       
        newBusinessLead.Email='abc@test.in';
        deployStateMap.put('four2',newBusinessLead.State);
        leadList.add(newBusinessLead);
        
        Lead newRevenueLead = new Lead();
        populateLead(newRevenueLead);
        newRevenueLead.OwnerId = Util.naNewBusinessQueue;
        newRevenueLead.Country='USS';
        newRevenueLead.State='CA';
        newRevenueLead.Company='xyzzz';
        newRevenueLead.PostalCode='06810';
        //newRevenueLead.Iso_Country_Code__c='US';
        newRevenueLead.Products_of_Interest__c='RHEL';        
        newRevenueLead.Email='abc@test.in';
        deployStateMap.put('four22',newRevenueLead.State);
        leadList.add(newRevenueLead);
        
        Lead nbRevenueLessLead = new Lead();
        populateLead(nbRevenueLessLead);
        nbRevenueLessLead.OwnerId = Util.naNewBusinessQueue;
        nbRevenueLessLead.Country='USN';
        nbRevenueLessLead.State='CC';
        nbRevenueLessLead.Company='xyzbc';
        nbRevenueLessLead.PostalCode='411013';
        //nbRevenueLessLead.Iso_Country_Code__c='USA';
        nbRevenueLessLead.AnnualRevenue = 1110;
        nbRevenueLessLead.Products_of_Interest__c='RHELL';
        nbRevenueLessLead.Email='abc@test.in';
        deployStateMap.put('one111',nbRevenueLessLead.State);
        leadList.add(nbRevenueLessLead);
        
        Lead nbRevenueLead = new Lead();
        populateLead(nbRevenueLead);
        nbRevenueLead.Country='USN';
        nbRevenueLead.OwnerId = Util.naNewBusinessQueue;
        nbRevenueLead.State='CC';
        nbRevenueLead.Company='xyzab';
        nbRevenueLead.PostalCode='411013';
        //nbRevenueLead.Iso_Country_Code__c='USA';
        nbRevenueLead.Products_of_Interest__c='RHELL';
        nbRevenueLead.Email='abc@test.in';
        deployStateMap.put('one11',nbRevenueLead.State);
        leadList.add(nbRevenueLead);       
               
        Lead newBusiErrorLead = new Lead();
        populateLead(newBusiErrorLead);
        newBusiErrorLead.OwnerId = Util.naNewBusinessQueue;
        newBusiErrorLead.Country='USS';
        newBusiErrorLead.State='CC';
        newBusiErrorLead.Company='xyzzx';
        //newBusiErrorLead.PostalCode='068109';
        //newBusiErrorLead.Iso_Country_Code__c='US';
        newBusiErrorLead.Products_of_Interest__c='RHEL';
        newBusiErrorLead.AnnualRevenue = 9;       
        newBusiErrorLead.Email='abc@test.in';
        deployStateMap.put('four222',newBusiErrorLead.State);
        leadList.add(newBusiErrorLead);

        Lead newcomm2LT = new Lead();
        populateLead(newcomm2LT);
        newcomm2LT.Country='USS';
        newcomm2LT.State='NC3';
        newcomm2LT.Company='xyz2';
        newcomm2LT.PostalCode='27602';
        //newcomm2LT.Iso_Country_Code__c='US';
        newcomm2LT.Products_of_Interest__c='RHEL';
        newcomm2LT.AnnualRevenue = 999;             
        newcomm2LT.Email='abc@test.in';
        deployStateMap.put('four1',newcomm2LT.State);
        leadList.add(newcomm2LT);
                
        Lead newcomm2L = new Lead();
        populateLead(newcomm2L);
        newcomm2L.Country='USS';
        newcomm2L.State='PA2';
        newcomm2L.Company='xyz2';
        newcomm2L.PostalCode='27602';
        //newcomm2L.Iso_Country_Code__c='US';
        newcomm2L.Products_of_Interest__c='Cloud Computing';
        newcomm2L.AnnualRevenue =111 ;              
        newcomm2L.Email='abc@test.in';
        deployStateMap.put('five',newcomm2L.State);
        leadList.add(newcomm2L);  
                
        Lead newcomm2R = new Lead();
        populateLead(newcomm2R);
        newcomm2R.Country='USS';
        newcomm2R.State='CP';
        newcomm2R.Company='xyz2';
        newcomm2R.PostalCode='27602';
        //newcomm2R.Iso_Country_Code__c='US';
        newcomm2R.Products_of_Interest__c='JBoss';
        newcomm2R.Email='abc@test.in';
        deployStateMap.put('six',newcomm2R.State);
        leadList.add(newcomm2R);

        
        Lead newcomm3 = new Lead();
        populateLead(newcomm3);
        newcomm3.Country='USS';
        newcomm3.State='PA2';
        newcomm3.Company='xyz3';
        newcomm3.AnnualRevenue = 50;
        //newcomm3.Iso_Country_Code__c='US';
        newcomm3.Products_of_Interest__c='JBoss Operations Network';
        newcomm3.PostalCode='11127';
        newcomm3.Email='abc@test.in';
        deployStateMap.put('seven',newcomm3.State);
        leadList.add(newcomm3);

        Lead newcomm3L = new Lead();
        populateLead(newcomm3L);
        newcomm3L.Country='USS';
        newcomm3L.State='PA1';
        newcomm3L.Company='xyz3';
        newcomm3L.AnnualRevenue = 111;
        //newcomm3L.Iso_Country_Code__c='US';
        newcomm3L.Products_of_Interest__c='Cloud Computing';
        newcomm3L.PostalCode='27605';
        newcomm3L.Email='abc@test.in';
        deployStateMap.put('eight',newcomm3L.State);
        leadList.add(newcomm3L);

        Lead newcomm4 = new Lead();
        populateLead(newcomm4);
        newcomm4.Country='USS';
        newcomm4.State='PA2';
        newcomm4.Company='xyz4';
        newcomm4.AnnualRevenue = 999;
        //newcomm4.Iso_Country_Code__c='US';
        newcomm4.Products_of_Interest__c='RHN';
        newcomm4.PostalCode='11166';
        newcomm4.Email='abc@test.in';
        newcomm4.Partner_Opt_In__c=true;
        deployStateMap.put('nine',newcomm4.State);
        leadList.add(newcomm4);


        Lead newcomm4L = new Lead();
        populateLead(newcomm4L);
        newcomm4L.Country='USS';
        newcomm4L.State='PA2';
        newcomm4L.Company='xyz4';
        newcomm4L.AnnualRevenue = 50;
        //newcomm4L.Iso_Country_Code__c='US';
        newcomm4L.Products_of_Interest__c='Cloud Computing';
        newcomm4L.PostalCode='11166';
        newcomm4L.Email='abc@test.in';
        newcomm4L.Partner_Opt_In__c=true;
        deployStateMap.put('ten',newcomm4L.State);
        leadList.add(newcomm4L);   
                
        Lead newcomm5 = new Lead();
        populateLead(newcomm5);
        newcomm5.Country='USS';
        //newcomm5.State='PA4';
        newcomm5.Company='ACNPune';
        newcomm5.AnnualRevenue = 111;
        //newcomm5.Iso_Country_Code__c='US';
        newcomm5.Products_of_Interest__c='JBoss';
        newcomm5.Email='kal@test.in';
        deployStateMap.put('eleven',newcomm5.State);
        leadList.add(newcomm5);

        Lead newcomm5e = new Lead();
        populateLead(newcomm5e);
        newcomm5e.Country='USS';
        newcomm5e.State='AA';
        newcomm5e.Company='ACNPune';
        newcomm5e.AnnualRevenue = 111;
        //newcomm5e.Iso_Country_Code__c='US';
        newcomm5e.Products_of_Interest__c='JBoss';
        newcomm5e.Email='kal@test.in';
        deployStateMap.put('twelve',newcomm5e.State);
        leadList.add(newcomm5e);

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
        ObjLead.Email='Paresh@gmail.testvalue';
        populateemailMap(ObjLead.Email);
        //objLead.Iso_Country_Code__c='US';
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
            deployemailatMap.put(atemailId,atemailId);
            dotEmail = atemailId.split('\\.',-1);
            if(dotEmail.size()>1)
            {
                dotemailId=dotEmail[dotEmail.size()-1].toUpperCase();
                deployemaildotMap.put('.'+dotemailId,'.'+dotemailId);
            }
        }
    }
//deployment method ends*/
}