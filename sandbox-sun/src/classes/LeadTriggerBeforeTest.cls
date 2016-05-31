/**
 * This class contains unit tests for validating the LeadTriggerBefore class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @version 2013-08-07
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-08-07 - Updated to no longer validate settings as we now call the method to auto create them
 * 2012-07-19 - update to api version 24 and extending the abstract trigger class
 * 2012-03-05 - refactored into sub classes
 * 2011-09-01 - Created
 */
@isTest
public class LeadTriggerBeforeTest extends LeadTriggerBefore {
	public LeadTriggerBeforeTest(Map<Id,Lead> oldMap,List<Lead> newList) {
		super(oldMap,newList);
	}

	public static Lead createLead(Id ownerId) {
		return new Lead(
			OwnerId = ownerId,
			LastName='Accenture',
			RecordTypeId = Lead_GlobalManagement.NA_SALES_LEAD_RECORDTYPE_ID,
			Company='Accenture',
			Status='New',
			Lead_Ranking__c = 'P1',
			Products_of_Interest__c='JBoss',
			LeadSourceDetail__c='SD_RONA',
			Country = 'Narnia',
			Country_of_Order__c = 'Narnia',
			Partner_Opt_In__c=true);
	}

	public static Lead createLead() {
		return createLead(UserInfo.getUserId());
	}

	@isTest
	static void userTest() {
		User u = [select Id from User where IsActive = true and Id != :UserInfo.getUserId() limit 1];
		LeadTriggerBeforeTest triggerBefore = new LeadTriggerBeforeTest(null,new List<Lead>{createLead(),createLead(u.Id)});
		System.assertEquals(UserInfo.getUserId(),triggerBefore.currentUser.Id);
		System.assertEquals(u.Id,triggerBefore.userMap.get(u.Id).Id);
	}

	Map<Id,Lead> getNewMap() {
		return newMap;
	}

	@isTest
	static void newMapTest() {
		LeadTriggerBeforeTest triggerBefore = new LeadTriggerBeforeTest(null,new List<Lead>{createLead()});
		System.assertEquals(1,triggerBefore.getNewMap().size());
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		Lead lead = createLead();
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Lead_Before.',true);
		// insert
		LeadTriggerBefore.processTrigger(null,new List<Lead>{lead});
		// update
		LeadTriggerBefore.processTrigger(new Map<Id,Lead>{lead.Id=>lead.clone(true)},new List<Lead>{lead});
		// delete
		LeadTriggerBefore.processTrigger(new Map<Id,Lead>{lead.Id=>lead},null);
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('Lead_Before.');
	}

	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('Lead_Before.',new List<Lead>{createLead()});
	}
}