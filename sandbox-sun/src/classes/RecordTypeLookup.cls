/**
 * This is a class to do record type ids.  Custom settings are automatically created,
 * so this can be used without governor limits, more than once.  Any sobjecttype requested
 * must have a corresponding IdFor<SObjectType> field in the RecordTypeLookup__c object.
 * e.g. IdForTask__c contains the record type Id for tasks.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-04-07
 * 2013-04-07 - created
 */
public without sharing class RecordTypeLookup {
	public static Boolean lookupCompleted = false;

	/**
	 * This is a mapping of all values.
	 */
	private static Map<String,RecordTypeLookup__c> lookupMap {
		get {
			if(lookupMap == null) {
				lookupMap = new Map<String,RecordTypeLookup__c>();
				for(RecordTypeLookup__c rtl : RecordTypeLookup__c.getAll().values()) {
					lookupMap.put(rtl.Name.toLowerCase(),rtl);
				}
 			}
 			return lookupMap;
		}
	}

	/**
	 * Lookup the record type id given the record type name and sobject type.
	 *
	 * @param name RecordType.Name
	 * @param sobjectType RecordType.SObjectType
	 * @return recordTypeId
	 */
	public static Id getRecordTypeId(String name,String sobjectType) {
		name = name.toLowerCase();
		RecordTypeLookup__c rtl = lookupMap.get(name);
		Id recordTypeId = null;
		String fieldName = 'IdFor'+sobjectType;
		if(! fieldName.toLowerCase().endsWith('__c')) {
			fieldName += '__c';
		}
		if(rtl != null) {
			recordTypeId = (Id)(String)rtl.get(fieldName);
		}
		if(recordTypeId == null && ! lookupCompleted) {
			System.debug('RecordTypeId for name='+name+',sobjecttype='+sobjectType+' must be looked up');
			lookupCompleted = true;
			Map<String,RecordTypeLookup__c> upsertMap = new Map<String,RecordTypeLookup__c>();
			// populate a map of SObjectType to RecordTypeLookup__c field name
			Map<String,String> fieldNameMap = new Map<String,String>();
			for(String xfieldName : Schema.SObjectType.RecordTypeLookup__c.fields.getMap().keySet()) {
				if(xfieldName.startsWith('idfor') && xfieldName.endsWith('__c')) {
					String objectType = xfieldName.substring(5).toLowerCase();
					fieldNameMap.put(objectType,xfieldName);
					fieldNameMap.put(objectType.substring(0,objectType.length()-3),xfieldName);
				}
			}
			System.debug('fieldNameMap='+fieldNameMap);
			for(RecordType rt : [
				select 
					Name,
					SObjectType
				from RecordType
				where SObjectType in :fieldNameMap.keySet()
					and IsActive = true ])
			{
				String xname = rt.Name.toLowerCase();
				RecordTypeLookup__c xrtl = lookupMap.get(xname);
				if(xrtl == null) {
					xrtl = new RecordTypeLookup__c(Name=rt.Name);
					lookupMap.put(xname,xrtl);
				}
				String xfieldName = fieldNameMap.get(rt.SObjectType.toLowerCase());
				Id xrecordTypeId = (Id)(String)xrtl.get(xfieldName);
				if(rt.Id != xrecordTypeId) {
					xrtl.put(xfieldName,(String)rt.Id);
					upsertMap.put(xname,xrtl);
					System.debug('xname='+xname+',xfieldname='+xfieldName+',rt.Id='+rt.Id);
					if(name == xname && fieldName == xfieldName) {
						recordTypeId = rt.Id;
					}
				}
			}
			if(! upsertMap.isEmpty()) {
				Database.upsert(upsertMap.values(),false);
			}
		}
		return recordTypeId;
	}
}