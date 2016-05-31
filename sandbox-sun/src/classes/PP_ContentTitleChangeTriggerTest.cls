@isTest(SeeAllData=true)
private without sharing class PP_ContentTitleChangeTriggerTest {

    static testMethod void myUnitTest() {
/*
		PP_Content__c[] contents = [select Id, DocumentId__c from PP_Content__c where WorkspaceId__c='058600000008OrRAAU'];
		ContentDocument[] cvlist = [
            select	Id
            from	ContentDocument
            where	Id in :PartnerUtil.getStringFieldSet(contents, 'DocumentId__c')
            and		IsArchived = false
            and		IsDeleted = false
        ];
        if (cvlist.isEmpty()) {
            return;
        }
        PP_Content__c content = null;
        for (PP_Content__c ppc : contents) {
            boolean found = false;
            for (ContentDocument cv : cvlist) {
                if (ppc.DocumentId__c == cv.Id) {
                    found = true;
                    content = ppc;
                    break;
                }
            }
            if (found) break;
        }
        
		ContentVersion cv2 = new ContentVersion();
		cv2.Title = 'hello, world';
		cv2.ContentDocumentId = content.DocumentId__c;
		cv2.VersionData = EncodingUtil.base64Decode('a fake document');
		cv2.ReasonForChange = 'testing';
		cv2.PathOnClient = '/dev/null';
		insert cv2;
		
		content = [select Id, Name from PP_Content__c where Id = :content.Id];
		System.assert(content.Name == 'hello, world', 'Expected content name change');
*/
    }
}