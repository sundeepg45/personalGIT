public without sharing class PPUserScorecardController {

	public String regionCode {get; set;}

    public ApexPages.StandardController controller {
        get;
        set;
    }    

    public PPUserScorecardController(ApexPages.StandardController controller) {
        this.controller = controller;
    }

	public Contact getContact() {
		if (controller.getRecord() != null && controller.getRecord().Id != null){
			regionCode = [select Account.Global_Region__c from Contact where id = :controller.getRecord().Id].Account.Global_Region__c;
		}
        return (Contact) controller.getRecord();
    }
    
    public PP_User_Points__c getUserPoints(){
    	PP_User_Points__c ppup = null;
    	
    	if ([select count() from PP_User_Points__c where Contact__c = :getContact().Id] > 0){
	    	ppup = [ 
	    		select
	    			Current_Points__c,
	    			Delivery_Points__c,
	    			PreSales_Points__c,
	    			Sales_Points__c,
	    			Expired_Points__c,
	    			Expiring_Points__c,
	    			Total_Lifetime_Points__c,
	    			Uncapped_Points__c
	    		from
	    			PP_User_Points__c
	    		where
	    			Contact__c = :getContact().Id
	    		limit 1
	    	];
    	}
    	return ppup == null ? new PP_User_Points__c(Account__r = getContact().Account, Contact__r = getContact(), Current_Points__c = 0) : ppup;
    }    
    
    public List<PP_Scores__c> getPointsList(){
    		List<PP_Scores__c> pointsList = [Select
						Id,
						Name,
						Category__c,
						Subcategory__c,
						ContentRef__c,
						Expiring_Soon__c,
						From_ID__c,
						Points__c,
						Points_Status__c,
						Partner_Track__r.Partner_Function__c,
						Partner_Track__r.Product_of_Interest__c,
						When_Earned__c
					From 
						PP_Scores__c
					Where
						Contact__c = :getContact().Id
					Order By
						Points_Status__c,
						When_Earned__c					
		];
		return pointsList;
    }
    
    public PP_Account_Points__c getAccountPoints(){
    	PP_Account_Points__c ppap = null;
    	 
    	if ([select count() from PP_Account_Points__c where Account__c = :getContact().AccountId] > 0){
    		
    		ppap = [ 
	    		select
	    			Current_Points__c,
	    			Delivery_Points__c,
	    			PreSales_Points__c,
	    			Sales_Points__c,
	    			Expired_Points__c,
	    			Expiring_Points__c,
	    			Total_Lifetime_Points__c,
	    			Total_Uncapped_Points__c
	    		from
	    			PP_Account_Points__c
	    		where
	    			Account__c = :getContact().AccountId
	    		limit 1
	    	];
    	}
    	
    	return ppap == null ? new PP_Account_Points__c(Account__r = getContact().Account, Current_Points__c = 0) : ppap;
    }
    

	public Integer getContactContribution(){
		if (getUserPoints().Current_Points__c == 0 || getAccountPoints().Current_Points__c == 0){
			return 0;
		}
		return Math.round((getUserPoints().Current_Points__c / getAccountPoints().Current_Points__c) * 100);
	}
	
    public Integer getRanking(){
    	Integer rank = -1;
    	List<AggregateResult> agl = [
    		select 
    			count_distinct( Current_Points__c ) userRank      			 
			from PP_User_Points__c 
			where 
				Account__c = :getContact().AccountId
				and IsActive__c = true
				and Current_Points__c > :getUserPoints().Current_Points__c
			];
			
		if (agl.size() > 0){
			rank = Integer.valueOf(agl.get(0).get('userRank'));
		}
				
    	return rank + 1;
    }
    
	public Integer getUserRegionalRanking(){
    	Integer rank = -1;
    	List<AggregateResult> agl = [
    		select 
    			count_distinct( Current_Points__c ) userRank  			 
			from PP_User_Points__c 
			where 
				IsActive__c = true
				and Current_Points__c > :getUserPoints().Current_Points__c
				and Account__r.IsPartner = true
				and Account__r.Finder_Partner_Type__c = :getContact().Account.Finder_Partner_Type__c
				and Account__r.Finder_Partner_Tier__c = :getContact().Account.Finder_Partner_Tier__c
				and Account__r.Global_Region__c = :regionCode
			];
		if (agl.size() > 0){
			rank = Integer.valueOf(agl.get(0).get('userRank'));
		}
				
    	return rank + 1;
    }
    
    public Pagereference processRedirect(){
        Id tmpid = ApexPages.currentPage().getParameters().get('id');
        if (tmpid == null) {
            User me = [select Contact.AccountId from User where Id = :UserInfo.getUserId()];
            PageReference pr = new PageReference('/apex/PartnerPointsUserScoreCard?id=' + me.Contact.Id);
            pr.setRedirect(true);
            return pr;
        }
    	return null;
    }
    
    public Boolean getIsNoElibilityCourseRequired(){
    	return !PPScoringUtil.getRegionEligibilityRequiredMap().get(regionCode);
    }
    
    public String getRegion(){
    	if (regionCode == 'NA'){
    		return Label.Region_NA;
    	} else if (regionCode == 'EMEA'){
    		return Label.Region_EMEA;
    	} else if (regionCode == 'LATAM'){
    		return Label.Region_LATAM;
    	}
    	
		return Label.Region_APAC;
    }
}