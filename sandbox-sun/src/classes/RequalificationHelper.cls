public with sharing class RequalificationHelper {


    public static void markOverdueAccounts(Set<Id> overdueAccounts) {
        List<Partner_Program__c> psList = [
            select      Id
            from        Partner_Program__c
            where       Is_Primary__c = true
            and         Account__c in :overdueAccounts
        ];
        for (Partner_Program__c pgm : psList) {
            pgm.Tier__c = PartnerConst.UNAFFILIATED_RENEWAL;
        }
        update psList;
    }

    public static void reinstateOverdueAccounts(Set<Id> overdueAccounts){
        List<Partner_Program__c> psList = [
            select      Id,
                        Program_Name__c
            from        Partner_Program__c
            where       Is_Primary__c = true
            and         Account__c in :overdueAccounts
        ];
        for (Partner_Program__c pgm : psList) {
            System.debug('Program Name --> ' + pgm.Program_Name__c);
            pgm.Tier__c = PartnerConst.READY;
            if (pgm.Program_Name__c == 'Distributor' || pgm.Program_Name__c == 'Alliance Partner/OEM') {
                pgm.Tier__c = PartnerConst.AFFILIATED;
            }
            if (pgm.Program_Name__c == 'Service/Cloud Provider') {
                pgm.Tier__c = PartnerConst.ADVANCED;
            }
        }
        update psList;
    }

    //@future
    /*
    public static void markOverdueAccounts(Set<Id> overdueAccounts){
        Classification__c unaffiliatedTier = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.UNAFFILIATED__RENEWAL_NOT_MET'];
        List<PartnerStatus__c> psList = [select Id,
                                                ApprovalStatus__c,
                                                PartnerType__c,
                                                PartnerTier__c,
                                                Partner__c
                                            from PartnerStatus__c
                                            where ApprovalStatus__c = 'Approved'
                                                and ActivationStatus__c = 'Active'
                                                and Partner__c in :overdueAccounts];
        List<PartnerStatus__c> newPsList = new List<PartnerStatus__c>();
        for (PartnerStatus__c ps : psList){
            ps.IsVisible__c = false;
            ps.ExpirationDate__c = System.today();

            PartnerStatus__c psUnaf = new PartnerStatus__c();
            psUnaf.PartnerType__c = ps.PartnerType__c;
            psUnaf.PartnerTier__c = unaffiliatedTier.Id;
            psUnaf.Partner__c = ps.Partner__c;
            psUnaf.IsVisible__c = false;
            psUnaf.ApprovalStatus__c = 'Approved';
            psUnaf.ActivationDate__c = ps.ExpirationDate__c;
            //psUnaf.ExpirationDate__c = ps.ExpirationDate__c.addYears(1);
            psUnaf.ExpirationDate__c = null;
            psUnaf.Previous_Partner_Status__c = ps.Id;
            newPsList.add(psUnaf);
        }
        if (newPsList.size() > 0){
            insert newPsList;
        }
//        ID[] idList = new List<ID>();
//        for (PartnerStatus__c ps : newPsList) {
//          idList.add(ps.Id);
//        }
//        approveStatuses(idList);
//      update newPsList;
        if (psList.size() > 0){
            update psList;
        }
        PartnerStatus_UpdateAccount.updateAccountFields(overdueAccounts);
    }

    @future
    static private void approveStatuses(Id[] statusIdList) {
        PartnerStatus__c[] psList = new List<PartnerStatus__c>();
        for (Id i : statusIdList) {
            psList.add(new PartnerStatus__c(Id = i, ApprovalStatus__c = 'Approved'));
        }
        update psList;
    }

    public static void reinstateOverdueAccounts(Set<Id> overdueAccounts){
        Classification__c readyTier = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.READY'];
        List<PartnerStatus__c> psList = [select Id,
                                                ApprovalStatus__c,
                                                PartnerType__c,
                                                PartnerTier__c,
                                                Partner__c
                                            from PartnerStatus__c
                                            where ApprovalStatus__c = 'Approved'
                                                and ActivationStatus__c = 'Active'
                                                and Partner__c in :overdueAccounts];
        List<PartnerStatus__c> newPsList = new List<PartnerStatus__c>();
        for (PartnerStatus__c ps : psList){
            ps.IsVisible__c = false;
            ps.ExpirationDate__c = System.today();

            PartnerStatus__c psReadyReseller = new PartnerStatus__c();
            psReadyReseller.PartnerType__c = ps.PartnerType__c;
            psReadyReseller.PartnerTier__c = readyTier.Id;
            psReadyReseller.Partner__c = ps.Partner__c;
            psReadyReseller.IsVisible__c = false;
            psReadyReseller.ApprovalStatus__c = 'Approved';
            psReadyReseller.ActivationDate__c = ps.ExpirationDate__c;
            //psReadyReseller.ExpirationDate__c = ps.ExpirationDate__c.addYears(1);
            psReadyReseller.ExpirationDate__c = null;
            psReadyReseller.Previous_Partner_Status__c = ps.Id;
            newPsList.add(psReadyReseller);
        }
        if (newPsList.size() > 0){
            insert newPsList;
        }
        if (psList.size() > 0){
            update psList;
        }
    }
    */

    public static Partner_Requal_Points__c getSpecializationPoints(Partner_Requal_Points__c rp, String accountId) {
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
        rp.Sales_Users__c = acct.Total_Partner_Sales_Certifications__c;
        rp.PreSales_Users__c = acct.Total_Pre_sales_Course_Completions__c;
        rp.Delivery_Users__c = acct.Total_Partner_Delivery_Certifications__c;
        return rp;
    }
}