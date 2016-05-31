/**
 * This class contains unit tests for validating the LeadTriggerBeforeSFA class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-07-19
 * 2012-07-19 - update to api version 24 and extending the abstract trigger class
 * @version 2012-05-18
 * 2012-05-18 - created
 */
@isTest
private class LeadTriggerBeforeSFATest {
	@isTest
	static void assignLegacyTest() {
		Lead lead = LeadTriggerBeforeTest.createLead();
		LeadTriggerBeforeSFA beforeTrigger = new LeadTriggerBeforeSFA(null,new List<Lead>{lead});
		beforeTrigger.assignLegacy();
		System.assertEquals(lead.OwnerId,lead.Owner__c);
	}
}