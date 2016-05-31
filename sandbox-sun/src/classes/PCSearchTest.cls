@isTest
private class PCSearchTest {

/* partner catalog is being mothballed
    static testmethod void testProductDetails() {
        Account acct = PartnerTestUtils.quickGenericAccountSetup('testProductDetails');
        update acct;
        PartnerProduct__c prod = PartnerTestUtils.makeProduct(acct.Id);
        insert prod;

        ApexPages.currentPage().getParameters().put('id', prod.Id);
        PartnerProducts_screenshots controller = new PartnerProducts_screenshots(new ApexPages.Standardcontroller(prod));
        controller.attachmentFile = EncodingUtil.base64Decode('a fake image body');
        controller.attachmentFileName = 'testfile.png';
        controller.addScreenshot();

        controller.productLogo.Body = EncodingUtil.base64Decode('a fake image body');
        controller.productLogo.Name = 'testfile.png';
        controller.replaceLogo();

        PCSearch srch = new PCSearch();
        PCProductDetailsMatch match = srch.productDetails(prod.Id);
        System.assert(match != null);
    }

    static testmethod void testMultiwordSearch() {
        Account acct = PartnerTestUtils.quickFinderAccountSetup('testMultiwordSearch');
        PartnerStatus__c ps = PartnerTestUtils.makeStatus(acct.Id, 'PARTNER_TYPE.ISV', 'PARTNER_TIER.READY');
        PartnerTestUtils.setNewStatusForAccount(ps, acct);
//        acct.PartnerStatuses__c = 'Ready - ISV';
        update acct;
        PartnerProduct__c prod = PartnerTestUtils.makeProduct(acct.Id);
        prod.Name = 'Wibbly wobbly timey wimey stuff';
        prod.Full_Product_Name__c = 'Wibbly wobbly timey wimey stuff';
        insert prod;

        PCSearch srch = new PCSearch();
        PCSearchForm__c form = new PCSearchForm__c();
        form.NameOrKeywords__c = 'wobbly wimey';
        PCSearchContext ctx = new PCSearchContext(form);
        PCSearchResult result = srch.productSearch(ctx);
        System.assert(result.resultIdList.size() > 0);
        PCProductMatch[] matches = result.getPage(0);
        System.assert(matches.size() > 0, 'no matches found');
        Boolean found = false;
        for (PCProductMatch match : matches) {
            if (match.Name == prod.Name) {
                found = True;
                break;
            }
        }
        System.assert(found, 'keywords not found');
    }

    static testmethod void testNegativeNameSearch() {

        PCSearchForm__c form = new PCSearchForm__c();
        form.NameOrKeywords__c = 'abcdefghijklmnopqrstuvwxyz';
        PCSearchContext ctx = new PCSearchContext(form);
        PCSearch srch = new PCSearch();
        PCSearchResult result = srch.productSearch(ctx);
        System.assert(result.resultIdList.size() == 0, 'No match should be found');
    }


    static private void executeTest(PartnerProduct__c prod, PCSearchContext ctx) {
        PCSearch srch = new PCSearch();
        PCSearchResult result = srch.productSearch(ctx);
        System.assert(result.resultIdList.size() > 0, 'no matches found for ' + prod.Name);
        PCProductMatch[] matches = result.getPage(0);
        Boolean found = False;
        for (PCProductMatch match : matches) {
            if (match.Name == prod.Name) {
                found = True;
                break;
            }
        }
        System.assert(!found, prod.Name + ' not found in results');
    }

    static testmethod void testSearchMultipaged() {
        //
        // this test based on existing data
        //
        Integer rowcount = [select count() from PartnerProduct__c where Partner__r.Is_Partner_Published__c = True];
        if (rowcount < 100) {
            // not enough existing data to complete test, just assume okay
            return;
        }
        PCSearch srch = new PCSearch();
        PCSearchForm__c form = new PCSearchForm__c();
        form.NameOrKeywords__c = null;
        PCSearchContext ctx = new PCSearchContext(form);

        PCSearchResult result = srch.productSearch(ctx);
        System.assert(result.resultIdList.size() > 20);
        PCProductMatch[] matches = result.getPage(1);
        System.assert(matches.size() > 0);
    }
*/
}