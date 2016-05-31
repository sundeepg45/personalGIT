@isTest
private class PFSearchTest {


    static testmethod void testPartnerDetails() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct = PartnerTestUtils.quickFinderAccountSetup('testPartnerDetails');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct.id, PartnerConst.ISV, PartnerConst.READY);
        insert ps;
//        PartnerTestUtils.setNewStatusForAccount(ps, acct);
        update acct;

        //
        // this test based on existing data
        //
/*
        Integer rowcount = [select count() from PartnerStatus__c where isVisible__c = True and ActivationStatus__c = 'Active'];
                            and Is_Partner_Published__c = True
                            and IsPartner = True
                            and VisibleApprovedStatuses__c > 0

        if (rowcount < 100) {
            // not enough existing data to complete test, just assume okay
            return;
        }
        PartnerStatus__c ps = [select Partner__c from PartnerStatus__c where isVisible__c = True and ActivationStatus__c = 'Active' limit 1];
*/
        PFSearch srch = new PFSearch();
        PFPartnerDetailsMatch match = srch.partnerDetails(acct.Id);
        System.assert(match != null);
    }

    static testmethod void testMultiwordSearch() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct = PartnerTestUtils.quickFinderAccountSetup('Wibbly wobbly timey wimey stuff');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct.id, PartnerConst.ISV, PartnerConst.READY);
        insert ps;
//        PartnerTestUtils.setNewStatusForAccount(ps, acct);
        update acct;

        PFSearch srch = new PFSearch();
        PFSearchForm__c form = new PFSearchForm__c();
        form.NameOrKeywords__c = 'wobbly wimey';
        PFSearchContext ctx = new PFSearchContext(form);
        PFSearchResult result = srch.partnerSearch(ctx);
        System.assert(result.resultIdList.size() > 0);
        PFPartnerMatch[] matches = result.getPage(0);
        System.assert(matches.size() > 0);
        boolean found = False;
        for (PFPartnerMatch match : matches) {
            System.debug('[PF]--------------- ms match=' + match.partnerName);
            if (match.PartnerName == acct.Name) {
                found = True;
                break;
            }
        }
        System.assert(found);
    }

    static testmethod void testFeaturedPartners() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct = PartnerTestUtils.quickFinderAccountSetup('A testFeaturedPartners Partner');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct.id, PartnerConst.ISV, PartnerConst.ADVANCED);
        insert ps;
//        PartnerTestUtils.setNewStatusForAccount(ps, acct);
        acct.PartnerStatuses__c = 'Advanced - ISV';
        update acct;
        delete [select Id from Featured_Partner__c];
        Featured_Partner__c fp = new Featured_Partner__c(Partner__c = acct.Id, Status__c = 'Active');
        insert fp;

        PFSearchForm__c form = new PFSearchForm__c();
        form.Country__c = 'US';
        PFSearchContext ctx = new PFSearchContext(form);
        PFSearch srch = new PFSearch();
        PFSearchResult result = srch.partnerSearch(ctx);
        System.assert(result.resultIdList.size() > 0, 'No results found');
        PFPartnerMatch[] featured = result.getFeaturedPartners();
        System.assert(featured.size() == 1, 'Expected to find 1 featured partner, found ' + featured.size());

    }

    static testmethod void testNameSearch() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct = PartnerTestUtils.quickFinderAccountSetup('A testNameSearch Partner');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct.id, PartnerConst.ISV, PartnerConst.READY);
        insert ps;
//        PartnerTestUtils.setNewStatusForAccount(ps, acct);
        acct.PartnerStatuses__c = 'Ready - ISV';
        update acct;

        PFSearchForm__c form = new PFSearchForm__c();
        form.NameOrKeywords__c = 'testNameSearch';
        PFSearchContext ctx = new PFSearchContext(form);
        executeTest(acct, ctx);
    }

    static testmethod void testReseller() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct = PartnerTestUtils.quickFinderAccountSetup('Advanced Reseller Partner');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct.id, PartnerConst.RESELLER, PartnerConst.ADVANCED);
        insert ps;
//        PartnerTestUtils.setNewStatusForAccount(ps, acct);
        update acct;

        PFSearchForm__c form = new PFSearchForm__c();
        form.NameOrKeywords__c = acct.Name;
        //
        // search for the specific Tier
        //
        form.PartnerTier__c = 'Advanced';
        form.PartnerType__c = 'Reseller';
        PFSearchContext ctx = new PFSearchContext(form);
        executeTest(acct, ctx);
    }

    static testmethod void testDistributor() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct = PartnerTestUtils.quickFinderAccountSetup('Affiliated Distributor Partner');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct.id, PartnerConst.DISTRIBUTOR, PartnerConst.AFFILIATED);
        insert ps;
//        PartnerTestUtils.setNewStatusForAccount(ps, acct);
        update acct;

        PFSearchForm__c form = new PFSearchForm__c();
        form.NameOrKeywords__c = acct.Name;
        //
        // search for the specific Tier
        //
        form.PartnerTier__c = 'Affiliated';
        form.PartnerType__c = 'Distributor';
        PFSearchContext ctx = new PFSearchContext(form);
        executeTest(acct, ctx);
    }

    static testmethod void testOEM() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct = PartnerTestUtils.quickFinderAccountSetup('A test OEM/AFFILIATED Partner');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct.id, PartnerConst.OEM, PartnerConst.AFFILIATED);
        insert ps;
//        PartnerTestUtils.setNewStatusForAccount(ps, acct);
        update acct;


        acct = PartnerTestUtils.refreshAccount(acct);

        System.debug('[PF]------------------------------ finder_partner_type=' + acct.Finder_Partner_Type__c);

        PFSearchForm__c form = new PFSearchForm__c();
        form.NameOrKeywords__c = acct.Name;
        //
        // search for the specific Type/Tier
        //
        PFSearchContext ctx = new PFSearchContext(form);
        form.PartnerTier__c = 'Affiliated';
        form.PartnerType__c = 'OEM';
        System.debug('[PF]--------- testOEM');
        executeTest(acct, ctx);
    }

    static private void executeTest(Account acct, PFSearchContext ctx) {
        PFSearch srch = new PFSearch();
        PFSearchResult result = srch.partnerSearch(ctx);
        System.assert(result.resultIdList.size() > 0, acct.Name + ' not found');
        System.debug('[PF]--------- matches=' + result.matchCount());
        PFPartnerMatch[] matches = result.getPage(0);
        System.assert(matches.size() == 1, acct.Name + ' not found');
        System.assert(matches[0].partnerName == acct.Name, acct.Name + ' not found');
    }

    static testmethod void testISV() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct = PartnerTestUtils.quickFinderAccountSetup('A testNameSearch Partner');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct.id, PartnerConst.ISV, PartnerConst.READY);
        insert ps;
//        PartnerTestUtils.setNewStatusForAccount(ps, acct);

        update acct;

        PFSearchForm__c form = new PFSearchForm__c();
        form.NameOrKeywords__c = acct.Name;
        //
        // search for the specific Tier
        //
        form.PartnerTier__c = 'Ready';
        form.PartnerType__c = 'Independent Software Vendor (ISV)';
        PFSearchContext ctx = new PFSearchContext(form);
        executeTest(acct, ctx);
    }

    static testmethod void testISVJBossProducts() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct = PartnerTestUtils.quickFinderAccountSetup('A testNameSearch Partner');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct.id, PartnerConst.ISV, PartnerConst.READY);
        insert ps;
//        PartnerTestUtils.setNewStatusForAccount(ps, acct);
        update acct;


        PFSearchForm__c form = new PFSearchForm__c();
        form.NameOrKeywords__c = 'testNameSearch';
        //
        // search for the specific Tier
        //
        form.PartnerTier__c = 'Ready';
        form.PartnerType__c = 'ISV';
        form.PlatformsSupported__c = 'JBoss';

        PFSearchContext ctx = new PFSearchContext(form);
        executeTest(acct, ctx);
    }


    static testmethod void testISVPlatformProducts() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct = PartnerTestUtils.quickFinderAccountSetup('A testNameSearch Partner');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct.id, PartnerConst.ISV, PartnerConst.READY);
        insert ps;
//        PartnerTestUtils.setNewStatusForAccount(ps, acct);
        update acct;

        PFSearchForm__c form = new PFSearchForm__c();
        form.NameOrKeywords__c = 'testNameSearch';
        //select Partner__c from Partner_Location__c where Partner__r.Is_Partner_Published__c = True and (Longitude__c >= -76.89128643935572 and Latitude__c <= 37.22163035017817and Longitude__c <= -80.46105356064427 and Latitude__c >= 34.32535564982184) order by Partner__r.Finder_Sort_Hint__c, Partner__r.Name
        // search for the specific Tier
        //
        form.PartnerTier__c = 'Ready';
        form.PartnerType__c = 'Independent Software Vendor (ISV)';
        form.PlatformsSupported__c = 'Red Hat Enterprise Linux';

        PFSearchContext ctx = new PFSearchContext(form);
        executeTest(acct, ctx);
    }

    static testmethod void testISVJBossAndPlatformProducts() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct = PartnerTestUtils.quickFinderAccountSetup('A testNameSearch Partner');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct.id, PartnerConst.ISV, PartnerConst.READY);
        insert ps;
//        PartnerTestUtils.setNewStatusForAccount(ps, acct);
        update acct;

        PFSearchForm__c form = new PFSearchForm__c();
        form.NameOrKeywords__c = 'testNameSearch';
        //
        // search for the specific Tier
        //
        form.PartnerTier__c = 'Ready';
        form.PartnerType__c = 'Independent Software Vendor (ISV)';
        form.PlatformsSupported__c = 'Red Hat Enterprise Linux;JBoss';

        PFSearchContext ctx = new PFSearchContext(form);
        executeTest(acct, ctx);
    }

    static testmethod void testSearchMultipaged() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        //
        // this test based on existing data
        //
        Integer rowcount = [select count() from PartnerStatus__c where isVisible__c = True and ActivationStatus__c = 'Active' and Partner__r.Is_Partner_Published__c = True];
        if (rowcount < 100) {
            // not enough existing data to complete test, just assume okay
            return;
        }
        PFSearch srch = new PFSearch();
        PFSearchForm__c form = new PFSearchForm__c();
        form.NameOrKeywords__c = null;
        PFSearchContext ctx = new PFSearchContext(form);

        PFSearchResult result = srch.partnerSearch(ctx);
        System.assert(result.resultIdList.size() > 20);
        PFPartnerMatch[] matches = result.getPage(1);
        System.assert(matches.size() > 0);
    }

}