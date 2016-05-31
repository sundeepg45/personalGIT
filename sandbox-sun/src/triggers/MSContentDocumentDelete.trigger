trigger MSContentDocumentDelete on ContentDocument (before delete) {

	Set<String> documentIdList = PartnerUtil.getIdSet(Trigger.old);
	List<String> normalIdList = new List<String>();
	for (String docId : documentIdList) {
		normalIdList.add(docId); //.substring(0, 15));
	}

	RH_Content__c[] rhclist = [
		select	Id,
				ContentDocumentId__c
		from	RH_Content__c
		where	ContentDocumentId__c in :normalIdList
		and		IsPublished__c = true
	];

	boolean hasError = false;
	for (RH_Content__c rhc : rhclist) {
		for (ContentDocument cv : Trigger.old) {
			ID rhcid = rhc.ContentDocumentId__c; //.substring(0,15);
			System.debug('****[debug]**** comparing ' + cv.Id + ' and ' + rhcid);
			if (cv.Id == rhcid) {
				System.debug('****[debug]**** found match for ' + cv.Id + ' and ' + rhcid);
				cv.addError('Content in use by Red Hat Microsite(s) and cannot be removed');
				cv.Title.addError('Content in use by Red Hat Microsite(s) and cannot be removed');
				hasError = true;
			}
		}
	}
	
	if (!hasError) {
		delete [select Id from RH_Content__c where ContentDocumentId__c in :normalIdList and IsPublished__c =  false];
	}
}