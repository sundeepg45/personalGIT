/**
 * This test class tests the AccountProfile_ManageSWOT class.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-11-09
 * 2012-11-09 - created
 */
@isTest
private class AccountProfile_ManageSWOTTest {

	static AccountProfile_ManageSWOT createController(Id profileId) {
		ApexPages.StandardController sc = new ApexPages.StandardController(new Account_Profile__c(Id=profileId));
		return new AccountProfile_ManageSWOT(sc);
	}

	static AccountProfile_ManageSWOT controller {
		get {
			if(controller == null) {
				controller = createController(
					AccountProfileSWOTControllerTest.accountProfileId);
			}
			return controller;
		}
	}

	static List<Account_Profile_SWOT__c> swots {
		get {
			if(swots ==null) {
				swots = AccountProfileSWOTControllerTest.createSWOTs(
					AccountProfileSWOTControllerTest.accountProfileId);
				insert swots;
			}
			return swots;
		}
	}

	@isTest
	static void swotEditorsTest() {
		Map<Id,Account_Profile_SWOT__c> swotMap = new Map<Id,Account_Profile_SWOT__c>(swots);
		Integer i=swots.size();
		Integer j=i;
		for(AccountProfile_ManageSWOT.SWOT_Editor editor : controller.swotEditors) {
			j--;
			if(editor.getSWOT().Id != null) {
				i--;
				System.assert(swotMap.containsKey(editor.getSWOT().Id),'Unexpected SWOT Analysis object: '+editor.getSWOT());
			}
			System.assertEquals(false,editor.IsDeleted);
			System.assertEquals(false,editor.IsChanged);
			editor.getSWOT().Statement__c+=' Anything';
			System.assertEquals(true,editor.IsChanged);
			editor.IsDeleted=true;
			System.assertEquals(true,editor.IsDeleted);
		}
		System.assertEquals(0,i);
		System.assert(j < 0,'Expected at least 1 new editor object');
	}

	@isTest
	static void buttonTest() {
		Map<Id,Account_Profile_SWOT__c> swotMap = new Map<Id,Account_Profile_SWOT__c>(swots);
		Integer i=swotMap.size();
		Integer j=0;
		for(AccountProfile_ManageSWOT.SWOT_Editor editor : controller.swotEditors) {
			if(editor.getSWOT().Id != null) {
				editor.getSWOT().Statement__c = editor.getSWOT().Type__c;
			}
			else {
				editor.getSWOT().Statement__c = 'Statement '+(++i);
			}
			j++;
		}
		System.assertEquals(null,controller.save());
		for(AccountProfile_ManageSWOT.SWOT_Editor editor : controller.swotEditors) {
			if(editor.getSWOT().Type__c == null) {
				editor.getSWOT().Type__c = AccountProfileSWOTController.WEAKNESS;
			}
		}
		PageReference result = controller.save();
		System.assertEquals('/'+AccountProfileSWOTControllerTest.accountProfileId,result.getUrl());
		List<Account_Profile_SWOT__c> updatedSWOTs = controller.getAccountProfileSWOTs();
		System.assertEquals(j,updatedSWOTs.size());
		for(Account_Profile_SWOT__c swot : updatedSWOTs) {
			if(swotMap.containsKey(swot.Id)) {
				System.assertEquals(swot.Type__c,swot.Statement__c);
			}
			else {
				System.assertNotEquals(swot.Type__c,swot.Statement__c);
			}
		}
		for(AccountProfile_ManageSWOT.SWOT_Editor editor : controller.swotEditors) {
			editor.IsDeleted = true;
		}
		result = controller.save();
		System.assertEquals('/'+AccountProfileSWOTControllerTest.accountProfileId,result.getUrl());
		System.assertEquals(0,controller.getAccountProfileSWOTs().size());
		System.assertEquals(null,controller.saveAndContinue());
		System.assertEquals(null,controller.reset());
		System.assertEquals('/'+AccountProfileSWOTControllerTest.accountProfileId,controller.cancel().getUrl());
	}
}