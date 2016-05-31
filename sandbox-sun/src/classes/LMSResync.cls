public with sharing class LMSResync {

    public String fileName {get; set;}
    public String contentType {get; set;}
    public String userId {get; set;}
    public List<SumTotal_Request__c> requests {get; private set;}
    public transient Blob file {get; set;}
    private static Set<String> contentTypesAllowed = new Set<String>{'text/csv'};
    private List<Id> ids;

    public LMSResync() {
        requests = new List<SumTotal_Request__c>();
        updateRequests();
    }

    private boolean isValidContentType(String contentType) {
        return contentTypesAllowed.contains(contentType);
    }

    public PageReference submit() {
        ids = new List<Id>();
        if (contentType != null && !isValidContentType(contentType)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, fileName + ' is an invalid file type.'));
            return null;
        }

        try {
            List<Map<String, String>> processedCSV = CSVReader.process(file);
            for (Map<String, String> currentMap : processedCSV) {
                Set<String> keySet = currentMap.keySet();
                for (String key : keySet) {
                    ids.add(currentMap.get(key));
                }
            }
            if (!String.isEmpty(userId)) {
                ids.add(userId);
            }
        } catch (Exception e) {
            ApexPages.addMessages(e);
            return null;
        }

        if (ids.size() > 0) {
            STConnector.enqueue(ids, STConnector.ACTION_REFRESH_CERTS);
        }

        return updateRequests();
    }

    public PageReference updateRequests() {
        List<SumTotal_Request__c> latestRequests = [
            select      CreatedById,
                        Name,
                        Action__c,
                        CompleteTime__c,
                        Status__c,
                        Status_Message__c,
                        SubmitTime__c,
                        User__c,
                        User__r.Name
            from        SumTotal_Request__c
            where       Action__c = :STConnector.ACTION_REFRESH_CERTS
            order by    SubmitTime__c desc
            limit       100
        ];

        requests.clear();
        if (latestRequests != null && latestRequests.size() > 0) {
            requests = latestRequests;
        }

        return null;
    }

    public PageReference deleteResyncRequests() {
        List<SumTotal_Request__c> latestRequests = [
            select      Id
            from        SumTotal_Request__c
            where       Action__c = :STConnector.ACTION_REFRESH_CERTS
        ];

        if (latestRequests != null && latestRequests.size() > 0) {
            delete latestRequests;
        }

        return updateRequests();
    }
}