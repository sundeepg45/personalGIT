@isTest
private class NavigationInputControllerTest {

	@isTest static void test_method_one() {

        PageReference pr = Page.NavigationInput;
        test.setCurrentPage(pr);

        Communities_Navigation_Item__c cni = new Communities_Navigation_Item__c();
        ApexPages.StandardController sc = new ApexPages.StandardController(cni);

        Audience__c aud = CommunitiesTestUtils.createAllPartnerStatusAudience();

        NavigationInputController nic = new NavigationInputController(sc);

        nic.navItem.Content_Targeting__c = 'Tab/Object Permissions';
        nic.selectedTab = nic.tabSelectOptions[1].getValue();
        nic.save();

        cni = [SELECT Id FROM Communities_Navigation_Item__c WHERE Id = :nic.NavItem.id];

        sc = new ApexPages.StandardController(cni);
        nic = new NavigationInputController(sc);

        nic.navItem.Content_Targeting__c = 'Audience';
        nic.clearTargetSelections();
        nic.navItem.Audience__c = aud.id;
        nic.dummyAction();
        nic.save();
	}
}