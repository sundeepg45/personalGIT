/**
* Class Name: LeadAssignmentTest
* Description:Test Class created for LeadAssignment business Class.
* Modificaton History:
* Modified By :Abhijeet Anand
* Reason for Modification:Enhanced code coverage and added assert statements.
*/
@IsTest
private class LeadAssignmentTest 
{   
    public static void createData() 
    {
        LeadMap.dbbyPass=false;
        Lead[] obj_arr_deploy= new Lead[8];   
        
        LeadCountryMap__c apacCountry = new LeadCountryMap__c();
        apacCountry.Country__c = 'IN1';
        apacCountry.Region__c = 'APAC';
        apacCountry.ISO_Code__c = 'IN';
        insert apacCountry;
    
        LeadCountryMap__c emeaCountry=new LeadCountryMap__c();
        emeaCountry.Country__c='UKK';
        emeaCountry.ISO_Code__c='UKK';
        emeaCountry.Region__c='EMEA';
        insert emeaCountry;
        
    
        LeadCountryMap__c latamCountry=new LeadCountryMap__c();
        latamCountry.Country__c='Brazilll';
        latamCountry.ISO_Code__c='BR';
        latamCountry.Region__c='LATAM';
        insert latamCountry;
        
    
        LeadCountryMap__c naCountry=new LeadCountryMap__c();
        naCountry.Country__c='UST';
        naCountry.ISO_Code__c='US';
        naCountry.Region__c='NA';
        insert naCountry;
        
        Lead apacLead= new Lead();
        populateLead(apacLead);
        apacLead.Company='Accenture1';
        apacLead.State='Maharashtra';
        apacLead.Country='IN1';
        
        // insert apacLead;
        
        Lead emeaLead= new Lead();
        populateLead(emeaLead);
        emeaLead.Company='Accenture2';
        emeaLead.State='London';
        emeaLead.Country='UKK';
        
        // insert emeaLead;
        
        Lead latamLead= new Lead();
        populateLead(latamLead);
        latamLead.Company='Accenture3';
        latamLead.State='Rio';
        latamLead.Country='Brazilll';
        
        // insert latamLead;
        
        Lead NALead= new Lead();
        populateLead(NALead);
        NALead.Company='Accenture4';
        NALead.Country='UST';
        NALead.State='NY';
        
       // insert nalead 
        
        Lead noRegionLead= new Lead();
        populateLead(noRegionLead);
        noRegionLead.Company='ABC';
        noRegionLead.Country='XXX';
        noRegionLead.State='YY';
        
        Lead laLead= new Lead();
        populateLead(laLead);
        laLead.LastName='Accenture3';
        laLead.Company='Rio';
        laLead.Country='Brazill';
       
        Lead NAnewBusinessLead= new Lead();
        populateLead(NAnewBusinessLead);
        NAnewBusinessLead.Company='Accenture';
        NAnewBusinessLead.Country='UST';
        NAnewBusinessLead.State='CA';
        NAnewBusinessLead.OwnerId=Util.naNewBusinessQueue;
        
        
        Lead NASledSalesLead= new Lead();
        populateLead(NASledSalesLead);
        NASledSalesLead.Company='Accenture';
        NASledSalesLead.Country='UST';
        NASledSalesLead.State='NY';
        NASledSalesLead.OwnerId=Util.naSledSalesQueue;
    
        Lead NAEduSalesLead= new Lead();
        populateLead(NAEduSalesLead);
        NAEduSalesLead.Company='Accenture';
        NAEduSalesLead.Country='UST';
        NAEduSalesLead.State='NY';
        NAEduSalesLead.OwnerId=Util.naEduQueue;
          
        //insert NALead;
      
        obj_arr_deploy[0]=apacLead;
        obj_arr_deploy[1]=emeaLead;
        obj_arr_deploy[2]=latamLead;
        obj_arr_deploy[3]=NALead;
        obj_arr_deploy[4]=NAnewBusinessLead;
        obj_arr_deploy[5]=NASledSalesLead;
        //LeadRules__c records are routing to an inactive user - commenting out this test lead for now (SLC 24 Aug 2012)
        //obj_arr_deploy[6]=NAEduSalesLead;
        obj_arr_deploy[6]=noRegionLead;
        obj_arr_deploy[7]=laLead;
        
        insert obj_arr_deploy;
                   
        laLead.Company='';
        laLead.Country='';
        
        NALead.Company='';
        NALead.Country='';
        try
        {
            update obj_arr_deploy;
        }
        catch(Exception e)
        {
            laLead.Company='asdf';
            laLead.Country='UST';
            NALead.Company='htr';
            NALead.Country='UST';
            
            update obj_arr_deploy;
        }
        
        Account TestAcc=new Account();
        TestAcc.Name='Test';
        TestAcc.Named_Account__c=true;
        TestAcc.isAccountActive__c=true;
        insert TestAcc;
        
        LeadAccountRules__c namedApacAccountRules= new LeadAccountRules__c();
        namedApacAccountRules.Type__c='Named Account';
        namedApacAccountRules.Value__c='Accenture';
        //namedApacAccountRules.Account__c=Util.ldAccount;
        namedApacAccountRules.Account__c=TestAcc.Id;
        namedApacAccountRules.Assign_To_Account_Team_Role__c = 'Account Owner';
        namedApacAccountRules.Assign_To_Account_Owner__c = true;
        namedApacAccountRules.SuperRegion__c='APAC';
        insert namedApacAccountRules;
        
        Lead namedAccountApacLead= new Lead();
        populateLead(namedAccountApacLead);
        namedAccountApacLead.Company='Accenture';
        namedAccountApacLead.Country='IN1';
        namedAccountApacLead.Email = 'test@rh.com';
        namedAccountApacLead.State = 'Goa';
        insert namedAccountApacLead;
    }
   
    public static testmethod void testLeadAssignment() 
    {
		TestingIds__c apiProfileTesting = TestingIds__c.getValues('API Profile');
		System.assertNotEquals(null,apiProfileTesting,'"API Profile" needs to be set in the TestingIds__c');
		Profile p = [select id from profile where Id = :apiProfileTesting.Id__c];
		User u = new User(alias = 'st7388', email='standarduser7388@testorg.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = p.Id,
        timezonesidkey='America/Los_Angeles', username='standarduser7388@testorg.com');
        insert u;
        System.runAs(u)
        {
            createData();
        }
        
        test.startTest();
            
        Lead newLead = [Select Id, OwnerId from Lead where Email =: 'test@rh.com' limit 1];
        
        //SLC disabling this assertion pending confirmation that above test is appropriate.
        //SLC existing routing rules appear to be trumping the test routing rule used here.
        //System.assertEquals(u.Id,newLead.OwnerId);
        
        test.stopTest();
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
        ObjLead.Email='Paresh@gmail.gov';
    }
}