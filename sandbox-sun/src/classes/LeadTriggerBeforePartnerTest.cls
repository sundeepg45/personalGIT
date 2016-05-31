/**
 * This class contains unit tests for validating the LeadTriggerBefore class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-03-05
 * 2011-09-01 - Created
 * 2012-03-05 - refactored into sub classes
 */
@isTest
private class LeadTriggerBeforePartnerTest {
	static Lead createLead() {
		return LeadTriggerBeforeTest.createLead();
	}

	static testMethod void partnerOptInTest() {
		Lead lead = createLead();
		Lead lead2 = lead.clone();
		LeadTriggerBeforePartner t = new LeadTriggerBeforePartner(new Map<Id,Lead>{null=>lead2},new List<Lead>{lead});
		t.partnerOptIn();
		System.assertEquals(null,lead.Partner_Opt_In_Last_Modified_By__c);
		System.assertEquals(null,lead.Partner_Opt_In_Last_Modified_Date__c);
		lead2.Partner_Opt_In__c = ! lead.Partner_Opt_In__c;
		t.partnerOptIn();
		System.assertEquals(UserInfo.getUserId(),lead.Partner_Opt_In_Last_Modified_By__c);
		System.assertNotEquals(null,lead.Partner_Opt_In_Last_Modified_Date__c);
	}
}