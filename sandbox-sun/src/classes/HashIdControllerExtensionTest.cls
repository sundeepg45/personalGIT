/**
 * Test class for HashIdControllerExtenison
 *
 * @version 2013-06-26
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * 2013-07-26 - Created
 */
@isTest
private class HashIdControllerExtensionTest {

	static private HashIdControllerExtension getControllerExtension() {
		PageReference pageRef = new PageReference('/'+UserInfo.getUserId()+'/e');
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController sc = new ApexPages.StandardController(new User(Id=UserInfo.getUserId()));
		HashIdControllerExtension extension = new HashIdControllerExtension(sc);
		return extension;
	}

	@isTest
	static void getterTests() {
		HashIdControllerExtension e = getControllerExtension();
		System.assert(!e.isClone);
		System.assert(!e.isCloneWithoutRecordType);
		e.isClone = null;
		e.isCloneWithoutRecordType = null;
		ApexPages.currentPage().getParameters().put('clone','1');
		System.assert(e.isClone);
		System.assert(!e.isCloneWithoutRecordType);
		e.isCloneWithoutRecordType = null;
		ApexPages.currentPage().getParameters().put('clonewort','1');
		System.assert(e.isCloneWithoutRecordType);
	}

	@isTest
	static void hashIdIfCloneTest() {
		HashIdControllerExtension e = getControllerExtension();
		e.hashIdIfClone();
		System.assert(! HashIdControllerExtension.hasHashForId(UserInfo.getUserId()),'Unexpected hash for current user id');
		e = getControllerExtension();
		ApexPages.currentPage().getParameters().put('clone','1');
		e.hashIdIfClone();
		HashIdControllerExtension.hashesForCurrentUser = null;
		System.assert(HashIdControllerExtension.hasHashForId(UserInfo.getUserId()),'Expected hash for current user id');
	}
}