/**
* Class Name:LeadAccountRulesTest
* Description:Test Class created for LeadAccountRules business Class.
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :4/27/2011
* Reason for Modification:Separated test class from business class and created a new test class
* Modified By :Nitesh Dokania
* Modified date :6/6/2011
* Reason for Modification: Enhanced the test class coverage.
*/

@IsTest
private class LeadAccountRulesTest
{
	public static testmethod void leadAccRulesTest()
    {

        Account TestAcc= new Account();
        TestAcc.Name='Test';
        TestAcc.Named_Account__c=true;
        TestAcc.isAccountActive__c=true;
        insert TestAcc;

        List<LeadAccountRules__c> obj_arr_deploy= new List<LeadAccountRules__c>();
        List<LeadAccountRules__c> obj_arr = new List<LeadAccountRules__c>();
        LeadAccountRules__c obj_deploy= new LeadAccountRules__c();
        LeadAccountRules__c obj_deploy1= new LeadAccountRules__c();
                
        obj_deploy.Type__c='Named Account';
        obj_deploy.Value__c='Accenture';
        obj_deploy.Account__c=TestAcc.Id;
        obj_deploy.User__c=Util.ldUserId;
        obj_deploy.SuperRegion__c='APAC';
        obj_arr_deploy.add(obj_deploy);
        
        obj_deploy1.Type__c='Named Account';
        obj_deploy1.Value__c='Accenture';
        obj_deploy1.Account__c=TestAcc.Id;
        obj_deploy1.User__c=Util.ldUserId;
        obj_deploy1.SuperRegion__c='LATAM';
        obj_arr_deploy.add(obj_deploy1);
                
		insert obj_arr_deploy;
                
        test.startTest();
        
        new LeadAccountRules().setUniqueIdentifier(obj_arr_deploy);
        obj_arr = [Select Id, Unique_Identifier__c, SuperRegion__c from LeadAccountRules__c where Account__c =: TestAcc.Id];
        
        test.stopTest();
        
        for(LeadAccountRules__c rule : obj_arr)
        {
        	if(rule.SuperRegion__c == 'LATAM')
        		System.assertEquals('LATAMAccenturenullnullNamed Account',rule.Unique_Identifier__c);
        	else
        		System.assertEquals('APACAccenturenullnull',rule.Unique_Identifier__c);
        }
    }
}