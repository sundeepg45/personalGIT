@isTest
private class PP_Batch_Delete_Validation_Test {

    static testMethod void myUnitTest() {
        update new User(Id = UserInfo.getUserId(), Global_Partner_Points_Admin__c = True, Region__c = 'NA');

    	PP_Catalog__c cat = new PP_Catalog__c();
    	cat.Category__c = 'Bulk Uploads';
    	cat.Global_Region__c = 'NA';
    	insert cat;

        PP_Batch__c b = new PP_Batch__c();
		b.Catalog__c = cat.Id;
    	b.Sub_Category__c = 'Red Hat Summit';
		b.Description__c = 'once upon a time';
		b.Full_Points__c = 100.0;
		b.Max_Units__c = 1;
		b.Partial_Points__c = 0.0;
		b.Region__c = 'NA';
		b.Name = 'snow white';
		insert b;

		delete b;
    }
}