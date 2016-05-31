public without sharing class CommunitiesNewsDisplayController {

    public final Map<String,List<String>> partnerStatusMap;
    public final User u { get; set; }
    final Account acc;
    public List<Communities_News_Item__c> allNewsItems { get; set; }
    public List<Communities_News_Item__c> relatedNewsItems { get; set; }
    public String selectedLanguageCode { get; set; }
    public Integer limitNumber { get; set; }
    public Boolean showMoreLink { get; set; }
    public Boolean showHeader { get; set; }
    public String viewMore { get; set; }
    public Boolean isExternalUser { get; set; }

    public CommunitiesNewsDisplayController() {

        viewMore = apexPages.currentPage().getParameters().get('allNews');

        u = CommunityTools.getUser(UserInfo.getUserId());

        // Test User Id - George Na
        //u = CommunityTools.getUser('00560000001ROuQ');

        isExternalUser = CommunityTools.getIsExternaluser(u);
        if(isExternalUser){
            selectedLanguageCode = CommunityTools.getLanguage(ApexPages.currentPage().getHeaders().get('Accept-Language'));
        }else{
            selectedLanguageCode = CommunityTools.getLanguage(u);
        }

        if(apexPages.currentPage().getParameters().get('viewMore') == 'true') {
            viewMore = 'true';
            limitNumber = 30;
            showHeader = true;
        } else {
            limitNumber = 5;
            showHeader = false;
        }

        acc = CommunityTools.getAccount(u);
        partnerStatusMap = CommunityTools.getPartnerStatus(acc, u.Contact.Id, u);
        Set<Id> matchingAudienceIds = CommunityTools.getMatchingAudiences(partnerStatusMap);
        relatedNewsItems = getRelatedNewsItems(matchingAudienceIds);
	}

    public List<Communities_News_Item__c> getRelatedNewsItems(Set<Id> audienceIds){

        List<Communities_News_Item__c> allNewsItems = [SELECT
            Id
            ,Sorting_Weight__c
            ,URL__c
            ,Publish_Date__c
            ,English_Label__c
            ,(SELECT
                Label__c
                ,Language_Code__c
                FROM Communities_News_Item_Labels__r
                WHERE Language_Code__c = :selectedLanguageCode
            )
            FROM Communities_News_Item__c
            WHERE Audience__c in :audienceIds
            AND Status__c = 'Published'
            ORDER BY
            Publish_Date__c DESC
            ,Sorting_Weight__c DESC
            ,Audience__r.Available_to_Unauthenticated_Users__c ASC
            LIMIT : limitNumber];

        return allNewsItems;
    }

}