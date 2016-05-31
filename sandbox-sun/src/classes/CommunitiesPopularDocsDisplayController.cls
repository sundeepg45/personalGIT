public class CommunitiesPopularDocsDisplayController{

    public List<ContentDocument> documentsList {get;set;}
    public final Map<String,String> partnerStatusMap;
    public final User u {get;set;}
    public String viewMore {get;set;}
    public String selectedLanguageCode { get; set; }
    public Boolean showHeader { get; set; }
    public Integer limitNumber {get;set;}
    final Account acc;
    public Boolean isExternalUser { get; set; }

    public CommunitiesPopularDocsDisplayController() {
        u = CommunityTools.getUser(UserInfo.getUserId());

        // Test User Id - George Na
        //u = CommunityTools.getUser('00560000001ROuQ');

        if(apexPages.currentPage().getParameters().get('viewMore') == 'true') {
            viewMore = 'true';
            limitNumber = 30;
            showHeader = true;
        } else {
            limitNumber = 5;
            showHeader = false;
        }

        isExternalUser = CommunityTools.getIsExternaluser(u);
        if(isExternalUser){
            selectedLanguageCode = CommunityTools.getLanguage(ApexPages.currentPage().getHeaders().get('Accept-Language'));
        }else{
            selectedLanguageCode = CommunityTools.getLanguage(u);
        }

        documentsList = getDocumentsList();

    }

    public List<ContentDocument> getDocumentsList() {

        List<ContentDocument> documents = [SELECT Id, CreatedDate, Title, LatestPublishedVersionId, LatestPublishedVersion.CreatedDate, LatestPublishedVersion.Latest_Version_View_Count__c, LatestPublishedVersion.Language
                                           FROM ContentDocument
                                           WHERE ParentId != null AND LatestPublishedVersion.Latest_Version_View_Count__c != null
                                           AND LatestPublishedVersion.Language = :selectedLanguageCode
                                           AND IsArchived = false
                                           ORDER BY LatestPublishedVersion.Latest_Version_View_Count__c DESC LIMIT : limitNumber];
/*
        if (documents.isEmpty()) {
            documents = [SELECT Id, CreatedDate, Title, LatestPublishedVersionId, LatestPublishedVersion.CreatedDate, LatestPublishedVersion.Latest_Version_View_Count__c, LatestPublishedVersion.Language
                         FROM ContentDocument
                         WHERE ParentId != null
                         AND LatestPublishedVersion.Latest_Version_View_Count__c != null
                         AND LatestPublishedVersion.Language = 'en_US'
                         AND IsArchived = false
                         ORDER BY LatestPublishedVersion.Latest_Version_View_Count__c DESC LIMIT : limitNumber];
        }


        List<String> publishedVerdionIds = new List<String>();

        List<ContentDocument> documentList = [SELECT Id, CreatedDate, Title, LatestPublishedVersionId, LatestPublishedVersion.CreatedDate
                                              FROM ContentDocument
                                              WHERE ParentId != null
                                              ORDER BY LatestPublishedVersion.CreatedDate DESC];
        for (ContentDocument c : documentList) {
            publishedVerdionIds.add(c.LatestPublishedVersionId);
        }

        List<ContentVersionHistory> viewRecordList = [SELECT Id, ContentVersionId, Field
                                                      FROM ContentVersionHistory
                                                      WHERE Field = 'contentVersionViewed' AND ContentVersionId in : publishedVerdionIds];

        Map<Integer, List<ContentDocument>> mostPopularTest = new Map<Integer, List<ContentDocument>>();

        for (ContentDocument c : documentList) {
            for (ContentVersionHistory cvh : viewRecordList) {

                Integer viewCount = 0;
                List<ContentDocument> existingDocs = new List<ContentDocument>();

                if (c.LatestPublishedVersionId == cvh.ContentVersionId) {
					viewCount++;
                }

                if (mostPopularTest.containsKey(viewCount)) {
                    existingDocs = mostPopularTest.get(viewCount);
                    existingDocs.add(c);
                    mostPopularTest.put(viewCount, existingDocs);
                } else {
                    mostPopularTest.put(viewCount, existingDocs);
                }

            }
        }

        if (!mostPopularTest.isEmpty()) {

            List<Integer> orderKey = new List<Integer>();

            for (Integer i : mostPopularTest.keySet()) {
                orderKey.add(i);
            }

            orderKey.sort();

            for (Integer i : orderKey) {
                for (ContentDocument c : mostPopularTest.get(i)) {
                    if (documents.size() < limitNumber) {
                        documents.add(c);
                    }
                }
            }

        } */

        return documents;

    }

}