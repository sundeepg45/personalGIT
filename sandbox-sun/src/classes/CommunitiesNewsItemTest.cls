@isTest(SeeAllData=true)
private class CommunitiesNewsItemTest {

	@isTest static void simpleTest() {
        Communities_News_Item__c item = new Communities_News_Item__c();
        item.Status__c = 'Pending';
        item.Audience__c = [select Id from Audience__c limit 1].Id;
        item.English_Label__c = 'test';
        item.Publish_Date__c = System.today();
        item.URL__c = 'http://www.redhat.com';
        insert item;

        Communities_News_Item_Label__c itemlabel = new Communities_News_Item_Label__c();
        itemlabel.Communities_News_Item__c = item.Id;
        itemlabel.Label__c = 'hello, world';
        itemlabel.Language__c = 'English';
        insert itemlabel;

        item.Status__c = 'Published';
        update item;
	}


}