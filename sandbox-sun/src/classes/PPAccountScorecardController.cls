public without sharing class PPAccountScorecardController {

	public String regionCode {get; set;}

    public ApexPages.StandardController controller {
        get;
        set;
    }

    public PPAccountScorecardController(ApexPages.StandardController controller) {
        this.controller = controller;
    }

	public Account getAccount() {
		if (controller.getRecord() != null && controller.getRecord().Id != null){
			regionCode = [select Global_Region__c from Account where id = :controller.getRecord().Id].Global_Region__c;
		}
        return (Account) controller.getRecord();
    }
    
    public PP_Account_Points__c getAccountPoints(){
    	PP_Account_Points__c ppap = null;
    	if ([select count() from PP_Account_Points__c where Account__c = :getAccount().Id] > 0){
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
	    			Account__c = :getAccount().Id
	    		limit 1
	    	];
    	}
    	return ppap == null ? new PP_Account_Points__c(Account__r = getAccount(), Current_Points__c = 0) : ppap;
    }
    
    public List<PP_User_Points__c> getPartnerContacts(){
    	List<PP_User_Points__c> pointsUsers = [
    		select 
    			Contact__r.Name,
    			Current_Points__c   			 
			from PP_User_Points__c 
			where 
				Account__c = :getAccount().Id
				and IsActive__c = true
			order by
				Current_Points__c desc,
				Contact__r.Name asc
		];
				
		return pointsUsers;
    }    
    
    public Integer getRanking(){
    	Integer rank = -1;
    	List<AggregateResult> agl = [
    		select 
    			count_distinct( Current_Points__c ) userRank	 
			from PP_Account_Points__c 
			where 
				Account__r.IsPartner = true
				and Current_Points__c > :getAccountPoints().Current_Points__c
				and Account__r.Finder_Partner_Type__c = :getAccount().Finder_Partner_Type__c
				and Account__r.Finder_Partner_Tier__c = :getAccount().Finder_Partner_Tier__c
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
            PageReference pr = new PageReference('/apex/PartnerPointsAccountScoreCard?id=' + me.Contact.AccountId);
            pr.setRedirect(true);
            return pr;
        }
    	return null;
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