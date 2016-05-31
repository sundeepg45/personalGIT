@isTest(SeeAllData=false)
private class MSContentVersionTriggerTest {

    static testMethod void myUnitTest() {
     	ContentWorkspace ws = [select Id from ContentWorkspace where Name = 'General Workspace'];
		ContentVersion cv = new ContentVersion();
		cv.Title = 'a test document';
		cv.VersionData = EncodingUtil.base64Decode('a fake document');
		cv.PathOnClient = '/dev/null';
		cv.FirstPublishLocationId = ws.id;
		insert cv;

		cv = [select ContentDocumentId from ContentVersion where Id = :cv.Id];

		RH_Content__c rhc = new RH_Content__c();
		rhc.ContentDocumentId__c = ((String) cv.ContentDocumentId); //.substring(0,15);
		rhc.Audience__c = 'Public';
		rhc.IsPublished__c = true;
		insert rhc;

		ContentDocument cd = [select Id from ContentDocument where Id = :cv.ContentDocumentId];		
		
		Boolean detected = false;
		try {
			delete cd;
		}
		catch (System.DmlException ex) {
			// this is what we expected
			detected = true;
		}
		System.assert(detected, 'Document deletion was not blocked');
		
		// now make it unpublished and try again
		rhc.IsPublished__c = false;
		update rhc;
		delete cd;
    }
}