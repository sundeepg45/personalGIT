/**
 * This class contains unit tests for validating the LeadTriggerAfterPartner class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-03-05
 * 2011-09-23 - Created
 * 2012-03-05 - Refactored into subclasses
 */
@isTest
private class LeadTriggerAfterPartnerTest {
	static Lead createLead(Id ownerId) {
		return LeadTriggerAfterTest.createLead(ownerId);
	}

	static Lead getLead(Id leadId) {
		return LeadTriggerAfterTest.getLead(leadId);
	}

	static testMethod void validateSettings() {
		String message = 'Missing AccountRecordType__c values:';
		String errorMessage = message;
		for(String key : LeadTriggerAfterPartner.PARTNER_RECORD_TYPE_BY_NAME.keySet()) {
			AccountRecordType__c art = AccountRecordType__c.getInstance(key);
			if(art  == null || art.RecordTypeId__c == null) {
				errorMessage += ' '+key;
			}
		}
		System.assertEquals(message,errorMessage);
	}

	static Country__c createCountry(Lead lead,String region) {
		return new Country__c(
			Iso3166Alpha2__c = lead.Country,
			Global_Region__c = region);
	}

	static Country__c queryOrInsertCountry(Country__c retval) {
		for(Country__c c : [select Iso3166Alpha2__c, Global_Region__c from Country__c where Iso3166Alpha2__c = :retval.Iso3166Alpha2__c limit 1]) {
			retval = c;
		}
		if(retval.Id == null) {
			insert retval;
		}
		return retval;
	}

	static Classification__c createClassification(String name,String key,Id parentId) {
		return new Classification__c(Name=name,IsActive__c=true,Parent__c=parentId,ReferenceKey__c=key);
	}

	static Classification__c queryOrInsertClassification(Classification__c retval,String hierarchyKey) {
		for(Classification__c c : [select Name,IsActive__c,ReferenceKey__c from Classification__c where HierarchyKey__c = :hierarchyKey and IsActive__c = true limit 1]) {
			retval = c;
		}
		if(retval.Id == null) {
			insert retval;
		}
		return retval;
	}

	static testMethod void partnerOnboardingApprovedTest() {
		Classification__c partnerType = queryOrInsertClassification(createClassification('PartnerType','PARTNER_TYPE',null),'PARTNER_TYPE');
		Classification__c partnerTier = queryOrInsertClassification(createClassification('PartnerTier','PARTNER_TIER',null),'PARTNER_TIER');
		Classification__c testPartnerType = queryOrInsertClassification(createClassification('testType','TEST_TYPE',partnerType.Id),'PARTNER_TYPE.TEST_TYPE');
		Classification__c testPartnerTier = queryOrInsertClassification(createClassification('testTier','TEST_TIER',partnerTier.Id),'PARTNER_TIER.TEST_TIER');
		Lead lead = createLead(UserInfo.getUserId());
		lead.Partner_Tier__c = testPartnerTier.Id;
		lead.Partner_Type__c = testPartnerType.Id;
		insert lead;
		queryOrInsertCountry(createCountry(lead,'EMEA'));
		Lead lead2 = getLead(lead.Id);
		lead2.Partner_Onboarding_Status__c = 'Approved';
		LeadTriggerAfterPartner afterTrigger = new LeadTriggerAfterPartner(new Map<Id,Lead>{lead.Id=>lead},new Map<Id,Lead>{lead2.Id=>lead2});
		afterTrigger.partnerOnboardingApproved();
		System.assert(! afterTrigger.hasErrors);
		// test some of the error conditions
		System.assert(afterTrigger.updateAccountsForLeads(
			new List<Account>{new Account()},
			new List<Lead>{lead},
			new Map<Id,Id>{lead.Id=>null} ).isEmpty() );
		System.assert(afterTrigger.hasErrors);
	}

	static testMethod void partnerConvertAgreementsTest() {
		Lead lead = createLead(UserInfo.getUserId());
		insert lead;
		lead = getLead(lead.Id);
		LeadTriggerAfterPartner afterTrigger = new LeadTriggerAfterPartner(new Map<Id,Lead>{lead.Id=>lead},new Map<Id,Lead>{lead.Id=>lead});
		Map<Id,Id> accountIdByLeadId = afterTrigger.convertLeads(new List<Lead>{lead});
		System.assert(! afterTrigger.hasErrors);
		System.assertEquals(1,accountIdByLeadId.size());
		Lead lead2 = getLead(lead.Id);
		lead2.Partner_Onboarding_Status__c = 'Approved';
		afterTrigger = new LeadTriggerAfterPartner(new Map<Id,Lead>{lead.Id=>lead},new Map<Id,Lead>{lead2.Id=>lead2});
		afterTrigger.partnerConvertAgreements();
		// test error conditions for convertLeads
		accountIdByLeadId = afterTrigger.convertLeads(new List<Lead>{lead});
		System.assert(afterTrigger.hasErrors);
		System.assertEquals(0,accountIdByLeadId.size());
	}
}