trigger Account_OwnerNameDisplays on Account (after insert, after update) {
    /*
    List<ServiceMessage__c> serviceMessageList = new List<ServiceMessage__c>();
    DOM.Document serviceMessageDocument;
    DOM.XmlNode serviceMessageDocumentXml;
    DOM.XmlNode serviceMessageXml;
    Integer i = -1;

    for(Account accountNew : Trigger.new) {
        i++;
      if (!accountNew.IsPartner || (Trigger.old[i] != null && accountNew.OwnerId == Trigger.old[i].OwnerId)) {
        continue;
      }
        serviceMessageDocument = new DOM.Document();
        serviceMessageDocumentXml = serviceMessageDocument.createRootElement('envelope', System.Label.NS_SOAP, 'soap');
        serviceMessageXml = serviceMessageDocumentXml.addChildElement('body', System.Label.NS_SOAP, null);
        serviceMessageXml.setNamespace('service', System.Label.NS_SERVICE);
        serviceMessageXml.setAttributeNS('generatedBy', 'Trigger.OwnerNameDisplays', System.Label.NS_SERVICE, null);
        serviceMessageXml.setAttributeNS('accountId', accountNew.Id, System.Label.NS_SERVICE, null);
        serviceMessageList.add(new ServiceMessage__c(Command__c = '/account/update-ownername-rule/set-account-ownername', Payload__c = serviceMessageDocument.toXmlString()));
    }
    
    if (serviceMessageList.size() != 0) {
        insert serviceMessageList;
    }
    */
}