public with sharing class PartnerSpecializationExtension {

    public Account account {get; set;}

    public boolean hasCloud { get; set; }
    public boolean hasDCI { get; set; }
    public boolean hasMWS { get; set; }
    public boolean hasPublicSector { get; set; }
    public Boolean cloudSelected { get; set; }
    public Boolean DCISelected { get; set; }
    public Boolean MWSSelected { get; set; }
    public Boolean publicSectorSelected {get; set; }
    
    public String globalRegion {get; set; }

    public list<Case> cases { get; set; }

    public PartnerSpecializationExtension(ApexPages.StandardController controller) {
        account = (Account) controller.getRecord();
        setup();
    }
    
    public PartnerSpecializationExtension(Account acct) {
        account = acct;
        setup();
    }

    public PartnerSpecializationExtension() {
        setup();
    }

    public void setup() {

        User me = [select Contact.AccountId from User where Id = :UserInfo.getUserId()];

        Account a = new Account();
        if (me.ContactId != null){
            Id accountId = me.Contact.AccountId;
            if (accountId != null){
                a = [select id, select_specialization_s__c, Global_Region__c from Account where Id = :accountId];
                globalRegion = a.Global_Region__c;
            }
        }else if(account!=null){
            a = [SELECT select_specialization_s__c FROM Account WHERE id = :account.id];
        }

        if(a.select_specialization_s__c != null && a.select_specialization_s__c != ''){
            hasPublicSector = a.select_specialization_s__c.contains('Public Sector');
            hasCloud = a.select_specialization_s__c.contains('Cloud Infrastructure');
            hasMWS = a.select_specialization_s__c.contains('Middleware Solutions');
            hasDCI = a.select_specialization_s__c.contains('Data Center Infrastructure');
        }else{
            hasPublicSector = false;
            hasCloud = false;
            hasMWS = false;
            hasDCI = false;
        }
        
        publicSectorSelected = hasPublicSector;
        cloudSelected = hasCloud;
        DCISelected = hasDCI;
        MWSSelected = hasMWS;
    }

    public PageReference doRequestCase() {

        cases = new List<Case>();

        if (publicSectorSelected && !hasPublicSector) {
            createCase(System.Label.Partner_Specialization_Public_Sector, cases);
        }
        if (cloudSelected && !hasCloud) {
            createCase(System.Label.Partner_Specialization_Cloud, cases);        
        }
        if (DCISelected && !hasDCI) {
            createCase(System.Label.Partner_Specialization_DCI, cases);
        }
        if (MWSSelected && !hasMWS) {
            createCase(System.Label.Partner_Specialization_MWS, cases);        
        }

        if (cases.size() > 0 && !test.isRunningTest()) {
            insert cases;
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, System.Label.Partner_Specialization_submitted));
        }
        return null;
    }
    
    private void createCase(String subject, List<Case> cases) {
        Case c = new Case();
        c.AccountId = account.id;
        c.Specializations__c = subject;
        c.RecordTypeId = [select Id from RecordType where DeveloperName = 'Request_Specialization'].Id;
        c.Priority = 'Medium';
        c.Requester__c = UserInfo.getName();
        c.Specializations__c = subject;
        c.Subject = 'Partner Request Specialization';

        c.ContactId = [select ContactId from User where id = :UserInfo.getUserId()].ContactId;
        Database.Dmloptions dmo = new Database.Dmloptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        c.setOptions(dmo);        
        
        cases.add(c);
    }
/*
* Commented out by Shawn Cureton : Dec. 5, 2013
* This functionality was replaced by a multi-select picklist on the Account record

    public Boolean hasVirtualization {
        get {
            for (PartnerClassification__c pc : specList) {
                if (pc.classification__r.hierarchykey__c == 'PARTNER_CLASSIFICATION.SPECIALIZATION.VIRTUALIZATION') {
                    return True;
                }
            }
            return False;
        }
    }

    public Boolean hasPublicSector {
        get {
            for (PartnerClassification__c pc : specList) {
                if (pc.classification__r.hierarchykey__c == 'PARTNER_CLASSIFICATION.SPECIALIZATION.PUBLIC_SECTOR') {
                    return True;
                }
            }
            return False;
        }
    }
    
    public Boolean hasCloud {
        get {
            for (PartnerClassification__c pc : specList) {
                if (pc.classification__r.hierarchykey__c == 'PARTNER_CLASSIFICATION.SPECIALIZATION.CLOUD') {
                    return True;
                }
            }
            return False;
        }
    }

    public Boolean hasRHEL {
        get {
            for (PartnerClassification__c pc : specList) {
                if (pc.classification__r.hierarchykey__c == 'PARTNER_CLASSIFICATION.SPECIALIZATION.RHEL') {
                    return True;
                }
            }
            return False;
        }
    }
    
    public Boolean hasStorage {
        get {
            for (PartnerClassification__c pc : specList) {
                if (pc.classification__r.hierarchykey__c == 'PARTNER_CLASSIFICATION.SPECIALIZATION.STORAGE') {
                    return True;
                }
            }
            return False;
        }
    }
    public Boolean hasJboss {
        get {
            for (PartnerClassification__c pc : specList) {
                if (pc.classification__r.hierarchykey__c == 'PARTNER_CLASSIFICATION.SPECIALIZATION.JBOSS') {
                    return True;
                }
            }
            return False;
        }
    }
*/
}