@isTest(SeeAllData = true)
private class SumTotal_UpdateTrackTest {

    @isTest static void test() {
        Account testAccount = PartnerTestUtils.quickGenericAccountSetup('SumTotal Update Track Test');
        Contact testContact = PartnerTestUtils.makeContact(testAccount.Id, 'SumTotalUpdateTrackTest');
        Contact_Track__c track = new Contact_Track__c();
        PartnerTrack__c partnerTrack = new PartnerTrack__c();
        partnerTrack.Partner_Function__c = 'Sales';
        partnerTrack.Product_of_Interest__c = 'Middleware Solutions';
        insert partnerTrack;
        track.Partner_Track__c = partnerTrack.Id;
        insert track;
    }
}