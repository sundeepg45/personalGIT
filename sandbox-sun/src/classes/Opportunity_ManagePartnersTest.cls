/**
 * This a test class of Opportunity_ManagePartner.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2015-02-05
 * 2013-03-19 - Updated API version.
 * 2010-10-29 - Created
 * Abhijeet Anand
 * 2011-06-28 - Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 * Scott Coleman <scoleman@redhat.com>
 * 2015-02-05 - Updated with C360 channel type
 * 2013-07-15 - Implemented Opp Lock
 */
@isTest(SeeAllData=true)
private class Opportunity_ManagePartnersTest {
    static Opportunity opportunity {
        get {
            if(opportunity == null)
            {
                RecordType recordType = [select Id,name from RecordType where name = 'Strategic' and SObjectType = 'Account' limit 1];
                Account account = new Account(name='account',RecordTypeId=recordType.Id,AccountClassification__c=recordType.name);
                insert account;
                account.RecordType = recordType;
                TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
                System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
                User xuser = [select Id from User where ProfileId = :salesUserProfileTesting.Id__c limit 1];
                RecordType recordType2 = [select Id,name from RecordType where name like 'EMEA %' and SObjectType = 'Opportunity' limit 1];
                opportunity = new Opportunity(Name='Opportunity_ManagePartnersTest Test',
                    CloseDate=System.today(),StageName='Prepare',//changed the opportunity stagename value to Prepare as part of Value Selling enhancement.July 20th release
                    Owner=xuser,// DateOrderSubmitted__c=Datetime.newInstance(2009,1,1),
                    AccountId=account.Id,Country_of_Order__c='India',FulfillmentChannel__c='OEM',
                    RecordTypeId = recordType2.Id);
                insert opportunity;
                opportunity.RecordType = recordType2;
                opportunity.Account = account;
            }
            return opportunity;
        }
    }

    static OpportunityPartner__c oppPartner {
        get {
            if(oppPartner == null)
            {
                Classification__c pType = null;
                Classification__c pTier = null;
                for(Classification__c c : [select Name from Classification__c where Name in ('Partner Type','Partner Tier') and Parent__c = null])
                {
                    if(c.Name == 'Partner Type')
                    {
                        pType = c;
                    }
                    else if(c.Name == 'Partner Tier')
                    {
                        pTier = c;
                    }
                }
                if(pType == null)
                {
                    pType=new Classification__c(Name='Partner Type');
                    insert pType;
                }
                if(pTier == null)
                {
                    pTier = new Classification__c(Name='Partner Tier');
                    insert pTier;
                }
                Classification__c cTier = new Classification__c(Name='Child Tier',Parent__c=pTier.Id);
                Classification__c cType = new Classification__c(Name='Child Type',Parent__c=pType.Id);
                insert new List<Classification__c>{cTier,cType};
                oppPartner = new OpportunityPartner__c(
                    Opportunity__c = opportunity.Id,
                    PartnerTier__c = cTier.Id,
                    PartnerType__c = cType.Id,
                    Partner__c = opportunity.AccountId,
                    RelationshipType__c = 'Financial'
                    );
                User xuser = [select Id from User where Username Like 'intadmin@redhat.com%' limit 1];
                System.Runas(xuser){
                    insert oppPartner;
                }
            }
            return oppPartner;
        }
    }

    @isTest
    static void testOppPartner()
    {
        System.assertNotEquals(null,oppPartner.Id);
    }

    @isTest
    static void testFinancialPartnerRequired()
    {
        System.assertEquals(true,Opportunity_ManagePartners.isFinancialPartnerRequired(opportunity.Id));
    }

    @isTest
    static void testMessages() {
        System.assertEquals(false,Opportunity_ManagePartners.hasMessages(ApexPages.Severity.ERROR));
        System.assertEquals(false,Opportunity_ManagePartners.hasMessages(ApexPages.Severity.CONFIRM));
        Opportunity_ManagePartners.addExceptionMessage('test');
        System.assertEquals(true,Opportunity_ManagePartners.hasMessages(ApexPages.Severity.ERROR));
        Opportunity_ManagePartners.addConfirmationMessage();
        System.assertEquals(true,Opportunity_ManagePartners.hasMessages(ApexPages.Severity.CONFIRM));
    }

    @isTest
    static void testCoverageTestStatic() {
        Opportunity_ManagePartners.SAFE_DATETIME = Opportunity_ManagePartners.OLDEST_DATETIME.addDays(1);
        for(String region : new List<String>{'APAC','EMEA','LATAM','NA'}) {
            System.assertEquals(true,Opportunity_ManagePartners.getAccountRecordTypeIdByRegion().containsKey(region));
        }
        System.assertNotEquals(null,Opportunity_ManagePartners.getCompletePartnerTierList());
        Id id = Opportunity_ManagePartners.rootPartnerTierId;
        System.assertNotEquals(null,Opportunity_ManagePartners.getPartnerTierMap());
        System.assertNotEquals(null,Opportunity_ManagePartners.getCompletePartnerTypeList());
        id = Opportunity_ManagePartners.rootPartnerTypeId;
        System.assertNotEquals(null,Opportunity_ManagePartners.getPartnerTypeMap());
        // The following are not static but we test them here anyway...
        ApexPages.StandardController controller = new ApexPages.StandardController(opportunity);
        Opportunity_ManagePartners extension = new Opportunity_ManagePartners(controller);
        extension.fillPartnerStatusMaps();
        extension.startDateTime=null;
        System.assertNotEquals(null,extension.getPartnerStatusRecordTypeIdTypeHierarchyMap());
        System.assertNotEquals(null,extension.getPartnerStatusMapByIdMap());
        System.assertNotEquals(null,extension.getPartnerStatusMap());
        System.assertNotEquals(null,extension.getPartnerTierIdByPartnerStatusIdMap());
        System.assertNotEquals(null,extension.getPartnerTypeIdByPartnerStatusIdMap());
        System.assertNotEquals(null,extension.partnerTypeMapByRelationshipTypeJS);
        System.assertNotEquals(null,extension.partnerStatusArrayJS);
    }

    @isTest
    static void testController() {
        Opportunity_ManagePartners.SAFE_DATETIME = Opportunity_ManagePartners.OLDEST_DATETIME.addDays(1);
        ApexPages.StandardController controller = new ApexPages.StandardController(opportunity);
        Opportunity_ManagePartners extension = new Opportunity_ManagePartners(controller);
        System.assertEquals(opportunity.Id,extension.getOpportunity().Id);
        System.assertEquals(true,extension.isFinancialPartnerRequired);
        System.assertNotEquals(0,extension.getRelationshipTypeOptions().size());
        System.assertEquals(true,extension.getHasAvailableRelationshipTypeOptions());
        //System.assertEquals(false,extension.isEdit);
        extension.insertOpportunityPartner();
        System.assertNotEquals(0,extension.getPartnerInfoList().size());
        System.assertEquals(true,extension.isEdit);
        extension.editSelected();
        extension.cancelEdit(extension.getPartnerInfoList().get(0).id);
        //System.assertEquals(false,extension.isEdit);
        extension.insertOpportunityPartner();
        extension.cancel();
        Boolean b = extension.getPartnerInfoListIsEmpty();
        extension.saveOpportunityPartnerListAndInsert();
        extension.saveOpportunityPartnerListAndReturn();
        extension.removeSelected();
    }

    @isTest
    static void testControllerSave() {
        Opportunity_ManagePartners.SAFE_DATETIME = Opportunity_ManagePartners.OLDEST_DATETIME.addDays(1);
        ApexPages.StandardController controller = new ApexPages.StandardController(opportunity);
        Opportunity_ManagePartners extension = new Opportunity_ManagePartners(controller);
        extension.insertOpportunityPartner();
        System.assertEquals(false,Opportunity_ManagePartners.hasMessages(ApexPages.Severity.ERROR));
        extension.saveOpportunityPartnerListAndReturn();
        //System.assertEquals(true,Opportunity_ManagePartners.hasMessages(ApexPages.Severity.ERROR));
    }

    @isTest
    static void testPartnerInfoCoverage() {
        Opportunity_ManagePartners.SAFE_DATETIME = Opportunity_ManagePartners.OLDEST_DATETIME.addDays(1);
        ApexPages.StandardController controller = new ApexPages.StandardController(opportunity);
        Opportunity_ManagePartners extension = new Opportunity_ManagePartners(controller);
        extension.insertOpportunityPartner();
        Opportunity_PartnerInfo partnerInfo = extension.getPartnerInfoList().get(0);
        OpportunityPartner__c opportunityPartner = partnerInfo.getOpportunityPartner();
        System.assertEquals(true,partnerInfo.isSelected);
        System.assertEquals(true,partnerInfo.isEdit);
        System.assertEquals(true,partnerInfo.isNew);
        partnerInfo.isRequired = false;
        System.assertEquals(false,partnerInfo.isRequired);
        PartnerStatus__c partnerStatus = partnerInfo.getPartnerStatus();
        Id id = partnerInfo.getPartnerStatusId();
        id = partnerInfo.getPartnerTierId();
        String partnerTierName = partnerInfo.getPartnerTierName();
        id = partnerInfo.getPartnerTypeId();
        id = partnerInfo.getPartnerSubTypeId();
        String partnerTypeName = partnerInfo.getPartnerTypeName();
        String partnerSubTypeName = partnerInfo.getPartnerSubTypeName();
        System.assertNotEquals(null,partnerInfo.getPartnerTypeOptions());
        System.assertNotEquals(null,partnerInfo.getPartnerTierOptions());
        System.assertNotEquals(null,partnerInfo.getPartnerSubTypeOptions());
        System.assertEquals(false,partnerInfo.showAllRegions);
        partnerInfo.updateRelationshipType();
        partnerInfo.updateShowAllRegions();
        partnerInfo.updatePartnerType();
        partnerInfo.updatePartnerTier();
        partnerInfo.updatePartnerSubType();
        partnerInfo.cancelEdit();
        partnerInfo.isEdit=true;
        partnerInfo.setPartnerStatus(extension.getPartnerStatusMap().values().get(0));
        System.assertNotEquals(null,partnerInfo.searchText);
        opportunityPartner.RelationshipType__c=Opportunity_ManagePartners.FINANCIAL;
        partnerInfo.updateRelationshipType();
        partnerTypeName = partnerInfo.getPartnerTypeName();
        partnerSubTypeName = partnerInfo.getPartnerSubTypeName();
        System.assertNotEquals(null,partnerInfo.getPartnerTypeOptions());
        System.assertNotEquals(null,partnerInfo.getPartnerTierOptions());
        System.assertNotEquals(null,partnerInfo.getPartnerSubTypeOptions());
        partnerInfo.searchText='test';
        partnerInfo.getLookupLink();
        PageReference p = new PageReference(partnerInfo.getLookupLink());
        Test.setCurrentPage(p);
        PartnerStatus_SetController sc = new PartnerStatus_SetController();
        Test.startTest();
        System.assertNotEquals(null,sc.getPartnerStatusPagination());
        Test.stopTest();
        sc.first();
        sc.last();
        sc.previous();
        sc.next();
    }   

    @isTest
    static void testAsUser() {
        Opportunity_ManagePartners_AsUser asUser = new Opportunity_ManagePartners_AsUser();
        boolean result = asUser.checkPermissions(opportunity);
    }

    @isTest
    static void testDelete() {
        System.runAs(new User(Id=UserInfo.getUserId())) {
            insert new AdminByPass__c(SetupOwnerId = UserInfo.getUserId(), IsSalesUser__c = true);
        }
        Id partnerId = oppPartner.Id;
        delete oppPartner;
        List<OpportunityPartner__c> partners = [select Id from OpportunityPartner__c where Id = :partnerId];
        System.assert(partners.IsEmpty());
    }
}