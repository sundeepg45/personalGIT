/**
 * Test class for OpportunityRedirectControllerExtension.cls
 *
 * @version 2015-05-12
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-05-12 - added coverage test of recallApproval
 * 2014-04-09 - change zero dollar order to zero value opportunity
 * 2014-03-05 - Added test case for zero dollar orders with errors.
 * 2013-11-13 - Updated to use new POC_Enabled__c object & fixed broken tests
 * 2013-06-10 - Add testing for proof of concept redirect
 * 2012-04-18 - Update for Security Model Redesign
 * Modified: Scott Coleman <scoleman@redhat.com>
 * 2013-10-08 - Added coverage for POC button enhancement
 * 2013-02-15 - Added test for enabling POC button
 */
@isTest(SeeAllData=false) // need all data to access custom settings
private class OpportunityRedirectControllerExtTest {

    static Account account {
        get {
            if(account == null) {
                RecordType recordType = [select Id,name from RecordType where name = 'Strategic' limit 1];
                account = new Account(name='account',RecordTypeId=recordType.Id,AccountClassification__c=recordType.name);
                insert account;
            }
            return account;
        }
    }

    static User xuser {
        get {
            if(xuser == null) {
                xuser = new User(Id=UserInfo.getUserId());
            }
            return xuser;
        }
    }

    static void createClassifications() {
        Classification__c pType = null;
        Classification__c pTier = null;
        for(Classification__c c : [select HierarchyKey__c from Classification__c where Name in (:Opportunity_ManagePartners.PARTNER_TYPE_ROOTKEY,:Opportunity_ManagePartners.PARTNER_TIER_ROOTKEY ) and Parent__c = null])
        {
            if(c.HierarchyKey__c == Opportunity_ManagePartners.PARTNER_TYPE_ROOTKEY) {
                pType = c;
            }
            else if(c.HierarchyKey__c == Opportunity_ManagePartners.PARTNER_TIER_ROOTKEY) {
                pTier = c;
            }
        }
        if(pType == null) {
            pType=new Classification__c(Name='Partner Type',ReferenceKey__c=Opportunity_ManagePartners.PARTNER_TYPE_ROOTKEY);
            insert pType;
        }
        if(pTier == null) {
            pTier = new Classification__c(Name='Partner Tier',ReferenceKey__c=Opportunity_ManagePartners.PARTNER_TIER_ROOTKEY);
            insert pTier;
        }
        Classification__c childType = new Classification__c(
            Name='Test',
            ReferenceKey__c='TEST',
            Parent__c=pType.Id);
        Classification__c childTier = new Classification__c(
            Name='Test',
            ReferenceKey__c='TEST',
            Parent__c=pTier.Id);
        insert new List<Classification__c>{childType,childTier};
    }

    static Opportunity opportunity1 {
        get {
            if(opportunity1 == null) {
                opportunity1 = new Opportunity(
                    Name='OpportunityRedirectControllerExtension Test',
                    FulfillmentChannel__c='Indirect – VAR/VAD',
                    CloseDate=System.today(),
                    StageName='Closed Booked',
                    Owner=xuser,
                    OracleOrderNumber__c = '-1',
                    DateOrderBooked__c=Datetime.newInstance(2009,1,1),
                    DateOrderSubmitted__c=Datetime.newInstance(2009,1,1),
                    AccountId=account.Id,Country_of_Order__c='India');
                insert opportunity1;
                opportunity1.StageName='Closed Booked';
                opportunity1.OracleOrderNumber__c = '-1';
                opportunity1.DateOrderBooked__c=Datetime.newInstance(2009,1,1);
                opportunity1.DateOrderSubmitted__c=Datetime.newInstance(2009,1,1);
                update opportunity1;
            }
            return opportunity1;
        }
    }

    static Opportunity opportunity2 {
        get {
            if(opportunity2 == null) {
                opportunity2 = new Opportunity(
                    Name='OpportunityRedirectControllerExtension Test',
                    FulfillmentChannel__c='Indirect – Webstore',
                    CloseDate=System.today(),
                    StageName='Closed Booked',
                    Owner=xuser,
                    OracleOrderNumber__c = '-1',
                    DateOrderBooked__c=Datetime.newInstance(2009,1,1),
                    DateOrderSubmitted__c=Datetime.newInstance(2009,1,1),
                    AccountId=account.Id,
                    Country_of_Order__c='India');
                insert opportunity2;
                opportunity2.StageName='Closed Booked';
                opportunity2.OracleOrderNumber__c = '-1';
                opportunity2.DateOrderBooked__c=Datetime.newInstance(2009,1,1);
                opportunity2.DateOrderSubmitted__c=Datetime.newInstance(2009,1,1);
                update opportunity2;
            }
            return opportunity2;
        }
    }

    static Opportunity opportunityPrepare {
        get {
            if(opportunityPrepare == null) {
                opportunityPrepare = new Opportunity(
                    Name='OpportunityRedirectControllerExtension Test',
                        FulfillmentChannel__c='Indirect – Webstore',
                        CloseDate=System.today(),
                        StageName='Prepare',
                        Owner=xuser,
                        AccountId=account.Id,
                        Country_of_Order__c='India');
                insert opportunityPrepare;
                System.assertEquals(1,[select count() from Opportunity where Id = :opportunityPrepare.Id and IsClosed = false]);
            }
            return opportunityPrepare;
        }
    }

    static Opportunity zeroValueOpportunity {
        get {
            if(zeroValueOpportunity == null) {
                Id zeroValueOpportunityRecordTypeId = OpportunityRedirectControllerExtension.zeroValueOpportunityRecordTypeId;
                if(zeroValueOpportunityRecordTypeId != null) { 
                    zeroValueOpportunity = new Opportunity(
                        Name='OpportunityRedirectControllerExtension Test',
                        OpportunityType__c='Bridge',
                        CloseDate=System.today(),
                        RecordTypeId = zeroValueOpportunityRecordTypeId,
                        StageName='Prepare',
                        Owner=xuser,
                        AccountId=account.Id,
                        Country_of_Order__c='India');
                    insert zeroValueOpportunity;
                }
            }
            return zeroValueOpportunity;
        }
    }

    static OpportunityRedirectControllerExtension getController(Opportunity opp) {
        opp = [ select Id,Name,CloseDate,StageName,OwnerId,Owner.Id,DateOrderSubmitted__c,AccountId,Account.Id,Country_of_Order__c from Opportunity where Id = :opp.Id];
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        OpportunityRedirectControllerExtension controller = new OpportunityRedirectControllerExtension(sc);
        return controller;
    }

    @isTest
    static void financialPartnerNeededTest() {
        createClassifications();
        OpportunityRedirectControllerExtension controller = getController(opportunity1);
        Boolean f = controller.financialPartnerRequired; // to do: Fix so we can test this
        controller.financialPartnerRequired = true;
        System.assertNotEquals(null,controller.viewOpportunity());
        System.assertNotEquals(null,controller.editOpportunity());
        System.assert(! controller.getHasErrors());
    }
    
    @isTest
    static void financialPartnerNeededTest1() {
        createClassifications();
        OpportunityRedirectControllerExtension controller = getController(opportunity1);
        Boolean f = controller.financialPartnerRequired; // to do: Fix so we can test this
        controller.financialPartnerRequired = true;
        //System.assertNotEquals(null,controller.viewOpportunity());
        System.assertNotEquals(null,controller.editOpportunity());
        System.assert(! controller.getHasErrors());
    }
    
    @isTest
    static void financialPartnerNotNeededTest() {
        createClassifications();
        OpportunityRedirectControllerExtension controller = getController(opportunity2);
        System.assert(! controller.financialPartnerRequired);
        System.assertEquals(null,controller.viewOpportunity());
        System.assertNotEquals(null,controller.editOpportunity());
        System.assert(! controller.getHasErrors());
    }

    @isTest
    static void zeroValueOpportunityTest() {
        Id zeroValueOpportunityRecordTypeId = OpportunityRedirectControllerExtension.zeroValueOpportunityRecordTypeId;
        if(zeroValueOpportunityRecordTypeId != null) {
            PageReference pageRef = new PageReference('https://na4.salesforce.com/OpportunityView?id='+zeroValueOpportunity.Id+'&nooverride=1&submitForApproval=1');
            Test.setCurrentPage(pageRef);
            OpportunityRedirectControllerExtension controller = getController(zeroValueOpportunity);
            System.assert(controller.isZeroValueOpportunity);
            System.assertEquals(null,controller.viewOpportunity());
            System.assertNotEquals(null,controller.editOpportunity());
            System.assert(controller.getHasErrors());
            System.assertNotEquals(null,controller.getShowSumitForApprovalErrorsUrl());
            System.assert(controller.getHasZeroValueOpportunityErrors());
        }
    }

    @isTest
    static void createPOCEnabledPrepareTest() {
        OpportunityRedirectControllerExtension controller = getController(opportunityPrepare);
        OpportunityRedirectControllerExtension controller2 = getController(opportunity2);
        //scenario - user's job function matches a job function in the setting
        POC_Enabled__c pocEnabled = POC_Enabled__c.getInstance();
        pocEnabled.APAC__c = true;
        pocEnabled.EMEA__c = false;
        pocEnabled.LATAM__c = false;
        pocEnabled.NA__c = false;
        pocEnabled.Global__c = false;
        pocEnabled.Job_Functions__c = 'House Pet\nTest User';
        upsert pocEnabled;
        Test.startTest();
        controller.createPOCEnabled = null;
        controller.user.Job_Function__c = 'TEST USER';
        controller.user.Region__c = 'EMEA';
        System.assert(controller.createPOCEnabled,'Expected EMEA - TEST USER to be able to create a POC from an open opportunity');
        controller.createPOCEnabled = null;
        controller.user.Region__c = 'APAC';
        System.assert(controller.createPOCEnabled,'Expected APAC - TEST USER to be able to create a POC from an open opportunity');
        controller.createPOCEnabled = null;
        controller.user.Job_Function__c = 'OTHER USER';
        System.assert(controller.createPOCEnabled,'Expected APAC - OTHER USER to be able to create a POC from an open opportunity');
        controller.createPOCEnabled = null;
        controller.user.Region__c = 'EMEA';
        System.assert(! controller.createPOCEnabled,'Did not expect EMEA - OTHER USER to be able to create a POC from an open opportunity');
        // scenario - try with a closed opportunity
        controller2.createPOCEnabled = null;
        controller2.user.Job_Function__c = 'TEST USER';
        controller2.user.Region__c = 'EMEA';
        System.assert(! controller2.createPOCEnabled,'Did not expect EMEA - TEST USER to be able to create a POC from a closed opportunity');
        controller2.createPOCEnabled = null;
        controller2.user.Region__c = 'APAC';
        System.assert(! controller2.createPOCEnabled,'Did not expect APAC - TEST USER to be able to create a POC from a closed opportunity');
        controller2.createPOCEnabled = null;
        controller2.user.Job_Function__c = 'OTHER USER';
        System.assert(! controller2.createPOCEnabled,'Did not expect APAC - OTHER USER to be able to create a POC from a closed opportunity');
        controller2.createPOCEnabled = null;
        controller2.user.Region__c = 'EMEA';
        System.assert(! controller2.createPOCEnabled,'Did not expect EMEA - OTHER USER to be able to create a POC from a closed opportunity');
        Test.stopTest();
    }

    @isTest
    static void pocRedirectTest() {
        OpportunityRedirectControllerExtension controller = getController(opportunity1);
        //scenario - user's job function matches a job function in the setting
        System.assert(! controller.isProofOfConcept,'Did not expect a proof of concept');
        controller.isProofOfConcept = true;
        PageReference r = controller.viewOpportunity();
        System.assertNotEquals(null,r);
        OpportunityRedirectControllerExtension.pocRecordTypeId = null;
        controller.editOpportunity();
    }

	@isTest
	static void recallApprovalTest() {
		OpportunityRedirectControllerExtension controller = getController(zeroValueOpportunity);
		Opportunity opp = controller.getQueriedOpp();
		System.assertEquals(zeroValueOpportunity.Id,opp.Id);
		opp.ApprovalStatus__c = OpportunityRedirectControllerExtension.APPROVED_PLV;
		System.assertEquals(true,controller.getIsAccepted());
		controller.recallApproval(); // coverage only
	}
}