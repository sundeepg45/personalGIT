public without sharing class CommunitiesFeaturedHeadlinesController {

	final Map<String,List<String>> partnerStatusMap;
    final User u { get; set; }
    public final Account acc {get; set; }
	private string pageName;
    public Communities_Featured_Headline__c headline { get; set; }

    public String selectedLanguageCode { get; set; }


	public CommunitiesFeaturedHeadlinesController() {

		u = CommunityTools.getUser(UserInfo.getUserId());

		// Test User Id - George Na
        //u = CommunityTools.getUser('00560000001ROuQ');
		if(ApexPages.currentPage().getParameters().get('page') != null)
        	pageName = String.escapeSingleQuotes( ApexPages.currentPage().getParameters().get('page'));

        selectedLanguageCode = apexPages.currentPage().getParameters().get('language');
        if(selectedLanguageCode == null || selectedLanguageCode == ''){
            selectedLanguageCode = CommunityTools.getLanguage(u);
        }

        acc = CommunityTools.getAccount(u);
        partnerStatusMap = CommunityTools.getPartnerStatus(acc, u.Contact.Id, u);
        Set<Id> matchingAudienceIds = CommunityTools.getMatchingAudiences(partnerStatusMap);

        headline = getHeadline(matchingAudienceIds);

	}

	public Communities_Featured_Headline__c getHeadline(Set<Id> audienceIds){

        String qry = 'SELECT Id ,HTML_Value__c ,Button_URL__c,Publish_Date__c,Include_Button__c ' +
			',(SELECT Id,Headline_Label__c,Language_Code__c,Button_Label__c FROM Communities_Featured_Headline_Labels__r WHERE Language_Code__c = :selectedLanguageCode) ' +
            'FROM Communities_Featured_Headline__c ' +
            'WHERE Status__c = \'Published\'' +
            'AND Audience__c in :audienceIds ';

        if(!String.isEmpty(pageName))
            qry += 'AND Site_com_Page__c INCLUDES(:pageName) ';

        qry += 'ORDER BY Publish_Date__c DESC LIMIT 1';

		List<Communities_Featured_Headline__c> headlineResults = ((List<Communities_Featured_Headline__c>)Database.query(qry));

        if(headlineResults.isEmpty())
            return null;
        else
        	return headlineResults[0];

    }

}