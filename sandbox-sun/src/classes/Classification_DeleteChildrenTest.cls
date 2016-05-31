@isTest
private class Classification_DeleteChildrenTest {

    static testMethod void myUnitTest() {
    	Classification__c c = new Classification__c();
    	c.Name = 'delete test';
    	insert c;
    	Classification__c c2 = new Classification__c();
    	c2.Name = 'delete test child 1';
    	c2.Parent__c = c.Id;
    	insert c2;
    	delete c;
    }
}