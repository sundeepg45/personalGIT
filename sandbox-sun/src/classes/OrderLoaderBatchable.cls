/**
 * This class runs matching logic on Opportunity Staging records created by the Order Loader tool.
 *
 * @version 2015-07-10
 * @author Scott Coleman <scoleman@redhat.com>
 * 2015-07-10 - Added contructor that supports querying staging records by a unique batch id
 * 2015-02-25 - Created
 */
global class OrderLoaderBatchable implements Database.Batchable<sObject> {
    
    String query;
    
    global OrderLoaderBatchable(Id UserId, Datetime BatchStartDate) {
        query = 'SELECT Id, Status__c from Opportunity_Header_Staging__c WHERE OwnerId = \'' + UserId + '\' AND CreatedDate >= ' + BatchStartDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        System.debug('+++ ' + query);
        this.query = query;
    }

    global OrderLoaderBatchable(String BatchId) {
        query = 'SELECT Id, Status__c from Opportunity_Header_Staging__c WHERE Batch_ID__c = \'' + BatchId + '\'';
        System.debug('+++ ' + query);
        this.query = query;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id, Opportunity_Header_Staging__c> headerStagingMap = new Map<Id, Opportunity_Header_Staging__c>();

        for(sObject obj : scope) {
            Opportunity_Header_Staging__c headerStaging = (Opportunity_Header_Staging__c)obj;
            if(headerStaging.Status__c == null) {
                headerStaging.Status__c = 'Error';
                headerStaging.Order_Status__c = 'BOOKED';
                headerStagingMap.put(headerStaging.Id, headerStaging);
            }
        }

        Database.Update(headerStagingMap.values(), false);

        OrderLoaderMatching.processOrders(headerStagingMap.keySet());
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
}