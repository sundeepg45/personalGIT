public without sharing class PartnerCertificationsListController {
    private transient Map<String, String> clfnsTranslationCache;


    public ApexPages.StandardController controller { get; set; }
 	public String redirectId { get; set; }
 	public String acctId { get; set; }

	public PartnerCertificationsListController() {
        system.debug('MD: constructor for PartnerCertificationsListController');
		acctId = ApexPages.currentPage().getParameters().get('id');
	}

	public PartnerCertificationsListController(ApexPages.StandardController controller) {
		this.controller = controller;
	}

	public PageReference createNewCertification() {
        system.debug('MD: Sending user to partnerCertification page..');
//    	PageReference p = new PageReference('/apex/partnerCertification?accountId=' + acctId);
  		PageReference p = page.partnerCertification;
        p.getParameters().put('accountId', acctId);
        p.setRedirect(true);
        return p;
	}

	public PageReference backToAccount() {
		return new PageReference('/' + acctId);
	}

    public PageReference removeCertification() {
		redirectId = ApexPages.currentPage().getParameters().get('redirect-id');
		delete [select id from PartnerTraining__c where Id = :redirectId];
    	return new PageReference('/apex/PartnerCertificationsList?id=' + acctId);
    }

	public PageReference editCertification() {
		redirectId = ApexPages.currentPage().getParameters().get('redirect-id');
		PageReference ref = new PageReference('/apex/partnerCertification?id=' + acctId);
		ref.getParameters().put('id', redirectId);
		return ref;
	}

	public List<PartnerTraining__c> getCertificationList() {
		List<PartnerTraining__c> certs = new List<PartnerTraining__c>();
        acctId = ApexPages.currentPage().getParameters().get('id');
        if (acctId == null){
	        User currentUser = [Select u.Id, u.Contact.Account.Id, u.ContactId From User u Where u.Id = :UserInfo.getUserId() ];
        	acctId = currentUser.Contact.Account.Id;
        }
		for (PartnerTraining__c cert : [
			select	Id
				 ,	CertificateNumber__c
				 ,	Date_Achieved__c
				 ,	Contact__r.Name
				 ,	Contact__c
				 ,	Certificate_Owner__c
				 ,  Certifying_Entity__c
				 ,  Certification__c
				 ,  Certification__r.Name
				 ,	TrainingType__r.Name
				 ,  TrainingType__c
				 ,  RedHatValidated__c
				 ,  IsValid__c
                 ,  IsActive__c
				 ,	LMSCreated__c
            	 ,	Accreditation_Name__c
			  from	PartnerTraining__c
			 where	Partner__c = :acctId
		]) certs.add(cert);

		//
		// translate the classifications
		//
		for (PartnerTraining__c cert : certs) {
            if (cert.TrainingType__r != null) {
				cert.TrainingType__r.Name = getTranslatedClfn(cert.TrainingType__c, cert.TrainingType__r.Name);
            }
            if (cert.Certification__r != null) {
				cert.Certification__r.Name = getTranslatedClfn(cert.Certification__c, cert.Certification__r.Name);
            }
		}
		return certs;
	}

    private String getTranslatedClfn(ID clfnId, String defaultValue) {

        if (clfnsTranslationCache == null){
            clfnsTranslationCache = new Map<String,String>();
            for (ClassificationTranslation__c ct : [
                    select Classification__c, LanguageCode__c, Translation__c
                      from ClassificationTranslation__c
                      where LanguageCode__c = :UserInfo.getLanguage()
            ]){
                clfnsTranslationCache.put(ct.Classification__c + UserInfo.getLanguage(), ct.Translation__c);
            }
        }

        if (clfnsTranslationCache.containsKey(clfnId + '_' + UserInfo.getLanguage()))
        {
            return clfnsTranslationCache.get(clfnId + '_' + UserInfo.getLanguage());
        }
        return defaultValue;
    }

    static testMethod void myTest() {
        PartnerCertificationsListController ctrl = new PartnerCertificationsListController();
        PartnerTraining__c pt = [select id, Partner__c from PartnerTraining__c limit 1];
        ApexPages.currentPage().getParameters().put('id', pt.Partner__c);
        List<PartnerTraining__c> trainingList = ctrl.getCertificationList();
        PageReference ref = ctrl.editCertification();
        ref = ctrl.removeCertification();
        ref = ctrl.backToAccount();
        ref = ctrl.createNewCertification();
    }
}