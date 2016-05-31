@isTest(SeeAllData=true)
private class PP_CapChangeRecalcTest {

    static testMethod void myUnitTest() {

        String reseller = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.RESELLER').ObjectId__c;
        String ready = RedHatObjectReferences__c.getInstance('PARTNER_TIER.READY').ObjectId__c;
        
        PP_Cap__c cap = new PP_Cap__c();
        cap.Partner_Type__c = reseller;
        cap.Partner_Tier__c = ready;
        cap.Global_Region__c = 'NA';
        cap.Cap_Points__c = 10000;
        insert cap;

        cap.Cap_Points__c = 10001;
        update cap;
    }
}