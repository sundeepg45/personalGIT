trigger Account_RollupPartnerStatuses on Account (before update) {
/***
    //
    // Reset the existing partner status rollup field
    //
//    Map<Id,RecordType> partnerRecordMap = new Map<Id,RecordType>([Select r.SobjectType, r.Name, r.Id From RecordType r where r.SobjectType='Account' and r.Name like '%Partner']);
    Set<Id> accountIdSet = new Set<Id>();
    for(Account account : Trigger.new) {
//      if (partnerRecordMap.containsKey(account.RecordTypeId)) {
            accountIdSet.add(account.Id);
//      }
        account.PartnerStatuses__c ='';
    }
    List<PartnerStatus__c> partnerStatusList = [select Partner__c, CombinedName__c from PartnerStatus__c where ActivationStatus__c = 'Active' and Partner__c in :accountIdSet order by Partner__c, CombinedName__c];
    Map<Id, List<String>> accountPartnerStatusMap = new Map<Id, List<String>>();
    for(PartnerStatus__c partnerStatus : partnerStatusList) {
        if (!accountPartnerStatusMap.containsKey(partnerStatus.Partner__c)) {
            accountPartnerStatusMap.put(partnerStatus.Partner__c, new List<String>());
        }
        accountPartnerStatusMap.get(partnerStatus.Partner__c).add(partnerStatus.CombinedName__c);
    }
    Integer index=0;
    for(Account account : Trigger.new) {
        if (!accountPartnerStatusMap.containsKey(account.Id) || accountPartnerStatusMap.get(account.Id).size() == 0) {
             continue;
        }
        index=0;
        for(String combinedName : accountPartnerStatusMap.get(account.Id)) {
             if (combinedName == null || combinedName == '') {
                continue;
             }
             if (index ==0) {
                 account.PartnerStatuses__c = combinedName;
             } else {
                account.PartnerStatuses__c += ';';
                account.PartnerStatuses__c += combinedName;
             }
             index++;
        }
    }
***/

/*
    for(Account account : Trigger.new) {
        account.PartnerStatuses__c = 'None'; 
    }
    //
    // Find and store all of the related partner statuses
    //
    
    Map<Id, List<String>> accountPartnerStatusMap = new Map<Id, List<String>>();
    Map<Id, List<Boolean>> accountPartnerStatusMapGlobal = new Map<Id, List<Boolean>>();
 
    
    for(Account account : Trigger.new){
        accountPartnerStatusMap.put(account.Id, new List<String>());
        accountPartnerStatusMapGlobal.put(account.Id, new List<Boolean>());
    }
    
    List<PartnerStatus__c> partnerStatusList = [
        select Partner__c
             , CombinedName__c
             , Global__c
          from PartnerStatus__c
         where ActivationStatus__c = 'Active'
           and Partner__c in :Trigger.new
      order by Partner__c, CombinedName__c
    ];
       
    for (PartnerStatus__c partnerStatus : partnerStatusList){
           accountPartnerStatusMap.get(partnerStatus.Partner__c).add(partnerStatus.CombinedName__c);
           accountPartnerStatusMapGlobal.get(partnerStatus.Partner__c).add(partnerStatus.Global__c);
    }            

    //
    // Roll back up to the account level
    //

    for(Account account : Trigger.new) {
        if (accountPartnerStatusMap.get(account.Id).size() == 0) {
            account.PartnerStatuses__c = '';        // Partner Finder depends on this field being blank to indicate inactive
            continue;
        }

        for(String combinedName : accountPartnerStatusMap.get(account.Id)) {
            if (combinedName == null || combinedName == '')
                continue;
                
            if (account.PartnerStatuses__c == 'None') {
                account.PartnerStatuses__c = combinedName;
                account.Global__c = TRUE;
            } else {
                account.PartnerStatuses__c += ';';
                account.PartnerStatuses__c += combinedName;
            }

        }
        
        for(Boolean globalStatus : accountPartnerStatusMapGlobal.get(account.Id)) 
            account.Global__c = globalStatus;
        
        
    }
*/
}