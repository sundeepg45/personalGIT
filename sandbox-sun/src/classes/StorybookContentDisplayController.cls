public with sharing class StorybookContentDisplayController {

    public Id sbId { get; set; }
    public List<ContentDocument> contentItems { get; set; }
    public List<StoryBookLink__c> linkItems { get; set; }
    public String storybookName { get; set; }
    public String selectedLanguageCode { get; set; }
    public Boolean isEmbedded { get; set; }
    public Boolean isExternalUser { get; set; }
    public Boolean hideTitle { get; set; }
    public final Map<String,List<String>> partnerStatusMap;
    public final User u { get; set; }
    final Account acc;

    public StorybookContentDisplayController() {

        sbId = apexPages.currentPage().getParameters().get('sbId');
        isEmbedded = apexPages.currentPage().getParameters().get('embedded') == 'true';
        hideTitle = apexPages.currentPage().getParameters().get('hideTitle') == 'true';
        u = CommunityTools.getUser(UserInfo.getUserId());

        isExternalUser = CommunityTools.getIsExternaluser(u);
        if(isExternalUser){
            selectedLanguageCode = CommunityTools.getLanguage(ApexPages.currentPage().getHeaders().get('Accept-Language'));
        }else{
            selectedLanguageCode = CommunityTools.getLanguage(u);
        }

        acc = CommunityTools.getAccount(u);
        partnerStatusMap = CommunityTools.getPartnerStatus(acc, u.Contact.Id, u);
        Set<Id> matchingAudienceIds = CommunityTools.getMatchingAudiences(partnerStatusMap);

        searchContent(sbId, matchingAudienceIds);
  }

  public String searchContent(String sbId, Set<Id> audiences){
        storybookName = [SELECT Name FROM Storybook__c WHERE id = :sbId].Name;
        contentItems = [SELECT Id, CreatedDate, Title, LatestPublishedVersionId, LatestPublishedVersion.CreatedDate, LatestPublishedVersion.Latest_Version_View_Count__c, LatestPublishedVersion.Language
            ,LatestPublishedVersion.Description, LatestPublishedVersion.FileType
            FROM ContentDocument
            WHERE LatestPublishedVersion.Storybook__c = :sbId
            ORDER BY LatestPublishedVersion.CreatedDate DESC];

        linkItems = [select Id, Name, URL__c
            ,(SELECT
                Label__c
                ,Language_Code__c
                ,CreatedDate
                FROM StoryBook_Link_Labels__r
                WHERE Language_Code__c = :selectedLanguageCode
            )
            FROM StoryBookLink__c
            WHERE Audience__c IN :audiences
            AND Storybook__c = :sbId
            ORDER BY CreatedDate DESC];

        return storybookName;
  }
}