@isTest(SeeAllData=true)
private class CDHToolsTest {

    //
    // Since web callouts aren't allowed in unit tests there isn't much to do but get coverage
    //
	@isTest static void searchCoverage() {

        CDHTools.SearchParams params = new CDHTools.SearchParams();
        params.AccName='Test';
        params.PartyNo='12345';
        params.Street='1st road';
        params.city='New York';
        params.postalcode='890098';
        params.DUNSNumber='898977';
        params.Country='US';
        params.state='New York';
        params.AliasFlag= true;

        CDHTools tools = new CDHTools();
        CDHTools.SearchResult[] results = tools.searchCDHParty(params);
	}


    @isTest static void searchContactCoverage() {
        CDHTools tools = new CDHTools();
        CDHTools.ContactSearchResult result = tools.searchContacts('whoever');
        System.assert(result.cdhPartyNumber == '531412', 'Party number mismatch, expected 531412 but got ' + result.cdhPartyNumber);
    }
}