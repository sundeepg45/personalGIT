/**
 * This is a test class for OpportunityBookedErrorClass class.
 *
 * @author Sagar J Mehta <smehta@redhat.com>
 * @version 2014-20-02
 * 2014-20-02 - created
 */
@isTest 
private class OpportunityBookedErrorClassTest {
    
    /*
     * Method used to cover positive scenarios
     * @param none
     */  
      @isTest
      static void saveMethodCoverage() {        
          User u1 = [Select Id, Name from User where Profile.Name = 'System Administrator' and IsActive = true];
          System.runAs(u1){
             Test.startTest();
             
             Opportunity_Header_Staging__c headerStaging=new  Opportunity_Header_Staging__c();
             headerStaging.Order_Status__c = 'BOOKED';
             headerStaging.Status__c = 'Processed';    
             insert headerStaging;            
            
             ApexPages.StandardController sc = new ApexPages.StandardController(headerStaging);
             OpportunityBookedErrorClass oppBookedErrorClass= new OpportunityBookedErrorClass(sc);        
          
             Profile profile = [select Id from Profile where Name =: 'System Administrator'];                             
             User user = new User();
             user.Username = 'sagamehta123@deloitte.com';
             user.Email = 'sagamehta@deloitte.com';
             user.LastName = 'Test';
             user.Alias = 'Test123';
             user.ProfileID = profile.Id;
             user.LocaleSidKey = 'en_US';
             user.LanguageLocaleKey = 'en_US';
             user.Country = 'India';
             user.TimeZoneSidKey = 'America/Los_Angeles';
             user.EmailEncodingKey='UTF-8';
             insert user;
             System.runAs(user) {
               oppBookedErrorClass.showErrorMessage();
             }            
          }  
          Test.stopTest();                     
      }
      
      /*
     * Method used to cover positive scenarios
     * @param none
     */  
      @isTest
      static void saveMethodCoverageElseScenario() {        
          User u1 = [Select Id, Name from User where Profile.Name = 'System Administrator' and IsActive = true];
          System.runAs(u1){
             Test.startTest();
             
             Opportunity_Header_Staging__c headerStaging=new  Opportunity_Header_Staging__c();
             headerStaging.Order_Status__c = 'CLOSED';
             headerStaging.Status__c = 'Error';    
             insert headerStaging;
             
             ApexPages.StandardController sc = new ApexPages.StandardController(headerStaging);
             OpportunityBookedErrorClass oppBookedErrorClass= new OpportunityBookedErrorClass(sc);        
          
             Profile profile = [select Id from Profile where Name =: 'System Administrator'];                             
             User user = new User();
             user.Username = 'sagamehta123@deloitte.com';
             user.Email = 'sagamehta@deloitte.com';
             user.LastName = 'Test';
             user.Alias = 'Test123';
             user.ProfileID = profile.Id;
             user.LocaleSidKey = 'en_US';
             user.LanguageLocaleKey = 'en_US';
             user.Country = 'India';
             user.TimeZoneSidKey = 'America/Los_Angeles';
             user.EmailEncodingKey='UTF-8';
             insert user;
             System.runAs(user) {
               oppBookedErrorClass.showErrorMessage();
             }            
          }  
          Test.stopTest();                     
      }
     
}