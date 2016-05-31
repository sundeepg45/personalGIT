public with sharing class RequalificationMetDashController {

    public Account account;
    public PartnerStatus__c partnerStatus;
    public Classification__c partnerType;
    public Classification__c partnerTier;
    public List<Customer_Reference__c>  expiredCustRefs {get; private set; }
    public List<Customer_Reference__c>  activeCustRefs {get; private set; }
    public String globalRegion {get; private set; }
    public static MetVsSetRequirements mvsr { get; set; }
    public SFDC_Channel_Account_Plan__c businessPlan {get; private set; }
    public boolean isSpecialized { get; private set; }
    public double exchangeRate { get; private set; }
    public CurrencyType currencyExchange { get; private set; }
    public List<String> specList { get; private set; }

    public Map<String,List<PartnerTraining__c>> sortedCertifications { get; set; }

    public List<PartnerTraining__c> techCerts { get; private set; }
    public List<PartnerTraining__c> salesEngineerCerts {get; private set; }
    public List<PartnerTraining__c> salesCerts {get; private set; }
    public List<PartnerTraining__c> deliveryCerts { get; private set; }

    public List<PartnerTraining__c> salesMiddleware { get; private set; }
    public List<PartnerTraining__c> salesCloud { get; private set; }
    public List<PartnerTraining__c> salesDCI { get; private set; }

    public List<PartnerTraining__c> salesEngineerMiddleware { get; private set; }
    public List<PartnerTraining__c> salesEngineerCloud { get; private set; }
    public List<PartnerTraining__c> salesEngineerDCI { get; private set; }

    public List<PartnerTraining__c> deliveryMiddleware { get; private set; }
    public List<PartnerTraining__c> deliveryCloud { get; private set; }
    public List<PartnerTraining__c> deliveryDCI { get; private set; }

    public Map<String,List<Integer>> specToAccreditedUserCount { get; private set; }

    public MetVsSetRequirements.RegionStatusReq affiliatedReqs { get; set; }
    public MetVsSetRequirements.RegionStatusReq readyReqs { get; set; }
    public MetVsSetRequirements.RegionStatusReq advReqs { get; set; }
    public MetVsSetRequirements.RegionStatusReq premReqs { get; set; }

    public RequalificationMetDashController() {

        Id accountId = null;
        Id tmpid = ApexPages.currentPage().getParameters().get('accountId');
        User me = [select DefaultCurrencyIsoCode, Contact.AccountId from User where Id = :UserInfo.getUserId()];
        string userIsoCode = me.DefaultCurrencyIsoCode;
        currencyExchange = [select isoCode, ConversionRate FROM CurrencyType WHERE isoCode = :userIsoCode LIMIT 1];
        exchangeRate = currencyExchange.ConversionRate;

        if (tmpid == null) {
            accountId = me.Contact.AccountId;
        }
        else {
            accountId = tmpid;
        }
        loadAccount(accountId);

         //Gather the reqs from MetVsSetRequirements
        mvsr = new MetVsSetRequirements(account);
        affiliatedReqs = mvsr.getReqs(globalRegion, 'Affiliated', mvsr.accountRevenue);
        readyReqs = mvsr.getReqs(globalRegion, 'Ready', mvsr.accountRevenue);
        advReqs = mvsr.getReqs(globalRegion, 'Advanced', mvsr.accountRevenue);
        premReqs = mvsr.getReqs(globalRegion, 'Premier', mvsr.accountRevenue);

        loadCustomerReferences();
        loadCertificationList(accountId);
        businessPlan = RequalUtils.loadBusinessPlan(accountId);

    }

    private void loadAccount(String accountId) {

        account = [
            select  Id
                 ,  RequalificationDate__c
                 ,  RequalStatus__c
                 ,  Name
                 ,  ShippingStreet
                 ,  ShippingCity
                 ,  ShippingState
                 ,  ShippingPostalCode
                 ,  ShippingCountry
                 ,  BillingStreet
                 ,  BillingCity
                 ,  BillingState
                 ,  BillingPostalCode
                 ,  BillingCountry
                 ,  Global_Region__c
                 ,  Phone
                 ,  Toll_Free_Number__c
                 ,  Website
                 ,  Description_of_business__c
                 ,  Partner_Type__c
                 ,  Finder_Partner_Type__c
                 ,	Finder_Partner_Tier__c
                 ,  Select_Specialization_s__c
                 ,  Enrollment_Date__c
                 ,  CurrencyIsoCode

              from  account
             where  Id = :accountId
        ];

        speclist = new List<String>();

        if(getIsSpecialized()){
            isSpecialized=true;
            if(account.Select_Specialization_s__c.contains(';')){
                speclist = account.Select_Specialization_s__c.split(';');
            }else{
                speclist.add(account.Select_Specialization_s__c);
            }
        }

        partnerStatus = [select Id, PartnerType__c, PartnerTier__c from PartnerStatus__c where Partner__c = :accountId and ActivationStatus__c = 'Active' Limit 1];
        partnerTier = [select Name, HierarchyKey__c from Classification__c where Id = :partnerStatus.PartnerTier__c];
        partnerType = [select Name, HierarchyKey__c from Classification__c where Id = :partnerStatus.PartnerType__c];

        if(account.Global_Region__c!=null){
            globalRegion = account.Global_Region__c;
        }else{
            globalRegion = 'NA';
        }
    }

    private void loadCustomerReferences() {
        activeCustRefs = new List<Customer_Reference__c>();
        expiredCustRefs = new List<Customer_Reference__c>();
        List<List<Customer_Reference__c>> allRefs = RequalUtils.loadCustomerReferences(account, expiredCustRefs,
                                                                                        activeCustRefs);
        activeCustRefs.addAll(allRefs[0]);
        expiredCustRefs.addAll(allRefs[1]);
    }

    private void loadCertificationList(Id accountId) {

        sortedCertifications = RequalUtils.sortCertifications(accountId);

        techCerts = sortedCertifications.get('techCerts');
        salesCerts = sortedCertifications.get('salesCerts');
        salesEngineerCerts = sortedCertifications.get('salesEngineerCerts');
        deliveryCerts = sortedCertifications.get('deliveryCerts');
        //Lists to hold the counts of accredited users by specialization.
        //Each spec list is ordered: Sales, Sales Engineer, Delivery

        List<Integer> cloudSpecialized = new list<Integer>{sortedCertifications.get('salesCloud').size(), sortedCertifications.get('salesEngineerCloud').size(),
            sortedCertifications.get('deliveryCloud').size()};
        List<Integer> middlewareSpecialized = new list<Integer>{sortedCertifications.get('salesMiddleware').size(), sortedCertifications.get('salesEngineerMiddleware').size(),
            sortedCertifications.get('deliveryMiddleware').size()};
        List<Integer> dciSpecialized = new list<Integer>{sortedCertifications.get('salesDCI').size(), sortedCertifications.get('salesEngineerDCI').size(),
        sortedCertifications.get('deliveryDCI').size()};

        specToAccreditedUserCount = new Map<String,List<Integer>>{'Cloud Infrastructure'=>cloudSpecialized,
            'Middleware Solutions'=>middlewareSpecialized,
            'Data Center Infrastructure'=>dciSpecialized
        };
    }

    public Boolean getIsPartnerUser() {
        User me = [select Id, Contact.AccountId from User where Id = :UserInfo.getUserId()];
        return me.Contact.AccountId != null;
    }

    public Boolean getIsAffiliated() {
    	return account.Finder_Partner_Tier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.AFFILIATED').ObjectId__c;
    }

    public Boolean getIsSpecialized() {
        return  account.Finder_Partner_Type__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.RESELLER').ObjectId__c &&
                account.Select_Specialization_s__c != null &&
                account.Select_Specialization_s__c != '' &&
                account.Select_Specialization_s__c != 'Public Sector';

    }

    public Partner_Requal_Points__c[] getRequalPointsAffiliated() {
        system.debug('***DEBUG return value on Affiliated: ' + getRequalPoints(RedHatObjectReferences__c.getInstance('PARTNER_TIER.AFFILIATED').ObjectId__c));
        return getRequalPoints(RedHatObjectReferences__c.getInstance('PARTNER_TIER.AFFILIATED').ObjectId__c);
    }

    public Partner_Requal_Points__c[] getRequalPointsReady() {
        system.debug('***DEBUG return value on Ready PRPs: ' + getRequalPoints(RedHatObjectReferences__c.getInstance('PARTNER_TIER.READY').ObjectId__c));
        return getRequalPoints(RedHatObjectReferences__c.getInstance('PARTNER_TIER.READY').ObjectId__c);
    }

    public Partner_Requal_Points__c[] getRequalPointsAdvanced() {
        system.debug('***DEBUG return value on Premier PRPs: ' + getRequalPoints(RedHatObjectReferences__c.getInstance('PARTNER_TIER.PREMIER').ObjectId__c));
        return getRequalPoints(RedHatObjectReferences__c.getInstance('PARTNER_TIER.ADVANCED').ObjectId__c);
    }

    public Partner_Requal_Points__c[] getRequalPointsPremier() {
        system.debug('***DEBUG return value on Premier PRPs: ' + getRequalPoints(RedHatObjectReferences__c.getInstance('PARTNER_TIER.PREMIER').ObjectId__c));
        return getRequalPoints(RedHatObjectReferences__c.getInstance('PARTNER_TIER.PREMIER').ObjectId__c);
    }

    public Partner_Requal_Points__c[] getRequalPoints(ID tier) {
        return RequalUtils.getRequalPoints(tier, partnerType.id, globalRegion, specList,
                                            account.id, specToAccreditedUserCount);

    }

    public Boolean getIsOEM() {
        return account.Finder_Partner_Type__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.OEM').ObjectId__c;
    }

    public Boolean getIsDistributor() {
        return account.Finder_Partner_Type__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.DISTRIBUTOR').ObjectId__c;
    }

}