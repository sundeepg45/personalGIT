/**
 * This class has static methods that initiate a snapshot of data points
 * that can be used to track data trends. This capture is driven by the
 * object and field metadata defined in the TrendDataSettings__c custom
 * setting. The data is stored in the TrendData__c object.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-04-17
 * 2013-04-17 - created
 */
public class TrendData {
	/**
	 * initiates a capture of trend data for every data field defined in TrendDataSettings__c
	 */
	public static List<QueryDetail> captureTrendData(String eventName) {
		return captureTrendData(eventName, null, null);		
	}

	/**
	 * initiates a capture of trend data. can optionally be filtered by object name and record id.
	 * if filterObjectName is not null, only fields for that object type will be captured.
	 * if filterRecordId is not null, the specified record id will be appended to the WhereClause__c value from TrendDataSettings__c.
	 */
	public static List<QueryDetail> captureTrendData(String eventName, String filterObjectName, Id filterRecordId) {
		//generate collection of data queries based on TrendDataSettings__c
		List<TrendDataSettings__c> trendDataSettings;
		if(filterObjectName == null) {
			trendDataSettings = [
				select 
					FieldName__c,
					ObjectName__c,
					WhereClause__c
				from TrendDataSettings__c
				order by ObjectName__c ASC, WhereClause__c ASC, FieldName__c ASC];
		}
		else {
			trendDataSettings = [
				select 
					FieldName__c,
					ObjectName__c,
					WhereClause__c
				from TrendDataSettings__c
				where ObjectName__c = :filterObjectName
				order by ObjectName__c ASC, WhereClause__c ASC, FieldName__c ASC];
		}

		String currentObjectName;
		List<String> currentFieldNames;
		String currentWhereClause;
		List<QueryDetail> queries = new List<QueryDetail>();
		Integer i = 0;
		for(TrendDataSettings__c setting : trendDataSettings) {
			if(i==0) {
				//initialize values on first iteration
				currentObjectName = setting.ObjectName__c;
				currentFieldNames = new List<String>();
				currentWhereClause = setting.WhereClause__c;
			}
			if(currentObjectName != setting.ObjectName__c || currentWhereClause != setting.WhereClause__c) {
				//wrap up the query we're currently building and reinitialize field list
				queries.add(new QueryDetail(currentObjectName, currentFieldNames, buildWhereClause(currentWhereClause, filterRecordId)));
				currentFieldNames = new List<String>();
			}
			currentObjectName = setting.ObjectName__c;
			currentFieldNames.add(setting.FieldName__c);
			currentWhereClause = setting.WhereClause__c;
			i++;
		}
		queries.add(new QueryDetail(currentObjectName, currentFieldNames, buildWhereClause(currentWhereClause, filterRecordId)));

		//invoke batachble data capture job for each query
		for(QueryDetail query : queries) {
			system.Debug(query.query);
			if(!test.isRunningTest()) {
				Id batchId = Database.executeBatch(new TrendDataBatchable(query.query,query.oName,query.fNames,eventName),1000);
			}
		}
		return queries;
	}

	private static String buildWhereClause(String whereClause, Id filterRecordId) {
		String filteredWhereClause;
		if(filterRecordId == null) {
			filteredWhereClause = whereClause;
		}
		else {
			if(whereClause == null) {
				filteredWhereClause = 'Id = \'' + filterRecordId + '\'';
			}
			else {
				filteredWhereClause = whereClause + ' and Id = \'' + filterRecordId + '\'';
			}
		}
		return filteredWhereClause;
	}

	public class QueryDetail {
		public String oName;
		public List<String> fNames;
		public String wClause;

		public String query {
			get {
				if(query == null) {
					if(oName != null && fNames != null && fNames.size() > 0) {
						query = 'select Id, CurrencyISOCode';
						for(String fieldName : fNames) {
							query += ', ' + fieldName;
						}
						query += ' from ' + oName;
						if(wClause != null) {
							query += ' where ' + wClause;
						}
					}
				}
				return query;
			}
			set;	
		}

		public QueryDetail(String objectName, List<String> fieldNames, String whereClause) {
			oName = objectName;
			fNames = fieldNames;
			wClause = whereClause;
		}	
	}
}