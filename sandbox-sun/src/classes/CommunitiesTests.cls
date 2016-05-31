@isTest(seeAllData=true)
private class CommunitiesTests {

	@isTest static void testNewsItems() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        User u = CommunitiesTestUtils.createGenericUser();
        Audience__c aud = CommunitiesTestUtils.createAllPartnerStatusAudience();

        Communities_News_Item__c cni = new Communities_News_Item__c(
            Sorting_Weight__c = 1,
            Audience__c = aud.id,
            Status__c = 'Draft');
        insert cni;

        Communities_News_Item_Label__c cnil = new Communities_News_Item_Label__c(
            Communities_News_Item__c = cni.id,
            Language__c = 'English',
            Label__c = 'testLabel');
        insert cnil;

        cni.Status__c = 'Published';
        update cni;

        Communities_News_Item__c updatedCni = [SELECT Publish_Date__c FROM Communities_News_Item__c WHERE id = :cni.id];

        system.assertNotEquals(updatedCni.Publish_Date__c,null);

        PageReference pr = Page.CommunitiesNewsDisplay;
        test.setCurrentPage(pr);

        system.runAs(u){
            CommunitiesNewsDisplayController cndc = new CommunitiesNewsDisplayController();
        }
	}

    @isTest static void testNavigation(){
        DeactivateAllTestUtil.setDeactivateAll(false);

        system.debug('***starting nav');
        User u = CommunitiesTestUtils.createGenericUser();
        Audience__c aud = CommunitiesTestUtils.createAllPartnerStatusAudience();

        Communities_Navigation_Item__c cniTop = new Communities_Navigation_Item__c(
            Content_Targeting__c = 'Audience',
            Audience__c = aud.id,
            Sequence__c = 1,
            URL__c = '#');
        insert cniTop;

        Communities_Navigation_Item__c cniChild = new Communities_Navigation_Item__c(
            Content_Targeting__c = 'Audience',
            Parent_Item__c = cniTop.id,
            Audience__c = aud.id,
            Sequence__c = 1,
            URL__c = '#');
        insert cniChild;

        Communities_Navigation_Item__c cniGrandchild = new Communities_Navigation_Item__c(
            Content_Targeting__c = 'Audience',
            Parent_Item__c = cniChild.id,
            Audience__c = aud.id,
            Sequence__c = 1,
            URL__c = '#');
        insert cniGrandchild;

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

        Communities_Navigation_Item_Label__c cnilGrandchild = new Communities_Navigation_Item_Label__c(
            Communities_Navigation_Item__c = cniGrandchild.id,
            Label__c = 'testLabel',
            Language__c = 'English');
        insert cnilGrandchild;

        /*
        PageReference pr = Page.CommunitiesNavigation;
        test.setCurrentPage(pr);
        */
        system.runAs(u){
            CommunitiesNavigationController cnc = new CommunitiesNavigationController();
            // this was throwing a mixed DML error
            //CommunitiesNavigationController.updateUserLanguage(u.id, 'English');
            CommunitiesNavigationController.executeSearch('Account', 'testString');
        }
    }
    @isTest static void testStorybooks(){
        DeactivateAllTestUtil.setDeactivateAll(false);

        User u = CommunitiesTestUtils.createGenericUser();
        Audience__c aud = CommunitiesTestUtils.createAllPartnerStatusAudience();

        Storybook__c sb = new Storybook__c(
            Name='testStorybook',
            Audience__c = aud.id,
            Status__c= 'Published'
            );
        insert sb;

        Storybook__c updatedSb = [SELECT Publish_Date__c FROM Storybook__c WHERE id = :sb.id];

        system.assertNotEquals(updatedSb.Publish_Date__c,null);

        PageReference pr = Page.CommunitiesStorybookDisplay;
        test.setCurrentPage(pr);

        system.runAs(u){
            CommunitiesStorybookDisplayController csdc = new CommunitiesStorybookDisplayController();
        }

        pr = Page.StorybookContentDisplay;

        test.setCurrentPage(pr);
        pr.getParameters().put('sbId',sb.id);

        system.runAs(u){
            StorybookContentDisplayController cscdc = new StorybookContentDisplayController();
        }
    }
    @isTest static void testFeaturedHeadlines(){
        DeactivateAllTestUtil.setDeactivateAll(false);

        User u = CommunitiesTestUtils.createGenericUser();
        Audience__c aud = CommunitiesTestUtils.createAllPartnerStatusAudience();

        Communities_Featured_Headline__c cfh = new Communities_Featured_Headline__c(
            Audience__c=aud.id
            ,Status__c='Published'
        );

        insert cfh;

        PageReference pr = Page.CommunitiesFeaturedHeadlines;
        test.setCurrentPage(pr);
        system.runAs(u){
            CommunitiesFeaturedHeadlinesController cf = new CommunitiesFeaturedHeadlinesController();
        }
    }

}