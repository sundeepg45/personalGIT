public with sharing class PartnerStatusControllerExt {
    /*
	private static final String ACCOUNT_ID = 'AccountId';
	private static final String PARTNER_STATUS_ID ='PartnerStatusID';
	private static final String RESELLER_STR='Reseller';
	private static final String ACTIVE_STR='Active';
	private static final String DRAFT_STR='Draft';
	private static final String ADDED_NEW_PARTNER_STATUS='Assigned account with new partner status';
	public Boolean validationFailed {get;  set;}

    public Account accountInfo{get; set;}
    public PartnerStatus__c  partnerStatusInfo {get; set;}
    public PartnerStatus__c  previousPartnerStatusInfo {get; set;}

    public PartnerStatusControllerExt(){
    	 this.partnerStatusInfo = new PartnerStatus__c();
    	 String accountId = ApexPages.currentPage().getParameters().get(ACCOUNT_ID);
    	 String partnerStatusID = ApexPages.currentPage().getParameters().get(PARTNER_STATUS_ID);
    	 System.debug('Account ID------------>'+ accountId);
    	 System.debug('Partner Status  ID------------>'+ partnerStatusID);
    	 this.accountInfo = getAccountDetails(accountId);
    	 this.previousPartnerStatusInfo =getPartnerPreviousStatusInfo(this.accountInfo, partnerStatusID);
    	 this.validationFailed = false;
    }

    public PageReference changePartnerStatus() {

    	try {
	   		partnerStatusInfo.Partner__c = accountInfo.Id;
	    	partnerStatusInfo.Previous_Partner_Status__c = this.previousPartnerStatusInfo.Id;
	    	partnerStatusInfo.PartnerType__c =this.previousPartnerStatusInfo.PartnerType__c;
	    	insert partnerStatusInfo;
		    PreviousPartnerInfo.markAllOldStatusesInvisible(accountInfo.Id);

	    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, ADDED_NEW_PARTNER_STATUS));
	  	} catch(Exception ex) {
	  		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
	  		return null;
	  	}
	  	return new PageReference('/'+ partnerStatusInfo.Id);

    }


    public PageReference back() {

    	PageReference pageReference = new PageReference('/' + this.previousPartnerStatusInfo.Id);
        pageReference.setRedirect(true);
    	System.debug('PreviousPartnerStatus ID::'+ this.previousPartnerStatusInfo.Id);
    	return pageReference;
    }


    private Classification__c getResellerClassificationObject() {
    	Classification__c resellerCalssification = [Select c.Name, c.Id From Classification__c c where c.Name =:RESELLER_STR];
    	return resellerCalssification;
    }

    private PartnerStatus__c getPartnerPreviousStatusInfo(Account account, String previousPartnerStatusId) {
    	PartnerStatus__c partnerStatusInfo = [Select p.Partner__c, p.Name, p.Id, p.ActivationStatus__c,p.PartnerType__c From PartnerStatus__c p where p.Partner__c= :account.Id AND p.Id =: previousPartnerStatusId];
    	return partnerStatusInfo;
    }

    private Account getAccountDetails(String accountId) {
    	Account accountInfo = [Select a.Name, a.Id From Account a where a.Id =: accountId];
    	return accountInfo;
    }

    private boolean checkPartnerStatus(Account accountInfo) {
    	boolean hasPendingStatus = false;
    	List<PartnerStatus__c>  partnerStatusList = [Select p.Partner__c, p.PartnerTier__c, p.Id, p.ApprovalStatus__c From PartnerStatus__c p where p.ApprovalStatus__c in ('Pending','Draft') AND p.Partner__c=:accountInfo.id ];
    	if (partnerStatusList != null && partnerStatusList.size() > 0) {
    		hasPendingStatus = true;
    	}
    	return hasPendingStatus;
    }

    //
    // This is called from the visual force page on load to check if there are any pending partner status, before allowing him to create new one.
    //
    public PageReference validatePartnerStatus() {
    	if (checkPartnerStatus(this.accountInfo)) {
    		this.validationFailed = true;
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Account has partner status that are pending for approvals'));
    	}
    	return null;
    }


    public static testMethod void test() {
        User user  = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
        Classification__c resellerClassification = [Select c.Name, c.Id From Classification__c c where c.Name ='Reseller'];
        Classification__c readyClassification = [Select c.Name, c.Id From Classification__c c where c.Name ='Ready'];
        RecordType partnerRecordType =[Select r.Name, r.Id From RecordType r where r.name='EMEA Partner'];

        Account a = new Account();
        a.ownerId = user.Id;
        a.name = 'Test';
        a.BillingStreet = 'Test';
        a.BillingCity = 'Test';
        a.BillingState = 'CA';
        a.BillingCountry = 'US';
        a.ShippingState = 'CA';
        a.ShippingCountry = 'US';
        a.RecordTypeId = partnerRecordType.Id;
        insert a;

        System.debug('Account Id----------->'+ a.Id);


        PartnerStatus__c partnerStatus = new PartnerStatus__c();
        partnerStatus.Partner__c= a.Id;
	    partnerStatus.PartnerType__c =resellerClassification.Id;
	    partnerStatus.PartnerTier__c =  readyClassification.Id;
	    insert partnerStatus;



	    ApexPages.currentPage().getParameters().put(ACCOUNT_ID, a.Id);
	    ApexPages.currentPage().getParameters().put(PARTNER_STATUS_ID, partnerStatus.Id);
	    PartnerStatusControllerExt contactExtController = new PartnerStatusControllerExt();
	    contactExtController.partnerStatusInfo.PartnerTier__c =readyClassification.Id;
	    contactExtController.validatePartnerStatus();
	    contactExtController.changePartnerStatus();
	    contactExtController.back();



     }
*/

}