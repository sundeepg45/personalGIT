/**
 * This is a test class for the EnhancedRelatedListController
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-09-10
 * 2013-03-19 - created
 * Scott Coleman <scoleman@redhat.com>
 * 2013-09-10 - column sorting test coverage
 */
@isTest
private class EnhancedRelatedListControllerTest {
	@isTest
	static void userTest() {
		EnhancedRelatedListController controller = new EnhancedRelatedListController();
		controller.queryObject = 'User';
		controller.queryFields = 'FirstName,LastName';
		controller.queryConditions = 'IsActive = true and (not Profile.Name like \'%partner%\')';
		controller.queryOrderBy = 'LastName';
		controller.queryLimit = 101;
		System.assertEquals('select FirstName,LastName from User where IsActive = true and (not Profile.Name like \'%partner%\') order by LastName limit 101',
			controller.getQueryString());
		controller.pageSize = 50;
		controller.fieldLabelListString = ',Last Name';
		System.assertEquals(2,controller.columns.size());
		System.assertEquals('FirstName',controller.columns[0].getFieldName());
		System.assertEquals('LastName',controller.columns[1].getFieldName());
		System.assertNotEquals(null,controller.columns[0].label);
		System.assertNotEquals('',controller.columns[0].label);
		System.assertEquals('Last Name',controller.columns[1].label);
		// first page
		System.assertEquals(50,controller.getRecords().size());
		User u1 = (User)controller.getRecords()[49];
		System.assertEquals(3,controller.getPageCount());
		// last page
		controller.last();
		System.assertEquals(1,controller.getRecords().size());
		User u3 = (User)controller.getRecords()[0];
		System.assertNotEquals(u1.Id,u3.Id);
		// second page
		controller.previous();
		System.assertEquals(50,controller.getRecords().size());
		User u2 = (User)controller.getRecords()[49];
		System.assertNotEquals(u1.Id,u2.Id);
		System.assertNotEquals(u2.Id,u3.Id);
		// first page again
		controller.first();
		System.assertEquals(u1.Id,controller.getRecords()[49].Id);
		// second page again
		controller.next();
		System.assertEquals(u2.Id,controller.getRecords()[49].Id);
		// just a bit of coverage
		controller.sequence = 2;
		System.assertEquals(2,controller.sequence);
	}

	@isTest
	static void sortingTest() {
		List<Account> testAccounts = new List<Account>{
			new Account(Name='E',AccountNumber='2',Site='TESTCLASS123'),
			new Account(Name='T',AccountNumber='1',Site='TESTCLASS123'),
			new account(Name='TING',AccountNumber='4',Site='TESTCLASS123'),
			new Account(Name='S',AccountNumber='3',Site='TESTCLASS123')};
		insert testAccounts;			
		EnhancedRelatedListController controller = new EnhancedRelatedListController();			
		controller.queryObject = 'Account';
		controller.queryFields = 'Name,AccountNumber';
		controller.sortFieldsString = ',AccountNumber';
		controller.queryConditions = 'Site = \'TESTCLASS123\'';
		controller.queryOrderBy = 'Name';
		System.assertEquals('select Name,AccountNumber from Account where Site = \'TESTCLASS123\' order by Name',
			controller.getQueryString());
		controller.pageSize = 50;
		System.assertEquals(2,controller.columns.size());
		System.assertEquals('AccountNumber',controller.columns[1].getFieldName());
		controller.columns[1].sortField();
		Account a1 = (Account)controller.getRecords()[0];
		System.assertEquals('T',a1.Name);
	}
}