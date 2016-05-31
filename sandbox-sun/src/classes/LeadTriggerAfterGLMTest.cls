/**
 * This class contains unit tests for validating the LeadTriggerAfterGLM class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @version 2014-04-28
 * @author Bill C Riemers <briemers@redhat.com>
 * 2014-04-28 - Commented out usage of mkt_cl_cmp_media_name__c
 * 2014-04-25 - Commented out usage of mkt_cl_cmp_cta__c to allow the changing of field type
 * 2014-02-20 - Added a test method for insertLeadForReporting
 * 2013-08-21 - Added test methods for opportunityAssignmentNotification.
 * 2013-08-07 - Added test methods for leadConvertWizard
 * 2012-04-11 - Corrected commented code for OpportunityBeforeTrigger
 * 2012-03-29 - Commented out code for US17312
 * 2012-03-05 - Refactored into subclasses
 * 2011-09-23 - Created
 * Scott Coleman <scoleman@redhat.com>
 * 2013-11-07 - Updated test for opportunityAssignmentNotification to resolve release issues
 * 2013-09-17 - Test method for errorNotification
 * 2013-09-13 - Test method for clearOpportunityTeam
 * 2013-08-12 - Added test coverage for leadConvertWizard default opp amount and stage
 * 2013-05-02 - Now touching related CampaignMember objects to invoke their triggers
 * 2012-10-04 - updated test to include no LMH for partner led leads
 * 2012-07-13 - saving last ownership change datetime on LMH record
 * 2012-05-31 - updated test to include no LMH for deal reg record types
 * 2012-05-21 - updated test to include Suspect leads
 * 2012-04-09 - SLC Commented out dependency on OpportunityBeforeTrigger for Release 14
 */
@isTest
private class LeadTriggerAfterGLMTest {
	static Lead createLead(Id ownerId) {
		return LeadTriggerAfterTest.createLead(ownerId);
	}

	static Lead getLead(Id leadId) {
		return LeadTriggerAfterTest.getLead(leadId);
	}

	public static Account emeaAccount {
		get {
			if(emeaAccount == null) {
				RecordType recordType = [
					select name
					from RecordType
					where name = 'EMEA Account'
						and SObjectType = 'Account'
						and IsActive = true
					limit 1 ];
				emeaAccount = new Account(
					RecordTypeId = recordType.Id,
					BillingCity = 'Raleigh',
					BillingCountry = 'US',
					BillingPostalCode = '27606',
					BillingState = 'North Carolina',
					BillingStreet = '1801 Varsity Drive',
					CurrencyIsoCode = 'USD',
					Name = 'Red Hat',
					PrimaryBillingAccountNumber__c = '12345',
					OracleAccountNumber__c = '12345',
					OraclePartyNumber__c = '12345',
					ShippingCity = 'Raleigh',
					ShippingCountry = 'US',
					ShippingPostalCode = '27606',
					ShippingState = 'North Carolina',
					ShippingStreet = '1801 Varsity Drive',
					VATNumber__c = '67890');
			}
			return emeaAccount;
		}
	}

	public static Id emeaAccountId {
		get {
			if(emeaAccount.Id == null) {
				insert emeaAccount;
			}
			return emeaAccount.Id;
		}
	}

	public static Opportunity emeaSalesOpportunity {
		get {
			if(emeaSalesOpportunity == null) {
				// create an opportunity
				RecordType recordType = [
					select name
					from RecordType
					where Name like 'EMEA Sales%'
						and SObjectType = 'Opportunity'
						and IsActive = true
					limit 1 ];
				emeaSalesOpportunity = new Opportunity(
					RecordTypeId = recordType.Id,
					AccountId = emeaAccountId,
					StageName = 'Prepare',
					CloseDate = Date.today(),
					BillingAccountNumber__c = emeaAccount.PrimaryBillingAccountNumber__c,
					BillingAddress__c = emeaAccount.BillingStreet,
					BillingCity__c = emeaAccount.BillingCity,
					BillingState__c = emeaAccount.BillingState,
					BillingZipPostalCode__c = emeaAccount.BillingPostalCode,
					BillingCountry__c = emeaAccount.BillingCountry,
					Country_Of_Order__c = emeaAccount.BillingCountry,
					CurrencyIsoCode = emeaAccount.CurrencyIsoCode,
					FulfillmentChannel__c = 'Direct - End Customer',
					Name = 'test Opportunity',
					OpportunityType__c = 'Standard',
					PaymentType__c = 'NA Purchase Order');
				emeaSalesOpportunityId = null;
			}
			return emeaSalesOpportunity;
		}
		set {
			emeaSalesOpportunity = value;
			Id oppId = null;
			if(value != null) {
				oppId = value.Id;
			}
			emeaSalesOpportunityId = oppId;
		}
	}

	public static Id emeaSalesOpportunityId {
		get {
// removing dependency on OpportunityTriggerBefore for Release 14
			if(emeaSalesOpportunity.Id == null) {
//				for(String key : OpportunityTriggerBefore.booleanSettingMap.keySet()) {
//					OpportunityTriggerBefore.booleanSettingMap.put(key,false);
//				}
				insert emeaSalesOpportunity;
			}
			return emeaSalesOpportunity.Id;
		}
		set;
	}

	static Campaign createCampaign(String email) {
		Id userId = UserInfo.getUserId();
		if(email == null) {
			email = [select Email from User where Id=:userId ].Email;
		}
		return new Campaign(
			Type='Onsite Promo',
			mkt_cl_cmp_ad_name__c ='Acn',
//			mkt_cl_cmp_media_name__c='Star',
			mkt_cl_cmp_owner__c=email,
			mkt_cl_cmp_is_internal__c=true,
			mkt_cl_cmp_audience__c='VP',
			mkt_cl_cmp_director__c='Emma Battle',
			mkt_cl_cmp_category__c = 'Anything',
			mkt_cl_cmp_vertical__c = 'Manufacturing',
			Campaign_Partner__c = 'OEM',
			mkt_cl_cmp_geo__c='NA',
//			mkt_cl_cmp_cta__c='Renew',
			mkt_cl_cmp_product_group__c= 'Multiple',
			Origin__c= 'Sales',
			Media_Source__c='CNET',
			Landing_Page_URL__c= 'http://Sf.com',
			Notes_for_Sales__c = 'Text',
			Description = 'Text',
			Status = 'Plannned',
			IsActive = true,
			EndDate = Date.Today()+1,
			OwnerId = userId,
			Solution_Code__c = 'SC',
			Title__c = 'Title',
			Expected_Number_of_Responses__c = 1,
			Name = 'Name');
	}

	static Campaign campaign {
		get {
			if(campaign == null) {
				campaign = createCampaign(null);
				insert campaign;
			}
			return campaign;
		}
		set;
	}	

	static CampaignMember member {
		get {
			if(member == null) {
				Lead lead = createLead(Util.globalLeadRoutingQueue);
				insert lead;
				member = new CampaignMember(
					LeadId = lead.Id,
					CampaignId = campaign.Id,
					Status = 'Sent');
				insert member;
			}
			return member;
		}
		set;
	}

//US17312	static testMethod void createNPSATest() {
//US17312		Lead lead = createLead(Util.globalLeadRoutingQueue);
//US17312		LeadTriggerAfterGLM.toAccountId = emeaAccountId;
//US17312		LeadTriggerAfterGLM.toOpportunityId = emeaSalesOpportunityId;
//US17312		LeadTriggerAfterGLM afterTrigger = new LeadTriggerAfterGLM(new Map<Id,Lead>{lead.Id=>lead},new Map<Id,Lead>{lead.Id=>lead});
//US17312		afterTrigger.createNPSA();
//US17312		System.assert(! afterTrigger.hasErrors);
//US17312		Opportunity opp = [
//US17312			select
//US17312				AccountId,
//US17312				ASIDST__c,
//US17312				NonPrimaryShippingAddress__r.Account__c,
//US17312				ShippingAddress__c,
//US17312				ShippingCity__c,
//US17312				ShippingState__c,
//US17312				ShippingZipPostalCode__c,
//US17312				ShippingCountry__c
//US17312			from Opportunity where Id = :emeaSalesOpportunityId ];
//US17312		System.assertEquals(lead.Street,opp.ShippingAddress__c);
//US17312		System.assertEquals(lead.City,opp.ShippingCity__c);
//US17312		System.assertEquals(lead.State,opp.ShippingState__c);
//US17312		System.assertEquals(lead.PostalCode,opp.ShippingZipPostalCode__c);
//US17312		System.assertEquals(lead.Country,opp.ShippingCountry__c);
//US17312		System.assertEquals(emeaAccountId,opp.NonPrimaryShippingAddress__r.Account__c);
//US17312		Id npsaId = opp.NonPrimaryShippingAddress__r.Id;
//US17312		// now try with a pre-existing Non Primary Shipping Address
//US17312		delete emeaSalesOpportunity;
//US17312		emeaSalesOpportunity = null;
//US17312		LeadTriggerAfterGLM.toOpportunityId = emeaSalesOpportunityId;
//US17312		afterTrigger.createNPSA();
//US17312		System.assert(! afterTrigger.hasErrors);
//US17312		Opportunity opp2 = [
//US17312			select
//US17312				AccountId,
//US17312				ASIDST__c,
//US17312				NonPrimaryShippingAddress__r.Account__c,
//US17312				ShippingAddress__c,
//US17312				ShippingCity__c,
//US17312				ShippingState__c,
//US17312				ShippingZipPostalCode__c,
//US17312				ShippingCountry__c
//US17312			from Opportunity where Id = :emeaSalesOpportunityId ];
//US17312		System.assertEquals(lead.Street,opp2.ShippingAddress__c);
//US17312		System.assertEquals(lead.City,opp2.ShippingCity__c);
//US17312		System.assertEquals(lead.State,opp2.ShippingState__c);
//US17312		System.assertEquals(lead.PostalCode,opp2.ShippingZipPostalCode__c);
//US17312		System.assertEquals(lead.Country,opp2.ShippingCountry__c);
//US17312		System.assertEquals(emeaAccountId,opp2.NonPrimaryShippingAddress__r.Account__c);
//US17312		System.assertEquals(npsaId,opp2.NonPrimaryShippingAddress__r.Id);
//US17312		// this time we'll generate an error
//US17312		delete emeaSalesOpportunity;
//US17312		emeaSalesOpportunity = null;
//US17312		afterTrigger.createNPSA();
//US17312		System.assert(afterTrigger.hasErrors);
//US17312	}

	@isTest
	static void insertLeadForReportingTest() {
		Lead lead = createLead(UserInfo.getUserId());
		AbstractTrigger.setBooleanSettings('Lead_After.',false);
		insert lead;
		LeadTriggerAfterGLM afterTrigger = new LeadTriggerAfterGLM(null,new Map<Id,Lead>{lead.Id=>lead});
		afterTrigger.insertLeadForReporting();
		LeadForReporting__c lfr = [
			select Id
			from LeadForReporting__c
			where LeadId__c = :lead.Id ];
	}

	@isTest
	static void insertHistoryTest1() {
		AbstractTrigger.setBooleanSettings('Lead_After.',false);
		Lead lead = createLead(Util.globalLeadRoutingQueue);
		insert lead;
		MAp<Id,Lead> leadMap = new Map<Id,Lead>{lead.Id=>lead};
		LeadTriggerAfterGLM afterTrigger = new LeadTriggerAfterGLM(null,new Map<Id,Lead>{lead.Id=>lead});
		afterTrigger.insertLeadForReporting();
		afterTrigger.insertHistory();
		Lead newLead = getLead(lead.Id);
		newLead.Stage__c = 'Testing 2';
		newLead.OwnerId = Util.globalLeadRoutingQueue;
		afterTrigger = new LeadTriggerAfterGLM(leadMap,new Map<Id,Lead>{newLead.Id=>newLead});
		afterTrigger.insertLeadForReporting();
		afterTrigger.insertHistory();
		LeadManagementHistory__c lmh = [
			select 
				LeadStageFrom__c,
				LeadStageTo__c,
				LFR__c
			from LeadManagementHistory__c
			where Lead__c = :lead.Id
			order by CreatedDate desc, Id desc
			limit 1 ];
		System.assertEquals(lead.Stage__c,lmh.LeadStageFrom__c);
		System.assertEquals(newLead.Stage__c,lmh.LeadStageTo__c);
		System.assertNotEquals(null,lmh.LFR__c);
	}

	@isTest
	static void insertHistoryTest2() {
		Util.setTesting(false);
		AdminByPass__c bypass = AdminByPass__c.getInstance();
		bypass.IsAdmin__c = true;
		upsert bypass;

		Lead lead = createLead(LeadTriggerBeforeGLM.NEW_LEADS_QUEUE);
		List<Lead> leads = new List<Lead>{
			lead,
			lead.clone(),
			lead.clone() };
		leads[0].OwnerId = LeadTriggerBeforeGLM.NEW_LEADS_QUEUE;
		leads[0].HistoryOnInsert__c = true;
		leads[0].HistoryOnInsertStage__c = LeadTriggerBeforeGLM.SUSPECT; 
		leads[1].RecordTypeId = '012600000005DofAAE'; // APAC Deal Registration
		leads[1].Stage__c = 'Testing1';
		leads[1].Red_Hat_Subscription_Revenue__c = 100;
		leads[2].Stage__c = 'Testing2';
		leads[2].Red_Hat_Subscription_Revenue__c = 100;
		leads[2].Partner_Led_Lead__c = true;
		AbstractTrigger.setBooleanSettings('Lead_After.',false);
		insert leads;
		Map<Id,Lead> leadMap = LeadTriggerAfterTest.getLeadMap(new Map<Id,Lead>(leads).keySet());
		leads[0] = leadMap.get(leads[0].Id);
		leads[1] = leadMap.get(leads[1].Id);
		leads[2] = leadMap.get(leads[2].Id);

		Test.startTest();

		LeadTriggerAfterGLM afterTrigger = new LeadTriggerAfterGLM(null,leadMap);
		afterTrigger.insertLeadForReporting();
		afterTrigger.insertHistory();
		LeadManagementHistory__c lmh = [
			select 
				LeadStageFrom__c,
				LeadStageTo__c,
				LFR__c
			from LeadManagementHistory__c
			where Lead__c = :leads[0].Id ];
		System.assertEquals(LeadTriggerBeforeGLM.SUSPECT,lmh.LeadStageFrom__c);
		System.assertNotEquals(null,lmh.LFR__c);

		leadMap.remove(leads.remove(0).Id);

		System.assertEquals(0,[
			select count() 
			from LeadManagementHistory__c 
			where Lead__c in :leadMap.keySet() ]);

		List<Lead> newList = leads.deepClone(true);
		newList[0].Stage__c = leads[0].Stage__c+'.1';
		newList[1].Stage__c = leads[1].Stage__c+'.1';
		Map<Id,Lead> newMap = new Map<Id,Lead>(newList);
		afterTrigger = new LeadTriggerAfterGLM(leadMap,newMap);
		afterTrigger.insertLeadForReporting();
		afterTrigger.insertHistory();

		Test.stopTest();

		System.assertEquals(0,[
			select count() 
			from LeadManagementHistory__c 
			where Lead__c in :newMap.keySet() ]);
	}

	@isTest
	static void updateHistoryTest() {
		Lead lead = createLead(Util.globalLeadRoutingQueue);
		lead.LastOwnerModifiedDateTime__c = DateTime.Now();
		insert lead;
		Lead lead2 = getLead(lead.Id);
		LeadManagementHistory__c lmh = LeadTriggerAfterGLM.updateLMH(lead,lead2,new LeadManagementHistory__c());
		LeadTriggerAfterGLM.leadManagementHistoryMap.put(lead.Id,lmh);
		lead2.OwnerId = UserInfo.getUserId();
		LeadTriggerAfterGLM afterTrigger = new LeadTriggerAfterGLM(new Map<Id,Lead>{lead.Id=>lead},new Map<Id,Lead>{lead2.Id=>lead2});
		afterTrigger.updateHistory();
		System.assertNotEquals(lead2.OwnerId,lmh.OwnerId_To__c);
		insert lmh;
		afterTrigger.updateHistory();
		System.assertEquals(lead2.OwnerId,lmh.OwnerId_To__c);
		System.assertNotEquals(null,lmh.FromOwnerModifiedDateTime__c);
	}

	@isTest
	static void touchCampaignMembersTest() {
		CampaignMember testMember = member;
		Lead testLead = getLead(member.LeadId);
		Lead updatedLead = testLead.clone(true);
		updatedLead.Stage__c = 'Marketing Disqualified';
		LeadTriggerAfterGLM afterTrigger = new LeadTriggerAfterGLM(new Map<Id,Lead>{testLead.Id=>testLead},new Map<Id,Lead>{testLead.Id=>updatedLead});
		afterTrigger.touchCampaignMembers();
	}

	// No leads will actually be processed by this test, as we will not use a converted lead.
	// Rather this test is just to verify the logic works for finding the lead id's, and to
	// invoke the future call for coverage.
	@isTest
	static void leadConvertWizardTest() {
		Set<String> fieldPaths = LeadTriggerAfterGLM.leadConversionWizardFieldPaths;
		fieldPaths.clear();
		fieldPaths.add('Desired_Account_Owner__c');
		fieldPaths.add('Desired_Contact_Owner__c');
		fieldPaths.add('Desired_Opportunity_Owner__c');
		fieldPaths.add('Desired_Opportunity_CloseDate__c');
		fieldPaths.add('Business_Unit__c');
		Lead lead = createLead(UserInfo.getUserId());
		Lead updatedLead = lead.clone(true);
		updatedLead.StandardConversion__c = false;
		updatedLead.Desired_Account_Owner__c = lead.OwnerId;
		updatedLead.Desired_Contact_Owner__c = lead.OwnerId;
		updatedLead.Desired_Opportunity_Owner__c = lead.OwnerId;
		updatedLead.Desired_Opportunity_CloseDate__c = System.today();
		updatedLead.Business_Unit__c = 'Cloud';
		updatedLead.SendEmailToOpportunityTeam__c = true;
		LeadTriggerBeforeGLM.toOpportunity = true;
		LeadTriggerAfterGLM afterTrigger = new LeadTriggerAfterGLM(new Map<Id,Lead>{lead.Id=>lead},new Map<Id,Lead>{updatedLead.Id=>updatedLead});
		Test.startTest();
		Set<Id> leadIds = afterTrigger.leadConvertWizard();
		Test.stopTest();
		System.assertEquals(1,leadIds.size());
		System.assert(leadIds.contains(updatedLead.Id),'Expected '+updatedLead.Id);
	}

	static Map<Id,Lead> convertedLeadMap {
		get {
			if(convertedLeadMap == null) {
				final Id userId = UserInfo.getUserId();
				final Set<Id> recordIds = Lead_GlobalManagement.GLM_RECORDTYPE_IDS;
				convertedLeadMap = new Map<Id,Lead>((List<Lead>)Database.query(LeadTriggerAfterGLM.leadConvertWizardQueryString
					+' from Lead'
					+' where IsConverted = true'
					+'	and ConvertedAccount.OwnerId != :userId'
					+'	and ConvertedAccount.Owner.IsActive = true'
					+'	and ConvertedContact.OwnerId != :userId'
					+'	and ConvertedContact.Owner.IsActive = true'
					+'	and ConvertedOpportunity.OwnerId != :userId'
					+'	and ConvertedOpportunity.Owner.IsActive = true'
					+'	and RecordTypeId in :recordIds'
					+' order by LastModifiedDate desc, ConvertedAccount.CreatedDate desc, ConvertedContact.CreatedDate desc'
					+' limit 1'));
			}
			return convertedLeadMap;
		}
	}

	@isTest(SeeAllData=true) // we need to find an actual converted lead for this test to work
	static void leadConvertWizardFindRecordsTest() {
		System.assertNotEquals(0,convertedLeadMap.size());
		Set<String> fieldPaths = LeadTriggerAfterGLM.leadConversionWizardFieldPaths;
		fieldPaths.clear();
		fieldPaths.add('Desired_Account_Owner__c');
		fieldPaths.add('Desired_Contact_Owner__c');
		fieldPaths.add('Desired_Opportunity_Owner__c');
		fieldPaths.add('Desired_Opportunity_CloseDate__c');
		fieldPaths.add('Business_Unit__c');
		insert new LeadConvertWizardOppDefaultAmount__c(Name='Test', Super_Region__c='TEST', Business_Unit__c='TestBU', Amount__c=100, Currency__c='USD');
		insert new LeadConvertWizardOppDefaultStage__c(Name='Test', Super_Region__c='TEST', Stage__c='Engage', Probability__c=1);
		Id userId = UserInfo.getUserId();
		Map<Id,Account> accountMap = new Map<Id,Account>();
		Map<Id,Contact> contactMap = new Map<Id,Contact>();
		Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
		Long compareTime = DateTime.now().getTime();
		Date closeDate = System.today();
		Test.startTest();
		List<Lead> leads = LeadTriggerAfterGLM.leadConvertWizardQueryLeads(convertedLeadMap.keySet());
		System.assertEquals(convertedLeadMap.size(),leads.size());
		for(Lead ld : leads) {
			System.assert(convertedLeadMap.containsKey(ld.Id),'Expected Lead Id: '+ld.Id);
			ld.StandardConversion__c = false;
			ld.Desired_Account_Owner__c = userId;
			ld.Desired_Contact_Owner__c = userId;
			ld.Desired_Opportunity_Owner__c = userId;
			ld.Desired_Opportunity_CloseDate__c = closeDate;
			ld.Super_Region__c = 'TEST';
			ld.Business_Unit__c = 'TestBU';
			for(DateTime d : new Set<DateTime>{ld.ConvertedAccount.CreatedDate,ld.ConvertedContact.CreatedDate}) {
				if(d != null) {
					Long xcompareTime = d.getTime();
					if(xcompareTime < compareTime) {
						compareTime = xcompareTime;
					}
				}
			}
		}
		LeadTriggerAfterGLM.leadConvertWizardFindRecords(leads,compareTime,accountMap,contactMap,opportunityMap);
		Test.stopTest();
		System.assertEquals(leads.size(),accountMap.size());
		for(Account acc : accountMap.values()) {
			System.assertEquals(userId,acc.OwnerId);
		}
		System.assertEquals(leads.size(),accountMap.size());
		for(Contact con : contactMap.values()) {
			System.assertEquals(userId,con.OwnerId);
		}
		System.assertEquals(leads.size(),opportunityMap.size());
		for(Opportunity opp : opportunityMap.values()) {
			System.assertEquals(userId,opp.OwnerId);
			System.assertEquals(closeDate,opp.CloseDate);
			System.assertEquals(100,opp.Amount);
			System.assertEquals('Engage',opp.StageName);
			System.assertEquals(1,opp.Probability);
		}
	}

	@isTest(SeeAllData=true) // We need to access e-mail templates
	static void opportunityAssignmentEmailTemplateTest() {
		EmailTemplate et = [
			select DeveloperName, Body, Subject
			from EmailTemplate
			where IsActive = true
			order by LastModifiedDate limit 1 ];
		StringSetting__c emailTemplateSetting = StringSetting__c.getInstance(LeadTriggerAfterGLM.OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE_SETTING);
		if(emailTemplateSetting == null) {
			emailTemplateSetting = new StringSetting__c(
				Name=LeadTriggerAfterGLM.OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE_SETTING);
		}
		emailTemplateSetting.Value__c=et.DeveloperName;
		upsert emailTemplateSetting;
		Test.startTest();
		EmailTemplate et2 = LeadTriggerAfterGLM.OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE;
		Test.stopTest();
		System.assertEquals(et.Id,et2.Id);
		System.assertEquals(et.Subject,et2.Subject);
		System.assertEquals(et.Body,et2.Body);
	}

	@isTest(SeeAllData=true) // we need to find an actual converted lead for this test to work
	static void opportunityAssignmentNotificationTest() {
		System.assertNotEquals(0,convertedLeadMap.size());
		final Id userId = UserInfo.getUserId();
		final String email = UserInfo.getUserEmail();
		List<OpportunityTeamMember> salesTeam = new List<OpportunityTeamMember>();
		for(Lead ld : convertedLeadMap.values()) {
			ld.SendEmailToOpportunityTeam__c = true;
			salesTeam.add(new OpportunityTeamMember(
				OpportunityId = ld.ConvertedOpportunityId,
				UserId = userId,
				TeamMemberRole=LeadTriggerAfterGLM.INSIDE_REP_STRING));
		}
		EmailTemplate et = new EmailTemplate(
			Subject='anything',
			Body='anything');
		LeadTriggerAfterGLM.OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE = et;
		delete [select Id from OpportunityTeamMember where Id in :convertedLeadMap.keySet()];
		insert salesTeam;
		Test.startTest();
		Map<Boolean,List<Messaging.SingleEmailMessage>> resultMap = LeadTriggerAfterGLM.opportunityAssignmentNotification(convertedLeadMap.values());
		Test.stopTest();
		System.assertEquals(0,resultMap.get(false).size());
		System.assertEquals(convertedLeadMap.size(),resultMap.get(true).size());
		for(Messaging.SingleEmailMessage mail : resultMap.get(true)) {
			System.assertEquals(et.Subject,mail.Subject);
			System.assert(mail.getPlainTextBody().startsWith(et.Body));
			//the cc address may be some other arbitrary user, commenting out this assert
			//System.assertEquals(email,mail.getCcAddresses()[0]);
			System.assertEquals(1,mail.getToAddresses().size());
			System.assertNotEquals(null,mail.getToAddresses()[0]);
		}
	}

	@isTest
	static void opportunityDefaultTest() {
		insert new LeadConvertWizardOppDefaultAmount__c(Name='Test', Super_Region__c='TEST', Business_Unit__c='TestBU', Amount__c=100, Currency__c='USD');
		insert new LeadConvertWizardOppDefaultStage__c(Name='Test', Super_Region__c='TEST', Stage__c='Engage', Probability__c=1);		
		System.assert(LeadTriggerAfterGLM.opportunityDefaultAmountMap.size()>0);
		System.assert(LeadTriggerAfterGLM.opportunityDefaultStageMap.size()>0);
	}

	@isTest
	static void clearOpportunityTeamTest() {
		Opportunity opp = new Opportunity(
			Id = emeaSalesOpportunityId, 
			OwnerId = UserInfo.getUserId());

		// converting to a coverage test for now as this method is not 100% compatible with opp splits. logging an issue to resolve root issue.
		LeadTriggerAfterGLM.clearOpportunityTeam(new List<Opportunity>{opp});
	}

	@isTest
	static void errorNotificationTest() {
		EmailTemplate et = new EmailTemplate(
			Subject='anything',
			Body='anything');
		LeadTriggerAfterGLM.LEAD_CONVERSION_ERROR_EMAIL_TEMPLATE = et;		
		Test.startTest();
		Map<Boolean,List<Messaging.SingleEmailMessage>> resultMap = LeadTriggerAfterGLM.errorNotification(new List<Lead>{createLead(UserInfo.getUserId())}, new List<String>{'Test errror'});
		Test.stopTest();
		System.assertEquals(0,resultMap.get(false).size());
		System.assertEquals(1,resultMap.get(true).size());
		Messaging.SingleEmailMessage mail = resultMap.get(true)[0];
		System.assertEquals(et.Subject,mail.Subject);
		System.assert(mail.getPlainTextBody().startsWith(et.Body));
		System.assertEquals(1,mail.getToAddresses().size());
		System.assertEquals(UserInfo.getUserEmail(),mail.getToAddresses()[0]);	
	}
}