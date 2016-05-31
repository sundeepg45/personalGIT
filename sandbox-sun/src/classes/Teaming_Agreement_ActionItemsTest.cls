/**
 * Test class for controller class Teaming_Agreement_ActionItems
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2012-05-18
 * 2012-05-18 - created
 * 
 */
@isTest
private class Teaming_Agreement_ActionItemsTest {

    static User user {
        get {
            if(user==null) {
                Profile p = [select id from profile where name='Standard User'];
                user = new User(
                    alias = 'st5911', email='standarduser5911@testorg.com',
                    emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                    localesidkey='en_US', profileid = p.Id,
                    timezonesidkey='America/Los_Angeles', username='standarduser5911@testorg.com');

                System.runAs(new User(Id = UserInfo.getUserId())) {
                    insert user;
                }
            }
            return user;
        }
        set;
    }

    static private Teaming_Agreement__c createTeamingAgreement() {
        User u = user;

    	Account a = new Account(Name = 'Teaming Agreement Test Account');
    	insert a;
    	Teaming_Agreement__c ta = new Teaming_Agreement__c(Partner_Name__c = a.Id, Channel_Account_Manager__c = u.Id);
    	insert ta;

    	return ta;
    }
    
    static private Action_Items__c createActionItem(Id teamingAgreementId) {
    	Action_Items__c ai = new Action_Items__c(Action_Item__c = 'Test test test', Due_Date__c = Date.today(), Teaming_Agreement__c = teamingAgreementId);
    	insert ai;
    	
    	return ai;
    }
    
    static testMethod void currentUserTest() {
    	Teaming_Agreement_ActionItems c = new Teaming_Agreement_ActionItems(null);
		System.assertEquals(UserInfo.getUserId(),c.currentUser.Id);
		System.assertNotEquals(null,c.currentUser.Profile.Name);
	}
	
	static testMethod void showEditButtonTest() {
		Teaming_Agreement_ActionItems c = new Teaming_Agreement_ActionItems(null);
		String profile = c.currentUser.Profile.Name;
		Boolean expectedValue = (profile == 'Administrator - Level 1' || profile == 'Administrator - Level 2' || profile == 'Order Entry/Billing User');
		System.assertEquals(expectedValue,c.showEditButton);
	}
	
	static testMethod void AddActionItemTest() {
        PageReference pageRef = Page.TeamingAgreementPageLayout;
        Test.setCurrentPage(pageRef);
        Teaming_Agreement__c agreement = createTeamingAgreement();
        ApexPages.currentPage().getParameters().put('id', agreement.Id);
        Teaming_Agreement_ActionItems c = new Teaming_Agreement_ActionItems(null);
        c.newteamingAgreementAction.Action_Item__c = 'Test test test';
        c.newteamingAgreementAction.Due_Date__c = Date.today();
        PageReference nextPage = c.AddActionItem();
        System.assertEquals(Page.TeamingAgreementPageLayout.getUrl(), nextPage.getUrl());
    }
    
    static testMethod void MarkCompleteTest() {
    	PageReference pageRef = Page.TeamingAgreementPageLayout;
        Test.setCurrentPage(pageRef);
        Teaming_Agreement__c agreement = createTeamingAgreement();
        ApexPages.currentPage().getParameters().put('id', agreement.Id);
        Action_Items__c item = createActionItem(agreement.Id);
        ApexPages.currentPage().getParameters().put('actionid', item.Id);
        ApexPages.currentPage().getParameters().put('actionitem', item.Id);
        Teaming_Agreement_ActionItems c = new Teaming_Agreement_ActionItems(null);
        PageReference nextPage = c.MarkComplete();
        System.assertEquals(Page.TeamingAgreementPageLayout.getUrl(), nextPage.getUrl());
    }
    
    static testMethod void DeleteActionItemTest() {
    	PageReference pageRef = Page.TeamingAgreementPageLayout;
        Test.setCurrentPage(pageRef);
        Teaming_Agreement__c agreement = createTeamingAgreement();
        ApexPages.currentPage().getParameters().put('id', agreement.Id);
        Action_Items__c item = createActionItem(agreement.Id);
        ApexPages.currentPage().getParameters().put('actionid', item.Id);
        ApexPages.currentPage().getParameters().put('actionitem', item.Id);
        Teaming_Agreement_ActionItems c = new Teaming_Agreement_ActionItems(null);
        PageReference nextPage = c.DeleteActionItem();
        System.assertEquals(Page.TeamingAgreementPageLayout.getUrl(), nextPage.getUrl());
    }

    static testMethod void EditActionItemTest() {
    	PageReference pageRef = Page.TeamingAgreementPageLayout;
        Test.setCurrentPage(pageRef);
        Teaming_Agreement__c agreement = createTeamingAgreement();
        ApexPages.currentPage().getParameters().put('id', agreement.Id);
        Action_Items__c item = createActionItem(agreement.Id);
        ApexPages.currentPage().getParameters().put('actionid', item.Id);
        ApexPages.currentPage().getParameters().put('actionitem', item.Id);
        Teaming_Agreement_ActionItems c = new Teaming_Agreement_ActionItems(null);
        PageReference nextPage = c.EditActionItem();
        PageReference expectedPage = new PageReference('/apex/TeamingAgreementEditActionitem?id='+item.id);
        System.assertEquals(expectedPage.getUrl(),nextPage.getUrl());
    }
    
 	static testMethod void submitforApprovalTest() {
    	PageReference pageRef = Page.TeamingAgreementPageLayout;
        Test.setCurrentPage(pageRef);
        Teaming_Agreement__c agreement = createTeamingAgreement();
        ApexPages.currentPage().getParameters().put('id', agreement.Id);
        Action_Items__c item = createActionItem(agreement.Id);
        Teaming_Agreement_ActionItems c = new Teaming_Agreement_ActionItems(null);
        PageReference nextPage = c.submitforApproval();
        System.assertEquals(Page.TeamingAgreementPageLayout.getUrl(), nextPage.getUrl());
    }    
    
}