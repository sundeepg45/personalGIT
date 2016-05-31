/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 *
 * @author  Bryan Bosely <bbosely@redhat.com>
 * @version	  2012-03-07
 * 2010-10-04 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2012-03-07 - refactored
 * Abhijeet Anand
 * 2011-09-14 - Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release.
 */
@isTest (SeeAllData=true)private class Renewal_CotermDetailControllerTest {
	static testMethod void constructorTest() {
		Id id = UserInfo.getUserId();
		// this is the wrong type of Id to use, but it doesn't matter for this test
		ApexPages.currentPage().getParameters().put('source', id);
		Renewal_CotermDetailController controller = new Renewal_CotermDetailController();
		System.assertEquals(id, controller.sourceOpportunityId);
	}
}