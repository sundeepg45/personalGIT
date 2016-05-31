/**
 * Tests that channel load users cannot update the OracleAccountNumber__c value.
 *
 * @author unknown
 * @version 2012-07-10
 * Bill Riemers <briemers@redhat.com>
 * 2012-07-10 - SMR update
 * Abhijeet Anand
 * unknown - Enhanced code coverage and added assert statements.
 */
@isTest
private class AccountChannelLoadTest
{
	@isTest
	static void accChannelTest()
	{
		AdminByPass__c adminByPass = AdminByPass__c.getInstance();
		adminByPass.IsAdmin__c = false;
		adminByPass.IsChannelLoad__c = true;
		adminByPass.IsOppAdmin__c = true;
		upsert adminByPass;
		Account acc = new Account();   
		acc.Name='TestAcc';   
		acc.CurrencyIsoCode='USD';
		acc.OracleAccountNumber__c ='12345';

		insert acc;

		acc.OracleAccountNumber__c ='67891';
		acc.PrimaryBillToAcct__c = true;
		update acc;

		Test.startTest();

		System.assertEquals('12345',[Select OracleAccountNumber__c from Account where id=:acc.id].OracleAccountNumber__c);

		Test.stopTest();
	}
}