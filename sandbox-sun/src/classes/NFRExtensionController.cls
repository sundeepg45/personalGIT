public class NFRExtensionController {

    public NFR_Request__c nfrObj {get; private set;}
    public String term {get; set;}
    //public List<LicenseKey> licenseKeys {get; set;}
    public Boolean isPartnerUser {get; private set;}
    public Boolean isAnnualValidation {get; private set;}

    public static final List<String> DAY_OPTION_SET_PARTNER = new List<String> {'30', '60', '90'};
    public static final List<String> DAY_OPTION_SET_INTERNAL = new List<String> {'30', '60', '90', '365'};

    public static final Set<String> VALID_NFR_STATUS = new Set<String> {'Approved', 'Extension Rejected', 'Extension Approved', 'Extension Processed', 'Processed'};
    public static final String PARTNER_USER_TYPE = 'PowerPartner';
    public static final Integer MIN_DAYS = 335;
    public static final Integer MAX_ROWS = 4;

    public String message {get; private set;}
    public Boolean error {get; private set;}

    //constructor
    public NFRExtensionController(ApexPages.StandardController stdController) {
        Id nfrId = stdController.getId();
        String annual = System.currentPageReference().getParameters().get('a');
        isAnnualValidation = (annual != null && annual.equals('1'));
        this.nfrObj = [Select Id, Name, Status__c, NFR_Type__c from NFR_Request__c where Id = :nfrId];
        init();

    }

    private void init() {
        isPartnerUser = Userinfo.getUserType().equalsIgnoreCase(PARTNER_USER_TYPE);
        error = false;
        /*licenseKeys = new List<LicenseKey>();
        for (Integer i = 0; i < MAX_ROWS; i++) {
            licenseKeys.add(new LicenseKey(''));
        }*/
    }

    public pageReference validate() {
        Boolean valid = (isAnnualValidation) ? validateAnnual() : validateExtension();
        if (valid && isAnnualValidation) {
       //     return saveAndSubmit();
        }
        return null;
    }

    private Boolean validateExtension() {

        String status = (nfrObj.Status__c != null) ? nfrObj.Status__c : '';
        String nfrType = nfrObj.NFR_Type__c != null ? nfrObj.NFR_Type__c : '';
        if (! VALID_NFR_STATUS.contains(status)) {
            error = true;
            message = 'The NFR does not have a valid status for an Extension Request.';
        } else if(nfrType.equalsIgnoreCase('Permanent')){
            error = true;
            message = 'This is a Permanent NFR.  An Extension is not required.';
        }else {
            Integer count = [Select count() from Opportunity where NFR__c = :nfrObj.Id];
            if (count == 0) {
                error = true;
                //message = 'Cannot continue. There is no opportunity attached to the NFR.';
                message = 'This NFR was created in a legacy system.  Contact orders@datacore.com to request an extension.';
            }else{
/*
                List<Opportunity> oppList = [Select Id, NFR__c, (Select Date_Processed__c from SOs__r) from Opportunity where NFR__c = :nfrObj.Id];
                if(oppList.size() > 0){
                    Opportunity opp = oppList[0];
                    if(opp.SOs__r.size() == 0){
                        message = 'This NFR was created in a legacy system.  Contact orders@datacore.com to request an extension.';
                        error = true;

                    }
                }
 */           }
        }
        return !error;
    }

    private Boolean validateAnnual() {
/*
        List<Opportunity> oppList = [Select Id, LastModifiedDate from Opportunity where NFR__c = :nfrObj.id order by LastModifiedDate desc limit 1];
        if (oppList.isEmpty()) {
            error = true;
            message = 'Cannot continue. There is no opportunity attached to the NFR.';
            return false;
        }

        Opportunity opp = oppList.get(0);
        List<Sales_Order__c> salesorderList = [Select Id, Date_Processed__c, License_Expiration_Date__c, License_Term__c from Sales_Order__c where Opportunity__c = :opp.id order by Date_Processed__c limit 1];
        if (salesOrderList.isEmpty()) {
            error = true;
            message = 'Cannot continue. There is no Sales Order associated with the opportunity attached to the NFR.';
            return false;
        }
        Sales_Order__c salesOrder = salesorderList.get(0);
        Integer licenseTerm = (salesOrder.License_Term__c == null || salesOrder.License_Term__c.equals('')) ? 0 : Integer.valueOf(salesOrder.License_Term__c);
        Date processedDate = salesOrder.Date_Processed__c != null ? salesOrder.Date_Processed__c : Date.today();
        Date dateCheck = (salesOrder.License_Expiration_Date__c != null)
            ? salesOrder.License_Expiration_Date__c : processedDate.addDays(licenseTerm);

        if (dateCheck == null || dateCheck.daysBetween(Date.today()) < MIN_DAYS) {
            error = true;
            message = 'Cannot continue. You can request for an Annual validation only 30 days before expiration.';
            return false;
        }
        return !error;
*/      return false;
    }

    public List<SelectOption> getExtensionOptions() {
        List<SelectOption> extensionOptions = new List<SelectOption>();
        for (String days : (isPartnerUser) ? DAY_OPTION_SET_PARTNER : DAY_OPTION_SET_INTERNAL) {
            extensionOptions.add(new SelectOption(days, days));
        }

        return extensionOptions;
    }

    //Action Methods
/*
    public PageReference saveAndSubmit() {
       try {
            if (isAnnualValidation) {
                nfrObj.License_Term__c = '365';
            }else{
                nfrObj.License_Term__c = term;
            }
            update nfrObj;
           Approval.ProcessResult result = FusionUtil.submitForApproval(nfrObj.Id,'NFR Extension Request (' + nfrObj.License_Term__c + ')');
            if (! result.isSuccess()) {
                message = 'Failed to Submit NFR for approval: ' + result.getErrors()[0].getMessage();
                error = true;
                return null;
            }

        } catch(DmlException e) {
            message = 'Failed to update NFR: ' + e.getMessage();
            error = true;
            return null;
        }
        return new pageReference('/' + nfrObj.Id);
    }
*/

    testMethod static void unit() {
        CDH_Party__c cdhParty = new CDH_Party__c();
        cdhParty.CDH_Party_Name__c = 'Test';
        insert cdhParty;

        User owner  = [Select Id, FirstName, LastName, FederationIdentifier from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
        Account account = new Account();
        account.CDH_Party_Name__c = cdhParty.Id;
        account.Name ='Test Acc';
        account.Global_Region__c ='APAC';
        account.OwnerId = owner.Id;
        account.PartnerStatuses__c ='ISV';
        insert account;

        Contact cont = new Contact();
        cont.OwnerId = owner.Id;
        cont.AccountId = account.Id;
        cont.FirstName ='FS';
        cont.LastName = 'LS';
        cont.email = 'a@b.com';
        cont.LoginName__c = 'someone@redhat.com';
        insert cont;

        owner.FederationIdentifier = cont.LoginName__c;
        update owner;

        NFR_Request__c nfr = new NFR_Request__c(Contact_at_Partner__c = cont.Id,NFR_Type__c = 'Temp',Partner__c=account.Id);
        nfr.User_RHN_Entitlement_Login__c = owner.FederationIdentifier;
        insert nfr;

        Product2 prd = new Product2();
        prd.Name ='Test';
        prd.LATAM_Product__c = true;
        prd.Family ='RHX';
        prd.CurrencyIsoCode ='USD';
        prd.IsActive = true;
        prd.for_NFR__c = true;
        insert prd;
        NFR_LI__c nfrLine = new NFR_LI__c();
        nfrLine.Product__c = prd.Id;
        nfrLine.NFR__c = nfr.Id;
        nfrLine.Quantity__c =4;
        insert nfrLine;
        nfr.Status__c ='Approved';
        update   nfr;

        Opportunity opp = new Opportunity(Name = 'Test', StageName = 'Prospecting', CloseDate = Date.today() +10, NFR__c = nfr.Id);
        insert opp;
        NFRExtensionController controller = new NFRExtensionController(new ApexPages.Standardcontroller(nfr));
        controller.validate();
        controller.validateExtension();
        controller.validateAnnual();
        controller.getExtensionOptions();
        PageReference pageRef = Page.NFRExtensionRequest;
        Test.setCurrentPage(pageRef);
        System.currentPageReference().getParameters().put('a', '1');
        controller = new NFRExtensionController(new ApexPages.Standardcontroller(nfr));
        controller.validate();
        controller.validateExtension();
        controller.validateAnnual();
        controller.getExtensionOptions();

        nfr = new NFR_Request__c(Contact_at_Partner__c = cont.Id,Status__c = 'Draft', NFR_Type__c = 'Permanent',Partner__c=account.Id);
        nfr.User_RHN_Entitlement_Login__c = owner.FederationIdentifier;
        insert nfr;
        opp = new Opportunity(Name = 'Test', StageName = 'Prospecting', CloseDate = Date.today() +10, NFR__c = nfr.Id);
        insert opp;
        controller = new NFRExtensionController(new ApexPages.Standardcontroller(nfr));
        controller.validate();
        controller.validateExtension();
        controller.validateAnnual();
        controller.getExtensionOptions();
        pageRef = Page.NFRExtensionRequest;
        Test.setCurrentPage(pageRef);
        System.currentPageReference().getParameters().put('a', '1');
        controller = new NFRExtensionController(new ApexPages.Standardcontroller(nfr));
        controller.validate();
        controller.validateExtension();
        controller.validateAnnual();
        controller.getExtensionOptions();
    }

/*
    public class LicenseKey {

        public String key {get; set;}

        public LicenseKey(String key) {
            this.key = key;
        }


    }
*/

}