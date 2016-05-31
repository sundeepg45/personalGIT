public without sharing class PartnerTrainingController {
    
    private static final String REFERENCE_KEY_TYPE='PARTNER_TRAINING.%';
    
    public PartnerTraining__c partnerTraining {get; set;}
    public String category {get; set;}
    private Map<Id,Contact> contactMap {get; set;}
    private User currentUser {get; set;}
    public boolean standardUser {get; set;}
    private Set<String> autoValidatedCerts {get; set;}
    
    
    public PartnerTrainingController() {
        autoValidatedCerts = new Set<String>();
        if (ApexPages.currentPage().getParameters().get('id') != null) {
            this.partnerTraining = [
                select  Id
                     ,  Contact__c
                     ,  CertificateNumber__c
                     ,  Certification__c
                     ,  TrainingType__c
                     ,  Date_Achieved__c
                     ,  Certifying_Entity__c
                     ,  Certificate_Owner__c
                     ,  TrainingType__r.Name
                     ,  Certification__r.Name
                     ,  Partner__c
                     ,  Contact__r.Name
                     ,  LMSCreated__c
                  from  PartnerTraining__c
                 where  Id = :ApexPages.currentPage().getParameters().get('id')
            ];
        }
        else {
            this.partnerTraining = new PartnerTraining__c();
            if (ApexPages.currentPage().getParameters().get('accountId') != null){
                this.partnerTraining.Partner__c = ApexPages.currentPage().getParameters().get('accountId');
            }
        }
        this.contactMap = new Map<Id,Contact>();
        if (currentUser == null){                       
            currentUser = [
                        Select 
                            u.Id, 
                            u.Profile.Name, 
                            u.ContactId, 
                            u.Contact.Account.Id 
                        From 
                            User u 
                        Where 
                            u.Id = :UserInfo.getUserId() 
            ];
        }
        this.standardUser =(UserInfo.getUserType().equals('PowerPartner'))? false:true;
    }
    
    public PageReference removeCertification() {
        Id accountId = partnerTraining.Partner__c;
        delete partnerTraining;
        return new PageReference('/apex/PartnerCertificationsList?id=' + accountId);
    }

    public PageReference saveCertification() {
        
        System.debug('saveCertification ::partnerTraining.Partner__c----------->'+ partnerTraining.Partner__c);
        if ((partnerTraining.CertificateNumber__c == null || partnerTraining.CertificateNumber__c.trim().length() == 0) && !autoValidatedCerts.contains(partnerTraining.Certification__c)) {
            // Don't need cert number of the autvalidated sales certs 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,Label.Partner_Certification_CN_Empty));
        }
        if (partnerTraining.Date_Achieved__c == null ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Partner_Certification_DA_Empty));
        }
        if (partnerTraining.Certificate_Owner__c == null || partnerTraining.Certificate_Owner__c.trim().length() == 0) {
            if (partnerTraining.Contact__c == null ) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Partner_Certificate_Contact_Empty));
            }
        }
        if (!ApexPages.hasMessages() ) {
            if (partnerTraining.Id != null) {
                update partnerTraining;
            }
            else {
                if (partnerTraining.Contact__c != null ) {
                    partnerTraining.Certificate_Owner__c = contactMap.get(partnerTraining.Contact__c).Name;
                }
                if (!this.standardUser) {
                    partnerTraining.Partner__c = this.currentUser.Contact.Account.Id;
                }
                if (partnerTraining.Partner__c == null){
                    partnerTraining.Partner__c = ApexPages.currentPage().getParameters().get('accountId');
                }
                if (autoValidatedCerts.contains(partnerTraining.Certification__c)){
                    partnerTraining.IsValid__c = true;
                    partnerTraining.RedHatValidated__c = true;
                }
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Partner_Certification_Create_Msg));
                insert partnerTraining;
            }
            //return new PageReference('/'+partnerTraining.Id);
            //return new PageReference('/a1l/o');
            return new PageReference('/apex/PartnerCertificationsList?id=' + ApexPages.currentPage().getParameters().get('accountId'));

        }
        return null;
    }

    public PageReference cancel() {
        return new PageReference('/apex/PartnerCertificationsList?id=' + ApexPages.currentPage().getParameters().get('accountId'));
    }

    public List<SelectOption> getCertifyingEntityList() {
        return ClassificationsUtil.getSelectOptions(REFERENCE_KEY_TYPE, true, new SelectOption('', Label.Partner_Certification_Select_Certifying_Entity));
    } 
    
    public List<SelectOption> getCategories() {
        System.debug('partnerTraining.TrainingType__c--------->'+ partnerTraining.TrainingType__c);
        if (partnerTraining.TrainingType__c != null) {
            return ClassificationsUtil.getSelectOptionsByParentId(partnerTraining.TrainingType__c);
        } else {
            return null;
        }
    } 
    
    public List<SelectOption> getCertificationList() {
        /*
        System.debug('category--------->'+ category);
        if (category != null) {
            return getSubClassificationList(category);
        } else {
            return null;
        }
        */
        System.debug('partnerTraining.TrainingType__c--------->'+ partnerTraining.TrainingType__c);
        System.debug('getCertificationListpartnerTraining.Partner__c----------->'+ partnerTraining.Partner__c);
        if (partnerTraining.TrainingType__c != null) {
            SelectOption[] alltypes = ClassificationsUtil.getSelectOptionsByParentId(partnerTraining.TrainingType__c);
            SelectOption[] restrictedTypes = new List<SelectOption>();
            for (SelectOption otype : alltypes) {
                if (otype.getLabel().contains('Red Hat')) {                 
                    if (!otype.getLabel().contains('Salesperson') && !otype.getLabel().contains('Presales')) {
                        restrictedTypes.add(otype);
                    } else {
                        if (isAdminUser())
                        {
                            restrictedTypes.add(otype);
                            autoValidatedCerts.add(otype.getValue());
                        }
                    }
                }
                else {
                    restrictedTypes.add(otype);
                }
            }
            return restrictedTypes;
        } else {
            return null;
        }        
        
    }     
    
    private Boolean isAdminUser(){
        String profile = currentUser.Profile.Name;
        return 'Administrator - Level 1' == profile
                || 'Administrator - Level 2' == profile
                || 'Administrator - Operations' == profile;
    }
    
    public List<SelectOption> getContacts() {
        System.debug('partnerTraining.Partner__c----------->'+ partnerTraining.Partner__c);
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', Label.Partner_Certification_Select_Contact));
        List<Contact> contactList = null;
        Id accountId = null;
        
        if (ApexPages.currentPage().getParameters().get('accountId') != null){
            accountId = ApexPages.currentPage().getParameters().get('accountId');
            System.debug('URL AccountId----------->'+ accountId);
        } else if (this.standardUser) {
            accountId = partnerTraining.Partner__c;
            System.debug('AccountId----------->'+ accountId);
        } else {
            this.currentUser = [Select u.Id, u.Contact.Account.Id, u.ContactId From User u Where u.Id =: UserInfo.getUserId() ];
            accountId = this.currentUser.Contact.Account.Id;
        }
        contactList = [Select c.Name, c.Id, c.AccountId From Contact c where c.AccountId =:accountId];
        if (contactList != null && contactList.size() > 0) {
            for (Contact c : contactList) {
                options.add(new SelectOption(c.Id, c.Name));
                contactMap.put(c.Id,c);
            }
        }
        return options;
    }
    
    public static testMethod void test() {
        User user  = PartnerTestUtils.getAdminUser();
        //List<Classification__c> classifications = [Select c.Id From Classification__c c where c.Parent__r.ReferenceKey__c='PARTNER_TRAINING' And c.Descendents__c > 0 limit 1];
        
        Classification__c classification = new Classification__c();
        classification.Name = 'Partner Training';
        insert classification;
        
        Classification__c ciscoClassification = new Classification__c();
        ciscoClassification.Name = 'Cisco';
        ciscoClassification.Parent__c = classification.Id;
        insert ciscoClassification;
        
        Classification__c ciscoOtClassification = new Classification__c();
        ciscoOtClassification.Name = 'Cisco Other';
        ciscoOtClassification.Parent__c = ciscoClassification.Id;
        insert ciscoOtClassification;
        
        Classification__c ciscoSalesClassification = new Classification__c();
        ciscoSalesClassification.Name = 'Cisco Sales';
        ciscoSalesClassification.Parent__c = ciscoClassification.Id;
        insert ciscoSalesClassification;
        
        Account account = PartnerTestUtils.makeAccount('Test Acc',user);

        Contact cc = new Contact();
        cc.FirstName ='Apprivo FS';
        cc.LastName = 'Apprivo FS';
        cc.Email = 'test@apprivo.com';
        cc.AccountId = account.Id;
        insert cc;
        PartnerTraining__c partnerTrn = new PartnerTraining__c();
        PartnerTrainingController partnerTrainingCnt = new PartnerTrainingController();
        partnerTrainingCnt.currentUser = user;
        partnerTrainingCnt.standardUser = true;
        partnerTrainingCnt.partnerTraining.CertificateNumber__c ='1233';
        partnerTrainingCnt.partnerTraining.Date_Achieved__c =System.today();
        partnerTrainingCnt.partnerTraining.Certificate_Owner__c = 'Test';
        partnerTrainingCnt.partnerTraining.Certification__c = classification.Id;
        //partnerTrainingCnt.partnerTraining.TrainingType__c = classifications.get(0).Id;
        partnerTrainingCnt.partnerTraining.TrainingType__c = classification.Id;
        partnerTrainingCnt.partnerTraining.Partner__c = account.Id;
        partnerTrainingCnt.getCertifyingEntityList();
        partnerTrainingCnt.getCertificationList();
        partnerTrainingCnt.getContacts();
        partnerTrainingCnt.getCategories();
        partnerTrainingCnt.saveCertification();
        
        
        partnerTrainingCnt = new PartnerTrainingController();
        partnerTrainingCnt.currentUser = user;
        partnerTrainingCnt.standardUser = true;
        partnerTrainingCnt.partnerTraining.CertificateNumber__c =null;
        partnerTrainingCnt.partnerTraining.Date_Achieved__c =null;
        partnerTrainingCnt.partnerTraining.Certificate_Owner__c = null;
        partnerTrainingCnt.saveCertification();
    }

}