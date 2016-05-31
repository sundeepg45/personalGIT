public with sharing class PPAdminOverrideController {

	public PPFactory factory {
		get;
		set;
	}
	
	public List<Contact> userSearchResults {
		get;
		set;
	}

	public List<PPSearchResult> itemSearchResults {
		get;
		set;
	}

	public String userSearchValue {
		get;
		set;
	}

	public String itemSearchValue {
		get;
		set;
	}

	public PPScoringPlugin currentPlugin {
		get;
		set;
	}
	
	public Contact currentContact {
		get;
		set;
	}
	
	public List<PP_Scores__c> pointsList {
		get;
		set;
	}

	public PPAdminOverrideController(){
		factory = new PPFactory();
	}
	
	private void loadContact(Id ContactId){
		currentContact = [Select
							Id,
							Name,
							Account.Id,
							Account.IsPartner,
							Account.Name,
							Account.Global_Region__c,
							Account.Finder_Partner_Tier__r.Name,
							Account.Finder_Partner_Type__r.Name,
							Point_Accrual_Start__c
						From 
							Contact
						Where
							Id = :ContactId
		];
		
		pointsList = [Select
						Id,
						Name,
						Category__c,
						Subcategory__c,
						ContentRef__c,
						Expiring_Soon__c,
						From_ID__c,
						Points__c,
						Points_Status__c,
						When_Earned__c
					From 
						PP_Scores__c
					Where
						Contact__c = :ContactId
					Order By
						Points_Status__c,
						When_Earned__c					
		];
	}
	
		
	public List<String> getPointsCategories(){
		List<String> names = new List<String>();
		
		List<PPScoringPlugin> l = factory.getPluginList();
		for (PPScoringPlugin ppsp : l){
			names.add(ppsp.getName());
		}
		
		return names;
	}

	public Pagereference deleteScore(){
		if (getParam('scoreId') != null){
			PP_Scores__c score = new PP_Scores__c(Id=Id.valueOf(getParam('scoreId')));
			delete score;
			loadContact(currentContact.Id);
		}
		return null;
	}
	
	public Pagereference addScore(){
		itemSearchResults = null;
		itemSearchValue = null;
		currentPlugin = null;
		return Page.PartnerPointsAdminOverrideFindPoints;
	}
	
	public Pagereference backToSearchResults(){
		return Page.PartnerPointsAdminOverride;
	}

	public Pagereference selectContact(){
		if (getParam('contactId') != null){
			loadContact(Id.valueOf(getParam('contactId')));
			List<Contact> contacts = new List<Contact>();
			if (!PPScoringUtil.isEligible(currentContact, DateTime.now(), contacts)){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '"' + currentContact.Name + '" is not eligible to receive points until he/she takes the appropriate course in their region.'));			
				return null;
			}
		}

		return Page.PartnerPointsAdminOverrideUserScoreCard;
	}
	
	public Pagereference checkContactSet(){
		if (getParam('contactId') == null && currentContact == null){
			return Page.PartnerPointsAdminOverride;
		}
		return null;
	}

	public Pagereference selectSubSystem(){
		if (getParam('system') != null){
			List<PPScoringPlugin> l = factory.getPluginList();
			for (PPScoringPlugin ppsp : l){
				if (getParam('system').equals(ppsp.getName())){
					currentPlugin = ppsp;
					itemSearchResults = null;
					itemSearchValue = null;
					break;
				}
			}
		}
		return Page.PartnerPointsAdminOverrideFindPoints;
	}

	public Pagereference doItemSearch(){
		Map<String, PPSearchResult> resultsMap = new Map<String, PPSearchResult>();
		itemSearchResults = currentPlugin.findScoredItems(itemSearchValue);
		
		List<PP_Scores__c> userScores = [Select 
											From_ID__c 
										from 
											PP_Scores__c 
										where 
											Contact__c = :currentContact.Id 
		];
		Set<String> usedId = new Set<String>();
		for(PP_Scores__c pps : userScores){
			String shortId = pps.From_ID__c; 
			if (pps.From_ID__c.length() > 15){
				shortId = pps.From_ID__c.substring(0,15);
			}
			usedId.add(shortId);
		}
			
		for (PPSearchResult ppsr : itemSearchResults){
			String shortId = ppsr.scoringFromId;
			if (ppsr.scoringFromId.length() > 15){
				shortId = ppsr.scoringFromId.substring(0,15);
			}
			System.debug('Adding with shortId = ' + shortId);
			
			if (usedId.contains(shortId)){
				ppsr.used = true;
			}
			
			resultsMap.put(shortId, ppsr);
		}
		
		return null;
	}

	public Pagereference addItem(){
		if (getParam('itemId') != null){
			PP_Scores__c score = currentPlugin.scoreSingle(currentContact, Id.valueOf(getParam('itemId')));

			if (score != null) {
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Item was added successfully with value of ' + score.Points__c + '.'));
				itemSearchResults = null;
				itemSearchValue = null;
				currentPlugin = null;
			} else {
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Item failed to be added.'));
			}
			
			loadContact(currentContact.Id);
		}
		return selectContact();
	}
		
	public Pagereference doUserSearch(){
		userSearchResults = new List<Contact>(); 

		if (userSearchValue == null || userSearchValue.length() < 2){			
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Your search must be at minimum 2 characters.'));
			return null;
		}
		List<List<SObject>> searchList = [
			find 
				:userSearchValue 
			in all fields
			returning 
				Contact (
					Id, 
					Name, 
					Account.Id, 
					Account.Name, 
					Account.Global_Region__c,
					Account.Finder_Partner_Tier__r.Name, 
					Account.Finder_Partner_Type__r.Name
					where Account.IsPartner = true
					limit 150
				)
		];
		userSearchResults = ((List<Contact>)searchList[0]);
		
		return null;
	}
	
    public static String getParam(String name) {
        return ApexPages.currentPage().getParameters().get(name);
    }
    
    static testmethod void simpleTest() {
    	Account a = PartnerTestUtils.makeAccount('PPAdminOverrideTestAccount', PartnerTestUtils.getAdminUser());
    	Contact c = PartnerTestUtils.makeContact(a.Id, 'PPAdminOverrideTestContact');
    	insert c;
    	PPAdminOverrideController aoc = new PPAdminOverrideController();
    	aoc.userSearchValue = 'test';
    	aoc.doUserSearch();
    	aoc.backToSearchResults();
    	aoc.addScore();
    	ApexPages.currentPage().getParameters().put('contactId', c.Id);
    	aoc.selectContact();
    	List<String> pc = aoc.getPointsCategories();
    	ApexPages.currentPage().getParameters().put('system', pc.get(0));
    	aoc.selectSubSystem();
    	aoc.itemSearchValue = 'test';
    	aoc.doItemSearch();
    	
	}

}