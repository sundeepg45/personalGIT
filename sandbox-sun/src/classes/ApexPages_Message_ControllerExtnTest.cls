/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ApexPages_Message_ControllerExtnTest {

	static testMethod void userUnitTests() {
		ApexPages.StandardController sc = new ApexPages.StandardController([select Id from User limit 1]);
		ApexPages_Message_ControllerExtension controller = new ApexPages_Message_ControllerExtension(sc);
		System.assert(! controller.getHasErrorMessages());
		ApexPages_Message_ControllerExtension.addErrorMessage('anything');
		System.assert(controller.getHasErrorMessages());
	}

	static testMethod void staticUnitTests() {
		System.assertEquals(0,ApexPages_Message_ControllerExtension.getErrorMessages().size());
		System.assertEquals(0,ApexPages_Message_ControllerExtension.getInfoMessages().size());
		System.assertEquals(0,ApexPages_Message_ControllerExtension.getWarningMessages().size());
		ApexPages_Message_ControllerExtension.addErrorMessage('anything 1');
		System.assertEquals(1,ApexPages_Message_ControllerExtension.getErrorMessages().size());
		System.assertEquals(0,ApexPages_Message_ControllerExtension.getInfoMessages().size());
		System.assertEquals(0,ApexPages_Message_ControllerExtension.getWarningMessages().size());
		ApexPages_Message_ControllerExtension.addInfoMessage('anything 2');
		System.assertEquals(1,ApexPages_Message_ControllerExtension.getErrorMessages().size());
		System.assertEquals(1,ApexPages_Message_ControllerExtension.getInfoMessages().size());
		System.assertEquals(0,ApexPages_Message_ControllerExtension.getWarningMessages().size());
		ApexPages_Message_ControllerExtension.addWarningMessage('anything 3');
		System.assertEquals(1,ApexPages_Message_ControllerExtension.getErrorMessages().size());
		System.assertEquals(1,ApexPages_Message_ControllerExtension.getInfoMessages().size());
		System.assertEquals(1,ApexPages_Message_ControllerExtension.getWarningMessages().size());
	}
}