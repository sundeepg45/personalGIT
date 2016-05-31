public without sharing class PCProductDetailsMatch extends PCProductMatch  {

    public String   callToAction 		{get; private set; }
    public String   distLicensing 		{get; private set; }
    public String   pricingSupport 		{get; private set; }
    public String   details 			{get; private set; }
    public String   summary 			{get; private set; }
    public String   softwareCategory	{get; private set; }
    public String   website 			{get; private set; }
    public String   moreInfoLink		{get; private set; }
    public String   moreInfoLinkText	{get; private set; }
    public String   sourceLicensing 	{get; private set; }
    public String   successStory 		{get; private set; }
    public String   usageLicensing 		{get; private set; }
    public ID		logoId 				{get; private set; }
    public ID[]		screenshotIdList	{get; private set; }
    public String	industryFocus		{get; private set; }
    public String[]	jbossPlatforms		{get; private set; }
    public String[]	languages			{get; private set; }
    public String[]	platforms			{get; private set; }
    public String[] rhev                {get; private set; }
    public String[] rhos                {get; private set; }


    public PCProductDetailsMatch(PartnerProduct__c prod, ID logoAttachmentId, PartnerProductScreenshot__c[] screenshots) {
        super(prod, logoAttachmentId);

        callToAction = PFUtils.get(prod.Call_To_Action_Text__c, null);
        distLicensing = PFUtils.get(prod.Distribution_Licensing__c, '');
        pricingSupport = PFUtils.get(prod.Pricing_And_Support_Details__c, null);
        details = PFUtils.get(prod.Product_Details__c, '');
        summary = PFUtils.get(prod.ProductSummary__c, '');
        website = PFUtils.get(prod.Application_Website__c, null);
        if (website != null && website.startsWith('http://') == false) {
        	website = 'http://' + website;
        }
        moreInfoLink = PFUtils.get(prod.Product_URL_2__c, null);
        if (moreInfoLink != null && moreInfoLink.startsWith('http://') == false) {
        	moreInfoLink = 'http://' + moreInfoLink;
        }
        moreInfoLinkText = PFUtils.get(prod.Product_URL_2_Info__c, null);
        sourceLicensing = PFUtils.get(prod.Source_Licensing__c, '');
        successStory = PFUtils.get(prod.Success_Story__c, null);
        usageLicensing = PFUtils.get(prod.Usage_Licensing__c, '');
        industryFocus = PFUtils.get(prod.Industry_Focus__c, null);
        jbossPlatforms = PFUtils.get(prod.JBoss_Platform__c);
        languages = PFUtils.get(prod.Language__c);
        platforms = PFUtils.get(prod.Platforms__c);
        rhev = PFUtils.get(prod.Enterprise_Virtualization__c);
        rhos = PFUtils.get(prod.OpenStack_Platform__c);
        if (PFUtils.isEmpty(prod.Software_Category__c)) {
            softwareCategory = null;
        }
        else {
            softwareCategory = prod.Software_Category__c;
        }
       	screenshotIdList = new List<ID>();
        if (!PFUtils.isEmpty(screenshots)) {
        	for (PartnerProductScreenshot__c ss : screenshots) {
				for (Attachment a :  ss.Attachments) {
        			screenshotIdList.add(a.Id);
        			System.debug('[PC]-------------------------- screen id=' + a.Id);
				}
        	}
        }
        logoId = logoAttachmentId;
		System.debug('[PC]-------------------------- logo id=' + logoId);
    }
}