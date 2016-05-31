public with sharing class PreviousPartnerInfo {


/*
    public static void inactivate(Set<Id> previousPartnerIDs) {
        List<PartnerStatus__c> updatePartnerStatusList =new List<PartnerStatus__c>();
        for(Id previousPartnerStatusID : previousPartnerIDs) {
            PartnerStatus__c partnerStatus = new PartnerStatus__c(Id=previousPartnerStatusID );
            System.debug('previousPartnerStatusID-------------->'+ previousPartnerStatusID );
            partnerStatus.ExpirationDate__c = System.today();
            partnerStatus.IsVisible__c = false;
            updatePartnerStatusList.add(partnerStatus);
        }
        if (updatePartnerStatusList.size() > 0) {
            update updatePartnerStatusList;
        }
     }
*/
/*
	 public static void markAllOldStatusesInvisible(Id accountId){
 		List<PartnerStatus__c> psList = [select Id
 											from 	PartnerStatus__c
 										 	where 	Partner__c = :accountId
 										 		and ActivationStatus__c = 'Expired'
 										 		and IsVisible__c = True];
	 	if (psList.size() > 0){
	        for(PartnerStatus__c ps : psList){
	        	ps.IsVisible__c = false;
		 	}
	 		update psList;
	 	}
	 }
*/

/*
     private static  Map<Id,PartnerStatus__c> getCurrentPartnerStatusGivenPreviousIds(Set<Id> previousPartnerIDs) {
        Map<Id, PartnerStatus__c> partnerStatusMap = new Map<Id, PartnerStatus__c>();
        List<PartnerStatus__c> partnerStatusList = [Select p.Previous_Partner_Status__c, p.Id, p.ActivationDate__c From PartnerStatus__c p Where p.Previous_Partner_Status__c IN : previousPartnerIDs ];
        if (partnerStatusList != null && partnerStatusList.size() > 0) {
            for(PartnerStatus__c partnerStatus : partnerStatusList) {
                partnerStatusMap.put(partnerStatus.Previous_Partner_Status__c, partnerStatus);
            }
        }
        return partnerStatusMap;
     }
*/

}