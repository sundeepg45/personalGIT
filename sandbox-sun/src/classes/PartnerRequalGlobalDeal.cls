//
// Used as a data buck for summarizing deal registrations by global region
//
public with sharing class PartnerRequalGlobalDeal {
	public String region {get; set; }
	public Double amount {get; set; }
}