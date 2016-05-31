trigger PP_DocumentTitleChange on ContentDocument (after update) {

//
// This has to be disabled because of the lame salesforce cms architecture.
// When the contentViewCountUpdate scheduled job runs it batch updates many rows,
// but they are fed into this trigger by the cms one at a time which blows up
// the soql limits.
//
/*
	Set<String> docIdList = PartnerUtil.getIdSet(Trigger.new);
	String[] idlist = new List<String>();
	for (String s : docIdList) {
		idlist.add(s);
	}

	PP_Content__c[] content = [select Id, Name, DocumentId__c from PP_Content__c where DocumentId__c in :idList];
	Map<String, PP_Content__c> contentMap = new Map<String, PP_Content__c>();
	for (PP_Content__c so : content) {
		contentMap.put(so.DocumentId__c, so);
	}
	
	for (ContentDocument cv : Trigger.new) {
		String docId = cv.Id;
		if (contentMap.containsKey(docId)) {
			String title = cv.Title;
			if (title.length() > 80) title = title.substring(0, 79);
			contentMap.get(cv.Id).Name = title;
		}
		else {
			System.debug('*****[debug]***** key not found: ' + cv.Id);
		}
	}
	update contentMap.values();
*/
}