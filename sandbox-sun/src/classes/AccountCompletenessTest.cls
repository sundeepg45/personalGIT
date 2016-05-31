/**
* Class Name: AccountCompletenessTest
* Description: Test Class created for AccountCompleteness trigger.
* Modified By :Nitesh Dokania
* Modified date :6/11/2011
* Reason for Modification: Enhanced the code coverage of the corresponding class.
*/

@isTest
private class AccountCompletenessTest 
{

	static testMethod void myUnitTest() 
	{

		DeactivateAllTestUtil.setDeactivateAll(false);

		// TO DO: implement unit test
		Account acct = new Account();
		acct.Name = 'Test Account';
		acct.AccountClassification__c = 'ETR';
		acct.Phone = '26710292';
		acct.Website = 'http://www.google.com';
		acct.BillingStreet = 'Test Street';
		acct.BillingCity = 'Pune';
		acct.BillingState = 'Maharashtra';
		acct.BillingPostalCode = '411013';
		acct.ShippingStreet = 'Test Street';
		acct.ShippingCity = 'Pune';
		acct.ShippingState = 'Maharashtra';
		acct.ShippingPostalCode = '411013';
		acct.Description = 'Test Desc';
		acct.Recent_Major_Events__c = 'trertwe';
		acct.RH_Sales_Strategy__c = 'freatr';
		acct.D_U_N_S__c = 'abcd';
		acct.Ownership = 'Joint Venture';
		acct.Industry = 'Aerospace';
		acct.NumberOfEmployees = 100;
		acct.AnnualRevenue = 12345.0;
		acct.Fiscal_Year_End__c = System.today();
		acct.Target_Revenue_for_Red_Hat_yearly__c = 43223.0;
		acct.Revenue_to_Date__c = 543534.0;
		acct.PreferredHWVendor__c = 'Dell';
		acct.Enrollment_Date__c = System.today();
		acct.Accreditation__c = 'test';
		acct.Number_of_RHCE__c = 23;
		acct.Number_of_RHCT_Certifications__c = 43;
		acct.Number_of_RHCA_Certifications__c = 32;
		acct.Number_of_RHCSS_Certifications__c = 12;
		acct.Number_of_Trained_JBoss_Professionals__c = 43;
		acct.Partner_Account_Status__c = 'app';
		acct.Class_of_Trade__c = 'Distributor';
		acct.Num_of_End_Customer_Account__c = 12;
		acct.Key_Contact_Email__c = 'test@test.com';
		acct.Key_Contact__c = 'test contact';
		acct.Key_Contact_Cell_Phone__c = '3213432';
		acct.Key_Contact_Primary_Phone__c = '4254322';
		acct.Service_Area__c = 'CANADA';
		acct.Technology_Solutions_Expertise__c = 'Application Maintenance';
		acct.Solution_Partners__c = 'BEA';
		acct.Industry_Vertical_Expertise__c = 'Aerospace';
		acct.Service_Offerings__c = 'Jboss';
		acct.Sweet_Spot__c = 'trew';
		acct.Special_Service_Offerings_or_Skills__c = true;
		acct.Describe__c = 'test desc';
		insert acct;
		
		test.startTest();
		
		Account acc = new Account();
		acc = [Select id, Completeness__c from Account where id=:acct.Id];
		
		test.stopTest();
		
		System.assertEquals(100.00,acc.Completeness__c);
	}
}