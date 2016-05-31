trigger Account_UpdateAccountPortalSharingRule on Account (after insert, after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
/*
    List<ServiceMessage__c> serviceMessageList = new List<ServiceMessage__c>();
    DOM.Document serviceMessageDocument;
    DOM.XmlNode serviceMessageDocumentXml;
    DOM.XmlNode serviceMessageXml;

    for(Account accountNew : Trigger.new) {
        if (!accountNew.IsPartner) {
            continue;
        }
        serviceMessageDocument = new DOM.Document();
        serviceMessageDocumentXml = serviceMessageDocument.createRootElement('envelope', System.Label.NS_SOAP, 'soap');
        serviceMessageXml = serviceMessageDocumentXml.addChildElement('body', System.Label.NS_SOAP, null);
        serviceMessageXml.setNamespace('service', System.Label.NS_SERVICE);
        serviceMessageXml.setAttributeNS('generatedBy', 'Trigger.Account_UpdateAccountPortalSharingRule', System.Label.NS_SERVICE, null);
        serviceMessageXml.setAttributeNS('accountId', accountNew.Id, System.Label.NS_SERVICE, null);
        serviceMessageList.add(new ServiceMessage__c(Command__c = '/account/update-sharing-rule/set-rule-editable', Payload__c = serviceMessageDocument.toXmlString()));
    }

    if (serviceMessageList.size() != 0) {
        insert serviceMessageList;
    }
*/

    if (Test.isRunningTest()) {
        return;
    }

    AccountShare[] shares =  [Select Id, RowCause, AccountAccessLevel, Account.IsPartner
                        FROM AccountShare
                        where RowCause = 'PortalImplicit' and AccountAccessLevel =
                        'Read' and Account.Id in :Trigger.newMap.keySet()];

    for (AccountShare share : shares) {
        share.AccountAccessLevel = 'Edit';
        //share.CaseAccessLevel = 'Edit';         //to fix US78035 (RH-00488687) - Kiran on 1/7/16
    }
    try {
        if (shares.size() > 0) {
            update shares;
        }
    } catch (Exception e) {
        System.debug(e);
    }
}