/**
 * Test class providing coverage for TrendData, TrendDataBatchable, and TrendDataSchedulable
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-06-19
 * 2013-04-19 - created
 * 2013-06-19 - added additional required fields to test strategic plan
 */
@isTest
private class TrendDataTest {

	static void populateSettings() {
		List<TrendDataSettings__c> settings = new List<TrendDataSettings__c>();
    	settings.add(new TrendDataSettings__c(
    					Name='StrategicPlan.NumberOfSolutions',
    					ObjectName__c='StrategicPlan__c',
    					FieldName__c='NumberOfSolutions__c'));
     	settings.add(new TrendDataSettings__c(
    					Name='StrategicPlan.NumberOfStrategies',
    					ObjectName__c='StrategicPlan__c',
    					FieldName__c='NumberOfStrategies__c'));
      	settings.add(new TrendDataSettings__c(
    					Name='StrategicPlan.TotalOpportunityAmount',
    					ObjectName__c='StrategicPlan__c',
    					FieldName__c='TotalOpportunityAmount__c'));
      	settings.add(new TrendDataSettings__c(
    					Name='StrategicPlan.Name',
    					ObjectName__c='StrategicPlan__c',
    					FieldName__c='Name',
    					WhereClause__c='Name=\'Test1234567890\''));
      	settings.add(new TrendDataSettings__c(
    					Name='Opportunity.Name',
    					ObjectName__c='Opportunity',
    					FieldName__c='Name',
    					WhereClause__c='Name=\'Test1234567890\''));
    	insert settings;
	}

	static Account account {
		get {
			if(account == null) {
				account = new Account(
					Name='Test account');
				insert account;
			}
			return account;
		}
		set;
	}
	
	static Account_Profile__c accountProfile {
		get {
			if(accountProfile == null) {
				accountProfile = new Account_Profile__c(
					Name='Test Profile',
					Account__c=account.Id);
				insert accountProfile;
			}
			return accountProfile;
		}
	}

	public static StrategicPlan__c strategicPlan {
		get {
			if(strategicPlan == null) {
				strategicPlan = new StrategicPlan__c(
					Name='Test1234567890',
					Account__c = account.Id,
					AccountProfile__c = accountProfile.Id,
					OwnerId = UserInfo.getUserId(),
					Status__c = 'Draft');
				insert strategicPlan;
			}
			return strategicPlan;
		}
		set;
	}

	@isTest
    static void captureTrendDataTest() {
    	//populate TrendDataSettings__c custom setting with test data
    	populateSettings();
    	//call captureTrendData()
    	List<TrendData.QueryDetail> queries = TrendData.captureTrendData('Test Class Run');
    	System.assertEquals(3, queries.size());
    	System.assertEquals('select Id, CurrencyISOCode, Name from Opportunity where Name=\'Test1234567890\'', queries[0].query);
    	System.assertEquals('select Id, CurrencyISOCode, NumberOfSolutions__c, NumberOfStrategies__c, TotalOpportunityAmount__c from StrategicPlan__c', queries[1].query);
    	System.assertEquals('select Id, CurrencyISOCode, Name from StrategicPlan__c where Name=\'Test1234567890\'', queries[2].query);
    	//test filtering parameters
    	queries = TrendData.captureTrendData('Test Class Run', 'StrategicPlan__c', '005000000000000000');
    	System.assertEquals(2, queries.size());
    	System.assertEquals('select Id, CurrencyISOCode, NumberOfSolutions__c, NumberOfStrategies__c, TotalOpportunityAmount__c from StrategicPlan__c where Id = \'005000000000000000\'', queries[0].query);
    	System.assertEquals('select Id, CurrencyISOCode, Name from StrategicPlan__c where Name=\'Test1234567890\' and Id = \'005000000000000000\'', queries[1].query);
    }
 
 	@isTest
 	static void batchableExecuteTest() {
 		populateSettings();
 		StrategicPlan__c plan = strategicPlan;
 		Test.StartTest();
 		List<TrendData.QueryDetail> queries = TrendData.captureTrendData('Test Class Run');
 		TrendDataBatchable trendDataBatch = new TrendDataBatchable(queries[2].query,queries[2].oName,queries[2].fNames,'Test Class Run');
 		Id batchProcessId = Database.executeBatch(trendDataBatch);
 		Test.StopTest();
 		List<TrendData__c> capturedData = [select ObjectName__c, FieldName__c, FieldValue__c, TimeStamp__c from TrendData__c];
 		System.assertEquals(1, capturedData.size());
 		System.assertNotEquals(null, capturedData[0].TimeStamp__c);
 		System.assertEquals('StrategicPlan__c', capturedData[0].ObjectName__c);
 		System.assertEquals('Name', capturedData[0].FieldName__c);
 		System.assertEquals('Test1234567890', capturedData[0].FieldValue__c);
 	}
 
 	@isTest
 	static void schedulableExecuteTest() {
		Test.StartTest();
		TrendDataSchedulable schedulableWrapper = new TrendDataSchedulable('Test Class Run');
		SchedulableContext sc;
		schedulableWrapper.execute(sc);
		Test.StopTest();
 	}
}