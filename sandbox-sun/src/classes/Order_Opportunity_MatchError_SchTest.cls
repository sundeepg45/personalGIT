@isTest
private class Order_Opportunity_MatchError_SchTest{
    static testmethod void  testschedule(){
        Test.StartTest();
            Order_Opportunity_MatchError_Schedulable sh1 = new Order_Opportunity_MatchError_Schedulable();      
            String sch = '0  00 1 3 * ?';
            system.schedule('Test', sch, sh1);
        Test.stopTest();
    }
}