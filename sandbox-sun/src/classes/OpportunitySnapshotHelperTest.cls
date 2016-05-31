@isTest
private class OpportunitySnapshotHelperTest {

    static testMethod void helperTest() {
        System.assertEquals(false, OpportunitySnapshotHelper.hasAlreadyCreatedSnapshot());
        OpportunitySnapshotHelper.setAlreadyCreatedSnapshot();
        System.assertEquals(true, OpportunitySnapshotHelper.hasAlreadyCreatedSnapshot());
    }
}