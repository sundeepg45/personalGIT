public with sharing class CommunitiesStorybookDisplayController {

    public final Map<String,List<String>> partnerStatusMap;
    public final User u { get; set; }
    final Account acc;
    public String selectedLanguageCode { get; set; }
    public Boolean isEmbedded { get; set; }
    public String pageName {get; set;}    
    public String storybookName { get; set; }
    public List<Storybook__c> storybooks { get; set; }

    public CommunitiesStorybookDisplayController() {

        isEmbedded = apexPages.currentPage().getParameters().get('embedded') == 'true';
		selectedLanguageCode = apexPages.currentPage().getParameters().get('language');
        if(selectedLanguageCode == null || selectedLanguageCode == '')selectedLanguageCode = 'en_US';
		
        // The site.com page name requesting this widget (used to filter content)
        if(ApexPages.currentPage().getParameters().get('page') != null)
        	pageName = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('page'));
        
        u = CommunityTools.getUser(UserInfo.getUserId());

        // Test User Id - George Na
        //u = CommunityTools.getUser('00560000001ROuQ');

        acc = CommunityTools.getAccount(u);
        partnerStatusMap = CommunityTools.getPartnerStatus(acc, u.Contact.Id, u);
        Set<Id> matchingAudienceIds = CommunityTools.getMatchingAudiences(partnerStatusMap);
        storybooks = getRelatedStorybooks(matchingAudienceIds);

	}

    public List<Storybook__c> getRelatedStorybooks(Set<Id> audienceIds){

        
        // Filter the stories based on the current page the user is on.
        string qry = 'SELECT Name, Id, Display_Image_URL__c, Publish_Date__c FROM Storybook__c ' + 
                     'WHERE ' + 
            	     'Audience__c in :audienceIds ' + 
                     'AND Status__c=\'Published\' ' +  
                     'AND Language_Code__c = :selectedLanguageCode ';
        if(!String.isEmpty(pageName))
            qry += 'AND Site_com_Page__c INCLUDES(:pageName) '; 
            
        qry += 'ORDER BY Publish_Date__c DESC';
        List<Storybook__c> relatedStorybooks = Database.query(qry);
        return relatedStorybooks;
    }


}