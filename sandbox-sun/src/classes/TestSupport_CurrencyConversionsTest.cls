/**
* Class Name: TestSupport_CurrencyConversionsTest
* Description: Test Class created for TestSupport_CurrencyConversions class.
* Created By :Nitesh Dokania
* Created date :09/08/2011
* Reason for Creation : Code coverage of the corresponding class was zero earlier. This class is created to 
*                       increase the code coverage of corresponding test class.
*/


@isTest
private class TestSupport_CurrencyConversionsTest 
{
    static testMethod void currencyConversionTest() 
    {    	
    	test.startTest();
    	
    	TestSupport_CurrencyConversions testCurr = new TestSupport_CurrencyConversions();	
    	testCurr.getDatedConversionRateList();
    	testCurr.getCurrencyTypeList();
    	
    	test.stopTest();  	    	
    }
}