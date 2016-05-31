public with sharing class PartnerProductListItem {
	public List<String> platforms {get; set;}
	public List<String> platformsJBoss {get; set;}
	public PartnerProduct__c product {get; set;}
	public List<Attachment> screenshots {get; set;}
	public Attachment logo {get; set; }
}