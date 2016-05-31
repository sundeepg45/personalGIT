public with sharing class LeadRejectReferralExtension {

    public Lead l;

    public LeadRejectReferralExtension(ApexPages.StandardController controller) {
    
        this.l = (Lead)controller.getRecord();
    
    }
    
    public PageReference rejectLead() {
          
        l.Status = 'Dead/Unqualified';
        l.Stage__c = 'Lost';
       
        update l;
        
        return new PageReference('/' + l.Id);
        
    } 
    
    @isTest(SeeAllData = true)
    private static void thisIsOnlyATest() {
    
        Lead l = [SELECT Id, Status, Stage__c FROM Lead WHERE Status != 'Dead/Unqualified' Limit 1];               
        ApexPages.StandardController lStdCtrlr = new ApexPages.standardController(l);
        LeadRejectReferralExtension leadRefRExt = new LeadRejectReferralExtension(lStdCtrlr);             
        ApexPages.currentPage().getParameters().put('Id',String.valueOf(l.id));
        leadRefRExt.rejectLead();       
        
    } 

}