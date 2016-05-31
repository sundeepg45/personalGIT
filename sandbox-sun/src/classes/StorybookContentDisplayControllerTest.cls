@isTest(seeAllData=true)
public with sharing class StorybookContentDisplayControllerTest {

    static testMethod void myUnitTest() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        User u = CommunitiesTestUtils.createGenericUser();
        Audience__c aud = CommunitiesTestUtils.createAllPartnerStatusAudience();

        Id contactId = [SELECT Contact.Id FROM User WHERE Id = :u.id].Contact.Id;

        StoryBook__c sb = new StoryBook__c(Name='test', Audience__c = aud.id);
        insert sb;
        StoryBookLink__c sbl = new StoryBookLink__c(StoryBook__c = sb.Id, Name='testlink', Audience__c = aud.id, URL__c = 'http://www.www.com/');
        insert sbl;
        StoryBookLinkLabel__c sbll = new StoryBookLinkLabel__c(StoryBookLink__c = sbl.Id, Label__c='Label Text');
        insert sbll;

        system.runAs(u){
            System.currentPageReference().getParameters().put('sbId', sb.Id);
            StorybookContentDisplayController controller = new StorybookContentDisplayController();
            System.currentPageReference().getParameters().put('embedded', 'true');
            controller = new StorybookContentDisplayController();
            System.currentPageReference().getParameters().put('hideTitle', 'true');
            controller = new StorybookContentDisplayController();
        }
    }

}