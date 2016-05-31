/**
 * Test the controller extension used for the StrategicPlanTab page.
 *
 * @version 2013-09-18
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-09-18 - disabling PDF attachment coverage for September release
 * 2013-09-04 - adding coverage for PDF attachments
 * 2013-08-14 - disabling currency trigger coverage for August release
 * 2013-08-05 - added coverage for currency trigger
 * 2013-05-02 - added coverage for getPlanContributors()
 * 2013-04-30 - added coverage for saveRecord()
 * 2013-04-09 - added approval tests
 * 2013-04-01 - added submit action 
 * 2013-03-21 - created
 * Bill C Riemers <briemers@redhat.com>
 * 2013-07-09 - added check for getShowSummaryEnabled method
 * 2013-07-04 - added coverage for showSummary
 * 2013-05-23 - Create account profile
 * 2013-05-09 - updated tests to reflect method name changes
 * 2013-04-22 - Changed to extend controller class and moved test only methods into this class
 */
@isTest
public class StrategicPlanControllerExtnTest extends StrategicPlanControllerExtension {
	/**
	 * Construct using a TabUIController.
	 * 
	 * @param tabUIController
	 */
	StrategicPlanControllerExtnTest(TabUIController tabUIController) {
		super(tabUIController);
	}

	/**
	 * Construct using a standard controller.
	 * 
	 * @param stdController
	 */
	StrategicPlanControllerExtnTest(ApexPages.StandardController stdController) {
		super(stdController);
	}

	/**
	 * This allows us to test the insertApprovalProxy call
	 * @return Id
	 */
	public Id test_insertApprovalProxy(){
		return insertApprovalProxy();
	}

	/**
	 * This allows us to test the deleteApprovalProxy call
	 */
	public void test_deleteApprovalProxy(){
		deleteApprovalProxy();
	}

	public with sharing class TestException extends Exception {}

	/**
	 * This just a reference to accountProfile.Account__r.
	 */
	static Account account {
		get {
			return accountProfile.Account__r;
		}
	}

	/**
	 * Reference to AccountProfileSWOTControllerTest.accountProfile.
	 */
	static Account_Profile__c accountProfile {
		get {
			Account_Profile__c profile = AccountProfileSWOTControllerTest.accountProfile;
			profile.Account__r.CurrencyIsoCode = 'EUR';
			update profile.Account__r;
			return profile;
		}
	}

	/**
	 * Reference to AccountProfileSWOTControllerTest.accountProfileId.
	 */
	static Id accountProfileId {
		get {
			return AccountProfileSWOTControllerTest.accountProfileId;
		}
	}

	/**
	 * A test strategicPlan.
	 */
	public static StrategicPlan__c strategicPlan {
		get {
			if(strategicPlan == null) {
				strategicPlan = new StrategicPlan__c(
					Name='Test Strategic Plan',
					AccountProfile__c = accountProfileId,
					Account__c = account.Id,
					OwnerId = testUser.Id,
					CurrencyIsoCode = 'EUR',
					Status__c = 'Draft');
			}
			return strategicPlan;
		}
	}

	/**
	 * The strategicPlan Id.
	 */
	public static Id strategicPlanId {
		get {
			if(strategicPlan.Id == null) {
				insert strategicPlan;
			}
			return strategicPlan.Id;
		}
	}

	/**
	 * Create and insert a strategicPlanReview.
	 */
	static StrategicPlan_Review__c strategicPlanReview {
		get {
			if(strategicPlanReview == null) {
				strategicPlanReview = new StrategicPlan_Review__c(
					StrategicPlan__c = strategicPlanId);
				insert strategicPlanReview;
			}
			return strategicPlanReview;
		}
		set;
	}

	/**
	 * Insert a test user.  (Yuck)
	 */
	static User testUser {
		get {
			if(testUser == null) {
				User u = [
					select 
						Alias,
						CommunityNickname,
						Email,
						EmailEncodingKey,
						FirstName,
						LastName,
						LocaleSidKey, 
						LanguageLocaleKey,
						TimeZoneSidKey,
						UserRole.Name,
						Profile.Name
					from User 
					where Id = :UserInfo.getUserId()];
				testUser = new User(
					Alias='test',
					CommunityNickname=u.CommunityNickname+'test', 
					LocaleSidKey=u.LocaleSidKey,
					Email=u.Email+'.test',
					EmailEncodingKey=u.EmailEncodingKey, 
					FirstName = 'Test',
					LanguageLocaleKey=u.LanguageLocaleKey,
					LastName = 'User',
					ManagerId = testManager.Id,
					ProfileId = UserInfo.getProfileId(),
					Profile = u.Profile,
					Region__c = 'NA',
					TimeZoneSidKey=u.TimeZoneSidKey, 
					Username=u.Email+'.test',
					UserRoleId = UserInfo.getUserRoleId(),
					UserRole = u.UserRole );
				System.runAs(new User(Id=UserInfo.getUserId())) {
					insert testUser;
				}					
			}
			return testUser;
		}
		set;
	}

	/**
	 * Insert a test management user.  (Yuck)
	 */
	static User testManager {
		get {
			if(testManager == null) {		
				User u = [
					select 
						Alias,
						CommunityNickname,
						Email,
						EmailEncodingKey,
						FirstName,
						LastName,
						LocaleSidKey, 
						LanguageLocaleKey,
						TimeZoneSidKey,
						UserRole.Name,
						Profile.Name
					from User 
					where Id = :UserInfo.getUserId()];
				testManager = new User(
					Alias='manager',
					CommunityNickname=u.CommunityNickname+'manager', 
					LocaleSidKey=u.LocaleSidKey,
					Email=u.Email+'.manager',
					EmailEncodingKey=u.EmailEncodingKey, 
					FirstName = 'Test',
					LanguageLocaleKey=u.LanguageLocaleKey,
					LastName = 'Manager',
					ProfileId = u.ProfileId,
					Profile = u.Profile,
					Region__c = 'NA',
					TimeZoneSidKey=u.TimeZoneSidKey, 
					Username=u.Email+'.manager',
					UserRoleId = u.UserRoleId,
					UserRole = u.UserRole );
				System.runAs(new User(Id=UserInfo.getUserId())) {
					insert testManager;
				}			
			}
			return testManager;
		}	
		set;
	}

	static TrackingEventLog__c eventLog {
		get {
			if(eventLog == null) {
				TrackingEvent__c event = new TrackingEvent__c(
					Code__c = 'SPEdit' );
				insert event;
				eventLog = new TrackingEventLog__c(
					User__c = testUser.Id,
					RelatedObjectId__c = strategicPlanId,
					Data2__c = 'Test Account Team Role',
					TrackingEvent__c = event.Id );
				insert eventLog;
			}
			return eventLog;
		}
		set;
	}

	@isTest
	static void createTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlanEdit?retURL=/anything'));
		TabUIController controller = new TabUIController();
		controller.setTabId('Account', account.Id);
		StrategicPlanControllerExtnTest extension = new StrategicPlanControllerExtnTest(controller);
		System.assertEquals(null,extension.getId());
		StrategicPlan__c s = extension.getStrategicPlan();
		System.assertEquals(null,s.Id);
		System.assertEquals(account.Id,s.Account__c);
		PageReference cancelStrategicPlan = extension.cancelStrategicPlan();
		System.assertEquals('/anything',cancelStrategicPlan.getUrl());
	}

	@isTest
	static void viewTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlanView?id='+strategicPlanId));
		ApexPages.StandardController stdController = new ApexPages.StandardController(strategicPlan);
		StrategicPlanControllerExtnTest extension = new StrategicPlanControllerExtnTest(stdController);
		StrategicPlan__c r = (StrategicPlan__c)extension.getRecord();
		System.assertEquals(strategicPlanId,r.Id);
		System.assertEquals(strategicPlanId,extension.getId());
		StrategicPlan__c s = extension.getStrategicPlan();
		System.assertEquals(strategicPlanId,s.Id);
		System.assertEquals(strategicPlan.Name,s.Name);
		System.assertEquals(account.Id,s.Account__c);
		extension.getAccountTeamMembers();
		extension.getPlanContributors();
		extension.navigateToOnDelete();
	}

	@isTest
	static void saveTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlanView?id='+strategicPlanId));
		TabUIController controller = new TabUIController();
		StrategicPlanControllerExtnTest extension = new StrategicPlanControllerExtnTest(controller);
		StrategicPlan__c s = extension.getStrategicPlan();
		s.Name = 'Test Strategic Plan (edited)';
		PageReference ref = extension.saveStrategicPlan();
		StrategicPlan__c savedPlan = [
			select
				Name,
				CurrencyIsoCode
			from StrategicPlan__c
			where Id = :strategicPlanId
			limit 1 ];
		System.assertEquals('Test Strategic Plan (edited)',savedPlan.Name);
		System.assertEquals('EUR',savedPlan.CurrencyIsoCode);
	}

	@isTest 
	static void newActionTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlanView?id='+strategicPlanId));
		TabUIController controller = new TabUIController();
		StrategicPlanControllerExtnTest extension = new StrategicPlanControllerExtnTest(controller);
		PageReference newAction = extension.newAction();
		System.assertEquals(null,newAction);
		System.assertEquals('StrategicPlan_Action__c',controller.activeTab);
	}

	@IsTest
	static void approvalTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlanView?id='+strategicPlanId));
		TabUIController controller = new TabUIController();
		StrategicPlanControllerExtnTest extension = new StrategicPlanControllerExtnTest(controller);
		//if the strategic approval process is active, this will test that its field update on submit is successful
		//if the process is not active, this test merely ensures sufficient coverage
		System.runAs(testUser) {
			PageReference submit = extension.submitStrategicPlan();
			if(!ApexPages.hasMessages()) {
				StrategicPlan__c testPlan = [select Status__c from StrategicPlan__c where Id = :strategicPlanId limit 1];
				System.assertEquals('Submitted', testPlan.Status__c);
			}
		}
		System.runAs(testManager) {
			extension.reviewHistory.Comments__c = 'Approving request';
			PageReference approve = extension.approveStrategicPlan();
			//approve again to induce error case
			approve = extension.approveStrategicPlan();
		}
		System.runAs(testUser) {
			PageReference submit = extension.submitStrategicPlan();
		}
		System.runAs(testManager) {
			extension.reviewHistory.Comments__c = 'Rejecting request';
			PageReference reject = extension.rejectStrategicPlan();
			//reject again to induce error case
			reject = extension.rejectStrategicPlan();
		}
		//additional coverage of error scenario
		System.runAs(testManager) {
			PageReference submit = extension.submitStrategicPlan();
			System.assert(ApexPages.hasMessages());
		}
	}

	@IsTest 
	static void approvalHistoryTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlanView?id='+strategicPlanId));
		TabUIController controller = new TabUIController();
		StrategicPlanControllerExtnTest extension = new StrategicPlanControllerExtnTest(controller);
		List<StrategicPlan_ReviewHistory__c> reviewHistoryList = extension.getReviewHistoryList();
		// to do: So far this is just coverage test
	}

	@IsTest
	static void approvalProxyTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlanView?id='+strategicPlanId));
		TabUIController controller = new TabUIController();
		StrategicPlanControllerExtnTest extension = new StrategicPlanControllerExtnTest(controller);
		StrategicPlan_Review__c proxy = strategicPlanReview;
		Id proxyId = proxy.Id;
		System.assertEquals(proxyId,extension.getApprovalProxyId());
		extension.test_deleteApprovalProxy();
		proxyId = extension.test_insertApprovalProxy();
		System.assertEquals(proxyId,extension.getApprovalProxyId());
	}

	@IsTest 
	static void getPlanContributorsTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlanView?id='+strategicPlanId));
		TabUIController controller = new TabUIController();
		StrategicPlanControllerExtnTest extension = new StrategicPlanControllerExtnTest(controller);
		TrackingEventLog__c testEventLog = eventLog;
		TrackingEventLog__c testEventLog2 = testEventLog.clone();
		insert testEventLog2;
		List<StrategicPlanControllerExtension.PlanContributor> contributors = extension.getPlanContributors();
		StrategicPlanControllerExtension.PlanContributor contributor = new StrategicPlanControllerExtension.PlanContributor('Name',1);
		Integer c = contributor.CompareTo(contributor);
		System.assertEquals(0,c);
	}

	@IsTest
	static void showSummaryTest() {
		StringSetting__c ss = new StringSetting__c(Name=StrategicPlanControllerExtension.SUMMARY_REPORT_ID_KEY,Value__c=UserInfo.getUserId());
		upsert ss;
		Test.setCurrentPage(new PageReference('/apex/StrategicPlanView?id='+strategicPlanId));
		TabUIController controller = new TabUIController();
		StrategicPlanControllerExtnTest extension = new StrategicPlanControllerExtnTest(controller);
		PageReference showSummary = extension.showSummary();
		System.assertNotEquals(null,showSummary);
		System.assert(extension.getShowSummaryEnabled(),'Expected show summary enabled to be true');
	}

	/*@IsTest
	static void attachmentsTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlanView?id='+strategicPlanId));
		TabUIController controller = new TabUIController();
		StrategicPlanControllerExtnTest extension = new StrategicPlanControllerExtnTest(controller);
		PageReference attachPDF = extension.attachPlanPDF();
		List<Attachment> attachments = extension.getAttachments();
		System.assertEquals(1,attachments.size());
	}*/
}