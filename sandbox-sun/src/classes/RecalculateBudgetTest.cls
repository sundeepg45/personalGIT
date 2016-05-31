/**
 * This is the controller used for testing RecalculateBudget.
 *
 * @version 2015-05-08
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-05-08 - Refactored from Recalculate Budget
 */
@isTest
public with sharing class RecalculateBudgetTest {

	@isTest(SeeAllData=true) // needed to query account
	public static void coverageTest() {

		User objUser=new User(Id = UserInfo.getUserId());
		// we really should create an account rather than looking for an existing one...
		Account objAccount=[
			select Id
			from Account
			where isAccountActive__c=true
			and RecordtypeId = '012600000004yfa'
			limit 1 ];

		objAccount.ownerId = objUser.Id;
		update objAccount;

		RecordType objRecordType=[Select Id from RecordType where Name='MDF' and  SobjectType='SFDC_Budget__c'];


		SFDC_Budget__c testBudget1 = new SFDC_Budget__c(Allocated_Budget__c = 1000,
			Approved_Requests__c = 100,
			Approved_Claims__c = 100,
			Requests_Submitted__c=100,
			Requests_Awaiting_Approval__c=100,
			Claims_Submitted__c=100,
			Claims_Awaiting_Approval__c=100,
			Last_Refresh_Date__c =datetime.now(),
			RecordtypeId=objRecordType.Id,
			CurrencyIsoCode ='CAD',
			Account_master__c=objAccount.Id );


		insert testBudget1;

		SFDC_MDF__c objMDF1 = new SFDC_MDF__c(
			Account_master__c=objAccount.Id,
			Budget__c=testBudget1.Id,
			Requester_Name__c=objUser.Id,
			Approval_Status__c='Pending First Approval',
			Total_Expenditure_of_Activity__c = 200,
			Estimated_Red_Hat_Funding_Requested__c=100,
			CurrencyIsoCode='CAD');

		SFDC_MDF__c objMDF2 = new SFDC_MDF__c(
			Account_master__c=objAccount.Id,
			Budget__c=testBudget1.Id,
			Requester_Name__c=objUser.Id,
			Approval_Status__c='Pending First Approval',
			Total_Expenditure_of_Activity__c = 200,
			Estimated_Red_Hat_Funding_Requested__c=50,
			CurrencyIsoCode='CAD',
			Oracle_Project_Code__c = '4619 – RHT Global Awareness');
		insert new List<SFDC_MDF__c>{objMDF1,objMDF2};

		objMDF2.Approval_Status__c='Approved';
		update objMDF2;

		SFDC_MDF_Claim__c objClaim12 = new SFDC_MDF_Claim__c(
			Account__c=objAccount.Id,
			Budget__c=testBudget1.Id,
			Claim_Requester_Name__c=objUser.Id,
			Requested_Amount__c=10,
			Approval_Status__c='Pending First Approval',
			CurrencyIsoCode='CAD',
			Fund_Request__c = objMDF2.Id);
		insert objClaim12;

		objClaim12.Approval_Status__c='Approved';
		update objClaim12;

		SFDC_MDF_Claim__c objClaim13 = new SFDC_MDF_Claim__c(
			Account__c=objAccount.Id,
			Budget__c=testBudget1.Id,
			Claim_Requester_Name__c=objUser.Id,
			Requested_Amount__c=1,
			Approval_Status__c='Pending First Approval',
			CurrencyIsoCode='CAD',
			Fund_Request__c = objMDF1.Id);
		insert objClaim13;

		Test.startTest();
		RecalculateBudget.calculate(testBudget1.Id);
		RecalculateBudget.getFundRequestAmount(testBudget1.Id);
		RecalculateBudget.getFundClaimAmount(testBudget1.Id);
		RecalculateBudget.getFundRequestSubmittedAmount(testBudget1.Id);
		RecalculateBudget.getFundRequestAwaitingApp(testBudget1.Id);
		RecalculateBudget.getFundClaimSubmiited(testBudget1.Id);
		RecalculateBudget.getFundClaimAwaitingApp(testBudget1.Id);
		RecalculateBudget.getConvertedCurrencyValue(objClaim12.Requested_Amount__c,objClaim12.CurrencyIsoCode,RecalculateBudget.budgetCurrency);
		Test.stopTest();
	}

}