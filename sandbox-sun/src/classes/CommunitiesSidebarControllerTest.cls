@isTest(seeAllData=true)
private class CommunitiesSidebarControllerTest {

    @isTest static void testNavigationItems(){

        DeactivateAllTestUtil.setDeactivateAll(false);

        User u = CommunitiesTestUtils.createGenericUser();
        Audience__c aud = CommunitiesTestUtils.createAllPartnerStatusAudience();

        Id contactId = [SELECT Contact.Id FROM User WHERE Id = :u.id].Contact.Id;

        List<Communities_Tool_Shortcut__c> shortcuts = CommunitiesTestUtils.createToolShortcuts();

        List<Contact_Tool_Shortcut__c> contactShortcuts = new List<Contact_Tool_Shortcut__c>();
        Contact_Tool_Shortcut__c cts1 = new Contact_Tool_Shortcut__c();
        cts1.Contact__c = contactId;
        cts1.Communities_Tool_Shortcut__c = shortcuts[0].id;
        contactShortcuts.add(cts1);
        Contact_Tool_Shortcut__c cts2 = new Contact_Tool_Shortcut__c();
        cts2.Contact__c = contactId;
        cts2.Communities_Tool_Shortcut__c = shortcuts[1].id;
        contactShortcuts.add(cts2);

        insert contactShortcuts;

        Communities_Navigation_Item__c cniTop = new Communities_Navigation_Item__c(
            Content_Targeting__c = 'Audience',
            Audience__c = aud.id,
            Sequence__c = 1,
            URL__c = '#',
            Type__c = 'Sidebar Navigation');
        insert cniTop;

        Communities_Navigation_Item__c cniChild = new Communities_Navigation_Item__c(
            Content_Targeting__c = 'Audience',
            Parent_Item__c = cniTop.id,
            Audience__c = aud.id,
            Sequence__c = 1,
            URL__c = '#',
            Type__c = 'Sidebar Navigation');
        insert cniChild;

        Communities_Navigation_Item_Label__c cnilTop = new Communities_Navigation_Item_Label__c(
            Communities_Navigation_Item__c = cniTop.id,
            Label__c = 'testLabel',
            Language__c = 'English');
        insert cnilTop;

        Communities_Navigation_Item_Label__c cnilChild = new Communities_Navigation_Item_Label__c(
            Communities_Navigation_Item__c = cniChild.id,
            Label__c = 'testLabel',
            Language__c = 'English');
        insert cnilChild;
        /*
        PageReference pr = Page.CommunitiesNavigation;
        test.setCurrentPage(pr);
        */
        system.runAs(u){
            CommunitiesSidebar cs  = new CommunitiesSidebar();
        }
    }


}