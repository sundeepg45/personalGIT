public with sharing class BusinessPlan_EditAccountFieldsController {
    public Account account {get; private set;}
    public Id bpId {get; set;}
    public String saveButtonLabel {get; set;}
    public Boolean saved {get; set;}
    
    public BusinessPlan_EditAccountFieldsController() {
        saveButtonLabel = Label.BusinessPlan_Save;
        saved = false;
        Id accountId = null;
        Id tmpid = ApexPages.currentPage().getParameters().get('accountId');
        bpId = ApexPages.currentPage().getParameters().get('bpId');
        if (tmpid == null) {
            User me = [select Contact.AccountId from User where Id = :UserInfo.getUserId()];
            accountId = me.Contact.AccountId;
        }
        else {
            accountId = tmpid;
        }
        loadAccount(accountId);
    }
    
    private void loadAccount(Id accountId){
        account = [ select 
                        Id,
                        Name,                         
                        Phone,
                        Fax,
                        ShippingStreet,
                        ShippingCity,
                        ShippingState,
                        ShippingCountry,
                        PartnerStatuses__c,
                        Offices_Locations__c,
                        Additional_Partnerships__c,
                        Target_Market_Size__c,
                        Partner_s_Largest_Customer__c,
                        Number_Enrolled_Sales_Cert__c,
                        NumberOfEmployeesInWWOrg__c,
                        Software_focus__c,
                        Select_Specialization_s__c,
                        Total_Partner_Sales_Certifications__c,
                        Total_Partner_Technical_Certifications__c                   
                    from Account 
                    where 
                        Id = :accountId
                ];
    }
    
    public PageReference save(){
        update account;
        saved = true;
        saveButtonLabel = Label.BusinessPlan_SaveSuccess;
        return null;
    }
    
}