public with sharing class PartnerPointsCatalogController {

	public PP_Catalog__c[] catalogList { get; set; }

	public String commandManageId {get; set; }
	
	ApexPages.StandardSetController setCon;

	public PartnerPointsCatalogController(ApexPages.StandardController controller) {
		// Not used	
	}
	
	public PartnerPointsCatalogController(ApexPages.StandardSetController controller) {
		setCon = controller;		
		catalogList = [
			select		Id, Name, Category__c, Global_Region__c, Description__c
			from		PP_Catalog__c
			order by	Global_Region__c, Category__c
		];
	}

	public PageReference manageButton() {
		PPScoringPlugin plugin = null;
		for (PP_Catalog__c cat : catalogList) {
			if (cat.Id == commandManageId) {
				plugin = PPFactory.getPlugin(cat.Category__c);
				break;
			}
		}		
		System.assert(plugin != null, 'Plugin not available for category ' + commandManageId);
		return plugin.getAdminUI();
	}
	
}