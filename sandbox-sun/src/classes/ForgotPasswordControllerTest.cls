/**
 * Test class for ForgotPasswordController.
 *
 * @author unknown
 * @version 2012-07-10
 * Bill Riemers <briemers@redhat.com>
 * 2012-07-10 - SMR update
 * Ratan Sharma
 * 2011-04-12 - Separated test class from business class and created a new test class
 * Abhijeet Anand
 * Unknown - Enhanced code coverage and added assert statements.
 */
@isTest
private class ForgotPasswordControllerTest
{
	@isTest
	public static void testForgotPasswordController() 
	{
		// Instantiate a new controller with all parameters in the page
		User u = new User(alias = 'standt', email='standarduser@testorg.com',
		emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
		localesidkey='en_US', profileid = UserInfo.getProfileId(),
		timezonesidkey='America/Los_Angeles', username='standarduser12@redhat.com');
		insert u;
		
		Test.startTest();
		
		ForgotPasswordController controller = new ForgotPasswordController();
		controller.username = u.Username; 
		controller.forgotPassword();
		Test.stopTest();
		
		System.assertEquals(controller.forgotPassword(),null); 
	}
}