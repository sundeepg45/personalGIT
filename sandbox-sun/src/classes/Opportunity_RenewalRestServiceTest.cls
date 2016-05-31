/**
 * Test class for Opportunity_RenewalRestService
 * 
 * @version 2015-01-27
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-01-27 - Depreciated create opportunity
 * 2012-05-30 - Created
 */
@isTest
private class Opportunity_RenewalRestServiceTest {
//depreciated	// test 500 error condition for createOpportunity
//depreciated	static testMethod void createOpportunity500Test() {
//depreciated		Opportunity_RenewalRestService.requestURI = 
//depreciated			Opportunity_RenewalRestService.URL_MAPPING +
//depreciated			Opportunity_RenewalRestService.CREATE_OPPORTUNITY;
//depreciated		Opportunity_RenewalRestService.requestBody = '<some random text>';
//depreciated		Opportunity_RenewalRestService.doPost();
//depreciated		System.assertEquals(500,Opportunity_RenewalRestService.statusCode);
//depreciated		System.assertNotEquals('',Opportunity_RenewalRestService.responseBody.toString());
//depreciated	}

//depreciated	// test 400 error for createOpportunity
//depreciated	static testMethod void createOpportunity400Test() {
//depreciated		Opportunity_RenewalRestService.requestURI = 
//depreciated			Opportunity_RenewalRestService.URL_MAPPING +
//depreciated			Opportunity_RenewalRestService.CREATE_OPPORTUNITY;
//depreciated		Opportunity_RenewalRestService.requestBody = Opportunity_RenewalTest.MESSAGE;
//depreciated		Opportunity_RenewalRestService.responseBody = null;
//depreciated		Opportunity_RenewalRestService.doPost();
//depreciated		System.assertEquals(400,Opportunity_RenewalRestService.statusCode);
//depreciated		System.assertNotEquals('',Opportunity_RenewalRestService.responseBody.toString());
//depreciated	}

	// test 500 error condition for accountQuery
	@isTest
	static void accountQuery500Test() {
		Opportunity_RenewalRestService.requestURI = 
			Opportunity_RenewalRestService.URL_MAPPING +
			Opportunity_RenewalRestService.QUERY_ACCOUNT;
		Opportunity_RenewalRestService.requestBody = '<some random text>';
		Opportunity_RenewalRestService.doPost();
		System.assertEquals(500,Opportunity_RenewalRestService.statusCode);
		System.assertNotEquals('',Opportunity_RenewalRestService.responseBody.toString());
	}

	// test success 200 for accountQuery
	// to do

	// test 404 error condition
	@isTest
	static void unrecognizedURITest() {
		Opportunity_RenewalRestService.requestURI = 
			Opportunity_RenewalRestService.URL_MAPPING +'*';
		Opportunity_RenewalRestService.requestBody = '<some random text>';
		Opportunity_RenewalRestService.doPost();
		System.assertEquals(404,Opportunity_RenewalRestService.statusCode);
		System.assertNotEquals('',Opportunity_RenewalRestService.responseBody.toString());
	}
}