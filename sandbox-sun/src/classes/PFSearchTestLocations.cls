@isTest
private class PFSearchTestLocations {

    static testmethod void testSearchLocation() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct1 = PartnerTestUtils.quickFinderAccountSetup('testSearchLocation_Test_Partner_1');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct1.Id, PartnerConst.ISV, PartnerConst.READY);
        insert ps;
        update acct1;

        // NOTE: the Account_ShipToPartnerLocation trigger will insert the billto/shipto address into the Location table automatically
        // so there will always be at least 1 address to test with in case you get really lazy.
        //
        Partner_Location__c loc1 = PartnerTestUtils.makeLocation(acct1.Id);
        loc1.Name = 'HQ';
        loc1.Country__c = 'US';
        loc1.State_Province__c = 'NC';
        loc1.City__c = 'Apex';
        insert loc1;
        Partner_Location__c loc2 = PartnerTestUtils.makeLocation(acct1.Id);
        loc2.Name = 'Loc2';
        loc2.Country__c = 'US';
        loc2.State_Province__c = 'NC';
        loc2.City__c = 'Raleigh';
        insert loc2;
        Partner_Location__c loc3 = PartnerTestUtils.makeLocation(acct1.Id);
        loc3.Name = 'Loc3';
        loc3.Country__c = 'US';
        loc3.State_Province__c = 'SC';
        loc3.City__c = 'Myrtle Beach';
        insert loc3;

        PFSearch srch = new PFSearch();
        PFSearchForm__c form = new PFSearchForm__c();
        form.ProximitySearch__c = True;
        form.NameOrKeywords__c = acct1.Name;
        //
        // country-level test
        //
        form.Country__c = 'US';
        PFSearchContext ctx = new PFSearchContext(form);
        PFSearchResult result = srch.partnerSearch(ctx);
        System.debug('[PF]------------------------------- results=' + result.resultIdList.size());
        System.assert(result.resultIdList.size() == 4, 'Expected 4 results');   // will get these 3 + the trigger autoinserted one
//      PFPartnerMatch[] matches = result.getPage(0);
//      System.assert(matches[0].partnerName == acct1.Name, 'Partner name ' + matches[0].partnerName + ' does not match ' + acct1.Name);

        //
        // state-level test
        //
        form.StateProvince__c = 'NC';
        result = srch.partnerSearch(ctx);
        System.debug('[PF]------------------------------- results=' + result.resultIdList.size());
        System.assert(result.resultIdList.size() == 3, 'Expected 3 results');
//      matches = result.getPage(0);
//      System.assert(matches[0].partnerName == acct1.Name, 'Partner name ' + matches[0].partnerName + ' does not match ' + acct1.Name);

        //
        // city-level test
        //
        form.City__c = 'Apex';
        result = srch.partnerSearch(ctx);
        System.debug('[PF]------------------------------- results=' + result.resultIdList.size());
        System.assert(result.resultIdList.size() == 1, 'Expected 1 result');
//      matches = result.getPage(0);
//      System.assert(matches[0].partnerName == acct1.Name, 'Partner name ' + matches[0].partnerName + ' does not match ' + acct1.Name);

        //
        // negative test
        //
        form.City__c = 'Greensboro';
        result = srch.partnerSearch(ctx);
        System.assert(result.resultIdList == null || result.resultIdList.size() == 0, 'Expected 0 results');
    }

    static testmethod void testSearchProximityNC() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account acct1 = PartnerTestUtils.quickFinderAccountSetup('Proximity Test Partner 1');
        Partner_Program__c ps = PartnerTestUtils.makeProgram(acct1.Id, PartnerConst.ISV, PartnerConst.READY);
        insert ps;
        update acct1;

        Partner_Location__c loc1 = PartnerTestUtils.makeLocation(acct1.Id);
        loc1.Name = 'Red Hat HQ';
        loc1.Latitude__c = 35.773493;
        loc1.Longitude__c = -78.676170;
        loc1.Is_Primary__c = true;
        insert loc1;

/*
        Account acct2 = PartnerTestUtils.quickFinderAccountSetup('Proximity Test Partner 2');
        Partner_Program__c ps2 = PartnerTestUtils.makeProgram(acct2.Id, PartnerConst.ISV, PartnerConst.READY);
        insert ps2;
        update acct2;
        Partner_Location__c loc2 = PartnerTestUtils.makeLocation(acct2.Id);
        loc2.Name = 'my last house in GSO';
        loc2.Latitude__c = 36.038203;
        loc2.Longitude__c = -79.906204;
        loc2.Is_Primary__c = true;
        insert loc2;
*/

        Test.startTest();
        PFSearch srch = new PFSearch();
        PFSearchForm__c form = new PFSearchForm__c();
        form.ProximitySearch__c = True;
        form.Latitude__c = '35.773493';     // Red Hat, Varsity Dr
        form.Longitude__c = '-78.676170';
        form.Distance__c = '10';
        form.DistanceMetric__c = 'Miles';
        form.NameOrKeywords__c = 'Proximity Test Partner';
        PFSearchContext ctx = new PFSearchContext(form);
        PFSearchResult result = srch.partnerSearch(ctx);
        System.debug('[PF]------------------------------- results=' + result.resultIdList.size());
        System.assert(result.resultIdList.size() == 1);
//      PFPartnerMatch[] matches = result.getPage(0);
//      System.assert(matches[0].partnerName == acct1.Name, 'Partner name ' + matches[0].partnerName + ' does not match ' + acct1.Name);

/*
        form.Distance__c = '120';
        result = srch.partnerSearch(ctx);
        System.debug('[PF]------------------------------- 2 results=' + result.resultIdList.size());
        System.assert(result.resultIdList.size() == 2, 'Expected to find 2 partners');
*/
        Test.stopTest();

    }

/*
    static testmethod void testSearchProximityEngland() {
        Account acct1 = PartnerTestUtils.quickFinderAccountSetup('Proximity Test Partner 1');
        Partner_Location__c loc1 = PartnerTestUtils.makeLocation(acct1.Id);
        loc1.Name = 'House of Parliament';
        loc1.Latitude__c = 51.498431;
        loc1.Longitude__c = -0.125120;
        loc1.Is_Primary__c = true;
        insert loc1;

        Account acct2 = PartnerTestUtils.quickFinderAccountSetup('Proximity Test Partner 2');
        Partner_Location__c loc2 = PartnerTestUtils.makeLocation(acct2.Id);
        loc2.Name = 'Westminister Abbey';
        loc2.Latitude__c = 51.499476;
        loc2.Longitude__c = -0.128623;
        loc2.Is_Primary__c = true;
        insert loc2;

        PFSearch srch = new PFSearch();
        PFSearchForm__c form = new PFSearchForm__c();
        form.ProximitySearch__c = True;
        form.Latitude__c = '51.500956';     // Buckingham Palace
        form.Longitude__c = '-0.143198';
        form.Distance__c = '1';
        form.DistanceMetric__c = 'Kilometers';
        form.NameOrKeywords__c = 'Proximity Test Partner';
        PFSearchContext ctx = new PFSearchContext(form);
        PFSearchResult result = srch.partnerSearch(ctx);
        System.debug('[PF]------------------------------- results=' + result.resultIdList.size());
        System.assert(result.resultIdList.size() == 0, 'search should have returned 0 matches');

        form.Distance__c = '5';
        result = srch.partnerSearch(ctx);
        System.debug('[PF]------------------------------- results=' + result.resultIdList.size());
        System.assert(result.resultIdList.size() == 2, 'search should have returned 2 matches');

        PFPartnerMatch[] matches = result.getPage(0);
        for (PFPartnerMatch match : matches) {
            System.debug('[PF]--------------- match=' + match.partnerName);
        }
    }

    static testmethod void testSearchProximitySpainPrimeMeridian() {
        Account acct1 = PartnerTestUtils.quickFinderAccountSetup('Proximity Test Partner 1');
        Partner_Location__c loc1 = PartnerTestUtils.makeLocation(acct1.Id);
        // Safari Park vergel
        loc1.Name = 'Safari Park vergel';
        loc1.Latitude__c = 38.857998;
        loc1.Longitude__c = -0.017434;
        loc1.Is_Primary__c = true;
        insert loc1;
        Partner_Location__c loc4 = PartnerTestUtils.makeLocation(acct1.Id);
        // Hospital General Universitario Gregorio Maranon, Madrid
        loc4.Name = 'Hospital General Universitario Gregorio Maranon, Madrid';
        loc4.Latitude__c = 40.418887;
        loc4.Longitude__c = -3.671193;
        insert loc4;


        Account acct2 = PartnerTestUtils.quickFinderAccountSetup('Proximity Test Partner 2');
        Partner_Location__c loc2 = PartnerTestUtils.makeLocation(acct2.Id);
        // Oficina De Turismo Els Poblets
        loc2.Name = 'Oficina De Turismo Els Poblets';
        loc2.Latitude__c = 38.849969;
        loc2.Longitude__c = 0.018840;
        loc2.Is_Primary__c = true;
        insert loc2;
        Partner_Location__c loc3 = PartnerTestUtils.makeLocation(acct2.Id);
        // Cip Centro de Informatica Profesional
        loc3.Name = 'Cip Centro de Informatica Profesional';
        loc3.Latitude__c = 38.828793;
        loc3.Longitude__c = 0.013947;
        insert loc3;

        PFSearch srch = new PFSearch();
        PFSearchForm__c form = new PFSearchForm__c();
        form.ProximitySearch__c = True;
        // Denia, Spain
        form.Latitude__c = '38.866667';
        form.Longitude__c = '0.0';
        form.Distance__c = '1';
        form.DistanceMetric__c = 'Kilometers';
        form.NameOrKeywords__c = 'Proximity Test Partner';
        PFSearchContext ctx = new PFSearchContext(form);
        PFSearchResult result = srch.partnerSearch(ctx);
        System.debug('[PF]------------------------------- results=' + result.resultIdList.size());
        System.assert(result.resultIdList.size() == 0, 'search should have returned 0 matches');

        form.Distance__c = '3';
        result = srch.partnerSearch(ctx);
        System.debug('[PF]------------------------------- results=' + result.resultIdList.size());
        System.assert(result.resultIdList.size() == 2, 'search should have returned 2 matches');

        PFPartnerMatch[] matches = result.getPage(0);
        for (PFPartnerMatch match : matches) {
            System.debug('[PF]--------------- match=' + match.partnerName);

        }
    }
*/

}