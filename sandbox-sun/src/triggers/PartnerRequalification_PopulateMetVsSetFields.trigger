trigger PartnerRequalification_PopulateMetVsSetFields on PartnerRequalification__c (before update) {
    List<PartnerRequalification__c> prqs = new List<PartnerRequalification__c>();
    Set<Id> accountIds = new Set<Id>();

    for (Integer x = 0; x < Trigger.new.size(); x++) {
        if (Trigger.new[x].PopulateMetVsSet__c && !Trigger.old[x].PopulateMetVsSet__c) {
            prqs.add(Trigger.new[x]);
            accountIds.add(Trigger.new[x].AccountId__c);
            Trigger.new[x].PopulateMetVsSet__c = False;
        }
    }

    if (prqs.size() > 0) {
        Map<Id, PartnerStatus__c> statusMap = new Map<Id, PartnerStatus__c>();
        for (PartnerStatus__c ps : [select Partner__c, PartnerType__r.HierarchyKey__c, PartnerTier__r.HierarchyKey__c from PartnerStatus__c where Partner__c in :accountIds]){
            statusMap.put(ps.Partner__c, ps);
        }

        Map<Id, Account> accountMap = new Map<Id, Account>();
        for (Account a : [select Id, Global_Region__c, Total_Partner_Technical_Certifications__c, Total_Partner_Sales_Certifications__c, Account_Specializations__c, RequalificationDate__c from Account where id in :accountIds]){
            accountMap.put(a.Id, a);
        }

        Map<Id, Integer> techCertCount = new Map<Id, Integer>();
        Map<Id, Integer> salesCertCount = new Map<Id, Integer>();
        Map<Id, Integer> custRefsCount = new Map<Id, Integer>();
        Map<Id, Integer> speczCount = new Map<Id, Integer>();

        for (Id id : accountIds) {
            techCertCount.put(id,accountMap.get(id).Total_Partner_Technical_Certifications__c == null ? 0 : Integer.valueOf(accountMap.get(id).Total_Partner_Technical_Certifications__c));
            salesCertCount.put(id,accountMap.get(id).Total_Partner_Sales_Certifications__c == null ? 0 : Integer.valueOf(accountMap.get(id).Total_Partner_Sales_Certifications__c));
            speczCount.put(id,accountMap.get(id).Account_Specializations__c == null ? 0 : Integer.valueOf(accountMap.get(id).Account_Specializations__c));
            custRefsCount.put(id,0);
        }

        //to-do: add logic to filter out CustomerRefs that are too old like in
        //RequalificationMetDashController
        for (Customer_Reference__c ref : [
                select  Account__c
                     ,  CreatedDate
                     ,  Approved_Date__c
                     ,  Date_Submitted__c
                  from  Customer_Reference__c
                 where  Account__c in :accountIds
                    and (Approved_Date__c != null
                        or Date_Submitted__c != null)]) {

                Account account = accountMap.get(ref.Account__c);

                if (ref.Approved_Date__c == null) {
                    custRefsCount.put(account.Id, custRefsCount.get(account.Id) + 1);
                }
                else if (ref.Approved_Date__c >= account.RequalificationDate__c.addMonths(-12)) {
                    custRefsCount.put(account.Id, custRefsCount.get(account.Id) + 1);
                }

            }

        for (PartnerRequalification__c pr : prqs){
            Account account = accountMap.get(pr.AccountId__c);

            pr.Sales_Certifications_Required__c = 0;
            pr.Technical_Certifications_Required__c = 0;
            pr.Customer_References_Required__c = 0;
            pr.Specializations_Required__c = 0;
            pr.Sales_Certifications_At_Submit__c = salesCertCount.get(pr.AccountId__c);
            pr.Technical_Certifications_At_Submit__c = techCertCount.get(pr.AccountId__c);
            pr.Customer_References_At_Submit__c = custRefsCount.get(pr.AccountId__c);
            pr.Specializations_At_Submit__c = speczCount.get(pr.AccountId__c);

            // edited 1/7/2014 in support of updates to requal requirements for specializations
            String hkey = statusMap.get(pr.AccountId__c).PartnerType__r.HierarchyKey__c;
            if (hkey == 'PARTNER_TYPE.RESELLER' || hkey == 'PARTNER_TYPE.SI' || hkey == 'PARTNER_TYPE.DISTRIBUTOR') {
                MetVsSetRequirements mvsr = new MetVsSetRequirements(account);
                String status;
                if (statusMap.get(pr.AccountId__c).PartnerTier__r.HierarchyKey__c == 'PARTNER_TIER.PREMIER') {
                    status = 'Premier';
                }
                else if(statusMap.get(pr.AccountId__c).PartnerTier__r.HierarchyKey__c == 'PARTNER_TIER.ADVANCED') {
                    status = 'Advanced';
                }
                else {
                    status = 'Ready';
                }
                MetVsSetRequirements.RegionStatusReq metReqs = mvsr.getReqs(account.Global_Region__c, status, mvsr.accountRevenue);
                pr.Sales_Certifications_Required__c = metReqs.Sales;
                // un-comment these once the necessary fields have been added
                //pr.Delivery_Certifications_Required__c = metReqs.Delivery
                //pr.Sales_Engineer_Certifications_Required__c = metReqs.SalesEngineer;
                pr.Technical_Certifications_Required__c = metReqs.Rhce;
                pr.Customer_References_Required__c = metReqs.CustomerRefs;
                pr.Specializations_Required__c = metReqs.Specializations;
            }
        }
    }
}