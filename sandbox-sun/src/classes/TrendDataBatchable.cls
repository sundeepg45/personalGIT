/**
 * This class defines a batch job that is invoked by the TrendData class. The contructor
 * accepts a SOQL query and some object and field information, runs the query, and processes
 * the results in batches. As a result, the TrendData__c object is populates with a snapshot
 * of the field values returned by the query.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-04-17
 * 2013-04-17 - created
 */
global class TrendDataBatchable implements Database.Batchable<sObject>, Database.Stateful {
	global final String query;
	global final String oName;
	global final List<String> fNames;
	global final String eName;

	/**
	 * constructor
	 */
	global TrendDataBatchable(String queryString, String objectName, List<String> fieldNames, String eventName)  
	{  
		query=queryString;
		oName=objectName;
		fNames=fieldNames;
		eName=eventName;
	}  

	/**
	 * start() method implemented for Database.Batchable interface
	 */
	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		return Database.getQueryLocator(query);
	}

	/**
	 * execute() method implemented for Database.Batchable interface 
	 */
	global void execute(Database.BatchableContext bc, List<SObject> sObjects) {
		List<TrendData__c> trendData = new List<TrendData__c>();
		Datetime tStamp = system.now();
		Schema.SObjectType objectType = Schema.getGlobalDescribe().get(oName);
		Map<String,Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
		for(SObject sObj : sObjects) {
			Object rId = sObj.get('Id');
			Object curr = sObj.get('CurrencyISOCode');
			for(String fName : fNames) {
				Schema.DisplayType displayType = fieldMap.get(fName).getDescribe().getType();
				Object fValue = sObj.get(fName);
				TrendData__c td = new TrendData__c(
					CurrencyISOCode=String.valueOf(curr),
					TimeStamp__c=tStamp,
					EventName__c=eName,
					RecordId__c=String.valueOf(rId),
					ObjectName__c=oName,
					FieldName__c=fName,
					FieldValue__c=String.valueOf(fValue));
				if(displayType == Schema.DisplayType.Currency) {
					td.FieldValueCurrency__c = (Decimal)fValue;
				}
				else if(displayType == Schema.DisplayType.Double || displayType == Schema.DisplayType.Integer || displayType == Schema.DisplayType.Percent) {
					td.FieldValueNumber__c = (Decimal)fValue;
				}
				trendData.add(td);
			}
		}
		if(trendData.size()>0) {
			insert trendData;
		}
	}

	/**
	 * finish() method implemented for Database.Batchable interface
	 */
	global void finish(Database.BatchableContext bc) {

	}
}