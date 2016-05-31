global class SalesPortalContentPublishing {

	WebService static void togglePublish(String ppId) {
		if (ppId == null || ppId.length() == 0) {
			return;
		}
				
		SalesPortalContent__c content = [select id, Published__c from SalesPortalContent__c where Id = :ppId];
		content.Published__c = !content.Published__c;
		update content;
	}

}