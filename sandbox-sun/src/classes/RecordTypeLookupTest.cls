/**
 * This is a test class for RecordTypeLookup.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-04-07
 * 2013-04-07 - created
 */
@isTest
private class RecordTypeLookupTest {
	@IsTest
	static void existingRecordTypeTest() {
		RecordType rt = [
			select Name, SObjectType
			from RecordType
			where 
				SObjectType='Task'
				and IsActive=true
			limit 1];
		Id recordTypeId = RecordTypeLookup.getRecordTypeId(rt.Name,rt.SObjectType);
		System.assertEquals(rt.Id,recordTypeId);
		RecordTypeLookup__c rtl = [select IdForTask__c from RecordTypeLookup__c where Name=:rt.Name];
		System.assertEquals(recordTypeId,(Id)rtl.IdForTask__c);
	}

	@IsTest
	static void fakeLookupTest() {
		Id fakeId = UserInfo.getUserId();
		insert new RecordTypeLookup__c(Name='Fake',IdForTask__c=UserInfo.getUserId());
		Id recordTypeId = RecordTypeLookup.getRecordTypeId('Fake','Task');
		System.assertEquals(fakeId,recordTypeId);
	}
}