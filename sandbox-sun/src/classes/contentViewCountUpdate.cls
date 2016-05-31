global class contentViewCountUpdate implements Schedulable{

    List<ContentVersion> documentList = new List<ContentVersion>();
    List<ContentVersionHistory> viewRecordList = new List<ContentVersionHistory>();
    Map<String, Integer> viewCountMap = new Map<String, Integer>();
    Map<String, ContentVersion> versionMap = new Map<String, ContentVersion>();
    Set<String> contentVersionIds = new Set<String>();

    global void execute(SchedulableContext sc) {
    	run();
    }

    public void run() {

        CommUtils__c lastRun = [SELECT Last_Run__c FROM CommUtils__c WHERE Name = 'viewCountLastRun'];

        if (Test.isRunningTest()) {
            viewRecordList = [SELECT Id, ContentVersionId, ContentVersion.Latest_Version_View_Count__c, CreatedDate, Field, ContentVersionHistory.CreatedBy.Profile.Name
                              FROM ContentVersionHistory
                              WHERE Field = 'contentVersionViewed'
                              AND CreatedDate > : lastRun.Last_Run__c
                              AND ContentVersionHistory.CreatedBy.Profile.Name LIKE '%Partner%' limit 200];
        }
        else {
            viewRecordList = [SELECT Id, ContentVersionId, ContentVersion.Latest_Version_View_Count__c, CreatedDate, Field, ContentVersionHistory.CreatedBy.Profile.Name
                              FROM ContentVersionHistory
                              WHERE Field = 'contentVersionViewed'
                              AND CreatedDate > : lastRun.Last_Run__c
                              AND ContentVersionHistory.CreatedBy.Profile.Name LIKE '%Partner%'];
        }
        for (ContentVersionHistory vh : viewRecordList) {

            contentVersionIds.add(vh.ContentVersionId);

            if (viewCountMap.containsKey(vh.ContentVersionId)) {
            	Integer newCount = viewCountMap.get(vh.ContentVersionId) + 1;
                viewCountMap.put(vh.ContentVersionId, newCount);
            } else {
                viewCountMap.put(vh.ContentVersionId, 1);
            }

        }

        if (!viewCountMap.isEmpty()) {

            List<ContentVersion> contentVersionList = [SELECT Id, Latest_Version_View_Count__c
                                      				   FROM ContentVersion
                                                       WHERE Id in : contentVersionIds AND IsLatest = True];

            for (ContentVersion c : contentVersionList) {
                versionMap.put(c.Id, c);
            }

            if (!versionMap.isEmpty()) {

                List <String> viewCountList = new List<String>();
                Set<String> viewCountSet = viewCountMap.keySet();

                for (String s : viewCountSet) {
                    viewCountList.add(s);
                }

                for (Integer i = 0; viewCountList.size() > i; i++) {
                    if (versionMap.containsKey(viewCountList.get(i))) {
                        if (versionMap.get(viewCountList.get(i)).Latest_Version_View_Count__c == null) {
                        	versionMap.get(viewCountList.get(i)).Latest_Version_View_Count__c = viewCountMap.get(viewCountList.get(i));
                        } else {
                            versionMap.get(viewCountList.get(i)).Latest_Version_View_Count__c += viewCountMap.get(viewCountList.get(i));
                        }
                        documentList.add(versionMap.get(viewCountList.get(i)));
                    }
                }
                lastRun.Last_Run__c = System.now();
                if(!test.isRunningTest()){
                    update lastRun;
                    update documentList;
                }
            }

        }

    }

}