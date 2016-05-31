/**
 * This is a test class for OpportunityPartnerStagingController class.
 *
 * @author Sagar J Mehta <smehta@redhat.com>
 * @version 2014-20-02
 * 2014-20-02 - created
 */
@isTest 
private class OpportunityPartnerStagingControllerTest {
    /*
     * Method used to cover positive scenarios
     * @param none
     */  
      @isTest
      static void saveMethodCoverage() {
      Opportunity_Partner_Staging__c partnerStaging=new  Opportunity_Partner_Staging__c();
      ApexPages.StandardController sc = new ApexPages.StandardController(partnerStaging);
      OpportunityPartnerStagingController oppPartnerStaging= new OpportunityPartnerStagingController(sc);
      PageReference pageRef =ApexPages.currentPage();
      pageRef=oppPartnerStaging.redirectToOpptyHeaderStaging();
        
      }
}