/**
* Class Name:LeadRulesTest 
* Description:Test Class created for LeadRulesTest business Class.
* Modificaton History:
* Modified By:Ratan Sharma
* Modified date :5/2/2011
* Reason for Modification:Separated test class from business class and created a new test class
*/

@IsTest
private class LeadRulesTest 
{
	public static testmethod void t1()
    {
    	LeadRules__c[] obj_arr_deploy= new LeadRules__c[2];
        LeadRules__c obj_arr = new LeadRules__c();
        LeadRules__c obj_deploy= new LeadRules__c();
        LeadRules__c obj_deploy1= new LeadRules__c();
      
        obj_deploy.Type__c='Country';
        obj_deploy.Value__c='India';
        obj_deploy.User__c=Util.ldUserId;
        obj_deploy.SuperRegion__c='APAC';
        obj_arr_deploy[0]=obj_deploy;
      
        obj_deploy1.Type__c='Country';
        obj_deploy1.Value__c='Indiaaa';
        obj_deploy1.User__c=Util.ldUserId;
        obj_deploy1.SuperRegion__c='LATAM';
        obj_deploy1.Zip_Code__c = '12345';
        obj_arr_deploy[1]=obj_deploy1;
      
        insert obj_arr_deploy;
      
        test.startTest();
      
        new LeadRules().setUniqueLeadRule(obj_arr_deploy);
        obj_arr = [Select Id, Unique_Identifiers__c, SuperRegion__c from LeadRules__c where Value__c =: 'Indiaaa' and SuperRegion__c=: 'LATAM'];
      
        test.stopTest();
      
        System.assertEquals('CountryLATAMIndiaaanullnullnull12345nullnull',obj_arr.Unique_Identifiers__c);
    }
}