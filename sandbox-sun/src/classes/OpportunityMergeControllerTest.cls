/*****************************************************************************************
    Name    : OpportunityMergeControllerTest 
    Desc    : This class will handle the test scenarios of OpportunityMergeController class
                            
Modification Log : 
---------------------------------------------------------------------------
Developer              Date            Description
---------------------------------------------------------------------------
Pankaj Banik           18 Jan 2015          Created
******************************************************************************************/

@isTest
private class OpportunityMergeControllerTest {
    static testMethod void testOpportunityMergeStart() 
    {
        // TO DO: implement unit test for opportunityMerge class
        
        // Variable to store Recordtype id
        string recordtypeid;
        
        //Create Sales Account
        Account salesAccount = new Account();
        
        //Fetch account record type
        recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
        salesAccount.Name = 'Test Sales Account1';
        salesAccount.CurrencyIsoCode = 'USD';
        salesAccount.RecordTypeId = recordTypeId;
        insert salesAccount;
        
        
        //Create Opportunity
        Opportunity firstOpportunityForMerge = new Opportunity();
        Opportunity secondOpportunityForMerge = new Opportunity();
        Opportunity thirdOpportunityForMerge = new Opportunity();        
        List<Opportunity> opportunityList = new List<Opportunity>();
        recordtypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('APAC Sales Opportunity').getRecordTypeId();
        
        // Opportunity No 1
        firstOpportunityForMerge.Name = '1234';
        firstOpportunityForMerge.StageName = 'Closed Booked';
        firstOpportunityForMerge.Amount = 12345;
        firstOpportunityForMerge.RecordTypeID = recordtypeid;
        firstOpportunityForMerge.Type = 'Standard';
        firstOpportunityForMerge.CloseDate = System.Today();
        firstOpportunityForMerge.PaymentType__c = 'Credit Card';
        firstOpportunityForMerge.FulfillmentChannel__c = 'Direct - End Customer';
        firstOpportunityForMerge.Country_of_Order__c = 'Australia';
        firstOpportunityForMerge.AccountId = salesAccount.Id;
        firstOpportunityForMerge.CurrencyIsoCode = 'USD';
        firstOpportunityForMerge.Pay_Now__c = 'Yes';
        firstOpportunityForMerge.ForecastCategoryName = 'Pipeline';
        firstOpportunityForMerge.Deal_Registration__c = true;
        firstOpportunityForMerge.LeadSourceDetail__c = 'Test';
        firstOpportunityForMerge.Year1PaymentAmount__c = 10000;
        firstOpportunityForMerge.Year2PaymentAmount__c = 2000;
        firstOpportunityForMerge.Year3PaymentAmount__c = 300;
        firstOpportunityForMerge.Year4PaymentAmount__c = 40;
        firstOpportunityForMerge.Year5PaymentAmount__c = 5;
        firstOpportunityForMerge.Year6PaymentAmount__c = 0;
        opportunityList.add(firstOpportunityForMerge);
        
        // Opportunity No 2
        secondOpportunityForMerge.Name = '1232';
        secondOpportunityForMerge.StageName = 'Prepare';
        secondOpportunityForMerge.Amount = 12345;
        secondOpportunityForMerge.RecordTypeID = recordtypeid;
        secondOpportunityForMerge.Type = 'Standard';
        secondOpportunityForMerge.CloseDate = System.Today();
        secondOpportunityForMerge.PaymentType__c ='Credit Card' ;
        secondOpportunityForMerge.FulfillmentChannel__c = 'Direct - End Customer';
        secondOpportunityForMerge.Country_of_Order__c = 'India';
        secondOpportunityForMerge.AccountId = salesAccount.Id;
        secondOpportunityForMerge.CurrencyIsoCode = 'AUD';
        secondOpportunityForMerge.Pay_Now__c = 'Yes';
        secondOpportunityForMerge.ForecastCategoryName = 'Pipeline';
        secondOpportunityForMerge.Deal_Registration__c = false;
        secondOpportunityForMerge.LeadSourceDetail__c = 'Test';
        secondOpportunityForMerge.Year1PaymentAmount__c = 12000;
        secondOpportunityForMerge.Year2PaymentAmount__c = 300;
        secondOpportunityForMerge.Year3PaymentAmount__c = 45;
        secondOpportunityForMerge.Year4PaymentAmount__c = 0;
        secondOpportunityForMerge.Year5PaymentAmount__c = 0;
        secondOpportunityForMerge.Year6PaymentAmount__c = 0;   
        opportunityList.add(secondOpportunityForMerge);
        insert opportunityList;
        firstOpportunityForMerge.stageName= 'Closed Booked';
        update firstOpportunityForMerge;

        Classification__c partnerType = new Classification__c();
        partnerType.Name = 'Partner Type';
        partnerType.ReferenceKey__c = 'PARTNER_TYPE';
        partnerType.IsActive__c = true;
        partnerType.IsInlineEdit__c = true;
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
        
        List <OpportunityPartner__c> partnersOpp = new List <OpportunityPartner__c>();
        
        OpportunityPartner__c f1 = new OpportunityPartner__c();
        f1.Opportunity__c = opportunityList[0].id;
        f1.Partner__c = financialAccount.Id;
        f1.PartnerTier__c = affiliated.Id;
        f1.PartnerType__c = distributor.Id;
        f1.RelationshipType__c = 'Financial';
        partnersOpp.add(f1); 
        
        OpportunityPartner__c f2 = new OpportunityPartner__c();
        f2.Partner__c = financialAccount.Id;
        f2.PartnerTier__c = affiliated.Id;
        f2.PartnerType__c = distributor.Id;
        f2.RelationshipType__c = 'Financial';
        f2.Opportunity__c = opportunityList[1].Id;
        partnersOpp.add(f2);
        
        insert partnersOpp;
        
        Profile profile = [select id from profile where Name like '%Sales%'  limit 1];
        User testUser1 = [Select id from User where profileid =: profile.id and isActive = true Limit 1];
                
        List <OpportunityTeamMember> teamMembers = new List <OpportunityTeamMember>();
        
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember(
          UserId=testUser1.id,
          OpportunityId=opportunityList[0].id,
          TeamMemberRole='Test Role');
        teamMembers.add(teamMember1);
        
        OpportunityTeamMember teamMember2 = new OpportunityTeamMember(
          UserId=testUser1.id,
          OpportunityId=opportunityList[1].id,
          TeamMemberRole='Test Role');
        teamMembers.add(teamMember2);
        
        insert teamMembers;
        
        List<OpportunitySplit> splits = new List<OpportunitySplit>();
        OpportunitySplit split1 = new OpportunitySplit(OpportunityId=opportunityList[0].id,
                                                        SplitOwnerId=testUser1.id, SplitPercentage=0);
        OpportunitySplit split2 = new OpportunitySplit(OpportunityId=opportunityList[1].id,       
                                                        SplitOwnerId=testUser1.id, SplitPercentage=0);
        splits.add(split1);
        splits.add(split2);
        
        insert splits;
        
        //Calling the OpportunityMergePage
        PageReference pageReference = Page.OpportunityMergePage;
        Test.setCurrentPage(pageReference);
        
        
        //passing Sales Account Id
        ApexPages.currentPage().getParameters().put('id', opportunityList[0].id);
        // Initiating test case
        test.starttest();
        // Creating object for opportunityMerge class
        OpportunityMergeController mergeController = new OpportunityMergeController();
        
        mergeController.validateMerge();
        
        system.assertNotEquals(null,mergeController); 
        system.assertNotEquals(null,mergeController.sourceOpportunities);    
        
        // Selecting records to be merged
        mergeController.sourceOpportunities[0].radioButton= true;        
        
        //Clicking of Select Button
        mergeController.onSelectButtonClick();
        test.stoptest();
        
       //End of Test
                
    }
    static testMethod void testOpportunityMerge() 
    {
        // TO DO: implement unit test for opportunityMerge class
        
        // Variable to store Recordtype id
        string recordtypeid;
        
        //Create Sales Account
        Account salesAccount = new Account();
        
        //Fetch account record type
        recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
        salesAccount.Name = 'Test Sales Account1';
        salesAccount.CurrencyIsoCode = 'USD';
        salesAccount.RecordTypeId = recordTypeId;
        insert salesAccount;
        
        
        //Create Opportunity
        Opportunity firstOpportunityForMerge = new Opportunity();
        Opportunity secondOpportunityForMerge = new Opportunity();
        Opportunity thirdOpportunityForMerge = new Opportunity();        
        List<Opportunity> opportunityList = new List<Opportunity>();
        recordtypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('APAC Sales Opportunity').getRecordTypeId();
        
        // Opportunity No 1
        firstOpportunityForMerge.Name = '1234';
        firstOpportunityForMerge.StageName = 'Closed Booked';
        firstOpportunityForMerge.Amount = 12345;
        firstOpportunityForMerge.RecordTypeID = recordtypeid;
        firstOpportunityForMerge.Type = 'Standard';
        firstOpportunityForMerge.CloseDate = System.Today();
        firstOpportunityForMerge.PaymentType__c = 'Credit Card';
        firstOpportunityForMerge.FulfillmentChannel__c = 'Direct - End Customer';
        firstOpportunityForMerge.Country_of_Order__c = 'Australia';
        firstOpportunityForMerge.AccountId = salesAccount.Id;
        firstOpportunityForMerge.CurrencyIsoCode = 'USD';
        firstOpportunityForMerge.Pay_Now__c = 'Yes';
        firstOpportunityForMerge.ForecastCategoryName = 'Pipeline';
        firstOpportunityForMerge.Deal_Registration__c = true;
        firstOpportunityForMerge.LeadSourceDetail__c = 'Test';
        firstOpportunityForMerge.Year1PaymentAmount__c = 10000;
        firstOpportunityForMerge.Year2PaymentAmount__c = 2000;
        firstOpportunityForMerge.Year3PaymentAmount__c = 300;
        firstOpportunityForMerge.Year4PaymentAmount__c = 40;
        firstOpportunityForMerge.Year5PaymentAmount__c = 5;
        firstOpportunityForMerge.Year6PaymentAmount__c = 0;
        opportunityList.add(firstOpportunityForMerge);
        
        // Opportunity No 2
        secondOpportunityForMerge.Name = '1232';
        secondOpportunityForMerge.StageName = 'Prepare';
        secondOpportunityForMerge.Amount = 12345;
        secondOpportunityForMerge.RecordTypeID = recordtypeid;
        secondOpportunityForMerge.Type = 'Standard';
        secondOpportunityForMerge.CloseDate = System.Today();
        secondOpportunityForMerge.PaymentType__c ='Credit Card' ;
        secondOpportunityForMerge.FulfillmentChannel__c = 'Direct - End Customer';
        secondOpportunityForMerge.Country_of_Order__c = 'India';
        secondOpportunityForMerge.AccountId = salesAccount.Id;
        secondOpportunityForMerge.CurrencyIsoCode = 'AUD';
        secondOpportunityForMerge.Pay_Now__c = 'Yes';
        secondOpportunityForMerge.ForecastCategoryName = 'Pipeline';
        secondOpportunityForMerge.Deal_Registration__c = false;
        secondOpportunityForMerge.LeadSourceDetail__c = 'Test';
        secondOpportunityForMerge.Year1PaymentAmount__c = 12000;
        secondOpportunityForMerge.Year2PaymentAmount__c = 300;
        secondOpportunityForMerge.Year3PaymentAmount__c = 45;
        secondOpportunityForMerge.Year4PaymentAmount__c = 0;
        secondOpportunityForMerge.Year5PaymentAmount__c = 0;
        secondOpportunityForMerge.Year6PaymentAmount__c = 0;   
        opportunityList.add(secondOpportunityForMerge);
        insert opportunityList;
        firstOpportunityForMerge.stageName= 'Closed Booked';
        update firstOpportunityForMerge;

        Classification__c partnerType = new Classification__c();
        partnerType.Name = 'Partner Type';
        partnerType.ReferenceKey__c = 'PARTNER_TYPE';
        partnerType.IsActive__c = true;
        partnerType.IsInlineEdit__c = true;
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
        
        List <OpportunityPartner__c> partnersOpp = new List <OpportunityPartner__c>();
        
        OpportunityPartner__c f1 = new OpportunityPartner__c();
        f1.Opportunity__c = opportunityList[0].id;
        f1.Partner__c = financialAccount.Id;
        f1.PartnerTier__c = affiliated.Id;
        f1.PartnerType__c = distributor.Id;
        f1.RelationshipType__c = 'Financial';
        partnersOpp.add(f1); 
        
        OpportunityPartner__c f2 = new OpportunityPartner__c();
        f2.Partner__c = financialAccount.Id;
        f2.PartnerTier__c = affiliated.Id;
        f2.PartnerType__c = distributor.Id;
        f2.RelationshipType__c = 'Financial';
        f2.Opportunity__c = opportunityList[1].Id;
        partnersOpp.add(f2);
        
        insert partnersOpp;
        
        Profile profile = [select id from profile where Name like '%Sales%'  limit 1];
        User testUser1 = [Select id from User where profileid =: profile.id and isActive = true Limit 1];
                
        List <OpportunityTeamMember> teamMembers = new List <OpportunityTeamMember>();
        
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember(
          UserId=testUser1.id,
          OpportunityId=opportunityList[0].id,
          TeamMemberRole='Test Role');
        teamMembers.add(teamMember1);
        
        OpportunityTeamMember teamMember2 = new OpportunityTeamMember(
          UserId=testUser1.id,
          OpportunityId=opportunityList[1].id,
          TeamMemberRole='Test Role');
        teamMembers.add(teamMember2);
        
        insert teamMembers;
        
        List<OpportunitySplit> splits = new List<OpportunitySplit>();
        OpportunitySplit split1 = new OpportunitySplit(OpportunityId=opportunityList[0].id,
                                                        SplitOwnerId=testUser1.id, SplitPercentage=0);
        OpportunitySplit split2 = new OpportunitySplit(OpportunityId=opportunityList[1].id,
        
                                                        SplitOwnerId=testUser1.id, SplitPercentage=0);
        splits.add(split1);
        splits.add(split2);
        
        insert splits;
        
        //Calling the OpportunityMergePage
        PageReference pageReference = Page.OpportunityMergePage;
        Test.setCurrentPage(pageReference);
        
        
        //passing Sales Account Id
        ApexPages.currentPage().getParameters().put('id', opportunityList[0].id);
        
        // Creating object for opportunityMerge class
        OpportunityMergeController mergeController = new OpportunityMergeController();
        
        mergeController.validateMerge();
        
        system.assertNotEquals(null,mergeController); 
        system.assertNotEquals(null,mergeController.sourceOpportunities);    
        
        // Selecting records to be merged
        mergeController.sourceOpportunities[0].radioButton= true;        
        
        //Clicking of Select Button
        mergeController.onSelectButtonClick();
        
        // Initiating test case
        test.starttest();
        
        //Clicking of Merge Button
        mergeController.onMerge();
        system.assertEquals('Closed Lost',[select Id, StageName from Opportunity where Id =:mergeController.selectedSourceOpportunity.Id].StageName);
       //End of Test
        test.stoptest();        
    }
    static testMethod void testOpportunityMergeClose() 
    {
        // TO DO: implement unit test for opportunityMerge class
        
        // Variable to store Recordtype id
        string recordtypeid;
        
        //Create Sales Account
        Account salesAccount = new Account();
        
        //Fetch account record type
        recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('APAC Account').getRecordTypeId();
        salesAccount.Name = 'Test Sales Account1';
        salesAccount.CurrencyIsoCode = 'USD';
        salesAccount.RecordTypeId = recordTypeId;
        insert salesAccount;
        
        
        //Create Opportunity
        Opportunity firstOpportunityForMerge = new Opportunity();
        Opportunity secondOpportunityForMerge = new Opportunity();
        Opportunity thirdOpportunityForMerge = new Opportunity();        
        List<Opportunity> opportunityList = new List<Opportunity>();
        recordtypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('APAC Sales Opportunity').getRecordTypeId();
        
        // Opportunity No 1
        firstOpportunityForMerge.Name = '1234';
        firstOpportunityForMerge.StageName = 'Closed Booked';
        firstOpportunityForMerge.Amount = 12345;
        firstOpportunityForMerge.RecordTypeID = recordtypeid;
        firstOpportunityForMerge.Type = 'Standard';
        firstOpportunityForMerge.CloseDate = System.Today();
        firstOpportunityForMerge.PaymentType__c = 'Credit Card';
        firstOpportunityForMerge.FulfillmentChannel__c = 'Direct - End Customer';
        firstOpportunityForMerge.Country_of_Order__c = 'Australia';
        firstOpportunityForMerge.AccountId = salesAccount.Id;
        firstOpportunityForMerge.CurrencyIsoCode = 'USD';
        firstOpportunityForMerge.Pay_Now__c = 'Yes';
        firstOpportunityForMerge.ForecastCategoryName = 'Pipeline';
        firstOpportunityForMerge.Deal_Registration__c = true;
        firstOpportunityForMerge.LeadSourceDetail__c = 'Test';
        firstOpportunityForMerge.Year1PaymentAmount__c = 10000;
        firstOpportunityForMerge.Year2PaymentAmount__c = 2000;
        firstOpportunityForMerge.Year3PaymentAmount__c = 300;
        firstOpportunityForMerge.Year4PaymentAmount__c = 40;
        firstOpportunityForMerge.Year5PaymentAmount__c = 5;
        firstOpportunityForMerge.Year6PaymentAmount__c = 0;
        opportunityList.add(firstOpportunityForMerge);
        
        // Opportunity No 2
        secondOpportunityForMerge.Name = '1232';
        secondOpportunityForMerge.StageName = 'Prepare';
        secondOpportunityForMerge.Amount = 12345;
        secondOpportunityForMerge.RecordTypeID = recordtypeid;
        secondOpportunityForMerge.Type = 'Standard';
        secondOpportunityForMerge.CloseDate = System.Today();
        secondOpportunityForMerge.PaymentType__c ='Credit Card' ;
        secondOpportunityForMerge.FulfillmentChannel__c = 'Direct - End Customer';
        secondOpportunityForMerge.Country_of_Order__c = 'India';
        secondOpportunityForMerge.AccountId = salesAccount.Id;
        secondOpportunityForMerge.CurrencyIsoCode = 'AUD';
        secondOpportunityForMerge.Pay_Now__c = 'Yes';
        secondOpportunityForMerge.ForecastCategoryName = 'Pipeline';
        secondOpportunityForMerge.Deal_Registration__c = false;
        secondOpportunityForMerge.LeadSourceDetail__c = 'Test';
        secondOpportunityForMerge.Year1PaymentAmount__c = 12000;
        secondOpportunityForMerge.Year2PaymentAmount__c = 300;
        secondOpportunityForMerge.Year3PaymentAmount__c = 45;
        secondOpportunityForMerge.Year4PaymentAmount__c = 0;
        secondOpportunityForMerge.Year5PaymentAmount__c = 0;
        secondOpportunityForMerge.Year6PaymentAmount__c = 0;   
        opportunityList.add(secondOpportunityForMerge);
        insert opportunityList;
        firstOpportunityForMerge.stageName= 'Closed Booked';
        update firstOpportunityForMerge;

        Classification__c partnerType = new Classification__c();
        partnerType.Name = 'Partner Type';
        partnerType.ReferenceKey__c = 'PARTNER_TYPE';
        partnerType.IsActive__c = true;
        partnerType.IsInlineEdit__c = true;
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
        
        List <OpportunityPartner__c> partnersOpp = new List <OpportunityPartner__c>();
        
        OpportunityPartner__c f1 = new OpportunityPartner__c();
        f1.Opportunity__c = opportunityList[0].id;
        f1.Partner__c = financialAccount.Id;
        f1.PartnerTier__c = affiliated.Id;
        f1.PartnerType__c = distributor.Id;
        f1.RelationshipType__c = 'Financial';
        partnersOpp.add(f1); 
        
        OpportunityPartner__c f2 = new OpportunityPartner__c();
        f2.Partner__c = financialAccount.Id;
        f2.PartnerTier__c = affiliated.Id;
        f2.PartnerType__c = distributor.Id;
        f2.RelationshipType__c = 'Financial';
        f2.Opportunity__c = opportunityList[1].Id;
        partnersOpp.add(f2);
        
        insert partnersOpp;
        
        Profile profile = [select id from profile where Name like '%Sales%'  limit 1];
        User testUser1 = [Select id from User where profileid =: profile.id and isActive = true Limit 1];
                
        List <OpportunityTeamMember> teamMembers = new List <OpportunityTeamMember>();
        
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember(
          UserId=testUser1.id,
          OpportunityId=opportunityList[0].id,
          TeamMemberRole='Test Role');
        teamMembers.add(teamMember1);
        
        OpportunityTeamMember teamMember2 = new OpportunityTeamMember(
          UserId=testUser1.id,
          OpportunityId=opportunityList[1].id,
          TeamMemberRole='Test Role');
        teamMembers.add(teamMember2);
        
        insert teamMembers;
        
        List<OpportunitySplit> splits = new List<OpportunitySplit>();
        OpportunitySplit split1 = new OpportunitySplit(OpportunityId=opportunityList[0].id,
                                                        SplitOwnerId=testUser1.id, SplitPercentage=0);
        OpportunitySplit split2 = new OpportunitySplit(OpportunityId=opportunityList[1].id,
        
                                                        SplitOwnerId=testUser1.id, SplitPercentage=0);
        splits.add(split1);
        splits.add(split2);
        
        insert splits;
        
        //Calling the OpportunityMergePage
        PageReference pageReference = Page.OpportunityMergePage;
        Test.setCurrentPage(pageReference);
        
        
        //passing Sales Account Id
        ApexPages.currentPage().getParameters().put('id', opportunityList[0].id);
        
        // Creating object for opportunityMerge class
        OpportunityMergeController mergeController = new OpportunityMergeController();
        
        mergeController.validateMerge();
        
        system.assertNotEquals(null,mergeController); 
        system.assertNotEquals(null,mergeController.sourceOpportunities);    
        
        // Selecting records to be merged
        mergeController.sourceOpportunities[0].radioButton= true;        
        
        //Clicking of Select Button
        mergeController.onSelectButtonClick();
        
        // Initiating test case
        test.starttest();
        
        String nextPageOnClickOfMerge = mergeController.onMerge().getUrl();
        String actualPage ='/'+ opportunityList[0].id;
        // Verify that the success page displays
        
        //Checking for updated opportunity
        system.assertEquals('Closed Lost',[select Id, StageName from Opportunity where Id =:mergeController.selectedSourceOpportunity.Id].StageName);
        
        //Clicking of Cancel Button
        mergeController.cancel();
        String nextPageOnClickOfCancel = mergeController.cancel().getUrl();
        actualPage ='/'+  opportunityList[0].id;
        
       //End of Test
        test.stoptest();        
    }
}