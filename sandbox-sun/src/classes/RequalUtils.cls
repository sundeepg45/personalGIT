public with sharing class RequalUtils {
	
    public static Map<String,List<PartnerTraining__c>> sortCertifications(Id accountId){
		return sortCertifications(accountId, false);
    }
	

	public static Map<String,List<PartnerTraining__c>> sortCertifications(Id accountId, Boolean validCertsOnly){

        List<PartnerTraining__c> techCerts = new List<PartnerTraining__c>();
        List<PartnerTraining__c> salesCerts = new List<PartnerTraining__c>();
        List<PartnerTraining__c> salesMiddleware = new List<PartnerTraining__c>();
        List<PartnerTraining__c> salesCloud = new List<PartnerTraining__c>();
        List<PartnerTraining__c> salesDCI = new List<PartnerTraining__c>();
        List<PartnerTraining__c> salesEngineerCerts = new List<PartnerTraining__c>();
        List<PartnerTraining__c> salesEngineerMiddleware = new List<PartnerTraining__c>();
        List<PartnerTraining__c> salesEngineerCloud = new List<PartnerTraining__c>();
        List<PartnerTraining__c> salesEngineerDCI = new List<PartnerTraining__c>();
        List<PartnerTraining__c> deliveryCerts = new List<PartnerTraining__c>();
        List<PartnerTraining__c> deliveryMiddleware = new List<PartnerTraining__c>();
        List<PartnerTraining__c> deliveryCloud = new List<PartnerTraining__c>();
        List<PartnerTraining__c> deliveryDCI = new List<PartnerTraining__c>();

        Set<id> deliveryMiddlewareCertHolders = new Set<id>();
        Set<id> deliveryCloudCertHolders = new Set<id>();
        Set<id> deliveryDCICertHolders = new Set<id>();

        Set<id> salesMiddlewareCertHolders = new Set<id>();
        Set<id> salesCloudCertHolders = new Set<id>();
        Set<id> salesDCICertHolders = new Set<id>();

        Set<id> salesEngineerMiddlewareCertHolders = new Set<id>();
        Set<id> salesEngineerCloudCertHolders = new Set<id>();
        Set<id> salesEngineerDCICertHolders = new Set<id>();

        Set<id> techCertHolders = new Set<id>();
        
        String ptQuery = 'select  Id ' + 
                	',   Accreditation_Name__c ' +
                    ' ,  CertificateNumber__c ' +
                     ',  Certificate_Owner__c ' +
                     ',  Certification_Key__c ' +
                     ',  Certification__c ' +
                     ',  Certification__r.Name ' +
                     ',  Certification__r.HierarchyKey__c ' +
                     ',  Certifying_Entity__c ' +
                     ',  Contact__c ' +
                     ',  Contact__r.Name ' +
                     ',  Date_Achieved__c ' +
                     ',  IsActive__c ' +
                     ',  IsValid__c ' +
                     ',  LMS_Assignment__r.Training_Path__c ' +
                     ',  LMS_Assignment__r.Training_Path__r.Name ' +
                     ',  LMS_Assignment__r.Training_Path__r.Partner_Function__c ' +
                     ',  RedHatValidated__c ' +
                     ',  Track__c ' +
                     ',  TrainingType__c ' +
                     ',  TrainingType__r.Name ' +
                 ' from  PartnerTraining__c ' +
                 ' where  Partner__c = \'' + accountId + '\'' +
                    ' and IsActive__c = true ';
                    
		if(!validCertsOnly) ptQuery+= ' and IsValid__c = true ';                    
        
        for (PartnerTraining__c cert : Database.query(ptQuery) ){
            if(cert.Track__c!=null && cert.Track__c!=''){
                if(cert.Track__c.startsWith('Sales Engineer')){
                    if(!salesEngineerMiddlewareCertHolders.contains(cert.Contact__c) && !salesEngineerCloudCertHolders.contains(cert.Contact__c) &&
                        !salesEngineerDCICertHolders.contains(cert.Contact__c)){
                        salesEngineerCerts.add(cert);
                    }
                    if(cert.Track__c.contains('Middleware Solutions') && !salesEngineerMiddlewareCertHolders.contains(cert.Contact__c)){
                        salesEngineerMiddleware.add(cert);
                        salesEngineerMiddlewareCertHolders.add(cert.Contact__c);
                    }else if(cert.Track__c.contains('Cloud Infrastructure') & !salesEngineerCloudCertHolders.contains(cert.Contact__c)){
                        salesEngineerCloud.add(cert);
                        salesEngineerCloudCertHolders.add(cert.Contact__c);
                    }else if(cert.Track__c.contains('Data Center Infrastructure') & !salesEngineerDCICertHolders.contains(cert.Contact__c)){
                        salesEngineerDCI.add(cert);
                        salesEngineerDCICertHolders.add(cert.Contact__c);
                    }
                }else if(cert.Track__c.startsWith('Sales')){
                    if(!salesMiddlewareCertHolders.contains(cert.Contact__c) && !salesCloudCertHolders.contains(cert.Contact__c) &&
                            !salesDCICertHolders.contains(cert.Contact__c)){
                        salesCerts.add(cert);
                    }
                    if(cert.Track__c.contains('Middleware Solutions') && !salesMiddlewareCertHolders.contains(cert.Contact__c)){
                        salesMiddleware.add(cert);
                        salesMiddlewareCertHolders.add(cert.Contact__c);
                    }else if(cert.Track__c.contains('Cloud Infrastructure') & !salesCloudCertHolders.contains(cert.Contact__c)){
                        salesCloud.add(cert);
                        salesCloudCertHolders.add(cert.Contact__c);
                    }else if(cert.Track__c.contains('Data Center Infrastructure') & !salesDCICertHolders.contains(cert.Contact__c)){
                        salesDCI.add(cert);
                        salesDCICertHolders.add(cert.Contact__c);
                    }
                }else if(cert.track__c.startsWith('Delivery')){
                    if(!deliveryMiddlewareCertHolders.contains(cert.Contact__c) && !deliveryCloudCertHolders.contains(cert.Contact__c) &&
                            !deliveryDCICertHolders.contains(cert.Contact__c)){
                        deliveryCerts.add(cert);
                    }
                    if(cert.Track__c.contains('Middleware Solutions') && !deliveryMiddlewareCertHolders.contains(cert.Contact__c)){
                        deliveryMiddleware.add(cert);
                        deliveryMiddlewareCertHolders.add(cert.Contact__c);
                    }else if(cert.Track__c.contains('Cloud Infrastructure') & !deliveryCloudCertHolders.contains(cert.Contact__c)){
                        deliveryCloud.add(cert);
                        deliveryCloudCertHolders.add(cert.Contact__c);
                    }else if(cert.Track__c.contains('Data Center Infrastructure') & !deliveryDCICertHolders.contains(cert.Contact__c)){
                        deliveryDCI.add(cert);
                        deliveryDCICertHolders.add(cert.Contact__c);
                    }
                }
            }else if(cert.Certification_Key__c!=null && cert.Certification_Key__c!=''){ 
                if(cert.Certification_Key__c.startsWith('PARTNER_TRAINING.RED_HAT') && !cert.Certification_Key__c.contains('PRESALES')
                    && !cert.Certification_Key__c.contains('SALESPERSON')){
                    if(cert.Contact__c!=null){
                        if(!techCertHolders.contains(cert.Contact__c)){
                            techCerts.add(cert);
                            techCertHolders.add(cert.Contact__c);
                        }
                    }else{
                    techCerts.add(cert);
                    }
                }
            }
        }

        Map<String,List<PartnerTraining__c>> accredSpecToCount = new Map<String,List<PartnerTraining__c>>{'techCerts'=>techCerts,'salesCerts'=>salesCerts,
            'salesMiddleware'=>salesMiddleware,'salesCloud'=>salesCloud,'salesDCI'=>salesDCI,'salesEngineerCerts'=>salesEngineerCerts,
            'salesEngineerDCI'=>salesEngineerDCI,'salesEngineerMiddleware'=>salesEngineerMiddleware,'salesEngineerCloud'=>salesEngineerCloud,
            'deliveryCerts'=>deliveryCerts,'deliveryMiddleware'=>deliveryMiddleware,'deliveryCloud'=>deliveryCloud,'deliveryDCI'=>deliveryDCI};

        return accredSpecToCount;

    }

    public static list<List<Customer_Reference__c>> loadCustomerReferences(Account account, List<Customer_Reference__c> expiredRefs,
                                                                            List<Customer_Reference__c> activeRefs) {


        List<Customer_Reference__c> refs = [
            select  Company_Name__c
                 ,  CreatedDate
                 ,  Contact__r.Name
                 ,  Contact__r.Email
                 ,  Pl__c
                 ,  Please_describe_how_the_customer_benefit__c
                 ,  Approved_Date__c
                 ,  Date_Submitted__c
              from  Customer_Reference__c
             where  Account__c = :account.id
                and (Approved_Date__c != null
                    or Date_Submitted__c != null)
        ];

        for (Customer_Reference__c ref : refs) {
            if(ref.Date_Submitted__c != null && ref.Date_Submitted__c > account.RequalificationDate__c.addMonths(-12)){
                if (ref.Approved_Date__c == null || ref.Approved_Date__c > account.RequalificationDate__c.addMonths(-12)){
                    activeRefs.add(ref);    // assume good if pending      
                }else{
                   expiredRefs.add(ref);
               }
            }    
        }
        List<List<Customer_Reference__c>> resultLists = new List<List<Customer_Reference__c>>{expiredRefs, activeRefs};
        resultLists.add(activeRefs);
        resultLists.add(expiredRefs);
        return resultLists;
    }

    public static Partner_Requal_Points__c[] getRequalPoints(ID tier, ID type, String region, list<String> specList, 
                                                        ID accountId, Map<String,List<Integer>> specToAccreditedUserCount){

        Partner_Requal_Points__c[] requalPoints = new List<Partner_Requal_Points__c>();
        
        
        Partner_Point_Requal_Limits__c[] limits = [
            SELECT  Id, Delivery_Users__c, Delivery_Points__c,
                    Sales_Users__c, Sales_Points__c, PreSales_Users__c,
                    PreSales_Points__c, Specialization__c
            FROM   Partner_Point_Requal_Limits__c
            WHERE  Partner_Type__c = :type
            AND    Partner_Tier__c = :tier
            AND    Global_Region__c = :region
            AND    Specialization__c in :specList
            ];

        // Don't display anything if there are no requal limits records.
        if(limits==null)return null;
        
        Map<String,Partner_Point_Requal_Limits__c> specToRequalLimit = new Map<String,Partner_Point_Requal_Limits__c>();
        
        for (Partner_Point_Requal_Limits__c plimit : limits){
            specToRequalLimit.put(plimit.Specialization__c,plimit);
        }
        
        for(String spec : specList){
            if(spec=='Public Sector')continue;
            Partner_Requal_Points__c prp = new Partner_Requal_Points__c();
            Partner_Point_Requal_Limits__c plimit = specToRequalLimit.get(spec);
            prp.Sales_Points__c = 0;
            prp.PreSales_Points__c = 0;
            prp.Delivery_Points__c = 0;
            prp.Specialization__c = spec;
            prp.Needed_Sales_Points__c = plimit.Sales_Points__c;
            prp.Needed_Sales_Users__c = plimit.Sales_Users__c;
            prp.Needed_PreSales_Points__c = plimit.PreSales_Points__c;
            prp.Needed_PreSales_Users__c = plimit.PreSales_Users__c;
            prp.Needed_Delivery_Points__c = plimit.Delivery_Points__c;
            prp.Needed_Delivery_Users__c = plimit.Delivery_Users__c;
            getSpecializationPoints(prp, accountId, specToAccreditedUserCount);
            requalPoints.add(prp);
        }

        return requalPoints;        
    }

    public static Partner_Requal_Points__c getSpecializationPoints(Partner_Requal_Points__c rp, String accountId, 
                                                                    Map<String,List<Integer>> specToUserCount) {
        PP_Account_Points__c[] aplist = [
            select  Id, Sales_Points__c, PreSales_Points__c, Delivery_Points__c
            from    PP_Account_Points__c
            where   Account__c = :accountId
        ];
        PP_Account_Points__c ap = null;
        if (aplist.size() > 0) {
            ap = aplist.get(0);
        }
        Account acct = [
            select  Id, Total_Partner_Delivery_Certifications__c,
                    Total_Partner_Sales_Certifications__c,
                    Total_Pre_sales_Course_Completions__c
            from    Account
            where   Id = :accountId
        ];

        if (ap != null) {
            rp.Sales_Points__c = ap.Sales_Points__c;
            rp.PreSales_Points__c = ap.PreSales_Points__c;
            rp.Delivery_Points__c = ap.Delivery_Points__c;
        }
        rp.Specialization__c = rp.Specialization__c;
        rp.Sales_Users__c = specToUserCount.get(rp.Specialization__c)[0];
        rp.PreSales_Users__c = specToUserCount.get(rp.Specialization__c)[1];
        rp.Delivery_Users__c = specToUserCount.get(rp.Specialization__c)[2];
        return rp; 
    }

    public static SFDC_Channel_Account_Plan__c loadBusinessPlan(Id accountId){
        
        SFDC_Channel_Account_Plan__c businessPlan = null;
        try {
            businessPlan = [select 
                                Id, 
                                Business_Plan_Name__c,
                                Business_Plan_Version__c,
                                Fiscal_Year__c,
                                LastModifiedBy.Name,
                                Approval_Status__c
                            from SFDC_Channel_Account_Plan__c
                            where
                                Partner_Name__c = :accountId and
                                Approval_Status__c = 'Approved'];
        } catch (System.QueryException qE){
            System.debug('Query exception returned trying to find an active business plan ' + qE);
        }

        return businessPlan;
    }

    public static Boolean getIsPartnerUser() {
        User me = [select Id, Contact.AccountId from User where Id = :UserInfo.getUserId()];
        return me.Contact.AccountId != null;
    }

    public static Boolean getIsSpecialized(Account account) {
        return  account.Finder_Partner_Type__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.RESELLER').ObjectId__c &&
                account.Select_Specialization_s__c != null &&
                account.Select_Specialization_s__c != '' &&
                account.Select_Specialization_s__c != 'Public Sector';
    }
}