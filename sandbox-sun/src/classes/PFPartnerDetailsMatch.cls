public without sharing class PFPartnerDetailsMatch extends PFPartnerMatch {
	public String[]		appTypes {get; private set; }
	public String		description {get; private set; }
	public String[]		hardwareFocus {get; private set; }
	public String[]		hardwarePlatform {get; private set; }
	public String[]		industryFocus {get; private set; }
	public String[]		middleware {get; private set; }
	public String[]		supportedOs {get; private set; }
	public String		ownershipType {get; private set; }
	public String[]		softwareFocus {get; private set; }
	public String[]		countriesOfOperation {get; private set; }
	public String[]		targetMarketSize {get; private set; }
	public String       displayWebsite {get; private set; }
	public String       companyEmail {get; private set; }
	public Integer		productCount {get; private set; }
	public Integer		techCertCount {get; private set; }
	public Integer		salesCertCount {get; private set; }
	public Partner_Location__c[]	locations {get; private set; }


	public PFPartnerDetailsMatch(Account acct, Partner_Location__c[] loclist, Id theLogo, Partner_Location__c primLoc, Integer prodCount) {
		super(acct, theLogo, primLoc, null);

		description = acct.Description_of_Business__c;
		targetMarketSize = PFUtils.get(acct.Target_Market_Size__c);
		appTypes = PFUtils.get(acct.Application_Types__c);
		hardwareFocus = PFUtils.get(acct.Hardware_Focus__c);
		hardwarePlatform = PFUtils.get(acct.Hardware_Platform__c);
		industryFocus = PFUtils.get(acct.Industry_Focus__c);
		middleware = PFUtils.get(acct.Middleware_Supported__c);
		supportedOs = PFUtils.get(acct.Operating_System_Supported__c);
		ownershipType = PFUtils.get(acct.Ownership_Type__c, '');
		softwareFocus = PFUtils.get(acct.Software_Focus__c);
		countriesOfOperation = PFUtils.get(acct.Additional_Countries_of_Operation__c);
		companyEmail = PFUtils.get(acct.Company_Email_Address__c, null);
		if (!String.isEmpty(website)) {
			displayWebsite = website.replace('http://', '').replace('https://', '');
		}

		salesCertCount = acct.Total_Partner_Sales_Certifications__c ==  null ? 0 : System.math.round(acct.Total_Partner_Sales_Certifications__c);
		techCertCount = acct.Total_Partner_Technical_Certifications__c ==  null ? 0 : System.math.round(acct.Total_Partner_Technical_Certifications__c);

		locations = loclist;
		productCount = prodCount;
	}

}