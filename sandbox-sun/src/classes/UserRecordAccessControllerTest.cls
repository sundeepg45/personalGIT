/**
 * This is a test class for UserRecordAccessController.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-09-19
 * 2012-09-19 - created
 */
@isTest
private class UserRecordAccessControllerTest {
	@isTest
	static void coverageTest() {
		UserRecordAccessController controller = new UserRecordAccessController();
		controller.recordId = UserInfo.getUserId();
		controller.requireAllAccess = true;
		System.assertEquals(true,controller.requireAllAccess);
		controller.requireDeleteAccess = true;
		System.assertEquals(true,controller.requireDeleteAccess);
		controller.requireEditAccess = true;
		System.assertEquals(true,controller.requireEditAccess);
		controller.requireTransferAccess = true;
		System.assertEquals(true,controller.requireTransferAccess);
		controller.requireReadAccess = true;
		System.assertEquals(true,controller.requireReadAccess);
		controller.requireAccess = true;
		System.assertEquals(true,controller.requireAccess);
		Boolean result1 = controller.getShowBody();
		controller.requireAccess = false;
		System.assertNotEquals(result1,controller.getShowBody());
	}
}