public with sharing class NFRListController {

    public ApexPages.StandardController controller {get; set;}

    public String acctId { get; set; }
    private User currentUser {get; set;}
    public NFR_Request__c nfrs {get; set;}
    public List<NFR_Request__c> NfrList1 {get; set;}
    public Account acct;

    public NFRListController(ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();
        NfrList1 = new List<NFR_Request__c>();

        if(acct.id<>null){
             NfrList1 = [select id,
                    Name,
                    Partner__r.id,
                    Partner__r.name,
                    Global_Region__c,
                    Subregion__c,
                    Partner_Status__c,
                    RHN_Login__c,
                    Use_Case__c,
                    Status__c,
                    Comments__c,
                    Owner.name,
                    Opportunity__r.id,
                    Opportunity__r.name,
                    Contact_at_Partner__r.id,
                    Contact_at_Partner__r.name,
                    Expiration_Date__c,
                    Active__c,
                    (Select Id, name,Product__c, NFR_Product_Name__c, Product_Code__c, Product_Description__c, Product_Family__c, Quantity__c, Configured_SKU__c from NFR_LIs__r),
                    (select id, name, StageName, CloseDate from NFR__r)
                    from NFR_Request__c
                    where Partner__r.id = :acct.Id
                    and Active__c = true
                ];
        }
    }

    public PageReference createNewNFR() {
        PageReference p = page.NFRPageLayout;
        p.getParameters().put('retURL', '/' + acct.id);
        p.setRedirect(true);
        return p;
    }

    public PageReference backToAccount() {
        return new PageReference('/' + acct.id);
    }

}