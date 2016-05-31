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
private class FormatControllerTest {
	static testMethod void currencyTest() {
		FormatController controller = new FormatController();
		controller.currencyString = 'dog';
		System.assertEquals(null,controller.currencyString);
		System.assertEquals(null,controller.getCurrencyFormatted());
		controller.currencyIsoCode = 'USD';
		System.assertEquals('USD',controller.currencyIsoCode);
		controller.currencyString = '-1.00';
		System.assertEquals('-1.00',controller.currencyString);
		System.assertNotEquals(null,controller.getCurrencyFormatted());
		controller.currencyString = '1.00';
		System.assertEquals('1.00',controller.currencyString);
		System.assertNotEquals(null,controller.getCurrencyFormatted());
		controller.currencyIsoCode='JPY';
		controller.currencyString = '-100.00';
		System.assertEquals('-100',controller.getCurrencyFormatted());
	}

	static testMethod void dateTest() {
		FormatController controller = new FormatController();
		Date dateValue = Date.newInstance(2009,11,30);
		System.assertEquals(null,controller.getDateFormatted());
		controller.dateValue = dateValue;
		System.assertEquals(dateValue,controller.dateValue);
		System.assertNotEquals(null,controller.getDateFormatted());
	}
}