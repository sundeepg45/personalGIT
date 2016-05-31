/*
*   @version 2013-12-3
*   @author Shawn Cureton <scureton@redhat.com>
*
*   Test Class for Opportunity_BeforeUpdate.trigger
*       Uses Opportunity code & settings from OpportunityTriggerBeforeTest.cls to create an Opportunity
*       with standard variables.
*/

@isTest
private class Opportunity_BeforeUpdateTest {
   /* 
    @isTest
    static void test_DealRegUpdateBlocker() {

    // Create users for runAs() with standard profile and admin profile.

        Profile standard = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        Profile admin = [SELECT Id FROM Profile WHERE Name='Administrator - Level 1'];

        User standardUser = new User(Alias = 'standt', Email='stcTestStandardUser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = standard.Id, 
          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestStandardUser@testorg.com');

        User adminUser = new User(Alias = 'admint', Email='stcTestAdminUser@testorg.com', 
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = admin.Id, 
          TimeZoneSidKey='America/Los_Angeles', UserName='stcTestAdminUser@testorg.com');

    // Create and insert Opportunity records for both users.
        Opportunity oStandard = new Opportunity();
        system.runAs(standardUser){
            oStandard = OpportunityTriggerBeforeTest.opportunity;
            oStandard.Deal_Registration__c = true;
            insert oStandard;
        }

        Opportunity oAdmin = new Opportunity();
        system.runAs(adminuser){
            oAdmin = OpportunityTriggerBeforeTest.opportunity.clone(false,false,false,false);
            oAdmin.Deal_Registration__c = true;
            insert oAdmin;
        }

    // Attempt to change the field and update each Opportunity record as the respective user.

        test.startTest();
        system.runAs(standardUser){
            oStandard.Deal_Registration__c = false;
            try{
                update oStandard;
            }catch(exception e){
                system.assert(e!=null);
            }
        }

        system.runAs(adminuser){
            oAdmin.Deal_Registration__c = false;
            try{
                update oAdmin;
            }catch(exception f){
                system.assert(f==null);
            }
        }
        test.stopTest();

    // Ensure that each record did or didn't update as appropriate.

        Opportunity oStandardAfter = [select Deal_Registration__c from Opportunity where id = :oStandard.id];
        Opportunity oAdminAfter = [select Deal_Registration__c from Opportunity where id = :oAdmin.id];
        system.assertEquals(oStandardAfter.Deal_Registration__c,true);
        system.assertEquals(oAdminAfter.Deal_Registration__c,false);

    }*/
}