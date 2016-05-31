/**
 * This class contains unit tests for validating the LeadTriggerAfter class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @version 2014-02-20
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-02-20 - Added getLeadMap method
 * 2013-08-07 - Updated to no longer validate settings as we now call the method to auto create them
 * 2012-10-04 - Added Partner Led Lead to createLead and getLead
 * 2012-03-05 - Refactored into subclasses
 * 2011-09-23 - Created
 */
@isTest
public class LeadTriggerAfterTest extends LeadTriggerAfter {
	public LeadTriggerAfterTest(Map<Id,Lead> oldMap,Map<Id,Lead> newMap) {
		super(oldMap,newMap);
	}

	public static Lead createLead(Id ownerId) {
		return new Lead(
			City = 'Raleigh',
			Company='Accenture',
			Country = 'US',
			Email = 'test@redhat.com.test',
			Products_of_Interest__c='JBoss',
			LastName='Accenture',
			LeadSourceDetail__c='SD_RONA',
			OwnerId = ownerId,
			Partner_Led_Lead__c = false,
			Partner_Onboarding_Status__c = 'Pending',
			Partner_Onboarding_Profile__c = 'NA Partner Portal – Strategic License',
			Partner_Opt_In__c=true,
			PostalCode = '27606',
			Qualified_By__c=null,
			RecordTypeId = '012300000000Pmx',
			Route_Around__c=false,
			RHNLogin__c='test@redhat.com.test',
			StandardConversion__c = true,
			Stage__c = 'Testing1',
			State = 'NC',
			Status='New',
			Street = '1801 Varsity Dr',
			HistoryOnInsert__c = false,
			HistoryOnInsertStage__c = null);
	}

	public static Lead createLead() {
		return createLead(UserInfo.getUserId());
	}

	public static Lead getLead(Id leadId) {
		return getLeadMap(new Set<Id>{leadId}).get(leadId);
	}

	public static Map<Id,Lead> getLeadMap(Set<Id> leadIds) {
		Map<Id,Lead> retval = new Map<Id,Lead>();
		for(Lead ld : [
			select 
				Account__c, 
				Company,
				ConvertedAccountId,
				ConvertedContactId,
				ConvertedOpportunityId,
				Country,
				Email,
				HistoryOnInsert__c,
				HistoryOnInsertStage__c,
				Interest_Score__c,
				IsConverted,
				LastOwnerModifiedDateTime__c,
				LastStageModifiedDateTime__c,
				Lead_Ranking__c,
				LastName,
				LeadSource,
				LeadSourceDetail__c,
				OwnerId,
				Partner_Led_Lead__c,
				Partner_Onboarding_Status__c,
				Partner_Onboarding_Profile__c,
				Partner_Opt_In__c,
				Partner_Tier__c,
				Partner_Type__c,
				Pre_Qualified__c,
				Products_of_Interest__c,
				Qualification_Score__c,
				Qualified_By__c,
				RecordTypeId,
				Red_Hat_Subscription_Revenue__c,
				Rejected__c,
				RHNLogin__c,
				Route_Around__c,
				StandardConversion__c,
				Status,
				Stage__c
			from Lead 
			where Id in :leadIds])
		{
			System.debug(ld);
			retval.put(ld.Id,ld.clone(true,true,true,true));
		}
		return retval;
	}

	@isTest
	static void userTest() {
		User u = [select Id from User where IsActive = true and Id != :UserInfo.getUserId() limit 1];
		LeadTriggerAfterTest triggerBefore = new LeadTriggerAfterTest(null,new Map<Id,Lead>{null=>createLead(u.Id)});
		System.assertEquals(UserInfo.getUserId(),triggerBefore.currentUser.Id);
		System.assertEquals(u.Id,triggerBefore.userMap.get(u.Id).Id);
	}

	@isTest
	static void processTriggerTest() {
		Lead lead = createLead(UserInfo.getUserId());
		// Turn off all the triggers before the insert, so we test from
		// our method calls, not from the actual insert.
		for(String key : LeadTriggerAfter.booleanSettingMap.keySet()) {
			LeadTriggerAfter.booleanSettingMap.put(key,false);
		}
		insert lead;
		lead = getLead(lead.Id);
		// Turn on all the triggers, and make sure everything is tested.
		for(String key : LeadTriggerAfter.booleanSettingMap.keySet()) {
			LeadTriggerAfter.booleanSettingMap.put(key,true);
		}
		// simulate an insert
		LeadTriggerAfter.processTrigger(null,new Map<Id,Lead>{lead.Id=>lead});
		// simulate an update
		LeadTriggerAfter.processTrigger(new Map<Id,Lead>{lead.Id=>lead},new Map<Id,Lead>{lead.Id=>lead});
		// simulate a delete
		LeadTriggerAfter.processTrigger(new Map<Id,Lead>{lead.Id=>lead},null);
	}

	@isTest
	static void deployTest() {
		Lead lead = createLead(UserInfo.getUserId());
		insert lead;
		update lead;
		delete lead;
	}
}