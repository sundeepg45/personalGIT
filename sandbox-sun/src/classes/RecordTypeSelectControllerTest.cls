/**
 * Test class for RecordTypeSelectController
 *
 * @version 2014-05-02
 * 
 * @author Scott Coleman <scoleman@redhat.com>
 * 2012-12-17 - Updated getterTests
 * 2012-05-29 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2014-05-02 - test for SFANewValue__c assignment
 * 2013-06-17 - Support POC redirect
 */
@isTest
private class RecordTypeSelectControllerTest {
	static final String TEST_JOB_FUNCTION = 'Test Job Function';
	static final String TEST_RECORD_TYPE_ID = '012000000000000';
	static final String EXPECTED_SELECT_RECORD_TYPE_URL = '/006/e?ent=Opportunity&nooverride=1&RecordType='+TEST_RECORD_TYPE_ID+'&retURL='+EncodingUtil.urlEncode('/006/o','UTF-8');
	static final String EXPECTED_CANCEL_URL = '/006/o';
	static final String EXPECTED_REDIRECT_URL = '/setup/ui/recordtypeselect.jsp?ent=Opportunity&nooverride=1&retURL='+EncodingUtil.urlEncode('/006/o','UTF-8')+'&save_new_url='+EncodingUtil.urlEncode('/006/e?retURL='+EncodingUtil.urlEncode('/006/o','UTF-8'),'UTF-8');

	static private List<RecordTypeAssignment__c> rtaList {
		get {
			if(rtaList == null) {
				rtaList = new List<RecordTypeAssignment__c>{
				// EMEA Sales Opportunity - Role Contains Any
				new RecordTypeAssignment__c(
					ManagedProfiles__c = RecordTypeSelectController.currentUser.Profile.Name,
					Object_Label__c = 'Opportunity',
					RecordType__c = 'EMEA Sales Opportunity',
					Super_Region__c = 'EMEA',
					Role_Contains_Any__c = 'A;C'),
				// NA Sales Opportunity - Job Function
				new RecordTypeAssignment__c(
					ManagedProfiles__c = RecordTypeSelectController.currentUser.Profile.Name,
					Object_Label__c = 'Opportunity',
					RecordType__c = 'NA Sales Opportunity',
					Super_Region__c = 'EMEA',
					Job_Functions__c = TEST_JOB_FUNCTION),
				// APAC Sales Opportunity - Role Contains All
				new RecordTypeAssignment__c(
					ManagedProfiles__c = RecordTypeSelectController.currentUser.Profile.Name,
					Object_Label__c = 'Opportunity',
					RecordType__c = 'APAC Sales Opportunity',
					Super_Region__c = 'EMEA',
					Role_Contains_All__c = 'A;B;C'),
				// LATAM Sales Opportunity - Role Excludes Any
				new RecordTypeAssignment__c(
					ManagedProfiles__c = RecordTypeSelectController.currentUser.Profile.Name,
					Object_Label__c = 'Opportunity',
					RecordType__c = 'LATAM Sales Opportunity',
					Super_Region__c = 'EMEA',
					Role_Excludes_Any__c = '1;2;3'),
				// Renewal - Role Excludes All
				new RecordTypeAssignment__c(
					ManagedProfiles__c = RecordTypeSelectController.currentUser.Profile.Name,
					Object_Label__c = 'Opportunity',
					RecordType__c = 'Renewal',
					Super_Region__c = 'EMEA;NA',
					Role_Excludes_All__c = 'A;B;3'),
				// EMEA OEM Sales - Role Includes Any - negative scenario
				new RecordTypeAssignment__c(
					ManagedProfiles__c = RecordTypeSelectController.currentUser.Profile.Name,
					Object_Label__c = 'Opportunity',
					RecordType__c = 'EMEA OEM Sales',
					Super_Region__c = 'GLOBAL;EMEA',
					Role_Contains_Any__c = 'A;1;2;3'),
				// EMEA Sales Opportunity - Role Contains Any
				new RecordTypeAssignment__c(
					ManagedProfiles__c = RecordTypeSelectController.currentUser.Profile.Name,
					Object_Label__c = 'Opportunity',
					RecordType__c = 'xEMEA Sales Opportunity',
					Super_Region__c = 'EMEA',
					Role_Contains_Any__c = '1;2'),
				// NA Sales Opportunity - Job Function
				new RecordTypeAssignment__c(
					ManagedProfiles__c = RecordTypeSelectController.currentUser.Profile.Name,
					Object_Label__c = 'Opportunity',
					RecordType__c = 'xNA Sales Opportunity',
					Super_Region__c = 'EMEA',
					Job_Functions__c = 'x'+TEST_JOB_FUNCTION),
				// APAC Sales Opportunity - Role Contains All
				new RecordTypeAssignment__c(
					ManagedProfiles__c = RecordTypeSelectController.currentUser.Profile.Name,
					Object_Label__c = 'Opportunity',
					RecordType__c = 'xAPAC Sales Opportunity',
					Super_Region__c = 'EMEA',
					Role_Contains_All__c = 'A;B;C;3'),
				// LATAM Sales Opportunity - Role Excludes Any
				new RecordTypeAssignment__c(
					ManagedProfiles__c = RecordTypeSelectController.currentUser.Profile.Name,
					Object_Label__c = 'Opportunity',
					RecordType__c = 'xLATAM Sales Opportunity',
					Super_Region__c = 'EMEA',
					Role_Excludes_Any__c = '1;2;3;A'),
				// Renewal - Role Excludes All
				new RecordTypeAssignment__c(
					ManagedProfiles__c = RecordTypeSelectController.currentUser.Profile.Name,
					Object_Label__c = 'Opportunity',
					RecordType__c = 'xRenewal',
					Super_Region__c = 'EMEA;NA',
					Role_Excludes_All__c = 'A;B'),
				// EMEA OEM Sales - Role Includes Any - negative scenario
				new RecordTypeAssignment__c(
					ManagedProfiles__c = RecordTypeSelectController.currentUser.Profile.Name,
					Object_Label__c = 'Opportunity',
					RecordType__c = 'xEMEA OEM Sales',
					Super_Region__c = 'GLOBAL;EMEA',
					Role_Contains_Any__c = '1;2;3') };
				insert rtaList;
			}
			return rtaList;
		}
		set;
	}

	static private RecordTypeSelectController getController() {
		PageReference pageRef = Page.RecordTypeSelect;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('ent','Opportunity');
		RecordTypeSelectController controller = new RecordTypeSelectController();
		return controller;
	}

	@IsTest
	static void getterTests() {
		RecordTypeSelectController c = getController();
		c.entityKey = null;
		c.objectApiName = null;
		c.keyPrefix = null;
		c.objectLabel = null;
		c.recordName = null;
		c.recordId = null;
		c.returnURL = null;
		c.saveURL = null;
		c.recordTypes = null;
		System.assertEquals('Opportunity',c.entityKey);
		System.assertEquals('Opportunity',c.objectApiName);
		System.assertEquals('006',c.keyPrefix);
		System.assertEquals('Opportunity',c.objectLabel);
		System.assertEquals(null,c.recordName);
		System.assertEquals(null,c.recordId);
		System.assertEquals('/006/o',c.returnURL);
		System.assertEquals('/006/e?retURL=%2F006%2Fo',c.saveURL);
		System.assertEquals(null,c.currentRecordType);
		System.assertEquals(UserInfo.getUserId(),RecordTypeSelectController.currentUser.Id);
		System.assertEquals(false,c.isManagedProfile);
		System.assertEquals(0,c.recordTypes.size());
		System.assertEquals(null,c.recordName);		
		c = getController();
		ApexPages.currentPage().getParameters().remove('ent');
		c.entityKey = 'default';
		c.objectApiName = 'default';
		c.keyPrefix = null;
		c.recordId = UserInfo.getUserRoleId();
		System.assertEquals('UserRole',c.entityKey);
		System.assertEquals('UserRole',c.objectApiName);
		System.assertEquals('00E',c.keyPrefix);
		System.assertEquals('Role',c.objectLabel);
		c = getController();
		Lead ld = LeadTriggerAfterTest.createLead();
		insert ld;
		ApexPages.currentPage().getParameters().remove('ent');
		ApexPages.currentPage().getParameters().put('id',ld.id);
		System.assertEquals('Lead',c.entityKey);
		System.assertEquals('Lead',c.objectApiName);
		System.assertEquals('00Q',c.keyPrefix);
		System.assertEquals('Lead',c.objectLabel);
		ld = [select Name, RecordTypeId from Lead where Id = :ld.Id];
		System.assertEquals(ld.Name,c.recordName);
		System.assertEquals(ld.RecordTypeId,c.currentRecordType.Id);
		System.assertEquals('/setup/ui/recordtypeselect.jsp?id='+(''+ld.Id).substring(0,15)+'&retURL=%2F00Q%2Fo',c.redirectURL);
		c.recordId = '';
		c.redirectURL = null;
		System.assertEquals('/00Q/e?retURL=%2F00Q%2Fo&nooverride=1',c.redirectURL);
		c.isClone = null;
		c.isCloneWithoutRecordType = null;
		ApexPages.currentPage().getParameters().put('clone','1');
		System.assert(c.isClone);
		System.assert(!c.isCloneWithoutRecordType);
		c.isCloneWithoutRecordType = null;
		ApexPages.currentPage().getParameters().put('clonewort','1');
		System.assert(c.isCloneWithoutRecordType);
	}

	@IsTest
	static void getRecordTypeOptionsTest() {
		// first confirm matching
		RecordTypeSelectController.currentUser.Job_Function__c = TEST_JOB_FUNCTION;
		RecordTypeSelectController.currentUser.Region__c = 'EMEA';
		RecordTypeSelectController.currentUser.UserRole.Name = 'EMEA | A | B | C';
		System.assertNotEquals(0,rtaList.size());
		RecordTypeSelectController c = getController();
		List<SelectOption> options = c.getRecordTypeOptions();
		
		System.assertEquals(7,options.size());
		
		Set<String> optionLabels = new Set<String>();
		for (SelectOption so : options) {
			optionLabels.add(so.getLabel());
		}
		
		System.assert(optionLabels.contains('--None--'));
		for(RecordTypeAssignment__c rta : rtaList) {
			System.assertNotEquals(''+rta.RecordType__c.startsWith('x'),''+optionLabels.contains(rta.RecordType__c),rta);
		}

		// now try where the region does not match
		RecordTypeSelectController.currentUser.Region__c = 'APAC';
		c = getController();
		System.assertEquals(1,c.getRecordTypeOptions().size());
	}

	@IsTest
	static void redirectTest() {
		RecordTypeSelectController c = getController();
		PageReference pageRef = c.redirect();
		
		System.assertEquals(EXPECTED_REDIRECT_URL,pageRef.getUrl());
	}

	@IsTest
	static void selectRecordTypeTest() {
		RecordTypeSelectController c = getController();
		c.recordTypeId = TEST_RECORD_TYPE_ID;
		PageReference pageRef = c.selectRecordType();
		
		System.assertEquals(EXPECTED_SELECT_RECORD_TYPE_URL,pageRef.getUrl());
	}

	@IsTest
	static void cancelTest() {
		RecordTypeSelectController c = getController();
		PageReference pageRef = c.cancel();
		
		System.assertEquals(EXPECTED_CANCEL_URL,pageRef.getUrl());
	}

	@IsTest
	static void appendParamsTest() {
		RecordTypeSelectController c = getController();
		c.isClone = true;
		insert new List<FieldId__c> {
			new FieldId__c(Name='00N123467890abc',Object__c='Opportunity',FieldName__c='IceCream__c',SFACloneable__c=false,SFACloneValue__c='cookies'),
			new FieldId__c(Name='00N123467891abd',Object__c='Opportunity',FieldName__c='Topping__c',SFACloneable__c=true,SFACloneValue__c='cream'),
			new FieldId__c(Name='opp3',Object__c='Opportunity',FieldName__c='Opportunity.Name',SFACloneable__c=true,SFANewValue__c='TestName') };
		String inputURL='/006012346789/e?retURL=x';
		String inputURL2='/006/e?retURL=x';
		Test.startTest();
		String outputURL = c.appendParams(inputURL);
		c.isClone = false;
		String outputURL2 = c.appendParams(inputURL2);
		Test.stopTest();
		System.assert(outputURL.contains('cookies'),'Expected cookies');
		System.assert(! outputURL.contains('cream'),'Did not expect cookies & cream');
		System.assert(! outputURL.contains('TestName'),'Did not expect TestName');
		System.assert(! outputURL2.contains('cookies'),'Did not expect cookies');
		System.assert(! outputURL2.contains('cream'),'Did not expect cream');
		System.assert(outputURL2.contains('TestName'),'Expected TestName');
	}
}