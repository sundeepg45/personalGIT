/**
 * This class contains unit tests for validating the behavior of 
 * CaseTriggerBefore.cls
 *
 * @version 2014-05-29
 * 
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-05-29 - added tests for assignContact() and setRegion()
 * 2012-06-01 - Created
 * 2012-11-20 - Updated for protectFields()
 * Bill Riemers
 * 2013-05-29 - Updated for new protectedFields logic
 */
@isTest
private class CaseTriggerBeforeTest {

	static final String LEGACY_PROFILE = 'Global Level 3';
	static final String LEGACY_ROLE = 'Global Administration';

	static Util__c util {
		get {
			if(util == null) {
				util = new Util__c(
					Name = 'RedhatIntAccountName',
					Variable_Name__c = 'RedhatIntAccountName',
					Variable_Value__c = 'Red Hat (Internal Use Only)');
				insert util;
			}
			return util;
		}
		set;
	}

	static Account account {
		get {
			if(account == null) {
				account = new Account(
					Name = util.Variable_Value__c);
				insert account;
			}
			return account;
		}
		set;
	}

	static Contact contact {
		get {
			if(contact == null) {
				contact = new Contact(
					Email = UserInfo.getUserEmail(),
					FirstName = UserInfo.getFirstName(),
					LastName = UserInfo.getLastName(),
					AccountId = account.Id);
				insert contact;
			}
			return contact;
		}
		set;
	}

	static User user {
		get {
			if(user == null) {
				user = new User(
					Id=UserInfo.getUserId(),
					Legacy_Profile__c=LEGACY_PROFILE,
					Legacy_Role__c=LEGACY_ROLE);
				update user;
			}
			return user;
		}
		set;
	}

	static Group group1 {
		get {
			if (group1 == null) {
				group1 = new Group(
					Name = 'Test Queue',
					Type = 'Queue');
				insert group1;
			}
			return group1;
		}
		set;
	}

	static List<GroupMember> groupMembers {
		get {
			if(groupMembers == null) {
				groupMembers = new List<GroupMember>();
				for(User u2 : [
					select Id 
					from User 
					where IsActive = true 
						and Profile.Name like 'Admin%' 
						and Id != :user.Id limit 2 ])
				{
					groupMembers.add(new GroupMember(UserOrGroupId=u2.Id,GroupId=group1.Id));
				}
			}
			return groupMembers;
		}
	}
	
	static Case case1 {
		get {
			if (case1 == null) {
				case1 = new Case(
					OwnerId = user.Id,
					Owner__c = null,
					Case_Notes__c = 'notes',
					Case_Resolution__c = 'resolution',
					Status = 'New',
					ContactId = null,
					NA_Business_Unit__c = null,
					Region__c = null);
			}
			return case1;
		}
		set;
	}

	@isTest
	static void assignContactTest() {
		User currentUser = [ SELECT Id, Contact_Id__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1 ];
		currentUser.Contact_Id__c = contact.Id;
		AbstractTrigger.setBooleanSettings('User_After.',false);
		System.runAs(new User(Id = UserInfo.getUserId())) {
			update currentUser;
		}
		CaseTriggerBefore ctb = new CaseTriggerBefore(null, new List<Case>{case1});
		ctb.assignContact();
		System.assertEquals(contact.Id, case1.ContactId);
	}

	@isTest 
		static void setRegionTest() {
		CaseRecordType__c crt = new CaseRecordType__c(Name = 'Test', RecordTypeId__c = case1.RecordTypeId);
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert crt;
		}
		User currentUser = [ SELECT Id, Contact_Id__c, Region__c, Business_Unit__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1 ];
		currentUser.Contact_Id__c = contact.Id;
		currentUser.Region__c = 'Test Region';
		currentUser.Business_Unit__c = 'Test BU';
		AbstractTrigger.setBooleanSettings('User_After.',false);
		System.runAs(new User(Id = UserInfo.getUserId())) {
			update currentUser;
		}
		CaseTriggerBefore ctb = new CaseTriggerBefore(null, new List<Case>{case1});
		ctb.assignContact();
		System.assertEquals(contact.Id, case1.ContactId);
		ctb.setRegion();
		System.assertEquals('Test BU', case1.NA_Business_Unit__c);
		System.assertEquals('Test Region', case1.Region__c);
	}

	@isTest
	static void protectFieldsTest() {
		Case c1 = case1;
		Case c2 = c1.clone();
		c2.Case_Notes__c = 'updated notes';
		c2.Case_Resolution__c = 'updated resolution';
		c2.Status = 'Pending Close';
		CaseTriggerBefore ctb = new CaseTriggerBefore(new Map<Id,Case>{null => c1}, new List<Case>{c2});
		ctb.protectFields();
		System.assert(!ctb.hasErrors);
		c1.OwnerId = group1.Id;
		c2.OwnerId = group1.Id;
		ctb = new CaseTriggerBefore(new Map<Id,Case>{null => c1}, new List<Case>{c2});
		ctb.protectFields();
		// we succeed because there are no group members
		System.assert(!ctb.hasErrors);
		insert groupMembers;
		ctb = new CaseTriggerBefore(new Map<Id,Case>{null => c1}, new List<Case>{c2});
		ctb.protectFields();
		// we fail because the current user is not a member of the group
		System.assert(ctb.hasErrors);
		c2 = c2.clone(); // clear the field errors
		GroupMember gm = new GroupMember(UserOrGroupId=user.Id,GroupId=group1.Id);
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert gm;
		}
		ctb = new CaseTriggerBefore(new Map<Id,Case>{null => c1}, new List<Case>{c2});
		ctb.protectFields();
		// we succeed because the current user is a member of he group
		System.assert(!ctb.hasErrors);
		System.runAs(new User(Id = UserInfo.getUserId())) {
			delete gm;
		}
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert new GroupSetting__c(Name=(String)group1.Id,GroupName__c=group1.Name,ProtectedCaseFields__c=false);
		}
		ctb = new CaseTriggerBefore(new Map<Id,Case>{null => c1}, new List<Case>{c2});
		ctb.protectFields();
		// we succeed this group by-passes the protected fields
		System.assert(!ctb.hasErrors);
		c1.OwnerId = c2.OwnerId = groupMembers[0].UserOrGroupId;
		ctb = new CaseTriggerBefore(new Map<Id,Case>{null => c1}, new List<Case>{c2});
		ctb.protectFields();
		// we fail because we are not the case owner
		System.assert(ctb.hasErrors);
		c2 = c2.clone(); // clear the field errors
		AdminByPass__c abp = AdminByPass__c.getInstance();
		abp.IsCaseAdmin__c = true;
		System.runAs(new User(Id = UserInfo.getUserId())) {
			upsert abp;
		}
		ctb = new CaseTriggerBefore(new Map<Id,Case>{null => c1}, new List<Case>{c2});
		ctb.protectFields();
		// we succeed because of the admin by pass
		System.assert(!ctb.hasErrors);
	}

	@isTest
	static void assignLegacyUserTest() {
		CaseTriggerBefore ctb = new CaseTriggerBefore(null, new List<Case>{case1});
		ctb.assignLegacy();
		System.assertEquals(user.Id,case1.OwnerId);
		System.assertEquals(user.Id,case1.Owner__c);
	}

	@isTest
	static void assignLegacyQueueTest() {
		Case c = case1;
		c.OwnerId = group1.Id;
		CaseTriggerBefore ctb = new CaseTriggerBefore(null, new List<Case>{c});
		ctb.assignLegacy();
		System.assertEquals(group1.Id,c.OwnerId);
		System.assertEquals(group1.Name,c.Queue_Name__c);
	}

	@isTest // (SeeAllData=true) is not needed anymore because we insert missing settings
	static void processTriggerTest() {
		AbstractTrigger.setBooleanSettings('Case_Before.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		List<Case> cases = new List<Case>{case1};
		Map<Id,Case> oldMap = new Map<Id,Case>{ case1.Id => case1 };
		List<Case> newList = cases.deepClone(true);
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Case_Before.',true);
		// insert
		AbstractTrigger.insertMissing = 0;
		CaseTriggerBefore.processTrigger(null,newList);
		// update
		newList = cases.deepClone(true);
		CaseTriggerBefore.processTrigger(oldMap,newList);
//		// delete
//		CaseTriggerBefore.processTrigger(oldMap,null);
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('Case_Before.');
	}

	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('Case_Before.',new List<Case>{case1});
	}

}