global class PartnerProducPublishing {

  WebService static void PartnerProducPublishing(String ppId) {
    if (ppId == null || ppId.length() == 0) {
        return;
    }
    PartnerProduct__c pproduct = [select id, Application_Visibility__c from PartnerProduct__c where Id = :ppId];
    if (pproduct.Application_Visibility__c == 'Visible') {
      pproduct.Application_Visibility__c = 'Hidden';
      update pproduct;
    }
    else {
        pproduct.Application_Visibility__c = 'Visible';
        update pproduct;
    }
  }
  
}