@isTest
private class SyncPicklistValuesControllerTest {
	
	@isTest static void createServiceTest() {
		MetadataService.MetadataPort service = SyncPicklistValuesController.createService();
		System.assertNotEquals(null, service);
	}

	@isTest static void clearUserRegionPicklistValuesTest() {
		SyncPicklistValuesController controller = new SyncPicklistValuesController();
		controller.clearUserRegionPicklistValues();
		System.assert(!String.isBlank(controller.log));
		System.debug(controller.log);
	}

	@isTest static void syncUserRegionPicklistValuesTest() {
		Region__c testRegion = new Region__c();
		testRegion.Super_Region__c = 'EMEA';
		testRegion.Region__c = 'Test Region';
		testRegion.Sub_Region__c = 'Test Subregion';
		insert testRegion;

		Region_NA__c testRegionNa = new Region_NA__c();
		testRegionNa.Super_Region__c = 'NA';
		testRegionNa.Region__c = 'Test NA Region';
		testRegionNa.Sub_Region__c = 'Test NA Subregion';
		insert testRegionNa;

		SyncPicklistValuesController controller = new SyncPicklistValuesController();
		controller.syncUserRegionPicklistValues();
		System.assert(!String.isBlank(controller.log));
		System.assert(controller.log.contains('Test Region'));
		System.assert(controller.log.contains('Test Subregion'));
		System.assert(controller.log.contains('Test NA Region'));
		System.assert(controller.log.contains('Test NA Subregion'));		
		System.assert(controller.log.contains('Test Complete!'));
		System.debug(controller.log);
	}
}