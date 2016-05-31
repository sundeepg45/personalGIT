public with sharing class RequalificationController {

    private Map<Id,User> userCache = new Map<ID, User>();
    static Integer REQUIRED_REFS = 0;
    static Integer REQUIRED_SPECIALIZATIONS = 0;

    static final PageReference[] reseller_ap_flow = new PageReference[] {
        Page.RequalificationProfileInfo, Page.RequalificationUsers, Page.RequalificationCertifications,
        //Page.RequalificationPartnerPoints,
        Page.RequalificationCustomerRefs,Page.RequalificationPartnerAgreement,
        Page.RequalificationFCPA, Page.RequalificationBusinessPlan }; //, Page.RequalificationSpecializations
    static final PageReference[] default_flow = new PageReference[] {
        Page.RequalificationProfileInfo, Page.RequalificationUsers,
        Page.RequalificationPartnerAgreement, Page.RequalificationFCPA  };
    static final PageReference[] oem_flow = new PageReference[] {
        Page.RequalificationProfileInfo, Page.RequalificationUsers, Page.RequalificationCertifications,
        Page.RequalificationPartnerAgreement, Page.RequalificationFCPA};
    static final PageReference[] training_flow = new PageReference[] {
        Page.RequalificationProfileInfo, Page.RequalificationUsers, Page.RequalificationCertifications,
        Page.RequalificationPartnerAgreement, Page.RequalificationFCPA  };
    static final PageReference[] ccsp_flow = new PageReference[] {
        Page.RequalificationProfileInfo, Page.RequalificationUsers, Page.RequalificationCertifications,
        Page.RequalificationPartnerAgreement, Page.RequalificationFCPA };
    static final PageReference[] si_flow = new PageReference[] {
        Page.RequalificationProfileInfo, Page.RequalificationUsers, Page.RequalificationCertifications,
        Page.RequalificationPartnerAgreement, Page.RequalificationFCPA}; //, Page.RequalificationSpecializations
    static final PageReference[] reseller_ready_flow = new PageReference[] {
        Page.RequalificationProfileInfo, Page.RequalificationUsers, Page.RequalificationCertifications,
        //Page.RequalificationPartnerPoints,
        Page.RequalificationPartnerAgreement,
        Page.RequalificationFCPA }; //, Page.RequalificationSpecializations
    static final PageReference[] disti_flow = new PageReference[] {
        Page.RequalificationProfileInfo, Page.RequalificationUsers, Page.RequalificationCertifications,
        Page.RequalificationFCPA }; //, Page.RequalificationSpecializations
    static final PageReference[] isv_flow = new PageReference[] {
        Page.RequalificationProfileInfo, Page.RequalificationUsers,
        //Page.RequalificationPartnerPoints,
        Page.RequalificationProducts,
        Page.RequalificationPartnerAgreement, Page.RequalificationFCPA };
    static final PageReference[] ccp_flow = new PageReference[] {
        Page.RequalificationProfileInfo, Page.RequalificationUsers, Page.RequalificationCertifications,
        Page.RequalificationFCPA };

    private integer currentPageIndex = 0;
    private PageReference[] currentRefSet = null;

    public Boolean confirmed {get; set; }
    public Boolean confirmedByFax {get; set; }
    public PartnerRequalification__c requalRec {get; private set;}
    public Account account {get; private set;}
    public Partner_Requal_Points__c[] requalPoints {get; private set; }
    public PartnerStatus__c partnerStatus {get; private set;}
    public Classification__c partnerTier {get; private set;}
    public Classification__c partnerType {get; private set;}
    public Country__c accountCountry {get; private set;}
    public List<Customer_Reference__c> activeCustRefs {get; private set;}
    public List<Customer_Reference__c> expiredCustRefs {get; private set;}
    public List<String> specializationList {get; private set;}
    public MetVsSetRequirements.RegionStatusReq metReqs {get; private set; }
    public Integer requiredCustRefs {get; private set; }
    public Integer requiredTechCerts {get; private set; }
    public Integer requiredSalesCerts {get; private set; }

    public Integer salesUsers {get; private set;}
    public Integer presalesUsers {get; private set;}
    public Integer deliveryUsers {get; private set;}
    public integer technicalUsers {get; private set;}

    public User accountContact {get; set; }
    public Integer salesCerts {get; set; }
    public Integer techCerts {get; set; }
//    public List<PartnerRequalGlobalDeal> dealSummary {get; private set; }
    public SFDC_Channel_Account_Plan__c businessPlan {get; private set; }

    private List<Id> prqsToArchive {get; set; }

    private Map<String,List<PartnerTraining__c>> specTrainingMap;
    private List<PartnerTraining__c> validSalesCerts;
    private List<PartnerTraining__c> validSalesEngCerts;
    private List<PartnerTraining__c> validDeliveryCerts;
    private List<PartnerTraining__c> validTechCerts;

    private transient Map<String, String> clfnsTranslationCache;
    LogSwarm log;



    public RequalificationController() {

        prqsToArchive = new List<Id>();
        Id accountId = null;
        requalPoints = new List<Partner_Requal_Points__c>();
        Id tmpid = ApexPages.currentPage().getParameters().get('accountId');
        if (tmpid == null) {
            User me = [select Contact.AccountId from User where Id = :UserInfo.getUserId()];
            accountId = me.Contact.AccountId;
        }
        else {
            accountId = tmpid;
        }
        setup(accountId);
    }


    public RequalificationController(ApexPages.StandardController stdController) {
        requalRec = (PartnerRequalification__c) stdController.getRecord();
        if (requalRec.Id == Null) {
            User me = [select Contact.AccountId from User where Id = :UserInfo.getUserId()];
            requalRec.AccountId__c = me.Contact.AccountId;
            insert requalRec;
        }
    }


    public void setup(String accountId) {
        log = new LogSwarm('Requal', 'Form');
        log.push('accountId', accountId);

        try {
            requalRec = new PartnerRequalification__c();
            List<PartnerRequalification__c> rqlist = [
                    select  Id
                         ,  AccountId__c
                         ,  AccountId__r.RequalStatus__c
                         ,  profileConfirmed__c
                         ,  profile_Confirmed_By__c
                         ,  profileConfirmed_Date__c
                         ,  userConfirmed__c
                         ,  user_Confirmed_By__c
                         ,  userConfirmed_Date__c
                         ,  certConfirmed__c
                         ,  cert_Confirmed_By__c
                         ,  certConfirmed_Date__c
                         ,  productConfirmed__c
                         ,  product_Confirmed_By__c
                         ,  productConfirmed_Date__c
                         ,  custRefConfirmed__c
                         ,  custRef_Confirmed_By__c
                         ,  custRefConfirmed_Date__c
                         ,  agreementConfirmed__c
                         ,  agreement_Confirmed_By__c
                         ,  agreementConfirmed_Date__c
                         ,  agreementByFaxConfirmed__c
    //                     ,  agreement_By_Fax_Confirmed_By__c
    //                     ,  agreementByFaxConfirmed_Date__c
                         ,  FCPAConfirmed__c
                         ,  FCPA_Confirmed_By__c
                         ,  FCPAConfirmed_Date__c
                         ,  FCPAActInGovernmentPosition__c
                         ,  FCPAConvictedOfCrime__c
                         ,  FCPA_Underlying_Facts__c
                         ,  BusinessPlanConfirmed__c
                         ,  BusinessPlan_Confirmed_By__c
                         ,  BusinessPlanConfirmed_Date__c
                         ,  Submitted__c
                         ,  Submitted_Date__c
                         ,  dealRegConfirmed__c
                         ,  dealReg_Confirmed_By__c
                         ,  dealRegConfirmed_Date__c
                         ,  pointsConfirmed__c
                         ,  points_Confirmed_By__c
                         ,  pointsConfirmed_Date__c
                         ,  Points_Requirement__c
                         ,  Points_Partner_Value__c
                         ,  agreement_Accepted_By__c
                         ,  agreementAccepted_Date__c
                         ,  agreement_Declined_By__c
                         ,  agreementDeclined_Date__c
                         ,  agreementDeclinedReason__c
                         ,  agreementState__c
                         ,  SpecializationsConfirmed__c
                         ,  Specializations_Confirmed_By__c
                         ,  SpecializationsConfirmed_Date__c
                      from  PartnerRequalification__c
                     where  AccountId__c = :accountId
                    //    and  Submitted__c = false
                       and  Status__c != 'Archived'
                  order by  CreatedDate desc
            ];

            if (rqlist.size() > 0 && rqlist.get(0).Submitted__c == False) {
                requalRec = rqlist.get(0);
                log.push('status', 'continuing');
                loadAccount(accountId);
            }
            else {
                if (rqlist.size() > 0 && rqlist.get(0).AccountId__r.RequalStatus__c != 'Eligible') {
                    // just show the last one
                    requalRec = rqlist.get(0);
                    loadAccount(accountId);
                }
                else {
                    // Archive all the old ones
                    for (PartnerRequalification__c prq : rqlist){
                        prqsToArchive.add(prq.id);
                    }
                    // no pending requal, start a new one
                    requalRec.AccountId__c = accountId;
                    log.push('status', 'new');
                    loadAccount(accountId);
                }
            }

            // Load the partner's current accreditations
            //specTrainingMap = RequalUtils.sortCertifications(account.Id);
            loadValidCerts(RequalUtils.sortCertifications(account.id, true));
        }
        catch (Exception ex) {
            log.exception(ex);
            throw ex;
        }
    }


    private void loadValidCerts(Map<string, List<PartnerTraining__c>> ptmap){

        validSalesCerts = new List<PartnerTraining__c>();
        validSalesEngCerts = new List<PartnerTraining__c>();
        validDeliveryCerts = new List<PartnerTraining__c>();
        validTechCerts = new List<PartnerTraining__c>();

        // Create lists of valid PartnerTraining certs
        for(PartnerTraining__c pt:ptmap.get('salesCerts')){
            if(pt.IsValid__c) validSalesCerts.add(pt);
        }

        for(PartnerTraining__c pt:ptmap.get('salesEngineerCerts')){
            if(pt.IsValid__c) validSalesEngCerts.add(pt);
        }

        for(PartnerTraining__c pt:ptmap.get('deliveryCerts')){
            if(pt.IsValid__c) validDeliveryCerts.add(pt);
        }

        for(PartnerTraining__c pt:ptmap.get('techCerts')){
            if(pt.IsValid__c) validTechCerts.add(pt);
        }

        salesUsers = validSalesCerts.size();
        presalesUsers =     validSalesEngCerts.size();
        deliveryUsers = validDeliveryCerts.size();
        technicalUsers = validTechCerts.size();

        log.push('sales_cert_users', validSalesCerts.size());
        log.push('presales_cert_users', validSalesCerts.size());
        log.push('delivery_cert_users', validSalesCerts.size());
        log.push('technical_cert_users', validSalesCerts.size());
    }


    @future
    private static void archiveOldRequals(List<Id> prqsToArch){
        List<PartnerRequalification__c> rqlist = new List<PartnerRequalification__c>();
        for (Id prqId : prqsToArch){
            PartnerRequalification__c prq = new PartnerRequalification__c(Id = prqId);
            prq.Status__c = 'Archived';
            rqlist.add(prq);
        }
        if (rqlist.size() > 0){
            update rqlist;
        }
    }


    public PageReference doOnLoad() {
        //
        // The "In Progress" status can be set outside this controller, so we need to fixup the lastestid on the
        // account to be sure
        //
        if (account.RequalStatus__c == 'Eligible' || account.RequalStatus__c == 'In Progress') {
            if (requalRec.Id == null) {
                requalRec.Name = 'Requalification for duedate ' + account.RequalificationDate__c;
                insert requalRec;
                createPointsRecs();
            }

            account.RequalStatus__c = 'In Progress';
            account.RequalificationLatestId__c = requalRec.Id;
            update account;

            if (prqsToArchive.size() > 0){
                archiveOldRequals(prqsToArchive);
                prqsToArchive = new List<Id>();
            }
        }
        loadPointsRecs();
        return null;
    }


    private void loadPointsRecs() {
        if (!getIsSpecialized()) return;

        requalPoints = [
            select  Id, Specialization__c,
                    Sales_Points__c, PreSales_Points__c, Delivery_Points__c,
                    Sales_Users__c, PreSales_Users__c, Delivery_Users__c,
                    Needed_Sales_Points__c, Needed_Sales_Users__c,
                    Needed_PreSales_Points__c, Needed_PreSales_Users__c,
                    Needed_Delivery_Points__c, Needed_Delivery_Users__c
            from    Partner_Requal_Points__c
            where   Partner_Requalification__c = :requalRec.Id
        ];
        if (requalPoints.size() == 0) {
            // try to create again - they may have accrued points since starting the requal process
            createPointsRecs();
        }

        // now recalculate each
        PP_Account_Points__c[] aplist = [
            select  Id, Sales_Points__c, PreSales_Points__c, Delivery_Points__c
            from    PP_Account_Points__c
            where   Account__c = :account.Id
        ];
        PP_Account_Points__c ap = null;
        if (aplist.size() > 0) {
            ap = aplist.get(0);
        }

        /* Commenting out for DE5322. This is the original code.
        Contact[] contactlist = [select Id from Contact where AccountId = :account.Id];
        Contact_Track__c[] tracks = [select Id, Partner_Track__r.Partner_Function__c from Contact_Track__c where Contact__c in :PartnerUtil.getIdSet(contactlist)];
        Integer salesUsers = 0;
        Integer presalesUsers = 0;
        Integer deliveryUsers = 0;
        for (Contact_Track__c track : tracks) {
            if (track.Partner_Track__r.Partner_Function__c == 'Sales') {
                salesUsers += 1;
            }
            if (track.Partner_Track__r.Partner_Function__c == 'Sales Engineer') {
                presalesUsers += 1;
            }
            if (track.Partner_Track__r.Partner_Function__c == 'Delivery') {
                deliveryUsers += 1;
            }
        }
        */


     /*

        //Begin fix for DE5322
        List <PartnerTraining__c> accredListSales = [SELECT id, Contact__c, Contact__r.AccountId, Track__c
                                                     FROM PartnerTraining__c
                                                     WHERE Contact__r.AccountId = : account.Id
                                                     AND IsActive__c = TRUE
                                                     AND LMS_Assignment__r.Training_Path__r.Name LIKE 'Sales /%'];
        List <PartnerTraining__c> accredListDelivery = [SELECT id, Contact__c, Contact__r.AccountId, Track__c
                                                        FROM PartnerTraining__c
                                                        WHERE Contact__r.AccountId = : account.Id
                                                        AND IsActive__c = TRUE
                                                        AND LMS_Assignment__r.Training_Path__r.Name LIKE 'Delivery /%'];
        List <PartnerTraining__c> accredListSalesEngineer = [SELECT id, Contact__c, Contact__r.AccountId, Track__c
                                                             FROM PartnerTraining__c
                                                             WHERE Contact__r.AccountId = : account.Id
                                                             AND IsActive__c = TRUE
                                                             AND LMS_Assignment__r.Training_Path__r.Name LIKE 'Sales Engineer /%'];
        List <PartnerTraining__c> accredListDeliveryAndSalesEngineer = [SELECT id, Contact__c, Contact__r.AccountId, Track__c
                                                                        FROM PartnerTraining__c
                                                                        WHERE Contact__r.AccountId = : account.Id
                                                                        AND IsActive__c = TRUE
                                                                        AND LMS_Assignment__r.Training_Path__r.Name LIKE 'Delivery and Sales Engineer /%'];

        Set <Id> salesSet = new Set <Id>();
        Set <Id> salesEngineerSet = new Set <Id>();
        Set <Id> deliverySet = new Set <Id>();
        Set <Id> deliveryAndSalesEngineerSet = new Set <Id>();

        if (accredListSales.size() > 0) {
            for (Integer i = 0; accredListSales.size() > i; i++) {
                salesSet.add(accredListSales[i].Contact__c);
            }
        }

        if (accredListSalesEngineer.size() > 0) {
            for (Integer i = 0; accredListSalesEngineer.size() > i; i++) {
                salesEngineerSet.add(accredListSalesEngineer[i].Contact__c);
            }
        }

        if (accredListDelivery.size() > 0) {
            for (Integer i = 0; accredListDelivery.size() > i; i++) {
                deliverySet.add(accredListDelivery[i].Contact__c);
            }
        }

        if (accredListDeliveryAndSalesEngineer.size() > 0) {
            for (Integer i = 0; accredListDeliveryAndSalesEngineer.size() > i; i++) {
                deliveryAndSalesEngineerSet.add(accredListDeliveryAndSalesEngineer[i].Contact__c);
            }
        }

        Integer salesUsers = salesSet.size();
        Integer presalesUsers = salesEngineerSet.size() + deliveryAndSalesEngineerSet.size();
        Integer deliveryUsers = deliverySet.size() + deliveryAndSalesEngineerSet.size();
        //End fix for DE5322

     */



        /*
        // BEGIN - MD US39334
        List <PartnerTraining__c> allTraining = [SELECT
                                                                            Id
                                                                            ,Contact__c
                                                                            ,Contact__r.Name
                                                                            ,Contact__r.AccountId
                                                                            ,IsValid__c
                                                                            ,LMS_Assignment__r.Name
                                                                            ,LMS_Assignment__r.Training_Path__r.Partner_Function__c
                                                                            ,LMS_Assignment__r.Training_Path__r.Name
                                                                            ,Track__c
                                                                            ,Certifying_Entity__c
                                                                         FROM PartnerTraining__c
                                                                         WHERE Contact__r.AccountId = : account.Id
                                                                            AND IsActive__c = TRUE
                                                                            AND (

                                                                                (
                                                                                    LMS_Assignment__r.Training_Path__r.Partner_Function__c = 'Sales'
                                                                                    OR LMS_Assignment__r.Training_Path__r.Partner_Function__c = 'Delivery'
                                                                                    OR LMS_Assignment__r.Training_Path__r.Partner_Function__c = 'Sales Engineer'
                                                                                    OR LMS_Assignment__r.Training_Path__r.Partner_Function__c = 'Delivery and Sales Engineer'
                                                                                )
                                                                                OR (
                                                                                    Track__c = NULL AND Certifying_Entity__c = 'Redhat')
                                                                                )
                                                                            ];


        Set <Id> salesSet = new Set <Id>();
        Set <Id> salesEngineerSet = new Set <Id>();
        Set <Id> deliverySet = new Set <Id>();
        Set <Id> deliveryAndSalesEngineerSet = new Set <Id>();
        Set <Id> technicalSet = new Set <Id>();

        List<PartnerTraining__c> salesList = new List<PartnerTraining__c>();
        List<PartnerTraining__c> salesEngineerList = new List<PartnerTraining__c>();
        List<PartnerTraining__c> deliveryList = new List<PartnerTraining__c>();
        List<PartnerTraining__c> deliveryAndSalesEngineerList = new List<PartnerTraining__c>();
        List<PartnerTraining__c> technicalList = new List<PartnerTraining__c>();



        for(PartnerTraining__c pt:allTraining){

            if(!pt.IsValid__c) continue; // only count Valid accreditations

            if (pt.LMS_Assignment__c == null && pt.Track__c == null && pt.Certifying_Entity__c == 'Redhat') {
                //technicalSet.add(pt.Contact__c);
                technicalList.add(pt);
            } else if (pt.LMS_Assignment__r.Training_Path__r.Partner_Function__c.equalsIgnoreCase('Delivery and Sales Engineer')){
                //deliveryAndSalesEngineerSet.add(pt.Contact__c);
                deliveryAndSalesEngineerList.add(pt);
                deliveryList.add(pt); // Also add to the Delivery list
                salesEngineerList.add(pt);
            } else if (pt.LMS_Assignment__r.Training_Path__r.Partner_Function__c.equalsIgnoreCase('Sales Engineer')){
                //salesEngineerSet.add(pt.Contact__c);
                salesEngineerList.add(pt);
            } else if (pt.LMS_Assignment__r.Training_Path__r.Partner_Function__c.equalsIgnoreCase('Delivery')){
                //deliverySet.add(pt.Contact__c);
                deliveryList.add(pt);
            } else if (pt.LMS_Assignment__r.Training_Path__r.Partner_Function__c.equalsIgnoreCase('Sales')){
                //salesSet.add(pt.Contact__c);
                salesList.add(pt);
            }  else {
                system.debug('Undefined training type: [' + pt + ']');
            }
        }

        salesUsers = salesList.size(); //salesSet.size();
        presalesUsers = salesEngineerList.size();//salesEngineerSet.size() + deliveryAndSalesEngineerSet.size();
        deliveryUsers = deliveryList.size();//deliverySet.size() + deliveryAndSalesEngineerSet.size();
        technicalUsers = technicalList.size();//technicalSet.size();
        */


        for (Partner_Requal_Points__c rp : requalPoints) {
            if (ap != null) {
                rp.Sales_Points__c = ap.Sales_Points__c;
                rp.PreSales_Points__c = ap.PreSales_Points__c;
                rp.Delivery_Points__c = ap.Delivery_Points__c;
            }

            rp.Specialization__c = rp.Specialization__c;
            rp.Sales_Users__c = salesUsers;
            rp.PreSales_Users__c = presalesUsers;
            rp.Delivery_Users__c = deliveryUsers;
        }
        if (requalPoints.size() > 0) update requalPoints;

    }

    private void createPointsRecs() {
        if (!getIsSpecialized()) return;
        requalPoints = new List<Partner_Requal_Points__c>();
        for (String spec : account.Select_Specialization_s__c.split(';')) {
            spec = spec.trim();
            System.debug('*****[debug]***** specialization=' + spec);
            Partner_Point_Requal_Limits__c[] limits = [
                select  Id,
                        Delivery_Users__c, Delivery_Points__c,
                        Sales_Users__c, Sales_Points__c,
                        PreSales_Users__c, PreSales_Points__c,
                        Specialization__c
                from    Partner_Point_Requal_Limits__c
                where   Partner_Type__c = :account.Finder_Partner_Type__c
                and     Partner_Tier__c = :account.Finder_Partner_Tier__c
                and     Global_Region__c = :account.Global_Region__c
                and     Specialization__c = :spec
            ];
            if (limits.size() == 0) {
                System.debug('*****[debug]***** no limits found');
                //
                // If no limits exist they don't apply
                //
                continue;
            }
            Partner_Point_Requal_Limits__c plimit = limits.get(0);
            Partner_Requal_Points__c prp = new Partner_Requal_Points__c();
            prp.Partner_Requalification__c = requalRec.Id;
            prp.Specialization__c = spec;
            prp.Needed_Sales_Points__c = plimit.Sales_Points__c;
            prp.Needed_Sales_Users__c = plimit.Sales_Users__c;
            prp.Needed_PreSales_Points__c = plimit.PreSales_Points__c;
            prp.Needed_PreSales_Users__c = plimit.PreSales_Users__c;
            prp.Needed_Delivery_Points__c = plimit.Delivery_Points__c;
            prp.Needed_Delivery_Users__c = plimit.Delivery_Users__c;
            requalPoints.add(prp);
        }
        if (requalPoints.size() > 0) {
            insert requalPoints;
        }
    }

    private void loadAccount(String accountId) {
        salesCerts = 0;
        techCerts = 0;

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
                 ,  Subregion__c
                 ,  Phone
                 ,  OwnerId
                 ,  Toll_Free_Number__c
                 ,  Website
                 ,  Description_of_business__c
                 ,  Select_Specialization_s__c
                 ,  Partner_Type__c
                 ,  Enrollment_Date__c
                 ,  Finder_Partner_Type__c
                 ,  Finder_Partner_Tier__c
                 ,  Additional_Countries_of_Operation__c
                 ,  Direct_Purchasing_Agreement__c
              from  account
             where  Id = :accountId
        ];

        log.push('global_region', account.Global_Region__c);

        partnerStatus = [select Id, PartnerType__c, PartnerTier__c from PartnerStatus__c where Partner__c = :accountId and ActivationStatus__c = 'Active' Limit 1];

        partnerTier = [select Name, HierarchyKey__c from Classification__c where Id = :partnerStatus.PartnerTier__c];
        partnerType = [select Name, HierarchyKey__c from Classification__c where Id = :partnerStatus.PartnerType__c];

        log.push('primary_program', partnerType.Name);
        log.push('primary_tier', partnerTier.Name);

        partnerTier.Name = getTranslatedClfn(partnerTier.Id, partnerTier.Name);
        partnerType.Name = getTranslatedClfn(partnerType.Id, partnerType.Name);

        loadRequirements(account);

        String countryAbbr = account.BillingCountry;
        if (countryAbbr == null) {
            countryAbbr = account.ShippingCountry;
        }
        try {
            accountCountry = [select Id, Iso3166Alpha2__c, IsAgreementSignatureRequired__c from Country__c where Abbreviation__c = :countryAbbr];
        } catch (Dmlexception de){
            // We potentially have a bad billing / shipping country, try the other way around
            countryAbbr = account.ShippingCountry;
            accountCountry = [select Id, Iso3166Alpha2__c, IsAgreementSignatureRequired__c from Country__c where Abbreviation__c = :countryAbbr];
        }
        log.push('country', accountCountry.Iso3166Alpha2__c);

        if (account.Select_Specialization_s__c != null){
            specializationList = account.Select_Specialization_s__c.split(';');
        }
        loadCustomerReferences(accountId);
//        loadDealReg(accountId);
        loadBusinessPlan(accountId);

        //start setting the flow with CCP Program and then fall-back to types
        //US79277: Skip Agreements section for CCP - Kiran 1/13/16
        if (getIsCCP()) {
            System.debug('setting ccp flow');
            currentRefSet = ccp_flow;
            //remove Agreements US79277
            //if (!hasAgreements) {
            //    removeAgreementPage();
            //}
            removeAgreementPage();
        }
        else if (getIsResellerAandP()) {
        	System.debug('setting reseller a and p flow');
            currentRefSet = reseller_ap_flow;
            if(getIsSpecialized()) {
                currentRefSet.add(Page.RequalificationSpecializations);
            }
        }
        else if (getIsResellerReady()) {
        	System.debug('setting reseller ready flow');
            currentRefSet = reseller_ready_flow;
            if(getIsSpecialized()) {
                currentRefSet.add(Page.RequalificationSpecializations);
            }
        }
        else if (getIsCCSP()) {
            System.debug('setting CCSP flow');
            currentRefSet = ccsp_flow;
            if (!hasAgreements) {
                removeAgreementPage();
            }
        }
        else if (getIsDisti()) {
        	System.debug('setting disti flow');
        	currentRefSet = disti_flow;
            if(getIsSpecialized()) {
                currentRefSet.add(Page.RequalificationSpecializations);
            }
            if (!hasAgreements) {
                removeAgreementPage();
            }
        }
        else if (getIsISV()) {
        	System.debug('setting isv flow');
            currentRefSet = isv_flow;
        }
        else if (getIsSI()) {
        	System.debug('setting si flow');
            currentRefSet = si_flow;
//            if(getIsSpecialized()) {
//                currentRefSet.add(Page.RequalificationSpecializations);
//            }
        }
        else if (getIsOEM()) {
            System.debug('setting oem flow');
            currentRefSet = oem_flow;
            if (!hasAgreements) {
                removeAgreementPage();
            }
        }
        else if (getIsTraining()) {
            System.debug('setting training flow');
            currentRefSet = training_flow;
            if (!hasAgreements) {
                removeAgreementPage();
            }
        }
        else {
            System.debug('setting default flow');
            currentRefSet = default_flow;
            if (!hasAgreements) {
                removeAgreementPage();
            }
        }
        loadAccountOwner(accountId);
    }

    private void loadRequirements(Account account){
        // edited 1/7/2014 in support of updates to requal requirements for specializations

        MetVsSetRequirements mvsr = new MetVsSetRequirements(account);
        String status;
        if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.PREMIER'){
            status = 'Premier';
        }else if(partnerTier.HierarchyKey__c == 'PARTNER_TIER.ADVANCED'){
            status = 'Advanced';
        }else{
            status = 'Ready';
        }
        metReqs = mvsr.getReqs(account.Global_Region__c, status, mvsr.accountRevenue);

        /*
        if (account.Global_Region__c == 'EMEA'){
            if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.PREMIER'){
                metReqs = MetVsSetRequirements.EMEA_Prem;
            } else if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.ADVANCED') {
                metReqs = MetVsSetRequirements.EMEA_Adv;
            } else {
                metReqs = MetVsSetRequirements.EMEA_Ready;
            }
        } else if (account.Global_Region__c == 'APAC'){
            if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.PREMIER'){
                metReqs = MetVsSetRequirements.APAC_Prem;
            } else if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.ADVANCED') {
                metReqs = MetVsSetRequirements.APAC_Adv;
            } else {
                metReqs = MetVsSetRequirements.APAC_Ready;
            }
        } else if (account.Global_Region__c == 'LATAM'){
            if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.PREMIER'){
                metReqs = MetVsSetRequirements.LATAM_Prem;
            } else if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.ADVANCED') {
                metReqs = MetVsSetRequirements.LATAM_Adv;
            } else {
                metReqs = MetVsSetRequirements.LATAM_Ready;
            }
        } else {
            if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.PREMIER'){
                metReqs = MetVsSetRequirements.NA_Prem;
            } else if (partnerTier.HierarchyKey__c == 'PARTNER_TIER.ADVANCED') {
                metReqs = MetVsSetRequirements.NA_Adv;
            } else {
                metReqs = MetVsSetRequirements.NA_Ready;
            }
        }
        */
        REQUIRED_REFS = metReqs.CustomerRefs;
        REQUIRED_SPECIALIZATIONS = metReqs.Specializations;
    }

    private void updatePointsReq(Account account){
        try {
            Partner_Points_Requal_Req__c ppreq = [select Id, Total_Points_Required__c
                                from Partner_Points_Requal_Req__c
                                where
                                    Global_Region__c = :account.Global_Region__c
                                and Partner_Tier__c = :partnerTier.Id
                                and Partner_Type__c = :partnerType.Id];
            requalRec.Points_Requirement__c = ppreq.Total_Points_Required__c;
        } catch (Exception onf){
            // No points requirement defined
            requalRec.Points_Requirement__c = 0;
        }
            PP_Account_Points__c accountPoints = getAccountPoints();

            requalRec.Points_Partner_Value__c = accountPoints.Current_Points__c;
    }

    public PP_Account_Points__c getAccountPoints(){
        PP_Account_Points__c ppap = null;
        if ([select count() from PP_Account_Points__c where Account__c = :account.Id] > 0){
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
                    Account__c = :account.Id
                limit 1
            ];
        }
        return ppap == null ? new PP_Account_Points__c(Account__r = account, Current_Points__c = 0) : ppap;
    }

    public List<PP_User_Points__c> getPartnerContacts(){
        List<PP_User_Points__c> pointsUsers = [
            select
                Contact__r.Name,
                Current_Points__c
            from PP_User_Points__c
            where
                Account__c = :account.Id
                and IsActive__c = true
            order by
                Current_Points__c desc,
                Contact__r.Name asc
        ];

        return pointsUsers;
    }

    private void loadBusinessPlan(Id accountId){
        try {
            businessPlan = [select
                                Id,
                                Name,
                                Business_Plan_Version__c,
                                Fiscal_Year__c,
                                LastModifiedBy.Name,
                                Approval_Status__c,
                                CreatedDate
                            from SFDC_Channel_Account_Plan__c
                            where
                                Partner_Name__c = :accountId and
                                Approval_Status__c = 'Approved'
                            order by CreatedDate desc
                            limit 1];
            if (businessPlan != null) requalRec.Business_Plan_Id__c = businessPlan.Id;
        } catch (System.QueryException qE){
            System.debug('Query exception returned trying to find an active business plan ' + qE);
            requalRec.Business_Plan_Id__c = null;
        }
    }

    public String[] shippingStreetAddresses {
        get {
            if (account.ShippingStreet == null) {
                return new String[0];
            }
            return account.ShippingStreet.split('\n');
        }
    }

    public String[] billingStreetAddresses {
        get {
            if (account.BillingStreet == null) {
                return new String[0];
            }
            return account.BillingStreet.split('\n');
        }
    }

    public Attachment partnerLogo {
        get {
            List<PartnerLogo__c> logos = [
                select  Id
                  from  PartnerLogo__c
                 where  Partner__c = :account.Id
            ];
            if (logos.size() > 0) {
                PartnerLogo__c logo = logos.get(0);
                Attachment a = getSingle([select Id, name, parentid from Attachment where ParentId = :logo.Id]);
                return a;
            }
            return null;
        }
    }

    public List<User> userList {
        get {
            return [select Name, Contact.LoginName__c, Contact.Email, IsPartnerAdmin__c, LastLoginDate from User where Contact.AccountId = :account.Id];
        }
    }

    public List<PartnerProductListItem> partnerProductItemList {
        get {
            return getProducts();
        }
    }

    public List<PartnerProductListItem> getProducts() {
        List<PartnerProductListItem> ppList = new List<PartnerProductListItem>();
        List<PartnerProduct__c> prods = [
            select  Name,
                    Partner__c,
                    Application_Status__c,
                    Application_Visibility__c,
                    IsSELinuxSupported__c,
                    Product_Details__c,
                    Pricing_and_Support_Details__c,
                    Product_Types__c,
                    Call_to_Action_Text__c,
                    Success_Story__c,
                    Platforms__c,
                    JBoss_Platform__c,
                    Industry_Focus__c,
                    Application_Website__c,
                    Application_Demo__c,
                    Usage_Licensing__c,
                    Industry__c,
                    Source_Licensing__c,
                    Distribution_Licensing__c,
//                    Application_Type__c,
                    Keywords__c,
                    Last_Update__c,
                    Application_Type__r.Name
              from  PartnerProduct__c
             where  PartnerProduct__c.Partner__c = :account.Id
               and  (Application_Status__c = 'Approved'
                or  Application_Status__c = 'Pending')];

         Set<Id> prodIds = new Set<Id>();

         for(PartnerProduct__c p : prods){
            prodIds.add(p.Id);
         }

         List<PartnerProductScreenshot__c> screenshots = [
            select  Id, PartnerProduct__c
              from  PartnerProductScreenshot__c
             where  PartnerProduct__c in :prodIds
         ];
         List<PartnerProductLogo__c> logos = [
            select  Id, PartnerProduct__c
              from  PartnerProductLogo__c
             where  PartnerProduct__c in :prodIds
         ];

         for(PartnerProduct__c p : prods){
            PartnerProductListItem ppli = new PartnerProductListItem();
            ppList.add(ppli);
            ppli.product = p;

            //
            // get screenshots
            //
            ppli.screenshots = new List<Attachment>();
            for (PartnerProductScreenshot__c ss : screenshots) {
                //System.debug('#### comparing ' + ss.PartnerProduct__c + ' to ' + p.Id);
                if (ss.PartnerProduct__c == p.Id) {
                    //System.debug('############# found attachment for product');
                    Attachment a = getSingle([select Id, name, parentid from Attachment where ParentId = :ss.Id]);
                    if (a != null) ppli.screenshots.add(a);
                }
            }

            //
            // get logo
            //
            ppli.logo = null;
            for (PartnerProductLogo__c ppl : logos) {
                if (ppl.PartnerProduct__c == p.Id) {
                    Attachment a = getSingle([select Id from Attachment where ParentId = :ppl.Id]);
                    if (a != null) ppli.logo = a;
                    break;
                }
            }

            ppli.platforms = PFUtils.get(p.Platforms__c);
            ppli.platformsJBoss = PFUtils.get(p.JBoss_Platform__c);
         }

     return ppList;
    }

    private Attachment getSingle(List<Attachment> aList) {
        if (aList == null || aList.size() == 0) {
            return null;
        }
        return aList.get(0);
    }

    public List<PartnerTraining__c> certificationList {
        get {
            List<PartnerTraining__c> certs = new List<PartnerTraining__c>();
//          User currentUser = [Select u.Id, u.Contact.Account.Id, u.ContactId From User u Where u.Id = :UserInfo.getUserId() ];
            /*
            for (PartnerTraining__c cert : [
                select  Id
                     ,  CertificateNumber__c
                     ,  Date_Achieved__c
                     ,  Contact__r.Name
                     ,  Contact__c
                     ,  Certificate_Owner__c
                     ,  Certification__c
                     ,  Certification__r.Name
                     ,  Certification__r.HierarchyKey__c
                     ,  Certifying_Entity__c
                     ,  Skill__c
                     ,  Track__c
                     ,  TrainingType__r.Name
                     ,  TrainingType__c
                     ,  RedHatValidated__c
                     ,  IsValid__c
                     ,  IsActive__c
                     ,  Accreditation_Name__c
                     ,  LMS_Assignment__r.Training_Path__c
                     ,  LMS_Assignment__r.Training_Path__r.Partner_Function__c
                  from  PartnerTraining__c
                 where  Partner__c = :account.Id
                    and    IsActive__c = true
                 ORDER BY LMS_Assignment__r.Training_Path__r.Partner_Function__c
            ]) certs.add(cert);
            */

            certs.addAll(validSalesCerts);
            certs.addAll(validSalesEngCerts);
            certs.addAll(validDeliveryCerts);
            certs.addAll(validTechCerts);


            requiredTechCerts = 0;
            requiredSalesCerts = 0;
            salesCerts = 0;
            techCerts = 0;

            for (PartnerTraining__c cert : certs) {
                //
                // only care about Red Hat certifications (Red Hat products)
                //
            //    if (cert.Certification__r.HierarchyKey__c == null) continue;
            /*
                if (cert.Certification__r.HierarchyKey__c.startsWith('PARTNER_TRAINING.RED_HAT')) {
                    if (cert.Certification__r.HierarchyKey__c.endsWith('_SALESPERSON'))
                        salesCerts += 1;
                    else
                        techCerts += 1;
                }
            */
                if (cert.LMS_Assignment__r.Training_Path__c != null) {
                    salesCerts += 1;
                } else {
                    techCerts += 1;
                }
            }

            if (techCerts < metReqs.Rhce) requiredTechCerts = metReqs.Rhce - techCerts;
            if (salesCerts < metReqs.Sales) requiredSalesCerts = metReqs.Sales - salesCerts;

            //
            // translate the classifications
            //
            for (PartnerTraining__c cert : certs) {
                if (cert.TrainingType__r != null) {
                    cert.TrainingType__r.Name = getTranslatedClfn(cert.TrainingType__c, cert.TrainingType__r.Name);
                }
                if (cert.Certification__r != null) {
                    cert.Certification__r.Name = getTranslatedClfn(cert.Certification__c, cert.Certification__r.Name);
                }

            }
            return certs;
        }
    }

    public Integer totalProductCount {
        get {
            return  [select count() from PartnerProduct__c where PartnerProduct__c.Partner__c = :account.Id];
        }
    }

    public Boolean userListIsEmpty {
        get {
            return [select Id from User where Contact.AccountId = :account.Id].isEmpty();
        }
    }

    private void loadCustomerReferences(Id accountId) {
        List<Customer_Reference__c> refs = [
            select  Company_Name__c
                 ,  CreatedDate
                 ,  Contact__r.Name
                 ,  Contact__r.Email
                 ,  Contact_Email__c
                 ,  Contact_First_Name__c
                 ,  Contact_Last_Name__c
                 ,  Pl__c
                 ,  Please_describe_how_the_customer_benefit__c
                 ,  Approved_Date__c
                 ,  Date_Submitted__c
              from  Customer_Reference__c
             where  Account__c = :accountId
                and (Approved_Date__c != null
                    or Date_Submitted__c != null)
        ];

        expiredCustRefs = new List<Customer_Reference__c>();
        activeCustRefs = new List<Customer_Reference__c>();
        for (Customer_Reference__c ref : refs) {
            if (ref.Approved_Date__c == null) {
                activeCustRefs.add(ref);    // assume good if pending
            }
            else {
                if (ref.Approved_Date__c < account.RequalificationDate__c.addMonths(-12)) {
                    expiredCustRefs.add(ref);
                }
                else {
                    activeCustRefs.add(ref);
                }
            }

        }

        requiredCustRefs = REQUIRED_REFS - activeCustRefs.size();
        if (requiredCustRefs < 0) requiredCustRefs = 0;
    }
/*
    private void loadDealReg(Id accountId) {
        List<Id> dealRegRecTypes = new List<Id>();
        for (RecordType rt : [
            select  Id
              from  RecordType
             where  SobjectType = 'Lead'
               and  Name like '%Deal%'
        ]) dealRegRecTypes.add(rt.Id);

        List<Lead> dealRegLeads = [
            select  Red_Hat_Total_Revenue__c
                 ,  Global_Region__c
              from  Lead
             where  PartnerAccountId = :accountId
               and  RecordTypeId in :dealRegRecTypes
        ];

        //
        // Group deals by global region
        //
        Map<String, List<Lead>> regionLeads = new Map<String, List<Lead>>();
        for (Lead deal : dealRegLeads) {
            if (!regionLeads.containsKey(deal.Global_Region__c)) {
                regionLeads.put(deal.Global_Region__c, new List<Lead>());
            }
            regionLeads.get(deal.Global_Region__c).add(deal);
        }
        dealSummary = new List<PartnerRequalGlobalDeal>();
        for (String region : regionLeads.keySet()) {
            PartnerRequalGlobalDeal summary = new PartnerRequalGlobalDeal();
            summary.region = region;
            summary.amount = 0.0;
            for (Lead lead : regionLeads.get(region)) {
                summary.amount += lead.Red_Hat_Total_Revenue__c;
            }
            dealSummary.add(summary);
        }
    }
*/

    private Boolean isFCPAException() {
        Boolean isException = false;
        if (requalRec.FCPAConvictedOfCrime__c == 'Yes') {
            isException = true;
        }
        if (requalRec.FCPAActInGovernmentPosition__c == 'Yes') {
            isException = true;
        }

        if (account.Finder_Partner_Tier__c != RedHatObjectReferences__c.getInstance('PARTNER_TIER.READY').ObjectId__c) {
            if (account.Direct_Purchasing_Agreement__c) {
                isException = true;
            }
            Set<String> matchedCountries = PartnerUtil.filterTIIndexedAccount(account);
            if (!matchedCountries.isEmpty()) {
                isException = true;
            }
        }
        return isException;
    }

    public PageReference submitRequal() {
        try {
            account.Requalification_Submitter__c = UserInfo.getUserId();
            if (isFCPAException()) {
                account.Anti_Corruption_Status__c = 'Review Required';
            }
            update account;

            Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();
            approvalReq.setComments('Account Submitted for Requalification Approval.');
            approvalReq.setObjectId(account.Id);
            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(approvalReq);

            requalRec.Submitted__c = true;
            requalRec.Submitted_Date__c = System.now();
            requalRec.Submit_By__c = UserInfo.getUserId();
            requalRec.Status__c = 'Submitted';
            requalRec.PopulateMetVsSet__c = True;
            requalRec.User_IP__c = PartnerUtil.getUserIPAddress();

            update requalRec;

//            log.info('requal submitted');
//            log.flush();

            return new PageReference(Page.RequalificationThankYou.getUrl());
        }
        catch (Exception ex) {
            log.exception(ex);
            throw ex;
        }
    }

    public PageReference confirmProfile() {
        confirm('profile');
        return null;
    }

    public PageReference confirmUser() {
        confirm('user');
        return null;
    }

    public PageReference confirmPP() {
        confirm('points');
        return null;
    }

    public PageReference confirmCert() {
        confirm('cert');
        return null;
    }

    public PageReference confirmProduct() {
        confirm('product');
        return null;
    }

    public PageReference confirmCustRef() {
        confirm('CustRef');
        return null;
    }

    private void storeAgreementIds() {
        List<Agreement__c> agreements = getAgreementList();
        for (Agreement__c agreement : agreements) {
            Partner_Requalification_Agreement__c pra = new Partner_Requalification_Agreement__c();
            pra.Partner_Requalification__c = requalRec.id;
            pra.Agreement__c = agreement.Id;
            insert pra;
        }
    }

    public PageReference confirmAgreement() {
        if (requalRec.AgreementState__c != null && requalRec.AgreementState__c == 'Accepted') {
            requalRec.AgreementAccepted_Date__c = System.now();
            requalRec.Agreement_Accepted_By__c = UserInfo.getUserId();
            requalRec.AgreementDeclined_Date__c = null;
            requalRec.Agreement_Declined_By__c = null;
        }
        else if (requalRec.AgreementState__c != null && requalRec.AgreementState__c == 'Declined') {
            requalRec.AgreementAccepted_Date__c = null;
            requalRec.Agreement_Accepted_By__c = null;
            requalRec.AgreementDeclined_Date__c = System.now();
            requalRec.Agreement_Declined_By__c = UserInfo.getUserId();
            if (requalRec.AgreementDeclinedReason__c == null || requalRec.AgreementDeclinedReason__c.length() < 5) {
                requalRec.AgreementDeclinedReason__c.AddError(System.Label.PRQ_RequalController_Reason_for_declining);
                confirmed = False;
                return null;
            }
        }
        else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.PRQ_RequalController_Please_accept_or_decline));
            confirmed = False;
            return null;
        }

        requalRec.AgreementConfirmed__c = True;
        requalRec.AgreementConfirmed_Date__c = System.now();
        requalRec.Agreement_Confirmed_By__c = UserInfo.getUserId();
        storeAgreementIds();
        insertOrUpdate();
        return null;
    }

    public PageReference confirmAgreementByFax() {
        requalRec.AgreementByFaxConfirmed__c = True;
        requalRec.AgreementConfirmed_Date__c = System.now();
        requalRec.Agreement_Confirmed_By__c = UserInfo.getUserId();
        requalRec.AgreementState__c = 'Accepted';
        requalRec.AgreementAccepted_Date__c = System.now();
        requalRec.Agreement_Accepted_By__c = UserInfo.getUserId();
        storeAgreementIds();
        insertOrUpdate();
        return null;
    }

/*
    public PageReference confirmDealReg() {
        confirm('DealReg');
        return null;
    }
*/
    public PageReference confirmFCPA() {
        if (requalRec.FCPAActInGovernmentPosition__c == null || requalRec.FCPAConvictedOfCrime__c == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.PRQ_RequalController_Indicate_Yes_or_No));
            confirmed = False;
            return null;
        }
        if ((requalRec.FCPAActInGovernmentPosition__c == 'Yes' || requalRec.FCPAConvictedOfCrime__c == 'Yes') && (requalRec.FCPA_Underlying_Facts__c == '' || requalRec.FCPA_Underlying_Facts__c == null)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.PRQ_RequalController_Provide_Underlying_Facts));
            confirmed = False;
            return null;
        }
        confirm('FCPA');
        return null;
    }

    public PageReference confirmBusinessPlan() {
        confirm('BusinessPlan');
        return null;
    }

    public PageReference confirmPoints() {
        confirm('Points');
        return null;
    }

    public PageReference confirmSpecializations() {
        confirm('Specializations');
        return null;
    }

    private void confirm(String fieldPrefix) {
        requalRec.put(fieldPrefix + 'Confirmed__c', True);
        requalRec.put(fieldPrefix + 'Confirmed_Date__c', System.now());
        requalRec.put(fieldPrefix + '_Confirmed_By__c', UserInfo.getUserId());
        insertOrUpdate();
    }

    public Boolean isComplete {
        get {
            if (account.requalStatus__c != 'In Progress') {
                return false;
            }

            if (getIsCCP()) {
                return  requalRec.profileConfirmed__c &&
                        requalRec.userConfirmed__c &&
                        requalRec.certConfirmed__c &&
                        requalRec.FCPAConfirmed__c;
            }

            if (getIsResellerReady()) {
                return  requalRec.profileConfirmed__c &&
                        requalRec.userConfirmed__c &&
                        requalRec.certConfirmed__c &&
                        //requalRec.pointsConfirmed__c &&
                        (!getIsSpecialized() || requalRec.SpecializationsConfirmed__c) &&
                        (requalRec.agreementConfirmed__c || requalRec.agreementByFaxConfirmed__c) &&
                        requalRec.FCPAConfirmed__c;
            }
            if (getIsDisti()) {
                return  requalRec.profileConfirmed__c &&
                        requalRec.userConfirmed__c &&
                        requalRec.certConfirmed__c &&
//                        requalRec.custRefConfirmed__c &&
                        //requalRec.pointsConfirmed__c &&
                        (!getIsSpecialized() || requalRec.SpecializationsConfirmed__c) &&
                        requalRec.FCPAConfirmed__c;
            }
            if (getIsResellerAandP()) {
                return  requalRec.profileConfirmed__c &&
                        requalRec.userConfirmed__c &&
                        requalRec.certConfirmed__c &&
                        requalRec.custRefConfirmed__c &&
                        (!getIsSpecialized() || requalRec.SpecializationsConfirmed__c) &&
                        //requalRec.pointsConfirmed__c &&
                        (requalRec.agreementConfirmed__c || requalRec.agreementByFaxConfirmed__c) &&
                        requalRec.FCPAConfirmed__c &&
                        requalRec.BusinessPlanConfirmed__c;
            }
            if (getIsSI()) {
                return  requalRec.profileConfirmed__c &&
                        requalRec.userConfirmed__c &&
                        requalRec.certConfirmed__c &&
//                        requalRec.custRefConfirmed__c &&
                        (!getIsSpecialized() || requalRec.SpecializationsConfirmed__c) &&
                        //requalRec.pointsConfirmed__c &&
                        requalRec.FCPAConfirmed__c;
            }
            if (getIsOEM() || getIsTraining() || getIsCCSP()) {
                Boolean flag = requalRec.profileConfirmed__c &&
                        requalRec.userConfirmed__c &&
                        requalRec.FCPAConfirmed__c;
                if (!hasAgreements) {
                    return flag;
                }
                else {
                    return flag && (requalRec.agreementConfirmed__c || requalRec.agreementByFaxConfirmed__c);
                }
            }
            if (getIsISV()) {
                return  requalRec.profileConfirmed__c &&
                        requalRec.userConfirmed__c &&
                        requalRec.productConfirmed__c &&
                        //requalRec.pointsConfirmed__c &&
                        (requalRec.agreementConfirmed__c || requalRec.agreementByFaxConfirmed__c) &&
                        requalRec.FCPAConfirmed__c;
            }

            //
            // if we fall through to here use the default flow
            //
            Boolean flag = requalRec.profileConfirmed__c && requalRec.userConfirmed__c && requalRec.FCPAConfirmed__c;
            if (!hasAgreements) {
                return flag;
            }
            else {
                return flag && (requalRec.agreementConfirmed__c || requalRec.agreementByFaxConfirmed__c);
            }
        }
    }

    private PageReference setCurrentPage(PageReference pg) {
        integer i = 0;
        for (PageReference p : currentRefSet) {
            if (p.getUrl() == pg.getUrl()) {
                currentPageIndex = i;
                break;
            }
            i += 1;
        }
        return pg;
    }

    private PageReference viewDispatcher(PageReference pg) {
        //System.debug('############# page = ' + pg.getUrl());
        if (pg.getUrl().endsWith('profileinfo')) {
            return viewProfile();
        }
        if (pg.getUrl().endsWith('users')) {
            return viewUser();
        }
        if (pg.getUrl().endsWith('certifications')) {
            return viewCerts();
        }
        if (pg.getUrl().endsWith('products')) {
            return viewProducts();
        }
        if (pg.getUrl().endsWith('points')) {
            return viewPP();
        }
        if (pg.getUrl().endsWith('customerrefs')) {
            return viewCustRefs();
        }
        if (pg.getUrl().endsWith('agreement')) {
            return viewAgreement();
        }
        if (pg.getUrl().endsWith('fcpa')) {
            return viewFCPA();
        }
        if (pg.getUrl().endsWith('businessplan')) {
            return viewBusinessPlan();
        }
        if (pg.getUrl().endsWith('specializations')) {
            return viewSpecializations();
        }
        return null;
    }

    public PageReference viewProfile() {
        confirmed = requalRec.ProfileConfirmed__c;
        return setCurrentPage(Page.RequalificationProfileInfo);
    }

    public PageReference viewUser() {
        confirmed = requalRec.UserConfirmed__c;
        return setCurrentPage(Page.RequalificationUsers);
    }

    public PageReference viewCerts() {
        confirmed = requalRec.CertConfirmed__c;
        return setCurrentPage(Page.RequalificationCertifications);
    }

    public PageReference viewPP() {
        confirmed = requalRec.PointsConfirmed__c;

        if (!confirmed){
            updatePointsReq(account);
            insertOrUpdate();
        }

        return setCurrentPage(Page.RequalificationPartnerPoints);
    }

    public PageReference viewProducts() {
        confirmed = requalRec.ProductConfirmed__c;
        return setCurrentPage(Page.RequalificationProducts);
    }

    public PageReference viewCustRefs() {
        confirmed = requalRec.CustRefConfirmed__c;
        return setCurrentPage(Page.RequalificationCustomerRefs);
    }

    public PageReference viewAgreement() {
        confirmed = requalRec.AgreementConfirmed__c;
        confirmedByFax = requalRec.AgreementByFaxConfirmed__c;
        return setCurrentPage(Page.RequalificationPartnerAgreement);
    }

    public PageReference viewFCPA() {
        confirmed = requalRec.FCPAConfirmed__c;
        return setCurrentPage(Page.RequalificationFCPA);
    }

    public PageReference viewBusinessPlan() {
        confirmed = requalRec.BusinessPlanConfirmed__c;
        return setCurrentPage(Page.RequalificationBusinessPlan);
    }

    public PageReference viewSpecializations() {
        confirmed = requalRec.SpecializationsConfirmed__c;
        return setCurrentPage(Page.RequalificationSpecializations);
    }

    public PageReference viewHome() {
        insertOrUpdate();
        return Page.RequalificationHome;
    }

    public PageReference nextPage() {
        confirmed = False;
        if (isLastPage) {
            // cannot go forward
            return new PageReference('/apex/RequalificationHome');
        }
        currentPageIndex += 1;
        System.debug('***** [debug] ***** next page is ' + currentRefSet[currentPAgeIndex].getUrl());
        return viewDispatcher(currentRefSet[currentPageIndex]);
        //return currentRefSet[currentPageIndex];
    }

    public PageReference previousPage() {
        confirmed = False;
        if (currentPageIndex == 0) {
            // cannot go back
            return new PageReference('/apex/RequalificationHome');
        }
        currentPageIndex -= 1;
        return viewDispatcher(currentRefSet[currentPageIndex]);
//      return currentRefSet[currentPageIndex];
    }

    public Boolean isLastPage {
        get {
            return currentPageIndex + 1 >= currentRefSet.size();
        }
    }

    private void insertOrUpdate() {
        if (requalRec.Id == Null) {
            insert requalRec;
        }
        else {
            update requalRec;
        }

    }

    public String UserConfirmed_By_Name {
        get {
            return  getUserName(requalRec.User_Confirmed_By__c);
        }
    }

    public String BusinessPlanConfirmed_By_Name {
        get {
            return  getUserName(requalRec.BusinessPlan_Confirmed_By__c);
        }
    }

    public String ProfileConfirmed_By_Name {
        get {
            return  getUserName(requalRec.Profile_Confirmed_By__c);
        }
    }

    public String CertConfirmed_By_Name {
        get {
            return  getUserName(requalRec.Cert_Confirmed_By__c);
        }
    }

    public String ProductConfirmed_By_Name {
        get {
            return  getUserName(requalRec.Product_Confirmed_By__c);
        }
    }

    public String PointsConfirmed_By_Name {
        get {
            return  getUserName(requalRec.points_Confirmed_By__c);
        }
    }

    public String CustRefConfirmed_By_Name {
        get {
            return  getUserName(requalRec.CustRef_Confirmed_By__c);
        }
    }

    public String AgreementConfirmed_By_Name {
        get {
            return  getUserName(requalRec.Agreement_Confirmed_By__c);
        }
    }

    public String FCPAConfirmed_By_Name {
        get {
            return  getUserName(requalRec.FCPA_Confirmed_By__c);
        }
    }

    public String SpecializationsConfirmed_By_Name {
        get {
            return  getUserName(requalRec.Specializations_Confirmed_By__c);
        }
    }

    private String getUserName(String userId) {
        if (userCache.containsKey(userId) == False) {
            List<User> users = [select Id, Name from User where Id = :userId];
            if (users.size() < 1) {
                return 'unknown';
            }
            userCache.put(users.get(0).Id, users.get(0));
        }
        return userCache.get(userId).Name;
    }

    public List<PartnerAgreement__c> partnerAgreementList {
        public get {
            List<PartnerAgreement__c> agreementList = [
                select  Id
                     ,  Agreement__r.Name
                     ,  Version__c
                     ,  Agreement__r.PartnerType__r.Name
                     ,  Agreement__r.Partner_Program__r.Program_Category__c
                     ,  Agreement__r.Id
                     ,  Agreement__c
                     ,  (select Id, Name from Attachments)
                     ,  PartnerApprovalStatus__c
                     ,  ActivationDate__c
                     ,  ExpirationDate__c
                  from  PartnerAgreement__c
                 where  Partner__c = :account.Id
            ];
            return agreementList;
        }
    }

    public Boolean hasAgreements {
        get {
            if (hasAgreements == null) {
                hasAgreements = !getAgreementList().isEmpty();
            }
            return hasAgreements;
        }
        set {
            hasAgreements = value;
        }
    }

    public Boolean getNoAgreements() {
        return !hasAgreements;
    }

    public List<Agreement__c> getAgreementList() {
        List<Agreement__c> agreementList = new List<Agreement__c>();

        Set<Id> programIds = new Set<Id>();
        for (Partner_Program__c ppm : [
                select Id, Program__c
                from Partner_Program__c
                where Account__c = :account.Id
                    and Status__c in ('Active')
            ]){
            programIds.add(ppm.Program__c);
        }

        System.assert(accountCountry != null, 'accountCountry is null');
        System.debug('Country = '  + accountCountry);
        System.debug('programIds = '  + programIds);

        // Here we are getting all the country-specific documents.
        Set<Id> agreementIdSet = new Set<Id>();
        List<Agreement_Country__c> agreementCountryList = [
            Select Agreement__c
              From Agreement_Country__c
             where Country__c = :accountCountry.Id
               and (( Agreement__r.PartnerType__c = :partnerStatus.PartnerType__c
                    and Agreement__r.Partner_Program__c = null )
               or ( Agreement__r.Partner_Program__c in :programIds
                    and Agreement__r.PartnerType__c = null ))

               and Agreement__r.ActivationStatus__c = 'Active'
               and Agreement__r.Type__c != 'User'
        ];

        for (Agreement_Country__c agreementCountry :agreementCountryList) {
            agreementIdSet.add(agreementCountry.Agreement__c);
        }

        System.debug('agreementIdSet = '  + agreementIdSet);

        if (agreementIdSet != null && agreementIdSet.size() > 0) {
            agreementList = [
                select  Id
                     ,  Name
                     ,  IsSignatureRequired__c
                     ,  Version__c
                     ,  (select Name from Attachments)
                     ,  PartnerType__c
                     ,  ApprovalStatus__c
                     ,  ActivationDate__c
                     ,  ExpirationDate__c
                  from  Agreement__c
                 where  Id IN :agreementIdSet
            ];
        }

        System.debug('agreementList = '  + agreementList);

        // Here we are getting all the global documents.
        List<Agreement__c> globalAgreementList  = [
                select Id
                     , Name
                     , IsSignatureRequired__c
                     , Version__c
                     , (select Name from Attachments)
                     ,  PartnerType__c
                     ,  ApprovalStatus__c
                     ,  ActivationDate__c
                     ,  ExpirationDate__c
                  from Agreement__c
                 where Country_Count__c = 0
                   and ActivationStatus__c = 'Active'
                   and Type__c != 'User'
                   and (( PartnerType__c = :partnerStatus.PartnerType__c
                        and Partner_Program__c = null )
                   or ( Partner_Program__c in :programIds
                        and PartnerType__c = null ))
        ];
        if (globalAgreementList != null && globalAgreementList.size() > 0) {
            for (Agreement__c globalAgreement :globalAgreementList) {
                agreementList.add(globalAgreement);
            }
        }
        return agreementList;
    }

    public List<Case> requestedCases {
        get {
            Id recordTypeId = [select Id from RecordType where DeveloperName = 'Request_Specialization'].Id;
            List<Case> cases = [
                select  id
                     ,  subject
                     ,  requester__c
                     ,  date_opened__c
                     ,  status
                     ,  specializations__c
                     ,  casenumber
                     ,  Contact.Name
                  from  Case
                 where  AccountId=:account.Id
                   and  RecordTypeId=:recordTypeId
                   and  Status in ('New', 'In Process', 'Submitted', 'Pending')
              order by  date_opened__c desc];
            return cases;
        }
    }

    public Boolean getIsSpecialized() {
        return  account.Finder_Partner_Type__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.RESELLER').ObjectId__c &&
                account.Select_Specialization_s__c != null &&
                account.Select_Specialization_s__c != '' &&
                account.Select_Specialization_s__c != 'Public Sector';

    }

    public Boolean hasProgram(String programName) {
        return [
            select  Id
            from    Partner_Program__c
            where   Account__c = :account.Id
            and     Status__c IN ('Active','Approved')
            and     Program_Name__c = :programName
        ].size() > 0;
    }

    private void removeAgreementPage() {
        for (Integer i = 0; i < currentRefSet.size(); i++) {
            if (currentRefSet.get(i).getUrl().endsWith('agreement')) {
                currentRefSet.remove(i);
                return;
            }
        }
    }

    public Boolean getIsReseller() {
        return  (partnerType.HierarchyKey__c == 'PARTNER_TYPE.RESELLER');
    }

    public Boolean getIsDisti() {
        return  (partnerType.HierarchyKey__c == 'PARTNER_TYPE.DISTRIBUTOR');
    }

//    public Boolean getIsRsiDist() {
//        return  (partnerType.HierarchyKey__c == 'PARTNER_TYPE.SI' || partnerType.HierarchyKey__c == 'PARTNER_TYPE.DISTRIBUTOR');
//    }

    public Boolean getIsResellerAandP() {
        return getIsResellerAdvanced() || getIsResellerPremier();
    }

    public Boolean getIsSI() {
        return partnerType.HierarchyKey__c == 'PARTNER_TYPE.SI';
    }

    public Boolean getIsOEM() {
        return partnerType.HierarchyKey__c == 'PARTNER_TYPE.OEM';
    }

    public Boolean getIsTraining() {
        return partnerType.HierarchyKey__c == 'PARTNER_TYPE.TRAINING';
    }

    public Boolean getIsCCSP() {
        return partnerType.HierarchyKey__c == 'PARTNER_TYPE.SERVICECLOUD_PROVIDER' && hasProgram(PartnerConst.CCNSP);
    }

    public Boolean getIsResellerAdvanced() {
        return  getIsReseller() && partnerTier.HierarchyKey__c == 'PARTNER_TIER.ADVANCED';
    }

    public Boolean getIsResellerPremier() {
        return  getIsReseller() && partnerTier.HierarchyKey__c == 'PARTNER_TIER.PREMIER';
    }

    public Boolean getIsRsiAdvanced() {
        return  getIsSI() && partnerTier.HierarchyKey__c == 'PARTNER_TIER.ADVANCED';
    }

    public Boolean getIsRsiPremier() {
        return  getIsSI() && partnerTier.HierarchyKey__c == 'PARTNER_TIER.PREMIER';
    }

    public Boolean getIsResellerReady() {
        return getIsReseller() && (partnerTier.HierarchyKey__c == 'PARTNER_TIER.READY');
    }

    public Boolean getIsISV() {
        return partnerType.HierarchyKey__c == 'PARTNER_TYPE.ISV';
    }

    public Boolean getIsCCP() {
        //US79277: Skip Agreements section for CCP
    	//return partnerType.HierarchyKey__c == 'PARTNER_TYPE.SERVICECLOUD_PROVIDER';
        return hasProgram(PartnerConst.CCP);
    }

    // Industry focus
//    public List<SelectOption> getIndustryFocusOptions() {
//        return getSelectOptions(PartnerRequalification__c.FCPAIndustryFocus__c.getDescribe().getPicklistValues());
//    }

    public List<SelectOption> getSelectOptions(List<Schema.PicklistEntry> picklistEntryList) {
        List<SelectOption> selectOptionList = new List<SelectOption>();

        for(Schema.PicklistEntry p : picklistEntryList)
            selectOptionList.add(new SelectOption(p.Value, p.Label));

        return selectOptionList;
    }

    private String getTranslatedClfn(ID clfnId, String defaultValue) {

        if (clfnsTranslationCache == null){
            clfnsTranslationCache = new Map<String,String>();
            for (ClassificationTranslation__c ct : [
                    select Classification__c, LanguageCode__c, Translation__c
                      from ClassificationTranslation__c
                      where LanguageCode__c = :UserInfo.getLanguage()
            ]){
                clfnsTranslationCache.put(ct.Classification__c + UserInfo.getLanguage(), ct.Translation__c);
                //System.debug('---------------------' + ct.Classification__c + UserInfo.getLanguage() + ' - ' + ct.Translation__c);
            }
        }

        if (clfnsTranslationCache.containsKey(clfnId + '_' + UserInfo.getLanguage()))
        {
            return clfnsTranslationCache.get(clfnId + '_' + UserInfo.getLanguage());
        }
        return defaultValue;
    }

    public PartnerRequalification__c getRequalRec() {
        return requalRec;
    }

    public void loadAccountOwner(Id accountId) {
        if (getIsResellerReady() && account.Global_Region__c == 'NA') {
            Id ownerId = null;
            List<AccountTeamMember> members = [
                select  UserId
                  from  AccountTeamMember
                 where  AccountId = :accountId
                   and  TeamMemberRole = 'Partner Relationship Manager - Regional'
                 limit  1
            ];
            if (members == null || members.size() == 0) {
                ownerId = account.OwnerId;
            }
            else {
                ownerId = members.get(0).UserId;
            }
            accountContact = [select Id, Name, Email, Phone from User where Id = :ownerId];
        }
        else {
            accountContact = [select Id, Name, Email, Phone from User where Id = :account.OwnerId];
        }
    }

    public String accountContactName {
        get {
            return accountContact.Name;
        }
    }

    public String accountContactEmail {
        get {
            return accountContact.Email;
        }
    }

}