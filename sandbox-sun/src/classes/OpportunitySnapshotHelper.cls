public with sharing class OpportunitySnapshotHelper {
	
	private static boolean alreadyCreatedSnapshot = false;
	
	public static boolean hasAlreadyCreatedSnapshot() {
		return alreadyCreatedSnapshot;
	}
	
	public static void setAlreadyCreatedSnapshot() {
		alreadyCreatedSnapshot = true;
	}
}