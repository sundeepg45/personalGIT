public with sharing class CommuntiesDocsDisplayController{

    public List<ContentDocument> documentsList {get;set;}
    public final Map<String,String> partnerStatusMap;
    public final User u {get;set;}
    public String viewMore {get;set;}
    public String selectedLanguageCode { get; set; }
    public Boolean showHeader { get; set; }
    public Integer limitNumber {get;set;}
    final Account acc;
    public Boolean isExternalUser { get; set; }

    public CommuntiesDocsDisplayController() {

        u = CommunityTools.getUser(UserInfo.getUserId());

        // Test User Id - George Na
        //u = CommunityTools.getUser('00560000001ROuQ');

        if (apexPages.currentPage().getParameters().get('viewMore') == 'true') {
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
        //acc = CommunityTools.getAccount(u);
        //partnerStatusMap = CommunityTools.getPartnerStatus(acc, u.Contact.Id);
        //Set<Id> matchingAudienceIds = CommunityTools.getMatchingAudiences(partnerStatusMap);
        documentsList = getDocumentsList(); //getDocumentsList(matchingAudienceIds, viewMore);

	}

    public List<ContentDocument> getDocumentsList() {

        List<ContentDocument> deDupe = new List<ContentDocument>();
        Set<String> libraries = new Set<String>();
        //User us = [SELECT Id, LanguageLocaleKey FROM User WHERE Id = : UserInfo.getUserId()];

        //if (audienceIds.size() > 0) {

         /* for (Communities_Document__c c : [SELECT Id, Selected_Audiences__c, Selected_Libraries__c FROM Communities_Document__c]) {
                for (String s : c.Selected_Audiences__c.split(';')) {
                    if (audienceIds.contains(s)) {
                        for (String l : c.Selected_Libraries__c.split(';')) {
                            libraries.add(l);
                        }
                    }
                }
            } */

            //if (libraries.size() > 0) {

                List<ContentDocument> documents = [SELECT Id, CreatedDate, Title, LatestPublishedVersion.CreatedDate
                                                   FROM ContentDocument WHERE ParentId != null
                                                   AND LatestPublishedVersion.Language = :selectedLanguageCode
                                                   AND IsArchived = false
                                                   ORDER BY LatestPublishedVersion.CreatedDate DESC LIMIT : limitNumber];
                    //[SELECT Id, CreatedDate, Title, LatestPublishedVersion.CreatedDate FROM ContentDocument WHERE ParentId in : libraries ORDER BY LatestPublishedVersion.CreatedDate DESC LIMIT : limitNumber];

             /* for (ContentDocument c : documents) {

                    Boolean duplicate = false;

                    for (ContentDocument d : deDupe) {

                        if (c.Id == d.Id) {
                            duplicate = true;
                        }

                	}

                    if (duplicate == false) {
                        deDupe.add(c);
                    }
                } */

            //}

        //}

        return documents;  //return deDupe();

    }

}