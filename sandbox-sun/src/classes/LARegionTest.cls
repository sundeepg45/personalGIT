/**
* Class Name:LARegionTest
* Description:Test Class created for LARegion business Class.
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :5/2/2011
* Reason for Modification:Separated test class from business class and created a new test class
* Modified By :Abhijeet Anand
* Reason for Modification :Enhanced code coverage and added assert statements.
*/

@IsTest
private class LARegionTest
{
    public static testmethod void testLARegion()
    {
        LeadCountryMap__c obj_deploy= new LeadCountryMap__c();
        obj_deploy.Country__c='India1';
        obj_deploy.ISO_Code__c='IND';
        obj_deploy.Region__c ='APAC';
        String isoCode;
        String region;
        
        Test.startTest(); 
        
        insert obj_deploy;        
        isoCode=new LARegion().getISOCode(obj_deploy.Country__c);
        region=new LARegion().getRegion(obj_deploy.ISO_Code__c);
        
        Test.stopTest();

        // Verify the results
        System.assertEquals('IND',isoCode);
        System.assertEquals('APAC',region);
        
    }
 }