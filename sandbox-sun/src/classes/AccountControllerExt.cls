public with sharing class AccountControllerExt {

	private static final String RESELLER_STR='Reseller';
	private static final String ACTIVE_STR='Active';
	private static final String DRAFT_STR='Draft';
	private static final String ADDED_NEW_PARTNER_STATUS='Assigned account with new partner status';
	public static Boolean APPROVED_BY_API = false;

    public Account accountInfo{get; set;}
    public PartnerStatus__c  partnerStatusInfo {get; set;}

      /*
     * Constructor for the controller
     */
    public AccountControllerExt(ApexPages.StandardController stdController){
    	 this.accountInfo = (Account)stdController.getRecord();
    	 this.partnerStatusInfo = new PartnerStatus__c();
    }

    /*
     *
     */
    public PageReference changePartnerStatus() {

    	try {
	   		partnerStatusInfo.Partner__c = accountInfo.Id;
	    	partnerStatusInfo.Previous_Partner_Status__c = getPartnerPreviousStatus(accountInfo).Id;
	    	partnerStatusInfo.PartnerType__c =getResellerClassificationObject().Id;
	    	partnerStatusInfo.ActivationDate__c = System.today();
	    	insert partnerStatusInfo;
	    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, ADDED_NEW_PARTNER_STATUS));
	  	} catch(Exception ex) {
	  		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
	  	}
    	return null;
    }


    /*
     * Method to go back to the contact page.
     */
    public PageReference back() {
    	return new PageReference('/'+this.accountInfo.Id);
    }


    private Classification__c getResellerClassificationObject() {
    	Classification__c resellerCalssification = [Select c.Name, c.Id From Classification__c c where c.Name =:RESELLER_STR];
    	return resellerCalssification;
    }

    private PartnerStatus__c getPartnerPreviousStatus(Account account) {
    	PartnerStatus__c partnerStatusInfo = [Select p.Partner__c, p.Name, p.Id, p.ActivationStatus__c From PartnerStatus__c p where p.Partner__c= :account.Id AND p.ActivationStatus__c =:ACTIVE_STR];
    	return partnerStatusInfo;
    }

    private List<PartnerStatus__c> getAllPartnerStatus(Account account) {
    	List<PartnerStatus__c> partnerStatusList = [Select p.Partner__c, p.Name, p.Id, p.ActivationStatus__c From PartnerStatus__c p where p.Partner__c= :account.Id AND p.ActivationStatus__c =:ACTIVE_STR];
    	return partnerStatusList;
    }

}