public interface PPScoringPlugin {

	boolean scoreObject(Contact user, String objId);
	double getObjectScore(String objectId);
	String getObjectSubcategory(String objectId);
	boolean scoreBatch(String batchId);
	PP_Scores__c scoreSingle(Contact contact, String batchItemId);
	String getName();
	PageReference getAdminUI();
	PPSearchResult[] findScoredItems(String pattern);
	PPSearchResult[] findByName(String pattern);
}