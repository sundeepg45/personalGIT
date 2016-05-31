/**
 * This is a test class for OpportunityLineStagingController class.
 *
 * @author Sagar J Mehta <smehta@redhat.com>
 * @version 2014-20-02
 * 2014-20-02 - created
 */
@isTest 
private class OpportunityLineStagingControllerTest {
      /*
     * Method used to cover positive scenarios
     * @param none
     */  
      @isTest
     static void saveMethodCoverage() {
            Opportunity_Line_Staging__c LineStaging=new  Opportunity_Line_Staging__c();
            ApexPages.StandardController sc = new ApexPages.StandardController(LineStaging);
            OpportunityLineStagingController oppLineStaging= new OpportunityLineStagingController(sc);
            PageReference pageRef =ApexPages.currentPage();
            pageRef=oppLineStaging.redirectToOpptyHeaderStaging();
    
    }
}