public virtual without sharing class PCProductMatch {

    public String   name        {get; private set; }
    public ID       productId   {get; private set; }
    public ID       partnerId   {get; private set; }
    public String   industry    {get; private set; }
    public String   productType {get; private set; }
    public String   partnerName {get; private set; }
    public ID       logoId      {get; private set; }
    public String[] platforms   {get; private set; }
    public String[] middleware          {get; private set; }
    public Boolean  hasJBossPlatforms   {get; private set; }
    public Boolean  hasRHELPlatforms    {get; private set; }
    public String  keywords {get; private set;}


    public PCProductMatch(PartnerProduct__c prod, ID logoAttachmentId) {
        productId = prod.ID;
        partnerId = prod.Partner__c;
        logoId = PFUtils.get(logoAttachmentId, null);
        name = prod.Full_Product_Name__c;
        keywords = prod.keywords__c;
        partnerName = prod.Partner__r.Name;
        hasJBossPlatforms = 'True' == prod.JBoss_Platforms_Supported__c;
        hasRHELPlatforms = 'True' == prod.RHEL_Platforms_Supported__c;
        if (PFUtils.isEmpty(prod.Software_Category__c)) {
            productType = null;
        }
        else {
            productType = prod.Software_Category__c;
        }

        platforms = PFUtils.get(prod.Platforms__c);
        middleware = PFUtils.get(prod.JBoss_Platform__c);
    }

    public String getPlatformString() {
        return PartnerUtil.joinArray(platforms, ',');
    }

    public String getMiddlewareString() {
        return PartnerUtil.joinArray(middleware, ',');
    }

}